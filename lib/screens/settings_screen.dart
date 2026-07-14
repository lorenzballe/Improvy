import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/purchase_service.dart';
import 'legal_screen.dart';

class SettingsScreen extends StatelessWidget {
  final void Function([String? reason]) onShowPaywall;
  final VoidCallback onSimulatePerfect;
  const SettingsScreen({super.key, required this.onShowPaywall, required this.onSimulatePerfect});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0A1A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 140 + MediaQuery.of(context).padding.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'SETTINGS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withAlpha(77),
                    letterSpacing: 4.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ACCOUNT STATUS
              _sectionLabel('ACCOUNT STATUS'),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: provider.isPro ? null : onShowPaywall,
                behavior: HitTestBehavior.opaque,
                child: _card(
                  shadow: const [BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 40,
                    offset: Offset(0, 20),
                  )],
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ACCOUNT STATUS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.white.withAlpha(102),
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      provider.isPro ? 'PRO' : 'NON-PRO',
                                      maxLines: 1,
                                      softWrap: false,
                                      style: const TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: -0.75,
                                      ),
                                    ),
                                  ),
                                ),
                                if (provider.isPro) ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFBBF24), size: 26),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: provider.isPro ? const Color(0x33FBBF24) : Colors.white.withAlpha(26),
                          border: Border.all(color: provider.isPro ? const Color(0x66FBBF24) : Colors.white.withAlpha(51)),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          provider.isPro ? 'ACTIVE' : 'FREE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: provider.isPro ? const Color(0xFFFBBF24) : Colors.white.withAlpha(128),
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // TRAINING
              _sectionLabel('TRAINING'),
              const SizedBox(height: 12),
              _card(
                shadow: const [BoxShadow(color: Color(0x4D000000), blurRadius: 32, offset: Offset(0, 8))],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (!provider.isPro) { onShowPaywall(); return; }
                        provider.setAdaptiveDifficulty(!provider.adaptiveDifficulty);
                      },
                      child: Opacity(
                        opacity: provider.isPro ? 1.0 : 0.6,
                        child: AnimatedContainer(
                          duration: Duration.zero, // instant on/off
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            // ON: blue-500/10 → /30 glow from top-left, blue border + glow.
                            gradient: provider.adaptiveDifficulty
                                ? const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0x4D3B82F6), Color(0x143B82F6)],
                                  )
                                : null,
                            color: provider.adaptiveDifficulty ? null : Colors.white.withAlpha(8),
                            border: Border.all(
                              color: provider.adaptiveDifficulty
                                  ? const Color(0x663B82F6)
                                  : Colors.white.withAlpha(13),
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: provider.adaptiveDifficulty
                                ? [const BoxShadow(color: Color(0x263B82F6), blurRadius: 30)]
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  AnimatedContainer(
                                    duration: Duration.zero,
                                    width: 48, height: 48,
                                    decoration: BoxDecoration(
                                      color: provider.adaptiveDifficulty ? const Color(0xFF3B82F6) : Colors.white.withAlpha(26),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: provider.adaptiveDifficulty
                                          ? [const BoxShadow(color: Color(0x663B82F6), blurRadius: 25)]
                                          : null,
                                    ),
                                    child: Icon(Icons.psychology_rounded,
                                      color: provider.adaptiveDifficulty ? Colors.white : Colors.white.withAlpha(102), size: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Adaptive Difficulty',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                            color: provider.adaptiveDifficulty ? Colors.white : Colors.white.withAlpha(179),
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'SMART TRAINING',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white.withAlpha(102),
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _ToggleSwitch(value: provider.adaptiveDifficulty, color: const Color(0xFF3B82F6)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                provider.isPro
                                    ? 'Our algorithm analyzes your response times and accuracy to focus on the notes you find most challenging.'
                                    : 'PRO feature — upgrade to unlock smart training that adapts to your weaknesses.',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withAlpha(102),
                                  height: 18 / 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    _KeyboardFromTonicCard(provider: provider),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0x33A855F7),
                            border: Border.all(color: const Color(0x33A855F7)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.translate_rounded, color: Color(0xFFC084FC), size: 16),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'NOTATION SYSTEM',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white.withAlpha(102),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0x66000000),
                        border: Border.all(color: Colors.white.withAlpha(13)),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: LayoutBuilder(
                        builder: (ctx, box) {
                          final isCDE = provider.notation == 'CDE';
                          const gap = 8.0; // web: gap-2 between the two tabs
                          final itemW = (box.maxWidth - gap) / 2;
                          return Stack(
                            children: [
                              // Sliding indicator — covers one tab, rounded-xl
                              // (12px) purple→indigo gradient with a purple glow.
                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                left: isCDE ? 0 : itemW + gap,
                                top: 0,
                                bottom: 0,
                                width: itemW,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF9333EA), Color(0xFF4F46E5)],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: const [BoxShadow(color: Color(0x4C7C3AED), blurRadius: 15, offset: Offset(0, 4))],
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  _NotationTab(label: 'C D E', selected: isCDE, onTap: () => provider.setNotation('CDE')),
                                  const SizedBox(width: gap),
                                  _NotationTab(label: 'DO RE MI', selected: !isCDE, onTap: () => provider.setNotation('DoReMi')),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // NEWS & UPDATES
              _sectionLabel('NEWS & UPDATES'),
              const SizedBox(height: 12),
              _card(
                shadow: const [BoxShadow(color: Color(0x4D000000), blurRadius: 32, offset: Offset(0, 8))],
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0x3310B981),
                        border: Border.all(color: const Color(0x3310B981)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.new_releases_rounded, color: Color(0xFF34D399), size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chords Mode Coming Soon!',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "We're working on a revolutionary way to visualize and master chords across the entire fretboard/keyboard. Stay tuned for a beautiful new interface!",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withAlpha(128),
                              height: 18 / 11,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 96,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0x339333EA), Color(0x332563EB), Color(0x3310B981)],
                                stops: [0.0, 0.5, 1.0],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(color: Colors.white.withAlpha(26)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const _ComingSoonPreview(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _card(
                shadow: const [BoxShadow(color: Color(0x4D000000), blurRadius: 32, offset: Offset(0, 8))],
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0x3306B6D4),
                        border: Border.all(color: const Color(0x3306B6D4)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.auto_graph_rounded, color: Color(0xFF22D3EE), size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Scales Visualization Coming Soon!',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'A stunning new way to see every scale light up across the keyboard — watch patterns, intervals and shapes come alive as you play.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withAlpha(128),
                              height: 18 / 11,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 96,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0x3306B6D4), Color(0x334F46E5), Color(0x33D946EF)],
                                stops: [0.0, 0.5, 1.0],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(color: Colors.white.withAlpha(26)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const _ScalesComingSoonPreview(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // STORE
              _sectionLabel('STORE'),
              const SizedBox(height: 12),
              _card(
                shadow: const [BoxShadow(color: Color(0x4D000000), blurRadius: 32, offset: Offset(0, 8))],
                child: Column(
                  children: [
                    if (!provider.isPro)
                      GestureDetector(
                        onTap: onShowPaywall,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF9333EA), Color(0xFF4F46E5)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [BoxShadow(
                              color: Color(0x4C7C3AED),
                              blurRadius: 15,
                              offset: Offset(0, 4),
                            )],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.star_rounded, color: Colors.white, size: 16),
                              SizedBox(width: 8),
                              Text('UPGRADE TO PRO', style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700,
                                color: Colors.white, letterSpacing: 0.6,
                              )),
                            ],
                          ),
                        ),
                      ),
                    if (!provider.isPro) const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final ok = await PurchaseService.instance.restorePurchases();
                        if (ok) provider.setIsPro(true);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(ok ? 'PRO restored' : 'No previous purchase found'),
                            behavior: SnackBarBehavior.floating,
                          ));
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0x33F59E0B),
                          border: Border.all(color: const Color(0x4DF59E0B)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.restore_rounded, color: Color(0xFFFBBF24), size: 16),
                            SizedBox(width: 8),
                            Text('RESTORE PURCHASES', style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700,
                              color: Color(0xFFFBBF24), letterSpacing: 0.6,
                            )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // SUPPORT
              _sectionLabel('SUPPORT'),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {},
                child: _blurCard(
                  child: Row(
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0x33F59E0B),
                          border: Border.all(color: const Color(0x33F59E0B)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.mail_rounded, color: Color(0xFFFBBF24), size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Contact Support',
                                maxLines: 1,
                                softWrap: false,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            Text(
                              "Questions or feedback? We're here to help.",
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withAlpha(102),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: Colors.white.withAlpha(51)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // LEGAL
              _sectionLabel('LEGAL'),
              const SizedBox(height: 12),
              _legalRow(context, 'Privacy Policy', Icons.privacy_tip_rounded,
                  const LegalScreen(title: 'Privacy Policy', body: kPrivacyPolicyBody)),
              const SizedBox(height: 10),
              _legalRow(context, 'Terms of Service', Icons.description_rounded,
                  const LegalScreen(title: 'Terms of Service', body: kTermsBody)),
              const SizedBox(height: 16),

              // DEVELOPER DEBUG — shown in debug builds AND the web preview
              // (the GitHub Pages test build), but NEVER in a native release.
              // The section includes an "Enable PRO" shortcut, so it must not
              // reach the App Store / Play Store build, where kIsWeb is false.
              if (kDebugMode || kIsWeb) ...[
              _sectionLabel('DEVELOPER DEBUG'),
              const SizedBox(height: 12),
              _blurCard(
                child: Column(
                  children: [
                    _DebugButton(
                      icon: Icons.bolt_rounded,
                      label: 'ENABLE PRO FEATURES',
                      color: const Color(0xFF34D399),
                      bgColor: const Color(0x3310B981),
                      borderColor: const Color(0x4D10B981),
                      onTap: () => provider.setIsPro(true),
                    ),
                    const SizedBox(height: 8),
                    _DebugButton(
                      icon: Icons.lock_rounded,
                      label: 'RESET TO FREE TIER',
                      color: const Color(0xFFFBBF24),
                      bgColor: const Color(0x33F59E0B),
                      borderColor: const Color(0x4DF59E0B),
                      onTap: () => provider.setIsPro(false),
                    ),
                    const SizedBox(height: 8),
                    _DebugButton(
                      icon: Icons.school_rounded,
                      label: 'SHOW TUTORIAL',
                      color: const Color(0xFF60A5FA),
                      bgColor: const Color(0x333B82F6),
                      borderColor: const Color(0x4D3B82F6),
                      onTap: () => provider.showTutorialAgain(),
                    ),
                    const SizedBox(height: 8),
                    _DebugButton(
                      icon: Icons.delete_rounded,
                      label: 'CLEAR ALL APP DATA',
                      color: const Color(0xFFFB7185),
                      bgColor: const Color(0x33EF4444),
                      borderColor: const Color(0x4DEF4444),
                      onTap: () => _confirmReset(context, provider),
                    ),
                    const SizedBox(height: 8),
                    _DebugButton(
                      icon: Icons.star_rounded,
                      label: 'MAX ALL LEVELS',
                      color: const Color(0xFFE879F9),
                      bgColor: const Color(0x33D946EF),
                      borderColor: const Color(0x4DD946EF),
                      onTap: () => provider.debugMaxProgress(),
                    ),
                    const SizedBox(height: 8),
                    _DebugButton(
                      icon: Icons.trending_up_rounded,
                      label: 'NEXT ANIMAL LEVEL',
                      color: const Color(0xFF60A5FA),
                      bgColor: const Color(0x333B82F6),
                      borderColor: const Color(0x4D3B82F6),
                      onTap: () => provider.debugNextAnimalLevel(),
                    ),
                    const SizedBox(height: 8),
                    _DebugButton(
                      icon: Icons.celebration_rounded,
                      label: 'SIMULATE PERFECT SESSION',
                      color: const Color(0xFFF472B6),
                      bgColor: const Color(0x33EC4899),
                      borderColor: const Color(0x4DEC4899),
                      onTap: onSimulatePerfect,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: Colors.white.withAlpha(102),
        letterSpacing: 2,
      ),
    ),
  );

  Widget _legalRow(BuildContext context, String title, IconData icon, Widget screen) => GestureDetector(
    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)),
    child: _blurCard(
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(13),
            border: Border.all(color: Colors.white.withAlpha(20)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white70, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(title, maxLines: 1, softWrap: false, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.4)),
          ),
        ),
        Icon(Icons.chevron_right_rounded, color: Colors.white.withAlpha(51)),
      ]),
    ),
  );

  Widget _card({required Widget child, List<BoxShadow>? shadow}) => RepaintBoundary(
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1625),
        border: Border.all(color: Colors.white.withAlpha(13)),
        borderRadius: BorderRadius.circular(32),
        boxShadow: shadow,
      ),
      child: child,
    ),
  );

  // No BackdropFilter: a real-time backdrop blur can't be cached and re-samples
  // the content behind it every frame, which stuttered the scroll. Over the dark
  // background the blur was barely visible anyway — a slightly more opaque fill
  // looks the same and lets the whole card cache into one layer for smooth scroll.
  Widget _blurCard({required Widget child}) => RepaintBoundary(
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xF01B1729),
        border: Border.all(color: Colors.white.withAlpha(13)),
        borderRadius: BorderRadius.circular(32),
      ),
      child: child,
    ),
  );

  void _confirmReset(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1625),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear All Data?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        content: const Text('This will permanently delete all your progress and stats.',
            style: TextStyle(color: Colors.white54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () { provider.resetAll(); Navigator.pop(context); },
            child: const Text('Clear', style: TextStyle(color: Color(0xFFFB7185), fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

// Toggle card: make the in-game piano keyboard start on the current tonic.
class _KeyboardFromTonicCard extends StatelessWidget {
  final AppProvider provider;
  const _KeyboardFromTonicCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final on = provider.keyboardFromTonic;
    const accent = Color(0xFF14B8A6); // teal
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => provider.setKeyboardFromTonic(!on),
      child: AnimatedContainer(
        duration: Duration.zero,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: on
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0x4D14B8A6), Color(0x1414B8A6)],
                )
              : null,
          color: on ? null : Colors.white.withAlpha(8),
          border: Border.all(color: on ? const Color(0x6614B8A6) : Colors.white.withAlpha(13)),
          borderRadius: BorderRadius.circular(24),
          boxShadow: on ? [const BoxShadow(color: Color(0x2614B8A6), blurRadius: 30)] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: on ? accent : Colors.white.withAlpha(26),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: on ? [const BoxShadow(color: Color(0x6614B8A6), blurRadius: 25)] : null,
                  ),
                  child: Icon(Icons.piano_rounded,
                      color: on ? Colors.white : Colors.white.withAlpha(102), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Keyboard from Tonic',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: on ? Colors.white : Colors.white.withAlpha(179),
                            letterSpacing: 0.4,
                          )),
                      const SizedBox(height: 3),
                      Text('PIANO INPUT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withAlpha(102),
                            letterSpacing: 1.5,
                          )),
                    ],
                  ),
                ),
                _ToggleSwitch(value: on, color: const Color(0xFF14B8A6)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'When the on-screen piano is active, it starts on the current key’s tonic (or the white key just below it) instead of always running from C.',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withAlpha(102),
                height: 18 / 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleSwitch extends StatelessWidget {
  final bool value;
  final Color color;
  const _ToggleSwitch({required this.value, this.color = const Color(0xFF3B82F6)});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      // The pill background fades smoothly while the thumb springs across.
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      width: 56,
      height: 28,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: value ? color : Colors.white.withAlpha(26),
        border: Border.all(color: value ? color.withAlpha(128) : Colors.white.withAlpha(26)),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: AnimatedAlign(
        // Springy, native-feeling thumb slide (slight settle at the end).
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 20, height: 20,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Color(0x66000000), blurRadius: 10, offset: Offset(0, 2))],
          ),
          child: value
              ? Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                )
              : null,
        ),
      ),
    );
  }
}

