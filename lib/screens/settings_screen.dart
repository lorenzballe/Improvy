import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kDebugMode, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_provider.dart';
import '../services/analytics_service.dart';
import '../constants/app_info.dart';
import '../constants/release_notes.dart';
import '../services/purchase_service.dart';
import '../services/review_service.dart';
import '../services/backup_service.dart';
import 'legal_screen.dart';
import 'free_mode_screen.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/feedback_sheet.dart';

/// Instagram's own mark — the rounded camera body, the lens and the flash dot.
/// Drawn as strokes so it stays crisp at any size, and tinted white by the
/// caller: worn on Instagram's gradient tile, which is how their brand
/// guidelines say to present it when linking to a profile.
const String _kInstagramGlyph =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
    'stroke="#000000" stroke-width="2" stroke-linecap="round" '
    'stroke-linejoin="round">'
    '<rect width="20" height="20" x="2" y="2" rx="5" ry="5"/>'
    '<path d="M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z"/>'
    '<line x1="17.5" x2="17.51" y1="6.5" y2="6.5"/>'
    '</svg>';

class SettingsScreen extends StatelessWidget {
  final void Function([String? reason]) onShowPaywall;
  final VoidCallback onSimulatePerfect;
  const SettingsScreen({super.key, required this.onShowPaywall, required this.onSimulatePerfect});

  /// A confirmation the user can actually see.
  ///
  /// The default here was the surface colour — the same `0xFF1A1625` as every
  /// card on the screen — on a bar that floats at the very bottom, where the
  /// tab bar already sits. So "Sent." was invisible twice over: the wrong
  /// colour, in the wrong place. This wears the accent the SEND button uses
  /// and is lifted clear of the nav.
  static void _toast(BuildContext context, String message, {IconData? icon}) {
    // 24 is where the nav is anchored, ~78 is how tall it stands.
    final lift = 24.0 + 78.0 + MediaQuery.of(context).padding.bottom;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF4F46E5),
        elevation: 12,
        duration: const Duration(seconds: 3),
        margin: EdgeInsets.fromLTRB(20, 0, 20, lift),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  /// Hands the address to the OS mail app. If the device has no mail client
  /// set up nothing opens, so the row shows the address itself — the user can
  /// still read it and write from wherever they like.
  static Future<void> _contactSupport(BuildContext context) async {
    try {
      final ok = await launchUrl(
        Uri.parse(kSupportMailto),
        mode: LaunchMode.externalApplication,
      );
      if (ok || !context.mounted) return;
    } catch (_) {
      if (!context.mounted) return;
    }
    _toast(context, context.l10n.settingsWriteTo(kSupportEmail), icon: Icons.mail_rounded);
  }

  /// Opens the developer's Instagram — the installed app when the OS resolves
  /// the universal link, the browser otherwise.
  ///
  /// Same contract as [_contactSupport]: a device that cannot open it must not
  /// leave the tap silently doing nothing, so the handle is spelled out and the
  /// user can find it themselves.
  static Future<void> _openInstagram(BuildContext context) async {
    try {
      final ok = await launchUrl(
        Uri.parse(kInstagramUrl),
        mode: LaunchMode.externalApplication,
      );
      if (ok || !context.mounted) return;
    } catch (_) {
      if (!context.mounted) return;
    }
    _toast(context, context.l10n.settingsInstagram(kInstagramHandle));
  }

