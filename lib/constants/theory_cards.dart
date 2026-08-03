/// One day's theory card, for the Theory of the Day widget.
///
/// A card is a scale degree and one sentence about what it *does* — Improvy is
/// about hearing the number under a note, so the sentence explains the note's
/// job, never its spelling.
class TheoryCard {
  /// The degree, written the way the app writes degrees (♭7, ♯4, …).
  final String degree;

  /// Hex colour for the degree, matched to the degree palette in app_colors.
  final String hex;

  final String text;

  const TheoryCard(this.degree, this.hex, this.text);
}

/// The rotation. Indexed by the day number, so every device shows the same card
/// on the same date and it turns over at midnight without the app running.
/// Length is deliberately not a multiple of 7 — a weekly cycle would make the
/// same card land on every Monday.
const List<TheoryCard> kTheoryCards = [
  TheoryCard('♭7', '#ff4d94',
      'The note that turns a major chord into a dominant — the pull that makes a resolution feel inevitable.'),
  TheoryCard('3', '#4dff4d',
      'The degree that decides major or minor. Move it one semitone and the whole colour of the key changes.'),
  TheoryCard('5', '#4d4dff',
      'The most stable note after the tonic. It is why a chord sounds settled, and why removing it sounds hollow.'),
  TheoryCard('♭3', '#ffff4d',
      'Minor in one note. Over a dominant chord it stops being sad and starts being blue.'),
  TheoryCard('♯4', '#00dcdc',
      'The tritone from the tonic — the furthest you can get from home, and the reason lydian sounds like it is floating.'),
  TheoryCard('2', '#ffdb4d',
      'Close enough to the tonic to lean on it, far enough to want to move. Add it to a chord and you get a 9.'),
  TheoryCard('6', '#ff4dff',
      'The note that makes a major chord sound wistful rather than triumphant — and the one that defines dorian in minor.'),
  TheoryCard('♭2', '#ff944d',
      'One semitone above home. The most unstable note in the key, which is exactly why it is so useful over a dominant.'),
  TheoryCard('7', '#ff4d4d',
      'The leading tone. It exists to resolve upward, and a key without it never quite closes.'),
  TheoryCard('4', '#00dcdc',
      'A semitone above the third, so it wants to fall. Suspend it instead and you get the most familiar delay in music.'),
  TheoryCard('♭6', '#944dff',
      'The note that darkens a minor key into something older — the difference between natural and harmonic.'),
];
