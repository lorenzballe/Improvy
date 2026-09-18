@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'screens_render_test.dart' show loadRealFonts;

/// A proposal, not a change.
///
/// Nothing here is imported by the app. Both halves of every pair are drawn
/// in this file: the left one reproduces what ships today, value for value,
/// read out of the real widgets; the right one is what it could be. Drawing
/// both the same way is the only way the comparison is fair — a screenshot of
/// the real screen and a mock-up of the new one differ in ways that have
/// nothing to do with the design.
///
///   flutter test test/design_proposal_test.dart --tags golden --run-skipped --update-goldens
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadRealFonts);

  Future<void> page(WidgetTester t, String file, Size size, Widget child) async {
    // The faces have to reach the engine through real async: loaded from a
    // fake-async body they never arrive and every glyph comes out a block.
    await t.runAsync(loadRealFonts);
    t.view.physicalSize = Size(size.width * 2, size.height * 2);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, fontFamily: 'Lexend', brightness: Brightness.dark),
        // Text with no Material above it is drawn in Flutter's debug style —
        // yellow double underline — which has nothing to do with the design.
        home: Material(
          color: Colors.transparent,
          child: Align(
            alignment: Alignment.topLeft,
            child: Transform.scale(
              scale: 2,
              alignment: Alignment.topLeft,
              child: SizedBox(width: size.width, height: size.height, child: child),
            ),
          ),
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 400));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$file'));
  }

  testWidgets('the mode card', (t) async {
    await page(
      t,
      'design_modecard.png',
      const Size(1000, 560),
      const _Pair(left: _ModeCardNow(), right: _ModeCardNext(), leftTall: 470, rightTall: 330),
    );
  });

  testWidgets('the statistics', (t) async {
    await page(
      t,
      'design_stats.png',
      const Size(1060, 560),
      const _Pair(left: _StatsNow(), right: _StatsNext(), leftTall: 470, rightTall: 470),
    );
  });

  testWidgets('the system', (t) async {
    await page(t, 'design_system.png', const Size(1020, 500), const _SystemSheet());
  });
}

// ── Tokens ──────────────────────────────────────────────────────────────────

/// What ships today, read out of the real widgets.
abstract final class Now {
  static const bg = Color(0xFF0F0A1A);
  static const card = Color(0xF21A1625);
  static const blue = Color(0xFF3B82F6);
  static const rose = Color(0xFFFB7185);
  static const gold = Color(0xFFFBBF24);
  static const green = Color(0xFF10B981);
}

/// The proposal. Three ideas, and everything follows from them:
///
///   · One accent per surface. Colour is reserved for state — right, wrong,
///     locked, earned — so that when it appears it means something.
///   · Depth from contrast, not from glow. A hairline and a lighter fill do
///     what a 40px coloured blur was doing, and they survive daylight.
///   · Hierarchy from size and weight, not from CAPITALS AND TRACKING.
abstract final class Next {
  static const bg = Color(0xFF0B0A10);
  static const surface = Color(0xFF16151C);
  static const surfaceHigh = Color(0xFF1E1C26);
  static const line = Color(0x14FFFFFF); // 8%
  static const lineStrong = Color(0x24FFFFFF); // 14%

  static const ink = Color(0xFFF5F4F8);
  static const inkMuted = Color(0xB3F5F4F8); // 70%
  static const inkFaint = Color(0x8AF5F4F8); // 54%
  static const inkGhost = Color(0x59F5F4F8); // 35%

  static const accent = Color(0xFF6D6BF6);
  static const good = Color(0xFF34D399);
  static const warn = Color(0xFFF5B95C);
  static const bad = Color(0xFFF2637E);

  // A scale, rather than a number picked per widget: 12 / 18 / 28.
  static const rChip = 12.0;
  static const rControl = 18.0;
  static const rCard = 28.0;

