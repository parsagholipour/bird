import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/providers.dart';
import '../data/progress_repository.dart';
import '../domain/game_rules.dart';
import '../domain/tracking.dart';
import '../data/passport_progress.dart';
import 'components.dart';
import 'theme.dart';
import 'flight_goals.dart';
import 'course_preview.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(progressProvider);
    final course = ref.watch(selectedCourseProvider);
    return Scaffold(
      body: SkyBackdrop(
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Panel(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Your nest needs a moment.', style: heading(28)),
                  const SizedBox(height: 16),
                  SkyButton(
                    label: 'Try again',
                    onPressed: () => ref.invalidate(progressProvider),
                  ),
                ],
              ),
            ),
          ),
          data: (p) => SceneLayout(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(30, 24, 30, 16),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 355,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.wb_sunny_rounded,
                                    size: 16,
                                    color: SkyColors.ink,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'THE SKY CLUB  /  ADVENTURE AWAITS',
                                    style: bodyText(
                                      12,
                                      weight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'PUSH-UP\nBIRD',
                                      style: heading(
                                        64,
                                        color: SkyColors.white,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'PUSH-UP\nBIRD',
                                    style: heading(64, weight: FontWeight.w700),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'A little effort. A lot of airtime.',
                                style: bodyText(16),
                              ),
                              Expanded(
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Positioned(
                                      left: 0,
                                      top: 0,
                                      child: CoursePreview(
                                        course: course,
                                        bird: p.settings.bird,
                                        reducedMotion: p.settings.reducedMotion,
                                      ),
                                    ),
                                    Positioned(
                                      left: 218,
                                      top: 0,
                                      child: SizedBox(
                                        width: 137,
                                        child: SkyButton(
                                          label: 'Tap & Fly',
                                          icon: Icons.touch_app_rounded,
                                          compact: true,
                                          color: SkyColors.mint,
                                          onPressed: () => context.go(
                                            '/play/touch?course=${course.name}',
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 218,
                                      top: 60,
                                      child: SizedBox(
                                        width: 137,
                                        child: SkyButton(
                                          label: 'Flight school',
                                          icon: null,
                                          compact: true,
                                          color: SkyColors.cream,
                                          onPressed: () => context.go(
                                            '/school?course=${course.name}',
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 242,
                                      top: 120,
                                      child: Transform.rotate(
                                        angle: .12,
                                        child: Semantics(
                                          button: true,
                                          label:
                                              'Today’s adventure. ${p.today?.completedGoals ?? 0} of 3 goals complete.',
                                          child: InkWell(
                                            key: const ValueKey(
                                              'daily-adventure',
                                            ),
                                            onTap: () => context.go('/daily'),
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                            child: SizedBox(
                                              height: 48,
                                              child: Center(
                                                child: Pill(
                                                  p.today?.complete == true
                                                      ? 'CARD STAMPED!'
                                                      : 'TODAY ${p.today?.completedGoals ?? 0}/3',
                                                  icon:
                                                      p.today?.complete == true
                                                      ? Icons.verified_rounded
                                                      : Icons.wb_sunny_outlined,
                                                  color:
                                                      p.today?.complete == true
                                                      ? SkyColors.mint
                                                      : SkyColors.yellow,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 30),
                        Expanded(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  for (final item in FlightCourse.values) ...[
                                    Expanded(
                                      child: Semantics(
                                        selected: course == item,
                                        child: InkWell(
                                          key: ValueKey('course-${item.name}'),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          onTap: () => ref
                                              .read(
                                                selectedCourseProvider.notifier,
                                              )
                                              .select(item),
                                          child: AnimatedContainer(
                                            duration: Duration(
                                              milliseconds:
                                                  p.settings.reducedMotion
                                                  ? 0
                                                  : 180,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: course == item
                                                  ? SkyColors.ink
                                                  : SkyColors.white.withValues(
                                                      alpha: .5,
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    item.relaxed
                                                        ? Icons.spa_outlined
                                                        : item ==
                                                              FlightCourse
                                                                  .skyCourier
                                                        ? Icons
                                                              .local_post_office_outlined
                                                        : item ==
                                                              FlightCourse
                                                                  .classic
                                                        ? Icons
                                                              .all_inclusive_rounded
                                                        : Icons
                                                              .auto_awesome_rounded,
                                                    size: 18,
                                                    color: course == item
                                                        ? SkyColors.yellow
                                                        : SkyColors.ink,
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    item.shortTitle,
                                                    style: bodyText(
                                                      14,
                                                      color: course == item
                                                          ? SkyColors.white
                                                          : SkyColors.ink,
                                                      weight: FontWeight.w900,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (item != FlightCourse.values.last)
                                      const SizedBox(width: 8),
                                  ],
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Text(
                                  course.subtitle,
                                  style: bodyText(13, color: SkyColors.muted),
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _ModeCard(
                                        pushUp: true,
                                        best: p
                                            .record(PlayMode.pushUp, course)
                                            .best,
                                        course: course,
                                        reducedMotion: p.settings.reducedMotion,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _ModeCard(
                                        pushUp: false,
                                        best: p
                                            .record(PlayMode.smile, course)
                                            .best,
                                        course: course,
                                        reducedMotion: p.settings.reducedMotion,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      InkWell(
                        onTap: () => context.go('/birds'),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          child: Row(
                            children: [
                              const Icon(Icons.flutter_dash_rounded, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                'YOUR FLOCK  ${p.unlocked.length}/4',
                                style: bodyText(12, weight: FontWeight.w900),
                              ),
                              const SizedBox(width: 14),
                              SizedBox(
                                width: 100,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(9),
                                  child: LinearProgressIndicator(
                                    value: p.nextBird == null
                                        ? 1
                                        : p.totalObstacles /
                                              unlockThresholds[p.nextBird!],
                                    minHeight: 8,
                                    backgroundColor: SkyColors.white,
                                    valueColor: const AlwaysStoppedAnimation(
                                      SkyColors.coral,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                p.nextBird == null
                                    ? 'The whole crew is here!'
                                    : '${unlockThresholds[p.nextBird!] - p.totalObstacles} to your next bird',
                                style: bodyText(12),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => context.go('/passport'),
                        icon: const Icon(
                          Icons.workspace_premium_outlined,
                          size: 20,
                        ),
                        label: Text(
                          'Passport ${p.earnedStamps}/8',
                          style: bodyText(13, weight: FontWeight.w900),
                        ),
                      ),
                      if (!course.relaxed)
                        TextButton.icon(
                          onPressed: () => showFlightGoals(context, course),
                          icon: const WingBadge(earned: true, size: 20),
                          label: Text(
                            'Flight goals',
                            style: bodyText(14, weight: FontWeight.w900),
                          ),
                        ),
                      TextButton.icon(
                        onPressed: () => context.go('/birds'),
                        icon: const Icon(Icons.grid_view_rounded, size: 19),
                        label: Text(
                          'Birds',
                          style: bodyText(14, weight: FontWeight.w900),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => context.go('/records'),
                        icon: const Icon(Icons.emoji_events_outlined, size: 20),
                        label: Text(
                          'Records',
                          style: bodyText(14, weight: FontWeight.w900),
                        ),
                      ),
                      RoundButton(
                        icon: Icons.tune_rounded,
                        label: 'Settings',
                        onPressed: () => context.go('/settings'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.pushUp,
    required this.best,
    required this.reducedMotion,
    required this.course,
  });
  final bool pushUp, reducedMotion;
  final int best;
  final FlightCourse course;
  @override
  Widget build(BuildContext context) => Panel(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: pushUp ? SkyColors.yellow : SkyColors.coral,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              BirdArt(
                bird: pushUp ? 0 : 1,
                size: 84,
                reducedMotion: reducedMotion,
              ),
              const Spacer(),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    course.relaxed
                        ? Icons.spa_outlined
                        : Icons.emoji_events_outlined,
                    size: 20,
                  ),
                  Text(
                    course.relaxed ? 'NO LIMITS' : 'BEST  $best',
                    style: bodyText(13, weight: FontWeight.w900),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          pushUp ? 'MOVE YOUR BODY' : 'FIND YOUR SMILE',
          style: bodyText(11, color: SkyColors.muted, weight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(pushUp ? 'Push-Up Flight' : 'Grin & Glide', style: heading(24)),
        const SizedBox(height: 3),
        Text(
          pushUp
              ? 'Push up to rise.\nLower to glide.'
              : 'One smile, one flap.\nRelax. Repeat.',
          style: bodyText(14, color: SkyColors.muted),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: SkyButton(
            label: course.relaxed
                ? 'Just drift'
                : course == FlightCourse.starTrail
                ? 'Chase the stars'
                : course == FlightCourse.skyCourier
                ? 'Deliver some joy'
                : 'Let’s fly',
            compact: true,
            color: pushUp ? SkyColors.coral : SkyColors.yellow,
            onPressed: () => context.go(
              '/play/${pushUp ? 'push-up' : 'smile'}?course=${course.name}',
            ),
          ),
        ),
        const SizedBox(height: 3),
        if (course.relaxed)
          const SizedBox(
            height: 48,
            child: Center(child: Text('Pause whenever you like')),
          )
        else
          Center(
            child: TextButton(
              onPressed: () => context.go(
                '/play/${pushUp ? 'push-up' : 'smile'}?practice=true&course=${course.name}',
              ),
              style: TextButton.styleFrom(
                minimumSize: const Size(120, 32),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(
                'Try a practice flight',
                style: bodyText(12, color: SkyColors.muted),
              ),
            ),
          ),
      ],
    ),
  );
}
