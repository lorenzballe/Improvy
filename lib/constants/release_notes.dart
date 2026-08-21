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
    version: '1.9.0',
    date: '21 AUG 2026',
    headline:
        'Pocket Mode now speaks Italian, and the English voice has been '
        're-recorded.',
    lines: [
      ReleaseLine(
        icon: Icons.record_voice_over_rounded,
        color: Color(0xFF34D399),
        title: 'It speaks your notes',
        detail:
            'Set the note names to Do-Re-Mi and the voice switches to Italian '
            'as well — questions, keys and answers. What is on screen and '
            'what is in your ear are finally the same words.',
      ),
      ReleaseLine(
        glyph: '♯♭',
        color: Color(0xFF818CF8),
        title: 'A clearer English voice',
        detail:
            'Every note name re-recorded, from C to G double sharp. The '
            'numbers are unchanged.',
      ),
    ],
  ),
  Release(
    version: '1.8.5',
    date: '20 AUG 2026',
    headline:
        'There is now a place to tell us what is wrong with this app, and it '
        'does not need your email.',
    lines: [
      ReleaseLine(
        icon: Icons.forum_rounded,
        color: Color(0xFF818CF8),
        title: 'Say it from inside the app',
        detail:
            'Settings, under Support. A box and a button — no mail app, no '
            'account, no name attached unless you write one. Leave an email '
            'only if you want an answer back.',
      ),
    ],
  ),
  Release(
    version: '1.8.4',
    date: '17 AUG 2026',
    headline:
        'The daily challenge now asks all three directions, and Pocket Mode '
        'lets you drill one spelling at a time.',
    lines: [
      ReleaseLine(
        icon: Icons.local_fire_department_rounded,
        color: Color(0xFFE5A93C),
        title: 'A new challenge every day',
        detail:
            'Some days you name the note for a degree, some days the degree '
            'for a note, some days the root a note belongs to. Same run for '
            'everyone, whichever one it is.',
      ),
      ReleaseLine(
        glyph: '♯♭',
        color: Color(0xFF6366F1),
        title: 'One spelling at a time',
        detail:
            'Train ♭5 without ♯4, or ♯2 without ♭3 — every spelling is its own '
            'button, and its own recording. The answer delay now goes down to '
            '0.3 seconds.',
      ),
      ReleaseLine(
        icon: Icons.swap_horiz_rounded,
        color: Color(0xFF34D399),
        title: 'Note to Number is free',
        detail:
            'All twelve keys, diatonic, no Pro needed. It is the one direction '
            'where the buttons cannot hint at the answer, so it is the honest '
            'way to learn a scale.',
      ),
      ReleaseLine(
        icon: Icons.piano_rounded,
        color: Color(0xFFF43F5E),
        title: 'The keyboard stops helping',
        detail:
            'Apprentice still lights the scale. Above it every key is live, so '
            'no question can be answered by counting — and Master takes the '
            'note names off, like a real piano.',
      ),
      ReleaseLine(
        icon: Icons.headphones_rounded,
        color: Color(0xFF34D399),
        title: 'Plays with the screen off',
        detail:
            'It kept stopping the moment the phone locked. It no longer does, '
            'so a walk really is a practice session.',
      ),
    ],
  ),
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
