import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/providers.dart';
import '../data/progress_repository.dart';
import '../domain/daily_adventure.dart';
import '../domain/game_rules.dart';
import 'components.dart';
import 'control_glyphs.dart';
import 'home_keys.dart';
import 'mini_chrome.dart';
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
        MiniHeader(
          title: 'Today’s little adventure.',
          size: 34,
          onBack: () => context.go('/'),
          trailing: [
            MiniTag(
              '${today.date.day} ${months[today.date.month - 1]} · ${today.completedGoals}/3 GOALS',
              icon: Icons.wb_sunny_rounded,
              color: SkyColors.yellow,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 64),
          child: Text(
            'Three goals. Any control. Fly Star Trail to work on all three.',
            style: bodyText(15, weight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 236,
                child: Column(
                  children: [
                    Expanded(
                      child: _Postcard(adventure: today, settings: p.settings),
                    ),
                    const SizedBox(height: 8),
                    _WeekCards(adventures: p.adventures, today: today.dayKey),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    for (var i = 0; i < today.goals.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      Expanded(
                        child: _GoalRow(goal: today.goals[i], index: i),
                      ),
                    ],
                    const SizedBox(height: 12),
                    // The main game's Endless first, then the mini games.
                    SizedBox(
                      height: 58,
                      child: Row(
                        children: [
                          for (final (i, (label, mode, control)) in [
                            ('Endless', 'touch', FlyControl.tap),
                            ('Push-Up Flight', 'push-up', FlyControl.pushUp),
                            ('Squat & Fly', 'squat', FlyControl.squat),
                            ('Jump & Fly', 'jump', FlyControl.jump),
                          ].indexed) ...[
                            if (i > 0) const SizedBox(width: 8),
                            Expanded(
                              flex: i == 0 ? 5 : 6,
                              child: _LaunchKey(
                                label: label,
                                control: control,
                                main: i == 0,
                                onPressed: () => fly(mode),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Today's postcard: the bird on a wash of the day's color, a postage
/// stamp in the corner, the day's title and how far along the card is,
/// with the week's cards along the bottom.
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
    return MiniCard(
      accent: adventure.complete ? SkyColors.teal : tint,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Expanded(
            child: MiniArtBand(
              color: tint,
              child: Stack(
                children: [
                  Positioned(
                    left: 12,
                    top: 10,
                    child: Text(
                      'SKY CLUB POSTCARD',
                      style: bodyText(
                        10,
                        weight: FontWeight.w900,
                      ).copyWith(letterSpacing: 1),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 8,
                    child: _CornerStamp(done: adventure.complete),
                  ),
                  Positioned.fill(
                    top: 28,
                    child: Center(
                      child: FittedBox(
                        child: BirdArt(
                          bird: settings.bird,
                          size: 120,
                          reducedMotion: settings.reducedMotion,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              adventure.title,
              style: heading(23, weight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Pill(
            adventure.complete
                ? 'POSTCARD STAMPED!'
                : '${adventure.completedGoals} / 3 GOALS COMPLETE',
            icon: adventure.complete
                ? Icons.check_rounded
                : Icons.auto_awesome_rounded,
            color: adventure.complete ? SkyColors.mint : SkyColors.white,
          ),
          const SizedBox(height: 8),
          Text(
            adventure.complete
                ? 'A small adventure, all yours.'
                : 'Finish all three to stamp this card.',
            style: bodyText(
              11.5,
              color: SkyColors.muted,
              weight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

/// The postcard's postage: a little perforated stamp that turns into a
/// franked check once the card is done.
class _CornerStamp extends StatelessWidget {
  const _CornerStamp({required this.done});
  final bool done;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: .08,
    child: Container(
      width: 34,
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: SkyColors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: SkyColors.ink, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: SkyColors.ink.withValues(alpha: .25),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: done ? SkyColors.mint : SkyColors.cream,
          borderRadius: BorderRadius.circular(2),
        ),
        child: Icon(
          done ? Icons.verified_rounded : Icons.local_post_office_rounded,
          size: 18,
          color: SkyColors.ink,
        ),
      ),
    ),
  );
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
      DailyTask.gates => Icons.flag_rounded,
      DailyTask.stars => Icons.star_rounded,
      DailyTask.streak => Icons.auto_awesome_rounded,
      DailyTask.perfects => Icons.center_focus_strong_rounded,
      DailyTask.finishTrail => Icons.route_rounded,
    };
    return Semantics(
      label:
          '${goal.description} ${goal.complete ? 'Complete' : '${goal.displayed} of ${goal.target}'}',
      child: Container(
        margin: const EdgeInsets.only(bottom: 3),
        padding: const EdgeInsets.fromLTRB(10, 6, 14, 8),
        decoration: BoxDecoration(
          color: goal.complete
              ? Color.lerp(SkyColors.cream, SkyColors.mint, .5)
              : SkyColors.cream,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: SkyColors.ink, width: 2),
          boxShadow: [
            BoxShadow(
              color: Color.lerp(
                goal.complete ? SkyColors.teal : color,
                SkyColors.ink,
                .4,
              )!,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            MiniCoin(
              icon: goal.complete ? Icons.check_rounded : icon,
              color: goal.complete ? SkyColors.mint : color,
              size: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          goal.title,
                          style: heading(19, weight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        '${goal.displayed}/${goal.target}',
                        style: heading(19, weight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    goal.description,
                    style: bodyText(12, color: SkyColors.muted),
                  ),
                  const SizedBox(height: 5),
                  MiniMeter(
                    value: goal.fraction,
                    color: goal.complete ? SkyColors.teal : color,
                    height: 10,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A way into a flight: the control's pictogram and its name on a key. The
/// main game's Endless is the sun key, as on the title screen; the mini
/// games share the quieter lavender of the Mini games key.
class _LaunchKey extends StatelessWidget {
  const _LaunchKey({
    required this.label,
    required this.control,
    required this.main,
    required this.onPressed,
  });
  final String label;
  final FlyControl control;
  final bool main;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => HomeKey(
    label: label,
    colors: main ? HomeKeyColors.sun : HomeKeyColors.lavender,
    lip: 6,
    radius: 18,
    onPressed: onPressed,
    builder: (context, _) => Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ControlGlyph(control, size: 32),
              const SizedBox(width: 7),
              Text(
                label,
                style: heading(17, weight: FontWeight.w700).copyWith(
                  height: 1,
                  shadows: const [
                    Shadow(color: SkyColors.cream, offset: Offset(0, 1.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// The week's postcards as a row of little coins, today's ringed in gold,
/// and a promise that a missed day costs nothing.
class _WeekCards extends StatelessWidget {
  const _WeekCards({required this.adventures, required this.today});
  final List<DailyAdventure> adventures;
  final String today;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final card in adventures)
            Tooltip(
              message:
                  '${card.dayKey}: ${card.complete ? 'Postcard stamped' : '${card.completedGoals}/3 goals'}',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: card.complete
                          ? SkyColors.mint
                          : card.dayKey == today
                          ? SkyColors.yellow
                          : SkyColors.cream,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: card.complete || card.dayKey == today
                            ? SkyColors.ink
                            : SkyColors.ink.withValues(alpha: .4),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      card.complete
                          ? Icons.check_rounded
                          : Icons.local_post_office_rounded,
                      size: 15,
                      color: card.complete || card.dayKey == today
                          ? SkyColors.ink
                          : SkyColors.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    const [
                      'M',
                      'T',
                      'W',
                      'T',
                      'F',
                      'S',
                      'S',
                    ][card.date.weekday - 1],
                    style: bodyText(
                      10,
                      weight: FontWeight.w900,
                    ).copyWith(height: 1.1),
                  ),
                ],
              ),
            ),
        ],
      ),
      const SizedBox(height: 3),
      Text(
        'Fresh goals. No streak to lose.',
        style: bodyText(11.5, weight: FontWeight.w800).copyWith(height: 1.1),
      ),
    ],
  );
}
