// New York through the whole app, with the build opened (`Campaign.openedForTest`):
// the level result after a guardian falls and after 3-4, where Paris is not in
// the build yet. The guardian flows run on the catalog's real data since the
// level-data step (3-2 ends in King Coo and 3-4 in the Searchlight Gargoyle);
// they used to skip themselves until then and ran against a stand-in patch.
//
// Run with `--dart-define=CAPTURE_NY_UI=true` to write PNGs to
// build/visual-review/ny-ui/.
@Timeout(Duration(minutes: 10))
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/data/session_repository.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/campaign_story.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/knockout_art.dart';
import 'package:push_up_bird/game/play_controller.dart';
import 'package:push_up_bird/main.dart';
import 'package:push_up_bird/ui/components.dart';
import 'package:push_up_bird/ui/delivery_art.dart';
import 'package:push_up_bird/ui/level_intro.dart';
import 'package:push_up_bird/ui/play_screen.dart';
import 'package:push_up_bird/ui/theme.dart';

import 'campaign_save_test.dart' show levelRun;
import 'play_session_test.dart' show SilentAudio;
import 'recorded_flight.dart' show rideTheSky;

const _capture = bool.fromEnvironment('CAPTURE_NY_UI');

/// Chapters 1 and 2 and the New York levels before [upTo], all finished.
Map<String, int> _saveBefore(String upTo) {
  final stars = <String, int>{};
  for (final level in Campaign.levels) {
    if (level.id == upTo) break;
    stars[level.id] = 2;
  }
  return stars;
}

