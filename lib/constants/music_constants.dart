const List<String> kKeys = ['C', 'G', 'F', 'D', 'B♭', 'A', 'E♭', 'E', 'A♭', 'B', 'D♭', 'F♯'];

const List<String> kAllKeys = ['C', 'G', 'D', 'A', 'E', 'B', 'F♯', 'D♭', 'A♭', 'E♭', 'B♭', 'F'];

// One degree label per semitone. The three tritone-adjacent degrees use both
// enharmonic spellings (e.g. '♭3/♯2') so the question and the note buttons
// stay mutually consistent — matching the web app's CHROMATIC_DEGREES constant.
const List<String> kChromaticDegrees = [
  '1', '♭2', '2', '♭3/♯2', '3', '4', '♯4/♭5', '5', '♭6/♯5', '6', '♭7', '7'
];

// Note→Number trains the DEGREE from a note, where a note's spelling implies a
// specific degree (F = ♭3, but E♯ = ♯2). So in that direction each enharmonic
// degree is split into its two spellings — distinct degrees with distinct
// musical functions, tracked separately. (Degree→Note keeps the slash form,
// since there a single degree maps to an enharmonic note button.)
const List<String> kChromaticDegreesSplit = [
  '1', '♭2', '2', '♯2', '♭3', '3', '4', '♯4', '♭5', '5', '♯5', '♭6', '6', '♭7', '7'
];

// Slash degree → its two split spellings (sharp-of-lower first, then flat-of-higher).
const Map<String, List<String>> kDegreeSplitMap = {
  '♭3/♯2': ['♯2', '♭3'],
  '♯4/♭5': ['♯4', '♭5'],
  '♭6/♯5': ['♯5', '♭6'],
};

// A split spelling → the slash degree it collapses back to (for the reverse switch).
const Map<String, String> kDegreeCollapseMap = {
  '♯2': '♭3/♯2', '♭3': '♭3/♯2',
  '♯4': '♯4/♭5', '♭5': '♯4/♭5',
  '♯5': '♭6/♯5', '♭6': '♭6/♯5',
};

// Roman labels for the 15 distinct degree spellings, in scale order.
// Enharmonic degrees (♯II/bIII, ♯IV/bV, ♯V/bVI) are separate entries: the
// trainer asks them as distinct questions (kChromaticDegreesSplit), so every
// stats screen must count them separately too.
const List<String> kRomanDegrees = [
  'I', 'bII', 'II', '♯II', 'bIII', 'III', 'IV', '♯IV', 'bV', 'V', '♯V', 'bVI', 'VI', 'bVII', 'VII',
];

// Roman label for each of the 12 semitones, flat spellings only — for places
// that name the degree of a RAW PITCH (e.g. the note the user tapped), where
// no enharmonic spelling exists.
const List<String> kFlatRomanBySemitone = [
  'I', 'bII', 'II', 'bIII', 'III', 'IV', 'bV', 'V', 'bVI', 'VI', 'bVII', 'VII',
];

// Stored degree token → roman label ('♭3' → 'bIII', '♯11' → '♯IV', '' on
// unknown). Legacy slash records ('♭3/♯2') predate the enharmonic split —
// attributed to the first-listed spelling, matching how they were shown then.
String romanDegree(String raw) {
  if (raw.isEmpty) return '';
  var d = raw.split('/')[0].trim();
  d = d.replaceAll('b', '♭').replaceAll('#', '♯');
  const ext = {'♭9': '♭2', '9': '2', '♯9': '♯2', '11': '4', '♯11': '♯4', '♭13': '♭6', '13': '6'};
  d = ext[d] ?? d;
  var acc = '';
  if (d.startsWith('♭')) { acc = 'b'; d = d.substring(1); }
  else if (d.startsWith('♯')) { acc = '♯'; d = d.substring(1); }
  const roman = {'1': 'I', '2': 'II', '3': 'III', '4': 'IV', '5': 'V', '6': 'VI', '7': 'VII'};
  final r = roman[d];
  return r == null ? '' : '$acc$r';
}

const Map<String, int> kNoteToSemitone = {
  'C': 0, 'B#': 0, 'B♯': 0,
  'C#': 1, 'C♯': 1, 'Db': 1, 'D♭': 1,
  'D': 2,
  'D#': 3, 'D♯': 3, 'Eb': 3, 'E♭': 3,
  'E': 4, 'Fb': 4, 'F♭': 4,
  'F': 5, 'E#': 5, 'E♯': 5,
  'F#': 6, 'F♯': 6, 'Gb': 6, 'G♭': 6,
  'G': 7,
  'G#': 8, 'G♯': 8, 'Ab': 8, 'A♭': 8,
  'A': 9,
  'A#': 10, 'A♯': 10, 'Bb': 10, 'B♭': 10,
  'B': 11, 'Cb': 11, 'C♭': 11,
  // Double accidentals (double-sharp 𝄪 / double-flat 𝄫) — needed so chromatic
  // enharmonic spellings in sharp/flat keys render correctly (e.g. G/F𝄪, E𝄫).
  'C𝄪': 2, 'Cx': 2, 'C##': 2, 'C𝄫': 10, 'Cbb': 10,
  'D𝄪': 4, 'Dx': 4, 'D##': 4, 'D𝄫': 0, 'Dbb': 0,
  'E𝄪': 6, 'Ex': 6, 'E##': 6, 'E𝄫': 2, 'Ebb': 2,
  'F𝄪': 7, 'Fx': 7, 'F##': 7, 'F𝄫': 3, 'Fbb': 3,
  'G𝄪': 9, 'Gx': 9, 'G##': 9, 'G𝄫': 5, 'Gbb': 5,
  'A𝄪': 11, 'Ax': 11, 'A##': 11, 'A𝄫': 7, 'Abb': 7,
  'B𝄪': 1, 'Bx': 1, 'B##': 1, 'B𝄫': 9, 'Bbb': 9,
};

const Map<String, String> kDoReMiMapping = {
  'C': 'Do', 'D': 'Re', 'E': 'Mi', 'F': 'Fa', 'G': 'Sol', 'A': 'La', 'B': 'Si'
};
