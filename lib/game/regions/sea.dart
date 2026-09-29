import 'dart:math' as math;
import 'dart:ui';

import 'region_scene.dart';
import 'weather.dart';
import 'world_region.dart';

/// The open sea at dawn: the sun lifting off the horizon with its path of
/// light, a tall ship far out, a lighthouse on a rocky islet, a humpback
/// whale that surfaces and dives, and rolling swells with foam and spray
/// under pink-bellied clouds and wheeling gulls.
class SeaScene extends RegionScene {
  const SeaScene();

  @override
  WorldRegion get region => WorldRegion.sea;

  @override
  double get horizon => .6;

  @override
  SkyLight get light => const SkyLight(
    at: _dawnSunAt,
    radius: _dawnSunR,
    disc: Color(0xffffe9c0),
    glow: Color(0xffffc48c),
    halo: .8,
    strength: .62,
  );

  static final _weather = Weather(Weather.of([(Mote.spray, 12)]));
  @override
  Weather get weather => _weather;

  static const _haze = Color(0xffffcdb0);

  @override
  Ground ground(Depth d) => switch (d) {
    // The horizon water mirrors the peach sky; each nearer swell is deeper
    // and greener. The crest lines are painted by `_swellRows` instead of a
    // plain rim, so the rims stay transparent here.
    Depth.far => const Ground(
      Color(0xffc3d0da),
      Color(0xffa9c5d5),
      Color(0xf0ffeed8),
      rimWidth: .0026,
    ),
    Depth.mid => const Ground(
      Color(0xff9bc2d6),
      Color(0xff6ea3c1),
      Color(0x00d6ebf3),
      rimWidth: 0,
    ),
    Depth.low => const Ground(
      Color(0xff5da5c6),
      Color(0xff2f7ba3),
      Color(0x00e4f2f8),
      rimWidth: 0,
    ),
    Depth.near => const Ground(
      Color(0xff3f94b8),
      Color(0xff175a85),
      Color(0x00f4fbff),
      rimWidth: 0,
    ),
  };

  static const _tau = math.pi * 2;

  // Swell crests rise where the wave is +1. Every wavelength of the two
  // distance-scrolled bands divides their 3 h period, so they tile.
  @override
  double ridge(Depth d, double x, double clock) => switch (d) {
    Depth.far => .6,
    Depth.mid =>
      .645 -
          .0032 * _swellWave(x, .7, .8, 0, clock) -
          .0018 * _swellWave(x, .33, .6, 1.9, clock),
    Depth.low =>
      .74 -
          .0095 * _swellGroup(x, .6) * _swellWave(x, .75, .8, .4, clock) -
          .0048 * _swellWave(x, .5, -.6, 1.9, clock) -
          .002 * _swellWave(x, .25, 1.1, .7, clock),
    Depth.near =>
      .875 -
          .019 * _swellGroup(x, 1.9) * _swellWave(x, 1.5, .55, .2, clock) -
          .01 * _swellWave(x, .75, .8, 1.6, clock) -
          .0036 * _swellWave(x, .375, -1.2, .9, clock),
  };

  @override
  double period(Depth d) => 3.0;

  @override
  double sink(Depth d) => switch (d) {
    // The tall ship and the island are ~.19 h and ~.13 h tall, the
    // lighthouse's finial stands ~.35 h above its waterline: each must sink
    // out of sight behind its ridge before it hands over.
    Depth.far => .26,
    Depth.mid => .4,
    Depth.low => .16,
    Depth.near => .14,
  };

  /// A swell profile in about -1..1: sharp crest, broad trough.
  static double _swellWave(
    double x,
    double len,
    double speed,
    double phase,
    double clock,
  ) {
    final t = _tau * x / len - clock * speed + phase;
    return math.cos(t) + .16 * math.cos(2 * t + .9);
  }

  /// Swells arrive in groups: a slow 3 h envelope that tiles with the bands.
  static double _swellGroup(double x, double seed) =>
      1 + .28 * math.sin(_tau * x / 3 + seed * 2.3);

  static double _swellBase(Depth d) => switch (d) {
    Depth.far => .6,
    Depth.mid => .645,
    Depth.low => .74,
    Depth.near => .875,
  };

  /// The rows of water drawn in each band, front to back of the band: the
  /// ridge itself first (its amplitude is the nominal ridge swing and its
  /// wave the dominant one), then sub-rows as (offset below the ridge,
  /// amplitude, wavelength, speed, phase, crest colour, trough colour).
  static List<(double, double, double, double, double, Color, Color)>
  _swellRows(Depth d) => switch (d) {
    Depth.mid => const [
      (0, .005, .7, .8, 0, Color(0xffa3c8da), Color(0xff90bcd2)),
      (.017, .0022, .5, -.5, 1, Color(0xff98c1d6), Color(0xff86b5cd)),
      (.038, .0027, .4, .6, 2.3, Color(0xff8dbad1), Color(0xff7aabc7)),
      (.063, .003, .6, -.4, 3.6, Color(0xff82b2cb), Color(0xff6ea1bf)),
    ],
    Depth.low => const [
      (0, .0165, .75, .8, .4, Color(0xff65adcb), Color(0xff4c96ba)),
      (.05, .0055, .6, .7, 2, Color(0xff5aa3c4), Color(0xff408cb3)),
      (.098, .007, 1, -.55, 4.1, Color(0xff509bbe), Color(0xff3581aa)),
    ],
    Depth.near => const [
      (0, .033, 1.5, .55, .2, Color(0xff469cbb), Color(0xff2e80a7)),
      (.058, .009, .75, .8, 1, Color(0xff3c92b4), Color(0xff23709a)),
      (.107, .01, 1, -.6, 3.3, Color(0xff3188ad), Color(0xff1a5f89)),
    ],
    Depth.far => const [],
  };

  /// Height of row [j] of band [d] at world x (viewport heights).
  double _swellY(Depth d, int j, double x, double clock) {
    if (j == 0) return ridge(d, x, clock);
    final (off, amp, len, speed, phase, _, _) = _swellRows(d)[j];
    return _swellBase(d) +
        off -
        amp * _swellGroup(x, phase) * _swellWave(x, len, speed, phase, clock);
  }

  @override
  void features(Canvas c, Depth d, Size size) {
    final w = size.width, h = size.height;
    switch (d) {
      case Depth.far:
        final (ship, unit) = _shipPlace(w, h);
        _island(c, Offset(w * .98, h * .605), h);
        _shipSloop(c, _shipSloopAt(w, h), h * .011);
        _shipSteamer(c, _shipSteamerAt(w, h), h * .011);
        _tallShip(c, ship, unit);
      case Depth.mid:
        _lighthouse(c, _lighthouseBase(w, h), h);
      case Depth.low || Depth.near:
        break;
    }
  }

  @override
  void live(Canvas c, Depth d, SceneFrame f, int copy) {
    final h = f.h;
    switch (d) {
      case Depth.mid:
        _lighthouseLive(c, f);
      case Depth.low:
        // Marine life behind the swell: humpback and calf, dolphins, flying fish, a diving gannet.
        _whaleLive(c, f, copy);
      case Depth.near:
        // The buoy rides the swell it floats on.
        final (dy, tilt) = _swellBuoyRide(f.clock);
        _buoy(
          c,
          Offset(h * _swellBuoyX, (ridge(d, _swellBuoyX, f.clock) + dy) * h),
          h * .05,
          tilt,
          f.clock,
        );
      case Depth.far:
        _shipLive(c, f);
    }
  }

  @override
  void overlay(Canvas c, Depth d, SceneFrame f, double presence) {
    if (d == Depth.far) _swellHorizon(c, f, presence);
    if (d == Depth.mid) {
      _swellRowsPaint(c, d, f, presence);
      _lighthouseSurf(c, f, presence);
    }
    switch (d) {
      case Depth.low || Depth.near:
        _swellRowsPaint(c, d, f, presence);
      case Depth.far:
        _shipWater(c, f, presence);
      case Depth.mid:
        break;
    }
  }

  @override
  void reflect(Canvas c, SceneFrame f, double presence) {
    // The sun's path: a warm pool of light under the sun and rows of glints
    // that widen, lengthen and thicken toward the viewer.
    final w = f.w, h = f.h, time = f.clock;
    final sx = w * light.at.dx;
    Sketch.mist(
      c,
      Rect.fromCenter(center: Offset(sx, h * .626), width: h * .95, height: h * .11),
      const Color(0xffffdcae),
      .45 * presence,
    );
    Sketch.mist(
      c,
      Rect.fromCenter(center: Offset(sx, h * .7), width: h * 1.1, height: h * .3),
      const Color(0xffffe6c2),
      .16 * presence,
    );
    final strong = Path(), soft = Path(), faint = Path();
    const rows = 17;
    for (var i = 0; i < rows; i++) {
      final k = i / (rows - 1);
      final y = h * (.652 + .225 * math.pow(k, 1.5).toDouble());
      final reach = h * (.05 + .25 * k);
      final n = 4 + (k * 7).round();
      for (var m = 0; m < n; m++) {
        final r1 = Sketch.hash(i * 53 + m * 17 + 5);
        final r2 = Sketch.hash(i * 29 + m * 41 + 9);
        final u = ((m + .5 + (r1 - .5) * .7) / n) * 2 - 1;
        final on = .5 + .5 * math.sin(time * (1.1 + r2 * 1.3) + i * 1.9 + m * 3.3);
        final power = (1 - u.abs()) * (.35 + .65 * on);
        if (power < .12) continue;
        final x = sx + u * reach + math.sin(time * .5 + i * 1.7 + m * 2.3) * h * (.004 + .012 * k);
        final len = h * (.008 + .05 * k) * (.55 + .45 * power);
        final th = h * (.0016 + .0032 * k) * (.6 + .5 * power);
        (power > .62 ? strong : power > .34 ? soft : faint)
          ..moveTo(x - len, y)
          ..quadraticBezierTo(x, y - th * 2, x + len, y)
          ..quadraticBezierTo(x, y + th * 2, x - len, y);
      }
    }
    _swellFill.shader = null;
    for (final (path, alpha) in [(faint, .28), (soft, .5), (strong, .85)]) {
      _swellFill.color = Sketch.fade(const Color(0xfffff3da), alpha * presence);
      c.drawPath(path, _swellFill);
    }
  }

  @override
  void sky(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h;
    final t = _dawnTime(f);
    // Everything that never moves is recorded once per viewport and fade
    // step, then replayed; only the drift, the rays' sway and the birds are
    // painted afresh.
    final level = (presence.clamp(0.0, 1.0) * _dawnLevels).round();
    final sun = Offset(w * _dawnSunAt.dx, h * _dawnSunAt.dy);
    // The rays and the disc wait until the compositor's sun has arrived.
    final late = (math.pow(presence.clamp(0.0, 1.0), 3) * _dawnLevels).round();
    if (level > 0) c.drawPicture(_dawnPicture(f.size, 0, level));
    if (late > 0) {
      c.save();
      c.translate(sun.dx, sun.dy);
      c.rotate(math.sin(f.clock * .13) * .011);
      c.translate(-sun.dx, -sun.dy);
      c.drawPicture(_dawnPicture(f.size, 1, late));
      c.restore();
      c.drawPicture(_dawnPicture(f.size, 2, late));
    }
    // The cloud decks drift at their own pace and fade as one, so a
    // crossing never shows the puffs through each other.
    final fading = presence < .995;
    if (fading) {
      c.saveLayer(
        Rect.fromLTRB(0, 0, w, h * .62),
        Paint()..color = Color.fromRGBO(0, 0, 0, presence.clamp(0.0, 1.0)),
      );
    }
    for (final (kind, speed) in const [(3, .005), (4, .0075)]) {
      c.save();
      c.translate(-(t - 8) * speed * h, 0);
      c.drawPicture(_dawnPicture(f.size, kind, 0));
      c.restore();
    }
    if (fading) c.restore();
    _dawnBirds(c, f, sun, t, presence);
  }

  // ---------------------------------------------------------------------------

  static Color _hazed(Color c, double t) => Sketch.mix(c, _haze, t);

  // -- dawn: the sky ------------------------------------------------------------

  /// The half-lifted sun, as fractions of the viewport, and its radius.
  static const _dawnSunAt = Offset(.66, .592);
  static const _dawnSunR = .072;

  /// Fade steps of the recorded sky pictures during a crossing.
  static const _dawnLevels = 20;

  static const _dawnGold = Color(0xffffd9a0);
  static const _dawnRose = Color(0xffeeb0c4);
  static const _dawnLilac = Color(0xffb7a3d2);
  static const _dawnCoral = Color(0xffffae9c);

  static final _dawnStart = WorldRegion.sea.index * WorldTour.leg;
  static final _dawnPictures = <(Size, int, int), Picture>{};
  static final _dawnInk = Paint();
  static final _dawnLine = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  /// Seconds into the open sea's leg (negative while it is still arriving).
  /// Reduced Motion holds the middle of the hold. Drift and flight are
  /// measured from here, so every lap composes the sky the same way.
  static double _dawnTime(SceneFrame f) {
    if (f.reducedMotion) return 8;
    const loop = WorldTour.loop;
    return (f.clock - _dawnStart + loop / 2) % loop - loop / 2;
  }

  /// The recorded sky layers: 0 air, 1 rays, 2 sun, 3 haze streaks, 4 banks.
  static Picture _dawnPicture(Size size, int kind, int level) {
    final key = (size, kind, level);
    final hit = _dawnPictures.remove(key);
    if (hit != null) return _dawnPictures[key] = hit;
    final recorder = PictureRecorder();
    final c = Canvas(recorder);
    final a = level / _dawnLevels;
    switch (kind) {
      case 0:
        _dawnAir(c, size, a);
      case 1:
        _dawnRays(c, size, a);
      case 2:
        _dawnSun(c, size, a);
      case 3:
        _dawnStreaks(c, size);
      default:
        _dawnBanks(c, size);
    }
    final picture = recorder.endRecording();
    _dawnPictures[key] = picture;
    if (_dawnPictures.length > 160) {
      _dawnPictures.remove(_dawnPictures.keys.first)!.dispose();
    }
    return picture;
  }

  /// The still sky: night clinging overhead with its last stars, lilac and
  /// rose belts down to gold, the sun's bloom, halo and pillar, high cirrus
  /// fanned out from the sun and the mist lying on the horizon.
  static void _dawnAir(Canvas c, Size size, double a) {
    final w = size.width, h = size.height;
    final sun = Offset(w * _dawnSunAt.dx, h * _dawnSunAt.dy);
    final hz = h * .6;
    Color k(Color col, double alpha) => Sketch.fade(col, alpha * a);
    c.drawRect(
      Rect.fromLTRB(0, 0, w, hz),
      Paint()
        ..shader = Gradient.linear(
          Offset.zero,
          Offset(0, hz),
          [
            k(const Color(0xff3f4f98), .42),
            k(const Color(0xff6a78b8), .24),
            k(_dawnLilac, .26),
            k(_dawnRose, .36),
            k(_dawnCoral, .4),
            k(_dawnGold, .5),
          ],
          const [0, .18, .4, .64, .84, 1],
        ),
    );
    // Warm light on the sun's side, a cooler lilac sky away from it.
    Sketch.mist(
      c,
      Rect.fromCenter(center: Offset(sun.dx, hz), width: w * 1.5, height: h),
      const Color(0xffffb878),
      .34 * a,
    );
    Sketch.mist(
      c,
      Rect.fromCenter(
        center: Offset(w * .05, hz - h * .1),
        width: w * .9,
        height: h * .7,
      ),
      const Color(0xffb6a8dc),
      .2 * a,
    );
    // The last stars, thinning out toward the light.
    for (var i = 0; i < 44; i++) {
      final x = w * Sketch.hash(i * 3 + 1500);
      final y = h * .3 * math.pow(Sketch.hash(i * 3 + 1501), 1.7);
      final fade = 1 - y / (h * .3);
      final r = Sketch.hash(i * 3 + 1502);
      _dawnInk.color = k(const Color(0xfff2f4ff), (.2 + .45 * r) * fade);
      c.drawCircle(Offset(x, y), h * (.0013 + .0017 * r), _dawnInk);
    }
    // The morning star, with a whisper of glint.
    final venus = Offset(w * .3, h * .085);
    Sketch.mist(
      c,
      Rect.fromCenter(center: venus, width: h * .06, height: h * .06),
      const Color(0xffffffff),
      .5 * a,
    );
    _dawnInk.color = k(const Color(0xfffdfdff), .85);
    c.drawCircle(venus, h * .0034, _dawnInk);
    _dawnLine
      ..strokeWidth = math.max(.6, h * .0015)
      ..color = k(const Color(0xfffdfdff), .35);
    c.drawLine(venus - Offset(h * .014, 0), venus + Offset(h * .014, 0), _dawnLine);
    c.drawLine(venus - Offset(0, h * .014), venus + Offset(0, h * .014), _dawnLine);
    _dawnCirrus(c, size, a, sun);
    // Bloom, the 22-degree ice halo with its sun dogs, and the pillar.
    Sketch.mist(
      c,
      Rect.fromCenter(center: sun, width: h * 1.1, height: h * 1.0),
      const Color(0xffffdca2),
      .5 * a,
    );
    final ring = h * .37, edge = ring + h * .05;
    c.drawCircle(
      sun,
      edge,
      Paint()
        ..shader = Gradient.radial(
          sun,
          edge,
          [
            k(_dawnRose, 0),
            k(_dawnRose, 0),
            k(const Color(0xffffb59a), .1),
            k(const Color(0xffffffff), .15),
            k(const Color(0xffbcd6ff), .09),
            k(const Color(0xffbcd6ff), 0),
          ],
          [
            0,
            (ring - h * .035) / edge,
            (ring - h * .012) / edge,
            ring / edge,
            (ring + h * .016) / edge,
            1,
          ],
        ),
    );
    for (final side in const [-1.0, 1.0]) {
      final dog = Offset(sun.dx + side * ring, sun.dy - h * .012);
      Sketch.mist(
        c,
        Rect.fromCenter(center: dog, width: h * .08, height: h * .05),
        const Color(0xffffe6c4),
        .3 * a,
      );
    }
    Sketch.mist(
      c,
      Rect.fromCenter(
        center: Offset(sun.dx, sun.dy - h * .17),
        width: h * .09,
        height: h * .52,
      ),
      const Color(0xffffeed2),
      .34 * a,
    );
    // Mist lying on the horizon: the ship and the island stand out of it.
    c.drawRect(
      Rect.fromLTRB(0, hz - h * .12, w, hz + 1),
      Paint()
        ..shader = Gradient.linear(
          Offset(0, hz - h * .12),
          Offset(0, hz),
          [k(const Color(0xffffe6d2), 0), k(const Color(0xffffe6d2), .5)],
        ),
    );
    for (final (fx, fw, fh, fa, warm) in const [
      (.06, .9, .05, .36, .0),
      (.34, 1.1, .04, .32, .2),
      (.58, 1.4, .045, .4, .8),
      (.92, 1.0, .05, .34, .5),
      (.2, .5, .02, .4, .1),
    ]) {
      Sketch.mist(
        c,
        Rect.fromCenter(
          center: Offset(w * fx, hz - h * .008),
          width: h * fw * 2,
          height: h * fh,
        ),
        Sketch.mix(const Color(0xffffe4d8), _dawnGold, warm),
        fa * a,
      );
    }
  }

  /// Mare's-tail cirrus, combed out along lines that run from the sun.
  static void _dawnCirrus(Canvas c, Size size, double a, Offset sun) {
    final w = size.width, h = size.height;
    for (var i = 0; i < 40; i++) {
      final ang = -math.pi * (.06 + .88 * Sketch.hash(i * 7 + 1700));
      // Streaks bunch into bands, leaving clear lanes of sky between.
      if (math.sin(ang * 6.3 + 1.1) + math.sin(ang * 2.7) < -.2) continue;
      final dist = h * (.28 + .5 * Sketch.hash(i * 7 + 1701));
      final dir = Offset(math.cos(ang), math.sin(ang));
      final from = sun + dir * dist;
      final len = h * (.12 + .24 * Sketch.hash(i * 7 + 1702));
      final bend = (Sketch.hash(i * 7 + 1703) - .5) * .3;
      final to = from + Offset(math.cos(ang + bend), math.sin(ang + bend)) * len;
      if (from.dy < h * .02 || from.dx < -h * .1 || from.dx > w + h * .1) continue;
      final th = h * (.0016 + .0032 * Sketch.hash(i * 7 + 1704));
      final perp = Offset(-dir.dy, dir.dx);
      final mid =
          (from + to) / 2 + perp * len * (Sketch.hash(i * 7 + 1705) - .5) * .35;
      final near = (1 - (from - sun).distance / (h * .8)).clamp(0.0, 1.0);
      final tint = Sketch.mix(const Color(0xfffff0f0), _dawnGold, near * .8);
      for (final (grow, alpha) in const [(2.6, .06), (1.0, .15)]) {
        final tk = th * grow;
        _dawnInk.color = Sketch.fade(tint, alpha * a);
        c.drawPath(
          Path()
            ..moveTo(from.dx, from.dy)
            ..quadraticBezierTo(mid.dx + perp.dx * tk, mid.dy + perp.dy * tk, to.dx, to.dy)
            ..quadraticBezierTo(mid.dx - perp.dx * tk * .7, mid.dy - perp.dy * tk * .7, from.dx, from.dy),
          _dawnInk,
        );
      }
    }
  }

  /// Crepuscular rays fanning up from the sun in three strengths.
  static void _dawnRays(Canvas c, Size size, double a) {
    final w = size.width, h = size.height;
    final sun = Offset(w * _dawnSunAt.dx, h * _dawnSunAt.dy);
    final reach = h * 1.25;
    Color k(Color col, double alpha) => Sketch.fade(col, alpha * a);
    const warm = Color(0xfffff0d6);
    for (final (tier, count, alpha, width) in const [
      (0, 7, .11, .085),
      (1, 13, .13, .034),
      (2, 22, .12, .013),
    ]) {
      final fan = Path();
      for (var i = 0; i < count; i++) {
        final u = (i + .15 + .7 * Sketch.hash(tier * 100 + i + 1600)) / count;
        final ang = -math.pi * (.03 + .94 * u);
        final half = width * (.5 + Sketch.hash(tier * 100 + i + 1650)) * .5;
        final p1 = sun + Offset(math.cos(ang - half), math.sin(ang - half)) * reach;
        final p2 = sun + Offset(math.cos(ang + half), math.sin(ang + half)) * reach;
        fan
          ..moveTo(sun.dx, sun.dy)
          ..lineTo(p1.dx, p1.dy)
          ..lineTo(p2.dx, p2.dy)
          ..close();
      }
      c.drawPath(
        fan,
        Paint()
          ..shader = Gradient.radial(
            sun,
            reach,
            [k(warm, alpha), k(warm, alpha * .55), k(warm, 0)],
            const [0, .3, 1],
          ),
      );
    }
  }