class _NotationTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NotationTab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              // AnimatedDefaultTextStyle replaces the inherited style, so the
              // font family must be set explicitly or it falls back to Roboto.
              style: TextStyle(
                fontFamily: 'Lexend',
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                color: selected ? Colors.white : Colors.white.withAlpha(77),
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}

// "Coming Soon" preview: three small note-cards that float up while pulsing
// opacity, with a radial pulse behind them — matches the original web app.
class _ComingSoonPreview extends StatefulWidget {
  const _ComingSoonPreview();

  @override
  State<_ComingSoonPreview> createState() => _ComingSoonPreviewState();
}

class _ComingSoonPreviewState extends State<_ComingSoonPreview> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        // Center radial pulse (animate-pulse).
        final pulse = 0.4 + 0.6 * (1 - math.cos(_c.value * 2 * math.pi)) / 2;
        return Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: pulse,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        radius: 0.7,
                        colors: [Color(0x1AFFFFFF), Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    _noteCard(i),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // Small card that floats up 10px while pulsing opacity, staggered per index.
  Widget _noteCard(int i) {
    final w = (1 - math.cos((_c.value - i * 0.2) * 2 * math.pi)) / 2; // 0..1
    return Transform.translate(
      offset: Offset(0, -10.0 * w),
      child: Opacity(
        opacity: 0.3 + 0.7 * w,
        child: Container(
          width: 32, height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withAlpha(51)),
          ),
          child: Icon(Icons.music_note_rounded, size: 16, color: Colors.white.withAlpha(102)),
        ),
      ),
    );
  }
}

