import { test } from "node:test";
import assert from "node:assert/strict";
import { applyStripeEvent, entitlementFromSession, proFromLookups } from "../lib/entitlements.js";

/** A store that is four Maps, so every decision can be read back. */
function fakeStore() {
  const events = new Map();
  const ents = new Map();
  return {
    events,
    ents,
    seen: async (id) => events.has(id),
    remember: async (id, s) => void events.set(id, s),
    grant: async (uid, doc) => void ents.set(uid, doc),
    revokeByPaymentIntent: async (pi, { reason, at }) => {
      let n = 0;
      for (const [uid, d] of ents) {
        if (d.paymentIntent === pi) {
          ents.set(uid, { ...d, pro: false, revokedAt: at, revokedReason: reason });
          n++;
        }
      }
      return n;
    },
  };
}

const NOW = new Date("2026-09-13T10:00:00Z");
const now = () => NOW;

const paidSession = (over = {}) => ({
  id: "cs_1",
  client_reference_id: "uid_alice",
  customer_details: { email: "Alice@Example.com" },
  payment_status: "paid",
  payment_intent: "pi_1",
  amount_total: 1999,
  currency: "eur",
  livemode: true,
  metadata: { uid: "uid_alice" },
  ...over,
});

const evt = (id, type, object, livemode = true) => ({ id, type, livemode, data: { object } });

test("a paid checkout becomes a licence on the account it names", async () => {
  const s = fakeStore();
  const out = await applyStripeEvent(evt("evt_1", "checkout.session.completed", paidSession()), s, { now });
  assert.equal(out, "granted");
  const doc = s.ents.get("uid_alice");
  assert.equal(doc.pro, true);
  assert.equal(doc.source, "stripe");
  assert.equal(doc.email, "alice@example.com", "lower-cased, so an email lookup matches");
  assert.equal(doc.paymentIntent, "pi_1");
  assert.equal(doc.amountTotal, 1999);
  assert.equal(doc.grantedAt, NOW);
  assert.equal(doc.revokedAt, null);
});

test("the same event twice grants once", async () => {
  const s = fakeStore();
  await applyStripeEvent(evt("evt_1", "checkout.session.completed", paidSession()), s, { now });
  const again = await applyStripeEvent(evt("evt_1", "checkout.session.completed", paidSession()), s, { now });
  assert.equal(again, "duplicate");
  assert.equal(s.ents.size, 1);
});

test("a completed session that is not paid yet grants nothing", async () => {
  // SEPA and friends: completed now, paid in a few days, or never.
  const s = fakeStore();
  const out = await applyStripeEvent(
    evt("evt_2", "checkout.session.completed", paidSession({ payment_status: "unpaid" })),
    s,
    { now }
  );
  assert.equal(out, "not-paid-yet");
  assert.equal(s.ents.size, 0);
  // …and the later success event is what grants.
  const later = await applyStripeEvent(
    evt("evt_3", "checkout.session.async_payment_succeeded", paidSession()),
    s,
    { now }
  );
  assert.equal(later, "granted");
});

test("a session with no account attached is refused, not guessed", async () => {
  const s = fakeStore();
  const out = await applyStripeEvent(
    evt("evt_4", "checkout.session.completed", paidSession({ client_reference_id: null, metadata: {} })),
    s,
    { now }
  );
  assert.equal(out, "no-account");
  assert.equal(s.ents.size, 0);
});

test("a full refund takes the licence back; a partial one does not", async () => {
  const s = fakeStore();
  await applyStripeEvent(evt("evt_1", "checkout.session.completed", paidSession()), s, { now });

  const partial = await applyStripeEvent(
    evt("evt_5", "charge.refunded", { payment_intent: "pi_1", amount: 1999, amount_refunded: 500, refunded: false }),
    s,
    { now }
  );
  assert.equal(partial, "partial-or-unlinked");
  assert.equal(s.ents.get("uid_alice").pro, true);

  const full = await applyStripeEvent(
    evt("evt_6", "charge.refunded", { payment_intent: "pi_1", amount: 1999, amount_refunded: 1999, refunded: true }),
    s,
    { now }
  );
  assert.equal(full, "revoked");
  const doc = s.ents.get("uid_alice");
  assert.equal(doc.pro, false);
  assert.equal(doc.revokedReason, "refunded");
  assert.equal(doc.revokedAt, NOW);
});

test("a chargeback revokes like a refund", async () => {
  const s = fakeStore();
  await applyStripeEvent(evt("evt_1", "checkout.session.completed", paidSession()), s, { now });
  const out = await applyStripeEvent(evt("evt_7", "charge.dispute.created", { payment_intent: "pi_1" }), s, { now });
  assert.equal(out, "revoked");
  assert.equal(s.ents.get("uid_alice").revokedReason, "disputed");
});

test("a refund for a payment we never granted is recorded and harmless", async () => {
  const s = fakeStore();
  const out = await applyStripeEvent(
    evt("evt_8", "charge.refunded", { payment_intent: "pi_other", amount: 1, amount_refunded: 1, refunded: true }),
    s,
    { now }
  );
  assert.equal(out, "nothing-to-revoke");
  assert.ok(s.events.has("evt_8"));
});

test("an event type we do not handle is remembered and answered", async () => {
  const s = fakeStore();
  const out = await applyStripeEvent(evt("evt_9", "payment_intent.created", {}), s, { now });
  assert.equal(out, "unhandled");
  assert.ok(s.events.has("evt_9"));
});

test("entitlementFromSession prefers the buyer's confirmed address", () => {
  const e = entitlementFromSession(
    paidSession({ customer_details: { email: "Real@x.com" }, customer_email: "typed@x.com" }),
    { now }
  );
  assert.equal(e.doc.email, "real@x.com");
});

test("who is Pro: by account first, by verified email second, never by an unverified one", () => {
  const live = { pro: true, revokedAt: null };
  const dead = { pro: false, revokedAt: NOW };
  assert.equal(proFromLookups({ byUid: live, byEmail: null, emailVerified: false }).via, "uid");
  assert.equal(proFromLookups({ byUid: null, byEmail: live, emailVerified: true }).via, "email");
  assert.equal(proFromLookups({ byUid: null, byEmail: live, emailVerified: false }).pro, false,
    "anyone can make a password account with someone else's address");
  assert.equal(proFromLookups({ byUid: dead, byEmail: null, emailVerified: true }).pro, false,
    "a revoked licence is not a licence");
  assert.equal(proFromLookups({ byUid: null, byEmail: null, emailVerified: true }).pro, false);
});
