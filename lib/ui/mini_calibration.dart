import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'components.dart' show BirdArt;
import 'match_hud.dart' show MatchPlate, matchDigits, matchInkEdge;
import 'theme.dart';

/// The pieces of a workout's camera calibration screen: a sticker bezel
/// around the live camera window, a badge saying what the camera is doing,
/// the coach's note, a meter for how far calibration has come and a little
/// sky where the bird shows the player's range.
///
/// On Android the live preview is a platform view laid out under these
/// widgets, so everything that sits over the camera window stays small and
/// at its edges; the bezel paints outside the window's box.

/// What the camera is up to, for its badge and its window's dressing.
enum CameraState { starting, live, ready, offline }

/// A chunky sticker frame around the camera window, in the cards' ink outline
/// on a lip of [accent]. The frame and its shadow paint outside the child's
/// box, so the window itself keeps its exact size and stays clear.
class CameraBezel extends StatelessWidget {
  const CameraBezel({
    super.key,
    required this.accent,
    required this.child,
    this.radius = 24,
  });
  final Color accent;
  final double radius;
  final Widget child;

  /// How far the frame reaches beyond the window on each side, and the lip
  /// below it.
  static const width = 9.0, lip = 5.0;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _BezelPainter(accent, radius), child: child);
}

class _BezelPainter extends CustomPainter {
  const _BezelPainter(this.accent, this.radius);
  final Color accent;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const w = CameraBezel.width, lip = CameraBezel.lip, outline = 2.5;
    final window = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final outer = window.inflate(w);
    final base = outer.shift(const Offset(0, lip));
    // Nothing lands inside the window: on Android the live camera is a
    // platform view underneath, and any paint here would hide it.
    canvas.save();
    canvas.clipPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(base.outerRect.inflate(20).expandToInclude(outer.outerRect))
        ..addRRect(window),
    );
    canvas.drawRRect(
      base.inflate(outline).shift(const Offset(0, 3)),
      Paint()
        ..color = SkyColors.ink.withValues(alpha: .28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    final ink = Paint()..color = SkyColors.ink;
    canvas.drawRRect(base.inflate(outline), ink);
    canvas.drawRRect(outer.inflate(outline), ink);
    canvas.drawRRect(
      base,
      Paint()..color = Color.lerp(accent, SkyColors.ink, .34)!,
    );
    // The frame is a ring: the window inside stays unpainted so the live
    // camera under it shows through.
    final ring = Path()
      ..fillType = PathFillType.evenOdd
      ..addRRect(outer)
      ..addRRect(window);
    final bounds = outer.outerRect;
    canvas.drawPath(
      ring,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [SkyColors.white, Color.lerp(SkyColors.cream, accent, .3)!],
        ).createShader(bounds),
    );
    canvas.drawRRect(
      outer.deflate(1.4),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [SkyColors.white, SkyColors.white.withValues(alpha: 0)],
          stops: const [0, .4],
        ).createShader(bounds),
    );
    // A fine accent groove halfway round the frame, like a lens barrel.
    canvas.drawRRect(
      window.inflate(w * .5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Color.lerp(accent, SkyColors.ink, .2)!.withValues(alpha: .45),
    );
    canvas.drawRRect(
      window.inflate(1.2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..color = SkyColors.ink,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BezelPainter oldDelegate) =>
      accent != oldDelegate.accent || radius != oldDelegate.radius;
}

/// Viewfinder brackets in the window's corners and a faint vignette, so the
/// camera reads as a framed shot without covering the player.
class ViewfinderCorners extends StatelessWidget {
  const ViewfinderCorners({super.key, required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) =>
      IgnorePointer(child: CustomPaint(painter: _CornersPainter(color)));
}

class _CornersPainter extends CustomPainter {
  const _CornersPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: .85,
          colors: [
            SkyColors.ink.withValues(alpha: 0),
            SkyColors.ink.withValues(alpha: 0),
            SkyColors.ink.withValues(alpha: .16),
          ],
          stops: const [0, .7, 1],
        ).createShader(rect),
    );
    const inset = 16.0, arm = 24.0, bend = 9.0;
    final path = Path();
    for (final (x, y) in [(0, 0), (1, 0), (0, 1), (1, 1)]) {
      final sx = x == 0 ? 1.0 : -1.0, sy = y == 0 ? 1.0 : -1.0;
      final cx = x == 0 ? inset : size.width - inset;
      final cy = y == 0 ? inset : size.height - inset;
      path
        ..moveTo(cx, cy + sy * arm)
        ..lineTo(cx, cy + sy * bend)
        ..quadraticBezierTo(cx, cy, cx + sx * bend, cy)
        ..lineTo(cx + sx * arm, cy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 8
        ..color = SkyColors.ink.withValues(alpha: .85),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 4
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_CornersPainter oldDelegate) => color != oldDelegate.color;
}

/// A sticker tab on the camera's frame: a lamp and a word for what the
/// camera is doing. While it watches, the lamp breathes like a recording
/// light, unless motion is reduced.
class CameraBadge extends StatefulWidget {
  const CameraBadge({super.key, required this.state, this.still = false});
  final CameraState state;

  /// The app's own Reduced Motion setting; the system's is read as well.
  final bool still;

  @override
  State<CameraBadge> createState() => _CameraBadgeState();
}

class _CameraBadgeState extends State<CameraBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void dispose() {
    pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final breathe =
        widget.state == CameraState.live &&
        !widget.still &&
        !MediaQuery.disableAnimationsOf(context);
    if (breathe && !pulse.isAnimating) {
      pulse.repeat(reverse: true);
    } else if (!breathe && pulse.isAnimating) {
      pulse.stop();
      pulse.value = 1;
    } else if (!breathe) {
      pulse.value = 1;
    }
    final (lamp, label) = switch (widget.state) {
      CameraState.starting => (SkyColors.yellow, 'WAKING'),
      CameraState.live => (const Color(0xffff5a4e), 'LIVE'),
      CameraState.ready => (const Color(0xff4fc97f), 'LOCKED ON'),
      CameraState.offline => (const Color(0xff9aa9ae), 'OFFLINE'),
    };
    return MatchPlate(
      color: SkyColors.cream,
      padding: const EdgeInsets.fromLTRB(9, 3, 12, 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: pulse,
            builder: (context, _) => Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: lamp,
                border: Border.all(color: SkyColors.ink, width: 1.8),
                boxShadow: [
                  BoxShadow(
                    color: lamp.withValues(alpha: .7 * pulse.value),
                    blurRadius: 6,
                    spreadRadius: 1.5 * pulse.value,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: matchDigits(12.5).copyWith(letterSpacing: 1.1, height: 1.1),
          ),
        ],
      ),
    );
  }
}

