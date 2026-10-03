import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/painting.dart';

import 'baron_bat_art.dart';
import 'baron_storm_pose.dart';
import 'boss_rig.dart';

/// The upgraded Baron's storm regalia, layered into [BossRig] (rig units,
/// right side; the rig mirrors the left).
///
/// He is the same crowned, caped elder, powered up: great ribbed sonar
/// ears that flare and glow before a screech, a taller crown with a
/// lightning spire and a sonic gem, a sonic resonator where his gem was,
/// jagged lightning trim on darker storm wings and a storm-torn cape.
/// One accent, sonic pink, marks everything that belongs to the screech,
/// so the glow in his ears reads as the warning for the wall of sound.
abstract final class BaronStormArt {
  /// Sonic pink: the screech and everything that warns of it.
  static const sonic = Color(0xffff7ae0), sonicDeep = Color(0xff9a3cf0);
  static const sonicCore = Color(0xfffff0fb);

  /// In fury the sound runs hot.
  static const furySonic = Color(0xffff5a86), furyDeep = Color(0xffb01e5c);

  static const _well = Color(0xff24163a), _concha = Color(0xffb47ab4);
  static const _rib = Color(0xffe3a2e6), _bronze = Color(0xffb97a3d);
  static const _lining = Color(0xffc2456a), _wine = Color(0xff6e2a4f);
  static const _deepWine = Color(0xff35122f);

  static Color sonicOf(bool fury) => fury ? furySonic : sonic;
  static Color deepOf(bool fury) => fury ? furyDeep : sonicDeep;

  /// Darker, stormier membranes than his debut's.
  static List<Color> wingColors(bool fury) => fury
      ? const [Color(0xffe08db6), Color(0xff69305f), Color(0xff2a1230)]
      : const [Color(0xffa28ade), Color(0xff45397a), Color(0xff1b1530)];