  /// Widgets are added from the OS home screen, not from inside an app — there
  /// is no API to place one. All the app can do is say where the button is,
  /// which is exactly what people look for after reading that widgets exist.
  static void _showWidgetHelp(BuildContext context) {
    final ios = defaultTargetPlatform == TargetPlatform.iOS;
    final steps = ios
        ? [
            context.l10n.settingsWidgetIos1,
            context.l10n.settingsWidgetIos2,
            context.l10n.settingsWidgetIos3,
          ]
        : [
            context.l10n.settingsWidgetIos1,
            context.l10n.settingsWidgetAndroid2,
            context.l10n.settingsWidgetAndroid3,
          ];
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withAlpha(160),
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1A1625),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: const BorderSide(color: Color(0x33FBBF24)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(context.l10n.settingsWidgetsTwo,
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w900,
                        letterSpacing: 2, color: Color(0xFFFCD34D))),
              ),
              const SizedBox(height: 16),
              _widgetBlurb(context.l10n.settingsWidgetQuestion, context.l10n.settingsWidgetQuestionBody),
              const SizedBox(height: 10),
              _widgetBlurb(context.l10n.settingsWidgetDaily, context.l10n.settingsWidgetDailyBody),
              const SizedBox(height: 20),
              Text(context.l10n.settingsWidgetHow,
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w900,
                      letterSpacing: 1.6, color: Colors.white.withAlpha(90))),
              const SizedBox(height: 10),
              for (var i = 0; i < steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${i + 1}',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w900,
                            color: Color(0xFFFBBF24))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(steps[i],
                          style: TextStyle(
                              fontSize: 13, height: 1.4,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withAlpha(190))),
                    ),
                  ]),
                ),
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(context.l10n.gotIt,
                      style: TextStyle(
                          fontWeight: FontWeight.w800, color: Color(0xFFFBBF24))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _widgetBlurb(String title, String body) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 2),
          Text(body,
              style: TextStyle(
                  fontSize: 12, height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withAlpha(140))),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      // Transparent so the root's living background shows through, shared with
      // the other tabs.
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          // Always rubber-bands, like the rest of the app — without this the
          // list only bounces on platforms whose default physics do, and sits
          // dead still everywhere else.
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: EdgeInsets.fromLTRB(24, 16, 24, 140 + MediaQuery.of(context).padding.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  context.l10n.settingsTitle,
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
              _sectionLabel(context.l10n.settingsAccountStatus),
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
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      provider.isPro ? context.l10n.settingsProPlan : context.l10n.settingsFreePlan,
                                      maxLines: 1,
                                      softWrap: false,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: -0.75,
                                      ),
                                    ),
                                  ),
                                ),
                                if (provider.isPro) ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFBBF24), size: 24),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              provider.isPro
                                  ? context.l10n.settingsProSub
                                  : context.l10n.settingsFreeSub,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withAlpha(120),
                                height: 1.3,
                              ),
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
                          provider.isPro ? context.l10n.settingsActive : context.l10n.free,
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
              _sectionLabel(context.l10n.settingsTraining),
              const SizedBox(height: 12),
              _card(
                shadow: const [BoxShadow(color: Color(0x4D000000), blurRadius: 32, offset: Offset(0, 8))],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (!provider.isPro) {
                          AnalyticsService.instance.lockedFeature('adaptive_difficulty');
                          onShowPaywall();
                          return;
                        }
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
                                          context.l10n.settingsAdaptive,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                            color: provider.adaptiveDifficulty ? Colors.white : Colors.white.withAlpha(179),
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          context.l10n.settingsAdaptiveTag,
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
                                    ? context.l10n.settingsAdaptiveBody
                                    : context.l10n.settingsAdaptiveLocked,
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

                    _SimpleNotesCard(provider: provider),
                    const SizedBox(height: 12),
                    _KeyboardFromTonicCard(provider: provider),
                    const SizedBox(height: 10),
                    _AnswerSoundCard(provider: provider),
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
                          context.l10n.settingsNotation,
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

              // FREE MODE
              _sectionLabel(context.l10n.settingsFreeMode),
              const SizedBox(height: 12),
              _freeModeRow(context),
              const SizedBox(height: 16),

              // NOTIFICATIONS
              _sectionLabel(context.l10n.settingsNotifications),
              const SizedBox(height: 12),
              _NotificationsCard(provider: provider),
              const SizedBox(height: 16),

              // NEWS & UPDATES
              _sectionLabel(context.l10n.settingsNews),
              const SizedBox(height: 12),
              // Release notes for the version actually installed.
              if (kReleases.isNotEmpty) ...[
                GestureDetector(
                  onTap: provider.openWhatsNew,
                  behavior: HitTestBehavior.opaque,
                  child: _card(
                    shadow: const [BoxShadow(color: Color(0x4D000000), blurRadius: 32, offset: Offset(0, 8))],
                    child: Row(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF2563EB), Color(0xFFA855F7)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
                            ),
                            if (provider.hasUnseenRelease)
                              Positioned(
                                top: -3, right: -3,
                                child: Container(
                                  width: 12, height: 12,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF1A1625), width: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      context.l10n.settingsWhatsNew,
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(20),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'v${kReleases.first.version}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white.withAlpha(140),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                kReleases.first.headline,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withAlpha(128),
                                  height: 18 / 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_right_rounded, color: Colors.white.withAlpha(90), size: 22),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // STORE
              _sectionLabel(context.l10n.settingsStore),
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.star_rounded, color: Colors.white, size: 16),
                              SizedBox(width: 8),
                              Text(context.l10n.settingsUpgrade, style: TextStyle(
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
                            content: Text(ok ? context.l10n.settingsProRestored : context.l10n.paywallNoPurchase),
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.restore_rounded, color: Color(0xFFFBBF24), size: 16),
                            SizedBox(width: 8),
                            // Scaled, not clipped: at the largest type size
                            // this label is a pixel wider than the button.
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(context.l10n.settingsRestorePurchases, maxLines: 1, softWrap: false, style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700,
                                  color: Color(0xFFFBBF24), letterSpacing: 0.6,
                                )),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // HOME SCREEN — widgets can only be placed from the launcher, so
              // this row explains rather than acts.
              if (!kIsWeb) ...[
                _sectionLabel(context.l10n.settingsHomeScreen),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _showWidgetHelp(context),
                  child: _blurCard(
                    child: Row(
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0x3322D3EE),
                            border: Border.all(color: const Color(0x3322D3EE)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.widgets_rounded,
                              color: Color(0xFF22D3EE), size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  context.l10n.settingsWidgets,
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
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  context.l10n.settingsWidgetsSub,
                                  maxLines: 1,
                                  softWrap: false,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF22D3EE),
                                  ),
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
              ],

              // SUPPORT
              _sectionLabel(context.l10n.settingsBackup),
              const SizedBox(height: 12),
              _backupRow(
                context,
                icon: Icons.upload_rounded,
                title: context.l10n.settingsExport,
                subtitle: context.l10n.settingsExportSub,
                onTap: () async {
                  final ok = await BackupService.instance.export(provider.storage);
                  if (!ok && context.mounted) {
                    _toast(context, context.l10n.settingsExportFailed, icon: Icons.error_outline_rounded);
                  }
                },
              ),
              const SizedBox(height: 10),
              _backupRow(
                context,
                icon: Icons.download_rounded,
                title: context.l10n.settingsRestoreFile,
                subtitle: context.l10n.settingsRestoreFileSub,
                onTap: () async {
                  final go = await _confirmRestore(context);
                  if (go != true || !context.mounted) return;
                  final err = await BackupService.instance.import(provider.storage);
                  if (!context.mounted) return;
                  if (err == null) {
                    await provider.reloadFromStorage();
                    if (context.mounted) {
                      _toast(context, context.l10n.settingsRestored,
                          icon: Icons.check_circle_rounded);
                    }
                  } else if (err.isNotEmpty) {
                    _toast(context, err, icon: Icons.error_outline_rounded);
                  }
                },
              ),
              const SizedBox(height: 28),

              _sectionLabel(context.l10n.settingsSupport),
              const SizedBox(height: 12),
              // Hidden until the store listing is reachable (iOS needs
              // kAppStoreId) — a row that goes nowhere is worse than no row.
              if (ReviewService.instance.canOpenStoreListing) ...[
                GestureDetector(
                  onTap: () => ReviewService.instance.openStoreListing(),
                  child: _blurCard(
                    child: Row(
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0x33FBBF24),
                            border: Border.all(color: const Color(0x33FBBF24)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  context.l10n.settingsRate,
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
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  context.l10n.settingsRateSub,
                                  maxLines: 1,
                                  softWrap: false,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFFBBF24),
                                  ),
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
                const SizedBox(height: 10),
              ],
              _feedbackRow(context),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _contactSupport(context),
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
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                context.l10n.settingsContact,
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
                            // The address is spelled out, not just implied by
                            // the tap: it's the same one published on the site.
                            const FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                kSupportEmail,
                                maxLines: 1,
                                softWrap: false,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFFBBF24),
                                ),
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
              const SizedBox(height: 10),
              // The person behind the app. Instagram's gradient is its own, not
              // the app's palette, so it is worn only by the small icon tile —
              // the same restraint every other row here shows.
              PressableScale(
                onTap: () => _openInstagram(context),
                child: _blurCard(
                  child: Row(
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                            colors: [Color(0xFFF9CE34), Color(0xFFEE2A7B), Color(0xFF6228D7)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: SvgPicture.string(
                            _kInstagramGlyph,
                            width: 18, height: 18,
                            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                context.l10n.settingsFollow,
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
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '@$kInstagramHandle',
                                maxLines: 1,
                                softWrap: false,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFEE2A7B),
                                ),
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
              _sectionLabel(context.l10n.settingsLegal),
              const SizedBox(height: 12),
              _legalRow(context, context.l10n.privacyPolicy, Icons.privacy_tip_rounded,
                  LegalScreen(title: context.l10n.privacyPolicy, body: kPrivacyPolicyBody)),
              const SizedBox(height: 10),
              _legalRow(context, context.l10n.termsOfService, Icons.description_rounded,
                  LegalScreen(title: context.l10n.termsOfService, body: kTermsBody)),
              const SizedBox(height: 16),

              // DEVELOPER DEBUG — shown in debug builds, and on the web
              // preview only when asked for with ?dev=1 on the address. The
              // preview is a public page and this section has an "Enable PRO"
              // switch on it; the old rule showed it to anyone who scrolled
              // down, which made the site a free Pro copy of the app for the
              // cost of finding the button. Never in a native release, where
              // kIsWeb is false.
              if (kDebugMode ||
                  (kIsWeb && Uri.base.queryParameters['dev'] == '1')) ...[
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
                    const SizedBox(height: 8),
                    _DebugButton(
                      icon: Icons.notifications_active_rounded,
                      label: 'SEND TEST NOTIFICATION',
                      color: const Color(0xFFFBBF24),
                      bgColor: const Color(0x33F59E0B),
                      borderColor: const Color(0x4DF59E0B),
                      onTap: () => provider.sendTestNotification(),
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

  /// Entry point for Free Mode — deliberately the one rainbow row in Settings,
  /// because it is the one thing here that is a place to go rather than a
  /// switch to flip.
  Widget _freeModeRow(BuildContext context) => PressableScale(
    onTap: () => Navigator.of(context).push(
      // Fades and lifts in, and plays the same motion backwards on the way
      // out, so entering and leaving the mode both read as a transition.
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, __, ___) => const FreeModeScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
      ),
    ),
    child: _blurCard(
      child: Row(children: [
        // No tile behind it — the star sits straight on the card, which is
        // also why it can be set larger than the boxed icons on other rows
        // and still balance them. Same 32px slot, so the titles stay aligned.
        //
        // Banded rather than blended, and filled in over the whole slot: a
        // smooth six-stop gradient over a glyph this size spends its width on
        // the hand-offs and comes out muddy, which is what stopped it reading
        // as a rainbow.
        SizedBox(
          width: 32, height: 32,
          child: ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (b) => freeSpectrumWheel().createShader(b),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.l10n.settingsFreeModeTitle,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.4)),
              const SizedBox(height: 2),
              Text(context.l10n.settingsFreeModeSub,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Colors.white.withAlpha(115))),
            ],
          ),
        ),
        Icon(Icons.chevron_right_rounded, color: Colors.white.withAlpha(51)),
      ]),
    ),
  );

  Widget _backupRow(BuildContext context,
          {required IconData icon,
          required String title,
          required String subtitle,
          required VoidCallback onTap}) =>
      PressableScale(
        onTap: onTap,
        child: _blurCard(
          child: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: const Color(0x3322D3EE),
                border: Border.all(color: const Color(0x3322D3EE)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF22D3EE), size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          color: Colors.white, letterSpacing: 0.4)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: Colors.white.withAlpha(115))),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.white.withAlpha(51)),
          ]),
        ),
      );

  /// Restoring overwrites; say so before, not after.
  Future<bool?> _confirmRestore(BuildContext context) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1625),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(context.l10n.settingsRestoreTitle,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          content: Text(
              context.l10n.settingsRestoreBody,
              style: TextStyle(color: Colors.white54, height: 1.4)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.cancel, style: const TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.l10n.settingsChooseFile,
                  style: TextStyle(color: Color(0xFF22D3EE), fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      );

  /// The one support row that cannot fail to open. Contact Support hands the
  /// message to a mail app the phone may not have set up; this is a box and a
  /// button, and it arrives whether or not the user owns an email client.
  Widget _feedbackRow(BuildContext context) => PressableScale(
        onTap: () async {
          final sent = await FeedbackSheet.show(context, source: 'settings');
          if (!sent || !context.mounted) return;
          _toast(context, context.l10n.settingsFeedbackSent,
              icon: Icons.check_circle_rounded);
        },
        child: _blurCard(
          child: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: const Color(0x334F46E5),
                border: Border.all(color: const Color(0x334F46E5)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.forum_rounded, color: Color(0xFF818CF8), size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      context.l10n.settingsFeedback,
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
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      context.l10n.settingsFeedbackSub,
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF818CF8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.white.withAlpha(51)),
          ]),
        ),
      );

  Widget _legalRow(BuildContext context, String title, IconData icon, Widget screen) => PressableScale(
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
        title: Text(context.l10n.settingsClearTitle, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        content: Text(context.l10n.settingsClearBody,
            style: TextStyle(color: Colors.white54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel, style: const TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () { provider.resetAll(); Navigator.pop(context); },
            child: Text(context.l10n.clear, style: const TextStyle(color: Color(0xFFFB7185), fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

// Toggle card: make the in-game piano keyboard start on the current tonic.
/// "Simple note names": one spelling per pitch class, everywhere.
///
/// Key-correct spelling is what a musician eventually needs — the ♭2 of E♭
/// really is F♭ — but it means the same piano key is labelled E in one session
/// and F♭ in the next, and the chromatic buttons carry slashed pairs. This
/// switches the whole app to the twelve names most players write:
/// C D♭ D E♭ E F F♯ G A♭ A B♭ B.
class _SimpleNotesCard extends StatelessWidget {
  final AppProvider provider;
  const _SimpleNotesCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final on = provider.simpleNotes;
    const accent = Color(0xFF8B5CF6); // violet
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => provider.setSimpleNotes(!on),
      child: AnimatedContainer(
        duration: Duration.zero,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: on
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0x4D8B5CF6), Color(0x148B5CF6)],
                )
              : null,
          color: on ? null : Colors.white.withAlpha(8),
          border: Border.all(color: on ? const Color(0x668B5CF6) : Colors.white.withAlpha(13)),
          borderRadius: BorderRadius.circular(24),
          boxShadow: on ? [const BoxShadow(color: Color(0x268B5CF6), blurRadius: 30)] : null,
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
                    boxShadow: on ? [const BoxShadow(color: Color(0x668B5CF6), blurRadius: 25)] : null,
                  ),
                  child: Icon(Icons.abc_rounded,
                      color: on ? Colors.white : Colors.white.withAlpha(102), size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.l10n.settingsSimpleNotes,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: on ? Colors.white : Colors.white.withAlpha(179),
                            letterSpacing: 0.4,
                          )),
                      const SizedBox(height: 3),
                      Text(context.l10n.settingsSimpleNotesTag,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withAlpha(102),
                            letterSpacing: 1.5,
                          )),
                    ],
                  ),
                ),
                _ToggleSwitch(value: on, color: accent),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.settingsSimpleNotesBody,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withAlpha(102),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The note itself on a correct answer. On by default — it is the lesson —
