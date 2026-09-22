import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'theme.dart';

enum MatchSymbol {
  star,
  heart,
  shield,
  magnet,
  shot,
  pause,
  stop,
  letter,
  wing,
}

/// Small illustrated symbols share the world's rounded outlines and highlights.
class MatchIcon extends StatelessWidget {
  const MatchIcon(this.symbol, {super.key, this.size = 32, this.muted = false});
  final MatchSymbol symbol;
  final double size;
  final bool muted;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _MatchIconPainter(symbol, muted)),
  );
}

class _MatchIconPainter extends CustomPainter {
  const _MatchIconPainter(this.symbol, this.muted);
  final MatchSymbol symbol;
  final bool muted;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 32, size.height / 32);
    final outline = Paint()
      ..color = muted ? SkyColors.muted.withValues(alpha: .35) : SkyColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    void shape(Path path, Color color) {
      canvas.drawPath(path, Paint()..color = muted ? SkyColors.sky : color);
      canvas.drawPath(path, outline);
    }

    void line(Path path, {Color? color, double width = 2}) => canvas.drawPath(
      path,
      Paint()
        ..color = color ?? outline.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    switch (symbol) {
      case MatchSymbol.star:
        final path = Path();
        for (var i = 0; i < 10; i++) {
          final angle = -math.pi / 2 + i * math.pi / 5;
          final radius = i.isEven ? 13.0 : 6.4;
          final x = 16 + math.cos(angle) * radius;
          final y = 16 + math.sin(angle) * radius;
          i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
        }
        shape(path..close(), SkyColors.yellow);
        line(
          Path()
            ..moveTo(12, 13)
            ..lineTo(15, 8),
          color: SkyColors.cream,
        );
      case MatchSymbol.heart:
        shape(
          Path()
            ..moveTo(16, 28)
            ..cubicTo(11, 24, 3, 18, 3, 11)
            ..cubicTo(3, 3, 12, 2, 16, 9)
            ..cubicTo(20, 2, 29, 3, 29, 11)
            ..cubicTo(29, 18, 21, 24, 16, 28)
            ..close(),
          SkyColors.coral,
        );
        if (!muted) {
          line(
            Path()
              ..moveTo(7, 12)
              ..quadraticBezierTo(7, 7, 11, 8),
            color: SkyColors.cream,
            width: 2.4,
          );
        }
      case MatchSymbol.shield:
        shape(
          Path()
            ..moveTo(16, 3)
            ..quadraticBezierTo(22, 7, 28, 7)
            ..lineTo(26, 19)
            ..quadraticBezierTo(23, 27, 16, 30)
            ..quadraticBezierTo(9, 27, 6, 19)
            ..lineTo(4, 7)
            ..quadraticBezierTo(10, 7, 16, 3)
            ..close(),
          SkyColors.mint,
        );
        line(
          Path()
            ..moveTo(16, 8)
            ..lineTo(16, 24),
          color: muted ? outline.color : SkyColors.white,
          width: 3,
        );
        line(
          Path()
            ..moveTo(10, 15)
            ..lineTo(22, 15),
          color: muted ? outline.color : SkyColors.white,
          width: 3,
        );
      case MatchSymbol.magnet:
        shape(
          Path()
            ..moveTo(4, 5)
            ..lineTo(12, 5)
            ..lineTo(12, 18)
            ..cubicTo(12, 24, 20, 24, 20, 18)
            ..lineTo(20, 5)
            ..lineTo(28, 5)
            ..lineTo(28, 19)
            ..cubicTo(28, 35, 4, 35, 4, 19)
            ..close(),
          SkyColors.lavender,
        );
        line(
          Path()
            ..moveTo(5, 11)
            ..lineTo(11, 11)
            ..moveTo(21, 11)
            ..lineTo(27, 11),
          color: SkyColors.white,
          width: 3,
        );
      case MatchSymbol.shot:
        line(
          Path()
            ..moveTo(2, 18)
            ..lineTo(11, 15)
            ..moveTo(5, 26)
            ..lineTo(14, 21),
          color: SkyColors.cream,
          width: 2.8,
        );
        shape(
          Path()
            ..moveTo(12, 12)
            ..lineTo(20, 7)
            ..lineTo(28, 11)
            ..lineTo(29, 19)
            ..lineTo(22, 25)
            ..lineTo(14, 23)
            ..close(),
          SkyColors.cream,
        );
        line(
          Path()
            ..moveTo(16, 14)
            ..lineTo(21, 11)
            ..lineTo(25, 13),
          color: SkyColors.sand,
          width: 2.2,
        );
        line(
          Path()
            ..moveTo(25, 2)
            ..lineTo(25, 5)
            ..moveTo(29, 5)
            ..lineTo(31, 4),
          color: SkyColors.cream,
          width: 1.6,
        );
      case MatchSymbol.pause:
        for (final x in [7.0, 20.0]) {
          shape(
            Path()..addRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTWH(x, 6, 6, 20),
                const Radius.circular(2),
              ),
            ),
            SkyColors.ink,
          );
        }
      case MatchSymbol.stop:
        shape(
          Path()..addRRect(
            RRect.fromRectAndRadius(
              const Rect.fromLTWH(7, 7, 18, 18),
              const Radius.circular(4),
            ),
          ),
          SkyColors.ink,
        );
      case MatchSymbol.letter:
        shape(
          Path()..addRRect(
            RRect.fromRectAndRadius(
              const Rect.fromLTWH(2, 6, 28, 21),
              const Radius.circular(4),
            ),
          ),
          SkyColors.yellow,
        );
        line(
          Path()
            ..moveTo(4, 9)
            ..lineTo(16, 18)
            ..lineTo(28, 9),
        );
        line(
          Path()
            ..moveTo(5, 24)
            ..lineTo(11, 18)
            ..moveTo(21, 18)
            ..lineTo(27, 24),
          color: SkyColors.gold,
        );
      case MatchSymbol.wing:
        shape(
          Path()
            ..moveTo(5, 25)
            ..quadraticBezierTo(3, 14, 11, 9)
            ..lineTo(29, 3)
            ..quadraticBezierTo(28, 12, 20, 15)
            ..lineTo(25, 14)
            ..quadraticBezierTo(22, 22, 14, 22)
            ..lineTo(18, 23)
            ..quadraticBezierTo(10, 30, 5, 25)
            ..close(),
          SkyColors.mint,
        );
        line(
          Path()
            ..moveTo(8, 23)
            ..quadraticBezierTo(12, 17, 21, 11),
          color: SkyColors.white,
        );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MatchIconPainter oldDelegate) =>
      symbol != oldDelegate.symbol || muted != oldDelegate.muted;
}

