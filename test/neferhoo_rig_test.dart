import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/neferhoo_boss_rig.dart';
import 'package:push_up_bird/game/neferhoo_kit.dart';
import 'package:push_up_bird/game/neferhoo_layout.dart';
import 'package:push_up_bird/game/neferhoo_pose.dart';
import 'package:push_up_bird/game/neferhoo_rig.dart';

import 'neferhoo_art_support.dart';

/// Neferhoo's rig (A1, the port of `egypt-ws/iter5/test/egypt/`): a pure
/// function of the boss and its motion (determinism, seeks), safe on bad
/// numbers, frozen under Reduced Motion, the same creature at every level of
/// detail (LOD parity at 41, 55, 60, 65 and 150 px per unit; the design's 4x4
/// block measure across the 60 px/unit switch), and warm after `prewarm`.

Future<Uint8List> _pixels(int w, int h, void Function(Canvas) draw) async {
  final rec = ui.PictureRecorder();
  draw(Canvas(rec));
  final pic = rec.endRecording();
  final img = await pic.toImage(w, h);
  final data = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
  img.dispose();
  pic.dispose();
  return data;
}

/// The rig at [unit] px per unit in a window of [win] (rig units).
Future<Uint8List> _shot(NeferhooPose p, double unit, Rect win, {bool sil = false, Set<String>? layers, bool sky = true}) {
  final w = (win.width * unit).round(), h = (win.height * unit).round();
  return _pixels(w, h, (c) {
    if (sky) c.drawRect(Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()), Paint()..color = const Color(0xffcfd8e0));
    c.translate(-win.left * unit, -win.top * unit);
    c.scale(unit);
    NeferhooPainter(c, p, silhouette: sil, sil: const Color(0xff000000), layers: layers).paint();
  });
}

Future<Uint8List> _rig(SkyBoss boss, {bool reduced = false}) => _pixels(400, 300, (c) {
  c.drawRect(const Rect.fromLTWH(0, 0, 400, 300), Paint()..color = const Color(0xffcfd8e0));
  c.translate(220, 170);
  c.scale(41.4);
  NeferhooBossRig.paint(c, boss, BossMotion(boss, reducedMotion: reduced), lookY: .3);
});

final _keyPoses = <(String, NeferhooPose)>[
  ('calm', NeferhooPose(crest: .4, wing: .2, phase: .3)),
  ('mail', NeferhooPose(crest: .42, wing: .45, cards: 3, satchelOpen: 1, reach: 1, wingRate: 0, brow: -.4, lean: .05, phase: .5, glint: .5)),
  ('ankh', NeferhooPose(crest: 1, wing: -.9, wingRate: 0, ankh: 1, glow: .9, brow: -.7, phase: .7)),
  ('fury', NeferhooPose(crest: 1, wing: -.6, fury: 1, unwrap: .8, cracked: 1, glow: 1, brow: -1, beak: .35, ribbons: 1.2, phase: 1.0)),
  ('express', NeferhooPose(crest: .6, wing: .45, fury: 1, unwrap: .8, cracked: 1, glow: 1, brow: -1, cards: 3, satchelOpen: 1, reach: 1, wingRate: 0, sweep: .6, lean: -.1, phase: 1.1)),
  ('gag', NeferhooPose(crest: .4, wing: .1, buff: 1, phase: 10.4, ringGlint: .5)),
];

