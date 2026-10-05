import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'components.dart';
import 'match_hud.dart';
import 'theme.dart';

/// Breathers for a push-up or squat flight: a cue for the body while the
/// bird waits.
const pauseTipsWorkout = [
  'Breathe in on the way down, out on the way up.',
  'Shake out your wrists and roll your shoulders.',
  'Keep a straight line from head to heels.',
  'Sip some water. The sky will wait for you.',
  'Slow reps count too. Smooth beats speedy.',
];

/// Breathers for Tap & Fly, where the body is resting anyway.
const pauseTipsTouch = [
  'Slow breath in… and out. Nice and easy.',
  'Short, steady taps keep the bird level.',
  'Look past the next gate, not at the bird.',
  'Unclench your hands. Your bird is safe here.',
];

/// Breathers for a pair flying together.
const pauseTipsCoop = [
  'High five your partner. You’ve earned it.',
  'Breathe out together on the way up.',
  'Pick a call for “flap now!” and stick to it.',
];

/// The tip for this pause: the same for as long as the pause lasts, and
/// moving on as the flight does, with no randomness.
String pauseTip(List<String> tips, int seed) => tips[seed.abs() % tips.length];

/// The in-flight pause: the frozen sky softly blurred behind a card that
/// settles in, with a breather tip, and Keep flying kept apart from the
/// actions that leave the flight.
class PauseCard extends StatelessWidget {
  const PauseCard({
    super.key,
    required this.subtitle,
    required this.tip,
    required this.secondary,
    required this.onResume,
    this.reducedMotion = false,
    this.perched = const [],
  });

  /// One warm line under the heading.
  final String subtitle;

  /// The breather tip in the card's mint note.
  final String tip;

  /// The quieter actions on the card's left, such as Map and Retry.
  final List<Widget> secondary;
  final VoidCallback onResume;
  final bool reducedMotion;

  /// Extra decorations perched on the card's top edge, positioned against
  /// the card, such as co-op's pair of birds.
  final List<Widget> perched;

  static const _duration = Duration(milliseconds: 260);

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
  Widget _frame(double t) {
    final card = Opacity(
      opacity: t.clamp(0, 1),
      child: Transform.translate(
        offset: Offset(0, 18 * (1 - t)),
        child: Transform.scale(scale: .94 + .06 * t, child: _card()),
      ),
    );
    return Stack(
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
        Center(
          child: Padding(padding: const EdgeInsets.only(top: 34), child: card),
        ),
      ],
    );
  }

  Widget _card() => Stack(
    clipBehavior: Clip.none,
    alignment: Alignment.topCenter,
    children: [
      MatchPlate(
        radius: 28,
        padding: const EdgeInsets.fromLTRB(32, 44, 32, 22),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
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
              const SizedBox(height: 14),
              _TipNote(tip),
              const SizedBox(height: 18),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (i, action) in secondary.indexed) ...[
                    if (i > 0) const SizedBox(width: 10),
                    action,
                  ],
                  // A clear gap and a stitch keep a leaving tap away from
                  // the way back into the sky.
                  if (secondary.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    const _Stitch(),
                    const SizedBox(width: 16),
                  ],
                  SkyButton(
                    label: 'Keep flying',
                    sound: 'resume',
                    icon: Icons.play_arrow_rounded,
                    onPressed: onResume,
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

/// A soft mint note holding the breather tip.
class _TipNote extends StatelessWidget {
  const _TipNote(this.tip);
  final String tip;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: SkyColors.mint.withValues(alpha: .45),
      borderRadius: BorderRadius.circular(SkyLayout.pill),
      border: Border.all(color: SkyColors.teal.withValues(alpha: .35)),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 7, 16, 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.spa_rounded, size: 18, color: SkyColors.teal),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              tip,
              style: bodyText(
                15,
                color: SkyColors.ink,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// A short dotted divider between the leaving actions and Keep flying.
class _Stitch extends StatelessWidget {
  const _Stitch();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Container(
            width: 3,
            height: 3,
            margin: const EdgeInsets.symmetric(vertical: 2.5),
            decoration: BoxDecoration(
              color: SkyColors.ink.withValues(alpha: .25),
              shape: BoxShape.circle,
            ),
          ),
      ],
    ),
  );
}
