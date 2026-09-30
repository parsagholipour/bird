import 'package:flutter/material.dart';
import 'theme.dart';
import 'match_hud.dart';

/// The hero readout: big numbers on a HUD plate with the streak multiplier
/// as a tilted tag. A rising score pops the plate once and flicks the star.
class FlightScore extends StatefulWidget {
  const FlightScore({
    super.key,
    required this.score,
    required this.reducedMotion,
    this.multiplier = 1,
    this.symbol = MatchSymbol.star,
  });

  final int score;
  final int multiplier;
  final MatchSymbol symbol;
  final bool reducedMotion;

  @override
  State<FlightScore> createState() => _FlightScoreState();
}

class _FlightScoreState extends State<FlightScore>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  late final _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 1.06,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.06,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeInOutCubic)),
      weight: 60,
    ),
  ]).animate(_pulse);
  // The star tips back and settles, in turns.
  late final _flick = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: -.07,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: -.07,
        end: 0.0,
      ).chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 65,
    ),
  ]).animate(_pulse);
  bool _disableAnimations = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (_disableAnimations || widget.reducedMotion) _pulse.reset();
  }

  @override
  void didUpdateWidget(FlightScore oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reducedMotion ||
        _disableAnimations ||
        widget.score < oldWidget.score) {
      _pulse.reset();
    } else if (widget.score > oldWidget.score) {
      _pulse.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: Semantics(
      label:
          'Score ${widget.score}${widget.multiplier > 1 ? ', ${widget.multiplier} times multiplier' : ''}',
      excludeSemantics: true,
      child: ScaleTransition(
        scale: _scale,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: MatchPlate(
            padding: EdgeInsets.fromLTRB(
              14,
              0,
              widget.multiplier > 1 ? 10 : 20,
              2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RotationTransition(
                  turns: _flick,
                  child: MatchIcon(widget.symbol, size: 40),
                ),
                const SizedBox(width: 8),
                Text('${widget.score}', style: matchDigits(56)),
                if (widget.multiplier > 1) ...[
                  const SizedBox(width: 8),
                  MatchPulse(
                    value: widget.multiplier,
                    reducedMotion: widget.reducedMotion,
                    child: MatchTag(
                      '${widget.multiplier}×',
                      color: widget.multiplier > 2
                          ? SkyColors.purple
                          : SkyColors.coral,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