class MatchPlate extends StatelessWidget {
  const MatchPlate({
    super.key,
    required this.child,
    this.color = SkyColors.cream,
  });
  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .94),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: SkyColors.white.withValues(alpha: .85),
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: SkyColors.ink.withValues(alpha: .12),
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );
}

/// A finite pop on a meaningful state change, never a looping HUD animation.
class MatchPulse extends StatefulWidget {
  const MatchPulse({
    super.key,
    required this.value,
    required this.reducedMotion,
    required this.child,
  });
  final Object value;
  final bool reducedMotion;
  final Widget child;

  @override
  State<MatchPulse> createState() => _MatchPulseState();
}

class _MatchPulseState extends State<MatchPulse>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 1.12,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.12,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 65,
    ),
  ]).animate(_controller);
  bool _disabled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _disabled = MediaQuery.disableAnimationsOf(context);
    if (_disabled || widget.reducedMotion) _controller.reset();
  }

  @override
  void didUpdateWidget(MatchPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_disabled || widget.reducedMotion) {
      _controller.reset();
    } else if (oldWidget.value != widget.value) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _scale, child: widget.child);
}

class MatchMeter extends StatelessWidget {
  const MatchMeter({
    super.key,
    required this.symbol,
    required this.value,
    required this.label,
    this.text,
    this.active = true,
    this.color = SkyColors.teal,
  });
  final MatchSymbol symbol;
  final double value;
  final String label;
  final String? text;
  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    excludeSemantics: true,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: 44,
          child: CustomPaint(
            painter: _MeterRing(value, color),
            child: Center(child: MatchIcon(symbol, size: 27, muted: !active)),
          ),
        ),
        if (text != null) ...[
          const SizedBox(width: 6),
          Text(text!, style: heading(21)),
        ],
      ],
    ),
  );
}

class MatchHealth extends StatelessWidget {
  const MatchHealth({
    super.key,
    required this.hearts,
    required this.shield,
    required this.charge,
    required this.recovering,
    required this.reducedMotion,
  });
  final int hearts, charge;
  final bool shield, recovering, reducedMotion;

