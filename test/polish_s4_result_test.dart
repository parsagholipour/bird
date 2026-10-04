// Polish checks and captures for the end of a campaign level: the result
// stage after a finish and the Bonk! stage after a knockout, at the three
// phone sizes. The checks always run: the panels say the right things, and
// the thank-you note for the delivery shows on a finished level only, holds
// its words and keeps clear of everything else on the stage.
//
// Run with `--dart-define=CAPTURE_POLISH=true` to write PNGs to
// build/visual-review/campaign/polish/s4-result/. Add
// `--dart-define=POLISH_ONLY=name` to render only the states whose name
// contains it.
@Timeout(Duration(minutes: 12))
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
import 'package:push_up_bird/ui/game_over_stage.dart' show StageBirdPainter;
import 'package:push_up_bird/ui/level_result.dart';
import 'package:push_up_bird/ui/play_screen.dart';
import 'package:push_up_bird/ui/stage_key.dart';
import 'package:push_up_bird/ui/theme.dart';

import 'campaign_save_test.dart' show levelRun;
import 'play_session_test.dart' show SilentAudio;
import 'recorded_flight.dart' show rideTheSky;
import 'bird_unlocks.dart';

const _capture = bool.fromEnvironment('CAPTURE_POLISH');
const _only = String.fromEnvironment('POLISH_ONLY');
const _folder = 'build/visual-review/campaign/polish/s4-result';

bool _want(String name) => _only.isEmpty || name.contains(_only);

CampaignLevel _level(String id) => Campaign.level(id)!;

/// Levels finished with [rating] stars each, the earlier ones of chapter 1
/// at three.
Future<void> _seed(
  ProgressRepository repo,
  Map<String, int> stars,
  int score,
) async {
  var n = 0;
  for (final MapEntry(key: id, value: rating) in stars.entries) {
    final marks = _level(id).marks;
    await repo.saveRun(
      levelRun(
        'seed-${n++}',
        id,
        stars: switch (rating) {
          3 => marks.three,
          2 => marks.two,
          _ => marks.two - 5,
        },
        score: score + n * 30,
        at: DateTime(2026, 9, 20, 12, n),
      ),
    );
  }
}

/// Chapter 1 done to its boss.
const _ch1 = {
  '1-1': 3,
  '1-2': 2,
  '1-3': 3,
  '1-4': 1,
  '1-5': 2,
  '1-6': 3,
  '1-7': 2,
};

