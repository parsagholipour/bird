import 'dart:math' as math;

import 'package:flutter/painting.dart';

import 'dragon_body_art.dart';
import 'dragon_head_art.dart';
import 'dragon_kit.dart';
import 'dragon_layout.dart';

/// The Ember Dragon's hide: torso, neck, head, tail and near legs painted as
/// ONE creature instead of parts laid over each other.
///
/// The joints used to show: every part had its own ink outline and its own
/// fill, so where the neck met the head, the chest, the thigh and the tail
/// you saw borders, and the dragon read as assembled plush parts. Here the
/// parts share ONE outline, ONE skin and ONE light:
///
///  * **Outline.** Every part of the trunk is laid in one path (they all wind
///    the same way, so it fills and clips as their union). It is stroked once
///    in ink, thick, BEFORE anything is filled; the skin is painted over it
///    afterwards and buries every stroke that lies inside the union, so only
///    the outer edge keeps its ink. No union is ever computed (`Path.combine`
///    costs more than the whole rest of the dragon's frame): the painter's
///    order does the merge. The stroke is shifted toward the shade side, so
///    the line is full weight on the lower right and ~0.6 on the lit side,
///    as the bible's line-weight system asks.
///  * **Skin and light.** One skin gradient in rig space, so neighbouring
///    parts match wherever they meet. The sky's rim light and the fire's
///    warm bounce are crescents made by shifting that same union: three
///    fills inside the trunk, a rim-coloured one in full, a fire-coloured
///    one carried a little toward the shade side and the skin's gradient
///    carried back toward the light; what each leaves uncovered along the
///    edges is the crescent. Only the last is a gradient (the crescents are
///    slivers of one colour), and only the first clip needs anti-aliasing
///    (the nested ones cut inside the outline). They follow the true outer
///    silhouette across every joint and never show an inner border. On a
///    dark sky a thin lilac rim is laid under the ink on the lit edges, so
///    the body's edge holds where plum and backdrop are close in value.
///  * **Detail.** Scale rows, the banded belly (one strip from the chin to
///    the tail) and the molten seams are clipped to the union and run on
///    across the joints.
///  * **Limbs.** The near legs stand in front, opaque, with their own form.
///    Their contour is a heavy line where they stand against the sky and
///    melts into a fine one where they lie on the trunk.
///
/// Built once a frame from the body and head poses.
final class DragonHide {
  DragonHide(DragonBodyPose body, DragonHeadPose head)
    : this._(body.finite, head);

  DragonHide._(this.body, this.head)
    : torso = DragonBodyArt.torsoOf(body),
      neck = DragonHeadArt.neckOf(head),
      tail = DragonBodyArt.tailOf(body),
      skull = DragonHeadArt.skullAt(head),
      jaw = DragonHeadArt.jawAt(head),
      hind = DragonBodyArt.legOf(body, hind: true, far: false),
      fore = DragonBodyArt.legOf(body, hind: false, far: false) {
    trunk = Path()
      ..addPath(torso, Offset.zero)
      ..addPath(neck.path, Offset.zero)
      ..addPath(tail.shape, Offset.zero)
      ..addPath(skull, Offset.zero)
      ..addPath(jaw, Offset.zero);
  }

  final DragonBodyPose body;
  final DragonHeadPose head;
  final Path torso, skull, jaw;
  final DragonNeck neck;
  final DragonTail tail;
  final DragonLeg hind, fore;

  /// Torso, neck, tail, skull and jaw laid together: filled and clipped, it
  /// is their union.
  late final Path trunk;

  static const _ink = DragonPalette.ink;

  /// The ink stroke is centred on the trunk's edge but the skin covers its
  /// inner half, so the visible line is HALF this wide, then shifted toward
  /// the lower right (the shade side): ~.065 on the lit edges to ~.10 on the
  /// shade ones, the bible's hero weight (.105) with its modulation.
  static const _inkHalf = .082;
  static const _inkShift = Offset(.013, .018);
  static final Paint _inkStroke = DragonKit.line(_ink, _inkHalf * 2);

  /// The crescents' shifts: how far the skin is carried toward the shade side
  /// (leaving the sky's rim on the lit edges) and toward the lit side (leaving
  /// the fire's bounce on the undersides).
  static const _rimShift = Offset(.04, .055);
  static const _fireShift = Offset(.02, .06);

