// Renders the campaign map and the chapter postcards at phone sizes, so the
// work grows with the stops captured.
@Timeout(Duration(minutes: 4))
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/sky_boss.dart' show BossKind;
import 'package:push_up_bird/game/regions/world_region.dart';
import 'package:push_up_bird/ui/campaign_chrome.dart';
import 'package:push_up_bird/ui/campaign_map.dart';
import 'package:push_up_bird/ui/campaign_map_art.dart' show MapSceneryPainter;
import 'package:push_up_bird/ui/campaign_postcard.dart';
import 'package:push_up_bird/ui/campaign_region_still.dart';
import 'package:push_up_bird/ui/components.dart';
import 'package:push_up_bird/ui/theme.dart';

const _capture = bool.fromEnvironment('CAPTURE_CAMPAIGN_ART');

/// The trip as docs/campaign.md lays it out: chapter, route, boss and each
/// region's levels.
const _chapters = [
  (
    'The Canopy Route',
    BossKind.baronBat,
    [
      (WorldRegion.jungle, ['First Delivery', 'Star Streak', 'Bat Patrol']),
      (WorldRegion.brazil, ['Carnival Skies', 'Express Post']),
      (WorldRegion.aztec, ['Temple Steps', 'Sunrise Roost', 'Baron Bat']),
    ],
  ),
  (
    'The Ancient Road',
    BossKind.spitterBeetle,
    [
      (WorldRegion.rome, ['Beetle Road', 'Sealed Gates', 'Wildfire Run']),
      (WorldRegion.egypt, ['Nile Switchbacks', 'Skyfall']),
      (
        WorldRegion.arabia,
        ['Lantern Bazaar', 'The Long Caravan', 'Spitter King'],
      ),
    ],
  ),
  (
    'The Lamplight Line',
    BossKind.duskMoth,
    [
      (
        WorldRegion.newYork,
        ['Moth Light', 'Wheels in the Rain', 'Swarm Alley', 'Storm Warning'],
      ),
      (
        WorldRegion.paris,
        [
          'Crystal Rooftops',
          'After the Gale',
          'Midnight Express',
          'Dusk Empress',
        ],
      ),
    ],
  ),
  (
    'The Tide Route',
    BossKind.pirate,
    [
      (
        WorldRegion.mexico,
        ['Harbour Lights', 'Volcano Pass', 'Down the Coast'],
      ),
      (
        WorldRegion.sea,
        [
          'Low Water',
          'Spring Tide',
          'Broadside Bay',
          'Stormy Crossing',
          'Pirate Captain',
        ],
      ),
    ],
  ),
  (
    'The Edge of the Map',
    BossKind.dragon,
    [
      (WorldRegion.antarctica, ['Aurora Post', 'Polar Night']),
      (WorldRegion.cyberpunk, ['Neon Express', 'Data Storm', 'Skyline Sprint']),
      (WorldRegion.china, ['Lantern Festival', 'The Last Leg', 'Ember Dragon']),
    ],
  ),
];

/// The map's stops for a save where [stars] holds each finished level's
/// best rating. Chapters 1 and 2 are playable; the rest are coming soon.
List<CampaignMapStop> stopsFor(Map<String, int> stars, {String? current}) {
  final stops = <CampaignMapStop>[];
  var open = true;
  String? next;
  for (final (c, (route, boss, regions)) in _chapters.indexed) {
    final chapter = c + 1;
    final playable = chapter <= 2;
    var number = 0;
    final chapterStops = <CampaignMapStop>[];
    for (final (region, names) in regions) {
      final nodes = <CampaignMapNode>[];
      for (final (j, name) in names.indexed) {
        number++;
        final id = '$chapter-$number';
        final earned = stars[id] ?? 0;
        final isBoss = j == names.length - 1 && region == regions.last.$1;
        final cleared = earned > 0;
        final unlocked = playable && (cleared || open);
        if (unlocked && !cleared && next == null) next = id;
        if (!cleared) open = false;
        nodes.add(
          CampaignMapNode(
            id: id,
            name: name,
            state: cleared
                ? CampaignNodeState.cleared
                : unlocked
                ? CampaignNodeState.open
                : CampaignNodeState.locked,
            stars: earned,
            isCurrent: id == (current ?? next),
            boss: isBoss ? boss : null,
          ),
        );
      }
      chapterStops.add(
        CampaignMapStop(
          region: region,
          chapter: chapter,
          route: route,
          nodes: nodes,
          locked: nodes.every((n) => n.locked),
          comingSoon: !playable,
          postcard:
              region == regions.last.$1 &&
              nodes.last.state == CampaignNodeState.cleared,
        ),
      );
    }
    stops.addAll(chapterStops);
  }
  if (current == null && next == null) {
    // Everything is finished: the bird waits on the last level played.
    final last = stars.keys.last;
    return stopsFor(stars, current: last);
  }
  return stops;
}

