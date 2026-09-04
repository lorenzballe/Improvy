@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'store_screenshot_test.dart' show loadRealFonts;

/// A picture of the twelve home-screen widgets.
///
/// The widgets themselves are native — SwiftUI on iOS, RemoteViews on Android —
/// and neither can be rendered here. This draws the *same design* in Flutter at
/// the real iOS widget sizes, so the layout can be looked at and argued with
/// without a phone in hand. It is a reference, not the implementation: when the
/// design changes, this changes with it.
///
///   flutter test test/widget_gallery_test.dart --tags golden --run-skipped --update-goldens
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the widget gallery', (t) async {
    await loadRealFonts();
    t.view.physicalSize = const Size(1500, 3560);
    t.view.devicePixelRatio = 2.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);

    await t.pumpWidget(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _Gallery(),
    ));
    await t.pump();
    await expectLater(find.byType(_Gallery), matchesGoldenFile('goldens/widget_gallery.png'));
  });
}

// ── The design, in one place ────────────────────────────────────────────────

const _inkTop = Color(0xFF1B1428);
const _inkBottom = Color(0xFF0E0A18);
const _gold = Color(0xFFFCD34D);
const _indigo = Color(0xFF6366F1);
const _violet = Color(0xFFA855F7);
const _mint = Color(0xFF34D399);
const _cyan = Color(0xFF22D3EE);
const _ember = Color(0xFFFB923C);
const _rose = Color(0xFFF43F5E);

/// iOS widget sizes on a 6.1" phone, in points.
const _small = Size(170, 170);
const _medium = Size(364, 170);
const _large = Size(364, 382);

class _Gallery extends StatelessWidget {
  const _Gallery();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0A0710),
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: DefaultTextStyle(
          // ♭ and ♯ live in NotoMusic, as they do in the app. Emoji have no
          // font in the test runner at all and draw as boxes here only.
          style: const TextStyle(fontFamily: 'Lexend', fontFamilyFallback: ['NotoMusic']),
          child: Wrap(
            spacing: 22,
            runSpacing: 22,
            children: [
              _labelled('Question', _small, const _Quiz()),
              _labelled('Daily · unplayed', _small, const _Daily(played: false, wide: false)),
              _labelled('Daily · done', _small, const _Daily(played: true, wide: false)),
              _labelled('Level', _small, const _Level()),
              _labelled('Streak · at risk', _small, const _Streak(atRisk: true)),
              _labelled('Weakest key', _small, const _Weakest()),
              _labelled('Pocket Mode', _small, const _Pocket()),
              _labelled('Question (wide)', _medium, const _Quiz(wide: true)),
              _labelled('Daily (wide)', _medium, const _Daily(played: false, wide: true)),
              _labelled('Key map', _medium, const _Map()),
              _labelled('Streak (wide)', _medium, const _Streak(atRisk: false, wide: true)),
              _labelled('Quick start', _medium, const _Launcher()),
              _labelled('Theory', _medium, const _Theory()),
              _labelled('Key map (large)', _large, const _Map(tall: true)),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _labelled(String name, Size size, Widget child) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: size.width, height: size.height, child: child),
          const SizedBox(height: 7),
          Text(name,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.34))),
        ],
      );
}

/// The surface every widget sits on: ink, an accent glow from the top-left, a
/// hairline in the accent.
class _Surface extends StatelessWidget {
  final Color accent;
  final bool lit;
  final Widget child;
  const _Surface({required this.accent, required this.child, this.lit = false});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_inkTop, _inkBottom],
        ),
        border: Border.all(color: accent.withValues(alpha: lit ? 0.55 : 0.16), width: lit ? 1.4 : 1),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: RadialGradient(
                  center: const Alignment(-1.05, -1.05),
                  radius: 1.5,
                  colors: [accent.withValues(alpha: lit ? 0.34 : 0.18), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(padding: const EdgeInsets.all(15), child: child),
          ),
        ],
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  final String text;
  final Color accent;
  final Widget? trailing;
  const _Eyebrow(this.text, {this.accent = _gold, this.trailing});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          // Shrink before truncating, the way the native `.fitted()` does: a
          // header that reads "NEEDS W…" is worse than one a point smaller.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(text,
                  maxLines: 1,
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.7,
                      color: accent)),
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      );
}

