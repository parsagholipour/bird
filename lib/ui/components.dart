import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'theme.dart';
import 'ui_sounds.dart';

const birdAssets = ['pip', 'peaches', 'minty', 'orbit'];

class BirdArt extends StatelessWidget {
  const BirdArt({
    super.key,
    this.bird = 0,
    this.size = 128,
    this.bob = true,
    this.reducedMotion = false,
  });
  final int bird;
  final double size;
  final bool bob, reducedMotion;
  @override
  Widget build(BuildContext context) {
    final art = Image.asset(
      'assets/images/${birdAssets[bird]}.png',
      width: size,
      height: size * 224 / 256,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
    );
    return bob && !reducedMotion ? Floating(child: art) : art;
  }
}

class Floating extends StatefulWidget {
  const Floating({super.key, required this.child});
  final Widget child;
  @override
  State<Floating> createState() => _FloatingState();
}

class _FloatingState extends State<Floating>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  bool disableAnimations = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (disableAnimations) {
      controller.stop();
    } else if (!controller.isAnimating) {
      controller.repeat();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    child: widget.child,
    builder: (context, child) => Transform.translate(
      offset: Offset(
        0,
        disableAnimations ? 0 : math.sin(controller.value * 2 * math.pi) * 5,
      ),
      child: child,
    ),
  );
}

class SkyButton extends StatefulWidget {
  const SkyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = SkyColors.coral,
    this.icon = Icons.arrow_forward_rounded,
    this.compact = false,
    this.busy = false,
    this.autofocus = false,
    this.sound = 'ui_tap',
  });
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final IconData? icon;
  final bool compact, busy, autofocus;
  final String sound;
  @override
  State<SkyButton> createState() => _SkyButtonState();
}

class _SkyButtonState extends State<SkyButton> {
  bool pressed = false, hasFocus = false;
  bool get enabled => widget.onPressed != null && !widget.busy;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(highlightModeChanged);
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(highlightModeChanged);
    super.dispose();
  }

  void highlightModeChanged(FocusHighlightMode mode) {
    if (hasFocus) setState(() {});
  }

  @override
  void didUpdateWidget(covariant SkyButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!enabled) pressed = false;
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      value: widget.busy ? 'Busy' : null,
      liveRegion: widget.busy,
      child: AnimatedContainer(
        duration: disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(
          0,
          pressed && !disableAnimations ? 3 : 0,
          0,
        ),
        decoration: BoxDecoration(
          color: enabled ? widget.color : SkyColors.sky,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: SkyColors.ink.withValues(alpha: .16),
            width: 1.5,
          ),
          boxShadow: [
            // The same keyboard ring as the Play key; pointer focus stays quiet.
            if (hasFocus &&
                FocusManager.instance.highlightMode ==
                    FocusHighlightMode.traditional) ...const [
              BoxShadow(color: SkyColors.ink, spreadRadius: 5),
              BoxShadow(color: SkyColors.cream, spreadRadius: 3),
            ],
            if (!pressed)
              BoxShadow(
                color: SkyColors.ink.withValues(alpha: .16),
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            autofocus: widget.autofocus,
            onFocusChange: (v) {
              if (mounted) setState(() => hasFocus = v);
            },
            borderRadius: BorderRadius.circular(16),
            onTap: enabled
                ? () {
                    UiSounds.effect(context, widget.sound);
                    widget.onPressed!();
                  }
                : null,
            onHighlightChanged: (v) {
              // Disabling a held InkWell can clear its highlight during build.
              // didUpdateWidget already released our pressed state in that case.
              if (!enabled || pressed == v) return;
              setState(() => pressed = v);
            },
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: widget.compact ? 44 : 52),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.compact ? 14 : 20,
                  vertical: 10,
                ),
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          widget.label,
                          style: bodyText(
                            widget.compact ? 15 : 17,
                            weight: FontWeight.w900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (widget.icon != null || widget.busy) ...[
                        const SizedBox(width: 12),
                        SizedBox.square(
                          dimension: 20,
                          child: widget.busy
                              ? Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: CircularProgressIndicator(
                                    value: disableAnimations ? .75 : null,
                                    strokeWidth: 2,
                                    color: SkyColors.ink,
                                  ),
                                )
                              : Icon(
                                  widget.icon,
                                  size: 20,
                                  color: SkyColors.ink,
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

class RoundButton extends StatelessWidget {
  const RoundButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color = SkyColors.cream,
    this.sound = 'ui_tap',
  });
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final String sound;
  @override
  Widget build(BuildContext context) => Material(
    color: color,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: SkyColors.ink.withValues(alpha: .12)),
    ),
    child: IconButton(
      onPressed: onPressed == null
          ? null
          : () {
              UiSounds.effect(
                context,
                sound == 'ui_tap' &&
                        (icon == Icons.arrow_back_rounded ||
                            icon == Icons.close_rounded)
                    ? 'ui_back'
                    : sound,
              );
              onPressed!();
            },
      icon: Icon(icon, color: SkyColors.ink),
      tooltip: label,
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
  );
}

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.color = SkyColors.cream,
    this.padding = const EdgeInsets.all(24),
  });
  final Widget child;
  final Color color;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: .8), width: 2),
      boxShadow: [
        BoxShadow(
          color: SkyColors.ink.withValues(alpha: .08),
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}

class Pill extends StatelessWidget {
  const Pill(
    this.label, {
    super.key,
    this.icon,
    this.color = SkyColors.cream,
    this.foreground = SkyColors.ink,
  });
  final String label;
  final IconData? icon;
  final Color color, foreground;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 15, color: foreground),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: bodyText(12, color: foreground, weight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class SceneLayout extends StatelessWidget {
  const SceneLayout({
    super.key,
    required this.child,
    this.width = 1000,
    this.height = 450,
  });
  final Widget child;
  final double width, height;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: LayoutBuilder(
      builder: (context, c) => Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(width: width, height: height, child: child),
        ),
      ),
    ),
  );
}