  /// The plates of the belly band are this long: few and broad, so the band
  /// reads as one warm ribbon with a grain, not a ladder.
  static const _plate = .3;

  /// Draws everything but the foreleg (which stands in front of the
  /// breastplate, so the rig paints it after the heart): what lies behind the
  /// skin, the outline, the skin and its light, the detail, the hind leg and
  /// the head's features.
  void paint(Canvas c) {
    final tone = body.tone;
    // Behind the skin: the tail's spines and blade, the neck's crest spines,
    // the horns, frill and cheek spike, the mouth's inside and lower fangs.
    // The skin buries their roots, so they grow out of it.
    DragonBodyArt.tailUnder(c, body, tail);
    DragonHeadArt.neckSpikes(c, tone, neck);
    DragonHeadArt.headUnder(c, head);

    // The outline, before the skin. On a dark sky the body's own edge cannot
    // hold against the backdrop (the plum is only 12-20 L* under it, and the
    // ink barely more), so the lit upper edge gets a thin lilac rim laid under
    // the ink: it is a stroke a little wider than the ink and carried toward
    // the light, so on the lit sides its outer edge shows past the ink as a
    // line ~.05 wide (2 px at phone size), and on the shade sides the ink covers it entirely.
    final dark = ((body.tone.dark - .5) * 2).clamp(0.0, 1.0);
    if (dark > 0) {
      final t = body.tone;
      c
        ..save()
        ..translate(-_inkShift.dx, -_inkShift.dy)
        ..drawPath(
          trunk,
          DragonKit.line(
            t.lit(Color.lerp(t.sky, DragonPalette.rimSky, .6)!),
            .18,
            .85 * dark,
          ),
        )
        ..restore();
    }
    c
      ..save()
      ..translate(_inkShift.dx, _inkShift.dy)
      ..drawPath(trunk, _inkStroke)
      ..restore();

    // The skin and its light, then the detail: all inside the union.
    c.save();
    c.clipPath(trunk);
    _skin(c);
    _tailCuff(c);
    _detail(c);
    c.restore();

    DragonBodyArt.legPaint(
      c,
      body,
      hind,
      hide: true,
      depth: _depth,
      fill: _legSkin(),
    );
    DragonHeadArt.headFeatures(c, head);
  }

  /// The near foreleg, in front of the breastplate.
  void paintForeleg(Canvas c) => DragonBodyArt.legPaint(
    c,
    body,
    fore,
    hide: true,
    depth: _depth,
    fill: _legSkin(),
  );

  // -------------------------------------------------------------- skin --

  /// The skin, lit from above and the upper left, in rig space: brightest at
  /// the head and neck, plum on the chest, deep on the haunch, darkest at the
  /// tail's tip.
  static const _skinAt = Offset(-1.2, -1.5);
  static const _skinRadius = 6.4;
  static const _skinStops = [0.0, .18, .34, .62, .85, 1.0];

  static List<Color> _skinColors(DragonTone t) {
    Color pl(Color c) => t.plate(c);
    return [
      pl(Color.lerp(DragonPalette.scaleLit, DragonPalette.scaleSheen, .06)!),
      pl(Color.lerp(DragonPalette.scaleLit, DragonPalette.scale, .3)!),
      pl(Color.lerp(DragonPalette.scale, DragonPalette.scaleLit, .2)!),
      pl(DragonPalette.scaleDeep),
      pl(Color.lerp(DragonPalette.scaleDeep, DragonPalette.scaleDark, .5)!),
      pl(DragonPalette.scaleDark),
    ];
  }

  static Color _rimSky(DragonTone t) => t.flash > .35
      ? Color.lerp(
          t.lit(t.sky),
          DragonPalette.white,
          ((t.flash - .35) / .2).clamp(0.0, 1.0),
        )!
      : t.lit(t.sky);

  /// The hide's tone-keyed paints. Least-recently-used, so a step in the tone
  /// (each heat step of the inhale, each darkness step of the sky) costs one
  /// entry's shaders and never rebuilds the lot in a single frame; bounded, so
  /// a long fight cannot grow it.
  static final DragonCache<Object, Paint> _paints = DragonCache(96);
  static Paint _cached(Object key, Paint Function() make) =>
      _paints.get(key, make);

  /// How many paints the hide holds (for the cache-bound test).
  static int get cacheSize => _paints.length;

  static double _fin(double v) => v.isFinite ? v : 0;

