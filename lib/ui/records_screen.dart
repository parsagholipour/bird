import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/providers.dart';
import '../domain/tracking.dart';
import 'components.dart';
import 'theme.dart';

class RecordsScreen extends ConsumerWidget {
  const RecordsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    const Pill(
                      'PERSONAL BESTS',
                      icon: Icons.emoji_events_rounded,
                      color: SkyColors.yellow,
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
                                      'The score to beat',
                                      style: heading(25),
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _best(
                                            'Push-Up Flight',
                                            p.pushUp.best,
                                            SkyColors.yellow,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: _best(
                                            'Grin & Glide',
                                            p.smile.best,
                                            SkyColors.coral,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${p.totalRuns} scored flights  ·  ${p.totalObstacles} obstacles\n${p.pushUp.repetitions} completed push-ups',
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
                                    Text('Recent flights', style: heading(25)),
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
                                                      r.mode == PlayMode.pushUp
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
                                                            r.mode ==
                                                                    PlayMode
                                                                        .pushUp
                                                                ? 'Push-Up Flight'
                                                                : 'Grin & Glide',
                                                            style: bodyText(
                                                              15,
                                                              weight: FontWeight
                                                                  .w800,
                                                            ),
                                                          ),
                                                          Text(
                                                            '${r.finishedAt.day}/${r.finishedAt.month} · ${r.durationSeconds.round()} sec',
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
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        Text('$best', style: heading(58)),
        Text(name, style: bodyText(14, weight: FontWeight.w900)),
      ],
    ),
  );
}
