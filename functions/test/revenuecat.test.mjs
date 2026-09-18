import { test } from "node:test";
import assert from "node:assert/strict";

import { decideFromRcEvent, isAccountId } from "../lib/revenuecat.js";

const UID = "aBcDeF1234567890GhIjKlMn";
const OTHER = "zZyYxX1234567890WwVvUuTt";

const ev = (over = {}) => ({
  type: "INITIAL_PURCHASE",
  app_user_id: UID,
  entitlement_ids: ["pro"],
  environment: "PRODUCTION",
  store: "APP_STORE",
  product_id: "improvy_pro_lifetime",
  transaction_id: "100001",
  subscriber_attributes: { $email: { value: "Mario@Example.com" } },
  ...over,
});

test("a purchase in the app becomes a licence on the account", () => {
  const d = decideFromRcEvent(ev());
  assert.equal(d.outcome, "grant");
  assert.equal(d.uid, UID);
  assert.equal(d.doc.pro, true);
  assert.equal(d.doc.source, "store");
  assert.equal(d.doc.email, "mario@example.com");
  assert.equal(d.doc.livemode, true);
});

test("a sandbox purchase is recorded, and marked as one", () => {
  const d = decideFromRcEvent(ev({ environment: "SANDBOX" }));
  assert.equal(d.outcome, "grant");
  assert.equal(d.doc.livemode, false);
});

test("a purchase by somebody who never signed in has no account to go to", () => {
  const d = decideFromRcEvent(ev({ app_user_id: "$RCAnonymousID:9f8e7d" }));
  assert.equal(d.outcome, "no-account");
  assert.equal(d.anonymous, true);
});

test("an id that is not an account id is refused, not guessed at", () => {
  for (const bad of ["", "short", "mario@example.com", "../../etc/passwd", null, 42]) {
    assert.equal(decideFromRcEvent(ev({ app_user_id: bad })).outcome, "no-account", String(bad));
  }
  assert.equal(isAccountId(UID), true);
});

test("an event about another product leaves this licence alone", () => {
  assert.equal(decideFromRcEvent(ev({ entitlement_ids: ["something_else"] })).outcome, "other-product");
  assert.equal(decideFromRcEvent(ev({ entitlement_ids: [] })).outcome, "other-product");
});

test("a refund takes it back", () => {
  const d = decideFromRcEvent(ev({ type: "REFUND" }));
  assert.equal(d.outcome, "revoke");
  assert.equal(d.uid, UID);
  assert.equal(d.reason, "refunded");
});

test("turning off renewal does not take away what was paid for", () => {
  // CANCELLATION on RevenueCat means "will not renew", not "gone now".
  assert.equal(decideFromRcEvent(ev({ type: "CANCELLATION" })).outcome, "unknown-event");
  // EXPIRATION is the event for when it actually has run out.
  assert.equal(decideFromRcEvent(ev({ type: "EXPIRATION" })).outcome, "revoke");
});

test("a transfer follows the licence to its new account, and off the old one", () => {
  const d = decideFromRcEvent(
    ev({
      type: "TRANSFER",
      app_user_id: undefined,
      transferred_from: ["$RCAnonymousID:9f8e7d", OTHER],
      transferred_to: [UID],
    })
  );
  assert.equal(d.outcome, "grant");
  assert.equal(d.uid, UID);
  // Only the real account is revoked from; the anonymous id was never written.
  assert.deepEqual(d.revokeFrom, [OTHER]);
});

test("an event type nobody has taught it about changes nothing", () => {
  assert.equal(decideFromRcEvent(ev({ type: "BILLING_ISSUE" })).outcome, "unknown-event");
  assert.equal(decideFromRcEvent({}).outcome, "ignored");
});

test("no email attribute is null, not an empty string", () => {
  assert.equal(decideFromRcEvent(ev({ subscriber_attributes: {} })).doc.email, null);
  assert.equal(
    decideFromRcEvent(ev({ subscriber_attributes: { $email: { value: "not-an-address" } } })).doc.email,
    null
  );
});