/// The camera warming up: a lens with an iris and a sweeping arc in the
/// middle of the dark window. Reduced motion holds the arc still.
class WakingLens extends StatefulWidget {
  const WakingLens({super.key, required this.accent, this.still = false});
  final Color accent;
  final bool still;

  @override
  State<WakingLens> createState() => _WakingLensState();
}

class _WakingLensState extends State<WakingLens>
    with SingleTickerProviderStateMixin {
  late final AnimationController spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void dispose() {
    spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = widget.still || MediaQuery.disableAnimationsOf(context);
    if (still) {
      spin
        ..stop()
        ..value = .15;
    } else if (!spin.isAnimating) {
      spin.repeat();
    }
    return IgnorePointer(
      child: SizedBox.square(
        dimension: 132,
        child: AnimatedBuilder(
          animation: spin,
          builder: (context, _) =>
              CustomPaint(painter: _LensPainter(widget.accent, spin.value)),
        ),
      ),
    );
  }
}

class _LensPainter extends CustomPainter {
  const _LensPainter(this.accent, this.turn);
  final Color accent;
  final double turn;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.drawCircle(
      c,
      r - 4,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..color = SkyColors.cream.withValues(alpha: .14),
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r - 4),
      turn * math.pi * 2 - math.pi / 2,
      math.pi * 1.25,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 7
        ..color = accent,
    );
    // The lens: an ink-rimmed barrel, a dark glass and an iris of blades
    // that turn the other way.
    final barrel = r * .62;
    canvas.drawCircle(c, barrel + 3, Paint()..color = SkyColors.ink);
    canvas.drawCircle(c, barrel, Paint()..color = SkyColors.cream);
    canvas.drawCircle(c, barrel * .78, Paint()..color = SkyColors.ink);
    final glass = barrel * .7;
    canvas.drawCircle(
      c,
      glass,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.3, -.4),
          colors: [const Color(0xff4b7280), SkyColors.night],
        ).createShader(Rect.fromCircle(center: c, radius: glass)),
    );
    final blade = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = SkyColors.cream.withValues(alpha: .35);
    for (var i = 0; i < 6; i++) {
      final a = -turn * math.pi + i * math.pi / 3;
      final from = c + Offset(math.cos(a), math.sin(a)) * glass * .92;
      final to = c + Offset(math.cos(a + 2.1), math.sin(a + 2.1)) * glass * .32;
      canvas.drawLine(from, to, blade);
    }
    canvas.drawCircle(
      c + Offset(-glass * .35, -glass * .38),
      glass * .16,
      Paint()..color = SkyColors.white.withValues(alpha: .8),
    );
    canvas.drawCircle(
      c + Offset(glass * .3, glass * .34),
      glass * .07,
      Paint()..color = SkyColors.white.withValues(alpha: .5),
    );
  }

  @override
  bool shouldRepaint(_LensPainter oldDelegate) =>
      turn != oldDelegate.turn || accent != oldDelegate.accent;
}

