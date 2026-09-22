import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../domain/obstacle.dart';
import '../../ui/theme.dart';
import '../sky_scenery.dart';

/// Collectible sky wreath. The oval stays fixed; only rim charms drift.
abstract final class CruiseRingsDesign {
  static void paint(
    Canvas c,
    Rect bounds,
    Obstacle o, {
    required double seconds,
    required bool reducedMotion,
    required bool cleared,
    required Color accent,
  }) {
    if (!bounds.isFinite || bounds.isEmpty) return;
    final time = seconds.isFinite ? math.max(0.0, seconds) : 0.0;
    final band = cleared ? Color.lerp(accent, SkyColors.mint, .7)! : accent;
    if (bounds.shortestSide < 6) {
      _oval(c, bounds, band, 1.2);
      return;
    }

    final variant = (o.appearance % 3 + 3) % 3;
    final sky = SkyPalette.at(time);
    final tint = _tint(o.kind);
    final cream = Color.lerp(
      SkyColors.cream,
      SkyColors.mint,
      cleared ? .4 : 0,
    )!;
    final cord = Color.lerp(
      Color.lerp(cream, tint, cleared ? .14 : .22)!,
      sky.haze,
      .1,
    )!.withValues(alpha: cleared ? .8 : .94);
    final rope = math.min(8.0, bounds.shortestSide * .2);
    final ornate = bounds.width >= 24 && bounds.height >= 44;
    final fit = bounds.width / 43;
    final s = fit < .34 ? .34 : (fit > 1 ? 1.0 : fit);

    Color tone(Color color) =>
        cleared ? Color.lerp(color, SkyColors.mint, .6)! : color;

    _rim(c, bounds, rope, cord, band, tint, cleared);
    if (o.kind == ObstacleKind.switchback) {
      _oval(
        c,
        bounds.inflate(2.4),
        Color.lerp(
          band,
          SkyColors.cream,
          .32,
        )!.withValues(alpha: cleared ? .4 : .88),
        1.45,
      );
    }
    if (variant == 1 && ornate) {
      _stitches(c, bounds.inflate(1.8), band.withValues(alpha: .9));
    }
    if (!ornate) return;

    final turn =
        -math.pi / 2 +
        variant * .47 +
        (reducedMotion ? 0.0 : time * _pace(o.kind));
    final glow = reducedMotion
        ? .92
        : .75 + .25 * (math.sin(time * 1.7) * .5 + .5);

    void place(
      int count,
      void Function(double size, int index) draw, {
      double shift = 0,
      bool alternate = false,
      double twist = 0,
    }) {
      _around(
        c,
        bounds,
        count: count,
        turn: turn + shift,
        s: s,
        alternate: alternate,
        twist: twist,
        draw: draw,
      );
    }

    switch (o.kind) {
      case ObstacleKind.garden:
        place(const [6, 8, 5][variant], (k, i) {
          c.drawCircle(
            Offset.zero,
            k * 1.45,
            Paint()..color = SkyColors.cream.withValues(alpha: .92),
          );
          c.rotate(i.isEven ? .22 : -.18);
          final leaf = Color.lerp(
            tone(SkyColors.mint),
            band,
            i.isOdd ? .55 : .22,
          )!;
          _leaf(c, k, leaf);
          c.rotate(i.isEven ? -.7 : .64);
          _leaf(c, k * .66, Color.lerp(leaf, SkyColors.cream, .3)!);
        }, alternate: variant == 1);
      case ObstacleKind.petalGate:
        place(const [4, 5, 4][variant], (k, i) {
          _blossom(
            c,
            k,
            Color.lerp(tone(SkyColors.coral), band, i.isOdd ? .64 : .46)!,
            tone(Color.lerp(SkyColors.cream, SkyColors.yellow, .7)!),
          );
        }, alternate: variant == 1);
      case ObstacleKind.windLift:
        if (variant != 1) {
          place(4, (k, _) {
            _tooth(c, k, Color.lerp(tone(SkyColors.gold), band, .28)!);
          }, shift: math.pi / 4);
        }
        if (variant != 2) {
          place(variant == 1 ? 6 : 4, (k, _) {
            _bolt(c, k, Color.lerp(band, SkyColors.ink, .12)!, SkyColors.cream);
          }, alternate: variant == 1);
        }
      case ObstacleKind.switchback:
        place(
          const [4, 6, 4][variant],
          (k, _) {
            _chevron(c, k, band);
          },
          twist: math.pi / 2,
          alternate: variant == 1,
        );
      case ObstacleKind.lanternDrift:
        final window = tone(SkyColors.yellow).withValues(alpha: glow);
        place(const [4, 3, 4][variant], (k, _) {
          _lantern(c, k, Color.lerp(SkyColors.cream, band, .32)!, window, band);
        });
      case ObstacleKind.sunWheels:
        if (variant == 2) {
          place(4, (k, _) {
            _spark(c, k, Color.lerp(SkyColors.cream, band, .42)!);
          });
        } else {
          place(variant == 1 ? 6 : 8, (k, _) {
            _ray(c, k, Color.lerp(SkyColors.cream, band, .62)!);
          }, alternate: variant == 1);
        }
      case ObstacleKind.crystalSteps:
        place(const [4, 6, 5][variant], (k, i) {
          _gem(
            c,
            k,
            Color.lerp(SkyColors.white, band, i.isOdd ? .74 : .5)!,
            SkyColors.cream,
          );
        }, alternate: variant == 1);
    }

    if (variant == 2) _clasp(c, bounds, s, band, tone(SkyColors.gold));
  }

