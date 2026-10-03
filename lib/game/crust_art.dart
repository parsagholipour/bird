import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../ui/theme.dart';

/// The stale crust King Coo's vanguard pigeons throw (rules version 45,
/// `EnemyAttack.crumb`): a hard slice of old bread, the toast-shaped
/// silhouette everyone reads as bread, baked dark at the crust, its crumb
/// gone grey-yellow, cracked and broken off at one corner. It tumbles end
/// over end inside a warning-orange halo with a dusty wake, so it reads as
/// something thrown at the bird (never as a star or a pickup: no gold, no
/// sparkle, no five points).
///
/// Drawn in hit-radius units: the inked rim ends on the hit circle at every
/// turn of the tumble, so a dodge that looks clean is clean (the halo, the
/// wake and the flying bits are allowed past it, as on every pellet). Shared
/// by the pellet ([EnemyAmmoArt]), its splash and its shatter, and the crust
/// a pigeon winds up with. Every motion follows the caller's clock; nothing
/// here saves a layer or blurs.
abstract final class CrustArt {
  /// Baked crust, lit to burnt; the stale crumb, its light and its holes.
  static const lit = Color(0xffd08a3e), crust = Color(0xff9a5524);
  static const burnt = Color(0xff5e2c12);
  static const crumb = Color(0xffe2c48a), crumbHi = Color(0xfffaeac0);
  static const hole = Color(0xffbf8f52);

  /// The warning glow and the dust it sheds.
  static const threat = Color(0xffff7a3d), dust = Color(0xffeedcb6);

  /// How fast it tumbles, radians per second (a little over a turn a second).
  static const spinRate = 7.5;

  // A slice of bread inside the unit circle: two shoulders over a straight
  // waist, the lower right corner snapped off in a jagged break.
  static final Path slice = () {
    final p = Path()
      ..moveTo(-.60, .76)
      ..lineTo(-.68, -.04)
      ..cubicTo(-.95, -.10, -.97, -.60, -.60, -.76)
      ..cubicTo(-.34, -.95, .34, -.95, .60, -.76)
      ..cubicTo(.97, -.60, .95, -.10, .68, -.04)
      ..lineTo(.64, .30)
      ..lineTo(.48, .40)
      ..lineTo(.58, .52)
      ..lineTo(.36, .62)
      ..lineTo(.30, .78)
      ..close();
    return p;
  }();

  // The crumb inside the crust: the same slice drawn in, its break left
  // open to the edge (the crust is gone where it snapped).
  static final Path _crumbFace = () {
    final p = Path()
      ..moveTo(-.40, .54)
      ..lineTo(-.46, -.14)
      ..cubicTo(-.70, -.20, -.70, -.52, -.42, -.58)
      ..cubicTo(-.22, -.72, .22, -.72, .42, -.58)
      ..cubicTo(.70, -.52, .70, -.20, .46, -.14)
      ..lineTo(.52, .26)
      ..lineTo(.40, .38)
      ..lineTo(.48, .50)
      ..lineTo(.30, .58)
      ..lineTo(.24, .62)
      ..close();
    return p;
  }();

  // Stale bread's holes, and the crack running in from the break.
  static final Path _holes = Path()
    ..addOval(
      Rect.fromCenter(
        center: const Offset(-.18, -.30),
        width: .16,
        height: .11,
      ),
    )
    ..addOval(
      Rect.fromCenter(center: const Offset(.20, -.08), width: .12, height: .09),
    )
    ..addOval(
      Rect.fromCenter(center: const Offset(-.20, .22), width: .10, height: .08),
    );
  static final Path _crack = Path()
    ..moveTo(.48, .40)
    ..lineTo(.24, .26)
    ..lineTo(.10, .34)
    ..lineTo(-.06, .18);

  // The crust's lit top edge.
  static final Path _sheen = Path()
    ..moveTo(-.70, -.50)
    ..cubicTo(-.62, -.78, -.30, -.86, 0, -.84);

