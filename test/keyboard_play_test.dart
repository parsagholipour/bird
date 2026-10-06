// Keyboard play: a flight's keys, Esc as the back key, Fly Together's two
// key sets, and the campaign walked from the map to a flight by Enter.
@Timeout(Duration(minutes: 4))
library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/data/session_repository.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/main.dart';
import 'package:push_up_bird/ui/coop_screen.dart';
import 'package:push_up_bird/ui/home_screen.dart';
import 'package:push_up_bird/ui/play_screen.dart';
import 'package:push_up_bird/ui/settings_screen.dart';

import 'campaign_opening_screens_test.dart' show open, settle;
import 'play_session_test.dart' show SilentAudio;

Future<ProviderContainer> _app(WidgetTester tester, String at) async {
  tester.view.physicalSize = const Size(800, 360);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repo = SqliteProgressRepository(
    ProgressDatabase(NativeDatabase.memory()),
  );
  await repo.setSetting(SettingKey.reducedMotion, true);
  final folder = Directory.systemTemp.createTempSync('keyboard-play');
  addTearDown(() => folder.deleteSync(recursive: true));
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
  addTearDown(container.dispose);
  await container.read(progressProvider.future);
  appRouter.go(at);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const PushUpBirdApp(),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

/// The flight's game, loaded and held still, so each step is driven here.
Future<BirdGame> _game(WidgetTester tester) async {
  final game = tester
      .widget<GameWidget<BirdGame>>(find.byType(GameWidget<BirdGame>))
      .game!;
  await tester.runAsync(() => game.loaded);
  await tester.pump();
  game.pauseEngine();
  return game;
}

/// Runs the countdown out.
Future<void> _countDown(WidgetTester tester, BirdGame game) async {
  for (var i = 0; i < 151 && game.simulation.phase != RunPhase.playing; i++) {
    game.update(.02);
  }
  await tester.pump();
  expect(game.simulation.phase, RunPhase.playing);
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

  testWidgets('a keyboard flies, shoots, sprints and pauses an endless '
      'flight', (tester) async {
    await _app(tester, '/');
    await tester.tap(find.byKey(const ValueKey('endless')));
    await tester.pump();
    await tester.pump();
    expect(find.byType(PlayScreen), findsOneWidget);
    final game = await _game(tester);
    final sim = game.simulation;
    expect(sim.phase, RunPhase.countdown);
    // A key in the countdown flaps nothing, and the hint turns to keys.
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    game.update(.06); // The HUD's 50 ms refresh.
    await tester.pump();
    expect(sim.flaps, 0);
    expect(find.textContaining('Space to flap'), findsOneWidget);
    await _countDown(tester, game);

    // Space, W and Up flap; a held key flaps once.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    game.update(.02);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.space);
    game.update(.02);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    game.update(.02);
    expect(sim.flaps, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyW);
    game.update(.02);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    game.update(.02);
    expect(sim.flaps, 3);

    // Holding D charges a shot, letting go throws it.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyD);
    game.update(.02);
    await tester.pump();
    expect(sim.charging, isTrue);
    expect(sim.shots, 0);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyD);
    game.update(.02);
    await tester.pump();
    expect(sim.charging, isFalse);
    expect(sim.shots, 1);
    // A sprints; neither key flaps.
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    game.update(.02);
    await tester.pump();
    expect(sim.sprints, 1);
    expect(sim.flaps, 3);

    // Esc pauses and the card's Keep flying key has the focus, so Enter
    // flies on; P pauses and Esc resumes too.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(sim.phase, RunPhase.paused);
    expect(find.text('Take a breather.'), findsOneWidget);
    expect(find.byType(PlayScreen), findsOneWidget);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(sim.phase, isNot(RunPhase.paused));
    expect(find.text('Take a breather.'), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await tester.pump();
    expect(sim.phase, RunPhase.paused);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(sim.phase, isNot(RunPhase.paused));
    await _countDown(tester, game);

    // From the pause card, Left reaches Finish flight; the result's Fly
    // again key has the focus, and Enter flies again.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(sim.phase, RunPhase.paused);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Fly again'), findsOneWidget);
    final played = sim;
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump();
    final again = await _game(tester);
    expect(again.simulation, isNot(same(played)));
    expect(again.simulation.phase, RunPhase.countdown);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Esc goes back from a menu and stays home on the title '
      'screen', (tester) async {
    await _app(tester, '/settings');
    expect(find.byType(SettingsScreen), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    appRouter.go('/birds');
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Fly Together takes W, A, D and the arrows for its two '
      'players, and Esc pauses', (tester) async {
    await _app(tester, '/coop');
    expect(find.byType(CoopScreen), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('coop-start')));
    await tester.pump();
    final game = await _game(tester);
    final sim = game.simulation;
    await _countDown(tester, game);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyW);
    game.update(.02);
    expect((sim.lead.flaps, sim.partner!.flaps), (1, 0));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    game.update(.02);
    expect((sim.lead.flaps, sim.partner!.flaps), (1, 1));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    game.update(.02);
    await tester.pump();
    expect((sim.lead.sprints, sim.partner!.sprints), (0, 1));
    // Esc pauses rather than leaving the flight, and resumes it.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(sim.phase, RunPhase.paused);
    expect(find.byType(CoopScreen), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(sim.phase, isNot(RunPhase.paused));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Enter opens the next level from the map and flies it; Esc '
      'closes its card', (tester) async {
    await open(tester, const Size(800, 360), at: '/campaign');
    final intro = find.byKey(const ValueKey('level-intro-fly'));
    expect(intro, findsNothing);
    // The next level up has the focus: Enter opens its card.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settle(tester);
    expect(intro, findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(tester);
    expect(intro, findsNothing);
    // The level takes the focus back once its card closes.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settle(tester);
    expect(intro, findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settle(tester);
    final play = tester.widget<PlayScreen>(find.byType(PlayScreen));
    expect(play.level?.id, '1-1');
    expect(tester.takeException(), isNull);
  });
}