/// A dozing camera for when it will not start: a friendly face rather than
/// a warning sign, since the fix is usually a tap away.
class SleepyCamera extends StatelessWidget {
  const SleepyCamera({super.key, this.size = 120, this.accent});
  final double size;
  final Color? accent;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: SizedBox(
      width: size,
      height: size * .84,
      child: CustomPaint(painter: _SleepyPainter(accent ?? SkyColors.coral)),
    ),
  );
}

class _SleepyPainter extends CustomPainter {
  const _SleepyPainter(this.accent);
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 120;
    final ink = Paint()..color = SkyColors.ink;
    final body = RRect.fromLTRBR(
      8 * u,
      30 * u,
      100 * u,
      94 * u,
      Radius.circular(18 * u),
    );
    final hump = RRect.fromLTRBR(
      30 * u,
      20 * u,
      62 * u,
      40 * u,
      Radius.circular(8 * u),
    );
    final lip = body.shift(Offset(0, 5 * u));
    canvas.drawRRect(lip.inflate(3 * u), ink);
    canvas.drawRRect(hump.inflate(3 * u), ink);
    canvas.drawRRect(body.inflate(3 * u), ink);
    canvas.drawRRect(
      lip,
      Paint()..color = Color.lerp(accent, SkyColors.ink, .34)!,
    );
    canvas.drawRRect(hump, Paint()..color = SkyColors.cream);
    canvas.drawRRect(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(accent, SkyColors.white, .55)!, accent],
        ).createShader(body.outerRect),
    );
    canvas.drawRRect(
      body.deflate(1.4 * u),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6 * u
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [SkyColors.white, SkyColors.white.withValues(alpha: 0)],
          stops: const [0, .45],
        ).createShader(body.outerRect),
    );
    // The flash, a little cream window.
    canvas.drawRRect(
      RRect.fromLTRBR(76 * u, 38 * u, 92 * u, 48 * u, Radius.circular(3 * u)),
      Paint()..color = SkyColors.cream,
    );
    final lens = Offset(52 * u, 64 * u);
    canvas.drawCircle(lens, 23 * u, ink);
    canvas.drawCircle(lens, 20 * u, Paint()..color = SkyColors.cream);
    canvas.drawCircle(lens, 14 * u, Paint()..color = const Color(0xff3c5f6b));
    // A closed, contented eye in the lens.
    final lid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3 * u
      ..color = SkyColors.cream;
    canvas.drawArc(
      Rect.fromCircle(center: lens + Offset(0, -3 * u), radius: 7 * u),
      .35,
      math.pi - .7,
      false,
      lid,
    );
    canvas.drawCircle(
      lens + Offset(6 * u, -8 * u),
      2.4 * u,
      Paint()..color = SkyColors.white.withValues(alpha: .7),
    );
    canvas.drawCircle(
      Offset(22 * u, 74 * u),
      5 * u,
      Paint()..color = SkyColors.white.withValues(alpha: .45),
    );
    // Z z z, drifting up and away.
    for (final (x, y, s) in [(102.0, 22.0, 28.0), (118.0, 2.0, 20.0)]) {
      final text = TextPainter(
        text: TextSpan(
          text: 'z',
          style: heading(
            s * u,
            color: SkyColors.cream,
            weight: FontWeight.w700,
          ).copyWith(shadows: matchInkEdge(1.2 * u)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, Offset(x * u, y * u) - text.size.center(Offset.zero));
      text.dispose();
    }
  }

  @override
  bool shouldRepaint(_SleepyPainter oldDelegate) =>
      accent != oldDelegate.accent;
}

