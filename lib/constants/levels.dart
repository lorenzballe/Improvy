import 'package:flutter/material.dart';

/// How many animal levels there are, top to bottom. The Level widget shows
/// "Level 3 of 8", and that 8 must follow the ladder rather than be retyped.
const int kAnimalLevelCount = 8;

class AnimalLevel {
  final int level;
  final String name;
  final String emoji;
  final Color color;
  final String hex;
  final String quote;

  const AnimalLevel({
    required this.level,
    required this.name,
    required this.emoji,
    required this.color,
    required this.hex,
    required this.quote,
  });
}

/// Where each animal starts, level 2 through 8. Level 1 is where everyone
/// begins, so it has no threshold.
///
/// Deliberately NOT eight equal steps, which is what they were. That spacing
/// was set when a key counted one skill; the scale is now three families deep,
/// so the same 12.5% costs three times the work and the FIRST level-up — the
/// moment someone decides the app is theirs — had drifted to about fourteen
/// perfect sessions. It is now about two.
///
/// The gaps widen all the way up (2, 4, 6, 10, 14, 18, 22), which is also what
/// the names promise: snail to turtle should be quick, falcon to cheetah
/// should cost. Past Cheetah the last stretch to a perfect 100 carries no new
/// animal, exactly as it did before.
const List<double> kAnimalThresholds = [2, 6, 12, 22, 36, 54, 76];

AnimalLevel getAnimalLevel(double progress) {
  // Quotes are plain text — the UI adds typographic “ ” marks where shown.
  if (progress >= kAnimalThresholds[6]) return AnimalLevel(level: 8, name: 'Cheetah', emoji: '🐆', color: const Color(0xFFeab308), hex: '#eab308', quote: 'Unstoppable! True Maestro!');
  if (progress >= kAnimalThresholds[5]) return AnimalLevel(level: 7, name: 'Falcon', emoji: '🦅', color: const Color(0xFFcbd5e1), hex: '#cbd5e1', quote: 'Soaring high! Sharp vision!');
  if (progress >= kAnimalThresholds[4]) return AnimalLevel(level: 6, name: 'Horse', emoji: '🐴', color: const Color(0xFFd97706), hex: '#d97706', quote: 'Galloping with precision!');
  if (progress >= kAnimalThresholds[3]) return AnimalLevel(level: 5, name: 'Fox', emoji: '🦊', color: const Color(0xFFf97316), hex: '#f97316', quote: 'Clever and quick!');
  if (progress >= kAnimalThresholds[2]) return AnimalLevel(level: 4, name: 'Rabbit', emoji: '🐰', color: const Color(0xFFf472b6), hex: '#f472b6', quote: 'Fast as a hare!');
  if (progress >= kAnimalThresholds[1]) return AnimalLevel(level: 3, name: 'Penguin', emoji: '🐧', color: const Color(0xFF0ea5e9), hex: '#0ea5e9', quote: 'Sliding smoothly!');
  if (progress >= kAnimalThresholds[0]) return AnimalLevel(level: 2, name: 'Turtle', emoji: '🐢', color: const Color(0xFF22c55e), hex: '#22c55e', quote: 'Steady progress!');
  return AnimalLevel(level: 1, name: 'Snail', emoji: '🐌', color: const Color(0xFFa3e635), hex: '#a3e635', quote: 'Slow and steady wins!');
}