  static Paint _skinPaint(List<Color> colors) =>
      DragonKit.radial(_skinAt, _skinRadius, colors, _skinStops);

  /// Lays the skin: everything is rim first; carried toward the shade side
  /// it leaves the fire's crescent under the undersides; carried back toward
  /// the lit side it leaves the sky's crescent along the upper edges.
  void _skin(Canvas c) {
    final t = DragonBodyArt.snap(body.tone);
    final base = _skinColors(t);
    final skin = _cached(('skin', t.key), () => _skinPaint(base));
    // The two crescents are slivers a few hundredths wide: their colour needs
    // no gradient along the body, so they are flat fills (a solid fill costs
    // a fraction of a shader's per-pixel work, and the skin's gradient is the
    // only one left of the three passes).
    final rimColor = _rimSky(t);
    final rimA = (t.skyRim * .8).clamp(0.0, 1.0);
    final fireColor = t.lit(DragonPalette.rimFire);
    final fireA = (t.fireRim * .6).clamp(0.0, 1.0);
    final rim = Paint()..color = Color.lerp(base[2], rimColor, rimA)!;
    final fire = Paint()..color = Color.lerp(base[3], fireColor, fireA)!;
    final area = _area;
    c.drawRect(area, rim);
    c.save();
    c.translate(_rimShift.dx, _rimShift.dy);
    c.clipPath(trunk, doAntiAlias: false);
    c.translate(-_rimShift.dx, -_rimShift.dy);
    c.drawRect(area, fire);
    c.save();
    c.translate(-_fireShift.dx, -_fireShift.dy);
    c.clipPath(trunk, doAntiAlias: false);
    c.translate(_fireShift.dx, _fireShift.dy);
    c.drawRect(area, skin);
    c.restore();
    c.restore();
  }

  /// The tail's last stretch in plain plum. The tail narrows to a few hundredths
  /// at its tip, where both crescents (the sky's on one side, the fire's on the
  /// other) meet across the whole width and read as a grey-brown patch: a cuff
  /// of the tail's own skin, fading in over the first sample, leaves them only
  /// the very edge.
  void _tailCuff(Canvas c) {
    final t = body.tone;
    final n = tail.spine.length, from = n - 5;
    final pts = <Offset>[], widths = <double>[];
    for (var i = from; i < n; i++) {
      pts.add(tail.spine[i]);
      final w = (tail.belly[i] - tail.dorsal[i]).distance;
      widths.add(w * .8 * ((i - from) / 1.5).clamp(0.0, 1.0));
    }
    // ...and over the tip's rounded end.
    pts.add(tail.end + tail.endDir * (widths.last * .5));
    widths.add(widths.last * .6);
    c.drawPath(
      DragonKit.ribbon(pts, widths),
      DragonKit.fill(t.plate(DragonPalette.scaleDark)),
    );
  }

  /// The trunk's box with a margin: the passes fill no more than they must.
  late final Rect _area = trunk.getBounds().inflate(.3);

  /// The limbs wear the same skin, a step lighter (they stand in front of the
  /// body and catch the sky), so a thigh reads as a form on the haunch and
  /// not as another creature's part.
  Paint _legSkin() {
    final t = DragonBodyArt.snap(body.tone);
    return _cached(
      ('leg', t.key),
      () => _skinPaint([
        for (final s in _skinColors(t))
          Color.lerp(s, t.plate(DragonPalette.scaleLit), .3)!,
      ]),
    );
  }

  // ------------------------------------------------------------ detail --

  void _detail(Canvas c) {
    final tone = body.tone;
    DragonBodyArt.torsoDetails(c, body);
    _rows(c);
    // The neck's core shade down its crest side, fading out at both ends.
    final crest = neck.along(.72, from: 1.2, to: 7.2);
    c.drawPath(
      DragonKit.ribbon(
        crest,
        DragonKit.taper(crest.length, .26, head: .3, tail: .35),
      ),
      DragonKit.fill(DragonPalette.scaleCore, .28),
    );
    // The wing's shoulder plate presses on the back.
    DragonBodyArt.contactRing(c, DragonLayout.nearShoulder, .95);
    DragonHeadArt.jawShade(c, head);
    DragonHeadArt.skullDetails(c, head);
    _band(c, tone);
  }

  // ------------------------------------------------------- scale rows --

