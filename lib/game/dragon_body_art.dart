import 'dart:math' as math;

import 'package:flutter/painting.dart';

import 'dragon_kit.dart';
import 'dragon_layout.dart';
import 'dragon_pose.dart';

double _straight(double u) => 0;

double _finite(double v) => v.isFinite ? v : 0;

/// [t] with every number finite: a NaN or infinite tone would throw where the
/// caches round it into a key.
DragonTone _cleanTone(DragonTone t) =>
    t.flash.isFinite && t.fury.isFinite && t.heat.isFinite && t.dark.isFinite
    ? t
    : DragonTone(
        flash: _finite(t.flash),
        fury: _finite(t.fury),
        heat: _finite(t.heat),
        dark: _finite(t.dark),
        sky: t.sky,
      );

/// A small least-recently-used cache for paints and shaders that depend on
/// the tone. (KIT-REQUEST: `DragonKit.cached` clears wholesale at 96 entries;
/// hoist this into the kit and use it there, so the head's caches and the
/// kit's stop rebuilding every shader in one frame.) A hit moves the entry to the back; a miss at capacity drops only
/// the oldest, so a step in the tone (each heat step of an inhale, each
/// darkness step of the sky) costs one entry's shaders and never clears the
/// lot in one frame.
final class DragonCache<K, V> {
  DragonCache(this.capacity);
  final int capacity;
  final Map<K, V> _map = <K, V>{};

  /// How many entries it holds now (never more than [capacity]).
  int get length => _map.length;

  V get(K key, V Function() make) {
    final hit = _map.remove(key);
    if (hit != null) {
      _map[key] = hit;
      return hit;
    }
    if (_map.length >= capacity) _map.remove(_map.keys.first);
    return _map[key] = make();
  }
}

/// The pose channels the body reads. `DragonBossRig` derives them from the
/// boss clock; nothing here keeps history, so any frame stands on its own.
final class DragonBodyPose {
  const DragonBodyPose({
    this.time = 0,
    this.breath = 0,
    this.heart = .2,
    this.open = 0,
    this.crit = 0,
    this.crack = 0,
    this.slump = 0,
    this.clutch = 0,
    this.kick = 0,
    this.hindSwing = 0,
    this.foreSwing = 0,
    this.bend = _straight,
    this.tailSway = 0,
    this.tone = const DragonTone(),
  });

  /// The body for [pose]. EVERY body implementation keeps this factory: the
  /// rig builds nothing but `DragonBodyPose.of(pose)`.
  factory DragonBodyPose.of(DragonPose pose) => DragonBodyPose(
    time: _finite(pose.time),
    breath: _finite(pose.chest),
    heart: _finite(pose.heart),
    open: _finite(math.max(pose.inhale, pose.blast)),
    crit: _finite(pose.crit),
    crack: _finite(pose.crack),
    slump: _finite(pose.slump),
    clutch: _finite(pose.clutch),
    kick: _finite(pose.legKick),
    hindSwing: _finite(pose.beatAt(.25) * .06),
    foreSwing: _finite(pose.beatAt(.30) * .04),
    bend: pose.tailBend,
    tone: _cleanTone(pose.tone),
  );

  /// Seconds on the boss clock, 0 when the pose must hold still.
  final double time;

  /// Chest swell (breath, inhale, roar), and the heart's light.
  final double breath, heart;

  /// How far the chest plates part to bare the heart (the breath).
  final double open;

  /// A hit on the open heart just now, and the defeat's cracks spreading
  /// out of it (0 to 1).
  final double crit, crack;

  /// The defeat's sag; claws curling in to strike or fire.
  final double slump, clutch;

  /// The hind legs' kick at the snap (-1..1), and the pendulum of the hind
  /// and fore legs in radians, hung on the wingbeat.
  final double kick, hindSwing, foreSwing;

  /// The tail's vertical bend at [0 root .. 1 blade] (rig units, down +).
  final double Function(double u) bend;

  /// A single tail swing, -1 to 1, for callers that have no [bend]: it bends
  /// the tail's tip by a quarter of a unit.
  final double tailSway;
  final DragonTone tone;

  /// This pose with every number finite (a pose built by hand can hold NaN;
  /// the painters call this once, so a bad number never reaches the canvas).
  DragonBodyPose get finite =>
      time.isFinite &&
          breath.isFinite &&
          heart.isFinite &&
          open.isFinite &&
          crit.isFinite &&
          crack.isFinite &&
          slump.isFinite &&
          clutch.isFinite &&
          kick.isFinite &&
          hindSwing.isFinite &&
          foreSwing.isFinite &&
          tailSway.isFinite &&
          tone.flash.isFinite &&
          tone.fury.isFinite &&
          tone.heat.isFinite &&
          tone.dark.isFinite
      ? this
      : DragonBodyPose(
          time: _finite(time),
          breath: _finite(breath),
          heart: _finite(heart),
          open: _finite(open),
          crit: _finite(crit),
          crack: _finite(crack),
          slump: _finite(slump),
          clutch: _finite(clutch),
          kick: _finite(kick),
          hindSwing: _finite(hindSwing),
          foreSwing: _finite(foreSwing),
          bend: bend,
          tailSway: _finite(tailSway),
          tone: _cleanTone(tone),
        );
}

/// The tail's geometry for one pose: the spine, both edges and the outline.
///
/// [belly] is the underside edge (the tube's +normal side) and [dorsal] the
/// crest edge; [shape] winds counter-clockwise on screen, like every
/// part of the hide.
final class DragonTail {
  const DragonTail._({
    required this.spine,
    required this.dirs,
    required this.belly,
    required this.dorsal,
    required this.shape,
    required this.end,
    required this.endDir,
  });
  final List<Offset> spine, dirs, belly, dorsal;
  final Path shape;
  final Offset end, endDir;
}

/// One leg's geometry for one pose: its joints, the limb outline and both
/// edges, and where the talons go.
final class DragonLeg {
  const DragonLeg._({
    required this.hind,
    required this.far,
    required this.knee,
    required this.ankle,
    required this.foot,
    required this.curl,
    required this.heading,
    required this.hook,
    required this.dew,
    required this.spine,
    required this.left,
    required this.right,
    required this.width,
    required this.shape,
    required this.ring,
  });
  final bool hind, far;
  final Offset knee, ankle, foot;

  /// How far the talons have curled (0 open .. 1 fist), and where they point.
  final double curl, heading, hook, dew;

  /// The ten spine samples, the two edges and the widths across them.
  final List<Offset> spine, left, right;
  final List<double> width;

  /// The limb as one rounded outline, and the same outline as points (edge,
  /// round foot cap, edge back), from the root round the foot.
  final Path shape;
  final List<Offset> ring;
}

/// The paints that only depend on how the dragon is lit, built once per tone
/// (flash, fury, backdrop) and kept: a frame builds no gradient for them.
final class _Look {
  _Look(DragonTone tone) {
    Color pl(Color c) => tone.plate(c);
    Color lit(Color c) => tone.lit(c);
    torso = DragonKit.radial(
      const Offset(-.7, -.3),
      3.5,
      [
        pl(DragonPalette.scaleLit),
        pl(DragonPalette.scale),
        pl(DragonPalette.scaleDeep),
        pl(DragonPalette.scaleDark),
      ],
      const [0, .27, .64, 1],
    ).shader!;
    tail = DragonKit.linear(
      const Offset(0, .1),
      const Offset(0, 3.4),
      [
        pl(DragonPalette.scaleLit),
        pl(DragonPalette.scale),
        pl(DragonPalette.scaleDeep),
        pl(DragonPalette.scaleDark),
      ],
      const [0, .3, .74, 1],
    ).shader!;
    limb = DragonKit.linear(
      const Offset(0, .2),
      const Offset(0, 3.3),
      [
        Color.lerp(pl(DragonPalette.scaleLit), pl(DragonPalette.scale), .4)!,
        pl(DragonPalette.scale),
        Color.lerp(pl(DragonPalette.scale), pl(DragonPalette.scaleDeep), .55)!,
      ],
      const [0, .42, .95],
    ).shader!;
    Color far(Color c) => DragonKit.shade(pl(c), .8);
    limbFar = DragonKit.linear(
      const Offset(0, .2),
      const Offset(0, 3.3),
      [
        far(DragonPalette.scale),
        far(DragonPalette.scaleDeep),
        far(DragonPalette.scaleDark),
      ],
      const [0, .5, 1],
    ).shader!;
    belly = DragonKit.radial(
      const Offset(0, .15),
      4.4,
      [
        tone.burn(
          Color.lerp(DragonPalette.bellyLit, DragonPalette.belly, .6)!,
          DragonPalette.flameGold,
        ),
        tone.burn(
          Color.lerp(DragonPalette.belly, DragonPalette.bellyDeep, .3)!,
          DragonPalette.flameGold,
        ),
        tone.burn(DragonPalette.bellyDeep, DragonPalette.flame),
        tone.burn(DragonPalette.bellyDark, DragonPalette.flameDark),
      ],
      const [.05, .28, .6, 1],
    ).shader!;
    scaleRows = DragonKit.linear(
      const Offset(-1.4, -1),
      const Offset(2.3, 1.7),
      [
        DragonPalette.inkCool.withValues(alpha: .3),
        DragonPalette.inkCool.withValues(alpha: 1),
        DragonPalette.inkCool.withValues(alpha: .8),
        DragonPalette.inkCool.withValues(alpha: .65),
      ],
      const [0, .34, .74, 1],
    ).shader!;
    bezel = DragonKit.linear(
      const Offset(-.44, -.44),
      const Offset(.44, .44),
      [
        lit(DragonPalette.goldLit),
        lit(DragonPalette.gold),
        lit(DragonPalette.goldDeep),
        lit(DragonPalette.goldShade),
      ],
      const [0, .3, .68, 1],
    ).shader!;
    talon = DragonKit.linear(
      Offset.zero,
      const Offset(.46, 0),
      [
        lit(DragonPalette.boneShade),
        lit(DragonPalette.boneDeep),
        lit(DragonPalette.bone),
        lit(DragonPalette.boneLit),
      ],
      const [0, .22, .7, 1],
    ).shader!;
    blade = DragonKit.linear(
      const Offset(-.1, 0),
      const Offset(.9, 0),
      [
        tone.burn(DragonPalette.membraneDeep, DragonPalette.flameDark),
        tone.burn(DragonPalette.membrane, DragonPalette.flame),
        tone.burn(DragonPalette.membraneLit, DragonPalette.flameGold),
      ],
      const [0, .45, 1],
    ).shader!;
    spine = DragonKit.linear(
      Offset.zero,
      const Offset(.4, 0),
      [
        lit(DragonPalette.boneShade),
        lit(DragonPalette.boneDeep),
        lit(DragonPalette.bone),
        lit(DragonPalette.boneLit),
      ],
      const [0, .3, .75, 1],
    ).shader!;
  }

