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
  wing,
  sprint,
  clock,
  eye,
}

/// The flight HUD's shared grid, in [SceneLayout] units. Every readout is a
/// [MatchPlate] or a round sticker button of the same material, so the
/// spacing below is measured between faces; outlines and lips hang outside.
abstract final class MatchLayout {
  /// Inset from the scene edges, and the standard face height of a plate.
  static const edge = 16.0, height = 56.0;

  /// Space between neighbouring faces in a row, and between stacked faces,
  /// which also clears the lip of the one above.
  static const gap = 12.0, stack = 20.0;
}

/// Bold Fredoka for every HUD number, drawn from the font's weight axis
/// rather than a synthesized bold.
TextStyle matchDigits(double size, {Color color = SkyColors.ink}) => heading(
  size,
  color: color,
  weight: FontWeight.w700,
).copyWith(fontVariations: const [FontVariation('wght', 700)]);

/// A thin ink edge and drop under light text on a colored face, so white
/// numbers hold on coral, gold and purple alike.
List<Shadow> matchInkEdge(double width) => [
  for (final (dx, dy) in [(-1, 0), (1, 0), (0, -1), (0, 1)])
    Shadow(color: SkyColors.ink, offset: Offset(dx * width, dy * width)),
  Shadow(color: SkyColors.ink, offset: Offset(0, width * 2)),
];

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
    // Muted symbols become empty sockets: a faint ink fill and outline read
    // as "not yet" on cream and colored faces alike.
    final outline = Paint()
      ..color = muted ? SkyColors.ink.withValues(alpha: .38) : SkyColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    void shape(Path path, Color color) {
      canvas.drawPath(
        path,
        Paint()..color = muted ? SkyColors.ink.withValues(alpha: .1) : color,
      );
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
          final radius = i.isEven ? 13.5 : 6.6;
          final x = 16 + math.cos(angle) * radius;
          final y = 16.5 + math.sin(angle) * radius;
          i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
        }
        shape(path..close(), SkyColors.yellow);
        if (!muted) {
          line(
            Path()
              ..moveTo(12, 13.5)
              ..lineTo(15, 8.5),
            color: SkyColors.white,
            width: 2.2,
          );
        }
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
            color: SkyColors.white,
            width: 2.6,
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
          color: muted ? outline.color : SkyColors.white,
          width: 3,
        );
      case MatchSymbol.shot:
        line(
          Path()
            ..moveTo(2, 18)
            ..lineTo(11, 15)
            ..moveTo(5, 26)
            ..lineTo(14, 21),
          color: muted ? outline.color : SkyColors.cream,
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
          color: muted ? outline.color : SkyColors.sand,
          width: 2.2,
        );
        line(
          Path()
            ..moveTo(25, 2)
            ..lineTo(25, 5)
            ..moveTo(29, 5)
            ..lineTo(31, 4),
          color: muted ? outline.color : SkyColors.cream,
          width: 1.6,
        );
      case MatchSymbol.pause:
        for (final x in [8.0, 19.0]) {
          shape(
            Path()..addRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTWH(x, 6, 5.5, 20),
                const Radius.circular(2.75),
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
          color: muted ? outline.color : SkyColors.white,
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
      case MatchSymbol.clock:
        shape(
          Path()..addRRect(
            RRect.fromRectAndRadius(
              const Rect.fromLTWH(12.5, 2, 7, 5),
              const Radius.circular(2),
            ),
          ),
          SkyColors.coral,
        );
        shape(
          Path()..addOval(
            Rect.fromCircle(center: const Offset(16, 18.5), radius: 11.5),
          ),
          SkyColors.white,
        );
        line(
          Path()
            ..moveTo(16, 18.5)
            ..lineTo(16, 11.5)
            ..moveTo(16, 18.5)
            ..lineTo(21, 21),
          width: 2.6,
        );
      case MatchSymbol.eye:
        shape(
          Path()
            ..moveTo(2.5, 16)
            ..quadraticBezierTo(16, 1, 29.5, 16)
            ..quadraticBezierTo(16, 31, 2.5, 16)
            ..close(),
          SkyColors.white,
        );
        shape(
          Path()..addOval(
            Rect.fromCircle(center: const Offset(16, 16), radius: 6.5),
          ),
          SkyColors.teal,
        );
        canvas.drawCircle(
          const Offset(16, 16),
          2.8,
          Paint()..color = outline.color,
        );
        if (!muted) {
          canvas.drawCircle(
            const Offset(18.2, 13.8),
            1.4,
            Paint()..color = SkyColors.white,
          );
        }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MatchIconPainter oldDelegate) =>
      symbol != oldDelegate.symbol || muted != oldDelegate.muted;
}

