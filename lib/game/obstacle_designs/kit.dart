import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../regions/world_region.dart';

/// Column geometry measured from the rim, the collision edge that faces the
/// flight lane. Patterns anchored to the rim move rigidly with a moving
/// opening instead of sliding against it.
class Column {
  Column(this.r, this.top)
    : ink = (r.width * .03).clamp(1.3, 2.2),
      lip = math.min((r.width * .05).clamp(2.2, 3.4), r.height * .3);
  final Rect r;
  final bool top;

  /// Thickness of the inked outline and of the state lip inside it.
  final double ink, lip;

  double get w => r.width;
  double get h => r.height;
  double get cx => r.center.dx;
  double get rim => top ? r.bottom : r.top;

  /// Direction from the rim into the solid.
  double get dir => top ? -1 : 1;

  /// Screen y at [dist] from the rim into the solid.
  double y(double dist) => top ? r.bottom - dist : r.top + dist;

  /// A horizontal band between two rim distances, optionally narrowed.
  Rect band(double a, double b, [double? left, double? right]) {
    final y1 = y(a), y2 = y(b);
    return Rect.fromLTRB(
      left ?? r.left,
      math.min(y1, y2),
      right ?? r.right,
      math.max(y1, y2),
    );
  }

  /// Room left for body detail once [cap] is reserved at the rim.
  double room(double cap) => h - cap;
}

/// How the flight treated an obstacle.
class PassState {
  const PassState({required this.cleared, required this.perfect});
  final bool cleared, perfect;

  static const _cream = Color(0xfffff9ed);
  static const _mint = Color(0xffbff0cf);
  static const _gold = Color(0xffffd45b);

  /// The lip on the collision edge: cream, mint once cleared, gold perfect.
  Color get lip => perfect ? _gold : (cleared ? _mint : _cream);
}

/// Shared drawing rules for every regional obstacle.
abstract final class Kit {
  static Color mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

  static void fill(Canvas c, Rect b, Color color) {
    if (!(b.width > 0) || !(b.height > 0)) return;
    c.drawRect(b, Paint()..color = color);
  }

