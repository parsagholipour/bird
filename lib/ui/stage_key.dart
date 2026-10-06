import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';
import 'ui_sounds.dart';

/// A chunky key in the home screen's style: an ink-outlined cap over a
/// darker base that it sinks into when pressed. Secondary keys are cream
/// with the icon over the label; the [hero] key is a taller coral key with
/// a cream icon badge beside a big label, and a glint can cross it once
/// ([shine] runs 0–1).
class StageKey extends StatefulWidget {
  const StageKey({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.hero = false,
    this.busy = false,
    this.shine = 0,
    this.height,
    this.sound = 'ui_tap',
    this.tint,
    this.autofocus = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool hero, busy;
  final double shine;

  /// The key's height with its base; 86 for the hero key and 70 otherwise.
  final double? height;

  /// The cue the key plays when tapped.
  final String sound;

  /// Colours a secondary key's cap instead of cream; the hero stays coral.
  final Color? tint;

  /// Takes the keyboard focus as soon as it can be pressed, unless another
  /// key on its screen has it, so Enter presses it.
  final bool autofocus;

  @override
  State<StageKey> createState() => _StageKeyState();
}

class _StageKeyState extends State<StageKey> {
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
  void didUpdateWidget(covariant StageKey oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!enabled) pressed = false;
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final hero = widget.hero;
    final depth = hero ? 8.0 : 6.0;
    final radius = BorderRadius.circular(hero ? 24 : 20);
    final sink = pressed && !still ? depth - 2 : 0.0;
    final tint = widget.tint;
    final (top, bottom, base) = !enabled
        ? (
            const Color(0xffe6eef0),
            const Color(0xffd5e1e5),
            const Color(0xffa9bcc2),
          )
        : hero
        ? pressed
              ? (
                  const Color(0xfff48d73),
                  const Color(0xffe46c53),
                  const Color(0xffb34a39),
                )
              : (
                  const Color(0xffffa088),
                  SkyColors.coral,
                  const Color(0xffb34a39),
                )
        : tint != null
        ? (
            Color.lerp(tint, SkyColors.white, pressed ? .2 : .45)!,
            pressed ? Color.lerp(tint, SkyColors.ink, .06)! : tint,
            Color.lerp(tint, SkyColors.ink, .3)!,
          )
        : pressed
        ? (
            const Color(0xfff6ecd6),
            const Color(0xffeee1c4),
            const Color(0xffcdb98c),
          )
        : (
            const Color(0xfffffcf3),
            const Color(0xfff6ebd4),
            const Color(0xffcdb98c),
          );
    final ink = enabled ? SkyColors.ink : SkyColors.muted;
    final glyph = widget.busy
        ? SizedBox.square(
            dimension: 22,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: CircularProgressIndicator(
                value: still ? .75 : null,
                strokeWidth: 2.5,
                color: SkyColors.ink,
              ),
            ),
          )
        : Icon(widget.icon, size: hero ? 26 : 24, color: ink);
    final label = Text(
      widget.label,
      maxLines: 1,
      textAlign: TextAlign.center,
      style: hero
          ? heading(32, weight: FontWeight.w700).copyWith(
              shadows: const [
                Shadow(color: Color(0x99fff9ed), offset: Offset(0, 1.5)),
              ],
            )
          : heading(17, color: ink, weight: FontWeight.w600),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      value: widget.busy ? 'Busy' : null,
      liveRegion: widget.busy,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          // A key that starts busy takes the focus once it is ready.
          autofocus: widget.autofocus && enabled,
          onFocusChange: (v) {
            if (mounted) setState(() => hasFocus = v);
          },
          borderRadius: radius,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          onTap: enabled
              ? () {
                  UiSounds.effect(context, widget.sound);
                  widget.onPressed!();
                }
              : null,
          onHighlightChanged: (v) {
            if (!enabled || pressed == v) return;
            setState(() => pressed = v);
          },
          child: SizedBox(
            height: widget.height ?? (hero ? 86 : 70),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // The same keyboard ring as the other keys; pointer focus
                // stays quiet.
                if (hasFocus &&
                    FocusManager.instance.highlightMode ==
                        FocusHighlightMode.traditional)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: radius,
                        boxShadow: const [
                          BoxShadow(color: SkyColors.ink, spreadRadius: 6),
                          BoxShadow(color: SkyColors.cream, spreadRadius: 4),
                        ],
                      ),
                    ),
                  ),
                Positioned.fill(
                  top: depth,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: radius,
                      border: Border.all(color: SkyColors.ink, width: 2.5),
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: still
                      ? Duration.zero
                      : const Duration(milliseconds: 90),
                  curve: Curves.easeOut,
                  left: 0,
                  right: 0,
                  top: sink,
                  bottom: depth - sink,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      border: Border.all(color: SkyColors.ink, width: 2.5),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [top, bottom],
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(hero ? 21 : 17),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // A cream catch-light along the top of the cap.
                          Positioned(
                            left: 18,
                            right: 18,
                            top: 5,
                            height: 3,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: SkyColors.cream.withValues(
                                  alpha: hero ? .7 : .9,
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                          if (widget.shine > 0 && widget.shine < 1)
                            CustomPaint(painter: _GlintPainter(widget.shine)),
                          ExcludeSemantics(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: hero ? 14 : 6,
                              ),
                              child: hero
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: SkyColors.cream,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: SkyColors.ink,
                                              width: 2.5,
                                            ),
                                          ),
                                          child: glyph,
                                        ),
                                        const SizedBox(width: 14),
                                        Flexible(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: label,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        glyph,
                                        const SizedBox(height: 2),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: label,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A soft diagonal band of light crossing a key once, [t] from 0 to 1.
class _GlintPainter extends CustomPainter {
  const _GlintPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final x = -60 + (size.width + 120) * Curves.easeInOut.transform(t);
    final fade = math.sin(t * math.pi);
    final band = Paint();
    canvas.save();
    canvas.translate(x, 0);
    canvas.transform(Matrix4.skewX(-.5).storage);
    canvas.drawRect(
      Rect.fromLTWH(-14, 0, 28, size.height),
      band..color = SkyColors.white.withValues(alpha: .5 * fade),
    );
    canvas.drawRect(
      Rect.fromLTWH(20, 0, 9, size.height),
      band..color = SkyColors.white.withValues(alpha: .35 * fade),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GlintPainter old) => old.t != t;
}

/// A yellow banner with notched tails, outlined in ink, for a new best.
class StageRibbon extends StatelessWidget {
  const StageRibbon(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: const _RibbonPainter(),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(22, 5, 22, 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            size: 16,
            color: SkyColors.ink,
          ),
          const SizedBox(width: 5),
          Text(label, style: bodyText(13, weight: FontWeight.w900)),
        ],
      ),
    ),
  );
}

class _RibbonPainter extends CustomPainter {
  const _RibbonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    const notch = 10.0;
    final shape = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w - notch, h / 2)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..lineTo(notch, h / 2)
      ..close();
    canvas.drawPath(
      shape.shift(const Offset(0, 3)),
      Paint()..color = SkyColors.ink.withValues(alpha: .25),
    );
    canvas.drawPath(shape, Paint()..color = SkyColors.yellow);
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round
        ..color = SkyColors.ink,
    );
  }

  @override
  bool shouldRepaint(_RibbonPainter old) => false;
}
