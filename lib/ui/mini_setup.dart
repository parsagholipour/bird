import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../domain/tracking.dart';
import '../game/bird_puppet.dart';
import 'match_hud.dart' show MatchPlate;
import 'mode_picker_art.dart';
import 'theme.dart';

/// Pieces of the camera setup screen shown before Push-Up Flight, Squat & Fly
/// and Jump & Fly: the hero scene, the "how to fly" rail, the lives chip and
/// the microphone badge.

/// The setup screen's hero: the workout's own picker scene, grown to fill the
/// card, with the phone that watches you on one side and your bird answering
/// the move on the other. The bird bobs and the phone's record light blinks
/// unless motion is reduced.
class SetupHero extends StatefulWidget {
  const SetupHero({
    super.key,
    required this.mode,
    required this.color,
    required this.bird,
    this.reducedMotion = false,
  });
  final PlayMode mode;
  final Color color;
  final int bird;
  final bool reducedMotion;

  @override
  State<SetupHero> createState() => _SetupHeroState();
}

class _SetupHeroState extends State<SetupHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(SetupHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final still =
        widget.reducedMotion || MediaQuery.disableAnimationsOf(context);
    if (still) {
      motion
        ..stop()
        ..value = .25;
    } else if (!motion.isAnimating) {
      motion.repeat();
    }
  }

  @override
  void dispose() {
    motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      size: Size.infinite,
      painter: SetupHeroArt(
        mode: widget.mode,
        color: widget.color,
        bird: widget.bird,
        motion: motion,
      ),
    ),
  );
}

/// Paints [SetupHero]. [motion] runs 0 to 1 once per bob of the bird.
class SetupHeroArt extends CustomPainter {
  SetupHeroArt({
    required this.mode,
    required this.color,
    required this.bird,
    required this.motion,
  }) : super(repaint: motion);
  final PlayMode mode;
  final Color color;
  final int bird;
  final Animation<double> motion;

  /// The picker scene is 180 × 140 units; the phone and the bird sit in the
  /// margins either side, so the whole story needs about this many.
  static const span = 330.0;

  @override
  void paint(Canvas canvas, Size size) {
    ModePickerArt(mode: mode, color: color).paint(canvas, size);
    // The same fit the picker art uses, so the overlays line up with it.
    final s = math.min(size.width / 180, size.height / 140);
    final origin = Offset((size.width - 180 * s) / 2, size.height - 140 * s);
    // Too narrow for the margins: the picker scene alone still reads.
    if (size.width < span * s) return;
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(s);
    final t = motion.value;
    final frame = switch (mode) {
      PlayMode.pushUp => const Rect.fromLTRB(36, 34, 170, 128),
      PlayMode.squat => const Rect.fromLTRB(52, 32, 140, 128),
      _ => const Rect.fromLTRB(46, 26, 140, 130),
    };
    final lens = _phone(canvas, t);
    _view(canvas, lens, frame);
    _flight(canvas, t);
    canvas.restore();
  }