Future<void> _open(
  WidgetTester tester,
  Size size,
  String at, {
  bool reduced = true,
  Map<String, int> stars = const {},
  int bird = 0,
  int seedScore = 400,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repo = SqliteProgressRepository(
    ProgressDatabase(NativeDatabase.memory()),
  );
  final folder = Directory.systemTemp.createTempSync('polish-s4');
  await tester.runAsync(() async {
    await repo.setSetting(SettingKey.reducedMotion, reduced);
    await unlockBirds(repo);
    await repo.equipBird(bird);
    await _seed(repo, stars, seedScore);
    // The story has been watched, so no scene plays on the way.
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

void _fly(
  PlayController controller, {
  bool Function(FlightSimulation sim)? until,
  int? collect,
}) {
  final sim = controller.simulation!;
  for (var frame = 1; frame <= 400 * 50; frame++) {
    if (sim.phase == RunPhase.ended || (until?.call(sim) ?? false)) break;
    if (sim.hearts < 2) sim.hearts = 3;
    if (collect != null && (sim.distanceToGo ?? 9) < .05) {
      sim.collectedStars = collect;
    }
    if (rideTheSky(sim)) controller.flap();
    if (sim.canSprint) controller.sprint();
    if (frame % 9 == 0 && sim.canCharge) controller.startCharge();
    if (frame % 9 == 3 && sim.charging) controller.shoot();
    controller.advance(.02, 0, 2.2);
    controller.tick();
  }
  // The game loop plays a finished level's celebration out before its
  // result.
  while (!controller.celebrationSettled) {
    controller.advance(.02, 0, 2.2);
  }
}

void _crash(PlayController controller) {
  final sim = controller.simulation!;
  sim
    ..hearts = 1
    ..shield = false
    ..invulnerableUntil = 0;
  for (var i = 0; i < 60 * 50 && sim.phase != RunPhase.ended; i++) {
    controller.advance(.02, 0, 2.2);
    controller.tick();
  }
}

void _skipKnockout(PlayController controller) {
  controller.knockout = KnockoutArt.skipAfter + .01;
  controller.skipKnockout();
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
    final file = File('$_folder/$name.png')..parent.createSync(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

/// One finished level: flown to its finish with [collect] stars, then shot
/// once the stage has settled.
Future<void> _finished(
  WidgetTester tester,
  Size size,
  String name,
  String level, {
  required int collect,
  Map<String, int> stars = const {},
  int bird = 0,
  bool boss = false,
  int seedScore = 400,
}) async {
  final w = size.width.round();
  await _open(
    tester,
    size,
    '/play/touch?level=$level',
    stars: stars,
    bird: bird,
    seedScore: seedScore,
  );
  final game = await _game(tester);
  final controller = _controller(tester);
  if (boss) {
    _fly(controller, until: (sim) => sim.boss != null);
    controller.simulation!.boss!.hp = 1;
    _fly(controller);
  } else {
    _fly(controller, collect: collect);
  }
  await _settle(tester);
  await _paint(tester, game);
  await tester.pump(const Duration(milliseconds: 2100));
  await _shot(tester, '$name-$w');
  await tester.pumpWidget(const SizedBox());
}

/// One failed level: crashed with [collect] stars in the bag, then shot on
/// the Bonk! stage.
Future<void> _fell(
  WidgetTester tester,
  Size size,
  String name,
  String level, {
  required int collect,
  int gates = 8,
  Map<String, int> stars = const {},
  int bird = 0,
  bool boss = false,
  int? bossHp,
}) async {
  final w = size.width.round();
  await _open(
    tester,
    size,
    '/play/touch?level=$level',
    stars: stars,
    bird: bird,
  );
  final game = await _game(tester);
  final controller = _controller(tester);
  if (boss) {
    _fly(controller, until: (sim) => sim.boss != null);
    if (bossHp != null) controller.simulation!.boss!.hp = bossHp;
    _fly(controller, until: (sim) => (sim.boss?.hp ?? 0) <= (bossHp ?? 0));
  } else {
    _fly(controller, until: (sim) => sim.gates >= gates);
  }
  controller.simulation!.collectedStars = collect;
  _crash(controller);
  await _settle(tester);
  _skipKnockout(controller);
  await _settle(tester);
  await _paint(tester, game);
  await tester.pump(const Duration(milliseconds: 2400));
  await _shot(tester, '$name-$w');
  await tester.pumpWidget(const SizedBox());
}

const _sizes = [Size(800, 360), Size(640, 360), Size(1000, 450)];

/// Chapter 2 open as far as 2-5, whose signer has the longest name.
const _toSkyfall = {..._ch1, '1-8': 2, '2-1': 3, '2-2': 2, '2-3': 3, '2-4': 2};

final _note = find.byKey(const ValueKey('level-result-note'));
final _seal = find.byKey(const ValueKey('level-result-seal'));
final _thanks = find.byKey(const ValueKey('level-result-thanks'));

RenderParagraph _paragraph(WidgetTester tester, Finder text) =>
    tester.renderObject<RenderParagraph>(
      find.descendant(of: text, matching: find.byType(RichText)),
    );

/// Where the note is drawn, seal and shadow included. The note leans a
/// little, so its corners reach just past the box its key reports.
Rect _noteRect(WidgetTester tester) =>
    tester.getRect(_note).expandToInclude(tester.getRect(_seal)).inflate(3);

/// The widest of the birds on the stage, in the courier painter's own
/// 380 x 346 space: its head at the top of its hop down to its lap, and out
/// to the tip of Minty's beak.
const _birdReach = Rect.fromLTRB(88, 59, 268, 241);

/// Everything else on a result stage that the note must keep clear of, by
/// name.
Map<String, Rect> _stageParts(WidgetTester tester, CampaignLevel level) {
  final word = level.isBoss ? 'Victory!' : 'Delivered!';
  final courier = tester.getRect(
    find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is StageBirdPainter,
    ),
  );
  final k = courier.width / StageBirdPainter.design.width;
  return {
    'title': tester.getRect(find.bySemanticsLabel(word)),
    'courier': Rect.fromLTRB(
      courier.left + _birdReach.left * k,
      courier.top + _birdReach.top * k,
      courier.left + _birdReach.right * k,
      courier.top + _birdReach.bottom * k,
    ),
    'plate': tester.getRect(
      find
          .ancestor(of: find.text(level.name), matching: find.byType(Container))
          .first,
    ),
    'scoreboard': tester.getRect(
      find
          .ancestor(
            of: find.text('STARS COLLECTED'),
            matching: find.byType(DecoratedBox),
          )
          .first,
    ),
    'stars': tester.getRect(find.bySemanticsLabel(RegExp(r'of 3 stars$'))),
    for (final (i, key) in find.byType(StageKey).evaluate().indexed)
      'key $i': tester.getRect(find.byWidget(key.widget)),
  };
}

void main() {
  // One test opens the app twice, with motion and without.
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

  group('panels', () {
    const phone = Size(800, 360);
    const open = {'1-1': 3, '1-2': 3, '1-3': 3};

    testWidgets('a two-star finish ticks its goals as they land and counts '
        'the rest to go', (tester) async {
      await _open(tester, phone, '/play/touch?level=1-4', stars: open);
      final game = await _game(tester);
      final controller = _controller(tester);
      _fly(controller, collect: 50);
      await _settle(tester);
      await _paint(tester, game);
      await tester.pump(const Duration(seconds: 2));
      expect(controller.levelStars, 2);
      expect(find.bySemanticsLabel('2 of 3 stars'), findsOneWidget);
      // Finish and the first mark are done; the last is 20 stars away.
      expect(find.text('Done'), findsNWidgets(2));
      expect(find.text('20 to go'), findsOneWidget);
      expect(find.text('First clear!'), findsOneWidget);
      expect(find.text('NEW BEST!'), findsNothing);
      expect(find.text('1-5 Express Post is open!'), findsOneWidget);
    });

    testWidgets('an interrupted first flight ticks nothing and has no best', (
      tester,
    ) async {
      await _open(tester, phone, '/play/touch?level=1-1');
      final game = await _game(tester);
      final controller = _controller(tester);
      _fly(controller, until: (sim) => sim.gates >= 6);
      controller.advance(.8, 0, 2.2);
      controller.tick();
      await _settle(tester);
      await _paint(tester, game);
      await tester.pump(const Duration(seconds: 2));
      expect(controller.result!.reason, EndReason.stalled);
      expect(find.bySemanticsLabel('0 of 3 stars'), findsOneWidget);
      expect(find.text('Done'), findsNothing);
      expect(find.text('Not yet'), findsOneWidget);
      // Only the score has a best to name, and there is none yet.
      expect(find.text('No best yet'), findsOneWidget);
      expect(find.text('Reach the finish to earn stars.'), findsOneWidget);
    });

    testWidgets('beating a level stamps NEW BEST on the count and the score', (
      tester,
    ) async {
      await _open(
        tester,
        phone,
        '/play/touch?level=1-4',
        stars: {...open, '1-4': 1},
        seedScore: 60,
      );
      final game = await _game(tester);
      final controller = _controller(tester);
      _fly(controller, collect: 75);
      await _settle(tester);
      await _paint(tester, game);
      await tester.pump(const Duration(seconds: 2));
      expect(controller.levelStars, 3);
      expect(find.text('NEW BEST!'), findsNWidgets(2));
      expect(find.text('Done'), findsNWidgets(3));
      expect(find.text('First clear!'), findsNothing);
    });

    testWidgets('a saved session turns the key into Watch replay and keeps the '
        'news in view', (tester) async {
      await _open(tester, phone, '/play/touch?level=1-4', stars: open);
      final game = await _game(tester);
      final controller = _controller(tester);
      _fly(controller, collect: 50);
      await _settle(tester);
      await _paint(tester, game);
      await tester.pump(const Duration(seconds: 2));
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('save-or-watch-session')));
        for (var i = 0; i < 100 && !controller.sessionSaved; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      await tester.pump();
      // The key says it, and the news strips keep the room.
      expect(find.text('Watch replay'), findsOneWidget);
      expect(find.text('Session saved · Watch in Records'), findsNothing);
      expect(find.text('1-5 Express Post is open!'), findsOneWidget);
    });

    testWidgets('the Bonk! panel names the next mark and the route flown', (
      tester,
    ) async {
      await _open(tester, phone, '/play/touch?level=1-4', stars: open);
      final game = await _game(tester);
      final controller = _controller(tester);
      _fly(controller, until: (sim) => sim.gates >= 8);
      controller.simulation!.collectedStars = 25;
      _crash(controller);
      await _settle(tester);
      _skipKnockout(controller);
      await _settle(tester);
      await _paint(tester, game);
      await tester.pump(const Duration(seconds: 3));
      // 1-4's first mark is 45, so a bag of 25 is about 20 short of two
      // stars.
      expect(find.textContaining(' more for'), findsOneWidget);
      expect(find.text('STARS COLLECTED'), findsOneWidget);
      expect(find.text('ROUTE FLOWN'), findsOneWidget);
      expect(find.text('1-4'), findsOneWidget);
    });
  });

  group('thanks', () {
    testWidgets('every delivery\'s note holds its thanks and its signer', (
      tester,
    ) async {
      for (final chapter in Campaign.chapters) {
        for (final level in chapter.levels) {
          final delivery = level.delivery;
          await tester.pumpWidget(
            MaterialApp(
              theme: skyTheme(),
              home: Scaffold(
                body: Center(
                  child: DeliveryNote(
                    delivery: delivery,
                    boss: level.boss,
                    seal: 1,
                  ),
                ),
              ),
            ),
          );
          final reason = level.id;
          expect(
            tester.widget<Text>(_thanks).data,
            '“${delivery.thanks}”',
            reason: reason,
          );
          expect(
            find.textContaining(delivery.thanks),
            findsOneWidget,
            reason: reason,
          );
          final signer = find.text('— ${delivery.from}');
          expect(signer, findsOneWidget, reason: reason);
          expect(
            find.bySemanticsLabel(
              'Thank-you note from ${delivery.from}: ${delivery.thanks}',
            ),
            findsOneWidget,
            reason: reason,
          );
          // Every word is written out, inside the paper, and the note is no
          // taller than the room the stage keeps for it.
          final paper = tester.getRect(_note);
          for (final text in [_thanks, signer]) {
            expect(
              _paragraph(tester, text).didExceedMaxLines,
              isFalse,
              reason: reason,
            );
            final words = tester.getRect(text);
            expect(
              paper.deflate(8).contains(words.topLeft) &&
                  paper.deflate(8).contains(words.bottomRight),
              isTrue,
              reason: '$reason: $words in $paper',
            );
          }
          expect(paper.width, DeliveryNote.width, reason: reason);
          expect(
            paper.height,
            lessThanOrEqualTo(DeliveryNote.maxHeight),
            reason: reason,
          );
        }
      }
    });

    for (final size in _sizes) {
      final w = size.width.round();

      // A plain level with the longest thanks, the level with the longest
      // signer (the tallest note) and a boss.
      for (final (id, stars, collect) in [
        ('1-1', const <String, int>{}, 40),
        ('2-5', _toSkyfall, 50),
        ('1-8', _ch1, 0),
      ]) {
        testWidgets('finishing $id brings its thank-you note, clear of the '
            'rest of the stage, at $w', (tester) async {
          final level = _level(id);
          await _open(tester, size, '/play/touch?level=$id', stars: stars);
          final game = await _game(tester);
          final controller = _controller(tester);
          if (level.isBoss) {
            _fly(controller, until: (sim) => sim.boss != null);
            controller.simulation!.boss!.hp = 1;
            _fly(controller);
          } else {
            _fly(controller, collect: collect);
          }
          await _settle(tester);
          await _paint(tester, game);
          expect(controller.levelComplete, isTrue);
          // Reduced Motion has the note in place from the first frame.
          final first = tester.getRect(_note);
          expect(
            tester
                .widget<Transform>(
                  find
                      .ancestor(of: _seal, matching: find.byType(Transform))
                      .first,
                )
                .transform
                .getMaxScaleOnAxis(),
            1,
          );
          await tester.pump(const Duration(seconds: 2));
          expect(tester.getRect(_note), first);

          final delivery = level.delivery;
          expect(find.textContaining(delivery.thanks), findsOneWidget);
          expect(tester.widget<Text>(_thanks).data, '“${delivery.thanks}”');
          expect(find.text('— ${delivery.from}'), findsOneWidget);
          expect(
            find.bySemanticsLabel(
              'Thank-you note from ${delivery.from}: ${delivery.thanks}',
            ),
            findsOneWidget,
          );
          expect(_paragraph(tester, _thanks).didExceedMaxLines, isFalse);

          final note = _noteRect(tester);
          final screen = Offset.zero & size;
          expect(
            screen.contains(note.topLeft) && screen.contains(note.bottomRight),
            isTrue,
            reason: '$note on $screen',
          );
          for (final MapEntry(key: name, value: rect) in _stageParts(
            tester,
            level,
          ).entries) {
            expect(
              note.overlaps(rect),
              isFalse,
              reason: 'the note $note over the $name $rect',
            );
          }
        });
      }

      testWidgets('an interrupted flight brings no note at $w', (tester) async {
        await _open(tester, size, '/play/touch?level=1-1');
        final game = await _game(tester);
        final controller = _controller(tester);
        _fly(controller, until: (sim) => sim.gates >= 6);
        controller.advance(.8, 0, 2.2);
        controller.tick();
        await _settle(tester);
        await _paint(tester, game);
        await tester.pump(const Duration(seconds: 2));
        expect(controller.levelComplete, isFalse);
        expect(find.bySemanticsLabel('Try again!'), findsOneWidget);
        expect(_note, findsNothing);
        expect(_thanks, findsNothing);
        expect(
          find.textContaining(_level('1-1').delivery.thanks),
          findsNothing,
        );
      });
    }

    testWidgets('the note flutters in after the title, as the last star '
        'lands, and settles where Reduced Motion puts it', (tester) async {
      const phone = Size(800, 360);
      Future<PlayController> finish({required bool reduced}) async {
        await _open(tester, phone, '/play/touch?level=1-1', reduced: reduced);
        final game = await _game(tester);
        final controller = _controller(tester);
        _fly(controller, collect: 60);
        await _settle(tester, 1);
        await _paint(tester, game);
        return controller;
      }

      double shown() => tester
          .widget<Opacity>(
            find.ancestor(of: _note, matching: find.byType(Opacity)).first,
          )
          .opacity;

      await finish(reduced: true);
      await tester.pump(const Duration(seconds: 2));
      final still = tester.getRect(_note);
      await tester.pumpWidget(const SizedBox());

      await finish(reduced: false);
      const entrance = LevelResultStage.entrance;
      // While the title is still landing the note has not set off.
      await tester.pump(entrance * (LevelResultStage.noteFrom - .2));
      expect(shown(), 0);
      // On its way down it is above where it will rest.
      await tester.pump(entrance * .2);
      expect(shown(), greaterThan(0));
      expect(tester.getRect(_note).center.dy, lessThan(still.center.dy));
      await tester.pump(entrance);
      expect(shown(), 1);
      final landed = tester.getRect(_note);
      expect(landed.left, closeTo(still.left, .01));
      expect(landed.top, closeTo(still.top, .01));
      expect(landed.size, still.size);
    });
  });

  group('capture', skip: !_capture, () {
    testWidgets('notes', (tester) async {
      if (!_want('notes')) return;
      // The notes on their own at twice their size: the longest thanks, the
      // longest signers, the shortest, the one in capitals and each boss's.
      tester.view.physicalSize = const Size(1000, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: skyTheme(),
          home: RepaintBoundary(
            key: const ValueKey('visual-capture'),
            child: Material(
              color: const Color(0xff6f9fae),
              child: FittedBox(
                child: SizedBox(
                  width: 920,
                  height: 700,
                  child: Center(
                    child: Wrap(
                      spacing: 22,
                      runSpacing: 30,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      children: [
                        for (final id in [
                          '1-1',
                          '2-5',
                          '2-6',
                          '3-2',
                          '4-1',
                          '4-2',
                          '5-4',
                          '5-5',
                          '3-7',
                          '1-4',
                          '1-8',
                          '2-8',
                          '3-8',
                          '4-8',
                          '5-8',
                        ])
                          DeliveryNote(
                            delivery: _level(id).delivery,
                            boss: _level(id).boss,
                            seal: 1,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      if (_capture) {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('visual-capture')),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('$_folder/notes.png')
            ..parent.createSync(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    });

    for (final size in _sizes) {
      final w = size.width.round();

      testWidgets('results at $w', (tester) async {
        // Chapter 1 levels 1-1 to 1-3 finished, 1-4 next (marks 45 / 70).
        const open = {'1-1': 3, '1-2': 3, '1-3': 3};
        if (_want('r3best')) {
          await _finished(
            tester,
            size,
            'r3best',
            '1-4',
            collect: 75,
            stars: {...open, '1-4': 1},
            bird: 1,
          );
        }
        if (_want('r3score')) {
          await _finished(
            tester,
            size,
            'r3score',
            '1-4',
            collect: 75,
            stars: {...open, '1-4': 1},
            bird: 2,
            seedScore: 60,
          );
        }
        if (_want('r3first')) {
          await _finished(
            tester,
            size,
            'r3first',
            '1-4',
            collect: 75,
            stars: open,
          );
        }
        if (_want('r2')) {
          await _finished(
            tester,
            size,
            'r2',
            '1-4',
            collect: 50,
            stars: open,
            bird: 2,
          );
        }
        if (_want('r1')) {
          await _finished(
            tester,
            size,
            'r1',
            '1-4',
            collect: 20,
            stars: open,
            bird: 3,
          );
        }
        if (_want('r1replay')) {
          await _finished(
            tester,
            size,
            'r1replay',
            '1-4',
            collect: 30,
            stars: {...open, '1-4': 3},
          );
        }
        if (_want('rboss')) {
          await _finished(
            tester,
            size,
            'rboss',
            '1-8',
            collect: 0,
            stars: _ch1,
            boss: true,
          );
        }
        if (_want('rbossagain')) {
          await _finished(
            tester,
            size,
            'rbossagain',
            '1-8',
            collect: 0,
            stars: {..._ch1, '1-8': 2},
            bird: 2,
            boss: true,
          );
        }
        if (_want('rch2')) {
          await _finished(
            tester,
            size,
            'rch2',
            '2-3',
            collect: 60,
            stars: {..._ch1, '1-8': 2, '2-1': 3, '2-2': 2},
            bird: 3,
          );
        }
        // The longest thanks, the longest signer and the widest lines the
        // playable chapters have.
        if (_want('rthanks-long')) {
          await _finished(
            tester,
            size,
            'rthanks-long',
            '1-1',
            collect: 60,
            bird: 2,
          );
        }
        if (_want('rthanks-signer')) {
          await _finished(
            tester,
            size,
            'rthanks-signer',
            '2-5',
            collect: 50,
            stars: {..._ch1, '1-8': 2, '2-1': 3, '2-2': 2, '2-3': 3, '2-4': 2},
            bird: 1,
          );
        }
        if (_want('rthanks-wide')) {
          await _finished(
            tester,
            size,
            'rthanks-wide',
            '2-6',
            collect: 40,
            stars: {
              ..._ch1,
              '1-8': 2,
              '2-1': 3,
              '2-2': 2,
              '2-3': 3,
              '2-4': 2,
              '2-5': 3,
            },
            bird: 3,
          );
        }
        if (_want('rlast')) {
          await _finished(
            tester,
            size,
            'rlast',
            '2-8',
            collect: 0,
            stars: {
              ..._ch1,
              '1-8': 2,
              '2-1': 3,
              '2-2': 2,
              '2-3': 3,
              '2-4': 2,
              '2-5': 3,
              '2-6': 2,
              '2-7': 3,
            },
            bird: 1,
            boss: true,
          );
        }
      });

      testWidgets('interrupted at $w', (tester) async {
        for (final (name, stars) in [
          ('rstall-first', const <String, int>{}),
          ('rstall-best', const {'1-1': 2}),
        ]) {
          if (!_want(name)) continue;
          await _open(
            tester,
            size,
            '/play/touch?level=1-1',
            stars: stars,
            bird: 1,
          );
          final game = await _game(tester);
          final controller = _controller(tester);
          _fly(controller, until: (sim) => sim.gates >= 6);
          controller.advance(.8, 0, 2.2);
          controller.tick();
          await _settle(tester);
          await _paint(tester, game);
          await tester.pump(const Duration(milliseconds: 2100));
          await _shot(tester, '$name-$w');
          await tester.pumpWidget(const SizedBox());
        }
      });

      testWidgets('session at $w', (tester) async {
        if (!_want('rsession')) return;
        await _open(
          tester,
          size,
          '/play/touch?level=1-4',
          stars: const {'1-1': 3, '1-2': 3, '1-3': 3},
          bird: 3,
        );
        final game = await _game(tester);
        final controller = _controller(tester);
        _fly(controller, collect: 50);
        await _settle(tester);
        await _paint(tester, game);
        await tester.pump(const Duration(seconds: 2));
        await tester.runAsync(() async {
          await tester.tap(find.byKey(const ValueKey('save-or-watch-session')));
          for (var i = 0; i < 100 && !controller.sessionSaved; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 10));
          }
        });
        await tester.pump();
        await _shot(tester, 'rsession-$w');
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('motion at $w', (tester) async {
        if (!_want('motion')) return;
        await _open(
          tester,
          size,
          '/play/touch?level=1-4',
          reduced: false,
          stars: const {'1-1': 3, '1-2': 3, '1-3': 3},
          bird: 2,
        );
        final game = await _game(tester);
        final controller = _controller(tester);
        _fly(controller, collect: 80);
        await _settle(tester, 1);
        await _paint(tester, game);
        for (var ms = 100; ms <= 1900; ms += 100) {
          await tester.pump(const Duration(milliseconds: 100));
          if (w == 800 || ms % 300 == 0) {
            await _shot(tester, 'motion-${ms.toString().padLeft(4, '0')}-$w');
          }
        }
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('game over at $w', (tester) async {
        const open = {'1-1': 3, '1-2': 3, '1-3': 3};
        if (_want('o-below')) {
          await _fell(
            tester,
            size,
            'o-below',
            '1-4',
            collect: 24,
            stars: open,
            bird: 1,
          );
        }
        if (_want('o-between')) {
          await _fell(
            tester,
            size,
            'o-between',
            '1-4',
            collect: 55,
            stars: open,
            bird: 2,
          );
        }
        if (_want('o-marks')) {
          await _fell(
            tester,
            size,
            'o-marks',
            '1-4',
            collect: 80,
            stars: open,
            bird: 3,
          );
        }
        if (_want('o-early')) {
          await _fell(tester, size, 'o-early', '1-1', collect: 0, gates: 1);
        }
        if (_want('o-boss')) {
          await _fell(
            tester,
            size,
            'o-boss',
            '1-8',
            collect: 20,
            stars: _ch1,
            boss: true,
            bossHp: 70,
          );
        }
        if (_want('o-ch2')) {
          await _fell(
            tester,
            size,
            'o-ch2',
            '2-4',
            collect: 35,
            gates: 20,
            stars: {..._ch1, '1-8': 2, '2-1': 3, '2-2': 2, '2-3': 3},
            bird: 3,
          );
        }
      });
    }
  });
}