  static Paint _glow(Offset at, double radius, Color color, double alpha) =>
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: alpha.clamp(0.0, 1.0)),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: at, radius: radius));

  // ----------------------------------------------------------------- ears --

  static const _earPivot = Offset(.5, -.56);
  static final _ear = Path()
    ..moveTo(.66, -.38)
    ..quadraticBezierTo(1.06, -.46, 1.16, -.74)
    ..lineTo(1.1, -.88)
    ..quadraticBezierTo(1.42, -1.06, 1.64, -1.5)
    ..quadraticBezierTo(1.1, -1.42, .62, -1.04)
    ..quadraticBezierTo(.36, -.84, .24, -.6)
    ..close();

  /// The inner ear: the outline drawn in toward the ear's middle.
  static final _inner = _ear.transform(
    _about(const Offset(1.0, -1.0), .66, const Offset(-.02, .04)),
  );

  static Float64List _about(Offset center, double k, Offset shift) =>
      Float64List.fromList([
        k, 0, 0, 0, //
        0, k, 0, 0, //
        0, 0, 1, 0, //
        center.dx * (1 - k) + shift.dx, center.dy * (1 - k) + shift.dy, 0, 1,
      ]);

  /// Light along the front edge, and the fur tuft at the root (as the
  /// debut's ears).
  static final _earRim = Path()
    ..moveTo(.36, -.72)
    ..quadraticBezierTo(.9, -1.32, 1.5, -1.46);
  static final _earTuft = Path()
    ..moveTo(.42, -.6)
    ..quadraticBezierTo(.56, -.76, .74, -.8)
    ..quadraticBezierTo(.66, -.72, .7, -.66)
    ..quadraticBezierTo(.8, -.72, .88, -.68)
    ..quadraticBezierTo(.78, -.6, .76, -.5)
    ..close();

  /// Transverse ridges across the ear, bowed toward the tip like sonar
  /// arcs going out.
  static final _ribs = () {
    const root = Offset(.55, -.72), tip = Offset(1.36, -1.28);
    final d = tip - root;
    final along = d / d.distance, across = Offset(-along.dy, along.dx);
    final path = Path();
    for (final (t, w) in const [(.3, .15), (.52, .12), (.74, .085)]) {
      final p = root + d * t;
      final from = p - across * w, to = p + across * w;
      final bow = p + along * .09;
      path
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(bow.dx, bow.dy, to.dx, to.dy);
    }
    return path;
  }();

  /// Where the right ear's tip sits in the pose.
  static Offset earTip(BaronStormPose p) {
    final (angle, scale) = _earTurn(p);
    final v = const Offset(1.6, -1.47) - _earPivot;
    return _earPivot +
        Offset(
              v.dx * math.cos(angle) - v.dy * math.sin(angle),
              v.dx * math.sin(angle) + v.dy * math.cos(angle),
            ) *
            scale;
  }

  static (double, double) _earTurn(BaronStormPose p) =>
      (p.flare * .22 - p.beckon * .14, 1 + p.flare * .2 + p.beckon * .06);

  static void ears(Canvas c, BaronStormPose p, {required bool fury}) {
    final glow = p.glow;
    final hot = sonicOf(fury);
    final (angle, scale) = _earTurn(p);
    for (final side in [-1.0, 1.0]) {
      c.save();
      c.scale(side, 1);
      c.translate(_earPivot.dx, _earPivot.dy);
      c.rotate(angle);
      c.scale(scale);
      c.translate(-_earPivot.dx, -_earPivot.dy);
      if (glow > .02) {
        c.drawCircle(
          const Offset(1.0, -1.0),
          .85,
          _glow(const Offset(1.0, -1.0), .85, hot, .6 * glow),
        );
      }
      c.drawPath(_ear.shift(const Offset(.03, .05)), BossRig.fill(BossRig.ink));
      c.drawPath(
        _ear,
        BossRig.gradient(const Rect.fromLTRB(.24, -1.5, 1.64, -.38), const [
          Color(0xff8a72b8),
          BossRig.plum,
          Color(0xff382a5a),
        ]),
      );
      c.drawPath(_ear, BossRig.line(BossRig.ink, .06));
      c.drawPath(
        _inner,
        BossRig.fill(Color.lerp(_concha, deepOf(fury), glow * .85)!),
      );
      if (glow > .02) {
        c.drawPath(_inner, BossRig.fill(hot.withValues(alpha: .35 * glow)));
      }
      c.drawPath(
        _ribs,
        BossRig.line(Color.lerp(_rib, sonicCore, glow)!, .05 + glow * .02),
      );
      c.drawPath(_earRim, BossRig.line(const Color(0xffb9a3e6), .03));
      c.drawPath(_earTuft, BossRig.fill(const Color(0xffd6b6eb)));
      c.restore();
    }
  }

  // ----------------------------------------------------------------- cape --

  /// The hem, torn into lightning points.
  static const _tatters = [
    Offset(-1.06, 1.0),
    Offset(-.82, .95),
    Offset(-.66, 1.3),
    Offset(-.44, 1.1),
    Offset(-.22, 1.44),
    Offset(0, 1.2),
    Offset(.22, 1.44),
    Offset(.44, 1.1),
    Offset(.66, 1.3),
    Offset(.82, .95),
    Offset(1.06, 1.0),
  ];
  static final _hem = () {
    final path = Path()..moveTo(-.78, .2);
    for (final p in _tatters) {
      path.lineTo(p.dx, p.dy);
    }
    return path
      ..lineTo(.78, .2)
      ..close();
  }();

  /// A storm-torn cape with a gold lightning trim and a high, spiked
  /// collar, in place of the debut's scalloped one.
  static void cape(Canvas c) {
    c.drawPath(_hem.shift(const Offset(.03, .06)), BossRig.fill(BossRig.ink));
    c.drawPath(
      _hem,
      BossRig.gradient(const Rect.fromLTRB(-1.1, .2, 1.1, 1.45), const [
        _lining,
        _wine,
        _deepWine,
      ]),
    );
    c.drawPath(_hem, BossRig.line(BossRig.ink, .055));
    final trim = Path();
    for (var i = 0; i < _tatters.length; i++) {
      final p = const Offset(0, .5) + (_tatters[i] - const Offset(0, .5)) * .84;
      i == 0 ? trim.moveTo(p.dx, p.dy) : trim.lineTo(p.dx, p.dy);
    }
    c.drawPath(trim, BossRig.line(BossRig.gold.withValues(alpha: .8), .035));
    _collar(c);
  }

  /// The debut's stiff bat-wing collar, its outer edge cut into lightning
  /// points and trimmed in gold (right half; mirrored).
  static final _collarRight = Path()
    ..moveTo(.42, .32)
    ..lineTo(1.06, .16)
    ..lineTo(1.18, -.08)
    ..lineTo(1.1, -.13)
    ..lineTo(1.28, -.4)
    ..lineTo(1.19, -.44)
    ..lineTo(1.38, -.84)
    ..quadraticBezierTo(1.06, -.62, .84, -.46)
    ..close();
  static final _collarInnerRight = Path()
    ..moveTo(.5, .24)
    ..lineTo(.97, .1)
    ..lineTo(1.06, -.08)
    ..lineTo(1.0, -.13)
    ..lineTo(1.15, -.38)
    ..lineTo(1.08, -.42)
    ..lineTo(1.22, -.68)
    ..quadraticBezierTo(1.0, -.52, .84, -.4)
    ..close();
  static final _collarTrimRight = Path()
    ..moveTo(1.06, .16)
    ..lineTo(1.18, -.08)
    ..lineTo(1.1, -.13)
    ..lineTo(1.28, -.4)
    ..lineTo(1.19, -.44)
    ..lineTo(1.38, -.84);
  static Path _both(Path right) => Path()
    ..addPath(right, Offset.zero)
    ..addPath(
      right.transform(
        Float64List.fromList([-1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]),
      ),
      Offset.zero,
    );
  static final _collars = _both(_collarRight);
  static final _collarInners = _both(_collarInnerRight);
  static final _collarTrims = _both(_collarTrimRight);

  static void _collar(Canvas c) {
    c.drawPath(
      _collars.shift(const Offset(.03, .06)),
      BossRig.fill(BossRig.ink),
    );
    c.drawPath(_collars, BossRig.fill(_deepWine));
    c.drawPath(_collarInners, BaronBatArt.collarLining);
    c.drawPath(_collars, BossRig.line(BossRig.ink, .055));
    c.drawPath(
      _collarTrims,
      BossRig.line(BossRig.gold.withValues(alpha: .9), .03),
    );
  }

  // ---------------------------------------------------------------- wings --

  /// A small lightning glyph for the membranes.
  static Path bolt(Offset at, double s) => Path()
    ..moveTo(at.dx - .25 * s, at.dy - s)
    ..lineTo(at.dx + .42 * s, at.dy - .12 * s)
    ..lineTo(at.dx + .06 * s, at.dy - .02 * s)
    ..lineTo(at.dx + .3 * s, at.dy + s)
    ..lineTo(at.dx - .42 * s, at.dy + .08 * s)
    ..lineTo(at.dx - .06 * s, at.dy)
    ..close();

  /// The wing's leading edge as a jagged lightning trim, along the two
  /// quadratic curves [a]→[b] (through [ab]) and [b]→[d] (through [bd]).
  static void wingEdge(
    Canvas c,
    Offset a,
    Offset ab,
    Offset b,
    Offset bd,
    Offset d, {
    required bool fury,
  }) {
    final points = <Offset>[];
    void quad(Offset p0, Offset p1, Offset p2, bool first) {
      const n = 7;
      for (var i = first ? 0 : 1; i <= n; i++) {
        final t = i / n;
        points.add(
          p0 * ((1 - t) * (1 - t)) + p1 * (2 * t * (1 - t)) + p2 * (t * t),
        );
      }
    }

    quad(a, ab, b, true);
    quad(b, bd, d, false);
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final p = points[i];
      if (i == points.length - 1) {
        path.lineTo(p.dx, p.dy);
        continue;
      }
      final dir = points[i + 1] - points[i - 1];
      final n = Offset(-dir.dy, dir.dx) / dir.distance;
      final z = p + n * (i.isEven ? .045 : -.045);
      path.lineTo(z.dx, z.dy);
    }
    c.drawPath(path, BossRig.line(BossRig.ink, .1));
    c.drawPath(path, BossRig.line(fury ? BossRig.ember : BossRig.gold, .055));
    c.drawPath(path, BossRig.line(BossRig.cream.withValues(alpha: .8), .018));
  }

  // ----------------------------------------------------------- resonator --

  /// The sonic resonator on his breastplate, where the debut's gem sat. It
  /// lights sonic pink with the screech and gold (ember in fury) as a
  /// fireball charges.
  static void resonator(
    Canvas c,
    BaronStormPose p, {
    required double charge,
    required bool fury,
  }) {
    // Low on the plate, clear of the screeching jaw.
    const at = Offset(0, .76);
    final hot = sonicOf(fury), glow = p.glow;
    if (glow > .02) c.drawCircle(at, .6, _glow(at, .6, hot, .55 * glow));
    c.drawCircle(at + const Offset(.02, .04), .25, BossRig.fill(BossRig.ink));
    c.drawCircle(at, .25, BossRig.fill(BossRig.ink));
    c.drawCircle(
      at,
      .21,
      BossRig.gradient(Rect.fromCircle(center: at, radius: .21), const [
        BossRig.cream,
        BossRig.gold,
        _bronze,
      ]),
    );
    c.drawCircle(
      at,
      .155,
      BossRig.fill(Color.lerp(_well, deepOf(fury), glow * .7)!),
    );
    final ring = Color.lerp(hot.withValues(alpha: .7), sonicCore, glow)!;
    c.drawCircle(at, .115, BossRig.line(ring, .028));
    c.drawCircle(at, .068, BossRig.line(ring, .026));
    c.drawCircle(
      at,
      .036 + glow * .018,
      BossRig.fill(Color.lerp(hot, sonicCore, .35 + glow * .65)!),
    );
    c.drawCircle(at, .155, BossRig.line(BossRig.ink, .03));
    // No fireball charges while he holds them for the screech.
    if (charge > .05 && !p.boss.screechQuiet) {
      // Four sparkle rays grow with a fireball's wind-up.
      final color = Color.lerp(
        fury ? BossRig.ember : BossRig.gold,
        BossRig.cream,
        .5,
      )!;
      final rays = Path();
      for (final d in const [
        Offset(0, -1),
        Offset(1, 0),
        Offset(0, 1),
        Offset(-1, 0),
      ]) {
        final from = at + d * (.25 + charge * .03);
        final to = at + d * (.27 + charge * .16);
        rays
          ..moveTo(from.dx, from.dy)
          ..lineTo(to.dx, to.dy);
      }
      c.drawPath(rays, BossRig.line(color, .045));
    }
  }

  // ---------------------------------------------------------------- mouth --

  /// The sound glowing in his throat, drawn inside the mouth's clip: rings
  /// of sound around a white-hot core as he screeches.
  static void throat(Canvas c, BaronStormPose p, double drop, bool fury) {
    final g = math.max(p.glow * .75, p.voice);
    if (g <= .02) return;
    // A dark rim of open jaw stays around the glow.
    final center = Offset(-.04, .14 + drop * .52);
    final w = .5, tall = .1 + drop * .86;
    c.drawOval(
      Rect.fromCenter(center: center, width: w, height: tall),
      BossRig.fill(sonicOf(fury).withValues(alpha: .85 * g)),
    );
    for (final k in const [.66, .4]) {
      c.drawOval(
        Rect.fromCenter(center: center, width: w * k, height: tall * k),
        BossRig.line(sonicCore.withValues(alpha: .75 * g), .03),
      );
    }
    c.drawOval(
      Rect.fromCenter(center: center, width: .15, height: .05 + drop * .3),
      BossRig.fill(sonicCore.withValues(alpha: g)),
    );
  }

  // ---------------------------------------------------------------- crown --

  /// The storm crown's reach in body coordinates (it also tumbles free in
  /// the defeat).
  static const crownBounds = Rect.fromLTRB(-1.05, -2.1, 1.05, -.55);

  static final _crownPaint = BossRig.gradient(
    const Rect.fromLTWH(-.9, -2.0, 1.8, 1.3),
    const [BossRig.cream, BossRig.gold, _bronze],
  );
  static final _crown = Path()
    ..moveTo(-.62, -.7)
    ..lineTo(-.9, -1.56)
    ..lineTo(-.46, -1.24)
    ..lineTo(-.2, -1.3)
    // The lightning spire.
    ..lineTo(-.3, -1.66)
    ..lineTo(-.07, -1.62)
    ..lineTo(-.15, -1.98)
    ..lineTo(.25, -1.5)
    ..lineTo(.04, -1.54)
    ..lineTo(.16, -1.3)
    ..lineTo(.46, -1.24)
    ..lineTo(.9, -1.56)
    ..lineTo(.62, -.7)
    ..quadraticBezierTo(0, -.94, -.62, -.7)
    ..close();

  /// The upgraded crown: taller, with a lightning spire and a sonic gem,
  /// seated with the debut crown's jaunty tilt.
  static void crown(Canvas c, {double glow = 0, bool fury = false}) {
    c.save();
    c.translate(0, -.84);
    c.rotate(.09);
    c.translate(0, .84);
    BaronBatArt.crownCap(c);
    c.drawPath(_crown.shift(const Offset(.03, .06)), BossRig.fill(BossRig.ink));
    c.drawPath(_crown, _crownPaint);
    BaronBatArt.crownBandFill(c);
    c.drawPath(_crown, BossRig.line(BossRig.ink, .055));
    BaronBatArt.crownBand(c, sonicOf(fury), deepOf(fury));
    // A bright seam down the spire.
    c.drawPath(
      Path()
        ..moveTo(-.1, -1.36)
        ..lineTo(-.18, -1.6)
        ..lineTo(-.02, -1.58)
        ..lineTo(-.09, -1.82),
      BossRig.line(BossRig.cream.withValues(alpha: .85), .03),
    );
    for (final at in const [Offset(-.9, -1.56), Offset(.9, -1.56)]) {
      c.drawCircle(at, .085, BossRig.fill(BossRig.ink));
      c.drawCircle(at, .06, BossRig.fill(BossRig.cream));
    }
    const gem = Offset(0, -1.1);
    final hot = sonicOf(fury);
    if (glow > .02) c.drawCircle(gem, .42, _glow(gem, .42, hot, .7 * glow));
    c.drawCircle(gem, .15, BossRig.fill(BossRig.ink));
    c.drawCircle(
      gem,
      .12,
      BossRig.gradient(Rect.fromCircle(center: gem, radius: .12), [
        sonicCore,
        hot,
        deepOf(fury),
      ]),
    );
    c.drawCircle(
      gem,
      .065,
      BossRig.line(sonicCore.withValues(alpha: .55 + .45 * glow), .022),
    );
    c.drawCircle(
      gem + const Offset(-.04, -.045),
      .03,
      BossRig.fill(const Color(0xffffffff)),
    );
    c.restore();
  }
}
