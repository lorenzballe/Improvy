import { test } from "node:test";
import assert from "node:assert/strict";
import { normalizeCode, discountedAmount, couponOf } from "../lib/promo.js";

test("codes are read the way people type them", () => {
  assert.equal(normalizeCode(" marco10 "), "MARCO10");
  assert.equal(normalizeCode("piano-tips10"), "PIANO-TIPS10");
  for (const bad of [null, 3, "", "ab", "has space!", "-X10", "<b>"]) assert.equal(normalizeCode(bad), null, String(bad));
});

test("10% off 18,99 € is 17,09 €, rounded as Stripe rounds", () => {
  assert.equal(discountedAmount(1899, { percent_off: 10 }), 1709);
  assert.equal(discountedAmount(1899, { percent_off: 15 }), 1614);
  assert.equal(discountedAmount(1899, { amount_off: 200 }), 1699);
  assert.equal(discountedAmount(1899, null), 1899);
  assert.equal(discountedAmount(1899, { amount_off: 5000 }), 0);
});

test("the coupon is found in either API shape", () => {
  assert.deepEqual(couponOf({ coupon: { id: "a" } }), { id: "a" });
  assert.equal(couponOf({ promotion: { type: "coupon", coupon: "creator-10" } }), "creator-10");
  assert.equal(couponOf({}), null);
});