  /// Scale rows on the neck and the tail, in the torso's own vocabulary: dark
  /// arcs with a lit lip, bulging toward the tail, the pitch shrinking toward
  /// the head and the tip (foreshortening). They begin where the tube leaves
  /// the torso, whose rows they meet.
  void _rows(Canvas c) {
    final tone = body.tone;
    final path = Path();
    DragonKit.tubeRows(
      path,
      (u) {
        final i = u.floor().clamp(0, 7), t = u - i;
        return (
          centre: Offset.lerp(neck.spine[i], neck.spine[i + 1], t)!,
          normal: DragonKit.unit(Offset.lerp(neck.nrm[i], neck.nrm[i + 1], t)!),
          plus: DragonKit.mix(neck.plus[i], neck.plus[i + 1], t),
          minus: DragonKit.mix(neck.minus[i], neck.minus[i + 1], t),
        );
      },
      from: 1.5,
      to: 7.0,
      pitchFrom: .24,
      pitchTo: .15,
      bulge: -1,
    );
    final n = tail.spine.length;
    DragonKit.tubeRows(
      path,
      (u) {
        final i = u.floor().clamp(0, n - 2), t = u - i;
        final d = DragonKit.unit(
          Offset.lerp(tail.dirs[i], tail.dirs[i + 1], t)!,
        );
        final w =
            DragonKit.mix(
              (tail.belly[i] - tail.dorsal[i]).distance,
              (tail.belly[i + 1] - tail.dorsal[i + 1]).distance,
              t,
            ) /
            2;
        // (the belly is the +normal side)
        return (
          centre: Offset.lerp(tail.spine[i], tail.spine[i + 1], t)!,
          normal: Offset(-d.dy, d.dx),
          plus: w,
          minus: w,
        );
      },
      from: 3.4,
      to: 10.2,
      pitchFrom: .22,
      pitchTo: .13,
      bulge: 1,
    );
    c.drawPath(
      path.shift(const Offset(0, -.05)),
      DragonKit.line(tone.plate(DragonPalette.scaleLit), .05, .55),
    );
    c.drawPath(path, DragonBodyArt.rowsPaint(tone));
  }

  // ------------------------------------------------------------- belly --

