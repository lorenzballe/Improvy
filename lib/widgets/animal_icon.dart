import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Stylized line-art level icons, identical to the web app's:
/// Snail / Turtle / Rabbit / Falcon use lucide icons; Penguin / Fox / Horse /
/// Cheetah use the app's own custom SVGs. Rendered as a single stroke colour via
/// a srcIn colour filter, so they stay crisp and tinted at any size.
class AnimalIcon extends StatelessWidget {
  final String name;
  final Color color;
  final double size;
  final double strokeWidth;

  const AnimalIcon({
    super.key,
    required this.name,
    required this.color,
    this.size = 28,
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final inner = _animalPaths[name] ?? _animalPaths['Snail']!;
    final svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
        'fill="none" stroke="#000000" stroke-width="$strokeWidth" '
        'stroke-linecap="round" stroke-linejoin="round">$inner</svg>';
    return SvgPicture.string(
      svg,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

const Map<String, String> _animalPaths = {
  // lucide: snail
  'Snail':
      '<path d="M2 13a6 6 0 1 0 12 0 4 4 0 1 0-8 0 2 2 0 0 0 4 0"/>'
      '<circle cx="10" cy="13" r="8"/>'
      '<path d="M2 21h12c4.4 0 8-3.6 8-8V7a2 2 0 1 0-4 0v6"/>'
      '<path d="M18 3 19.1 5.2"/>'
      '<path d="M22 3 20.9 5.2"/>',
  // lucide: turtle
  'Turtle':
      '<path d="m12 10 2 4v3a1 1 0 0 0 1 1h2a1 1 0 0 0 1-1v-3a8 8 0 1 0-16 0v3a1 1 0 0 0 1 1h2a1 1 0 0 0 1-1v-3l2-4h4Z"/>'
      '<path d="M4.82 7.9 8 10"/>'
      '<path d="M15.18 7.9 12 10"/>'
      '<path d="M16.93 10H20a2 2 0 0 1 0 4H2"/>',
  // custom
  'Penguin':
      '<path d="M12 2c-3.3 0-6 2.7-6 6v8a6 6 0 0 0 12 0V8c0-3.3-2.7-6-6-6Z"/>'
      '<path d="M9 10h.01"/>'
      '<path d="M15 10h.01"/>'
      '<path d="M12 13l-1-1h2z"/>'
      '<path d="M6 12l-2 2 1 3"/>'
      '<path d="M18 12l2 2-1 3"/>'
      '<path d="M9 22v-2"/>'
      '<path d="M15 22v-2"/>',
  // lucide: rabbit
  'Rabbit':
      '<path d="M13 16a3 3 0 0 1 2.24 5"/>'
      '<path d="M18 12h.01"/>'
      '<path d="M18 21h-8a4 4 0 0 1-4-4 7 7 0 0 1 7-7h.2L9.6 6.4a1 1 0 1 1 2.8-2.8L15.8 7h.2c3.3 0 6 2.7 6 6v1a2 2 0 0 1-2 2h-1a3 3 0 0 0-3 3"/>'
      '<path d="M20 8.54V4a2 2 0 1 0-4 0v3"/>'
      '<path d="M7.612 12.524a3 3 0 1 0-1.6 4.3"/>',
  // custom
  'Fox':
      '<path d="M3 3l3 7"/>'
      '<path d="M21 3l-3 7"/>'
      '<path d="M6 10l6 9 6-9-6-4-6 4z"/>'
      '<path d="M9 12h.01"/>'
      '<path d="M15 12h.01"/>'
      '<path d="M12 17h.01"/>',
  // custom
  'Horse':
      '<path d="M8 20h8"/>'
      '<path d="M10 20V14l-4-2 1-4 3-1V4l3 1 3 4v5l-2 2v4"/>'
      '<path d="M14 4l1-2 2 1"/>'
      '<path d="M10 10h.01"/>',
  // lucide: bird
  'Falcon':
      '<path d="M16 7h.01"/>'
      '<path d="M3.4 18H12a8 8 0 0 0 8-8V7a4 4 0 0 0-7.28-2.3L2 20"/>'
      '<path d="m20 7 2 .5-2 .5"/>'
      '<path d="M10 18v3"/>'
      '<path d="M14 17.75V21"/>'
      '<path d="M7 18a6 6 0 0 0 3.84-10.61"/>',
  // custom
  'Cheetah':
      '<path d="M12 5c.67 0 1.35.09 2 .26 1.78-2 5.03-2.84 6.42-2.26 1.4.58-.42 7-.42 7 .57 1.07 1 2.24 1 3.44C21 17.9 16.97 21 12 21s-9-3-9-7.56c0-1.25.5-2.4 1-3.44 0 0-1.89-6.42-.5-7 1.39-.58 4.72.23 6.5 2.23A9.04 9.04 0 0 1 12 5Z"/>'
      '<path d="M8 14v.5"/>'
      '<path d="M16 14v.5"/>'
      '<path d="M11.25 16.25h1.5L12 17l-.75-.75Z"/>'
      '<circle cx="7" cy="18" r="0.5" fill="#000000"/>'
      '<circle cx="17" cy="18" r="0.5" fill="#000000"/>'
      '<circle cx="14" cy="19" r="0.5" fill="#000000"/>'
      '<circle cx="10" cy="19" r="0.5" fill="#000000"/>',
};
