import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/passport_progress.dart';
import '../data/providers.dart';
import '../data/progress_repository.dart';
import '../domain/game_rules.dart';
import '../domain/tracking.dart';
import 'campaign_screen.dart' show campaignStarsInBuild;
import 'components.dart';
import 'control_glyphs.dart';
import 'flight_goals.dart';
import 'home_campaign_key.dart';
import 'home_parts.dart';
import 'home_world.dart';
import 'menu_collectible_art.dart';
import 'mode_picker.dart';
import 'play_button.dart';
import 'theme.dart';
import 'ui_sounds.dart';

const _course = FlightCourse.starTrail;

Future<void> _chooseMode(BuildContext context) async {
  final mode = await showModePicker(context);
  if (mode == null || !context.mounted) return;
  final route = mode == PlayMode.pushUp ? 'push-up' : mode.name;
  context.go('/play/$route?course=${_course.name}');
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
            data: (progress) => HomeStage(
              reducedMotion: progress.settings.reducedMotion,
              child: _HomeScene(progress: progress),
            ),
          ),
    ),
  );
}

/// The best Star Trail flight in any mode, so a player who taps or squats
/// still sees their achievement.
({int best, FlyControl? control}) _bestFlight(ProgressSnapshot progress) {
  var best = 0;
  FlyControl? control;
  for (final (mode, flyControl) in [
    (PlayMode.pushUp, FlyControl.pushUp),
    (PlayMode.squat, FlyControl.squat),
    (PlayMode.jump, FlyControl.jump),
    (PlayMode.touch, FlyControl.tap),
  ]) {
    final score = progress.record(mode, _course).best;
    if (score > best) {
      best = score;
      control = flyControl;
    }
  }
  return (best: best, control: control);
}

String _greeting(ProgressSnapshot progress) {
  final name = birdNames[progress.settings.bird];
  // A campaign level counts as a first flight too.
  if (progress.flightsFlown == 0) return 'Hi, I’m $name! Ready to fly?';
  if (progress.today?.complete ?? false) {
    return 'Adventure done! $name is proud.';
  }
  return '$name is ready. Are you?';
}

class _HomeScene extends StatelessWidget {
  const _HomeScene({required this.progress});
  final ProgressSnapshot progress;

