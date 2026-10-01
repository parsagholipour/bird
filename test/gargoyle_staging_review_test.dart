import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/game/gargoyle_kit.dart';
import 'package:push_up_bird/domain/game_rules.dart';

import 'gargoyle_stage_support.dart';

/// The Searchlight Gargoyle's staging, for the eye (G8): every test here is
/// skipped unless `GARGOYLE_STAGING_REVIEW=1`, which writes the review frames
/// (arrival beats, each fight beat, fury, hit, defeat; at 640 and 800, with and
/// without Reduced Motion, over New York's night) to
/// `build/visual-review/g8-staging/`. `GARGOYLE_STAGING_VIDEO=1` also streams a
/// whole encounter, arrival to victory, to `gargoyle-encounter.mp4` (needs
/// ffmpeg). The assertions are in `gargoyle_staging_test.dart`.
final _review = Platform.environment['GARGOYLE_STAGING_REVIEW'] == '1';
final _folder = Directory('build/visual-review/g8-staging');

const _arrivalBeats = <(String, double)>[
  ('0.40 storm', .4),
  ('1.20 ledge slides in', 1.2),
  ('1.62 before the strike', 1.62),
  ('1.68 STRIKE', 1.68),
  ('1.74', 1.74),
  ('1.82', 1.82),
  ('1.95 stone to colour', 1.95),
  ('2.15 pigeons flush', 2.15),
  ('2.45 fan unfolds', 2.45),
  ('2.75 ROAR', 2.75),
  ('2.95 card slams', 2.95),
  ('3.30 roar ends', 3.3),
  ('3.60 sweep finds bird', 3.6),
  ('3.95 spotted', 3.95),
  ('4.30 card holds', 4.3),
  ('4.70 control', 4.7),
];

Future<void> _write(String name, ui.Image image) async {
  _folder.createSync(recursive: true);
  File('${_folder.path}/$name.png').writeAsBytesSync(await png(image));
}

/// The fight, cycle by cycle (the aim is latched at each warning from the
/// bird's height then): HIGH, LOW, the tipping into fury, a zone and a slit
/// sweep in fury, then the killing blow.
Future<void> _lightning(Stage s, String tag) async {
  // The first cycles that flicker (a hash of the cycle number decides).
  final frames = <(String, ui.Image)>[];
  var shown = 0;
  for (var k = 0; k < 12 && shown < 2; k++) {
    if (GargoyleKit.hash(k, 11) > .55) continue;
    final start = k * 9.0 + .95 + GargoyleKit.hash(k, 13) * .5;
    for (final du in const [.03, .1, .18, .3, .5]) {
      s.fightTo(start + du);
      frames.add(('cycle $k +$du', await s.render()));
    }
    shown++;
  }
  await sheet(_folder, 'lightning-$tag', frames, cols: 3, scale: tag.startsWith('640') ? .8 : .64);
  await disposeAll(frames);
}

