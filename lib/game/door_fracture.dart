import 'dart:math' as math;
import 'dart:ui';

/// Stable pseudo-randomness and easing shared by the breakable-wall art.
/// Everything is a pure function of its integer inputs, so a replay seek or a
/// second panel with the same look always paints the same pixels.
abstract final class DoorMath {
  static double hash(int a, [int b = 0, int c = 0]) {
    final v = math.sin(a * 12.9898 + b * 78.233 + c * 37.719) * 43758.5453;
    return v - v.floorToDouble();
  }

  static double clamp01(double t) => t < 0 ? 0 : (t > 1 ? 1 : t);
  static double outCubic(double t) {
    final x = 1 - clamp01(t);
    return 1 - x * x * x;
  }

  static double outQuad(double t) {
    final x = 1 - clamp01(t);
    return 1 - x * x;
  }

  static double inQuad(double t) {
    final x = clamp01(t);
    return x * x;
  }

  static double outBack(double t) {
    final x = clamp01(t) - 1;
    const c1 = 1.70158, c3 = c1 + 1;
    return 1 + c3 * x * x * x + c1 * x * x;
  }

  static double smooth(double t) {
    final x = clamp01(t);
    return x * x * (3 - 2 * x);
  }
}

/// A blow, in panel-local terms, as the fracture sees it.
class DoorBlow {
  const DoorBlow(this.y, this.power);

  /// Height of the strike on the panel's left face, 0 at the panel top.
  final double y;
  final double power;
}

/// One piece of the shattered slab, in panel units.
class DoorShard {
  DoorShard._(this.points, this.centroid, this.area, this.source, this.index);

  /// The outline in panel coordinates (jagged, shared with its neighbours).
  final List<Offset> points;
  final Offset centroid;
  final double area;

  /// Which blow this piece sits around (or -1 for ground pieces).
  final int source;
  final int index;

  bool get gravel => area < .0007;

  /// The outline around [centroid], so a piece can spin about its middle.
  late final List<Offset> local = [for (final p in points) p - centroid];

  late final double radius = local.fold<double>(
    0,
    (m, p) => math.max(m, p.distance),
  );

  late final Path face = Path()..addPolygon(local, true);

  static const _light = Offset(-.55, -.83);

  /// Short inset strokes along the edges that face the light (top and left)
  /// and along those that face away, so every piece reads as a bevelled slab.
  late final Path lit = _edges(true);
  late final Path shade = _edges(false);

  Path _edges(bool lit) {
    final path = Path();
    var signed = 0.0;
    for (var i = 0; i < local.length; i++) {
      final a = local[i], b = local[(i + 1) % local.length];
      signed += a.dx * b.dy - b.dx * a.dy;
    }
    final flip = signed < 0 ? -1.0 : 1.0;
    for (var i = 0; i < local.length; i++) {
      final a = local[i], b = local[(i + 1) % local.length];
      final d = b - a, len = d.distance;
      if (len < .008) continue;
      final normal = Offset(d.dy, -d.dx) / len * flip;
      final facing = normal.dx * _light.dx + normal.dy * _light.dy;
      if (lit ? facing < .3 : facing > -.25) continue;
      final inset = -normal * .0034;
      path
        ..moveTo(a.dx + d.dx * .14 + inset.dx, a.dy + d.dy * .14 + inset.dy)
        ..lineTo(a.dx + d.dx * .86 + inset.dx, a.dy + d.dy * .86 + inset.dy);
    }
    return path;
  }

  /// A cache for whatever the painter wants to remember about this piece.
  Object? paintCache;
}

/// A crack between two pieces: a jagged polyline in panel coordinates.
class DoorCrack {
  DoorCrack(this.points, this.source, this.late);
  final List<Offset> points;

  /// The blow whose impact point the crack grows from.
  final int source;

  /// Cracks between two ground pieces only open near the end.
  final bool late;
}

/// The stone's fracture pattern, built from the blows the panel has taken.
///
/// Every blow lays a small web of pieces around where it struck: a crater at
/// the strike itself, a ring of wedges around that, and for heavy blows a
/// second ring. A loose grid of ground pieces fills the rest. The pieces are
/// the cells of one Voronoi diagram, so a crack drawn on the damaged panel is
/// exactly the seam a shard later breaks along, and the shards that fly off
/// come from where the cracks already were.
class DoorFracture {
  DoorFracture._({
    required this.w,
    required this.h,
    required this.blows,
    required this.craters,
    required this.shards,
    required this.cracks,
    required this.silhouette,
    required this.origins,
  });

  final double w, h;

  /// The blows in their (nudged) places, oldest first.
  final List<DoorBlow> blows;

  /// Where each blow's crater sits, on the left face.
  final List<Offset> origins;

  /// Pieces already gone: one crater per non-lethal blow.
  final List<List<Offset>> craters;

