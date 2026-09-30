import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/pirate_rigging_art.dart';
import 'package:push_up_bird/game/pirate_ship_art.dart';

/// The Pirate Captain's masts, sails, rigging and flags are pure, seekable
/// and still under Reduced Motion, respond to fury and damage, and stay
/// inside the ship's [PirateShipArt.bounds] (the arrival silhouette layer is
/// clipped to them).
const _unit = 24.0;
const _pad = 1.0;

SkyBoss _boss({double t = 1.2}) {
  final boss = SkyBoss(number: 4, x: 2, kind: BossKind.pirate, cinematic: true);
  boss.age = boss.arrivalDuration + t;
  return boss;
}

/// The rigging alone, rig units around the origin, at [_unit] px per unit
/// with a margin of [_pad] units around the bounds.
Future<Uint8List> _pixels(SkyBoss boss, {bool reduced = false}) async {
  const bounds = PirateShipArt.bounds;
  final w = ((bounds.width + 2 * _pad) * _unit).ceil();
  final h = ((bounds.height + 2 * _pad) * _unit).ceil();
  final recorder = ui.PictureRecorder();
  final c = Canvas(recorder);
  c.translate((_pad - bounds.left) * _unit, (_pad - bounds.top) * _unit);
  c.scale(_unit);
  PirateRiggingArt.paint(c, boss, BossMotion(boss, reducedMotion: reduced));
  final picture = recorder.endRecording();
  final image = await picture.toImage(w, h);
  final bytes = (await image.toByteData())!.buffer.asUint8List();
  image.dispose();
  picture.dispose();
  return bytes;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the rigging renders deterministically and seeks exactly', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final boss = _boss();
      final first = await _pixels(boss);
      expect(await _pixels(_boss()), first);
      boss.age += .37;
      expect(await _pixels(boss), isNot(equals(first)), reason: 'It sways');
      boss.age -= .37;
      expect(await _pixels(boss), first, reason: 'Sway seeks exactly');
    });
  });

  testWidgets('Reduced Motion holds the rigging still', (tester) async {
    await tester.runAsync(() async {
      final idle = await _pixels(_boss(), reduced: true);
      expect(await _pixels(_boss(t: 2.9), reduced: true), idle);
      final shot = _boss()..lastVolleyAt = _boss().age - .12;
      expect(await _pixels(shot, reduced: true), idle);
    });
  });

  testWidgets('fury, damage and the recoil each change the rigging', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final calm = await _pixels(_boss());
      final hurt = _boss()..hp = _boss().maxHp * 3 ~/ 4;
      final fury = _boss()..hp = _boss().maxHp ~/ 3;
      final recoil = _boss()..lastVolleyAt = _boss().age - .12;
      final hurtPixels = await _pixels(hurt);
      final furyPixels = await _pixels(fury);
      expect(hurtPixels, isNot(equals(calm)), reason: 'Shot holes open');
      expect(furyPixels, isNot(equals(calm)));
      expect(furyPixels, isNot(equals(hurtPixels)));
      expect(await _pixels(recoil), isNot(equals(calm)), reason: 'Luffs');
    });
  });

  testWidgets('nothing is drawn outside the ship bounds', (tester) async {
    await tester.runAsync(() async {
      const bounds = PirateShipArt.bounds;
      final w = ((bounds.width + 2 * _pad) * _unit).ceil();
      final states = <String, SkyBoss>{
        'calm': _boss(),
        'later': _boss(t: 3.1),
        'sailing in': _boss(t: -3.3),
        'fury': _boss()..hp = _boss().maxHp ~/ 3,
        'defeated': _boss()..defeatedAt = _boss().age - .3,
      };
      for (final (name, boss) in states.entries.map((e) => (e.key, e.value))) {
        final pixels = await _pixels(boss);
        final rows = pixels.length ~/ 4 ~/ w;
        // A pixel of slack for the antialiased edge.
        final left = (_pad * _unit).floor() - 1;
        final right = ((_pad + bounds.width) * _unit).ceil() + 1;
        final top = (_pad * _unit).floor() - 1;
        final bottom = ((_pad + bounds.height) * _unit).ceil() + 1;
        var painted = 0;
        for (var y = 0; y < rows; y++) {
          for (var x = 0; x < w; x++) {
            if (x >= left && x <= right && y >= top && y <= bottom) {
              if (pixels[(y * w + x) * 4 + 3] > 0) painted++;
              continue;
            }
            expect(
              pixels[(y * w + x) * 4 + 3],
              0,
              reason: '$name draws outside the bounds at $x,$y',
            );
          }
        }
        expect(painted, greaterThan(5000), reason: '$name draws the rigging');
      }
    });
  });
}
