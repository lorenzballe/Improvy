const List<String> kKeys = ['C', 'G', 'F', 'D', 'B♭', 'A', 'E♭', 'E', 'A♭', 'B', 'D♭', 'F♯'];

const List<String> kAllKeys = ['C', 'G', 'D', 'A', 'E', 'B', 'F♯', 'D♭', 'A♭', 'E♭', 'B♭', 'F'];

// One degree label per semitone. The three tritone-adjacent degrees use both
// enharmonic spellings (e.g. '♭3/♯2') so the question and the note buttons
// stay mutually consistent — matching the web app's CHROMATIC_DEGREES constant.
const List<String> kChromaticDegrees = [
  '1', '♭2', '2', '♭3/♯2', '3', '4', '♭5/♯4', '5', '♭6/♯5', '6', '♭7', '7'
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
  '♭5/♯4': ['♯4', '♭5'],
  '♭6/♯5': ['♯5', '♭6'],
};

// A split spelling → the slash degree it collapses back to (for the reverse switch).
const Map<String, String> kDegreeCollapseMap = {
  '♯2': '♭3/♯2', '♭3': '♭3/♯2',
  '♯4': '♭5/♯4', '♭5': '♭5/♯4',
  '♯5': '♭6/♯5', '♭6': '♭6/♯5',
};

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