Future<void> _fight(Stage s, String tag) async {
  final out = <String, List<(String, ui.Image)>>{};
  Future<void> shot(String sheetName, String label, [double? birdY]) async {
    if (birdY != null) s.birdY = birdY;
    (out[sheetName] ??= []).add((label, await s.render()));
  }

  s.birdY = .5;
  // Cycle 0: a HIGH sweep (the bird is in the upper half as it is aimed).
  s.cycleTo(0, .7);
  await shot('perch', 'perch .7');
  s.cycleTo(0, .9);
  s.rock();
  s.tick();
  await shot('perch', 'glance +.0');
  s.tick();
  s.tick();
  s.tick();
  await shot('perch', 'glance +.07');
  s.cycleTo(0, 1.5);
  await shot('perch', 'feather falls 1.5');
  s.cycleTo(0, 1.95);
  s.birdY = .28;
  s.cycleTo(0, 2.4);
  await shot('warn', 'warning HIGH 2.4');
  s.cycleTo(0, 3.2);
  s.birdY = .8;
  await shot('warn', 'warning HIGH 3.2 (flee down)');
  s.cycleTo(0, 3.55);
  await shot('sweep', 'sweep HIGH 3.55 ignition');
  s.cycleTo(0, 4.5);
  await shot('sweep', 'sweep HIGH 4.5');
  s.cycleTo(0, 6.0);
  await shot('sweep', 'hold 6.0');
  s.cycleTo(0, 6.5);
  s.birdY = .56;
  await shot('vent', 'vent 6.5 lamp opens');
  s.cycleTo(0, 7.1);
  await shot('vent', 'vent 7.1');
  s.rock();
  s.cycleTo(0, 7.25);
  await shot('vent', 'HIT +.1');
  s.cycleTo(0, 7.4);
  await shot('vent', 'HIT +.25');
  // Cycle 1: LOW (the bird is in the lower half as it is aimed).
  s.cycleTo(1, 1.95);
  s.birdY = .75;
  s.cycleTo(1, 3.0);
  await shot('low', 'warning LOW 3.0');
  s.cycleTo(1, 3.6);
  s.birdY = .22;
  s.cycleTo(1, 4.6);
  await shot('low', 'sweep LOW 4.6');
  s.cycleTo(1, 4.7);
  await shot('low', 'feather 4.7');
  // The bird in the beam: SPOTTED!
  s.vulnerable = true;
  s.birdY = .78;
  s.cycleTo(1, 5.0);
  await shot('low', 'SPOTTED +.0');
  s.cycleTo(1, 5.3);
  await shot('low', 'SPOTTED +.3');
  s.vulnerable = false;
  s.cycleTo(1, 6.0);
  s.birdY = .56;
  s.cycleTo(1, 7.0);
  // The blow that crosses into fury.
  s.boss.hp = s.boss.maxHp ~/ 2 + 5;
  s.rock();
  s.runTo(s.boss.age + .06);
  s.rock();
  final fury0 = s.boss.age;
  var guard = 0;
  while (!s.boss.enraged && guard++ < 120) {
    s.tick();
  }
  s.runTo(fury0 + .12);
  await shot('fury', 'fury +.1');
  s.runTo(s.boss.enragedAt + .3);
  await shot('fury', 'fury +.3 roar');
  s.runTo(s.boss.enragedAt + .6);
  await shot('fury', 'fury +.6');
  s.runTo(s.boss.enragedAt + 1.4);
  await shot('fury', 'fury +1.4');
  // Cycle 2: the first fury sweep is a zone sweep.
  s.cycleTo(2, 1.95);
  s.birdY = .3;
  s.cycleTo(2, 4.0);
  s.birdY = .8;
  await shot('fury', 'fury zone 4.0');
  // Cycle 3: the slit.
  s.cycleTo(3, 1.9);
  s.birdY = .5;
  s.cycleTo(3, 2.8);
  await shot('slit', 'slit warning 2.8');
  s.cycleTo(3, 4.0);
  await shot('slit', 'slit 4.0');
  s.cycleTo(3, 5.2);
  await shot('slit', 'slit 5.2');
  s.cycleTo(3, 7.0);
  s.birdY = .56;
  // The killing blow.
  s.boss.hp = 10;
  s.rock();
  var kill = 0;
  while (s.boss.phase != BossPhase.defeated && kill++ < 120) {
    s.tick();
  }
  final dead = s.boss.defeatedAt!;
  for (final d in const [.04, .1, .2, .32, .5, .7, .86, .95, 1.1, 1.3, 1.56, 1.8, 2.1, 2.4, 2.8, 3.2, 3.6]) {
    s.runTo(dead + d);
    await shot('defeat', 'defeat +${d.toStringAsFixed(2)}');
  }
  for (final e in out.entries) {
    final frames = e.value;
    for (var i = 0; i < frames.length; i += 6) {
      await sheet(_folder, '${e.key}-$tag-${i ~/ 6}', frames.skip(i).take(6).toList(), cols: 3, scale: tag.startsWith('640') ? .8 : .64);
    }
    for (final (label, image) in frames) {
      await _write('f-$tag-${e.key}-${label.replaceAll(' ', '_').replaceAll(RegExp(r'[^A-Za-z0-9_.+-]'), '')}', image);
    }
    await disposeAll(frames);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);

  group('review frames', skip: _review ? false : 'set GARGOYLE_STAGING_REVIEW=1', () {
    for (final (width, reduced) in const [(640.0, false), (800.0, false), (640.0, true), (800.0, true)]) {
      final tag = '${width.toInt()}${reduced ? 'rm' : ''}';
      testWidgets('fight $tag', (tester) async {
        await tester.runAsync(() async {
          final s = await stage(tester, width, reduced: reduced);
          s.runTo(s.boss.arrivalDuration);
          await _fight(s, tag);
          if (!reduced) {
            // The distant lightning, on a flight of its own (the fight above
            // runs the clock through the defeat).
            final t = await stage(tester, width);
            t.runTo(t.boss.arrivalDuration);
            await _lightning(t, tag);
          }
        });
      }, timeout: const Timeout(Duration(minutes: 8)));
      testWidgets('arrival $tag', (tester) async {
        await tester.runAsync(() async {
          final s = await stage(tester, width, reduced: reduced);
          final all = <(String, ui.Image)>[];
          for (final (label, age) in _arrivalBeats) {
            all.add((label, await s.at(age)));
          }
          for (var i = 0; i < all.length; i += 6) {
            await sheet(_folder, 'arrival-$tag-${i ~/ 6}', all.skip(i).take(6).toList(), cols: 3, scale: width == 640 ? .8 : .64);
          }
          for (final (label, image) in all) {
            await _write('f-$tag-arrival-${label.split(' ').first}', image);
          }
          await disposeAll(all);
        });
      }, timeout: const Timeout(Duration(minutes: 5)));
    }

    // The whole encounter as a video: arrival, a real fight flown by the pilot
    // (the real rules, base damage), the killing blow and the defeat.
    testWidgets('video', skip: Platform.environment['GARGOYLE_STAGING_VIDEO'] != '1', (tester) async {
      await tester.runAsync(() async {
        final s = await stage(tester, 640);
        s.hold = false;
        s.birdY = .5;
        _folder.createSync(recursive: true);
        final ff = await Process.start('ffmpeg', [
          '-y', '-f', 'rawvideo', '-pix_fmt', 'rgba', '-s', '640x360', '-r', '30', '-i', '-',
          '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '20', '${_folder.path}/gargoyle-encounter.mp4',
        ]);
        ff.stderr.drain<void>();
        var frames = 0;
        var tick = 0;
        double? dead;
        while (s.sim.boss != null && (dead == null || s.boss.age - dead < 3.7) && frames < 30 * 140) {
          // During the arrival the bird coasts at mid-height; the pilot takes over after.
          s.hold = s.boss.phase == BossPhase.arriving;
          s.tick();
          if (s.sim.boss == null) break;
          if (s.boss.defeatedAt != null) dead ??= s.boss.defeatedAt;
          if (tick++ % 2 == 0) {
            final image = await s.render();
            ff.stdin.add(await rgba(image));
            image.dispose();
            frames++;
          }
        }
        await ff.stdin.close();
        await ff.exitCode;
      });
    }, timeout: const Timeout(Duration(minutes: 20)));
  });
}
