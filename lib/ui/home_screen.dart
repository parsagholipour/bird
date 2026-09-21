import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/passport_progress.dart';
import '../data/providers.dart';
import '../data/progress_repository.dart';
import '../domain/game_rules.dart';
import '../domain/tracking.dart';
import 'components.dart';
import 'flight_goals.dart';
import 'home_world.dart';
import 'menu_collectible_art.dart';
import 'play_button.dart';
import 'theme.dart';

const _course = FlightCourse.starTrail;

void _play(BuildContext context, String mode, {bool practice = false}) {
  context.go(
    '/play/$mode?${practice ? 'practice=true&' : ''}course=${_course.name}',
  );
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xff7dcddd), Color(0xffb9e5de), Color(0xffedf3d9)],
        ),
      ),
      child: ref
          .watch(progressProvider)
          .when(
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
            data: (progress) => SceneLayout(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: HomeWorld(
                      bird: progress.settings.bird,
                      reducedMotion: progress.settings.reducedMotion,
                    ),
                  ),
                  Positioned(
                    left: 26,
                    top: 16,
                    child: _BestScore(
                      best: progress.record(PlayMode.pushUp, _course).best,
                    ),
                  ),
                  const Positioned(right: 24, top: 14, child: _HomeTools()),
                  const Positioned(
                    left: 94,
                    top: 44,
                    width: 382,
                    child: _GameTitle(),
                  ),
                  Positioned(
                    left: 112,
                    top: 218,
                    width: 348,
                    child: _PlayMenu(),
                  ),
                  Positioned(
                    right: 121,
                    top: 312,
                    width: 260,
                    child: Center(
                      child: Text(
                        '${birdNames[progress.settings.bird]} is ready. Are you?',
                        style: bodyText(14, weight: FontWeight.w800),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 108,
                    right: 108,
                    bottom: 4,
                    height: 102,
                    child: _Collectibles(progress: progress),
                  ),
                ],
              ),
            ),
          ),
    ),
  );
}

class _GameTitle extends StatelessWidget {
  const _GameTitle();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Semantics(
        label: 'Push-Up Bird',
        header: true,
        child: ExcludeSemantics(
          child: Transform.rotate(
            angle: -.035,
            child: Column(
              children: [
                _TitleWord('PUSH-UP', size: 49, color: SkyColors.yellow),
                _TitleWord('BIRD', size: 91, color: SkyColors.cream),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'A little effort. A lot of airtime.',
        style: bodyText(16, weight: FontWeight.w800),
      ),
    ],
  );
}

class _TitleWord extends StatelessWidget {
  const _TitleWord(this.text, {required this.size, required this.color});
  final String text;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = heading(
      size,
      weight: FontWeight.w700,
    ).copyWith(height: .94, letterSpacing: 3);
    return Stack(
      children: [
        Transform.translate(
          offset: const Offset(0, 5),
          child: Text(
            text,
            style: style.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeJoin = StrokeJoin.round
                ..strokeWidth = 7
                ..color = SkyColors.ink,
            ),
          ),
        ),
        Text(
          text,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeJoin = StrokeJoin.round
              ..strokeWidth = 6
              ..color = SkyColors.ink,
          ),
        ),
        Text(text, style: style.copyWith(color: color)),
      ],
    );
  }
}

class _PlayMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      PlayButton(
        key: const ValueKey('push-up-mode'),
        onPressed: () => _play(context, 'push-up'),
      ),
      const SizedBox(height: 6),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: () => _play(context, 'push-up', practice: true),
            style: TextButton.styleFrom(minimumSize: const Size(94, 44)),
            child: Text(
              'Practice',
              style: bodyText(13, weight: FontWeight.w900),
            ),
          ),
          Container(
            width: 1,
            height: 14,
            color: SkyColors.ink.withValues(alpha: .2),
          ),
          TextButton(
            onPressed: () => _showOtherWays(context),
            style: TextButton.styleFrom(minimumSize: const Size(182, 44)),
            child: Row(
              children: [
                Text('Other ways to play', style: bodyText(13)),
                const SizedBox(width: 5),
                const Icon(Icons.expand_more_rounded, size: 18),
              ],
            ),
          ),
        ],
      ),
    ],
  );
}

class _BestScore extends StatelessWidget {
  const _BestScore({required this.best});
  final int best;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Push-up best: $best star points',
    excludeSemantics: true,
    child: Row(
      children: [
        const Icon(Icons.emoji_events_rounded, color: SkyColors.ink, size: 29),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PERSONAL BEST', style: bodyText(9, weight: FontWeight.w900)),
            Text('$best stars', style: heading(21)),
          ],
        ),
      ],
    ),
  );
}

class _HomeTools extends StatelessWidget {
  const _HomeTools();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      TextButton.icon(
        onPressed: () => context.go('/school'),
        icon: const Icon(Icons.school_outlined, size: 20),
        label: Text(
          'Flight school',
          style: bodyText(13, weight: FontWeight.w900),
        ),
        style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
      ),
      const SizedBox(width: 10),
      RoundButton(
        icon: Icons.settings_rounded,
        label: 'Settings',
        onPressed: () => context.go('/settings'),
      ),
    ],
  );
}

class _Collectibles extends StatelessWidget {
  const _Collectibles({required this.progress});
  final ProgressSnapshot progress;

