// The Searchlight Gargoyle contract's VISUAL REVIEW: renders the real rig, its
// beams and its staging through the real pose channels into PNGs. Off unless
//   flutter test --dart-define=GARGOYLE_REVIEW=true test/gargoyle_review_test.dart
// Writes build/visual-review/gargoyle-contract/ (or $GARGOYLE_OUT): the eight
// evidence sheets (01..08) and a few extras (Reduced Motion, head close-ups).
@Timeout(Duration(minutes: 10))
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart' show FontWeight, TextDirection, TextPainter, TextSpan, TextStyle;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/sky_boss.dart';
import 'package:push_up_bird/game/boss_health_bar_art.dart';
import 'package:push_up_bird/game/gargoyle_beam_art.dart';
import 'package:push_up_bird/game/gargoyle_boss_rig.dart';
import 'package:push_up_bird/game/gargoyle_kit.dart';
import 'package:push_up_bird/game/gargoyle_layout.dart';
import 'package:push_up_bird/game/gargoyle_pose.dart';
import 'package:push_up_bird/game/regions/world_backdrop.dart';
import 'package:push_up_bird/game/sky_scenery.dart';

import 'proof/gargoyle_proof_rig.dart';
import 'proof/gargoyle_stage.dart';

const _review = bool.fromEnvironment('GARGOYLE_REVIEW');
const _outEnv = String.fromEnvironment('GARGOYLE_OUT');
final _out = _outEnv.isEmpty ? 'build/visual-review/gargoyle-contract' : _outEnv;
const _ink = ui.Color(0xff222222);

Future<void> _save(ui.Image image, String name) async {
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  File('$_out/$name.png')
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(png!.buffer.asUint8List());
}

Future<ui.Image> _render(int w, int h, void Function(ui.Canvas) draw) async {
  final rec = ui.PictureRecorder();
  final c = ui.Canvas(rec)..clipRect(ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()));
  draw(c);
  final pic = rec.endRecording();
  final img = await pic.toImage(w, h);
  pic.dispose();
  return img;
}

double _tw(String s, double size) {
  final p = TextPainter(
    text: TextSpan(text: s, style: TextStyle(fontFamily: 'Nunito', fontSize: size, fontWeight: FontWeight.w800)),
    textDirection: TextDirection.ltr,
  )..layout();
  return p.width;
}

typedef _P = (String, GargoylePose Function());

List<_P> _poses() => [
  ('idle (Reduced Motion)', () => poseOf(gBoss(1.0), reduced: true)),
  ('feather wind-up', () => poseOf(gBoss(4.35))),
  ('feather shrug (blade leaves)', () => poseOf(gBoss(4.6 + .04))),
  ('warning HIGH (t 3.0)', () => poseOf(gBoss(3.0))),
  ('warning LOW (t 3.3)', () => poseOf(gBoss(3.3, side: BeamSide.low))),
  ('sweep HIGH (t 4.8)', () => poseOf(gBoss(4.8))),
  ('sweep LOW (t 5.2)', () => poseOf(gBoss(5.2, side: BeamSide.low))),
  ('vent (lamp open, steam)', () => poseOf(gBoss(7.2))),
  ('fury slit', () => poseOf(gBoss(5.0, fury: true, slit: true))),
  ('fury roar', () => poseOf(gBoss(1.0, fury: true, enragedAgo: .4))),
  ('hit', () => poseOf(gBoss(1.0, hitAgo: .08))),
  ('stone (arrival 1.0 s)', () => poseOf(gBoss(1.0 - 4.6))),
  ('waking roar (arrival 3.0 s)', () => poseOf(gBoss(3.0 - 4.6))),
  ('defeat slump (.6 s)', () => poseOf(gBoss(1.0, deadFor: .6))),
];

enum _Mode { colour, realFlat, proof }

