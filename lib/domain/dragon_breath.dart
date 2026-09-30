/// Which band of sky the Ember Dragon's breath scorches. The dragon aims
/// where the bird is when it starts to inhale, so every breath asks for a
/// dodge; the rest of the sky stays safe.
enum BreathLane {
  /// The upper half burns; the lower half is safe.
  high,

  /// A band through the middle burns; strips above and below are safe.
  middle,

  /// The lower half burns; the upper half is safe.
  low,
}

/// The Ember Dragon's breath: a fixed combat-time cycle and the bands of sky
/// it scorches, in screen heights (0 = top).
///
/// Like the tide and the veil, fury never changes the cycle, so pause and
/// seek stay exact and every breath gets its full warning.
abstract final class DragonBreath {
  /// Combat-time cycle: calm, inhale (the warning), blast, calm.
  static const period = 11.0, warnAt = 4.0, blastAt = 5.5, endAt = 7.1;

  /// Warning and blast lengths, for readers that count down.
  static const warnSeconds = blastAt - warnAt, blastSeconds = endAt - blastAt;

  /// Band edges: the high breath burns down to [split], the low one from it;
  /// the middle breath burns between [middleTop] and [middleBottom].
  static const split = .5, middleTop = .32, middleBottom = .68;

  /// Bird heights that draw the high or low breath; between them the dragon
  /// breathes through the middle.
  static const highBelow = .36, lowAbove = .64;

  /// The burning band of [lane] as (top, bottom).
  static (double, double) band(BreathLane lane) => switch (lane) {
    BreathLane.high => (0, split),
    BreathLane.middle => (middleTop, middleBottom),
    BreathLane.low => (split, 1),
  };

  /// The safe bands left by [lane], top to bottom, as (top, bottom).
  static List<(double, double)> safeBands(BreathLane lane) => switch (lane) {
    BreathLane.high => const [(split, 1)],
    BreathLane.middle => const [(0, middleTop), (middleBottom, 1)],
    BreathLane.low => const [(0, split)],
  };

  /// Where the dragon aims for a bird at [birdY]. On its [debut] it only
  /// ever takes one half of the sky, so the safe band is always the wide
  /// half and never a strip along an edge.
  static BreathLane aimAt(double birdY, {bool debut = false}) => debut
      ? birdY < split
            ? BreathLane.high
            : BreathLane.low
      : birdY < highBelow
      ? BreathLane.high
      : birdY > lowAbove
      ? BreathLane.low
      : BreathLane.middle;

  /// Whether a circle at height [y] with [radius] reaches into [lane]'s band.
  static bool scorches(BreathLane lane, double y, double radius) {
    final (top, bottom) = band(lane);
    return y + radius > top && y - radius < bottom;
  }

  /// 0 before the cycle's warning, rising to 1 as the blast begins.
  static double warning(double cycle) =>
      cycle < warnAt || cycle >= blastAt ? 0 : (cycle - warnAt) / warnSeconds;

  /// Whether the flame burns at this point of the cycle.
  static bool blasting(double cycle) => cycle >= blastAt && cycle < endAt;

  /// From the first sign of the inhale to the last of the flame: the heart
  /// lies open.
  static bool busy(double cycle) => cycle >= warnAt && cycle < endAt;

  /// The dragon stops launching fireballs this long before each inhale, so
  /// the last ones have gone by when the warning asks the bird to move.
  static const quietBefore = 1.0;

  /// Whether the jaws are held for the breath: from [quietBefore] ahead of
  /// the inhale to the end of the flame.
  static bool quiet(double cycle) =>
      cycle >= warnAt - quietBefore && cycle < endAt;

  /// How many cycles have reached [at] by combat time [t].
  static int count(double t, double at) =>
      t < at ? 0 : ((t - at) / period).floor() + 1;
}