// "Scales Coming Soon" preview: seven ascending bars (scale degrees) that
// light up in a rising wave, with a glowing dot gliding along their tops —
// like a scale run climbing the keyboard.
class _ScalesComingSoonPreview extends StatefulWidget {
  const _ScalesComingSoonPreview();

  @override
  State<_ScalesComingSoonPreview> createState() => _ScalesComingSoonPreviewState();
}

class _ScalesComingSoonPreviewState extends State<_ScalesComingSoonPreview> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  static const _barColors = [
    Color(0xFF22D3EE), Color(0xFF38BDF8), Color(0xFF818CF8),
    Color(0xFFA78BFA), Color(0xFFC084FC), Color(0xFFE879F9), Color(0xFFF472B6),
  ];

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value; // 0..1
        return Stack(
          children: [
            // Soft sweep of light following the run
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.5,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(-1.0 + 2.0 * t, 0.2),
                        radius: 0.6,
                        colors: const [Color(0x26FFFFFF), Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (int i = 0; i < 7; i++) ...[
                    if (i > 0) const SizedBox(width: 7),
                    _bar(i, t),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // Each bar glows when the "run" passes over it. Bars ascend in height like
  // a scale; the pulse travels left→right and fades behind itself.
  Widget _bar(int i, double t) {
    final pos = t * 8.4; // travelling pulse position, with dwell past the last bar
    final dist = (pos - i).abs();
    final glow = (1 - dist / 1.6).clamp(0.0, 1.0);

    final baseH = 18.0 + i * 5.5; // ascending staircase
    final h = baseH + glow * 10;
    final color = _barColors[i];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Glowing dot hovering on the active bar
        Opacity(
          opacity: glow,
          child: Container(
            width: 6, height: 6,
            margin: const EdgeInsets.only(bottom: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [BoxShadow(color: color.withAlpha(220), blurRadius: 10, spreadRadius: 1)],
            ),
          ),
        ),
        Container(
          width: 14,
          height: h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(color.withAlpha(70), color, glow)!,
                color.withAlpha(30 + (glow * 60).round()),
              ],
            ),
            border: Border.all(color: color.withAlpha(40 + (glow * 120).round())),
            boxShadow: glow > 0.05
                ? [BoxShadow(color: color.withAlpha((glow * 140).round()), blurRadius: 14)]
                : null,
          ),
        ),
      ],
    );
  }
}

class _DebugButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _DebugButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