/// The coach's note along the bottom of the camera window: an ink plate with
/// a colored coin for its icon.
class CalibrationNote extends StatelessWidget {
  const CalibrationNote({
    super.key,
    required this.text,
    required this.icon,
    required this.accent,
  });
  final String text;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
    decoration: BoxDecoration(
      color: SkyColors.ink.withValues(alpha: .92),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: SkyColors.cream.withValues(alpha: .45),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: SkyColors.night.withValues(alpha: .3),
          offset: const Offset(0, 3),
          blurRadius: 6,
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent,
            border: Border.all(color: SkyColors.cream, width: 2),
          ),
          child: Icon(icon, size: 19, color: SkyColors.ink),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: bodyText(
              17,
              color: SkyColors.white,
              weight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

/// A step's title after a numbered coin, or a check once calibration is done.
class CalibrationStepTitle extends StatelessWidget {
  const CalibrationStepTitle({
    super.key,
    required this.title,
    required this.step,
    required this.accent,
    this.done = false,
  });
  final String title;

  /// The step's number, from 1.
  final int step;
  final Color accent;
  final bool done;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: done ? SkyColors.mint : accent,
          shape: BoxShape.circle,
          border: Border.all(color: SkyColors.ink, width: 2),
          boxShadow: const [
            BoxShadow(color: SkyColors.ink, offset: Offset(0, 2.5)),
          ],
        ),
        child: done
            ? const Icon(Icons.check_rounded, size: 20, color: SkyColors.ink)
            : Text(
                '$step',
                style: heading(17, weight: FontWeight.w700).copyWith(height: 1),
              ),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            maxLines: 1,
            style: heading(
              25,
              color: SkyColors.cream,
              weight: FontWeight.w700,
            ).copyWith(letterSpacing: .3, shadows: matchInkEdge(1.4)),
          ),
        ),
      ),
    ],
  );
}

/// How far calibration has come: a chunky track in the HUD material, split
/// into [segments] with notches, that fills with [color]. The fill eases to
/// a new value unless motion is reduced.
class CalibrationMeter extends StatelessWidget {
  const CalibrationMeter({
    super.key,
    required this.value,
    required this.segments,
    required this.color,
    this.still = false,
  });
  final double value;
  final int segments;
  final Color color;
  final bool still;

  @override
  Widget build(BuildContext context) {
    final reduced = still || MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      height: 22,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value.clamp(0.0, 1.0)),
        duration: reduced ? Duration.zero : const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => CustomPaint(
          size: const Size(double.infinity, 22),
          painter: _MeterPainter(v, segments, color),
        ),
      ),
    );
  }
}

