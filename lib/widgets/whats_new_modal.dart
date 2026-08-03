import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_info.dart';
import '../constants/release_notes.dart';

/// The "What's New" sheet — design 9c, *EDITORIAL*.
///
/// A bottom sheet rather than a centred card: it arrives from the edge the
/// thumb is already at, and the numbered list reads as a short column of
/// release notes instead of a feature grid. The indigo primary is the one the
/// app's own dialogs use.
///
/// Two ways out, and they mean different things: [onDismiss] closes but leaves
/// the badge lit (swiped away mid-thought), while [onRead] is the explicit
/// CONTINUE that records the version as read. Same distinction the provider
/// draws — see AppProvider.markReleaseSeen.
class WhatsNewModal extends StatefulWidget {
  final Release release;
  final VoidCallback onDismiss;
  final VoidCallback onRead;

  const WhatsNewModal({
    super.key,
    required this.release,
    required this.onDismiss,
    required this.onRead,
  });

  @override
  State<WhatsNewModal> createState() => _WhatsNewModalState();
}

class _WhatsNewModalState extends State<WhatsNewModal>
    with SingleTickerProviderStateMixin {
  static const _gold = Color(0xFFFCD34D);
  static const _indigo = Color(0xFF4F46E5);
  static const _sheet = Color(0xFF1A1625);

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  )..forward();

  late final Animation<double> _rise = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _openChangelog() async {
    try {
      await launchUrl(Uri.parse(kWebsiteUrl), mode: LaunchMode.externalApplication);
    } catch (_) {
      // No browser to hand it to: the sheet stays put rather than pretending
      // something happened.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Positioned.fill(
        child: GestureDetector(
          onTap: widget.onDismiss,
          child: FadeTransition(
            opacity: _rise,
            child: Container(color: const Color(0xBD06030C)),
          ),
        ),
      ),
      Align(
        alignment: Alignment.bottomCenter,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(_rise),
          child: _sheetBody(context),
        ),
      ),
    ]);
  }

  Widget _sheetBody(BuildContext context) {
    final r = widget.release;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    // Never taller than most of the screen: past that the list scrolls instead
    // of the type getting smaller.
    final maxHeight = MediaQuery.of(context).size.height * 0.88;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: _sheet,
        border: Border(top: BorderSide(color: Color(0x1AFFFFFF))),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0xCC000000),
            blurRadius: 60,
            spreadRadius: -20,
            offset: Offset(0, -30),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _versionRule(r),
                const SizedBox(height: 22),
                // Two lines by design: the version claims the first, so the
                // sentence lands rather than trailing off.
                Text(
                  'Version ${r.version}\nis here',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 34,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -1,
                    height: 1.06,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  r.headline,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.55,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < r.lines.length; i++) ...[
                    if (i > 0) const Divider(height: 1, thickness: 1, color: Color(0x13FFFFFF)),
                    _entry(i + 1, r.lines[i]),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 30 + bottomInset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: widget.onRead,
                  child: Container(
                    height: 54,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _indigo,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'CONTINUE',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.4,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: _openChangelog,
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    'Full changelog',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.38),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// VERSION 1.6.0 ——————————————— 2 AUG 2026
  Widget _versionRule(Release r) => Row(
        children: [
          Text(
            'VERSION ${r.version}',
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.9,
              color: _gold,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0x66FCD34D), Color(0x00FCD34D)],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            r.date,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.57,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
        ],
      );

  Widget _entry(int number, ReleaseLine line) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 22,
              child: Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  number.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: line.color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (line.glyph != null)
                        Text(
                          line.glyph!,
                          style: TextStyle(
                            fontFamily: 'NotoMusic',
                            fontSize: 16,
                            height: 1,
                            color: line.color,
                          ),
                        )
                      else
                        Icon(line.icon, size: 17, color: line.color),
                      const SizedBox(width: 9),
                      Flexible(
                        child: Text(
                          line.title,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (line.pro) ...[
                        const SizedBox(width: 9),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _gold.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.85,
                              color: _gold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    line.detail,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.55,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
