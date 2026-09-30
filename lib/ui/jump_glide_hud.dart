import 'package:flutter/material.dart';
import '../domain/game_rules.dart';
import 'match_hud.dart';
import 'theme.dart';

class JumpGlideHud extends StatelessWidget {
  const JumpGlideHud({
    super.key,
    required this.simulation,
    this.compact = false,
    this.reducedMotion = false,
  });
  final FlightSimulation simulation;
  final bool compact, reducedMotion;

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
    final time = '${remaining.toStringAsFixed(1)}s';
    if (compact) {
      return Text(
        active ? 'Glide · $time' : 'Jump to glide',
        style: bodyText(11, color: SkyColors.mint),
      );
    }
    return MatchPulse(
      value: (active, low, simulation.lastGlideStarAt),
      reducedMotion: reducedMotion,
      child: MatchPlate(
        key: const ValueKey('jump-glide-meter'),
        // A glide about to end warms the plate, like the flight clock.
        color: low ? SkyColors.yellow : SkyColors.cream,
        child: MatchMeter(
          symbol: MatchSymbol.wing,
          value: active ? remaining / FlightSimulation.maxGlideSeconds : 0,
          active: active,
          text: active ? time : 'Jump',
          color: low ? SkyColors.coralDeep : SkyColors.teal,
          label: active
              ? '${low ? 'Glide ending' : 'Glide'}, $time remaining'
              : 'Jump to charge a 3-second glide',
        ),
      ),
    );
  }
}
