import 'dart:math' as math;
import 'dart:ui';
import '../ui/theme.dart';
import 'sky_landmarks.dart';

/// Procedural scenery keeps the offline APK small and scales to any viewport.
class SkyPalette {
  const SkyPalette(this.top, this.horizon, this.haze, this.land, this.accent);
  final Color top, horizon, haze, land, accent;
  static const sunrise = SkyPalette(
    Color(0xff8dd8eb),
    Color(0xffe9f5df),
    Color(0xfff9eac5),
    Color(0xff68b1a8),
    SkyColors.yellow,
  );
  static const peach = SkyPalette(
    Color(0xffaaa9e0),
    Color(0xffffdfc3),
    Color(0xfff3b6aa),
    Color(0xff9e82b4),
    SkyColors.coral,
  );
  static const twilight = SkyPalette(
    Color(0xff485584),
    Color(0xffadb6da),
    Color(0xffcbc9e3),
    Color(0xff626c9f),
    SkyColors.lavender,
  );
  static SkyPalette at(double seconds) {
    const all = [sunrise, peach, twilight];
    final phase = (seconds / 20) % 3;
    final i = phase.floor();
    final a = all[i], b = all[(i + 1) % 3];
    final t = ((phase - i - .75) * 4).clamp(0.0, 1.0);
    return SkyPalette(
      Color.lerp(a.top, b.top, t)!,
      Color.lerp(a.horizon, b.horizon, t)!,
      Color.lerp(a.haze, b.haze, t)!,
      Color.lerp(a.land, b.land, t)!,
      Color.lerp(a.accent, b.accent, t)!,
    );
  }

  static double regionWeight(double seconds, int region) {
    final phase = (seconds / 20) % 3;
    final index = phase.floor();
    final blend = ((phase - index - .75) * 4).clamp(0.0, 1.0);
    if (region == index) return 1 - blend;
    return region == (index + 1) % 3 ? blend : 0;
  }
}

