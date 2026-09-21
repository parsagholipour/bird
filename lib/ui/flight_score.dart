import 'package:flutter/material.dart';
import 'theme.dart';

class FlightScore extends StatefulWidget {
  const FlightScore({
    super.key,
    required this.score,
    required this.reducedMotion,
  });

  final int score;
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
      label: 'Score ${widget.score}',
      excludeSemantics: true,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 3),
          decoration: BoxDecoration(
            color: SkyColors.cream.withValues(alpha: .94),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Text(
            '${widget.score}',
            style: heading(48, weight: FontWeight.w700),
          ),
        ),
      ),
    ),
  );
}
