import 'dart:math' as math;
import 'dart:ui';

import 'region_scene.dart';
import 'weather.dart';
import 'world_region.dart';

/// Paints the world tour behind gameplay: sky, light, four parallax bands and
/// weather, all from the replay clock.
///
/// A crossing is staged rather than faded. The palette and the light travel
/// together; each band then hands over in turn from the horizon forward. The
/// old band's landmarks sink behind its ridge, the ridge itself morphs into
/// the new region's terrain, and the new landmarks rise over it. Weather
/// hands over slot by slot. Reduced Motion keeps the bands still and fades
/// the landmarks in place instead.
///
/// A campaign level holds one region for minutes rather than one leg, so
/// its timed bands repeat (see [copies]) instead of drifting off their
/// composition; everything else paints exactly as on the tour.
abstract final class WorldBackdrop {
  /// Nominal flight speed, in viewport heights per second, for timed bands.
  static const cruise = .36;

  /// Crossing windows per depth, far first: the new region shows up on the
  /// horizon before it reaches the ground under the bird.
  static const _windows = [(0.0, .62), (.12, .74), (.26, .88), (.38, 1.0)];

  static void paint(Canvas c, SceneFrame f) {
    if (f.w <= 0 || f.h <= 0) return;
    final blend = f.blend;
    final a = RegionScene.of(blend.from);
    final b = RegionScene.of(blend.to);
    final crossing = blend.crossing;
    final horizon = crossing
        ? a.horizon + (b.horizon - a.horizon) * blend.stage(.1, .9)
        : a.horizon;
    _sky(c, f, blend.palette, horizon);
    _light(
      c,
      f,
      crossing ? SkyLight.lerp(a.light, b.light, blend.stage(0, 1)) : a.light,
    );
    final skyOut = crossing ? 1 - blend.stage(0, .6) : 1.0;
    final skyIn = crossing ? blend.stage(.4, 1) : 0.0;
    if (skyOut > 0) a.sky(c, f, skyOut);
    if (skyIn > 0) b.sky(c, f, skyIn);
    for (final d in Depth.values) {
      final (start, end) = _windows[d.index];
      final u = crossing ? ((blend.t - start) / (end - start)) : 0.0;
      _band(c, f, d, a, b, blend, u.clamp(0.0, 1.0));
      if (crossing && d.index < 2) {
        _veil(c, f, blend.palette.haze, horizon, math.sin(blend.t * math.pi));
      }
    }
    Weather.paint(c, f, a.weather, b.weather, blend.t);
  }

  /// [region] as a campaign level shows it, [seconds] into the flight, for
  /// a map stop or a postcard. By default it is the calm still a level opens
  /// on, the same picture the tour composes for the region under Reduced
  /// Motion; with [reducedMotion] off, the bands have drifted and the flight
  /// has covered ground at cruising speed.
  static void still(
    Canvas c,
    Size size,
    WorldRegion region, {
    double seconds = 0,
    bool reducedMotion = true,
  }) => paint(
    c,
    SceneFrame(
      size,
      seconds: seconds,
      distance: seconds * cruise,
      reducedMotion: reducedMotion,
      region: region,
    ),
  );

  static double _scroll(Depth d, SceneFrame f, double start) {
    if (f.reducedMotion) return 0;
    return d.timed
        ? (f.seconds - start) * cruise * d.parallax * f.h
        : f.distance * d.parallax * f.h;
  }

  /// How far timed band [d] of [region] has drifted left, in pixels: from
  /// the start of the region's leg, or of a campaign level.
  static double drift(SceneFrame f, Depth d, WorldRegion region) =>
      _scroll(d, f, f.blend.startOf(region));

  /// The copies of timed band [d] that can show: how far right of the
  /// composition each stands, and the screen x it shows between, in
  /// pixels. The tour shows the one composition everywhere; a held region
  /// repeats it, so a painter that follows the band from outside it (a
  /// reflection in the water) draws once per copy, inside its stretch.
  static Iterable<BandCopy> copies(SceneFrame f, Depth d) sync* {
    final region = f.region;
    if (region == null || !d.timed) {
      yield (shift: 0, from: double.negativeInfinity, to: double.infinity);
      return;
    }
    final r = _Repeat(RegionScene.of(region), d, f, drift(f, d, region));
    for (final k in r.copies) {
      final left = k * r.period - r.scroll;
      yield (shift: k * r.period, from: left + r.start, to: left + r.end);
    }
  }

