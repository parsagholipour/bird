import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'theme.dart';
import 'ui_sounds.dart';

/// A physical-looking play key with a fixed touch target and native button input.
/// With [animated], it breathes at rest and a glint crosses it every few
/// seconds. [reducedMotion] joins the platform's animation setting in keeping
/// the key still.
class PlayButton extends StatefulWidget {
  const PlayButton({
    super.key,
    required this.onPressed,
    this.animated = false,
    this.reducedMotion = false,
  });
  final VoidCallback onPressed;
  final bool animated, reducedMotion;

  @override
  State<PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<PlayButton>
    with SingleTickerProviderStateMixin {
  final states = WidgetStatesController();
  late final loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  );
  // True while the key should hold its resting pose.
  bool still = true;

  bool get reduced =>
      widget.reducedMotion || MediaQuery.disableAnimationsOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(PlayButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    still = !widget.animated || reduced;
    if (still) {
      loop.stop();
      loop.value = 0;
    } else if (!loop.isAnimating) {
      loop.repeat();
    }
  }

  @override
  void dispose() {
    loop.dispose();
    states.dispose();
    super.dispose();
  }

  // Two slow breaths per cycle: 0 at rest, 1 at the top of each.
  double get breath => still ? 0 : .5 - .5 * math.cos(loop.value * 4 * math.pi);

  @override
  Widget build(BuildContext context) {
    final reducedMotion = reduced;
    return SizedBox(
      height: 76,
      width: double.infinity,
      child: TextButton(
        statesController: states,
        onPressed: () {
          UiSounds.effect(context);
          widget.onPressed();
        },
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(48, 76),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          overlayColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          enableFeedback: true,
        ),
        child: Semantics(
          label: 'Play. Choose your mode',
          excludeSemantics: true,
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              // A warm glow that stays put while the key breathes over it.
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                bottom: 0,
                child: RepaintBoundary(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: SkyColors.yellow.withValues(alpha: .6),
                          blurRadius: 30,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: loop,
                builder: (context, child) =>
                    Transform.scale(scale: 1 + .022 * breath, child: child),
                child: ValueListenableBuilder<Set<WidgetState>>(
                  valueListenable: states,
                  builder: (context, value, _) {
                    final pressed = value.contains(WidgetState.pressed);
                    final focused = value.contains(WidgetState.focused);
                    final hovered = value.contains(WidgetState.hovered);
                    return Stack(
                      fit: StackFit.expand,
                      clipBehavior: Clip.none,
                      children: [
                        if (focused)
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(26),
                                boxShadow: const [
                                  BoxShadow(
                                    color: SkyColors.ink,
                                    spreadRadius: 7,
                                  ),
                                  BoxShadow(
                                    color: SkyColors.cream,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Positioned(
                          top: 8,
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xffce9239),
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                color: SkyColors.ink,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: SkyColors.ink.withValues(alpha: .16),
                                  offset: const Offset(0, 4),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          bottom: 8,
                          left: 0,
                          right: 0,
                          child: AnimatedContainer(
                            duration: reducedMotion
                                ? Duration.zero
                                : const Duration(milliseconds: 90),
                            curve: Curves.easeOut,
                            transform: Matrix4.translationValues(
                              0,
                              pressed && !reducedMotion ? 6 : 0,
                              0,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                color: SkyColors.ink,
                                width: 2.5,
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: pressed
                                    ? const [
                                        Color(0xffffd05a),
                                        Color(0xfff2b839),
                                      ]
                                    : hovered
                                    ? const [
                                        Color(0xffffeead),
                                        Color(0xffffd969),
                                      ]
                                    : const [
                                        Color(0xffffe991),
                                        Color(0xffffcc4d),
                                      ],
                              ),
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Positioned.fill(
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(19),
                                        border: Border.all(
                                          color: SkyColors.cream.withValues(
                                            alpha: .55,
                                          ),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 25,
                                  top: 7,
                                  width: 61,
                                  height: 3,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: SkyColors.cream.withValues(
                                        alpha: .85,
                                      ),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                                if (!reducedMotion)
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(23),
                                      child: CustomPaint(
                                        painter: _GlintPainter(loop),
                                      ),
                                    ),
                                  ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'PLAY',
                                      style:
                                          heading(
                                            38,
                                            weight: FontWeight.w700,
                                          ).copyWith(
                                            letterSpacing: 2,
                                            shadows: const [
                                              Shadow(
                                                color: SkyColors.cream,
                                                offset: Offset(0, 1.5),
                                              ),
                                            ],
                                          ),
                                    ),
                                    const SizedBox(width: 22),
                                    AnimatedBuilder(
                                      animation: loop,
                                      builder: (context, child) =>
                                          Transform.translate(
                                            offset: Offset(4 * breath, 0),
                                            child: child,
                                          ),
                                      child: const CustomPaint(
                                        size: Size(30, 34),
                                        painter: _PlayArrowPainter(),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A soft diagonal band of light that crosses the key once per cycle.
class _GlintPainter extends CustomPainter {
  _GlintPainter(this.loop) : super(repaint: loop);
  final Animation<double> loop;

  static final Paint _band = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final u = (loop.value - .45) / .18;
    if (u <= 0 || u >= 1) return;
    final x = -70 + (size.width + 140) * Curves.easeInOut.transform(u);
    final fade = math.sin(u * math.pi);
    canvas.save();
    canvas.translate(x, 0);
    canvas.transform(Matrix4.skewX(-.5).storage);
    canvas.drawRect(
      Rect.fromLTWH(-12, 0, 24, size.height),
      _band..color = SkyColors.white.withValues(alpha: .55 * fade),
    );
    canvas.drawRect(
      Rect.fromLTWH(18, 0, 8, size.height),
      _band..color = SkyColors.white.withValues(alpha: .4 * fade),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GlintPainter oldDelegate) => false;
}

class _PlayArrowPainter extends CustomPainter {
  const _PlayArrowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final triangle = Path()
      ..moveTo(5, 3)
      ..quadraticBezierTo(2, 1, 2, 5)
      ..lineTo(2, size.height - 5)
      ..quadraticBezierTo(2, size.height - 1, 5, size.height - 3)
      ..lineTo(size.width - 3, size.height / 2 + 2)
      ..quadraticBezierTo(
        size.width,
        size.height / 2,
        size.width - 3,
        size.height / 2 - 2,
      )
      ..close();
    canvas.drawPath(
      triangle.shift(const Offset(0, 2)),
      Paint()..color = SkyColors.gold,
    );
    canvas.drawPath(triangle, Paint()..color = SkyColors.cream);
    canvas.drawPath(
      triangle,
      Paint()
        ..color = SkyColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_PlayArrowPainter oldDelegate) => false;
}