  static final Paint _crustPaint = Paint()
    ..shader = const LinearGradient(
      begin: Alignment(-.3, -1),
      end: Alignment(.3, 1),
      colors: [lit, crust, burnt],
      stops: [0, .5, 1],
    ).createShader(const Rect.fromLTRB(-1, -1, 1, 1));
  static final Paint _crumbPaint = Paint()
    ..shader = const LinearGradient(
      begin: Alignment(-.4, -1),
      end: Alignment(.4, 1),
      colors: [crumbHi, crumb, Color(0xffd2b276)],
      stops: [0, .55, 1],
    ).createShader(const Rect.fromLTRB(-1, -1, 1, 1));
  static final Paint _halo = Paint()
    ..shader = RadialGradient(
      colors: [
        threat.withValues(alpha: .5),
        threat.withValues(alpha: .26),
        threat.withValues(alpha: 0),
      ],
      stops: const [.45, .66, 1],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: 2.0));

  /// The slice in unit space, turned by [spin] (radians), rimmed in ink
  /// [edge] wide (the rim's outer edge on the unit circle). [fine] adds the
  /// holes, the crack and the lit edge, for sizes that can show them;
  /// [alpha] fades it all.
  static void slab(
    Canvas c, {
    double spin = 0,
    required double edge,
    bool fine = false,
    double alpha = 1,
  }) {
    final a = alpha.clamp(0.0, 1.0);
    if (a <= 0) return;
    c.save();
    c.rotate(spin);
    final body = 1 - edge / 2;
    c.scale(body);
    c.drawPath(slice, _alpha(_crustPaint, a));
    // Stale bread is mostly crust: the crumb shows as a smaller face in it.
    c.save();
    c.translate(-.02, -.02);
    c.scale(.8);
    c.drawPath(_crumbFace, _alpha(_crumbPaint, a));
    c.restore();
    if (fine) {
      c.drawPath(_holes, _fill(hole, a));
      c.drawPath(_crack, _stroke(burnt, .07, a));
      c.drawPath(_sheen, _stroke(crumbHi, .08, .7 * a));
    } else {
      // At gameplay size: one dark crack, so the crumb still reads as broken.
      c.drawPath(_crack, _stroke(burnt, .12, a));
    }
    c.drawPath(slice, _stroke(SkyColors.ink, edge / body, a));
    c.restore();
  }

  /// The pellet heading along +x: its warning glow, a dusty wake that
  /// unrolls to [reach], and the slice tumbling at [time] ([pop] scales the
  /// slice alone, for its launch).
  static void pellet(
    Canvas c, {
    required double time,
    required double reach,
    required double edge,
    required bool fine,
    double pop = 1,
  }) {
    c.drawCircle(Offset.zero, 2.0, _halo);
    _wake(c, time, reach);
    c.save();
    c.scale(pop);
    slab(c, spin: time * spinRate, edge: edge, fine: fine);
    c.restore();
  }

  /// Dust streaks and three crumbs shed behind it, tumbling and fading.
  static void _wake(Canvas c, double time, double reach) {
    final tail = 4.2 * reach;
    if (tail < .9) return;
    for (final (y, len) in const [(-.62, .6), (.62, .45)]) {
      c.drawLine(
        Offset(-1.15, y),
        Offset(-1.15 - tail * len, y * 1.12),
        _stroke(dust, .26, .42),
      );
    }
    for (var i = 0; i < 3; i++) {
      final life = (time * 1.5 + i / 3) % 1;
      final x = -1.4 - life * (tail - 1.2);
      if (x < -tail) continue;
      final fade = math.sin(life * math.pi);
      final s = .34 * (1 - life * .45);
      c.save();
      c.translate(x, (i - 1) * (.30 + life * .45));
      c.rotate(time * 6 + i * 2);
      c.drawRect(
        Rect.fromCenter(center: Offset.zero, width: s * 1.4, height: s),
        _fill(i == 1 ? crust : crumb, .95 * fade),
      );
      c.restore();
    }
  }

  /// A chunk of broken crust in unit space (for splashes and shatters):
  /// crust on one side, crumb on the broken one.
  static void chunk(Canvas c, {required double edge, double alpha = 1}) {
    final a = alpha.clamp(0.0, 1.0);
    if (a <= 0) return;
    c.drawPath(_chunk, _fill(crust, a));
    c.drawPath(_chunkCrumb, _fill(crumb, a));
    c.drawPath(_chunk, _stroke(SkyColors.ink, edge, a));
  }

  static final Path _chunk = Path()
    ..moveTo(.9, -.2)
    ..lineTo(.2, -.85)
    ..lineTo(-.7, -.5)
    ..lineTo(-.85, .35)
    ..lineTo(-.1, .8)
    ..lineTo(.55, .45)
    ..close();
  static final Path _chunkCrumb = Path()
    ..moveTo(.55, .45)
    ..lineTo(-.1, .8)
    ..lineTo(-.45, .58)
    ..lineTo(-.05, .2)
    ..lineTo(.4, .08)
    ..lineTo(.72, .05)
    ..close();

  static Paint _alpha(Paint p, double a) => a >= 1
      ? p
      : (Paint()
          ..shader = p.shader
          ..color = Color.fromRGBO(255, 255, 255, a));

  static Paint _fill(Color color, [double alpha = 1]) =>
      Paint()..color = color.withValues(alpha: color.a * alpha);

  static Paint _stroke(Color color, double width, [double alpha = 1]) =>
      _fill(color, alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
}