  /// The phone, propped low for push-ups and on a little tripod in landscape
  /// for full-body moves. Returns where its lens is.
  Offset _phone(Canvas canvas, double t) {
    final low = mode == PlayMode.pushUp;
    final ink = Paint()..color = SkyColors.ink;
    final shadow = Paint()..color = SkyColors.ink.withValues(alpha: .14);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-36, 127), width: 44, height: 7),
      shadow,
    );
    final RRect body;
    if (low) {
      // A small wedge stand holds the phone upright on the floor.
      _outlined(
        canvas,
        Path()
          ..moveTo(-52, 126)
          ..lineTo(-24, 126)
          ..lineTo(-30, 112)
          ..close(),
        SkyColors.sand,
      );
      body = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-48, 82, 22, 38),
        const Radius.circular(5),
      );
    } else {
      final legs = Paint()
        ..color = SkyColors.ink
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      for (final foot in [-50.0, -36.0, -22.0]) {
        canvas.drawLine(const Offset(-36, 92), Offset(foot, 126), legs);
      }
      canvas.drawCircle(const Offset(-36, 92), 3.5, ink);
      body = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-56, 70, 40, 22),
        const Radius.circular(5),
      );
    }
    canvas.drawRRect(body.shift(const Offset(2, 3)), shadow);
    canvas.drawRRect(body, ink);
    final screen = body.deflate(3);
    canvas.drawRRect(screen, Paint()..color = SkyColors.sky);
    // A wave of horizon and a tiny bird on the screen: the game is running.
    canvas.save();
    canvas.clipRRect(screen);
    canvas.drawCircle(
      Offset(screen.center.dx, screen.bottom + screen.height * .6),
      screen.height * .85,
      Paint()..color = SkyColors.mint,
    );
    canvas.restore();
    BirdPuppet.paint(
      canvas,
      Rect.fromCenter(center: screen.center, width: 12, height: 10.5),
      bird: bird,
      wing: 0,
    );
    final lens = low
        ? Offset(body.center.dx, body.top + 2)
        : Offset(body.right - 2, body.center.dy);
    // The record light blinks while the phone is watching.
    final on = t < .55;
    final rec = low
        ? Offset(body.left + 4.5, body.top + 1.6)
        : Offset(body.right - 1.6, body.top + 4.5);
    canvas.drawCircle(
      rec,
      2.4,
      Paint()
        ..color = on
            ? SkyColors.coral
            : SkyColors.coralDeep.withValues(alpha: .5),
    );
    canvas.drawCircle(lens, 2.2, Paint()..color = SkyColors.night);
    canvas.drawCircle(
      lens + const Offset(-.6, -.6),
      .7,
      Paint()..color = SkyColors.cream,
    );
    return lens;
  }

  /// A soft beam from the lens and viewfinder corners around the mover: the
  /// camera needs all of this in sight.
  void _view(Canvas canvas, Offset lens, Rect frame) {
    final near = Offset(frame.left, frame.top), far = frame.bottomLeft;
    canvas.drawPath(
      Path()
        ..moveTo(lens.dx, lens.dy)
        ..lineTo(near.dx, near.dy)
        ..lineTo(far.dx, far.dy)
        ..close(),
      Paint()
        ..shader = LinearGradient(
          colors: [
            SkyColors.cream.withValues(alpha: .55),
            SkyColors.cream.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromPoints(lens, far)),
    );
    for (final end in [near, far]) {
      _dashes(canvas, lens, end, SkyColors.cream);
    }
    const arm = 11.0;
    final corners = [
      (frame.topLeft, 1.0, 1.0),
      (frame.topRight, -1.0, 1.0),
      (frame.bottomLeft, 1.0, -1.0),
      (frame.bottomRight, -1.0, -1.0),
    ];
    for (final (c, dx, dy) in corners) {
      final path = Path()
        ..moveTo(c.dx + dx * arm, c.dy)
        ..lineTo(c.dx, c.dy)
        ..lineTo(c.dx, c.dy + dy * arm);
      final pen = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(
        path,
        pen
          ..color = SkyColors.ink
          ..strokeWidth = 5.5,
      );
      canvas.drawPath(
        path,
        pen
          ..color = SkyColors.cream
          ..strokeWidth = 2.6,
      );
    }
  }

  /// Your bird answering the move, along a dotted trail: push up to climb,
  /// squat to dip and stand to rise, jump for a boost and a long glide.
  void _flight(Canvas canvas, double t) {
    final path = switch (mode) {
      PlayMode.pushUp =>
        Path()
          ..moveTo(184, 114)
          ..cubicTo(204, 108, 214, 82, 236, 58),
      PlayMode.squat =>
        Path()
          ..moveTo(180, 52)
          ..cubicTo(196, 54, 198, 108, 214, 104)
          ..cubicTo(226, 101, 228, 70, 240, 62),
      _ =>
        Path()
          ..moveTo(180, 116)
          ..cubicTo(190, 112, 194, 58, 210, 54)
          ..lineTo(242, 54),
    };
    final metric = path.computeMetrics().first;
    for (var d = 0.0; d < metric.length - 14; d += 8) {
      final p = metric.getTangentForOffset(d)!.position;
      canvas.drawCircle(
        p,
        1.9,
        Paint()..color = SkyColors.cream.withValues(alpha: .95),
      );
    }
    final end = metric.getTangentForOffset(metric.length)!.position;
    final wave = math.sin(t * math.pi * 2);
    final center = end + Offset(10, -6 + wave * 2.5);
    // A soft halo lifts the bird off the wash.
    canvas.drawCircle(
      center,
      27,
      Paint()
        ..shader = RadialGradient(
          colors: [
            SkyColors.cream.withValues(alpha: .7),
            SkyColors.cream.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: 27)),
    );
    BirdPuppet.paint(
      canvas,
      Rect.fromCenter(center: center, width: 54, height: 47),
      bird: bird,
      wing: -.15 + wave * .35,
    );
  }

  void _dashes(Canvas canvas, Offset a, Offset b, Color color) {
    final pen = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final length = (b - a).distance;
    final step = (b - a) / length;
    for (var d = 4.0; d < length - 6; d += 7) {
      canvas.drawLine(a + step * d, a + step * math.min(d + 3.5, length), pen);
    }
  }

  void _outlined(Canvas canvas, Path path, Color fill) {
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = SkyColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(SetupHeroArt oldDelegate) =>
      oldDelegate.mode != mode ||
      oldDelegate.color != color ||
      oldDelegate.bird != bird ||
      oldDelegate.motion != motion;
}

/// One step of "how to fly": a numbered coin on a dotted rail that runs down
/// to the next step, so the three read as one route.
class SetupStep extends StatelessWidget {
  const SetupStep({
    super.key,
    required this.number,
    required this.title,
    required this.subtitle,
    required this.color,
    this.last = false,
  });
  final String number, title, subtitle;
  final Color color;

  /// The last step has no rail below it.
  final bool last;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          children: [
            _Coin(number, color: color),
            if (!last)
              Expanded(
                child: CustomPaint(
                  size: const Size(30, double.infinity),
                  painter: _Rail(Color.lerp(color, SkyColors.ink, .35)!),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 3, bottom: last ? 0 : 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: heading(
                    18,
                    weight: FontWeight.w700,
                  ).copyWith(height: 1.15),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: bodyText(
                    12.5,
                    color: SkyColors.muted,
                  ).copyWith(height: 1.3),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

/// A step's coin: the workout's color with a glossy top and an ink lip, like
/// the coins on the campaign map.
class _Coin extends StatelessWidget {
  const _Coin(this.number, {required this.color});
  final String number;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 30,
    height: 30,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color.lerp(color, SkyColors.cream, .45)!, color],
      ),
      border: Border.all(color: SkyColors.ink, width: 2),
      boxShadow: const [
        BoxShadow(color: SkyColors.ink, offset: Offset(0, 2.5)),
      ],
    ),
    child: Text(
      number,
      style: heading(16, weight: FontWeight.w700).copyWith(height: 1),
    ),
  );
}

class _Rail extends CustomPainter {
  const _Rail(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()..color = color;
    for (var y = 8.0; y < size.height - 2; y += 7) {
      canvas.drawCircle(Offset(size.width / 2, y), 1.8, dot);
    }
  }

  @override
  bool shouldRepaint(_Rail oldDelegate) => oldDelegate.color != color;
}

/// What a scored flight forgives, as a sticker: three hearts and a shield on
/// endless flights, a single heart on Classic, followed by [text].
class SetupLives extends StatelessWidget {
  const SetupLives({super.key, required this.hearts, required this.text});

  /// Three hearts and a shield, or Classic's one chance.
  final bool hearts;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      MatchPlate(
        color: SkyColors.white,
        padding: const EdgeInsets.fromLTRB(7, 4, 8, 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < (hearts ? 3 : 1); i++)
              const Icon(
                Icons.favorite_rounded,
                size: 15,
                color: SkyColors.coralDeep,
              ),
            if (hearts) ...[
              const SizedBox(width: 3),
              const Icon(Icons.shield_rounded, size: 15, color: SkyColors.teal),
            ],
          ],
        ),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          text,
          style: bodyText(
            11.5,
            color: SkyColors.muted,
            weight: FontWeight.w700,
          ).copyWith(height: 1.25),
        ),
      ),
    ],
  );
}

/// The microphone's round badge: teal and live when replays record sound,
/// a quiet crossed-out mic when they do not.
class SetupMicBadge extends StatelessWidget {
  const SetupMicBadge({super.key, required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 180),
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: on ? SkyColors.teal : SkyColors.cream,
      border: Border.all(color: SkyColors.ink, width: 2),
      boxShadow: const [BoxShadow(color: SkyColors.ink, offset: Offset(0, 2))],
    ),
    child: Icon(
      on ? Icons.mic_rounded : Icons.mic_off_rounded,
      size: 20,
      color: on ? SkyColors.white : SkyColors.muted,
    ),
  );
}