/// The classic clock's beats are scripted here (12 s cycles, the gag's room,
/// the hint and lane moments): rules 54, the last rules on that clock. The
/// faster clock (rules 55) has its own checks (`neferhoo_faster_art_test`).
const _classic = FlightSimulation.cooRestartRulesVersion;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('determinism', () {
    test('the same fight state paints the same pixels, however it was reached', () async {
      for (final (px, stage) in [(640.0, 1), (800.0, 2), (864.0, 1)]) {
        for (final t in [12.6 + .3, 12 + 5.9, 12 + 7.2, 12 + 10.4, 12 + 11.5]) {
          // two real flights of the same level (a replay's seek re-flies it)
          final a = courier(px: px, stage: stage, version: _classic), b = courier(px: px, stage: stage, version: _classic);
          fightTo(a, t);
          fightTo(b, t);
          final pa = NeferhooPose.fight(a, BossMotion(a, reducedMotion: false), lookY: .3);
          final pb = NeferhooPose.fight(b, BossMotion(b, reducedMotion: false), lookY: .3);
          for (final (name, get) in <(String, double Function(NeferhooPose))>[
            ('wing', (p) => p.wing),
            ('crest', (p) => p.crest),
            ('lid', (p) => p.lid),
            ('look', (p) => p.look.dx + 7 * p.look.dy),
            ('buff', (p) => p.buff),
            ('glint', (p) => p.glint),
            ('sweep', (p) => p.sweep),
            ('ankh', (p) => p.ankh),
          ]) {
            expect(get(pa), get(pb), reason: '$name at $px px, t $t');
          }
          expect(await _rig(a), await _rig(b), reason: 'pixels at $px px, t $t');
        }
      }
    });

    test('bad numbers in the boss never reach the rig', () {
      final boss = courier(stage: 2, version: _classic);
      fightTo(boss, 20);
      boss
        ..lastHitAt = double.nan
        ..previousHitAt = double.nan
        ..enragedAt = double.nan;
      boss.neferhoo.lastLandAt = double.nan;
      for (final lookY in [double.nan, double.infinity, -5.0]) {
        final p = NeferhooPose.fight(boss, BossMotion(boss, reducedMotion: false), lookY: lookY);
        for (final v in [p.wing, p.crest, p.lid, p.brow, p.look.dx, p.look.dy, p.lean, p.headTilt, p.hit, p.stamp, p.wingRate ?? 0]) {
          expect(v.isFinite, isTrue);
        }
      }
      boss.age = double.nan;
      final p = NeferhooPose.fight(boss, BossMotion(boss, reducedMotion: false));
      expect(p.wing.isFinite && p.crest.isFinite, isTrue);
    });

    test('every beat of every stage paints at 640, 800 and 864 px, calm, fury and Reduced Motion', () {
      for (final px in [640.0, 800.0, 864.0]) {
        for (final stage in [0, 1, 2]) {
          final boss = courier(px: px, stage: stage, version: _classic);
          for (var t = 0.0; t < 24; t += .37) {
            fightTo(boss, t);
            for (final reduced in [false, true]) {
              final rec = ui.PictureRecorder();
              final c = Canvas(rec)..scale(41.4);
              NeferhooBossRig.paint(c, boss, BossMotion(boss, reducedMotion: reduced));
              rec.endRecording().dispose();
            }
          }
        }
      }
    });
  });

  group('Reduced Motion', () {
    test('the clocks freeze: two idle moments paint the same rig', () async {
      final boss = courier(stage: 0, version: _classic);
      fightTo(boss, 12 + 4.0);
      final a = await _rig(boss, reduced: true);
      fightTo(boss, 12 + 4.9);
      final b = await _rig(boss, reduced: true);
      expect(a, b);
      // and with motion on, he lives (breath, gaze, wingbeat)
      fightTo(boss, 24 + 4.0);
      final c = await _rig(boss);
      fightTo(boss, 24 + 4.9);
      expect(await _rig(boss), isNot(c));
    });

    test('the states stay: the fan, the raised ankh and fury show under Reduced Motion', () {
      final boss = courier(stage: 2, version: _classic);
      fightTo(boss, 12 + 1.7);
      final mail = NeferhooPose.fight(boss, BossMotion(boss, reducedMotion: true));
      expect(mail.cards, greaterThan(0));
      expect(mail.satchelOpen, greaterThan(.5));
      expect(mail.fury, 1);
      fightTo(boss, 12 + 6.3);
      final ankh = NeferhooPose.fight(boss, BossMotion(boss, reducedMotion: true));
      expect(ankh.ankh, greaterThan(.9));
      expect(ankh.buff, 0);
    });
  });

  group('LOD parity', () {
    test('across the 60 px/unit switch only texture changes (the design measure: 4x4 blocks)', () async {
      // design (iteration 5, closing round): whole rig 1119 / 1168 / 1205 of 11330 blocks,
      // the head layer alone 343 / 362 / 364 of 4266
      const win = Rect.fromLTRB(-3.4, -3.9, 4.0, 3.0), headWin = Rect.fromLTRB(-3.4, -3.9, 1.9, -.3);
      Future<(int, int)> blocks(NeferhooPose p, Rect w, Set<String>? layers) async {
        final a = await _shot(p, 59.9, w, layers: layers), b = await _shot(p, 60.1, w, layers: layers);
        final width = (w.width * 59.9).round(), height = (w.height * 59.9).round();
        final widthB = (w.width * 60.1).round();
        final dw = width ~/ 4, dh = height ~/ 4;
        var n = 0;
        for (var by = 0; by < dh; by++) {
          for (var bx = 0; bx < dw; bx++) {
            var d = 0.0;
            for (var k = 0; k < 4; k++) {
              var sa = 0, sb = 0;
              for (var yy = 0; yy < 4; yy++) {
                for (var xx = 0; xx < 4; xx++) {
                  sa += a[((by * 4 + yy) * width + bx * 4 + xx) * 4 + k];
                  sb += b[((by * 4 + yy) * widthB + bx * 4 + xx) * 4 + k];
                }
              }
              d = math.max(d, (sa - sb).abs() / 16);
            }
            if (d > 24) n++;
          }
        }
        return (n, dw * dh);
      }

      for (final (name, p) in [_keyPoses[0], _keyPoses[2], _keyPoses[3]]) {
        final (whole, total) = await blocks(p, win, null);
        final (head, headTotal) = await blocks(p, headWin, {'head'});
        // ignore: avoid_print
        print('lod pop $name: whole rig $whole of $total blocks, head $head of $headTotal');
        expect(whole / total, lessThan(.12), reason: '$name: whole rig $whole of $total blocks change');
        expect(head / headTotal, lessThan(.10), reason: '$name: head $head of $headTotal blocks change');
      }
    });

    test('the same creature at 41.4, 55, 60, 65 and 150 px per unit: no part appears or vanishes', () async {
      const win = Rect.fromLTRB(-3.6, -3.8, 4.6, 2.6);
      for (final (name, p) in _keyPoses) {
        final areas = <double, double>{}, boxes = <double, Rect>{};
        for (final unit in [41.4, 55.0, 60.0, 65.0, 150.0]) {
          final px = await _shot(p, unit, win, sil: true, sky: false);
          final w = (win.width * unit).round(), h = (win.height * unit).round();
          var n = 0, l = w, t = h, r = -1, b = -1;
          for (var y = 0; y < h; y++) {
            for (var x = 0; x < w; x++) {
              if (px[(y * w + x) * 4 + 3] > 127) {
                n++;
                l = math.min(l, x);
                r = math.max(r, x);
                t = math.min(t, y);
                b = math.max(b, y);
              }
            }
          }
          areas[unit] = n / (unit * unit);
          boxes[unit] = Rect.fromLTRB(l / unit + win.left, t / unit + win.top, (r + 1) / unit + win.left, (b + 1) / unit + win.top);
        }
        final ref = areas[150]!, box = boxes[150]!;
        // ignore: avoid_print
        print('lod silhouette $name: area (u²) ${areas.entries.map((e) => '${e.key}: ${e.value.toStringAsFixed(3)}').join(', ')}');
        for (final unit in areas.keys) {
          expect((areas[unit]! - ref).abs() / ref, lessThan(.03), reason: '$name area at $unit px/u: ${areas[unit]} vs $ref u²');
          final bx = boxes[unit]!;
          for (final d in [bx.left - box.left, bx.top - box.top, bx.right - box.right, bx.bottom - box.bottom]) {
            expect(d.abs(), lessThan(.08), reason: '$name bounds at $unit px/u: $bx vs $box');
          }
        }
      }
    });

    test('the level of detail follows the canvas, or the caller', () {
      expect([10.0, 11.0, 24.0, 41.4, 55.0, 59.9, 60.0, 150.0].map(NeferhooKit.lodOfScale), [0, 1, 2, 2, 2, 2, 3, 3]);
      final rec = ui.PictureRecorder();
      final c = Canvas(rec)..scale(41.4);
      expect(NeferhooPainter(c, NeferhooPose()).lod, 2);
      expect(NeferhooPainter(c, NeferhooPose(), lod: 3).lod, 3);
      rec.endRecording().dispose();
    });
  });

  test('after prewarm a fight frame at 640 and 800 px records no picture', () {
    NeferhooBossRig.prewarm();
    var recorded = 0;
    NeferhooKit.debugWrap = (c) {
      recorded++;
      return c;
    };
    addTearDown(() => NeferhooKit.debugWrap = null);
    for (final px in [640.0, 800.0]) {
      for (final stage in [1, 2]) {
        final boss = courier(px: px, stage: stage, version: _classic);
        for (var t = 12.0; t < 24; t += .25) {
          fightTo(boss, t);
          final rec = ui.PictureRecorder();
          final c = Canvas(rec);
          c.save();
          c.translate(boss.x * 360, boss.y * 360);
          c.scale(360 * SkyBoss.radius);
          NeferhooBossRig.paint(c, boss, BossMotion(boss, reducedMotion: false));
          c.restore();
          rec.endRecording().dispose();
        }
      }
    }
    expect(recorded, 0);
  });

  test('the envelope and the layer bounds are the layout\'s', () {
    expect(NeferhooBossRig.envelope, NeferhooLayout.envelope);
    expect(NeferhooBossRig.layerBounds.contains(NeferhooLayout.envelope.topLeft), isTrue);
    expect(NeferhooBossRig.layerBounds.contains(NeferhooLayout.envelope.bottomRight), isTrue);
  });
}