  late final Shader torso,
      tail,
      limb,
      limbFar,
      belly,
      scaleRows,
      bezel,
      talon,
      blade,
      spine;
}

/// The Ember Dragon's body in rig units (1 = the hit radius, the heart at
/// the origin): an armoured barrel of obsidian plate seamed with molten
/// light, a banded amber belly, the breastplate and the heart-gem that is
/// its weak point, digitigrade hind legs, a reaching clawed foreleg, a
/// spined back and a heavy tail ending in a bone-and-membrane blade.
///
/// Everything static is a `static final` path; everything that only depends
/// on the tone is a cached shader ([_Look]); what moves is rebuilt from a
/// few points a frame. Details stay inside their shapes by construction or
/// under three clips (the torso, and the scale rows over the two near limbs),
/// so the part stays under 110 draws, 2 new shaders and 3 clips a frame.
///
/// Paint order (`DragonBossRig`): [back] far legs and the tail, [torsoPaint]
/// the barrel, its belly and its molten cracks, [front] the near hind leg,
/// then the neck and the near wing (not ours), [heart] the back spines, the
/// breastplate and the gem, and last [foreleg].
abstract final class DragonBodyArt {
  static const _ink = DragonPalette.ink;

  // ------------------------------------------------------------ helpers --

  /// [t] snapped to the steps of [DragonTone.key] (flash, fury and heat in
  /// eighths, darkness in quarters), the tone every cached paint is built
  /// from: two frames with the same key always share the same paint, whichever
  /// tone reached the cache first, so a replay in any order paints the same
  /// pixels. (KIT-REQUEST: `DragonTone.snapped()`; this is its stand-in.)
  static DragonTone snap(DragonTone t) {
    final c = _cleanTone(t);
    double q(double v, double steps) => (v * steps).round() / steps;
    return DragonTone(
      flash: q(c.flash, 8),
      fury: q(c.fury, 8),
      heat: q(c.heat, 8),
      dark: q(c.dark, 4),
      sky: c.sky,
    );
  }

  static final _looks = DragonCache<int, _Look>(24);

  /// How many tone looks the body holds (for the cache-bound test).
  static int get cacheSize => _looks.length;

  /// The tone-keyed paints. Heat and the sky's tint do not change a fill
  /// (only strokes), so they are not part of the key.
  static _Look _look(DragonTone t) {
    final tone = snap(t);
    final key = Object.hash(
      (tone.flash * 8).round(),
      (tone.fury * 8).round(),
      (tone.dark * 4).round(),
    );
    return _looks.get(key, () => _Look(tone));
  }

  static Paint _fillWith(Shader s, [double alpha = 1]) => Paint()
    ..shader = s
    ..color = Color.fromRGBO(0, 0, 0, alpha);