/// A save partway through chapter 1: the Jungle done, Brazil next.
const _earlySave = {'1-1': 3, '1-2': 2, '1-3': 1};

/// Chapter 1 beaten, chapter 2 under way.
const _midSave = {
  '1-1': 3,
  '1-2': 3,
  '1-3': 2,
  '1-4': 3,
  '1-5': 2,
  '1-6': 1,
  '1-7': 3,
  '1-8': 2,
  '2-1': 3,
  '2-2': 1,
  '2-3': 2,
  '2-4': 2,
};

/// Everything in this build finished.
final _doneSave = {
  for (final id in [
    '1-1', '1-2', '1-3', '1-4', '1-5', '1-6', '1-7', '1-8', //
    '2-1', '2-2', '2-3', '2-4', '2-5', '2-6', '2-7', '2-8',
  ])
    id: id.hashCode % 3 + 1,
};

Widget _harness(
  Widget child,
  Size size, {
  EdgeInsets padding = EdgeInsets.zero,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: skyTheme(),
  home: MediaQuery(
    data: MediaQueryData(size: size, padding: padding, viewPadding: padding),
    child: RepaintBoundary(
      key: const ValueKey('campaign-capture'),
      child: Scaffold(body: child),
    ),
  ),
);

Future<void> _pumpMap(
  WidgetTester tester,
  Size size, {
  required List<CampaignMapStop> stops,
  int bird = 0,
  bool reducedMotion = false,
  int? focusStop,
  void Function(String)? onLevel,
  void Function(String)? onLockedLevel,
  void Function(int)? onPostcard,
  EdgeInsets padding = EdgeInsets.zero,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    _harness(
      CampaignMap(
        key: UniqueKey(),
        stops: stops,
        bird: bird,
        reducedMotion: reducedMotion,
        focusStop: focusStop,
        onLevel: onLevel ?? (_) {},
        onLockedLevel: onLockedLevel,
        onPostcard: onPostcard,
        leading: MapKey(
          glyph: MapGlyph.back,
          label: 'Back',
          reducedMotion: reducedMotion,
          onPressed: () {},
        ),
        trailing: const CampaignStarTotal(stars: 12, of: 48),
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

Future<void> _save(WidgetTester tester, String name) async {
  if (!_capture) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('campaign-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/visual-review/campaign/$name.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
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

  group('capture', skip: !_capture, () {
    for (final size in const [
      Size(800, 360),
      Size(640, 360),
      Size(915, 412),
      Size(1000, 450),
    ]) {
      final w = size.width.round();
      testWidgets('map stops at $w', (tester) async {
        final early = stopsFor(_earlySave);
        final mid = stopsFor(_midSave);
        final done = stopsFor(_doneSave);
        final shots = <(String, List<CampaignMapStop>, int, int)>[
          ('fresh-jungle', stopsFor(const {}), 0, 0),
          ('early-jungle', early, 0, 1),
          ('early-brazil', early, 1, 2),
          ('early-aztec-locked', early, 2, 1),
          ('mid-aztec-postcard', mid, 2, 3),
          ('mid-egypt', mid, 4, 0),
          ('done-arabia', done, 5, 2),
          ('done-new-york-soon', done, 6, 2),
          ('done-sea-soon', done, 9, 2),
          ('done-china-soon', done, 12, 2),
        ];
        for (final (name, stops, stop, bird) in shots) {
          await _pumpMap(
            tester,
            size,
            stops: stops,
            focusStop: stop,
            bird: bird,
          );
          await _save(tester, 'map/$name-$w');
        }
      });
    }

    for (final size in const [
      Size(800, 360),
      Size(640, 360),
      Size(915, 412),
      Size(1000, 450),
    ]) {
      final w = size.width.round();
      testWidgets('postcards at $w', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        for (var chapter = 1; chapter <= 5; chapter++) {
          if (w != 800 && chapter > 1) break;
          await tester.pumpWidget(
            _harness(
              SkyBackdrop(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Center(
                      child: CampaignPostcard(
                        chapter: chapter,
                        bird: chapter % 4,
                        action: SkyButton(label: 'Continue', onPressed: () {}),
                      ),
                    ),
                  ),
                ),
              ),
              size,
            ),
          );
          await tester.pump(const Duration(milliseconds: 100));
          await _save(tester, 'postcards/chapter-$chapter-$w');
        }
      });
    }

    testWidgets('map between stops and under Reduced Motion', (tester) async {
      const size = Size(800, 360);
      final mid = stopsFor(_midSave);
      await _pumpMap(tester, size, stops: mid, focusStop: 3);
      final scroll = tester.state<ScrollableState>(find.byType(Scrollable));
      for (final f in [.25, .5, .75]) {
        scroll.position.jumpTo((2 + f) * size.width);
        await tester.pump();
        await _save(tester, 'map/seam-aztec-rome-${(f * 100).round()}');
      }
      scroll.position.jumpTo(5.5 * size.width);
      await tester.pump();
      await _save(tester, 'map/seam-arabia-new-york-50');
      await _pumpMap(
        tester,
        size,
        stops: mid,
        focusStop: 3,
        reducedMotion: true,
      );
      await _save(tester, 'map/reduced-rome-800');
      // A notch on the left: the levels, banner and keys keep clear of it.
      await _pumpMap(
        tester,
        size,
        stops: stopsFor(_doneSave),
        focusStop: 9,
        padding: const EdgeInsets.only(left: 44, bottom: 12),
      );
      await _save(tester, 'map/notch-sea-800');
      await _pumpMap(
        tester,
        size,
        stops: stopsFor(_earlySave),
        focusStop: 0,
        padding: const EdgeInsets.only(right: 44, bottom: 12),
      );
      await _save(tester, 'map/notch-jungle-800');
    });
  });

  group('map', () {
    const size = Size(800, 360);

    testWidgets('opens on the current level\'s stop, or the one asked for', (
      tester,
    ) async {
      await _pumpMap(tester, size, stops: stopsFor(_earlySave));
      final scroll = tester.state<ScrollableState>(find.byType(Scrollable));
      // 1-4 is next, in Brazil, the second stop.
      expect(scroll.position.pixels, size.width);
      await _pumpMap(tester, size, stops: stopsFor(_midSave), focusStop: 5);
      expect(
        tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
        5 * size.width,
      );
    });

    testWidgets('nodes show their state, stars and the current level', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pumpMap(tester, size, stops: stopsFor(_earlySave), focusStop: 0);
      expect(
        find.bySemanticsLabel('Level 1-1, First Delivery. 3 of 3 stars.'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Level 1-3, Bat Patrol. 1 of 3 stars.'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          'Level 1-4, Carnival Skies. Next up. 0 of 3 stars.',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Level 1-5, Express Post. Locked.'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('1-8, Baron Bat, boss. Locked.'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          RegExp(
            '^New York. Chapter 3, '
            'The Lamplight Line. Coming soon.',
          ),
        ),
        findsOneWidget,
      );
      // The bird perches only on the current level.
      expect(find.byType(BirdArt), findsOneWidget);
      handle.dispose();
    });

    testWidgets('open levels start, locked ones only nudge', (tester) async {
      final started = <String>[], nudged = <String>[];
      await _pumpMap(
        tester,
        size,
        stops: stopsFor(_earlySave),
        focusStop: 1,
        onLevel: started.add,
        onLockedLevel: nudged.add,
      );
      await tester.tap(find.byKey(const ValueKey('campaign-node-1-4')));
      await tester.tap(find.byKey(const ValueKey('campaign-node-1-5')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(started, ['1-4']);
      expect(nudged, ['1-5']);
    });

    testWidgets('a beaten chapter offers its postcard', (tester) async {
      final postcards = <int>[];
      await _pumpMap(
        tester,
        size,
        stops: stopsFor(_midSave),
        focusStop: 2,
        onPostcard: postcards.add,
      );
      expect(find.byKey(const ValueKey('campaign-postcard-2')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('campaign-postcard-1')));
      expect(postcards, [1]);
    });

    testWidgets('Reduced Motion holds a still frame and jumps between stops', (
      tester,
    ) async {
      await _pumpMap(
        tester,
        size,
        stops: stopsFor(_earlySave),
        reducedMotion: true,
      );
      // Nothing ticks: once the neighbouring stills are painted, no more
      // frames are asked for and the bird stays put.
      for (var i = 0; i < 3; i++) {
        await tester.pump();
      }
      expect(tester.binding.hasScheduledFrame, isFalse);
      final bird = tester.getTopLeft(find.byType(BirdArt));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.getTopLeft(find.byType(BirdArt)), bird);
      await tester.tap(find.bySemanticsLabel('Next stop'));
      await tester.pump();
      expect(
        tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
        2 * size.width,
      );
    });

    testWidgets('with motion the bird hops and the step keys glide', (
      tester,
    ) async {
      await _pumpMap(tester, size, stops: stopsFor(_earlySave));
      final bird = tester.getTopLeft(find.byType(BirdArt));
      await tester.pump(const Duration(milliseconds: 350));
      expect(tester.getTopLeft(find.byType(BirdArt)), isNot(bird));
      await tester.tap(find.bySemanticsLabel('Previous stop'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      final scroll = tester.state<ScrollableState>(find.byType(Scrollable));
      expect(scroll.position.pixels, inExclusiveRange(0, size.width));
      await tester.pump(const Duration(milliseconds: 600));
      expect(scroll.position.pixels, 0);
    });
  });

  testWidgets('card and postcard pictures never evict the map\'s stills', (
    tester,
  ) async {
    const page = Size(400, 180);
    final stops = [WorldRegion.jungle, WorldRegion.brazil, WorldRegion.aztec];
    final map = [
      for (final (i, region) in stops.indexed)
        MapSceneryPainter.still(region, page, 1, first: i == 0),
    ];
    // Level cards and postcards over them, in other sizes and regions.
    for (final region in WorldRegion.values.take(5)) {
      CampaignRegionStill.image(region, const Size(300, 120), 1);
    }
    for (final (i, region) in stops.indexed) {
      expect(
        MapSceneryPainter.still(region, page, 1, first: i == 0),
        same(map[i]),
        reason: region.name,
      );
    }
  });

  testWidgets('every chapter\'s postcard renders its letter and action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (var chapter = 1; chapter <= 5; chapter++) {
      var continued = false;
      await tester.pumpWidget(
        _harness(
          Center(
            child: CampaignPostcard(
              chapter: chapter,
              bird: 0,
              action: SkyButton(
                label: 'Continue',
                onPressed: () => continued = true,
              ),
            ),
          ),
          const Size(800, 360),
        ),
      );
      final letter = CampaignPostcard.letters[chapter - 1];
      expect(find.text('Dear courier,'), findsOneWidget);
      expect(find.text(letter.body), findsOneWidget);
      expect(find.text('— ${letter.route}'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      expect(continued, isTrue);
    }
  });
}
