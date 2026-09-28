import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/boss_art.dart';
import 'package:push_up_bird/game/boss_ammo_art.dart';
import 'package:push_up_bird/game/combat_art.dart';
import 'package:push_up_bird/game/enemy_art.dart';
import 'package:push_up_bird/game/enemy_defeat_art.dart';
import 'package:push_up_bird/game/enemy_hit_art.dart';
import 'package:push_up_bird/ui/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'directional enemies render at gameplay scale and through attacks',
    (tester) async {
      await tester.runAsync(() async {
        for (final family in ['Fredoka', 'Nunito']) {
          await (FontLoader(
            family,
          )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
        }
        final folder = Directory('build/visual-review/small-enemies');
        folder.createSync(recursive: true);
        Future<List<int>> raster(
          void Function(Canvas) draw,
          String? name, {
          int width = 1600,
          int height = 600,
        }) async {
          final recorder = ui.PictureRecorder();
          draw(Canvas(recorder));
          final picture = recorder.endRecording();
          final image = await picture.toImage(width, height);
          final pixels = (await image.toByteData())!.buffer.asUint8List();
          if (name != null) {
            final png = (await image.toByteData(
              format: ui.ImageByteFormat.png,
            ))!.buffer.asUint8List();
            File('${folder.path}/$name.png').writeAsBytesSync(png);
          }
          image.dispose();
          picture.dispose();
          return pixels;
        }

        for (var appearance = 0; appearance < 4; appearance++) {
          final sim = FlightSimulation(rules: TapFlyMode(), practice: true)
            ..elapsed = 5;
          final enemy = SkyEnemy(
            x: .5,
            y: .5,
            appearance: appearance,
            flightPhase: appearance * 2.399963,
          )..age = 1;
          sim.enemies.add(enemy);
          void draw(Canvas c, bool reduced) {
            // Gameplay motion remains visible under Reduced Motion. Compare
            // the character at a fixed center to check decorative wing/bank pose.
            sim.birdY = enemy.y;
            c.translate(0, (.5 - enemy.y) * 200);
            CombatArt.paint(c, 200, sim, reducedMotion: reduced);
          }

          final first = await raster(
            (c) => draw(c, false),
            null,
            width: 200,
            height: 200,
          );
          final still = await raster(
            (c) => draw(c, true),
            null,
            width: 200,
            height: 200,
          );
          enemy.age = 2.3;
          sim.elapsed = 6.3;
          final later = await raster(
            (c) => draw(c, false),
            null,
            width: 200,
            height: 200,
          );
          final frozen = await raster(
            (c) => draw(c, true),
            null,
            width: 200,
            height: 200,
          );
          expect(
            first,
            isNot(equals(later)),
            reason: 'articulated wings $appearance',
          );
          expect(still, frozen, reason: 'Reduced Motion $appearance');

          for (final reduced in [false, true]) {
            Future<List<int>> body() => raster(
              (c) => EnemyArt.paint(
                c,
                200,
                enemy,
                birdY: enemy.y,
                reducedMotion: reduced,
              ),
              null,
              width: 200,
              height: 200,
            );
            enemy.lastHitAt = double.negativeInfinity;
            final beforeHit = await body();
            enemy.takeDamage(1);
            final impact = await body();
            expect(
              impact,
              isNot(equals(beforeHit)),
              reason: 'visible hit on $appearance, reduced: $reduced',
            );
            expect(await body(), impact, reason: 'paused frame stays exact');

            enemy.age += EnemyHitArt.hitSeconds;
            final settled = await body();
            enemy.lastHitAt = double.negativeInfinity;
            expect(await body(), settled, reason: 'hit leaves no residual art');
          }
        }

        await raster((c) => _lineup(c, 1.1), 'lineup');
        await raster(
          (c) => _ammoDesign(c, 0),
          'ammo-design',
          width: 1120,
          height: 580,
        );
        await raster(
          (c) => _ammoDesign(c, 1.33, includeBoss: true),
          'ammo-family-design',
          width: 1120,
          height: 820,
        );
        for (final attack in [EnemyAttack.aimed, EnemyAttack.fan]) {
          for (final fromBoss in [false, true]) {
            final sim = FlightSimulation(rules: TapFlyMode(), practice: true)
              ..elapsed = 2;
            if (fromBoss) {
              // Keep the boss outside the raster so only projectile motion is
              // compared, through the renderer used by the actual encounter.
              sim.boss = SkyBoss(
                number: 2,
                x: 2,
                kind: attack == EnemyAttack.aimed
                    ? BossKind.spitterBeetle
                    : BossKind.duskMoth,
                cinematic: true,
              )..age = 5;
              sim.bossAmmo.add(BossAmmo(x: .28, y: .28, vx: -.4, vy: -.1));
            } else {
              sim.enemyAmmo.add(
                EnemyAmmo(x: .28, y: .28, vx: -.4, vy: -.1, attack: attack),
              );
            }
            Future<List<int>> frame({bool reduced = false}) => raster(
              (c) => fromBoss
                  ? BossArt.paint(
                      c,
                      const Size(800, 360),
                      sim,
                      reducedMotion: reduced,
                    )
                  : CombatArt.paint(c, 360, sim, reducedMotion: reduced),
              null,
              width: 200,
              height: 200,
            );
            final first = await frame();
            final still = await frame(reduced: true);
            expect(
              await frame(),
              first,
              reason: '$attack stays exact when paused',
            );
            sim.elapsed += .17;
            expect(
              await frame(),
              isNot(equals(first)),
              reason: '$attack animates at gameplay size',
            );
            expect(
              await frame(reduced: true),
              still,
              reason: '$attack respects Reduced Motion',
            );
            sim.elapsed = 2;
            expect(
              await frame(),
              first,
              reason: '$attack restores on replay seek',
            );
          }
        }
        if (const bool.fromEnvironment('CAPTURE_AMMO_MOVIE')) {
          for (var frame = 0; frame < 120; frame++) {
            await raster(
              (c) => _ammoDesign(c, frame / 30),
              'ammo-${frame.toString().padLeft(4, '0')}',
              width: 1120,
              height: 580,
            );
          }
        }
        if (const bool.fromEnvironment('CAPTURE_BOSS_AMMO_MOVIE')) {
          for (var frame = 0; frame < 120; frame++) {
            await raster(
              (c) => _ammoDesign(c, frame / 30, includeBoss: true),
              'ammo-family-${frame.toString().padLeft(4, '0')}',
              width: 1120,
              height: 820,
            );
          }
        }
        for (final reduced in [false, true]) {
          final sim = FlightSimulation(rules: TapFlyMode(), practice: true)
            ..elapsed = 2;
          final blank = await raster(
            (c) => CombatArt.paint(c, 200, sim, reducedMotion: reduced),
            null,
            width: 200,
            height: 200,
          );
          sim.events.add(
            const FlightEvent(FlightEventKind.enemyHit, 2, .5, gateWorldX: .5),
          );
          Future<List<int>> burst() => raster(
            (c) => CombatArt.paint(c, 200, sim, reducedMotion: reduced),
            null,
            width: 200,
            height: 200,
          );
          final impact = await burst();
          expect(
            impact,
            isNot(equals(blank)),
            reason: 'defeat is visible after the enemy is removed',
          );
          sim.elapsed += .15;
          final later = await burst();
          expect(later, isNot(equals(impact)));
          sim.elapsed = 2;
          expect(await burst(), impact, reason: 'seeking restores the effect');
          sim.elapsed += EnemyDefeatArt.seconds;
          expect(await burst(), blank, reason: 'defeat particles expire');
          await raster(
            (c) => _hitFeedback(c, reducedMotion: reduced),
            reduced ? 'hit-feedback-reduced' : 'hit-feedback',
            width: 1440,
            height: 790,
          );
        }
        await raster(
          (c) {
            c.drawPaint(Paint()..color = const Color(0xffc6e5e5));
            _text(
              c,
              'ENEMY HEALTH · 10 DAMAGE PER SHOT',
              const Offset(32, 24),
              24,
            );
            final sim = FlightSimulation(rules: TapFlyMode(), practice: true);
            for (var i = 0; i < 4; i++) {
              final enemy = SkyEnemy(
                x: .4 + i * .7,
                y: .5,
                appearance: i,
                maxHp: 30,
              );
              if (i > 0) {
                enemy.takeDamage(i == 1 ? 10 : 20);
                enemy.age = .3;
              }
              sim.enemies.add(enemy);
              _text(
                c,
                '${enemy.hp} / ${enemy.maxHp} HP',
                Offset(enemy.x * 360 - 42, 230),
                18,
              );
            }
            CombatArt.paint(c, 360, sim, reducedMotion: true);
          },
          'health-bars',
          width: 1200,
          height: 300,
        );
        await raster(
          (c) => _spitter(c, 1.35),
          'spitter-detail',
          width: 1000,
          height: 520,
        );
        const captureSpitter = bool.fromEnvironment('CAPTURE_SPITTER_MOVIE');
        if (captureSpitter) {
          for (var frame = 0; frame < 150; frame++) {
            await raster(
              (c) => _spitter(c, frame / 30),
              'spitter-${frame.toString().padLeft(4, '0')}',
              width: 1000,
              height: 520,
            );
          }
        }
        const captureMovie = bool.fromEnvironment('CAPTURE_ENEMY_MOVIE');
        if (captureMovie) {
          for (var frame = 0; frame < 120; frame++) {
            await raster(
              (c) => _lineup(c, frame / 30),
              'frame-${frame.toString().padLeft(4, '0')}',
            );
          }
        }
      });
    },
  );

  testWidgets('small enemies and both ammo types render in the actual game', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final sim = FlightSimulation(rules: TapFlyMode(), practice: true)
      ..phase = RunPhase.playing
      ..elapsed = 21;
    for (var kind = 0; kind < 3; kind++) {
      sim.enemies.add(
        SkyEnemy(
            x: 1.35 + kind * .30,
            y: .28 + kind * .22,
            appearance: kind,
            flightPhase: kind * 2.399963,
          )
          ..age = 1.8
          ..preparing = kind > 0
          ..fireIn = .15,
      );
    }
    sim.enemies.add(
      SkyEnemy(x: 1.03, y: .27, appearance: 3, flightPhase: 2.1)..age = 1.8,
    );
    sim.enemyAmmo.add(
      EnemyAmmo(x: 1.07, y: .51, vx: -.44, vy: 0, attack: EnemyAttack.aimed),
    );
    for (final angle in [-.3, 0.0, .3]) {
      sim.enemyAmmo.add(
        EnemyAmmo(
          x: 1.56,
          y: .72 + angle * .3,
          vx: -.34 * math.cos(angle),
          vy: .34 * math.sin(angle),
          attack: EnemyAttack.fan,
        ),
      );
    }
    final game = BirdGame(
      simulation: sim,
      nowMs: () => 0,
      bird: 0,
      reducedMotion: false,
      playback: true,
      onChanged: () {},
    );
    await tester.pumpWidget(GameWidget(game: game));
    await tester.runAsync(() async {
      await game.loaded;
      game.pauseEngine();
      final folder = Directory('build/visual-review/small-enemies')
        ..createSync(recursive: true);
      Future<void> capture(String name) async {
        final recorder = ui.PictureRecorder();
        game.render(Canvas(recorder));
        final picture = recorder.endRecording();
        final image = await picture.toImage(800, 360);
        final bytes = (await image.toByteData(
          format: ui.ImageByteFormat.png,
        ))!.buffer.asUint8List();
        File('${folder.path}/$name.png').writeAsBytesSync(bytes);
        expect(bytes.length, greaterThan(2000));
        image.dispose();
        picture.dispose();
      }

      await capture('in-game');
      for (var i = 0; i < sim.enemies.length; i++) {
        sim.enemies[i].takeDamage(5);
        sim.enemies[i].age += .02 + i * .025;
      }
      sim.events.add(
        FlightEvent(
          FlightEventKind.enemyHit,
          sim.elapsed - .06,
          .77,
          gateWorldX: sim.distance + 1.1,
          value: 3,
        ),
      );
      await capture('hit-feedback-in-game');
    });
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}

