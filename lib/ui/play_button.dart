import 'package:flutter/material.dart';
import 'theme.dart';
import 'ui_sounds.dart';

/// A physical-looking play key with a fixed touch target and native button input.
class PlayButton extends StatefulWidget {
  const PlayButton({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  State<PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<PlayButton> {
  final states = WidgetStatesController();

  @override
  void dispose() {
    states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
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
                            BoxShadow(color: SkyColors.ink, spreadRadius: 7),
                            BoxShadow(color: SkyColors.cream, spreadRadius: 5),
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
                        border: Border.all(color: SkyColors.ink, width: 2.5),
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
                        border: Border.all(color: SkyColors.ink, width: 2.5),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: pressed
                              ? const [Color(0xffffd05a), Color(0xfff2b839)]
                              : hovered
                              ? const [Color(0xffffeead), Color(0xffffd969)]
                              : const [Color(0xffffe991), Color(0xffffcc4d)],
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
                                color: SkyColors.cream.withValues(alpha: .85),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'PLAY',
                                style: heading(38, weight: FontWeight.w700)
                                    .copyWith(
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
                              const CustomPaint(
                                size: Size(30, 34),
                                painter: _PlayArrowPainter(),
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
      ),
    );
  }
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