class _MeterPainter extends CustomPainter {
  const _MeterPainter(this.value, this.segments, this.color);
  final double value;
  final int segments;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const lip = 3.0, outline = 2.5;
    final h = size.height - lip;
    final face = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, h),
      Radius.circular(h / 2),
    );
    final base = face.shift(const Offset(0, lip));
    final ink = Paint()..color = SkyColors.ink;
    canvas.drawRRect(base.inflate(outline), ink);
    canvas.drawRRect(face.inflate(outline), ink);
    canvas.drawRRect(base, Paint()..color = const Color(0xffcfc0a4));
    canvas.drawRRect(face, Paint()..color = const Color(0xffeee3cd));
    // An inner shadow along the groove's top edge.
    canvas.save();
    canvas.clipRRect(face);
    canvas.drawRRect(
      face.shift(const Offset(0, 3)).inflate(2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = SkyColors.ink.withValues(alpha: .14),
    );
    if (value > 0) {
      final fill = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, math.max(h, size.width * value), h),
        Radius.circular(h / 2),
      );
      canvas.drawRRect(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.lerp(color, SkyColors.white, .45)!, color],
            stops: const [0, .6],
          ).createShader(fill.outerRect),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(h * .35, 2.5, fill.width - h * .7, h * .26),
          Radius.circular(h),
        ),
        Paint()..color = SkyColors.white.withValues(alpha: .55),
      );
    }
    canvas.restore();
    final notch = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = SkyColors.ink.withValues(alpha: .4);
    for (var i = 1; i < segments; i++) {
      final x = size.width * i / segments;
      canvas.drawLine(Offset(x, 4), Offset(x, h - 4), notch);
    }
  }

  @override
  bool shouldRepaint(_MeterPainter oldDelegate) =>
      value != oldDelegate.value ||
      segments != oldDelegate.segments ||
      color != oldDelegate.color;
}

/// A little sky where the bird follows the player: it rises and falls with
/// [height] (0 at the ground, 1 at the top), casting a shadow that shrinks as
/// it climbs, beside an altitude rail that fills to match. The bird glides to
/// each new height unless motion is reduced.
class CalibrationPreview extends StatelessWidget {
  const CalibrationPreview({
    super.key,
    required this.bird,
    required this.height,
    required this.color,
    this.caption,
    this.still = false,
  });
  final int bird;
  final double height;
  final Color color;
  final String? caption;
  final bool still;

