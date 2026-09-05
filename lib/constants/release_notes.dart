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
    version: '1.16.0',
    date: '4 SEP 2026',
    headline: 'The home-screen widgets, rebuilt — and on iPhone, built at all.',
    lines: [
      ReleaseLine(
        icon: Icons.widgets_rounded,
        color: Color(0xFF22D3EE),
        title: 'Twelve widgets on iPhone',
        detail:
            'There were none. The widget extension had never been added to the '
            'iOS project, so nothing Improvy wrote ever reached a home screen. '
            'All twelve are there now: the hourly question, the daily, the key '
            'map, your level, the streak, the weakest key and the rest.',
      ),
      ReleaseLine(
        icon: Icons.auto_awesome_rounded,
        color: Color(0xFFA855F7),
        title: 'A design, not a dark rectangle',
        detail:
            'Every widget wears its own accent — a glow from the top corner and '
            'an edge to match — so a home screen of them reads as separate '
            'things. The key map fills each of the twelve tiles by how well you '
            'know that key.',
      ),
      ReleaseLine(
        icon: Icons.pets_rounded,
        color: Color(0xFFA3E635),
        title: 'The widgets draw the real animal',
        detail:
            'The level widget showed an emoji where the app draws its own line '
            'art. It draws the same animal now, in the level\u2019s colour — '
            'and the empty squares elsewhere are gone: they were characters '
            'set in a font that has no glyph for them.',
      ),
      ReleaseLine(
        icon: Icons.touch_app_rounded,
        color: Color(0xFF6366F1),
        title: 'Widget taps arrive somewhere',
        detail:
            'Chromatic pointed at a setup screen that does not exist, so it '
            'opened the app and stopped; Theory landed on the home screen. '
            'Both go where they say they go.',
      ),
      ReleaseLine(
        icon: Icons.record_voice_over_rounded,
        color: Color(0xFF34D399),
        title: 'Pocket Mode speaks Italian all the way through',
        detail:
            'The sixth degree and D flat had never been recorded, so an '
            'Italian session said those two words in English — about one '
            'question in eight. Both are recorded now.',
      ),
      ReleaseLine(
        icon: Icons.tablet_mac_rounded,
        color: Color(0xFF60A5FA),
        title: 'A real app on iPad',
        detail:
            'Every screen here is drawn for a phone held upright, and an iPad '
            'was getting all of it stretched to 1024 points wide. The app now '
            'keeps to a centred column of phone width, and stays portrait.',
      ),
      ReleaseLine(
        icon: Icons.translate_rounded,
        color: Color(0xFF34D399),
        title: 'The last English left over',
        detail:
            'The widgets speak your language now, and so do the bits the app '
            'had missed: the daily challenge rule, the streak in days, the '
            'game counts in Statistics.',
      ),
      ReleaseLine(
        icon: Icons.local_fire_department_rounded,
        color: Color(0xFFFB923C),
        title: 'Your week, in seven dots',
        detail:
            'The streak widgets now show the last seven days, not just the '
            'count — and the whole card turns gold on the day you are about to '
            'break one.',
      ),
    ],
  ),
  Release(
    version: '1.15.0',
    date: '3 SEP 2026',
    headline: 'Every mode you play now counts, and you can see exactly where.',
    lines: [
      ReleaseLine(
        icon: Icons.equalizer_rounded,
        color: Color(0xFFA855F7),
        title: 'Three bars, not one average',
        detail:
            'Each key in Statistics now shows Degree to Note, Note to Degree '
            'and \u2026Of What? separately, so a single number can never hide '
            'which of the three you have actually built.',
      ),
      ReleaseLine(
        icon: Icons.military_tech_rounded,
        color: Color(0xFF34D399),
        title: 'The summary reports what moved',
        detail:
            'After a session you see the family you just played and the key '
            'overall — and Note to Degree and \u2026Of What? get that card '
            'too, now that they keep records of their own.',
      ),
      ReleaseLine(
        icon: Icons.translate_rounded,
        color: Color(0xFF60A5FA),
        title: 'One name per mode, in every language',
        detail:
            'Note to Number, \u2026Of What?, Pocket Mode and the rest keep '
            'their names whatever language the app is in. Everything around '
            'them still follows your phone.',
      ),
      ReleaseLine(
        icon: Icons.headphones_rounded,
        color: Color(0xFFFBBF24),
        title: 'Pocket Mode says nothing it cannot know',
        detail:
            'The key tiles no longer carry a mastery bar. Pocket Mode never '
            'sees your answer, so it has nothing to measure — an empty bar was '
            'only ever telling you off for nothing.',
      ),
      ReleaseLine(
        icon: Icons.palette_rounded,
        color: Color(0xFF22D3EE),
        title: 'A prettier walkthrough',
        detail:
            'The three opening screens each have their own colour, and the '
            'keyboard on them sits in a rounded bed instead of being cut off '
            'at the edges.',
      ),
    ],
  ),
  Release(
    version: '1.14.1',
    date: '1 SEP 2026',
    headline: 'Restoring a backup no longer asks the phone for more than it needs.',
    lines: [
      ReleaseLine(
        icon: Icons.folder_open_rounded,
        color: Color(0xFF22D3EE),
        title: 'A file picker, and only that',
        detail:
            'Choosing a backup file used the same component that picks photos '
            'and videos, so the app looked like it wanted your camera roll. It '
            'now opens documents and nothing else.',
      ),
    ],
  ),
  Release(
    version: '1.14.0',
    date: '1 SEP 2026',
    headline: 'The first three screens now show the idea instead of describing it.',
    lines: [
      ReleaseLine(
        icon: Icons.piano_rounded,
        color: Color(0xFFA855F7),
        title: 'A keyboard you can move',
        detail:
            'The numbers sit on the keys. Change the key and watch the letters '
            'move while the numbers stay — that is the whole idea of the app, '
            'in one tap.',
      ),
      ReleaseLine(
        icon: Icons.touch_app_rounded,
        color: Color(0xFF34D399),
        title: 'Answer one before you start',
        detail:
            'The last screen is a real question, with the key lighting up when '
            'you get it. Nobody reaches the home screen without having played.',
      ),
    ],
  ),
  Release(
    version: '1.13.0',
    date: '1 SEP 2026',
    headline: 'Improvy now speaks your language.',
    lines: [
      ReleaseLine(
        icon: Icons.translate_rounded,
        color: Color(0xFF22D3EE),
        title: 'Italian, Spanish, French, German, Portuguese',
        detail:
            'The whole app follows your phone\u2019s language. Musicians who '
            'write Do Re Mi get that notation from the first screen, and '
            'Pocket Mode already speaks Italian.',
      ),
    ],
  ),
  Release(
    version: '1.12.0',
    date: '31 AUG 2026',
    headline: 'Your progress can leave the phone, and the app can be read aloud.',
    lines: [
      ReleaseLine(
        icon: Icons.upload_rounded,
        color: Color(0xFF22D3EE),
        title: 'Export and restore',
        detail:
            'Settings → Backup writes one file with every key, score and '
            'setting. Reinstall, change phone, switch between iPhone and '
            'Android — restore it and everything is back.',
      ),
      ReleaseLine(
        icon: Icons.accessibility_new_rounded,
        color: Color(0xFF34D399),
        title: 'Larger type, and a screen reader that makes sense',
        detail:
            'The app now follows the system text size up to 130%, and keys, '
            'answer buttons and switches announce what they are.',
      ),
    ],
  ),
  Release(
    version: '1.11.0',
    date: '31 AUG 2026',
    headline: 'Hear the note you just named, and a proper start for newcomers.',
    lines: [
      ReleaseLine(
        icon: Icons.music_note_rounded,
        color: Color(0xFF22D3EE),
        title: 'Every right answer sounds',
        detail:
            'Name the ♭3 of A and you hear it. The ear learns alongside the '
            'number — switch it off in Settings for quiet places.',
      ),
      ReleaseLine(
        icon: Icons.school_rounded,
        color: Color(0xFFA855F7),
        title: 'What a degree is, before the first question',
        detail:
            'Three short screens after the welcome: the numbers, why they work '
            'in every key, and what the game asks. Skippable if you already '
            'know.',
      ),
      ReleaseLine(
        icon: Icons.fact_check_rounded,
        color: Color(0xFF34D399),
        title: 'The summary tells the truth',
        detail:
            '"Level passed" now means the next tier is actually open — the '
            'same 80% bar the rest of the app uses — and a free player who '
            'finishes a key is shown the half they have not seen.',
      ),
    ],
  ),
  Release(
    version: '1.10.5',
    date: '30 AUG 2026',
    headline: 'Every key shows how far you have taken it, at a glance.',
    lines: [
      ReleaseLine(
        icon: Icons.horizontal_rule_rounded,
        color: Color(0xFF34D399),
        title: 'A bar under every key',
        detail:
            'Pick a key in Note to Number or …Of What? and each one carries a '
            'small bar: filled as far as you have taken it, empty for the rest. '
            'Twelve keys read like twelve columns, and the one you select says '
            'its exact figure at the top.',
      ),
    ],
  ),
  Release(
    version: '1.10.2',
    date: '30 AUG 2026',
    headline: 'The statistics now measure what you would feel on a bandstand.',
    lines: [
      ReleaseLine(
        icon: Icons.emoji_events_rounded,
        color: Color(0xFFFACC15),
        title: 'The key ranking means something',
        detail:
            'It ranked by raw accuracy over all history, which rewarded not '
            'climbing: a key dabbled with at six seconds outranked one taken '
            'to Master. It now ranks how often you answer right inside 1.2 '
            'seconds — either you know where the ♭3 is or you are counting.',
      ),
      ReleaseLine(
        icon: Icons.speed_rounded,
        color: Color(0xFF22D3EE),
        title: 'Response time, not accuracy over time',
        detail:
            'Accuracy fell off a cliff the day you unlocked a harder tier, so '
            'the chart showed a decline for what was clearly progress. Speed '
            'has no such reversal — it only ever falls as you get better.',
      ),
      ReleaseLine(
        icon: Icons.filter_alt_rounded,
        color: Color(0xFF818CF8),
        title: 'Each card reads the modes it is about',
        detail:
            'Degree Accuracy takes both directions over a key and leaves the '
            'harmonizer out. The keyboard heatmap takes everything, but one '
            'reading per session, so a long evening cannot drown a short one.',
      ),
    ],
  ),
  Release(
    version: '1.10.1',
    date: '30 AUG 2026',
    headline: 'The animals come faster now, and the harder ones cost more.',
    lines: [
      ReleaseLine(
        icon: Icons.pets_rounded,
        color: Color(0xFF22C55E),
        title: 'Turtle is two sessions away',
        detail:
            'The eight levels used to be eight equal steps, set when a key '
            'counted one skill. The first ones are now close together and the '
            'last ones are a long climb — which is what their names always '
            'promised.',
      ),
      ReleaseLine(
        icon: Icons.balance_rounded,
        color: Color(0xFFA855F7),
        title: 'The two directions carry more weight',
        detail:
            'Reading a degree and naming the note, and its mirror, are 40% of '
            'a key each. Naming the key a note belongs to is rarer and more '
            'advanced, and is the remaining 20%.',
      ),
    ],
  ),
  Release(
    version: '1.10.0',
    date: '30 AUG 2026',
    headline:
        'A key is now scored on all three ways of knowing it — so most of them '
        'just got a lot bigger.',
    lines: [
      ReleaseLine(
        icon: Icons.hexagon_outlined,
        color: Color(0xFFA855F7),
        title: 'Three skills, one number',
        detail:
            'Naming the note for a degree, naming the degree for a note, and '
            'naming the key a note belongs to. Each is a third of what it '
            'means to know a key, and the tile shows the three together.',
      ),
      ReleaseLine(
        icon: Icons.unfold_more_rounded,
        color: Color(0xFFFBBF24),
        title: 'Your percentages will look smaller',
        detail:
            'Nothing was lost and nothing was reset. The scale got three times '
            'longer, so a key you had finished now reads 33% — and open it to '
            'see exactly which two thirds are left.',
      ),
      ReleaseLine(
        icon: Icons.insights_rounded,
        color: Color(0xFF34D399),
        title: 'Every key explains itself',
        detail:
            'Key Analysis breaks the number into its three parts instead of '
            'the two it used to show, so the figure on the tile is never a '
            'black box.',
      ),
    ],
  ),
  Release(
    version: '1.9.4',
    date: '30 AUG 2026',
    headline:
        'Every mode is scored the same way now, and half of each one is free.',
    lines: [
      ReleaseLine(
        icon: Icons.stacked_bar_chart_rounded,
        color: Color(0xFF34D399),
        title: 'One rule, three modes',
        detail:
            'Note to Number and …Of What? are now scored like the main modes: '
            'half the score is knowing the core cold — the seven scale '
            'degrees, or the chord tones — and half is extending it to every '
            'degree.',
      ),
      ReleaseLine(
        glyph: '♯♭',
        color: Color(0xFF22D3EE),
        title: 'Chord and All keep their own records',
        detail:
            '…Of What? used to pool both into one bar, so a run on the four '
            'chord tones filled the same dial as a run on all fifteen '
            'degrees. They are separate now, and your old scores stay where '
            'they belong.',
      ),
    ],
  ),
  Release(
    version: '1.9.3',
    date: '30 AUG 2026',
    headline:
        'The percentage on a key finally counts everything you have already '
        'proved.',
    lines: [
      ReleaseLine(
        icon: Icons.calculate_rounded,
        color: Color(0xFFA855F7),
        title: 'A number that adds up',
        detail:
            'Chromatic contains the seven notes of the scale, and Master asks '
            'the same questions as Apprentice with less time. Your key '
            'percentage now takes both into account, so a hard run counts for '
            'the easier ones you never needed to play.',
      ),
      ReleaseLine(
        icon: Icons.lock_open_rounded,
        color: Color(0xFF34D399),
        title: 'One bar to clear, and it is lower',
        detail:
            'Every tier now opens at 80% of the one below it — it used to be '
            '90% for Virtuoso and 92.5% for Master, two different bars. And a '
            'key you have already proved opens its tiers straight away.',
      ),
      ReleaseLine(
        icon: Icons.trending_up_rounded,
        color: Color(0xFFFBBF24),
        title: 'Some keys just went up',
        detail:
            'Nothing you have done was lost — it was being counted wrongly. '
            'Nobody goes down, and a few keys jump a long way.',
      ),
    ],
  ),
  Release(
    version: '1.9.1',
    date: '21 AUG 2026',
    headline:
        'Note to Number and …Of What? now remember what you did, and every key '
        'wears how far you have taken it.',
    lines: [
      ReleaseLine(
        icon: Icons.donut_large_rounded,
        color: Color(0xFF34D399),
        title: 'Every key shows its own progress',
        detail:
            'The outline of each key fills as you take it through the three '
            'tiers, in that key\u2019s own colour. Twelve keys, read at a glance.',
      ),
      ReleaseLine(
        icon: Icons.stairs_rounded,
        color: Color(0xFFA855F7),
        title: 'The ladder reaches the other modes',
        detail:
            'Note to Number and …Of What? keep your record for each key and '
            'each tier, and Master has to be earned through Apprentice and '
            'Virtuoso — the same rule the main modes have always had.',
      ),
      ReleaseLine(
        icon: Icons.tune_rounded,
        color: Color(0xFF22D3EE),
        title: 'Simpler setups, longer sessions',
        detail:
            '…Of What? is now Chord or All, and its length comes from the tier '
            'instead of a separate list. Custom Mode builds any of the three '
            'directions, and both it and Pocket Mode run 30, 50, 100 — or '
            'until you stop.',
      ),
    ],
  ),
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
