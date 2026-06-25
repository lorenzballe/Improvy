import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0F0A1A);
  static const Color surface = Color(0xFF1A1625);
  static const Color surfaceLight = Color(0xFF241D35);

  static const Map<String, Color> noteColors = {
    // C — Red
    'C':  Color(0xFFff4d4d),
    'B#': Color(0xFFff4d4d),
    'B♯': Color(0xFFff4d4d),
    // C#/Db — Orange
    'C#': Color(0xFFff944d),
    'C♯': Color(0xFFff944d),
    'Db': Color(0xFFff944d),
    'D♭': Color(0xFFff944d),
    // D — Yellow-Orange
    'D':  Color(0xFFffdb4d),
    // D#/Eb — Yellow
    'D#': Color(0xFFffff4d),
    'D♯': Color(0xFFffff4d),
    'Eb': Color(0xFFffff4d),
    'E♭': Color(0xFFffff4d),
    // E — Green
    'E':  Color(0xFF4dff4d),
    'Fb': Color(0xFF4dff4d),
    'F♭': Color(0xFF4dff4d),
    // F — Cyan/Teal
    'F':  Color(0xFF00dcdc),
    'E#': Color(0xFF00dcdc),
    'E♯': Color(0xFF00dcdc),
    // F#/Gb — Light Blue
    'F#': Color(0xFF4d94ff),
    'F♯': Color(0xFF4d94ff),
    'Gb': Color(0xFF4d94ff),
    'G♭': Color(0xFF4d94ff),
    // G — Blue
    'G':  Color(0xFF4d4dff),
    // G#/Ab — Purple
    'G#': Color(0xFF944dff),
    'G♯': Color(0xFF944dff),
    'Ab': Color(0xFF944dff),
    'A♭': Color(0xFF944dff),
    // A — Magenta
    'A':  Color(0xFFff4dff),
    // A#/Bb — Pink
    'A#': Color(0xFFff4d94),
    'A♯': Color(0xFFff4d94),
    'Bb': Color(0xFFff4d94),
    'B♭': Color(0xFFff4d94),
    // B/Cb — Red (wraps around)
    'B':  Color(0xFFff4d4d),
    'Cb': Color(0xFFff4d4d),
    'C♭': Color(0xFFff4d4d),
  };

  static const Map<String, Color> degreeColors = {
    '1':         Color(0xFFff4d4d),
    '♭2':        Color(0xFFff944d),
    '2':         Color(0xFFffdb4d),
    '♭3':        Color(0xFFffff4d),
    '♭3/♯2':     Color(0xFFffff4d),
    '♯2':        Color(0xFFffff4d),
    '3':         Color(0xFF4dff4d),
    '4':         Color(0xFF00dcdc),
    '♯4':        Color(0xFF4d94ff),
    '♭5':        Color(0xFF4d94ff),
    '♯4/♭5':     Color(0xFF4d94ff),
    '♭5/♯4':     Color(0xFF4d94ff),
    '5':         Color(0xFF4d4dff),
    '♭6':        Color(0xFF944dff),
    '♯5':        Color(0xFF944dff),
    '♭6/♯5':     Color(0xFF944dff),
    '♯5/♭6':     Color(0xFF944dff),
    '6':         Color(0xFFff4dff),
    '♭7':        Color(0xFFff4d94),
    '7':         Color(0xFFff4d4d),
  };

  // Positional rainbow: hsl(index × 30°, 95%, 60%)
  static Color keyColor(int index) =>
      HSLColor.fromAHSL(1.0, (index * 30.0) % 360, 0.95, 0.60).toColor();
}