  /// Everything that flies when the panel lets go.
  final List<DoorShard> shards;
  final List<DoorCrack> cracks;

  /// The shards, biggest first, so small chips paint over the slabs.
  late final List<DoorShard> byArea = [...shards]
    ..sort((a, b) => b.area.compareTo(a.area));

  /// The panel's outline with every crater bitten out of its left edge.
  final Path silhouette;

  static const minSpacing = .075;
  static const craterInset = .006;
  static final _cache = <String, DoorFracture>{};

  /// [blows] in local panel units. With [lethal] the last blow is the one
  /// that broke the panel: its crater becomes a flying chip, not a hole.
  static DoorFracture of({
    required double w,
    required double h,
    required int seed,
    required List<DoorBlow> blows,
    required bool lethal,
  }) {
    final key =
        '$seed/${(w * 1000).round()}/${(h * 1000).round()}/$lethal/'
        '${[for (final b in blows) '${(b.y * 1000).round()}:${(b.power * 20).round()}'].join(',')}';
    final hit = _cache[key];
    if (hit != null) return hit;
    if (_cache.length >= 24) _cache.remove(_cache.keys.first);
    return _cache[key] = _build(w, h, seed, blows, lethal);
  }

  static double _nudge(double y, List<double> taken, double h) {
    final lo = .03, hi = h - .03;
    final start = y.clamp(lo, hi);
    for (var step = 0; step < 60; step++) {
      for (final sign in [1.0, -1.0]) {
        final c = start + sign * step * .006;
        if (c < lo || c > hi) continue;
        if (taken.every((t) => (t - c).abs() >= minSpacing)) return c;
      }
    }
    return start;
  }