class _Chip extends StatelessWidget {
  final String text;
  final Color colour;
  const _Chip(this.text, {this.colour = _gold});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: colour.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colour.withValues(alpha: 0.30)),
        ),
        child: Text(text,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: colour)),
      );
}

class _KeyTile extends StatelessWidget {
  final String label;
  final Color colour;
  final double size;
  final double? fill;
  const _KeyTile(this.label, this.colour, {this.size = 46, this.fill});

  @override
  Widget build(BuildContext context) {
    final r = size * 0.30;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colour.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(r),
              ),
            ),
          ),
          if (fill != null && fill! > 0)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: fill!.clamp(0.06, 1.0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(r * 0.7),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            colour.withValues(alpha: 0.95),
                            colour.withValues(alpha: 0.55),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(r),
                border: Border.all(
                    color: colour.withValues(alpha: fill == null ? 0.45 : 0.30)),
              ),
            ),
          ),
          Text(label,
              style: TextStyle(
                fontSize: size * 0.40,
                fontWeight: FontWeight.w900,
                color: (fill ?? 0) < 0.55 ? colour : Colors.white,
                shadows: const [Shadow(color: Color(0x73000000), blurRadius: 2)],
              )),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double value;
  final Color colour;
  final double height;
  const _Bar(this.value, this.colour, {this.height = 6});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: SizedBox(
          height: height,
          child: Stack(children: [
            Positioned.fill(child: ColoredBox(color: Colors.white.withValues(alpha: 0.10))),
            FractionallySizedBox(
              widthFactor: value.clamp(0, 1),
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [colour.withValues(alpha: 0.75), colour]),
                ),
              ),
            ),
          ]),
        ),
      );
}

class _Glyph extends StatelessWidget {
  final IconData icon;
  final Color colour;
  final double size;
  const _Glyph(this.icon, this.colour, {this.size = 38});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colour.withValues(alpha: 0.16),
          shape: BoxShape.circle,
          border: Border.all(color: colour.withValues(alpha: 0.42)),
        ),
        child: Icon(icon, size: size * 0.42, color: colour),
      );
}

// ── The twelve ──────────────────────────────────────────────────────────────

class _Quiz extends StatelessWidget {
  final bool wide;
  const _Quiz({this.wide = false});

  @override
  Widget build(BuildContext context) => _Surface(
        accent: _gold,
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Eyebrow(wide ? "TODAY'S QUESTION" : 'QUESTION'),
                const Spacer(),
                Text('♭3',
                    style: TextStyle(
                      fontSize: wide ? 46 : 40,
                      fontWeight: FontWeight.w800,
                      color: _gold,
                      shadows: [Shadow(color: _gold.withValues(alpha: 0.35), blurRadius: 14)],
                    )),
                Text('of E♭',
                    style: TextStyle(
                        fontSize: wide ? 15 : 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.55))),
                const Spacer(),
                Text('Tap to reveal',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.42))),
              ],
            ),
          ),
          if (wide) const _Glyph(Icons.visibility_rounded, _gold, size: 54),
        ]),
      );
}

class _Daily extends StatelessWidget {
  final bool played;
  final bool wide;
  const _Daily({required this.played, required this.wide});

  @override
  Widget build(BuildContext context) {
    const keyColour = Color(0xFF60A5FA);
    return _Surface(
      accent: played ? _violet : _gold,
      lit: !played,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow(wide ? 'DAILY CHALLENGE' : 'DAILY',
              accent: played ? Colors.white.withValues(alpha: 0.45) : _gold,
              trailing: _Chip('🔥 7',
                  colour: played ? Colors.white.withValues(alpha: 0.55) : _gold)),
          const Spacer(),
          // On the small tile the key IS the headline — repeating it as
          // "Key of B♭" next to a tile that already says B♭ cost the line that
          // tells you what the run actually is.
          if (!wide)
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              _KeyTile('B♭', played ? _violet : keyColour, size: 52),
              const SizedBox(width: 10),
              Expanded(
                child: Text(played ? '9/10' : 'today',
                    maxLines: 1,
                    style: TextStyle(
                        fontSize: played ? 24 : 15,
                        fontWeight: FontWeight.w800,
                        color: played ? Colors.white : Colors.white.withValues(alpha: 0.55))),
              ),
            ])
          else
            Row(children: [
              _KeyTile('B♭', keyColour, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(played ? '9/10' : 'Key of B♭',
                        maxLines: 1,
                        style: const TextStyle(
                            fontSize: 23, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 3),
                    Text(played ? '🟩🟩🟩🟥🟩🟩🟩🟩🟩🟩' : '10 questions · 40 seconds',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.5))),
                    if (!played)
                      Text('Chromatic',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: keyColour.withValues(alpha: 0.9))),
                  ],
                ),
              ),
              if (!played) const _Glyph(Icons.play_arrow_rounded, _gold, size: 46),
            ]),
          const Spacer(),
          if (!wide)
            Text(played ? 'Next one tomorrow' : '10 questions · 40s',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.5))),
        ],
      ),
    );
  }
}

