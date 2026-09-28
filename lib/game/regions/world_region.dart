import 'dart:ui';

import '../../domain/obstacle.dart';

/// The places a flight tours, in flight order. Each owns a sky, parallax
/// skyline, weather and obstacle materials, painted procedurally.
///
/// The order alternates warm and cold, day and night, so every hand-off is a
/// strong contrast: desert noon, polar twilight, jungle morning, a Chinese
/// dusk, a New York night and an ocean dawn that leads back to the desert.
enum WorldRegion {
  egypt('Egypt'),
  antarctica('Antarctica'),
  jungle('Jungle'),
  china('China'),
  newYork('New York'),
  sea('Open Sea');

  const WorldRegion(this.title);
  final String title;

  WorldRegion get next => values[(index + 1) % values.length];

  SkyPalette get palette => switch (this) {
    egypt => const SkyPalette(
      Color(0xff78bddc),
      Color(0xfffae6bf),
      Color(0xfff1cf9c),
      Color(0xffd9a86c),
      Color(0xffe8a73c),
    ),
    antarctica => const SkyPalette(
      Color(0xff34507e),
      Color(0xfff2cfd2),
      Color(0xffc3d4ea),
      Color(0xffe4eef7),
      Color(0xff7ee3c4),
    ),
    jungle => const SkyPalette(
      Color(0xff93cfc6),
      Color(0xfff4f1cf),
      Color(0xffcde3c1),
      Color(0xff3f8d62),
      Color(0xfff06f5b),
    ),
    china => const SkyPalette(
      Color(0xffb4a0cc),
      Color(0xffffdcb8),
      Color(0xfff2c6b6),
      Color(0xff6b8a88),
      Color(0xffd8473a),
    ),
    newYork => const SkyPalette(
      Color(0xff222c55),
      Color(0xffbd7a89),
      Color(0xff6c5f92),
      Color(0xff2e3453),
      Color(0xffffc95a),
    ),
    sea => const SkyPalette(
      Color(0xff7db3dd),
      Color(0xffffe1bf),
      Color(0xffffcdb0),
      Color(0xff3b86a9),
      Color(0xfff47d64),
    ),
  };
}

/// Procedural scenery keeps the offline APK small and scales to any viewport.
/// [top] and [horizon] frame the sky gradient, [haze] is the atmosphere that
/// swallows distant layers, [land] the main ground tone and [accent] the
/// region's signature colour.
class SkyPalette {
  const SkyPalette(this.top, this.horizon, this.haze, this.land, this.accent);
  final Color top, horizon, haze, land, accent;

  /// The palette of the world tour at a replay clock second.
  static SkyPalette at(double seconds) => WorldTour.at(seconds).palette;

  static SkyPalette lerp(SkyPalette a, SkyPalette b, double t) {
    if (t <= 0) return a;
    if (t >= 1) return b;
    return SkyPalette(
      Color.lerp(a.top, b.top, t)!,
      Color.lerp(a.horizon, b.horizon, t)!,
      Color.lerp(a.haze, b.haze, t)!,
      Color.lerp(a.land, b.land, t)!,
      Color.lerp(a.accent, b.accent, t)!,
    );
  }
}

/// Where the flight is on the tour. [from] holds until the crossing starts,
/// then hands over to [to]. [t] is the linear progress through the crossing
/// (0 while holding) so every layer can stage its own eased step.
class RegionBlend {
  const RegionBlend(this.from, this.to, this.t, {required this.fromStart});
  final WorldRegion from, to;
  final double t;

  /// Clock second when [from]'s leg began; [to]'s leg begins one leg later.
  final double fromStart;

  bool get crossing => t > 0;

  /// Progress through the crossing at which new obstacles take the next
  /// region's materials. An obstacle spends about six seconds on screen, so
  /// handing over early lets the first new structures arrive while the
  /// horizon changes and the last old ones leave just after the ground does.
  static const handOff = .2;

  /// The region whose obstacles spawn now.
  WorldRegion get dominant => t < handOff ? from : to;

  double startOf(WorldRegion region) =>
      region == from ? fromStart : fromStart + WorldTour.leg;

  /// Eased progress of a step that runs from [a] to [b] of the crossing.
  double stage(double a, double b) => smooth((t - a) / (b - a));

  /// How much of [region] is showing, summing to 1 across the tour.
  double weight(WorldRegion region) {
    final eased = stage(0, 1);
    if (region == from) return 1 - eased;
    return region == to ? eased : 0;
  }

  SkyPalette get palette =>
      SkyPalette.lerp(from.palette, to.palette, stage(.08, .92));

  /// Smoothstep with clamping, the shared easing of every transition.
  static double smooth(double x) {
    if (!(x > 0)) return 0;
    if (x >= 1) return 1;
    return x * x * (3 - 2 * x);
  }
}

/// The world tour's schedule, the single source of truth for which region is
/// showing. Everything reads the replayable simulation clock, so a replay or
/// a seek always lands in the same place.
///
/// Endless flights run from half a minute (a first Classic attempt) to a few
/// minutes (Star Trail with hearts and shields). A 16 second hold and a 6
/// second crossing show the first hand-off at 16 s, three regions by the
/// one-minute mark and the whole tour in 132 s before it loops.
abstract final class WorldTour {
  static const hold = 16.0, crossing = 6.0, leg = hold + crossing;

  /// One leg per [WorldRegion].
  static const loop = leg * 6;

  static RegionBlend at(double seconds) {
    final s = seconds.isFinite && seconds > 0 ? seconds : 0.0;
    final lap = (s / loop).floor();
    final inLap = s - lap * loop;
    final i = (inLap / leg).floor().clamp(0, WorldRegion.values.length - 1);
    final local = inLap - i * leg;
    final from = WorldRegion.values[i];
    return RegionBlend(
      from,
      from.next,
      ((local - hold) / crossing).clamp(0.0, 1.0),
      fromStart: lap * loop + i * leg,
    );
  }

  /// An obstacle keeps the region it spawned in for its whole life, so the
  /// new region's structures stream in from the right edge during a crossing
  /// instead of changing costume on screen.
  static WorldRegion of(Obstacle o) => at(o.bornAt).dominant;
}