  /// The disc itself, flattened by the air, melting into the horizon haze,
  /// with a streak of glare along the sea and a wash of lens ghosts.
  static void _dawnSun(Canvas c, Size size, double a) {
    final w = size.width, h = size.height;
    final sun = Offset(w * _dawnSunAt.dx, h * _dawnSunAt.dy);
    final r = h * _dawnSunR;
    final hz = h * .6;
    Color k(Color col, double alpha) => Sketch.fade(col, alpha * a);
    // Soft shoulder that swallows the ring the compositor paints.
    c.drawCircle(
      sun,
      r * 1.7,
      Paint()
        ..shader = Gradient.radial(
          sun,
          r * 1.7,
          [
            k(const Color(0xfffff0c8), .4),
            k(const Color(0xfffff0c8), .4),
            k(const Color(0xffffdca2), .0),
          ],
          [0, 1 / 1.7, 1],
        ),
    );
    c.drawOval(
      Rect.fromCenter(center: sun, width: r * 2.06, height: r * 1.94),
      Paint()
        ..shader = Gradient.linear(
          Offset(0, sun.dy - r),
          Offset(0, sun.dy + r),
          [
            k(const Color(0xffffefbc), 1),
            k(const Color(0xffffd68e), 1),
            k(const Color(0xffffa85e), 1),
          ],
          const [0, .55, 1],
        ),
    );
    // Haze over the sun's foot and the streak of glare.
    c.drawRect(
      Rect.fromLTRB(0, hz - h * .03, w, hz + 1),
      Paint()
        ..shader = Gradient.linear(
          Offset(0, hz - h * .03),
          Offset(0, hz),
          [k(const Color(0xffffe2bc), 0), k(const Color(0xffffe2bc), .42)],
        ),
    );
    Sketch.mist(
      c,
      Rect.fromCenter(
        center: Offset(sun.dx, hz - h * .006),
        width: w * 1.3,
        height: h * .075,
      ),
      const Color(0xffffedc8),
      .4 * a,
    );
    Sketch.mist(
      c,
      Rect.fromCenter(
        center: Offset(sun.dx, hz - h * .004),
        width: w * .55,
        height: h * .022,
      ),
      const Color(0xfffffaea),
      .8 * a,
    );
    // Faint lens ghosts strung along the line through the frame's centre.
    final axis = Offset(w * .5, h * .5) - sun;
    for (final (at, rad, tone, alpha) in const [
      (.62, .03, 0xffbfe6ff, .05),
      (1.02, .052, 0xffffc4dc, .04),
      (1.55, .026, 0xffffe0a8, .05),
    ]) {
      final o = sun + axis * at;
      final rr = h * rad;
      c.drawCircle(
        o,
        rr,
        Paint()
          ..shader = Gradient.radial(
            o,
            rr,
            [k(Color(tone), 0), k(Color(tone), alpha * .5), k(Color(tone), alpha * 1.6), k(Color(tone), 0)],
            const [0, .55, .88, 1],
          ),
      );
    }
  }

  // -- dawn: the clouds ----------------------------------------------------------

  /// Thin stratus streaks lying near the horizon, gold toward the sun and
  /// rose-lilac away from it. They drift slower than the banks above.
  static void _dawnStreaks(Canvas c, Size size) {
    final w = size.width, h = size.height;
    for (final (fx, fy, len, thick, warm) in const [
      (.1, .53, .24, .0095, .15),
      (.38, .462, .3, .011, .3),
      (.55, .553, .36, .008, .6),
      (.8, .49, .42, .013, .85),
      (1.08, .55, .3, .009, .7),
      (.66, .576, .34, .0055, 1.0),
      (.26, .565, .2, .006, .3),
      (.96, .43, .28, .01, .8),
      (.5, .402, .28, .008, .4),
      (.02, .44, .22, .008, .1),
      (.74, .535, .2, .006, .9),
    ]) {
      _dawnStreak(c, Offset(w * fx, h * fy), h * len, h * thick, (fx * 97).round(), warm);
    }
  }

  static void _dawnStreak(
    Canvas c,
    Offset o,
    double len,
    double thick,
    int seed,
    double warm,
  ) {
    const n = 8;
    final left = Offset(o.dx - len / 2, o.dy);
    final right = Offset(o.dx + len / 2, o.dy);
    Path lens(double lift, double squash) {
      final top = <Offset>[
        for (var i = 1; i < n; i++)
          Offset(
            o.dx + (i / n - .5) * len,
            o.dy -
                lift -
                thick *
                    squash *
                    math.sin(math.pi * i / n) *
                    (.45 + .55 * Sketch.hash(seed * 13 + i)),
          ),
      ];
      final path = Path()..moveTo(left.dx, left.dy - lift * .4);
      for (var i = 0; i < top.length - 1; i++) {
        final mid = (top[i] + top[i + 1]) / 2;
        path.quadraticBezierTo(top[i].dx, top[i].dy, mid.dx, mid.dy);
      }
      path
        ..quadraticBezierTo(top.last.dx, top.last.dy, right.dx, right.dy - lift * .4)
        ..quadraticBezierTo(o.dx, o.dy + thick * .55, left.dx, left.dy - lift * .4);
      return path..close();
    }

    final under = Sketch.mix(const Color(0xffe6a9c4), const Color(0xffffa98e), warm);
    final body = Sketch.mix(const Color(0xfff8d4e0), const Color(0xffffdcb4), warm);
    final lit = Sketch.mix(const Color(0xfffff0f6), const Color(0xfffff2cf), warm);
    _dawnInk.color = Sketch.fade(under, .82);
    c.drawPath(lens(0, 1), _dawnInk);
    _dawnInk.color = Sketch.fade(body, .9);
    c.drawPath(lens(thick * .14, .85), _dawnInk);
    _dawnInk.color = Sketch.fade(lit, .85);
    c.drawPath(lens(thick * .32, .5), _dawnInk);
  }

  /// The stratocumulus banks: pink-bellied, lit from below by the low sun,
  /// and one grey one that trails a shaft of rain toward the sea.
  static void _dawnBanks(Canvas c, Size size) {
    final w = size.width, h = size.height;
    // Rain first, so its cloud sits over the top of it.
    _dawnRain(c, Offset(w * .335, h * .335), h * .3, h * .6, h * .05);
    for (final (fx, fy, width, tall, seed, gloom) in const [
      (.17, .225, .66, .105, 1, .0),
      (.56, .118, .4, .058, 2, .0),
      (.87, .318, .6, .09, 3, .0),
      (.335, .338, .5, .07, 4, .55),
      (.99, .112, .32, .05, 5, .0),
      (.7, .2, .22, .04, 6, .0),
    ]) {
      final at = Offset(w * fx, h * fy);
      final toward = (w * _dawnSunAt.dx - at.dx).sign;
      _cloud(c, at, h * width, h * tall, seed, toward, gloom);
    }
  }

  /// One stratocumulus bank on a flat base at [base] (bottom centre): a few
  /// big domes with crowns and shoulders, shaded as whole masses (a coral
  /// underside lit by the low sun, a warm body, a pale crown), with lobe
  /// creases and a gold rim on the sun's side, and a wavy pink belly.
  static void _cloud(
    Canvas c,
    Offset base,
    double width,
    double tall,
    int seed,
    double toward,
    double gloom,
  ) {
    final puffs = <(double, double, double)>[];
    final crowns = <(double, double, double)>[];
    final bars = <Rect>[];
    final n = 6 + (width / tall * .7).round();
    final gap = width / n;
    for (var i = 0; i < n; i++) {
      final u = (i + .5 + (Sketch.hash(seed * 31 + i) - .5) * .6) / n;
      final env = math.pow(math.sin(math.pi * u), 1.1).toDouble();
      final r = tall * (.16 + .34 * env) * (.75 + .5 * Sketch.hash(seed * 31 + i + 500));
      final x = base.dx + (u - .5) * width;
      puffs.add((x, base.dy - r * .55, r));
      // A low bar under each dome fills the gaps into one continuous mass.
      bars.add(Rect.fromCenter(center: Offset(x, base.dy - tall * (.13 + .12 * env)), width: gap * 2.6, height: tall * (.3 + .25 * env)));
      if (r > tall * .24) {
        final dx = (Sketch.hash(seed * 31 + i + 900) - .5) * r * 1.5;
        final cr = r * (.5 + .25 * Sketch.hash(seed * 31 + i + 950));
        crowns.add((x + dx, base.dy - r * 1.05 - cr * .1, cr));
      }
    }
    puffs.addAll(crowns);
    Color dusk(Color clear, Color grey) => Sketch.mix(clear, grey, gloom);
    final coral = dusk(_dawnCoral, const Color(0xff9a8fac));
    final lilac = dusk(const Color(0xffc9a5c6), const Color(0xff736b91));
    final bodyLow = dusk(const Color(0xffffcbbb), const Color(0xffb3a9c2));
    final bodyHigh = dusk(const Color(0xfffff0ee), const Color(0xffccc4d6));
    final top = dusk(const Color(0xfffffaf6), const Color(0xffe3dde8));
    final rim = dusk(const Color(0xffffe2a4), const Color(0xffe6c9b0));
    var reach = 0.0, left = base.dx, right = base.dx;
    for (final (x, y, r) in puffs) {
      reach = math.max(reach, base.dy - y + r);
      left = math.min(left, x - r);
      right = math.max(right, x + r);
    }
    Path mass(double lift, double scale, double lean) {
      final path = Path();
      for (final (x, y, r) in puffs) {
        path.addOval(Rect.fromCircle(center: Offset(x + toward * r * lean, y - r * lift), radius: r * scale));
      }
      for (final b in bars) {
        path.addOval(Rect.fromCenter(center: b.center + Offset(toward * b.height * lean * .5, -b.height * lift * .5), width: b.width * scale, height: b.height * scale));
      }
      return path;
    }

    Paint ramp(Color a, Color b) => Paint()
      ..shader = Gradient.linear(Offset(0, base.dy - reach), Offset(0, base.dy), [a, b]);
    c.save();
    c.clipRect(Rect.fromLTRB(left - tall, base.dy - reach - tall, right + tall, base.dy - tall * .02));
    c.drawPath(mass(0, 1, 0), ramp(lilac, coral));
    c.drawPath(mass(.24, .88, .05), ramp(bodyHigh, bodyLow));
    c.drawPath(mass(.32, .74, .09), Paint()..color = Sketch.fade(Sketch.mix(bodyHigh, top, .4), .95));
    c.drawPath(mass(.5, .5, .13), Paint()..color = Sketch.fade(top, .9));
    // Creases where lobes meet, on the lobes' shaded flanks.
    _dawnLine
      ..strokeWidth = math.max(.7, tall * .022)
      ..color = Sketch.fade(lilac, .34);
    for (final (x, y, r) in puffs) {
      if (r < tall * .2) continue;
      final start = toward > 0 ? math.pi * .55 : -math.pi * .05;
      c.drawArc(Rect.fromCircle(center: Offset(x, y - r * .08), radius: r * .84), start, math.pi * .5, false, _dawnLine);
    }
    // The sun's flank and the crowns catch a gold rim.
    _dawnLine
      ..strokeWidth = math.max(.8, tall * .028)
      ..color = Sketch.fade(rim, .9);
    for (final (x, y, r) in crowns) {
      final start = toward > 0 ? -math.pi * .5 : -math.pi * .9;
      c.drawArc(Rect.fromCircle(center: Offset(x, y), radius: r * .96), start, math.pi * .45, false, _dawnLine);
    }
    c.restore();
    // The pink belly under the flat cut, pinched at both ends, with wisps.
    final belly = Path()
      ..moveTo(left + tall * .1, base.dy - tall * .05)
      ..lineTo(right - tall * .1, base.dy - tall * .05);
    const seg = 6;
    final span = right - left - tall * .2;
    for (var i = 0; i < seg; i++) {
      final ex = right - tall * .1 - span * (i + 1) / seg;
      final cx = right - tall * .1 - span * (i + .5) / seg;
      final env = math.sin(math.pi * (i + .5) / seg);
      final dip = tall * (.05 + .06 * Sketch.hash(seed * 7 + i + 300)) * env;
      belly.quadraticBezierTo(cx, base.dy + dip * 1.8, ex, base.dy - tall * .05 + dip * .4 * (i == seg - 1 ? 0 : 1));
    }
    belly.close();
    _dawnInk.color = Sketch.fade(coral, .95);
    c.drawPath(belly, _dawnInk);
    _dawnInk.color = Sketch.fade(dusk(const Color(0xffffcdb0), const Color(0xffb0a2b4)), .75);
    c.drawOval(
      Rect.fromCenter(
        center: Offset((left + right) / 2 + toward * width * .06, base.dy - tall * .015),
        width: (right - left) * .6,
        height: tall * .1,
      ),
      _dawnInk,
    );
    for (var i = 0; i < 5; i++) {
      final wx = left + (right - left) * (.15 + .7 * Sketch.hash(seed * 5 + i + 700));
      _dawnInk.color = Sketch.fade(coral, .4);
      c.drawOval(
        Rect.fromCenter(
          center: Offset(wx, base.dy + tall * (.06 + .06 * Sketch.hash(seed * 5 + i + 800))),
          width: tall * (.3 + .5 * Sketch.hash(seed * 5 + i + 600)),
          height: tall * .05,
        ),
        _dawnInk,
      );
    }
  }

  /// A distant shaft of rain hanging from a grey cloud to the sea: a curtain
  /// of slanting strips that end at different heights, a few streaks and a
  /// pale mist where it lands.
  static void _dawnRain(Canvas c, Offset from, double topW, double seaY, double lean) {
    final drop = seaY - from.dy;
    const strips = 11;
    for (var i = 0; i < strips; i++) {
      final u = (i + .5) / strips - .5 + (Sketch.hash(i + 1830) - .5) * .06;
      final sw = topW * (.06 + .1 * Sketch.hash(i + 1840));
      final len = drop * (.5 + .5 * Sketch.hash(i + 1850));
      final x0 = from.dx + u * topW * .8;
      final bend = lean * (.7 + .5 * Sketch.hash(i + 1860));
      final xb = x0 + u * topW * .55 + bend;
      final y1 = from.dy + len;
      final tone = .55 + .45 * Sketch.hash(i + 1870);
      c.drawPath(
        Path()
          ..moveTo(x0 - sw / 2, from.dy)
          ..lineTo(x0 + sw / 2, from.dy)
          ..quadraticBezierTo(x0 + sw / 2 + bend * .1, from.dy + len * .5, xb + sw * .8, y1)
          ..lineTo(xb - sw * .8, y1)
          ..quadraticBezierTo(x0 - sw / 2 + bend * .1, from.dy + len * .5, x0 - sw / 2, from.dy)
          ..close(),
        Paint()
          ..shader = Gradient.linear(
            Offset(0, from.dy),
            Offset(0, y1),
            [
              Sketch.fade(const Color(0xff7b84ad), .34 * tone),
              Sketch.fade(const Color(0xff97a6cb), .17 * tone),
              Sketch.fade(const Color(0xffb0bedb), 0),
            ],
            const [0, .6, 1],
          ),
      );
    }
    _dawnLine
      ..strokeWidth = math.max(.7, drop * .005)
      ..color = const Color(0x2ee6eefc);
    for (var i = 0; i < 12; i++) {
      final u = Sketch.hash(i + 1800) - .5;
      final y0 = from.dy + drop * (.08 + .5 * Sketch.hash(i + 1810));
      final len = drop * (.12 + .2 * Sketch.hash(i + 1820));
      final k = (y0 - from.dy) / drop;
      final x0 = from.dx + u * topW * (.8 + .6 * k) + lean * k;
      c.drawLine(Offset(x0, y0), Offset(x0 + lean * len / drop, y0 + len), _dawnLine);
    }
    Sketch.mist(
      c,
      Rect.fromCenter(
        center: Offset(from.dx + lean, seaY - drop * .015),
        width: topW * 1.5,
        height: drop * .14,
      ),
      const Color(0xffe4e6f4),
      .5,
    );
  }

  // -- dawn: the birds -----------------------------------------------------------

  /// A tern flock, two gulls, a soaring albatross and a handful of specks,
  /// all flown from the leg's clock so a lap replays the same sky.
  static void _dawnBirds(Canvas c, SceneFrame f, Offset sun, double t, double presence) {
    final w = f.w, h = f.h;
    final dt = t - 8;
    Color tone(Offset p, Color far) {
      // Against the glare a bird is a warm silhouette, up high it is pale.
      final near = (1 - (p - sun).distance / (h * .55)).clamp(0.0, 1.0);
      return Sketch.fade(Sketch.mix(far, const Color(0xffd9a9a8), near * .8), presence);
    }

    // Flock of terns in a loose V, heading with the bird.
    final lead = Offset(w * .2 + dt * h * .024, h * .072 - dt * h * .0008);
    for (var i = 0; i < 7; i++) {
      final rank = (i + 1) ~/ 2;
      final side = i.isOdd ? 1.0 : -1.0;
      final bob = math.sin(f.clock * .9 + i * 1.7) * h * .003;
      final p = lead + Offset(-rank * h * .026, side * rank * h * .013 + bob);
      final flap = math.sin(f.clock * 4.6 + i * 1.9) * (.65 + .35 * math.sin(f.clock * .5 + i));
      _dawnBird(c, p, h * (.013 - rank * .0007), flap, tone(p, const Color(0xfffff8f4)), null);
    }
    // Two gulls wheeling over the sun's glare.
    for (var i = 0; i < 2; i++) {
      final a = f.clock * (.28 + i * .06) + i * 2.4;
      final home = Offset(w * (.52 + i * .13), h * (.43 + i * .05));
      final p = home + Offset(math.cos(a) * h * .07, math.sin(a) * h * .018);
      final flap = math.sin(f.clock * 3.2 + i * 2.2) * .8;
      final ink = tone(p, const Color(0xfffff4ee));
      _dawnBird(c, p, h * (.024 - i * .004), flap, ink, Sketch.fade(const Color(0xff6c6478), presence * .8));
    }
    // The albatross soars on long stiff wings, hardly flapping.
    final soar = Offset(w * .5 - dt * h * .012, h * .175 + math.sin(f.clock * .35) * h * .008);
    _dawnBird(
      c,
      soar,
      h * .042,
      math.sin(f.clock * .5) * .12 - .05,
      tone(soar, const Color(0xfffffaf6)),
      Sketch.fade(const Color(0xff6a6478), presence * .8),
      slim: 1,
    );
    // Specks near the horizon: far terns, only chevrons.
    _dawnLine
      ..strokeWidth = math.max(.6, h * .0016)
      ..color = Sketch.fade(const Color(0xfffff6f0), .55 * presence);
    final specks = Path();
    for (var i = 0; i < 9; i++) {
      final p = Offset(
        w * (.08 + .3 * Sketch.hash(i + 1900)) + dt * h * .01,
        h * (.475 + .07 * Sketch.hash(i + 1910)) + math.sin(f.clock * .7 + i) * h * .002,
      );
      final s = h * (.004 + .003 * Sketch.hash(i + 1920));
      final flap = math.sin(f.clock * 3 + i * 2.1) * s * .45;
      specks
        ..moveTo(p.dx - s, p.dy - s * .35 + flap)
        ..quadraticBezierTo(p.dx - s * .4, p.dy - s * .6 + flap * .5, p.dx, p.dy)
        ..quadraticBezierTo(p.dx + s * .4, p.dy - s * .6 + flap * .5, p.dx + s, p.dy - s * .35 + flap);
    }
    c.drawPath(specks, _dawnLine);
  }

  /// A bird seen from behind and below with wings spread: shoulder, elbow
  /// and a hand that sweeps back down, [flap] in -1..1; [slim] lengthens the
  /// wing for the albatross and [tips] darkens the primaries.
  static void _dawnBird(Canvas c, Offset p, double s, double flap, Color ink, Color? tips, {double slim = 0}) {
    final arm = .2 + flap * .5;
    final hand = arm - .55 + slim * .3;
    final elbow = Offset(math.cos(arm), -math.sin(arm)) * s * (.46 + slim * .1);
    final tip = elbow + Offset(math.cos(hand), -math.sin(hand)) * s * (.56 + slim * .14);
    final chord = s * (.17 - slim * .06);
    final wings = Path();
    final tipPath = Path();
    for (final side in const [-1.0, 1.0]) {
      double x(double v) => p.dx + side * v;
      wings
        ..moveTo(p.dx, p.dy - chord * .2)
        ..quadraticBezierTo(x(elbow.dx), p.dy + elbow.dy - chord * .35, x(tip.dx), p.dy + tip.dy)
        ..quadraticBezierTo(x(elbow.dx * .92), p.dy + elbow.dy + chord * .62, p.dx, p.dy + chord * .5)
        ..close();
      if (tips != null) {
        final root = Offset.lerp(elbow, tip, .55)!;
        tipPath
          ..moveTo(x(root.dx), p.dy + root.dy - chord * .1)
          ..lineTo(x(tip.dx), p.dy + tip.dy)
          ..lineTo(x(root.dx * 1.02), p.dy + root.dy + chord * .32)
          ..close();
      }
    }
    _dawnInk.color = ink;
    c.drawPath(wings, _dawnInk);
    c.drawOval(
      Rect.fromCenter(center: Offset(p.dx, p.dy + chord * .1), width: s * .2, height: s * .34),
      _dawnInk,
    );
    if (tips != null) {
      _dawnInk.color = tips;
      c.drawPath(tipPath, _dawnInk);
    }
  }

  // ---- ship: the tall ship, her two consorts and the island beyond ----------

  /// The tall ship's waterline mark and her size unit (a sixth of her hull).
  static (Offset, double) _shipPlace(double w, double h) =>
      (Offset(w * .205, h * .603), h * .038);

  static Offset _shipSteamerAt(double w, double h) =>
      Offset(w * .585, h * .603);

  static Offset _shipSloopAt(double w, double h) => Offset(w * .072, h * .602);

  static const _shipSpar = Color(0xff4b4458),
      _shipHullDark = Color(0xff2e3852),
      _shipGold = Color(0xffe9bd6c),
      _shipSailLit = Color(0xfffff1de),
      _shipSailWarm = Color(0xffffdfb8),
      _shipSailShade = Color(0xff9d97b8);

  /// The three masts, aft to fore: (x, rake, top, sails), each sail being
  /// (yard height, foot height, half width) in ship units, y up is negative.
  static const _shipMasts =
      <(double, double, double, List<(double, double, double)>)>[
        (
          -1.85,
          .06,
          -4.42,
          [(-2.2, -3.1, .5), (-3.16, -3.78, .4), (-3.83, -4.26, .29)],
        ),
        (
          -.2,
          .035,
          -4.97,
          [
            (-.85, -2.05, .86),
            (-2.13, -3.28, .74),
            (-3.34, -4.1, .56),
            (-4.15, -4.7, .4),
          ],
        ),
        (
          1.35,
          .02,
          -4.52,
          [
            (-.85, -1.9, .78),
            (-1.98, -2.98, .68),
            (-3.04, -3.75, .52),
            (-3.8, -4.3, .38),
          ],
        ),
      ];

  /// Top of the hull's side at [x] (ship units): a sweeping sheer, high at
  /// the stern castle and again at the bow.
  static double _shipSheer(double x) {
    final aft = math.max(0.0, (-x - 1) / 2), fore = math.max(0.0, (x - 1.2) / 1.85);
    return -.58 - .42 * aft * aft - .26 * fore * fore;
  }