  @override
  Widget build(BuildContext context) {
    final reduced = still || MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: height),
      duration: reduced ? Duration.zero : const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      builder: (context, h, _) => LayoutBuilder(
        builder: (context, box) {
          final size = math.min(84.0, box.maxHeight * .62);
          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _SkyPainter(color, h)),
              // The bird's lowest perch stays clear of the caption.
              Positioned.fill(
                bottom: caption == null ? 8 : 22,
                child: Align(
                  alignment: Alignment(-.45, .8 - h * 1.6),
                  child: BirdArt(bird: bird, size: size, bob: false),
                ),
              ),
              if (caption != null)
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 6,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(10, 3, 10, 3),
                      decoration: BoxDecoration(
                        color: SkyColors.cream.withValues(alpha: .88),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        caption!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: bodyText(12, color: SkyColors.muted),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SkyPainter extends CustomPainter {
  const _SkyPainter(this.color, this.height);
  final Color color;
  final double height;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(SkyColors.sky, SkyColors.white, .25)!,
            Color.lerp(color, SkyColors.cream, .62)!,
          ],
        ).createShader(rect),
    );
    final cloud = Paint()..color = SkyColors.white.withValues(alpha: .85);
    for (final (x, y, s) in [(.14, .2, 1.0), (.58, .12, .8), (.9, .42, .6)]) {
      final c = Offset(w * x, h * y);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: 44 * s, height: 13 * s),
          Radius.circular(8 * s),
        ),
        cloud,
      );
      canvas.drawCircle(c + Offset(-5 * s, -6 * s), 8 * s, cloud);
      canvas.drawCircle(c + Offset(7 * s, -4 * s), 6 * s, cloud);
    }
    final spark = Paint()..color = SkyColors.white;
    for (final (x, y, r) in [(.36, .3, 3.5), (.06, .55, 2.5), (.5, .5, 2.0)]) {
      final c = Offset(w * x, h * y);
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy - r * 1.6)
          ..quadraticBezierTo(c.dx, c.dy, c.dx + r * 1.6, c.dy)
          ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r * 1.6)
          ..quadraticBezierTo(c.dx, c.dy, c.dx - r * 1.6, c.dy)
          ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r * 1.6),
        spark,
      );
    }
    // Rolling ground, and the bird's shadow on it, small when it is high.
    final ground = h - 14;
    canvas.drawPath(
      Path()
        ..moveTo(0, ground + 2)
        ..quadraticBezierTo(w * .3, ground - 8, w * .62, ground)
        ..quadraticBezierTo(w * .85, ground + 6, w, ground - 3)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      Paint()..color = Color.lerp(color, SkyColors.cream, .35)!,
    );
    // Under the bird, which sits at Alignment(-.45, ...) in the band.
    final bx = w * .275 + 18;
    final shade = 1 - height.clamp(0.0, 1.0) * .6;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(bx, ground - 1),
        width: 46 * shade,
        height: 8 * shade,
      ),
      Paint()..color = SkyColors.ink.withValues(alpha: .18 * shade),
    );
    // The altitude rail on the right.
    final top = 16.0, bottom = ground - 12;
    if (bottom - top < 24) return;
    final x = w - 26;
    final rail = RRect.fromLTRBR(
      x - 5,
      top,
      x + 5,
      bottom,
      const Radius.circular(5),
    );
    canvas.drawRRect(rail.inflate(2), Paint()..color = SkyColors.ink);
    canvas.drawRRect(rail, Paint()..color = SkyColors.cream);
    final y = bottom - (bottom - top) * height.clamp(0.0, 1.0);
    canvas.drawRRect(
      RRect.fromLTRBR(x - 5, y, x + 5, bottom, const Radius.circular(5)),
      Paint()..color = color,
    );
    final chevron = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = SkyColors.ink.withValues(alpha: .55);
    canvas.drawPath(
      Path()
        ..moveTo(x - 13, top + 8)
        ..lineTo(x - 18.5, top + 2)
        ..lineTo(x - 24, top + 8),
      chevron,
    );
    canvas.drawPath(
      Path()
        ..moveTo(x - 13, bottom - 8)
        ..lineTo(x - 18.5, bottom - 2)
        ..lineTo(x - 24, bottom - 8),
      chevron,
    );
    canvas.drawCircle(Offset(x, y), 9, Paint()..color = SkyColors.ink);
    canvas.drawCircle(Offset(x, y), 6.5, Paint()..color = SkyColors.white);
    canvas.drawCircle(Offset(x, y), 3.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SkyPainter oldDelegate) =>
      color != oldDelegate.color || height != oldDelegate.height;
}

/// One thing to check when the camera will not start, after a small coin.
class CalibrationTip extends StatelessWidget {
  const CalibrationTip({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: SkyColors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: SkyColors.ink.withValues(alpha: .7),
            width: 1.8,
          ),
        ),
        child: Icon(icon, size: 17, color: SkyColors.coralDeep),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(text, style: bodyText(14, color: SkyColors.muted)),
      ),
    ],
  );
}

/// The tracker's speed, set small and quiet under the main key: useful when
/// something feels slow, never something to read first.
class CalibrationMetrics extends StatelessWidget {
  const CalibrationMetrics(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = SkyColors.muted.withValues(alpha: .7);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.speed_rounded, size: 12, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: bodyText(10.5, color: color, weight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
