import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/alley_pigeon_overlay_art.dart';
import 'package:push_up_bird/game/boss_art.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/gargoyle_encounter_ui.dart';

import 'alley_pigeon_art_test.dart' show Counting, pigeon;

/// New York's two painters that used to throw (or kill the process) on input
/// the game never sends but a native abort cannot be caught: the Searchlight
/// Gargoyle's name card at no height, and the Alley Pigeon's marks on
/// non-finite numbers. The Gargoyle's other painters and the steam painters
/// already take any input (the QA review poisoned them).

const _nan = double.nan, _inf = double.infinity;

Canvas _canvas() => Canvas(ui.PictureRecorder());

FlightSimulation _sim() => FlightSimulation(rules: TapFlyMode(), practice: true)
  ..phase = RunPhase.playing
  ..elapsed = 30;

void main() {
  group('the Gargoyle\'s name card needs room', () {
    SkyBoss gargoyle(double age) =>
        SkyBoss(
            number: 7,
            x: 1.2,
            kind: BossKind.searchlightGargoyle,
            cinematic: true,
          )
          ..y = .5
          ..age = age;

    test('no height, no width, no size: the card is ours and draws nothing', () {
      for (final reduced in [false, true]) {
        for (final age in [2.8, 3.0, 3.3, 3.6, 4.2]) {
          final boss = gargoyle(age);
          for (final size in [
            const Size(640, 0),
            const Size(0, 360),
            const Size(0, 0),
            const Size(640, .5),
            const Size(.4, .4),
            const Size(640, -3),
            const Size(_nan, 360),
            const Size(640, _nan),
            const Size(640, _inf),
          ]) {
            final recorder = ui.PictureRecorder();
            final canvas = Canvas(recorder);
            expect(
              GargoyleEncounterUi.nameCard(
                canvas,
                size,
                boss,
                BossMotion(boss, reducedMotion: reduced),
                birdY: .5,
                line: '“Hold still!”',
              ),
              isTrue,
              reason: 'age $age at $size',
            );
            recorder.endRecording().dispose();
          }
        }
      }
    });

    test('the encounter\'s foreground survives a canvas of no height', () {
      // The QA reproduction: BossArt.foreground at Size(640, 0), boss age 3.
      for (final reduced in [false, true]) {
        for (final age in [2.9, 3.0, 3.4, 4.0]) {
          final sim = _sim()..boss = gargoyle(age);
          for (final size in const [
            Size(640, 0),
            Size(640, .25),
            Size(0, 0),
          ]) {
            BossArt.foreground(_canvas(), size, sim, reduced);
          }
        }
      }
    });

    test('a real size still draws the card', () {
      final boss = gargoyle(3.3);
      final count = Counting(_canvas());
      final shown = GargoyleEncounterUi.nameCard(
        count,
        const Size(640, 360),
        boss,
        BossMotion(boss, reducedMotion: false),
        line: '“Hold still!”',
      );
      expect(shown, isTrue);
      expect(count.draws, greaterThan(10), reason: 'the guard is not a veto');
    });
  });

  group('the Alley Pigeon\'s marks take any number', () {
    /// A sim holding a warning pigeon over its prey, a diver, a thief that
    /// has just snatched, and a freed star.
    ({FlightSimulation sim, List<SkyEnemy> birds, SkyStar freed}) scene() {
      final sim = _sim();
      final prey = [for (var i = 0; i < 3; i++) SkyStar(x: 1.4 + i * .17, y: .56)];
      final freed = SkyStar(x: 1.0, y: .5)
        ..freedAt = 29.9
        ..rescued = true;
      sim.stars
        ..addAll(prey)
        ..add(freed);
      final birds = [
        pigeon(PigeonPhase.warning, into: .4, x: 1.5, y: .4)
          ..pigeon!.prey = prey[0],
        pigeon(PigeonPhase.dive, into: .2, x: 1.45, y: .42)
          ..pigeon!.prey = prey[1],
        pigeon(PigeonPhase.carry, into: .1, x: 1.1, y: .5, loot: true)
          ..pigeon!.prey = prey[2],
      ];
      sim.enemies.addAll(birds);
      return (sim: sim, birds: birds, freed: freed);
    }

    void paintAll(FlightSimulation sim, SkyStar freed, double h, bool reduced) {
      AlleyPigeonOverlayArt.paint(_canvas(), h, sim, reducedMotion: reduced);
      AlleyPigeonOverlayArt.freed(
        _canvas(),
        h,
        freed,
        sim.elapsed,
        reducedMotion: reduced,
      );
    }

    test('the clean scene draws marks (the guards are not vetoes)', () {
      final (:sim, :birds, :freed) = scene();
      final count = Counting(_canvas());
      AlleyPigeonOverlayArt.paint(count, 360, sim, reducedMotion: false);
      expect(count.draws, greaterThan(8));
    });

    test('a non-finite or empty height draws nothing and throws nothing', () {
      for (final h in [_nan, _inf, -_inf, 0.0, -360.0]) {
        for (final reduced in [false, true]) {
          final (:sim, :birds, :freed) = scene();
          final count = Counting(_canvas());
          AlleyPigeonOverlayArt.paint(count, h, sim, reducedMotion: reduced);
          AlleyPigeonOverlayArt.freed(
            count,
            h,
            freed,
            sim.elapsed,
            reducedMotion: reduced,
          );
          expect(count.draws, 0, reason: 'height $h');
        }
      }
    });

    test('a non-finite clock draws nothing and throws nothing', () {
      for (final elapsed in [_nan, _inf, -_inf]) {
        final (:sim, :birds, :freed) = scene();
        sim.elapsed = elapsed;
        for (final reduced in [false, true]) {
          paintAll(sim, freed, 360, reduced);
        }
      }
    });

    test('a poisoned pigeon, prey or star is skipped, the others still draw', () {
      final poisons = <String, void Function(SkyEnemy, SkyStar)>{
        'age NaN': (e, p) => e.age = _nan,
        'age inf': (e, p) => e.age = _inf,
        'x NaN': (e, p) => e.x = _nan,
        'x inf': (e, p) => e.x = _inf,
        'y NaN': (e, p) => e.y = _nan,
        'phaseAt NaN': (e, p) => e.pigeon!.phaseAt = _nan,
        'phaseAt -inf': (e, p) => e.pigeon!.phaseAt = -_inf,
        'snatchedAt NaN': (e, p) => e.pigeon!.snatchedAt = _nan,
        'prey x NaN': (e, p) => p.x = _nan,
        'prey x inf': (e, p) => p.x = _inf,
        'prey y NaN': (e, p) => p.heldY = _nan,
        'prey y -inf': (e, p) => p.heldY = -_inf,
      };
      for (final MapEntry(key: why, value: poison) in poisons.entries) {
        for (var i = 0; i < 3; i++) {
          for (final reduced in [false, true]) {
            final (:sim, :birds, :freed) = scene();
            final victim = birds[i];
            poison(victim, victim.pigeon!.prey ?? freed);
            expect(
              () => AlleyPigeonOverlayArt.paint(
                _canvas(),
                360,
                sim,
                reducedMotion: reduced,
              ),
              returnsNormally,
              reason: '$why on pigeon $i, reduced $reduced',
            );
          }
        }
      }
    });

    test('a poisoned freed star is skipped', () {
      for (final poison in <void Function(SkyStar)>[
        (s) => s.x = _nan,
        (s) => s.x = _inf,
        (s) => s.heldY = _nan,
        (s) => s.freedAt = _nan,
        (s) => s.freedAt = _inf,
      ]) {
        final (:sim, :birds, :freed) = scene();
        poison(freed);
        for (final reduced in [false, true]) {
          expect(
            () => AlleyPigeonOverlayArt.freed(
              _canvas(),
              360,
              freed,
              sim.elapsed,
              reducedMotion: reduced,
            ),
            returnsNormally,
          );
        }
      }
    });
  });
}