  /// A cylinder's horizontal shading: lit left, true body, shaded right.
  static void volume(Canvas c, Rect r, Color lit, Color body, Color shade) {
    c.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          colors: [lit, body, body, shade],
          stops: const [0, .34, .62, 1],
        ).createShader(r),
    );
  }

  /// The inked silhouette and the collision edge: an ink line on the very
  /// edge (reads on pale skies), the state lip inside it (reads on dark
  /// skies) and a hair of shadow under the lip.
  static void edge(Canvas c, Column g, Color ink, PassState pass) {
    final r = g.r;
    fill(c, Rect.fromLTWH(r.left, r.top, g.ink, r.height), ink);
    fill(c, Rect.fromLTWH(r.right - g.ink, r.top, g.ink, r.height), ink);
    if (g.h < 3) {
      fill(c, r, pass.lip);
      return;
    }
    fill(c, g.band(0, g.ink), ink);
    fill(
      c,
      g.band(g.ink, g.ink + g.lip, r.left + g.ink, r.right - g.ink),
      pass.lip,
    );
    // Sheen on the lip's upper half so it reads as a rounded moulding.
    fill(
      c,
      g.band(
        g.ink + g.lip * (g.top ? 0 : .5),
        g.ink + g.lip * (g.top ? .5 : 1),
        r.left + g.ink,
        r.right - g.ink,
      ),
      mix(pass.lip, const Color(0xffffffff), .45),
    );
    fill(
      c,
      g.band(g.ink + g.lip, g.ink + g.lip + math.max(1.0, g.ink * .6)),
      mix(ink, const Color(0x00000000), .45),
    );
  }

  /// Distance from the rim to the inside of the edge moulding.
  static double edgeDepth(Column g) =>
      g.ink + g.lip + math.max(1.0, g.ink * .6);

  /// A region's cleared seal. Perfect passes turn it gold.
  static void emblem(
    Canvas c,
    WorldRegion region,
    Offset at,
    double s, {
    required bool perfect,
  }) {
    if (s < 2 || !at.dx.isFinite || !at.dy.isFinite) return;
    const ink = Color(0xff203b45);
    const gold = Color(0xffffc93f), goldDeep = Color(0xffc98a22);
    final paint = Paint();
    c.save();
    c.translate(at.dx, at.dy);
    // A dark backing disc keeps any motif legible on any material.
    c.drawCircle(
      Offset.zero,
      s * 1.12,
      paint..color = ink.withValues(alpha: .55),
    );
    switch (region) {
      case WorldRegion.egypt:
        // A lotus: three pointed petals over a sepal cup.
        final petal = perfect ? gold : const Color(0xff49c1c4);
        final deep = perfect ? goldDeep : const Color(0xff2f7fa6);
        for (final (a, len) in const [
          (-1.95, .9),
          (-1.19, .9),
          (-1.57, 1.05),
        ]) {
          c.save();
          c.rotate(a + math.pi / 2);
          c.drawPath(
            Path()
              ..moveTo(0, s * .45)
              ..quadraticBezierTo(-s * .38, -s * .2, 0, -s * len)
              ..quadraticBezierTo(s * .38, -s * .2, 0, s * .45)
              ..close(),
            paint..color = a == -1.57 ? petal : deep,
          );
          c.restore();
        }
        c.drawOval(
          Rect.fromCenter(
            center: Offset(0, s * .45),
            width: s * 1.1,
            height: s * .38,
          ),
          paint..color = perfect ? goldDeep : const Color(0xff2f7fa6),
        );
      case WorldRegion.cyberpunk:
        // A microchip: silver pins on every side of a neon die, a dark
        // circuit well and a glowing magenta core.
        final pin = paint..color = perfect ? goldDeep : const Color(0xffd8e4ff);
        for (var k = -1; k <= 1; k++) {
          final along = k * s * .38;
          for (final pad in [
            Rect.fromCenter(center: Offset(along, -s * .8), width: s * .16, height: s * .3),
            Rect.fromCenter(center: Offset(along, s * .8), width: s * .16, height: s * .3),
            Rect.fromCenter(center: Offset(-s * .8, along), width: s * .3, height: s * .16),
            Rect.fromCenter(center: Offset(s * .8, along), width: s * .3, height: s * .16),
          ]) {
            c.drawRect(pad, pin);
          }
        }
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: s * 1.36, height: s * 1.36),
            Radius.circular(s * .16),
          ),
          paint..color = perfect ? gold : const Color(0xff3fe0f4),
        );
        c.drawRect(
          Rect.fromCenter(center: Offset.zero, width: s * .84, height: s * .84),
          paint..color = perfect ? goldDeep : const Color(0xff1b1d48),
        );
        c.drawPath(
          Path()
            ..moveTo(0, -s * .34)
            ..lineTo(s * .34, 0)
            ..lineTo(0, s * .34)
            ..lineTo(-s * .34, 0)
            ..close(),
          paint..color = perfect ? const Color(0xfffff4c8) : const Color(0xffff4fc8),
        );
        c.drawCircle(
          Offset(-s * .44, -s * .44),
          s * .08,
          paint..color = const Color(0xccffffff),
        );
      case WorldRegion.antarctica:
        // A six-armed snowflake with side barbs.
        final arm = Paint()
          ..color = perfect ? gold : const Color(0xffeaf8ff)
          ..strokeWidth = math.max(1.0, s * .2)
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 6; i++) {
          final a = i * math.pi / 3;
          final d = Offset(math.cos(a), math.sin(a));
          final n = Offset(-d.dy, d.dx);
          c.drawLine(Offset.zero, d * s * .95, arm);
          c.drawLine(d * s * .55, d * s * .55 + (d + n) * s * .24, arm);
          c.drawLine(d * s * .55, d * s * .55 + (d - n) * s * .24, arm);
        }
      case WorldRegion.jungle:
        // A hibiscus: five broad petals and a long stamen.
        final petal = perfect ? gold : const Color(0xfff25f6b);
        for (var i = 0; i < 5; i++) {
          final a = -math.pi / 2 + i * math.pi * 2 / 5;
          c.drawCircle(
            Offset(math.cos(a), math.sin(a)) * s * .5,
            s * .42,
            paint..color = petal,
          );
        }
        c.drawCircle(
          Offset.zero,
          s * .22,
          paint..color = perfect ? goldDeep : const Color(0xff9e2a45),
        );
        c.drawLine(
          Offset.zero,
          Offset(s * .5, -s * .55),
          Paint()
            ..color = const Color(0xffffe27a)
            ..strokeWidth = math.max(.8, s * .12)
            ..strokeCap = StrokeCap.round,
        );
      case WorldRegion.china:
        // A small red silk lantern with gold caps.
        final body = perfect ? gold : const Color(0xffe0412f);
        c.drawOval(
          Rect.fromCenter(center: Offset.zero, width: s * 1.6, height: s * 1.3),
          paint..color = body,
        );
        final cap = paint..color = perfect ? goldDeep : const Color(0xffffc85a);
        c.drawRect(
          Rect.fromCenter(
            center: Offset(0, -s * .66),
            width: s * .8,
            height: s * .26,
          ),
          cap,
        );
        c.drawRect(
          Rect.fromCenter(
            center: Offset(0, s * .66),
            width: s * .8,
            height: s * .26,
          ),
          cap,
        );
        c.drawLine(
          Offset(0, -s * .5),
          Offset(0, s * .5),
          Paint()
            ..color = (perfect ? goldDeep : const Color(0xffa82a22)).withValues(
              alpha: .8,
            )
            ..strokeWidth = math.max(.7, s * .1),
        );
      case WorldRegion.newYork:
        // The Big Apple.
        c.drawCircle(
          Offset(-s * .26, s * .1),
          s * .56,
          paint..color = perfect ? gold : const Color(0xffe8453c),
        );
        c.drawCircle(Offset(s * .26, s * .1), s * .56, paint);
        c.drawOval(
          Rect.fromCenter(
            center: Offset(s * .3, -s * .72),
            width: s * .56,
            height: s * .3,
          ),
          paint..color = perfect ? goldDeep : const Color(0xff5fbf6a),
        );
        c.drawCircle(
          Offset(-s * .3, -s * .12),
          s * .14,
          paint..color = const Color(0xccffffff),
        );
      case WorldRegion.aztec:
        // A jade mask: a green disc with dark eyes and a gold crown.
        c.drawCircle(
          Offset.zero,
          s * .8,
          paint..color = perfect ? gold : const Color(0xff2fb5a0),
        );
        c.drawRect(
          Rect.fromLTRB(-s * .8, -s * .8, s * .8, -s * .5),
          paint..color = perfect ? goldDeep : const Color(0xffe6b44c),
        );
        for (final dx in const [-.33, .33]) {
          c.drawCircle(
            Offset(dx * s, -s * .08),
            s * .17,
            paint..color = const Color(0xff1f3a3a),
          );
        }
        c.drawRect(
          Rect.fromCenter(
            center: Offset(0, s * .4),
            width: s * .7,
            height: s * .16,
          ),
          paint..color = const Color(0xff1f3a3a),
        );
      case WorldRegion.paris:
        // A golden star.
        c.drawPath(
          Path()
            ..moveTo(0, -s)
            ..lineTo(s * .28, -s * .28)
            ..lineTo(s, 0)
            ..lineTo(s * .28, s * .28)
            ..lineTo(0, s)
            ..lineTo(-s * .28, s * .28)
            ..lineTo(-s, 0)
            ..lineTo(-s * .28, -s * .28)
            ..close(),
          paint..color = perfect ? gold : const Color(0xffffe08a),
        );
        c.drawCircle(
          Offset.zero,
          s * .18,
          paint..color = perfect ? goldDeep : const Color(0xffe8a73c),
        );
      case WorldRegion.brazil:
        // A football: a white ball with a dark centre patch.
        c.drawCircle(
          Offset.zero,
          s * .85,
          paint..color = perfect ? gold : const Color(0xfff6f1e2),
        );
        final patch = paint..color = perfect ? goldDeep : const Color(0xff26303a);
        c.drawPath(
          Path()
            ..moveTo(0, -s * .34)
            ..lineTo(s * .32, -s * .1)
            ..lineTo(s * .2, s * .28)
            ..lineTo(-s * .2, s * .28)
            ..lineTo(-s * .32, -s * .1)
            ..close(),
          patch,
        );
        for (var i = 0; i < 5; i++) {
          final a = -math.pi / 2 + i * math.pi * 2 / 5;
          c.drawLine(
            Offset(math.cos(a), math.sin(a)) * s * .36,
            Offset(math.cos(a), math.sin(a)) * s * .8,
            Paint()
              ..color = const Color(0xff26303a)
              ..strokeWidth = math.max(.8, s * .09),
          );
        }
      case WorldRegion.arabia:
        // A turquoise onion dome on a cream drum under a gilt finial.
        c.drawRect(
          Rect.fromLTRB(-s * .58, s * .36, s * .58, s * .8),
          paint..color = perfect ? goldDeep : const Color(0xfff6e6d0),
        );
        c.drawPath(
          Path()
            ..moveTo(-s * .6, s * .4)
            ..cubicTo(-s * 1.02, s * .2, -s * .8, -s * .36, -s * .22, -s * .52)
            ..quadraticBezierTo(-s * .04, -s * .6, 0, -s * .8)
            ..quadraticBezierTo(s * .04, -s * .6, s * .22, -s * .52)
            ..cubicTo(s * .8, -s * .36, s * 1.02, s * .2, s * .6, s * .4)
            ..close(),
          paint..color = perfect ? gold : const Color(0xff2fb3ae),
        );
        c.drawOval(
          Rect.fromCenter(
            center: Offset(s * .3, -s * .06),
            width: s * .2,
            height: s * .42,
          ),
          paint..color = const Color(0x88ffffff),
        );
        c.drawCircle(
          Offset(0, -s * .92),
          s * .13,
          paint..color = perfect ? goldDeep : const Color(0xffffc93f),
        );
      case WorldRegion.rome:
        // A laurel wreath ring around a red dot.
        final leaf = paint..color = perfect ? gold : const Color(0xff7fa85a);
        for (var i = 0; i < 8; i++) {
          final a = -math.pi / 2 + i * math.pi / 4;
          c.drawCircle(Offset(math.cos(a), math.sin(a)) * s * .7, s * .22, leaf);
        }
        c.drawCircle(
          Offset.zero,
          s * .34,
          paint..color = perfect ? goldDeep : const Color(0xffb23a2c),
        );
      case WorldRegion.mexico:
        // A marigold: two rings of round petals.
        final petal = perfect ? gold : const Color(0xfff7a21b);
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          c.drawCircle(
            Offset(math.cos(a), math.sin(a)) * s * .55,
            s * .3,
            paint..color = petal,
          );
        }
        c.drawCircle(
          Offset.zero,
          s * .34,
          paint..color = perfect ? goldDeep : const Color(0xffe6407a),
        );
      case WorldRegion.sea:
        // A starfish.
        final path = Path();
        for (var i = 0; i < 10; i++) {
          final a = -math.pi / 2 + i * math.pi / 5;
          final rad = s * (i.isEven ? 1.0 : .42);
          final p = Offset(math.cos(a), math.sin(a)) * rad;
          if (i == 0) {
            path.moveTo(p.dx, p.dy);
          } else {
            path.lineTo(p.dx, p.dy);
          }
        }
        c.drawPath(
          path..close(),
          paint..color = perfect ? gold : const Color(0xffff9360),
        );
        c.drawCircle(
          Offset.zero,
          s * .16,
          paint..color = perfect ? goldDeep : const Color(0xffffd2a8),
        );
    }
    if (perfect) {
      c.drawCircle(
        Offset.zero,
        s * 1.12,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.0, s * .16)
          ..color = gold,
      );
    }
    c.restore();
  }

  /// An orb's collision edge: a metal bezel band, the state lip inside it
  /// and an ink outline on the very edge. Drawn over the clipped body.
  static void bezel(
    Canvas c,
    double r,
    Color metal,
    Color ink,
    PassState pass, {
    double band = .11,
  }) {
    final outline = math.min(3.0, math.max(1.3, r * .05));
    final width = math.max(2.2, r * band);
    c.drawCircle(
      Offset.zero,
      r - outline - width / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = metal,
    );
    c.drawCircle(
      Offset.zero,
      r - outline - width + .6,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = pass.cleared ? 1.8 : 1.2
        ..color = pass.lip,
    );
    c.drawCircle(
      Offset.zero,
      r - outline / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = outline
        ..color = ink,
    );
  }

  /// A closed polygon from (x, y) pairs.
  static Path poly(List<double> xy) {
    final path = Path()..moveTo(xy[0], xy[1]);
    for (var i = 2; i + 1 < xy.length; i += 2) {
      path.lineTo(xy[i], xy[i + 1]);
    }
    return path..close();
  }

  /// A spinning angle from the replay clock, frozen in Reduced Motion.
  static double spin(
    double seconds,
    bool reducedMotion,
    double speed, [
    double rest = 0,
  ]) {
    if (reducedMotion || !seconds.isFinite) return rest;
    final period = math.pi * 2 / speed.abs();
    return rest + (seconds % period) * speed;
  }
}