  static void _tallShip(Canvas c, Offset at, double s) {
    Color hz(Color k, [double t = .3]) => _hazed(k, t);
    final spar = hz(_shipSpar), lit = hz(_shipSailLit, .2);
    final warm = hz(_shipSailWarm, .2), shade = hz(_shipSailShade, .28);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = spar;
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(s);

    // Bowsprit and jib-boom, the guy under them, then the stays.
    c.drawLine(const Offset(2.6, -.7), const Offset(5.25, -1.87), line..strokeWidth = .1);
    c.drawLine(const Offset(4.6, -1.6), const Offset(5.25, -1.87), line..strokeWidth = .065);

    // Mizzen spanker, behind the square sails.
    final gaff = Path()
      ..moveTo(-1.99, -2.45)
      ..lineTo(-3.05, -3.02)
      ..quadraticBezierTo(-3.3, -2.1, -3.38, -1.3)
      ..lineTo(-1.99, -1.36)
      ..close();
    c.drawPath(
      gaff,
      Paint()
        ..shader = Gradient.linear(const Offset(-3.3, -2.6), const Offset(-2, -1.4), [
          shade,
          Sketch.mix(shade, lit, .55),
          lit,
        ], const [0, .5, 1]),
    );
    c.drawLine(const Offset(-1.99, -1.36), const Offset(-3.4, -1.3), line..strokeWidth = .06);
    c.drawLine(const Offset(-1.99, -2.45), const Offset(-3.08, -3.05), line..strokeWidth = .05);

    // Stays run fore-and-aft behind the sails: between the masts, back to the
    // taffrail, and the guy under the bowsprit.
    c.drawPath(
      Path()
        ..moveTo(-2.14, -4.42)
        ..lineTo(-.33, -2.3)
        ..moveTo(-.37, -4.97)
        ..lineTo(1.28, -2.5)
        ..moveTo(-2.14, -4.42)
        ..lineTo(-3.02, -1.02)
        ..moveTo(-.37, -4.97)
        ..lineTo(-2.7, -1.0)
        ..moveTo(5.25, -1.87)
        ..lineTo(3.02, -.38),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .026
        ..color = Sketch.fade(spar, .55),
    );

    // Masts, sails and yards, aft to fore so the forward ones overlap.
    final yards = Path();
    final rigging = Path();
    for (final (mx, rake, top, sails) in _shipMasts) {
      double xAt(double y) => mx + rake * y;
      final deck = _shipSheer(mx);
      final nest = (sails.length > 3 ? sails[1].$1 : sails[0].$1) + .1;
      line
        ..strokeWidth = .09
        ..color = spar;
      c.drawLine(Offset(xAt(deck), deck), Offset(xAt(nest), nest), line);
      c.drawLine(Offset(xAt(nest), nest), Offset(xAt(sails.last.$1), sails.last.$1), line..strokeWidth = .065);
      c.drawLine(Offset(xAt(sails.last.$1), sails.last.$1), Offset(xAt(top), top), line..strokeWidth = .045);
      for (final (head, foot, half) in sails) {
        final x = xAt((head + foot) / 2);
        _shipSail(c, x, head, foot, half, lit, warm, shade);
        yards
          ..moveTo(xAt(head) - half * 1.14, head)
          ..lineTo(xAt(head) + half * 1.14, head);
      }
      // Shrouds to the rail with ratlines between, and the top platform.
      for (final side in const [-1.0, 1.0]) {
        for (final spread in const [.36, .64]) {
          rigging
            ..moveTo(xAt(nest) + side * .09, nest)
            ..lineTo(mx + side * spread, deck);
        }
        for (var k = 1; k <= 5; k++) {
          final t = k / 6, y = nest + (deck - nest) * t;
          rigging
            ..moveTo(xAt(nest) + side * (.09 + .27 * t), y)
            ..lineTo(xAt(nest) + side * (.09 + .55 * t), y);
        }
      }
      c.drawPath(
        Sketch.poly([-.24, 0, .24, 0, .18, .09, -.18, .09], at: Offset(xAt(nest), nest - .02)),
        Paint()..color = spar,
      );
      c.drawLine(
        Offset(xAt(nest) - .24, nest - .11),
        Offset(xAt(nest) + .24, nest - .11),
        line..strokeWidth = .025,
      );
    }
    c.drawPath(
      yards,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .06
        ..strokeCap = StrokeCap.round
        ..color = spar,
    );
    c.drawPath(
      rigging,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .026
        ..color = Sketch.fade(spar, .55),
    );

    // Headsails hang from stays that fan out to the bowsprit.
    for (final (ax, ay, bx, by, t, clewX, clewY) in const [
      (1.42, -4.15, 5.25, -1.87, .32, 3.75, -1.95),
      (1.42, -3.5, 4.2, -1.43, .3, 3.05, -1.52),
      (1.42, -2.72, 3.4, -1.06, .3, 2.55, -1.14),
    ]) {
      final head = Offset(ax + (bx - ax) * t, ay + (by - ay) * t);
      _shipJib(c, head, Offset(bx, by), Offset(clewX, clewY), lit, warm, shade);
      c.drawLine(Offset(ax, ay), Offset(bx, by), line..strokeWidth = .026..color = Sketch.fade(spar, .6));
    }

    // The longboat on the booms amidships.
    c.drawPath(
      Path()
        ..moveTo(.3, -.6)
        ..quadraticBezierTo(.4, -.78, .65, -.79)
        ..quadraticBezierTo(.9, -.78, 1.0, -.6)
        ..close(),
      Paint()..color = hz(const Color(0xff5d4f52), .3),
    );

    _shipHull(c, hz);

    c.restore();
    // Haze lying on the water swallows the waterline.
    Sketch.mist(
      c,
      Rect.fromCenter(center: at + Offset(0, s * .05), width: s * 12, height: s * 1.1),
      _haze,
      .5,
    );
  }

  /// One billowed square sail with its yard-shadow, fold and seams.
  static void _shipSail(
    Canvas c,
    double x,
    double head,
    double foot,
    double half,
    Color lit,
    Color warm,
    Color shade,
  ) {
    final mid = (head + foot) / 2, tall = foot - head;
    final sail = Path()
      ..moveTo(x - half, head)
      ..lineTo(x + half, head)
      ..quadraticBezierTo(x + half * 1.26, mid, x + half * .97, foot)
      ..quadraticBezierTo(x, foot - tall * .13, x - half * .97, foot)
      ..quadraticBezierTo(x - half * .86, mid, x - half, head)
      ..close();
    c.drawPath(
      sail,
      Paint()
        ..shader = Gradient.linear(
          Offset(x - half, head),
          Offset(x + half * 1.1, foot),
          [shade, lit, warm],
          const [0, .52, 1],
        ),
    );
    c.save();
    c.clipPath(sail);
    c.drawRect(
      Rect.fromLTRB(x - half * 1.3, head, x + half * 1.4, head + tall * .36),
      Paint()
        ..shader = Gradient.linear(Offset(0, head), Offset(0, head + tall * .36), [
          Sketch.fade(shade, .6),
          Sketch.fade(shade, 0),
        ]),
    );
    // The billow turns from the light along a soft fold.
    c.drawPath(
      Path()
        ..moveTo(x - half * .1, head)
        ..quadraticBezierTo(x - half * .3, mid, x - half * .12, foot)
        ..lineTo(x - half * .55, foot)
        ..quadraticBezierTo(x - half * .66, mid, x - half * .46, head)
        ..close(),
      Paint()..color = Sketch.fade(shade, .3),
    );
    final seams = Path();
    for (var k = -2; k <= 2; k++) {
      seams
        ..moveTo(x + k * half * .4, head)
        ..lineTo(x + k * half * .43, foot);
    }
    c.drawPath(
      seams,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .018
        ..color = Sketch.fade(shade, .5),
    );
    c.restore();
    // Sunrise catches the leading edge.
    c.drawPath(
      Path()
        ..moveTo(x + half, head)
        ..quadraticBezierTo(x + half * 1.26, mid, x + half * .97, foot),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .05
        ..strokeCap = StrokeCap.round
        ..color = Sketch.fade(const Color(0xffffe9c8), .7),
    );
  }

  /// A triangular headsail: head on the stay, tack on the bowsprit.
  static void _shipJib(Canvas c, Offset head, Offset tack, Offset clew, Color lit, Color warm, Color shade) {
    final mid = Offset.lerp(head, tack, .5)!;
    c.drawPath(
      Path()
        ..moveTo(head.dx, head.dy)
        ..quadraticBezierTo(mid.dx, mid.dy + .1, tack.dx, tack.dy)
        ..quadraticBezierTo((tack.dx + clew.dx) / 2, tack.dy + .12, clew.dx, clew.dy)
        ..quadraticBezierTo(clew.dx - .12, (head.dy + clew.dy) / 2, head.dx, head.dy)
        ..close(),
      Paint()
        ..shader = Gradient.linear(clew, Offset.lerp(head, tack, .6)!, [
          Sketch.mix(shade, lit, .35),
          lit,
          warm,
        ], const [0, .5, 1]),
    );
  }

  static void _shipHull(Canvas c, Color Function(Color, [double]) hz) {
    final hull = hz(_shipHullDark), hullLit = hz(const Color(0xff56607d));
    final gold = hz(_shipGold, .24), port = hz(const Color(0xff1f2538));
    final body = Path()..moveTo(-3.0, _shipSheer(-3.0));
    for (var x = -2.8; x <= 3.0; x += .2) {
      body.lineTo(x, _shipSheer(x));
    }
    body
      ..lineTo(3.05, _shipSheer(3.05))
      ..quadraticBezierTo(3.12, -.35, 2.62, .15)
      ..lineTo(-2.5, .15)
      ..quadraticBezierTo(-3.1, -.15, -3.0, _shipSheer(-3.0))
      ..close();
    c.drawPath(
      body,
      Paint()
        ..shader = Gradient.linear(const Offset(-3, 0), const Offset(3, 0), [
          Sketch.mix(hull, port, .3),
          hull,
          hullLit,
        ], const [0, .55, 1]),
    );
    // The gilded wale with a row of gun ports along it.
    c.save();
    c.clipPath(body);
    final wale = Path()..moveTo(-2.95, _shipSheer(-2.95) + .2);
    for (var x = -2.75; x <= 2.95; x += .2) {
      wale.lineTo(x, _shipSheer(x) + .2);
    }
    for (var x = 2.95; x >= -2.95; x -= .2) {
      wale.lineTo(x, _shipSheer(x) + .34);
    }
    c.drawPath(wale..close(), Paint()..color = gold);
    final ports = Paint()..color = port;
    for (var x = -1.75; x < 2.6; x += .36) {
      c.drawRect(Rect.fromLTWH(x, _shipSheer(x) + .225, .15, .095), ports);
    }
    c.restore();
    // Raised stern castle with its gallery windows.
    c.drawRect(
      Rect.fromLTRB(-2.95, -1.3, -2.02, _shipSheer(-2.5)),
      Paint()..color = Sketch.mix(hull, port, .2),
    );
    c.drawRect(Rect.fromLTRB(-2.97, -1.34, -2.0, -1.28), Paint()..color = gold);
    for (final x in const [-2.8, -2.55, -2.3]) {
      c.drawRect(Rect.fromLTWH(x, -1.17, .13, .1), Paint()..color = gold);
    }
    // Rail cap catches the light, the stem takes a warm rim.
    final rail = Path()..moveTo(-3.0, _shipSheer(-3.0));
    for (var x = -2.8; x <= 3.0; x += .2) {
      rail.lineTo(x, _shipSheer(x));
    }
    c.drawPath(
      rail,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .05
        ..color = Sketch.fade(const Color(0xffffe9c8), .5),
    );
    c.drawPath(
      Path()
        ..moveTo(3.05, _shipSheer(3.05))
        ..quadraticBezierTo(3.12, -.35, 2.66, .12),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .06
        ..strokeCap = StrokeCap.round
        ..color = Sketch.fade(const Color(0xffffdcae), .8),
    );
    // Gilded trim round the transom and the figurehead under the bowsprit.
    c.drawPath(
      Path()
        ..moveTo(-3.0, _shipSheer(-3.0))
        ..quadraticBezierTo(-3.1, -.15, -2.5, .15),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .05
        ..color = Sketch.fade(gold, .8),
    );
    c.drawPath(
      Sketch.poly([2.98, -.66, 3.3, -.74, 3.2, -.5, 3.0, -.42]),
      Paint()..color = gold,
    );
    c.drawCircle(const Offset(3.3, -.76), .07, Paint()..color = gold);
    // Ensign staff over the taffrail.
    c.drawLine(
      const Offset(-3.0, -1.3),
      const Offset(-3.22, -2.06),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .045
        ..strokeCap = StrokeCap.round
        ..color = hz(_shipSpar),
    );
  }