class _Level extends StatelessWidget {
  const _Level();

  @override
  Widget build(BuildContext context) => _Surface(
        accent: _mint,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Eyebrow('YOUR LEVEL',
                accent: _mint,
                trailing: Text('4/8',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withValues(alpha: 0.40)))),
            const Spacer(),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Text('🦊', style: TextStyle(fontSize: 30)),
              const SizedBox(width: 8),
              const Text('38%',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white)),
            ]),
            const Text('Fox',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: _mint)),
            const Spacer(),
            const _Bar(0.38, _mint),
            const SizedBox(height: 5),
            Text('Quick, and getting quicker.',
                maxLines: 2,
                style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.42))),
          ],
        ),
      );
}

class _Map extends StatelessWidget {
  final bool tall;
  const _Map({this.tall = false});

  static const _keys = [
    ('C', Color(0xFFFF4D4D), 0.72),
    ('D♭', Color(0xFFFFB84D), 0.0),
    ('D', Color(0xFFFFE24D), 0.44),
    ('E♭', Color(0xFFA3E635), 0.0),
    ('E', Color(0xFF4ADE80), 0.30),
    ('F', Color(0xFF34D399), 0.58),
    ('F♯', Color(0xFF22D3EE), 0.0),
    ('G', Color(0xFF60A5FA), 0.66),
    ('A♭', Color(0xFF818CF8), 0.12),
    ('A', Color(0xFFA855F7), 0.51),
    ('B♭', Color(0xFFE879F9), 0.0),
    ('B', Color(0xFFFB7185), 0.22),
  ];

  @override
  Widget build(BuildContext context) {
    final columns = tall ? 4 : 6;
    final gap = tall ? 9.0 : 7.0;
    return _Surface(
      accent: _cyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow('KEY MASTERY',
              accent: _cyan,
              trailing: Text('38%',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.white.withValues(alpha: 0.55)))),
          SizedBox(height: gap),
          Expanded(
            child: LayoutBuilder(builder: (context, c) {
              final rows = (_keys.length / columns).ceil();
              final side = [
                (c.maxWidth - gap * (columns - 1)) / columns,
                (c.maxHeight - gap * (rows - 1)) / rows,
              ].reduce((a, b) => a < b ? a : b);
              return Column(
                children: [
                  for (var r = 0; r < rows; r++) ...[
                    if (r > 0) SizedBox(height: gap),
                    Row(children: [
                      for (var c2 = 0; c2 < columns; c2++) ...[
                        if (c2 > 0) SizedBox(width: gap),
                        if (r * columns + c2 < _keys.length)
                          () {
                            final k = _keys[r * columns + c2];
                            final played = k.$3 > 0;
                            return _KeyTile(
                              k.$1,
                              played ? k.$2 : Colors.white.withValues(alpha: 0.30),
                              size: side,
                              fill: played ? k.$3 : 0,
                            );
                          }(),
                      ],
                    ]),
                  ],
                ],
              );
            }),
          ),
          if (tall) ...[
            SizedBox(height: gap),
            const _Bar(0.38, _cyan, height: 7),
            const SizedBox(height: 8),
            const Text('🦊  Fox',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _mint)),
          ],
        ],
      ),
    );
  }
}

/// The last seven days, oldest first, today last and ringed.
class _WeekDots extends StatelessWidget {
  final Color colour;
  final double size;
  const _WeekDots(this.colour, {this.size = 9});

  static const _week = [true, true, false, true, true, true, false];

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < _week.length; i++) ...[
            if (i > 0) SizedBox(width: size * 0.62),
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _week[i] ? colour : Colors.white.withValues(alpha: 0.12),
                border: i == _week.length - 1
                    ? Border.all(color: colour.withValues(alpha: 0.85), width: 1.5)
                    : null,
              ),
            ),
          ],
        ],
      );
}

