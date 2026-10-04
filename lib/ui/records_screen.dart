import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/providers.dart';
import '../domain/tracking.dart';
import '../domain/flight_course.dart';
import '../domain/flight_goals.dart';
import '../domain/tether.dart';
import 'campaign_screen.dart' show campaignStarsInBuild;
import 'campaign_chrome.dart' show MapGlyph, MapKey;
import 'components.dart';
import 'mini_games.dart' show miniGameModes;
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
                    MapKey(
                      glyph: MapGlyph.back,
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
                                    const SizedBox(height: 8),
                                    // The main game leads; the mini games
                                    // keep their own, smaller bests.
                                    _section('Main game'),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _best(
                                            'Endless · Tap & Fly',
                                            p
                                                .record(PlayMode.touch, course)
                                                .best,
                                            SkyColors.yellow,
                                            key: const ValueKey(
                                              'record-endless',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _best(
                                            'Campaign stars\nof $campaignStarsInBuild',
                                            p.campaign.totalStars,
                                            SkyColors.mint,
                                            key: const ValueKey(
                                              'record-campaign',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    _section('Mini games'),
                                    Row(
                                      children: [
                                        for (final mode in miniGameModes) ...[
                                          if (mode != miniGameModes.first)
                                            const SizedBox(width: 8),
                                          Expanded(
                                            child: _best(
                                              mode.title,
                                              p.record(mode, course).best,
                                              switch (mode) {
                                                PlayMode.squat =>
                                                  SkyColors.coral,
                                                PlayMode.jump =>
                                                  SkyColors.lavender,
                                                _ => SkyColors.sand,
                                              },
                                              compact: true,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Fly Together keeps a team best for
                                    // each team mode, apart from the solo
                                    // ones. Duels only count.
                                    Row(
                                      children: [
                                        for (final mode
                                            in CoopMode.values.where(
                                              (m) => m.team,
                                            )) ...[
                                          if (mode != CoopMode.values.first)
                                            const SizedBox(width: 8),
                                          Expanded(
                                            child: _best(
                                              'Fly Together · ${mode.title}',
                                              p.coop.record(mode).best,
                                              mode == CoopMode.roped
                                                  ? SkyColors.mint
                                                  : SkyColors.skyDeep,
                                              compact: true,
                                              key: ValueKey(
                                                'coop-record-${mode.name}',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${p.totalRuns} scored flights  ·  ${p.totalObstacles} gates'
                                      '${p.coop.flights > p.coop.duels ? '  ·  ${p.coop.flights - p.coop.duels} together' : ''}'
                                      '${p.coop.duels > 0 ? '  ·  ${p.coop.duels} duels' : ''}'
                                      '\n${p.totalRepetitions} push-ups · ${p.totalSquats} squats',
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

  /// A small heading over a group of bests.
  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      title.toUpperCase(),
      style: bodyText(
        10.5,
        color: SkyColors.muted,
        weight: FontWeight.w900,
      ).copyWith(letterSpacing: 1.2, height: 1.1),
    ),
  );

  /// A best score on a coloured tile; [compact] for the mini games, under
  /// the main game's.
  Widget _best(
    String name,
    int best,
    Color color, {
    Key? key,
    bool compact = false,
  }) => Container(
    key: key,
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: compact ? 5 : 8),
    decoration: BoxDecoration(
      color: compact ? Color.lerp(color, SkyColors.cream, .35) : color,
      borderRadius: BorderRadius.circular(compact ? 14 : 18),
    ),
    child: Row(
      children: [
        Text('$best', style: heading(compact ? 26 : 38)),
        SizedBox(width: compact ? 6 : 10),
        Expanded(
          child: Text(
            name,
            style: bodyText(compact ? 11.5 : 14, weight: FontWeight.w900),
          ),
        ),
      ],
    ),
  );
}
