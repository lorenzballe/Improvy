/**
 * The App Review demo account — see .github/workflows/review-account.yml.
 *
 *   REVIEW_PASSWORD=… node tools/review-account.mjs <email>
 *
 * Creates the email-and-password account (or resets its password if it
 * already exists), marks the address verified, and writes a Pro licence on
 * entitlements/{uid}. The app reads that licence at sign-in exactly like a
 * website purchase, so signing in with these credentials unlocks Pro with no
 * build and no special case in the app.
 *
 * Signing out again leaves the device free, so a reviewer can still walk the
 * store purchase from the paywall. Idempotent. Prints no password.
 */
import { initializeApp, applicationDefault } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { appendFileSync } from "node:fs";

const email = String(process.argv[2] ?? "").trim().toLowerCase();
const password = process.env.REVIEW_PASSWORD ?? "";
if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) {
  console.log(`::error::"${email}" is not an email address.`);
  process.exit(1);
}
if (password.length < 10) {
  console.log("::error::REVIEW_PASSWORD must be at least 10 characters.");
  process.exit(1);
}

initializeApp({ credential: applicationDefault(), projectId: process.env.GOOGLE_CLOUD_PROJECT });
const auth = getAuth();

let user;
try {
  user = await auth.getUserByEmail(email);
  user = await auth.updateUser(user.uid, { password, emailVerified: true, disabled: false });
  console.log(`Updated ${email} (${user.uid}).`);
} catch (e) {
  if (e?.code !== "auth/user-not-found") throw e;
  user = await auth.createUser({ email, password, emailVerified: true, displayName: "App Review" });
  console.log(`Created ${email} (${user.uid}).`);
}

await getFirestore().collection("entitlements").doc(user.uid).set({
  pro: true,
  source: "review",
  email,
  grantedAt: FieldValue.serverTimestamp(),
}, { merge: false });
console.log("Pro granted on entitlements/" + user.uid);

if (process.env.GITHUB_STEP_SUMMARY) {
  appendFileSync(process.env.GITHUB_STEP_SUMMARY,
    `### Review account ready\n\n- Email: \`${email}\`\n- Pro: granted\n- Password: the one passed to this run\n`);
}
