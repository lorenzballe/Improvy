/**
 * Improvy's server side. Five functions, one purpose: a Pro licence bought
 * on the website becomes a document the app honours.
 *
 *   createCheckoutSession  the site calls this, signed in; it answers with a
 *                          Stripe Checkout URL carrying the buyer's account id
 *   stripeWebhook          Stripe calls this after the money moved; it writes
 *                          entitlements/{uid}, or takes it back on a refund
 *   confirmCheckout        the buyer comes back carrying a session id; this
 *                          asks Stripe whether it was paid and writes the
 *                          licence if the webhook has not already
 *   revenueCatWebhook      RevenueCat calls this when somebody buys in the
 *                          app; it writes the same document, so a licence is
 *                          one fact wherever it was bought
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
// firebase-admin/firestore loads @google-cloud/firestore, which
// firebase-admin declares as an OPTIONAL dependency — and an optional
// dependency npm decides to skip is skipped in silence. It installed here
// and not on the deploy runner, where the analysis then failed with "Cannot
// find module" while nothing looked wrong locally. package.json names it
// outright so it is no longer npm's decision.
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import Stripe from "stripe";
import { timingSafeEqual } from "node:crypto";

import { applyStripeEvent, confirmDecision, proFromLookups } from "./lib/entitlements.js";
import { proLineItem, PRO_AMOUNT, PRO_CURRENCY } from "./lib/catalog.js";
import { cleanRef } from "./lib/referral.js";
import { normalizeCode, discountedAmount, couponOf } from "./lib/promo.js";
import { decideFromRcEvent } from "./lib/revenuecat.js";

setGlobalOptions({ region: "europe-west1", maxInstances: 10 });
initializeApp();

// Secrets live in Secret Manager; the GitHub Action writes them there from
// the repository's secrets. Params come from functions/.env, committed.
const STRIPE_SECRET_KEY = defineSecret("STRIPE_SECRET_KEY");
const STRIPE_WEBHOOK_SECRET = defineSecret("STRIPE_WEBHOOK_SECRET");
// The value RevenueCat is told to send in its Authorization header. It has no
// signature scheme, so this shared word is the whole of the proof that an
// event came from them.
const REVENUECAT_WEBHOOK_AUTH = defineSecret("REVENUECAT_WEBHOOK_AUTH");
const SITE_URL = defineString("SITE_URL", { default: "https://improvy.app/" });
const STRIPE_AUTOMATIC_TAX = defineString("STRIPE_AUTOMATIC_TAX", { default: "false" });
// Optional. Empty means the checkout describes the product itself — name,
// line, price and the app's icon — which is one less thing to create in a
// dashboard. Set it to a price_… to let the Stripe catalogue rule instead.
const STRIPE_PRICE_ID = defineString("STRIPE_PRICE_ID", { default: "" });
// Shown on the right of the Stripe page. Stripe fetches it from its own
// servers, so it has to be public; the site serves it next to the page.
const PRO_IMAGE_URL = defineString("PRO_IMAGE_URL", { default: "" });

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
  { secrets: [STRIPE_SECRET_KEY], cors: true },
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
    // A discount code applied on the page, checked again here: the page is
    // only a preview, this is what Stripe will charge.
    const found = request.data?.code ? await findPromotion({ code: request.data.code }) : null;
    // The creator whose link brought them — or, failing that, whose code
    // they typed. It is what pays an affiliate.
    const ref = cleanRef(request.data?.ref) || cleanRef(found?.promo?.metadata?.ref);
    const tax = STRIPE_AUTOMATIC_TAX.value() === "true";

    const session = await stripe().checkout.sessions.create({
      mode: "payment",
      line_items: [
        proLineItem({
          priceId: STRIPE_PRICE_ID.value() || null,
          image: PRO_IMAGE_URL.value() || `${site}improvy-pro.png`,
          tax,
        }),
      ],
      // The account, carried through Stripe and back: this is what the
      // webhook keys the licence on. Never the email alone.
      client_reference_id: auth.uid,
      customer_email: email,
      metadata: {
        uid: auth.uid,
        email: email ?? "",
        consent: "terms+immediate-delivery",
        consentAt: new Date().toISOString(),
        ...(ref ? { ref } : {}),
        ...(found ? { code: found.code } : {}),
      },
      // The id goes in the query, not inside the fragment: a fragment is not
      // part of what a server ever sees, and this one has to survive whatever
      // Stripe does to the URL. The page reads either spelling.
      success_url: `${site}?session_id={CHECKOUT_SESSION_ID}#pro/success`,
      cancel_url: `${site}#pro/cancel`,
      // A code chosen on our page is applied here; without one, Stripe's own
      // "Add promotion code" field stays available. Stripe allows one or the
      // other, never both.
      ...(found ? { discounts: [{ promotion_code: found.promo.id }] } : { allow_promotion_codes: true }),
      // "Pay", not "Subscribe" or "Donate": it is one payment, forever.
      submit_type: "pay",
      // The last thing read before the money moves, and the same promise the
      // page made: what is bought, and that it arrives on the account.
      custom_text: {
        submit: {
          message:
            "Improvy Pro is a one-off payment. The licence lands on the account you signed in with, on any phone.",
        },
      },
      // Stripe Tax collects the address it needs by itself; asking for it
      // when tax is off would be friction for a record nobody keeps.
      ...(tax ? { automatic_tax: { enabled: true }, billing_address_collection: "required" } : {}),
      // On the payment too, so Stripe → Payments can be filtered by creator
      // without opening each session.
      payment_intent_data: {
        description: "Improvy Pro — lifetime licence",
        ...(ref ? { metadata: { ref } } : {}),
      },
    });

    logger.info("checkout opened", { uid: auth.uid, session: session.id, livemode: session.livemode, ref });
    return { url: session.url, sessionId: session.id };
  }
);

// ── The buyer comes back from Stripe ────────────────────────────────────────

/**
 * The second path to a licence, and the one that saves the first day.
 *
 * Stripe's webhook is the proper way in, but it is also the piece most
 * likely to be missing or misrouted the first time somebody sets this up —
 * and the person who finds out is the one who has just paid. So the success
 * page hands its session id here, and the server asks Stripe directly.
 *
 * Nothing about the answer comes from the browser. The session is fetched
 * with the secret key, it must say `paid`, and it must have been opened for
 * the account making the call — an id belonging to someone else's checkout
 * is refused, not honoured.
 */
