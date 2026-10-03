import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_scroll.dart';

class LegalScreen extends StatelessWidget {
  final String title;
  final String body;
  const LegalScreen({super.key, required this.title, required this.body});

  /// The plain-text document set as a document: the title it opens with is
  /// already in the header, section headings ("1. INFORMATION WE COLLECT")
  /// stand out, the date is quiet, and the prose is the prose.
  List<Widget> _paragraphs() {
    final heading = RegExp(r"^(\d+\.\s+)?[A-Z0-9 &,'’()/\-—]+$");
    final blocks = body
        .trim()
        .split(RegExp(r'\n\s*\n'))
        .map((b) => b.trim())
        .where((b) => b.isNotEmpty)
        .toList();
    if (blocks.isNotEmpty && blocks.first.toUpperCase() == blocks.first &&
        !blocks.first.contains('\n')) {
      blocks.removeAt(0);
    }
    final out = <Widget>[];
    for (final b in blocks) {
      if (!b.contains('\n') && heading.hasMatch(b)) {
        out.add(Padding(
          padding: const EdgeInsets.only(top: 22, bottom: 8),
          child: Text(b,
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: Colors.white)),
        ));
      } else if (b.startsWith('Last updated') || b.startsWith('Ultimo aggiornamento')) {
        out.add(Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(b,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.4))),
        ));
      } else {
        out.add(Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(b,
              style: TextStyle(fontSize: 14, height: 1.6, color: Colors.white.withValues(alpha: 0.72))),
        ));
      }
    }
    return out;
  }

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _paragraphs(),
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
IMPROVY PRIVACY POLICY

Last updated: 3 October 2026

Improvy (“App”, “we”, “us”) — the app and this website — is developed and operated by Lorenzo Ballestrazzi (“Developer”). This Privacy Policy explains what information we collect, how we use it, and your rights.

The short version: you can use Improvy without an account, and then we hold nothing that identifies you — only anonymous usage data and a coarse, IP-based location. If you choose to create an account (so that Pro follows you across devices, to redeem a code, or to buy Pro on this site), we hold the little an account needs: an identifier, your email address, and how you signed in. Everything below simply spells that out.

1. INFORMATION WE COLLECT

We never collect your name, phone number, contacts, photos, or precise location. Depending on how you use Improvy, we collect:

ANONYMOUS USAGE EVENTS

Sessions started and completed, the training mode selected, accuracy and average response time, the key and difficulty chosen, and level-up or streak milestones. For a purchase in the app we also record its outcome — the product, its price and currency, the store's transaction reference, and whether it was a test purchase — and, when the store refuses one, which app store installed Improvy. On their own these contain nothing that identifies you. If you enter a creator's code in the app, the creator's name and the code are attached to your later events too, so we can tell which creator brought whom.

ACCOUNT DATA (ONLY IF YOU SIGN IN)

Signing in with Apple, Google or an email address creates an account with a unique identifier, your email address, the sign-in method, and the times the account was created and last used. Email passwords are handled by Firebase Authentication and are never visible to us. With Sign in with Apple you may hide your address, in which case we receive Apple’s private relay address instead.

PURCHASE AND LICENCE STATUS

Whether Improvy Pro is active and how it was obtained: an app-store purchase (managed by RevenueCat, which receives the store receipt), a promotional code redeemed on your account (we store which code and when), or a purchase on this website (we store the Stripe payment reference, the amount, the currency, the time, and the email address you gave at checkout). We never receive or store your card details — those stay with Apple, Google or Stripe.

DEVICE METADATA (VIA POSTHOG)

Our analytics provider may automatically record app version, operating system version, device model, and screen resolution, under a random per-install identifier. If you sign in, that identifier is linked to your account identifier and your email is stored as a property of the profile, so your usage across devices is one record rather than several strangers.

APPROXIMATE LOCATION

PostHog derives a coarse location — roughly your city, region, and country — from the IP address of each request, so we can see broadly where Improvy is used. The app itself never asks for location access and cannot read your device’s GPS. It is used only for analytics, never for advertising.

FEEDBACK YOU CHOOSE TO SEND

The app has a feedback box in Settings and this site has a feedback page. We receive only what you type: the message, the category, and — if you fill it in — a reply address. Leaving it blank keeps the message anonymous.

COOKIES ON THIS WEBSITE

This website sets no advertising or analytics cookies, and its analytics keep nothing in your browser once the tab is closed — which is why there is no cookie banner. If you arrive through a creator's link (improvy.app/?ref=…), that creator's name is kept for the open tab only and attached to your visit and, if you buy, to the payment together with any discount code you used, so we know whom to thank. If you sign in to buy Pro, Firebase keeps your sign-in in your browser's storage so that you stay signed in; that storage is strictly necessary for the purchase and is removed when you sign out.

