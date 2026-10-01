import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/gargoyle_beam_art.dart';
import 'package:push_up_bird/game/gargoyle_encounter_art.dart';
import 'package:push_up_bird/game/gargoyle_encounter_ui.dart';
import 'package:push_up_bird/game/gargoyle_kit.dart';
import 'package:push_up_bird/game/gargoyle_pose.dart';
import 'package:push_up_bird/game/gargoyle_staging_art.dart';

import 'gargoyle_stage_support.dart';

/// The Searchlight Gargoyle's staging, scanned (G8): the pixels of him that are
/// drawn are never clipped by the white-out's layer bounds, by the screen or by
/// the letterbox, at 640 x 360 and 800 x 360, in ANY state (the dragon's
/// `dragon_staging_test` is the pattern); the joins between his clocks have no
/// pop; and a whole fight under the real rules renders every phase.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);

  group('nothing of him is clipped', () {
    for (final width in const [640.0, 800.0]) {
      testWidgets('by the layer bounds, the screen or the letterbox: every arrival, fight and defeat state at ${width.toInt()}', (tester) async {
        await tester.runAsync(() async {
          var scanned = 0;
          for (final (name, mk) in encounterStates()) {
            final boss = mk(width);
            // While the tower slides in from the right (before the roar) he is
            // off the right edge by design; the top, the bottom and the layer
            // still apply.
            final sliding = boss.phase == BossPhase.arriving && boss.age < 2.65;
            for (final reduced in const [false, true]) {
              final r = await reach(boss, width, reduced: reduced, right: !sliding);
              expect(r.top, lessThanOrEqualTo(0), reason: '$name @ $width (reduced $reduced): cropped by the top / letterbox by ${r.top} px');
              expect(r.bottom, lessThanOrEqualTo(0), reason: '$name @ $width (reduced $reduced): cropped by the bottom / letterbox by ${r.bottom} px');
              expect(r.right, lessThanOrEqualTo(0), reason: '$name @ $width (reduced $reduced): off the right by ${r.right} px');
              expect(await clippedByLayer(boss, width, reduced: reduced), 0, reason: '$name @ $width (reduced $reduced): the layer bounds cut pixels off');
              scanned++;
            }
          }
          // ignore: avoid_print
          print('scanned $scanned states at $width');
        });
      }, timeout: const Timeout(Duration(minutes: 8)));
    }

    testWidgets('a hit\'s own jolt, at the nose-up of the fury roar, still fits (the crest has the least headroom there)', (tester) async {
      await tester.runAsync(() async {
        for (final width in const [640.0, 800.0]) {
          // The fury roar at .3 s with a hit just landed: the highest crest, plus a jolt.
          final boss = bossAt(1.0, width: width, fury: true, enragedAgo: .3, hitAgo: .02);
          final r = await reach(boss, width);
          expect(r.top, lessThanOrEqualTo(0), reason: 'the jolt must not push the crest off the top');
        }
      });
    });
  });

  group('the joins have no pop', () {
    test('the frame is the same at the end of the arrival, the start of the fight and the killing blow', () {
      for (final width in const [640.0, 800.0]) {
        final a = GargoyleEncounterArt.frame(motion(bossAt(-1e-6, width: width)), 360);
        final b = GargoyleEncounterArt.frame(motion(bossAt(0, width: width)), 360);
        final c = GargoyleEncounterArt.frame(motion(bossAt(3, width: width, deadFor: 0)), 360);
        expect((a.heart - b.heart).distance, lessThan(1e-3));
        expect((b.heart - c.heart).distance, lessThan(1e-6));
        expect(a.unit, b.unit);
      }
    });

    test('the fade-in of the tower is continuous and monotone from .95 s to 1.2 s', () {
      double alpha(double age) {
        final b = bossAt(age - 4.6);
        final r = Rec();
        GargoyleEncounterArt.paint(r, const ui.Size(640, 360), simOf(b), motion(b));
        return r.layers.isEmpty ? (age < .95 ? 0 : 1) : r.layers.single.alpha;
      }

      var last = alpha(.9);
      expect(last, 0);
      for (var age = .9; age <= 1.3; age += 1 / 60) {
        final a = alpha(age);
        expect(a, greaterThanOrEqualTo(last - 1e-9), reason: 'monotone at $age');
        expect(a - last, lessThan(.2), reason: 'a pop at $age');
        last = a;
      }
      expect(last, 1);
    });

    testWidgets('the roosting pigeons lift off their perches without a pop: the flock\'s pixels change smoothly through 2.0 s', (tester) async {
      await tester.runAsync(() async {
        const lamp = ui.Offset(460, 180);
        const size = ui.Size(640, 360);
        final bg = await raster((c) {}, 640);
        var last = -1;
        var worst = 0.0;
        for (var age = 1.9; age <= 2.7; age += 1 / 60) {
          final px = await raster((c) {
            GargoyleEncounterUi.roost(c, lamp, 360, age, reduced: false);
            GargoyleEncounterUi.flush(c, lamp, 360, age, reduced: false);
          }, 640);
          final n = changed(px, bg);
          if (last > 0 && n > 100) worst = math.max(worst, (n - last).abs() / last);
          last = n;
        }
        expect(size.height, 360);
        expect(worst, lessThan(.45), reason: 'the flock\'s size changes by at most ${(worst * 100).round()}% per frame');
      });
    });

    test('the nest pigeon: asleep, awake and in flight join (position and alpha)', () {
      GargoylePose at(double age, {double? deadFor}) {
        final b = deadFor == null ? bossAt(age - 4.6) : bossAt(1.0, deadFor: deadFor);
        return GargoylePose(b, motion(b));
      }

      for (var age = 1.9; age < 2.4; age += .02) {
        final a = GargoyleStagingArt.pigeonState(at(age)).sleep, b = GargoyleStagingArt.pigeonState(at(age + .02)).sleep;
        expect((a - b).abs(), lessThan(.15), reason: 'the wake-up at $age');
      }
      for (var d = 0.0; d < 1.3; d += .02) {
        final a = GargoyleStagingArt.pigeonState(at(0, deadFor: d)).alpha, b = GargoyleStagingArt.pigeonState(at(0, deadFor: d + .02)).alpha;
        expect((a - b).abs(), lessThan(.25), reason: 'the take-off at $d');
        final fa = GargoyleStagingArt.pigeonState(at(0, deadFor: d)).flight, fb = GargoyleStagingArt.pigeonState(at(0, deadFor: d + .02)).flight;
        expect((fa - fb).abs(), lessThan(.03));
      }
      expect(GargoyleStagingArt.pigeonState(at(0, deadFor: .05)).flight, 0, reason: 'it climbs away only after the blow has landed');
    });
  });

  group('a whole fight under the real rules', () {
    testWidgets('the pilot flies the arrival, every phase and the defeat; every frame renders through the real game', (tester) async {
      await tester.runAsync(() async {
        final s = await stage(tester, 800);
        s.hold = false;
        final seen = <String>{};
        var frames = 0, tick = 0;
        double? dead;
        var glanced = false;
        while (s.sim.boss != null && (dead == null || s.boss.age - dead < 3.7) && frames < 60 * 150) {
          // The arrival coasts; the pilot takes over after it. A rock on the
          // shut lamp once, early in the first perch (the pilot never wastes one).
          s.hold = s.boss.phase == BossPhase.arriving;
          s.birdY = .5;
          if (!glanced && s.boss.phase == BossPhase.attacking && s.boss.gargoyleCycle > .8) {
            s.rock();
            glanced = true;
          }
          s.tick();
          final boss = s.sim.boss;
          if (boss == null) break;
          if (boss.defeatedAt != null) dead ??= boss.defeatedAt;
          if (boss.phase == BossPhase.arriving) {
            seen.add('arrival');
            if (boss.age > 2.9 && boss.age < 4.2) seen.add('card');
          }
          if (boss.phase == BossPhase.attacking) {
            final x = boss.gargoyleCycle;
            if (x < 2) seen.add('perch');
            if (x >= 2 && x < 3.5) seen.add('warning');
            if (x >= 3.5 && x < 6.4) seen.add(boss.slitSweep ? 'slit' : (boss.beamSide == BeamSide.high ? 'sweep high' : 'sweep low'));
            if (x >= 6.4) seen.add('vent');
            if (boss.lastDamage > 0 && boss.age - boss.lastHitAt < .3) seen.add('hit');
            if (boss.age - boss.lastGlanceAt < .15) seen.add('glance');
            if (boss.enraged) seen.add('fury');
            if (s.sim.bossAmmo.any((a) => a.feather)) seen.add('feather');
            if (boss.age - boss.enragedAt >= 0 && boss.age - boss.enragedAt < 1.1) seen.add('fury onset');
            if (GargoyleBeamArt.spotOf(s.sim) != null) seen.add('spotted');
          }
          if (boss.defeatedAt != null) {
            final d = boss.age - boss.defeatedAt!;
            seen.add('defeat');
            if (d > 1.6) seen.add('victory card');
            if (d > 2.2) seen.add('rubble');
          }
          // Every 6th step through the real renderer (10 fps of the flight).
          if (tick++ % 6 == 0) {
            final image = await s.render();
            image.dispose();
            frames++;
          }
        }
        // ignore: avoid_print
        print('real fight: $frames frames rendered; phases $seen');
        for (final phase in ['arrival', 'card', 'perch', 'warning', 'vent', 'hit', 'glance', 'fury', 'fury onset', 'feather', 'defeat', 'victory card', 'rubble']) {
          expect(seen, contains(phase), reason: 'the flight reached "$phase"');
        }
        expect(seen.any((p) => p.startsWith('sweep')), isTrue, reason: 'a zone sweep was rendered');
        expect(seen, contains('slit'), reason: 'a fury slit was rendered');
        expect(GargoyleKit.cacheSize, lessThanOrEqualTo(GargoyleKit.cacheCapacity));
        expect(s.sim.boss == null || s.boss.defeatedAt != null, isTrue);
      });
    }, timeout: const Timeout(Duration(minutes: 10)));
  });
}