  /// A flag streaming forward on the following wind: [hoist] tall at the
  /// staff and [taper] of it lost by the fly, with an optional centre band.
  static void _shipFlag(
    Canvas c,
    Offset root,
    double len,
    double hoist,
    double taper,
    double clock,
    double phase,
    Color color, [
    Color? band,
  ]) {
    Path cloth(double from, double to) {
      final top = <Offset>[], bottom = <Offset>[];
      for (var i = 0; i <= 5; i++) {
        final t = i / 5;
        final y = math.sin(clock * 3.4 + t * 3.6 + phase) * len * .11 * t;
        final tall = hoist * (1 - taper * t);
        top.add(Offset(root.dx + t * len, root.dy + y + tall * from));
        bottom.add(Offset(root.dx + t * len, root.dy + y + tall * to));
      }
      final path = Path()..moveTo(top.first.dx, top.first.dy);
      for (final p in top.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      for (final p in bottom.reversed) {
        path.lineTo(p.dx, p.dy);
      }
      return path..close();
    }

    c.drawPath(cloth(0, 1), Paint()..color = color);
    if (band != null) c.drawPath(cloth(.34, .66), Paint()..color = band);
  }

  /// Life on the far band: flags flutter and gulls circle the headland.
  static void _shipLive(Canvas c, SceneFrame f) {
    _shipFlags(c, f);
    final h = f.h, at = Offset(f.w * .98, h * .605);
    for (var i = 0; i < 5; i++) {
      final a = f.clock * (.35 + Sketch.hash(i + 790) * .3) + i * 2.1;
      final home = at + Offset(h * (-.1 + i * .075), -h * (.15 + Sketch.hash(i + 750) * .08));
      Sketch.bird(
        c,
        home + Offset(math.cos(a) * h * .03, math.sin(a) * h * .008),
        h * (.0068 - (i % 2) * .0015),
        Sketch.fade(const Color(0xff4b4a5e), .6),
        flap: math.sin(f.clock * 5 + i * 1.7),
      );
    }
  }

  /// Pennants and the ensign flutter (cheap: a few small paths).
  static void _shipFlags(Canvas c, SceneFrame f) {
    final (at, s) = _shipPlace(f.w, f.h);
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(s);
    final t = f.clock;
    final cols = [
      _hazed(const Color(0xffe9b445), .26),
      _hazed(const Color(0xffe4574a), .26),
      _hazed(const Color(0xff4468a6), .3),
    ];
    var i = 0;
    for (final (mx, rake, top, _) in _shipMasts) {
      _shipFlag(c, Offset(mx + rake * top, top - .02), .72 + i * .1, .2, .85, t, i * 1.9, cols[i]);
      i++;
    }
    _shipFlag(
      c,
      const Offset(-3.22, -2.06),
      .78,
      .46,
      0,
      t,
      .6,
      _hazed(const Color(0xffd94e42), .28),
      _hazed(const Color(0xfffff1de), .2),
    );
    c.restore();
  }

  /// Reflections, wake and bow wave in the pale far water (overlay).
  static void _shipWater(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h, t = f.clock;
    final (at, s) = _shipPlace(w, h);
    final y0 = h * .6;
    final p = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.8, h * .0026);
    // A broken reflection row: two dashes with a gap that wanders.
    void row(double cx, double half, double y, Color color, double alpha, int seed) {
      p.color = Sketch.fade(color, alpha * presence);
      final gap = cx + math.sin(t * .9 + seed * 2.3) * half * .45;
      final hole = half * (.14 + .1 * Sketch.hash(seed + 900));
      final sway = math.sin(t * 1.3 + seed * 1.9) * half * .08;
      c.drawLine(Offset(cx + sway - half, y), Offset(gap - hole + sway, y), p);
      c.drawLine(Offset(gap + hole + sway, y), Offset(cx + sway + half, y), p);
    }

    final hullTone = _hazed(_shipHullDark, .3);
    final sailTone = _hazed(_shipSailWarm, .15);
    for (var i = 0; i < 4; i++) {
      row(at.dx, s * (2.8 - i * .5), y0 + h * (.0058 + i * .0049), hullTone, .3 - i * .06, i);
    }
    for (var i = 0; i < 3; i++) {
      row(at.dx - s * .1, s * (1.7 - i * .4), y0 + h * (.0255 + i * .0049), sailTone, .4 - i * .1, i + 4);
    }
    final steamer = _shipSteamerAt(w, h), sloop = _shipSloopAt(w, h);
    final k = h * .011;
    for (var i = 0; i < 2; i++) {
      row(steamer.dx, k * (2.8 - i * .7), y0 + h * (.0055 + i * .0046), hullTone, .28 - i * .09, i + 8);
      row(sloop.dx, k * (1.7 - i * .5), y0 + h * (.0052 + i * .0046), hullTone, .26 - i * .09, i + 10);
    }
    // White wake trailing astern, and small foam at the stem and stern.
    final foam = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.9, h * .0024);
    final x0 = at.dx - s * 3.1;
    for (final (dy, len, alpha) in const [(.0034, 4.5, .6), (.0068, 7.0, .36)]) {
      for (final (from, to, fall) in const [(0.0, .42, 1.0), (.5, .78, .6), (.86, 1.0, .3)]) {
        foam.color = Sketch.fade(const Color(0xfffffaf0), alpha * fall * presence);
        c.drawLine(Offset(x0 - s * len * from, y0 + h * dy), Offset(x0 - s * len * to, y0 + h * dy), foam);
      }
    }
    foam.color = Sketch.fade(const Color(0xffffffff), .75 * presence);
    c.drawLine(Offset(at.dx + s * 3.05, y0 + h * .0034), Offset(at.dx + s * 3.9, y0 + h * .0034), foam);
    c.drawLine(Offset(at.dx + s * 3.15, y0 + h * .0066), Offset(at.dx + s * 3.6, y0 + h * .0066), foam..color = Sketch.fade(const Color(0xffffffff), .45 * presence));
    c.drawLine(Offset(at.dx - s * 3.1, y0 + h * .0034), Offset(at.dx - s * 2.4, y0 + h * .0034), foam..color = Sketch.fade(const Color(0xffffffff), .6 * presence));
  }

  /// A far steamer crossing the sun's glare, smoke trailing on the wind.
  static void _shipSteamer(Canvas c, Offset at, double u) {
    Color hz(Color k, [double t = .42]) => _hazed(k, t);
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(u);
    // Smoke drifts off downwind, widening and thinning as it goes.
    final smoke = hz(const Color(0xff8b8a9c), .3);
    c.drawPath(
      Path()
        ..moveTo(1.3, -2.95)
        ..cubicTo(2.6, -3.5, 5.2, -3.3, 10.5, -4.2)
        ..cubicTo(9.0, -3.0, 5.0, -2.4, 1.75, -2.95)
        ..close(),
      Paint()
        ..shader = Gradient.linear(const Offset(1.4, 0), const Offset(10.5, 0), [
          Sketch.fade(smoke, .6),
          Sketch.fade(smoke, .3),
          Sketch.fade(smoke, 0),
        ], const [0, .5, 1]),
    );
    final mast = Paint()
      ..strokeWidth = .09
      ..color = hz(const Color(0xff3c4660));
    c.drawLine(const Offset(-2.2, -.9), const Offset(-2.2, -2.7), mast);
    c.drawLine(const Offset(-2.7, -2.1), const Offset(-1.7, -2.1), mast..strokeWidth = .05);
    c.drawLine(const Offset(-2.2, -2.7), const Offset(-.3, -1.5), mast..strokeWidth = .03);
    final cream = hz(const Color(0xffe4dede), .34), cast = hz(const Color(0xffcfc5cd), .34);
    c.drawPath(Sketch.poly([-.9, -.7, -.9, -1.5, 2.3, -1.5, 2.3, -.7]), Paint()..color = cream);
    c.drawPath(Sketch.poly([1.0, -.7, 1.0, -1.5, 2.3, -1.5, 2.3, -.7]), Paint()..color = cast);
    c.drawPath(Sketch.poly([-.2, -1.5, -.2, -1.9, 1.0, -1.9, 1.0, -1.5]), Paint()..color = cream);
    c.drawRect(const Rect.fromLTRB(-.8, -1.24, 2.2, -1.1), Paint()..color = hz(const Color(0xff4a5570), .4));
    c.drawPath(Sketch.poly([1.15, -1.5, 1.2, -2.8, 1.75, -2.8, 1.8, -1.5]), Paint()..color = hz(const Color(0xff3a4258)));
    c.drawRect(const Rect.fromLTRB(1.19, -2.5, 1.77, -2.3), Paint()..color = hz(const Color(0xffd8574a), .38));
    c.drawPath(Sketch.poly([1.17, -2.8, 1.78, -2.8, 1.74, -2.95, 1.21, -2.95]), Paint()..color = hz(const Color(0xff2b3145)));
    c.drawPath(
      Path()
        ..moveTo(-3.5, -1.1)
        ..quadraticBezierTo(-3.2, -.85, -2.6, -.85)
        ..lineTo(3.1, -.78)
        ..lineTo(2.9, .2)
        ..lineTo(-2.9, .2)
        ..close(),
      Paint()..color = hz(const Color(0xff36405a)),
    );
    c.drawRect(const Rect.fromLTRB(-3.2, -.72, 3.0, -.6), Paint()..color = hz(const Color(0xffe5bf70), .4));
    c.restore();
  }

  /// A tiny fore-and-aft sloop, bow to the right, beating along the horizon.
  static void _shipSloop(Canvas c, Offset at, double u) {
    Color hz(Color k, [double t = .34]) => _hazed(k, t);
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(u);
    final lit = hz(_shipSailLit, .22), shade = hz(_shipSailShade, .3);
    c.drawLine(
      const Offset(-.1, -.6),
      const Offset(-.1, -4.0),
      Paint()
        ..strokeWidth = .09
        ..color = hz(_shipSpar),
    );
    c.drawPath(
      Path()
        ..moveTo(-.18, -.85)
        ..lineTo(-.18, -3.95)
        ..quadraticBezierTo(-1.4, -2.2, -1.9, -.9)
        ..close(),
      Paint()
        ..shader = Gradient.linear(const Offset(-1.9, -2), const Offset(0, -2), [shade, lit]),
    );
    c.drawPath(
      Sketch.poly([.02, -3.6, 2.5, -.85, .02, -.85]),
      Paint()..color = hz(_shipSailWarm, .2),
    );
    c.drawPath(
      Path()
        ..moveTo(-2.0, -.6)
        ..lineTo(2.6, -.8)
        ..quadraticBezierTo(1.5, .2, .9, .2)
        ..lineTo(-1.5, .2)
        ..close(),
      Paint()..color = hz(const Color(0xff4a3f58), .3),
    );
    c.restore();
  }

  /// Knots (dx, height above the water) of the island's headland profile,
  /// in viewport heights, sun-facing cliffs on the left, long slope right.
  static const _shipHeadland = <double>[
    -.42, -.004, -.41, .024, -.396, .054, -.378, .078, -.345, .086, //
    -.29, .092, -.235, .103, -.18, .113, -.12, .107, -.06, .12, //
    -.005, .128, .05, .114, .11, .103, .17, .09, .24, .075, //
    .3, .062, .36, .05, .42, .038, .5, .024, .58, .011, .66, -.004,
  ];

  static Path _shipHeadlandPath(Offset at, double h, {double lift = 0, double from = -9, double to = 9}) {
    final pts = <Offset>[];
    for (var i = 0; i + 1 < _shipHeadland.length; i += 2) {
      final dx = _shipHeadland[i];
      if (dx < from || dx > to) continue;
      pts.add(Offset(at.dx + dx * h, at.dy - (_shipHeadland[i + 1] - lift) * h));
    }
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i + 1 < pts.length; i++) {
      final mid = Offset.lerp(pts[i], pts[i + 1], .5)!;
      path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
    }
    return path..lineTo(pts.last.dx, pts.last.dy);
  }

  /// Height of the headland's profile at [dx] (viewport heights).
  static double _shipHeadlandY(double dx) {
    for (var i = 0; i + 3 < _shipHeadland.length; i += 2) {
      final x0 = _shipHeadland[i], x1 = _shipHeadland[i + 2];
      if (dx >= x0 && dx <= x1) {
        final t = (dx - x0) / (x1 - x0);
        return _shipHeadland[i + 1] + (_shipHeadland[i + 3] - _shipHeadland[i + 1]) * t;
      }
    }
    return 0;
  }

  static void _island(Canvas c, Offset at, double h) {
    Color hz(Color k, [double t = .4]) => _hazed(k, t);
    // Two paler ranges stand behind the headland, each hazier than the last.
    for (final (tone, haze, base, lift, wave) in const [
      (0xff9aa6c0, .64, .1, .05, 5.2),
      (0xff8590b0, .5, .06, .03, 8.1),
    ]) {
      final range = Path()..moveTo(at.dx - h * .1, at.dy + h * .01);
      for (var x = -.1; x <= 1.0; x += .04) {
        final open = ((x + .1) / .32).clamp(0.0, 1.0);
        final ht = (base + lift * math.sin(x * wave + 1) + lift * .55 * math.sin(x * wave * 2.3 + 2)) * open * open * (3 - 2 * open);
        range.lineTo(at.dx + x * h, at.dy - math.max(.003, ht) * h);
      }
      range
        ..lineTo(at.dx + h, at.dy + h * .01)
        ..close();
      c.drawPath(range, Paint()..color = hz(Color(tone), haze));
    }
    final body = Path.from(_shipHeadlandPath(at, h))
      ..lineTo(at.dx + .66 * h, at.dy + h * .01)
      ..lineTo(at.dx - .42 * h, at.dy + h * .01)
      ..close();
    c.drawPath(
      body,
      Paint()
        ..shader = Gradient.linear(at + Offset(-h * .4, 0), at + Offset(h * .4, 0), [
          hz(const Color(0xff9a8fa6), .3),
          hz(const Color(0xff7982a2), .34),
          hz(const Color(0xff5f739a), .4),
        ], const [0, .45, 1]),
    );
    c.save();
    c.clipPath(body);
    // Shadow plane on the slope turned from the sun, in faceted gullies.
    c.drawPath(
      Sketch.poly([
        -.005, -.14, .7, -.14, .7, .02, .36, 0, .3, -.035, .22, -.02, //
        .17, -.06, .11, -.05, .06, -.09, .02, -.1,
      ], at: at, s: h),
      Paint()..color = Sketch.fade(hz(const Color(0xff44587c), .4), .5),
    );
    // Sunlit flank of the cliff, then strata and ledges cut across it.
    c.drawPath(
      Sketch.poly([-.43, .01, -.41, -.05, -.37, -.088, -.3, -.07, -.25, -.03, -.2, .01], at: at, s: h),
      Paint()..color = Sketch.fade(const Color(0xffffcfa0), .3),
    );
    final strata = Paint();
    var x = -.42;
    for (var i = 0; x < -.04; i++) {
      final wide = .012 + Sketch.hash(i + 700) * .02;
      if (i.isEven) {
        strata.color = Sketch.fade(hz(const Color(0xff45506c), .4), .14 + Sketch.hash(i + 710) * .12);
        c.drawRect(Rect.fromLTRB(at.dx + x * h, at.dy - h * .14, at.dx + (x + wide) * h, at.dy), strata);
      }
      x += wide;
    }
    final ledge = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.7, h * .002)
      ..color = Sketch.fade(const Color(0xffffe4c8), .32);
    for (var i = 0; i < 9; i++) {
      final lx = -.41 + i * .034 + Sketch.hash(i + 760) * .02;
      final ly = .012 + Sketch.hash(i + 770) * .05;
      final len = .012 + Sketch.hash(i + 780) * .026;
      c.drawLine(Offset(at.dx + lx * h, at.dy - ly * h), Offset(at.dx + (lx + len) * h, at.dy - (ly + .002) * h), ledge);
    }
    // Turf along the top, a fringe of trees on the far slope, a warm rim.
    c.drawPath(
      _shipHeadlandPath(at, h, lift: .0055, from: -.36, to: .56),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .011
        ..strokeJoin = StrokeJoin.round
        ..color = Sketch.fade(hz(const Color(0xff6f9878), .32), .9),
    );
    c.drawPath(
      _shipHeadlandPath(at, h, lift: .0018, to: -.06),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0036
        ..strokeCap = StrokeCap.round
        ..color = Sketch.fade(const Color(0xffffe0b8), .75),
    );
    // Dark rock at the waterline, then surf.
    c.drawRect(
      Rect.fromLTRB(at.dx - h * .43, at.dy - h * .011, at.dx + h * .67, at.dy),
      Paint()..color = Sketch.fade(hz(const Color(0xff36445e), .4), .65),
    );
    c.restore();
    // A fringe of trees breaks the skyline on the far slope.
    final tree = Paint()..color = Sketch.fade(hz(const Color(0xff4c7461), .34), .9);
    for (var i = 0; i < 22; i++) {
      final dx = -.03 + i * .027 + Sketch.hash(i + 720) * .012;
      final r = h * (.0042 + Sketch.hash(i + 730) * .0032);
      c.drawCircle(Offset(at.dx + dx * h, at.dy - _shipHeadlandY(dx) * h + r * .35), r, tree);
    }
    c.drawRect(
      Rect.fromLTRB(at.dx - h * .42, at.dy - h * .005, at.dx + h * .55, at.dy),
      Paint()..color = Sketch.fade(const Color(0xffffffff), .55),
    );
    Sketch.mist(
      c,
      Rect.fromCenter(center: at + Offset(h * .05, -h * .004), width: h * 1.4, height: h * .07),
      _haze,
      .55,
    );
  }

  // --- lighthouse (mid band) --------------------------------------------------
  // Offsets are in viewport heights from `base`: x is the tower axis, y the mean
  // waterline (the mid ridge), so negative y is up. The sun sits to the left, so
  // every lit plane faces left and the shade falls to the right.

  static const _lighthouseAt = .86;
  static const _lighthouseFoot = -.111;
  static const _lighthouseHead = -.251;
  static const _lighthouseLamp = -.279;

  Offset _lighthouseBase(double w, double h) =>
      Offset(w * _lighthouseAt, h * ridge(Depth.mid, w * _lighthouseAt / h, 0));

  static Color _lighthouseTint(Color k) => _hazed(k, .07);

  static void _lighthouse(Canvas c, Offset base, double h) {
    _lighthouseRock(c, base, h);
    _lighthouseGrass(c, base, h);
    _lighthouseSteps(c, base, h);
    _lighthouseCottage(c, base, h);
    _lighthouseTower(c, base, h);
    _lighthouseFence(c, base, h);
    _lighthouseBirds(c, base, h);
  }

  static const _lighthouseOutline = <double>[
    -.212, .04, -.21, -.004, -.201, -.011, -.196, -.021, -.19, -.034, -.187, -.045, //
    -.174, -.047, -.165, -.055, -.16, -.067, -.151, -.075, -.139, -.076, -.128, -.083,
    -.121, -.095, -.111, -.103, -.097, -.105, -.086, -.109, -.077, -.117, -.066, -.122,
    -.052, -.124, -.04, -.127, -.01, -.128, .02, -.127, .06, -.129, .09, -.127,
    .11, -.125, .13, -.126, .152, -.123, .16, -.113, .163, -.103, .168, -.095,
    .172, -.088, .181, -.087, .186, -.078, .189, -.068, .191, -.058, .199, -.057,
    .206, -.05, .208, -.04, .211, -.032, .217, -.024, .222, -.016, .226, -.004,
    .23, .04,
  ];

  /// Height of the islet's outline at x (the outline only ever moves right).
  static double _lighthouseCrown(double x) {
    const o = _lighthouseOutline;
    for (var i = 0; i + 3 < o.length; i += 2) {
      if (x >= o[i] && x <= o[i + 2]) {
        final t = (x - o[i]) / (o[i + 2] - o[i]);
        return o[i + 1] + (o[i + 3] - o[i + 1]) * t;
      }
    }
    return .04;
  }

  /// Where the wet, dark rock meets the dry: an irregular tide line.
  static double _lighthouseTide(double x) =>
      -.026 + .005 * math.sin(x * 61 + .5) + .0035 * math.sin(x * 137 + 2);

  static void _lighthouseRock(Canvas c, Offset base, double h) {
    Offset p(double x, double y) => Offset(base.dx + x * h, base.dy + y * h);
    Paint fill(Color k) => Paint()..color = _lighthouseTint(k);
    final body = Sketch.poly(_lighthouseOutline, at: base, s: h);
    c.drawPath(body, fill(const Color(0xff8d8798)));
    c.save();
    c.clipPath(body);
    // Sunlit planes face the rising sun on the left, the right side is shade.
    for (final (color, xy) in const <(Color, List<double>)>[
      (Color(0xffc9a898), [-.212, .04, -.21, -.004, -.201, -.011, -.196, -.021, -.19, -.034, -.187, -.045, -.174, -.047, -.165, -.055, -.16, -.067, -.151, -.075, -.139, -.076, -.128, -.083, -.121, -.095, -.111, -.103, -.097, -.105, -.086, -.109, -.077, -.117, -.066, -.122, -.052, -.124, -.04, -.127, -.036, -.1, -.058, -.082, -.082, -.068, -.104, -.05, -.122, -.03, -.14, -.005, -.15, .04]),
      (Color(0xffdcc0ac), [-.097, -.105, -.086, -.109, -.077, -.117, -.066, -.122, -.052, -.124, -.04, -.127, -.036, -.1, -.058, -.09, -.08, -.092]),
      (Color(0xffa89ca4), [-.03, -.126, .012, -.128, .024, -.085, .014, -.04, 0, -.02, -.02, -.05, -.028, -.09]),
      (Color(0xff44455e), [.012, -.128, .02, -.128, .034, -.08, .03, -.04, .02, -.02, .014, -.04, .024, -.085]),
      (Color(0xffa89ca4), [.06, -.129, .09, -.127, .094, -.09, .086, -.06, .072, -.04, .066, -.07]),
      (Color(0xff44455e), [.09, -.127, .1, -.126, .108, -.09, .104, -.05, .096, -.04, .09, -.06, .096, -.09]),
      (Color(0xff9a8e9c), [.1, -.126, .13, -.126, .135, -.124, .13, -.1, .122, -.075, .108, -.05, .104, -.09]),
      (Color(0xff585970), [.152, -.123, .16, -.113, .163, -.103, .168, -.095, .172, -.088, .181, -.087, .186, -.078, .189, -.068, .191, -.058, .199, -.057, .206, -.05, .208, -.04, .211, -.032, .217, -.024, .222, -.016, .226, -.004, .23, .04, .112, .04, .1, -.02, .108, -.05, .122, -.075, .13, -.1, .135, -.124]),
      (Color(0xffdcc0ac), [-.187, -.045, -.174, -.047, -.165, -.055, -.171, -.04, -.184, -.036]),
      (Color(0xffdcc0ac), [-.151, -.075, -.139, -.076, -.128, -.083, -.134, -.068, -.147, -.066]),
      (Color(0xff8f8aa2), [.172, -.088, .181, -.087, .186, -.078, .178, -.078]),
]) {
      c.drawPath(Sketch.poly(xy, at: base, s: h), fill(color));
    }
    // Shadow the grass lip throws on the cliff below it.
    c.drawPath(
      Sketch.poly([-.07, -.106, .156, -.106, .156, -.086, -.07, -.088], at: base, s: h),
      Paint()..shader = Gradient.linear(p(0, -.106), p(0, -.084), [Sketch.fade(const Color(0xff2b2a44), .34), Sketch.fade(const Color(0xff2b2a44), 0)]),
    );
    // Strata: broken seams, each with a lit lip, dipping gently to the right.
    final seams = Path(), lips = Path();
    for (var k = 0; k < 6; k++) {
      final y0 = -.112 + k * .024;
      var x = -.23 + Sketch.hash(k + 2100) * .05;
      for (var i = 0; x < .24; i++) {
        final len = .03 + Sketch.hash(k * 40 + i + 2110) * .07;
        final dy = (Sketch.hash(k * 40 + i + 2150) - .5) * .008;
        final a = p(x, y0 + dy + x * .05), b = p(x + len, y0 + dy + (x + len) * .05);
        seams
          ..moveTo(a.dx, a.dy)
          ..lineTo(b.dx, b.dy);
        lips
          ..moveTo(a.dx, a.dy - h * .003)
          ..lineTo(b.dx, b.dy - h * .003);
        x += len + .012 + Sketch.hash(k * 40 + i + 2190) * .03;
      }
    }
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.7, h * .002);
    c.drawPath(seams, line..color = Sketch.fade(const Color(0xff2b2b42), .2));
    c.drawPath(lips, line..color = Sketch.fade(const Color(0xffffe6d2), .16));
    // Fractures between the seams.
    final cracks = Path();
    for (var i = 0; i < 16; i++) {
      final a = p(-.19 + Sketch.hash(i + 2300) * .38, -.1 + Sketch.hash(i + 2320) * .07);
      cracks
        ..moveTo(a.dx, a.dy)
        ..lineTo(a.dx + (Sketch.hash(i + 2360) - .5) * h * .012, a.dy + h * (.012 + Sketch.hash(i + 2340) * .014));
    }
    c.drawPath(cracks, line..color = Sketch.fade(const Color(0xff26263c), .32));
    // Dark wet rock below the tide line, with a wet sheen along its edge.
    final tide = <Offset>[for (var i = 0; i <= 44; i++) p(-.26 + i * .012, _lighthouseTide(-.26 + i * .012) + (Sketch.hash(i + 2400) - .5) * .004)];
    final wet = Path()..moveTo(tide.first.dx, p(0, .06).dy);
    for (final o in tide) {
      wet.lineTo(o.dx, o.dy);
    }
    wet
      ..lineTo(tide.last.dx, p(0, .06).dy)
      ..close();
    c.drawPath(
      wet,
      Paint()..shader = Gradient.linear(p(-.22, 0), p(.24, 0), [_lighthouseTint(const Color(0xff566a80)), _lighthouseTint(const Color(0xff2d3b54))]),
    );
    final fringe = Path()..moveTo(tide.first.dx, tide.first.dy - h * .004);
    for (final o in tide.skip(1)) {
      fringe.lineTo(o.dx, o.dy - h * .004);
    }
    c.drawPath(
      fringe,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = h * .008
        ..color = Sketch.fade(_lighthouseTint(const Color(0xff7d8a44)), .5),
    );
    final sheen = Path()..moveTo(tide.first.dx, tide.first.dy);
    for (final o in tide.skip(1)) {
      sheen.lineTo(o.dx, o.dy);
    }
    c.drawPath(sheen, line..color = Sketch.fade(const Color(0xffc9e6f2), .42));
    // Barnacles crust the dry rock just above the tide.
    final crust = Paint()..color = Sketch.fade(const Color(0xffe9e0d8), .38);
    for (var i = 0; i < 34; i++) {
      final x = -.2 + Sketch.hash(i + 2440) * .42;
      c.drawCircle(p(x, _lighthouseTide(x) - .005 - Sketch.hash(i + 2480) * .014), h * .0016, crust);
    }
    // Contact shadow toward the water.
    c.drawRect(
      Rect.fromPoints(p(-.3, -.03), p(.4, .06)),
      Paint()..shader = Gradient.linear(p(0, -.03), p(0, .04), [Sketch.fade(const Color(0xff1b2540), 0), Sketch.fade(const Color(0xff1b2540), .4)]),
    );
    c.restore();
    // Rim light along the sunward edge.
    final rim = Path()..moveTo(p(-.21, -.004).dx, p(-.21, -.004).dy);
    for (var i = 2; i <= 38; i += 2) {
      final o = p(_lighthouseOutline[i], _lighthouseOutline[i + 1]);
      rim.lineTo(o.dx, o.dy);
    }
    c.drawPath(rim, line..color = Sketch.fade(const Color(0xffffe9cf), .55));
    // Clumps of rockweed hang off the tide line.
    final weed = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.8, h * .0026);
    for (var i = 0; i < 11; i++) {
      final x = -.195 + i * .039 + (Sketch.hash(i + 2500) - .5) * .02;
      for (var j = 0; j < 4; j++) {
        final sx = x + (j - 1.5) * .0042;
        final lean = (Sketch.hash(i * 4 + j + 2520) - .5) * .012;
        final s = p(sx, _lighthouseTide(sx) - .002);
        weed.color = _lighthouseTint(const [Color(0xff566030), Color(0xff6f7b3a), Color(0xff7d6634), Color(0xff4c6a3c)][(i + j) % 4]);
        c.drawPath(
          Path()
            ..moveTo(s.dx, s.dy)
            ..quadraticBezierTo(s.dx + lean * h * .8, s.dy + h * .008, s.dx + lean * h * 1.3, s.dy + h * (.014 + Sketch.hash(i * 4 + j + 2560) * .012)),
          weed,
        );
      }
    }
    // Outlying skerries breaking the surface.
    for (final (xy, lit) in const <(List<double>, List<double>)>[
      ([.236, .04, .24, -.01, .252, -.026, .262, -.036, .274, -.022, .286, -.012, .292, .04], [.236, .04, .24, -.01, .252, -.026, .262, -.036, .262, -.006, .25, .04]),
      ([.312, .04, .316, -.004, .326, -.014, .338, -.002, .344, .04], [.312, .04, .316, -.004, .326, -.014, .326, .02]),
    ]) {
      final shape = Sketch.poly(xy, at: base, s: h);
      c.drawPath(shape, fill(const Color(0xff5f5d74)));
      c.drawPath(Sketch.poly(lit, at: base, s: h), fill(const Color(0xffa08f94)));
      c.save();
      c.clipPath(shape);
      c.drawRect(Rect.fromPoints(p(.2, -.012), p(.4, .06)), fill(const Color(0xff2d3b54)));
      c.restore();
    }
  }

  static void _lighthouseGrass(Canvas c, Offset base, double h) {
    Offset p(double x, double y) => Offset(base.dx + x * h, base.dy + y * h);
    const from = -.088, to = .158;
    final grass = Path()..moveTo(p(from, _lighthouseCrown(from) + .002).dx, p(from, _lighthouseCrown(from) + .002).dy);
    var x = from;
    for (var i = 0; x < to; i++) {
      final w = math.min(.012 + Sketch.hash(i + 2600) * .01, to - x);
      final a = p(x + w / 2, _lighthouseCrown(x + w / 2) - .003 - Sketch.hash(i + 2620) * .006);
      final b = p(x + w, _lighthouseCrown(x + w));
      grass.quadraticBezierTo(a.dx, a.dy, b.dx, b.dy);
      x += w;
    }
    // The front edge overhangs the cliff in scalloped tufts.
    for (var i = 0; x > from; i++) {
      final w = math.min(.011 + Sketch.hash(i + 2640) * .008, x - from);
      final drop = Sketch.hash(i + 2660) > .55 ? .012 : .004;
      final a = p(x - w / 2, -.098 + drop * 1.6), b = p(x - w, -.106 + (Sketch.hash(i + 2680) - .5) * .004);
      grass.quadraticBezierTo(a.dx, a.dy, b.dx, b.dy);
      x -= w;
    }
    grass.close();
    c.drawPath(
      grass,
      Paint()..shader = Gradient.linear(p(0, -.136), p(0, -.096), [_lighthouseTint(const Color(0xffb6cf8e)), _lighthouseTint(const Color(0xff88ab7a)), _lighthouseTint(const Color(0xff5b8465))], const [0, .45, 1]),
    );
    // Wind-swept blades and a few flowers.
    final blades = Path();
    for (var i = 0; i < 30; i++) {
      final bx = from + .01 + i * ((to - from - .02) / 30) + (Sketch.hash(i + 2700) - .5) * .006;
      final o = p(bx, _lighthouseCrown(bx) - .002);
      blades
        ..moveTo(o.dx, o.dy)
        ..lineTo(o.dx - h * (.001 + Sketch.hash(i + 2720) * .002), o.dy - h * (.004 + Sketch.hash(i + 2740) * .005));
    }
    c.drawPath(
      blades,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(.8, h * .0026)
        ..color = _lighthouseTint(const Color(0xffa4c281)),
    );
    final bloom = Paint();
    for (var i = 0; i < 9; i++) {
      bloom.color = _lighthouseTint(const [Color(0xfffff2ee), Color(0xffffc4d0), Color(0xffe6dcff)][i % 3]);
      c.drawCircle(p(-.07 + i * .026 + Sketch.hash(i + 2760) * .012, -.117 + Sketch.hash(i + 2780) * .008), h * .0022, bloom);
    }
  }

  static void _lighthouseSteps(Canvas c, Offset base, double h) {
    Offset p(double x, double y) => Offset(base.dx + x * h, base.dy + y * h);
    // A stair cut into the sunlit slope, with a handrail, leads up from a jetty.
    const a = Offset(-.19, -.02), b = Offset(-.068, -.108), half = .0055;
    final d = b - a, n = Offset(-d.dy, d.dx) / d.distance;
    Offset edge(Offset o, double side) => p(o.dx + n.dx * half * side, o.dy + n.dy * half * side);
    c.drawPath(
      Path()
        ..moveTo(edge(a, 1).dx, edge(a, 1).dy)
        ..lineTo(edge(b, 1).dx, edge(b, 1).dy)
        ..lineTo(edge(b, -1).dx, edge(b, -1).dy)
        ..lineTo(edge(a, -1).dx, edge(a, -1).dy)
        ..close(),
      Paint()..color = _lighthouseTint(const Color(0xffe8d6c6)),
    );
    final treads = Path(), posts = Path();
    for (var i = 1; i < 13; i++) {
      final t = a + d * (i / 13);
      treads
        ..moveTo(edge(t, -1).dx, edge(t, -1).dy)
        ..lineTo(edge(t, 1).dx, edge(t, 1).dy);
    }
    for (var i = 0; i <= 4; i++) {
      final t = edge(a + d * (i / 4), -1);
      posts
        ..moveTo(t.dx, t.dy)
        ..lineTo(t.dx, t.dy - h * .014);
    }
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.6, h * .0016)
      ..color = Sketch.fade(const Color(0xff5b4f66), .5);
    c.drawPath(treads, line);
    line
      ..strokeWidth = math.max(.7, h * .002)
      ..color = _lighthouseTint(const Color(0xff45465e));
    c.drawPath(posts, line);
    final ra = edge(a, -1), rb = edge(b, -1);
    c.drawLine(Offset(ra.dx, ra.dy - h * .014), Offset(rb.dx, rb.dy - h * .014), line);
    // Jetty at the waterline and a dinghy alongside.
    c.drawRect(Rect.fromPoints(p(-.256, -.014), p(-.196, -.009)), Paint()..color = _lighthouseTint(const Color(0xffa07c5e)));
    c.drawRect(Rect.fromPoints(p(-.256, -.0095), p(-.196, -.007)), Paint()..color = Sketch.fade(const Color(0xff3a2e3c), .5));
    final pile = Paint()..color = _lighthouseTint(const Color(0xff5c463c));
    for (final x in const [-.254, -.232, -.212]) {
      c.drawRect(Rect.fromPoints(p(x, -.017), p(x + .0035, .02)), pile);
    }
    c.drawPath(
      Path()
        ..moveTo(p(-.318, -.013).dx, p(-.318, -.013).dy)
        ..quadraticBezierTo(p(-.296, .008).dx, p(-.296, .008).dy, p(-.266, -.009).dx, p(-.266, -.009).dy)
        ..lineTo(p(-.268, -.014).dx, p(-.268, -.014).dy)
        ..quadraticBezierTo(p(-.292, -.004).dx, p(-.292, -.004).dy, p(-.316, -.017).dx, p(-.316, -.017).dy)
        ..close(),
      Paint()..color = _lighthouseTint(const Color(0xffc4473c)),
    );
    c.drawPath(
      Path()
        ..moveTo(p(-.317, -.0155).dx, p(-.317, -.0155).dy)
        ..quadraticBezierTo(p(-.292, -.0025).dx, p(-.292, -.0025).dy, p(-.267, -.0115).dx, p(-.267, -.0115).dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..color = _lighthouseTint(const Color(0xfff8efe4))
        ..strokeWidth = math.max(.7, h * .002),
    );
  }

  static void _lighthouseWindow(Canvas c, Rect r, double h, {bool arch = false}) {
    final pad = math.max(.5, h * .0016);
    Radius top(double extra) => Radius.circular(arch ? r.width / 2 + extra : 0);
    c.drawRRect(
      RRect.fromRectAndCorners(r.inflate(pad), topLeft: top(pad), topRight: top(pad)),
      Paint()..color = _lighthouseTint(const Color(0xfffbf0e0)),
    );
    c.drawRRect(
      RRect.fromRectAndCorners(r, topLeft: top(0), topRight: top(0)),
      Paint()..shader = Gradient.linear(r.topCenter, r.bottomCenter, [_lighthouseTint(const Color(0xffa9c4da)), _lighthouseTint(const Color(0xff3f5278))]),
    );
    c.drawLine(
      r.topCenter,
      r.bottomCenter,
      Paint()
        ..color = Sketch.fade(const Color(0xfffbf0e0), .7)
        ..strokeWidth = math.max(.5, h * .0014),
    );
  }

  static void _lighthouseCottage(Canvas c, Offset base, double h) {
    Offset p(double x, double y) => Offset(base.dx + x * h, base.dy + y * h);
    Paint fill(Color k) => Paint()..color = _lighthouseTint(k);
    // A lean-to store on the right, in shade.
    c.drawPath(Sketch.poly([.1, -.113, .1, -.145, .148, -.127, .148, -.113], at: base, s: h), fill(const Color(0xffc3c2d4)));
    c.drawRect(Rect.fromPoints(p(.117, -.127), p(.128, -.113)), fill(const Color(0xff4a5a70)));
    c.drawPath(Sketch.poly([.096, -.15, .153, -.131, .153, -.124, .096, -.143], at: base, s: h), fill(const Color(0xff8c3848)));
    // The house: a whitewashed wall, lit on the left.
    c.drawRect(
      Rect.fromPoints(p(.026, -.15), p(.1, -.113)),
      Paint()..shader = Gradient.linear(p(.026, 0), p(.1, 0), [_lighthouseTint(const Color(0xfffff4e6)), _lighthouseTint(const Color(0xfff8ead9)), _lighthouseTint(const Color(0xffcfcbdb))], const [0, .55, 1]),
    );
    c.drawRect(Rect.fromPoints(p(.026, -.117), p(.1, -.113)), Paint()..color = Sketch.fade(const Color(0xff5a5872), .35));
    _lighthouseWindow(c, Rect.fromPoints(p(.036, -.141), p(.046, -.126)), h);
    _lighthouseWindow(c, Rect.fromPoints(p(.082, -.141), p(.092, -.126)), h);
    c.drawRRect(
      RRect.fromRectAndCorners(Rect.fromPoints(p(.056, -.136), p(.068, -.113)), topLeft: Radius.circular(h * .005), topRight: Radius.circular(h * .005)),
      fill(const Color(0xff3f6c7a)),
    );
    c.drawRect(Rect.fromPoints(p(.0545, -.1145), p(.0695, -.1125)), fill(const Color(0xffe6dcd0)));
    // Slate-red gable, lit on its left slope, with shingle courses and trim.
    final gable = Sketch.poly([.016, -.148, .063, -.194, .11, -.148], at: base, s: h);
    c.drawPath(Sketch.poly([.016, -.148, .063, -.194, .063, -.148], at: base, s: h), fill(const Color(0xffdb5341)));
    c.drawPath(Sketch.poly([.063, -.194, .11, -.148, .063, -.148], at: base, s: h), fill(const Color(0xff9a3b48)));
    c.save();
    c.clipPath(gable);
    final courses = Path();
    for (var i = 0; i < 5; i++) {
      final y = -.155 - i * .0075;
      courses
        ..moveTo(p(.0, y).dx, p(.0, y).dy)
        ..lineTo(p(.13, y).dx, p(.13, y).dy);
    }
    c.drawPath(
      courses,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, h * .0014)
        ..color = Sketch.fade(const Color(0xff4a1d34), .3),
    );
    c.restore();
    final trim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.8, h * .0024)
      ..color = _lighthouseTint(const Color(0xfffbe9d6));
    c.drawPath(
      Path()
        ..moveTo(p(.014, -.1465).dx, p(.014, -.1465).dy)
        ..lineTo(p(.063, -.1955).dx, p(.063, -.1955).dy)
        ..lineTo(p(.112, -.1465).dx, p(.112, -.1465).dy),
      trim..color = Sketch.fade(const Color(0xffffd9c4), .8),
    );
    c.drawCircle(p(.063, -.165), h * .0055, fill(const Color(0xfffbf0e0)));
    c.drawCircle(p(.063, -.165), h * .0038, fill(const Color(0xff3f5278)));
    // Chimney on the right slope, with a lit and a shaded face.
    c.drawRect(Rect.fromPoints(p(.083, -.201), p(.0875, -.158)), fill(const Color(0xffbe6350)));
    c.drawRect(Rect.fromPoints(p(.0875, -.201), p(.092, -.158)), fill(const Color(0xff87404a)));
    c.drawRect(Rect.fromPoints(p(.0815, -.2045), p(.0935, -.2)), fill(const Color(0xffe9ddd0)));
    // The tower's shadow falls across the wall.
    c.save();
    c.clipRect(Rect.fromPoints(p(.026, -.15), p(.1, -.113)));
    c.drawPath(Sketch.poly([.02, -.15, .05, -.15, .066, -.113, .02, -.113], at: base, s: h), Paint()..color = Sketch.fade(const Color(0xff3a3a66), .17));
    c.restore();
  }

  /// The tower's stone-white or banded-red body: lit left, turning to shade.
  static Paint _lighthouseBody(Offset base, double h, bool red) => Paint()
    ..shader = Gradient.linear(
      Offset(base.dx - h * .031, 0),
      Offset(base.dx + h * .031, 0),
      [
        for (final k in red
            ? const [Color(0xffef6a55), Color(0xffd94a3b), Color(0xffb63b40), Color(0xff8d3349), Color(0xff7d2f4b)]
            : const [Color(0xfffff1dc), Color(0xfff8e9d9), Color(0xffdad0d6), Color(0xffb3b2c8), Color(0xffa09fba)])
          _lighthouseTint(k),
      ],
      const [0, .3, .52, .8, 1],
    );

  static void _lighthouseTower(Canvas c, Offset base, double h) {
    Offset p(double x, double y) => Offset(base.dx + x * h, base.dy + y * h);
    const foot = _lighthouseFoot, head = _lighthouseHead;
    double half(double k) => .03 - .011 * k - .0012 * math.sin(math.pi * k);
    double yAt(double k) => foot + (head - foot) * k;
    final shaft = Path();
    const n = 8;
    for (var i = 0; i <= n; i++) {
      final o = p(-half(i / n), yAt(i / n));
      i == 0 ? shaft.moveTo(o.dx, o.dy) : shaft.lineTo(o.dx, o.dy);
    }
    for (var i = n; i >= 0; i--) {
      final o = p(half(i / n), yAt(i / n));
      shaft.lineTo(o.dx, o.dy);
    }
    shaft.close();
    final white = _lighthouseBody(base, h, false), red = _lighthouseBody(base, h, true);
    c.save();
    c.clipPath(shaft);
    c.drawRect(Rect.fromPoints(p(-.04, foot + .01), p(.04, head - .01)), white);
    for (final (k0, k1) in const [(.17, .36), (.53, .72)]) {
      c.drawRect(Rect.fromPoints(p(-.04, yAt(k1)), p(.04, yAt(k0))), red);
    }
    // Stone courses and staggered joints read as a fine tint.
    final stone = Path();
    for (var i = 0; i < 12; i++) {
      final y0 = yAt(i / 12), y1 = yAt((i + 1) / 12);
      stone
        ..moveTo(p(-.04, y1).dx, p(-.04, y1).dy)
        ..lineTo(p(.04, y1).dx, p(.04, y1).dy);
      for (var j = 0; j < 7; j++) {
        final o = p(-.037 + j * .0125 + (i.isOdd ? .00625 : 0), y0);
        stone
          ..moveTo(o.dx, o.dy)
          ..lineTo(o.dx, p(0, y1).dy);
      }
    }
    c.drawPath(
      stone,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, h * .0013)
        ..color = Sketch.fade(const Color(0xff4a4c78), .11),
    );
    // The gallery shades the top of the shaft.
    c.drawRect(
      Rect.fromPoints(p(-.04, head), p(.04, head + .026)),
      Paint()..shader = Gradient.linear(p(0, head), p(0, head + .026), [Sketch.fade(const Color(0xff3a3a66), .34), Sketch.fade(const Color(0xff3a3a66), 0)]),
    );
    c.restore();
    // Plinth of dressed stone.
    c.drawPath(
      Sketch.poly([-.034, foot + .008, -.0325, foot - .005, .0325, foot - .005, .034, foot + .008], at: base, s: h),
      Paint()
        ..shader = Gradient.linear(p(-.034, 0), p(.034, 0), [_lighthouseTint(const Color(0xffe6d3c2)), _lighthouseTint(const Color(0xffc9bfc6)), _lighthouseTint(const Color(0xff8d8ca8))], const [0, .5, 1]),
    );
    // Sunward rim light down the left edge.
    final rim = Path();
    for (var i = 0; i <= n; i++) {
      final o = p(-half(i / n) + .0008, yAt(i / n));
      i == 0 ? rim.moveTo(o.dx, o.dy) : rim.lineTo(o.dx, o.dy);
    }
    c.drawPath(
      rim,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.7, h * .002)
        ..color = Sketch.fade(const Color(0xffffffff), .6),
    );
    // Slit windows spiral up the shaft; the door has an arched fanlight.
    for (final (k, dx) in const [(.28, -.004), (.62, .006), (.87, -.002)]) {
      final y = yAt(k);
      _lighthouseWindow(c, Rect.fromPoints(p(dx - .0036, y - .008), p(dx + .0036, y + .006)), h, arch: true);
    }
    c.drawRRect(
      RRect.fromRectAndCorners(Rect.fromPoints(p(-.0105, foot - .0245), p(.0105, foot + .002)), topLeft: Radius.circular(h * .0105), topRight: Radius.circular(h * .0105)),
      Paint()..color = _lighthouseTint(const Color(0xfffbefe0)),
    );
    c.drawRRect(
      RRect.fromRectAndCorners(Rect.fromPoints(p(-.0083, foot - .0225), p(.0083, foot + .002)), topLeft: Radius.circular(h * .0083), topRight: Radius.circular(h * .0083)),
      Paint()..color = _lighthouseTint(const Color(0xff5a3a3a)),
    );
    c.drawLine(
      p(0, foot - .0225),
      p(0, foot + .002),
      Paint()
        ..color = Sketch.fade(const Color(0xff2a1c24), .55)
        ..strokeWidth = math.max(.5, h * .0013),
    );
    c.drawRect(Rect.fromPoints(p(-.013, foot + .002), p(.013, foot + .0075)), Paint()..color = _lighthouseTint(const Color(0xffd8cdc8)));
    _lighthouseLantern(c, base, h);
  }

  static void _lighthouseLantern(Canvas c, Offset base, double h) {
    Offset p(double x, double y) => Offset(base.dx + x * h, base.dy + y * h);
    const head = _lighthouseHead;
    final iron = _lighthouseTint(const Color(0xff3d3f58));
    final lamp = p(0, _lighthouseLamp);
    final hair = math.max(.6, h * .0016);
    // The lamp's glow spills past the glass, cached with the rest.
    c.drawCircle(
      lamp,
      h * .05,
      Paint()..shader = Gradient.radial(lamp, h * .05, [Sketch.fade(const Color(0xfffff0c0), .42), Sketch.fade(const Color(0xfffff0c0), 0)]),
    );
    // Cornice on dentils under the gallery.
    c.drawPath(
      Sketch.poly([-.021, head + .012, -.028, head + .0015, .028, head + .0015, .021, head + .012], at: base, s: h),
      Paint()..shader = Gradient.linear(p(-.028, 0), p(.028, 0), [_lighthouseTint(const Color(0xfff2e2d2)), _lighthouseTint(const Color(0xffc2bccb)), _lighthouseTint(const Color(0xff8f8eaa))], const [0, .55, 1]),
    );
    final dentils = Path();
    for (var i = 0; i < 7; i++) {
      final x = -.0225 + i * .0075;
      dentils
        ..moveTo(p(x, head + .0015).dx, p(x, head + .0015).dy)
        ..lineTo(p(x, head + .0115).dx, p(x, head + .0115).dy);
    }
    c.drawPath(
      dentils,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, h * .0015)
        ..color = Sketch.fade(const Color(0xff3a3a66), .3),
    );
    // Watch room in red, then the glazed lantern above the railing.
    c.drawRect(Rect.fromPoints(p(-.0185, head - .013), p(.0185, head - .002)), _lighthouseBody(base, h, true));
    final glass = Rect.fromPoints(p(-.0165, head - .043), p(.0165, head - .013));
    c.drawRect(
      glass,
      Paint()..shader = Gradient.linear(glass.topCenter, glass.bottomCenter, [_lighthouseTint(const Color(0xffe6eef4)), _lighthouseTint(const Color(0xfffff3c6)), _lighthouseTint(const Color(0xffffdf98))], const [0, .4, 1]),
    );
    // The lens: a bright core in the middle of the glass.
    c.drawOval(Rect.fromCenter(center: lamp, width: h * .017, height: h * .022), Paint()..color = Sketch.fade(const Color(0xffffffff), .8));
    c.drawOval(Rect.fromCenter(center: lamp, width: h * .008, height: h * .012), Paint()..color = const Color(0xffffe9a0));
    final bars = Path();
    for (final x in const [-.0165, -.0055, .0055, .0165]) {
      bars
        ..moveTo(p(x, head - .0435).dx, p(x, head - .0435).dy)
        ..lineTo(p(x, head - .0125).dx, p(x, head - .0125).dy);
    }
    bars
      ..moveTo(p(-.0165, head - .028).dx, p(-.0165, head - .028).dy)
      ..lineTo(p(.0165, head - .028).dx, p(.0165, head - .028).dy);
    c.drawPath(
      bars,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.6, h * .0019)
        ..color = Sketch.fade(iron, .82),
    );
    // A sunward glint on the glass.
    c.drawLine(
      p(-.0135, head - .04),
      p(-.0135, head - .022),
      Paint()
        ..color = Sketch.fade(const Color(0xffffffff), .8)
        ..strokeWidth = hair,
    );
    // Gallery: deck, and a railing of slim balusters.
    c.drawRect(Rect.fromPoints(p(-.037, head - .003), p(.037, head + .0015)), Paint()..color = iron);
    c.drawRect(Rect.fromPoints(p(-.037, head - .0035), p(.037, head - .0025)), Paint()..color = Sketch.fade(const Color(0xffffe1c4), .6));
    final rail = Path();
    for (var i = 0; i <= 11; i++) {
      final x = -.0345 + i * .0063;
      rail
        ..moveTo(p(x, head - .003).dx, p(x, head - .003).dy)
        ..lineTo(p(x, head - .014).dx, p(x, head - .014).dy);
    }
    for (final y in const [-.014, -.0085]) {
      rail
        ..moveTo(p(-.0345, head + y).dx, p(-.0345, head + y).dy)
        ..lineTo(p(.0345, head + y).dx, p(.0345, head + y).dy);
    }
    c.drawPath(
      rail,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.6, h * .0015)
        ..color = Sketch.fade(iron, .9),
    );
    // Roof cornice, copper-red dome, vent ball and lightning rod.
    c.drawRect(Rect.fromPoints(p(-.0215, head - .0485), p(.0215, head - .043)), Paint()..color = iron);
    c.drawPath(
      Path()
        ..moveTo(p(-.0195, head - .0485).dx, p(-.0195, head - .0485).dy)
        ..cubicTo(p(-.0195, head - .064).dx, p(-.0195, head - .064).dy, p(-.008, head - .0725).dx, p(-.008, head - .0725).dy, p(0, head - .0725).dx, p(0, head - .0725).dy)
        ..cubicTo(p(.008, head - .0725).dx, p(.008, head - .0725).dy, p(.0195, head - .064).dx, p(.0195, head - .064).dy, p(.0195, head - .0485).dx, p(.0195, head - .0485).dy)
        ..close(),
      _lighthouseBody(base, h, true),
    );
    c.drawPath(
      Path()
        ..moveTo(p(-.014, head - .052).dx, p(-.014, head - .052).dy)
        ..quadraticBezierTo(p(-.0145, head - .063).dx, p(-.0145, head - .063).dy, p(-.006, head - .069).dx, p(-.006, head - .069).dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(.7, h * .0022)
        ..color = Sketch.fade(const Color(0xffffd5c0), .7),
    );
    c.drawCircle(p(0, head - .0755), h * .0032, Paint()..color = iron);
    c.drawLine(
      p(0, head - .0785),
      p(0, head - .0885),
      Paint()
        ..color = iron
        ..strokeWidth = hair,
    );
    c.drawCircle(p(0, head - .0895), h * .0018, Paint()..color = _lighthouseTint(const Color(0xffe9ddd0)));
  }

  static void _lighthouseFence(Canvas c, Offset base, double h) {
    Offset p(double x, double y) => Offset(base.dx + x * h, base.dy + y * h);
    // Low shrubs in the lee of the fence.
    for (final (x, y, r) in const [(.158, -.108, .012), (-.058, -.108, .01), (.017, -.107, .0075)]) {
      c.drawCircle(p(x, y), h * r, Paint()..color = _lighthouseTint(const Color(0xff4f7a5c)));
      c.drawCircle(p(x - r * .28, y - r * .3), h * r * .7, Paint()..color = _lighthouseTint(const Color(0xff7ea672)));
      c.drawCircle(p(x + r * .5, y + r * .25), h * r * .5, Paint()..color = _lighthouseTint(const Color(0xff3f6a54)));
    }
    // A picket fence along the cliff edge.
    final fence = Path();
    for (final (x0, x1) in const [(-.063, -.03), (.024, .15)]) {
      final n = ((x1 - x0) / .0095).round();
      for (var i = 0; i <= n; i++) {
        final x = x0 + (x1 - x0) * i / n;
        fence
          ..moveTo(p(x, -.1035).dx, p(x, -.1035).dy)
          ..lineTo(p(x, -.1165).dx, p(x, -.1165).dy);
      }
      for (final y in const [-.1085, -.1135]) {
        fence
          ..moveTo(p(x0, y).dx, p(x0, y).dy)
          ..lineTo(p(x1, y).dx, p(x1, y).dy);
      }
    }
    c.drawPath(
      fence,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(.7, h * .0021)
        ..shader = Gradient.linear(p(-.06, 0), p(.15, 0), [_lighthouseTint(const Color(0xfffff2e0)), _lighthouseTint(const Color(0xfffbeedc)), _lighthouseTint(const Color(0xffc6c3d6))], const [0, .55, 1]),
    );
  }

  /// A perched cormorant, [s] tall, looking right when [face] is 1. With
  /// [spread] it holds its wings out to dry, facing the viewer.
  static void _lighthouseCormorant(Canvas c, Offset foot, double s, {double face = 1, bool spread = false}) {
    final skin = Paint()..color = _lighthouseTint(const Color(0xff2f3a54));
    final sheen = Paint()..color = Sketch.fade(const Color(0xff9fb4cc), .38);
    c.save();
    c.translate(foot.dx, foot.dy);
    c.scale(face * s, s);
    if (spread) {
      for (final side in const [-1.0, 1.0]) {
        c.drawPath(
          Path()
            ..moveTo(side * .1, -.6)
            ..lineTo(side * .66, -.72)
            ..lineTo(side * .72, -.46)
            ..lineTo(side * .5, -.36)
            ..lineTo(side * .4, -.22)
            ..lineTo(side * .14, -.24)
            ..close(),
          skin,
        );
        c.drawPath(
          Path()
            ..moveTo(side * .12, -.58)
            ..lineTo(side * .6, -.68)
            ..lineTo(side * .5, -.56)
            ..lineTo(side * .14, -.46)
            ..close(),
          sheen,
        );
      }
      c.drawOval(Rect.fromCenter(center: const Offset(0, -.3), width: .36, height: .62), skin);
      c.drawPath(
        Path()
          ..moveTo(0, -.55)
          ..quadraticBezierTo(.04, -.76, 0, -.9),
        skin
          ..style = PaintingStyle.stroke
          ..strokeWidth = .12
          ..strokeCap = StrokeCap.round,
      );
      skin.style = PaintingStyle.fill;
      c.drawCircle(const Offset(0, -.93), .085, skin);
      c.drawPath(Sketch.poly(const [.06, -.96, .26, -.93, .05, -.9]), skin);
    } else {
      c.drawPath(Sketch.poly(const [-.1, -.24, -.44, .02, -.04, -.04]), skin);
      c.save();
      c.translate(0, -.3);
      c.rotate(.2);
      c.drawOval(Rect.fromCenter(center: Offset.zero, width: .42, height: .68), skin);
      c.drawOval(Rect.fromCenter(center: const Offset(-.06, .02), width: .16, height: .4), sheen);
      c.restore();
      c.drawPath(
        Path()
          ..moveTo(.08, -.52)
          ..quadraticBezierTo(.02, -.74, .16, -.9),
        skin
          ..style = PaintingStyle.stroke
          ..strokeWidth = .13
          ..strokeCap = StrokeCap.round,
      );
      skin.style = PaintingStyle.fill;
      c.drawCircle(const Offset(.18, -.94), .09, skin);
      c.drawPath(Sketch.poly(const [.25, -.98, .46, -.93, .43, -.89, .25, -.9]), skin);
    }
    c.restore();
  }

  static void _lighthouseBirds(Canvas c, Offset base, double h) {
    Offset p(double x, double y) => Offset(base.dx + x * h, base.dy + y * h);
    _lighthouseCormorant(c, p(-.148, -.0755), h * .03, face: -1);
    _lighthouseCormorant(c, p(-.13, -.0805), h * .026);
    _lighthouseCormorant(c, p(.177, -.083), h * .032, spread: true);
    _lighthouseCormorant(c, p(.262, -.035), h * .027, face: -1);
  }

  /// The lamp turning, chimney smoke and wheeling gulls (the surf is painted
  /// in front of the water by [_lighthouseSurf]).
  void _lighthouseLive(Canvas c, SceneFrame f) {
    final h = f.h;
    final base = _lighthouseBase(f.w, h);
    Offset p(double x, double y) => Offset(base.dx + x * h, base.dy + y * h);
    // Twin beams turn about the lamp: the one swinging toward the viewer is
    // brighter and wider, and a flare blooms as it points straight at us.
    final lamp = p(0, _lighthouseLamp);
    final a = f.clock * .7;
    final swing = math.cos(a), toward = math.sin(a);
    for (final end in const [1.0, -1.0]) {
      final reach = h * .5 * swing * end;
      final near = (1 + toward * end) / 2;
      if (reach.abs() < h * .02) continue;
      final tip = lamp + Offset(reach, h * .012);
      final open = h * (.01 + .03 * near) * swing.abs();
      c.drawPath(
        Path()
          ..moveTo(lamp.dx, lamp.dy - h * .004)
          ..lineTo(tip.dx, tip.dy - open)
          ..lineTo(tip.dx, tip.dy + open)
          ..lineTo(lamp.dx, lamp.dy + h * .004)
          ..close(),
        Paint()
          ..shader = Gradient.linear(lamp, tip, [
            Sketch.fade(const Color(0xfffff3d0), .14 + .3 * near),
            Sketch.fade(const Color(0xfffff3d0), .06 * near),
            Sketch.fade(const Color(0xfffff3d0), 0),
          ], const [0, .55, 1]),
      );
    }
    final flare = math.pow(toward.abs(), 6).toDouble();
    final bloom = Paint();
    for (final (r, alpha) in const [(.034, .1), (.02, .2), (.01, .42)]) {
      bloom.color = Sketch.fade(const Color(0xfffff6dc), alpha * (.3 + .7 * flare));
      c.drawCircle(lamp, h * r, bloom);
    }
    // Smoke leans off the chimney with the wind, thinning as it climbs.
    final smoke = Paint();
    for (var k = 0; k < 8; k++) {
      final u = (f.clock * .09 + k / 8) % 1;
      smoke.color = Sketch.fade(const Color(0xfff4eee8), .34 * (1 - u) * math.min(1, u * 6));
      c.drawCircle(
        p(.0875 - u * .036 + .004 * math.sin(u * 7 + k), -.203 - u * .07),
        h * (.003 + .006 * u),
        smoke,
      );
    }
    // Gulls wheel round the lantern.
    final wing = Sketch.fade(const Color(0xfffff8ee), .9);
    for (var i = 0; i < 3; i++) {
      final b = f.clock * (.34 + i * .06) + i * 2.3;
      Sketch.bird(
        c,
        lamp + Offset(math.cos(b) * h * (.1 + i * .015), h * (.03 + i * .022) + math.sin(b) * h * .022),
        h * (.012 - i * .001),
        wing,
        flap: math.sin(f.clock * 4.2 + i * 1.7),
      );
    }
  }

  /// How much of the islet stands above the water during a crossing: the same
  /// staging as the compositor's sink and rise of the mid band, so the surf
  /// (which is painted in front of the water, not sunk with it) leaves and
  /// arrives together with the rock it breaks on.
  static double _lighthouseShow(SceneFrame f, double presence) {
    if (f.reducedMotion) return presence;
    final blend = WorldTour.at(f.seconds);
    if (!blend.crossing) return 1;
    final u = ((blend.t - .12) / (.74 - .12)).clamp(0.0, 1.0);
    if (blend.from == WorldRegion.sea) return 1 - RegionBlend.smooth(u / .52);
    return RegionBlend.smooth((u - .3) / .62);
  }

  /// Surf: wash along the waterline and breakers bursting on the rock. Drawn
  /// after the mid water so it lies in front of it and the islet sits IN the
  /// sea instead of behind it.
  void _lighthouseSurf(Canvas c, SceneFrame f, double presence) {
    final fade = presence * _lighthouseShow(f, presence);
    if (fade <= .01) return;
    final h = f.h;
    final base = _lighthouseBase(f.w, h);
    final foam = Paint();
    for (var i = 0; i < 16; i++) {
      final x = -.27 + i * .04 + (Sketch.hash(i + 2800) - .5) * .025;
      final wx = base.dx + h * (x + math.sin(f.clock * .7 + i * 1.9) * .006);
      final surge = .5 + .5 * math.sin(f.clock * 1.15 + i * 2.3);
      foam.color = Sketch.fade(const Color(0xfff6fcff), (.35 + .4 * surge) * fade);
      c.drawOval(
        Rect.fromCenter(
          center: Offset(wx, h * ridge(Depth.mid, wx / h, f.clock) - h * .001),
          width: h * (.05 + .03 * Sketch.hash(i + 2820)),
          height: h * (.004 + .006 * surge),
        ),
        foam,
      );
    }
    for (final (x, period, phase) in const <(double, double, double)>[
      (-.2, 5.6, .1),
      (-.09, 7.1, .55),
      (.06, 6.3, .3),
      (.19, 5.2, .8),
      (.27, 6.8, .45),
    ]) {
      final u = ((f.clock + phase * period) % period) / period;
      if (u > .42) continue;
      final k = u / .42, lift = math.sin(k * math.pi);
      final sx = base.dx + h * x;
      final sy = h * ridge(Depth.mid, sx / h, f.clock);
      foam.color = Sketch.fade(const Color(0xfff8fdff), .75 * lift * fade);
      c.drawCircle(Offset(sx, sy - h * (.006 + .02 * lift)), h * (.005 + .006 * lift), foam);
      c.drawCircle(Offset(sx - h * .008 * k, sy - h * .006 * lift), h * .006 * (.5 + lift), foam);
      c.drawCircle(Offset(sx + h * .01 * k, sy - h * .004 * lift), h * .005 * (.5 + lift), foam);
      for (var j = 0; j < 4; j++) {
        final vy = .1 + .03 * (j % 2);
        c.drawCircle(
          Offset(sx + h * (j - 1.5) * .012 * k, sy - h * (vy * k - vy * k * k) * 1.05),
          math.max(.8, h * .0026),
          foam,
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Marine life. All of it is drawn by the low band's `live`, behind the swell
  // crest, so every animal rises out from behind the wave in front of it.

  static final _whaleSkin = _hazed(const Color(0xff2f4258), .08);
  static final _whaleSkinLit = _hazed(const Color(0xff4d6784), .1);
  static final _whaleBelly = _hazed(const Color(0xffb1c5d7), .1);
  static final _whaleBellyHi = _hazed(const Color(0xffe2ecf4), .08);
  static const _whaleRim = Color(0xfffff0d6);
  static const _whaleFoam = Color(0xfff6fcff);
  static const _whaleMist = Color(0xffbdd3e3);

  static final _whaleFill = Paint();
  static final _whaleLine = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static final _whaleLegStart = WorldRegion.sea.index * WorldTour.leg;

  /// Seconds into this region's leg (negative while it is still arriving), so a
  /// visit always opens on cue. Reduced Motion (clock 0) lands on the leg's last
  /// moment; every actor is phased so that instant is a good picture.
  static double _whaleLocal(double clock) =>
      ((clock - _whaleLegStart + 6) % WorldTour.loop) - 6;

  /// Time inside a repeating [period]; [ref] is the moment shown at clock 0.
  static double _whaleCycle(double local, double period, double ref) =>
      (local - _whaleLocal(0) + ref) % period;

  static double _whaleEase(double x) {
    final k = x.clamp(0.0, 1.0);
    return k * k * (3 - 2 * k);
  }

  /// Dolphins: (exit x, leap length, apex, body length, cycle, moment at clock 0),
  /// x and sizes in viewport heights, cycle in seconds.
  static const _whalePod = [
    (.30, .20, .085, .10, 5.2, .55),
    (.47, .18, .070, .088, 5.2, .32),
    (.80, .22, .100, .10, 6.1, 1.5),
    (.95, .16, .060, .076, 5.7, 3.4),
  ];

  /// Flying fish: (x offset, launch delay, glide length, apex, body length).
  static const _whaleFishes = [
    (.00, .00, .30, .028, .036),
    (.03, .14, .26, .034, .032),
    (.07, .06, .33, .024, .038),
    (.01, .30, .28, .030, .030),
    (.06, .38, .24, .022, .028),
  ];

  /// The marine life of the low band: a humpback and her calf, a dolphin pod,
  /// flying fish and a diving gannet. Actors sit on the local swell and are
  /// only drawn while they can be on screen.
  void _whaleLive(Canvas c, SceneFrame f, int copy) {
    final h = f.h;
    final local = _whaleLocal(f.clock);
    final scroll = f.reducedMotion ? 0.0 : f.distance * Depth.low.parallax * h;
    final off = copy * period(Depth.low) * h - scroll;
    bool onScreen(double x, double reach) {
      final sx = x * h + off;
      return sx > -reach * h && sx < f.w + reach * h;
    }

    // The sea surface under an animal, in pixels: the lowest crest across its
    // footprint, so it always rises from behind a swell.
    double sea(double x0, double x1) {
      var y = 0.0;
      for (var i = 0; i < 5; i++) {
        y = math.max(y, ridge(Depth.low, x0 + (x1 - x0) * i / 4, f.clock));
      }
      return y * h + h * .004;
    }

    if (onScreen(.75, .6)) {
      for (var i = 0; i < _whalePod.length; i++) {
        final (x, dist, apex, size, cycle, ref) = _whalePod[i];
        final t = _whaleCycle(local + copy * 1.9, cycle, ref);
        _whaleLeap(c, f, x, dist, apex, size, t, i);
      }
    }
    if (onScreen(1.2, .6)) {
      final t = _whaleCycle(local + copy * 3.1, 6.3, .55);
      for (var i = 0; i < _whaleFishes.length; i++) {
        final (dx, delay, dist, apex, size) = _whaleFishes[i];
        _whaleGlide(c, f, 1.02 + dx, dist, apex, size, t - delay, i);
      }
      final tb = _whaleCycle(local + copy * 2.3, 8.4, 1.3);
      if (tb < 4.2) _whaleGannet(c, f, 1.28, sea(1.2, 1.32), tb);
    }
    if (onScreen(1.5, .8)) {
      final t = _whaleCycle(local, 14, 4.7);
      _whaleHump(c, 1.5 * h, sea(1.4, 1.6), h * .18, t, calf: true);
    }
    if (onScreen(1.9, .9)) {
      final t = _whaleCycle(local, 14, 7.5);
      _whaleHump(c, 1.9 * h, sea(1.65, 2.15), h * .34, t);
    }
  }

  // --- Humpback ---------------------------------------------------------------

  /// The dive path, in whale lengths with y down: a shallow rise, a rolling
  /// crest at (0, 0) and a steep descent, traced once.
  static const _whaleRise = -.31, _whaleDive = 1.26, _whaleTurn = .8;

  /// Water height below the crest, integration step, spine stations and the
  /// station where the tail hinges.
  static const _whaleHc = .12, _whaleDs = .02, _whaleN = 24, _whaleHinge = 19;

  static final _whaleTrack = _whaleTrace();
  static final _whaleEmergeX = _whaleCross(false);
  static final _whaleDiveX = _whaleCross(true);

  static ({int crest, List<double> x, List<double> y, List<double> a})
  _whaleTrace() {
    const from = -2.6, to = 3.2;
    final n = ((to - from) / _whaleDs).round() + 1;
    final xs = List<double>.filled(n, 0);
    final ys = List<double>.filled(n, 0);
    final an = List<double>.filled(n, 0);
    double theta(double s) =>
        _whaleRise + (_whaleDive - _whaleRise) * _whaleEase(s / _whaleTurn);
    var x = 0.0, y = 0.0;
    for (var i = 0; i < n; i++) {
      final s = from + i * _whaleDs;
      xs[i] = x;
      ys[i] = y;
      an[i] = theta(s);
      final mid = theta(s + _whaleDs / 2);
      x += math.cos(mid) * _whaleDs;
      y += math.sin(mid) * _whaleDs;
    }
    var crest = 0;
    while (crest < n - 1 && an[crest] < 0) {
      crest++;
    }
    final cx = xs[crest], cy = ys[crest];
    for (var i = 0; i < n; i++) {
      xs[i] -= cx;
      ys[i] -= cy;
    }
    return (crest: crest, x: xs, y: ys, a: an);
  }

  /// Where the path meets the water, rising or diving, in whale lengths.
  static double _whaleCross(bool dive) {
    final t = _whaleTrack;
    for (var i = dive ? t.crest : 0; i < t.x.length; i++) {
      if (dive ? t.y[i] >= _whaleHc : t.y[i] <= _whaleHc) return t.x[i];
    }
    return 0;
  }

  /// Path position and heading at [s] lengths past the crest.
  static (double, double, double) _whaleAt(double s) {
    final t = _whaleTrack;
    final f = math.min(math.max(s / _whaleDs + t.crest, 0.0), t.x.length - 1.001);
    final i = f.floor(), k = f - i;
    return (
      t.x[i] + (t.x[i + 1] - t.x[i]) * k,
      t.y[i] + (t.y[i + 1] - t.y[i]) * k,
      t.a[i] + (t.a[i + 1] - t.a[i]) * k,
    );
  }

  /// Snout speed keys (show second, lengths per second): a brisk rise, a slow
  /// roll while she blows, then the dive quickens.
  static const _whaleSpeed = [
    (0.0, .30),
    (1.8, .34),
    (2.6, .16),
    (3.6, .12),
    (5.4, .14),
    (6.0, .28),
    (7.2, .32),
    (9.0, .34),
  ];

  /// Snout position on the path (lengths past the crest) at show second [t].
  static double _whaleHead(double t) {
    var s = -.55;
    for (var i = 0; i + 1 < _whaleSpeed.length; i++) {
      final (t0, v0) = _whaleSpeed[i];
      final (t1, v1) = _whaleSpeed[i + 1];
      if (t <= t0) return s;
      final dt = math.min(t, t1) - t0;
      final v = v0 + (v1 - v0) * dt / (t1 - t0);
      s += (v0 + v) / 2 * dt;
    }
    return s + .34 * math.max(0.0, t - 9);
  }

  /// How far the tail is thrown up from the path (radians): the fluke lift.
  static double _whaleFlick(double t) =>
      1.0 * _whaleEase((t - 5.6) / 1.4) * (1 - _whaleEase((t - 7.6) / 1.2));

  /// Pectoral fin angle from the body axis: it rests along the flank, is raised
  /// and waved, then slaps down.
  static double _whaleFin(double t) {
    const rest = -.3, peak = 1.15, slap = -.7;
    final up = _whaleEase((t - 3.9) / 1.1);
    final down = _whaleEase((t - 5.7) / .35);
    final back = _whaleEase((t - 6.1) / .9);
    final wave = math.sin(t * 7) * .1 * up * (1 - down);
    return rest + (peak - rest) * up - (peak - slap) * down + (rest - slap) * back + wave;
  }

  /// Humpback outline keys: (station 0..1 from the snout, half thickness above
  /// the spine, half thickness below), in body lengths.
  static const _whaleShape = [
    (.0, .003, .003),
    (.03, .043, .038),
    (.07, .066, .068),
    (.12, .079, .092),
    (.2, .088, .105),
    (.3, .096, .112),
    (.4, .100, .112),
    (.5, .097, .104),
    (.6, .092, .090),
    (.7, .078, .070),
    (.78, .058, .050),
    (.86, .040, .034),
    (.93, .027, .024),
    (1.0, .017, .015),
  ];

  static (double, double) _whaleThick(double a) {
    for (var i = 1; i < _whaleShape.length; i++) {
      final (a1, u1, d1) = _whaleShape[i];
      if (a <= a1) {
        final (a0, u0, d0) = _whaleShape[i - 1];
        final k = (a - a0) / (a1 - a0);
        return (u0 + (u1 - u0) * k, d0 + (d1 - d0) * k);
      }
    }
    return (.017, .015);
  }

  static Offset _whaleLerp(List<Offset> v, double a) {
    final f = a * (v.length - 1);
    final i = f.floor().clamp(0, v.length - 2);
    return Offset.lerp(v[i], v[i + 1], f - i)!;
  }

  /// A smooth closed curve through [p].
  static Path _whaleClosed(List<Offset> p) {
    final n = p.length;
    final start = Offset.lerp(p[n - 1], p[0], .5)!;
    final path = Path()..moveTo(start.dx, start.dy);
    for (var i = 0; i < n; i++) {
      final m = Offset.lerp(p[i], p[(i + 1) % n], .5)!;
      path.quadraticBezierTo(p[i].dx, p[i].dy, m.dx, m.dy);
    }
    return path..close();
  }

  /// A smooth open curve through [p].
  static Path _whaleOpen(List<Offset> p) {
    final path = Path()..moveTo(p[0].dx, p[0].dy);
    for (var i = 1; i < p.length - 1; i++) {
      final m = Offset.lerp(p[i], p[i + 1], .5)!;
      path.quadraticBezierTo(p[i].dx, p[i].dy, m.dx, m.dy);
    }
    return path..lineTo(p.last.dx, p.last.dy);
  }

  /// One humpback at show second [t]. [ox] is where the crest of its dive path
  /// stands, [oy] the water, [L] its length.
  static void _whaleHump(
    Canvas c,
    double ox,
    double oy,
    double L,
    double t, {
    bool calf = false,
  }) {
    _whaleRings(c, ox, oy, L, t);
    _whaleBody(c, ox, oy, L, t);
    for (final (start, life, size) in const [(2.2, 2.8, 1.0), (5.0, 2.0, .62)]) {
      final age = t - start;
      if (age <= 0 || age >= life) continue;
      final (x, y, a) = _whaleAt(_whaleHead(math.min(t, start + .5)) - .17);
      final hole =
          Offset(ox + x * L, oy + (y - _whaleHc) * L) +
          Offset(math.sin(a), -math.cos(a)) * (L * .08);
      if (hole.dy > oy + L * .02) continue;
      _spout(c, hole, L * .3 * size, age, life);
    }
  }

  /// Wake rings where she surfaces and where she goes down, then a calm slick.
  static void _whaleRings(Canvas c, double ox, double oy, double L, double t) {
    for (final (x, t0, count, reach) in [
      (ox + _whaleEmergeX * L, .5, 3, .3),
      (ox + _whaleDiveX * L, 6.6, 4, .42),
    ]) {
      for (var i = 0; i < count; i++) {
        final age = t - t0 - i * .6;
        if (age < 0 || age > 2.8) continue;
        final k = age / 2.8;
        final r = L * (.04 + reach * (1 - (1 - k) * (1 - k)));
        _whaleLine
          ..strokeWidth = math.max(.7, L * .007 * (1 - k * .5))
          ..color = Sketch.fade(_whaleFoam, .6 * (1 - k) * (1 - k));
        c.drawOval(
          Rect.fromCenter(center: Offset(x, oy - r * .04), width: r * 2, height: r * .3),
          _whaleLine,
        );
      }
    }
    final slick = (t - 7.6) / 5;
    if (slick > 0 && slick < 1) {
      _whaleFill.color = Sketch.fade(_whaleFoam, .2 * (1 - slick));
      c.drawOval(
        Rect.fromCenter(
          center: Offset(ox + _whaleDiveX * L, oy - L * .01),
          width: L * (.3 + .4 * slick),
          height: L * (.06 + .05 * slick),
        ),
        _whaleFill,
      );
    }
  }

  static void _whaleBody(Canvas c, double ox, double oy, double L, double t) {
    final head = _whaleHead(t);
    if (head < -.62 || head > 1.85) return;
    const n = _whaleN;
    final sp = List<Offset>.filled(n + 1, Offset.zero);
    final th = List<double>.filled(n + 1, 0);
    for (var j = 0; j <= n; j++) {
      final (x, y, a) = _whaleAt(head - j / n);
      sp[j] = Offset(ox + x * L, oy + (y - _whaleHc) * L);
      th[j] = a;
    }
    final flick = _whaleFlick(t);
    if (flick > 0) {
      for (var j = _whaleHinge + 1; j <= n; j++) {
        final w = _whaleEase((j - _whaleHinge) / (n - _whaleHinge));
        final a = th[j] + flick * w;
        sp[j] = sp[j - 1] - Offset(math.cos(a), math.sin(a)) * (L / n);
      }
    }
    final tg = List<Offset>.filled(n + 1, Offset.zero);
    final nm = List<Offset>.filled(n + 1, Offset.zero);
    final top = List<Offset>.filled(n + 1, Offset.zero);
    final bot = List<Offset>.filled(n + 1, Offset.zero);
    final bel = List<Offset>.filled(n + 1, Offset.zero);
    for (var j = 0; j <= n; j++) {
      final d = sp[math.max(j - 1, 0)] - sp[math.min(j + 1, n)];
      tg[j] = d / d.distance;
      nm[j] = Offset(tg[j].dy, -tg[j].dx);
      final (up, down) = _whaleThick(j / n);
      top[j] = sp[j] + nm[j] * (up * L);
      bot[j] = sp[j] - nm[j] * (down * L);
      final w = _whaleEase(math.min(j, n - j) / 5);
      final k = 1 + (.36 + .16 * Sketch.hash(j + 40) - 1) * w;
      bel[j] = sp[j] - nm[j] * (down * L * k);
    }
    // Flukes first: they hang off the end of the tail.
    if (sp[n].dy < oy + L * .2) {
      _whaleFluke(c, sp[n] - tg[n] * (L * .006), -tg[n], L, t, oy);
    }
    // Dorsal fin, low and swept back on its hump.
    final fb = top[15], ft = tg[15], fn = nm[15];
    _whaleFill.color = _whaleSkin;
    final fin = Path()
      ..moveTo(fb.dx + ft.dx * L * .045, fb.dy + ft.dy * L * .045)
      ..quadraticBezierTo(
        fb.dx + fn.dx * L * .06 + ft.dx * L * .015,
        fb.dy + fn.dy * L * .06 + ft.dy * L * .015,
        fb.dx + fn.dx * L * .085 - ft.dx * L * .045,
        fb.dy + fn.dy * L * .085 - ft.dy * L * .045,
      )
      ..quadraticBezierTo(
        fb.dx + fn.dx * L * .03 - ft.dx * L * .03,
        fb.dy + fn.dy * L * .03 - ft.dy * L * .03,
        fb.dx - ft.dx * L * .07,
        fb.dy - ft.dy * L * .07,
      )
      ..close();
    c.drawPath(fin, _whaleFill);
    final outline = <Offset>[
      sp[0] + tg[0] * (L * .006),
      for (var j = 1; j <= n; j++) top[j],
      sp[n] - tg[n] * (L * .012),
      for (var j = n; j >= 1; j--) bot[j],
    ];
    c.drawPath(_whaleClosed(outline), _whaleFill);
    // The paler belly, mottled along its edge, with throat pleats.
    _whaleFill.color = _whaleBelly;
    c.drawPath(
      _whaleClosed([
        for (var j = 1; j < n; j++) bel[j],
        for (var j = n - 1; j >= 1; j--) bot[j],
      ]),
      _whaleFill,
    );
    final pleats = Path();
    for (var m = 0; m < 10; m++) {
      final a = .09 + .04 * m;
      final from = _whaleLerp(bel, a), to = _whaleLerp(bot, a);
      pleats
        ..moveTo(from.dx, from.dy)
        ..lineTo(to.dx - _whaleLerp(tg, a).dx * L * .012, to.dy - _whaleLerp(tg, a).dy * L * .012);
    }
    _whaleLine
      ..strokeWidth = math.max(.6, L * .004)
      ..color = Sketch.fade(_whaleSkinLit, .5);
    c.drawPath(pleats, _whaleLine);
    // Long pectoral fin, along the flank until she raises and slaps it.
    _whalePec(
      c,
      _whaleLerp(sp, .27) - _whaleLerp(nm, .27) * (L * .03),
      _whaleLerp(tg, .27),
      _whaleLerp(nm, .27),
      L,
      _whaleFin(t),
    );
    // Wet sheen and the warm rim from the low sun on the back.
    final inset = <Offset>[for (var j = 1; j <= n; j++) top[j] - nm[j] * (L * .016)];
    _whaleLine
      ..strokeWidth = math.max(.8, L * .016)
      ..color = Sketch.fade(_whaleSkinLit, .85);
    c.drawPath(_whaleOpen(inset), _whaleLine);
    _whaleLine
      ..strokeWidth = math.max(.9, L * .011)
      ..color = Sketch.fade(_whaleRim, .62);
    c.drawPath(_whaleOpen([for (var j = 0; j <= n; j++) top[j]]), _whaleLine);
    c.drawPath(fin, _whaleLine..color = Sketch.fade(_whaleRim, .3));
    // Head: mouth line, eye, tubercles and barnacles.
    final mouth = <Offset>[
      for (final (a, d) in const [(.012, .006), (.05, .016), (.1, .024), (.15, .026), (.2, .014)])
        _whaleLerp(sp, a) - _whaleLerp(nm, a) * (d * L),
    ];
    _whaleLine
      ..strokeWidth = math.max(.6, L * .005)
      ..color = const Color(0x8022303f);
    c.drawPath(_whaleOpen(mouth), _whaleLine);
    _whaleFill.color = const Color(0xff1b2735);
    c.drawCircle(_whaleLerp(sp, .21) - _whaleLerp(nm, .21) * (L * .01), math.max(.7, L * .011), _whaleFill);
    final knobs = <Offset>[
      for (final a in const [.03, .06, .09, .12, .15])
        _whaleLerp(top, a) - _whaleLerp(nm, a) * (L * .014),
      for (final a in const [.05, .09, .13])
        _whaleLerp(bot, a) + _whaleLerp(nm, a) * (L * .014),
    ];
    _whaleLine
      ..strokeWidth = math.max(1.0, L * .016)
      ..color = _whaleSkinLit;
    c.drawPoints(PointMode.points, knobs, _whaleLine);
    final shells = <Offset>[
      _whaleLerp(bot, .07),
      _whaleLerp(bot, .1) + _whaleLerp(tg, .1) * (L * .01),
      _whaleLerp(top, .56) - _whaleLerp(nm, .56) * (L * .012),
      _whaleLerp(top, .6) - _whaleLerp(nm, .6) * (L * .014),
      _whaleLerp(bot, .3) + _whaleLerp(nm, .3) * (L * .012),
    ];
    _whaleLine
      ..strokeWidth = math.max(1.1, L * .02)
      ..color = const Color(0xffe6dccb);
    c.drawPoints(PointMode.points, shells, _whaleLine);
    // Foam where the body cuts the water line.
    final cuts = <double>[];
    for (var i = 0; i < outline.length; i++) {
      final p = outline[i], q = outline[(i + 1) % outline.length];
      if ((p.dy - oy) * (q.dy - oy) < 0) {
        cuts.add(p.dx + (q.dx - p.dx) * (oy - p.dy) / (q.dy - p.dy));
      }
    }
    cuts.sort();
    for (var i = 0; i + 1 < cuts.length; i += 2) {
      _whaleFill.color = Sketch.fade(_whaleFoam, .7);
      c.drawOval(
        Rect.fromLTRB(cuts[i] - L * .04, oy - L * .022, cuts[i + 1] + L * .04, oy + L * .01),
        _whaleFill,
      );
    }
  }

  static void _whalePec(Canvas c, Offset root, Offset tg, Offset nm, double L, double beta) {
    final dir = -tg * math.cos(beta) + nm * math.sin(beta);
    var side = Offset(-dir.dy, dir.dx);
    final want = tg - nm * .5;
    if (side.dx * want.dx + side.dy * want.dy < 0) side = -side;
    final tip = root + dir * (L * .31);
    final ctrlLead = root + dir * (L * .13) + side * (L * .075);
    final ctrlTrail = root + dir * (L * .17) - side * (L * .012);
    final base = root + side * (L * .03);
    final path = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(ctrlLead.dx, ctrlLead.dy, tip.dx, tip.dy)
      ..quadraticBezierTo(ctrlTrail.dx, ctrlTrail.dy, root.dx - side.dx * L * .03, root.dy - side.dy * L * .03)
      ..close();
    _whaleFill.color = Sketch.fade(_whaleBellyHi, .92);
    c.drawPath(path, _whaleFill);
    final lead = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(ctrlLead.dx, ctrlLead.dy, tip.dx, tip.dy);
    _whaleLine
      ..strokeWidth = math.max(.8, L * .01)
      ..color = Sketch.fade(_whaleSkin, .75);
    c.drawPath(lead, _whaleLine);
  }

  /// The fluke at the end of the tail: a notched crescent whose span stays
  /// horizontal on screen, so it reads as a thin sliver while the tail lies
  /// along the swell and opens into a broad Y as it is lifted.
  static Path _whaleFlukePath(Offset root, Offset back, double L, double su, double sv) {
    Offset q(double u, double v) =>
        root + back * (u * su * L) + Offset(v * sv * L * .78, v * sv * L * .05);
    const trail = [
      (.085, .025, .06, .065),
      (.1, .095, .07, .125),
      (.115, .165, .085, .19),
      (.105, .22, .108, .25),
    ];
    final p = Path();
    void quad(Offset a, Offset b) => p.quadraticBezierTo(a.dx, a.dy, b.dx, b.dy);
    final m = q(.045, 0);
    p.moveTo(m.dx, m.dy);
    for (final (cu, cv, eu, ev) in trail) {
      quad(q(cu, cv), q(eu, ev));
    }
    quad(q(.055, .16), q(.006, .035));
    final r = q(.006, -.035);
    p.lineTo(r.dx, r.dy);
    quad(q(.055, -.16), q(.108, -.25));
    for (var i = trail.length - 1; i >= 0; i--) {
      final (cu, cv, _, _) = trail[i];
      final end = i == 0 ? (.045, 0.0) : (trail[i - 1].$3, -trail[i - 1].$4);
      quad(q(cu, -cv), q(end.$1, end.$2));
    }
    return p..close();
  }

  static void _whaleFluke(Canvas c, Offset root, Offset back, double L, double t, double oy) {
    _whaleFill.color = _whaleSkin;
    c.drawPath(_whaleFlukePath(root, back, L, 1, 1), _whaleFill);
    _whaleFill.color = Sketch.fade(_whaleBelly, .85);
    c.drawPath(_whaleFlukePath(root, back, L, .7, .8), _whaleFill);
    _whaleLine
      ..strokeWidth = math.max(.8, L * .008)
      ..color = Sketch.fade(_whaleRim, .45);
    c.drawPath(_whaleFlukePath(root, back, L, 1, 1), _whaleLine);
    // Water sheeting off the trailing edge as the fluke slides down.
    final flow = _whaleEase((t - 6.6) / .5) * (1 - _whaleEase((t - 8.6) / .7));
    if (flow <= 0) return;
    _whaleLine
      ..strokeWidth = math.max(.7, L * .005)
      ..color = Sketch.fade(_whaleFoam, .75 * flow);
    for (var i = 0; i < 7; i++) {
      final v = -.2 + i * .0667;
      final start = root + back * (L * .05) + Offset(v * L * .78, v * L * .05);
      final len = L * (.05 + .09 * Sketch.hash(i + 70)) * (.6 + .4 * math.sin(t * 6 + i));
      final y1 = math.min(oy, start.dy + len);
      if (y1 > start.dy) c.drawLine(start, Offset(start.dx, y1), _whaleLine);
    }
  }

  /// A blow: a jet that shoots up, then a bushy mist that spreads and drifts.
  static void _spout(Canvas c, Offset at, double tall, double age, double life) {
    if (age <= 0 || age >= life || tall <= 0) return;
    final k = age / life;
    final rise = math.min(1.0, age / .55);
    final grow = 1 - (1 - rise) * (1 - rise);
    final fade = k < .3 ? 1.0 : math.pow(1 - (k - .3) / .7, 1.3).toDouble();
    const puffs = 7;
    for (var pass = 0; pass < 2; pass++) {
      for (var i = 0; i < puffs; i++) {
        final u = (i + .5) / puffs;
        if (u > grow + .08) break;
        final r = tall * (.07 + .14 * u) * (1 + 1.1 * k) * (.7 + .3 * grow);
        final sway = math.sin(i * 2.1 + age * 1.3) * tall * .03 * u;
        final p = at + Offset(-tall * .3 * u * u * (.3 + k) + sway, -tall * u * grow);
        final a = fade * (.78 - .3 * u);
        if (pass == 0) {
          _whaleFill.color = Sketch.fade(_whaleMist, a * .85);
          c.drawCircle(p + Offset(-r * .18, r * .16), r, _whaleFill);
        } else {
          _whaleFill.color = Sketch.fade(const Color(0xfffffaf0), a);
          c.drawCircle(p + Offset(r * .1, -r * .12), r * .85, _whaleFill);
        }
      }
    }
    _whaleSpray(c, at, age - .1, life * .6, tall * .55, 3, -.4);
  }

  /// A handful of droplets thrown up and falling back over [life] seconds.
  static void _whaleSpray(Canvas c, Offset o, double age, double life, double size, int seed, double lean) {
    if (age <= 0 || age >= life) return;
    final k = age / life;
    for (var i = 0; i < 7; i++) {
      final r0 = Sketch.hash(seed * 31 + i * 7), r1 = Sketch.hash(seed * 17 + i * 13 + 3);
      final x = o.dx + ((r0 - .5) * 2.2 + lean) * size * k;
      final y = o.dy - size * (.6 + r1 * 1.2) * 4 * k * (1 - k) * .5;
      _whaleFill.color = Sketch.fade(_whaleFoam, .85 * (1 - k));
      c.drawCircle(Offset(x, y), math.max(.6, size * (.035 + .03 * r0)), _whaleFill);
    }
  }

  // --- Dolphins, flying fish, gannet ---------------------------------------------

  static final _whaleDolphinBody = Path()
    ..moveTo(.5, .018)
    ..cubicTo(.46, .006, .42, -.012, .385, -.048)
    ..cubicTo(.36, -.082, .28, -.1, .17, -.104)
    ..cubicTo(.09, -.107, .03, -.104, -.02, -.098)
    ..cubicTo(-.045, -.14, -.075, -.2, -.1, -.232)
    ..cubicTo(-.115, -.2, -.125, -.13, -.135, -.088)
    ..cubicTo(-.24, -.07, -.34, -.045, -.43, -.012)
    ..cubicTo(-.46, -.03, -.5, -.07, -.545, -.085)
    ..cubicTo(-.53, -.055, -.515, -.03, -.505, -.005)
    ..cubicTo(-.515, .02, -.53, .05, -.545, .075)
    ..cubicTo(-.5, .05, -.46, .025, -.43, .012)
    ..cubicTo(-.35, .045, -.2, .078, -.04, .088)
    ..cubicTo(.1, .094, .24, .075, .33, .052)
    ..cubicTo(.4, .042, .46, .034, .5, .018)
    ..close();
  static final _whaleDolphinCape = Path()
    ..moveTo(-.43, .012)
    ..cubicTo(-.35, .045, -.2, .078, -.04, .088)
    ..cubicTo(.1, .094, .24, .075, .33, .052)
    ..cubicTo(.4, .042, .46, .034, .5, .018)
    ..cubicTo(.42, -.004, .3, -.02, .15, -.015)
    ..cubicTo(0, -.012, -.22, -.02, -.43, -.004)
    ..close();
  static final _whaleDolphinBelly = Path()
    ..moveTo(-.43, .012)
    ..cubicTo(-.35, .045, -.2, .078, -.04, .088)
    ..cubicTo(.1, .094, .24, .075, .33, .052)
    ..cubicTo(.4, .042, .46, .034, .5, .018)
    ..cubicTo(.42, .02, .3, .022, .15, .03)
    ..cubicTo(0, .04, -.22, .03, -.43, .008)
    ..close();
  static final _whaleDolphinFlipper = Path()
    ..moveTo(.13, .055)
    ..quadraticBezierTo(.1, .13, -.01, .185)
    ..quadraticBezierTo(.04, .1, .05, .07)
    ..close();
  static final _whaleDolphinBack = Path()
    ..moveTo(.385, -.048)
    ..cubicTo(.36, -.082, .28, -.1, .17, -.104)
    ..cubicTo(.09, -.107, .03, -.104, -.02, -.098);

  static void _whaleDolphin(Canvas c, Offset p, double ang, double size) {
    c.save();
    c.translate(p.dx, p.dy);
    c.rotate(ang);
    c.scale(size);
    _whaleFill.color = _hazed(const Color(0xff3c536b), .08);
    c.drawPath(_whaleDolphinBody, _whaleFill);
    _whaleFill.color = _hazed(const Color(0xff7d95ab), .1);
    c.drawPath(_whaleDolphinCape, _whaleFill);
    _whaleFill.color = _hazed(const Color(0xffe6edf3), .08);
    c.drawPath(_whaleDolphinBelly, _whaleFill);
    _whaleFill.color = _hazed(const Color(0xff33475d), .08);
    c.drawPath(_whaleDolphinFlipper, _whaleFill);
    _whaleLine
      ..strokeWidth = .022
      ..color = Sketch.fade(_whaleRim, .7);
    c.drawPath(_whaleDolphinBack, _whaleLine);
    c.restore();
  }

  /// One dolphin leap: an arc from behind one swell to behind the next, with
  /// spray at both ends.
  void _whaleLeap(Canvas c, SceneFrame f, double x, double dist, double apex, double size, double t, int seed) {
    const air = 1.0;
    final h = f.h;
    double sea(double xh) => ridge(Depth.low, xh, f.clock) * h + h * .004;
    if (t < air) {
      final u = t / air;
      final xh = x + dist * u;
      final e = h * .014, a = apex * h + e;
      final y = sea(xh) + e - a * 4 * u * (1 - u);
      final ang = math.atan2(-a * 4 * (1 - 2 * u), dist * h);
      _whaleDolphin(c, Offset(xh * h, y), ang, size * h);
    }
    if (t < .8) _whaleSpray(c, Offset(x * h, sea(x)), t, .8, h * .035, seed * 7 + 11, 0);
    final age = t - air;
    if (age > 0 && age < 1.5) {
      final base = Offset((x + dist) * h, sea(x + dist));
      _whaleSpray(c, base, age, .9, h * .04, seed * 7 + 5, 0);
      final k = age / 1.5;
      _whaleLine
        ..strokeWidth = math.max(.7, h * .002)
        ..color = Sketch.fade(_whaleFoam, .6 * (1 - k) * (1 - k));
      final r = h * (.012 + .04 * k);
      c.drawOval(Rect.fromCenter(center: base + Offset(0, -r * .05), width: r * 2, height: r * .3), _whaleLine);
    }
  }

  static final _whaleFishBody = Path()
    ..moveTo(.5, .01)
    ..cubicTo(.4, -.08, .1, -.11, -.25, -.05)
    ..lineTo(-.4, -.02)
    ..lineTo(-.5, -.1)
    ..lineTo(-.45, .02)
    ..lineTo(-.53, .16)
    ..lineTo(-.38, .045)
    ..cubicTo(-.15, .09, .2, .09, .5, .01)
    ..close();
  static final _whaleFishWing = Path()
    ..moveTo(.2, -.05)
    ..quadraticBezierTo(-.05, -.42, -.42, -.46)
    ..quadraticBezierTo(-.2, -.2, -.12, -.06)
    ..close();

  /// One flying fish glide: it bursts from a crest, skims and drops back.
  void _whaleGlide(Canvas c, SceneFrame f, double x, double dist, double apex, double size, double t, int seed) {
    const air = 1.25;
    if (t < 0 || t > air + .5) return;
    final h = f.h;
    Offset at(double u) {
      final xh = x + dist * u;
      final lift = math.pow(math.sin(math.pi * u), .8).toDouble();
      return Offset(xh * h, ridge(Depth.low, xh, f.clock) * h - h * .012 - apex * h * lift);
    }

    if (t < air) {
      final u = t / air;
      final p = at(u), q = at(math.min(1.0, u + .04));
      c.save();
      c.translate(p.dx, p.dy);
      c.rotate(math.atan2(q.dy - p.dy, q.dx - p.dx));
      c.scale(size * h);
      _whaleFill.color = const Color(0xb0e8f4fa);
      c.drawPath(_whaleFishWing, _whaleFill);
      _whaleFill.color = _hazed(const Color(0xff56728b), .1);
      c.drawPath(_whaleFishBody, _whaleFill);
      c.restore();
    }
    if (t < .5) _whaleSpray(c, at(0), t, .5, h * .02, seed + 40, 0);
  }

  static final _whaleDart = Path()
    ..moveTo(.5, 0)
    ..cubicTo(.35, -.1, -.1, -.09, -.5, -.03)
    ..lineTo(-.5, .03)
    ..cubicTo(-.1, .09, .35, .1, .5, 0)
    ..close();

  /// A gannet glides in, folds its wings and plunges, leaving a white plume.
  void _whaleGannet(Canvas c, SceneFrame f, double xh, double water, double t) {
    final h = f.h;
    final x0 = xh * h;
    const white = Color(0xfff8f6f0), tip = Color(0xff2b2f3a);
    if (t < 1.6) {
      final k = t / 1.6;
      final p = Offset(x0 - h * (.27 - .19 * k), water - h * (.15 - .05 * k) + math.sin(t * 5) * h * .002);
      final span = h * .026;
      final flap = math.sin(t * 7) * .7;
      Sketch.bird(c, p, span, white, flap: flap);
      final lift = span * (.2 + flap * .22);
      _whaleFill.color = tip;
      c.drawCircle(p + Offset(-span, -lift), span * .1, _whaleFill);
      c.drawCircle(p + Offset(span, -lift), span * .1, _whaleFill);
    } else if (t < 2.15) {
      final q = (t - 1.6) / .55;
      final p = Offset(x0 - h * .08 * (1 - q), water - h * .1 + h * .112 * q * q);
      c.save();
      c.translate(p.dx, p.dy);
      c.rotate(math.atan2(h * .224 * q, h * .08));
      c.scale(h * .055);
      _whaleFill.color = white;
      c.drawPath(_whaleDart, _whaleFill);
      _whaleFill.color = tip;
      c.drawRect(const Rect.fromLTRB(-.55, -.04, -.3, .04), _whaleFill);
      _whaleFill.color = const Color(0xffefd9a0);
      c.drawCircle(const Offset(.38, 0), .07, _whaleFill);
      c.restore();
    } else {
      final age = t - 2.15;
      final size = h * .06;
      final rise = math.sin(math.min(1.0, age / .6) * math.pi / 2);
      final ht = size * rise * (age < .9 ? 1 : math.max(0.0, 1 - (age - .9) / .9));
      final w = size * .16 * (1 + age * .5);
      if (ht > 0) {
        _whaleFill.color = Sketch.fade(_whaleFoam, .8);
        c.drawPath(
          Path()
            ..moveTo(x0 - w, water)
            ..quadraticBezierTo(x0 - w * .4, water - ht * .6, x0, water - ht)
            ..quadraticBezierTo(x0 + w * .4, water - ht * .6, x0 + w, water)
            ..close(),
          _whaleFill,
        );
      }
      _whaleSpray(c, Offset(x0, water), age, 1.4, size, 9, 0);
      final k = math.min(1.0, age / 1.8);
      _whaleLine
        ..strokeWidth = math.max(.7, h * .002)
        ..color = Sketch.fade(_whaleFoam, .6 * (1 - k) * (1 - k));
      final r = h * (.012 + .05 * k);
      c.drawOval(Rect.fromCenter(center: Offset(x0, water), width: r * 2, height: r * .3), _whaleLine);
    }
  }

  /// A channel-marker buoy riding the swell: a red float with a white band,
  /// rust and a wet waterline, a steel cage, a small lamp and a perched gull.
  /// [base] is the waterline, [s] the float's width.
  static void _buoy(Canvas c, Offset base, double s, double tilt, double clock) {
    const red = Color(0xffcf4239),
        redShade = Color(0xffa03230),
        redRim = Color(0xffff9c6e),
        white = Color(0xfff5efe6),
        whiteShade = Color(0xffcfd0dc),
        steel = Color(0xff353646),
        steelLit = Color(0xff7b7e92);
    final fill = Paint();
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.8, s * .055);
    c.save();
    c.translate(base.dx, base.dy);
    c.rotate(tilt);
    // Float: a rounded cone, lit only on its sun side.
    final hull = Path()
      ..moveTo(-s * .55, s * .08)
      ..cubicTo(-s * .58, -s * .3, -s * .38, -s * .72, -s * .3, -s * .96)
      ..lineTo(s * .3, -s * .96)
      ..cubicTo(s * .38, -s * .72, s * .58, -s * .3, s * .55, s * .08)
      ..close();
    c.drawPath(hull, fill..color = red);
    c.save();
    c.clipPath(hull);
    c.drawRect(Rect.fromLTRB(-s, -s, -s * .12, s * .2), fill..color = redShade);
    c.drawRect(Rect.fromLTRB(s * .34, -s, s, s * .2), fill..color = redRim);
    // The white band.
    c.drawRect(Rect.fromLTRB(-s * .7, -s * .68, s * .7, -s * .42), fill..color = white);
    c.drawRect(Rect.fromLTRB(-s * .7, -s * .68, -s * .12, -s * .42), fill..color = whiteShade);
    c.drawRect(Rect.fromLTRB(s * .34, -s * .68, s * .7, -s * .42), fill..color = const Color(0xffffe3c4));
    // Rust weeps down from the seam, and the waterline is dark and wet.
    fill.color = const Color(0xb38f4c2e);
    for (final (dx, len) in const [(-.3, .2), (-.02, .13), (.24, .17)]) {
      c.drawRect(Rect.fromLTWH(s * dx, -s * .42, s * .05, s * len), fill);
    }
    c.drawRect(Rect.fromLTRB(-s, -s * .1, s, s * .2), fill..color = const Color(0x8a1d2a48));
    // Weed at the waterline.
    c.drawRect(Rect.fromLTRB(-s, -s * .03, s, s * .12), fill..color = const Color(0xaa3f6a4a));
    c.restore();
    // Deck ring and cage.
    c.drawOval(Rect.fromCenter(center: Offset(0, -s * .96), width: s * .64, height: s * .13), fill..color = steel);
    line.color = steel;
    c.drawLine(Offset(-s * .24, -s * .96), Offset(-s * .09, -s * 1.8), line);
    c.drawLine(Offset(s * .24, -s * .96), Offset(s * .09, -s * 1.8), line);
    line
      ..color = steelLit
      ..strokeWidth = math.max(.6, s * .04);
    c.drawLine(Offset(-s * .06, -s * .96), Offset(-s * .05, -s * 1.8), line);
    c.drawLine(Offset(s * .06, -s * .96), Offset(s * .05, -s * 1.8), line);
    line
      ..color = steel
      ..strokeWidth = math.max(.6, s * .04);
    c.drawLine(Offset(-s * .2, -s * 1.22), Offset(s * .2, -s * 1.22), line);
    c.drawLine(Offset(-s * .15, -s * 1.5), Offset(s * .15, -s * 1.5), line);
    c.drawLine(Offset(-s * .24, -s * .96), Offset(s * .2, -s * 1.22), line);
    c.drawLine(Offset(s * .24, -s * .96), Offset(-s * .2, -s * 1.22), line);
    // Lamp: a pale glass drum under a small dome and topmark.
    final pulse = .5 + .5 * math.sin(clock * 2.4);
    c.drawRect(Rect.fromLTRB(-s * .14, -s * 1.88, s * .14, -s * 1.78), fill..color = steel);
    c.drawRect(
      Rect.fromLTRB(-s * .1, -s * 2.08, s * .1, -s * 1.88),
      fill..color = Sketch.mix(const Color(0xffe6d8b0), const Color(0xfffff0be), pulse),
    );
    c.drawPath(Sketch.poly([-.13, -2.08, 0, -2.24, .13, -2.08], s: s), fill..color = steel);
    c.drawLine(Offset(0, -s * 2.24), Offset(0, -s * 2.38), line);
    c.drawPath(Sketch.poly([0, -2.5, .07, -2.42, 0, -2.34, -.07, -2.42], s: s), fill..color = steel);
    // A gull rests on the deck, keeping upright as the buoy rocks.
    c.save();
    c.translate(-s * .3, -s * .97);
    c.rotate(-tilt * .7 + math.sin(clock * .7) * .03);
    const gull = Color(0xfff8f8f4), gullShade = Color(0xffc9d3da), tip = Color(0xff3b3f4c);
    line
      ..color = const Color(0xffe89a52)
      ..strokeWidth = math.max(.6, s * .03);
    c.drawLine(Offset(-s * .03, 0), Offset(-s * .03, -s * .06), line);
    c.drawLine(Offset(s * .04, 0), Offset(s * .04, -s * .06), line);
    c.drawOval(Rect.fromCenter(center: Offset(0, -s * .14), width: s * .44, height: s * .2), fill..color = gull);
    c.drawPath(Sketch.poly([.16, -.18, .3, -.13, .16, -.1], s: s), fill..color = gull);
    c.drawOval(Rect.fromCenter(center: Offset(s * .03, -s * .17), width: s * .3, height: s * .12), fill..color = gullShade);
    c.drawPath(Sketch.poly([.12, -.16, .28, -.135, .12, -.13], s: s), fill..color = tip);
    c.drawCircle(Offset(-s * .19, -s * .25), s * .075, fill..color = gull);
    c.drawPath(Sketch.poly([-.25, -.26, -.33, -.235, -.25, -.22], s: s), fill..color = const Color(0xffefb03e));
    c.restore();
    c.restore();
  }

  // ---- swells: painting -------------------------------------------------------

  static const _swellFoam = Color(0xfff7fcff);
  static const _swellSun = Color(0xfffff6e2);
  static const _swellDeep = Color(0xff123e66);

  /// WorldBackdrop.cruise: how fast the timed far band drifts.
  static const _swellCruise = .36;

  /// Where the near buoy floats, in viewport heights along the period.
  static const _swellBuoyX = 2.2;

  static final _swellFill = Paint();
  static final _swellInk = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// Row-body gradients are the same every frame, so they are built once per
  /// viewport height.
  static final _swellShaders = <(double, Depth, int), Shader>{};

  static Shader _swellShader(double h, Depth d, int j) =>
      _swellShaders[(h, d, j)] ??= _swellMakeShader(h, d, j);

  static Shader _swellMakeShader(double h, Depth d, int j) {
    if (d == Depth.far) {
      return Gradient.linear(
        Offset(0, h * .6),
        Offset(0, h * .65),
        [
          // Starts as the sky's own horizon colour so the water meets the
          // glow without a seam, then cools into the mid swell.
          const Color(0xe6ffe0c6),
          const Color(0x8cf6d6c8),
          const Color(0x30e6d2d4),
          const Color(0x00dcd0d8),
        ],
        const [0, .3, .7, 1],
      );
    }
    final rows = _swellRows(d);
    final (off, amp, _, _, _, crest, trough) = rows[j];
    final gap = j + 1 < rows.length ? rows[j + 1].$1 - off : .07;
    final base = _swellBase(d) + off;
    return Gradient.linear(
      Offset(0, (base - amp * 1.15) * h),
      Offset(0, (base + gap) * h),
      [crest, Sketch.mix(crest, trough, .5), trough],
      const [0, .3, 1],
    );
  }

  /// Height offset and tilt of the near buoy, following the swell under it.
  (double, double) _swellBuoyRide(double clock) {
    const e = .04;
    final slope =
        (ridge(Depth.near, _swellBuoyX + e, clock) -
            ridge(Depth.near, _swellBuoyX - e, clock)) /
        (2 * e);
    final bob =
        .004 * math.sin(clock * 1.7 + .6) + .0018 * math.sin(clock * 2.6 + 2);
    final tilt =
        math.atan(slope) * 1.1 +
        .045 * math.sin(clock * 1.3 + 1) +
        .02 * math.sin(clock * 2.1);
    return (.012 + bob, tilt);
  }

  /// A position along a row for item [k] of [count]: seeded, and carried
  /// along by the row's wave so foam rides the swell that made it.
  static double _swellItem(int k, int count, int seed, double extent, double drift) =>
      (((k + Sketch.hash(seed + k * 13) * .8) / count) * extent + drift) % extent;

  /// The far water: the peach sky mirrored under the horizon, the sun's
  /// path glinting in it, and a few faint long swell lines. Painted in the
  /// far band so the islet and the ship stay in front of it.
  void _swellHorizon(Canvas c, SceneFrame f, double presence) {
    final h = f.h, x0 = -h * .3, end = f.w + h * .7;
    _swellFill.color = Color.fromARGB((presence * 255).round().clamp(0, 255), 255, 255, 255);
    _swellFill.shader = _swellShader(h, Depth.far, 0);
    c.drawRect(Rect.fromLTRB(x0, h * .6, end, h * .65), _swellFill);
    _swellFill.shader = null;
    final pale = Path(), dark = Path();
    for (var r = 0; r < 3; r++) {
      final y = h * (.61 + r * .012);
      for (var k = 0; k < 9; k++) {
        final x = x0 + (end - x0) * (k + Sketch.hash(r * 31 + k + 700) * .8) / 9;
        final len = h * (.03 + .09 * Sketch.hash(r * 17 + k + 720));
        (r == 1 ? dark : pale)
          ..moveTo(x - len, y + h * .0015 * math.sin(x))
          ..lineTo(x + len, y);
      }
    }
    _swellInk.strokeWidth = math.max(.7, h * .0024);
    c.drawPath(dark, _swellInk..color = Sketch.fade(const Color(0xff7fa6bf), .3 * presence));
    c.drawPath(pale, _swellInk..color = Sketch.fade(const Color(0xfffff0e0), .42 * presence));
    // The far band drifts on the region clock; follow it to keep the glints
    // under the (screen-fixed) sun.
    final start = WorldTour.at(f.seconds).startOf(WorldRegion.sea);
    final drift = f.reducedMotion ? 0.0 : (f.seconds - start) * _swellCruise * Depth.far.parallax * h;
    final sx = f.w * light.at.dx + drift;
    final glint = Path();
    for (var r = 0; r < 4; r++) {
      final y = h * (.6075 + r * .0105);
      final reach = h * (.02 + r * .012);
      final n = 3 + r;
      for (var m = 0; m < n; m++) {
        final r1 = Sketch.hash(r * 61 + m * 19 + 800);
        final u = ((m + .5 + (r1 - .5) * .7) / n) * 2 - 1;
        final on = .5 + .5 * math.sin(f.clock * (1.2 + r1 * 1.3) + r * 1.9 + m * 3.1);
        final power = (1 - u.abs()) * (.35 + .65 * on);
        if (power < .15) continue;
        final x = sx + u * reach;
        final len = h * (.007 + .012 * r) * (.55 + .45 * power);
        final th = h * (.0012 + .0012 * r) * (.6 + .5 * power);
        glint
          ..moveTo(x - len, y)
          ..quadraticBezierTo(x, y - th * 2, x + len, y)
          ..quadraticBezierTo(x, y + th * 2, x - len, y);
      }
    }
    _swellFill.color = Sketch.fade(const Color(0xfffff3da), .85 * presence);
    c.drawPath(glint, _swellFill);
  }

  /// Rows of swell in one band: sunlit backs under every crest, shadow in
  /// front of it, translucent teal crest strips, a sun-warmed hot spot, and
  /// foam (broken crest lines, streaks, lace, whitecaps, ripples).
  void _swellRowsPaint(Canvas c, Depth d, SceneFrame f, double presence) {
    if (presence <= 0) return;
    final h = f.h, w = f.w, clock = f.clock;
    final tiled = d != Depth.mid;
    final rows = _swellRows(d);
    final count = rows.length;
    final base = _swellBase(d);
    // Timed bands start left of the screen too: a crossing pushes them back.
    final x0 = tiled ? 0.0 : -h * .3;
    final extent = tiled ? period(d) * h : w + h * 1.0;
    final n = math.max(12, (extent / (h * .05)).round());
    final step = extent / n;
    final scale = switch (d) {
      Depth.near => 1.6,
      Depth.low => 1.0,
      _ => .5,
    };
    final scroll = tiled && !f.reducedMotion ? f.distance * d.parallax * h : 0.0;
    final sunX = (w * light.at.dx + scroll) % extent;

    // How much of the sun's warmth reaches world x; the sun column sits at
    // the same local x in every copy of a repeating band.
    double gain(double x) {
      if (!tiled) return 0;
      var dx = (x - sunX) % extent;
      if (dx > extent / 2) dx -= extent;
      final q = dx / (h * .3);
      final g = 1 / (1 + q * q);
      return g * g;
    }

    // Items shrink away near the ends of a repeating band, so nothing is cut
    // by the next copy's water and everything is continuous across the seam.
    double edge(double x, double reach) {
      if (!tiled) return 1;
      final m = math.min(x, extent - x) / reach;
      return m >= 1 ? 1.0 : m * m * (3 - 2 * m);
    }

    double yAt(int j, double x) => _swellY(d, j, x / h, clock) * h;
    double liftAt(int j, double y) {
      final (off, amp, _, _, _, _, _) = rows[j];
      return (((base + off) * h - y) / (amp * h)).clamp(-1.3, 1.3);
    }

    final ys = [for (var j = 0; j < count; j++) List<double>.filled(n + 1, 0)];
    final lifts = [for (var j = 0; j < count; j++) List<double>.filled(n + 1, 0)];
    for (var j = 0; j < count; j++) {
      for (var i = 0; i <= n; i++) {
        final y = yAt(j, x0 + i * step);
        ys[j][i] = y;
        lifts[j][i] = liftAt(j, y);
      }
    }

    // Polygon between two edges given per sample.
    void band(Path p, int j, double Function(int) top, double Function(int) bottom) {
      final y = ys[j];
      p.moveTo(x0, y[0] + top(0));
      for (var i = 1; i <= n; i++) {
        p.lineTo(x0 + i * step, y[i] + top(i));
      }
      for (var i = n; i >= 0; i--) {
        p.lineTo(x0 + i * step, y[i] + bottom(i));
      }
      p.close();
    }

    // Row bodies, back to front: crest tone falling to the trough.
    final bottom = switch (d) {
      Depth.near => h + 2,
      Depth.low => h * .94,
      _ => h * .77,
    };
    _swellFill.color = Color.fromARGB((presence * 255).round().clamp(0, 255), 255, 255, 255);
    for (var j = 0; j < count; j++) {
      final y = ys[j];
      final body = Path()..moveTo(x0, y[0] - .5);
      for (var i = 0; i <= n; i++) {
        body.lineTo(x0 + i * step, y[i] - .5);
      }
      body
        ..lineTo(x0 + extent + 1.5, y[n] - .5)
        ..lineTo(x0 + extent + 1.5, bottom)
        ..lineTo(x0, bottom)
        ..close();
      _swellFill.shader = _swellShader(h, d, j);
      c.drawPath(body, _swellFill);
    }
    _swellFill.shader = null;

    // Shadow in front of each crest, then the crest strips in two steps.
    final shade = Path(), stripA = Path(), stripB = Path(), hot = Path();
    for (var j = tiled ? 0 : 1; j < count; j++) {
      final l = lifts[j];
      band(shade, j, (i) => -h * .008 * scale * (.8 + .35 * math.max(0.0, l[i])), (i) => 0);
    }
    for (var j = 0; j < count; j++) {
      final l = lifts[j];
      double a(int i) => h * (.0085 + .007 * math.max(0.0, l[i])) * scale;
      band(stripA, j, (i) => 0, a);
      band(stripB, j, (i) => 0, (i) => a(i) * .4);
      // The hot spot: warm light along the crest, thinning away from the sun.
      if (tiled) {
        var i = 0;
        while (i <= n) {
          if (gain(i * step) < .05) {
            i++;
            continue;
          }
          final start = i;
          while (i <= n && gain(i * step) >= .05) {
            i++;
          }
          final end = i - 1;
          final y = ys[j];
          hot.moveTo(start * step, y[start]);
          for (var q = start + 1; q <= end; q++) {
            hot.lineTo(q * step, y[q]);
          }
          for (var q = end; q >= start; q--) {
            hot.lineTo(q * step, y[q] + a(q) * .45 * gain(q * step));
          }
          hot.close();
        }
      }
    }
    _swellFill.color = Sketch.fade(_swellDeep, .14 * presence);
    c.drawPath(shade, _swellFill);
    _swellFill.color = Sketch.fade(const Color(0xff8fe0dc), .26 * presence);
    c.drawPath(stripA, _swellFill);
    _swellFill.color = Sketch.fade(const Color(0xffeafbff), .3 * presence);
    c.drawPath(stripB, _swellFill);
    if (tiled) {
      _swellFill.color = Sketch.fade(_swellSun, .8 * presence);
      c.drawPath(hot, _swellFill);
    }

    // Foam and texture, riding each row's own wave.
    final hiCool = Path(), hiWarm = Path(), lens = Path(), lace = Path();
    final caps = Path(), drops = Path(), rippleLight = Path(), rippleDark = Path();
    for (var j = 0; j < count; j++) {
      final (_, _, len, speed, _, _, _) = rows[j];
      final drift = tiled ? clock * speed * len / _tau * h : 0.0;
      final seed = j * 977 + d.index * 131;
      final crestDy = h * .0012 * scale;

      final nHi = math.max(4, (extent / h / .19).round());
      for (var k = 0; k < nHi; k++) {
        final x = x0 + _swellItem(k, nHi, seed + 11, extent, drift);
        final y = yAt(j, x);
        final s = ((liftAt(j, y) - .05) * 1.5).clamp(0.0, 1.0) * edge(x, h * .14 * scale);
        if (s < .05) continue;
        final half = h * (.016 + .05 * Sketch.hash(seed + k * 7)) * scale * s;
        (gain(x) > .3 ? hiWarm : hiCool)
          ..moveTo(x - half, yAt(j, x - half) + crestDy)
          ..lineTo(x, y + crestDy)
          ..lineTo(x + half, yAt(j, x + half) + crestDy);
      }

      final nLens = math.max(2, (extent / h / .42).round());
      for (var k = 0; k < nLens; k++) {
        final x = x0 + _swellItem(k, nLens, seed + 31, extent, drift);
        final y = yAt(j, x);
        final s = ((liftAt(j, y) + .25) * 1.2).clamp(0.0, 1.0) * edge(x, h * .12 * scale);
        if (s < .05) continue;
        final r = Sketch.hash(seed + k * 5 + 3);
        final half = h * (.022 + .034 * r) * scale * s;
        final th = h * (.0024 + .0026 * r) * scale * s;
        final yc = y + h * (.007 + .008 * r) * scale;
        final slope = (yAt(j, x + half) - yAt(j, x - half)) / (2 * half);
        final a = Offset(x - half, yc - slope * half);
        final b = Offset(x + half, yc + slope * half);
        lens
          ..moveTo(a.dx, a.dy)
          ..quadraticBezierTo(x, yc - th * 2, b.dx, b.dy)
          ..quadraticBezierTo(x, yc + th * 2, a.dx, a.dy);
      }

      if (tiled && j < 2) {
        final nLace = d == Depth.near ? 3 : 2;
        for (var k = 0; k < nLace; k++) {
          final x = x0 + _swellItem(k, nLace, seed + 51, extent, drift);
          final s = ((liftAt(j, yAt(j, x)) - .1) * 1.4).clamp(0.0, 1.0) * edge(x, h * .2 * scale);
          if (s < .05) continue;
          final total = h * .2 * scale * s;
          final xs = x - total / 2, seg = total / 6;
          final dy = h * .011 * scale;
          final bump = h * .008 * scale * s * (.7 + .6 * Sketch.hash(seed + k));
          var px = xs, py = yAt(j, px) + dy;
          lace.moveTo(px, py);
          for (var m = 1; m <= 6; m++) {
            final nx = xs + m * seg, ny = yAt(j, nx) + dy;
            lace.quadraticBezierTo((px + nx) / 2, (py + ny) / 2 + bump, nx, ny);
            px = nx;
            py = ny;
          }
        }

        const nCap = 3;
        for (var k = 0; k < nCap; k++) {
          final x = x0 + _swellItem(k, nCap, seed + 91, extent, drift);
          final y = yAt(j, x);
          final s = ((liftAt(j, y) - .3) * 2).clamp(0.0, 1.0) * edge(x, h * .1 * scale);
          if (s < .05) continue;
          final r = Sketch.hash(seed + k * 3 + 1);
          final cw = h * (.03 + .03 * r) * scale * s, ch = h * .007 * scale * s;
          caps
            ..addOval(Rect.fromCenter(center: Offset(x, y + ch * .15), width: cw, height: ch))
            ..addOval(Rect.fromCenter(center: Offset(x - cw * .32, y + ch * .5), width: cw * .5, height: ch * .7))
            ..addOval(Rect.fromCenter(center: Offset(x + cw * .3, y + ch * .55), width: cw * .42, height: ch * .6));
          for (var m = 0; m < 3; m++) {
            final phase = (clock * .9 + r + m * .33) % 1;
            final rise = math.sin(phase * math.pi) * h * .02 * scale * s;
            drops.addOval(
              Rect.fromCircle(
                center: Offset(x + (m - 1) * cw * .35 + phase * h * .01, y - rise - ch * .4),
                radius: h * .0022 * scale * (1 - phase * .4),
              ),
            );
          }
        }
      }

      final nR = math.max(6, (extent / h / .17).round());
      for (var k = 0; k < nR; k++) {
        for (var pass = 0; pass < 2; pass++) {
          final x = x0 + _swellItem(k, nR, seed + 71 + pass * 211, extent, drift);
          final top = yAt(j, x);
          final low = j + 1 < count ? yAt(j + 1, x) : top + h * .06;
          final r = Sketch.hash(seed + k * 9 + pass * 401);
          final y = top + (low - top) * (.3 + .55 * r);
          final rl = h * (.008 + .022 * Sketch.hash(seed + k * 11 + pass * 77)) * scale * edge(x, h * .05 * scale);
          (pass == 0 ? rippleLight : rippleDark)
            ..moveTo(x - rl, y)
            ..lineTo(x + rl, y - rl * .06);
        }
      }
    }
    _swellInk.strokeWidth = math.max(.7, h * .0016 * scale);
    c.drawPath(rippleDark, _swellInk..color = Sketch.fade(_swellDeep, .2 * presence));
    c.drawPath(rippleLight, _swellInk..color = Sketch.fade(const Color(0xffeaf8ff), .3 * presence));
    _swellInk.strokeWidth = math.max(.7, h * .0022 * scale);
    c.drawPath(lace, _swellInk..color = Sketch.fade(_swellFoam, .5 * presence));
    _swellInk.strokeWidth = math.max(.8, h * .0028 * scale);
    c.drawPath(hiCool, _swellInk..color = Sketch.fade(const Color(0xffeafcff), .7 * presence));
    c.drawPath(hiWarm, _swellInk..color = Sketch.fade(_swellSun, .85 * presence));
    _swellFill.color = Sketch.fade(_swellFoam, .5 * presence);
    c.drawPath(lens, _swellFill);
    _swellFill.color = Sketch.fade(_swellFoam, .9 * presence);
    c.drawPath(caps, _swellFill);
    c.drawPath(drops, _swellFill);

    if (d == Depth.near) _swellBuoyFoam(c, f, presence);
    if (d == Depth.low) _swellFarBuoy(c, f, presence);
  }

  /// Foam hugging the near buoy's waterline, and ripples spreading from it.
  void _swellBuoyFoam(Canvas c, SceneFrame f, double presence) {
    final h = f.h, clock = f.clock;
    final (dy, _) = _swellBuoyRide(clock);
    final bx = h * _swellBuoyX;
    final wy = (ridge(Depth.near, _swellBuoyX, clock) + dy) * h;
    final foam = Path();
    for (final (dx, dyy, half) in const [(-.03, .002, .08), (.035, .004, .07), (0.0, .008, .05)]) {
      foam
        ..moveTo(bx + (dx - half) * h, wy + dyy * h)
        ..quadraticBezierTo(bx + dx * h, wy + (dyy - .006) * h, bx + (dx + half) * h, wy + dyy * h)
        ..quadraticBezierTo(bx + dx * h, wy + (dyy + .005) * h, bx + (dx - half) * h, wy + dyy * h);
    }
    _swellFill.shader = null;
    _swellFill.color = Sketch.fade(_swellFoam, .8 * presence);
    c.drawPath(foam, _swellFill);
    for (var k = 0; k < 2; k++) {
      final p = (clock * .35 + k * .5) % 1;
      final rx = h * (.05 + .07 * p);
      _swellInk
        ..strokeWidth = math.max(.7, h * .002)
        ..color = Sketch.fade(_swellFoam, .5 * (1 - p) * presence);
      c.drawOval(Rect.fromCenter(center: Offset(bx, wy + h * .014), width: rx * 2, height: rx * .3), _swellInk);
    }
  }

  /// A small distant buoy bobbing on the low swell.
  void _swellFarBuoy(Canvas c, SceneFrame f, double presence) {
    final h = f.h, clock = f.clock;
    const x = .85;
    final wy = (ridge(Depth.low, x, clock) + .011) * h;
    final s = h * .017;
    final tilt = .05 * math.sin(clock * 1.5 + 2);
    c.save();
    c.translate(x * h, wy + math.sin(clock * 1.9) * h * .002);
    c.rotate(tilt);
    _swellFill.shader = null;
    _swellFill.color = Sketch.fade(const Color(0xffc9443b), presence);
    c.drawPath(Sketch.poly([-.5, 0, -.3, -1, .3, -1, .5, 0], s: s), _swellFill);
    _swellFill.color = Sketch.fade(const Color(0xfff4eee6), presence);
    c.drawRect(Rect.fromLTRB(-s * .4, -s * .66, s * .4, -s * .4), _swellFill);
    _swellFill.color = Sketch.fade(const Color(0xff353646), presence);
    c.drawRect(Rect.fromLTRB(-s * .05, -s * 1.9, s * .05, -s), _swellFill);
    _swellFill.color = Sketch.fade(const Color(0xfffff0be), presence);
    c.drawCircle(Offset(0, -s * 1.95), s * .13, _swellFill);
    c.restore();
    _swellFill.color = Sketch.fade(_swellFoam, .8 * presence);
    c.drawOval(Rect.fromCenter(center: Offset(x * h, wy + h * .002), width: s * 1.7, height: s * .26), _swellFill);
  }
}