2. HOW WE USE YOUR INFORMATION

We use this information only to:

RUN YOUR ACCOUNT

Sign you in, keep your Pro licence attached to it, and honour promotional codes.

DELIVER WHAT YOU BOUGHT

Recognise a licence on any device you sign in on, and handle refunds and disputes where they arise.

IMPROVE THE APP

Understand which training features are most useful, find and fix bugs, plan ahead.

ANSWER YOU

Read and, where you asked for one, reply to your feedback.

We do not use your data for advertising, and we never sell, rent, or share it with third parties for marketing purposes.

3. THIRD-PARTY SERVICES

FIREBASE (GOOGLE) — ACCOUNTS AND LICENCES

Firebase Authentication signs you in; Cloud Firestore stores account data, code redemptions and licences. Google processes this on its servers in the EU and the United States under its data processing terms. Firebase Privacy and Security.

STRIPE — PAYMENTS ON THIS WEBSITE

Stripe processes payments made here. Your card details go to Stripe, never to us; we receive the payment reference, amount, and the email you gave at checkout. Stripe Privacy Policy.

APPLE / GOOGLE — IN-APP PURCHASES

Purchases made inside the app are processed by Apple (App Store) or Google (Play Store) under their own privacy policies: Apple · Google.

REVENUECAT — PURCHASE MANAGEMENT

Verifies and manages in-app purchase status from the store receipt. If you sign in, your account identifier is used as the RevenueCat customer identifier so the purchase follows you, and your email address is attached to it. RevenueCat Privacy Policy.

POSTHOG — ANALYTICS

Collects the usage events, device metadata and coarse location described above, and carries the feedback you send. May process data on servers in the EU. PostHog Privacy Policy.

4. DATA RETENTION

Anonymous analytics events are kept for up to 12 months and then deleted. Account data is kept for as long as the account exists. Licence and payment records are kept for as long as the licence is valid and, afterwards, for as long as accounting and tax law require. Your local app data — training history, settings, streak — is stored only on your device and is removed when you uninstall the app.

You can delete your account from the app’s Settings at any time. Doing so removes your sign-in and account data and gives up any licence tied to it; anonymised usage data and legally required payment records may remain.

5. YOUR RIGHTS (GDPR)

If you are in the European Economic Area, you have the right to access, correct, or delete your personal data, to object to or restrict its processing, to receive it in a portable form, and to lodge a complaint with your national data protection authority.

Without an account there is typically no personal data to act on. With one, most of this you can do yourself in Settings; for anything else, contact us at thebalecompany@gmail.com and we will respond within 30 days.

Legal bases: performance of a contract (your account and your licence), legitimate interests (improving the app, applied to anonymous events), and legal obligation (keeping payment records).

6. CHILDREN’S PRIVACY

Improvy is suitable for all ages. We do not knowingly collect personal information from children under 13, and accounts are for people 13 and over. If you believe a child has provided personal data, contact us and we will delete it promptly.

7. SECURITY

We use reasonable technical measures to protect data in transit and at rest, and we hold as little of it as the service needs. Access to account and licence data is restricted to what the app and the website require to work.

8. CHANGES TO THIS POLICY

We may update this Privacy Policy. When we do, we will revise the “Last updated” date above and, for material changes, notify you within the app. The latest version is always available in the app and on this website.

9. CONTACT

Lorenzo Ballestrazzi

thebalecompany@gmail.com
''';

// ─── TERMS OF SERVICE ────────────────────────────────────────────────────────
// The website's #terms carries one section more, about buying there; nothing
// in the App points at that, and the App's own copy does not describe it.

const String kTermsBody = '''
IMPROVY TERMS OF SERVICE

Last updated: 24 September 2026

Please read these Terms of Service (“Terms”) carefully before using Improvy or buying Improvy Pro.

1. ACCEPTANCE

By downloading, installing, or using the Improvy app (“App”), or by creating an account or buying Improvy Pro on this website, you confirm that you have read and agree to these Terms. If you do not agree, do not use the App or the website.

2. DESCRIPTION

Improvy is a music-training application that helps you master where every scale degree lives across all 12 keys — building the instant recall used for improvisation, transposition, and composition. The App is available on iOS and Android; this website presents it and sells Improvy Pro.

3. LICENSE

Subject to these Terms, we grant you a limited, personal, non-exclusive, non-transferable, revocable licence to use the App on devices you own or control, solely for personal, non-commercial training.

You may not:

COPY OR MODIFY

Copy, modify, distribute, or create derivative works of the App.

REVERSE-ENGINEER