void _ammoDesign(Canvas c, double seconds, {bool includeBoss = false}) {
  c.drawPaint(Paint()..color = const Color(0xfff2eedf));
  _text(
    c,
    includeBoss ? 'ENEMY & BOSS AMMO' : 'SMALL ENEMY AMMO',
    const Offset(28, 22),
    28,
  );
  _text(
    c,
    includeBoss
        ? 'Related palettes · distinct boss silhouettes and motion'
        : 'Mint spit & amber embers · detail and actual gameplay size',
    const Offset(28, 62),
    17,
  );
  for (var kind = 0; kind < 2; kind++) {
    final left = 24.0 + kind * 548;
    final attack = kind == 0 ? EnemyAttack.aimed : EnemyAttack.fan;
    final panel = Rect.fromLTWH(left, 106, 524, includeBoss ? 690 : 450);
    c.drawRRect(
      RRect.fromRectAndRadius(panel, const Radius.circular(22)),
      Paint()..color = SkyColors.cream,
    );
    _text(
      c,
      includeBoss
          ? kind == 0
                ? 'Spit / pressurized globule'
                : 'Ember / pollen rosette'
          : kind == 0
          ? 'Spitter beetle / mint spit'
          : 'Dusk moth / amber ember',
      Offset(left + 22, 126),
      23,
    );
    _text(
      c,
      includeBoss
          ? kind == 0
                ? 'Wobbling droplet / swirling liquid shell'
                : 'Fluttering fins / rotating petal blades'
          : kind == 0
          ? 'Liquid wobble · drifting droplets'
          : 'Flickering core · fluttering tails',
      Offset(left + 22, 161),
      16,
    );
    final detailHeight = includeBoss ? 1875.0 : 2500.0;
    EnemyArt.ammo(
      c,
      detailHeight,
      EnemyAmmo(
        x: (left + (includeBoss ? 98 : 145)) / detailHeight,
        y: 262 / detailHeight,
        vx: -1,
        vy: 0,
        attack: attack,
      ),
      seconds: seconds,
      reducedMotion: false,
    );
    if (includeBoss) {
      BossAmmoArt.paint(
        c,
        center: Offset(left + 332, 262),
        radius: 38,
        direction: math.pi,
        attack: attack,
        seconds: seconds,
        reducedMotion: false,
      );
      _text(c, 'SMALL', Offset(left + 73, 319), 12, color: SkyColors.purple);
      _text(c, 'BOSS', Offset(left + 312, 319), 12, color: SkyColors.purple);
    } else {
      EnemyArt.paint(
        c,
        720,
        SkyEnemy(x: (left + 421) / 720, y: 262 / 720, appearance: kind + 1)
          ..age = 1.8,
        birdY: 262 / 720,
        reducedMotion: true,
      );
    }
    _text(
      c,
      'AT GAMEPLAY SIZE · 360px HIGH VIEWPORT',
      Offset(left + 22, 350),
      12,
      color: SkyColors.purple,
      weight: FontWeight.w900,
    );
    for (var sky = 0; sky < 2; sky++) {
      final preview = Rect.fromLTWH(left + 16 + sky * 252, 381, 240, 156);
      c.save();
      c.clipRRect(RRect.fromRectAndRadius(preview, const Radius.circular(14)));
      c.drawRect(
        preview,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: sky == 0
                ? const [Color(0xffbde9f6), Color(0xfff9efd8)]
                : const [Color(0xff8f86bf), Color(0xffd2a9af)],
          ).createShader(preview),
      );
      _text(
        c,
        sky == 0 ? 'DAYLIGHT' : 'DUSK',
        preview.topLeft + const Offset(14, 12),
        11,
      );
      EnemyArt.paint(
        c,
        360,
        SkyEnemy(
          x: (preview.left + 190) / 360,
          y: (preview.top + 91) / 360,
          appearance: kind + 1,
        )..age = 1.8,
        birdY: (preview.top + 91) / 360,
        reducedMotion: true,
      );
      for (final angle in kind == 0 ? [0.0] : [-.3, 0.0, .3]) {
        EnemyArt.ammo(
          c,
          360,
          EnemyAmmo(
            x: (preview.left + 72) / 360,
            y: (preview.top + 91 + angle * 94) / 360,
            vx: -math.cos(angle),
            vy: math.sin(angle),
            attack: attack,
          ),
          seconds: seconds,
          reducedMotion: false,
        );
      }
      c.restore();
    }
    if (includeBoss) {
      final preview = Rect.fromLTWH(left + 16, 553, 492, 224);
      c.save();
      c.clipRRect(RRect.fromRectAndRadius(preview, const Radius.circular(14)));
      c.drawRect(preview, Paint()..color = const Color(0xff243a47));
      _text(
        c,
        kind == 0
            ? 'SPITTER KING · PRESSURIZED GLOBULES'
            : 'DUSK EMPRESS · POLLEN ROSETTES',
        preview.topLeft + const Offset(14, 12),
        12,
        color: SkyColors.cream,
      );
      c.translate(preview.left, preview.top);
      final boss =
          SkyBoss(
              number: kind + 2,
              x: 1.04,
              kind: kind == 0 ? BossKind.spitterBeetle : BossKind.duskMoth,
              cinematic: true,
            )
            ..y = .35
            ..age = 5 + seconds;
      final cycle = seconds % 2;
      // A staged charge, release and travelling fan uses the real boss renderer.
      boss.fireIn = cycle < .65 ? .65 - cycle : 1;
      if (cycle >= .65) boss.lastVolleyAt = boss.age - (cycle - .65);
      final sim = FlightSimulation(rules: TapFlyMode(), practice: true)
        ..elapsed = seconds
        ..boss = boss;
      if (cycle >= .65) {
        for (final angle in boss.volleyOffsets) {
          sim.bossAmmo.add(
            BossAmmo(
              x:
                  boss.muzzleX -
                  (cycle - .65) * boss.projectileSpeed * math.cos(angle),
              y:
                  boss.y +
                  (cycle - .65) * boss.projectileSpeed * math.sin(angle),
              vx: -boss.projectileSpeed * math.cos(angle),
              vy: boss.projectileSpeed * math.sin(angle),
            ),
          );
        }
      }
      BossArt.paint(c, const Size(492, 360), sim, reducedMotion: false);
      c.restore();
    }
  }
}

