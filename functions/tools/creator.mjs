/**
 * Everything a new creator needs, in one run — see .github/workflows/creator.yml.
 *
 *   node tools/creator.mjs <slug> [percentOff] [freeCodes]
 *
 * 1. A Stripe promotion code for their audience (MARCO10 → 10% off on the
 *    site), on a shared coupon created the first time.
 * 2. A free-Pro promo code for the app (MARCO-PRO), in Firestore, with a use
 *    limit — for the creator and anyone they want to hand it to.
 * 3. Their affiliate link, improvy.app/?ref=marco.
 *
 * Idempotent: run it twice for the same creator and nothing is duplicated —
 * existing codes are reported, not recreated. Reads STRIPE_SECRET_KEY and the
 * Google credentials from the environment; prints no secret.
 */
import Stripe from "stripe";
import { initializeApp, applicationDefault } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { appendFileSync } from "node:fs";

const [slugRaw, pctRaw = "10", freeRaw = "1"] = process.argv.slice(2);
const slug = String(slugRaw ?? "").trim().toLowerCase();
// Narrower than the site's ref shape on purpose: the slug becomes both codes,
// and the app's code format allows no underscore.
if (!/^[a-z0-9][a-z0-9-]{1,20}[a-z0-9]$/.test(slug)) {
  console.log(`::error::"${slugRaw}" is not a usable creator name — 3 to 22 letters, digits or hyphens, e.g. marco or piano-tips.`);
  process.exit(1);
}
const pct = Number(pctRaw);
if (!Number.isInteger(pct) || pct < 1 || pct > 50) {
  console.log(`::error::discount must be a whole number between 1 and 50, not "${pctRaw}".`);
  process.exit(1);
}
const free = Number(freeRaw);
if (!Number.isInteger(free) || free < 0 || free > 100) {
  console.log(`::error::free Pro codes must be between 0 and 100, not "${freeRaw}".`);
  process.exit(1);
}
if (!process.env.STRIPE_SECRET_KEY) {
  console.log("::error::STRIPE_SECRET_KEY is not set.");
  process.exit(1);
}

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);
const compact = slug.replace(/-/g, "").toUpperCase();
const discountCode = `${compact}${pct}`;
const proCode = `${slug.toUpperCase()}-PRO`;
const link = `https://improvy.app/?ref=${slug}`;

// ── Stripe: one coupon per percentage, shared by every creator ──
const couponId = `creator-${pct}`;
let coupon;
try {
  coupon = await stripe.coupons.retrieve(couponId);
} catch {
  coupon = await stripe.coupons.create({
    id: couponId,
    percent_off: pct,
    duration: "once",
    name: `Creator ${pct}% off`,
  });
}
const existing = await stripe.promotionCodes.list({ code: discountCode, limit: 1 });
let promo = existing.data[0];
const promoNew = !promo;
if (!promo) {
  promo = await stripe.promotionCodes.create({
    promotion: { type: "coupon", coupon: coupon.id },
    code: discountCode,
    metadata: { ref: slug },
  }).catch(async (e) => {
    // Older API shape: coupon at the top level.
    if (String(e?.message ?? "").includes("promotion")) {
      return stripe.promotionCodes.create({ coupon: coupon.id, code: discountCode, metadata: { ref: slug } });
    }
    throw e;
  });
}

// ── Firestore: the same discount code, recognised by the app ──
initializeApp({ credential: applicationDefault() });
const db = getFirestore();
await db.collection("creators").doc(discountCode).set(
  { active: true, ref: slug, pct, updatedAt: FieldValue.serverTimestamp() },
  { merge: true },
);

// ── Firestore: the free-Pro code the app redeems ──
let proNote = "skipped (0 requested)";
if (free > 0) {
  const ref = db.collection("codes").doc(proCode);
  const snap = await ref.get();
  if (snap.exists) {
    const d = snap.data();
    proNote = `already existed — ${d.uses ?? 0}/${d.maxUses ?? "?"} used`;
  } else {
    await ref.set({
      active: true,
      maxUses: free,
      uses: 0,
      note: `creator: ${slug}`,
      createdAt: FieldValue.serverTimestamp(),
    });
    proNote = `created — ${free} use${free === 1 ? "" : "s"}`;
  }
}

const mode = String(process.env.STRIPE_SECRET_KEY).startsWith("sk_live") ? "LIVE" : "TEST";
const summary = [
  `## Creator: ${slug}`,
  "",
  `| | |`,
  `|---|---|`,
  `| Affiliate link | ${link} |`,
  `| Discount for their audience | **${discountCode}** — ${pct}% off · on the site (Stripe ${mode}, ${promoNew ? "created" : "already existed"}) and in the app (Settings → Have a code?) |`,
  `| Free Pro in the app (Settings → Promo code) | **${proCode}** · ${proNote} |`,
  "",
  `Sales from the link show in Stripe → Payments with metadata ref = ${slug}; uses of ${discountCode} show under Products → Coupons → ${couponId}.`,
].join("\n");
console.log(summary);
if (process.env.GITHUB_STEP_SUMMARY) appendFileSync(process.env.GITHUB_STEP_SUMMARY, summary + "\n");