  /// The banded belly: ONE strip of amber plates from the chin, down the
  /// throat, under the chest and belly and along the tail to its tip. Its
  /// outer edge lies past the silhouette (the clip trims it), so only the
  /// inner edge shows, and that runs unbroken through every joint.
  void _band(Canvas c, DragonTone tone) {
    final outer = <Offset>[], inner = <Offset>[];
    // The chin and the jaw's belly.
    final (jo, ji) = DragonHeadArt.jawBandEdges(head);
    outer.addAll(jo.sublist(0, jo.length - 1));
    inner.addAll(ji.sublist(0, ji.length - 1));
    // Down the throat, until the neck runs into the chest. The band is .23
    // wide inside the throat edge (.17: the belly is the largest bright shape
    // and must not out-shout the face), the same across the jaw's corner, where
    // the two inner edges meet in a mitre (the corner is a notch in the
    // silhouette; the plates turn it).
    final throat = neck.throatEdge;
    // The throat edge runs straight into the jaw's corner over its last
    // stretch: its inward normal there is the line's, not the samples'.
    final lineDir = DragonKit.unit(throat[16] - throat[13]);
    Offset inward(int i, Offset centre) {
      final Offset d;
      if (i >= 13) {
        d = lineDir;
      } else {
        d = DragonKit.unit(throat[i + 1] - throat[i - (i > 0 ? 1 : 0)]);
      }
      var n = Offset(-d.dy, d.dx);
      if ((centre - throat[i]).dx * n.dx + (centre - throat[i]).dy * n.dy < 0) {
        n = -n;
      }
      return n;
    }

    var last = 16;
    var kept = throat[16];
    var step = -lineDir;
    for (var i = 15; i >= 0; i--) {
      final pt = throat[i];
      if (_torsoDepth(pt) > .02) break;
      // A neck folded by a low strike doubles back on itself: the strip
      // follows only what moves on (a sample that stays put or turns back
      // is skipped).
      final move = pt - kept;
      if (i != 15 &&
          (move.distance < .06 ||
              move.dx * step.dx + move.dy * step.dy < .2 * move.distance)) {
        continue;
      }
      if (i != 15) {
        step = DragonKit.unit(move);
      }
      kept = pt;
      final u = i / 2;
      final centre = neck.at(u, 0);
      final width = math.min(.17, neck.minus[u.floor().clamp(0, 8)] * .9);
      // The strip's outer edge lies past the silhouette where the throat is
      // the silhouette; where the neck folds against the chest or under the
      // jaw the throat's edge is inside the body and the strip stops at it.
      final away = DragonKit.unit(pt - centre);
      final beyond = pt + away * .12;
      final exposed =
          _torsoDepth(beyond) < 0 &&
          !jaw.contains(beyond) &&
          (i < 11 || !skull.contains(beyond));
      outer.add(pt + away * (exposed ? .16 : 0));
      inner.add(pt + inward(i, centre) * width);
      if (i == 15) {
        // The mitre: the jaw's inner edge meets the throat's.
        final a0 = inner[inner.length - 2], a1 = inner[inner.length - 3];
        final da = a0 - a1, db = -lineDir;
        final cross = da.dx * db.dy - da.dy * db.dx;
        if (cross.abs() > 1e-6) {
          final w = inner.last - a0;
          final t = (w.dx * db.dy - w.dy * db.dx) / cross;
          final x = a0 + da * t;
          final p15 = inner.last;
          // The mitre lies ahead of the jaw's last sample and behind the
          // throat's first, and near both; otherwise the edges just join.
          if ((x - a0).dx * da.dx + (x - a0).dy * da.dy > 0 &&
              (p15 - x).dx * db.dx + (p15 - x).dy * db.dy > 0 &&
              (x - a0).distance < .9 &&
              (x - p15).distance < .5) {
            inner.insert(inner.length - 1, x);
            outer.insert(outer.length - 1, outer.last);
          }
        }
      }
      last = i;
    }
    final headEnd = outer.length;
    final from = throat[last];
    // Down the chest front, under the keel and up to the waist.
    final chest = _chestBand;
    var start = 0;
    var best = double.infinity;
    final local = Offset(
      from.dx / (1 + body.breath * .6),
      from.dy / (1 + body.breath),
    );
    for (var i = 0; i < chest.length; i++) {
      final d = (chest[i].$1 - local).distanceSquared;
      if (d < best) {
        best = d;
        start = i;
      }
    }
    // A head hung low over the chest folds the neck away: if the throat
    // never reaches the chest front, the strip starts afresh at the chest.
    final joined = best < .45 * .45;
    if (!joined) start = 0;
    final bodyFrom = outer.length;
    for (var i = start; i < chest.length; i++) {
      final (p, n, depth) = chest[i];
      outer.add(DragonBodyArt.swell(body, p - n * .18));
      inner.add(DragonBodyArt.swell(body, p + n * depth));
    }
    // Along the underside of the tail to its tip.
    final tailFrom = inner.length;
    final count = tail.spine.length;
    for (var i = 2; i <= 10; i++) {
      final e = tail.belly[i];
      outer.add(e + DragonKit.unit(e - tail.spine[i]) * .14);
      // (the plates thin to nothing by the tenth sample of the tail)
      final frac =
          .58 *
          (1 - .45 * i / (count - 1)) *
          (i > 8 ? math.max(0.0, (10 - i) / 2) : 1.0);
      inner.add(Offset.lerp(e, tail.spine[i], frac)!);
    }

    // The strip is painted in parts: the chin's (in front) and the rest,
    // which the open jaw hides where it hangs over the throat.
    final firstNeck = ji.length; // (six jaw points and the mitre)
    final chinEnd = math.min(firstNeck, headEnd);
    final covered = _jawCovers(
      outer,
      inner,
      math.min(chinEnd, headEnd),
      math.min(headEnd + 3, inner.length),
    );
    var next = .06;
    void part(int a, int b, {int? tailFrom, bool smooth = false}) => _bandPart(
      c,
      tone,
      outer,
      inner,
      a,
      b,
      () => next,
      (v) => next = v,
      headEnd,
      jo.first,
      from,
      tailFrom: tailFrom,
      smoothOuter: smooth,
    );

    part(0, chinEnd, smooth: true);
    final restFrom = math.max(0, firstNeck - 1);
    if (covered) {
      c
        ..save()
        ..clipPath(DragonKit.outside(jaw));
    }
    if (headEnd > restFrom + 1) {
      if (joined) {
        part(restFrom, outer.length, tailFrom: tailFrom);
      } else {
        // (the neck's part, then the chest's on its own)
        part(restFrom, headEnd);
        part(bodyFrom, outer.length, tailFrom: tailFrom);
      }
    } else {
      part(bodyFrom, outer.length, tailFrom: tailFrom);
    }
    if (covered) {
      // The jaw hangs over the throat with no line of ink to say so: it casts
      // a soft shade on it along its belly.
      c.drawPath(
        DragonKit.spline(jo, closed: false),
        DragonKit.line(DragonPalette.scaleCore, .2, .42),
      );
      c.restore();
    }
    // One hard pill of white on the belly's swell, the roster's shine (only
    // when the strip runs under the chest: a head hung low may not).
    if (start <= _glintAt) {
      final (p0, n0, d0) = chest[_glintAt];
      final (p1, n1, d1) = chest[_glintAt + 1];
      c.drawPath(
        Path()
          ..moveTo(
            DragonBodyArt.swell(body, p0 + n0 * d0 * .5).dx,
            DragonBodyArt.swell(body, p0 + n0 * d0 * .5).dy,
          )
          ..lineTo(
            DragonBodyArt.swell(body, p1 + n1 * d1 * .5).dx,
            DragonBodyArt.swell(body, p1 + n1 * d1 * .5).dy,
          ),
        DragonKit.line(tone.lit(DragonPalette.white), .06, .65),
      );
    }
  }

