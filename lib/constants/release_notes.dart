import 'package:flutter/material.dart';

/// One line of a release — an icon, a headline and a sentence of detail.
class ReleaseLine {
  final IconData icon;
  final Color color;
  final String title;
  final String detail;

  const ReleaseLine({
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
  });
}

/// What shipped in one version.
class Release {
  /// Must match `version:` in pubspec.yaml, without the build number.
  final String version;

  /// Short banner line shown under the version — the release in one breath.
  final String headline;
  final List<ReleaseLine> lines;

  const Release({
    required this.version,
    required this.headline,
    required this.lines,
  });
}

/// Every release worth telling the user about, **newest first**.
///
/// This list is the source of truth for the What's New sheet: [kReleases].first
/// is "the current version", so adding an entry here is what makes the sheet
/// appear after an update. Deliberately hand-written rather than read from the
/// binary — the user reads these sentences, and only a human should write them.
///
/// Housekeeping when you ship:
///   1. bump `version:` in pubspec.yaml
///   2. add an entry here with the SAME version string
/// Skipping step 2 simply means that release passes without a sheet, which is
/// the right behaviour for a pure bug-fix build.
const List<Release> kReleases = [
  Release(
    version: '1.6.0',
    headline: 'Home-screen widgets, and a calmer paywall.',
    lines: [
      ReleaseLine(
        icon: Icons.widgets_rounded,
        color: Color(0xFF34D399),
        title: 'Home-screen widgets',
        detail:
            'Add Improvy to your home screen: a scale degree to answer every '
            'hour, and the Daily Challenge with your streak.',
      ),
      ReleaseLine(
        icon: Icons.notifications_active_rounded,
        color: Color(0xFF22D3EE),
        title: 'Smarter reminders',
        detail:
            'Daily nudges now arrive as a question to answer, not a nag — and '
            'your streak gets a warning before it breaks.',
      ),
      ReleaseLine(
        icon: Icons.headphones_rounded,
        color: Color(0xFFA855F7),
        title: 'Pocket Mode speaks properly',
        detail:
            'A real recorded voice instead of a synthetic one, and the keyboard '
            'now names every note the way your current key spells it.',
      ),
      ReleaseLine(
        icon: Icons.auto_awesome_rounded,
        color: Color(0xFFF59E0B),
        title: 'Perfect-session celebration',
        detail:
            'Finish a session without a single mistake and the whole screen '
            'answers you in colour.',
      ),
    ],
  ),
];
