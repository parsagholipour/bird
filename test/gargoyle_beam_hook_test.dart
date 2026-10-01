import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/game/boss_encounter_art.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/gargoyle_layout.dart';

import 'gargoyle_pilot.dart' as pilot;
import 'proof/gargoyle_stage.dart';

/// The staging hooks of `patches/g5-beam.patch` in `BossEncounterArt`: the
/// warning and beams in the BACKDROP (under the obstacles, stars, feathers,
/// the boss and the bird), the lens flares after the rig, SPOTTED! in the
/// foreground. These tests need that patch applied (they are the proof that it
/// is wired), so they live apart from `gargoyle_beam_test.dart`.
const _size = ui.Size(640, 360);

Future<Uint8List> _render(void Function(ui.Canvas) draw) async {
  final rec = ui.PictureRecorder();
  draw(ui.Canvas(rec));
  final pic = rec.endRecording();
  final img = await pic.toImage(640, 360);
  final px = (await img.toByteData())!.buffer.asUint8List();
  img.dispose();
  pic.dispose();
  return px;
}

/// How many pixels differ by more than a little between two RGBA frames inside [r].
int _diff(Uint8List a, Uint8List b, ui.Rect r) {
  var n = 0;
  for (var y = r.top.floor(); y < r.bottom.ceil(); y++) {
    for (var x = r.left.floor(); x < r.right.ceil(); x++) {
      final i = (y * 640 + x) * 4;
      if ((a[i] - b[i]).abs() + (a[i + 1] - b[i + 1]).abs() + (a[i + 2] - b[i + 2]).abs() > 12) n++;
    }
  }
  return n;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Fredoka')..addFont(rootBundle.load('assets/fonts/Fredoka.ttf'))).load();
  });

  testWidgets('the backdrop carries the warning and the beam, and nothing of them is left to the encounter\'s paint', (tester) async {
    await tester.runAsync(() async {
      final perch = gBoss(1.0), sweep = gBoss(4.5), warn = gBoss(3.3);
      Future<Uint8List> backdrop(boss) => _render((c) => BossEncounterArt.backdrop(c, _size, boss, BossMotion(boss, reducedMotion: false)));
      final base = await backdrop(perch);
      final withBeam = await backdrop(sweep), withWarning = await backdrop(warn);
      // the beam: pixels at the bird's column and to its left, none beside the boss
      final col = GargoyleLayout.birdColumn * 360;
      expect(_diff(base, withBeam, ui.Rect.fromLTWH(col - 80, 20, 160, 200)), greaterThan(600));
      expect(_diff(base, withBeam, const ui.Rect.fromLTWH(560, 0, 80, 360)), 0, reason: 'nothing at the far right');
      expect(_diff(base, withWarning, ui.Rect.fromLTWH(col - 80, 20, 160, 300)), greaterThan(2000), reason: 'the warning veils and hatches the sky');
      // the encounter's own paint draws only the lens flares of it: nothing
      // at the bird's column (the beam and the veil are not drawn twice)
      final sim = pilot.arena();
      final boss = sim.boss!;
      pilot.fightAt(boss, 4.5);
      boss
        ..beamSide = sweep.beamSide
        ..sweepsAimed = 1;
      final m = BossMotion(boss, reducedMotion: false);
      final over = await _render((c) => BossEncounterArt.paint(c, _size, sim, m));
      final empty = await _render((c) {});
      expect(_diff(empty, over, ui.Rect.fromLTWH(col - 40, 0, 80, 360)), 0, reason: 'the paint leaves the bird\'s column to the backdrop');
    });
  });

  testWidgets('the foreground shows SPOTTED! around the bird once the rules have caught it, and only then', (tester) async {
    await tester.runAsync(() async {
      final sim = pilot.arena();
      final boss = sim.boss!
        ..beamSide = gBoss(4.5).beamSide
        ..sweepsAimed = 1
        ..featherCycle = 0
        ..featherSlot = 9;
      pilot.fightAt(boss, 4.5);
      final quiet = await _render((c) => BossEncounterArt.foreground(c, _size, sim, BossMotion(boss, reducedMotion: false)));
      expect(quiet.every((v) => v == 0), isTrue, reason: 'nothing before the catch');
      for (var i = 0; i < 3; i++) {
        sim
          ..birdY = .42
          ..velocity = 0;
        pilot.frame(sim, dt: 1 / 60);
      }
      expect(boss.spots, 1);
      final m = BossMotion(boss, reducedMotion: false);
      final caught = await _render((c) => BossEncounterArt.foreground(c, _size, sim, m));
      final bird = ui.Offset(GargoyleLayout.birdColumn * 360, .42 * 360);
      var ring = 0;
      for (var y = 0; y < 360; y++) {
        for (var x = 0; x < 640; x++) {
          if (caught[(y * 640 + x) * 4 + 3] > 40 && (ui.Offset(x + .5, y + .5) - bird).distance < 60) ring++;
        }
      }
      expect(ring, greaterThan(300), reason: 'the halo and the flash are at the bird');
      // and the reduced-motion foreground differs (no flash) yet still says it
      final still = await _render((c) => BossEncounterArt.foreground(c, _size, sim, BossMotion(boss, reducedMotion: true)));
      expect(still, isNot(caught));
      expect(still.any((v) => v != 0), isTrue);
      // later, healed and clear of the light: gone
      for (var i = 0; i < 120; i++) {
        sim.birdY = .9;
        pilot.frame(sim, dt: 1 / 60);
      }
      final gone = await _render((c) => BossEncounterArt.foreground(c, _size, sim, BossMotion(boss, reducedMotion: false)));
      expect(gone.every((v) => v == 0), isTrue);
    });
  });
}