  @override
  Widget build(BuildContext context) {
    final best = _bestFlight(progress);
    // The canvas is a fixed layout, so very large system text is held to a
    // size the pills and buttons were drawn for.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.25,
      child: SceneLayout(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: HomeWorld(bird: progress.settings.bird)),
            const Positioned.fill(child: HomeTitleSparkles()),
            Positioned(
              left: 24,
              top: 12,
              child: HomeEntrance(
                begin: .02,
                end: .3,
                slide: const Offset(-20, 0),
                curve: Curves.easeOutCubic,
                child: HomeBestPill(
                  best: best.best,
                  control: best.control,
                  firstFlight: progress.flightsFlown == 0,
                ),
              ),
            ),
            Positioned(
              right: 24,
              top: 10,
              child: _HomeTools(newPlayer: progress.flightsFlown == 0),
            ),
            const Positioned(left: 60, top: 60, width: 440, child: HomeTitle()),
            Positioned(
              left: 70,
              top: 218,
              width: 420,
              height: 76,
              child: _PlayKey(),
            ),
            // The campaign waits beside Play, in the open sky before the
            // bird's island, so Play keeps its size and place. Its key is as
            // tall as Play's; the star tag hangs below it.
            Positioned(
              left: 501,
              top: 218,
              width: HomeCampaignButton.width,
              height: HomeCampaignButton.height,
              child: HomeEntrance(
                begin: .46,
                end: .72,
                pop: .6,
                child: HomeCampaignButton(
                  key: const ValueKey('campaign'),
                  stars: progress.campaign.totalStars,
                  of: campaignStarsInBuild,
                  onPressed: () => context.go('/campaign'),
                ),
              ),
            ),
            const Positioned(
              left: 50,
              top: 304,
              width: 460,
              child: Center(
                child: HomeEntrance(
                  begin: .5,
                  end: .75,
                  slide: Offset(0, 14),
                  child: HomeHooks(),
                ),
              ),
            ),
            Positioned(
              left: 50,
              top: 350,
              width: 460,
              child: _Dock(progress: progress),
            ),
            Positioned(
              left: 570,
              top: 340,
              width: 360,
              child: Center(
                child: HomeEntrance(
                  begin: .62,
                  end: .9,
                  slide: const Offset(0, 12),
                  child: _BirdGreeting(text: _greeting(progress)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayKey extends StatelessWidget {
  @override
  Widget build(BuildContext context) => HomeEntrance(
    begin: .34,
    end: .62,
    pop: .6,
    child: PlayButton(
      key: const ValueKey('play'),
      animated: true,
      reducedMotion: HomeMotion.of(context).still,
      onPressed: () => _chooseMode(context),
    ),
  );
}

class _BirdGreeting extends StatelessWidget {
  const _BirdGreeting({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    label: text,
    excludeSemantics: true,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: SkyColors.cream,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SkyColors.ink, width: 2.2),
        boxShadow: [
          BoxShadow(
            color: SkyColors.ink.withValues(alpha: .16),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(text, style: bodyText(14.5, weight: FontWeight.w900)),
    ),
  );
}

class _HomeTools extends StatelessWidget {
  const _HomeTools({required this.newPlayer});

  /// A first-time player is nudged toward the lessons.
  final bool newPlayer;

  @override
  Widget build(BuildContext context) => HomeEntrance(
    begin: .05,
    end: .35,
    slide: const Offset(20, 0),
    curve: Curves.easeOutCubic,
    // A little larger than the layout box so both targets stay a full 48 dp
    // on the phones that scale this canvas down.
    child: Transform.scale(
      scale: 1.1,
      alignment: Alignment.topRight,
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: SkyColors.cream,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: SkyColors.ink.withValues(alpha: .12)),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    UiSounds.effect(context);
                    context.go('/school');
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: SizedBox(
                      height: 48,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.school_rounded,
                            size: 21,
                            color: SkyColors.ink,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            'Flight school',
                            style: bodyText(13.5, weight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (newPlayer)
                const Positioned(
                  top: -4,
                  right: -4,
                  child: ExcludeSemantics(child: _NewDot()),
                ),
            ],
          ),
          const SizedBox(width: 10),
          RoundButton(
            icon: Icons.settings_rounded,
            label: 'Settings',
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
    ),
  );
}

class _NewDot extends StatelessWidget {
  const _NewDot();

  @override
  Widget build(BuildContext context) => Container(
    width: 15,
    height: 15,
    decoration: BoxDecoration(
      color: SkyColors.coral,
      shape: BoxShape.circle,
      border: Border.all(color: SkyColors.cream, width: 2.5),
      boxShadow: [
        BoxShadow(color: SkyColors.ink.withValues(alpha: .25), blurRadius: 3),
      ],
    ),
  );
}

/// Five shortcuts on a soft shelf. Today's adventure leads and calls for
/// attention while it is open.
class _Dock extends StatelessWidget {
  const _Dock({required this.progress});
  final ProgressSnapshot progress;

  @override
  Widget build(BuildContext context) {
    final completed = progress.today?.completedGoals ?? 0;
    final done = completed == 3;
    final items = [
      HomeDockItem(
        key: const ValueKey('daily-adventure'),
        label: 'Adventure',
        semanticLabel: 'Today’s adventure. $completed of 3 goals complete.',
        glow: HomeAdventureGlow(done: done),
        badge: HomeBadge(done ? '3/3' : '$completed/3', done: done),
        art: const MenuCollectibleArt(MenuCollectible.adventure),
        onTap: () => context.go('/daily'),
      ),
      HomeDockItem(
        label: 'Birds',
        semanticLabel:
            'Birds. Flying with ${birdNames[progress.settings.bird]}.',
        art: FittedBox(
          child: SizedBox(
            width: 100,
            height: 80,
            child: _BirdCollectionArt(bird: progress.settings.bird),
          ),
        ),
        onTap: () => context.go('/birds'),
      ),
      HomeDockItem(
        label: 'Passport',
        semanticLabel: 'Passport. ${progress.earnedStamps} of 8 stamps.',
        art: const MenuCollectibleArt(MenuCollectible.passport),
        onTap: () => context.go('/passport'),
      ),
      HomeDockItem(
        label: 'Records',
        art: const MenuCollectibleArt(MenuCollectible.records),
        onTap: () => context.go('/records'),
      ),
      HomeDockItem(
        label: 'Flight goals',
        art: const MenuCollectibleArt(MenuCollectible.goals),
        onTap: () => showFlightGoals(context, _course),
      ),
    ];
    return HomeEntrance(
      begin: .5,
      end: .74,
      slide: const Offset(0, 30),
      curve: Curves.easeOutCubic,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: SkyColors.cream.withValues(alpha: .8),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withValues(alpha: .9),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: SkyColors.ink.withValues(alpha: .1),
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            children: [
              for (final (i, item) in items.indexed)
                Expanded(
                  child: HomeEntrance(
                    begin: .62 + i * .05,
                    end: .84 + i * .05,
                    slide: const Offset(0, 14),
                    pop: .7,
                    // Today's adventure sits on a warm tile, gold once done.
                    child: i == 0
                        ? DecoratedBox(
                            decoration: BoxDecoration(
                              color: (done ? SkyColors.gold : SkyColors.yellow)
                                  .withValues(alpha: done ? .34 : .4),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: item,
                          )
                        : item,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
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
