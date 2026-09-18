/**
 * The decisions, kept apart from Stripe and Firestore so they can be run
 * without either.
 *
 * A Pro licence bought on the website is one document, entitlements/{uid},
 * written only from here. The app reads it on sign-in and treats it exactly
 * like a store purchase or a promo code: a third door to the same room.
 *
 * Every event is applied at most once. Stripe retries a webhook until it is
 * answered 2xx, and a retry of a refund must not revoke twice any more than a
 * retry of a payment must grant twice — harmless here, but the record of
 * what happened has to stay true.
 */

/** Stripe's own reasons a completed session is not yet paid. */
const PAID = "paid";

/**
 * What entitlements/{uid} looks like after a paid Checkout Session.
 * Returns null for a session that does not carry an account, which the
 * checkout function never creates but a hand-made payment link could.
 */
export function entitlementFromSession(session, { now = () => new Date() } = {}) {
  const uid = session.client_reference_id || session.metadata?.uid || null;
  if (!uid) return null;
  const email =
    session.customer_details?.email || session.customer_email || session.metadata?.email || null;
  return {
    uid,
    doc: {
      pro: true,
      source: "stripe",
      email: email ? email.toLowerCase() : null,
      sessionId: session.id,
      paymentIntent: typeof session.payment_intent === "string" ? session.payment_intent : session.payment_intent?.id || null,
      amountTotal: session.amount_total ?? null,
      currency: session.currency ?? null,
      livemode: session.livemode === true,
      grantedAt: now(),
      revokedAt: null,
      revokedReason: null,
    },
  };
}

/**
 * What to do when the buyer comes back from Stripe carrying a session id.
 *
 * The webhook is the way a licence is normally written, and it is the only
 * one that can be trusted on its own — but it is also the part most likely
 * to be missing on the first day: a wrong endpoint, a secret not yet in
 * Secret Manager, an event type left unticked. Meanwhile somebody has paid
 * and is looking at a page that says "waiting".
 *
 * So the success page asks the server to look. The server retrieves the
 * session from Stripe — not from the browser — and grants only what Stripe
 * itself says was paid, to the account the session was opened for. The
 * client supplies an id and nothing else, and an id for somebody else's
 * checkout is refused.
 *
 * [existing] is entitlements/{uid} as it stands, so the decision is the same
 * whichever of the two paths gets there first:
 *
 *   granted    Stripe says paid, nothing was written yet — write it
 *   already    the webhook beat us to it, or this is a second visit
 *   revoked    this very purchase was refunded or charged back; do not undo
 *              that because the buyer reloaded an old success URL
 *   not-paid   a delayed method (SEPA) that has not cleared
 */
export function confirmDecision({ session, uid, existing, now = () => new Date() }) {
  const owner = session?.client_reference_id || session?.metadata?.uid || null;
  if (!owner) return { outcome: "no-account" };
  if (owner !== uid) return { outcome: "wrong-account" };
  if (session.payment_status !== PAID) return { outcome: "not-paid" };

  // A refund wrote pro:false on this same purchase. Re-granting from a stale
  // success URL would hand the licence back for money that went home.
  if (existing?.revokedAt && existing?.sessionId === session.id) {
    return { outcome: "revoked" };
  }
  if (existing?.pro === true && !existing?.revokedAt) return { outcome: "already" };

  const ent = entitlementFromSession(session, { now });
  return ent ? { outcome: "granted", doc: ent.doc } : { outcome: "no-account" };
}

/**
 * Applies one Stripe event to the store. The store is four functions so a
 * test can hand in a Map:
 *
 *   seen(eventId) -> bool           has this event been applied before
 *   remember(eventId, summary)      record that it has
 *   grant(uid, doc)                 write entitlements/{uid}
 *   revokeByPaymentIntent(pi, why)  flip pro to false on the matching doc(s)
 *
 * Returns a short word saying what happened, for the log line.
 */
export async function applyStripeEvent(event, store, { now = () => new Date() } = {}) {
  if (await store.seen(event.id)) return "duplicate";

  switch (event.type) {
    case "checkout.session.completed":
    case "checkout.session.async_payment_succeeded": {
      const session = event.data.object;
      // A completed session with a delayed payment method (SEPA, for one) is
      // "unpaid" until async_payment_succeeded arrives; granting on the first
      // event would hand out Pro for money that may never come.
      if (session.payment_status !== PAID) {
        await store.remember(event.id, { type: event.type, outcome: "not-paid-yet" });
        return "not-paid-yet";
      }
      const ent = entitlementFromSession(session, { now });
      if (!ent) {
        await store.remember(event.id, { type: event.type, outcome: "no-account" });
        return "no-account";
      }
      await store.grant(ent.uid, ent.doc);
      await store.remember(event.id, { type: event.type, outcome: "granted", uid: ent.uid });
      return "granted";
    }

    case "checkout.session.async_payment_failed": {
      // Nothing was granted (see above), so nothing to take back.
      await store.remember(event.id, { type: event.type, outcome: "ignored" });
      return "ignored";
    }

    case "charge.refunded": {
      const charge = event.data.object;
      // Partial refunds keep the licence: a goodwill partial refund is not a
      // return. Only money fully given back takes Pro with it.
      const full = charge.refunded === true || (charge.amount_refunded ?? 0) >= (charge.amount ?? 0);
      const pi = typeof charge.payment_intent === "string" ? charge.payment_intent : charge.payment_intent?.id;
      if (!full || !pi) {
        await store.remember(event.id, { type: event.type, outcome: "partial-or-unlinked" });
        return "partial-or-unlinked";
      }
      const n = await store.revokeByPaymentIntent(pi, { reason: "refunded", at: now() });
      await store.remember(event.id, { type: event.type, outcome: n > 0 ? "revoked" : "nothing-to-revoke", paymentIntent: pi });
      return n > 0 ? "revoked" : "nothing-to-revoke";
    }

    case "charge.dispute.created": {
      // A chargeback is a refund the buyer took rather than asked for. Same
      // outcome for the licence, and the Stripe dashboard is where to argue.
      const dispute = event.data.object;
      const pi = typeof dispute.payment_intent === "string" ? dispute.payment_intent : dispute.payment_intent?.id;
      if (!pi) {
        await store.remember(event.id, { type: event.type, outcome: "unlinked" });
        return "unlinked";
      }
      const n = await store.revokeByPaymentIntent(pi, { reason: "disputed", at: now() });
      await store.remember(event.id, { type: event.type, outcome: n > 0 ? "revoked" : "nothing-to-revoke", paymentIntent: pi });
      return n > 0 ? "revoked" : "nothing-to-revoke";
    }

    default:
      // Everything else Stripe might be configured to send. Recorded so a
      // retry is cheap, and so the log says it arrived.
      await store.remember(event.id, { type: event.type, outcome: "unhandled" });
      return "unhandled";
  }
}

/**
 * Whether the person holding this token is Pro by a website purchase.
 *
 * By account id first. Then, only for a verified address, by email: the
 * same human can sign in with Google on the site and Apple in the app and be
 * two accounts, and the address is what they share. Unverified addresses
 * are not consulted — anyone can create a password account with someone
 * else's email, and that must not become someone else's licence.
 */
export function proFromLookups({ byUid, byEmail, emailVerified }) {
  const live = (d) => d && d.pro === true && !d.revokedAt;
  if (live(byUid)) return { pro: true, via: "uid", doc: byUid };
  if (emailVerified && live(byEmail)) return { pro: true, via: "email", doc: byEmail };
  return { pro: false, via: null, doc: null };
}
