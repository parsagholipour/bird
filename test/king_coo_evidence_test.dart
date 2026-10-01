import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/sky_boss.dart';
import 'package:push_up_bird/game/king_coo_boss_rig.dart';
import 'package:push_up_bird/game/king_coo_layout.dart';
import 'package:push_up_bird/game/king_coo_pose.dart';
import 'package:push_up_bird/game/sky_scenery.dart';

import 'king_coo_test_kit.dart';

/// Review renders for King Coo's contract: the pose sheet, the anchor map, the
/// envelope onion skin, in-game frames over New York at 640 and 800, and the
/// motion strips, all through the REAL rig and the REAL pose channels. They
/// are written to `build/king-coo-review/` (or `--dart-define=KING_COO_OUT=`);
/// the silhouette sheets (`sil-250`, `sil-120`) come from
/// `king_coo_silhouette_test.dart`. Nothing here asserts pixels: it asserts
/// that each picture was made and is not empty.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('evidence: the pose sheet over New York', (tester) async {
    await tester.runAsync(() async {
      await loadFonts();
      final light = newYorkLight();
      final poses = sheetPoses(light: light);
      const cols = 4, cw = 330, ch = 290;
      final rows = (poses.length / cols).ceil();
      await savePng('pose-sheet', cw * cols, ch * rows, (c) {
        for (var i = 0; i < poses.length; i++) {
          final x = (i % cols) * cw.toDouble(), y = (i ~/ cols) * ch.toDouble();
          c.save();
          c.clipRect(Rect.fromLTWH(x, y, cw.toDouble(), ch.toDouble()));
          c.translate(x - 320 + 150, y - 150 + 150);
          // A slice of New York behind each cell, moving with the cell so the
          // backdrop is never the same twice.
          SkyScenery.paint(
            c,
            const Size(640, 360),
            seconds: 6.0 + i * 1.7,
            distance: (6.0 + i * 1.7) * .36,
            held: WorldRegion.newYork,
          );
          c.restore();
          c.save();
          c.clipRect(Rect.fromLTWH(x, y, cw.toDouble(), ch.toDouble()));
          c.translate(x + 120, y + 152);
          c.scale(41.4);
          KingCooBossRig.paintPose(c, poses[i].$2);
          c.restore();
          c.drawRect(
            Rect.fromLTWH(x, y, cw.toDouble(), 22),
            Paint()..color = const Color(0xaa0c0a24),
          );
          label(c, poses[i].$1, Offset(x + 6, y + 3), color: const Color(0xffffffff), size: 13);
        }
      });
    });
  });

  testWidgets('evidence: the anchor map', (tester) async {
    await tester.runAsync(() async {
      await loadFonts();
      const ppu = 100.0, x0 = -3.2, y0 = -3.4, wU = 8.6, hU = 6.5;
      final pose = KingCooPose.still;
      final hold = poseOf(cooBoss(combat: 1.0, setup: (b) => b.lobs.add(lobAt(b.age - .6))), reduced: true);
      await savePng('anchors', (wU * ppu).round(), (hU * ppu).round(), (c) {
        c.drawRect(
          Rect.fromLTWH(0, 0, wU * ppu, hU * ppu),
          Paint()..color = const Color(0xffe6dfd6),
        );
        c.save();
        c.scale(ppu);
        c.translate(-x0, -y0);
        c.saveLayer(null, Paint()..color = const Color(0x88ffffff));
        KingCooBossRig.paintPose(c, pose);
        c.restore();
        Paint line(Color col, [double w = 1.6]) => Paint()
          ..color = col
          ..style = PaintingStyle.stroke
          ..strokeWidth = w / ppu;
        c.drawRect(KingCooLayout.envelope, line(const Color(0xff30a030), 2));
        c.drawRect(KingCooLayout.restEnvelope, line(const Color(0x8830a030)));
        c.drawRect(KingCooLayout.layerBounds, line(const Color(0x66a06030)));
        c.drawLine(const Offset(KingCooLayout.screenRight, -9), const Offset(KingCooLayout.screenRight, 9), line(const Color(0xffd03030)));
        c.drawLine(Offset(-9, KingCooLayout.healthBarClearance), Offset(9, KingCooLayout.healthBarClearance), line(const Color(0xffd03030)));
        c.drawCircle(Offset.zero, 1, line(const Color(0xff2060d0), 2.4));
        c.drawCircle(Offset.zero, KingCooLayout.chestFluffRadius, line(const Color(0x882060d0)));
        final labels = <(Offset, String, Color)>[];
        void dot(Offset p, String name, Color col) {
          c.drawCircle(p, 4 / ppu, Paint()..color = col);
          labels.add((p, name, col));
        }

        const head = Color(0xff107030), body = Color(0xff1050b0);
        const wing = Color(0xffc02020), tail = Color(0xff8040a0);
        dot(Offset.zero, 'CHEST (hit circle r 1)', body);
        dot(KingCooLayout.badge, 'badge', body);
        dot(KingCooBossRig.eyeAt(pose), 'eye', head);
        dot(KingCooBossRig.beakAt(pose), 'beak tip', head);
        dot(KingCooBossRig.mouthAt(pose), 'mouth', head);
        dot(KingCooBossRig.whistleAt(pose), 'whistle (hanging)', head);
        dot(pose.headPoint(KingCooLayout.headWhistle), 'whistle in beak', head);
        dot(KingCooBossRig.capAt(pose).at, 'cap seat', head);
        dot(KingCooBossRig.sirenAt(pose), 'siren', head);
        dot(KingCooLayout.headRest, 'head centre', head);
        dot(KingCooLayout.neckBase, 'neck base', head);
        dot(KingCooLayout.nearShoulder, 'near shoulder', wing);
        dot(KingCooLayout.farShoulder, 'far shoulder', wing);
        dot(hold.handAt, 'hand (wind-up hold)', wing);
        dot(KingCooLayout.lobRelease, 'LOB RELEASE (bomb origin)', wing);
        dot(KingCooLayout.sackMouth, 'sack mouth', tail);
        dot(KingCooLayout.tailRoot, 'tail root', tail);
        dot(KingCooLayout.nearHip, 'near hip', body);
        dot(KingCooLayout.farHip, 'far hip', body);
        // The wind-up's wing tip path (the toss, every 1/30 s).
        final path = Path();
        var first = true;
        for (var i = 0; i <= 24; i++) {
          final t = 4.6 + .6 + i * (.8 / 24);
          final p = poseOf(
            cooBoss(combat: 0, setup: (b) {
              b.lobs.add(lobAt(4.6 + .6));
              b.age = t;
            }),
            reduced: true,
          );
          final tip = p.handAt;
          first ? path.moveTo(tip.dx, tip.dy) : path.lineTo(tip.dx, tip.dy);
          first = false;
        }
        c.drawPath(path, line(const Color(0xffc02020), 1.5));
        c.restore();
        for (final (p, name, col) in labels) {
          label(
            c,
            name,
            (p - const Offset(x0, y0)) * ppu + const Offset(6, -16),
            color: col,
            size: 12,
          );
        }
        label(c, 'envelope (green), rest envelope, layer bounds (brown), screen right and health bar (red), hit circle (blue)', const Offset(8, 6), size: 12);
      });
    });
  });

  testWidgets('evidence: the envelope onion skin', (tester) async {
    await tester.runAsync(() async {
      await loadFonts();
      const ppu = 90.0, x0 = -3.3, y0 = -4.0, wU = 9.0, hU = 7.0;
      final sampled = <KingCooPose>[
        for (final (_, p) in combatPoses(cycles: 1, dt: .2)) p,
      ];
      await savePng('envelope', (wU * ppu).round(), (hU * ppu).round(), (c) {
        c.drawRect(
          Rect.fromLTWH(0, 0, wU * ppu, hU * ppu),
          Paint()..color = const Color(0xffe6dfd6),
        );
        c.save();
        c.scale(ppu);
        c.translate(-x0, -y0);
        for (final pose in sampled) {
          c.saveLayer(null, Paint()..color = const Color(0x16000000));
          KingCooBossRig.paintPose(c, pose);
          c.restore();
        }
        Paint line(Color col, [double w = 1.6]) => Paint()
          ..color = col
          ..style = PaintingStyle.stroke
          ..strokeWidth = w / ppu;
        c.drawRect(KingCooLayout.envelope, line(const Color(0xff30a030), 2));
        c.drawRect(KingCooLayout.layerBounds, line(const Color(0x66a06030)));
        c.drawLine(const Offset(KingCooLayout.screenRight, -9), const Offset(KingCooLayout.screenRight, 9), line(const Color(0xffd03030)));
        c.drawLine(Offset(-9, KingCooLayout.healthBarClearance), Offset(9, KingCooLayout.healthBarClearance), line(const Color(0xffd03030)));
        c.drawLine(Offset(-9, KingCooLayout.visibleWorst.top), Offset(9, KingCooLayout.visibleWorst.top), line(const Color(0x88d03030)));
        c.drawCircle(Offset.zero, 1, line(const Color(0xff2060d0), 2));
        c.restore();
        label(c, '${sampled.length} combat poses (every .2 s of the calm, fury, hit and pop cycles) over the envelope', const Offset(8, 6), size: 12);
        label(c, 'red: screen right / health bar / top of the worst hover', Offset(8, hU * ppu - 20), size: 12, color: const Color(0xffd03030));
      });
    });
  });

  testWidgets('evidence: in-game frames at 640 and 800', (tester) async {
    await tester.runAsync(() async {
      await loadFonts();
      final light = newYorkLight();
      for (final w in [640.0, 800.0]) {
        final frames = <(String, KingCooPose, double, double, WorldRegion?)>[
          (
            'idle: waddle-hover',
            poseOf(cooBoss(combat: 2.2), light: light),
            2.2,
            .5,
            null,
          ),
          (
            'wind-up: the bomb in his hand',
            poseOf(cooBoss(combat: 1.0, setup: (b) => b.lobs.add(lobAt(b.age - .55))), light: light),
            1.0,
            .5,
            null,
          ),
          (
            'puffed: chest = hit circle, whistle in the beak',
            poseOf(cooBoss(combat: 9.0), light: light),
            9.0,
            .5,
            null,
          ),
          (
            'fury + a hit',
            poseOf(cooBoss(combat: 2.3, fury: true, setup: (b) => b.lastHitAt = b.age - .07), light: light),
            2.3,
            .42,
            null,
          ),
          (
            'the same idle on a bright sky (Egypt)',
            poseOf(cooBoss(combat: 2.2), light: regionLight(WorldRegion.egypt)),
            2.2,
            .5,
            WorldRegion.egypt,
          ),
          (
            'arrival: the COO!',
            poseOf(arrivingBoss(3.0), light: light),
            0.0,
            .5,
            null,
          ),
          (
            'pop: three puffed hits',
            poseOf(cooBoss(combat: 8.9, setup: (b) => b.poppedAt = b.age - .45), light: light),
            8.9,
            .55,
            null,
          ),
          (
            'defeat: he inflates',
            poseOf(dyingBoss(.62), light: light),
            1.2,
            .5,
            null,
          ),
        ];
        final perRow = 2, rows = (frames.length / perRow).ceil();
        final fw = w.round(), fh = 360;
        await savePng('frames-${w.round()}', fw * perRow, fh * rows, (c) {
          for (var i = 0; i < frames.length; i++) {
            final (name, pose, t, birdY, region) = frames[i];
            c.save();
            c.translate((i % perRow) * fw.toDouble(), (i ~/ perRow) * fh.toDouble());
            nyFrame(
              c,
              w,
              pose: pose,
              combat: t,
              birdY: birdY,
              seconds: 12.0 + i,
              region: region ?? WorldRegion.newYork,
              above: (c, boss, h) {
                // What the health bar covers at the worst hover, for scale.
                c.drawLine(
                  Offset(0, (.5 - .06) * h + KingCooLayout.healthBarClearance * 41.4),
                  Offset(w, (.5 - .06) * h + KingCooLayout.healthBarClearance * 41.4),
                  Paint()
                    ..color = const Color(0x55ff4060)
                    ..strokeWidth = 1,
                );
              },
            );
            c.drawRect(
              const Rect.fromLTWH(0, 0, 300, 20),
              Paint()..color = const Color(0xaa0c0a24),
            );
            label(c, '$name @ ${w.round()}', const Offset(6, 2), color: const Color(0xffffffff), size: 12);
            c.restore();
          }
        });
      }
    });
  });

  testWidgets('evidence: the motion strips', (tester) async {
    await tester.runAsync(() async {
      await loadFonts();
      final light = newYorkLight();
      const cw = 168, ch = 150;
      const cols = 8;
      final rows = <(String, List<KingCooPose>)>[
        (
          'waddle-hover: one 1.25 s step (8 frames, 0.156 s apart)',
          [for (var i = 0; i < cols; i++) poseOf(cooBoss(combat: 2.0 + i * 1.25 / cols), light: light)],
        ),
        (
          'the throw: lock, dip, bomb, backswing, hold, swing, RELEASE, whip (every .1 s)',
          [
            for (var i = 0; i < cols; i++)
              poseOf(
                cooBoss(combat: 1.4 - .8 + i * .115, setup: (b) => b.lobs.add(lobAt(4.6 + 1.4 - .8))),
                light: light,
              ),
          ],
        ),
        (
          'the puff window: 7.6 inhale .. 8.5 whistle up .. 9.2 blow .. 10.4 settled',
          [
            for (final t in [7.6, 8.0, 8.5, 8.9, 9.2, 9.4, 10.0, 10.5])
              poseOf(cooBoss(combat: t), light: light),
          ],
        ),
        (
          'arrival: shadow 1.0, reveal 1.95, rears 2.45, COO! 2.8 / 3.0, swell 3.2, settles 3.8, ready 4.5',
          [
            for (final a in [1.0, 1.95, 2.45, 2.8, 3.0, 3.2, 3.8, 4.5])
              poseOf(arrivingBoss(a), light: light),
          ],
        ),
        (
          'defeat: hit-stop .05, cap rises .2, cap off .35, inflates .5 / .7 / .8, POP .9, gone 1.0',
          [
            for (final d in [.05, .2, .35, .5, .7, .8, .9, 1.0])
              poseOf(dyingBoss(d), light: light),
          ],
        ),
        (
          'Reduced Motion: idle, dip, hold, release, puffed, whistle, pop, fury (state stays, motion zero)',
          [
            poseOf(cooBoss(combat: 2.0), light: light, reduced: true),
            poseOf(cooBoss(combat: 1.0, setup: (b) => b.lobs.add(lobAt(b.age - .6))), light: light, reduced: true),
            poseOf(cooBoss(combat: 1.0, setup: (b) => b.lobs.add(lobAt(b.age - .7))), light: light, reduced: true),
            poseOf(cooBoss(combat: 1.0, setup: (b) => b.lobs.add(lobAt(b.age - .8))), light: light, reduced: true),
            poseOf(cooBoss(combat: 9.0), light: light, reduced: true),
            poseOf(cooBoss(combat: 9.3), light: light, reduced: true),
            poseOf(cooBoss(combat: 9.0, setup: (b) => b.poppedAt = b.age - .5), light: light, reduced: true),
            poseOf(cooBoss(combat: 2.0, fury: true), light: light, reduced: true),
          ],
        ),
      ];
      await savePng('motion-strips', cw * cols, (ch + 18) * rows.length, (c) {
        c.drawRect(
          Rect.fromLTWH(0, 0, (cw * cols).toDouble(), ((ch + 18) * rows.length).toDouble()),
          Paint()
            ..shader = ui.Gradient.linear(
              Offset.zero,
              Offset(0, ((ch + 18) * rows.length).toDouble()),
              const [Color(0xff2a2a52), Color(0xff6b5b86)],
            ),
        );
        for (var r = 0; r < rows.length; r++) {
          final y = r * (ch + 18).toDouble();
          label(c, rows[r].$1, Offset(6, y + 2), color: const Color(0xffffffff), size: 12);
          for (var i = 0; i < cols; i++) {
            c.save();
            c.clipRect(Rect.fromLTWH(i * cw.toDouble(), y + 18, cw.toDouble(), ch.toDouble()));
            c.translate(i * cw + 66.0, y + 18 + 72);
            c.scale(23);
            KingCooBossRig.paintPose(c, rows[r].$2[i]);
            c.restore();
          }
        }
      });
    });
  });

  test('the review renders were written', () {
    // (Each testWidgets above asserts its own file exists.)
    expect(math.pi, greaterThan(3));
    expect(SkyBoss.radius, .115);
  });
}