export const confirmCheckout = onCall(
  { secrets: [STRIPE_SECRET_KEY], cors: true },
  async (request) => {
    const auth = request.auth;
    if (!auth) throw new HttpsError("unauthenticated", "Sign in first.");

    const id = String(request.data?.sessionId ?? "");
    if (!/^cs_[A-Za-z0-9_]{10,200}$/.test(id)) {
      throw new HttpsError("invalid-argument", "That is not a checkout session.");
    }

    let session;
    try {
      session = await stripe().checkout.sessions.retrieve(id);
    } catch (e) {
      logger.warn("confirm: session not retrievable", { uid: auth.uid, id, error: String(e?.message ?? e) });
      throw new HttpsError("not-found", "Stripe does not know that checkout.");
    }

    const existing = await entitlementByUid(auth.uid);
    const decision = confirmDecision({ session, uid: auth.uid, existing });

    if (decision.outcome === "wrong-account") {
      logger.warn("confirm: session belongs to another account", { uid: auth.uid, id });
      throw new HttpsError("permission-denied", "That checkout belongs to another account.");
    }
    if (decision.outcome === "granted") {
      await db().collection("entitlements").doc(auth.uid).set(decision.doc, { merge: false });
    }
    logger.info("confirm", { uid: auth.uid, id, outcome: decision.outcome, livemode: session.livemode });

    return {
      pro: decision.outcome === "granted" || decision.outcome === "already",
      outcome: decision.outcome,
    };
  }
);

// ── The site asks whether the licence has landed ────────────────────────────

/**
 * A live promotion code and its coupon, or null. Looked up by the code
 * someone typed, or by the creator whose link they followed — the New
 * creator workflow records every creator's code in creators/{CODE}.
 */
async function findPromotion({ code, ref }) {
  let wanted = normalizeCode(code);
  if (!wanted && ref) {
    const q = await db()
      .collection("creators")
      .where("ref", "==", ref)
      .where("active", "==", true)
      .limit(1)
      .get();
    if (!q.empty) wanted = q.docs[0].id;
  }
  if (!wanted) return null;
  const list = await stripe().promotionCodes.list({ code: wanted, active: true, limit: 1 });
  const promo = list.data[0];
  if (!promo) return null;
  let coupon = couponOf(promo);
  if (typeof coupon === "string") coupon = await stripe().coupons.retrieve(coupon);
  if (!coupon || coupon.valid === false) return null;
  if (promo.expires_at && promo.expires_at * 1000 < Date.now()) return null;
  return { promo, coupon, code: promo.code };
}