Future<void> _open(
  WidgetTester tester,
  Size size,
  String at, {
  bool reduced = true,
  Map<String, int> stars = const {},
  int bird = 0,
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  if (textScale != 1) {
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }
  final repo = SqliteProgressRepository(
    ProgressDatabase(NativeDatabase.memory()),
  );
  final folder = Directory.systemTemp.createTempSync('ny-ui-flow');
  await tester.runAsync(() async {
    await repo.setSetting(SettingKey.reducedMotion, reduced);
    await repo.equipBird(bird);
    var n = 0;
    for (final MapEntry(key: id, value: rating) in stars.entries) {
      final marks = Campaign.level(id)!.marks;
      await repo.saveRun(
        levelRun(
          'seed-${n++}',
          id,
          stars: rating == 3 ? marks.three : marks.two,
          score: 400 + n * 30,
          at: DateTime(2026, 9, 20, 12, n),
        ),
      );
    }
    for (final chapter in Campaign.chapters) {
      if (chapter.levels.every((l) => stars.containsKey(l.id))) {
        await repo.markPostcardSeen(chapter);
      }
    }
    for (final scene in CampaignStory.scenes) {
      await repo.markStoryWatched(scene);
    }
  });
  final container = ProviderContainer(
    overrides: [
      progressRepositoryProvider.overrideWithValue(repo),
      sessionRepositoryProvider.overrideWithValue(SessionRepository(folder)),
      audioFactoryProvider.overrideWithValue(() => SilentAudio()),
      trackingSourceFactoryProvider.overrideWithValue(
        () => throw StateError('Tap & Fly never opens the camera'),
      ),
    ],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await tester.runAsync(repo.close);
    if (folder.existsSync()) folder.deleteSync(recursive: true);
  });
  await tester.runAsync(() => container.read(progressProvider.future));
  appRouter.go(at);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const RepaintBoundary(
        key: ValueKey('visual-capture'),
        child: PushUpBirdApp(),
      ),
    ),
  );
  await tester.runAsync(() async {
    final context = tester.element(find.byType(Scaffold).first);
    for (final asset in [...birdAssets, 'island']) {
      await precacheImage(AssetImage('assets/images/$asset.png'), context);
    }
  });
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester, [int frames = 4]) async {
  for (var i = 0; i < frames; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

PlayController _controller(WidgetTester tester) =>
    (tester.state(find.byType(PlayScreen)) as dynamic).controller
        as PlayController;

Future<BirdGame> _game(WidgetTester tester) async {
  await tester.pump();
  final game = tester
      .widget<GameWidget<BirdGame>>(find.byType(GameWidget<BirdGame>))
      .game!;
  await tester.runAsync(() => game.loaded.timeout(const Duration(seconds: 5)));
  game.pauseEngine();
  await tester.pump();
  return game;
}

void _fly(PlayController controller, {bool Function(FlightSimulation)? until}) {
  final sim = controller.simulation!;
  for (var frame = 1; frame <= 400 * 50; frame++) {
    if (sim.phase == RunPhase.ended || (until?.call(sim) ?? false)) break;
    if (sim.hearts < 2) sim.hearts = 3;
    if (rideTheSky(sim)) controller.flap();
    if (sim.canSprint) controller.sprint();
    if (frame % 9 == 0 && sim.canCharge) controller.startCharge();
    if (frame % 9 == 3 && sim.charging) controller.shoot();
    controller.advance(.02, 0, 2.2);
    controller.tick();
  }
}

Future<void> _paint(WidgetTester tester, BirdGame game) async {
  game.resumeEngine();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
  game.pauseEngine();
  await tester.pump();
}

Future<void> _shot(WidgetTester tester, String name) async {
  if (!_capture) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('visual-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/visual-review/ny-ui/$name.png')
      ..parent.createSync(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

/// Flies [level] to its end (a boss level: to the boss, then it falls) and
/// lets the result stage settle.
Future<PlayController> _finish(
  WidgetTester tester,
  Size size,
  String level, {
  required Map<String, int> stars,
  bool boss = false,
  bool reduced = true,
  double textScale = 1,
}) async {
  await _open(
    tester,
    size,
    '/play/touch?level=$level',
    stars: stars,
    reduced: reduced,
    textScale: textScale,
  );
  final game = await _game(tester);
  final controller = _controller(tester);
  if (boss) {
    _fly(controller, until: (sim) => sim.boss != null);
    controller.simulation!.boss!.hp = 1;
    _fly(controller);
  } else {
    _fly(controller);
  }
  await _settle(tester);
  await _paint(tester, game);
  await tester.pump(const Duration(milliseconds: 2100));
  return controller;
}

/// Every label in the semantics tree, in reading order.
List<String> _semanticLabels(WidgetTester tester) {
  final labels = <String>[];
  void walk(SemanticsNode node) {
    if (node.label.isNotEmpty) labels.add(node.label);
    node.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  walk(tester.getSemantics(find.byType(Scaffold).first));
  return labels;
}

/// The beaten guardian's shield on the finish gate (`_TrophyPainter`).
final _trophy = find.byWidgetPredicate(
  (w) =>
      w is CustomPaint && w.painter.runtimeType.toString() == '_TrophyPainter',
);

bool _sealIsOrdinary(WidgetTester tester) {
  final seal = tester.widget<CustomPaint>(
    find.byKey(const ValueKey('level-result-seal')),
  );
  return (seal.painter! as DeliverySealPainter).boss == null;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

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
  setUp(() => Campaign.openedForTest = true);
  tearDown(() {
    Campaign.openedForTest = false;
    Campaign.closedForTest = false;
  });

  const sizes = [Size(640, 360), Size(800, 360)];

  test('the catalog\'s 3-2 and 3-4 are the guardians these flows need', () {
    // The nine guardian flows below used to skip until this data existed;
    // now they cannot silently skip again.
    expect(Campaign.level('3-2')!.isGuardian, isTrue);
    expect(Campaign.level('3-4')!.isGuardian, isTrue);
  });

  group('guardian result', () {
    for (final size in sizes) {
      final w = size.width.round();

      testWidgets('King Coo falls: Guardian down!, 3-3 opens, no postcard at '
          '$w', (tester) async {
        final handle = tester.ensureSemantics();
        await _finish(
          tester,
          size,
          '3-2',
          stars: _saveBefore('3-2'),
          boss: true,
        );
        expect(find.bySemanticsLabel('Guardian down!'), findsOneWidget);
        expect(find.bySemanticsLabel('Victory!'), findsNothing);
        expect(find.bySemanticsLabel('Delivered!'), findsNothing);
        expect(find.text('3-3 Steam Alley is open!'), findsOneWidget);
        expect(find.text('A postcard is waiting on the map!'), findsNothing);
        expect(find.text('Paris is coming soon!'), findsNothing);
        // Its goal is the guardian, and its thank-you is an ordinary friend's.
        expect(find.text('Guardian'), findsOneWidget);
        expect(find.text('Boss'), findsNothing);
        expect(_sealIsOrdinary(tester), isTrue);
        // The beaten guardian's shield hangs on the gate in place of its
        // FINISH sign.
        expect(_trophy, findsOneWidget);
        expect(find.byKey(const ValueKey('level-result-next')), findsOneWidget);
        await _shot(tester, 'result-guardian-coo-$w');
        handle.dispose();
      });

      testWidgets('the Gargoyle falls: Guardian down!, Paris is coming soon, '
          'no Next at $w', (tester) async {
        final handle = tester.ensureSemantics();
        await _finish(
          tester,
          size,
          '3-4',
          stars: _saveBefore('3-4'),
          boss: true,
        );
        expect(find.bySemanticsLabel('Guardian down!'), findsOneWidget);
        expect(find.text('Paris is coming soon!'), findsOneWidget);
        expect(find.text('A postcard is waiting on the map!'), findsNothing);
        expect(find.byKey(const ValueKey('level-result-next')), findsNothing);
        expect(find.byKey(const ValueKey('level-result-map')), findsOneWidget);
        expect(_sealIsOrdinary(tester), isTrue);
        await _shot(tester, 'result-guardian-gargoyle-$w');
        handle.dispose();
      });
    }

    testWidgets('a replayed guardian still says Guardian down! and, for 3-4, '
        'that Paris is coming soon', (tester) async {
      await _finish(
        tester,
        const Size(800, 360),
        '3-4',
        stars: {..._saveBefore('3-4'), '3-4': 3},
        boss: true,
      );
      expect(find.bySemanticsLabel('Guardian down!'), findsOneWidget);
      expect(find.text('Paris is coming soon!'), findsOneWidget);
    });
  });

  group('guardians on the map and card', () {
    for (final size in sizes) {
      final w = size.width.round();

      testWidgets('the map draws both shields and the card opens with its '
          'ribbon at $w', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(
          tester,
          size,
          '/campaign',
          stars: {..._saveBefore('3-2'), '3-1': 3},
        );
        expect(find.text('GUARDIAN'), findsNWidgets(2));
        expect(find.text('King Coo'), findsOneWidget);
        expect(find.text('Searchlight Gargoyle'), findsOneWidget);
        expect(
          find.bySemanticsLabel(RegExp(r'^[0-9]+ of 60 campaign stars$')),
          findsOneWidget,
        );
        await _shot(tester, 'app-map-next-guardian-$w');
        // The locked level before a guardian names it; the guardian's own
        // lock names the level before it.
        await tester.tap(find.byKey(const ValueKey('campaign-node-3-3')));
        await _settle(tester, 2);
        expect(find.text('Beat King Coo to unlock'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('campaign-node-3-2')));
        await _settle(tester, 2);
        expect(
          find.byKey(const ValueKey('level-intro-guardian')),
          findsOneWidget,
        );
        expect(find.text('BOSS FIGHT'), findsNothing);
        expect(
          find.text('Alley pigeons swoop in to grab stars. Shoot them first!'),
          findsOneWidget,
        );
        expect(find.text('Beat King Coo'), findsOneWidget);
        await _shot(tester, 'app-card-guardian-$w');
        handle.dispose();
      });
    }
  });

  group('guardian result with motion and a knockout', () {
    testWidgets('the word drops in with the entrance and the keys wait for '
        'it', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(
        tester,
        sizes[1],
        '/play/touch?level=3-2',
        stars: _saveBefore('3-2'),
        reduced: false,
      );
      final game = await _game(tester);
      final controller = _controller(tester);
      _fly(controller, until: (sim) => sim.boss != null);
      controller.simulation!.boss!.hp = 1;
      _fly(controller);
      await _settle(tester);
      await _paint(tester, game);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.bySemanticsLabel('Guardian down!'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 2200));
      expect(find.text('3-3 Steam Alley is open!'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _shot(tester, 'result-guardian-coo-motion-800');
      handle.dispose();
    });

    testWidgets('a knockout in a guardian\'s level wears a lavender chip, a '
        'chapter boss\'s a coral one', (tester) async {
      await _open(
        tester,
        sizes[1],
        '/play/touch?level=3-2',
        stars: _saveBefore('3-2'),
      );
      final game = await _game(tester);
      final controller = _controller(tester);
      _fly(controller, until: (sim) => sim.boss != null);
      final sim = controller.simulation!;
      sim
        ..hearts = 1
        ..shield = false
        ..invulnerableUntil = 0;
      for (var i = 0; i < 60 * 50 && sim.phase != RunPhase.ended; i++) {
        controller.advance(.02, 0, 2.2);
        controller.tick();
      }
      await _settle(tester);
      controller.knockout = KnockoutArt.skipAfter + .01;
      controller.skipKnockout();
      await _settle(tester);
      await _paint(tester, game);
      await tester.pump(const Duration(milliseconds: 2400));
      final chip = tester.widget<Container>(
        find
            .ancestor(of: find.text('3-2'), matching: find.byType(Container))
            .first,
      );
      expect((chip.decoration! as BoxDecoration).color, SkyColors.lavender);
      expect(find.text('3-2'), findsOneWidget);
      // What is left of him reads as health, not as "went away".
      expect(find.text('KING COO: 140 HP LEFT'), findsOneWidget);
      expect(find.text('KING COO LEFT'), findsNothing);
      expect(find.text('Both marks reached. Beat King Coo!'), findsOneWidget);
      await _shot(tester, 'knockout-guardian-800');
    });
  });

  testWidgets('a closed build (NEW_YORK_OPEN=false) keeps chapter 3 as plain '
      'locked coins', (tester) async {
    // New York is open as the build ships: the rollback state is forced here.
    Campaign.openedForTest = false;
    Campaign.closedForTest = true;
    await _open(tester, sizes[1], '/campaign', stars: _saveBefore('3-1'));
    final map = tester.state<ScrollableState>(find.byType(Scrollable));
    map.position.jumpTo(6 * sizes[1].width);
    await _settle(tester, 2);
    expect(find.text('GUARDIAN'), findsNothing);
    expect(find.text('Paris — coming soon'), findsNothing);
    expect(find.text('0 / 48'), findsNothing);
    expect(find.text('Coming soon'), findsWidgets);
    await _shot(tester, 'app-map-closed-new-york-800');
  });

  testWidgets('with a card open the map is out of the semantics tree, so a '
      'screen reader meets the card first', (tester) async {
    final handle = tester.ensureSemantics();
    await _open(tester, sizes[1], '/campaign', stars: const {'1-1': 3});
    expect(
      find.bySemanticsLabel(RegExp(r'^Level 1-1, First Delivery')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('campaign-node-1-1')));
    await _settle(tester, 2);
    expect(find.byType(LevelIntroCard), findsOneWidget);
    // The card is read; the map's nodes, keys and star total are not. (The
    // semantics tree itself is read: a finder by label also matches widgets
    // the tree has dropped.)
    var labels = _semanticLabels(tester);
    expect(
      labels.where((l) => l.startsWith('Level 1-1, First Delivery. Jungle')),
      hasLength(1),
    );
    expect(
      labels.where((l) => RegExp(r'^Level \d-\d, ').hasMatch(l)).length,
      1,
    );
    expect(labels, isNot(contains('Next stop')));
    expect(labels.where((l) => l.contains('campaign stars')), isEmpty);
    // Closing the card brings the map back.
    await tester.tap(find.byKey(const ValueKey('level-intro-close')));
    await _settle(tester, 2);
    labels = _semanticLabels(tester);
    expect(labels.where((l) => l.startsWith('Level 1-2, ')), hasLength(1));
    expect(labels, contains('Next stop'));
    handle.dispose();
  });

  group('large text', () {
    for (final size in sizes) {
      testWidgets('an ordinary result keeps its layout at 1.3x and 2x text at '
          '${size.width.round()}', (tester) async {
        for (final scale in [1.3, 2.0]) {
          await _finish(tester, size, '1-1', stars: const {}, textScale: scale);
          expect(tester.takeException(), isNull, reason: 'text $scale');
          expect(find.bySemanticsLabel('Delivered!'), findsOneWidget);
          // An ordinary level keeps the gate's own sign.
          expect(_trophy, findsNothing);
          expect(
            find.byKey(const ValueKey('level-result-next')),
            findsOneWidget,
          );
          // The keys stay on the screen and the scoreboard clear of them.
          final screen = Offset.zero & size;
          final keys = tester.getRect(
            find.byKey(const ValueKey('level-result-next')),
          );
          expect(screen.contains(keys.bottomRight), isTrue);
          await _shot(
            tester,
            'fix-result-text${(scale * 10).round()}-${size.width.round()}',
          );
          await tester.pumpWidget(const SizedBox());
        }
      });
    }

    testWidgets('a guardian result keeps its shield and its words at 1.3x', (
      tester,
    ) async {
      await _finish(
        tester,
        sizes[1],
        '3-4',
        stars: _saveBefore('3-4'),
        boss: Campaign.level('3-4')!.isBoss,
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Paris is coming soon!'), findsOneWidget);
      await _shot(tester, 'fix-result-guardian-text13-800');
    });
  });

  group('3-4 result', () {
    testWidgets('names Paris and hides Next after the last New York level', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final last = Campaign.level('3-4')!;
      await _finish(
        tester,
        const Size(800, 360),
        '3-4',
        stars: _saveBefore('3-4'),
        boss: last.isBoss,
      );
      expect(find.text('Paris is coming soon!'), findsOneWidget);
      expect(find.byKey(const ValueKey('level-result-next')), findsNothing);
      expect(find.text('3-5 Crystal Rooftops is open!'), findsNothing);
      expect(
        find.bySemanticsLabel(
          last.isGuardian ? 'Guardian down!' : 'Delivered!',
        ),
        findsOneWidget,
      );
      await _shot(tester, 'result-3-4-800');
      handle.dispose();
    });
  });
}
