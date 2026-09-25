/**
 * Discount codes on the website — the same codes a creator gives out
 * (MARCO10), which the app also recognises. Pure parts only, so they can be
 * tested without Stripe.
 */

/** "marco10 " → "MARCO10"; anything that cannot be a code → null. */
export function normalizeCode(value) {
  if (typeof value !== "string") return null;
  const v = value.trim().toUpperCase().replace(/\s+/g, "");
  return /^[A-Z0-9][A-Z0-9-]{2,30}[A-Z0-9]$/.test(v) ? v : null;
}

/**
 * The price after a coupon, in cents, computed the way Stripe computes it:
 * the discount is rounded to the cent, then subtracted. So the figure the
 * site shows before paying is the figure on the Stripe page and the receipt.
 */
export function discountedAmount(amount, coupon) {
  if (!coupon) return amount;
  if (typeof coupon.percent_off === "number" && coupon.percent_off > 0) {
    return Math.max(0, amount - Math.round((amount * coupon.percent_off) / 100));
  }
  if (typeof coupon.amount_off === "number" && coupon.amount_off > 0) {
    return Math.max(0, amount - coupon.amount_off);
  }
  return amount;
}

/**
 * The coupon inside a promotion code, whichever shape the API version
 * returns: `coupon` on older versions, `promotion.coupon` on newer ones —
 * either an object or just its id.
 */
export function couponOf(promo) {
  return promo?.coupon ?? promo?.promotion?.coupon ?? null;
}
