import 'package:flutter/material.dart';

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

AnimalLevel getAnimalLevel(double progress) {
  // Quotes are plain text — the UI adds typographic “ ” marks where shown.
  if (progress >= 87.5) return AnimalLevel(level: 8, name: 'Cheetah', emoji: '🐆', color: const Color(0xFFeab308), hex: '#eab308', quote: 'Unstoppable! True Maestro!');
  if (progress >= 75) return AnimalLevel(level: 7, name: 'Falcon', emoji: '🦅', color: const Color(0xFFcbd5e1), hex: '#cbd5e1', quote: 'Soaring high! Sharp vision!');
  if (progress >= 62.5) return AnimalLevel(level: 6, name: 'Horse', emoji: '🐴', color: const Color(0xFFd97706), hex: '#d97706', quote: 'Galloping with precision!');
  if (progress >= 50) return AnimalLevel(level: 5, name: 'Fox', emoji: '🦊', color: const Color(0xFFf97316), hex: '#f97316', quote: 'Clever and quick!');
  if (progress >= 37.5) return AnimalLevel(level: 4, name: 'Rabbit', emoji: '🐰', color: const Color(0xFFf472b6), hex: '#f472b6', quote: 'Fast as a hare!');
  if (progress >= 25) return AnimalLevel(level: 3, name: 'Penguin', emoji: '🐧', color: const Color(0xFF0ea5e9), hex: '#0ea5e9', quote: 'Sliding smoothly!');
  if (progress >= 12.5) return AnimalLevel(level: 2, name: 'Turtle', emoji: '🐢', color: const Color(0xFF22c55e), hex: '#22c55e', quote: 'Steady progress!');
  return AnimalLevel(level: 1, name: 'Snail', emoji: '🐌', color: const Color(0xFFa3e635), hex: '#a3e635', quote: 'Slow and steady wins!');
}
