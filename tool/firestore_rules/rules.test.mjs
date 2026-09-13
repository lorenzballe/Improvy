// firestore.rules against the emulator. Run from this directory:
//
//   npm install && npm test
//
// Every "no" here is a hole the rules close: without the server, the rules
// are the only thing between a curious person with the project ID and free
// Pro for everyone.
import { test, before, after, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';
import {
  doc, getDoc, setDoc, updateDoc, deleteDoc, getDocs, collection,
  writeBatch, increment, serverTimestamp, Timestamp,
} from 'firebase/firestore';

let env;
const PROJECT = 'improvy-rules-test';

before(async () => {
  env = await initializeTestEnvironment({
    projectId: PROJECT,
    firestore: { rules: readFileSync('../../firestore.rules', 'utf8'), host: '127.0.0.1', port: 8080 },
  });
});
after(async () => env.cleanup());

const live = { active: true, maxUses: 2, uses: 0, note: 'test' };
const seed = async (codes) => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    for (const [id, data] of Object.entries(codes)) {
      await setDoc(doc(ctx.firestore(), 'codes', id), data);
    }
  });
};
beforeEach(() => seed({ LIVE: live }));

const alice = () => env.authenticatedContext('alice').firestore();
const bob = () => env.authenticatedContext('bob').firestore();
const nobody = () => env.unauthenticatedContext().firestore();
// The same human on another phone: a different uid, the same address.
const aliceElsewhere = (verified) =>
  env.authenticatedContext('alice2', { email: 'alice@example.com', email_verified: verified }).firestore();

/** What the app does: +1 and a redemption, in one batch. */
function redeem(db, uid, code) {
  const b = writeBatch(db);
  b.update(doc(db, 'codes', code), { uses: increment(1) });
  b.set(doc(db, 'redemptions', uid), { code, at: serverTimestamp() });
  return b.commit();
}

test('a signed-in person can look a code up by name', async () => {
  await assertSucceeds(getDoc(doc(alice(), 'codes', 'LIVE')));
});

test('nobody can list the codes', async () => {
  await assertFails(getDocs(collection(alice(), 'codes')));
});

test('signed out, nothing', async () => {
  await assertFails(getDoc(doc(nobody(), 'codes', 'LIVE')));
  await assertFails(redeem(nobody(), 'ghost', 'LIVE'));
});

test('the app\'s redemption batch is accepted, once', async () => {
  await assertSucceeds(redeem(alice(), 'alice', 'LIVE'));
  await assertSucceeds(getDoc(doc(alice(), 'redemptions', 'alice')));
  // Same person again: the redemption exists, create is refused.
  await assertFails(redeem(alice(), 'alice', 'LIVE'));
});

test('the counter cannot be moved on its own', async () => {
  await assertFails(updateDoc(doc(alice(), 'codes', 'LIVE'), { uses: increment(1) }));
  await assertFails(updateDoc(doc(alice(), 'codes', 'LIVE'), { uses: increment(-1) }));
  await assertFails(updateDoc(doc(alice(), 'codes', 'LIVE'), { maxUses: 1000 }));
  await assertFails(updateDoc(doc(alice(), 'codes', 'LIVE'), { active: false }));
});

test('a redemption cannot be written on its own', async () => {
  await assertFails(setDoc(doc(alice(), 'redemptions', 'alice'), { code: 'LIVE', at: serverTimestamp() }));
});

test('a redemption cannot be written for someone else', async () => {
  await assertFails(redeem(alice(), 'bob', 'LIVE'));
});

test('the redemption must carry the server clock and nothing extra', async () => {
  const db = alice();
  const b = writeBatch(db);
  b.update(doc(db, 'codes', 'LIVE'), { uses: increment(1) });
  b.set(doc(db, 'redemptions', 'alice'), { code: 'LIVE', at: Timestamp.fromDate(new Date(2020, 0, 1)) });
  await assertFails(b.commit());
  const c = writeBatch(db);
  c.update(doc(db, 'codes', 'LIVE'), { uses: increment(1) });
  c.set(doc(db, 'redemptions', 'alice'), { code: 'LIVE', at: serverTimestamp(), pro: true });
  await assertFails(c.commit());
});