  static Color _tint(ObstacleKind kind) => switch (kind) {
    ObstacleKind.garden => SkyColors.mint,
    ObstacleKind.petalGate => SkyColors.coral,
    ObstacleKind.windLift => SkyColors.teal,
    ObstacleKind.switchback => SkyColors.lavender,
    ObstacleKind.lanternDrift => SkyColors.gold,
    ObstacleKind.sunWheels => SkyColors.yellow,
    ObstacleKind.crystalSteps => SkyColors.skyDeep,
  };

  static double _pace(ObstacleKind kind) => switch (kind) {
    ObstacleKind.windLift => .3,
    ObstacleKind.sunWheels => .24,
    ObstacleKind.petalGate => .15,
    ObstacleKind.lanternDrift => .09,
    ObstacleKind.garden ||
    ObstacleKind.switchback ||
    ObstacleKind.crystalSteps => .11,
  };

  static void _oval(Canvas c, Rect r, Color color, double width) {
    if (r.width < 1 || r.height < 1 || width < .2) return;
    c.drawOval(
      r,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
  }

  static void _rim(
    Canvas c,
    Rect bounds,
    double rope,
    Color cord,
    Color band,
    Color tint,
    bool cleared,
  ) {
    _oval(
      c,
      bounds.inflate(2.2),
      cord.withValues(alpha: cleared ? .3 : .16),
      math.min(4, rope * .48),
    );
    final cordPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = rope
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(cord, SkyColors.white, cleared ? .22 : .4)!,
          cord,
          Color.lerp(cord, tint, cleared ? .08 : .2)!,
        ],
        stops: const [0, .48, 1],
      ).createShader(bounds.inflate(rope));
    c.drawOval(bounds, cordPaint);
    _oval(c, bounds, band, math.max(1.6, rope * .46));
    final inset = math.min(2.6, bounds.shortestSide * .1);
    if (inset < rope * .42) {
      _oval(
        c,
        bounds.deflate(inset),
        SkyColors.white.withValues(alpha: cleared ? .38 : .72),
        1.15,
      );
    }
    c.drawArc(
      bounds,
      -2.4,
      1.05,
      false,
      Paint()
        ..color = SkyColors.white.withValues(alpha: cleared ? .3 : .7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.min(1.7, math.max(.8, rope * .18))
        ..strokeCap = StrokeCap.round,
    );
  }

  static void _stitches(Canvas c, Rect oval, Color color) {
    if (oval.width < 2 || oval.height < 2) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    const count = 9;
    const sweep = .2;
    final step = math.pi * 2 / count;
    for (var i = 0; i < count; i++) {
      c.drawArc(oval, -math.pi / 2 + i * step, sweep, false, paint);
    }
  }

