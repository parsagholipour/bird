// Visual review of King Coo's stragglers (rules version 45): the vanguard
// that got away (its pips marked to come back), the owed tag under his plate
// beside his own tags, a straggler coming back and being caught, and ALL
// CAUGHT!. A real 3-2 flight whose pilot never shoots in the vanguard, so
// all fourteen are owed. Writes PNGs to
// build/visual-review/boss-stages/straggler/; the assertions live in
// boss_stages_art_test.dart.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/enemy_designs/alley_pigeon.dart';
import 'package:push_up_bird/game/straggler_art.dart';

import 'boss_stages_support.dart';

const _folder = 'build/visual-review/boss-stages/straggler';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);
  final out = Directory(_folder);

  /// Shoots every straggler that has come well on screen.
  void catchStragglers(StagesGame g) {
    final guard = g.sim.vanguard!;
    for (final enemy in guard.stragglers) {
      if (!g.sim.enemies.contains(enemy) || enemy.x > g.aspect - .35) continue;
      if (g.sim.rocks.any((r) => (r.y - enemy.y).abs() < .01)) continue;
      g.sim.rocks.add(BirdRock(x: enemy.x - .02, y: enemy.y));
    }
  }

  for (final width in [640.0, 800.0, 792.0]) {
    testWidgets('stragglers at $width', (tester) async {
      await tester.runAsync(() async {
        final g = await stagesGame(tester, BossKind.kingCoo, width);
        final guard = g.sim.vanguard!;
        final frames = <(String, ui.Image)>[];
        Future<void> shot(String label, String file) async {
          frames.add((label, await g.render()));
          await save(out, 'frames/${width.toInt()}-$file', frames.last.$2);
        }

        g.run(guard.startedAt + .4 - g.sim.elapsed);
        await shot('card', 'card');
        // Nobody shoots: the whole vanguard gets away.
        g.runUntil((s) => guard.escaped >= 6, seconds: 30);
        await shot('vanguard: 6 got away', 'plate-escaped');
        g.runUntil((s) => s.boss != null, seconds: 40);
        g.bossTo(g.boss!.arrivalDuration + .2);
        await shot('fight begins: ×${guard.owed}', 'owed-in');
        g.runUntil(
          (s) =>
              guard.stragglers.isNotEmpty &&
              s.enemies.contains(guard.stragglers.last) &&
              guard.stragglers.last.age > .3 &&
              guard.stragglers.last.age < .55,
          seconds: 30,
        );
        await shot('one comes back (the arrow turns)', 'return');
        g.runUntil(
          (s) => guard.stragglers.any(
            (e) =>
                s.enemies.contains(e) &&
                e.preparing &&
                e.charge > .7 &&
                e.x < g.aspect - .3,
          ),
          seconds: 30,
        );
        await shot('a straggler winds up', 'windup');
        // Catch it: the tag pops.
        catchStragglers(g);
        g.runUntil((s) => guard.stragglerDownedAt.isNotEmpty, seconds: 5);
        g.run(.12);
        await shot('caught: ×${guard.owed}', 'pop');
        // His puff (PUFFED x2 hangs from the plate) beside the tag.
        final coo = g.boss!;
        g.runUntil(
          (s) =>
              coo.puffWindow &&
              coo.cooCycle > KingCoo.puffAt + .4 &&
              coo.cooCycle < KingCoo.puffAt + .6,
          seconds: 30,
        );
        await shot('PUFFED x2 and the tag', 'puffed');
        // STRONGER! beside the tag (away from his puff).
        g.runUntil(
          (s) => coo.cooCycle > 1.0 && coo.cooCycle < 1.2,
          seconds: 30,
        );
        g.hurtTo(.6, after: .7);
        await shot('STRONGER! and the tag', 'stronger');
        // Catch them all.
        var guardSteps = 0;
        while (guard.owed > 0 && guardSteps++ < 60 * 200) {
          catchStragglers(g);
          g.tick();
        }
        g.run(.15);
        await shot('ALL CAUGHT!', 'caught');
        g.run(1.2);
        await shot('ALL CAUGHT! +1.35s', 'caught-late');
        await sheet(
          out,
          'flight-${width.toInt()}',
          frames,
          cols: 3,
          scale: .75,
        );
        // The plate and its tags in every frame, at 3x.
        final crop = Rect.fromCenter(
          center: Offset(width / 2, 34),
          width: 430,
          height: 68,
        );
        final zoomed = <(String, ui.Image)>[
          for (final (label, image) in frames)
            (label, await zoom(image, crop, 3)),
        ];
        await sheet(out, 'zoom-${width.toInt()}', zoomed, cols: 2, height: 204);
        for (final (_, image) in [...frames, ...zoomed]) {
          image.dispose();
        }
      });
    }, timeout: const Timeout(Duration(minutes: 6)));
  }

  testWidgets('a straggler beside his squadron and a vanguard pigeon', (
    tester,
  ) async {
    await tester.runAsync(() async {
      // The same coat at game size, then 3x: a vanguard pigeon, a straggler
      // (scuffs and badge), each winding up, and one of his squadron.
      final g = await stagesGame(tester, BossKind.kingCoo, 640);
      const size = Size(340, 70);
      final recorder = ui.PictureRecorder();
      final c = Canvas(recorder);
      c.drawRect(Offset.zero & size, Paint()..color = const Color(0xff2a2850));
      final r = 360 * SkyEnemy.radius;
      for (final (i, (straggler, windup)) in const [
        (false, 0.0),
        (true, 0.0),
        (false, .8),
        (true, .8),
      ].indexed) {
        c.save();
        c.translate(36 + i * 64.0, 40);
        AlleyPigeonArt.paint(
          c,
          r,
          seconds: 1.2,
          reducedMotion: false,
          pose: const PigeonPose(coat: 1),
          glider: true,
          throwing: (windup: windup, follow: -1.0),
          ragged: straggler,
        );
        c.restore();
        if (straggler) {
          // (EnemyArt adds the badge over its head.)
          StragglerArt.strayBadge(c, Offset(36 + i * 64.0, 40), r);
        }
      }
      c.save();
      c.translate(36 + 4 * 64.0, 40);
      AlleyPigeonArt.paint(
        c,
        r,
        seconds: 1.2,
        reducedMotion: false,
        pose: const PigeonPose(coat: 1),
        glider: true,
      );
      c.restore();
      final image = await recorder.endRecording().toImage(340, 70);
      await save(out, 'pigeons-1x', image);
      final big = await zoom(image, Offset.zero & size, 4);
      await save(out, 'pigeons-4x', big);
      image.dispose();
      big.dispose();
      g.game.pauseEngine();
    });
  });
}