class SkyBackdrop extends StatelessWidget {
  const SkyBackdrop({
    super.key,
    required this.child,
    this.reducedMotion = false,
  });
  final Widget child;
  final bool reducedMotion;
  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [SkyColors.skyDeep, SkyColors.sky, Color(0xffe3f5ef)],
          ),
        ),
      ),
      const Positioned(left: -30, top: 30, child: Cloud(width: 190)),
      const Positioned(right: 70, top: 50, child: Cloud(width: 145)),
      const Positioned(right: -65, bottom: 60, child: Cloud(width: 250)),
      const Positioned(left: 90, bottom: 4, child: Cloud(width: 300)),
      child,
    ],
  );
}

class Cloud extends StatelessWidget {
  const Cloud({super.key, this.width = 120});
  final double width;
  @override
  Widget build(BuildContext context) => Opacity(
    opacity: .65,
    child: SizedBox(
      width: width,
      height: width * .4,
      child: CustomPaint(painter: _CloudPainter()),
    ),
  );
}

class _CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawOval(
      Rect.fromLTWH(w * .08, h * .7, w * .84, h * .28),
      Paint()..color = const Color(0xff8eb4c4).withValues(alpha: .28),
    );
    final body = Paint()..color = SkyColors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, h * .46, w, h * .44),
        Radius.circular(h * .22),
      ),
      body,
    );
    canvas.drawOval(Rect.fromLTWH(w * .05, h * .26, w * .32, h * .58), body);
    canvas.drawOval(Rect.fromLTWH(w * .26, h * .04, w * .4, h * .72), body);
    canvas.drawOval(Rect.fromLTWH(w * .54, h * .2, w * .3, h * .55), body);
    canvas.drawOval(Rect.fromLTWH(w * .72, h * .34, w * .24, h * .42), body);
    canvas.drawOval(
      Rect.fromLTWH(w * .36, h * .12, w * .16, h * .24),
      Paint()..color = SkyColors.cream.withValues(alpha: .75),
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

void showFailure(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Could not save this change. Please try again. ($error)'),
    ),
  );
}