  static void _band(
    Canvas c,
    SceneFrame f,
    Depth d,
    RegionScene a,
    RegionScene b,
    RegionBlend blend,
    double u,
  ) {
    final smooth = RegionBlend.smooth;
    final still = f.reducedMotion;
    // Old landmarks start sinking first and the ridge morphs under them;
    // the new landmarks rise while the last of the old ones go down, so the
    // band is never left empty.
    final morph = smooth((u - .18) / .6);
    final out = still ? morph : smooth(u / .52);
    final rise = still ? morph : smooth((u - .3) / .62);
    final scrollA = _scroll(d, f, blend.startOf(a.region));
    final scrollB = _scroll(d, f, blend.startOf(b.region));
    if (blend.held && d.timed) {
      _held(c, f, d, _Repeat(a, d, f, scrollA));
      return;
    }
    if (out < 1) _features(c, f, a, d, scrollA, 1 - out);
    if (rise > 0) _features(c, f, b, d, scrollB, rise);
    _ridge(c, f, d, a, b, morph, scrollA, scrollB);
    if (morph < 1) _overlay(c, f, a, d, scrollA, 1 - morph);
    if (morph > 0) _overlay(c, f, b, d, scrollB, morph);
    if (d == Depth.low) {
      if (morph < 1) a.reflect(c, f, 1 - morph);
      if (morph > 0) b.reflect(c, f, morph);
    }
  }

  static void _features(
    Canvas c,
    SceneFrame f,
    RegionScene s,
    Depth d,
    double scroll,
    double presence,
  ) {
    final picture = _picture(s, d, f.size);
    final fading = f.reducedMotion && presence < 1;
    // Rising features decelerate into place; sinking ones accelerate away.
    final drop = f.reducedMotion
        ? 0.0
        : s.sink(d) * f.h * (1 - presence) * (1 - presence * .35);
    if (fading) {
      c.saveLayer(
        Offset.zero & f.size,
        Paint()..color = Color.fromRGBO(0, 0, 0, presence),
      );
    }
    if (d.timed) {
      c.save();
      c.translate(-scroll, drop);
      c.drawPicture(picture);
      s.live(c, d, f, 0);
      c.restore();
    } else {
      final span = s.period(d) * f.h;
      for (final k in _copies(scroll, span, f)) {
        c.save();
        c.translate(k * span - scroll, drop);
        c.drawPicture(picture);
        s.live(c, d, f, k);
        c.restore();
      }
    }
    if (fading) c.restore();
  }

  static void _overlay(
    Canvas c,
    SceneFrame f,
    RegionScene s,
    Depth d,
    double scroll,
    double presence,
  ) {
    if (d.timed) {
      c.save();
      c.translate(-scroll, 0);
      s.overlay(c, d, f, presence);
      c.restore();
      return;
    }
    final span = s.period(d) * f.h;
    for (final k in _copies(scroll, span, f)) {
      c.save();
      c.translate(k * span - scroll, 0);
      s.overlay(c, d, f, presence);
      c.restore();
    }
  }

  /// Repeats of a distance-scrolled band that can reach the viewport. A
  /// copy may spill up to half a viewport height past its own period (a palm
  /// frond, a moored boat), so neighbours that close stay in.
  static Iterable<int> _copies(double scroll, double span, SceneFrame f) sync* {
    final spill = f.h * .5;
    for (
      var k = (scroll / span).floor() - 1;
      k * span - scroll < f.w + spill;
      k++
    ) {
      if (k * span - scroll + span + spill > 0) yield k;
    }
  }

  static final _ridgePaint = Paint();
  static final _rimPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeJoin = StrokeJoin.round;

  static void _ridge(
    Canvas c,
    SceneFrame f,
    Depth d,
    RegionScene a,
    RegionScene b,
    double morph,
    double scrollA,
    double scrollB,
  ) {
    final w = f.w, h = f.h;
    // About 7 px between samples keeps crests smooth at phone size.
    final step = math.max(4.0, w / 140);
    final line = Path();
    var top = h * 2;
    for (var x = 0.0; ; x += step) {
      final sx = math.min(x, w);
      var y = morph >= 1 ? 0.0 : a.ridge(d, (sx + scrollA) / h, f.clock);
      if (morph > 0) {
        final yb = b.ridge(d, (sx + scrollB) / h, f.clock);
        y = morph >= 1 ? yb : y + (yb - y) * morph;
      }
      final py = math.min(y, 1.05) * h;
      top = math.min(top, py);
      if (x == 0) {
        line.moveTo(sx, py);
      } else {
        line.lineTo(sx, py);
      }
      if (sx >= w) break;
    }
    if (top >= h) return;
    _fill(c, f, line, top, Ground.lerp(a.ground(d), b.ground(d), morph));
  }

