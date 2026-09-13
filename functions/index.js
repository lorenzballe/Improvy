/**
 * Improvy's server side. Three functions, one purpose: a Pro licence bought
 * on the website becomes a document the app honours.
 *
 *   createCheckoutSession  the site calls this, signed in; it answers with a
 *                          Stripe Checkout URL carrying the buyer's account id
 *   stripeWebhook          Stripe calls this after the money moved; it writes
 *                          entitlements/{uid}, or takes it back on a refund
 *   proStatus              the site's success page asks this whether the
 *                          licence has landed yet
 *
 * Nothing here is reachable from the app in a way that could grant Pro: the
 * app only ever READS entitlements/{uid}, under rules that let nobody write
 * it. Everything that writes goes through the webhook, and the webhook trusts
 * nothing that is not signed by Stripe.
 */
import { onCall, onRequest, HttpsError } from "firebase-functions/v2/https";
import { defineSecret, defineString } from "firebase-functions/params";
import { setGlobalOptions } from "firebase-functions/v2";
import { logger } from "firebase-functions";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import Stripe from "stripe";

import { applyStripeEvent, proFromLookups } from "./lib/entitlements.js";

setGlobalOptions({ region: "europe-west1", maxInstances: 10 });
initializeApp();

// Secrets live in Secret Manager; the GitHub Action writes them there from
// the repository's secrets. Params come from functions/.env, committed.
const STRIPE_SECRET_KEY = defineSecret("STRIPE_SECRET_KEY");
const STRIPE_WEBHOOK_SECRET = defineSecret("STRIPE_WEBHOOK_SECRET");
const STRIPE_PRICE_ID = defineSecret("STRIPE_PRICE_ID");
const SITE_URL = defineString("SITE_URL", { default: "https://lorenzballe.github.io/Improvyapp/" });
const STRIPE_AUTOMATIC_TAX = defineString("STRIPE_AUTOMATIC_TAX", { default: "false" });

const db = () => getFirestore();
const stripe = () => new Stripe(STRIPE_SECRET_KEY.value(), { apiVersion: "2025-08-27.basil" });

/** entitlements/{uid}, or null. */
async function entitlementByUid(uid) {
  const snap = await db().collection("entitlements").doc(uid).get();
  return snap.exists ? snap.data() : null;
}

/** The newest live entitlement carrying this (lower-cased) address, or null. */
async function entitlementByEmail(email) {
  if (!email) return null;
  const q = await db()
    .collection("entitlements")
    .where("email", "==", email.toLowerCase())
    .where("pro", "==", true)
    .limit(1)
    .get();
  return q.empty ? null : q.docs[0].data();
}

async function proFor(auth) {
  const email = auth.token.email ? String(auth.token.email).toLowerCase() : null;
  const [byUid, byEmail] = await Promise.all([
    entitlementByUid(auth.uid),
    entitlementByEmail(email),
  ]);
  return proFromLookups({ byUid, byEmail, emailVerified: auth.token.email_verified === true });
}

// ── The site asks for a place to pay ────────────────────────────────────────

export const createCheckoutSession = onCall(
  { secrets: [STRIPE_SECRET_KEY, STRIPE_PRICE_ID], cors: true },
  async (request) => {
    const auth = request.auth;
    if (!auth) throw new HttpsError("unauthenticated", "Sign in first: the licence is tied to an account.");

    // Express consent to immediate delivery, and to the terms. EU consumer
    // law lets someone give up the 14-day withdrawal right for digital
    // content only if they say so before paying — so the site asks, and this
    // refuses to open a checkout without the answer.
    if (request.data?.consent !== true) {
      throw new HttpsError("failed-precondition", "The terms have to be accepted before paying.");
    }

    const already = await proFor(auth);
    if (already.pro) return { alreadyPro: true, via: already.via };

    const email = auth.token.email ? String(auth.token.email) : undefined;
    const site = SITE_URL.value().replace(/\/?$/, "/");
    const tax = STRIPE_AUTOMATIC_TAX.value() === "true";

    const session = await stripe().checkout.sessions.create({
      mode: "payment",
      line_items: [{ price: STRIPE_PRICE_ID.value(), quantity: 1 }],
      // The account, carried through Stripe and back: this is what the
      // webhook keys the licence on. Never the email alone.
      client_reference_id: auth.uid,
      customer_email: email,
      metadata: {
        uid: auth.uid,
        email: email ?? "",
        consent: "terms+immediate-delivery",
        consentAt: new Date().toISOString(),
      },
      success_url: `${site}#pro/success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${site}#pro/cancel`,
      allow_promotion_codes: true,
      ...(tax ? { automatic_tax: { enabled: true } } : {}),
      payment_intent_data: { description: "Improvy Pro — lifetime licence" },
    });

    logger.info("checkout opened", { uid: auth.uid, session: session.id, livemode: session.livemode });
    return { url: session.url, sessionId: session.id };
  }
);

// ── The site asks whether the licence has landed ────────────────────────────

export const proStatus = onCall({ cors: true }, async (request) => {
  const auth = request.auth;
  if (!auth) throw new HttpsError("unauthenticated", "Sign in first.");
  const r = await proFor(auth);
  return {
    pro: r.pro,
    via: r.via,
    grantedAt: r.doc?.grantedAt?.toDate?.()?.toISOString?.() ?? null,
    email: r.doc?.email ?? null,
  };
});

// ── Stripe says the money moved ─────────────────────────────────────────────

export const stripeWebhook = onRequest(
  { secrets: [STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET] },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("POST only");
      return;
    }
    let event;
    try {
      // rawBody, not the parsed one: the signature covers the exact bytes.
      event = stripe().webhooks.constructEvent(
        req.rawBody,
        req.headers["stripe-signature"],
        STRIPE_WEBHOOK_SECRET.value()
      );
    } catch (e) {
      logger.warn("webhook rejected", { reason: String(e?.message ?? e) });
      res.status(400).send("bad signature");
      return;
    }

    const firestore = db();
    const events = firestore.collection("stripe_events");
    const entitlements = firestore.collection("entitlements");

    const store = {
      seen: async (id) => (await events.doc(id).get()).exists,
      remember: (id, summary) =>
        events.doc(id).set({ ...summary, receivedAt: FieldValue.serverTimestamp(), livemode: event.livemode }),
      grant: (uid, doc) => entitlements.doc(uid).set(doc, { merge: false }),
      revokeByPaymentIntent: async (pi, { reason, at }) => {
        const q = await entitlements.where("paymentIntent", "==", pi).get();
        await Promise.all(
          q.docs.map((d) => d.ref.set({ pro: false, revokedAt: at, revokedReason: reason }, { merge: true }))
        );
        return q.size;
      },
    };

    try {
      const outcome = await applyStripeEvent(event, store);
      logger.info("webhook applied", { id: event.id, type: event.type, outcome, livemode: event.livemode });
      res.status(200).json({ received: true, outcome });
    } catch (e) {
      // 5xx makes Stripe retry, which is what we want for a Firestore hiccup.
      logger.error("webhook failed", { id: event.id, type: event.type, error: String(e?.stack ?? e) });
      res.status(500).send("try again");
    }
  }
);