  static Paint _strokeWith(Shader s, double width, [double alpha = 1]) =>
      Paint()
        ..shader = s
        ..color = Color.fromRGBO(0, 0, 0, alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

  /// The colour of the sky's rim light: the backdrop's bounce, bleached by the
  /// hit flash, and white once the flash is strong so it still shows on pale
  /// skies.
  ///
  /// KIT-REQUEST: the bible puts this in `DragonTone` (crescents go white above
  /// flash .35); every part needs it, so hoist it there and drop this copy.
  static Color _skyRim(DragonTone t) => t.flash > .35
      ? Color.lerp(
          t.lit(t.sky),
          DragonPalette.white,
          ((t.flash - .35) / .2).clamp(0.0, 1.0),
        )!
      : t.lit(t.sky);

  static Offset _polar(double angle, double r) =>
      Offset(math.cos(angle) * r, math.sin(angle) * r);

  static double _smooth(double t) => t * t * (3 - 2 * t);

  /// A point on the torso outline: segment [seg] (from vertex seg to seg+1)
  /// at [t], exactly as `DragonKit.spline` draws it.
  static Offset _torsoAt(int seg, double t) {
    const pts = DragonLayout.torsoOutline;
    final n = pts.length;
    Offset at(int i) => pts[(i % n + n) % n];
    final p0 = at(seg - 1), p1 = at(seg), p2 = at(seg + 1), p3 = at(seg + 2);
    return DragonKit.bezier(p1, p1 + (p2 - p0) / 6, p2 - (p3 - p1) / 6, p2, t);
  }

  /// Appends a Catmull-Rom curve through [pts] to [path], which must
  /// already be at `pts.first`.
  static void _curveThrough(Path path, List<Offset> pts) {
    final n = pts.length;
    Offset at(int i) => pts[i.clamp(0, n - 1)];
    for (var i = 0; i < n - 1; i++) {
      final p0 = at(i - 1), p1 = at(i), p2 = at(i + 1), p3 = at(i + 2);
      final c1 = p1 + (p2 - p0) / 6, c2 = p2 - (p3 - p1) / 6;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
  }

  static Path _open(List<Offset> pts) {
    final p = Path()..moveTo(pts.first.dx, pts.first.dy);
    _curveThrough(p, pts);
    return p;
  }

  /// A point on the Catmull-Rom curve through [pts] between vertex [i] and
  /// the next, at [t] (the ends repeat).
  static Offset _catmull(List<Offset> pts, int i, double t) {
    final n = pts.length;
    Offset at(int k) => pts[k.clamp(0, n - 1)];
    final p0 = at(i - 1), p1 = at(i), p2 = at(i + 1), p3 = at(i + 2);
    return DragonKit.bezier(p1, p1 + (p2 - p0) / 6, p2 - (p3 - p1) / 6, p2, t);
  }

  static double _catmullD(List<double> v, int i, double t) {
    final n = v.length;
    double at(int k) => v[k.clamp(0, n - 1)];
    final p0 = at(i - 1), p1 = at(i), p2 = at(i + 1), p3 = at(i + 2);
    final u = 1 - t;
    return p1 * (u * u * u) +
        (p1 + (p2 - p0) / 6) * (3 * u * u * t) +
        (p2 - (p3 - p1) / 6) * (3 * u * t * t) +
        p2 * (t * t * t);
  }

  /// A crack as a thin tapering polygon along [pts]: [w0] wide at the first
  /// point, [w1] at the last. Filled, it reads as light in a split.
  static Path _taper(List<Offset> pts, double w0, double w1) {
    final n = pts.length;
    final left = <Offset>[], right = <Offset>[];
    for (var i = 0; i < n; i++) {
      final d = DragonKit.unit(
        pts[math.min(i + 1, n - 1)] - pts[math.max(i - 1, 0)],
      );
      final nrm = Offset(-d.dy, d.dx);
      final w = (w0 + (w1 - w0) * i / (n - 1)) / 2;
      left.add(pts[i] + nrm * w);
      right.add(pts[i] - nrm * w);
    }
    return Path()..addPolygon([...left, ...right.reversed], true);
  }

  // ------------------------------------------------------------- static --

  /// The torso: chest barrel, keel, waist tuck and haunch.
  static final torso = DragonKit.spline(DragonLayout.torsoOutline);

  /// The banded belly: the plates that follow the underside from the waist
  /// round the keel to the chest, as fill, plate seams, catch-lights and the
  /// strip's inner edge.
  static final _belly = () {
    final pts = <Offset>[];
    for (var seg = 7; seg <= 10; seg++) {
      for (var k = 0; k < 8; k++) {
        pts.add(_torsoAt(seg, k / 8));
      }
    }
    pts.add(_torsoAt(10, 1));
    final cum = <double>[0];
    for (var i = 1; i < pts.length; i++) {
      cum.add(cum.last + (pts[i] - pts[i - 1]).distance);
    }
    final total = cum.last;
    // The point, the inward normal and the direction of travel at arclength s.
    (Offset, Offset, Offset) at(double s) {
      final v = s.clamp(0.0, total);
      var i = 1;
      while (i < cum.length - 1 && cum[i] < v) {
        i++;
      }
      final t = (v - cum[i - 1]) / (cum[i] - cum[i - 1]);
      final p = Offset.lerp(pts[i - 1], pts[i], t)!;
      final d = DragonKit.unit(
        pts[math.min(i + 1, pts.length - 1)] - pts[math.max(i - 2, 0)],
      );
      return (p, Offset(-d.dy, d.dx), d);
    }

    // Deep at the keel, thin toward the chest and the waist.
    double depth(double u) => .1 + .46 * math.pow(math.sin(math.pi * u), .8);
    final inner = <Offset>[], outer = <Offset>[];
    const m = 14;
    for (var i = 0; i <= m; i++) {
      final u = i / m;
      final (p, n, _) = at(u * total);
      inner.add(p + n * depth(u));
      outer.add(p - n * .18);
    }
    final fill = Path()..moveTo(outer.first.dx, outer.first.dy);
    for (final o in outer.skip(1)) {
      fill.lineTo(o.dx, o.dy);
    }
    fill.lineTo(inner.last.dx, inner.last.dy);
    _curveThrough(fill, inner.reversed.toList());
    fill.close();

    // Eight plates: seven seams, the plates narrower at both ends.
    final seams = Path(), glints = Path();
    for (var k = 1; k < 8; k++) {
      final u0 = k / 8;
      final u = u0 - .26 * math.sin(2 * math.pi * u0) / (2 * math.pi);
      final (p, n, d) = at(u * total);
      final a = p - n * .18, b = p + n * (depth(u) + .02);
      final mid = Offset.lerp(a, b, .5)! + d * .07;
      seams
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy);
      final s = d * -.045;
      glints
        ..moveTo(a.dx + s.dx + n.dx * .14, a.dy + s.dy + n.dy * .14)
        ..quadraticBezierTo(
          mid.dx + s.dx,
          mid.dy + s.dy,
          b.dx + s.dx - n.dx * .05,
          b.dy + s.dy - n.dy * .05,
        );
    }
    return (fill: fill, seams: seams, glints: glints, edge: _open(inner));
  }();

  /// Scale rows across the flank: each scale is a downward arc. The pitch
  /// shrinks toward the neck and the haunch (foreshortening), and nothing is
  /// laid under the breastplate.
  static final _scales = () {
    final p = Path();
    var y = -.95;
    var row = 0;
    while (y < 1.6) {
      final pitch =
          .21 + .13 * _smooth(1 - ((y - .55).abs() / 1.5).clamp(0.0, 1.0));
      var x = -1.45 + (row.isOdd ? .17 : 0.0);
      while (x < 2.3) {
        final q = .34 - .1 * _smooth(((x - .9) / 1.3).clamp(0.0, 1.0));
        if (Offset(x, y).distance > 1.08) {
          p
            ..moveTo(x - q / 2, y)
            ..quadraticBezierTo(x, y + pitch * 1.35, x + q / 2, y);
        }
        x += q;
      }
      y += pitch;
      row++;
    }
    return p;
  }();
  static final _scalesLip = _scales.shift(const Offset(0, -.05));

  /// The two back spines, one bold and one small: rooted on the back line
  /// where the wing's membrane meets the flank, swept back. They are painted
  /// with the heart, in front of the near wing.
  static final _dorsal = () {
    final items = <(Offset, Offset, Offset, double)>[];
    for (final (seg, t, len) in const [(2, .55, .56)]) {
      final at = _torsoAt(seg, t);
      final d = DragonKit.unit(_torsoAt(seg, t + .03) - _torsoAt(seg, t - .03));
      final out = Offset(d.dy, -d.dx);
      const rake = .5;
      items.add((
        at - out * .04,
        DragonKit.unit(out * math.cos(rake) + d * math.sin(rake)),
        d,
        len,
      ));
    }
    return items;
  }();

  /// A soft ring of shade in a unit circle (clear inside, darkest at .68,
  /// gone at 1): where the shoulder and the thigh press on the body.
  static final Paint _aoRing = DragonKit.radial(
    Offset.zero,
    1,
    [
      DragonPalette.scaleCore.withValues(alpha: 0),
      DragonPalette.scaleCore.withValues(alpha: .55),
      DragonPalette.scaleCore.withValues(alpha: 0),
    ],
    const [.5, .68, 1],
  );

  /// A glossy catch-light on the lit chest, the house style's shine.
  static final _chestGloss = Path()
    ..moveTo(-1.27, .16)
    ..quadraticBezierTo(-1.24, -.32, -.9, -.6)
    ..moveTo(-1.2, .44)
    ..quadraticBezierTo(-1.25, .34, -1.27, .28);

  /// The molten fissures that run out of the breastplate's gaps across the
  /// body, tapering as they go: as a dark crease, a bloom and a white-hot
  /// core. The upper ones are dim, the lower ones (toward the belly, where
  /// the fire's light falls) hot.
  static final _fissures = () {
    List<Offset> way(double angle, List<(double, double)> ways) {
      final d = DragonKit.heading(angle), n = Offset(-d.dy, d.dx);
      return [for (final (r, side) in ways) d * r + n * side];
    }

    Path group(List<List<Offset>> cracks, double w0, double w1) {
      final path = Path();
      for (final c in cracks) {
        path.addPath(_taper(c, w0, w1), Offset.zero);
      }
      return path;
    }

    final high = [
      way(_gap(5), const [(.7, 0), (.95, .04), (1.12, -.05), (1.28, .02)]),
      way(_gap(6), const [(.7, 0), (.95, -.04), (1.1, .05), (1.24, -.02)]),
    ];
    // Three cracks, not six: the two long ones run down toward the belly's
    // plates and a short one toward the haunch.
    final low = [
      way(_gap(1), const [
        (.7, 0),
        (.92, .05),
        (1.1, -.05),
        (1.28, .04),
        (1.42, -.03),
      ]),
      way(_gap(2), const [
        (.7, 0),
        (.95, -.06),
        (1.14, .06),
        (1.34, -.06),
        (1.55, .06),
        (1.76, -.04),
        (1.98, .03),
      ]),
      way(_gap(3), const [
        (.7, 0),
        (.95, .06),
        (1.16, -.06),
        (1.38, .06),
        (1.6, -.05),
        (1.8, .03),
        (2.0, -.02),
      ]),
    ];
    return (
      highCrease: group(high, .17, .05),
      highBloom: group(high, .1, .028),
      highCore: group(high, .04, .01),
      lowCrease: group(low, .2, .05),
      lowBloom: group(low, .125, .03),
      lowCore: group(low, .055, .014),
    );
  }();

  // ---- the breastplate and gem ----

  static const _petals = 7;
  static const _petalFirst = -math.pi / 3;

  /// The angle of the gap after petal [k]: the breastplate's cracks leave here.
  static double _gap(int k) => _petalFirst + (k + .5) * 2 * math.pi / _petals;

  /// The tip radius of each petal. They stay at .90 or more (the gem is the
  /// clearest target only while the ring fills the hit circle) but well short
  /// of its edge, so the ring reads as armour on the chest and not as a badge.
  static const _petalTip = [.93, .93, .93, .93, .92, .91, .90];

  /// The six breastplate petals for a chest opened by [open] (0..1): the
  /// whole outline, the lit halves (each petal is a two-faced ridge), the
  /// ridge lines, the sky's catch-light and the inner edges that the gem's
  /// fire warms. Opening swings each petal about a hinge near its tip and
  /// slides it outward, baring the molten bed beneath. Every tip stays
  /// inside the hit circle.
  static ({Path all, Path lit, Path sky, Path glint, Path inner}) _petalsFor(
    double open,
  ) {
    const lightDir = Offset(-.55, -.83);
    final all = Path(), lit = Path(), sky = Path(), glint = Path();
    final inner = Path();
    for (var k = 0; k < _petals; k++) {
      final phi = _petalFirst + k * 2 * math.pi / _petals;
      final rt = _petalTip[k];
      final hinge = _polar(phi, rt - .08);
      Offset tf(double r, double d) {
        final rr = rt - (rt - r) * (1 - .22 * open);
        final pt = _polar(phi + d, rr);
        if (open == 0) return pt;
        return hinge + DragonKit.turn(pt - hinge, open * .34);
      }

      final inL = tf(.52, -.34), inR = tf(.52, .34);
      final midL = tf(.72, -.39), midR = tf(.72, .39);
      final tipL = tf(rt - .2, -.13), tipR = tf(rt - .2, .13);
      final tip = tf(rt, 0), inMid = tf(.52, 0);
      final inCtl = tf(.52 / math.cos(.34), 0);
      // The sides bow outward at the shoulder and hollow toward the tip, so a
      // plate ends in a thorn.
      final shR = tf(.86, .22), shL = tf(.86, -.22);
      all
        ..moveTo(inL.dx, inL.dy)
        ..quadraticBezierTo(inCtl.dx, inCtl.dy, inR.dx, inR.dy)
        ..quadraticBezierTo(tf(.6, .42).dx, tf(.6, .42).dy, midR.dx, midR.dy)
        ..quadraticBezierTo(tipR.dx, tipR.dy, tip.dx, tip.dy)
        ..quadraticBezierTo(tipL.dx, tipL.dy, midL.dx, midL.dy)
        ..quadraticBezierTo(tf(.6, -.42).dx, tf(.6, -.42).dy, inL.dx, inL.dy)
        ..close();
      // The half that faces the sky is the lit one.
      final rad = DragonKit.heading(phi), tan = Offset(-rad.dy, rad.dx);
      final nA = tan * -.85 + rad * .5, nB = tan * .85 + rad * .5;
      final dA = nA.dx * lightDir.dx + nA.dy * lightDir.dy;
      final dB = nB.dx * lightDir.dx + nB.dy * lightDir.dy;
      final aLit = dA >= dB;
      if (aLit) {
        lit.addPolygon([inL, midL, shL, tip, inMid], true);
      } else {
        lit.addPolygon([inMid, tip, shR, midR, inR], true);
      }
      // Only the plates that face the sky keep a lit edge, and the ones that
      // face it squarely catch one hard white glint: no spokes, no ticks.
      final facing = aLit ? dA : dB;
      if (facing > .3) {
        final a = aLit ? midL : midR, b = aLit ? shL : shR;
        sky
          ..moveTo(a.dx, a.dy)
          ..lineTo(b.dx, b.dy)
          ..lineTo(tip.dx, tip.dy);
      }
      if (facing > .62) {
        final a = aLit ? midL : midR, b = aLit ? shL : shR;
        final g0 = Offset.lerp(a, b, .18)!, g1 = Offset.lerp(a, b, .62)!;
        final inward = (inMid - a) * .07;
        glint
          ..moveTo(g0.dx + inward.dx, g0.dy + inward.dy)
          ..lineTo(g1.dx + inward.dx, g1.dy + inward.dy);
      }
      inner
        ..moveTo(inL.dx, inL.dy)
        ..quadraticBezierTo(inCtl.dx, inCtl.dy, inR.dx, inR.dy);
    }
    return (all: all, lit: lit, sky: sky, glint: glint, inner: inner);
  }

  static final _petalsRest = _petalsFor(0);

  /// The gem, cut with seven facets, in a unit circle: the girdle, the
  /// table, the facets that face the sky (bright) and away from it (dark)
  /// and the cut lines between them.
  static final _gem = () {
    const n = 7;
    final g = [
      for (var i = 0; i < n; i++)
        _polar(-math.pi / 2 + i * 2 * math.pi / n, 1.0),
    ];
    final t = [
      for (var i = 0; i < n; i++)
        _polar(-math.pi / 2 + (i + .5) * 2 * math.pi / n, .5),
    ];
    final towardLight = math.atan2(-.83, -.55);
    double face(double angle) => math.cos(angle - towardLight);
    final bright = Path(), dim = Path(), edges = Path();
    for (var i = 0; i < n; i++) {
      final j = (i + 1) % n, h = (i + n - 1) % n;
      // The kite between two girdle corners, pointing at the table.
      final aOut = -math.pi / 2 + (i + .5) * 2 * math.pi / n;
      final fOut = face(aOut);
      if (fOut > .3) bright.addPolygon([g[i], g[j], t[i]], true);
      if (fOut < -.25) dim.addPolygon([g[i], g[j], t[i]], true);
      // The triangle under a girdle corner, flatter than the kites.
      final aIn = -math.pi / 2 + i * 2 * math.pi / n;
      final fIn = face(aIn);
      if (fIn > .55) bright.addPolygon([t[h], t[i], g[i]], true);
      if (fIn < -.4) dim.addPolygon([t[h], t[i], g[i]], true);
      edges
        ..moveTo(t[i].dx, t[i].dy)
        ..lineTo(g[i].dx, g[i].dy)
        ..moveTo(t[i].dx, t[i].dy)
        ..lineTo(g[j].dx, g[j].dy)
        ..moveTo(t[i].dx, t[i].dy)
        ..lineTo(t[j].dx, t[j].dy);
    }
    return (
      girdle: Path()..addPolygon(g, true),
      table: Path()..addPolygon(t, true),
      bright: bright,
      dim: dim,
      edges: edges,
    );
  }();

  /// A four-point glint in the unit circle.
  static final _glint = Path()
    ..moveTo(0, -1)
    ..quadraticBezierTo(.1, -.1, 1, 0)
    ..quadraticBezierTo(.1, .1, 0, 1)
    ..quadraticBezierTo(-.1, .1, -1, 0)
    ..quadraticBezierTo(-.1, -.1, 0, -1)
    ..close();

  /// The molten bed under the plates, lit from the socket outward and gone
  /// at its rim, so only the gaps between plates show it.
  static final Paint _bed = DragonKit.radial(
    Offset.zero,
    .8,
    [
      DragonPalette.flameYellow,
      DragonPalette.flameGold,
      DragonPalette.flame,
      DragonPalette.flameDark.withValues(alpha: .8),
      DragonPalette.soot.withValues(alpha: 0),
    ],
    const [.55, .66, .78, .9, 1],
  );

  static final Paint _gemBase = DragonKit.radial(
    const Offset(-.18, -.22),
    1.25,
    [
      DragonPalette.flameCore,
      DragonPalette.flameYellow,
      DragonPalette.flameGold,
      DragonPalette.flame,
      DragonPalette.flameDark,
    ],
    const [0, .22, .48, .78, 1],
  );

  /// The defeat's cracks: from the gem, an angle and (radius, sideways)
  /// waypoints out across the plates and the body.
  static const _crackRays = <(double, List<(double, double)>)>[
    (
      -.6,
      [
        (.3, 0),
        (.5, .07),
        (.72, -.06),
        (.95, .08),
        (1.25, -.07),
        (1.6, .07),
        (2.0, -.05),
        (2.4, .05),
      ],
    ),
    (
      .35,
      [
        (.3, 0),
        (.52, -.06),
        (.78, .08),
        (1.05, -.06),
        (1.4, .07),
        (1.8, -.06),
        (2.3, .04),
      ],
    ),
    (
      1.3,
      [
        (.3, 0),
        (.5, .07),
        (.74, -.07),
        (1.0, .07),
        (1.3, -.06),
        (1.66, .06),
        (2.0, -.04),
      ],
    ),
    (
      2.2,
      [
        (.3, 0),
        (.52, -.06),
        (.8, .07),
        (1.06, -.07),
        (1.4, .06),
        (1.8, -.05),
        (2.1, .04),
      ],
    ),
    (
      3.1,
      [
        (.3, 0),
        (.5, .07),
        (.78, -.07),
        (1.0, .06),
        (1.3, -.06),
        (1.6, .05),
        (1.9, -.04),
      ],
    ),
    (
      4.0,
      [(.3, 0), (.52, -.07), (.8, .06), (1.04, -.06), (1.34, .06), (1.6, -.04)],
    ),
    (
      5.0,
      [(.3, 0), (.5, .07), (.76, -.06), (1.0, .06), (1.3, -.05), (1.5, .03)],
    ),
  ];

  /// The cracks out to [reach], only between radii [from] and [to], as thin
  /// tapering polygons ([w0] wide where they start, [w1] where they end).
  static Path _cracks(
    double reach,
    double from,
    double to,
    double w0,
    double w1,
  ) {
    final path = Path();
    final limit = math.min(reach, to);
    for (final (angle, ways) in _crackRays) {
      final d = DragonKit.heading(angle), n = Offset(-d.dy, d.dx);
      Offset pt((double, double) w) => d * w.$1 + n * w.$2;
      final pts = <Offset>[];
      for (var i = 0; i + 1 < ways.length; i++) {
        final a = ways[i], b = ways[i + 1];
        if (b.$1 <= from || a.$1 >= limit) continue;
        final pa = pt(a), pb = pt(b);
        if (pts.isEmpty) {
          pts.add(
            a.$1 < from
                ? Offset.lerp(pa, pb, (from - a.$1) / (b.$1 - a.$1))!
                : pa,
          );
        }
        pts.add(
          b.$1 > limit
              ? Offset.lerp(pa, pb, (limit - a.$1) / (b.$1 - a.$1))!
              : pb,
        );
      }
      if (pts.length > 1) path.addPath(_taper(pts, w0, w1), Offset.zero);
    }
    return path;
  }

  // -------------------------------------------------------------- paint --

  // ------------------------------------------------------- the hide's API --

  /// The torso outline wound counter-clockwise on screen, like every part of
  /// the hide (parts laid in one path fill and clip as their union only if
  /// they wind alike).
  static final Path _torsoCcw = DragonKit.spline(
    DragonKit.winding(DragonLayout.torsoOutline) > 0
        ? DragonLayout.torsoOutline.reversed.toList()
        : DragonLayout.torsoOutline,
  );

  /// The torso for [p] in rig units: swelling with the breath about the
  /// heart, wound counter-clockwise.
  static Path torsoOf(DragonBodyPose p) {
    final breath = _finite(p.breath);
    return breath == 0
        ? _torsoCcw
        : DragonKit.affine(_torsoCcw, 1 + breath * .6, 0, 0, 1 + breath, 0, 0);
  }

  /// A point of the torso's frame as the breath swells it.
  static Offset swell(DragonBodyPose p, Offset local) =>
      Offset(local.dx * (1 + p.breath * .6), local.dy * (1 + p.breath));

  /// A point on the torso outline: segment [seg] (from vertex seg to seg+1)
  /// at [t] in the torso's own frame.
  static Offset torsoAt(int seg, double t) => _torsoAt(seg, t);

  /// The paint for scale rows (the shader-stroke of the torso's rows) and
  /// the tone's plate colour for their lit lip.
  static Paint rowsPaint(DragonTone tone, [double alpha = 1]) =>
      _strokeWith(_look(tone).scaleRows, .055, alpha);

  /// A soft ring of shade round [at] (rig units), radius [r]: where a part
  /// presses on the body (the wing's shoulder plate).
  static void contactRing(Canvas c, Offset at, double r) {
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(r);
    c.drawCircle(Offset.zero, 1, Paint()..shader = _aoRing.shader);
    c.restore();
  }

  /// The torso's scale rows and their lit lip, in the torso's frame.
  static Path get scaleRows => _scales;
  static Path get scaleLip => _scalesLip;

  /// The torso's surface detail for the hide, in the torso's frame swelled by
  /// the breath: scale rows, the chest's gloss, the molten fissures, the
  /// contact shadows of the wing root, shoulder and thigh, and (in defeat) the
  /// cracks. The caller has clipped to the trunk; the belly, the rims and the
  /// ink are the hide's.
  static void torsoDetails(
    Canvas c,
    DragonBodyPose p, {
    Path? rows,
    Path? lip,
  }) {
    p = p.finite;
    final tone = p.tone;
    c.save();
    c.scale(1 + p.breath * .6, 1 + p.breath);
    c.drawPath(
      _scalesLip,
      DragonKit.line(tone.plate(DragonPalette.scaleLit), .05, .55),
    );
    c.drawPath(_scales, rowsPaint(tone));
    c.drawPath(
      _chestGloss,
      DragonKit.line(tone.lit(DragonPalette.scaleSheen), .07, .34),
    );
    _fissuresPaint(c, p, high: false);
    _contactShadows(c);
    _crackedPaint(c, p);
    c.restore();
  }

  /// Everything behind the torso: far legs, tail and the spines along it.
  static void back(Canvas c, DragonBodyPose p) {
    farLegs(c, p);
    tail(c, p);
  }

  /// The far legs, behind the trunk.
  static void farLegs(Canvas c, DragonBodyPose p) {
    _leg(c, p, hind: true, far: true);
    _leg(c, p, hind: false, far: true);
  }

  /// The torso with its scales, seams, belly and rim lights.
  static void torsoPaint(Canvas c, DragonBodyPose p) {
    p = p.finite;
    final tone = p.tone;
    final look = _look(tone);
    final glow = tone.glow;
    c.save();
    // The chest swells with each breath, about the heart.
    c.scale(1 + p.breath * .6, 1 + p.breath);
    c.drawPath(torso, _fillWith(look.torso));
    c.save();
    c.clipPath(torso, doAntiAlias: false);
    // Core shadow: a band inside the lower-right edge, thin on the lit side.
    c.save();
    c.translate(-.16, -.22);
    c.drawPath(
      torso,
      DragonKit.line(tone.plate(DragonPalette.scaleDark), .66, .5),
    );
    c.restore();
    // Tier 2: scale rows, dark arcs with a lit lip, only in the mid tones.
    c.drawPath(
      _scalesLip,
      DragonKit.line(tone.plate(DragonPalette.scaleLit), .05, .55),
    );
    c.drawPath(_scales, _strokeWith(look.scaleRows, .055));
    c.drawPath(
      _chestGloss,
      DragonKit.line(tone.lit(DragonPalette.scaleSheen), .07, .34),
    );
    _fissuresPaint(c, p);
    _contactShadows(c);
    // The banded belly.
    c.drawPath(_belly.fill, _fillWith(look.belly));
    c.drawPath(_belly.seams, DragonKit.line(DragonPalette.inkWarm, .045, .95));
    c.drawPath(
      _belly.glints,
      DragonKit.line(tone.lit(DragonPalette.bellyLit), .03, .85),
    );
    c.drawPath(_belly.edge, DragonKit.line(DragonPalette.inkWarm, .06, .9));
    // Rim lights: the sky's along the upper-left edge, the fire's under the
    // keel. The one clip serves them both; the ink comes after, outside it.
    final wide = 1 + tone.dark * .7;
    c.save();
    c.translate(.05, .05);
    c.drawPath(torso, DragonKit.line(_skyRim(tone), .1 * wide, tone.skyRim));
    c.restore();
    c.save();
    c.translate(-.015, -.06);
    c.drawPath(
      torso,
      DragonKit.line(
        tone.lit(DragonPalette.rimFire),
        .12,
        tone.fireRim * (.5 + glow * .5),
      ),
    );
    c.restore();
    _crackedPaint(c, p);
    c.restore();
    DragonKit.inkHero(c, torso, DragonLayout.inkHero);
    c.restore();
  }

  /// Tier 1: the molten fissures out of the breastplate, in a dark crease.
  /// Painted in the torso's frame, inside a clip of the body.
  ///
  /// The two upper cracks leave the plates toward the neck's root, past the
  /// torso's own edge: on their own the neck covers their tips, in the hide
  /// they would show on the neck, so the hide leaves them out ([high] false).
  static void _fissuresPaint(Canvas c, DragonBodyPose p, {bool high = true}) {
    final tone = p.tone;
    final glow = tone.glow;
    final pulse = p.time == 0 ? 1.0 : 1 + math.sin(p.time * 2.4) * .1;
    final f = _fissures;
    final hotness = math.max(p.open, math.max(tone.fury, tone.heat));
    // Lit from within even at rest: a thin white-hot core down a warm bloom,
    // not a brown scratch (the crease around it is only a shade of the plate).
    c.drawPath(f.lowCrease, DragonKit.fill(DragonPalette.scaleCore, .7));
    c.drawPath(
      f.lowBloom,
      DragonKit.fill(
        tone.seam,
        ((.88 + hotness * .12) * pulse).clamp(0.0, 1.0),
      ),
    );
    c.drawPath(
      f.lowCore,
      DragonKit.fill(
        DragonPalette.seamHot,
        (.45 + .4 * glow + hotness * .15).clamp(0.0, 1.0),
      ),
    );
    if (high && hotness > .05) {
      // The upper cracks only wake when the fire does.
      c.drawPath(
        f.highCrease,
        DragonKit.fill(DragonPalette.scaleCore, .85 * hotness),
      );
      c.drawPath(
        f.highBloom,
        DragonKit.fill(tone.seam, (hotness * .9 * pulse).clamp(0.0, 1.0)),
      );
      if (glow > .5) {
        c.drawPath(
          f.highCore,
          DragonKit.fill(DragonPalette.seamHot, glow * .7 * hotness),
        );
      }
    }
  }

  /// Ambient occlusion where other parts sit on the body: the wing root, the
  /// shoulder, the thigh.
  static void _contactShadows(Canvas c) {
    final ao = Paint()
      ..color = DragonPalette.scaleCore.withValues(alpha: .5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .44
      ..strokeCap = StrokeCap.round;
    c.drawPath(
      Path()
        ..moveTo(.55, -1.0)
        ..quadraticBezierTo(1.7, -.7, 2.45, .45),
      ao,
    );
    for (final (at, r) in const [
      (Offset(-.92, .86), .85),
      (Offset(1.55, .7), 1.0),
    ]) {
      c.save();
      c.translate(at.dx, at.dy);
      c.scale(r);
      c.drawCircle(Offset.zero, 1, Paint()..shader = _aoRing.shader);
      c.restore();
    }
  }

  /// The defeat's cracks across the body.
  static void _crackedPaint(Canvas c, DragonBodyPose p) {
    if (p.crack > 0) {
      final reach = .3 + p.crack * 2.3;
      c.drawPath(
        _cracks(reach, .98, 3, .2, .05),
        DragonKit.fill(DragonPalette.scaleCore, .92),
      );
      c.drawPath(
        _cracks(reach, .98, 3, .11, .03),
        DragonKit.fill(DragonPalette.seam),
      );
      c.drawPath(
        _cracks(reach, .98, 3, .04, .012),
        DragonKit.fill(DragonPalette.seamHot),
      );
    }
  }

  /// The breastplate over the neck's root and the heart-gem in it. It is the
  /// hit circle, so nothing but the reaching foreleg's shoulder may cover it.
  static void heart(Canvas c, DragonBodyPose p) {
    p = p.finite;
    final tone = p.tone;
    final look = _look(tone);
    final light = p.heart.clamp(0.0, 1.0);
    // The plates breathe a little even when the chest is shut.
    final breathe = p.time == 0
        ? 0.0
        : (math.sin(p.time * 2.2) * .5 + .5) * .07;
    final open = (p.open + breathe).clamp(0.0, 1.0);
    final pulse = p.time == 0 ? 0.0 : math.sin(p.time * 7) * .06;
    final petals = open == 0 ? _petalsRest : _petalsFor(open);

    // The back spines, in front of the wing's root; taller in fury.
    final sc = 1 + tone.fury * .25;
    final sx = 1 + p.breath * .6, sy = 1 + p.breath;
    _spines(c, tone, [
      for (final (at, dir, along, len) in _dorsal)
        (Offset(at.dx * sx, at.dy * sy), dir, along, len * sc),
    ]);

    // The gem's light spills out around the armour.
    DragonKit.glow(
      c,
      Offset.zero,
      1.0 + open * .25 + pulse + tone.fury * .08,
      DragonPalette.flameGold,
      .18 + light * .3,
    );
    // The bed: molten light under the plates, seen in every gap.
    c.drawCircle(Offset.zero, .8, _fillWith(_bed.shader!, .6 + .4 * light));
    final gaps = Path();
    final reach = .55 + open * .3;
    for (var k = 0; k < _petals; k++) {
      final phi =
          _petalFirst + (k + .5) * 2 * math.pi / _petals + open * .34 * .5;
      final a = _polar(phi, .4), b = _polar(phi, .45 + reach * .5);
      gaps
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy);
    }
    DragonKit.moltenSeam(c, gaps, tone, width: .1, alpha: .7 + .3 * light);

    // The plates: a cast shadow, the dark body of each, its lit half, the
    // ridge, the sky's catch-light and the ink.
    c.save();
    c.translate(.04, .06);
    c.drawPath(petals.all, DragonKit.fill(DragonPalette.scaleCore, .5));
    c.restore();
    c.drawPath(petals.all, DragonKit.fill(tone.plate(DragonPalette.scaleDeep)));
    c.drawPath(
      petals.lit,
      DragonKit.fill(
        tone.plate(
          Color.lerp(DragonPalette.scale, DragonPalette.scaleLit, .35)!,
        ),
      ),
    );
    c.drawPath(
      petals.sky,
      DragonKit.line(_skyRim(tone), .04, (tone.skyRim * .9).clamp(0.0, 1.0)),
    );
    c.drawPath(
      petals.glint,
      DragonKit.line(tone.lit(DragonPalette.white), .045, .85),
    );
    if (open > .05 || tone.fury > 0) {
      // The gem's fire warms the plates' inner edges.
      c.drawPath(
        petals.inner,
        DragonKit.line(
          DragonPalette.seam,
          .06,
          math.max(open, tone.fury * .6).clamp(0.0, 1.0),
        ),
      );
    }
    c.drawPath(petals.all, DragonKit.line(_ink, .036));

    // The socket: a dark well ringed in gold-deep.
    c.drawCircle(Offset.zero, .485, DragonKit.fill(DragonPalette.scaleCore));
    c.drawCircle(
      Offset.zero,
      .415,
      Paint()
        ..shader = look.bezel
        ..style = PaintingStyle.stroke
        ..strokeWidth = .08,
    );
    c.drawCircle(
      Offset.zero,
      .368,
      DragonKit.line(DragonPalette.goldShade, .035, .9),
    );
    c.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: .435),
      math.pi * .78,
      math.pi * .55,
      false,
      DragonKit.line(tone.lit(DragonPalette.goldLit), .03, .95),
    );

