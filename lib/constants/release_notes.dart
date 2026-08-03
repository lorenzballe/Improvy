import 'package:flutter/material.dart';

/// One numbered entry of a release.
class ReleaseLine {
  final IconData? icon;

  /// Musical glyph shown instead of [icon] — set one or the other. Rendered in
  /// NotoMusic so ♯ and ♭ keep the shapes the rest of the app uses.
  final String? glyph;
  final Color color;
  final String title;
  final String detail;

  /// Marks the entry with the gold PRO chip.
  final bool pro;

  const ReleaseLine({
    this.icon,
    this.glyph,
    required this.color,
    required this.title,
    required this.detail,
    this.pro = false,
  }) : assert(icon != null || glyph != null, 'a line needs an icon or a glyph');
}

/// What shipped in one version.
class Release {
  /// Must match `version:` in pubspec.yaml, without the build number.
  final String version;

  /// Shown small beside the version, e.g. '2 AUG 2026'. Written by hand so it
  /// says the release date, not the day the sheet happens to be read.
  final String date;

  /// One sentence under the title — the release in a breath.
  final String headline;

  /// Three entries fit without scrolling, and a fourth still does. Beyond that
  /// the list scrolls rather than shrinking the type.
  final List<ReleaseLine> lines;

  const Release({
    required this.version,
    required this.date,
    required this.headline,
    required this.lines,
  });
}

/// Every release worth telling the user about, **newest first**.
///
/// [kReleases].first is "the current version", so adding an entry here is what
/// makes the What's New sheet appear after an update. Deliberately hand-written
/// rather than read from the binary — the user reads these sentences, and only
/// a human should write them.
///
/// Housekeeping when you ship:
///   1. bump `version:` in pubspec.yaml
///   2. add an entry here with the SAME version string
/// Skipping step 2 simply means that release passes without a sheet, which is
/// the right behaviour for a pure bug-fix build.
const List<Release> kReleases = [
  Release(
    version: '1.6.0',
    date: '2 AUG 2026',
    headline:
        'Eleven home-screen widgets, a map of every key you have touched, and '
        'a paywall that finally behaves.',
    lines: [
      ReleaseLine(
        icon: Icons.widgets_rounded,
        color: Color(0xFF6366F1),
        title: 'Widgets on your home screen',
        detail:
            'A question that changes every hour, the daily challenge, your '
            'streak, your weakest key — put any of them where you will see them.',
      ),
      ReleaseLine(
        glyph: '♯♭',
        color: Color(0xFFA855F7),
        title: 'Mastery, key by key',
        detail:
            'Twelve tiles showing where you actually stand, and a shortcut '
            'straight into the key you keep getting wrong.',
      ),
      ReleaseLine(
        icon: Icons.headphones_rounded,
        color: Color(0xFF34D399),
        title: 'Pocket Mode speaks properly',
        detail:
            'A real recorded voice instead of a synthetic one, and the keyboard '
            'names every note the way your current key spells it.',
      ),
    ],
  ),
];
