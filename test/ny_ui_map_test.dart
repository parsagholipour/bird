// The campaign map once the build opens New York: its two guardians are
// shields with their name on a plaque (not the chapter lair's big crowned
// coin), Paris keeps its padlocks under a "Paris — coming soon" ribbon, and
// the star total counts 60. The stops are handed over as data, so none of
// this depends on the catalog's 3-2 and 3-4 having bosses yet; the catalog's
// own stops are checked at the end, open and closed.
@Timeout(Duration(minutes: 4))
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/campaign_progress.dart';
import 'package:push_up_bird/domain/game_rules.dart' show BossKind, WorldRegion;
import 'package:push_up_bird/ui/campaign_chrome.dart';
import 'package:push_up_bird/ui/campaign_map.dart';
import 'package:push_up_bird/ui/campaign_map_art.dart';
import 'package:push_up_bird/ui/campaign_screen.dart'
    show campaignStarsInBuild, campaignStops;
import 'package:push_up_bird/ui/components.dart';

import 'ny_ui_support.dart';

Future<void> _pump(
  WidgetTester tester,
  Size size,
  List<CampaignMapStop> stops, {
  int focusStop = 0,
  bool reducedMotion = true,
  EdgeInsets padding = EdgeInsets.zero,
  void Function(String)? onLevel,
  void Function(String)? onLocked,
  int total = 0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    nyHarness(
      CampaignMap(
        key: UniqueKey(),
        stops: stops,
        bird: 0,
        reducedMotion: reducedMotion,
        focusStop: focusStop,
        onLevel: onLevel ?? (_) {},
        onLockedLevel: onLocked,
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

const _sizes = [Size(640, 360), Size(800, 360)];
const _saves = {'3-1': 3, '3-2': 2, '3-3': 1};

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
  // New York is open in the build as it ships; tests force a state with the
  // hooks, so they pass under either `NEW_YORK_OPEN` define.
  tearDown(() {
    Campaign.openedForTest = false;
    Campaign.closedForTest = false;
  });

  group('guardian nodes', () {
    test('a guardian is a boss level but not a chapter lair', () {
      const guardian = CampaignMapNode(
        id: '3-2',
        name: 'Wheels in the Rain',
        boss: BossKind.kingCoo,
        guardian: true,
      );
      const lair = CampaignMapNode(
        id: '1-8',
        name: 'Baron Bat',
        boss: BossKind.baronBat,
      );
      const coin = CampaignMapNode(id: '1-1', name: 'First Delivery');
      expect(guardian.isGuardian, isTrue);
      expect(guardian.isBoss, isFalse);
      expect(lair.isBoss, isTrue);
      expect(lair.isGuardian, isFalse);
      expect(coin.isBoss || coin.isGuardian, isFalse);
    });

    for (final size in _sizes) {
      final w = size.width.round();

      testWidgets('both shields wear their plaque at $w', (tester) async {
        await _pump(tester, size, nyStops(stars: _saves), focusStop: 0);
        expect(find.text('GUARDIAN'), findsNWidgets(2));
        expect(find.text('King Coo'), findsOneWidget);
        expect(find.text('Searchlight Gargoyle'), findsOneWidget);
        // A shield stands in place of the coin's number.
        expect(find.text('3-2'), findsNothing);
        expect(find.text('3-4'), findsNothing);
        expect(find.text('3-1'), findsOneWidget);
        expect(find.text('3-3'), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(
          find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is MapGuardianPainter,
          ),
          findsNWidgets(2),
        );
      });

      testWidgets('a shield is smaller than a lair and its plaque stays on '
          'the stop at $w', (tester) async {
        // One open stop with a guardian, a coin and a chapter lair side by
        // side, so the three sizes can be compared.
        const stops = [
          CampaignMapStop(
            region: WorldRegion.newYork,
            chapter: 3,
            route: 'The Lamplight Line',
            nodes: [
              CampaignMapNode(
                id: '3-1',
                name: 'Moth Light',
                state: CampaignNodeState.open,
              ),
              CampaignMapNode(
                id: '3-2',
                name: 'Wheels in the Rain',
                state: CampaignNodeState.open,
                boss: BossKind.kingCoo,
                guardian: true,
              ),
              CampaignMapNode(
                id: '3-8',
                name: 'Dusk Empress',
                state: CampaignNodeState.open,
                boss: BossKind.duskMoth,
              ),
            ],
          ),
        ];
        await _pump(tester, size, stops);
        Size painted(String id, Type painter) => tester.getSize(
          find.descendant(
            of: find.byKey(ValueKey('campaign-node-$id')),
            matching: find.byWidgetPredicate(
              (w) => w is CustomPaint && w.painter.runtimeType == painter,
            ),
          ),
        );
        final shield = painted('3-2', MapGuardianPainter);
        final coin = painted('3-1', MapNodePainter);
        final lair = painted('3-8', MapNodePainter);
        expect(shield.height, lessThan(lair.height));
        expect(shield.width, lessThan(lair.width));
        // About the size of a level coin, a little taller.
        expect(shield.width, closeTo(coin.width, 8));
        expect(shield.height, inInclusiveRange(coin.height, coin.height + 14));
        // Its plaque hangs under it, wider than the shield and centred on it.
        final plaque = tester.getRect(
          find.byKey(const ValueKey('campaign-guardian-King Coo')),
        );
        final node = tester.getRect(
          find.byKey(const ValueKey('campaign-node-3-2')),
        );
        expect(plaque.left, greaterThanOrEqualTo(0));
        expect(plaque.right, lessThanOrEqualTo(size.width));
        expect(plaque.width, greaterThan(node.width * .9));
        expect(plaque.center.dx, closeTo(node.center.dx, 1));
        expect(plaque.top, greaterThan(node.center.dy));
      });

      testWidgets('the plaques clear the notch and the neighbours at $w', (
        tester,
      ) async {
        const notch = EdgeInsets.fromLTRB(44, 0, 44, 12);
        await _pump(
          tester,
          size,
          nyStops(stars: _saves),
          focusStop: 0,
          padding: notch,
        );
        final safe = notch.deflateRect(Offset.zero & size);
        final rects = <String, Rect>{};
        for (final name in ['King Coo', 'Searchlight Gargoyle']) {
          final plaque = tester.getRect(
            find.byKey(ValueKey('campaign-guardian-$name')),
          );
          expect(safe.left, lessThanOrEqualTo(plaque.left + .5), reason: name);
          expect(safe.right, greaterThanOrEqualTo(plaque.right - .5));
          rects[name] = plaque;
        }
        // The plaque never covers another level's node.
        for (final id in ['3-1', '3-3']) {
          final node = tester.getRect(
            find.byKey(ValueKey('campaign-node-$id')),
          );
          for (final MapEntry(:key, :value) in rects.entries) {
            expect(
              value.overlaps(node.deflate(6)),
              isFalse,
              reason: '$key over $id',
            );
          }
        }
      });
    }

    testWidgets('a shield is tapped like any node: open ones start, locked '
        'ones nudge', (tester) async {
      final opened = <String>[], locked = <String>[];
      await _pump(
        tester,
        _sizes[1],
        nyStops(stars: const {'3-1': 3}),
        onLevel: opened.add,
        onLocked: locked.add,
      );
      await tester.tap(find.byKey(const ValueKey('campaign-node-3-2')));
      await tester.tap(find.byKey(const ValueKey('campaign-node-3-4')));
      expect(opened, ['3-2']);
      expect(locked, ['3-4']);
    });

    testWidgets('semantics name the guardian and keep the level\'s', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        _sizes[1],
        nyStops(stars: const {'3-1': 3, '3-2': 2}),
      );
      expect(
        find.bySemanticsLabel(
          'Level 3-2, Wheels in the Rain, guardian King Coo. 2 of 3 stars.',
        ),
        findsOneWidget,
      );
      // 3-3 is next up; 3-4 waits behind it.
      expect(
        find.bySemanticsLabel(
          'Level 3-4, Storm Warning, guardian Searchlight Gargoyle. Locked.',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Level 3-3, Steam Alley. Next up. 0 of 3 stars.'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('the current guardian carries the courier and its glow', (
      tester,
    ) async {
      await _pump(tester, _sizes[1], nyStops(stars: const {'3-1': 3}));
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('campaign-node-3-2')),
          matching: find.byType(CustomPaint),
        ),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Reduced Motion holds every frame still; with motion the '
        'courier hops', (tester) async {
      final stops = nyStops(stars: const {'3-1': 3});
      await _pump(tester, _sizes[1], stops);
      // Nothing ticks: once the neighbouring stills are painted, no more
      // frames are asked for and the bird stays put.
      for (var i = 0; i < 3; i++) {
        await tester.pump();
      }
      expect(tester.binding.hasScheduledFrame, isFalse);
      final bird = tester.getTopLeft(find.byType(BirdArt));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.getTopLeft(find.byType(BirdArt)), bird);
      await _pump(tester, _sizes[1], stops, reducedMotion: false);
      final hopping = tester.getTopLeft(find.byType(BirdArt));
      await tester.pump(const Duration(milliseconds: 350));
      expect(tester.getTopLeft(find.byType(BirdArt)), isNot(hopping));
    });

    testWidgets('locked guardians step back with the rest of a closed stop', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _sizes[1], nyStops(open: false));
      expect(
        find.bySemanticsLabel(
          'Level 3-2, Wheels in the Rain, guardian King Coo. Locked.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      handle.dispose();
    });
  });

  group('Paris', () {
    for (final size in _sizes) {
      testWidgets('keeps its padlocks under a named ribbon at '
          '${size.width.round()}', (tester) async {
        final handle = tester.ensureSemantics();
        await _pump(tester, size, nyStops(stars: _saves), focusStop: 1);
        expect(find.text('Paris — coming soon'), findsOneWidget);
        expect(
          find.bySemanticsLabel(
            'Paris. Chapter 3, The Lamplight Line. Coming soon.',
          ),
          findsOneWidget,
        );
        for (final id in ['3-5', '3-6', '3-7']) {
          expect(
            find.bySemanticsLabel(RegExp('^Level $id, .*Locked.\$')),
            findsOneWidget,
            reason: id,
          );
        }
        // The ribbon sits on screen, centred.
        final ribbon = tester.getRect(find.text('Paris — coming soon'));
        expect(ribbon.center.dx, closeTo(size.width / 2, 12));
        expect(ribbon.left, greaterThan(0));
        expect(ribbon.right, lessThan(size.width));
        expect(tester.takeException(), isNull);
        handle.dispose();
      });
    }

    testWidgets('a closed build says plain Coming soon on both stops', (
      tester,
    ) async {
      await _pump(tester, _sizes[0], nyStops(open: false), focusStop: 1);
      expect(find.text('Coming soon'), findsNWidgets(2));
      expect(find.text('Paris — coming soon'), findsNothing);
    });
  });

  group('star total', () {
    testWidgets('counts out of 60 when New York is open', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _sizes[1], nyStops(stars: _saves), total: 18);
      expect(find.text('18'), findsOneWidget);
      expect(find.text(' / 60'), findsOneWidget);
      expect(find.bySemanticsLabel('18 of 60 campaign stars'), findsOneWidget);
      handle.dispose();
    });
  });

  group('the catalog\'s stops', () {
    final empty = CampaignProgress(const []);
    // Chapters 1 and 2 beaten, so the first New York level is open.
    final twoChapters = CampaignProgress([
      for (final level in Campaign.levels.take(16))
        LevelRecord(levelId: level.id, bestStars: 1),
    ]);

    test('a closed build (NEW_YORK_OPEN=false) keeps chapter 3 as it was', () {
      Campaign.closedForTest = true;
      expect(Campaign.stopsOpen, isFalse);
      final stops = campaignStops(empty);
      for (final stop in stops.where((s) => s.chapter == 3)) {
        expect(stop.comingSoon, isTrue, reason: stop.title);
        expect(stop.locked, isTrue, reason: stop.title);
        expect(stop.soonNote, 'Coming soon', reason: stop.title);
        for (final node in stop.nodes) {
          expect(node.isGuardian, isFalse, reason: node.id);
          expect(node.locked, isTrue, reason: node.id);
          // Only the chapter's own lair is drawn as one, as it always was:
          // a guardian level is a plain locked coin until the stop opens.
          expect(
            node.isBoss,
            Campaign.level(node.id)!.isChapterBoss,
            reason: node.id,
          );
        }
      }
      expect({for (final s in stops) s.soonNote}, {'Coming soon'});
    });

    test('an open build opens New York and names Paris\'s ribbon', () {
      Campaign.openedForTest = true;
      final stops = campaignStops(twoChapters);
      final ny = stops.firstWhere((s) => s.region == WorldRegion.newYork);
      final paris = stops.firstWhere((s) => s.region == WorldRegion.paris);
      expect(ny.comingSoon, isFalse);
      expect(ny.soonNote, 'Coming soon');
      expect(ny.nodes.first.locked, isFalse);
      expect(ny.nodes.first.isCurrent, isTrue);
      expect(paris.comingSoon, isTrue);
      expect(paris.soonNote, 'Paris — coming soon');
      expect(paris.nodes.every((n) => n.locked), isTrue);
      // Every other stop that is still to come keeps the plain ribbon.
      for (final stop in stops.where(
        (s) => s.comingSoon && s.region != WorldRegion.paris,
      )) {
        expect(stop.soonNote, 'Coming soon', reason: stop.title);
      }
      // A node is a guardian exactly when its level is one (the level data
      // gives 3-2 and 3-4 their bosses).
      for (final node in ny.nodes) {
        expect(
          node.isGuardian,
          Campaign.level(node.id)!.isGuardian,
          reason: node.id,
        );
        expect(node.isBoss, isFalse, reason: node.id);
      }
      expect(campaignStarsInBuild, 60);
    });
  });
}
