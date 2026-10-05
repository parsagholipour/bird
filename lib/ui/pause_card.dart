import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'match_hud.dart';
import 'stage_key.dart';
import 'theme.dart';

/// One of the pause card's quieter keys, such as Map or Retry.
class PauseAction {
  const PauseAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.key,
    this.tint,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Key? key;

  /// Colours the key's cap instead of cream, such as mint for Retry.
  final Color? tint;
}

/// The in-flight pause: the frozen sky softly blurred behind a card that
/// settles in, holding the result screens' chunky keys. The way back into
/// the sky is the big coral key; the keys that leave the flight sit apart
/// on its left.
class PauseCard extends StatelessWidget {
  const PauseCard({
    super.key,
    required this.subtitle,
    required this.actions,
    required this.onResume,
    this.reducedMotion = false,
    this.perched = const [],
  });

  /// One warm line under the heading.
  final String subtitle;

  /// The quieter keys on the card's left.
  final List<PauseAction> actions;
  final VoidCallback onResume;
  final bool reducedMotion;

  /// Extra decorations perched on the card's top edge, positioned against
  /// the card, such as co-op's pair of birds.
  final List<Widget> perched;

  static const _duration = Duration(milliseconds: 260);
  static const _maxWidth = 520.0, _sidePadding = 32.0;

  @override
  Widget build(BuildContext context) {
    final still = reducedMotion || MediaQuery.disableAnimationsOf(context);
    if (still) return _frame(1);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: _duration,
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => _frame(t),
    );
  }

  /// The pause at [t] of its entrance, from 0 (just paused) to 1 (settled).
  Widget _frame(double t) => Stack(
    fit: StackFit.expand,
    children: [
      // The frozen flight stays in view, softened and pushed back.
      ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 6 * t, sigmaY: 6 * t),
          child: ColoredBox(
            color: Color.lerp(
              SkyColors.ink.withValues(alpha: 0),
              SkyColors.ink.withValues(alpha: .22),
              t,
            )!,
          ),
        ),
      ),
      LayoutBuilder(
        builder: (context, constraints) {
          final width = math.min(
            _maxWidth,
            constraints.maxWidth - 2 * _sidePadding - 32,
          );
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 34),
              child: Opacity(
                opacity: t.clamp(0, 1),
                child: Transform.translate(
                  offset: Offset(0, 18 * (1 - t)),
                  child: Transform.scale(
                    scale: .94 + .06 * t,
                    child: _card(width),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ],
  );

  Widget _card(double width) {
    // One leaving key gets room for a longer label such as Finish flight.
    final actionWidth = actions.length == 1 ? 128.0 : 100.0;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        MatchPlate(
          radius: 28,
          padding: const EdgeInsets.fromLTRB(
            _sidePadding,
            44,
            _sidePadding,
            24,
          ),
          child: SizedBox(
            width: width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Take a breather.', style: heading(38)),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: bodyText(16, color: SkyColors.muted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final (i, action) in actions.indexed) ...[
                      if (i > 0) const SizedBox(width: 10),
                      SizedBox(
                        width: actionWidth,
                        child: StageKey(
                          key: action.key,
                          height: 76,
                          label: action.label,
                          icon: action.icon,
                          tint: action.tint,
                          onPressed: action.onPressed,
                        ),
                      ),
                    ],
                    // A wider gap keeps a leaving tap away from the way
                    // back into the sky.
                    if (actions.isNotEmpty) const SizedBox(width: 18),
                    Expanded(
                      child: StageKey(
                        label: 'Keep flying',
                        icon: Icons.play_arrow_rounded,
                        hero: true,
                        sound: 'resume',
                        onPressed: onResume,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        ...perched,
        // The paused badge crowns the card.
        const Positioned(
          top: -34,
          child: ExcludeSemantics(
            child: SizedBox.square(
              dimension: 68,
              child: MatchPlate(
                color: SkyColors.yellow,
                padding: EdgeInsets.zero,
                child: Center(child: MatchIcon(MatchSymbol.pause, size: 34)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