    // The gem.
    final r = .3 + open * .08 + pulse * .3;
    final s = 1 / r;
    c.save();
    c.scale(r);
    c.drawPath(_gem.girdle, Paint()..shader = _gemBase.shader);
    // At rest it smoulders: the facets away from the sky are banked, the
    // table stays white-hot.
    if (light < .6) {
      c.drawPath(
        _gem.girdle,
        DragonKit.fill(DragonPalette.flameDark, (.6 - light) * 1.3),
      );
    }
    c.drawPath(
      _gem.dim,
      DragonKit.fill(DragonPalette.flameDark, .32 + (1 - light) * .3),
    );
    c.drawPath(_gem.bright, DragonKit.fill(DragonPalette.white, .42));
    c.drawPath(
      _gem.table,
      DragonKit.fill(DragonPalette.flameCore, .55 + .45 * light),
    );
    if (p.crit > 0) {
      c.drawPath(_gem.girdle, DragonKit.fill(DragonPalette.white, p.crit * .8));
    }
    c.drawPath(
      _gem.edges,
      DragonKit.line(DragonPalette.flameDark, .03 * s, .55 - p.crit * .3),
    );
    c.drawPath(_gem.girdle, DragonKit.line(_ink, .05 * s));
    final tw = p.time == 0 ? .85 : .7 + .3 * math.sin(p.time * 5.3);
    c.save();
    c.translate(-.42, -.46);
    c.scale(.34 + .1 * tw);
    c.drawPath(_glint, DragonKit.fill(DragonPalette.white, tw));
    c.restore();
    c.restore();

