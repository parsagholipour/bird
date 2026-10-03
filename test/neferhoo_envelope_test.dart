import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/neferhoo_layout.dart';
import 'package:push_up_bird/game/neferhoo_pose.dart';
import 'package:push_up_bird/game/neferhoo_rig.dart';

import 'neferhoo_art_support.dart';

/// Neferhoo's envelope: every combat pose (every 1/10 s of whole calm and
/// fury cycles at 560 to 960 px, the hits, the stamp, the stage-up roar,
/// Reduced Motion) stays inside [NeferhooLayout.envelope] (the design's
/// measured union: -3.16 / -3.34 / 4.22 / 2.12), and the envelope at his
/// place in the fight is on screen at 640, 800 and 864 x 360 (nothing crops).

const _unit = 20.0;
const _win = Rect.fromLTRB(-5, -5, 6, 4);

Future<Rect> _bounds(NeferhooPose p) async {
  final w = (_win.width * _unit).round(), h = (_win.height * _unit).round();
  final rec = ui.PictureRecorder();
  final c = Canvas(rec)
    ..translate(-_win.left * _unit, -_win.top * _unit)
    ..scale(_unit);
  // full detail: the widest level (the silhouette draws every part flat)
  NeferhooPainter(c, p, silhouette: true, sil: const Color(0xff000000), lod: 3).paint();
  final pic = rec.endRecording();
  final img = await pic.toImage(w, h);
  final px = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
  img.dispose();
  pic.dispose();
  return _box(px, w, h);
}

Rect _box(Uint8List px, int w, int h) {
  var l = w, t = h, r = -1, b = -1;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (px[(y * w + x) * 4 + 3] > 24) {
        l = math.min(l, x);
        r = math.max(r, x);
        t = math.min(t, y);
        b = math.max(b, y);
      }
    }
  }
  return Rect.fromLTRB(l / _unit + _win.left, t / _unit + _win.top, (r + 1) / _unit + _win.left, (b + 1) / _unit + _win.top);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every combat pose stays inside the envelope', () async {
    final env = NeferhooLayout.envelope.inflate(1 / _unit);
    Rect? union;
    var returns = 0;
    for (final px in [560.0, 640.0, 800.0, 864.0, 960.0]) {
      for (final stage in [1, 2]) {
        for (final reduced in [false, true]) {
          final boss = courier(px: px, stage: stage);
          for (var i = 0; i < 120; i++) {
            final t = 12 + i / 10;
            fightTo(boss, t);
            // a letter is sent back every so often (a real rock): its landing's
            // recoil and the stamp
            if (i % 17 == 5) {
              for (final letter in boss.liveLetters) {
                if (!letter.returned && letter.xAt(boss.age, boss.handX) > FlightSimulation.birdX + .2) {
                  returnLetter(boss, letter);
                  returns++;
                  break;
                }
              }
            }
            final p = NeferhooPose.fight(boss, BossMotion(boss, reducedMotion: reduced), lookY: i.isEven ? 1.2 : -1.2);
            final r = await _bounds(p);
            union = union == null ? r : union.expandToInclude(r);
            expect(env.contains(r.topLeft) && env.contains(r.bottomRight), isTrue, reason: '${px.round()} px stage $stage t $t${reduced ? ' RM' : ''}: $r');
          }
        }
      }
    }
    expect(returns, greaterThanOrEqualTo(10), reason: 'letters sent back (their landings recoil and stamp)');
    // the roar of a stage-up (a real blow to a third: the rules roar)
    final boss = courier(stage: 1);
    fightTo(boss, 14);
    boss.takeDamage(boss.hp - boss.maxHp ~/ 3);
    for (var i = 0; i < 15; i++) {
      fightTo(boss, 14 + i / 10);
      final r = await _bounds(NeferhooPose.fight(boss, BossMotion(boss, reducedMotion: false)));
      union = union!.expandToInclude(r);
      expect(env.contains(r.topLeft) && env.contains(r.bottomRight), isTrue, reason: 'roar: $r');
    }
    expect(boss.stageReached, 2);
    // ignore: avoid_print
    print('combat union of the painted rig (rig units): $union; envelope ${NeferhooLayout.envelope}');
  }, timeout: const Timeout(Duration(minutes: 6)));

  test('the envelope is on screen wherever he fights (640 px and wider)', () {
    // (at 560 px the rules' anchor, max(bird + .70, width - .55), leaves his tail tip 43 px
    // past the right edge: see HANDOFF; every phone the game targets is 640 px or wider)
    for (final px in [640.0, 720.0, 800.0, 864.0, 960.0]) {
      final w = px / 360;
      final x = Neferhoo.anchorX(FlightSimulation.birdX, w);
      for (var t = 0.0; t < 8; t += .05) {
        final y = Neferhoo.hoverY(t);
        final e = NeferhooLayout.envelope;
        final left = x + e.left * SkyBoss.radius, right = x + e.right * SkyBoss.radius;
        final top = y + e.top * SkyBoss.radius, bottom = y + e.bottom * SkyBoss.radius;
        expect(right, lessThanOrEqualTo(w), reason: '${px.round()} px: right edge ${right * 360} px');
        expect(top, greaterThanOrEqualTo(0), reason: '${px.round()} px: top ${top * 360} px');
        expect(bottom, lessThanOrEqualTo(1), reason: '${px.round()} px: bottom ${bottom * 360} px');
        // and his beak never reaches the bird's column
        expect(left, greaterThan(FlightSimulation.birdX + FlightSimulation.birdRadius), reason: '${px.round()} px');
      }
    }
  });
}
