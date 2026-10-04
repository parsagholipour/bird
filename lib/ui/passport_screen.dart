import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/providers.dart';
import '../data/passport_progress.dart';
import '../domain/sky_passport.dart';
import 'campaign_chrome.dart' show MapGlyph, MapKey;
import 'components.dart';
import 'theme.dart';

class PassportScreen extends ConsumerWidget {
  const PassportScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider).asData?.value;
    return Scaffold(
      body: SkyBackdrop(
        child: SceneLayout(
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
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
                    Text('Your sky passport.', style: heading(36)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => context.go('/daily'),
                      icon: const Icon(Icons.wb_sunny_outlined),
                      label: Text(
                        'Daily card',
                        style: bodyText(13, weight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Pill(
                      '${progress?.earnedStamps ?? 0} / ${SkyStamp.values.length} STAMPS',
                      icon: Icons.workspace_premium_outlined,
                      color: SkyColors.yellow,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Small adventures. Lasting souvenirs. Earn stamps in scored flights.',
                  style: bodyText(14, color: SkyColors.muted),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: progress == null
                      ? const Center(child: CircularProgressIndicator())
                      : GridView.count(
                          crossAxisCount: 4,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.60,
                          children: [
                            for (final stamp in progress.passport)
                              _StampCard(progress: stamp),
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
}

class _StampCard extends StatelessWidget {
  const _StampCard({required this.progress});
  final StampProgress progress;
  @override
  Widget build(BuildContext context) {
    final stamp = progress.stamp;
    final icon = switch (stamp) {
      SkyStamp.firstWings => Icons.flight_takeoff_rounded,
      SkyStamp.onTheDot => Icons.center_focus_strong_rounded,
      SkyStamp.starChaser => Icons.star_rounded,
      SkyStamp.constellation => Icons.auto_awesome_rounded,
      SkyStamp.skyCaptain => Icons.explore_rounded,
      SkyStamp.trailblazer => Icons.route_rounded,
      SkyStamp.flockTogether => Icons.flutter_dash_rounded,
      SkyStamp.bothWings => Icons.favorite_rounded,
    };
    final accent = [
      SkyColors.yellow,
      SkyColors.mint,
      SkyColors.coral,
      SkyColors.lavender,
    ][stamp.index % 4];
    return Semantics(
      label:
          '${stamp.title}. ${stamp.description} ${progress.earned ? 'Earned' : '${progress.current} of ${stamp.target}'}',
      child: Panel(
        padding: const EdgeInsets.all(12),
        color: progress.earned
            ? Color.lerp(SkyColors.cream, accent, .18)!
            : SkyColors.cream,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: progress.earned
                        ? accent
                        : SkyColors.sky.withValues(alpha: .4),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 19,
                    color: progress.earned ? SkyColors.ink : SkyColors.muted,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(stamp.title, style: heading(18))),
                if (progress.earned)
                  const Icon(
                    Icons.verified_rounded,
                    size: 18,
                    color: SkyColors.teal,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              stamp.description,
              style: bodyText(11, color: SkyColors.muted),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress.fraction,
                      minHeight: 4,
                      backgroundColor: SkyColors.sky.withValues(alpha: .4),
                      valueColor: AlwaysStoppedAnimation(
                        progress.earned ? SkyColors.teal : accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  progress.earned
                      ? 'STAMPED'
                      : '${progress.current}/${stamp.target}',
                  style: bodyText(
                    10,
                    weight: FontWeight.w900,
                    color: progress.earned ? SkyColors.teal : SkyColors.muted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
