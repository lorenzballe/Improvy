import 'package:flutter/material.dart';

/// The thin bar across the foot of a key tile that says how far that key has
/// been taken.
///
/// It replaces an outline that traced a fraction of the tile's border, which
/// failed for one reason worth writing down: **it had no track**. The part not
/// yet earned was the tile's ordinary border — the same border an untouched
/// key already has — so there was nothing to measure the earned part against.
/// A key at 8% read as a rendering fault, and 62% and 100% could only be told
/// apart by comparing tiles with each other.
///
/// A bar carries its own empty half, which is the whole trick. It also cannot
/// be mistaken for the selected state, which a filled tile can: the grid's
/// first job is still to say which key you picked, and the progress must not
/// compete with that.
///
/// The track shows even at zero. A key nobody has played says "nothing here
/// yet" rather than saying nothing at all, and it teaches what the bar is for
/// before there is anything in it.
class MasteryBar extends StatelessWidget {
  /// 0–1.
  final double progress;

  /// The key's own colour, or white on the selected tile — where the tile is
  /// already painted that colour and the bar would vanish into it.
  final Color color;

  const MasteryBar({super.key, required this.progress, required this.color});

  static const double height = 3;
  static const double inset = 12;
  static const double bottom = 7;

  /// How much room the bar and its breathing space take at the foot of a tile,
  /// so the letter above can be nudged up by the same amount and stay
  /// optically centred.
  static const double reserved = height + bottom;

  @override
  Widget build(BuildContext context) => Positioned(
        left: inset,
        right: inset,
        bottom: bottom,
        height: height,
        // The cell around it already says the percentage; a second reading
        // of the same number is noise to a screen reader.
        child: ExcludeSemantics(
          child: ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: Stack(children: [
            Positioned.fill(
                child: ColoredBox(color: Colors.white.withValues(alpha: 0.10))),
            FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              heightFactor: 1,
              child: ColoredBox(color: color),
            ),
          ]),
        ),
        ),
      );
}