/**
 * The price a code gives, before paying — so the page can show 18,99 €
 * crossed out and the real total beside it, and a wrong code is caught on
 * the page instead of on Stripe's. Needs no account: it reveals nothing but
 * what the code itself is for.
 */
export const quotePromo = onCall({ secrets: [STRIPE_SECRET_KEY], cors: true }, async (request) => {
  const ref = cleanRef(request.data?.ref);
  const found = await findPromotion({ code: request.data?.code, ref });
  if (!found) return { valid: false, amount: PRO_AMOUNT, currency: PRO_CURRENCY };
  return {
    valid: true,
    code: found.code,
    percentOff: found.coupon.percent_off ?? null,
    amountOff: found.coupon.amount_off ?? null,
    regularAmount: PRO_AMOUNT,
    amount: discountedAmount(PRO_AMOUNT, found.coupon),
    currency: PRO_CURRENCY,
  };
});

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

// ── RevenueCat says somebody bought in the app ──────────────────────────────

/**
 * The other door into entitlements/{uid}.
 *
 * A purchase made in the app used to live in RevenueCat and nowhere else, so
 * the website — which reads Firestore — could offer Pro to somebody who had
 * already paid for it. Now both doors write the same page, and "is this
 * account Pro" has one answer.
 *
 * RevenueCat signs nothing. What it does is send back a header you gave it,
 * so that header is the whole proof, and it is compared in constant time
 * against the secret: a comparison that returns early leaks the answer one
 * character at a time to anyone patient enough to measure.
 */
export const revenueCatWebhook = onRequest(
  { secrets: [REVENUECAT_WEBHOOK_AUTH] },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("POST only");
      return;
    }
    const want = REVENUECAT_WEBHOOK_AUTH.value();
    const got = String(req.headers.authorization ?? "");
    if (!want || !safeEqual(got, want)) {
      logger.warn("revenuecat webhook rejected");
      res.status(401).send("no");
      return;
    }

    const event = req.body?.event;
    if (!event?.id) {
      res.status(400).send("no event");
      return;
    }

    const firestore = db();
    const events = firestore.collection("revenuecat_events");
    const entitlements = firestore.collection("entitlements");

    try {
      // RevenueCat retries until it is answered 2xx, and a retried refund
      // must not revoke twice any more than a retried purchase grants twice.
      if ((await events.doc(event.id).get()).exists) {
        res.status(200).json({ received: true, outcome: "duplicate" });
        return;
      }

      const d = decideFromRcEvent(event);
      if (d.outcome === "grant") {
        await entitlements.doc(d.uid).set(d.doc, { merge: false });
        for (const old of d.revokeFrom) {
          await entitlements
            .doc(old)
            .set({ pro: false, revokedAt: d.doc.grantedAt, revokedReason: "transferred" }, { merge: true });
        }
      } else if (d.outcome === "revoke") {
        await entitlements
          .doc(d.uid)
          .set({ pro: false, revokedAt: d.at, revokedReason: d.reason }, { merge: true });
      }

      await events.doc(event.id).set({
        type: event.type ?? null,
        outcome: d.outcome,
        uid: d.uid ?? null,
        receivedAt: FieldValue.serverTimestamp(),
      });
      logger.info("revenuecat webhook", { id: event.id, type: event.type, outcome: d.outcome });
      res.status(200).json({ received: true, outcome: d.outcome });
    } catch (e) {
      // 5xx makes RevenueCat retry, which is what a Firestore hiccup wants.
      logger.error("revenuecat webhook failed", { id: event.id, error: String(e?.stack ?? e) });
      res.status(500).send("try again");
    }
  }
);

/** Compares without letting the clock say how much of it matched. */
function safeEqual(a, b) {
  const x = Buffer.from(String(a));
  const y = Buffer.from(String(b));
  if (x.length !== y.length) {
    // Still compare something, so a wrong length is not the fast case.
    timingSafeEqual(x, x);
    return false;
  }
  return timingSafeEqual(x, y);
}

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