class SkyScenery {
  static void paint(
    Canvas c,
    Size size, {
    double seconds = 0,
    double distance = 0,
    bool reducedMotion = false,
  }) {
    final w = size.width, h = size.height;
    if (w <= 0 || h <= 0) return;
    final palette = SkyPalette.at(seconds);
    final cycle = seconds % 60;
    final night =
        ((cycle - 33) / 7).clamp(0.0, 1.0) * ((60 - cycle) / 5).clamp(0.0, 1.0);
    c.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = Gradient.linear(
          Offset.zero,
          Offset(0, h),
          [
            palette.top,
            Color.lerp(palette.top, palette.horizon, .42)!,
            palette.horizon,
            Color.lerp(palette.horizon, palette.haze, .45)!,
          ],
          const [0, .38, .7, 1],
        ),
    );
    _sun(c, Offset(w * .76, h * .28), h, palette, night);
    if (night > 0) _stars(c, size, night);
    for (var layer = 0; layer < 3; layer++) {
      _range(
        c,
        size,
        layer: layer,
        palette: palette,
        distance: distance,
        reducedMotion: reducedMotion,
      );
    }
    _islets(
      c,
      size,
      palette: palette,
      distance: distance,
      reducedMotion: reducedMotion,
    );
    SkyLandmarks.paint(
      c,
      size,
      seconds: seconds,
      distance: distance,
      reducedMotion: reducedMotion,
      sunrise: SkyPalette.regionWeight(seconds, 0),
      peach: SkyPalette.regionWeight(seconds, 1),
      twilight: SkyPalette.regionWeight(seconds, 2),
    );
    final drift = reducedMotion ? 0.0 : distance * h * .1;
    for (var i = 0; i < 4; i++) {
      final x = ((i * w * .34 - drift * .45) % (w + h * .4)) - h * .2;
      cloud(
        c,
        Offset(x, h * (.06 + (i % 2) * .08)),
        h * (.16 + (i % 2) * .04),
        .2,
        shape: i + 1,
      );
    }
    for (var i = 0; i < 6; i++) {
      final x = ((i * w * .27 - drift) % (w + h * .55)) - h * .28;
      cloud(
        c,
        Offset(x, h * (.14 + (i % 3) * .12)),
        h * (.24 + (i % 2) * .08),
        .4 + (i % 3) * .04,
        shape: i,
      );
    }
    _flock(
      c,
      size,
      seconds: seconds,
      reducedMotion: reducedMotion,
      night: night,
      palette: palette,
    );
  }

  static void _sun(
    Canvas c,
    Offset sun,
    double h,
    SkyPalette palette,
    double night,
  ) {
    c.drawCircle(
      sun,
      h * .3,
      Paint()
        ..shader = Gradient.radial(
          sun,
          h * .3,
          [
            palette.accent.withValues(alpha: .22 * (1 - night * .35)),
            palette.accent.withValues(alpha: .06),
            palette.accent.withValues(alpha: 0),
          ],
          const [0, .42, 1],
        ),
    );
    final disc = h * .078;
    c.drawCircle(
      sun,
      disc,
      Paint()..color = SkyColors.cream.withValues(alpha: .96),
    );
    c.save();
    c.clipPath(Path()..addOval(Rect.fromCircle(center: sun, radius: disc)));
    c.drawOval(
      Rect.fromCenter(
        center: sun + Offset(0, disc * .42),
        width: disc * 2.1,
        height: disc * 1.15,
      ),
      Paint()..color = palette.accent.withValues(alpha: .34 * (1 - night)),
    );
    c.restore();
    c.drawCircle(
      sun + Offset(-disc * .28, -disc * .3),
      disc * .38,
      Paint()..color = SkyColors.white.withValues(alpha: .72),
    );
    if (night > .35) {
      final shade = palette.haze.withValues(alpha: night * .28);
      for (final (dx, dy, r) in [
        (-.22, .08, .16),
        (.18, -.2, .1),
        (.08, .28, .08),
      ]) {
        c.drawCircle(
          sun + Offset(disc * dx, disc * dy),
          disc * r,
          Paint()..color = shade,
        );
      }
    }
  }

  static void _stars(Canvas c, Size size, double night) {
    final w = size.width, h = size.height;
    for (var i = 0; i < 28; i++) {
      final x = (i * 137.5) % w;
      final y = h * (.05 + ((i * 7) % 17) / 40);
      final alpha = night * (i % 4 == 0 ? .85 : .55);
      if (i % 5 == 0) {
        c.drawPath(
          star(Offset(x, y), i % 10 == 0 ? 3.2 : 2.1),
          Paint()..color = SkyColors.cream.withValues(alpha: alpha),
        );
      } else {
        c.drawCircle(
          Offset(x, y),
          i % 4 == 0 ? 1.7 : 1,
          Paint()..color = SkyColors.cream.withValues(alpha: alpha),
        );
      }
    }
  }

  static void _range(
    Canvas c,
    Size size, {
    required int layer,
    required SkyPalette palette,
    required double distance,
    required bool reducedMotion,
  }) {
    final h = size.height;
    final travel = reducedMotion ? 0.0 : distance * h * (.02 + layer * .028);
    final span = h * (.34 + layer * .05);
    final base = h * (.7 + layer * .055);
    final rise = h * (.16 - layer * .03);
    final fill = switch (layer) {
      0 => Color.lerp(palette.horizon, palette.haze, .62)!,
      1 => Color.lerp(palette.haze, palette.land, .55)!,
      _ => Color.lerp(palette.land, palette.haze, .12)!,
    };
    final cap = Color.lerp(
      SkyColors.cream,
      layer == 2 ? SkyColors.mint : palette.horizon,
      .4,
    )!;
    final paint = Paint()..color = fill;
    c.drawRect(
      Rect.fromLTWH(-h, base, size.width + h * 2, h - base + 2),
      paint,
    );
    const widths = <List<double>>[
      [1.35, .62, 1.05, .48, .88],
      [.7, 1.25, .55, 1.0, .78],
      [1.15, .5, .92, 1.4, .66],
    ];
    const heights = <List<double>>[
      [.42, 1, .58, .78, .34],
      [1, .4, .86, .55, .72],
      [.62, .95, .38, .8, .5],
    ];
    final count = (size.width / span).ceil() + 6;
    for (var i = 0; i < count; i++) {
      final width = span * widths[layer][i % 5];
      final domeRise = rise * heights[layer][i % 5];
      final cx = -span * 2 - (travel % span) + i * span * .78;
      final dome = Rect.fromCenter(
        center: Offset(cx, base),
        width: width,
        height: domeRise * 2,
      );
      c.drawOval(dome, paint);
      c.save();
      c.clipPath(Path()..addOval(dome));
      c.clipRect(Rect.fromLTWH(dome.left, dome.top, dome.width, domeRise * .7));
      c.drawOval(
        Rect.fromCenter(
          center: Offset(cx - width * .08, base - domeRise * .55),
          width: width * .5,
          height: domeRise * .7,
        ),
        Paint()..color = cap.withValues(alpha: .42),
      );
      c.restore();
    }
    if (layer == 2) _meadow(c, size, palette, travel, span);
  }

  static void _meadow(
    Canvas c,
    Size size,
    SkyPalette palette,
    double travel,
    double span,
  ) {
    final h = size.height;
    final bush = Color.lerp(
      SkyColors.mint,
      palette.land,
      .35,
    )!.withValues(alpha: .85);
    final paint = Paint()..color = bush;
    final bloom = Paint()..color = palette.accent.withValues(alpha: .8);
    for (var i = 0; i < 9; i++) {
      final x = ((i * span * .72 - travel) % (size.width + h * .2)) - h * .1;
      final y = h * (.86 + (i % 3) * .03);
      c.drawCircle(Offset(x, y), h * .018, paint);
      c.drawCircle(Offset(x - h * .016, y + h * .006), h * .013, paint);
      c.drawCircle(Offset(x + h * .014, y + h * .008), h * .012, paint);
      if (i.isEven) {
        c.drawCircle(Offset(x + h * .004, y - h * .01), h * .006, bloom);
      }
    }
  }

  static void _islets(
    Canvas c,
    Size size, {
    required SkyPalette palette,
    required double distance,
    required bool reducedMotion,
  }) {
    final w = size.width, h = size.height;
    final drift = reducedMotion ? 0.0 : distance * h * .04;
    final grass = Color.lerp(SkyColors.teal, palette.land, .28)!;
    for (var i = 0; i < 3; i++) {
      final x = ((i * w * .42 + h * .2 - drift) % (w + h * .36)) - h * .18;
      _islet(
        c,
        Offset(x, h * (.6 + (i % 2) * .045)),
        h * (.16 + (i % 2) * .035),
        grass,
      );
    }
  }

  static void _islet(Canvas c, Offset center, double w, Color grass) {
    c.drawPath(
      Path()
        ..moveTo(center.dx - w * .42, center.dy)
        ..lineTo(center.dx - w * .26, center.dy + w * .2)
        ..lineTo(center.dx - w * .02, center.dy + w * .28)
        ..lineTo(center.dx + w * .18, center.dy + w * .16)
        ..lineTo(center.dx + w * .38, center.dy + w * .05)
        ..close(),
      Paint()..color = SkyColors.sand,
    );
    c.drawPath(
      Path()
        ..moveTo(center.dx - w * .42, center.dy)
        ..lineTo(center.dx - w * .2, center.dy + w * .14)
        ..lineTo(center.dx - w * .02, center.dy + w * .05)
        ..close(),
      Paint()..color = SkyColors.rock,
    );
    c.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, w * .02),
        width: w,
        height: w * .28,
      ),
      Paint()..color = grass,
    );
    c.drawOval(
      Rect.fromCenter(
        center: center + Offset(-w * .05, -w * .02),
        width: w * .68,
        height: w * .15,
      ),
      Paint()..color = SkyColors.mint,
    );
    c.drawOval(
      Rect.fromCenter(
        center: center + Offset(-w * .1, -w * .045),
        width: w * .28,
        height: w * .07,
      ),
      Paint()..color = SkyColors.cream.withValues(alpha: .8),
    );
    final trunk = Paint()
      ..color = SkyColors.rock
      ..strokeWidth = w * .035
      ..strokeCap = StrokeCap.round;
    final trunkTop = center + Offset(w * .14, -w * .2);
    c.drawLine(center + Offset(w * .14, w * .02), trunkTop, trunk);
    c.drawCircle(
      trunkTop + Offset(0, -w * .08),
      w * .11,
      Paint()..color = grass,
    );
    c.drawCircle(
      trunkTop + Offset(-w * .04, -w * .12),
      w * .045,
      Paint()..color = SkyColors.mint,
    );
  }

  static void _flock(
    Canvas c,
    Size size, {
    required double seconds,
    required bool reducedMotion,
    required double night,
    required SkyPalette palette,
  }) {
    final w = size.width, h = size.height;
    final drift = reducedMotion ? 0.0 : seconds * 3;
    final color = Color.lerp(
      palette.land,
      SkyColors.cream,
      night,
    )!.withValues(alpha: .42 + night * .25);
    for (var i = 0; i < 5; i++) {
      final column = i - 2;
      _glider(
        c,
        Offset(
          (w * .58 + column * h * .045 - drift) % w,
          h * .2 + column.abs() * h * .018,
        ),
        h * .012,
        color,
      );
    }
  }

  static void _glider(Canvas c, Offset p, double scale, Color color) {
    c.save();
    c.translate(p.dx, p.dy);
    c.scale(scale);
    final paint = Paint()..color = color;
    c.drawPath(
      Path()
        ..moveTo(1.4, .1)
        ..quadraticBezierTo(-.4, -1.7, -3.6, -.2)
        ..quadraticBezierTo(-1.5, .25, .3, .4)
        ..close(),
      paint,
    );
    c.drawPath(
      Path()
        ..moveTo(1.4, .15)
        ..quadraticBezierTo(-.2, 1.15, -3.1, .85)
        ..quadraticBezierTo(-1.2, .35, .2, .2)
        ..close(),
      paint,
    );
    c.drawOval(
      Rect.fromCenter(center: const Offset(1.7, .12), width: 1.5, height: .62),
      paint,
    );
    c.restore();
  }

  static void cloud(
    Canvas c,
    Offset o,
    double w,
    double alpha, {
    int shape = 0,
  }) {
    final lift = (shape % 3) * w * .02;
    c.drawOval(
      Rect.fromLTWH(o.dx + w * .08, o.dy + w * .26, w * .84, w * .12),
      Paint()..color = const Color(0xff7aa4b6).withValues(alpha: alpha * .2),
    );
    final body = Paint()..color = SkyColors.white.withValues(alpha: alpha);
    final lobes = switch (shape % 3) {
      0 => [
        Rect.fromLTWH(o.dx + w * .04, o.dy + w * .12, w * .32, w * .2),
        Rect.fromLTWH(o.dx + w * .26, o.dy + w * .02, w * .4, w * .24),
        Rect.fromLTWH(o.dx + w * .56, o.dy + w * .08, w * .3, w * .2),
        Rect.fromLTWH(o.dx + w * .74, o.dy + w * .14, w * .22, w * .15),
      ],
      1 => [
        Rect.fromLTWH(o.dx, o.dy + w * .14 - lift, w * .28, w * .18),
        Rect.fromLTWH(o.dx + w * .18, o.dy + w * .05, w * .36, w * .22),
        Rect.fromLTWH(o.dx + w * .46, o.dy + lift, w * .32, w * .24),
        Rect.fromLTWH(o.dx + w * .7, o.dy + w * .1, w * .26, w * .16),
      ],
      _ => [
        Rect.fromLTWH(o.dx + w * .08, o.dy + w * .08, w * .34, w * .22),
        Rect.fromLTWH(o.dx + w * .32, o.dy + w * .02 + lift, w * .3, w * .2),
        Rect.fromLTWH(o.dx + w * .54, o.dy + w * .1, w * .28, w * .18),
        Rect.fromLTWH(o.dx + w * .72, o.dy + w * .13, w * .24, w * .15),
      ],
    };
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(o.dx, o.dy + w * .16, w, w * .16),
        Radius.circular(w * .08),
      ),
      body,
    );
    for (final lobe in lobes) {
      c.drawOval(lobe, body);
    }
    c.drawOval(
      Rect.fromLTWH(
        lobes[1].left + w * .08,
        lobes[1].top + w * .03,
        w * .14,
        w * .08,
      ),
      Paint()..color = SkyColors.cream.withValues(alpha: alpha * .5),
    );
  }

  static Path star(
    Offset center,
    double radius, {
    double rotation = -math.pi / 2,
  }) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = rotation + i * math.pi / 5;
      final r = radius * (i.isEven ? 1 : .46);
      final p = center + Offset(math.cos(a) * r, math.sin(a) * r);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }
}
