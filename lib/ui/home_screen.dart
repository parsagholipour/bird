import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/providers.dart';
import '../data/progress_repository.dart';
import 'components.dart';
import 'theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(progressProvider);
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
                          width: 390,
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
                                    'THE SKY CLUB  /  EST. TODAY',
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
                                      left: 25,
                                      top: 44,
                                      child: Image.asset(
                                        'assets/images/island.png',
                                        width: 265,
                                        height: 166,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    Positioned(
                                      left: 84,
                                      top: -8,
                                      child: BirdArt(
                                        bird: p.settings.bird,
                                        size: 175,
                                        reducedMotion: p.settings.reducedMotion,
                                      ),
                                    ),
                                    Positioned(
                                      left: 294,
                                      top: 35,
                                      child: Transform.rotate(
                                        angle: .12,
                                        child: const Pill(
                                          'LET’S FLY!',
                                          icon: Icons.auto_awesome,
                                          color: SkyColors.yellow,
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
                                  Text(
                                    'Choose your way to fly',
                                    style: heading(24),
                                  ),
                                  const Spacer(),
                                  const Pill(
                                    'OFFLINE',
                                    icon: Icons.cloud_off_rounded,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _ModeCard(
                                        pushUp: true,
                                        best: p.pushUp.best,
                                        reducedMotion: p.settings.reducedMotion,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _ModeCard(
                                        pushUp: false,
                                        best: p.smile.best,
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
  });
  final bool pushUp, reducedMotion;
  final int best;
  @override
  Widget build(BuildContext context) => Panel(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 60,
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
                  const Icon(Icons.emoji_events_outlined, size: 20),
                  Text(
                    'BEST  $best',
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
        const SizedBox(height: 9),
        Text(
          pushUp
              ? 'Push up to rise.\nLower to glide.'
              : 'One smile, one flap.\nRelax. Repeat.',
          style: bodyText(16, color: SkyColors.muted),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: SkyButton(
            label: 'Let’s fly',
            compact: true,
            color: pushUp ? SkyColors.coral : SkyColors.yellow,
            onPressed: () =>
                context.go('/play/${pushUp ? 'push-up' : 'smile'}'),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: TextButton(
            onPressed: () => context.go(
              '/play/${pushUp ? 'push-up' : 'smile'}?practice=true',
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