  /// The chest band's sample the belly's glint starts at (the keel's chest
  /// side).
  static const _glintAt = 17;

  /// Whether the open jaw lies over the throat's part of the strip.
  bool _jawCovers(List<Offset> outer, List<Offset> inner, int from, int to) {
    // (a few samples of the strip's inner edge tell)
    for (var i = from; i < to; i += 3) {
      if (jaw.contains(inner[i])) return true;
    }
    return false;
  }

  /// One part of the strip, points [a] .. [b) of the two edges: the plates,
  /// the violet of the swarm call over the chin and throat (points before
  /// [headEnd]), the fire rising in the throat, the seams across it and the
  /// molten light along its edge (brighter past [tailFrom]).
  void _bandPart(
    Canvas c,
    DragonTone tone,
    List<Offset> outer,
    List<Offset> inner,
    int a,
    int b,
    double Function() carry,
    void Function(double) setCarry,
    int headEnd,
    Offset chin,
    Offset throatEnd, {
    int? tailFrom,
    bool smoothOuter = false,
  }) {
    if (b - a < 2) return;
    final oa = outer.sublist(a, b), ia = inner.sublist(a, b);
    final m = oa.length;
    // The outer edge lies past the silhouette (the clip trims it), so it is
    // laid straight; only the inner edge is a smooth curve, and the one curve
    // serves the band, its edge line and its molten seam. (The chin's outer
    // edge IS the jaw's contour, which an open jaw shows over the throat:
    // that one is smooth too.)
    final edge = DragonKit.spline(ia.reversed.toList(), closed: false);
    final band = smoothOuter
        ? DragonKit.spline(oa, closed: false)
        : (Path()..moveTo(oa.first.dx, oa.first.dy));
    if (!smoothOuter) {
      for (var i = 1; i < m; i++) {
        band.lineTo(oa[i].dx, oa[i].dy);
      }
    }
    band
      ..extendWithPath(edge, Offset.zero)
      ..close();
    // (Built from the snapped tone and a quarter-stepped heat, the very values
    // the key names, so the cached paint never depends on which frame came
    // first.)
    final st = DragonBodyArt.snap(tone);
    final heat = ((_fin(tone.heat).clamp(0.0, 1.0)) * 4).round() / 4;
    c.drawPath(
      band,
      _cached(
        ('band', st.key, (heat * 4).round()),
        () => DragonKit.radial(
          const Offset(.3, 1.4),
          5.2,
          [
                // (the lit stop is only a step above the body of the plates:
                // the band must sit near L* 66, under the face and the gem)
                st.burn(
                  Color.lerp(DragonPalette.bellyLit, DragonPalette.belly, .6)!,
                  DragonPalette.flameGold,
                ),
                st.burn(
                  Color.lerp(DragonPalette.belly, DragonPalette.bellyDeep, .3)!,
                  DragonPalette.flameGold,
                ),
                st.burn(DragonPalette.bellyDeep, DragonPalette.flame),
                st.burn(DragonPalette.bellyDark, DragonPalette.flameDark),
              ]
              .map((col) => Color.lerp(col, DragonPalette.belly, heat * .5)!)
              .toList(),
          const [.05, .26, .6, 1],
        ),
      ),
    );

    // The swarm call is cool where the breath is hot: it turns the chin's and
    // the throat's plates violet, fading out down the chest.
    final tintTo = math.min(b, headEnd);
    if (_fin(head.call) > .02 && tintTo - a >= 2) {
      final cool = _fin(head.call).clamp(0.0, 1.0);
      final tint = Path()..moveTo(oa.first.dx, oa.first.dy);
      for (var i = 1; i < tintTo - a; i++) {
        tint.lineTo(oa[i].dx, oa[i].dy);
      }
      tint
        ..extendWithPath(
          DragonKit.spline(
            ia.sublist(0, tintTo - a).reversed.toList(),
            closed: false,
          ),
          Offset.zero,
        )
        ..close();
      c.drawPath(
        tint,
        DragonKit.linear(
          chin,
          throatEnd,
          [
            DragonPalette.callDeep.withValues(alpha: .85 * cool),
            DragonPalette.call.withValues(alpha: .7 * cool),
            DragonPalette.call.withValues(alpha: 0),
          ],
          const [0, .6, 1],
        ),
      );
    }
    // Fire rising from the heart lights the plates on its way up the throat.
    final throatHeat = _fin(head.throat).clamp(0.0, 1.0);
    if (throatHeat > .02) {
      final reach = (throatHeat * 1.15).clamp(0.0, 1.0);
      final pulse = _fin(head.time) == 0
          ? 1.0
          : .88 + .12 * math.sin(_fin(head.time) * 9) * throatHeat;
      final fire = _cached(
        ('fire', (throatHeat * 8).round()),
        () => DragonKit.linear(
          const Offset(0, -.1),
          Offset(-.2, -.1 - 2.2 * reach),
          [
            // Amber to orange, not lemon: the eye is the brightest thing.
            DragonPalette.flameGold.withValues(alpha: .7),
            DragonPalette.flame.withValues(alpha: .55),
            DragonPalette.flame.withValues(alpha: 0),
          ],
          const [0, .7, 1],
        ),
      );
      c.drawPath(
        band,
        Paint()
          ..shader = fire.shader
          ..color = DragonPalette.white.withValues(
            alpha: pulse.clamp(0.0, 1.0),
          ),
      );
    }

    // Plate seams square across the strip, and their catch-lights: every
    // .19 along the inner edge, straight to the outer one.
    final seams = Path(), lights = Path();
    var next = carry();
    for (var i = 0; i < m - 1; i++) {
      final p = ia[i], pq = ia[i + 1] - p;
      final len = pq.distance;
      if (len == 0) continue;
      final o = oa[i], oq = oa[i + 1] - o;
      final back = pq * (-.035 / len);
      var d = next;
      while (d <= len) {
        final t = d / len;
        final pin = p + pq * t, pout = o + oq * t;
        seams
          ..moveTo(pin.dx, pin.dy)
          ..lineTo(pout.dx, pout.dy);
        lights
          ..moveTo(pin.dx + back.dx, pin.dy + back.dy)
          ..lineTo(pout.dx + back.dx, pout.dy + back.dy);
        d += _plate;
      }
      next = d - len;
    }
    setCarry(next);
    c.drawPath(
      seams,
      DragonKit.line(tone.lit(DragonPalette.bellyDark), .03, .85),
    );
    c.drawPath(
      lights,
      DragonKit.line(tone.lit(DragonPalette.bellyLit), .02, .6),
    );
    c.drawPath(edge, DragonKit.line(DragonPalette.inkWarm, .055, .9));
    // The light escapes along the plates' upper edge: a faint seam down the
    // throat and the chest that wakes with the fire, and a bright one where
    // the plates end on the tail.
    // Lit from within at rest too: a glowing line, not a brown one.
    DragonKit.moltenSeam(
      c,
      edge,
      tone,
      width: .045,
      alpha: (.75 + _fin(head.throat) * .25 + body.open * .25).clamp(0.0, 1.0),
    );
    if (tone.glow <= .5) {
      c.drawPath(
        edge,
        DragonKit.line(DragonPalette.seamHot, .016, .5 + tone.glow * .4),
      );
    }
    if (tailFrom != null && tailFrom >= a && tailFrom < b - 1) {
      DragonKit.moltenSeam(
        c,
        DragonKit.spline(ia.sublist(tailFrom - a), closed: false),
        tone,
        width: .05,
        alpha: .8 + body.open * .2,
      );
    }
  }

