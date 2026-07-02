import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class LegalScreen extends StatelessWidget {
  final String title;
  final String body;
  const LegalScreen({super.key, required this.title, required this.body});

  static const String privacyPolicyUrl = 'https://improvy.app/privacy';
  static const String termsUrl = 'https://improvy.app/terms';

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
// Last reviewed: June 2026
// Replace [DEVELOPER_NAME] with your legal name or company name before release.

const String kPrivacyPolicyBody = '''
PRIVACY POLICY

Last updated: June 28, 2026

Improvy ("App", "we", "us") is developed and operated by Lorenzo Ballestrazzi ("Developer"). This Privacy Policy explains what information we collect, how we use it, and your rights.

──────────────────────────────────
1. INFORMATION WE COLLECT
──────────────────────────────────

Improvy does not require you to create an account. We do not collect your name, email address, phone number, contacts, photos, or precise location.

We collect:

a) Anonymous usage events
When you use the App, we record anonymous events such as:
- Training sessions started and completed
- Training mode selected (diatonic, chromatic, custom)
- Accuracy percentage and average response time
- Key and difficulty settings chosen
- Level-up and streak milestones
These events contain no personally identifiable information. They cannot be traced back to you.

b) Purchase status
We record whether you have activated Improvy PRO. This is stored locally on your device and also managed by RevenueCat (see §3). We never receive or store your payment details — those remain with Apple or Google.

c) Device metadata (collected automatically by PostHog)
Our analytics provider (PostHog) may automatically record: app version, operating system version, device model, screen resolution, and a country derived from your IP address at the time of the request. Your IP address is not stored by PostHog.

──────────────────────────────────
2. HOW WE USE YOUR INFORMATION
──────────────────────────────────

We use anonymous usage data exclusively to:
- Understand which training features are most useful
- Identify and fix bugs
- Prioritise future improvements

We do not use your data for advertising. We do not sell, rent, or share your data with any third party for marketing purposes.

──────────────────────────────────
3. THIRD-PARTY SERVICES
──────────────────────────────────

PostHog (Analytics)
We use PostHog to collect anonymous usage events. PostHog may process data on servers located in the EU. No personal data is sent to PostHog. You can opt out of analytics in the App's Settings screen at any time. PostHog Privacy Policy: https://posthog.com/privacy

Apple / Google (In-App Purchases)
In-app purchases are processed directly by Apple (App Store) or Google (Play Store). Their privacy policies govern the processing of your payment and account data:
- Apple: https://www.apple.com/legal/privacy
- Google: https://policies.google.com/privacy

RevenueCat (Purchase Management)
We use RevenueCat to verify and manage your purchase status. RevenueCat receives your app store purchase receipt (a non-personal cryptographic token). RevenueCat Privacy Policy: https://www.revenuecat.com/privacy

──────────────────────────────────
4. DATA RETENTION
──────────────────────────────────

Anonymous analytics events are retained for up to 12 months and then permanently deleted. Local app data (your training history, settings, and streak) is stored only on your device and is deleted when you uninstall the App.

──────────────────────────────────
5. YOUR RIGHTS (GDPR)
──────────────────────────────────

If you are located in the European Economic Area (EEA), you have the right to:
- Access any personal data we hold about you
- Request correction or deletion of your personal data
- Object to or restrict our processing of your data
- Lodge a complaint with your national data protection authority

Because Improvy collects only anonymous data with no account or identity, there is typically no personal data to access, correct, or delete. For any privacy concern, contact us at support@improvy.app and we will respond within 30 days.

Legal basis for processing: Legitimate interests (improving the App) — applied only to fully anonymous events.

──────────────────────────────────
6. CHILDREN'S PRIVACY
──────────────────────────────────

Improvy is suitable for users of all ages. We do not knowingly collect personal information from children under 13. If you believe a child has provided personal data, contact us and we will delete it promptly.

──────────────────────────────────
7. SECURITY
──────────────────────────────────

We implement reasonable technical measures to protect data in transit and at rest. Because we collect no personal data, the risk to you is minimal.

──────────────────────────────────
8. CHANGES TO THIS POLICY
──────────────────────────────────

We may update this Privacy Policy. When we do, we will revise the "Last updated" date above and, for material changes, notify you within the App. The latest version is always available at: https://improvy.app/privacy

──────────────────────────────────
9. CONTACT
──────────────────────────────────

Lorenzo Ballestrazzi
support@improvy.app
''';

// ─── TERMS OF SERVICE ────────────────────────────────────────────────────────

const String kTermsBody = '''
TERMS OF SERVICE

Last updated: June 28, 2026

Please read these Terms of Service ("Terms") carefully before using Improvy.

──────────────────────────────────
1. ACCEPTANCE
──────────────────────────────────

By downloading, installing, or using the Improvy app ("App"), you confirm that you have read and agree to these Terms. If you do not agree, do not use the App.

──────────────────────────────────
2. DESCRIPTION OF THE APP
──────────────────────────────────

Improvy is a music ear-training application that helps users develop interval recognition, scale knowledge, and relative pitch. The App is available on iOS and Android.

──────────────────────────────────
3. LICENSE
──────────────────────────────────

Subject to your compliance with these Terms, we grant you a limited, personal, non-exclusive, non-transferable, revocable licence to use the App on devices you own or control, solely for personal, non-commercial ear-training purposes.

You may not:
- Copy, modify, distribute, or create derivative works of the App
- Reverse-engineer, decompile, or disassemble the App
- Use the App for any commercial purpose without our prior written consent
- Use automated tools (bots, scrapers) to interact with the App

──────────────────────────────────
4. IMPROVY PRO
──────────────────────────────────

Certain features of the App ("Improvy PRO") are available only after a one-time in-app purchase ("lifetime upgrade") processed by Apple (App Store) or Google (Play Store).

Price: displayed in your local currency at the time of purchase.

Refunds: all refund requests are handled by Apple or Google in accordance with their respective policies. Contact Apple Support or Google Play Support directly.

Restoring purchases: if you reinstall the App or switch devices, you can restore your PRO status from the Settings screen using the same Apple ID or Google account used for the original purchase. No additional payment is required.

We reserve the right to add, modify, or discontinue features at any time. Existing PRO users will retain access to features available at the time of their purchase.

──────────────────────────────────
5. USER CONTENT AND CONDUCT
──────────────────────────────────

Improvy does not involve user-generated content or social features. You agree to use the App only for lawful purposes.

──────────────────────────────────
6. INTELLECTUAL PROPERTY
──────────────────────────────────

All content within the App — including but not limited to the music engine logic, user interface, graphics, animations, and text — is owned by Lorenzo Ballestrazzi and is protected by Italian and international copyright, trademark, and other intellectual property laws.

"Improvy" and the Improvy logo are trademarks of Lorenzo Ballestrazzi. You may not use them without prior written permission.

──────────────────────────────────
7. DISCLAIMER OF WARRANTIES
──────────────────────────────────

THE APP IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.

We do not warrant that:
- The App will be available at all times or free of errors
- Defects will be corrected
- The App is free of viruses or harmful components

──────────────────────────────────
8. LIMITATION OF LIABILITY
──────────────────────────────────

To the maximum extent permitted by applicable law, Lorenzo Ballestrazzi shall not be liable for any indirect, incidental, special, consequential, or punitive damages, including loss of profits, data, or goodwill, arising from your use of or inability to use the App.

Our total liability to you for any claim arising out of these Terms or your use of the App shall not exceed the amount you paid for Improvy PRO (or €0 if you have not purchased PRO).

──────────────────────────────────
9. GOVERNING LAW AND JURISDICTION
──────────────────────────────────

These Terms are governed by and construed in accordance with the laws of Italy. Any dispute arising out of or relating to these Terms shall be subject to the exclusive jurisdiction of the courts of Italy.

If you are a consumer resident in the EU, you also have the right to use the EU Online Dispute Resolution platform: https://ec.europa.eu/consumers/odr

──────────────────────────────────
10. CHANGES TO THESE TERMS
──────────────────────────────────

We may update these Terms at any time. We will notify you of significant changes through the App or by updating the "Last updated" date above. Continued use of the App after changes take effect constitutes your acceptance of the revised Terms.

──────────────────────────────────
11. CONTACT
──────────────────────────────────

Lorenzo Ballestrazzi
support@improvy.app
https://improvy.app
''';
