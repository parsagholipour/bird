// Visual review captures of the New York UI: the partly open map, the
// guardian level card, the results and the "To be continued" card, at the two
// phone sizes, with motion and under Reduced Motion.
//
// Run with `--dart-define=CAPTURE_NY_UI=true` to write PNGs to
// build/visual-review/ny-ui/. Add `--dart-define=NY_UI_ONLY=name` to render
// only the states whose name contains it.
@Timeout(Duration(minutes: 8))
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/campaign_progress.dart';
import 'package:push_up_bird/ui/campaign_chrome.dart';
import 'package:push_up_bird/ui/campaign_map.dart';
import 'package:push_up_bird/ui/campaign_map_art.dart'
    show MapGuardianPainter, MapNodeLook;
import 'package:push_up_bird/ui/campaign_text_scale.dart';
import 'package:push_up_bird/ui/components.dart';
import 'package:push_up_bird/domain/game_rules.dart' show BossKind, WorldRegion;
import 'package:push_up_bird/ui/level_hud.dart' show MatchRoute;
import 'package:push_up_bird/ui/level_intro.dart';
import 'package:push_up_bird/ui/story_scene.dart';
import 'package:push_up_bird/ui/theme.dart';

import 'ny_ui_support.dart';

const _capture = bool.fromEnvironment('CAPTURE_NY_UI');
const _only = String.fromEnvironment('NY_UI_ONLY');

bool _want(String name) => _only.isEmpty || name.contains(_only);

const _sizes = [Size(640, 360), Size(800, 360)];

Future<void> _pumpMap(
  WidgetTester tester,
  Size size, {
  required List<CampaignMapStop> stops,
  int focusStop = 0,
  bool reducedMotion = true,
  int bird = 0,
  int total = 0,
  EdgeInsets padding = EdgeInsets.zero,
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    nyHarness(
      CampaignMap(
        key: UniqueKey(),
        stops: stops,
        bird: bird,
        reducedMotion: reducedMotion,
        focusStop: focusStop,
        onLevel: (_) {},
        onLockedLevel: (_) {},
        leading: MapKey(
          glyph: MapGlyph.back,
          label: 'Back',
          reducedMotion: reducedMotion,
          onPressed: () {},
        ),
        trailing: CampaignStarTotal(stars: total, of: 60),
      ),
      size,
      padding: padding,
      textScale: textScale,
    ),
  );
  await tester.runAsync(() async {
    final context = tester.element(find.byType(CampaignMap));
    for (final asset in birdAssets) {
      await precacheImage(AssetImage('assets/images/$asset.png'), context);
    }
  });
  await tester.pump(const Duration(milliseconds: 400));
}