    if (p.crit > 0) {
      // A struck heart flares white.
      DragonKit.glow(
        c,
        Offset.zero,
        .7 + p.crit * .6,
        DragonPalette.white,
        p.crit * .85,
      );
    }
    if (p.crack > 0) {
      final reach = .3 + p.crack * 2.3;
      c.drawPath(
        _cracks(reach, .3, .98, .2, .18),
        DragonKit.fill(DragonPalette.scaleCore, .92),
      );
      c.drawPath(
        _cracks(reach, .3, .98, .11, .1),
        DragonKit.fill(DragonPalette.seam),
      );
      c.drawPath(
        _cracks(reach, .3, .98, .04, .035),
        DragonKit.fill(DragonPalette.seamHot),
      );
    }
  }

  /// The near legs, over the torso.
  static void front(Canvas c, DragonBodyPose p) {
    _leg(c, p, hind: true, far: false);
  }

  /// The near foreleg, drawn over the neck's base.
  static void foreleg(Canvas c, DragonBodyPose p) {
    _leg(c, p, hind: false, far: false);
  }

  // ------------------------------------------------------------- spines --

  /// A row of bone thorns as up to four draws: [items] are (root, direction,
  /// along the surface, length). The base tucks under the body. [shaded] gives
  /// the shaft its dark root and its pale tip: the shafts are `boneDeep`, so
  /// only the points are light and a row of thorns is an accent, not a rash of
  /// cream specks.
  static void _spines(
    Canvas c,
    DragonTone tone,
    List<(Offset, Offset, Offset, double)> items, {
    bool shaded = true,
  }) {
    final body = Path(), root = Path(), point = Path();
    for (final (at, dir, along, len) in items) {
      final bw = len * .34;
      final base = at - dir * .07;
      final tip = at + dir * len + along * len * .2;
      final ctl1 = at + dir * len * .58 - along * bw * .45;
      final ctl2 = at + dir * len * .45 + along * bw * .55;
      body
        ..moveTo(base.dx - along.dx * bw, base.dy - along.dy * bw)
        ..quadraticBezierTo(ctl1.dx, ctl1.dy, tip.dx, tip.dy)
        ..quadraticBezierTo(
          ctl2.dx,
          ctl2.dy,
          base.dx + along.dx * bw,
          base.dy + along.dy * bw,
        )
        ..close();
      if (!shaded) continue;
      final m = at + dir * len * .38 + along * len * .05;
      root
        ..moveTo(base.dx - along.dx * bw, base.dy - along.dy * bw)
        ..lineTo(m.dx - along.dx * bw * .5, m.dy - along.dy * bw * .5)
        ..lineTo(m.dx + along.dx * bw * .5, m.dy + along.dy * bw * .5)
        ..lineTo(base.dx + along.dx * bw, base.dy + along.dy * bw)
        ..close();
      final k = at + dir * len * .6 + along * len * .07;
      point
        ..moveTo(k.dx - along.dx * bw * .3, k.dy - along.dy * bw * .3)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(k.dx + along.dx * bw * .36, k.dy + along.dy * bw * .36)
        ..close();
    }
    c.drawPath(
      body,
      DragonKit.fill(
        tone.lit(
          shaded
              ? DragonPalette.boneDeep
              : Color.lerp(DragonPalette.boneDeep, DragonPalette.bone, .4)!,
        ),
      ),
    );
    if (shaded) {
      c.drawPath(root, DragonKit.fill(DragonPalette.boneShade, .8));
      c.drawPath(point, DragonKit.fill(tone.lit(DragonPalette.boneLit), .95));
    }
    c.drawPath(body, DragonKit.line(_ink, DragonLayout.inkPart));
  }

  /// A bone spine (the neck's crest uses it too): a curved thorn rooted at
  /// [at], [size] long, pointing along [angle] and swept back toward the tail.
  ///
  /// Drawn in its own frame (root at the origin, +x toward the tip) so one
  /// cached bone gradient serves every spine.
  static void spine(
    Canvas c,
    Offset at,
    double size,
    double angle,
    DragonTone tone, {
    double shade = 1,
  }) {
    final d = DragonKit.heading(angle), n = Offset(-d.dy, d.dx);
    final tip = at + d * size + const Offset(.16, 0) * size;
    final rot = math.atan2(tip.dy - at.dy, tip.dx - at.dx);
    Offset local(Offset world) => DragonKit.turn(world - at, -rot);
    final a = local(at - n * size * .4);
    final k1 = local(at + d * size * .5 - n * size * .25);
    final t = local(tip);
    final k2 = local(at + d * size * .35 + n * size * .35);
    final b = local(at + n * size * .45);
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(k1.dx, k1.dy, t.dx, t.dy)
      ..quadraticBezierTo(k2.dx, k2.dy, b.dx, b.dy)
      ..close();
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(rot);
    c.drawPath(
      path,
      shade >= 1
          ? _fillWith(_look(tone).spine)
          : DragonKit.fill(DragonKit.shade(DragonPalette.boneDeep, shade)),
    );
    c.drawPath(path, DragonKit.line(_ink, DragonLayout.inkPart));
    c.restore();
  }

  // --------------------------------------------------------------- tail --

  static final List<Offset> _tailAnchors = [
    DragonLayout.tailSpine[0] -
        (DragonLayout.tailSpine[1] - DragonLayout.tailSpine[0]) * .55,
    ...DragonLayout.tailSpine,
  ];

  /// The tail is a little slimmer than the layout's widths, most at its root
  /// (a heavy stub read as a chibi's; the layout's numbers stay the envelope's
  /// truth: this only removes flesh).
  static const _tailSlim = [.84, .84, .875, .88, .91, .93, .94];
  static final List<double> _tailAnchorW = [
    for (var i = 0; i < DragonLayout.tailWidths.length + 1; i++)
      DragonLayout.tailWidths[math.max(0, i - 1)] * _tailSlim[i],
  ];

  static final List<Offset> _tailBase = [
    for (var a = 0; a < _tailAnchors.length - 1; a++)
      for (var k = 0; k < 2; k++) _catmull(_tailAnchors, a, k / 2),
    _tailAnchors.last,
  ];
  static final List<double> _tailW = [
    for (var a = 0; a < _tailAnchors.length - 1; a++)
      for (var k = 0; k < 2; k++) _catmullD(_tailAnchorW, a, k / 2),
    _tailAnchorW.last,
  ];

  /// The blade in its own frame: origin at the tail's tip, +x along the tail,
  /// +y toward the belly. Two swept-back barbs, a long hooked point.
  static final _blade = Path()
    ..moveTo(0, -.13)
    ..quadraticBezierTo(-.06, -.32, -.24, -.47)
    ..quadraticBezierTo(.1, -.42, .27, -.28)
    ..quadraticBezierTo(.55, -.2, .9, .14)
    ..quadraticBezierTo(.56, .22, .3, .3)
    ..quadraticBezierTo(.1, .44, -.22, .48)
    ..quadraticBezierTo(-.06, .32, 0, .13)
    ..close();
  static const _bladeInk = .164 * .68;
  static final _bladeSpar = Path()
    ..moveTo(-.04, 0)
    ..quadraticBezierTo(.5, -.02, .86, .12);
  static final _bladeRibs = Path()
    ..moveTo(.2, -.01)
    ..quadraticBezierTo(.16, -.16, .02, -.3)
    ..moveTo(.2, -.01)
    ..quadraticBezierTo(.15, .14, .04, .3)
    ..moveTo(.46, .0)
    ..quadraticBezierTo(.4, -.1, .28, -.2)
    ..moveTo(.46, .0)
    ..quadraticBezierTo(.4, .1, .32, .2);

  /// The tail for [p]: its spine bent by the pose, both edges, the outline
  /// and the tip. Built once a frame and shared by [tail] (standalone) and
  /// the hide.
  static DragonTail tailOf(DragonBodyPose p) {
    p = p.finite;
    final n = _tailBase.length;
    final double Function(double) rawBend = identical(p.bend, _straight)
        ? (u) => p.tailSway * .25 * u * u
        : p.bend;
    double bend(double u) => _finite(rawBend(u)).clamp(-.8, .8);
    final spine = <Offset>[];
    final belly = <Offset>[], dorsal = <Offset>[];
    for (var i = 0; i < n; i++) {
      final u = ((i / 2 - 1) / 5).clamp(0.0, 1.0);
      spine.add(_tailBase[i] + Offset(0, bend(u)));
    }
    final dirs = <Offset>[];
    for (var i = 0; i < n; i++) {
      final d = DragonKit.unit(
        spine[math.min(i + 1, n - 1)] - spine[math.max(i - 1, 0)],
      );
      dirs.add(d);
      final nrm = Offset(-d.dy, d.dx), w = _tailW[i] / 2;
      belly.add(spine[i] + nrm * w);
      dorsal.add(spine[i] - nrm * w);
    }
    final end = spine.last, endDir = dirs.last;
    final endN = Offset(-endDir.dy, endDir.dx), endW = _tailW.last / 2;
    // The outline: belly side out, a rounded tip, dorsal side back.
    final ring = <Offset>[
      ...belly,
      end + endN * endW * .7 + endDir * endW * .7,
      end + endDir * endW,
      end - endN * endW * .7 + endDir * endW * .7,
      ...dorsal.reversed,
    ];
    return DragonTail._(
      spine: spine,
      dirs: dirs,
      belly: belly,
      dorsal: dorsal,
      shape: DragonKit.spline(ring),
      end: end,
      endDir: endDir,
    );
  }

  /// The tail's spines and its blade: everything that lies BEHIND the tail's
  /// body (its roots and the blade's stem are covered by it).
  static void tailUnder(Canvas c, DragonBodyPose p, DragonTail t) {
    p = p.finite;
    final tone = p.tone;
    final look = _look(tone);
    // Spines along the crest, drawn first so the body covers their roots.
    final scale = 1 + tone.fury * .25;
    const rake = .62;
    final items = <(Offset, Offset, Offset, double)>[];
    // One bold accent near the root and one small one after it.
    const at = [3, 7];
    const lens = [.58, .3];
    for (var k = 0; k < at.length; k++) {
      final i = at[k];
      final d = t.dirs[i], out = Offset(d.dy, -d.dx);
      final dir = DragonKit.unit(out * math.cos(rake) + d * math.sin(rake));
      items.add((t.dorsal[i], dir, d, lens[k] * scale));
    }
    _spines(c, tone, items);

    // The blade, behind the tail's tip.
    c.save();
    c.translate(t.end.dx, t.end.dy);
    c.rotate(math.atan2(t.endDir.dy, t.endDir.dx));
    c.drawPath(_blade, _fillWith(look.blade));
    c.drawPath(
      _bladeRibs,
      DragonKit.line(DragonPalette.membraneDark, .035, .7),
    );
    c.drawPath(
      _bladeSpar,
      DragonKit.line(tone.lit(DragonPalette.boneDeep), .085),
    );
    c.drawPath(
      _bladeSpar,
      DragonKit.line(tone.lit(DragonPalette.boneLit), .03, .9),
    );
    // The blade's ink is the tail's own line weight: the hide's trunk stroke is
    // .164 centred with its inner half buried under the skin (.082 shows); the
    // blade shows both halves, so it takes .68 of it (~.11 visible), a step
    // heavier than the tail's edge and in the same hand, not a hairline.
    c.drawPath(_blade, DragonKit.line(_ink, _bladeInk));
    c.restore();
  }

  /// The tail: a heavy root sweeping down and out, hooking under itself,
  /// with a spined crest, banded belly plates below, molten rings between the
  /// segments and a bone-and-membrane blade at the tip.
  static void tail(Canvas c, DragonBodyPose p) {
    p = p.finite;
    final tone = p.tone;
    final look = _look(tone);
    final t = tailOf(p);
    final n = t.spine.length;
    final spine = t.spine, belly = t.belly, dorsal = t.dorsal, dirs = t.dirs;
    tailUnder(c, p, t);
    final shape = t.shape;

    // The body.
    c.drawPath(shape, _fillWith(look.tail));
    // Belly plates: an amber band up the underside, tapering to the tip.
    final inner = <Offset>[
      for (var i = 0; i < n; i++)
        Offset.lerp(belly[i], spine[i], .72 * (1 - .45 * i / (n - 1)))!,
    ];
    const k0 = 2, k1 = 10;
    final band = Path()..moveTo(belly[k0].dx, belly[k0].dy);
    _curveThrough(band, belly.sublist(k0, k1 + 1));
    band.lineTo(inner[k1].dx, inner[k1].dy);
    _curveThrough(band, inner.sublist(k0, k1 + 1).reversed.toList());
    band.close();
    c.drawPath(band, _fillWith(look.belly));
    final cuts = Path(), rings = Path(), glints = Path();
    for (var i = k0 + 1; i <= k1; i++) {
      cuts
        ..moveTo(belly[i].dx, belly[i].dy)
        ..lineTo(inner[i].dx, inner[i].dy);
      final g = dirs[i] * -.04;
      glints
        ..moveTo(belly[i].dx + g.dx, belly[i].dy + g.dy)
        ..lineTo(inner[i].dx + g.dx, inner[i].dy + g.dy);
      // A ring of scale seam from the crest down to the plate.
      final top = Offset.lerp(dorsal[i], spine[i], .14)!;
      final bot = inner[i];
      final mid = Offset.lerp(top, bot, .5)! - dirs[i] * .06;
      rings
        ..moveTo(top.dx, top.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, bot.dx, bot.dy);
    }
    c.drawPath(rings, DragonKit.line(DragonPalette.scaleCore, .06, .8));
    c.drawPath(cuts, DragonKit.line(DragonPalette.inkWarm, .045, .9));
    c.drawPath(
      glints,
      DragonKit.line(tone.lit(DragonPalette.bellyLit), .03, .8),
    );
    // The plates' upper edge is where the light escapes.
    final edge = _open(inner.sublist(k0, k1 + 1));
    c.drawPath(edge, DragonKit.line(DragonPalette.scaleCore, .1, .8));
    DragonKit.moltenSeam(c, edge, tone, width: .055, alpha: .85 + p.open * .15);
    // The sky's light along the crest.
    final crest = [
      for (var i = 2; i < n - 1; i++) Offset.lerp(dorsal[i], spine[i], .17)!,
    ];
    c.drawPath(
      _open(crest),
      DragonKit.line(_skyRim(tone), .075 * (1 + tone.dark * .7), tone.skyRim),
    );
    DragonKit.inkHero(c, shape, DragonLayout.inkHero);
  }

  // --------------------------------------------------------------- legs --

  /// The width of a limb at its ten samples (three to a segment): the hind
  /// leg swells into a thigh, pinches at the knee and hock, and ends in a
  /// stout foot; the foreleg has a shoulder, an elbow and a strong wrist.
  static const _hindWidth = [.92, .94, .80, .56, .50, .42, .36, .40, .40, .36];
  static const _foreWidth = [.62, .68, .62, .52, .50, .46, .40, .44, .44, .40];

  /// A limb along [joints] (Catmull-Rom, three samples a segment) as one
  /// outline with round ends, [width] across at each of its ten samples.
  static ({
    Path shape,
    List<Offset> ring,
    List<Offset> spine,
    List<Offset> left,
    List<Offset> right,
    List<double> width,
  })
  _limb(List<Offset> joints, List<double> width) {
    const per = 3;
    final segs = joints.length - 1;
    final spine = <Offset>[];
    for (var s = 0; s < segs; s++) {
      for (var k = 0; k < per; k++) {
        spine.add(_catmull(joints, s, k / per));
      }
    }
    spine.add(joints.last);
    final n = spine.length;
    final left = <Offset>[], right = <Offset>[];
    final dirs = <Offset>[];
    for (var i = 0; i < n; i++) {
      final d = DragonKit.unit(
        spine[math.min(i + 1, n - 1)] - spine[math.max(i - 1, 0)],
      );
      dirs.add(d);
      final nrm = Offset(-d.dy, d.dx);
      left.add(spine[i] + nrm * (width[i] / 2));
      right.add(spine[i] - nrm * (width[i] / 2));
    }
    // Round caps: quarter-turn points around both ends.
    Offset capAt(int i, double th, double sign) {
      final d = dirs[i], nrm = Offset(-d.dy, d.dx), r = width[i] / 2;
      return spine[i] +
          nrm * (r * math.cos(th)) +
          d * (sign * r * math.sin(th));
    }

    final ring = <Offset>[
      ...left,
      for (final th in const [math.pi / 4, math.pi / 2, 3 * math.pi / 4])
        capAt(n - 1, th, 1),
      ...right.reversed,
      for (final th in const [3 * math.pi / 4, math.pi / 2, math.pi / 4])
        capAt(0, th, -1),
    ];
    return (
      shape: DragonKit.spline(ring),
      ring: ring,
      spine: spine,
      left: left,
      right: right,
      width: width,
    );
  }

  /// Talons at [foot], fanned about [heading] (radians), curled by [curl]
  /// (0 open .. 1 fist), drawn in the foot's own frame so one cached gradient
  /// serves every foot. [hook] is the side they curl toward (+1 or -1); a
  /// dewclaw at [dew] (relative to the heading) hooks the other way.
  static void _talons(
    Canvas c,
    Offset foot,
    double heading,
    double curl,
    DragonTone tone, {
    required bool far,
    required double hook,
    double dew = -.9,
    double size = 1,
  }) {
    final path = Path();
    final spread = .5 - .26 * curl;
    final fist = 1 - .22 * curl;
    // A claw is a curved blade: a centre line that curls toward [hook] and a
    // width that tapers to nothing, so the point is sharp and the root stout.
    void claw(double angle, double len, double wid, double bend) {
      final d = DragonKit.heading(angle), n = Offset(-d.dy, d.dx) * hook;
      const m = 6;
      final left = <Offset>[], right = <Offset>[];
      for (var i = 0; i <= m; i++) {
        final t = i / m;
        final centre = d * (len * t) + n * (bend * len * t * t);
        final tan = DragonKit.unit(d * len + n * (2 * bend * len * t));
        final side = Offset(-tan.dy, tan.dx) * hook;
        final w = wid * (1 - math.pow(t, 1.5));
        left.add(centre + side * w);
        right.add(centre - side * w);
      }
      path.addPolygon([...left, ...right.reversed], true);
    }

    final bend = .28 + .62 * curl;
    claw(-spread * hook, .44 * fist, .12, bend);
    claw(0, .58 * fist, .14, bend);
    claw(spread * hook, .44 * fist, .12, bend);
    if (dew != 0) claw(dew, .3, .085, -.32);
    c.save();
    c.translate(foot.dx, foot.dy);
    c.rotate(heading);
    c.scale(size);
    if (far) {
      // Far claws are one dark shape in the far leg's own shade: solid, no
      // translucency and no ink, so they read as the far foot's shadow claws
      // and not as a grey fringe behind the near one.
      c.drawPath(
        path,
        DragonKit.fill(
          tone.plate(
            Color.lerp(DragonPalette.scaleDark, DragonPalette.boneShade, .18)!,
          ),
        ),
      );
    } else {
      c.drawPath(path, _fillWith(_look(tone).talon));
      c.drawPath(path, DragonKit.line(_ink, DragonLayout.inkPart * .7));
    }
    c.restore();
  }

  /// The leg for [p]: hind or fore, near or far, with its joints swung by the
  /// wingbeat, the kick, the clutch and the defeat's sag.
  static DragonLeg legOf(
    DragonBodyPose p, {
    required bool hind,
    required bool far,
  }) {
    p = p.finite;
    final base = hind ? DragonLayout.hindLeg : DragonLayout.foreLeg;
    final shift = far ? DragonLayout.farLegShift : Offset.zero;
    final swing = hind ? p.hindSwing : p.foreSwing;
    final root = base[0] + shift;
    var knee = root + DragonKit.turn(base[1] - base[0], swing);
    var ankle = root + DragonKit.turn(base[2] - base[0], swing);
    final curl = p.clutch;
    if (hind) {
      // The kick at the snap, the tuck of a clutch, the sag of defeat.
      ankle +=
          Offset(.25 * p.kick, -.08 * p.kick.abs()) + Offset(.1, .1) * p.slump;
      knee += Offset(-.03, -.06) * curl;
    } else {
      ankle += Offset(.06, -.1) * curl + Offset(.1, .3) * p.slump;
    }
    final foot = ankle + (hind ? DragonLayout.hindFoot : DragonLayout.foreFoot);
    // The shoulder starts below the breastplate: a round mass on the chest.
    final start = hind ? root : root + (knee - root) * .32;
    final limb = _limb([
      start,
      knee,
      ankle,
      foot,
    ], hind ? _hindWidth : _foreWidth);
    return DragonLeg._(
      hind: hind,
      far: far,
      knee: knee,
      ankle: ankle,
      foot: foot,
      curl: curl,
      heading: hind ? .95 + curl * .45 : 2.75 - curl * .45,
      hook: hind ? 1.0 : -1.0,
      dew: hind ? -.9 : 1.3,
      spine: limb.spine,
      left: limb.left,
      right: limb.right,
      width: limb.width,
      shape: limb.shape,
      ring: limb.ring,
    );
  }

  /// A near leg's ink contour as one filled ribbon round the limb (edge,
  /// foot, edge back), [DragonLayout.inkMajor] wide where the limb stands
  /// against the sky and thinning to a fine line where it lies on the
  /// trunk. [depth] is how far inside the trunk a point is (negative outside):
  /// the line is full weight at the trunk's edge and fine [_fine] a third of a
  /// unit inside it, so the body's own outline hands over to the limb's
  /// without a step.
  static Path legContour(DragonLeg leg, double Function(Offset) depth) {
    const fine = .026, heavy = DragonLayout.inkMajor;
    final ring = leg.ring;
    // (Depth is a smooth field: every other sample is enough, the ones
    // between are their neighbours' mean.)
    final ramp = List<double>.filled(ring.length, 0);
    for (var i = 0; i < ring.length; i += 2) {
      ramp[i] = depth(ring[i]);
    }
    for (var i = 1; i < ring.length; i += 2) {
      ramp[i] = i + 1 < ring.length
          ? (ramp[i - 1] + ramp[i + 1]) / 2
          : ramp[i - 1];
    }
    final widths = <double>[
      for (final d in ramp)
        DragonKit.mix(heavy, fine, _smooth(((d + .02) / .34).clamp(0.0, 1.0))),
    ];
    return DragonKit.ribbon(ring, widths);
  }

  /// A short hard highlight along the first stretch of [pts]: a pill.
  static Path _pill(List<Offset> pts) => Path()
    ..moveTo(
      Offset.lerp(pts[0], pts[1], .1)!.dx,
      Offset.lerp(pts[0], pts[1], .1)!.dy,
    )
    ..lineTo(
      Offset.lerp(pts[0], pts[1], .85)!.dx,
      Offset.lerp(pts[0], pts[1], .85)!.dy,
    );

  /// A leg: a heavy thigh or shoulder, a jointed shin or forearm and a foot
  /// of hooked bone talons. Far legs sit back in shade and show only shape.
  static void _leg(
    Canvas c,
    DragonBodyPose p, {
    required bool hind,
    required bool far,
  }) => legPaint(c, p, legOf(p, hind: hind, far: far));

  /// The near legs at rest, which their scale rows are laid out on.
  static final _restHind = legOf(
    DragonBodyPose.of(DragonPose.still),
    hind: true,
    far: false,
  );
  static final _restFore = legOf(
    DragonBodyPose.of(DragonPose.still),
    hind: false,
    far: false,
  );

  /// Paints [leg]. On its own ([hide] false) the limb wears a full ink
  /// contour; in the hide it stands opaque in front of the body, its
  /// contour melting into the skin where it lies on the trunk (see
  /// [legContour]) and its shading thinning out toward the root.
  static void legPaint(
    Canvas c,
    DragonBodyPose p,
    DragonLeg leg, {
    bool hide = false,
    double Function(Offset)? depth,
    Paint? fill,
  }) {
    p = p.finite;
    final tone = p.tone;
    final look = _look(tone);
    final hind = leg.hind, far = leg.far;
    final curl = leg.curl, foot = leg.foot;
    final heading = leg.heading, dew = leg.dew, hook = leg.hook;
    final limb = (
      shape: leg.shape,
      spine: leg.spine,
      left: leg.left,
      right: leg.right,
      width: leg.width,
    );
    if (far) {
      c.drawPath(limb.shape, _fillWith(look.limbFar));
      _talons(
        c,
        foot,
        heading,
        curl,
        tone,
        far: true,
        hook: hook,
        dew: dew,
        size: far ? (hind ? .85 : .95) : (hind ? 1 : 1.05),
      );
      c.drawPath(limb.shape, DragonKit.line(_ink, DragonLayout.inkMajor * .75));
      return;
    }
    _talons(
      c,
      foot,
      heading,
      curl,
      tone,
      far: false,
      hook: hook,
      dew: dew,
      size: far ? (hind ? .85 : .95) : (hind ? 1 : 1.05),
    );
    c.drawPath(limb.shape, fill ?? _fillWith(look.limb));

    final n = limb.spine.length;
    // The lit side is the edge that lies more up and to the left.
    double score(List<Offset> e) => e.fold(0.0, (a, o) => a + o.dx + o.dy);
    final leftLit = score(limb.left) < score(limb.right);
    final litEdge = leftLit ? limb.left : limb.right;
    final darkEdge = leftLit ? limb.right : limb.left;
    List<Offset> inset(List<Offset> e, double f, int a, int b) => [
      for (var i = a; i < b; i++) Offset.lerp(e[i], limb.spine[i], f)!,
    ];
    // Armour lames across the muscle: the seams, with every other band
    // lighter so the limb reads as plate.
    final lames = Path(), bands = Path();
    (Offset, Offset, Offset) lame(double at, double bow) {
      final i = at.floor().clamp(0, n - 2), f = at - i;
      final sp = Offset.lerp(limb.spine[i], limb.spine[i + 1], f)!;
      final w = limb.width[i] + (limb.width[i + 1] - limb.width[i]) * f;
      final d = DragonKit.unit(limb.spine[i + 1] - limb.spine[i]);
      final nrm = Offset(-d.dy, d.dx);
      final a = sp + nrm * (w * .41), b = sp - nrm * (w * .41);
      final m = sp + d * bow;
      lames
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(m.dx, m.dy, b.dx, b.dy);
      return (a, m, b);
    }

    final marks = hind
        ? const [.9, 1.8, 2.6, 4.4, 5.6]
        : const [1.3, 2.4, 4.1, 5.2];
    final arcs = [for (final at in marks) lame(at, hind ? .1 : .08)];
    for (var k = 0; k + 1 < arcs.length; k += 2) {
      final (a0, m0, b0) = arcs[k];
      final (a1, m1, b1) = arcs[k + 1];
      bands
        ..moveTo(a0.dx, a0.dy)
        ..quadraticBezierTo(m0.dx, m0.dy, b0.dx, b0.dy)
        ..lineTo(b1.dx, b1.dy)
        ..quadraticBezierTo(m1.dx, m1.dy, a1.dx, a1.dy)
        ..close();
    }
    c.drawPath(bands, DragonKit.fill(tone.plate(DragonPalette.scaleLit), .3));
    c.drawPath(
      lames,
      DragonKit.line(tone.plate(DragonPalette.scaleDark), .055, .9),
    );
    c.drawPath(
      lames.shift(const Offset(-.015, -.05)),
      DragonKit.line(tone.plate(DragonPalette.scaleLit), .035, .55),
    );
    // The torso's scale rows run on across the haunch and the shoulder. In
    // the hide they are laid along the limb itself (no clip needed).
    if (hide) {
      final rows = Path();
      ({Offset centre, Offset normal, double plus, double minus}) Function(
        double,
      )
      frame(List<Offset> spine, List<double> width) => (u) {
        final n = spine.length;
        final i = u.floor().clamp(0, n - 2), t = u - i;
        final d = DragonKit.unit(spine[i + 1] - spine[i]);
        final w = DragonKit.mix(width[i], width[i + 1], t) / 2;
        return (
          centre: Offset.lerp(spine[i], spine[i + 1], t)!,
          normal: Offset(-d.dy, d.dx),
          plus: w,
          minus: w,
        );
      };
      // (Laid out on the resting leg and carried by this one: see
      // [DragonKit.tubeRows].)
      final rest = hind ? _restHind : _restFore;
      DragonKit.tubeRows(
        rows,
        frame(limb.spine, limb.width),
        layout: frame(rest.spine, rest.width),
        from: .6,
        to: hind ? 3.8 : 3.3,
        pitchFrom: .23,
        pitchTo: .19,
        bulge: 1,
        reach: .8,
      );
      c.drawPath(rows, _strokeWith(look.scaleRows, .055, .75));
    } else {
      c.save();
      c.clipPath(limb.shape, doAntiAlias: false);
      c.drawPath(_scales, _strokeWith(look.scaleRows, .055, .75));
      c.restore();
    }
    // Cel shading that follows the form: a hard shadow band along the dark
    // edge, a lighter one along the lit edge, the sky's line on the very
    // edge and the dragon's own fire under the belly-facing side.
    // In the hide a strip thins out toward the root, so it never ends in an
    // edge on the body it grows from.
    Path strip(List<Offset> edge, double f0, double f1) {
      final outer = inset(edge, f0, 1, n - 1);
      final inner = hide
          ? [
              for (var i = 1; i < n - 1; i++)
                Offset.lerp(
                  edge[i],
                  limb.spine[i],
                  f0 + (f1 - f0) * _smooth(((i - 1) / 3).clamp(0.0, 1.0)),
                )!,
            ]
          : inset(edge, f1, 1, n - 1);
      final path = Path()..moveTo(outer.first.dx, outer.first.dy);
      _curveThrough(path, outer);
      path.lineTo(inner.last.dx, inner.last.dy);
      _curveThrough(path, inner.reversed.toList());
      return path..close();
    }

    c.drawPath(
      strip(darkEdge, .1, .62),
      DragonKit.fill(tone.plate(DragonPalette.scaleDeep), .55),
    );
    c.drawPath(
      strip(litEdge, .08, .34),
      DragonKit.fill(tone.plate(DragonPalette.scaleLit), .45),
    );
    // The sky's line on the lit edge, the fire's on the dark one, a sheen on
    // the shoulder. In the hide they are tapered ribbons that begin at
    // nothing, not strokes that stop short on the body.
    Path line(List<Offset> pts, double w) => DragonKit.ribbon(
      pts,
      DragonKit.taper(pts.length, w, head: .35, tail: .12),
    );
    final skyW = .06 * (1 + tone.dark * .7);
    if (hide) {
      c.drawPath(
        line(inset(litEdge, .13, 1, n - 1), skyW),
        DragonKit.fill(_skyRim(tone), tone.skyRim),
      );
      c.drawPath(
        line(inset(darkEdge, .1, 1, n - 1), .045),
        DragonKit.fill(tone.lit(DragonPalette.rimFire), tone.fireRim * .8),
      );
      // One hard pill of white on the lit swell, the roster's shine.
      c.drawPath(
        _pill(inset(litEdge, .34, 1, 4)),
        DragonKit.line(tone.lit(DragonPalette.white), .07, .72),
      );
      c.drawPath(legContour(leg, depth ?? ((_) => 0)), DragonKit.fill(_ink));
    } else {
      c.drawPath(
        _open(inset(litEdge, .13, 1, n - 1)),
        DragonKit.line(_skyRim(tone), skyW, tone.skyRim),
      );
      c.drawPath(
        _open(inset(darkEdge, .1, 1, n - 1)),
        DragonKit.line(
          tone.lit(DragonPalette.rimFire),
          .045,
          tone.fireRim * .8,
        ),
      );
      c.drawPath(
        _pill(inset(litEdge, .34, 1, 4)),
        DragonKit.line(tone.lit(DragonPalette.white), .07, .72),
      );
      c.drawPath(limb.shape, DragonKit.line(_ink, DragonLayout.inkMajor));
    }
    // Bone at the joint that leads, on the hind leg only: one bold knee guard,
    // rooted on the limb's own edge so it grows from the leg whatever its
    // width. (The foreleg's elbow spur went with the spike cull: a hierarchy
    // has a few bold thorns, not one on every joint.)
    if (hind) {
      final j = limb.spine;
      final out = DragonKit.unit(litEdge[3] - j[3]);
      final aim = DragonKit.turn(out, -.3);
      _spines(c, tone, [
        (Offset.lerp(litEdge[3], j[3], .22)!, aim, Offset(-aim.dy, aim.dx), .3),
      ], shaded: false);
    }
  }
}
