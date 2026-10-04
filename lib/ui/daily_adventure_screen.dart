import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/providers.dart';
import '../data/progress_repository.dart';
import '../domain/daily_adventure.dart';
import '../domain/game_rules.dart';
import 'campaign_chrome.dart' show MapGlyph, MapKey;
import 'components.dart';
import 'theme.dart';

class DailyAdventureScreen extends ConsumerWidget {
  const DailyAdventureScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    return Scaffold(
      body: SkyBackdrop(
        child: SceneLayout(
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: progress.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: Panel(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Your adventure needs a moment.',
                        style: heading(26),
                      ),
                      const SizedBox(height: 16),
                      SkyButton(
                        label: 'Try again',
                        onPressed: () => ref.invalidate(progressProvider),
                      ),
                    ],
                  ),
                ),
              ),
              data: (p) => _content(context, ref, p),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, WidgetRef ref, ProgressSnapshot p) {
    final today =
        p.today ??
        DailyAdventure.forDate(ref.read(appClockProvider)(), const []);
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    void fly(String control) {
      ref.read(selectedCourseProvider.notifier).select(FlightCourse.starTrail);
      context.go('/play/$control?course=starTrail');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            MapKey(
              glyph: MapGlyph.back,
              label: 'Back home',
              onPressed: () => context.go('/'),
            ),
            const SizedBox(width: 18),
            Text('Today’s little adventure.', style: heading(36)),
            const Spacer(),
            Pill(
              '${today.date.day} ${months[today.date.month - 1]} · ${today.completedGoals}/3 GOALS',
              icon: Icons.wb_sunny_outlined,
              color: SkyColors.yellow,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Three goals. Any control. Fly Star Trail to work on all three.',
          style: bodyText(14, color: SkyColors.muted),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 250,
                child: _Postcard(adventure: today, settings: p.settings),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: [
                    for (var i = 0; i < today.goals.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      Expanded(
                        child: _GoalRow(goal: today.goals[i], index: i),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _WeekCards(adventures: p.adventures),
                const SizedBox(height: 4),
                Text(
                  'Fresh goals. No streak to lose.',
                  style: bodyText(11, color: SkyColors.muted),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // The main game's Endless first, then the mini games.
            for (final (label, mode, icon, color) in [
              ('Endless', 'touch', Icons.touch_app_rounded, SkyColors.yellow),
              (
                'Push-Up Flight',
                'push-up',
                Icons.fitness_center_rounded,
                SkyColors.sand,
              ),
              (
                'Squat & Fly',
                'squat',
                Icons.airline_seat_legroom_extra_rounded,
                SkyColors.coral,
              ),
              (
                'Jump & Fly',
                'jump',
                Icons.accessibility_new_rounded,
                SkyColors.lavender,
              ),
            ]) ...[
              Expanded(
                child: SkyButton(
                  label: label,
                  compact: true,
                  icon: icon,
                  color: color,
                  onPressed: () => fly(mode),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }
}

class _Postcard extends StatelessWidget {
  const _Postcard({required this.adventure, required this.settings});
  final DailyAdventure adventure;
  final GameSettings settings;
  @override
  Widget build(BuildContext context) {
    final tint = [
      SkyColors.yellow,
      SkyColors.coral,
      SkyColors.lavender,
      SkyColors.sky,
      SkyColors.lavender,
      SkyColors.mint,
    ][adventure.theme];
    return Panel(
      color: Color.lerp(SkyColors.cream, tint, .25)!,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'SKY CLUB POSTCARD',
                style: bodyText(
                  10,
                  weight: FontWeight.w900,
                  color: SkyColors.muted,
                ),
              ),
              const Spacer(),
              Icon(
                adventure.complete
                    ? Icons.verified_rounded
                    : Icons.local_post_office_outlined,
                color: adventure.complete ? SkyColors.teal : SkyColors.muted,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            adventure.title,
            style: heading(26),
            textAlign: TextAlign.center,
          ),
          Expanded(
            child: Center(
              child: FittedBox(
                child: BirdArt(
                  bird: settings.bird,
                  size: 144,
                  reducedMotion: settings.reducedMotion,
                ),
              ),
            ),
          ),
          Transform.rotate(
            angle: -.06,
            child: Pill(
              adventure.complete
                  ? 'POSTCARD STAMPED!'
                  : '${adventure.completedGoals} / 3 GOALS COMPLETE',
              icon: adventure.complete
                  ? Icons.check_rounded
                  : Icons.auto_awesome_rounded,
              color: adventure.complete ? SkyColors.mint : tint,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            adventure.complete
                ? 'A small adventure, all yours.'
                : 'Finish all three to stamp this card.',
            style: bodyText(11, color: SkyColors.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.goal, required this.index});
  final DailyGoal goal;
  final int index;
  @override
  Widget build(BuildContext context) {
    final color = [SkyColors.yellow, SkyColors.lavender, SkyColors.mint][index];
    final icon = switch (goal.task) {
      DailyTask.flights => Icons.flight_takeoff_rounded,
      DailyTask.gates => Icons.flag_outlined,
      DailyTask.stars => Icons.star_rounded,
      DailyTask.streak => Icons.auto_awesome_rounded,
      DailyTask.perfects => Icons.center_focus_strong_rounded,
      DailyTask.finishTrail => Icons.route_rounded,
    };
    return Semantics(
      label:
          '${goal.description} ${goal.complete ? 'Complete' : '${goal.displayed} of ${goal.target}'}',
      child: Panel(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        color: goal.complete ? const Color(0xffedf6e5) : SkyColors.cream,
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      goal.complete ? Icons.check_rounded : icon,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(goal.title, style: heading(19)),
                        const SizedBox(height: 3),
                        Text(
                          goal.description,
                          style: bodyText(12, color: SkyColors.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${goal.displayed}/${goal.target}',
                    style: heading(
                      23,
                      color: goal.complete ? SkyColors.muted : SkyColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: goal.fraction,
                minHeight: 4,
                backgroundColor: SkyColors.sky.withValues(alpha: .4),
                valueColor: AlwaysStoppedAnimation(
                  goal.complete ? SkyColors.teal : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekCards extends StatelessWidget {
  const _WeekCards({required this.adventures});
  final List<DailyAdventure> adventures;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final card in adventures)
        Padding(
          padding: const EdgeInsets.only(right: 5),
          child: Tooltip(
            message:
                '${card.dayKey}: ${card.complete ? 'Postcard stamped' : '${card.completedGoals}/3 goals'}',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 27,
                  height: 27,
                  decoration: BoxDecoration(
                    color: card.complete
                        ? SkyColors.mint
                        : SkyColors.cream.withValues(alpha: .75),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    card.complete
                        ? Icons.verified_rounded
                        : Icons.local_post_office_outlined,
                    size: 17,
                    color: card.complete ? SkyColors.ink : SkyColors.muted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][card.date.weekday -
                      1],
                  style: bodyText(10),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}