/// The HUD's one material, painted around a face that fills the layout box:
/// a soft drop shadow, a chunky ink outline wrapped around the face and its
/// darker lip, and a lit top rim. A light face with a dark edge keeps a
/// clear silhouette over bright snow, neon nights and busy jungle alike.
///
/// [pressed] (0 to 1) sinks the face into its lip. The outline, lip and
/// shadow paint outside the box, so sizes and hit targets stay exact.
class _Surface extends CustomPainter {
  const _Surface({
    required this.color,
    this.radius,
    this.pressed = 0,
    this.focused = false,
    this.lip = 4,
    this.outline = 2.5,
  });
  final Color color;

  /// Corner radius; null makes a pill or, on a square box, a circle.
  final double? radius;
  final double pressed, lip, outline;
  final bool focused;

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.min(radius ?? size.height / 2, size.shortestSide / 2);
    final base = RRect.fromRectAndRadius(
      Offset(0, lip) & size,
      Radius.circular(r),
    );
    final face = base.shift(Offset(0, -lip * (1 - pressed)));
    canvas.drawRRect(
      base.inflate(outline).shift(const Offset(0, 2)),
      Paint()
        ..color = SkyColors.ink.withValues(alpha: .3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    if (focused) {
      final ring = Paint()..color = SkyColors.gold;
      canvas.drawRRect(base.inflate(outline + 3.5), ring);
      canvas.drawRRect(face.inflate(outline + 3.5), ring);
    }
    final ink = Paint()..color = SkyColors.ink;
    canvas.drawRRect(base.inflate(outline), ink);
    canvas.drawRRect(face.inflate(outline), ink);
    canvas.drawRRect(
      base,
      Paint()..color = Color.lerp(color, SkyColors.ink, .34)!,
    );
    final bounds = face.outerRect;
    canvas.drawRRect(
      face,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(color, SkyColors.white, .5)!, color],
          stops: const [0, .55],
        ).createShader(bounds),
    );
    canvas.drawRRect(
      face.deflate(1.2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            SkyColors.white.withValues(alpha: .95),
            SkyColors.white.withValues(alpha: 0),
          ],
          stops: const [0, .5],
        ).createShader(bounds),
    );
  }

  @override
  bool shouldRepaint(_Surface oldDelegate) =>
      color != oldDelegate.color ||
      radius != oldDelegate.radius ||
      pressed != oldDelegate.pressed ||
      focused != oldDelegate.focused ||
      lip != oldDelegate.lip ||
      outline != oldDelegate.outline;
}

/// A readout plate in the HUD material. [radius] defaults to a pill.
class MatchPlate extends StatelessWidget {
  const MatchPlate({
    super.key,
    required this.child,
    this.color = SkyColors.cream,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.radius,
  });
  final Widget child;
  final Color color;
  final EdgeInsets padding;
  final double? radius;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _Surface(color: color, radius: radius),
    child: Padding(padding: padding, child: child),
  );
}

/// A small tilted sticker for a bonus, such as the score multiplier.
class MatchTag extends StatelessWidget {
  const MatchTag(this.text, {super.key, this.color = SkyColors.coral});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: -.12,
    child: CustomPaint(
      painter: _Surface(color: color, radius: 11, lip: 3, outline: 2),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 1, 9, 3),
        child: Text(
          text,
          style: matchDigits(
            24,
            color: SkyColors.white,
          ).copyWith(shadows: matchInkEdge(1.2)),
        ),
      ),
    ),
  );
}

/// Presses a round sticker face into its lip. Under reduced motion the face
/// stays put and a held press shades it instead.
class _PressedFace extends StatelessWidget {
  const _PressedFace({
    required this.size,
    required this.color,
    required this.pressed,
    required this.still,
    required this.focused,
    required this.child,
  });
  final double size;
  final Color color;
  final bool pressed, still, focused;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: pressed && !still ? 1 : 0),
    duration: still ? Duration.zero : const Duration(milliseconds: 90),
    curve: Curves.easeOut,
    child: child,
    builder: (context, depth, child) => SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _Surface(color: color, pressed: depth, focused: focused),
        child: Transform.translate(
          offset: Offset(0, 4 * depth),
          child: DecoratedBox(
            // Without motion, a held press still shades the face.
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: pressed && still
                  ? SkyColors.ink.withValues(alpha: .1)
                  : Colors.transparent,
            ),
            child: child,
          ),
        ),
      ),
    ),
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
        end: 1.14,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.14,
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

/// A symbol inside a progress ring, with an optional value beside it.
/// [segments] splits the ring into countable steps, such as the nine stars
/// that restore a shield.
class MatchMeter extends StatelessWidget {
  const MatchMeter({
    super.key,
    required this.symbol,
    required this.value,
    required this.label,
    this.text,
    this.active = true,
    this.color = SkyColors.teal,
    this.segments = 0,
  });
  final MatchSymbol symbol;
  final double value;
  final String label;
  final String? text;
  final bool active;
  final Color color;
  final int segments;

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
            painter: _MeterRing(value, color, segments: segments),
            child: Center(child: MatchIcon(symbol, size: 26, muted: !active)),
          ),
        ),
        if (text != null) ...[
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(text!, style: matchDigits(25)),
          ),
        ],
      ],
    ),
  );
}