  @override
  Widget build(BuildContext context) {
    final completed = progress.today?.completedGoals ?? 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _MenuCollectible(
          key: const ValueKey('daily-adventure'),
          label: 'Adventure',
          semanticLabel: 'Today’s adventure. $completed of 3 goals complete.',
          badge: completed == 3 ? '✓' : '$completed/3',
          art: const MenuCollectibleArt(MenuCollectible.adventure),
          onTap: () => context.go('/daily'),
        ),
        _MenuCollectible(
          label: 'Birds',
          semanticLabel: 'Birds. ${progress.unlocked.length} of 4 unlocked.',
          badge: '${progress.unlocked.length}/4',
          art: _BirdCollectionArt(bird: progress.settings.bird),
          onTap: () => context.go('/birds'),
        ),
        _MenuCollectible(
          label: 'Passport',
          semanticLabel: 'Passport. ${progress.earnedStamps} of 8 stamps.',
          art: const MenuCollectibleArt(MenuCollectible.passport),
          onTap: () => context.go('/passport'),
        ),
        _MenuCollectible(
          label: 'Records',
          art: const MenuCollectibleArt(MenuCollectible.records),
          onTap: () => context.go('/records'),
        ),
        _MenuCollectible(
          label: 'Flight goals',
          art: const MenuCollectibleArt(MenuCollectible.goals),
          onTap: () => showFlightGoals(context, _course),
        ),
      ],
    );
  }
}

class _MenuCollectible extends StatelessWidget {
  const _MenuCollectible({
    super.key,
    required this.label,
    required this.art,
    required this.onTap,
    this.badge,
    this.semanticLabel,
  });
  final String label;
  final String? badge, semanticLabel;
  final Widget art;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semanticLabel ?? label,
    onTap: onTap,
    excludeSemantics: true,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 112,
          child: Column(
            children: [
              SizedBox(
                width: 100,
                height: 80,
                child: Stack(
                  children: [
                    Positioned.fill(child: art),
                    if (badge != null)
                      Positioned(
                        right: 0,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: SkyColors.cream,
                            border: Border.all(
                              color: SkyColors.ink,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            badge!,
                            style: bodyText(11, weight: FontWeight.w900),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Text(label, style: heading(16)),
            ],
          ),
        ),
      ),
    ),
  );
}

class _BirdCollectionArt extends StatelessWidget {
  const _BirdCollectionArt({required this.bird});
  final int bird;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned(
        left: 10,
        bottom: 3,
        child: Container(
          width: 78,
          height: 8,
          decoration: BoxDecoration(
            color: SkyColors.ink.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
      Positioned(
        right: 0,
        top: 0,
        child: Transform.rotate(
          angle: .15,
          child: BirdArt(bird: bird == 1 ? 0 : 1, size: 63, bob: false),
        ),
      ),
      Positioned(
        left: 0,
        bottom: 4,
        child: Transform.rotate(
          angle: -.1,
          child: BirdArt(bird: bird, size: 76, bob: false),
        ),
      ),
    ],
  );
}

Future<void> _showOtherWays(BuildContext context) async {
  final selection = await showDialog<({String mode, bool practice})>(
    context: context,
    builder: (context) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 510),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Other ways to play', style: heading(27)),
                  ),
                  RoundButton(
                    icon: Icons.close_rounded,
                    label: 'Close other ways to play',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Same sky. A different way to fly.',
                style: bodyText(14, color: SkyColors.muted),
              ),
              const SizedBox(height: 20),
              _AlternativeMode(
                title: 'Tap & Fly',
                description: 'Tap to flap. Shoot the bats. No camera needed.',
                icon: Icons.touch_app_rounded,
                color: SkyColors.mint,
                onPlay: () =>
                    Navigator.pop(context, (mode: 'touch', practice: false)),
              ),
              const SizedBox(height: 12),
              _AlternativeMode(
                title: 'Jump & Fly',
                description:
                    'Jump through buildings. Collect stars. No enemies.',
                icon: Icons.accessibility_new_rounded,
                color: SkyColors.lavender,
                onPlay: () =>
                    Navigator.pop(context, (mode: 'jump', practice: false)),
                onPractice: () =>
                    Navigator.pop(context, (mode: 'jump', practice: true)),
              ),
              const SizedBox(height: 12),
              _AlternativeMode(
                title: 'Squat & Fly',
                description:
                    'Squat to descend. Stand to rise. Feet stay planted.',
                icon: Icons.airline_seat_legroom_extra_rounded,
                color: SkyColors.coral,
                practiceLabel: 'Squat practice',
                onPlay: () =>
                    Navigator.pop(context, (mode: 'squat', practice: false)),
                onPractice: () =>
                    Navigator.pop(context, (mode: 'squat', practice: true)),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  if (selection != null && context.mounted) {
    _play(context, selection.mode, practice: selection.practice);
  }
}

class _AlternativeMode extends StatelessWidget {
  const _AlternativeMode({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onPlay,
    this.onPractice,
    this.practiceLabel = 'Jump practice',
  });
  final String title, description, practiceLabel;
  final IconData icon;
  final Color color;
  final VoidCallback onPlay;
  final VoidCallback? onPractice;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: SkyButton(
          label: title,
          icon: icon,
          color: color,
          onPressed: onPlay,
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description, style: bodyText(13, color: SkyColors.muted)),
            if (onPractice != null)
              TextButton(onPressed: onPractice, child: Text(practiceLabel)),
          ],
        ),
      ),
    ],
  );
}