  static void _clasp(Canvas c, Rect bounds, double s, Color dye, Color metal) {
    final h = 5.4 * s;
    final w = 9.2 * s;
    final rect = Rect.fromCenter(
      center: bounds.topCenter + Offset(0, -h * .08),
      width: w,
      height: h,
    );
    final radius = Radius.circular(h / 2);
    c.drawRRect(
      RRect.fromRectAndRadius(rect.inflate(math.min(1.2, s * .8)), radius),
      Paint()..color = Color.lerp(SkyColors.cream, SkyColors.white, .35)!,
    );
    c.drawRRect(RRect.fromRectAndRadius(rect, radius), Paint()..color = dye);
    c.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      Paint()
        ..color = metal.withValues(alpha: .9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.8, s * .7),
    );
    c.drawLine(
      rect.center + Offset(-w * .28, 0),
      rect.center + Offset(w * .28, 0),
      Paint()
        ..color = SkyColors.cream
        ..strokeWidth = math.max(1, s * 1.1)
        ..strokeCap = StrokeCap.round,
    );
  }

  static void _around(
    Canvas c,
    Rect oval, {
    required int count,
    required double turn,
    required double s,
    required void Function(double size, int index) draw,
    bool alternate = false,
    double twist = 0,
  }) {
    if (count <= 0 || s <= 0 || oval.width < 1 || oval.height < 1) return;
    final origin = oval.center;
    final rx = oval.width / 2;
    final ry = oval.height / 2;
    for (var i = 0; i < count; i++) {
      final a = turn + i * math.pi * 2 / count;
      final at = origin + Offset(math.cos(a) * rx, math.sin(a) * ry);
      if (!at.dx.isFinite || !at.dy.isFinite) continue;
      c.save();
      c.translate(at.dx, at.dy);
      c.rotate(a + twist);
      draw(alternate && i.isOdd ? s * .74 : s, i);
      c.restore();
    }
  }

  static void _leaf(Canvas c, double s, Color color) {
    c.drawPath(
      Path()
        ..moveTo(-s * .3, 0)
        ..quadraticBezierTo(s * 2.4, -s * 2.7, s * 7, 0)
        ..quadraticBezierTo(s * 2.4, s * 2.7, -s * .3, 0)
        ..close(),
      Paint()..color = color,
    );
    c.drawLine(
      Offset(s * .4, 0),
      Offset(s * 5.4, 0),
      Paint()
        ..color = Color.lerp(color, SkyColors.ink, .22)!.withValues(alpha: .45)
        ..strokeWidth = math.max(.7, s * .7)
        ..strokeCap = StrokeCap.round,
    );
  }

  static void _blossom(Canvas c, double s, Color petal, Color heart) {
    final paint = Paint()..color = petal;
    for (var i = 0; i < 3; i++) {
      c.save();
      c.rotate(i * math.pi * 2 / 3);
      c.drawPath(
        Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(s * 1.15, -s * 1.9, s * 3.2, 0)
          ..quadraticBezierTo(s * 1.15, s * 1.9, 0, 0)
          ..close(),
        paint,
      );
      c.restore();
    }
    c.drawCircle(Offset.zero, s * 1.2, Paint()..color = heart);
  }

  static void _tooth(Canvas c, double s, Color color) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-s * .2, -s * 1.2, s * 5.6, s * 2.4),
        Radius.circular(s * 1.2),
      ),
      Paint()..color = color,
    );
  }

  static void _bolt(Canvas c, double s, Color metal, Color shine) {
    final side = s * 4.2;
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: side, height: side),
        Radius.circular(s * .9),
      ),
      Paint()..color = metal,
    );
    c.drawCircle(Offset(-s * .55, -s * .55), s * .85, Paint()..color = shine);
  }

  static void _chevron(Canvas c, double s, Color color) {
    c.drawPath(
      Path()
        ..moveTo(-s * 2, -s * 2.5)
        ..lineTo(s * 2.2, 0)
        ..lineTo(-s * 2, s * 2.5),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.7, s * 2)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  static void _lantern(
    Canvas c,
    double s,
    Color paper,
    Color window,
    Color cap,
  ) {
    final body = Rect.fromCenter(
      center: Offset(s * 2.3, 0),
      width: s * 5,
      height: s * 6.6,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(body, Radius.circular(s * 1.7)),
      Paint()..color = paper,
    );
    final pane = body.deflate(s * 1.2);
    if (pane.width > .8 && pane.height > .8) {
      c.drawRRect(
        RRect.fromRectAndRadius(pane, Radius.circular(s * .8)),
        Paint()..color = window,
      );
    }
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(s * .15, 0),
          width: s * 1.8,
          height: s * 2.5,
        ),
        Radius.circular(s * .45),
      ),
      Paint()..color = cap,
    );
  }

  static void _ray(Canvas c, double s, Color color) {
    c.drawPath(
      Path()
        ..moveTo(s * .3, -s * 1.7)
        ..lineTo(s * 6.6, 0)
        ..lineTo(s * .3, s * 1.7)
        ..close(),
      Paint()..color = color,
    );
  }

  static void _spark(Canvas c, double s, Color color) {
    c.drawPath(
      Path()
        ..moveTo(s * 3.6, 0)
        ..lineTo(s * .85, s * .85)
        ..lineTo(0, s * 3.6)
        ..lineTo(-s * .85, s * .85)
        ..lineTo(-s * 3.6, 0)
        ..lineTo(-s * .85, -s * .85)
        ..lineTo(0, -s * 3.6)
        ..lineTo(s * .85, -s * .85)
        ..close(),
      Paint()..color = color,
    );
  }

  static void _gem(Canvas c, double s, Color color, Color facet) {
    c.drawPath(
      Path()
        ..moveTo(-s * 1.3, 0)
        ..lineTo(0, -s * 2.7)
        ..lineTo(s * 5.4, 0)
        ..lineTo(0, s * 2.7)
        ..close(),
      Paint()..color = color,
    );
    c.drawPath(
      Path()
        ..moveTo(s * .4, 0)
        ..lineTo(s * 1.7, -s * 1.05)
        ..lineTo(s * 3.5, 0)
        ..close(),
      Paint()..color = facet.withValues(alpha: .84),
    );
  }
}