Future<ui.Image> _sheet(int cell, _Mode mode, {List<_P>? poses, int cols = 5}) async {
  final list = poses ?? _poses();
  final rows = (list.length / cols).ceil();
  const label = 22;
  final w = cols * cell, h = rows * (cell + label);
  const fx0 = -5.0, fy0 = -4.6, span = 9.7;
  final scale = cell / span;
  final env = GargoyleLayout.envelope;
  return _render(w, h, (c) {
    c.drawRect(ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()), ui.Paint()..color = const ui.Color(0xffe9dfd2));
    for (var i = 0; i < list.length; i++) {
      final (name, mk) = list[i];
      final pose = mk();
      final x0 = (i % cols) * cell.toDouble(), y0 = (i ~/ cols) * (cell + label).toDouble() + label;
      text(c, name, ui.Offset(x0 + 4, y0 - label + 2), cell >= 200 ? 12 : 10, _ink, bold: false);
      c.save();
      c.clipRect(ui.Rect.fromLTWH(x0, y0, cell.toDouble(), cell.toDouble()));
      c.translate(x0 - fx0 * scale, y0 - fy0 * scale);
      c.scale(scale);
      final lim = ui.Paint()
        ..color = const ui.Color(0xffd33a3a)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1 / scale;
      c.drawLine(const ui.Offset(4.35, -5), const ui.Offset(4.35, 5), lim);
      c.drawLine(const ui.Offset(-5, 4.35), const ui.Offset(5, 4.35), lim);
      c.drawLine(const ui.Offset(-5, -4.35), const ui.Offset(5, -4.35), lim);
      switch (mode) {
        case _Mode.colour:
          c.drawRect(
            const ui.Rect.fromLTRB(-3.7, -4.35, 4.35, 4.35),
            ui.Paint()..shader = ui.Gradient.linear(const ui.Offset(0, -4.35), const ui.Offset(0, 4.35), const [ui.Color(0xff33305e), ui.Color(0xff6a5b8c)]),
          );
          GargoyleBossRig.paintPose(c, pose);
        case _Mode.realFlat:
          c.saveLayer(null, ui.Paint()..colorFilter = const ui.ColorFilter.mode(ui.Color(0xff000000), ui.BlendMode.srcIn));
          GargoyleBossRig.paintPose(c, pose, plinth: false);
          c.restore();
        case _Mode.proof:
          paintProofGargoyle(c, pose, plinth: true);
      }
      c.drawRect(
        env,
        ui.Paint()
          ..color = const ui.Color(0xff2f9f3a)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 1.2 / scale,
      );
      c.restore();
    }
  });
}

