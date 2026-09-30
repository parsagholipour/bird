/// Where the gap opens in Baron Bat's sonic screech. The wall of sound fills
/// the sky from edge to edge except for this one opening.
enum ScreechGap {
  /// An opening high in the sky.
  high,

  /// An opening through the middle of the sky.
  middle,

  /// An opening low in the sky.
  low,
}

/// Baron Bat's sonic screech, from rules version 40 on every encounter after
/// his debut: a fixed combat-time cycle, the wall of sound it sends across
/// the sky, and the gap the bird flies through. Heights are screen heights
/// (0 = top); the wall is a vertical band sweeping left.
///
/// Like the tide, the veil and the dragon's breath, fury never changes the
/// cycle, so pause and seek stay exact and every screech gets its full
/// warning. Fury only narrows the gap.
abstract final class BaronScreech {
  /// Combat-time cycle: calm, warning (ears flare, the gap is marked), the
  /// screech leaves his mouth and sweeps left, calm.
  static const period = 10.0, warnAt = 5.0, screechAt = 6.5, endAt = 8.0;

  /// Warning and sweep lengths, for readers that count down.
  static const warnSeconds = screechAt - warnAt,
      sweepSeconds = endAt - screechAt;

  /// The wall's leading edge moves left this fast (screen heights per
  /// second), and the wall reaches [thickness] behind it. At the widest
  /// phone it has crossed the bird's column a second after it leaves.
  static const speed = 1.2, thickness = .08;

  /// Centers of the three places a gap may open, and the gap's height:
  /// [gapHeight] normally and [furyGapHeight] in fury.
  static const highCenter = .27, middleCenter = .5, lowCenter = .73;
  static const gapHeight = .36, furyGapHeight = .30;

  /// Bird heights that count as high or low when a screech is aimed; the
  /// middle lies between them. Each sits halfway between two gap centers.
  static const highBelow = (highCenter + middleCenter) / 2;
  static const lowAbove = (middleCenter + lowCenter) / 2;

  static double center(ScreechGap gap) => switch (gap) {
    ScreechGap.high => highCenter,
    ScreechGap.middle => middleCenter,
    ScreechGap.low => lowCenter,
  };

  /// The open part of the sky as (top, bottom).
  static (double, double) opening(ScreechGap gap, {bool fury = false}) {
    final half = (fury ? furyGapHeight : gapHeight) / 2;
    final c = center(gap);
    return (c - half, c + half);
  }

  /// Where the Baron opens the gap for a bird at [birdY] on screech number
  /// [index] (0 for the first): never around the bird, so every screech asks
  /// it to move, and alternating between the other two places so the
  /// screeches never settle into one pattern. Uses no random draws.
  static ScreechGap aimAt(double birdY, int index) {
    final first = index.isEven;
    if (birdY < highBelow) return first ? ScreechGap.low : ScreechGap.middle;
    if (birdY > lowAbove) return first ? ScreechGap.high : ScreechGap.middle;
    return first ? ScreechGap.high : ScreechGap.low;
  }

  /// Whether a circle at height [y] with [radius] sticks out of the gap.
  static bool blocked(
    ScreechGap gap,
    double y,
    double radius, {
    bool fury = false,
  }) {
    final (top, bottom) = opening(gap, fury: fury);
    return y - radius < top || y + radius > bottom;
  }

  /// 0 before the cycle's warning, rising to 1 as the screech leaves.
  static double warning(double cycle) =>
      cycle < warnAt || cycle >= screechAt ? 0 : (cycle - warnAt) / warnSeconds;

  /// Whether the wall is in the sky at this point of the cycle.
  static bool sweeping(double cycle) => cycle >= screechAt && cycle < endAt;

  /// The wall's leading edge in screen x, for a screech that left [originX]
  /// at [cycle].
  static double front(double originX, double cycle) =>
      originX - speed * (cycle - screechAt);

  /// Whether the wall, leading edge at [front], overlaps a circle at [x]
  /// with [radius] horizontally.
  static bool reaches(double front, double x, double radius) =>
      front <= x + radius && front + thickness >= x - radius;

  /// The Baron holds his fireballs from [quietBefore] ahead of the warning
  /// until the screech has gone, and fires again no sooner than [refire]
  /// after it, so no fireball is near the bird while it moves to the gap.
  static const quietBefore = 1.5, refire = .6;
  static bool quiet(double cycle) =>
      cycle >= warnAt - quietBefore && cycle < endAt;

  /// His small bats come in pairs, released as the screech fades ([pairAt])
  /// and, in fury, once more at [furyPairAt]. Even at the slowest pace (0.36
  /// a second) on the widest phone (2.4 wide) a bat needs 6.0 s to fly past
  /// the bird, so both pairs are gone before the next warning.
  static const pairAt = 7.8, furyPairAt = 8.8;

  /// The heights the two bats of a pair fly at.
  static const pairHeights = (.3, .7);

  /// How many cycles have reached [at] by combat time [t].
  static int count(double t, double at) =>
      t < at ? 0 : ((t - at) / period).floor() + 1;
}
