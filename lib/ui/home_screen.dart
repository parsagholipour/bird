import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/passport_progress.dart';
import '../data/providers.dart';
import '../data/progress_repository.dart';
import '../domain/campaign_progress.dart';
import '../domain/game_rules.dart';
import '../domain/tracking.dart';
import '../l10n/l10n.dart';
import '../l10n/text/birds_text.dart';
import 'campaign_chrome.dart' show MapGlyph, MapKey;
import 'campaign_screen.dart' show campaignStarsInBuild;
import 'components.dart';
import 'home_keys.dart';
import 'home_parts.dart';
import 'home_world.dart';
import 'launch_screen.dart';
import 'match_hud.dart' show MatchIcon, MatchSymbol;
import 'menu_collectible_art.dart';
import 'mini_games.dart';
import 'theme.dart';

const _course = FlightCourse.starTrail;

/// The main game is the campaign and the endless flight, both flown with
/// taps; push-ups, squats, jumps and Fly Together are the mini games, and
/// the Level Builder makes levels of one's own.
void _flyEndless(BuildContext context) =>
    context.go('/play/touch?course=${_course.name}');

Future<void> _chooseMiniGame(BuildContext context) async {
  final mode = await showMiniGames(context);
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
            loading: () => const BeakboundLaunchScreen(),
            error: (e, _) => Center(
              child: Panel(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(context.l10n.homeUnavailable, style: heading(28)),
                    const SizedBox(height: 16),
                    SkyButton(
                      label: context.l10n.commonTryAgain,
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

/// The level the campaign continues with, as the Campaign key shows it, or
/// null once every level this build can fly is cleared.
String? _nextLevel(AppLocalizations l, CampaignProgress campaign) {
  final level = campaign.current;
  return campaign.cleared(level)
      ? null
      : l.homeLevelLabel(level.id, l.levelName(level));
}

String _greeting(AppLocalizations l, ProgressSnapshot progress) {
  final bird = progress.settings.bird;
  final name = l.birdName(bird);
  // A campaign level counts as a first flight too.
  if (progress.flightsFlown == 0) return l.homeGreetingFirst(name);
  if (progress.today?.complete ?? false) {
    return l.homeGreetingDone(birdGender(bird), name);
  }
  return l.homeGreetingReady(birdGender(bird), name);
}

class _HomeScene extends StatelessWidget {
  const _HomeScene({required this.progress});
  final ProgressSnapshot progress;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
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
            const Positioned(right: 24, top: 10, child: _HomeTools()),
            const Positioned(left: 60, top: 0, width: 440, child: HomeTitle()),
            // The main game: the campaign and the endless flight, side by
            // side and the same size, under the title.
            Positioned(
              left: 50,
              top: 128,
              width: 250,
              height: 108,
              child: HomeEntrance(
                begin: .3,
                end: .58,
                pop: .6,
                child: HomeCampaignKey(
                  key: const ValueKey('campaign'),
                  stars: progress.campaign.totalStars,
                  of: campaignStarsInBuild,
                  next: _nextLevel(l, progress.campaign),
                  onPressed: () => context.go('/campaign'),
                ),
              ),
            ),
            Positioned(
              left: 310,
              top: 128,
              width: 250,
              height: 108,
              child: HomeEntrance(
                begin: .36,
                end: .64,
                pop: .6,
                child: HomeEndlessKey(
                  key: const ValueKey('endless'),
                  best: progress.record(PlayMode.touch, _course).best,
                  animated: true,
                  reducedMotion: HomeMotion.of(context).still,
                  onPressed: () => _flyEndless(context),
                ),
              ),
            ),
            // The mini games and the Level Builder share one quieter row
            // below, each half of it and still a full 48 dp on the smallest
            // phones.
            Positioned(
              left: 50,
              top: 246,
              width: 250,
              height: 76,
              child: HomeEntrance(
                begin: .46,
                end: .72,
                slide: const Offset(0, 14),
                child: HomeMiniGamesKey(
                  key: const ValueKey('mini-games'),
                  onPressed: () => _chooseMiniGame(context),
                ),
              ),
            ),
            Positioned(
              left: 310,
              top: 246,
              width: 250,
              height: 76,
              child: HomeEntrance(
                begin: .5,
                end: .76,
                slide: const Offset(0, 14),
                child: HomeLevelBuilderKey(
                  key: const ValueKey('level-builder'),
                  flightsLeft: progress.flightsToBuilder,
                  onPressed: () => context.go('/builder'),
                ),
              ),
            ),
            Positioned(
              left: 50,
              top: 334,
              width: 510,
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
                  child: _BirdGreeting(text: _greeting(l, progress)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
  const _HomeTools();

  @override
  Widget build(BuildContext context) => HomeEntrance(
    begin: .05,
    end: .35,
    slide: const Offset(20, 0),
    curve: Curves.easeOutCubic,
    // A little larger than the layout box so the target stays a full 48 dp
    // on the phones that scale this canvas down.
    child: Transform.scale(
      scale: 1.1,
      alignment: Alignment.topRight,
      // The same round sticker key as every Back key in the menus.
      child: MapKey(
        glyph: MapGlyph.settings,
        label: context.l10n.homeSettings,
        onPressed: () => context.go('/settings'),
      ),
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
    final l = context.l10n;
    final completed = progress.today?.completedGoals ?? 0;
    final done = completed == 3;
    final items = [
      HomeDockItem(
        key: const ValueKey('daily-adventure'),
        label: l.homeDockAdventure,
        semanticLabel: l.homeDockAdventureSemantics(completed),
        glow: HomeAdventureGlow(done: done),
        badge: HomeBadge(done ? '3/3' : '$completed/3', done: done),
        art: const MenuCollectibleArt(MenuCollectible.adventure),
        onTap: () => context.go('/daily'),
      ),
      HomeDockItem(
        label: l.homeDockBirds,
        semanticLabel: l.homeDockBirdsSemantics(
          l.birdName(progress.settings.bird),
        ),
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
        key: const ValueKey('upgrades'),
        label: l.homeDockUpgrades,
        semanticLabel: l.homeDockUpgradesSemantics(progress.starWallet),
        badge: HomeBadge('${progress.starWallet}'),
        art: const FittedBox(child: MatchIcon(MatchSymbol.star, size: 64)),
        onTap: () => context.go('/upgrades'),
      ),
      HomeDockItem(
        label: l.homeDockPassport,
        semanticLabel: l.homeDockPassportSemantics(
          progress.earnedMedals,
          passportMedals,
        ),
        art: const MenuCollectibleArt(MenuCollectible.passport),
        onTap: () => context.go('/passport'),
      ),
      HomeDockItem(
        label: l.homeDockRecords,
        art: const MenuCollectibleArt(MenuCollectible.records),
        onTap: () => context.go('/records'),
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