/// and switchable for a train carriage or a shared room.
class _AnswerSoundCard extends StatelessWidget {
  final AppProvider provider;
  const _AnswerSoundCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final on = provider.answerSound;
    const accent = Color(0xFF22D3EE); // cyan
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => provider.setAnswerSound(!on),
      child: AnimatedContainer(
        duration: Duration.zero,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: on
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0x4D22D3EE), Color(0x1422D3EE)],
                )
              : null,
          color: on ? null : Colors.white.withAlpha(8),
          border: Border.all(color: on ? const Color(0x6622D3EE) : Colors.white.withAlpha(13)),
          borderRadius: BorderRadius.circular(24),
          boxShadow: on ? [const BoxShadow(color: Color(0x2622D3EE), blurRadius: 30)] : null,
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
                    boxShadow: on ? [const BoxShadow(color: Color(0x6622D3EE), blurRadius: 25)] : null,
                  ),
                  child: Icon(Icons.music_note_rounded,
                      color: on ? Colors.white : Colors.white.withAlpha(102), size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.l10n.settingsHearNote,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: on ? Colors.white : Colors.white.withAlpha(179),
                            letterSpacing: 0.4,
                          )),
                      const SizedBox(height: 3),
                      Text(context.l10n.settingsHearNoteTag,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withAlpha(102),
                            letterSpacing: 1.5,
                          )),
                    ],
                  ),
                ),
                _ToggleSwitch(value: on, color: accent),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.settingsHearNoteBody,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withAlpha(102),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
                      Text(context.l10n.settingsKeyboardTonic,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: on ? Colors.white : Colors.white.withAlpha(179),
                            letterSpacing: 0.4,
                          )),
                      const SizedBox(height: 3),
                      Text(context.l10n.settingsKeyboardTonicTag,
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
              context.l10n.settingsKeyboardTonicBody,
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

// Notification controls — daily reminder on/off, its time, and comeback nudges.
// (The reminders themselves are built by AppProvider; this only flips the
// preferences and re-syncs the schedule.)
class _NotificationsCard extends StatelessWidget {
  final AppProvider provider;
  const _NotificationsCard({required this.provider});

  static const _accent = Color(0xFFF59E0B); // amber

  @override
  Widget build(BuildContext context) {
    final on = provider.notifDailyOn;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => provider.setNotifDailyOn(!on),
      child: AnimatedContainer(
        duration: Duration.zero,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: on
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0x4DF59E0B), Color(0x14F59E0B)],
                )
              : null,
          color: on ? null : Colors.white.withAlpha(8),
          border: Border.all(color: on ? const Color(0x66F59E0B) : Colors.white.withAlpha(13)),
          borderRadius: BorderRadius.circular(24),
          boxShadow: on ? [const BoxShadow(color: Color(0x26F59E0B), blurRadius: 30)] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: on ? _accent : Colors.white.withAlpha(26),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: on ? [const BoxShadow(color: Color(0x66F59E0B), blurRadius: 25)] : null,
                  ),
                  child: Icon(Icons.notifications_active_rounded,
                      color: on ? Colors.white : Colors.white.withAlpha(102), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.l10n.settingsReminders,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: on ? Colors.white : Colors.white.withAlpha(179),
                            letterSpacing: 0.4,
                          )),
                      const SizedBox(height: 3),
                      Text(context.l10n.settingsRemindersTag,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withAlpha(102),
                            letterSpacing: 1.5,
                          )),
                    ],
                  ),
                ),
                _ToggleSwitch(value: on, color: _accent),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.settingsRemindersBody,
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
    // The card around this is the tap target; the switch just has to tell a
    // screen reader which way it is.
    return Semantics(
      toggled: value,
      child: AnimatedContainer(
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
      child: PressableScale(
        onTap: onTap,
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
    return PressableScale(
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
            // Scaled rather than clipped: these labels are written by hand and
            // the longest one already overflows a narrow phone by 28px.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