void _hitFeedback(Canvas c, {required bool reducedMotion}) {
  c.drawPaint(Paint()..color = const Color(0xffc6e5e5));
  _text(
    c,
    'HIT FEEDBACK${reducedMotion ? ' · REDUCED MOTION' : ''}',
    const Offset(24, 20),
    24,
  );
  const ages = [-1.0, .02, .08, .18, .30, .02, .15, .30];
  const labels = [
    'Before',
    'Hit · 20ms',
    '80ms',
    '180ms',
    'Settled',
    'Defeat · 20ms',
    '150ms',
    '300ms',
  ];
  for (var col = 0; col < ages.length; col++) {
    _text(c, labels[col], Offset(col * 180 + 18, 65), 16);
  }
  for (var appearance = 0; appearance < 4; appearance++) {
    final top = 102.0 + appearance * 170;
    _text(c, EnemyKind.values[appearance].name, Offset(18, top), 15);
    for (var col = 0; col < ages.length; col++) {
      c.save();
      c.translate(col * 180 - 170, top + 24);
      final sim = FlightSimulation(rules: TapFlyMode(), practice: true)
        ..elapsed = 2 + math.max(0, ages[col]);
      if (col < 5) {
        final enemy = SkyEnemy(x: .725, y: .17, appearance: appearance)
          ..age = 1;
        if (col > 0) enemy.takeDamage(5);
        enemy.age += math.max(0, ages[col]);
        sim.enemies.add(enemy);
      } else {
        sim.events.add(
          const FlightEvent(FlightEventKind.enemyHit, 2, .17, gateWorldX: .725),
        );
      }
      CombatArt.paint(c, 360, sim, reducedMotion: reducedMotion);
      c.restore();
    }
  }
}

