import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/progress_repository.dart';
import '../data/providers.dart';
import '../domain/game_rules.dart' show RunResult;
import '../domain/tracking.dart';
import '../domain/flight_course.dart';
import '../domain/tether.dart';
import '../game/star_art.dart';
import '../l10n/l10n.dart';
import '../l10n/text/date_text.dart';
import '../l10n/text/replay_text.dart';
import 'campaign_screen.dart' show campaignStarsInBuild;
import 'components.dart';
import 'control_glyphs.dart';
import 'fit_text.dart';
import 'match_hud.dart' show MatchPlate;
import 'mini_chrome.dart';
import 'mini_games.dart' show miniGameModes;
import 'theme.dart';

/// The pictogram a flight with [mode] is steered by.
FlyControl _control(PlayMode mode) => switch (mode) {
  PlayMode.touch => FlyControl.tap,
  PlayMode.pushUp => FlyControl.pushUp,
  PlayMode.squat => FlyControl.squat,
  PlayMode.jump => FlyControl.jump,
};

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
    final l = context.l10n;
    return Scaffold(
      body: SkyBackdrop(
        child: SceneLayout(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(26, 22, 26, 18),
            child: Column(
              children: [
                MiniHeader(
                  title: l.recordsTitle,
                  size: 34,
                  onBack: () => context.go('/'),
                  trailing: [
                    MiniPillKey(
                      icon: Icons.video_library_rounded,
                      label: l.replaySavedSessions,
                      onPressed: () => context.go('/sessions'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: p == null
                      ? const Center(child: CircularProgressIndicator())
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 11, child: _bests(l, p)),
                            const SizedBox(width: 20),
                            Expanded(flex: 10, child: _recent(l, p)),
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

  Widget _bests(AppLocalizations l, ProgressSnapshot p) => MiniCard(
    accent: SkyColors.yellow,
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const MiniCoin(
              icon: Icons.emoji_events_rounded,
              color: SkyColors.yellow,
              size: 32,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FitText(
                l.recordsBestsTitle,
                style: heading(22, weight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // The main game leads; the mini games keep their own, smaller
        // bests.
        _section(l.recordsSectionMain),
        Row(
          children: [
            Expanded(
              child: _BestTile(
                key: const ValueKey('record-endless'),
                name: l.recordsEndless,
                best: p.record(PlayMode.touch, course).best,
                color: SkyColors.yellow,
                badge: const _StarCoin(size: 34),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _BestTile(
                key: const ValueKey('record-campaign'),
                name: l.recordsCampaignStars,
                best: p.campaign.totalStars,
                of: campaignStarsInBuild,
                color: SkyColors.mint,
                badge: const MiniCoin(
                  icon: Icons.map_rounded,
                  color: SkyColors.mint,
                  size: 34,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _section(l.recordsSectionMini),
        Row(
          children: [
            for (final mode in miniGameModes) ...[
              if (mode != miniGameModes.first) const SizedBox(width: 8),
              Expanded(
                child: _BestTile(
                  name: l.playModeName(mode),
                  best: p.record(mode, course).best,
                  color: miniColor(mode),
                  badge: ControlGlyph(_control(mode), size: 28),
                  compact: true,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        // Fly Together keeps a team best for each team mode, apart from the
        // solo ones. Duels only count.
        Row(
          children: [
            for (final mode in CoopMode.values.where((m) => m.team)) ...[
              if (mode != CoopMode.values.first) const SizedBox(width: 8),
              Expanded(
                child: _BestTile(
                  name: l.flyTogetherName(mode),
                  best: p.coop.record(mode).best,
                  color: mode == CoopMode.roped
                      ? SkyColors.mint
                      : SkyColors.skyDeep,
                  badge: MiniCoin(
                    icon: mode == CoopMode.roped
                        ? Icons.link_rounded
                        : Icons.people_alt_rounded,
                    color: mode == CoopMode.roped
                        ? SkyColors.mint
                        : SkyColors.skyDeep,
                    size: 28,
                  ),
                  compact: true,
                  key: ValueKey('coop-record-${mode.name}'),
                ),
              ),
            ],
          ],
        ),
        const Spacer(),
        // Lifetime totals, as a row of small plates.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Row(
            children: [
              for (final (i, (value, label)) in [
                (p.totalRuns, l.recordsTotalFlights),
                (p.totalObstacles, l.recordsTotalGates),
                if (p.coop.flights > p.coop.duels)
                  (p.coop.flights - p.coop.duels, l.recordsTotalTogether),
                if (p.coop.duels > 0) (p.coop.duels, l.recordsTotalDuels),
                (p.totalRepetitions, l.recordsTotalPushUps),
                (p.totalSquats, l.recordsTotalSquats),
              ].indexed) ...[
                if (i > 0) const SizedBox(width: 8),
                _Total(value: l.formatCount(value), label: label(value)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
      ],
    ),
  );

  Widget _recent(AppLocalizations l, ProgressSnapshot p) => MiniCard(
    accent: SkyColors.lavender,
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const MiniCoin(
              icon: Icons.history_rounded,
              color: SkyColors.lavender,
              size: 32,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FitText(
                l.recordsRecentTitle,
                style: heading(22, weight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: p.recent.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const BirdArt(size: 110, bob: false),
                      Text(
                        l.recordsEmptyTitle,
                        style: heading(20),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l.recordsEmptyBody,
                        textAlign: TextAlign.center,
                        style: bodyText(13, color: SkyColors.muted),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 14),
                  itemCount: p.recent.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _FlightSlip(run: p.recent[i]),
                ),
        ),
      ],
    ),
  );

  /// A small heading over a group of bests.
  Widget _section(String title) => Padding(
    padding: const EdgeInsetsDirectional.only(start: 2, bottom: 5),
    child: Text(
      title,
      style: bodyText(
        11,
        weight: FontWeight.w900,
      ).copyWith(letterSpacing: 1.2, height: 1.1),
    ),
  );
}

/// A best on a colored sticker tile: what it is for, the score under it and
/// a coin or pictogram beside. [compact] for the mini games, under the main
/// game's. [of] adds the most there is to earn.
class _BestTile extends StatelessWidget {
  const _BestTile({
    super.key,
    required this.name,
    required this.best,
    required this.color,
    required this.badge,
    this.of,
    this.compact = false,
  });
  final String name;
  final int best;
  final int? of;
  final Color color;
  final Widget badge;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 3),
    padding: EdgeInsets.fromLTRB(8, compact ? 5 : 7, 8, compact ? 5 : 7),
    decoration: BoxDecoration(
      color: Color.lerp(SkyColors.cream, color, compact ? .5 : .75),
      borderRadius: BorderRadius.circular(compact ? 14 : 16),
      border: Border.all(color: SkyColors.ink, width: 2),
      boxShadow: [
        BoxShadow(
          color: Color.lerp(color, SkyColors.ink, .4)!,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      children: [
        badge,
        SizedBox(width: compact ? 6 : 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FitText(
                name,
                style: bodyText(
                  compact ? 11 : 13,
                  weight: FontWeight.w900,
                ).copyWith(height: 1.1),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$best',
                    style: heading(compact ? 22 : 32, weight: FontWeight.w700),
                  ),
                  if (of != null)
                    Text(
                      ' / $of',
                      style: bodyText(
                        14,
                        color: SkyColors.muted,
                        weight: FontWeight.w900,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// A lifetime total on a small plate: the number, then what it counts.
class _Total extends StatelessWidget {
  const _Total({required this.value, required this.label});

  /// The count, its thousands grouped the language's way.
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => MatchPlate(
    padding: const EdgeInsets.fromLTRB(10, 3, 12, 3),
    child: Text.rich(
      TextSpan(
        text: '$value ',
        style: heading(16, weight: FontWeight.w700),
        children: [
          TextSpan(
            text: label,
            style: bodyText(
              12,
              color: SkyColors.muted,
              weight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ),
  );
}

/// One recent flight on a paper slip: how it was steered, where and when,
/// and its score.
class _FlightSlip extends StatelessWidget {
  const _FlightSlip({required this.run});
  final RunResult run;

  @override
  Widget build(BuildContext context) {
    final r = run;
    final l = context.l10n;
    final date = l.dayMonthDigits(r.finishedAt);
    final seconds = r.durationSeconds.round();
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: BoxDecoration(
        color: SkyColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: SkyColors.ink.withValues(alpha: .25),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          ControlGlyph(_control(r.mode), size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.playModeName(r.mode),
                  style: bodyText(15, weight: FontWeight.w900),
                ),
                Text(
                  r.course == FlightCourse.classic
                      ? l.recordsSlipDetailClassic(date, seconds)
                      : l.recordsSlipDetail(date, seconds),
                  style: bodyText(12, color: SkyColors.muted),
                ),
              ],
            ),
          ),
          MatchPlate(
            color: SkyColors.yellow,
            padding: const EdgeInsets.fromLTRB(6, 2, 10, 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _StarCoin(size: 16),
                const SizedBox(width: 4),
                Text('${r.score}', style: heading(20, weight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The game's own star, inked, for a score.
class _StarCoin extends StatelessWidget {
  const _StarCoin({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: const _StarPainter());
}

class _StarPainter extends CustomPainter {
  const _StarPainter();

  @override
  void paint(Canvas canvas, Size size) => StarArt.mini(
    canvas,
    size.center(Offset.zero),
    size.shortestSide * .5,
    outline: size.shortestSide > 24 ? 2 : 1.2,
  );

  @override
  bool shouldRepaint(_StarPainter oldDelegate) => false;
}