  static void _fill(
    Canvas c,
    SceneFrame f,
    Path line,
    double top,
    Ground ground,
  ) {
    final w = f.w, h = f.h;
    final fill = Path.from(line)
      ..lineTo(w, h + 2)
      ..lineTo(0, h + 2)
      ..close();
    _ridgePaint.shader = Gradient.linear(Offset(0, top), Offset(0, h), [
      ground.top,
      ground.bottom,
    ]);
    c.drawPath(fill, _ridgePaint);
    if (ground.rimWidth > 0 && ground.rim.a > 0) {
      _rimPaint
        ..strokeWidth = ground.rimWidth * h
        ..color = ground.rim;
      c.drawPath(line, _rimPaint);
    }
  }

  static void _sky(Canvas c, SceneFrame f, SkyPalette p, double horizon) {
    c.drawRect(
      Offset.zero & f.size,
      Paint()
        ..shader = Gradient.linear(
          Offset.zero,
          Offset(0, f.h),
          [
            p.top,
            Color.lerp(p.top, p.horizon, .42)!,
            p.horizon,
            Color.lerp(p.horizon, p.haze, .7)!,
          ],
          [0, horizon * .52, horizon, 1],
        ),
    );
  }

  static void _light(Canvas c, SceneFrame f, SkyLight l) {
    final at = Offset(l.at.dx * f.w, l.at.dy * f.h);
    final halo = l.halo * f.h;
    c.drawCircle(
      at,
      halo,
      Paint()
        ..shader = Gradient.radial(
          at,
          halo,
          [
            Sketch.fade(l.glow, l.strength),
            Sketch.fade(l.glow, l.strength * .32),
            Sketch.fade(l.glow, 0),
          ],
          const [0, .38, 1],
        ),
    );
    final r = l.radius * f.h;
    c.drawCircle(at, r * 1.18, Paint()..color = Sketch.fade(l.disc, .35));
    c.drawCircle(at, r, Paint()..color = l.disc);
    if (l.moon > .05) {
      // Soft maria give the moon a face without a crescent path operation;
      // they only surface once the light is mostly moon.
      final mare = Paint()
        ..color = Sketch.fade(const Color(0xffb9bfd6), .55 * l.moon * l.moon);
      for (final (dx, dy, s) in const [
        (-.28, -.12, .3),
        (.2, .18, .22),
        (.1, -.34, .14),
        (-.08, .36, .12),
      ]) {
        c.drawCircle(at + Offset(dx * r, dy * r), s * r, mare);
      }
    }
  }

  /// A haze bank across the horizon while bands are handing over.
  static void _veil(
    Canvas c,
    SceneFrame f,
    Color haze,
    double horizon,
    double strength,
  ) {
    if (strength <= .01) return;
    final top = (horizon - .2) * f.h, bottom = (horizon + .16) * f.h;
    c.drawRect(
      Rect.fromLTRB(0, top, f.w, bottom),
      Paint()
        ..shader = Gradient.linear(
          Offset(0, top),
          Offset(0, bottom),
          [
            Sketch.fade(haze, 0),
            Sketch.fade(haze, .26 * strength),
            Sketch.fade(haze, 0),
          ],
          const [0, .62, 1],
        ),
    );
  }

  /// A held region's timed band, copy by copy: features and their live
  /// motion behind the ridge, the ridge, then the overlay.
  static void _held(Canvas c, SceneFrame f, Depth d, _Repeat r) {
    final s = r.scene;
    final picture = _picture(s, d, f.size);
    for (final k in r.copies) {
      final shift = k * r.period, frame = f.shifted(shift);
      r.paint(c, f, k, () {
        c.translate(shift - r.scroll, 0);
        c.drawPicture(picture);
        s.live(c, d, frame, k);
      });
    }
    final step = math.max(4.0, f.w / 140);
    final line = Path();
    var top = f.h * 2;
    for (var x = 0.0; ; x += step) {
      final sx = math.min(x, f.w);
      final py = math.min(r.ridge(sx, f.clock), 1.05) * f.h;
      top = math.min(top, py);
      if (x == 0) {
        line.moveTo(sx, py);
      } else {
        line.lineTo(sx, py);
      }
      if (sx >= f.w) break;
    }
    if (top < f.h) _fill(c, f, line, top, s.ground(d));
    for (final k in r.copies) {
      final shift = k * r.period, frame = f.shifted(shift);
      r.paint(c, f, k, () {
        c.translate(shift - r.scroll, 0);
        s.overlay(c, d, frame, 1);
      });
    }
  }

  static final _pictures = <(WorldRegion, Depth, double, double), Picture>{};