void _text(
  Canvas c,
  String text,
  Offset at,
  double size, {
  Color color = SkyColors.ink,
  FontWeight weight = FontWeight.w600,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'Nunito',
        fontSize: size,
        fontWeight: weight,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(c, at);
}

void _lineup(Canvas c, double seconds) {
  c.drawRect(
    const Rect.fromLTWH(0, 0, 1600, 600),
    Paint()..color = const Color(0xfff2eedf),
  );
  _text(c, 'SMALL ENEMIES', const Offset(34, 22), 24, weight: FontWeight.w900);
  _text(
    c,
    'Gentle flight arcs • slight banking • independent wingbeats',
    const Offset(34, 56),
    17,
  );
  const appearances = [3, 1, 2, 0];
  const names = ['Bat', 'Spitter beetle', 'Dusk moth', 'Cave bat'];
  const descriptions = [
    'Simple purple bat • no crown',
    'One aimed seed shot',
    'Three slower shots in a fan',
    'Natural bat, kept as its own character',
  ];
  final clock = seconds % 4;
  final fireIn = 1.5 - clock;
  for (var kind = 0; kind < appearances.length; kind++) {
    final left = 24.0 + kind * 394;
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, 98, 370, 474),
        const Radius.circular(22),
      ),
      Paint()..color = const Color(0xfffaf8ed),
    );
    _text(c, names[kind], Offset(left + 24, 118), 24, weight: FontWeight.w900);
    _text(c, descriptions[kind], Offset(left + 24, 153), 16);
    final shoots = kind == 1 || kind == 2;
    final enemy =
        SkyEnemy(
            x: 1,
            y: 0,
            appearance: appearances[kind],
            flightPhase: kind * 2.399963,
          )
          ..age = seconds
          ..preparing = shoots && clock < 1.5
          ..fireIn = fireIn
          ..lastShotAt = shoots && clock >= 1.5
              ? seconds - (clock - 1.5)
              : double.negativeInfinity;
    c.save();
    c.translate(left + 165 - 1333.333, 294);
    // Pass the real renderer a larger scale for inspection; the lower copy
    // is exactly the size used in an 800×360 game viewport.
    EnemyArt.paint(c, 1333.333, enemy, birdY: 0, reducedMotion: false);
    c.restore();
    _text(
      c,
      'GAMEPLAY SIZE',
      Offset(left + 24, 413),
      12,
      color: SkyColors.purple,
      weight: FontWeight.w900,
    );
    c.save();
    c.translate(left + 204 - 360, 473);
    EnemyArt.paint(c, 360, enemy, birdY: 0, reducedMotion: false);
    if (shoots && clock >= 1.5) {
      final t = (clock - 1.5);
      for (final angle in kind == 2 ? [-.30, 0.0, .30] : [0.0]) {
        final speed = kind == 2 ? .16 : .22;
        final ammo = EnemyAmmo(
          x: enemy.muzzleX - t * speed * math.cos(angle),
          y: t * speed * math.sin(angle),
          vx: -speed * math.cos(angle),
          vy: speed * math.sin(angle),
          attack: enemy.attack,
        );
        EnemyArt.ammo(c, 360, ammo, seconds: seconds, reducedMotion: false);
      }
    }
    c.restore();
    final state = !shoots
        ? 'Patrol'
        : clock < .75
        ? 'Watch'
        : clock < 1.5
        ? 'Charge'
        : clock < 1.74
        ? 'Recoil'
        : 'Recover';
    _text(c, state, Offset(left + 24, 531), 14, color: SkyColors.purple);
  }
}

