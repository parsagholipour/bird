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
    final palette = SkyPalette.at(seconds);
    c.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = Gradient.linear(Offset.zero, Offset(0, h), [
          palette.top,
          palette.horizon,
        ]),
    );
    final sun = Offset(w * .76, h * .28);
    for (var i = 3; i >= 1; i--) {
      c.drawCircle(
        sun,
        h * (.09 + i * .04),
        Paint()..color = SkyColors.cream.withValues(alpha: .055),
      );
    }
    c.drawCircle(
      sun,
      h * .095,
      Paint()..color = SkyColors.cream.withValues(alpha: .85),
    );
    final cycle = seconds % 60;
    final night =
        ((cycle - 33) / 7).clamp(0.0, 1.0) * ((60 - cycle) / 5).clamp(0.0, 1.0);
    if (night > 0) {
      for (var i = 0; i < 32; i++) {
        final x = ((i * 137.5) % w);
        final y = h * (.08 + ((i * 7) % 17) / 35);
        c.drawCircle(
          Offset(x, y),
          i % 5 == 0 ? 1.8 : 1,
          Paint()..color = SkyColors.cream.withValues(alpha: night * .7),
        );
      }
    }
    // Far and near mountain silhouettes drift at different speeds.
    for (var layer = 0; layer < 3; layer++) {
      final path = Path()..moveTo(-h, h);
      final travel = reducedMotion ? 0.0 : distance * h * (.025 + layer * .03);
      final segment = h * .48;
      final shift = travel % segment;
      path.lineTo(-segment - shift, h * .82);
      for (var i = -1; i < (w / segment).ceil() + 3; i++) {
        final x = i * segment - shift;
        final y = h * (.70 + layer * .065);
        path.quadraticBezierTo(
          x + segment * .25,
          y - h * (.15 - layer * .025),
          x + segment * .6,
          y,
        );
        path.quadraticBezierTo(x + segment * .8, y + h * .04, x + segment, y);
      }
      path.lineTo(w + h, h);
      path.close();
      c.drawPath(
        path,
        Paint()
          ..color = Color.lerp(
            palette.haze,
            palette.land,
            .2 + layer * .2,
          )!.withValues(alpha: .35 + layer * .1),
      );
    }
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
    for (var i = 0; i < 7; i++) {
      final x = ((i * w * .23 - drift) % (w + h * .5)) - h * .25;
      cloud(
        c,
        Offset(x, h * (.13 + (i % 3) * .15)),
        h * (.22 + i % 2 * .1),
        .32,
      );
    }
    // Tiny distant gliders add life without competing with the player's bird.
    final driftBird = reducedMotion ? 0.0 : seconds * 3;
    final pen = Paint()
      ..color = palette.land.withValues(alpha: .5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final x = (w * .53 + i * 18 - driftBird) % w;
      final y = h * .22 + i * 7;
      c.drawPath(
        Path()
          ..moveTo(x - 5, y)
          ..quadraticBezierTo(x - 2, y - 3, x, y)
          ..quadraticBezierTo(x + 2, y - 3, x + 5, y),
        pen,
      );
    }
  }

  static void cloud(Canvas c, Offset o, double w, double alpha) {
    final p = Paint()..color = SkyColors.white.withValues(alpha: alpha);
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(o.dx, o.dy + w * .13, w, w * .16),
          Radius.circular(w * .08),
        ),
      )
      ..addOval(Rect.fromLTWH(o.dx + w * .12, o.dy + w * .03, w * .34, w * .23))
      ..addOval(Rect.fromLTWH(o.dx + w * .38, o.dy, w * .34, w * .28));
    c.drawPath(path, p);
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
