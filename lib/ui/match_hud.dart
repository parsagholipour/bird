import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../domain/power_shot.dart';
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
  sprint,
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
      case MatchSymbol.sprint:
        line(
          Path()
            ..moveTo(1, 11)
            ..lineTo(7, 11)
            ..moveTo(2, 16)
            ..lineTo(11, 16)
            ..moveTo(1, 21)
            ..lineTo(7, 21),
          color: muted ? outline.color : SkyColors.cream,
          width: 2.4,
        );
        for (final (x, color) in [
          (8.0, SkyColors.cream),
          (16.0, SkyColors.yellow),
        ]) {
          shape(
            Path()
              ..moveTo(x, 6)
              ..lineTo(x + 6, 6)
              ..lineTo(x + 14, 16)
              ..lineTo(x + 6, 26)
              ..lineTo(x, 26)
              ..lineTo(x + 8, 16)
              ..close(),
            color,
          );
        }
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

class MatchAction extends StatefulWidget {
  const MatchAction({
    super.key,
    required this.symbol,
    required this.label,
    required this.onPressed,
    required this.reducedMotion,
    this.size = 72,
  });
  final MatchSymbol symbol;
  final String label;
  final VoidCallback? onPressed;
  final bool reducedMotion;
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
    final disabled =
        widget.reducedMotion || MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      enabled: widget.onPressed != null,
      label: widget.label,
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
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [SkyColors.white, SkyColors.cream],
                  ),
                  border: Border.all(
                    color: _focused
                        ? SkyColors.gold
                        : SkyColors.white.withValues(alpha: .9),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: SkyColors.ink.withValues(alpha: .22),
                      offset: Offset(0, _pressed ? 1 : 4),
                    ),
                  ],
                ),
                child: Center(child: MatchIcon(widget.symbol, size: 30)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tap to sprint. While the burst lasts its ring drains; afterwards the ring
/// refills over the cooldown under a seconds countdown. The opaque target
/// consumes touches while recharging, so a press never flaps the bird.
class MatchSprintButton extends StatefulWidget {
  const MatchSprintButton({
    super.key,
    required this.label,
    required this.recharge,
    required this.burst,
    required this.secondsLeft,
    required this.onPressed,
    required this.reducedMotion,
    this.size = 80,
  });
  final String label;

  /// Each from 0 to 1: progress toward the next sprint, and the share of the
  /// current burst still to come.
  final double recharge, burst;
  final int secondsLeft;
  final VoidCallback? onPressed;
  final bool reducedMotion;
  final double size;

  @override
  State<MatchSprintButton> createState() => _MatchSprintButtonState();
}

class _MatchSprintButtonState extends State<MatchSprintButton> {
  bool _pressed = false, _focused = false;

  @override
  void didUpdateWidget(MatchSprintButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onPressed == null) _pressed = false;
  }

  @override
  Widget build(BuildContext context) {
    final still =
        widget.reducedMotion || MediaQuery.disableAnimationsOf(context);
    final sprinting = widget.burst > 0;
    final ready = !sprinting && widget.secondsLeft == 0;
    final scale = _pressed && !still ? .92 : 1.0;
    return Semantics(
      button: true,
      enabled: widget.onPressed != null,
      label: widget.label,
      value: sprinting
          ? 'Sprinting'
          : ready
          ? 'Ready'
          : 'Recharging, ${widget.secondsLeft} seconds',
      hint: 'Rush ahead to smash bats and stone panels',
      onTap: widget.onPressed,
      excludeSemantics: true,
      child: Tooltip(
        message: widget.label,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          child: MatchPulse(
            value: ready,
            reducedMotion: widget.reducedMotion,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: widget.onPressed,
                onFocusChange: (value) => setState(() => _focused = value),
                onHighlightChanged: (value) {
                  if (widget.onPressed == null || _pressed == value) return;
                  setState(() => _pressed = value);
                },
                child: AnimatedContainer(
                  duration: still
                      ? Duration.zero
                      : const Duration(milliseconds: 100),
                  width: widget.size,
                  height: widget.size,
                  transformAlignment: Alignment.center,
                  transform: Matrix4.diagonal3Values(scale, scale, 1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: sprinting
                          ? const [SkyColors.yellow, SkyColors.gold]
                          : ready
                          ? const [SkyColors.mint, SkyColors.teal]
                          : const [SkyColors.white, SkyColors.cream],
                    ),
                    border: Border.all(
                      color: _focused
                          ? SkyColors.ink
                          : SkyColors.white.withValues(alpha: .9),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: SkyColors.ink.withValues(alpha: .22),
                        offset: Offset(0, _pressed ? 1 : 4),
                        blurRadius: ready ? 10 : 0,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: CustomPaint(
                      painter: _MeterRing(
                        sprinting ? widget.burst : widget.recharge,
                        sprinting
                            ? SkyColors.white
                            : ready
                            ? SkyColors.cream
                            : SkyColors.teal,
                      ),
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            MatchIcon(
                              MatchSymbol.sprint,
                              size: 40,
                              muted: !ready && !sprinting,
                            ),
                            if (!ready && !sprinting)
                              Text('${widget.secondsLeft}', style: heading(26)),
                          ],
                        ),
                      ),
                    ),
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

/// Hold to charge a power shot, release to fire. The outer ring is the ammo
/// reserve; while charging, its yellow tail is the share the release will
/// spend, matching the inner charge ring. Once the shot is full, that inner
/// ring counts down the 500 ms it can stay held. The opaque target
/// consumes every touch, so a press during a cooldown or refill never flaps
/// the bird.
class MatchShotButton extends StatefulWidget {
  const MatchShotButton({
    super.key,
    required this.label,
    required this.reserve,
    required this.charge,
    required this.spend,
    required this.charging,
    required this.empty,
    required this.onPress,
    required this.onRelease,
    required this.reducedMotion,
    this.hold = 1,
    this.size = 100,
  });
  final String label;

  /// Each from 0 to 1: remaining reserve, held charge and the reserve share
  /// the release would spend. [hold] is the share of the full-charge window
  /// still left; it stays at 1 until the shot is full.
  final double reserve, charge, spend, hold;
  final bool charging, empty;
  final VoidCallback? onPress;
  final VoidCallback onRelease;
  final bool reducedMotion;
  final double size;

  @override
  State<MatchShotButton> createState() => _MatchShotButtonState();
}

class _MatchShotButtonState extends State<MatchShotButton> {
  static final _activators = {
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
  };
  int? _pointer;
  bool _keyHeld = false, _focused = false;
  bool get _held => _pointer != null || _keyHeld;

  void _down(PointerDownEvent event) {
    if (_held || widget.onPress == null) return;
    setState(() => _pointer = event.pointer);
    widget.onPress!();
  }

  // A cancelled touch still releases, so a charge never outlives its finger.
  void _up(PointerEvent event) {
    if (event.pointer != _pointer) return;
    setState(() => _pointer = null);
    widget.onRelease();
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (!_activators.contains(event.logicalKey)) return KeyEventResult.ignored;
    if (event is KeyDownEvent && !_held && widget.onPress != null) {
      setState(() => _keyHeld = true);
      widget.onPress!();
    } else if (event is KeyUpEvent && _keyHeld) {
      setState(() => _keyHeld = false);
      widget.onRelease();
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final still =
        widget.reducedMotion || MediaQuery.disableAnimationsOf(context);
    final enabled = widget.onPress != null;
    final showingCharge = widget.charging && !widget.empty;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      value: widget.empty
          ? 'Reloading…'
          : showingCharge
          ? widget.charge >= 1
                ? 'Full charge, ${(widget.hold * PowerShot.maxFullHoldSeconds * 1000).round()} ms left'
                : 'Charging ${(widget.charge * 100).round()}%'
          : 'Ammo ${(widget.reserve * 100).round()}%',
      hint: 'Hold to charge a bigger rock',
      focusable: enabled,
      focused: _focused,
      onTap: enabled
          ? () {
              widget.onPress!();
              widget.onRelease();
            }
          : null,
      excludeSemantics: true,
      child: Focus(
        canRequestFocus: enabled,
        includeSemantics: false,
        onFocusChange: (value) => setState(() => _focused = value),
        onKeyEvent: _key,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _down,
          onPointerUp: _up,
          onPointerCancel: _up,
          child: AnimatedScale(
            duration: still ? Duration.zero : const Duration(milliseconds: 100),
            scale: _held && !still ? .94 : 1,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(
                      SkyColors.coral,
                      SkyColors.gold,
                      widget.charge * .5,
                    )!,
                    SkyColors.coralDeep,
                  ],
                ),
                border: Border.all(
                  color: _focused
                      ? SkyColors.gold
                      : SkyColors.white.withValues(alpha: .9),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: SkyColors.coralDeep.withValues(alpha: .22),
                    offset: Offset(0, _held ? 1 : 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: CustomPaint(
                painter: _ShotMeter(
                  reserve: widget.reserve,
                  spend: widget.spend,
                  charge: widget.charge,
                  hold: widget.hold,
                  charging: showingCharge,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: still ? 1 : 1 + widget.charge * .2,
                        child: MatchIcon(
                          MatchSymbol.shot,
                          size: widget.empty ? 32 : 46,
                          muted: widget.empty,
                        ),
                      ),
                      if (widget.empty) ...[
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Reloading…',
                              style: heading(12, color: SkyColors.white),
                            ),
                          ),
                        ),
                      ],
                    ],
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

class _ShotMeter extends CustomPainter {
  const _ShotMeter({
    required this.reserve,
    required this.spend,
    required this.charge,
    required this.hold,
    required this.charging,
  });
  final double reserve, spend, charge, hold;
  final bool charging;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    void arc(Rect bounds, double from, double to, Color color) {
      if (to <= from) return;
      canvas.drawArc(
        bounds,
        -math.pi / 2 + math.pi * 2 * from,
        math.pi * 2 * (to - from),
        false,
        paint..color = color,
      );
    }

    final outer = (Offset.zero & size).deflate(7);
    final left = reserve.clamp(0.0, 1.0);
    final kept = (left - spend).clamp(0.0, left);
    canvas.drawOval(
      outer,
      paint..color = SkyColors.cream.withValues(alpha: .2),
    );
    arc(outer, 0, kept, SkyColors.cream);
    arc(outer, kept, left, SkyColors.yellow);
    if (!charging) return;
    final inner = (Offset.zero & size).deflate(17);
    canvas.drawOval(
      inner,
      paint..color = SkyColors.yellow.withValues(alpha: .25),
    );
    final level = charge >= 1 ? hold.clamp(0.0, 1.0) : charge;
    arc(inner, 0, level, charge >= 1 ? SkyColors.white : SkyColors.yellow);
  }

  @override
  bool shouldRepaint(_ShotMeter oldDelegate) =>
      reserve != oldDelegate.reserve ||
      spend != oldDelegate.spend ||
      charge != oldDelegate.charge ||
      hold != oldDelegate.hold ||
      charging != oldDelegate.charging;
}

class _MeterRing extends CustomPainter {
  const _MeterRing(this.value, this.color);
  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = (Offset.zero & size).deflate(2);
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
      value != oldDelegate.value || color != oldDelegate.color;
}
