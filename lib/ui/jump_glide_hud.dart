import 'package:flutter/material.dart';
import '../domain/game_rules.dart';
import 'theme.dart';

class JumpGlideHud extends StatelessWidget {
  const JumpGlideHud({
    super.key,
    required this.simulation,
    this.compact = false,
  });
  final FlightSimulation simulation;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final active = simulation.hasGlideCharge;
    final remaining = simulation.glideRemaining;
    final low =
        active &&
        remaining <
            (simulation.smoothJumpDescent
                ? FlightSimulation.glideEaseOutSeconds
                : .75);
    final title = !active
        ? 'JUMP TO GLIDE'
        : simulation.gliding
        ? low
              ? 'GLIDE ENDING'
              : 'GLIDING'
        : 'BOOST + GLIDE';
    final time = '${remaining.toStringAsFixed(1)}s';
    final starAdded =
        active && simulation.elapsed - simulation.lastGlideStarAt < .8;
    if (compact) {
      return Text(
        active ? 'Glide · $time' : 'Jump to glide',
        style: bodyText(11, color: SkyColors.mint),
      );
    }
    final color = low ? SkyColors.gold : SkyColors.teal;
    return Semantics(
      label: active
          ? '$title, $time of glide remaining'
          : 'Jump to charge a 3-second glide',
      excludeSemantics: true,
      child: Container(
        key: const ValueKey('jump-glide-meter'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: SkyColors.cream.withValues(alpha: .96),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: .35)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.air_rounded, color: color, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: bodyText(12, weight: FontWeight.w900),
                  ),
                ),
                if (active)
                  Text(time, style: bodyText(14, weight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: active
                    ? remaining / FlightSimulation.maxGlideSeconds
                    : 0,
                minHeight: 5,
                backgroundColor: SkyColors.mint.withValues(alpha: .3),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              starAdded
                  ? 'Star added glide!'
                  : low
                  ? 'Jump when you need a boost'
                  : simulation.collectsStars
                  ? 'Stars extend your glide'
                  : 'Jump for a boost + 3s glide',
              style: bodyText(11, color: SkyColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