/// One arrival frame: the rules slide him in from the right edge (x eased from
/// the screen's edge to the anchor between .95 s and 2.65 s) and the art pins
/// y to the anchor.
SkyBoss _arrivalBoss(double age, double aspect) {
  final b = gBoss(age - 4.6, aspect: aspect);
  final target = SearchlightGargoyle.anchorX(GargoyleLayout.birdColumn, aspect);
  final e = ((age - .95) / 1.7).clamp(0.0, 1.0);
  final ease = 1 - math.pow(1 - e, 3);
  b.x = (aspect + .3) * (1 - ease) + target * ease;
  return b;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(family)..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
  });

  test('01..03 silhouettes and the pose sheet', skip: !_review, () async {
    await _save(await _sheet(250, _Mode.realFlat), '01-silhouette-250');
    await _save(await _sheet(120, _Mode.realFlat), '02-silhouette-120');
    await _save(await _sheet(250, _Mode.colour), '03-pose-sheet');
    await _save(await _sheet(250, _Mode.proof), 'x-sil-proof-250');
  });

  test('04 the anchor sheet', skip: !_review, () async {
    const w = 1240, h = 820;
    const k = 78.0; // px per rig unit
    const origin = ui.Offset(600, 360);
    final pose = GargoylePose.still;
    final img = await _render(w, h, (c) {
      c.drawRect(ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()), ui.Paint()..color = const ui.Color(0xffeee6da));
      c.drawRect(
        ui.Rect.fromLTRB(origin.dx - 4.9 * k, origin.dy - 4.35 * k, origin.dx + 4.35 * k, origin.dy + 4.35 * k),
        ui.Paint()..shader = ui.Gradient.linear(ui.Offset(0, origin.dy - 4.35 * k), ui.Offset(0, origin.dy + 4.35 * k), const [ui.Color(0xff34315f), ui.Color(0xff6a5b8c)]),
      );
      c.save();
      c.translate(origin.dx, origin.dy);
      c.scale(k);
      GargoyleBossRig.paintPose(c, pose);
      void frame(ui.Rect r, ui.Color col, {double wdt = 2}) => c.drawRect(
        r,
        ui.Paint()
          ..color = col
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = wdt / k,
      );
      frame(GargoyleLayout.envelope, const ui.Color(0xff35d07f));
      frame(GargoyleLayout.restEnvelope, const ui.Color(0xff35d07f).withValues(alpha: .45), wdt: 1.2);
      frame(const ui.Rect.fromLTRB(-4.9, -4.35, 4.35, 4.35), const ui.Color(0xffff4a5a));
      frame(GargoyleLayout.layerBounds, const ui.Color(0xffb0a0ff).withValues(alpha: .7), wdt: 1.2);
      // the HP bar zone at 640 (x < .14) and 800 (x < -.85), above y -3.65
      c.drawRect(ui.Rect.fromLTRB(-9, -4.35, GargoyleLayout.healthBarRight640, GargoyleLayout.healthBarBottom), ui.Paint()..color = const ui.Color(0xffffb84a).withValues(alpha: .22));
      c.drawRect(ui.Rect.fromLTRB(-9, -4.35, GargoyleLayout.healthBarRight800, GargoyleLayout.healthBarBottom), ui.Paint()..color = const ui.Color(0xffffb84a).withValues(alpha: .28));
      c.drawCircle(
        ui.Offset.zero,
        1,
        ui.Paint()
          ..color = const ui.Color(0xffff3b6b)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 2.5 / k,
      );
      c.restore();
      ui.Offset pt(ui.Offset rig) => origin + rig * k;
      void pin(ui.Offset rig, String label, ui.Offset at, {ui.Color col = const ui.Color(0xffffffff)}) {
        final p = pt(rig);
        c.drawLine(p, at + const ui.Offset(0, 9), ui.Paint()..color = col.withValues(alpha: .9)..strokeWidth = 1.4);
        c.drawCircle(p, 4.5, ui.Paint()..color = col);
        c.drawCircle(p, 4.5, ui.Paint()..color = GargoylePalette.ink..style = ui.PaintingStyle.stroke..strokeWidth = 1.2);
        final box = ui.Rect.fromLTWH(at.dx - 4, at.dy - 3, _tw(label, 12) + 10, 21);
        c.drawRRect(ui.RRect.fromRectAndRadius(box, const ui.Radius.circular(5)), ui.Paint()..color = const ui.Color(0xff17162b).withValues(alpha: .88));
        text(c, label, at, 12, const ui.Color(0xfffff2c9), maxW: 2000);
      }

      String f(ui.Offset o) => '(${o.dx.toStringAsFixed(2)}, ${o.dy.toStringAsFixed(2)})';
      final near = GargoyleBossRig.eyeAt(pose), far = GargoyleBossRig.eyeAt(pose, far: true);
      pin(ui.Offset.zero, 'LAMP = CHEST = HIT CIRCLE · r 1.00 at (0, 0), never moves', const ui.Offset(24, 600), col: const ui.Color(0xffff3b6b));
      pin(near, 'NEAR LENS · beam source ${f(near)} · r ${(GargoyleLayout.eyeNearRadius * GargoyleLayout.headScale).toStringAsFixed(2)}', const ui.Offset(16, 120), col: GargoylePalette.lampWarm);
      pin(far, 'FAR LENS (slit\'s upper beam) ${f(far)} · r ${(GargoyleLayout.eyeFarRadius * GargoyleLayout.headScale).toStringAsFixed(2)}', const ui.Offset(16, 160), col: GargoylePalette.lampWarm);
      pin(GargoyleBossRig.beakTipAt(pose), 'BEAK TIP ${f(GargoyleBossRig.beakTipAt(pose))}: most forward point · hook ≥ .55 beyond the brow', const ui.Offset(16, 204));
      pin(const ui.Offset(-.9, -3.35), 'CREST: 3 swept blades · top ≈ -3.6 at rest', const ui.Offset(16, 40));
      pin(GargoyleLayout.shoulder, 'NEAR FAN root (0.80, -1.25) · 7 blades', const ui.Offset(820, 40));
      pin(GargoyleLayout.farShoulder, 'FAR FAN root (1.10, -1.55)', const ui.Offset(820, 78));
      pin(const ui.Offset(4.0, -1.4), 'FAN TIP limit: R ≤ 4.32 after the lean · T ≥ -3.85', const ui.Offset(820, 116));
      pin(const ui.Offset(1.1, -2.6), 'STEAM PORTS (.55,-1.95) (1.15,-2.25)', const ui.Offset(820, 154));
      pin(GargoyleLayout.tailRoot + const ui.Offset(1.4, .3), 'TAIL FAN root (1.40, 2.05) · 5 blades', const ui.Offset(820, 640));
      pin(const ui.Offset(-1.3, GargoyleLayout.ledgeY), 'TALONS grip the ledge lip y = 2.95', const ui.Offset(16, 700));
      pin(GargoyleLayout.vaneMount + const ui.Offset(0, -1.1), 'EMPTY VANE MOUNT (-2.0, 2.95→1.68)', const ui.Offset(16, 660));
      pin(const ui.Offset(1.0, 3.5), 'LEDGE · lip y 2.95 · corbels to 4.2 (staging, not envelope)', const ui.Offset(820, 720));
      pin(const ui.Offset(4.0, 0.5), 'TOWER PIER x ≥ 3.55 (runs off the top)', const ui.Offset(820, 360));
      pin(const ui.Offset(-6.0, -3.95), 'HP BAR zone: y < -3.65 and x < +0.14 (640 wide) / -0.85 (800)', const ui.Offset(16, 4), col: const ui.Color(0xffffb84a));
      text(c, 'SEARCHLIGHT GARGOYLE · anchor sheet · rig units: 1 = hit radius = .115 of the screen height = 41.4 px at 360 · green = ENVELOPE (L -4.40 T -3.85 R 4.32 B 3.50) · red = screen (right 4.35, top/bottom ±4.35) · violet = layer clip',
          const ui.Offset(14, 794), 12, _ink, maxW: 1220);
    });
    await _save(img, '04-anchors');
  });

  test('05..06 in-game frames at 640 and 800 over New York', skip: !_review, () async {
    for (final w in [640, 800]) {
      final s = ui.Size(w.toDouble(), 360);
      final aspect = w / 360;
      final shots = <(String, SkyBoss, FrameOptions)>[
        ('PERCH · a stone feather drops from the cornice', gBoss(.35, aspect: aspect), const FrameOptions(birdY: .65)),
        ('WARNING · fly low: fan, dark side, tag (green/red strip = safe/hurt bird heights)', gBoss(3.1, aspect: aspect), const FrameOptions(birdY: .7, rules: true)),
        ('SWEEP HIGH · beam at its inner end; the bird sits in the dark', gBoss(5.4, aspect: aspect), const FrameOptions(birdY: .78, rules: true)),
        ('SWEEP LOW · the other way: refuge above', gBoss(5.2, side: BeamSide.low, aspect: aspect), const FrameOptions(birdY: .25, rules: true)),
        ('VENT · beam off, shutters open: shoot the lamp', gBoss(7.1, aspect: aspect), const FrameOptions(birdY: .5)),
        ('FURY · the slit closes: hold between the beams', gBoss(5.0, fury: true, slit: true, aspect: aspect), const FrameOptions(birdY: .5, rules: true)),
      ];
      final img = await _render(w * 2, 360 * 3, (c) {
        for (var i = 0; i < shots.length; i++) {
          c.save();
          c.translate((i % 2) * s.width, (i ~/ 2) * s.height);
          c.clipRect(ui.Offset.zero & s);
          final o = shots[i].$3;
          paintFrame(c, s, shots[i].$2, FrameOptions(birdY: o.birdY, rules: o.rules, label: shots[i].$1));
          c.restore();
        }
      });
      await _save(img, w == 640 ? '05-ingame-640' : '06-ingame-800');
    }
  });

  test('07 the beam study', skip: !_review, () async {
    const size = ui.Size(640, 360);
    final boss = gBoss(4.6);
    final pose = poseOf(boss);
    final b = pose.beams.single;
    final eye = bossCentre(size, boss) + GargoyleBossRig.beamOrigins(pose).near * (360 * SkyBoss.radius);
    final img = await _render(1280, 360 + 150 + 250 + 130, (c) {
      c.drawRect(const ui.Rect.fromLTWH(0, 0, 1280, 900), ui.Paint()..color = const ui.Color(0xff14122a));
      // A: in the game over New York; B: over the brightest sky (Egypt).
      for (var i = 0; i < 2; i++) {
        c.save();
        c.translate(i * 640.0, 0);
        c.clipRect(ui.Offset.zero & size);
        paintFrame(c, size, boss, FrameOptions(birdY: .78, region: i == 0 ? WorldRegion.newYork : WorldRegion.egypt, hud: false, rules: i == 0));
        text(c, i == 0 ? 'A · New York night: warm, hard-edged, from his lenses (the region\'s own cream beams are behind)' : 'B · the brightest sky (Egypt): the hard edge and the warmth still carry it',
            const ui.Offset(8, 4), 11, const ui.Color(0xffffffff), outline: true);
        c.restore();
      }
      // C: exploded layers along one beam.
      const names = ['1 haze (130% wide, .13)', '2 body (.27)', '3 core (50% wide, .42)', '4 hairline edges + lens flare', 'all (6 ops, ~18 vertices)'];
      const masks = [1, 2, 4, 8, 15];
      for (var k = 0; k < 5; k++) {
        c.save();
        c.translate(k * 256.0, 360);
        c.clipRect(const ui.Rect.fromLTWH(0, 0, 256, 150));
        c.drawRect(const ui.Rect.fromLTWH(0, 0, 256, 150), ui.Paint()..color = const ui.Color(0xff1b1838));
        // the same beam scaled to fit the panel: eye at the right, band at the left
        final sc = 256 / 640.0 * 1.0;
        c.translate(0, 75 - eye.dy * sc);
        c.scale(sc);
        GargoyleBeamArt.beam(c, size, b, eye, layers: masks[k]);
        c.restore();
        text(c, names[k], ui.Offset(k * 256.0 + 6, 364), 10, const ui.Color(0xffffe39a), outline: true);
      }
      // D: the warning fans.
      for (var i = 0; i < 3; i++) {
        final bb = switch (i) {
          0 => gBoss(3.2),
          1 => gBoss(3.3, side: BeamSide.low),
          _ => gBoss(3.4, fury: true, slit: true),
        };
        c.save();
        c.translate(i * 426.0, 510);
        c.clipRect(const ui.Rect.fromLTWH(0, 0, 426, 240));
        c.scale(426 / 640.0);
        paintFrame(c, size, bb, const FrameOptions(birdY: .5, hud: false));
        c.restore();
      }
      text(c, 'D · the warning (1.5 s): fan the beam will sweep, dashed extreme edges, the dark side washed cool with chevrons, dodge tag clear of the bird\'s column',
          const ui.Offset(8, 514), 11, const ui.Color(0xffffffff), outline: true);
      // E: NY cream beside the boss beam over the same sky (the contrast numbers).
      const night = ui.Color(0xff2c3055);
      c.drawRect(const ui.Rect.fromLTWH(0, 760, 1280, 140), ui.Paint()..color = night);
      c.drawRect(ui.Rect.fromLTWH(40, 780, 420, 70), ui.Paint()..color = ui.Color.alphaBlend(GargoyleBeamLook.regionCream.withValues(alpha: .22), night));
      text(c, 'New York\'s own searchlight: cream #f5ecd2 at ≤ .22, saturation .14, no edge', const ui.Offset(44, 856), 11, const ui.Color(0xffffffff), outline: true);
      c.drawRect(ui.Rect.fromLTWH(520, 780, 420, 70), ui.Paint()..color = ui.Color.alphaBlend(GargoyleBeamLook.body.withValues(alpha: .27), night));
      c.drawRect(ui.Rect.fromLTWH(520, 780, 420, 1.6), ui.Paint()..color = GargoyleBeamLook.edge.withValues(alpha: .75));
      c.drawRect(ui.Rect.fromLTWH(520, 848.4, 420, 1.6), ui.Paint()..color = GargoyleBeamLook.edge.withValues(alpha: .75));
      text(c, 'the boss beam: amber #ffd36a body, hard 1.6 px #ffb84a edges, saturation .58-.71', const ui.Offset(524, 856), 11, const ui.Color(0xffffffff), outline: true);
      c.drawRect(ui.Rect.fromLTWH(1000, 780, 240, 70), ui.Paint()..color = ui.Color.alphaBlend(GargoyleBeamLook.furyBody.withValues(alpha: .34), night));
      c.drawRect(ui.Rect.fromLTWH(1000, 780, 240, 1.6), ui.Paint()..color = GargoyleBeamLook.furyEdge.withValues(alpha: .75));
      c.drawRect(ui.Rect.fromLTWH(1000, 848.4, 240, 1.6), ui.Paint()..color = GargoyleBeamLook.furyEdge.withValues(alpha: .75));
      text(c, 'fury: arc-white, orange edge', const ui.Offset(1004, 856), 11, const ui.Color(0xffffffff), outline: true);
    });
    await _save(img, '07-beam-study');
    // make sure the sky helpers are used
    expect(SkyScenery.paint, isNotNull);
    expect(WorldBackdrop.cruise, greaterThan(0));
  });

  test('08 envelope at both sizes, arrival, defeat', skip: !_review, () async {
    final arrival = [.6, 1.6, 1.75, 2.1, 2.4, 2.7, 3.0, 4.0];
    final defeat = [.05, .3, .6, .9, 1.2, 2.2];
    final img = await _render(1600, 360 + 30 + 2 * 225 + 30 + 225 + 40, (c) {
      c.drawRect(const ui.Rect.fromLTWH(0, 0, 1600, 1100), ui.Paint()..color = const ui.Color(0xff14122a));
      // Envelope: ghosts of every beat at 640 and 800 with the box and the bar.
      for (final (i, w) in [640, 800].indexed) {
        final s = ui.Size(w.toDouble(), 360);
        final aspect = w / 360;
        c.save();
        c.translate(i == 0 ? 0.0 : 660.0, 0);
        c.clipRect(ui.Offset.zero & s);
        final ghosts = <SkyBoss>[
          for (final t in const [1.0, 2.5, 3.2, 3.6, 4.6, 5.0, 5.6, 6.4, 7.0, 7.6, 8.5, 13.6]) gBoss(t, aspect: aspect),
          gBoss(1.0, fury: true, enragedAgo: .4, aspect: aspect),
          gBoss(4.4, hitAgo: .1, aspect: aspect),
          gBoss(5.0, side: BeamSide.low, aspect: aspect),
        ];
        paintFrame(c, s, gBoss(1.0, aspect: aspect), FrameOptions(ghostPoses: ghosts, hud: true, dim: .4));
        final u = 360 * SkyBoss.radius;
        final cx = SearchlightGargoyle.anchorX(GargoyleLayout.birdColumn, aspect) * 360;
        c.drawRect(
          ui.Rect.fromLTRB(cx + GargoyleLayout.envelope.left * u, 180 + GargoyleLayout.envelope.top * u, cx + GargoyleLayout.envelope.right * u, 180 + GargoyleLayout.envelope.bottom * u),
          ui.Paint()..color = const ui.Color(0xff35d07f)..style = ui.PaintingStyle.stroke..strokeWidth = 1.6,
        );
        final bar = BossHealthBarArt.bounds(s, gBoss(1.0, aspect: aspect));
        c.drawRect(bar, ui.Paint()..color = const ui.Color(0xffffb84a)..style = ui.PaintingStyle.stroke..strokeWidth = 1.4);
        text(c, '${w}x360 · 15 poses ghosted · green = envelope · amber = health bar', const ui.Offset(8, 340), 11, const ui.Color(0xffffffff), outline: true);
        c.restore();
      }
      // Arrival strip (the rig alone: the lightning, dust and pigeons are G8's).
      for (final (i, age) in arrival.indexed) {
        c.save();
        c.translate((i % 4) * 400.0, 390 + (i ~/ 4) * 225.0);
        c.clipRect(const ui.Rect.fromLTWH(0, 0, 400, 225));
        c.scale(400 / 640.0);
        const s = ui.Size(640, 360);
        paintFrame(c, s, _arrivalBoss(age, 640 / 360), FrameOptions(hud: false, label: 'arrival ${age.toStringAsFixed(2)} s'));
        c.restore();
      }
      // Defeat strip.
      for (final (i, d) in defeat.indexed) {
        c.save();
        c.translate(i * 266.0, 870);
        c.clipRect(const ui.Rect.fromLTWH(0, 0, 266, 150));
        c.scale(266 / 640.0);
        const s = ui.Size(640, 360);
        paintFrame(c, s, gBoss(1.0, deadFor: d), FrameOptions(hud: false, label: 'defeat ${d.toStringAsFixed(2)} s'));
        c.restore();
      }
      text(c, 'the rig alone: the arrival\'s lightning / dust / pigeons and the defeat\'s burst / chunks / rubble are the staging\'s (G8)', const ui.Offset(8, 1024), 12, const ui.Color(0xffffe39a), outline: true);
    });
    await _save(img, '08-envelope-arrival-defeat');
  });

  test('extras: Reduced Motion sheet and the head close-ups', skip: !_review, () async {
    final rm = <_P>[
      ('RM idle', () => poseOf(gBoss(1.0), reduced: true)),
      ('RM warning HIGH', () => poseOf(gBoss(3.0), reduced: true)),
      ('RM sweep LOW', () => poseOf(gBoss(5.0, side: BeamSide.low), reduced: true)),
      ('RM vent', () => poseOf(gBoss(7.0), reduced: true)),
      ('RM fury', () => poseOf(gBoss(1.0, fury: true), reduced: true)),
      ('RM hit', () => poseOf(gBoss(1.0, hitAgo: .1), reduced: true)),
      ('RM stone', () => poseOf(gBoss(-3.6), reduced: true)),
      ('RM roar', () => poseOf(gBoss(-1.6), reduced: true)),
      ('RM defeat', () => poseOf(gBoss(1.0, deadFor: .7), reduced: true)),
    ];
    await _save(await _sheet(220, _Mode.colour, poses: rm, cols: 5), 'x-reduced-motion');
    const cells = 6, cw = 330, ch = 300;
    final heads = <_P>[
      ('idle', () => poseOf(gBoss(1.0), reduced: true)),
      ('warning', () => poseOf(gBoss(3.2), reduced: true)),
      ('sweep LOW', () => poseOf(gBoss(5.0, side: BeamSide.low), reduced: true)),
      ('vent (beak open)', () => poseOf(gBoss(7.0), reduced: true)),
      ('fury', () => poseOf(gBoss(1.0, fury: true), reduced: true)),
      ('hit', () => poseOf(gBoss(1.0, hitAgo: .08), reduced: true)),
    ];
    final img = await _render(cells * cw, ch + 22, (c) {
      c.drawRect(ui.Rect.fromLTWH(0, 0, (cells * cw).toDouble(), (ch + 22).toDouble()), ui.Paint()..color = const ui.Color(0xff2a2746));
      for (var i = 0; i < cells; i++) {
        c.save();
        c.translate(i * cw.toDouble(), 22);
        c.clipRect(ui.Rect.fromLTWH(0, 0, cw.toDouble(), ch.toDouble()));
        c.translate(cw * .78, ch * .80);
        c.scale(58);
        GargoyleBossRig.paintPose(c, heads[i].$2(), only: {'head', 'ruff', 'lamp'}, plinth: false);
        c.restore();
        text(c, heads[i].$1, ui.Offset(i * cw + 6.0, 3), 12, const ui.Color(0xffffffff));
      }
    });
    await _save(img, 'x-head-closeups');
  });
}
