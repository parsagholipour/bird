import 'dart:ui';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import '../domain/game_rules.dart';
import '../domain/tracking.dart';
import '../ui/theme.dart';

class BirdGame extends FlameGame {
  BirdGame({
    required this.simulation,
    required this.nowMs,
    required this.bird,
    required this.reducedMotion,
    required this.onChanged,
    this.advance,
    this.playback = false,
    this.transparent = false,
  });
  FlightSimulation simulation;
  final void Function(double dt, double now, double width)? advance;
  final bool playback;
  bool transparent;
  final double Function() nowMs;
  final int bird;
  final bool reducedMotion;
  final void Function() onChanged;
  Sprite? _bird, _island;
  double _time = 0, _notify = 0;
  final List<double> _frameDurations = [];
  double get renderHz => _frameDurations.isEmpty
      ? 0
      : _frameDurations.length / _frameDurations.reduce((a, b) => a + b);
  double get p95FrameMs {
    if (_frameDurations.isEmpty) return 0;
    final frames = [..._frameDurations]..sort();
    return frames[((frames.length - 1) * .95).ceil()] * 1000;
  }

  @override
  Color backgroundColor() =>
      transparent ? const Color(0x00000000) : SkyColors.sky;
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _bird = await loadSprite(
      '${['pip', 'peaches', 'minty', 'orbit'][bird]}.png',
    );
    _island = await loadSprite('island.png');
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (size.y <= 0) return;
    _time = playback ? simulation.elapsed : _time + dt;
    if (simulation.phase == RunPhase.playing && dt > 0) {
      _frameDurations.add(dt);
      if (_frameDurations.length > 600) _frameDurations.removeAt(0);
    }
    if (playback) return;
    if (advance != null) {
      advance!(dt, nowMs(), size.x / size.y);
    } else {
      simulation.tick(dt, nowMs(), viewportWidth: size.x / size.y);
    }
    _notify += dt;
    if (_notify >= .05 || simulation.phase == RunPhase.ended) {
      _notify = 0;
      onChanged();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final w = size.x, h = size.y;
    if (h <= 0) return;
    if (!transparent) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        Paint()
          ..shader = Gradient.linear(
            Offset.zero,
            Offset(0, h),
            [SkyColors.skyDeep, SkyColors.sky, const Color(0xffe4f4e7)],
            const [0, .5, 1],
          ),
      );
      final drift = reducedMotion ? 0 : _time * 5;
      for (var i = 0; i < 5; i++) {
        final x = ((i * w * .28 - drift) % (w + 160)) - 70;
        _cloud(
          canvas,
          Offset(x, h * (.12 + (i % 3) * .16)),
          h * (.26 + (i % 2) * .09),
          .6,
        );
      }
      if (_island != null) {
        final x = ((w * .73 - simulation.distance * h * .13) % (w + h * .5));
        _island!.render(
          canvas,
          position: Vector2(x, h * .77),
          size: Vector2(h * .5, h * .3125),
          overridePaint: Paint()..color = const Color(0x77ffffff),
        );
        _island!.render(
          canvas,
          position: Vector2(
            ((w * .18 - simulation.distance * h * .08) % (w + h * .3)),
            h * .86,
          ),
          size: Vector2(h * .32, h * .20),
          overridePaint: Paint()..color = const Color(0x55ffffff),
        );
      }
    }
    for (final o in simulation.obstacles) {
      final x = o.x * h,
          width = o.width * h,
          top = o.top * h,
          bottom = o.bottom * h;
      _tower(canvas, Rect.fromLTWH(x, -10, width, top + 10), true);
      _tower(canvas, Rect.fromLTWH(x, bottom, width, h - bottom + 10), false);
      if (!o.scored) {
        final center = Offset(x + width / 2, o.center * h);
        final paint = Paint()
          ..color = SkyColors.white.withValues(alpha: .55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(center, h * .018, paint);
      }
    }
    if (_bird != null) {
      final cx = FlightSimulation.birdX * h, cy = simulation.birdY * h;
      canvas.save();
      canvas.translate(cx, cy);
      final tilt = simulation.rules.mode == PlayMode.smile
          ? (simulation.velocity * .6).clamp(-.23, .4)
          : 0.0;
      canvas.rotate(tilt);
      final bw = h * .145;
      _bird!.render(
        canvas,
        position: Vector2(-bw * .48, -bw * .43),
        size: Vector2(bw, bw * 224 / 256),
      );
      canvas.restore();
    }
  }

  void _cloud(Canvas c, Offset o, double w, double alpha) {
    final p = Paint()..color = SkyColors.white.withValues(alpha: alpha);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(o.dx, o.dy + w * .13, w, w * .16),
        Radius.circular(w * .08),
      ),
      p,
    );
    c.drawOval(
      Rect.fromLTWH(o.dx + w * .12, o.dy + w * .03, w * .34, w * .23),
      p,
    );
    c.drawOval(Rect.fromLTWH(o.dx + w * .38, o.dy, w * .34, w * .28), p);
  }

  void _tower(Canvas c, Rect r, bool top) {
    if (r.right < 0 || r.left > size.x) return;
    final p = Paint()..color = SkyColors.sand;
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(8)), p);
    c.drawRect(
      Rect.fromLTWH(r.left + r.width * .68, r.top, r.width * .32, r.height),
      Paint()..color = SkyColors.rock.withValues(alpha: .6),
    );
    final edge = top ? r.bottom - 17 : r.top;
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(r.left - 5, edge, r.width + 10, 17),
        const Radius.circular(7),
      ),
      Paint()..color = SkyColors.teal,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(r.left - 5, top ? edge + 9 : edge, r.width + 10, 8),
        const Radius.circular(5),
      ),
      Paint()..color = SkyColors.mint,
    );
    final line = Paint()
      ..color = SkyColors.cream.withValues(alpha: .3)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (double y = r.top + 40; y < r.bottom - 25; y += 48) {
      c.drawLine(
        Offset(r.left + 8, y),
        Offset(r.left + r.width * .55, y - 4),
        line,
      );
    }
  }
}
