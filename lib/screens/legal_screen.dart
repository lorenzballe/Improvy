import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_info.dart';
import '../constants/app_scroll.dart';

class LegalScreen extends StatelessWidget {
  final String title;
  final String body;
  const LegalScreen({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(13),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withAlpha(26), width: 1.2),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: Colors.white70, size: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: kAppScrollPhysics,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                child: Text(
                  body,
                  style: TextStyle(fontSize: 14, height: 1.6, color: Colors.white.withValues(alpha: 0.7)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PRIVACY POLICY ──────────────────────────────────────────────────────────
// The same text as the website's #privacy page, in plain prose. Change one,
// change the other: the store listings point at the site, Settings shows this.

const String kPrivacyPolicyBody = '''
PRIVACY POLICY

Last updated: September 13, 2026

Improvy ("App", "we", "us") — the app and our website — is developed and operated by Lorenzo Ballestrazzi ("Developer"). This Privacy Policy explains what information we collect, how we use it, and your rights.

The short version: you can use Improvy without an account, and then we hold nothing that identifies you — only anonymous usage data and a coarse, IP-based location. If you choose to create an account (so that PRO follows you across devices, or to redeem a code), we hold the little an account needs: an identifier, your email address, and how you signed in. Everything below simply spells that out.

1. INFORMATION WE COLLECT

We never collect your name, phone number, contacts, photos, or precise location. Depending on how you use Improvy, we collect:

a) Anonymous usage events
When you use the App, we record anonymous events such as:
- Training sessions started and completed
- Training mode selected (diatonic, chromatic, custom)
- Accuracy percentage and average response time
- Key and difficulty settings chosen
- Level-up and streak milestones
On their own these contain nothing that identifies you.

b) Account data (only if you sign in)
Signing in with Apple, Google or an email address creates an account with a unique identifier, your email address, the sign-in method, and the times the account was created and last used. Email passwords are handled by Firebase Authentication and are never visible to us. With Sign in with Apple you may hide your address, in which case we receive Apple's private relay address instead.

c) Purchase and licence status
Whether Improvy PRO is active and how it was obtained: an app-store purchase (managed by RevenueCat, which receives the store receipt), a promotional code redeemed on your account (we store which code and when), or a licence granted to your account through another sales channel we operate (we store the payment reference, the amount, the currency, the time, and the email address given at checkout). We never receive or store your card details — those stay with Apple, Google or our payment processor.

d) Device metadata (collected automatically by PostHog)
Our analytics provider may automatically record app version, operating system version, device model, and screen resolution, under a random per-install identifier. If you sign in, that identifier is linked to your account identifier and your email is stored as a property of the profile, so your usage across devices is one record rather than several strangers.

e) Approximate location
PostHog derives a coarse location (roughly your city, region, and country) from the IP address of each request, so we can see broadly where Improvy is used. The App itself never asks for location access and cannot read your device's GPS. It is used only for analytics, never for advertising.

f) Feedback you choose to send
The App has a feedback box in Settings. We receive only what you type into it: your message, the category you pick, and — if you fill in the optional email field — the address you enter, which we use solely to reply to you. Leaving that field blank keeps the message anonymous.

2. HOW WE USE YOUR INFORMATION

We use this information only to:
- Sign you in, keep your PRO licence attached to your account, and honour promotional codes
- Recognise a licence on any device you sign in on, and handle refunds and disputes where they arise
- Understand which training features are most useful, find and fix bugs, and plan ahead
- Read, and where you asked for one, answer your feedback

We do not use your data for advertising. We do not sell, rent, or share your data with any third party for marketing purposes.

3. THIRD-PARTY SERVICES

Firebase (Google) — accounts and licences
Firebase Authentication signs you in; Cloud Firestore stores account data, code redemptions and licences. Google processes this on its servers in the EU and the United States under its data processing terms. https://firebase.google.com/support/privacy

Apple / Google — in-app purchases
Purchases made inside the App are processed by Apple (App Store) or Google (Play Store) under their own privacy policies:
- Apple: https://www.apple.com/legal/privacy
- Google: https://policies.google.com/privacy

RevenueCat — purchase management
Verifies and manages in-app purchase status from the store receipt. If you sign in, your account identifier is used as the RevenueCat customer identifier so the purchase follows you. https://www.revenuecat.com/privacy

Stripe — payments on other channels we operate
Where PRO is bought outside the App, Stripe processes the payment. Card details go to Stripe, never to us; we receive the payment reference, amount, and the email given at checkout. https://stripe.com/privacy

PostHog — analytics
Collects the usage events, device metadata and coarse location described above, and carries the feedback you send. May process data on servers in the EU. https://posthog.com/privacy

4. DATA RETENTION

Anonymous analytics events are kept for up to 12 months and then deleted. Account data is kept for as long as the account exists. Licence and payment records are kept for as long as the licence is valid and, afterwards, for as long as accounting and tax law require. Your local app data (training history, settings, streak) is stored only on your device and is removed when you uninstall the App.

You can delete your account from Settings at any time. Doing so removes your sign-in and account data and gives up any licence tied to it; anonymised usage data and legally required payment records may remain.

5. YOUR RIGHTS (GDPR)

If you are located in the European Economic Area (EEA), you have the right to:
- Access any personal data we hold about you
- Request correction or deletion of your personal data
- Object to or restrict our processing of your data
- Receive your data in a portable form
- Lodge a complaint with your national data protection authority

Without an account there is typically no personal data to act on. With one, most of this you can do yourself in Settings; for anything else, contact us at $kSupportEmail and we will respond within 30 days.

Legal bases: performance of a contract (your account and your licence), legitimate interests (improving the App, applied to anonymous events), and legal obligation (keeping payment records).

6. CHILDREN'S PRIVACY

Improvy is suitable for users of all ages. We do not knowingly collect personal information from children under 13, and accounts are for people 13 and over. If you believe a child has provided personal data, contact us and we will delete it promptly.

7. SECURITY

We use reasonable technical measures to protect data in transit and at rest, and we hold as little of it as the service needs. Access to account and licence data is restricted to what the App and our website require to work.

8. CHANGES TO THIS POLICY

We may update this Privacy Policy. When we do, we will revise the "Last updated" date above and, for material changes, notify you within the App. The latest version is always available in the App and on our website.

9. CONTACT

Lorenzo Ballestrazzi
$kSupportEmail
$kWebsiteUrl
''';

// ─── TERMS OF SERVICE ────────────────────────────────────────────────────────
// The website's #terms carries one section more, about buying there; nothing
// in the App points at that, and the App's own copy does not describe it.

const String kTermsBody = '''
TERMS OF SERVICE

Last updated: September 13, 2026

Please read these Terms of Service ("Terms") carefully before using Improvy.

1. ACCEPTANCE

By downloading, installing, or using the Improvy app ("App"), or by creating an account, you confirm that you have read and agree to these Terms. If you do not agree, do not use the App.

2. DESCRIPTION OF THE APP

Improvy is a music-training application that helps you master where every scale degree lives across all 12 keys — building the instant recall used for improvisation, transposition, and composition. The App is available on iOS and Android.

3. LICENSE

Subject to your compliance with these Terms, we grant you a limited, personal, non-exclusive, non-transferable, revocable licence to use the App on devices you own or control, solely for personal, non-commercial training.

You may not:
- Copy, modify, distribute, or create derivative works of the App
- Reverse-engineer, decompile, or disassemble the App
- Use the App for any commercial purpose without our prior written consent
- Use automated tools (bots, scrapers) to interact with the App

4. ACCOUNTS

An account is optional. You need one only for a PRO licence to follow you across devices or to redeem a promotional code. You may sign in with Apple, Google, or an email address and password.

- Keep your sign-in credentials to yourself, and tell us if you believe your account has been used without your permission.
- An account is for one person, aged 13 or over, and is not transferable.
- You can delete your account at any time from Settings. This gives up any licence or code tied to it.
- We may suspend or close an account used to breach these Terms, to obtain licences improperly, or to interfere with the service.

5. IMPROVY PRO

Certain features of the App ("Improvy PRO") are unlocked with a one-time payment — a lifetime licence, not a subscription. There are no recurring fees.

In the App, PRO is an in-app purchase processed by Apple (App Store) or Google (Play Store), at the price shown there in your local currency. Refunds for these purchases are handled by Apple or Google under their own policies: contact Apple Support or Google Play Support directly.

A promotional code we issue unlocks PRO on the account that redeems it. One code per account; codes are non-transferable, may carry a use limit or an expiry, and may be withdrawn if obtained or used improperly.

A PRO licence obtained through any channel we operate is recognised in the App on any device where you sign in with the same account. In-app purchases can also be restored from Settings with the same Apple ID or Google account used for the original purchase. No additional payment is required.

We reserve the right to add, modify, or discontinue features at any time. Existing PRO users will retain access to features available at the time of their purchase.

6. USER CONTENT AND CONDUCT

Improvy does not involve user-generated content or social features. You agree to use the App only for lawful purposes, and not to attempt to obtain PRO other than as described above.

7. INTELLECTUAL PROPERTY

All content within the App — including but not limited to the music engine logic, user interface, graphics, animations, and text — is owned by Lorenzo Ballestrazzi and is protected by Italian and international copyright, trademark, and other intellectual property laws.

"Improvy" and the Improvy logo are trademarks of Lorenzo Ballestrazzi. You may not use them without prior written permission.

8. DISCLAIMER OF WARRANTIES

THE APP IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.

We do not warrant that:
- The App will be available at all times or free of errors
- Defects will be corrected
- The App is free of viruses or harmful components

Nothing here limits the rights you have as a consumer under the law that applies to you.

9. LIMITATION OF LIABILITY

To the maximum extent permitted by applicable law, Lorenzo Ballestrazzi shall not be liable for any indirect, incidental, special, consequential, or punitive damages, including loss of profits, data, or goodwill, arising from your use of or inability to use the App.

Our total liability to you for any claim arising out of these Terms or your use of the App shall not exceed the amount you paid for Improvy PRO (or €0 if you have not purchased PRO).

10. GOVERNING LAW AND JURISDICTION

These Terms are governed by and construed in accordance with the laws of Italy. Any dispute arising out of or relating to these Terms shall be subject to the jurisdiction of the courts of Italy, without prejudice to the mandatory protections of the country where you live if you are a consumer.

If you are a consumer resident in the EU, you also have the right to use the EU Online Dispute Resolution platform: https://ec.europa.eu/consumers/odr

11. CHANGES TO THESE TERMS

We may update these Terms at any time. We will notify you of significant changes through the App or by updating the "Last updated" date above. Continued use of the App after changes take effect constitutes your acceptance of the revised Terms. Changes do not affect a licence you have already paid for.

12. CONTACT

Lorenzo Ballestrazzi
$kSupportEmail
$kWebsiteUrl
''';