  /// The torso outline from the top of the chest, down the front, under the
  /// keel and up to the rump's underside, in the torso's own frame: the point,
  /// the inward normal and how deep the plates are there.
  static final List<(Offset, Offset, double)> _chestBand = () {
    // Walked backwards: vertex 0 (14) -> 13 -> 12 -> ... -> 6.
    final out = <(Offset, Offset, double)>[];
    const perSeg = 4;
    // Depth at each vertex 13 .. 6 (the throat's .23 carries on and thins to
    // the chest front, swells to the keel and thins again to the waist).
    const depthAt = {
      14: .17,
      13: .17,
      12: .15,
      11: .12,
      10: .26,
      9: .42,
      8: .3,
      7: .13,
      6: .13,
    };
    for (var seg = 13; seg >= 6; seg--) {
      for (var k = 0; k < perSeg; k++) {
        final t = 1 - k / perSeg;
        final p = DragonBodyArt.torsoAt(seg, t);
        final d = DragonKit.unit(
          DragonBodyArt.torsoAt(seg, math.min(1.0, t + .05)) -
              DragonBodyArt.torsoAt(seg, math.max(0.0, t - .05)),
        );
        final depth = DragonKit.mix(depthAt[seg]!, depthAt[seg + 1]!, t);
        out.add((p, Offset(-d.dy, d.dx), depth));
      }
    }
    return out;
  }();