  static TextStyle display(double s) =>
      TextStyle(fontSize: s, fontWeight: FontWeight.w700, letterSpacing: -0.6, height: 1.05, color: ink);
  static const title = TextStyle(fontSize: 19, fontWeight: FontWeight.w600, letterSpacing: -0.2, color: ink);
  static const body = TextStyle(fontSize: 14.5, fontWeight: FontWeight.w400, height: 1.45, color: inkMuted);
  static const label = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
    color: inkFaint,
  );
  static const number = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
    height: 1,
    color: ink,
  );
}

// ── Page furniture ──────────────────────────────────────────────────────────

class _Pair extends StatelessWidget {
  final Widget left;
  final Widget right;
  final double leftTall;
  final double rightTall;
  const _Pair({required this.left, required this.right, required this.leftTall, required this.rightTall});

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFF070710),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _Column(
              tag: 'OGGI',
              tagColor: const Color(0x66FFFFFF),
              bg: Now.bg,
              height: leftTall,
              child: left,
            ),
          ),
          const SizedBox(width: 28),
          Expanded(
            child: _Column(
              tag: 'PROPOSTA',
              tagColor: Next.accent,
              bg: Next.bg,
              height: rightTall,
              child: right,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Column extends StatelessWidget {
  final String tag;
  final Color tagColor;
  final Color bg;
  final double height;
  final Widget child;
  const _Column({
    required this.tag,
    required this.tagColor,
    required this.bg,
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        tag,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.2, color: tagColor),
      ),
      const SizedBox(height: 10),
      Container(
        height: height,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.all(18),
        child: child,
      ),
    ],
  );
}

// ── ① The mode card ─────────────────────────────────────────────────────────

/// What ships. Reproduced from home_screen.dart: radius 40, a 1.2px accent
/// border, a 40px coloured glow around the whole card, a radial accent bleed
/// in the corner, three cryptic tier glyphs, a 33px w900 headline, and a
/// gradient button with a 28px coloured shadow under it.
class _ModeCardNow extends StatelessWidget {
  const _ModeCardNow();

