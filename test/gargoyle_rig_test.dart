import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart' show Canvas;
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/sky_boss.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/gargoyle_boss_rig.dart';
import 'package:push_up_bird/game/gargoyle_body_art.dart';
import 'package:push_up_bird/game/gargoyle_head_art.dart';
import 'package:push_up_bird/game/gargoyle_kit.dart';
import 'package:push_up_bird/game/gargoyle_layout.dart';
import 'package:push_up_bird/game/gargoyle_pose.dart';
import 'package:push_up_bird/game/gargoyle_wing_art.dart';

import 'proof/gargoyle_raster.dart';
import 'proof/gargoyle_stage.dart';

/// `GargoyleBossRig`: the assembly. It only places and orders the parts; these
/// tests hold the API the parts, the beams, the staging and the story art code
/// against (anchors, order, balance, purity).
Future<Mask> _scan(GargoylePose pose, {Set<String>? only, bool plinth = false}) =>
    rasterize((c) => GargoyleBossRig.paintPose(c, pose, only: only, plinth: plinth), ppu: 24, solid: 200);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('API and anchors', () {
    test('the layer clip is the layout\'s; the lamp centre is the hit circle', () {
      expect(GargoyleBossRig.bounds, GargoyleLayout.layerBounds);
      expect(GargoyleBossRig.lampCenter, ui.Offset.zero);
    });

    test('beam sources: the near lens is lower and forward of the far one in every pose', () {
      for (var t = 0.0; t < 18; t += .37) {
        for (final (fury, slit) in const [(false, false), (true, true)]) {
          final p = poseOf(gBoss(t, fury: fury, slit: slit));
          final o = GargoyleBossRig.beamOrigins(p);
          expect(o.far.dy, lessThan(o.near.dy), reason: 't$t');
          expect(o.far.dx, greaterThan(o.near.dx), reason: 't$t');
          expect(GargoyleBossRig.eyeAt(p), o.near);
          expect(GargoyleBossRig.eyeAt(p, far: true), o.far);
        }
      }
    });

    test('the lenses stay clear of the lamp and of the crest: the anchors sit where the layout says', () {
      final p = GargoylePose.still;
      final near = GargoyleBossRig.eyeAt(p);
      expect(near.dx, closeTo(-2.5, .1));
      expect(near.dy, closeTo(-2.6, .12));
      expect(GargoyleBossRig.eyeRest, near);
      expect(GargoyleBossRig.beakTipAt(p).dx, lessThan(near.dx - 1.2));
    });

    testWidgets('the drawn lens is on the anchor: the pixel at eyeAt is bright glass', (tester) async {
      await tester.runAsync(() async {
        for (final (lean, pitch, head) in const [(0.0, 0.0, ui.Offset.zero), (.6, .3, ui.Offset(.1, .1)), (-.6, -.2, ui.Offset(.2, -.05))]) {
          final pose = GargoylePose.custom(brow: 0, flare: 1, lean: lean, pitch: pitch, head: head);
          final m = await rasterize((c) => GargoyleBossRig.paintPose(c, pose, only: {'head'}, plinth: false), ppu: 24, solid: 1);
          for (final far in [false, true]) {
            final e = GargoyleBossRig.eyeAt(pose, far: far);
            final x = ((e.dx - m.x0) * m.ppu).round(), y = ((e.dy - m.y0) * m.ppu).round();
            final i = (y * m.w + x) * 4;
            final (r, g, b) = (m.data[i], m.data[i + 1], m.data[i + 2]);
            expect(r, greaterThan(225), reason: 'lens ${far ? 'far' : 'near'} lean $lean pitch $pitch (r $r g $g b $b)');
            expect(g, greaterThan(200));
          }
        }
      });
    });

    testWidgets('the lamp is drawn on the hit circle in every lean', (tester) async {
      await tester.runAsync(() async {
        for (final lean in const [-.8, -.3, 0.0, .4, .8]) {
          final pose = GargoylePose.custom(lean: lean, lamp: .5);
          final m = await rasterize((c) => GargoyleBossRig.paintPose(c, pose, only: {'lamp'}, plinth: false), ppu: 24, solid: 200);
          final b = m.bounds!.rect;
          expect(b.center.dx, closeTo(0, .06), reason: 'lean $lean');
          expect(b.center.dy, closeTo(0, .06), reason: 'lean $lean');
          expect(b.width, closeTo(2 * GargoyleLayout.housingRadius * math.cos(math.pi / 8), .25), reason: 'lean $lean');
        }
      });
    });

    testWidgets('the legs, the talons and the tail stay on the ledge in every lean (they do not lean)', (tester) async {
      await tester.runAsync(() async {
        final base = await _scan(GargoylePose.custom(lean: 0), only: {'thigh', 'farLeg'});
        for (final lean in const [-.8, .8]) {
          final m = await _scan(GargoylePose.custom(lean: lean), only: {'thigh', 'farLeg'});
          expect(m.bounds!.rect, base.bounds!.rect, reason: 'lean $lean');
        }
      });
    });

    test('featherSpawn is the rules\' top-edge drop, the same x at both widths; the loosened blade leaves the near fan', () {
      final a = GargoyleBossRig.featherSpawn(const ui.Size(640, 360));
      final b = GargoyleBossRig.featherSpawn(const ui.Size(800, 360));
      expect(a, b);
      expect(a.dx, closeTo((GargoyleLayout.birdColumn + SearchlightGargoyle.featherOffsetX) * 360, 1e-9));
      expect(a.dy, closeTo(SearchlightGargoyle.featherY * 360, 1e-9));
      final p = poseOf(gBoss(4.6));
      final leave = GargoyleBossRig.featherLeaveAt(p);
      expect(GargoyleLayout.envelope.inflate(.6).contains(leave), isTrue);
      expect(leave.dy, lessThan(-2));
    });

    test('the visor the defeat knocks loose starts exactly on the slumped head and is continuous', () {
      final at = GargoyleBossRig.visorAt(GargoylePose.atDeath(.3));
      final drop = GargoyleBossRig.visorDrop(.3);
      expect(drop.at, at.at);
      expect(drop.scale, GargoyleLayout.headScale);
      expect(at.at, GargoylePose.atDeath(.3).headPoint(GargoyleLayout.visorSeat));
      var last = GargoyleBossRig.visorDrop(.0).at;
      for (var d = .01; d < 1; d += .01) {
        final now = GargoyleBossRig.visorDrop(d).at;
        expect((now - last).distance, lessThan(.12), reason: 'death $d');
        last = now;
      }
      // in Reduced Motion the seat is still
      expect(GargoyleBossRig.visorDrop(.35, reduced: true).at, GargoyleBossRig.visorDrop(.9, reduced: true).at);
    });
  });

  group('assembly', () {
    test('parts are painted in the layout\'s z-order, bloom first, shed last', () {
      final boss = gBoss(4.6 + .05); // a blade in flight
      final p = poseOf(boss);
      final lamp = poseOf(gBoss(7.0));
      expect(p.shedTau, greaterThanOrEqualTo(0));
      // a pose with the lamp open AND a blade in flight
      final both = GargoylePose.custom(lamp: 1);
      final seen = <String>[];
      GargoyleBossRig.paintPose(ui.Canvas(ui.PictureRecorder()), lamp, trace: seen.add);
      expect(seen, [for (final part in GargoyleLayout.zOrder) if (part != 'shed') part]);
      final seen2 = <String>[];
      GargoyleBossRig.paintPose(ui.Canvas(ui.PictureRecorder()), p, trace: seen2.add);
      expect(seen2.last, 'shed');
      expect(seen2.first, isNot('bloom'), reason: 'the bloom is only for an open lamp');
      expect(both.lamp, 1);
    });

    test('only= paints exactly the named parts', () {
      final pose = poseOf(gBoss(7.0));
      for (final part in GargoyleLayout.zOrder) {
        if (part == 'shed') continue;
        final seen = <String>[];
        GargoyleBossRig.paintPose(ui.Canvas(ui.PictureRecorder()), pose, only: {part}, trace: seen.add);
        expect(seen, [part]);
      }
      final seen = <String>[];
      GargoyleBossRig.paintPose(ui.Canvas(ui.PictureRecorder()), pose, plinth: false, trace: seen.add);
      expect(seen, isNot(contains('ledge')));
    });

    test('the canvas comes back as it was: saves balance, no layers', () {
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      final before = c.getSaveCount();
      for (final mk in <SkyBoss Function()>[
        () => gBoss(1.0),
        () => gBoss(4.6),
        () => gBoss(7.0),
        () => gBoss(3.2, side: BeamSide.low),
        () => gBoss(5.0, fury: true, slit: true),
        () => gBoss(-3.6),
        () => gBoss(1.0, deadFor: .5),
        () => gBoss(1.0, deadFor: 1.4),
      ]) {
        GargoyleBossRig.paintPose(c, poseOf(mk()));
        expect(c.getSaveCount(), before);
      }
      rec.endRecording().dispose();
    });

    test('the body that has crumbled paints the ledge and nothing else', () {
      final pose = poseOf(gBoss(1.0, deadFor: 1.4));
      expect(pose.crumble, closeTo(1, 1e-9));
      final seen = <String>[];
      GargoyleBossRig.paintPose(ui.Canvas(ui.PictureRecorder()), pose, trace: seen.add);
      expect(seen, ['ledge']);
    });

    testWidgets('paint(boss, motion) is paintPose(GargoylePose)', (tester) async {
      await tester.runAsync(() async {
        for (final boss in [gBoss(4.6), gBoss(7.0, fury: true), gBoss(1.0, hitAgo: .1)]) {
          final m = BossMotion(boss, reducedMotion: false);
          Future<Uint8List> px(void Function(ui.Canvas) draw) async {
            final rec = ui.PictureRecorder();
            final c = ui.Canvas(rec);
            c.translate(200, 190);
            c.scale(24);
            draw(c);
            final img = await rec.endRecording().toImage(400, 400);
            final d = (await img.toByteData())!.buffer.asUint8List();
            img.dispose();
            return Uint8List.fromList(d);
          }

          final a = await px((c) => GargoyleBossRig.paint(c, boss, m, light: const GargoyleSkyLight(dark: .8)));
          final b = await px((c) => GargoyleBossRig.paintPose(c, GargoylePose(boss, m, light: const GargoyleSkyLight(dark: .8))));
          expect(a, b);
        }
      });
    });

    testWidgets('a dark sky changes the light, not the drawing\'s bounds', (tester) async {
      await tester.runAsync(() async {
        final boss = gBoss(4.6);
        final day = await _scan(poseOf(boss, light: const GargoyleSkyLight(dark: 0)));
        final night = await _scan(poseOf(boss, light: const GargoyleSkyLight(dark: 1)));
        expect(night.bounds!.rect, day.bounds!.rect);
      });
    });

    test('a NaN or infinite clock paints (and every part rounds something)', () {
      for (final mutate in <void Function(SkyBoss)>[
        (b) => b.age = double.nan,
        (b) => b.lastHitAt = double.nan,
        (b) => b.enragedAt = double.infinity,
        (b) => b.defeatedAt = double.nan,
      ]) {
        final b = gBoss(3.0, fury: true);
        mutate(b);
        final rec = ui.PictureRecorder();
        expect(() => GargoyleBossRig.paint(ui.Canvas(rec), b, BossMotion(b, reducedMotion: false)), returnsNormally);
        rec.endRecording().dispose();
      }
    });

    test('the part factories speak the pose: the wings\' tips are the pose\'s fans\', the head and body read its channels', () {
      final pose = poseOf(gBoss(6.9));
      final near = GargoyleWing.nearOf(pose), far = GargoyleWing.farOf(pose);
      for (var i = 0; i < GargoyleLayout.fanBlades; i++) {
        expect(near.tips[i], pose.nearFan.tip(i, far: false));
        expect(far.tips[i], pose.farFan.tip(i, far: true));
      }
      expect(near.far, isFalse);
      expect(far.far, isTrue);
      final head = GargoyleHeadPose.of(pose);
      expect(head.gape, pose.gape);
      expect(head.brow, pose.brow);
      expect(head.visor, isTrue);
      final body = GargoyleBodyPose.of(pose);
      expect(body.lamp, pose.lamp);
      expect(body.steam, pose.steam);
      expect(GargoyleHeadPose.of(GargoylePose.atDeath(.5)).visor, isFalse);
      expect(GargoyleHeadPose.of(pose).tone.key, pose.tone.key);
    });

    testWidgets('a tone override reaches every part', (tester) async {
      await tester.runAsync(() async {
        final pose = GargoylePose.custom();
        final plain = await rasterize((c) => GargoyleBossRig.paintPose(c, pose, plinth: false), ppu: 12, solid: 200);
        final flashed = await rasterize(
          (c) => GargoyleBossRig.paintPose(c, pose.withTone(const GargoyleTone(flash: .55)), plinth: false),
          ppu: 12,
          solid: 200,
        );
        expect(plain.bounds!.rect, flashed.bounds!.rect);
        var brighter = 0;
        for (var i = 0; i < plain.data.length; i += 4) {
          if (plain.data[i + 3] > 200 && flashed.data[i] > plain.data[i] + 10) brighter++;
        }
        expect(brighter, greaterThan(300));
        expect(GargoyleKit.shadersBuilt, greaterThan(0));
      });
    });
  });
}
