import 'package:flutter/material.dart';

/// Renders a note name with accidentals (♯/♭) as superscript
class NoteText extends StatelessWidget {
  final String note;
  final TextStyle? style;

  const NoteText({super.key, required this.note, this.style});

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold);
    if (!note.contains('♯') && !note.contains('♭') && !note.contains('#') && !note.contains('b') &&
        !note.contains('𝄪') && !note.contains('𝄫')) {
      return Text(note, style: baseStyle);
    }

    final spans = <InlineSpan>[];
    // Alternation (not a char class) + unicode so the surrogate-pair double
    // accidentals 𝄪 / 𝄫 are matched as whole code points.
    final pattern = RegExp('(𝄪|𝄫|♯|♭|#|b)', unicode: true);
    final parts = note.split(pattern);
    final matches = pattern.allMatches(note).map((m) => m.group(0)!).toList();

    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        spans.add(TextSpan(text: parts[i], style: baseStyle));
      }
      if (i < matches.length) {
        // Display double accidentals as the common 'x' (double-sharp) and 'bb'
        // (double-flat) so they render reliably regardless of font.
        final raw = matches[i];
        final acc = raw == '#' ? '♯' : raw == 'b' ? '♭' : raw == '𝄪' ? 'x' : raw == '𝄫' ? '♭♭' : raw;
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.top,
          child: Text(
            acc,
            style: baseStyle.copyWith(fontSize: (baseStyle.fontSize ?? 16) * 0.65),
          ),
        ));
      }
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
