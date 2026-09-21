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
  static const course = FlightCourse.starTrail;
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
                                      'Your star points to beat',
                                      style: heading(25),
                                    ),
                                    const SizedBox(height: 20),
                                    for (final modes in [
                                      [PlayMode.pushUp, PlayMode.jump],
                                      [PlayMode.touch, PlayMode.squat],
                                    ]) ...[
                                      Row(
                                        children: [
                                          for (
                                            var i = 0;
                                            i < modes.length;
                                            i++
                                          ) ...[
                                            if (i > 0)
                                              const SizedBox(width: 12),
                                            Expanded(
                                              child: _best(
                                                modes[i].title,
                                                p.record(modes[i], course).best,
                                                switch (modes[i]) {
                                                  PlayMode.pushUp =>
                                                    SkyColors.yellow,
                                                  PlayMode.jump =>
                                                    SkyColors.coral,
                                                  PlayMode.touch =>
                                                    SkyColors.mint,
                                                  PlayMode.squat =>
                                                    SkyColors.lavender,
                                                },
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                    const Spacer(),
                                    Text(
                                      '${p.totalRuns} scored flights  ·  ${p.totalObstacles} gates\n${p.totalRepetitions} push-ups · ${p.totalSquats} squats',
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
                                                                .accessibility_new_rounded,
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
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Text('$best', style: heading(38)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(name, style: bodyText(14, weight: FontWeight.w900)),
        ),
      ],
    ),
  );
}
