import 'package:flutter/material.dart';
import '../domain/flight_goals.dart';
import '../domain/flight_course.dart';
import 'campaign_chrome.dart' show MapGlyph, MapKey;
import 'theme.dart';

class WingBadge extends StatelessWidget {
  const WingBadge({super.key, required this.earned, this.size = 26});
  final bool earned;
  final double size;
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _WingPainter(earned));
}

class _WingPainter extends CustomPainter {
  const _WingPainter(this.earned);
  final bool earned;
  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 32);
    c.drawCircle(
      const Offset(16, 16),
      15,
      Paint()
        ..color = earned
            ? SkyColors.yellow
            : SkyColors.sky.withValues(alpha: .45),
    );
    final wing = Path()
      ..moveTo(8, 24)
      ..cubicTo(5, 14, 17, 7, 27, 6)
      ..cubicTo(25, 19, 19, 28, 8, 24)
      ..close();
    c.drawPath(
      wing,
      Paint()
        ..color = earned
            ? SkyColors.cream
            : SkyColors.white.withValues(alpha: .6),
    );
    c.drawPath(
      Path()
        ..moveTo(8, 24)
        ..quadraticBezierTo(15, 17, 24, 9)
        ..moveTo(14, 18)
        ..lineTo(20, 19)
        ..moveTo(18, 14)
        ..lineTo(23, 15),
      Paint()
        ..color = earned
            ? SkyColors.gold
            : SkyColors.muted.withValues(alpha: .65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
    c.restore();
  }

  @override
  bool shouldRepaint(_WingPainter oldDelegate) => oldDelegate.earned != earned;
}

class FlightWings extends StatelessWidget {
  const FlightWings({super.key, required this.goals, this.size = 24});
  final List<FlightGoalProgress> goals;
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
    label:
        '${FlightGoals.earned(goals)} of ${goals.length} flight wings earned',
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final goal in goals)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: WingBadge(earned: goal.earned, size: size),
          ),
      ],
    ),
  );
}

Future<void> showFlightGoals(
  BuildContext context,
  FlightCourse course, {
  List<FlightGoalProgress>? progress,
}) => showDialog<void>(
  context: context,
  builder: (context) {
    final goals =
        progress ??
        [
          for (final goal in FlightGoals.forCourse(course))
            FlightGoalProgress(goal, 0),
        ];
    final pending = goals.where((g) => !g.earned);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${course.title} · Flight goals',
                      style: heading(25),
                    ),
                  ),
                  MapKey(
                    glyph: MapGlyph.close,
                    label: 'Close flight goals',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                progress == null
                    ? 'Earn all three wings in one scored flight.'
                    : pending.isEmpty
                    ? 'All three wings earned in one flight!'
                    : 'Next flight: ${pending.first.goal.description}',
                style: bodyText(14, color: SkyColors.muted),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (final goal in goals)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          child: Row(
                            children: [
                              WingBadge(earned: goal.earned, size: 38),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(goal.goal.title, style: heading(20)),
                                    Text(
                                      goal.goal.description,
                                      style: bodyText(
                                        13,
                                        color: SkyColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (progress != null)
                                Text(
                                  goal.earned
                                      ? 'EARNED'
                                      : '${goal.displayed}/${goal.goal.target}',
                                  style: bodyText(
                                    12,
                                    weight: FontWeight.w900,
                                    color: goal.earned
                                        ? SkyColors.teal
                                        : SkyColors.muted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  },
);

class FlightGoalHud extends StatelessWidget {
  const FlightGoalHud({
    super.key,
    required this.goals,
    required this.celebrating,
    required this.reducedMotion,
  });
  final List<FlightGoalProgress> goals;
  final bool celebrating, reducedMotion;
  @override
  Widget build(BuildContext context) {
    final count = FlightGoals.earned(goals);
    return TweenAnimationBuilder<double>(
      key: ValueKey(count),
      tween: Tween(begin: count > 0 && !reducedMotion ? 1.1 : 1, end: 1),
      duration: reducedMotion
          ? Duration.zero
          : const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: SkyColors.cream,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FlightWings(goals: goals, size: 22),
            const SizedBox(height: 2),
            Text(
              celebrating ? 'Wing earned!' : '$count/3 flight wings',
              style: bodyText(11, weight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}