test('an unknown, inactive, exhausted or expired code is refused', async () => {
  await seed({
    OFF: { ...live, active: false },
    GONE: { ...live, uses: 2 },
    OLD: { ...live, expiresAt: Timestamp.fromDate(new Date(2020, 0, 1)) },
    SOON: { ...live, expiresAt: Timestamp.fromDate(new Date(Date.now() + 86_400_000)) },
  });
  await assertFails(redeem(alice(), 'alice', 'NOPE'));
  await assertFails(redeem(alice(), 'alice', 'OFF'));
  await assertFails(redeem(alice(), 'alice', 'GONE'));
  await assertFails(redeem(alice(), 'alice', 'OLD'));
  await assertSucceeds(redeem(alice(), 'alice', 'SOON'));
});

test('the last use goes to whoever gets there first', async () => {
  await seed({ ONE: { ...live, maxUses: 1 } });
  await assertSucceeds(redeem(alice(), 'alice', 'ONE'));
  await assertFails(redeem(bob(), 'bob', 'ONE'));
});

test('codes cannot be created or deleted from the app', async () => {
  await assertFails(setDoc(doc(alice(), 'codes', 'MINE'), { ...live, maxUses: 9999 }));
  await assertFails(deleteDoc(doc(alice(), 'codes', 'LIVE')));
});

test('a person can read and give up their own redemption, nobody else\'s', async () => {
  await assertSucceeds(redeem(alice(), 'alice', 'LIVE'));
  await assertFails(getDoc(doc(bob(), 'redemptions', 'alice')));
  await assertFails(deleteDoc(doc(bob(), 'redemptions', 'alice')));
  await assertFails(getDocs(collection(alice(), 'redemptions')));
  await assertSucceeds(deleteDoc(doc(alice(), 'redemptions', 'alice')));
});

// ── entitlements: written by the webhook, read by the app ───────────────────

const seedEntitlement = async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'entitlements', 'alice'), {
      pro: true, source: 'stripe', email: 'alice@example.com', paymentIntent: 'pi_1',
    });
  });
};

test('a person can read their own licence and nobody else\'s', async () => {
  await seedEntitlement();
  await assertSucceeds(getDoc(doc(alice(), 'entitlements', 'alice')));
  await assertFails(getDoc(doc(bob(), 'entitlements', 'alice')));
  await assertFails(getDoc(doc(nobody(), 'entitlements', 'alice')));
});

test('a licence can be found by a VERIFIED email, never by an unverified one', async () => {
  await seedEntitlement();
  const { query, where } = await import('firebase/firestore');
  const byEmail = (db) => getDocs(query(collection(db, 'entitlements'), where('email', '==', 'alice@example.com')));
  await assertSucceeds(byEmail(aliceElsewhere(true)));
  // Anyone can make a password account with someone else's address; that
  // must not become someone else's Pro.
  await assertFails(byEmail(aliceElsewhere(false)));
  // And a verified address only finds ITS OWN licences.
  const bobDb = env.authenticatedContext('bob', { email: 'bob@example.com', email_verified: true }).firestore();
  await assertFails(byEmail(bobDb));
  await assertFails(getDocs(collection(alice(), 'entitlements')));
});

test('nobody can write a licence from the app', async () => {
  await assertFails(setDoc(doc(alice(), 'entitlements', 'alice'), { pro: true, source: 'stripe' }));
  await seedEntitlement();
  await assertFails(updateDoc(doc(alice(), 'entitlements', 'alice'), { pro: true }));
  await assertFails(deleteDoc(doc(alice(), 'entitlements', 'alice')));
});

test('the Stripe ledger is nobody\'s business', async () => {
  await assertFails(getDoc(doc(alice(), 'stripe_events', 'evt_1')));
  await assertFails(setDoc(doc(alice(), 'stripe_events', 'evt_1'), { type: 'x' }));
});