  // ------------------------------------------------------------- depth --

  static final List<Offset> _torsoPoly = [
    for (var seg = 0; seg < DragonLayout.torsoOutline.length; seg++)
      for (var k = 0; k < 2; k++) DragonBodyArt.torsoAt(seg, k / 2),
  ];

  /// The torso outline's box, in its own frame, with a margin: a point
  /// outside it is outside the torso by more than the margin.
  static const _torsoBox = Rect.fromLTRB(-1.6, -1.1, 2.4, 1.85);

  /// How far inside the torso [p] (rig units) is: positive inside, negative
  /// outside, in the torso's own frame. (A coarse figure, good to a few
  /// hundredths: it only decides where an outline fades and where a strip
  /// hands over.)
  double _torsoDepth(Offset p) {
    final q = Offset(p.dx / (1 + body.breath * .6), p.dy / (1 + body.breath));
    if (!_torsoBox.contains(q)) return -.3;
    var inside = false;
    var best = double.infinity;
    final n = _torsoPoly.length;
    for (var i = 0, j = n - 1; i < n; j = i++) {
      final a = _torsoPoly[i], b = _torsoPoly[j];
      if ((a.dy > q.dy) != (b.dy > q.dy) &&
          q.dx < (b.dx - a.dx) * (q.dy - a.dy) / (b.dy - a.dy) + a.dx) {
        inside = !inside;
      }
      final abx = b.dx - a.dx, aby = b.dy - a.dy;
      final len2 = abx * abx + aby * aby;
      final t = len2 == 0
          ? 0.0
          : (((q.dx - a.dx) * abx + (q.dy - a.dy) * aby) / len2).clamp(
              0.0,
              1.0,
            );
      final dx = a.dx + abx * t - q.dx, dy = a.dy + aby * t - q.dy;
      final d = dx * dx + dy * dy;
      if (d < best) best = d;
    }
    final dist = math.sqrt(best);
    return inside ? dist : -dist;
  }

  /// How far inside the tail [p] is (its half width less the distance to its
  /// spine), positive inside.
  double _tailDepth(Offset p) {
    var best = -double.infinity;
    final s = tail.spine;
    for (var i = 0; i + 1 < s.length; i++) {
      final a = s[i], ab = s[i + 1] - a;
      final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
      final t = len2 == 0
          ? 0.0
          : (((p.dx - a.dx) * ab.dx + (p.dy - a.dy) * ab.dy) / len2).clamp(
              0.0,
              1.0,
            );
      final half =
          DragonKit.mix(
            (tail.belly[i] - tail.dorsal[i]).distance,
            (tail.belly[i + 1] - tail.dorsal[i + 1]).distance,
            t,
          ) /
          2;
      best = math.max(best, half - (a + ab * t - p).distance);
    }
    return best;
  }

  /// How far inside the trunk (torso or tail) [p] is; negative outside.
  double _depth(Offset p) => math.max(_torsoDepth(p), _tailDepth(p));
}
