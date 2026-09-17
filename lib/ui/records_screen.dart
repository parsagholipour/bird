import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/providers.dart';
import '../domain/tracking.dart';
import '../domain/flight_course.dart';
import '../domain/flight_goals.dart';
import 'components.dart';
import 'theme.dart';
import 'flight_goals.dart';

class RecordsScreen extends ConsumerStatefulWidget {
  const RecordsScreen({super.key});
  @override
  ConsumerState<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends ConsumerState<RecordsScreen> {
  FlightCourse course = FlightCourse.classic;
  @override
  Widget build(BuildContext context) {
    final p = ref.watch(progressProvider).asData?.value;
    return Scaffold(
      body: SkyBackdrop(
        child: SceneLayout(
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              children: [
                Row(
                  children: [
                    RoundButton(
                      icon: Icons.arrow_back_rounded,
                      label: 'Back home',
                      onPressed: () => context.go('/'),
                    ),
                    const SizedBox(width: 18),
                    Text('Your little victories.', style: heading(36)),
                    const Spacer(),
                    SegmentedButton<FlightCourse>(
                      segments: [
                        for (final item in FlightCourse.values.where(
                          (c) => !c.relaxed,
                        ))
                          ButtonSegment(
                            value: item,
                            label: Text(item.shortTitle),
                            icon: Icon(
                              item == FlightCourse.classic
                                  ? Icons.all_inclusive
                                  : item == FlightCourse.skyCourier
                                  ? Icons.local_post_office_outlined
                                  : Icons.star_rounded,
                            ),
                          ),
                      ],
                      selected: {course},
                      onSelectionChanged: (value) =>
                          setState(() => course = value.single),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Expanded(
                  child: p == null
                      ? const Center(child: CircularProgressIndicator())
                      : Row(
                          children: [
                            Expanded(
                              child: Panel(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      course == FlightCourse.classic
                                          ? 'The score to beat'
                                          : course == FlightCourse.skyCourier
                                          ? 'Your deliveries to beat'
                                          : 'Your star points to beat',
                                      style: heading(25),
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _best(
                                            'Push-Up Flight',
                                            p
                                                .record(PlayMode.pushUp, course)
                                                .best,
                                            SkyColors.yellow,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: _best(
                                            'Grin & Glide',
                                            p
                                                .record(PlayMode.smile, course)
                                                .best,
                                            SkyColors.coral,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _best(
                                            'Tap & Fly',
                                            p
                                                .record(PlayMode.touch, course)
                                                .best,
                                            SkyColors.mint,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${p.totalRuns} scored flights  ·  ${p.totalObstacles} gates\n${p.totalRepetitions} completed push-ups',
                                      style: bodyText(
                                        16,
                                        color: SkyColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 22),
                            Expanded(
                              child: Panel(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Recent flights',
                                          style: heading(25),
                                        ),
                                        const Spacer(),
                                        TextButton.icon(
                                          onPressed: () =>
                                              context.go('/sessions'),
                                          icon: const Icon(
                                            Icons.video_library_outlined,
                                          ),
                                          label: const Text('Saved sessions'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Expanded(
                                      child: p.recent.isEmpty
                                          ? Center(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const BirdArt(
                                                    size: 110,
                                                    bob: false,
                                                  ),
                                                  Text(
                                                    'A big sky. A clean slate.',
                                                    style: heading(20),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Your first scored flight starts the story.',
                                                    style: bodyText(
                                                      13,
                                                      color: SkyColors.muted,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : ListView.separated(
                                              itemCount: p.recent.length,
                                              separatorBuilder: (_, _) =>
                                                  const Divider(height: 12),
                                              itemBuilder: (context, i) {
                                                final r = p.recent[i];
                                                return Row(
                                                  children: [
                                                    Icon(
                                                      r.mode == PlayMode.touch
                                                          ? Icons
                                                                .touch_app_rounded
                                                          : r.mode ==
                                                                PlayMode.pushUp
                                                          ? Icons
                                                                .fitness_center_rounded
                                                          : Icons
                                                                .sentiment_satisfied_alt_rounded,
                                                      color: SkyColors.muted,
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            r.mode.title,
                                                            style: bodyText(
                                                              15,
                                                              weight: FontWeight
                                                                  .w800,
                                                            ),
                                                          ),
                                                          Text(
                                                            '${r.course.title} · ${r.finishedAt.day}/${r.finishedAt.month} · ${r.durationSeconds.round()} sec',
                                                            style: bodyText(
                                                              12,
                                                              color: SkyColors
                                                                  .muted,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Text(
                                                      '${r.score}',
                                                      style: heading(28),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    IconButton(
                                                      tooltip:
                                                          'View ${r.course.title} flight goals',
                                                      onPressed: () =>
                                                          showFlightGoals(
                                                            context,
                                                            r.course,
                                                            progress:
                                                                FlightGoals.forRun(
                                                                  r,
                                                                ),
                                                          ),
                                                      icon: FlightWings(
                                                        goals:
                                                            FlightGoals.forRun(
                                                              r,
                                                            ),
                                                        size: 15,
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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

  Widget _best(String name, int best, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        Text('$best', style: heading(58)),
        Text(
          name,
          textAlign: TextAlign.center,
          style: bodyText(14, weight: FontWeight.w900),
        ),
      ],
    ),
  );
}