/// Hearts and the shield. A lost heart bursts out of its socket and shakes
/// the plate; a new heart pops in. Both are single, short reactions, and
/// reduced motion shows the new state at once.
const _v = int.fromEnvironment('MERGE_V');

class MatchHealth extends StatefulWidget {
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
  State<MatchHealth> createState() => _MatchHealthState();
}

class _MatchHealthState extends State<MatchHealth>
    with SingleTickerProviderStateMixin {
  static const _heart = 32.0;
  late final _reaction = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );

  /// The socket that changed, and whether it filled or emptied.
  int _slot = -1;
  bool _gained = false;

  bool get _still =>
      widget.reducedMotion || MediaQuery.disableAnimationsOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_still) _reaction.reset();
  }

  @override
  void didUpdateWidget(MatchHealth oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_still) {
      _reaction.reset();
    } else if (widget.hearts != oldWidget.hearts) {
      _gained = widget.hearts > oldWidget.hearts;
      _slot = _gained ? widget.hearts - 1 : widget.hearts;
      _reaction.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _reaction.dispose();
    super.dispose();
  }

  Widget _socket(int i, double t) {
    final full = i < widget.hearts;
    final heart = MatchIcon(MatchSymbol.heart, size: _heart, muted: !full);
    if (i != _slot || !_reaction.isAnimating) return heart;
    if (_gained) {
      final pop = Curves.easeOutBack.transform(t);
      return Transform.scale(scale: .35 + .65 * pop, child: heart);
    }
    // The lost heart swells and fades out of its now-empty socket.
    return Stack(
      alignment: Alignment.center,
      children: [
        heart,
        Opacity(
          opacity: (1 - t).clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 1 + .7 * Curves.easeOut.transform(t),
            child: const MatchIcon(MatchSymbol.heart, size: _heart),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hearts = widget.hearts;
    final shield = widget.shield, recovering = widget.recovering;
    final shieldMeter = MatchPulse(
      value: (shield, recovering),
      reducedMotion: widget.reducedMotion,
      child: MatchMeter(
        key: const ValueKey('match-shield'),
        symbol: MatchSymbol.shield,
        value: shield || recovering ? 1 : widget.charge / 9,
        active: shield || recovering,
        color: recovering ? SkyColors.gold : SkyColors.teal,
        segments: shield || recovering ? 0 : 9,
        label: recovering
            ? 'Recovering'
            : shield
            ? 'Shield ready'
            : 'Shield charging: ${widget.charge} of 9 stars',
      ),
    );
    return AnimatedBuilder(
      animation: _reaction,
      builder: (context, _) {
        final t = _reaction.value;
        final shaking = _reaction.isAnimating && !_gained;
        final heartRow = ConstrainedBox(
          constraints: const BoxConstraints(minWidth: _heart * 3),
          child: SizedBox(
            height: 34,
            child: Semantics(
              label: '$hearts hearts remaining',
              excludeSemantics: true,
              child: Center(
                child: hearts > 3
                    ? Transform.scale(
                        scale: _reaction.isAnimating
                            ? 1 + .15 * math.sin(t * math.pi)
                            : 1,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const MatchIcon(
                              MatchSymbol.heart,
                              size: _heart + 4,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '×$hearts',
                              style: matchDigits(
                                27,
                                color: SkyColors.coralDeep,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [for (var i = 0; i < 3; i++) _socket(i, t)],
                      ),
              ),
            ),
          ),
        );
        return Transform.translate(
          offset: Offset(
            shaking ? math.sin(t * math.pi * 6) * 6 * (1 - t) : 0,
            0,
          ),
          child: MatchPlate(
            radius: _v == 0
                ? 32
                : _v == 1
                ? 28
                : 24,
            padding: const EdgeInsets.fromLTRB(11, 5, 11, 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [heartRow, const _Seam(), shieldMeter],
            ),
          ),
        );
      },
    );
  }
}

/// A faint groove between two readouts that share one plate.
class _Seam extends StatelessWidget {
  const _Seam();

  @override
  Widget build(BuildContext context) => Container(
    width: 84,
    height: 2.5,
    margin: const EdgeInsets.symmetric(vertical: 4),
    decoration: BoxDecoration(
      color: SkyColors.ink.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

/// A round sticker button. [hitSlop] widens the touch target around the
/// face without making the face itself bigger.
class MatchAction extends StatefulWidget {
  const MatchAction({
    super.key,
    required this.symbol,
    required this.label,
    required this.onPressed,
    required this.reducedMotion,
    this.size = 72,
    this.hitSlop = 0,
  });
  final MatchSymbol symbol;
  final String label;
  final VoidCallback? onPressed;
  final bool reducedMotion;
  final double size, hitSlop;

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
    final still =
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
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              focusColor: Colors.transparent,
              onTap: widget.onPressed,
              onFocusChange: (value) => setState(() => _focused = value),
              onHighlightChanged: (value) {
                // Disabled InkWells can clear their highlight during build.
                if (widget.onPressed == null || _pressed == value) return;
                setState(() => _pressed = value);
              },
              child: Padding(
                padding: EdgeInsets.all(widget.hitSlop),
                child: _PressedFace(
                  size: widget.size,
                  color: SkyColors.cream,
                  pressed: _pressed,
                  still: still,
                  focused: _focused,
                  child: Center(
                    child: MatchIcon(widget.symbol, size: widget.size * .54),
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
    final recharging = !ready && !sprinting;
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
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
                focusColor: Colors.transparent,
                onTap: widget.onPressed,
                onFocusChange: (value) => setState(() => _focused = value),
                onHighlightChanged: (value) {
                  if (widget.onPressed == null || _pressed == value) return;
                  setState(() => _pressed = value);
                },
                child: _PressedFace(
                  size: widget.size,
                  color: sprinting
                      ? SkyColors.yellow
                      : ready
                      ? SkyColors.teal
                      : SkyColors.cream,
                  pressed: _pressed,
                  still: still,
                  focused: _focused,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: CustomPaint(
                      painter: recharging || sprinting
                          ? _MeterRing(
                              sprinting ? widget.burst : widget.recharge,
                              sprinting ? SkyColors.white : SkyColors.teal,
                              width: 5,
                            )
                          : null,
                      child: Center(
                        child: recharging
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${widget.secondsLeft}',
                                    style: matchDigits(widget.size * .36),
                                  ),
                                  MatchIcon(
                                    MatchSymbol.sprint,
                                    size: widget.size * .24,
                                    muted: true,
                                  ),
                                ],
                              )
                            : MatchIcon(
                                MatchSymbol.sprint,
                                size: widget.size * .5,
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
          child: _PressedFace(
            size: widget.size,
            color: widget.empty
                ? Color.lerp(SkyColors.coral, SkyColors.muted, .35)!
                : Color.lerp(
                    SkyColors.coral,
                    SkyColors.gold,
                    widget.charge * .6,
                  )!,
            pressed: _held,
            still: still,
            focused: _focused,
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
                        size: widget.size * (widget.empty ? .34 : .46),
                        muted: widget.empty,
                      ),
                    ),
                    if (widget.empty) ...[
                      const SizedBox(height: 2),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: widget.size * .16,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Reloading…',
                            style: matchDigits(
                              16,
                              color: SkyColors.white,
                            ).copyWith(shadows: matchInkEdge(1)),
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
      ..strokeWidth = 5
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

    final outer = (Offset.zero & size).deflate(8);
    final left = reserve.clamp(0.0, 1.0);
    final kept = (left - spend).clamp(0.0, left);
    // The reserve runs in a dark groove, so a low reserve still reads.
    canvas.drawOval(outer, paint..color = SkyColors.ink.withValues(alpha: .28));
    arc(outer, 0, kept, SkyColors.cream);
    arc(outer, kept, left, SkyColors.yellow);
    if (!charging) return;
    final inner = (Offset.zero & size).deflate(18);
    canvas.drawOval(inner, paint..color = SkyColors.ink.withValues(alpha: .2));
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
  const _MeterRing(this.value, this.color, {this.segments = 0, this.width = 4});
  final double value;
  final Color color;
  final int segments;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = (Offset.zero & size).deflate(width / 2 + .5);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    final track = SkyColors.ink.withValues(alpha: .14);
    final level = value.clamp(0.0, 1.0);
    if (segments > 1) {
      // Countable steps: a gap wide enough to survive the round caps.
      final step = math.pi * 2 / segments;
      final gap = width / (bounds.width / 2) + .2;
      final filled = (level * segments).round();
      for (var i = 0; i < segments; i++) {
        canvas.drawArc(
          bounds,
          -math.pi / 2 + i * step + gap / 2,
          step - gap,
          false,
          paint..color = i < filled ? color : track,
        );
      }
      return;
    }
    canvas.drawOval(bounds, paint..color = track);
    if (level > 0) {
      canvas.drawArc(
        bounds,
        -math.pi / 2,
        math.pi * 2 * level,
        false,
        paint..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_MeterRing oldDelegate) =>
      value != oldDelegate.value ||
      color != oldDelegate.color ||
      segments != oldDelegate.segments ||
      width != oldDelegate.width;
}
