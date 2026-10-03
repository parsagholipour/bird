// Visual review of King Coo's crust-throwing vanguard (rules version 45):
// the thrown crust beside the other pellets and the pickups, its splash and
// its shatter, the pigeon's wind-up and throw, and the real 3-2 vanguard.
// Writes PNGs to build/visual-review/boss-stages/crust/ for a person to look
// at; the assertions live in boss_stages_art_test.dart.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/ammo_shatter_art.dart';
import 'package:push_up_bird/game/enemy_ammo_art.dart';
import 'package:push_up_bird/game/enemy_ammo_impact_art.dart';
import 'package:push_up_bird/game/enemy_designs/alley_pigeon.dart';
import 'package:push_up_bird/game/star_art.dart';
import 'package:push_up_bird/game/heart_pickup_art.dart';

import 'boss_stages_support.dart';

const _folder = 'build/visual-review/boss-stages/crust';

const _night = [Color(0xff2a2850), Color(0xff6a5a8a)];
const _day = [Color(0xff90d5ee), Color(0xffbde9f6)];

void _sky(Canvas c, Rect r, List<Color> colors) => c.drawRect(
  r,
  Paint()
    ..shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors,
    ).createShader(r),
);

Future<ui.Image> _draw(void Function(Canvas) paint, Size size) {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder));
  return recorder.endRecording().toImage(
    size.width.round(),
    size.height.round(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);
  final out = Directory(_folder);
  const h = 360.0, pellet = h * EnemyAmmo.radius, bird = h * SkyEnemy.radius;

  testWidgets('the crust beside the other pellets and the pickups', (
    tester,
  ) async {
    await tester.runAsync(() async {
      // Game size (a 360 px high screen), then the same pixels at 4x.
      for (final (name, sky) in [('night', _night), ('day', _day)]) {
        const size = Size(300, 60);
        final image = await _draw((c) {
          _sky(c, Offset.zero & size, sky);
          // Eight moments of the tumble, flying left.
          for (var i = 0; i < 8; i++) {
            EnemyAmmoArt.paint(
              c,
              h,
              EnemyAmmo(
                x: (14 + i * 22) / h,
                y: 20 / h,
                vx: -.40,
                vy: .04,
                attack: EnemyAttack.crumb,
              ),
              seconds: 1 + i * .06,
              reducedMotion: false,
            );
          }
          // The others: spit, ember, a star and a heart to collect.
          for (final (i, attack) in [
            EnemyAttack.aimed,
            EnemyAttack.fan,
          ].indexed) {
            EnemyAmmoArt.paint(
              c,
              h,
              EnemyAmmo(
                x: (22 + i * 30) / h,
                y: 46 / h,
                vx: -.44,
                vy: 0,
                attack: attack,
              ),
              seconds: 1,
              reducedMotion: false,
            );
          }
          StarArt.paint(c, const Offset(110, 46), h * StarArt.radius);
          HeartPickupArt.paint(
            c,
            h,
            SkyHeart(x: 150 / h, y: 46 / h),
            seconds: 1,
            reducedMotion: false,
          );
          // Reduced Motion: still, untumbled.
          EnemyAmmoArt.paint(
            c,
            h,
            EnemyAmmo(
              x: 200 / h,
              y: 46 / h,
              vx: -.40,
              vy: 0,
              attack: EnemyAttack.crumb,
            ),
            seconds: 1,
            reducedMotion: true,
          );
        }, size);
        await save(out, 'pellets-$name-1x', image);
        final big = await zoom(image, Offset.zero & size, 4);
        await save(out, 'pellets-$name-4x', big);
        image.dispose();
        big.dispose();
      }
    });
  });

  testWidgets('the crust splashes and shatters', (tester) async {
    await tester.runAsync(() async {
      const ages = [0.0, .02, .05, .09, .14, .2, .27, .33];
      const cell = 56.0;
      final rows = [
        ('blocked', AmmoStop.blocked, false),
        ('struck', AmmoStop.struck, false),
        ('deflected', AmmoStop.deflected, false),
        ('blocked RM', AmmoStop.blocked, true),
        ('deflected RM', AmmoStop.deflected, true),
      ];
      final size = Size(cell * ages.length, cell * rows.length);
      final image = await _draw((c) {
        _sky(c, Offset.zero & size, _night);
        for (final (r, (_, stop, reduced)) in rows.indexed) {
          for (final (i, age) in ages.indexed) {
            EnemyAmmoImpactArt.splash(
              c,
              Offset(cell * i + cell / 2, cell * r + cell / 2),
              pellet,
              direction: 3.0,
              attack: EnemyAttack.crumb,
              stop: stop,
              age: age,
              reducedMotion: reduced,
              seed: .37,
            );
          }
        }
      }, size);
      final big = await zoom(image, Offset.zero & size, 3);
      await save(out, 'splash-3x', big);
      image.dispose();
      big.dispose();

      const shatterAges = [0.0, .04, .08, .14, .22, .32, .45, .56];
      const shatterRows = [(.4, false), (1.0, false), (1.0, true)];
      // Each row as tall as its blast.
      final heights = [
        for (final (charge, _) in shatterRows)
          h * PowerShot.shatterReach(charge) * 2 + 16,
      ];
      final scell = heights.reduce((a, b) => a > b ? a : b);
      final ssize = Size(
        scell * shatterAges.length,
        heights.reduce((a, b) => a + b),
      );
      final shatter = await _draw((c) {
        _sky(c, Offset.zero & ssize, _night);
        var top = 0.0;
        for (final (r, (charge, reduced)) in shatterRows.indexed) {
          for (final (i, age) in shatterAges.indexed) {
            AmmoShatterArt.blast(
              c,
              Offset(scell * i + scell / 2, top + heights[r] / 2),
              pellet,
              reach: h * PowerShot.shatterReach(charge),
              charge: charge,
              direction: 3.0,
              attack: EnemyAttack.crumb,
              age: age,
              reducedMotion: reduced,
              seed: .41,
            );
          }
          top += heights[r];
        }
      }, ssize);
      final sbig = await zoom(shatter, Offset.zero & ssize, 1.25);
      await save(out, 'shatter', sbig);
      shatter.dispose();
      sbig.dispose();
    });
  });

  testWidgets('the pigeon winds up and throws', (tester) async {
    await tester.runAsync(() async {
      final moments = <(String, PigeonThrow?, bool)>[
        ('glide (no throw)', null, false),
        ('wind-up .15', (windup: .15, follow: -1.0), false),
        ('wind-up .35', (windup: .35, follow: -1.0), false),
        ('wind-up .6', (windup: .6, follow: -1.0), false),
        ('wind-up .85', (windup: .85, follow: -1.0), false),
        ('wind-up 1.0', (windup: 1.0, follow: -1.0), false),
        ('release +.03', (windup: 0.0, follow: .07), false),
        ('release +.1', (windup: 0.0, follow: .22), false),
        ('release +.2', (windup: 0.0, follow: .45), false),
        ('release +.35', (windup: 0.0, follow: .78), false),
        ('RM wind-up', (windup: .5, follow: -1.0), true),
        ('RM release', (windup: 0.0, follow: .2), true),
      ];
      const cell = 64.0;
      for (final coat in [0, 1, 2]) {
        final size = Size(cell * moments.length, cell);
        final image = await _draw((c) {
          _sky(c, Offset.zero & size, _night);
          for (final (i, (_, t, reduced)) in moments.indexed) {
            c.save();
            c.translate(cell * i + cell / 2 + 4, cell / 2 + 4);
            AlleyPigeonArt.paint(
              c,
              bird,
              seconds: 1.13,
              reducedMotion: reduced,
              pose: PigeonPose(coat: coat),
              glider: true,
              throwing: t,
            );
            c.restore();
          }
        }, size);
        await save(out, 'throw-coat$coat-1x', image);
        final big = await zoom(image, Offset.zero & size, 3);
        await save(out, 'throw-coat$coat-3x', big);
        image.dispose();
        big.dispose();
      }
    });
  });

  for (final width in [640.0, 792.0]) {
    testWidgets(
      'the 3-2 vanguard throws at $width',
      (tester) async {
        await tester.runAsync(() async {
          final g = await stagesGame(tester, BossKind.kingCoo, width);
          final guard = g.sim.vanguard!;
          final frames = <(String, ui.Image)>[];
          Future<void> shot(String label) async {
            frames.add((label, await g.render()));
            await save(
              out,
              'flight-${width.toInt()}-${frames.length}',
              frames.last.$2,
            );
          }

          g.run(guard.startedAt + .35 - g.sim.elapsed);
          await shot('card +0.35s');
          bool any(bool Function(SkyEnemy) test) =>
              g.sim.enemies.where(guard.members.contains).any(test);
          g.runUntil((s) => any((e) => e.preparing && e.charge > .7));
          await shot('wind-up');
          g.runUntil((s) {
            return any((e) {
              final since = e.age - e.lastShotAt;
              return since > .05 && since < .1;
            });
          });
          await shot('release');
          g.run(.35);
          await shot('crusts in flight');
          g.shooting = true;
          g.runUntil(
            (s) => s.ammoShatters.isNotEmpty || s.enemyAmmoImpacts.isNotEmpty,
            seconds: 20,
          );
          g.run(.05);
          await shot('a crust breaks');
          g.run(guard.startedAt + 9.6 - g.sim.elapsed);
          await shot('wave 3');
          await sheet(
            out,
            'flight-${width.toInt()}',
            frames,
            cols: 3,
            scale: .75,
          );
          for (final (_, image) in frames) {
            image.dispose();
          }
        });
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  }
}
