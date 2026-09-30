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
import 'experience_ui_test.dart' show capture;
import 'play_session_test.dart' show SilentAudio;

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

  for (final bossNumber in [1, 2, 3]) {
    for (final width in [640.0, 800.0]) {
      testWidgets('boss $bossNumber fits with live touch controls at $width', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 360);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = SqliteProgressRepository(
          ProgressDatabase(NativeDatabase.memory()),
        );
        await repo.setSetting(SettingKey.reducedMotion, width == 640);
        final folder = Directory.systemTemp.createTempSync('boss-ui');
        final container = ProviderContainer(
          overrides: [
            progressRepositoryProvider.overrideWithValue(repo),
            sessionRepositoryProvider.overrideWithValue(
              SessionRepository(folder),
            ),
            audioFactoryProvider.overrideWithValue(() => SilentAudio()),
            trackingSourceFactoryProvider.overrideWithValue(
              () => throw StateError('Boss flights must not create a camera'),
            ),
          ],
        );
        await container.read(progressProvider.future);
        appRouter.go('/play/touch?practice=true&course=starTrail');
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const RepaintBoundary(
              key: ValueKey('visual-capture'),
              child: PushUpBirdApp(),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();
        await tester.tap(find.text('Start touch flight'));
        await tester.pump();
        final game = tester
            .widget<GameWidget<BirdGame>>(find.byType(GameWidget<BirdGame>))
            .game!;
        await tester.runAsync(() => game.loaded);
        await tester.pump();
        game.pauseEngine();
        Future<void> draw(String name) async {
          game.resumeEngine();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 16));
          game.pauseEngine();
          final prefix = bossNumber == 3
              ? name.replaceFirst('boss', 'dusk-moth-boss')
              : bossNumber == 2
              ? name.replaceFirst('boss', 'spitter-boss')
              : name;
          await capture(tester, '$prefix-${width.toInt()}');
        }

        for (var i = 0; i < 151; i++) {
          game.update(.02);
        }
        final sim = game.simulation;
        // The first Dusk Empress fights without her shield, so stage her
        // second encounter to cover the shield states.
        sim.bossesDefeated = bossNumber == 3 ? 6 : bossNumber - 1;
        sim.elapsed = FlightSimulation.bossInterval;
        game.update(.06);
        await tester.pump();
        expect(sim.boss!.phase, BossPhase.arriving);
        await draw('boss-arriving');

        void hover(double seconds) {
          for (var i = 0; i < (seconds / .02).round(); i++) {
            sim.birdY = .5;
            sim.velocity = 0;
            // Keep the staged moth capture alive while it hovers in the fan.
            // Legal-input survival is checked in dusk_moth_boss_test.
            if (sim.boss?.isMoth == true) sim.hearts = 3;
            game.update(.02);
          }
        }

        hover(1.3);
        await draw('boss-warning');
        hover(1.5);
        await draw('boss-reveal');
        hover(sim.boss!.arrivalDuration - sim.boss!.age + .15);
        final boss = sim.boss!;
        sim.birdY = boss.y;
        sim.velocity = 0;
        final shoot = find.byKey(const ValueKey('touch-shoot'));
        await tester.pump();
        await tester.tap(shoot);
        hover(.7);
        await tester.pump();
        expect(boss.hp, boss.maxHp - sim.weaponDamage);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.label ==
                    'Tap to flap. ${boss.name}: ${boss.hp} of ${boss.maxHp} health${boss.isMoth ? '. ${boss.shieldHint}' : ''}',
          ),
          findsOneWidget,
        );
        expect(sim.shots, 1);
        expect(sim.flaps, 0);
        if (boss.isMoth) {
          hover(boss.arrivalDuration + 4.5 - boss.age);
          expect(boss.shieldWarning, greaterThan(0));
          await draw('boss-shield-warning');
          hover(.7);
          expect(boss.shielded, isTrue);
          await draw('boss-shielded');
          expect(
            find.byWidgetPredicate(
              (widget) =>
                  widget is Semantics &&
                  (widget.properties.label?.contains('SHIELDED') ?? false),
            ),
            findsOneWidget,
          );
          final shieldHp = boss.hp;
          sim.rocks.add(BirdRock(x: boss.x - SkyBoss.shieldRadius, y: boss.y));
          game.update(.02);
          expect(boss.hp, shieldHp);
          expect(boss.lastShieldHitAt, closeTo(boss.age, .02));
          await draw('boss-shield-block');
        }
        if (!boss.isMoth) hover(4.8);
        boss.fireIn = .3;
        await tester.pump(const Duration(milliseconds: 16));
        await draw('boss-fighting');
        expect(tester.getSize(shoot).height, greaterThanOrEqualTo(44));
        expect(sim.obstacles, isEmpty);
        expect(tester.takeException(), isNull);

        boss.hp = 5;
        game.update(.06);
        await tester.pump();
        await draw('boss-furious');
        if (boss.isMoth && (boss.shielded || boss.shieldWarning > 0)) {
          hover(2.5);
        }
        sim.enemies.clear();
        sim.rocks.addAll(
          List.generate(5, (_) => BirdRock(x: boss.x - .07, y: boss.y)),
        );
        game.update(.06);
        await tester.pump();
        expect(sim.boss!.phase, BossPhase.defeated);
        await draw('boss-defeated');
        expect(tester.takeException(), isNull);
        hover(1.1);
        await draw('boss-burst');
        hover(1.1);
        await draw('boss-victory');
        hover(boss.departureDuration - (boss.age - boss.defeatedAt!) + .1);
        expect(sim.boss, isNull);
        expect(sim.obstacles, isNotEmpty);
        if (bossNumber == 1) {
          sim.hearts = 3;
          sim.heartPickups.add(SkyHeart(x: 1.1, y: .5));
          await draw('heart-pickup');
          sim.heartPickups.single.x = FlightSimulation.birdX;
          sim.birdY = .5;
          sim.velocity = 0;
          game.update(.06);
          await tester.pump();
          expect(sim.hearts, 4);
          expect(find.text('×4'), findsOneWidget);
          expect(
            find.byWidgetPredicate(
              (widget) =>
                  widget is Semantics &&
                  widget.properties.label == '4 hearts remaining',
            ),
            findsOneWidget,
          );
          await draw('heart-collected');
          sim.heartPickups.add(
            SkyHeart(x: FlightSimulation.birdX, y: sim.birdY),
          );
          game.update(.06);
          await tester.pump();
          expect(sim.hearts, 5);
          expect(find.text('×5'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(const SizedBox());
        container.dispose();
        await tester.runAsync(() async {
          await repo.close();
          await folder.delete(recursive: true);
        });
      });
    }
  }
}
