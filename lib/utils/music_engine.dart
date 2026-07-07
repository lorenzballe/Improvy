import '../constants/music_constants.dart';

const List<String> _naturalNotes = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];

List<String> calculateMajorScale(String root) {
  final rootLetter = root[0];
  final rootIndex = _naturalNotes.indexOf(rootLetter);
  if (rootIndex == -1) return ['C', 'D', 'E', 'F', 'G', 'A', 'B'];

  final scale = <String>[];
  const intervals = [0, 2, 4, 5, 7, 9, 11];
  final rootSemitone = kNoteToSemitone[root] ?? 0;

  for (var i = 0; i < 7; i++) {
    final naturalNote = _naturalNotes[(rootIndex + i) % 7];
    final targetSemitone = (rootSemitone + intervals[i]) % 12;

    var found = false;
    for (final accidental in ['', '♯', '♭', '𝄪', '𝄫', '#', 'b']) {
      final candidate = naturalNote + accidental;
      if (kNoteToSemitone[candidate] == targetSemitone) {
        scale.add(candidate);
        found = true;
        break;
      }
    }
    if (!found) scale.add(naturalNote);
  }
  return scale;
}

bool areEnharmonicEquivalent(String n1, String n2) {
  if (n1.isEmpty || n2.isEmpty) return false;
  return kNoteToSemitone[n1] == kNoteToSemitone[n2];
}

String getNoteFromChromaticDegree(String degree, List<String> scale, String key) {
  final cleanDegree = degree.split('/')[0];
  const mapping = {
    '1': 0,
    '♭2': 1, 'b2': 1, '♭9': 1, 'b9': 1,
    '2': 2, '9': 2,
    '♯2': 3, '#2': 3, '♭3': 3, 'b3': 3, '♯9': 3, '#9': 3,
    '3': 4,
    '4': 5, '11': 5,
    '♯4': 6, '#4': 6, '♭5': 6, 'b5': 6, '♯11': 6, '#11': 6,
    '5': 7,
    '♯5': 8, '#5': 8, '♭6': 8, 'b6': 8, '♭13': 8, 'b13': 8,
    '6': 9, '13': 9,
    '♭7': 10, 'b7': 10,
    '7': 11,
  };

  const letterOffsets = {
    '1': 0,
    '♭2': 1, 'b2': 1, '♭9': 1, 'b9': 1,
    '2': 1, '9': 1,
    '♯2': 1, '#2': 1, '♯9': 1, '#9': 1,
    '♭3': 2, 'b3': 2, '3': 2,
    '4': 3, '11': 3,
    '♯4': 3, '#4': 3, '♯11': 3, '#11': 3,
    '♭5': 4, 'b5': 4, '5': 4, '♯5': 4, '#5': 4,
    '♭6': 5, 'b6': 5, '♭13': 5, 'b13': 5, '6': 5, '13': 5,
    '♭7': 6, 'b7': 6, '7': 6,
  };

  final rootSemitone = kNoteToSemitone[key] ?? 0;
  final semitoneOffset = mapping[cleanDegree] ?? 0;
  final targetSemitone = (rootSemitone + semitoneOffset) % 12;

  final rootLetter = key[0];
  final rootIndex = _naturalNotes.indexOf(rootLetter);
  final letterOffset = letterOffsets[cleanDegree];

  if (letterOffset != null) {
    final targetLetter = _naturalNotes[(rootIndex + letterOffset) % 7];
    for (final acc in ['', '♯', '♭', '𝄪', '𝄫', '#', 'b']) {
      final candidate = targetLetter + acc;
      if (kNoteToSemitone[candidate] == targetSemitone) return candidate;
    }
  }

  // Fallback to scale note or default name
  for (final s in scale) {
    if (areEnharmonicEquivalent(s, _getSemitoneNoteName(targetSemitone))) return s;
  }
  return _getSemitoneNoteName(targetSemitone);
}

/// Note names for the on-screen piano in CHROMATIC mode: every semitone is
/// spelled by its degree relative to [key] — 1 ♭2 2 ♭3 3 4 ♯4 5 ♭6 6 ♭7 7.
/// So in C the black keys read D♭ E♭ F♯ A♭ B♭ (A♭, not G♯), while in D the
/// tritone makes G♯ (♯4). Returns semitone → spelled note name.
Map<int, String> chromaticKeyboardNoteNames(String key) {
  const degs = ['1', '♭2', '2', '♭3', '3', '4', '♯4', '5', '♭6', '6', '♭7', '7'];
  final names = <int, String>{};
  for (final d in degs) {
    final note = getNoteFromChromaticDegree(d, const [], key);
    final s = kNoteToSemitone[note];
    if (s != null) names[s] = note;
  }
  return names;
}

String _getSemitoneNoteName(int semitone) {
  const names = {
    0: 'C', 1: 'D♭', 2: 'D', 3: 'E♭', 4: 'E',
    5: 'F', 6: 'G♭', 7: 'G', 8: 'A♭', 9: 'A', 10: 'B♭', 11: 'B'
  };
  return names[semitone % 12] ?? 'C';
}

class NoteItem {
  final String label;
  final String? rawLabel;
  final String note;
  final bool disabled;

  NoteItem({required this.label, this.rawLabel, required this.note, this.disabled = false});
}

List<NoteItem> getChromaticButtons(List<String> scale, String key) {
  const notes  = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
  const labels = ['C', 'C#/D♭', 'D', 'D#/E♭', 'E', 'F', 'F#/G♭', 'G', 'G#/A♭', 'A', 'A#/B♭', 'B'];
  return List.generate(12, (i) => NoteItem(label: labels[i], rawLabel: labels[i], note: notes[i]));
}

String formatNoteText(String note) {
  // Returns plain text version (no rich text)
  return note.replaceAll('♯', '#').replaceAll('♭', 'b');
}

String normalizeExtension(String degree) {
  const map = {
    '9': '2', '♭9': '♭2', '♯9': '♯2',
    '11': '4', '♯11': '♯4',
    '13': '6', '♭13': '♭6',
  };
  return map[degree] ?? degree;
}