/// The level card over the dimmed New York map, as the campaign screen lays
/// it.
Future<void> _pumpCard(
  WidgetTester tester,
  Size size,
  CampaignLevel level, {
  LevelRecord? record,
  bool still = true,
  List<CampaignMapStop>? stops,
  bool story = true,
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final grow = (size.height / 360).clamp(1.0, 1.2);
  await tester.pumpWidget(
    nyHarness(
      Stack(
        fit: StackFit.expand,
        children: [
          CampaignMap(
            stops: stops ?? nyStops(stars: const {'3-1': 3}),
            bird: 0,
            reducedMotion: still,
            chromeHidden: true,
            focusStop: 0,
            onLevel: (_) {},
          ),
          ColoredBox(color: SkyColors.ink.withValues(alpha: .4)),
          SafeArea(
            minimum: const EdgeInsets.all(10),
            child: Center(
              child: Builder(
                builder: (context) {
                  // As the campaign screen lays it: the card's design box
                  // grows with the text size and the screen scales it down.
                  final design = LevelIntroCard.sizeFor(
                    CampaignTextScale.of(context),
                  );
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: design.width * grow,
                      maxHeight: design.height * grow,
                    ),
                    child: LevelIntroCard(
                      level: level,
                      record: record ?? LevelRecord(levelId: level.id),
                      onFly: () {},
                      onClose: () {},
                      onStory: story ? () {} : null,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      size,
      textScale: textScale,
    ),
  );
  await tester.runAsync(() async {
    final context = tester.element(find.byType(CampaignMap));
    for (final asset in birdAssets) {
      await precacheImage(AssetImage('assets/images/$asset.png'), context);
    }
  });
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  setUpAll(() async {
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  // The fix round: large text, the locked guardian, the emblem.
  group('capture fix round', skip: !_capture, () {
    for (final size in _sizes) {
      final w = size.width.round();
      for (final scale in [1.0, 1.3, 2.0]) {
        final tag = scale == 1 ? '' : '-text${(scale * 10).round()}';
        testWidgets('map at $w text $scale', (tester) async {
          await _pumpMap(
            tester,
            size,
            stops: nyStops(stars: const {'3-1': 3, '3-2': 2}),
            bird: 1,
            total: 5,
            textScale: scale,
          );
          await savePng(
            tester,
            find.byKey(const ValueKey('ny-capture')),
            'fix-map-mid$tag-$w',
          );
          // New York with 3-1 next: both guardians locked.
          await _pumpMap(
            tester,
            size,
            stops: nyStops(stars: const {'3-1': 3}),
            bird: 1,
            total: 3,
            textScale: scale,
          );
          await savePng(
            tester,
            find.byKey(const ValueKey('ny-capture')),
            'fix-map-locked$tag-$w',
          );
          await _pumpMap(
            tester,
            size,
            stops: nyStops(
              stars: const {'3-1': 3, '3-2': 3, '3-3': 3, '3-4': 3},
            ),
            total: 60,
            textScale: scale,
          );
          await savePng(
            tester,
            find.byKey(const ValueKey('ny-capture')),
            'fix-map-done$tag-$w',
          );
          await _pumpMap(
            tester,
            size,
            stops: nyStops(
              stars: const {'3-1': 3, '3-2': 2, '3-3': 1, '3-4': 3},
            ),
            focusStop: 1,
            total: 9,
            textScale: scale,
          );
          await savePng(
            tester,
            find.byKey(const ValueKey('ny-capture')),
            'fix-map-paris$tag-$w',
          );
        });
        testWidgets('cards at $w text $scale', (tester) async {
          for (final (name, level, record) in [
            ('guardian', nyWheels, null),
            ('gargoyle', nyStorm, null),
            (
              'cleared',
              nyStorm,
              LevelRecord(
                levelId: '3-4',
                bestStars: 3,
                bestCollected: 30,
                bestScore: 600,
                plays: 4,
              ),
            ),
            ('boss', Campaign.level('3-8')!, null),
          ]) {
            await _pumpCard(
              tester,
              size,
              level,
              record: record,
              textScale: scale,
            );
            expect(tester.takeException(), isNull, reason: '$name $scale');
            await savePng(
              tester,
              find.byKey(const ValueKey('ny-capture')),
              'fix-card-$name$tag-$w',
            );
          }
        });
        testWidgets('end card at $w text $scale', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            nyHarness(
              StoryScenePlayer(
                key: UniqueKey(),
                scene: nyLastWord,
                bird: 0,
                reducedMotion: true,
                onDone: () {},
              ),
              size,
              textScale: scale,
            ),
          );
          await tester.pump();
          for (var i = 0; i < nyLastWord.lines.length - 1; i++) {
            await tester.tap(find.byKey(const ValueKey('story-advance')));
            await tester.pump();
          }
          expect(tester.takeException(), isNull);
          await savePng(
            tester,
            find.byKey(const ValueKey('ny-capture')),
            'fix-end-card$tag-$w',
          );
        });
      }
    }
    // The emblem at the sizes it is drawn: the map shield, the card ribbon, the
    // route mark, the lair post.
    testWidgets('emblems', (tester) async {
      const size = Size(640, 360);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        nyHarness(
          ColoredBox(
            color: const Color(0xffeadfc8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final boss in const [
                      BossKind.kingCoo,
                      BossKind.searchlightGargoyle,
                    ])
                      for (final look in MapNodeLook.values)
                        SizedBox(
                          width: 66,
                          height: 74,
                          child: CustomPaint(
                            painter: MapGuardianPainter(
                              look: look,
                              radius: 29,
                              boss: boss,
                            ),
                          ),
                        ),
                  ],
                ),
                for (final boss in const [
                  BossKind.kingCoo,
                  BossKind.searchlightGargoyle,
                ])
                  Center(child: MatchRoute(progress: .45, bird: 1, boss: boss)),
              ],
            ),
          ),
          size,
        ),
      );
      await tester.runAsync(() async {
        final context = tester.element(find.byType(MatchRoute).first);
        for (final asset in birdAssets) {
          await precacheImage(AssetImage('assets/images/$asset.png'), context);
        }
      });
      await tester.pump();
      await savePng(
        tester,
        find.byKey(const ValueKey('ny-capture')),
        'fix-emblems',
      );
    });
  });

  group('capture', skip: !_capture, () {
    testWidgets('route marks', (tester) async {
      const size = Size(640, 360);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        nyHarness(
          ColoredBox(
            color: const Color(0xff1d2040),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final boss in const [
                  BossKind.baronBat,
                  BossKind.kingCoo,
                  BossKind.searchlightGargoyle,
                ])
                  Center(child: MatchRoute(progress: .45, bird: 1, boss: boss)),
              ],
            ),
          ),
          size,
        ),
      );
      await tester.runAsync(() async {
        final context = tester.element(find.byType(MatchRoute).first);
        for (final asset in birdAssets) {
          await precacheImage(AssetImage('assets/images/$asset.png'), context);
        }
      });
      await tester.pump();
      await savePng(
        tester,
        find.byKey(const ValueKey('ny-capture')),
        'route-marks',
      );
    });
    for (final size in const [..._sizes, Size(1000, 450)]) {
      final w = size.width.round();
      for (final reduced in [true, false]) {
        testWidgets('end card at $w${reduced ? '' : ' with motion'}', (
          tester,
        ) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            nyHarness(
              StoryScenePlayer(
                key: UniqueKey(),
                scene: nyLastWord,
                bird: 0,
                reducedMotion: reduced,
                onDone: () {},
              ),
              size,
            ),
          );
          await tester.pump();
          final last = nyLastWord.lines.length - 1;
          for (var i = 0; i < last; i++) {
            if (reduced) {
              await tester.tap(find.byKey(const ValueKey('story-advance')));
              await tester.pump();
            } else {
              await tester.pump(const Duration(seconds: 3));
              await tester.tap(find.byKey(const ValueKey('story-advance')));
              await tester.pump(const Duration(milliseconds: 400));
            }
          }
          final name = 'end-card${reduced ? '' : '-motion'}';
          if (!reduced) {
            for (final (ms, tag) in [(450, 'writing'), (2600, 'whole')]) {
              await tester.pump(Duration(milliseconds: ms));
              await savePng(
                tester,
                find.byKey(const ValueKey('ny-capture')),
                '$name-$tag-$w',
              );
            }
          } else {
            await savePng(
              tester,
              find.byKey(const ValueKey('ny-capture')),
              '$name-$w',
            );
          }
        });
      }
    }
    for (final size in _sizes) {
      final w = size.width.round();
      testWidgets('cards at $w', (tester) async {
        final dusk = Campaign.level('3-8')!;
        final shots = <(String, CampaignLevel, LevelRecord?)>[
          ('card-guardian-coo', nyWheels, null),
          ('card-guardian-gargoyle', nyStorm, null),
          (
            'card-guardian-cleared',
            nyWheels,
            LevelRecord(
              levelId: '3-2',
              bestStars: 2,
              bestCollected: 24,
              bestScore: 480,
              plays: 2,
            ),
          ),
          (
            'card-guardian-tip',
            CampaignLevel(
              name: nyStorm.name,
              delivery: nyStorm.delivery,
              hint: nyStorm.hint,
              hintIsNew: false,
              bossLine: nyStorm.bossLine,
              plan: nyStorm.plan,
            ),
            LevelRecord(
              levelId: '3-4',
              bestStars: 3,
              bestCollected: 30,
              bestScore: 600,
              plays: 4,
            ),
          ),
          (
            'card-guardian-nohint',
            CampaignLevel(
              name: nyWheels.name,
              delivery: nyWheels.delivery,
              plan: nyWheels.plan,
            ),
            null,
          ),
          ('card-chapter-boss', dusk, null),
          ('card-normal-hint', Campaign.level('3-1')!, null),
        ];
        for (final (name, level, record) in shots) {
          if (!_want(name)) continue;
          await _pumpCard(tester, size, level, record: record);
          await savePng(
            tester,
            find.byKey(const ValueKey('ny-capture')),
            '$name-$w',
          );
        }
      });
    }
    for (final size in _sizes) {
      final w = size.width.round();
      testWidgets('map at $w', (tester) async {
        final shots = <(String, Map<String, int>, int, int, int)>[
          ('map-fresh', const {}, 0, 0, 0),
          ('map-mid', const {'3-1': 3, '3-2': 2}, 0, 1, 5),
          ('map-guardian-next', const {'3-1': 3}, 0, 3, 3),
          ('map-done', const {'3-1': 3, '3-2': 2, '3-3': 1, '3-4': 3}, 0, 2, 9),
          (
            'map-paris',
            const {'3-1': 3, '3-2': 2, '3-3': 1, '3-4': 3},
            1,
            2,
            9,
          ),
        ];
        // With motion: the courier hops and the glow breathes.
        if (_want('map-motion')) {
          await _pumpMap(
            tester,
            size,
            stops: nyStops(stars: const {'3-1': 3, '3-2': 2}),
            reducedMotion: false,
            bird: 1,
            total: 5,
          );
          await tester.pump(const Duration(milliseconds: 350));
          await savePng(
            tester,
            find.byKey(const ValueKey('ny-capture')),
            'map-motion-$w',
          );
        }
        // A light sky and a dark one, to see the shields against both.
        for (final region in [WorldRegion.arabia, WorldRegion.rome]) {
          if (!_want('map-day')) break;
          await _pumpMap(
            tester,
            size,
            stops: nyStops(stars: const {'3-1': 3, '3-2': 2}, region: region),
            total: 5,
            bird: 1,
          );
          await savePng(
            tester,
            find.byKey(const ValueKey('ny-capture')),
            'map-day-${region.name}-$w',
          );
        }
        for (final (name, stars, stop, bird, total) in shots) {
          if (!_want(name)) continue;
          await _pumpMap(
            tester,
            size,
            stops: nyStops(stars: stars),
            focusStop: stop,
            bird: bird,
            total: total,
          );
          await savePng(
            tester,
            find.byKey(const ValueKey('ny-capture')),
            '$name-$w',
          );
        }
      });
    }
  });
}
