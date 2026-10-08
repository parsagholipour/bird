import 'package:flutter/material.dart';
import '../domain/game_rules.dart';
import '../l10n/l10n.dart';
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
    final l = context.l10n;
    final time = l.flightSeconds(remaining.toStringAsFixed(1));
    if (compact) {
      return Text(
        active ? l.hudGlideCompact(time) : l.hudJumpToGlide,
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
          text: active ? time : l.hudJump,
          color: low ? SkyColors.coralDeep : SkyColors.teal,
          label: active
              ? low
                    ? l.hudGlideEndingSemantics(time)
                    : l.hudGlideSemantics(time)
              : l.hudJumpChargeSemantics,
        ),
      ),
    );
  }
}