  @override
  Widget build(BuildContext context) => MatchPlate(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: '$hearts hearts remaining',
          excludeSemantics: true,
          child: MatchPulse(
            value: hearts,
            reducedMotion: reducedMotion,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hearts > 3) ...[
                  const MatchIcon(MatchSymbol.heart),
                  const SizedBox(width: 4),
                  Text(
                    '×$hearts',
                    style: heading(24, color: SkyColors.coralDeep),
                  ),
                ] else
                  for (var i = 0; i < 3; i++)
                    MatchIcon(MatchSymbol.heart, size: 28, muted: i >= hearts),
              ],
            ),
          ),
        ),
        Container(
          width: 1,
          height: 24,
          margin: const EdgeInsets.symmetric(horizontal: 9),
          color: SkyColors.ink.withValues(alpha: .12),
        ),
        MatchPulse(
          value: (shield, recovering),
          reducedMotion: reducedMotion,
          child: MatchMeter(
            key: const ValueKey('match-shield'),
            symbol: MatchSymbol.shield,
            value: shield || recovering ? 1 : charge / 9,
            active: shield || recovering,
            color: recovering ? SkyColors.gold : SkyColors.teal,
            label: recovering
                ? 'Recovering'
                : shield
                ? 'Shield ready'
                : 'Shield charging: $charge of 9 stars',
          ),
        ),
      ],
    ),
  );
}

/// An opaque hit target also consumes taps while the projectile is recharging.
class MatchAction extends StatefulWidget {
  const MatchAction({
    super.key,
    required this.symbol,
    required this.label,
    required this.onPressed,
    required this.reducedMotion,
    this.cooldown,
    this.size = 72,
  });
  final MatchSymbol symbol;
  final String label;
  final VoidCallback? onPressed;
  final bool reducedMotion;
  final double? cooldown;
  final double size;

  @override
  State<MatchAction> createState() => _MatchActionState();
}

class _MatchActionState extends State<MatchAction> {
  bool _pressed = false;
  bool _focused = false;

  @override
  void didUpdateWidget(MatchAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onPressed == null) _pressed = false;
  }

  @override
  Widget build(BuildContext context) {
    final shoot = widget.symbol == MatchSymbol.shot;
    final disabled =
        widget.reducedMotion || MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      enabled: widget.onPressed != null,
      label: widget.label,
      value: shoot ? (widget.onPressed == null ? 'Recharging' : 'Ready') : null,
      onTap: widget.onPressed,
      excludeSemantics: true,
      child: Tooltip(
        message: widget.label,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: widget.onPressed,
              onFocusChange: (value) => setState(() => _focused = value),
              onHighlightChanged: (value) {
                // Disabled InkWells can clear their highlight during build.
                if (widget.onPressed == null || _pressed == value) return;
                setState(() => _pressed = value);
              },
              child: AnimatedContainer(
                duration: disabled
                    ? Duration.zero
                    : const Duration(milliseconds: 100),
                width: widget.size,
                height: widget.size,
                transformAlignment: Alignment.center,
                transform: Matrix4.diagonal3Values(
                  _pressed && !disabled ? .92 : 1,
                  _pressed && !disabled ? .92 : 1,
                  1,
                ),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: shoot
                        ? [SkyColors.coral, SkyColors.coralDeep]
                        : [SkyColors.white, SkyColors.cream],
                  ),
                  border: Border.all(
                    color: _focused
                        ? SkyColors.gold
                        : SkyColors.white.withValues(alpha: .9),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (shoot ? SkyColors.coralDeep : SkyColors.ink)
                          .withValues(alpha: .22),
                      offset: Offset(0, _pressed ? 1 : 4),
                      blurRadius: shoot ? 12 : 0,
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: widget.cooldown == null
                      ? null
                      : _MeterRing(widget.cooldown!, SkyColors.cream, inset: 7),
                  child: Center(
                    child: MatchIcon(widget.symbol, size: shoot ? 46 : 30),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MeterRing extends CustomPainter {
  const _MeterRing(this.value, this.color, {this.inset = 2});
  final double value, inset;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = (Offset.zero & size).deflate(inset);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawOval(bounds, paint..color = color.withValues(alpha: .18));
    if (value > 0) {
      canvas.drawArc(
        bounds,
        -math.pi / 2,
        math.pi * 2 * value.clamp(0, 1),
        false,
        paint..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_MeterRing oldDelegate) =>
      value != oldDelegate.value ||
      color != oldDelegate.color ||
      inset != oldDelegate.inset;
}