void _spitter(Canvas c, double seconds) {
  c.drawRect(
    const Rect.fromLTWH(0, 0, 1000, 520),
    Paint()..color = const Color(0xfff2eedf),
  );
  _text(c, 'SPITTER BEETLE', const Offset(32, 22), 26, weight: FontWeight.w900);
  _text(
    c,
    'Flight • anticipation • aimed spit • recovery',
    const Offset(32, 60),
    17,
  );
  final clock = seconds % 5;
  final enemy = SkyEnemy(x: 1.4, y: .5, appearance: 1, flightPhase: 2.399963)
    ..age = seconds
    ..preparing = clock < 2.0
    ..fireIn = 2.0 - clock
    ..lastShotAt = clock >= 2.0
        ? seconds - (clock - 2.0)
        : double.negativeInfinity;
  for (final (rect, height, center, label) in [
    (
      const Rect.fromLTWH(24, 102, 580, 302),
      1666.667,
      const Offset(277, 260),
      'CHARACTER DETAIL',
    ),
    (
      const Rect.fromLTWH(624, 102, 352, 302),
      360.0,
      const Offset(821, 263),
      'ACTUAL GAMEPLAY SIZE',
    ),
  ]) {
    c.save();
    c.clipRRect(RRect.fromRectAndRadius(rect, const Radius.circular(20)));
    c.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xffc6e5e5), Color(0xfff9efd8)],
        ).createShader(rect),
    );
    _text(
      c,
      label,
      rect.topLeft + const Offset(22, 18),
      12,
      weight: FontWeight.w900,
    );
    c.translate(center.dx - enemy.x * height, center.dy - .5 * height);
    EnemyArt.paint(c, height, enemy, birdY: .5, reducedMotion: false);
    if (clock >= 2 && clock < 3.5) {
      final shot = EnemyAmmo(
        x: enemy.muzzleX - .44 * (clock - 2),
        y: .5,
        vx: -.44,
        vy: 0,
        attack: EnemyAttack.aimed,
      );
      EnemyArt.ammo(c, height, shot, seconds: seconds, reducedMotion: false);
    }
    c.restore();
  }
  const stages = ['CRUISE', 'CHARGE', 'SPIT', 'RECOVER'];
  final active = clock < 1.25
      ? 0
      : clock < 2
      ? 1
      : clock < 2.24
      ? 2
      : 3;
  for (var i = 0; i < stages.length; i++) {
    final rect = Rect.fromLTWH(24 + i * 242, 427, 226, 56);
    c.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      Paint()
        ..color = i == active
            ? const Color(0xff285b50)
            : const Color(0xffe4e6d9),
    );
    _text(
      c,
      stages[i],
      rect.topLeft + const Offset(18, 17),
      16,
      weight: FontWeight.w900,
      color: i == active ? SkyColors.cream : SkyColors.muted,
    );
  }
}
