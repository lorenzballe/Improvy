/**
 * What a RevenueCat event means for a licence.
 *
 * A purchase made in the app lives in RevenueCat and nowhere else: the
 * receipt goes to Apple or Google, RevenueCat records it, and Firestore
 * never hears about it. That is why the website could offer Pro to somebody
 * who had already bought it — it was looking in the only place that did not
 * know.
 *
 * With this, both doors write to the same page. entitlements/{uid} becomes
 * the answer to "is this account Pro", whoever took the money.
 *
 * Kept apart from Firestore and from the network so every decision can be
 * read without either.
 */

/** RevenueCat's id for a customer who has never signed in. */
const ANONYMOUS = "$RCAnonymousID:";

/**
 * A Firebase uid, as far as this is concerned: 20 to 128 characters of the
 * alphabet Firebase uses. Anything else — an anonymous RevenueCat id, an
 * email somebody typed into a dashboard — is not an account we can write to,
 * and writing to a guessed one would hand a licence to a stranger.
 */
export function isAccountId(id) {
  return typeof id === "string" && /^[A-Za-z0-9]{20,128}$/.test(id);
}

/** The event types that mean "this customer now has it". */
const GRANTS = new Set([
  "INITIAL_PURCHASE",
  "NON_RENEWING_PURCHASE",
  "RENEWAL",
  "UNCANCELLATION",
  "PRODUCT_CHANGE",
  "SUBSCRIPTION_EXTENDED",
  "TEMPORARY_ENTITLEMENT_GRANT",
]);

/**
 * And the ones that mean "not any more".
 *
 * CANCELLATION is deliberately not here: on RevenueCat it means the customer
 * turned off renewal, and they keep what they paid for until it runs out.
 * EXPIRATION is the event for when it actually has. REFUND and
 * SUBSCRIPTION_PAUSED do take it away now.
 */
const REVOKES = new Set(["EXPIRATION", "REFUND", "SUBSCRIPTION_PAUSED"]);

/** The address RevenueCat carries for this customer, if the app set one. */
function emailOf(event) {
  const raw = event?.subscriber_attributes?.$email?.value;
  return typeof raw === "string" && raw.includes("@") ? raw.trim().toLowerCase() : null;
}

/**
 * Whether the event says this customer holds [entitlement] right now.
 *
 * RevenueCat names the entitlements an event touches; an event about some
 * other product must not move this one. When it names none — which older
 * event shapes do — the type alone decides, because the project sells one
 * thing and any purchase of it is that thing.
 */
function touchesEntitlement(event, entitlement) {
  const ids = event?.entitlement_ids;
  if (!Array.isArray(ids)) {
    return typeof event?.entitlement_id === "string"
      ? event.entitlement_id === entitlement
      : true;
  }
  return ids.includes(entitlement);
}

/**
 * What to do with one event. Returns a verb and, when there is something to
 * write, the document to write.
 *
 *   grant        write entitlements/{uid}, this account has Pro
 *   revoke       flip it to false: refunded, expired, or charged back
 *   no-account   a purchase with nobody to attach it to (never signed in),
 *                or an id that is not an account. Valid in the app, invisible
 *                to the website, and there is no honest way around that.
 *   other-product / ignored / unknown-event
 */
export function decideFromRcEvent(event, { entitlement = "pro", now = () => new Date() } = {}) {
  const type = event?.type;
  if (!type) return { outcome: "ignored" };

  const grants = GRANTS.has(type);
  const revokes = REVOKES.has(type);
  // A transfer is the anonymous purchase finally finding its account, which
  // is exactly the moment the website needs to learn about it.
  const transfer = type === "TRANSFER";
  if (!grants && !revokes && !transfer) return { outcome: "unknown-event", type };

  if (!touchesEntitlement(event, entitlement)) return { outcome: "other-product" };

  // On a transfer the licence moves to whoever it moved to, and away from
  // whoever it left. RevenueCat names both sides.
  const uid = transfer
    ? (event.transferred_to || []).find(isAccountId) || null
    : event.app_user_id;

  if (!isAccountId(uid)) {
    return { outcome: "no-account", anonymous: String(uid || "").startsWith(ANONYMOUS) };
  }

  if (revokes) {
    return {
      outcome: "revoke",
      uid,
      reason: type === "REFUND" ? "refunded" : type.toLowerCase(),
      at: now(),
    };
  }

  return {
    outcome: "grant",
    uid,
    doc: {
      pro: true,
      source: "store",
      email: emailOf(event),
      store: event.store ?? null,
      productId: event.product_id ?? null,
      transactionId: event.transaction_id ?? event.original_transaction_id ?? null,
      // Sandbox purchases are real events with fake money. Recorded as such,
      // so a test can be told apart from a customer at a glance.
      livemode: event.environment === "PRODUCTION",
      grantedAt: now(),
      revokedAt: null,
      revokedReason: null,
    },
    // Everyone the licence just left, on a transfer.
    revokeFrom: transfer ? (event.transferred_from || []).filter(isAccountId) : [],
  };
}