Reverse-engineer, decompile, or disassemble the App.

COMMERCIAL USE

Use the App for any commercial purpose without our prior written consent.

AUTOMATION

Use bots, scrapers, or other automated tools to interact with the App or the website.

4. ACCOUNTS

An account is optional. You need one only for a Pro licence to follow you across devices, to redeem a promotional code, or to buy Pro on this website. You may sign in with Apple, Google, or an email address and password.

YOUR RESPONSIBILITY

Keep your sign-in credentials to yourself and tell us if you believe your account has been used without your permission.

ONE PERSON

An account is for one person, aged 13 or over, and is not transferable.

DELETING IT

You can delete your account at any time from the App’s Settings. This gives up any licence or code tied to it.

ABUSE

We may suspend or close an account used to breach these Terms, to obtain licences improperly, or to interfere with the service.

5. IMPROVY PRO

Certain features (“Improvy Pro”) are unlocked with a one-time payment — a lifetime licence, not a subscription. There are no recurring fees. Pro can be obtained in three ways:

IN THE APP

As an in-app purchase processed by Apple (App Store) or Google (Play Store), at the price shown there in your local currency. Refunds for these purchases are handled by Apple or Google under their own policies — contact Apple Support or Google Play Support directly.

ON THIS WEBSITE

By card or wallet through Stripe, under section 6 below.

WITH A PROMOTIONAL CODE

A code we issue unlocks Pro on the account that redeems it. One code per account; codes are non-transferable, may carry a use limit or an expiry, and may be withdrawn if obtained or used improperly.

A Pro licence obtained by any route is recognised in the App on any device where you sign in with the same account (for in-app purchases, the same Apple ID or Google account also restores it from Settings). We may add, modify, or discontinue features at any time; existing Pro users keep access to the features available at the time of their purchase.

6. BUYING ON THIS WEBSITE

SELLER

Lorenzo Ballestrazzi, Italy. Contact details are at the end of these Terms.

PRICE

The price is shown at checkout in euro and includes VAT where it applies. It may differ from the in-app price.

PAYMENT

Payments are processed by Stripe. We never see your card details. You receive Stripe’s receipt by email.

DELIVERY

The licence is delivered immediately after payment, by being attached to the account you signed in with. It appears in the App the next time that account signs in.

RIGHT OF WITHDRAWAL

EU consumers normally have 14 days to withdraw from a distance purchase. Because Pro is digital content delivered immediately, the checkout asks you to request immediate delivery and to acknowledge that, once delivered, you lose that right of withdrawal (Directive 2011/83/EU, art. 16(m)). You cannot pay without giving that consent.

REFUNDS

Even so, if something is wrong with your purchase, write to us within 14 days and we will help — including a refund at our discretion. A refunded or charged-back payment removes the licence from the account.

USE THE RIGHT ACCOUNT

The licence belongs to the account you paid with. Sign in with that same account in the App.

7. CONDUCT

Improvy has no user-generated content or social features. You agree to use the App and the website only for lawful purposes, and not to attempt to obtain Pro other than as described above.

8. INTELLECTUAL PROPERTY

All content within the App and this website — including the music-engine logic, user interface, graphics, animations, and text — is owned by Lorenzo Ballestrazzi and protected by Italian and international copyright, trademark, and other intellectual property laws.

“Improvy” and the Improvy logo are trademarks of Lorenzo Ballestrazzi. You may not use them without prior written permission.

9. DISCLAIMER OF WARRANTIES

THE APP AND THE WEBSITE ARE PROVIDED “AS IS” AND “AS AVAILABLE” WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.

We do not warrant that the App will always be available or error-free, that defects will be corrected, or that it is free of harmful components. Nothing here limits the rights you have as a consumer under the law that applies to you.

10. LIMITATION OF LIABILITY

To the maximum extent permitted by law, Lorenzo Ballestrazzi shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising from your use of, or inability to use, the App or the website.

Our total liability for any claim shall not exceed the amount you paid for Improvy Pro (or €0 if you have not purchased Pro).

11. GOVERNING LAW & JURISDICTION

These Terms are governed by the laws of Italy. Any dispute shall be subject to the jurisdiction of the courts of Italy, without prejudice to the mandatory protections of the country where you live if you are a consumer.

If you are a consumer resident in the EU, you may also use the EU Online Dispute Resolution platform at ec.europa.eu/consumers/odr.

12. CHANGES TO THESE TERMS

We may update these Terms at any time. We will note significant changes in the App or by updating the “Last updated” date above. Continued use after changes take effect means you accept the revised Terms. Changes do not affect a licence you have already paid for.

13. CONTACT

Lorenzo Ballestrazzi

thebalecompany@gmail.com
''';