  @override
  Widget build(BuildContext context) {
    const accent = Now.blue;
    return Container(
      decoration: BoxDecoration(
        color: Now.card,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: accent.withAlpha(80), width: 1.2),
        boxShadow: [BoxShadow(color: accent.withAlpha(25), blurRadius: 40)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [accent.withAlpha(50), Colors.transparent]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFF388EF8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF7BB8FB).withAlpha(120)),
                      ),
                      child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 32),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            for (final on in [true, false, false])
                              Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: Icon(
                                  Icons.music_note_rounded,
                                  size: 26,
                                  color: on ? Now.blue : Colors.white.withAlpha(40),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'APPRENTICE',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.6,
                            color: Now.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(flex: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Expanded(
                      child: Text(
                        'C Diatonic',
                        style: TextStyle(
                          fontSize: 33,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.8,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          '47%',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            height: 1,
                            letterSpacing: -0.5,
                            color: Now.rose,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '14/30 BEST',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            color: Colors.white.withAlpha(90),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Master the 7 notes of the scale.',
                  maxLines: 2,
                  style: TextStyle(fontSize: 14, color: Colors.white60, height: 1.5),
                ),
                const Spacer(flex: 3),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent, accent.withValues(alpha: 0.75)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.38),
                        blurRadius: 28,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'START',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The proposal.
///
/// Same information, 160px shorter, and it says more. The glow and the
/// coloured border go: a hairline and a slightly lighter fill separate the
/// card from the page, and hold up in daylight where a purple bloom does not.
/// The headline drops from 33/w900 to 28/w700 — Lexend Black at that size was
/// shouting the key at someone who chose it a second ago.
///
/// The three note glyphs become a real segmented control with the tier names
/// on it, so the thing you can actually change looks changeable and the
/// locked ones look locked. The record stops being "14/30 BEST" in 9px caps
/// and becomes a bar with the number on it: a percentage is a proportion, and
/// a proportion is a length.
class _ModeCardNext extends StatelessWidget {
  const _ModeCardNext();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Next.surface,
        borderRadius: BorderRadius.circular(Next.rCard),
        border: Border.all(color: Next.line),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Next.accent.withAlpha(38),
                  borderRadius: BorderRadius.circular(Next.rChip),
                ),
                child: const Icon(Icons.music_note_rounded, color: Next.accent, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('C Diatonic', style: Next.display(24)),
                    const SizedBox(height: 3),
                    const Text('The 7 notes of the scale', style: Next.body),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // The record, as a proportion.
          Row(
            children: [
              const Text('Best', style: Next.label),
              const Spacer(),
              const Text(
                '14',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Next.ink),
              ),
              Text(' / 30', style: Next.label.copyWith(fontSize: 13)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Next.warn.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '47%',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Next.warn),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: 14 / 30,
              minHeight: 5,
              backgroundColor: Next.lineStrong,
              color: Next.warn,
            ),
          ),
          const SizedBox(height: 18),

          // The tier, as something you can see is a choice.
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0E14),
              borderRadius: BorderRadius.circular(Next.rControl - 4),
              border: Border.all(color: Next.line),
            ),
            child: Row(
              children: [
                for (final (name, state) in [('Apprentice', 0), ('Virtuoso', 1), ('Master', 2)])
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: state == 0
                          ? BoxDecoration(
                              color: Next.surfaceHigh,
                              borderRadius: BorderRadius.circular(Next.rChip),
                            )
                          : null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (state == 2) ...[
                            const Icon(Icons.lock_rounded, size: 11, color: Next.inkGhost),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: state == 0 ? FontWeight.w600 : FontWeight.w500,
                              color: state == 0 ? Next.ink : Next.inkGhost,
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

          SizedBox(
            width: double.infinity,
            height: 50,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Next.accent,
                borderRadius: BorderRadius.circular(Next.rControl),
              ),
              child: const Center(
                child: Text(
                  'Start training',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── ② The statistics ────────────────────────────────────────────────────────

/// What ships: three tiles with a 10px all-caps label, a 32px w900 number, a
/// coloured corner bloom inside each, and a border only on the one that
/// happens to be the streak. Then a degree list where every row carries its
/// own colour, so eight rows carry eight colours and none of them means
/// anything.
class _StatsNow extends StatelessWidget {
  const _StatsNow();

  Widget _tile(String label, String value, Color c, {bool bordered = false}) => Expanded(
    child: Container(
      height: 92,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1625),
        borderRadius: BorderRadius.circular(24),
        border: bordered ? Border.all(color: c.withAlpha(90)) : null,
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 20, offset: Offset(0, 8))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: -16,
            right: -16,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(shape: BoxShape.circle, color: c.withAlpha(38)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                    color: Colors.white.withAlpha(120),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, height: 1, color: c),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _row(String numeral, Color c, int plays, int pct) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withAlpha(8),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withAlpha(12)),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: c.withAlpha(45), borderRadius: BorderRadius.circular(9)),
              child: Text(
                numeral,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: c),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PLAYS',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: Colors.white.withAlpha(110),
                  ),
                ),
                Text(
                  '$plays',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'ACCURACY',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: Colors.white.withAlpha(110),
                  ),
                ),
                Text(
                  '$pct%',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: c),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: pct / 100,
            minHeight: 5,
            backgroundColor: Colors.white.withAlpha(20),
            color: c,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          _tile('NOTES', '90', Now.blue),
          const SizedBox(width: 10),
          _tile('ACCURACY', '78%', Now.green),
          const SizedBox(width: 10),
          _tile('STREAK', '1', Now.gold, bordered: true),
        ],
      ),
      const SizedBox(height: 16),
      const Text(
        'Degree Accuracy',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.3),
      ),
      const SizedBox(height: 10),
      _row('I', const Color(0xFFEF4444), 15, 67),
      _row('II', const Color(0xFFF59E0B), 15, 67),
      _row('III', const Color(0xFF84CC16), 15, 100),
    ],
  );
}