class _Streak extends StatelessWidget {
  final bool atRisk;
  final bool wide;
  const _Streak({required this.atRisk, this.wide = false});

  @override
  Widget build(BuildContext context) {
    final colour = atRisk ? _gold : _ember;
    return _Surface(
      accent: colour,
      lit: atRisk,
      child: wide
          ? Row(children: [
              const Text('🔥', style: TextStyle(fontSize: 54)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('7',
                        style: TextStyle(
                            fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white)),
                    Text(atRisk ? 'Play today to keep it' : 'day streak',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: atRisk ? _gold : Colors.white.withValues(alpha: 0.5))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _WeekDots(colour, size: 11),
                  if (atRisk) ...[
                    const SizedBox(height: 10),
                    const _Glyph(Icons.play_arrow_rounded, _gold, size: 44),
                  ],
                ],
              ),
            ])
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Eyebrow('STREAK', accent: colour),
                const Spacer(),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: const [
                  Text('🔥', style: TextStyle(fontSize: 30)),
                  SizedBox(width: 6),
                  Text('7',
                      style: TextStyle(
                          fontSize: 42, fontWeight: FontWeight.w800, color: Colors.white)),
                ]),
                const Spacer(),
                _WeekDots(colour),
                const SizedBox(height: 7),
                Text(atRisk ? 'Play today to keep it' : 'days in a row',
                    maxLines: 2,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: atRisk ? _gold : Colors.white.withValues(alpha: 0.45))),
              ],
            ),
    );
  }
}

class _Weakest extends StatelessWidget {
  const _Weakest();

  @override
  Widget build(BuildContext context) => _Surface(
        accent: _rose,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Eyebrow('NEEDS WORK', accent: _rose),
            const Spacer(),
            Row(children: [
              const _KeyTile('A♭', _rose, size: 52),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('12%',
                      style:
                          TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _rose)),
                  Text('mastered',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.45))),
                ],
              ),
            ]),
            const Spacer(),
            Text('Your weakest key. Tap to train it.',
                maxLines: 2,
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.45))),
          ],
        ),
      );
}

class _Pocket extends StatelessWidget {
  const _Pocket();

  @override
  Widget build(BuildContext context) => _Surface(
        accent: _indigo,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Eyebrow('HANDS-FREE', accent: _indigo),
            const Spacer(),
            const _Glyph(Icons.headphones_rounded, _indigo, size: 46),
            const Spacer(),
            const Text('Pocket Mode',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white)),
            Text('Train with the screen off',
                maxLines: 2,
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.45))),
          ],
        ),
      );
}

class _Launcher extends StatelessWidget {
  const _Launcher();

  static const _modes = [
    ('Daily', Icons.local_fire_department_rounded, _gold),
    ('Pocket', Icons.headphones_rounded, _indigo),
    ('Chromatic', Icons.music_note_rounded, _violet),
    ('Custom', Icons.tune_rounded, Color(0xFFD857EC)),
  ];

  @override
  Widget build(BuildContext context) => _Surface(
        accent: _indigo,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Eyebrow('START TRAINING', accent: _indigo),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: [
                  for (final (name, icon, colour) in _modes) ...[
                    if (name != 'Daily') const SizedBox(width: 9),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: colour.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colour.withValues(alpha: 0.22)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _Glyph(icon, colour, size: 40),
                            const SizedBox(height: 6),
                            Text(name,
                                maxLines: 1,
                                style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white.withValues(alpha: 0.72))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}

class _Theory extends StatelessWidget {
  const _Theory();

  @override
  Widget build(BuildContext context) => _Surface(
        accent: _rose,
        child: Row(children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _rose.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: _rose.withValues(alpha: 0.35)),
            ),
            alignment: Alignment.center,
            child: const Text('♭7',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _rose)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const _Eyebrow('DEGREE OF THE DAY', accent: _rose),
                const SizedBox(height: 5),
                Text(
                    'The ♭7 is what turns a major chord into a dominant — '
                    'the sound of wanting to move somewhere.',
                    maxLines: 4,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                        color: Colors.white.withValues(alpha: 0.88))),
              ],
            ),
          ),
        ]),
      );
}
