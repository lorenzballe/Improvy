import 'dart:ui';
import 'package:flutter/material.dart';

import '../constants/release_notes.dart';

/// The "What's New" sheet, shown once after an update and re-openable from
/// Settings.
///
/// Two ways out, and they mean different things: [onDismiss] closes but leaves
/// the badge lit (the user swiped it away mid-thought), while [onRead] is the
/// explicit "Got it" that records the version as read. Same distinction the
/// provider draws — see AppProvider.markReleaseSeen.
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
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Staggered entrance: the card lands, then each line arrives behind it.
  Animation<double> _step(double begin, double end) => CurvedAnimation(
        parent: _c,
        curve: Interval(begin, end, curve: Curves.easeOutCubic),
      );

  Widget _fadeUp(Animation<double> a, {required Widget child}) =>
      AnimatedBuilder(
        animation: a,
        builder: (_, c) => Opacity(
          opacity: a.value.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, 14 * (1 - a.value)), child: c),
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final lines = widget.release.lines;
    return Stack(children: [
      Positioned.fill(
        child: GestureDetector(
          onTap: widget.onDismiss,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(color: Colors.black.withValues(alpha: 0.6)),
          ),
        ),
      ),
      Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 40),
          child: _fadeUp(
            _step(0.0, 0.5),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1625),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header — the mark, the version, the promise.
                  Row(children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFFA855F7)],
                        ),
                        borderRadius: BorderRadius.circular(17),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFA855F7).withValues(alpha: 0.35),
                            blurRadius: 22,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.auto_awesome_rounded,
                          color: Colors.white, size: 27),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "What's new",
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.3,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Version ${widget.release.version}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.45),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _fadeUp(
                    _step(0.08, 0.58),
                    child: Text(
                      widget.release.headline,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // The list itself scrolls, so a long release never pushes the
                  // button off a short screen.
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < lines.length; i++)
                            _fadeUp(
                              _step(
                                (0.16 + i * 0.07).clamp(0.0, 0.85),
                                (0.66 + i * 0.07).clamp(0.15, 1.0),
                              ),
                              child: Padding(
                                padding: EdgeInsets.only(
                                    bottom: i == lines.length - 1 ? 0 : 16),
                                child: _ReleaseRow(line: lines[i]),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _fadeUp(
                    _step(0.4, 1.0),
                    child: GestureDetector(
                      onTap: widget.onRead,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Got it',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}

class _ReleaseRow extends StatelessWidget {
  final ReleaseLine line;
  const _ReleaseRow({required this.line});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: line.color.withValues(alpha: 0.16),
            border: Border.all(color: line.color.withValues(alpha: 0.22)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(line.icon, color: line.color, size: 19),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                line.title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                line.detail,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.5,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