  static DoorFracture _build(
    double w,
    double h,
    int seed,
    List<DoorBlow> blows,
    bool lethal,
  ) {
    // ---- blows, spread out so their craters never overlap --------------
    final ys = <double>[];
    for (final b in blows) {
      ys.add(_nudge(b.y, ys, h));
    }
    final placed = [
      for (var i = 0; i < blows.length; i++) DoorBlow(ys[i], blows[i].power),
    ];
    final origins = [for (final y in ys) Offset(craterInset, y)];

    // ---- sites ----------------------------------------------------------
    final sites = <_Site>[];
    final rows = math.max(3, (h / .11).round());
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < 2; c++) {
        final n = r * 2 + c;
        final jx = DoorMath.hash(seed, 11, n) - .5;
        final jy = DoorMath.hash(seed, 23, n) - .5;
        // Alternate rows stagger, so the seams never line up into a grid.
        final stagger = r.isOdd ? .1 : -.1;
        sites.add(
          _Site(
            (w * (.28 + .44 * c + stagger + jx * .2)).clamp(.02, w - .02),
            h * ((r + .5) / rows) + jy * h / rows * .6,
            -1,
            _Kind.ground,
          ),
        );
      }
    }
    for (var j = 0; j < placed.length; j++) {
      final o = origins[j];
      final isLast = lethal && j == placed.length - 1;
      final power = placed[j].power;
      sites.add(_Site(o.dx, o.dy, j, isLast ? _Kind.chip : _Kind.crater));
      // The killing blow shatters finely at the strike and coarsely away
      // from it; earlier blows only start a small web.
      final n1 = isLast ? (power > .5 ? 7 : 6) : (j == 0 ? 4 : 3);
      final r1 = (isLast ? .03 : .034) + .012 * power;
      void ring(int count, double radius, double phase, int salt) {
        for (var i = 0; i < count; i++) {
          final span = 2.9 / count;
          final a =
              -1.45 +
              span * (i + .5 + phase) +
              (DoorMath.hash(seed, salt + j * 7, i) - .5) * span * .55;
          final rr = radius * (.85 + .3 * DoorMath.hash(seed, salt + 3, i + j));
          final p = Offset(o.dx + math.cos(a) * rr, o.dy + math.sin(a) * rr);
          if (p.dy < -.02 || p.dy > h + .02 || p.dx > w + .02) continue;
          // Never let a ring wedge crowd an older site or a locked crater.
          if (sites.any((s) => (s.p - p).distance < .024)) continue;
          if (sites.any(
            (s) =>
                s.kind == _Kind.crater &&
                s.hit != j &&
                (s.p - p).distance < .042,
          )) {
            continue;
          }
          sites.add(_Site(p.dx, p.dy, j, _Kind.ring));
        }
      }

      ring(n1, r1, 0, 40);
      if (isLast) {
        ring(n1 + 1, r1 * 2.1, .5, 80);
        ring(n1, r1 * 3.4, .25, 120);
      }
    }

    // ---- Voronoi cells --------------------------------------------------
    final rect = [Offset.zero, Offset(w, 0), Offset(w, h), Offset(0, h)];
    final cells = <_Cell>[];
    for (var i = 0; i < sites.length; i++) {
      var poly = _Poly(List.of(rect), [-1, -2, -3, -4]);
      for (var j = 0; j < sites.length && poly.v.length >= 3; j++) {
        if (i == j) continue;
        final n = sites[j].p - sites[i].p;
        final mid = (sites[j].p + sites[i].p) / 2;
        poly = _clip(poly, n, n.dx * mid.dx + n.dy * mid.dy, j);
      }
      cells.add(_Cell(i, _tidy(poly)));
    }

    // ---- jagged seams, shared by both neighbours -----------------------
    // The lower-numbered cell bends each seam once; its neighbour walks the
    // same points backwards, so the two outlines always meet exactly.
    final seams = <int, List<Offset>>{};
    List<Offset> seamOf(int i, int j, Offset a, Offset b) {
      if (i < j) return seams[i * 100 + j] = _seam(a, b, seed, i * 100 + j);
      final shared = seams[j * 100 + i];
      return shared == null ? [a, b] : shared.reversed.toList();
    }

    final outlines = <List<Offset>>[];
    for (final cell in cells) {
      final poly = cell.poly;
      final out = <Offset>[];
      for (var e = 0; e < poly.v.length; e++) {
        final a = poly.v[e], b = poly.v[(e + 1) % poly.v.length];
        out.add(a);
        if (poly.label[e] < 0) continue;
        final seam = seamOf(cell.site, poly.label[e], a, b);
        out.addAll(seam.sublist(1, seam.length - 1));
      }
      outlines.add(out);
    }

    // ---- pieces ---------------------------------------------------------
    final craters = <List<Offset>>[];
    final shards = <DoorShard>[];
    for (var i = 0; i < cells.length; i++) {
      final pts = outlines[i];
      if (pts.length < 3) continue;
      final s = sites[i];
      if (s.kind == _Kind.crater && _bite(pts)) {
        craters.add(pts);
        continue;
      }
      final (area, centroid) = _areaCentroid(pts);
      if (area < 2e-5) continue;
      shards.add(DoorShard._(pts, centroid, area, s.hit, shards.length));
    }

    // ---- cracks: every seam between two pieces, once -------------------
    final cracks = <DoorCrack>[];
    bool hole(int i) => sites[i].kind == _Kind.crater && _bite(outlines[i]);
    if (origins.isNotEmpty) {
      for (var i = 0; i < cells.length; i++) {
        final poly = cells[i].poly;
        for (var e = 0; e < poly.v.length; e++) {
          final label = poly.label[e];
          if (label < 0 || label < i) continue;
          final a = sites[i], b = sites[label];
          // Crater rims are drawn as chips, not as cracks.
          if (hole(i) || hole(label)) continue;
          final p0 = poly.v[e], p1 = poly.v[(e + 1) % poly.v.length];
          final pts = seams[i * 100 + label] ?? [p0, p1];
          var src = math.min(a.hit < 0 ? 99 : a.hit, b.hit < 0 ? 99 : b.hit);
          var late = false;
          if (src == 99) {
            late = true;
            src = 0;
            var best = double.infinity;
            final mid = (p0 + p1) / 2;
            for (var k = 0; k < origins.length; k++) {
              final d = (origins[k] - mid).distance;
              if (d < best) {
                best = d;
                src = k;
              }
            }
          }
          cracks.add(DoorCrack(pts, src, late));
        }
      }
    }

    // ---- outline with the craters bitten out -----------------------------
    var silhouette = Path()..addRect(Rect.fromLTWH(0, 0, w, h));
    for (final c in craters) {
      try {
        silhouette = Path.combine(
          PathOperation.difference,
          silhouette,
          Path()..addPolygon(c, true),
        );
      } on StateError {
        // A degenerate bite is skipped rather than losing the whole panel.
        continue;
      }
    }

    return DoorFracture._(
      w: w,
      h: h,
      blows: placed,
      craters: craters,
      shards: shards,
      cracks: cracks,
      silhouette: silhouette,
      origins: origins,
    );
  }

  // ---- crack drawing helpers ---------------------------------------------

  /// The cracks that have opened, as one path. [reach] gives, for each blow,
  /// how far its cracks have run from the strike (panel units); ground seams
  /// open [lateScale] as far. Segments are clipped to that circle so a crack
  /// visibly grows outwards from where the rock landed.
  Path crackPath(double Function(int blow) reach, {double lateScale = .6}) {
    final path = Path();
    for (final crack in cracks) {
      final o = origins[crack.source];
      final r = reach(crack.source) * (crack.late ? lateScale : 1);
      if (r <= 0) continue;
      for (var i = 0; i + 1 < crack.points.length; i++) {
        final seg = _within(crack.points[i], crack.points[i + 1], o, r);
        if (seg == null) continue;
        path
          ..moveTo(seg.$1.dx, seg.$1.dy)
          ..lineTo(seg.$2.dx, seg.$2.dy);
      }
    }
    return path;
  }

  static (Offset, Offset, bool)? _within(
    Offset a,
    Offset b,
    Offset c,
    double r,
  ) {
    final d = b - a;
    final f = a - c;
    final qa = d.dx * d.dx + d.dy * d.dy;
    if (qa < 1e-12) return null;
    final qb = 2 * (f.dx * d.dx + f.dy * d.dy);
    final qc = f.dx * f.dx + f.dy * f.dy - r * r;
    final disc = qb * qb - 4 * qa * qc;
    if (disc < 0) return null;
    final sq = math.sqrt(disc);
    final t0 = math.max(0.0, (-qb - sq) / (2 * qa));
    final t1 = math.min(1.0, (-qb + sq) / (2 * qa));
    if (t0 >= t1) return null;
    return (a + d * t0, a + d * t1, t0 <= 0 && t1 >= 1);
  }

  // ---- geometry --------------------------------------------------------

  static _Poly _clip(_Poly p, Offset n, double d, int label) {
    final v = <Offset>[], l = <int>[];
    for (var i = 0; i < p.v.length; i++) {
      final a = p.v[i], b = p.v[(i + 1) % p.v.length];
      final da = n.dx * a.dx + n.dy * a.dy - d;
      final db = n.dx * b.dx + n.dy * b.dy - d;
      final aIn = da <= 1e-12, bIn = db <= 1e-12;
      if (aIn) {
        v.add(a);
        l.add(p.label[i]);
      }
      if (aIn != bIn) {
        final t = da / (da - db);
        v.add(a + (b - a) * t);
        l.add(aIn ? label : p.label[i]);
      }
    }
    return _Poly(v, l);
  }

  static _Poly _tidy(_Poly p) {
    final v = <Offset>[], l = <int>[];
    for (var i = 0; i < p.v.length; i++) {
      final next = p.v[(i + 1) % p.v.length];
      if ((p.v[i] - next).distance < 1e-7) continue;
      v.add(p.v[i]);
      l.add(p.label[i]);
    }
    return _Poly(v, l);
  }

  static (double, Offset) _areaCentroid(List<Offset> pts) {
    var a = 0.0, cx = 0.0, cy = 0.0;
    for (var i = 0; i < pts.length; i++) {
      final p = pts[i], q = pts[(i + 1) % pts.length];
      final cross = p.dx * q.dy - q.dx * p.dy;
      a += cross;
      cx += (p.dx + q.dx) * cross;
      cy += (p.dy + q.dy) * cross;
    }
    if (a.abs() < 1e-12) {
      return (
        0,
        pts.fold(Offset.zero, (s, p) => s + p) / pts.length.toDouble(),
      );
    }
    return (a.abs() / 2, Offset(cx / (3 * a), cy / (3 * a)));
  }

  /// A crater cell is only a bite if it stays small; a stray oversized cell
  /// (a blow that landed against a corner) is kept as a normal piece.
  static bool _bite(List<Offset> pts) {
    var minX = double.infinity, maxX = -double.infinity;
    var minY = double.infinity, maxY = -double.infinity;
    for (final p in pts) {
      minX = math.min(minX, p.dx);
      maxX = math.max(maxX, p.dx);
      minY = math.min(minY, p.dy);
      maxY = math.max(maxY, p.dy);
    }
    return maxX - minX < .045 && maxY - minY < .075;
  }

  /// The seam between [a] and [b], bent a little so cracks run like stone
  /// splits rather than ruled lines.
  static List<Offset> _seam(Offset a, Offset b, int seed, int pair) {
    final d = b - a;
    final len = d.distance;
    if (len < .012) return [a, b];
    final normal = Offset(d.dy, -d.dx) / len;
    final count = len > .06 ? 2 : 1;
    final all = <Offset>[a];
    for (var m = 1; m <= count; m++) {
      final t = m / (count + 1) + (DoorMath.hash(seed, pair, m + 5) - .5) * .12;
      final amp =
          (DoorMath.hash(seed, pair, m) - .5) * 2 * math.min(len * .17, .011);
      all.add(a + d * t + normal * amp);
    }
    all.add(b);
    return all;
  }
}

enum _Kind { ground, crater, ring, chip }

class _Site {
  _Site(double x, double y, this.hit, this.kind) : p = Offset(x, y);
  final Offset p;
  final int hit;
  final _Kind kind;
}

class _Poly {
  _Poly(this.v, this.label);
  final List<Offset> v;

  /// label[i] tags the edge that starts at v[i]: the neighbouring site, or a
  /// negative number for the panel's own border.
  final List<int> label;
}

class _Cell {
  _Cell(this.site, this.poly);
  final int site;
  final _Poly poly;
}