/// The proposal.
///
/// The three numbers stop being three coloured objects and become one row of
/// facts: same fill, same weight, no bloom, no border on whichever one felt
/// special. Colour leaves the number and goes to the one place it carries
/// meaning — the accuracy, which is good, fine or poor.
///
/// The labels come down from 10px black caps at 1.4 tracking to 12px regular
/// sentence case. They are labels; they do not need to shout to be read.
///
/// In the list, a degree is a degree: the chip is neutral and only the bar
/// carries a colour, so a row that is going badly stands out instead of
/// competing with seven others that are fine. Each row loses its box and
/// keeps a single hairline between — eight boxes inside a box is a fence
/// around every word in a sentence.
class _StatsNext extends StatelessWidget {
  const _StatsNext();

  Widget _stat(String label, String value, {Color? valueColor}) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Next.label),
        const SizedBox(height: 6),
        Text(value, style: Next.number.copyWith(color: valueColor ?? Next.ink)),
      ],
    ),
  );

  Widget _row(String numeral, int plays, int pct, Color bar, {bool last = false}) => Container(
    padding: const EdgeInsets.symmetric(vertical: 13),
    decoration: BoxDecoration(
      border: last ? null : const Border(bottom: BorderSide(color: Next.line)),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 30,
          child: Text(
            numeral,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Next.ink),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 6,
              backgroundColor: Next.lineStrong,
              color: bar,
            ),
          ),
        ),
        SizedBox(
          width: 52,
          child: Text(
            '$pct%',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Next.ink),
          ),
        ),
        SizedBox(
          width: 62,
          child: Text('$plays plays', textAlign: TextAlign.right, style: Next.label),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        decoration: BoxDecoration(
          color: Next.surface,
          borderRadius: BorderRadius.circular(Next.rCard),
          border: Border.all(color: Next.line),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _stat('Notes', '90'),
            _stat('Accuracy', '78%', valueColor: Next.good),
            _stat('Streak', '1'),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          const Text('Degree accuracy', style: Next.title),
          const Spacer(),
          Text('Last 30 games', style: Next.label),
        ],
      ),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: Next.surface,
          borderRadius: BorderRadius.circular(Next.rCard),
          border: Border.all(color: Next.line),
        ),
        child: Column(
          children: [
            _row('1', 15, 67, Next.warn),
            _row('2', 15, 67, Next.warn),
            _row('3', 15, 100, Next.good, last: true),
          ],
        ),
      ),
    ],
  );
}

// ── ③ The system underneath ─────────────────────────────────────────────────