  /// Features are static per viewport, so each band is recorded once.
  static Picture _picture(RegionScene s, Depth d, Size size) {
    final key = (s.region, d, size.width, size.height);
    final cached = _pictures.remove(key);
    if (cached != null) return _pictures[key] = cached;
    final recorder = PictureRecorder();
    s.features(Canvas(recorder), d, size);
    final picture = recorder.endRecording();
    _pictures[key] = picture;
    if (_pictures.length > 48) {
      _pictures.remove(_pictures.keys.first)!.dispose();
    }
    return picture;
  }
}

/// One copy of a held region's timed band on screen: [shift] pixels right
/// of the composition, showing between screen x [from] and [to].
typedef BandCopy = ({double shift, double from, double to});

/// A held region's timed band repeated along the flight. Copy k is the
/// band's composition from [start] to [end] (see [RegionScene.span]), laid
/// [period] further right than copy k - 1 so the two overlap by [seam].
/// Across that overlap the old copy thins into the haze as the new one
/// rises out of it, and the ridge follows whichever copy stands higher, so
/// neither copy's landmarks float above it. Copy 0 opens the level exactly
/// as the tour composes the band.
class _Repeat {
  _Repeat(this.scene, this.d, SceneFrame f, this.scroll) : h = f.h {
    final (a, b) = scene.span(d, f.size);
    start = a;
    // The first seam must not show at the start of a level.
    end = math.max(b, f.w + (_seam + _ramp) * h);
    period = end - start - seam;
    // A copy's ridge reaches a little past its stretch, so it counts from
    // just before it comes on screen until just after it has gone.
    final reach = _ramp * h;
    final first = math.max(0, ((scroll - end - reach) / period).ceil());
    copies = [
      for (var k = first; k * period + start - reach - scroll < f.w; k++) k,
    ];
  }

  /// The overlap, and how far past its own stretch a copy's ridge still
  /// leans on the line, in viewport heights.
  static const _seam = .35, _ramp = .2;

  /// Opacity across the overlap: the new copy is mostly in before the old
  /// one thins, so little sky shows through either.
  static const _rising = [
    Color(0x00000000),
    Color(0x8c000000),
    Color(0xff000000),
    Color(0xff000000),
  ];
  static const _thinning = [
    Color(0xff000000),
    Color(0xff000000),
    Color(0x73000000),
    Color(0x00000000),
  ];

  final RegionScene scene;
  final Depth d;
  final double scroll, h;
  late final double start, end, period;
  late final List<int> copies;
  double get seam => _seam * h;

  /// Paints copy [k] with [draw]: rising across the overlap with the copy
  /// before, solid, then thinning across the overlap with the next.
  void paint(Canvas c, SceneFrame f, int k, void Function() draw) {
    final left = k * period - scroll;
    final from = left + start, to = left + end;
    final solidFrom = k == 0 ? from : from + seam;
    final solid = Rect.fromLTRB(
      math.max(solidFrom, 0),
      0,
      math.min(to - seam, f.w),
      f.h,
    );
    if (solid.width > 0) {
      c.save();
      c.clipRect(solid);
      draw();
      c.restore();
    }
    if (k > 0) {
      _fade(c, f, from, from + seam, _rising, const [0, .3, .65, 1], draw);
    }
    _fade(c, f, to - seam, to, _thinning, const [0, .35, .7, 1], draw);
  }

  static void _fade(
    Canvas c,
    SceneFrame f,
    double from,
    double to,
    List<Color> mask,
    List<double> stops,
    void Function() draw,
  ) {
    final zone = Rect.fromLTRB(math.max(from, 0), 0, math.min(to, f.w), f.h);
    if (zone.width <= 0) return;
    c.save();
    c.clipRect(zone);
    c.saveLayer(zone, Paint());
    c.save();
    draw();
    c.restore();
    c.drawRect(
      zone,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = Gradient.linear(Offset(from, 0), Offset(to, 0), mask, stops),
    );
    c.restore();
    c.restore();
  }

  /// Ridge height at screen x, in viewport heights: the highest copy that
  /// stands there, each leaning out gently past its own stretch.
  double ridge(double sx, double clock) {
    var y = double.infinity;
    final ramp = _ramp * h;
    for (final k in copies) {
      final left = k * period - scroll;
      final from = left + start, to = left + end;
      if (sx > to + ramp || (k > 0 && sx < from - ramp)) continue;
      final lean =
          (k > 0 ? RegionBlend.smooth((from - sx) / ramp) : 0) +
          RegionBlend.smooth((sx - to) / ramp);
      y = math.min(y, scene.ridge(d, (sx - left) / h, clock) + lean * 2);
    }
    return y;
  }
}
