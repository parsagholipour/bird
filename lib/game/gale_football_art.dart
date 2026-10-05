import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../ui/theme.dart';

/// The footballs a gale throws over Brazil. One hand-drawn ball, in the
/// spirit of a classic flat clip-art football (design/gale-footballs), in
/// four kits: the classic black and white, Brazil's canary yellow and green,
/// an old laced leather ball, and Brazil's blue away kit.
///
/// The panels turn with the ball while the light stays put, so a tumbling
/// ball still reads as a sphere. Every ball fills exactly the circle the
/// rules hit with.
abstract final class GaleFootballArt {
  static const kits = 4;

  static const _ink = Color(0xff1d2830);
  static const _white = Color(0xfffbfaf4);
  static const _canary = Color(0xffffd23a), _green = Color(0xff13924a);
  static const _blue = Color(0xff2a5fc9), _blueDeep = Color(0xff163a86);
  static const _leather = Color(0xffb8743c), _leatherDark = Color(0xff6e3d1e);
  static const _lace = Color(0xfff4e2bf);

  /// A ball of kit [kit] at [center], filling the circle of radius [r],
  /// turned to [turn] and faded to [alpha].
  static void paint(
    Canvas canvas,
    Offset center,
    double r,
    int kit,
    double turn,
    double alpha,
  ) {
    final (panel, patch, seam) = switch (kit % kits) {
      0 => (_white, _ink, _ink),
      1 => (_canary, _green, _blueDeep),
      2 => (_leather, _leatherDark, _leatherDark),
      _ => (_blue, _white, _blueDeep),
    };
    Color a(Color c, [double o = 1]) => c.withValues(alpha: c.a * o * alpha);
    // A shadow behind the ball lifts it off a busy backdrop.
    canvas.drawCircle(
      center + Offset(r * .1, r * .16),
      r * .98,
      Paint()..color = a(SkyColors.ink, .2),
    );
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(r);
    canvas.drawCircle(Offset.zero, 1, Paint()..color = a(panel));
    canvas.save();
    canvas.clipPath(_disc);
    canvas.rotate(turn);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      _seams,
      stroke
        ..strokeWidth = .055
        ..color = a(seam, .7),
    );
    canvas.drawPath(_patches, Paint()..color = a(patch));
    canvas.drawPath(
      _patches,
      stroke
        ..strokeWidth = .055
        ..color = a(kit % kits == 3 ? _blueDeep : _ink, .85),
    );
    if (kit % kits == 2) _laces(canvas, a);
    canvas.restore();
    // The light stays up and to the left however the ball turns.
    canvas.drawCircle(
      Offset.zero,
      1,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.42, -.48),
          radius: 1.25,
          colors: [
            a(SkyColors.white, .4),
            a(SkyColors.white, 0),
            a(SkyColors.ink, .22),
          ],
          stops: const [0, .5, 1],
        ).createShader(_unit),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-.4, -.46), width: .36, height: .2),
      Paint()..color = a(SkyColors.white, .55),
    );
    canvas.drawCircle(
      Offset.zero,
      .95,
      stroke
        ..strokeWidth = .1
        ..color = a(_ink, .9),
    );
    canvas.restore();
  }

  static final _unit = Rect.fromCircle(center: Offset.zero, radius: 1);
  static final _disc = Path()..addOval(_unit);

  static Offset _at(double angle, double radius) =>
      Offset(math.cos(angle), math.sin(angle)) * radius;

  /// The five corners of the facing pentagon point down and round, and an
  /// outer pentagon sits off each corner, foreshortened as it turns away.
  static double _corner(int k) => math.pi / 2 + k * 2 * math.pi / 5;

  static const _core = .33, _reach = .58, _side = .8, _sideTurn = .25;

  static final Path _patches = () {
    final path = Path();
    for (var k = 0; k < 5; k++) {
      final p = _at(_corner(k), _core);
      k == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    for (var k = 0; k < 5; k++) {
      final c = _corner(k);
      path.addPolygon([
        _at(c, _reach),
        _at(c + _sideTurn, _side),
        _at(c + .15, 1.06),
        _at(c - .15, 1.06),
        _at(c - _sideTurn, _side),
      ], true);
    }
    return path;
  }();

  /// The stitching: a seam out from each corner of the facing pentagon,
  /// the far edge of each hexagon between two outer pentagons, and a seam
  /// on from the middle of that edge to the rim.
  static final Path _seams = () {
    final path = Path();
    for (var k = 0; k < 5; k++) {
      final c = _corner(k), next = _corner(k + 1);
      final from = _at(c, _core), to = _at(c, _reach);
      path
        ..moveTo(from.dx, from.dy)
        ..lineTo(to.dx, to.dy);
      final a = _at(c + _sideTurn, _side), b = _at(next - _sideTurn, _side);
      path
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy);
      final mid = (a + b) / 2, rim = _at((c + next) / 2, 1.05);
      path
        ..moveTo(mid.dx, mid.dy)
        ..lineTo(rim.dx, rim.dy);
    }
    return path;
  }();

  /// The leather ball's laced slot across the hexagon above the facing
  /// pentagon: a dark slit with pale laces crossing it.
  static void _laces(Canvas canvas, Color Function(Color, [double]) a) {
    final slot = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = .09
      ..color = a(_leatherDark);
    canvas.drawLine(const Offset(-.2, -.56), const Offset(.2, -.56), slot);
    final lace = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = .065
      ..color = a(_lace);
    for (var i = 0; i < 4; i++) {
      final x = -.15 + i * .1;
      canvas.drawLine(Offset(x, -.65), Offset(x + .02, -.47), lace);
    }
  }
}