/// The four rules the two pages above follow, on one sheet. A redesign that
/// is only "these two screens look nicer" drifts back within a month; these
/// are the things that would go in one file and be imported everywhere.
class _SystemSheet extends StatelessWidget {
  const _SystemSheet();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFF070710),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'IL SISTEMA',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.2,
              color: Next.accent,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Block(
                        title: 'Testo',
                        note: 'Gerarchia da peso e misura, non da MAIUSCOLE spaziate.',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Before(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'C DIATONIC',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.8,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'APPRENTICE · 14/30 BEST',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.6,
                                      color: Colors.white.withAlpha(120),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Master the 7 notes of the scale.',
                                    style: TextStyle(fontSize: 12, color: Colors.white60, height: 1.5),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            _After(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('C Diatonic', style: Next.display(22)),
                                  const SizedBox(height: 4),
                                  const Text('Apprentice · best 14 of 30', style: Next.label),
                                  const SizedBox(height: 4),
                                  const Text('The 7 notes of the scale', style: Next.body),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _Block(
                        title: 'Angoli',
                        note: 'Una scala di tre, non un numero deciso ogni volta.',
                        child: Row(
                          children: [
                            _Radius(label: 'oggi', values: '40 · 32 · 24 · 16 · ∞', r: const [40, 24, 9999]),
                            const SizedBox(width: 18),
                            _Radius(
                              label: 'proposta',
                              values: '28 · 18 · 12',
                              r: const [28, 18, 12],
                              accent: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 22),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Block(
                        title: 'Colore',
                        note:
                            'Un accento per superficie. Il resto del colore dice uno stato: giusto, così così, sbagliato, chiuso.',
                        child: Row(
                          children: [
                            for (final (c, n) in [
                              (Next.accent, 'accento'),
                              (Next.good, 'bene'),
                              (Next.warn, 'così così'),
                              (Next.bad, 'male'),
                              (Next.inkGhost, 'chiuso'),
                            ])
                              Expanded(
                                child: Column(
                                  children: [
                                    Container(
                                      height: 34,
                                      margin: const EdgeInsets.only(right: 6),
                                      decoration: BoxDecoration(
                                        color: c,
                                        borderRadius: BorderRadius.circular(Next.rChip),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(n, style: Next.label.copyWith(fontSize: 10)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _Block(
                        title: 'Pulsanti',
                        note:
                            'Niente alone colorato: la profondità viene dal contrasto, e regge anche alla luce del sole.',
                        child: Column(
                          children: [
                            _Before(
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Now.blue, Color(0xBF3B82F6)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Now.blue.withValues(alpha: 0.38),
                                      blurRadius: 28,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'START',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 3,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _After(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 46,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: Next.accent,
                                        borderRadius: BorderRadius.circular(Next.rControl),
                                      ),
                                      child: const Text(
                                        'Start training',
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    height: 46,
                                    width: 100,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: Next.surfaceHigh,
                                      borderRadius: BorderRadius.circular(Next.rControl),
                                      border: Border.all(color: Next.lineStrong),
                                    ),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600,
                                        color: Next.inkMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _Block extends StatelessWidget {
  final String title;
  final String note;
  final Widget child;
  const _Block({required this.title, required this.note, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Next.bg,
      borderRadius: BorderRadius.circular(Next.rCard),
      border: Border.all(color: Next.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Next.title.copyWith(fontSize: 16)),
        const SizedBox(height: 3),
        Text(note, style: Next.label.copyWith(height: 1.4)),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

class _Before extends StatelessWidget {
  final Widget child;
  const _Before({required this.child});
  @override
  Widget build(BuildContext context) => _Tagged(tag: 'oggi', color: const Color(0x59FFFFFF), child: child);
}

class _After extends StatelessWidget {
  final Widget child;
  const _After({required this.child});
  @override
  Widget build(BuildContext context) => _Tagged(tag: 'proposta', color: Next.accent, child: child);
}

class _Tagged extends StatelessWidget {
  final String tag;
  final Color color;
  final Widget child;
  const _Tagged({required this.tag, required this.color, required this.child});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 54,
        child: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            tag,
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: color),
          ),
        ),
      ),
      Expanded(child: child),
    ],
  );
}

class _Radius extends StatelessWidget {
  final String label;
  final String values;
  final List<double> r;
  final bool accent;
  const _Radius({required this.label, required this.values, required this.r, this.accent = false});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: accent ? Next.accent : const Color(0x59FFFFFF),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final v in r)
              Container(
                width: 34,
                height: 34,
                margin: const EdgeInsets.only(right: 7),
                decoration: BoxDecoration(
                  color: Next.surfaceHigh,
                  borderRadius: BorderRadius.circular(v),
                  border: Border.all(color: accent ? Next.accent.withAlpha(110) : Next.lineStrong),
                ),
              ),
          ],
        ),
        const SizedBox(height: 7),
        Text(values, style: Next.label.copyWith(fontSize: 10)),
      ],
    ),
  );
}
