import 'package:flutter/widgets.dart';

/// How the campaign's screens treat the system text size. They are composed
/// as posters on a fixed canvas (the map's stops, the level card, the result
/// stage, the story's end card), so their text follows the system size up to
/// [max] times and no further; below 1 it stays at its design size. Each
/// piece makes room for the bigger text itself (a plate that grows, a card
/// whose design box is taller and which the screen then scales to fit, a
/// line that shrinks to its box) instead of overflowing.
abstract final class CampaignTextScale {
  /// The most the campaign's text grows.
  static const max = 1.3;

  /// The system text size as these screens apply it, 1 to [max].
  static double of(BuildContext context) =>
      (MediaQuery.textScalerOf(context).scale(16) / 16).clamp(1.0, max);

  /// [child] with the text size clamped to 1 to [max].
  static Widget wrap(Widget child) => MediaQuery.withClampedTextScaling(
    minScaleFactor: 1,
    maxScaleFactor: max,
    child: child,
  );
}
