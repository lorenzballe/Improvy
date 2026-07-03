import 'package:flutter/material.dart';

/// Renders a note name with accidentals (♯/♭) drawn from the bundled
/// **Noto Music** font instead of whatever symbol font the platform falls
/// back to (Android/iOS fallbacks size and sit those glyphs badly — too low
/// and too small).
///
/// Positioning is deterministic: each accidental is a [WidgetSpan] anchored
/// to the text baseline and nudged with a fixed [Transform.translate], so it
/// renders identically on every platform.
class NoteText extends StatelessWidget {
  final String note;
  final TextStyle? style;

  const NoteText({super.key, required this.note, this.style});

  static final _pattern = RegExp('(𝄪|𝄫|♯|♭|#|b)', unicode: true);

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold);
    if (!_pattern.hasMatch(note)) {
      return Text(note, style: baseStyle);
    }

    final baseSize = baseStyle.fontSize ?? 16;
    final accSize = baseSize * 0.78;
    final accColor = baseStyle.color ?? Colors.white;
    // Noto Music ships one (light) weight. Next to heavy display type the bare
    // glyph looks spindly, so we thicken it with a subtle same-color stroke
    // drawn underneath the fill.
    final accFill = baseStyle.copyWith(
      fontFamily: 'NotoMusic',
      fontSize: accSize,
      height: 1,
      fontWeight: FontWeight.w400,
    );
    final accStroke = accFill.copyWith(
      color: null,
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = accSize * 0.032
        ..color = accColor,
    );

    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in _pattern.allMatches(note)) {
      if (m.start > last) {
        spans.add(TextSpan(text: note.substring(last, m.start), style: baseStyle));
      }
      final raw = m.group(0)!;
      // Normalize ASCII spellings to real music glyphs; render double
      // accidentals with their proper single glyphs (Noto Music has both).
      final acc = switch (raw) {
        '#' => '♯',
        'b' => '♭',
        _ => raw,
      };
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: Transform.translate(
          // Lift the accidental into superscript position. Fixed fraction of
          // the letter size → same optics on every device.
          offset: Offset(0, -baseSize * 0.14),
          child: Stack(children: [
            Text(acc, style: accStroke),
            Text(acc, style: accFill),
          ]),
        ),
      ));
      last = m.end;
    }
    if (last < note.length) {
      spans.add(TextSpan(text: note.substring(last), style: baseStyle));
    }

    // Text.rich (not RichText) so the spans inherit the app's default font
    // (Lexend). Plain RichText falls back to Roboto, which made accidental and
    // slashed notes look different from single letters.
    return Text.rich(TextSpan(children: spans), textAlign: TextAlign.center);
  }
}

String formatNoteForDisplay(String note, String notation) {
  if (notation != 'DoReMi') return note;
  const map = {'C': 'Do', 'D': 'Re', 'E': 'Mi', 'F': 'Fa', 'G': 'Sol', 'A': 'La', 'B': 'Si'};
  return note.replaceAllMapped(RegExp(r'[CDEFGAB]'), (m) => map[m.group(0)] ?? m.group(0)!);
}
