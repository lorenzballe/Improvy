import '../l10n/l10n.dart';

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

  /// Which sentence: `theoryCard<id>` in the ARB files. The words live there,
  /// in every language the app speaks, rather than here in one — the widget
  /// used to show an English paragraph under a localised header.
  final int id;

  const TheoryCard(this.degree, this.hex, this.id);

  String text(AppLocalizations l) => switch (id) {
        1 => l.theoryCard1,
        2 => l.theoryCard2,
        3 => l.theoryCard3,
        4 => l.theoryCard4,
        5 => l.theoryCard5,
        6 => l.theoryCard6,
        7 => l.theoryCard7,
        8 => l.theoryCard8,
        9 => l.theoryCard9,
        10 => l.theoryCard10,
        _ => l.theoryCard11,
      };
}

/// The rotation. Indexed by the day number, so every device shows the same card
/// on the same date and it turns over at midnight without the app running.
/// Length is deliberately not a multiple of 7 — a weekly cycle would make the
/// same card land on every Monday.
///
/// The order is the rotation, and the ids name the sentences in the ARB files
/// (`theoryCard1` is the ♭7's). Appending is safe; reordering moves every
/// day's card.
const List<TheoryCard> kTheoryCards = [
  TheoryCard('♭7', '#ff4d94', 1),
  TheoryCard('3', '#4dff4d', 2),
  TheoryCard('5', '#4d4dff', 3),
  TheoryCard('♭3', '#ffff4d', 4),
  TheoryCard('♯4', '#00dcdc', 5),
  TheoryCard('2', '#ffdb4d', 6),
  TheoryCard('6', '#ff4dff', 7),
  TheoryCard('♭2', '#ff944d', 8),
  TheoryCard('7', '#ff4d4d', 9),
  TheoryCard('4', '#00dcdc', 10),
  TheoryCard('♭6', '#944dff', 11),
];
