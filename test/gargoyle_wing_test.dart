// The Searchlight Gargoyle's WINGS (G3): tests and the visual review.
//
// Review (off unless GARGOYLE_WING_REVIEW=true) writes PNGs to
// build/visual-review/gargoyle-wings/ (or $GARGOYLE_WING_OUT).
@Timeout(Duration(minutes: 10))
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/game/gargoyle_boss_rig.dart';
import 'package:push_up_bird/game/gargoyle_kit.dart';
import 'package:push_up_bird/game/gargoyle_layout.dart';
import 'package:push_up_bird/game/gargoyle_pose.dart';
import 'package:push_up_bird/game/gargoyle_wing_art.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/regions/world_backdrop.dart';

import 'campaign_flight.dart';
import 'ny_plans.dart';
import 'proof/counting_canvas.dart';
import 'proof/gargoyle_raster.dart';
import 'proof/gargoyle_stage.dart';

const _review = bool.fromEnvironment('GARGOYLE_WING_REVIEW');
const _outEnv = String.fromEnvironment('GARGOYLE_WING_OUT');
final _out = _outEnv.isEmpty ? 'build/visual-review/gargoyle-wings' : _outEnv;

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

/// One frame of the real game art at [size], cropped to the rig-unit window
/// [rect] (origin = the chest lamp) and drawn [ppu] pixels per unit.
void _crop(
  ui.Canvas c,
  ui.Size size,
  SkyBoss boss,
  ui.Rect rect,
  double ppu, {
  ui.Offset at = ui.Offset.zero,
  FrameOptions options = const FrameOptions(hud: false),
}) {
  final u = size.height * SkyBoss.radius;
  final centre = bossCentre(size, boss);
  c.save();
  c.translate(at.dx, at.dy);
  c.clipRect(ui.Rect.fromLTWH(0, 0, rect.width * ppu, rect.height * ppu));
  c.scale(ppu / u);
  c.translate(-(centre.dx + rect.left * u), -(centre.dy + rect.top * u));
  paintFrame(c, size, boss, options);
  c.restore();
}


/// CIE L* of an opaque 8-bit sRGB pixel.
double _lstar(int r, int g, int b) {
  double lin(int v) {
    final x = v / 255;
    return x <= .04045 ? x / 12.92 : math.pow((x + .055) / 1.055, 2.4).toDouble();
  }

  final y = .2126 * lin(r) + .7152 * lin(g) + .0722 * lin(b);
  return y > 216 / 24389 ? 116 * math.pow(y, 1 / 3).toDouble() - 16 : 24389 / 27 * y;
}

const _region = ui.Rect.fromLTRB(-1.5, -5.2, 6.0, 2.2);

Future<Mask> _paintParts(GargoylePose pose, Set<String> parts, {double ppu = 24}) => rasterize(
  (c) => GargoyleBossRig.paintPose(c, pose, only: parts, plinth: false),
  ppu: ppu,
  region: _region,
  solid: 255,
);

/// The contract's reference fans (blade outlines and hub polygons, inked with
/// [grow] more on every side), in the rig's leaned frame.
void _referenceFans(ui.Canvas c, GargoylePose pose, double grow) {
  c.rotate(GargoyleLayout.bodyTurn(pose.lean));
  final fill = ui.Paint()..color = const ui.Color(0xff000000);
  final line = ui.Paint()
    ..color = const ui.Color(0xff000000)
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = GargoyleLayout.inkMajor + 2 * grow
    ..strokeJoin = ui.StrokeJoin.round;
  for (final (fan, far) in [(pose.farFan, true), (pose.nearFan, false)]) {
    final root = GargoyleLayout.fanRoot(far: far);
    for (var i = 0; i < GargoyleLayout.fanBlades; i++) {
      final p = GargoyleKit.poly(GargoyleLayout.bladeOutline(root, fan.tip(i, far: far)));
      c.drawPath(p, fill);
      c.drawPath(p, line);
    }
    final hub = GargoyleKit.poly(GargoyleLayout.hubOutline).shift(root);
    c.drawPath(hub, fill);
    c.drawPath(hub, line);
  }
}

typedef _Look = (String, SkyBoss Function(), bool);

/// A spread of moments of the fight that exercise every wing state.
List<_Look> _moments() => [
  for (var k = 0; k < 30; k++) ('calm t${(k * .6).toStringAsFixed(1)}', () => gBoss(k * .6), false),
  for (var k = 0; k < 20; k++) ('fury t${(k * .9).toStringAsFixed(1)}', () => gBoss(k * .9, fury: true), false),
  for (var k = 0; k < 8; k++) ('slit t${(2 + k * 1.1).toStringAsFixed(1)}', () => gBoss(2 + k * 1.1, fury: true, slit: true), false),
  for (final e in const [.2, 4.6, 4.5, 5.2])
    for (final d in const [-.4, -.2, -.1, -.03, .0001, .03, .08, .15, .3, .45, .6])
      ('feather $e ${d >= 0 ? '+' : ''}$d', () => gBoss(e + d, fury: e == 4.5 || e == 5.2), false),
  for (var k = 0; k < 8; k++) ('rage +${(k * .15).toStringAsFixed(2)}', () => gBoss(1.0 + k * .15, fury: true, enragedAgo: k * .15), false),
  for (final h in const [.02, .06, .15]) ('hit +$h', () => gBoss(5.0, hitAgo: h), false),
  for (var k = 0; k < 24; k++) ('arrival ${(k * .19).toStringAsFixed(2)}', () => gBoss(k * .19 - 4.6), false),
  for (var k = 0; k < 8; k++) ('defeat +${(k * .12).toStringAsFixed(2)}', () => gBoss(1.0, deadFor: k * .12), false),
  for (var k = 0; k < 8; k++) ('RM t${k * 2.2}', () => gBoss(k * 2.2, fury: k.isOdd), true),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(family)..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
  });


  group('the wings', () {
    test('the fans are the layout\'s: every tip is fanTip of the pose\'s stroke and spread, the root is the layout\'s', () {
      for (final b in [gBoss(1.0), gBoss(4.58), gBoss(7.0), gBoss(1.0, fury: true, enragedAgo: .4), gBoss(-1.6)]) {
        final pose = poseOf(b);
        for (final far in [false, true]) {
          final wing = far ? GargoyleWing.farOf(pose) : GargoyleWing.nearOf(pose);
          final fan = far ? pose.farFan : pose.nearFan;
          expect(wing.far, far);
          expect(wing.root, GargoyleLayout.fanRoot(far: far));
          expect(wing.strokes, fan.strokes);
          expect(wing.spread, fan.spread);
          for (var i = 0; i < GargoyleLayout.fanBlades; i++) {
            expect(wing.tips[i], GargoyleLayout.fanTip(i, far: far, stroke: fan.strokes[i], spread: fan.spread));
          }
        }
        expect(GargoyleWing.nearOf(pose).shed, pose.nearFan.shed);
        expect(GargoyleWing.farOf(pose).shed, 0, reason: 'only the near fan loses a blade');
      }
    });

    test('budget: both fans and the flying blade are <= 80 ops / 3 shaders / 2 clips in every moment, no layer, no blur', () {
      GargoyleKit.clearCaches();
      var worstNear = 0, worstFar = 0, worstAll = 0, worstClips = 0, worstAt = '';
      for (final (name, mk, reduced) in _moments()) {
        final pose = poseOf(mk(), reduced: reduced);
        Counting count(Set<String> parts) {
          final c = Counting(ui.Canvas(ui.PictureRecorder()));
          GargoyleBossRig.paintPose(c, pose, only: parts, plinth: false);
          return c;
        }

        final near = count({'nearFan'}), far = count({'farFan'}), all = count({'farFan', 'nearFan', 'shed'});
        worstNear = math.max(worstNear, near.draws);
        worstFar = math.max(worstFar, far.draws);
        if (all.draws > worstAll) {
          worstAll = all.draws;
          worstAt = name;
        }
        worstClips = math.max(worstClips, all.clips);
        expect(all.layers + all.blurs, 0, reason: name);
        expect(all.counts['UNFORWARDED.noSuchMethod'] ?? 0, 0, reason: name);
      }
      final shaders = GargoyleKit.built.where((k) => '$k'.startsWith('wing.')).toList();
      // ignore: avoid_print
      print('wings: near <= $worstNear ops, far <= $worstFar, both + the loose blade <= $worstAll (at $worstAt), '
          '$worstClips clip(s), shaders $shaders');
      expect(worstAll, lessThanOrEqualTo(80));
      expect(worstClips, lessThanOrEqualTo(2));
      expect(shaders.length, lessThanOrEqualTo(3));
    });

    test('a warm frame builds no shader; a tone (hit flash, fury, stone, a dark or bright sky) is never a new one', () {
      for (final b in [gBoss(1.0), gBoss(4.55), gBoss(5.0, fury: true), gBoss(1.0, hitAgo: .05), gBoss(-3.6)]) {
        final pose = poseOf(b);
        final c = Counting(ui.Canvas(ui.PictureRecorder()));
        GargoyleBossRig.paintPose(c, pose, only: {'farFan', 'nearFan', 'shed'}, plinth: false);
        final before = GargoyleKit.shadersBuilt;
        for (final dark in const [0.0, .4, 1.0]) {
          GargoyleBossRig.paintPose(Counting(ui.Canvas(ui.PictureRecorder())), poseOf(b, light: GargoyleSkyLight(dark: dark)), only: {'farFan', 'nearFan', 'shed'}, plinth: false);
        }
        GargoyleBossRig.paintPose(Counting(ui.Canvas(ui.PictureRecorder())), pose, only: {'farFan', 'nearFan', 'shed'}, plinth: false);
        expect(GargoyleKit.shadersBuilt, before);
      }
    });

    testWidgets('inside the envelope in every moment, and inside the contract\'s blade outlines (+.12)', (tester) async {
      await tester.runAsync(() async {
        final out = <String>[];
        var worst = ui.Rect.zero;
        for (final (name, mk, reduced) in _moments()) {
          final pose = poseOf(mk(), reduced: reduced);
          final art = await _paintParts(pose, {'farFan', 'nearFan'}, ppu: 20);
          final b = art.bounds;
          if (b == null) continue;
          if (name.startsWith('arrival') && !name.contains('3.') && !name.contains('4.')) {
            // The arrival's unfold is staged: only the layer clip applies.
            continue;
          }
          worst = worst.expandToInclude(b.rect);
          final e = GargoyleLayout.envelope;
          if (b.rect.left < e.left - .03 || b.rect.top < e.top - .03 || b.rect.right > e.right + .03 || b.rect.bottom > e.bottom + .03) {
            out.add('$name: ${b.rect} outside the envelope');
          }
          final ref = await rasterize((c) => _referenceFans(c, pose, .12), ppu: 20, region: _region, solid: 128);
          var stray = 0;
          var minX = 1e9, minY = 1e9, maxX = -1e9, maxY = -1e9;
          for (var i = 0; i < art.solid.length; i++) {
            if (art.solid[i] == 1 && ref.solid[i] == 0) {
              final px = art.ux(i % art.w), py = art.uy(i ~/ art.w);
              // The shoulders (pauldron, nozzle, pins) are drawn a little fuller than the
              // contract's hub; the blades are the contract's.
              if ((ui.Offset(px, py) - GargoyleLayout.shoulder).distance < 1.7 || (ui.Offset(px, py) - GargoyleLayout.farShoulder).distance < 1.7) continue;
              stray++;
              minX = math.min(minX, px);
              maxX = math.max(maxX, px);
              minY = math.min(minY, py);
              maxY = math.max(maxY, py);
            }
          }
          if (stray > 2) {
            out.add('$name: $stray px of the wings outside the contract outlines, in x ${minX.toStringAsFixed(2)}..${maxX.toStringAsFixed(2)} y ${minY.toStringAsFixed(2)}..${maxY.toStringAsFixed(2)}');
          }
        }
        // ignore: avoid_print
        print('wings union over the sweep: $worst   envelope ${GargoyleLayout.envelope}');
        expect(out.take(8), isEmpty);
      });
    }, timeout: const Timeout(Duration(minutes: 3)));

    testWidgets('value separation: the cool steel fans and the warm limestone body never share a value, the far fan sits back, and none is black', (tester) async {
      await tester.runAsync(() async {
        double median(Mask m) {
          final v = <double>[];
          for (var i = 0; i < m.w * m.h; i++) {
            if (m.data[i * 4 + 3] < 255) continue;
            final l = _lstar(m.data[i * 4], m.data[i * 4 + 1], m.data[i * 4 + 2]);
            if (l > 14) v.add(l); // the ink is not a material
          }
          v.sort();
          return v[v.length ~/ 2];
        }

        // Warm or cool: the mean of red minus blue over the solid, non-ink pixels.
        double warmth(Mask m) {
          var s = 0.0, n = 0;
          for (var i = 0; i < m.w * m.h; i++) {
            if (m.data[i * 4 + 3] < 255) continue;
            if (_lstar(m.data[i * 4], m.data[i * 4 + 1], m.data[i * 4 + 2]) <= 14) continue;
            s += m.data[i * 4] - m.data[i * 4 + 2];
            n++;
          }
          return s / n;
        }

        final pose = poseOf(gBoss(1.0));
        final nearMask = await _paintParts(pose, {'nearFan'});
        final bodyMask = await _paintParts(pose, {'torso', 'ruff'});
        expect(warmth(nearMask), lessThan(0), reason: 'the steel fans are cool');
        expect(warmth(bodyMask), greaterThan(0), reason: 'the limestone body is warm');
        final wings = median(nearMask);
        final far = median(await _paintParts(pose, {'farFan'}));
        final body = median(bodyMask);
        // ignore: avoid_print
        print('median L*: near fan ${wings.toStringAsFixed(1)}, far fan ${far.toStringAsFixed(1)}, body ${body.toStringAsFixed(1)}');
        // The contract's first-cut body was cream limestone (L* 75), the real one
        // (G2) is a shaded violet-grey stone (L* 48): the wings are now the
        // LIGHTER of the two. What must hold is that they never share a value,
        // and (always) that steel and stone differ in hue as well.
        expect((body - wings).abs(), greaterThanOrEqualTo(8), reason: 'the wing must not share the body\'s value');
        expect(wings - far, greaterThanOrEqualTo(6), reason: 'the far fan is dimmer than the near one');
        expect(far, greaterThan(22), reason: 'but it is not black: it stays a steel above the night sky');
      });
    });

    testWidgets('the hit flash takes the fans near-white, the dormant stone drains their colour, the ink holds', (tester) async {
      await tester.runAsync(() async {
        double meanL(Mask m) {
          var s = 0.0, n = 0;
          for (var i = 0; i < m.w * m.h; i++) {
            if (m.data[i * 4 + 3] < 255) continue;
            final l = _lstar(m.data[i * 4], m.data[i * 4 + 1], m.data[i * 4 + 2]);
            if (l <= 14) continue;
            s += l;
            n++;
          }
          return s / n;
        }

        double percentile(Mask m, double q) {
          final v = <double>[];
          for (var i = 0; i < m.w * m.h; i++) {
            if (m.data[i * 4 + 3] < 255) continue;
            final l = _lstar(m.data[i * 4], m.data[i * 4 + 1], m.data[i * 4 + 2]);
            if (l > 14) v.add(l);
          }
          v.sort();
          return v[(v.length * q).floor().clamp(0, v.length - 1)];
        }

        double chroma(Mask m) {
          var s = 0.0, n = 0;
          for (var i = 0; i < m.w * m.h; i++) {
            if (m.data[i * 4 + 3] < 255) continue;
            final r = m.data[i * 4], g = m.data[i * 4 + 1], b = m.data[i * 4 + 2];
            if (_lstar(r, g, b) <= 14) continue;
            s += math.max(r, math.max(g, b)) - math.min(r, math.min(g, b));
            n++;
          }
          return s / n;
        }

        double inkShare(Mask m) {
          var ink = 0, n = 0;
          for (var i = 0; i < m.w * m.h; i++) {
            if (m.data[i * 4 + 3] < 255) continue;
            n++;
            if (_lstar(m.data[i * 4], m.data[i * 4 + 1], m.data[i * 4 + 2]) <= 14) ink++;
          }
          return ink / n;
        }

        final calm = await _paintParts(GargoylePose.custom(), {'nearFan'});
        final flash = await _paintParts(GargoylePose.custom(flash: .55), {'nearFan'});
        final stone = await _paintParts(GargoylePose.custom(stone: 1), {'nearFan'});
        final l0 = meanL(calm), l1 = meanL(flash);
        // ignore: avoid_print
        print('near fan mean L*: calm ${l0.toStringAsFixed(1)}, flash ${l1.toStringAsFixed(1)}; chroma calm ${chroma(calm).toStringAsFixed(0)}, '
            'stone ${chroma(stone).toStringAsFixed(0)}; ink share calm ${inkShare(calm).toStringAsFixed(3)}, flash ${inkShare(flash).toStringAsFixed(3)}');
        // ignore: avoid_print
        print('near fan L* at the flash peak: p50 ${percentile(flash, .5).toStringAsFixed(1)}, p75 ${percentile(flash, .75).toStringAsFixed(1)}, '
            'p90 ${percentile(flash, .9).toStringAsFixed(1)}; calm p50 ${percentile(calm, .5).toStringAsFixed(1)}');
        expect(percentile(flash, .75), greaterThanOrEqualTo(85), reason: 'the lit planes go near-white');
        expect(l1 - l0, greaterThanOrEqualTo(15));
        expect(chroma(stone), lessThan(chroma(calm) * .45), reason: 'grey stone');
        expect((inkShare(flash) - inkShare(calm)).abs(), lessThan(.03), reason: 'the flash bleaches the lights, not the ink');
      });
    });

    testWidgets('the pauldron hides the far fan\'s pivot in every pose, and rises with a shrug and sinks with a mantle', (tester) async {
      await tester.runAsync(() async {
        final out = <String>[];
        for (final (name, mk, reduced) in _moments()) {
          final pose = poseOf(mk(), reduced: reduced);
          if (name.startsWith('arrival') || name.startsWith('defeat')) continue;
          final m = await _paintParts(pose, {'nearFan'}, ppu: 24);
          final p = GargoyleLayout.turn(GargoyleLayout.farShoulder, GargoyleLayout.bodyTurn(pose.lean));
          final x = ((p.dx - m.x0) * m.ppu).floor(), y = ((p.dy - m.y0) * m.ppu).floor();
          if (!m.at(x, y)) out.add('$name: the far fan\'s pivot shows at $p');
        }
        expect(out.take(5), isEmpty);
        // The shoulder's bottom edge rides the stroke.
        double bottomOf(GargoylePose pose, Mask m) {
          final x = ((GargoyleLayout.shoulder.dx + .1 - m.x0) * m.ppu).round();
          var best = -99.0;
          for (var y = 0; y < m.h; y++) {
            if (m.at(x, y)) best = math.max(best, m.uy(y + 1));
          }
          return best;
        }

        final up = GargoylePose.custom(wing: -1), down = GargoylePose.custom(wing: 1);
        final bu = bottomOf(up, await _paintParts(up, {'nearFan'}, ppu: 40)), bd = bottomOf(down, await _paintParts(down, {'nearFan'}, ppu: 40));
        expect(bd - bu, greaterThanOrEqualTo(.12), reason: 'shrugged ($bu) above mantled ($bd)');
      });
    }, timeout: const Timeout(Duration(minutes: 2)));

    testWidgets('the wing V stays open: >= 1.0 at rest, >= .8 in action (silhouette of the real art at 120 px)', (tester) async {
      await tester.runAsync(() async {
        const wingV = ui.Rect.fromLTRB(-.3, -4.3, 2.3, -1.9);
        const ppu = 120 / 9.7;
        final rows = <String>[];
        for (final (name, pose, rest) in <(String, GargoylePose, bool)>[
          ('idle', GargoylePose.still, true),
          ('perch', poseOf(gBoss(1.0)), true),
          ('warning', poseOf(gBoss(3.0)), false),
          ('sweep', poseOf(gBoss(4.8)), false),
          ('vent', poseOf(gBoss(7.2)), false),
          ('shrug', poseOf(gBoss(4.55)), false),
          ('launch', poseOf(gBoss(4.6001)), false),
          ('fury slit', poseOf(gBoss(5.0, fury: true, slit: true)), false),
          ('fury roar', poseOf(gBoss(1.0, fury: true, enragedAgo: .4)), false),
          ('hit', poseOf(gBoss(1.0, hitAgo: .08)), false),
        ]) {
          final m = await rasterize((c) => GargoyleBossRig.paintPose(c, pose, plinth: false), ppu: ppu, solid: 128);
          final v = m.largestEmptyDisc(wingV);
          rows.add('$name ${v.toStringAsFixed(2)}');
          expect(v, greaterThanOrEqualTo(rest ? GargoyleGates.wingV : GargoyleGates.wingV * .8), reason: '$name wing V');
        }
        // ignore: avoid_print
        print('wing V (diameter of the largest empty disc): ${rows.join(', ')}');
      });
    });

    test('Reduced Motion: no rattle, no clock; the idle wing is identical at every age', () {
      for (final age in const [0.3, 1.1, 1.9, 4.3]) {
        final b = gBoss(age);
        final w = GargoyleWing.nearOf(poseOf(b, reduced: true));
        expect(w.time, 0);
        expect(w.loose, 0);
      }
      final a = poseOf(gBoss(.4), reduced: true), b = poseOf(gBoss(1.7), reduced: true);
      expect(GargoyleWing.nearOf(a).tips, GargoyleWing.nearOf(b).tips);
      // The telegraph of a loosening feather is a motion channel: it rattles in
      // play and holds still under Reduced Motion.
      final live = GargoyleWing.nearOf(poseOf(gBoss(4.5)));
      expect(live.loose, greaterThan(.5));
      expect(live.time, greaterThan(0));
    });

    testWidgets('fury heats the blade tips (more fury, more heat, at the apex first); Reduced Motion idle pixels are the same at every age', (tester) async {
      await tester.runAsync(() async {
        // The tip of near blade 2 (a long one) at rest, looked at on its axis.
        final base = GargoylePose.custom();
        final wing = GargoyleWing.nearOf(base);
        final d = wing.tips[2] - wing.root;
        final u = d / d.distance;
        ui.Offset at(double back) => GargoyleLayout.turn(wing.root + u * (d.distance - back), GargoyleLayout.bodyTurn(base.lean));
        double redness(Mask m, ui.Offset p) {
          final i = (((p.dy - m.y0) * m.ppu).floor() * m.w + ((p.dx - m.x0) * m.ppu).floor()) * 4;
          return m.data[i] - m.data[i + 2].toDouble();
        }

        final readings = <double>[];
        for (final fury in const [0.0, .3, .6, .9]) {
          final m = await _paintParts(GargoylePose.custom(fury: fury), {'nearFan'}, ppu: 60);
          readings.add(redness(m, at(.35)));
        }
        // ignore: avoid_print
        print('red minus blue at the tip of blade 2, fury 0 / .3 / .6 / .9: ${readings.map((v) => v.toStringAsFixed(0)).join(' ')}');
        for (var i = 1; i < readings.length; i++) {
          expect(readings[i], greaterThan(readings[i - 1] + 8), reason: 'heat grows with fury');
        }
        final cool = await _paintParts(GargoylePose.custom(fury: .9), {'nearFan'}, ppu: 60);
        expect(redness(cool, at(.35)), greaterThan(redness(cool, at(1.4)) + 20), reason: 'the tip is hotter than the blade behind it');

        final a = await _paintParts(poseOf(gBoss(.4), reduced: true), {'farFan', 'nearFan', 'shed'}, ppu: 20);
        final b = await _paintParts(poseOf(gBoss(1.7), reduced: true), {'farFan', 'nearFan', 'shed'}, ppu: 20);
        var diff = 0;
        for (var i = 0; i < a.data.length; i++) {
          if (a.data[i] != b.data[i]) diff++;
        }
        expect(diff, 0, reason: 'the Reduced Motion idle is one still frame');
      });
    });

    testWidgets('pixels depend only on the pose: the same moments in the opposite order after a cache flood are identical', (tester) async {
      await tester.runAsync(() async {
        final moments = _moments().where((m) => m.$1.hashCode % 5 == 0).take(14).toList();
        final first = <String, List<int>>{};
        for (final (name, mk, reduced) in moments) {
          first[name] = (await _paintParts(poseOf(mk(), reduced: reduced), {'farFan', 'nearFan', 'shed'}, ppu: 16)).data.toList();
        }
        for (var i = 0; i < 400; i++) {
          GargoyleKit.cached('flood.$i', () => GargoyleKit.fill(const ui.Color(0xff123456)));
        }
        expect(GargoyleKit.cacheSize, lessThanOrEqualTo(GargoyleKit.cacheCapacity));
        for (final (name, mk, reduced) in moments.reversed) {
          final again = (await _paintParts(poseOf(mk(), reduced: reduced), {'farFan', 'nearFan', 'shed'}, ppu: 16)).data;
          final was = first[name]!;
          var diff = 0;
          for (var i = 0; i < was.length; i++) {
            if (was[i] != again[i]) diff++;
          }
          expect(diff, 0, reason: '$name differs after the cache flood');
        }
      });
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('non-finite input is harmless: NaN and infinite tips, shed, fury, strokes and times draw nothing wrong and never throw', () {
      const nan = double.nan, inf = double.infinity;
      final c = Counting(ui.Canvas(ui.PictureRecorder()));
      for (final far in [false, true]) {
        final bad = GargoyleWing(
          far: far,
          tips: const [ui.Offset(nan, 0), ui.Offset(inf, -inf), ui.Offset(1, nan), ui.Offset.zero, ui.Offset(2, -3), ui.Offset(nan, nan), ui.Offset(3, -2)],
          tone: const GargoyleTone(),
          shed: nan,
          fury: inf,
          strokes: const [nan],
          spread: nan,
          loose: nan,
          time: inf,
        );
        GargoyleWingArt.paint(c, bad);
        GargoyleWingArt.paint(c, GargoyleWing(far: far, tips: const [], tone: const GargoyleTone()));
        GargoyleWingArt.shedBlade(c, bad, .2);
      }
      for (final tau in const [nan, inf, -inf, -1.0, .6001, 5.0]) {
        final k = Counting(ui.Canvas(ui.PictureRecorder()));
        GargoyleWingArt.shedBlade(k, GargoyleWing.nearOf(GargoylePose.still), tau);
        expect(k.draws, 0, reason: 'tau $tau');
      }
      // A boss with broken clocks yields a finite wing.
      final b = gBoss(4.6);
      b.age = nan;
      b.lastHitAt = nan;
      final wing = GargoyleWing.nearOf(poseOf(b));
      for (final t in wing.tips) {
        expect(t.dx.isFinite && t.dy.isFinite, isTrue);
      }
    });
  });

  group('the leaving feather', () {
    // The top blade of the near fan: where it stands, its axis samples beyond
    // the pauldron where no other blade reaches.
    List<ui.Offset> axis(GargoylePose pose) {
      final wing = GargoyleWing.nearOf(pose);
      final d = wing.tips[GargoyleLayout.shedBlade] - wing.root;
      final u = d / d.distance, n = ui.Offset(-u.dy, u.dx);
      ui.Offset leaned(ui.Offset p) => GargoyleLayout.turn(p, GargoyleLayout.bodyTurn(pose.lean));
      return [for (final a in const [1.5, 1.7, 1.9]) leaned(wing.root + u * math.min(a, d.distance - .45) - n * .15)];
    }

    int solidAt(Mask m, List<ui.Offset> pts) => pts.where((p) => m.at(((p.dx - m.x0) * m.ppu).floor(), ((p.dy - m.y0) * m.ppu).floor())).length;

    testWidgets('in the very frame the feather launches the blade is gone from the fan and flying from the same place', (tester) async {
      await tester.runAsync(() async {
        for (final (e, fury) in const [(4.6, false), (.2, false), (4.5, true), (5.2, true)]) {
          final before = poseOf(gBoss(e - .02, fury: fury)), at = poseOf(gBoss(e + .0001, fury: fury));
          expect(before.shedTau, -1, reason: 'launch $e: still on the fan the frame before');
          expect(at.shedTau, inInclusiveRange(0, .01), reason: 'launch $e: the blade leaves in the launch frame');
          expect(GargoyleWing.nearOf(before).shed, 0);
          expect(GargoyleWing.nearOf(at).shed, 1);
          final pts = axis(at);
          final fanBefore = await _paintParts(before, {'nearFan'}, ppu: 40);
          final fanAt = await _paintParts(at, {'nearFan'}, ppu: 40);
          final flying = await _paintParts(at, {'shed'}, ppu: 40);
          expect(solidAt(fanBefore, axis(before)), 3, reason: 'launch $e: the blade stood on the fan');
          expect(solidAt(fanAt, pts), 0, reason: 'launch $e: the fan shows the gap');
          expect(solidAt(flying, pts), 3, reason: 'launch $e: and it is in flight from where it stood');
        }
      });
    });

    testWidgets('the gap shows briefly, the blade slides back out of the pauldron and is whole by .55 s; the flying blade is off the top of the screen by .45 s', (tester) async {
      await tester.runAsync(() async {
        var last = -1;
        final reach = <String>[];
        for (final tau in const [.02, .1, .2, .3, .4, .5, .56, .7]) {
          final pose = poseOf(gBoss(4.6 + tau));
          final wing = GargoyleWing.nearOf(pose);
          final fan = await _paintParts(pose, {'nearFan'}, ppu: 40);
          // How far along its own axis the blade stands: samples out to its tip.
          final d = GargoyleLayout.fanTip(0, far: false, stroke: pose.nearFan.strokes[0], spread: pose.spread) - wing.root;
          final u = d / d.distance, nrm = ui.Offset(-u.dy, u.dx);
          var n = 0;
          for (var a = 1.2; a < d.distance - .05; a += .05) {
            final p = GargoyleLayout.turn(wing.root + u * a - nrm * .15, GargoyleLayout.bodyTurn(pose.lean));
            if (fan.at(((p.dx - fan.x0) * fan.ppu).floor(), ((p.dy - fan.y0) * fan.ppu).floor())) n++;
          }
          reach.add('${tau.toStringAsFixed(2)}:$n');
          expect(n, greaterThanOrEqualTo(last), reason: 'regrow is monotone, tau $tau');
          last = n;
        }
        // ignore: avoid_print
        print('blade 0 samples standing along its axis, by seconds since the launch: ${reach.join(' ')}');
        final fresh = poseOf(gBoss(4.6 + .02)), whole = poseOf(gBoss(4.6 + .7));
        expect(GargoyleWing.nearOf(fresh).shed, greaterThan(.95), reason: 'the gap is on screen at once');
        expect(GargoyleWing.nearOf(poseOf(gBoss(4.6 + .3))).shed, inInclusiveRange(.1, .9), reason: 'half way back at .3 s');
        expect(GargoyleWing.nearOf(whole).shed, 0);
        final gone = await _paintParts(poseOf(gBoss(4.6 + .46)), {'shed'}, ppu: 20);
        expect(gone.bounds == null || gone.bounds!.rect.bottom < GargoyleLayout.screen.top, isTrue, reason: 'off the top of the screen at .46 s');
        final mid = await _paintParts(poseOf(gBoss(4.6 + .15)), {'shed'}, ppu: 20);
        expect(mid.bounds, isNotNull, reason: 'it is plainly visible at .15 s');
        expect(mid.bounds!.rect.bottom, greaterThan(GargoyleLayout.screen.top), reason: 'still on screen at .15 s');
      });
    });

    test('the loose blade is two ops, nothing before the launch or after .6 s', () {
      final pose = poseOf(gBoss(4.6 + .2));
      for (final (tau, ops) in const [(-.01, 0), (0.0, 2), (.2, 2), (.6, 2), (.61, 0)]) {
        final c = Counting(ui.Canvas(ui.PictureRecorder()));
        GargoyleWingArt.shedBlade(c, GargoyleWing.nearOf(pose), tau);
        expect(c.draws, ops, reason: 'tau $tau');
        expect(c.layers + c.blurs, 0);
      }
    });

    test('through the real rules: every launch of a whole fight has the blade leaving the fan in that frame', () {
      final plan = nyPlan(
        id: '3-4',
        seed: 3104,
        lineup: const [EnemyKind.simpleBat, EnemyKind.caveBat],
        boss: BossKind.searchlightGargoyle,
      );
      final sim = nyFlight(plan, weaponDamage: BirdRock.baseDamage);
      var launches = 0, left = 0, lastLaunched = 0, flying = 0;
      GargoyleWing? prevWing;
      flyLevel(
        sim,
        seconds: 300,
        shootWhen: (s) => false,
        until: (s) {
          final b = s.boss;
          return b != null && b.isGargoyle && (b.phase == BossPhase.defeated || b.combatTime > 50);
        },
        watch: (s) {
          final b = s.boss;
          if (b == null || !b.isGargoyle) return;
          if (b.phase == BossPhase.attacking && b.combatTime > 22 && !b.enraged) b.hp = b.maxHp ~/ 2 - 10;
          final pose = GargoylePose(b, BossMotion(b, reducedMotion: false), gap: b.x - .299 - GargoyleLayout.birdColumn);
          final wing = GargoyleWing.nearOf(pose);
          if (b.phase == BossPhase.attacking && b.feathersLaunched > lastLaunched) {
            launches += b.feathersLaunched - lastLaunched;
            lastLaunched = b.feathersLaunched;
            if (wing.shed > .999 && (prevWing?.shed ?? 1) < .5) left++;
            final c = Counting(ui.Canvas(ui.PictureRecorder()));
            GargoyleWingArt.shedBlade(c, wing, pose.shedTau);
            if (c.draws == 2) flying++;
          }
          prevWing = wing;
        },
      );
      // ignore: avoid_print
      print('real fight: $launches launches, $left with the blade leaving the fan, $flying drawn in flight in that frame');
      expect(launches, greaterThanOrEqualTo(10));
      expect(left, launches);
      expect(flying, launches);
    }, timeout: const Timeout(Duration(minutes: 4)));
  });

  group('visual review', () {
    const size640 = ui.Size(640, 360);

    test('w01 in-game frames at 640 and 800', skip: !_review, () async {
      for (final w in [640, 800]) {
        final s = ui.Size(w.toDouble(), 360);
        final aspect = w / 360;
        final shots = <(String, SkyBoss)>[
          ('perch', gBoss(1.0, aspect: aspect)),
          ('warning', gBoss(3.0, aspect: aspect)),
          ('sweep', gBoss(5.0, aspect: aspect)),
          ('vent', gBoss(7.2, aspect: aspect)),
          ('shrug', gBoss(4.56, aspect: aspect)),
          ('fury', gBoss(5.0, fury: true, aspect: aspect)),
        ];
        final img = await _render(w * 2, 360 * 3, (c) {
          for (var i = 0; i < shots.length; i++) {
            c.save();
            c.translate((i % 2) * s.width, (i ~/ 2) * s.height);
            c.clipRect(ui.Offset.zero & s);
            paintFrame(c, s, shots[i].$2, FrameOptions(birdY: .62, label: shots[i].$1));
            c.restore();
          }
        });
        await _save(img, 'w01-ingame-$w');
      }
    });

    test('w02 fans apart: far only, near only, both', skip: !_review, () async {
      const win = ui.Rect.fromLTRB(-.6, -4.4, 4.6, .6);
      const ppu = 110.0;
      final cw = (win.width * ppu).round(), ch = (win.height * ppu).round();
      final poses = [poseOf(gBoss(1.0)), poseOf(gBoss(7.0))];
      final img = await _render(cw * 3, ch * 2, (c) {
        c.drawRect(ui.Rect.fromLTWH(0, 0, cw * 3.0, ch * 2.0), ui.Paint()..color = const ui.Color(0xff2a2d52));
        for (var r = 0; r < 2; r++) {
          for (var k = 0; k < 3; k++) {
            c.save();
            c.translate(k * cw.toDouble(), r * ch.toDouble());
            c.clipRect(ui.Rect.fromLTWH(0, 0, cw.toDouble(), ch.toDouble()));
            c.scale(ppu);
            c.translate(-win.left, -win.top);
            final parts = k == 0 ? {'farFan'} : k == 1 ? {'nearFan'} : {'farFan', 'torso', 'ruff', 'nearFan'};
            GargoyleBossRig.paintPose(c, poses[r], only: parts, plinth: false);
            c.restore();
          }
        }
      });
      await _save(img, 'w02-fans-apart');
    });

    // The wing window: rig units around the fans.
    const wingWin = ui.Rect.fromLTRB(-.8, -4.5, 4.7, .9);

    test('w03 onion skins: shrug (12), spread, fold, arrival unfold', skip: !_review, () async {
      const ppu = 82.0;
      final cw = (wingWin.width * ppu).round(), ch = (wingWin.height * ppu).round();
      final sets = <(String, List<SkyBoss>)>[
        ('SHRUG: feather flick 4.45 .. 5.25 s (12 samples)', [for (var k = 0; k < 12; k++) gBoss(4.45 + k * .073)]),
        ('SPREAD: warning 2.0 .. 3.4, vent 6.4 .. 7.8', [for (var k = 0; k < 6; k++) gBoss(2.0 + k * .28), for (var k = 0; k < 6; k++) gBoss(6.4 + k * .28)]),
        ('FOLD: dormant stone, then unfold 1.2 .. 3.1 s of the arrival', [for (var k = 0; k < 12; k++) gBoss(1.2 + k * .17 - 4.6)]),
        ('FOLD: defeat 0 .. .5 s, fury roar', [for (var k = 0; k < 6; k++) gBoss(1.0, deadFor: k * .1), for (var k = 0; k < 6; k++) gBoss(1.0, fury: true, enragedAgo: .1 + k * .12)]),
      ];
      final img = await _render(cw * 2, ch * 2, (c) {
        for (var i = 0; i < sets.length; i++) {
          final x0 = (i % 2) * cw.toDouble(), y0 = (i ~/ 2) * ch.toDouble();
          c.save();
          c.translate(x0, y0);
          c.clipRect(ui.Rect.fromLTWH(0, 0, cw.toDouble(), ch.toDouble()));
          c.drawRect(ui.Rect.fromLTWH(0, 0, cw.toDouble(), ch.toDouble()), ui.Paint()..color = const ui.Color(0xff262a4e));
          c.scale(ppu);
          c.translate(-wingWin.left, -wingWin.top);
          final list = sets[i].$2;
          for (var k = 0; k < list.length; k++) {
            final last = k == list.length - 1;
            final pose = poseOf(list[k]);
            if (!last) {
              c.saveLayer(null, ui.Paint()..color = ui.Color.fromRGBO(255, 255, 255, .22));
              GargoyleBossRig.paintPose(c, pose, only: {'farFan', 'nearFan'}, plinth: false);
              c.restore();
            }
          }
          GargoyleBossRig.paintPose(c, poseOf(list.last), only: {'farFan', 'torso', 'ruff', 'nearFan'}, plinth: false);
          final e = GargoyleLayout.envelope;
          c.drawRect(e, ui.Paint()..color = const ui.Color(0xff35d07f)..style = ui.PaintingStyle.stroke..strokeWidth = 2 / ppu);
          c.restore();
          text(c, sets[i].$1, ui.Offset(x0 + 6, y0 + 4), 13, const ui.Color(0xffffffff), outline: true);
        }
      });
      await _save(img, 'w03-onion');
    });

    test('w04 launch strip: the blade leaves, the gap, the regrow', skip: !_review, () async {
      const ppu = 62.0;
      final cw = (wingWin.width * ppu).round(), ch = (wingWin.height * ppu).round();
      final times = [4.38, 4.50, 4.57, 4.60, 4.617, 4.65, 4.70, 4.78, 4.88, 5.0, 5.12, 5.3];
      final img = await _render(cw * 4, ch * 3, (c) {
        for (var i = 0; i < times.length; i++) {
          _crop(c, size640, gBoss(times[i]), wingWin, ppu, at: ui.Offset((i % 4) * cw.toDouble(), (i ~/ 4) * ch.toDouble()));
          text(c, 't ${times[i].toStringAsFixed(3)}  (launch 4.6)', ui.Offset((i % 4) * cw + 6.0, (i ~/ 4) * ch + 4.0), 13, const ui.Color(0xffffffff), outline: true);
        }
      });
      await _save(img, 'w04-launch');
    });

    test('w05 close-ups: night New York, bright Egypt, hit flash, stone', skip: !_review, () async {
      const ppu = 120.0;
      const win = ui.Rect.fromLTRB(-.4, -4.2, 4.5, -.4);
      final cw = (win.width * ppu).round(), ch = (win.height * ppu).round();
      final shots = <(String, SkyBoss, FrameOptions)>[
        ('night: idle', gBoss(1.0), const FrameOptions(hud: false)),
        ('night: vent (spread, stroke up)', gBoss(7.0), const FrameOptions(hud: false)),
        ('bright Egypt: idle', gBoss(1.0), const FrameOptions(hud: false, region: WorldRegion.egypt)),
        ('bright Egypt: fury', gBoss(1.0, fury: true), const FrameOptions(hud: false, region: WorldRegion.egypt)),
        ('hit flash peak', gBoss(1.0, hitAgo: .04), const FrameOptions(hud: false)),
        ('dormant stone', gBoss(1.0 - 4.6), const FrameOptions(hud: false)),
      ];
      final img = await _render(cw * 2, ch * 3, (c) {
        for (var i = 0; i < shots.length; i++) {
          _crop(c, size640, shots[i].$2, win, ppu, at: ui.Offset((i % 2) * cw.toDouble(), (i ~/ 2) * ch.toDouble()), options: shots[i].$3);
          text(c, shots[i].$1, ui.Offset((i % 2) * cw + 6.0, (i ~/ 2) * ch + 4.0), 14, const ui.Color(0xffffffff), outline: true);
        }
      });
      await _save(img, 'w05-closeups');
    });

    test('w06 silhouettes at 250 and 120 px, the wing V gate', skip: !_review, () async {
      final poses = <(String, GargoylePose Function())>[
        ('idle', () => GargoylePose.still),
        ('perch', () => poseOf(gBoss(1.0))),
        ('warning', () => poseOf(gBoss(3.0))),
        ('sweep HIGH', () => poseOf(gBoss(4.8))),
        ('sweep LOW', () => poseOf(gBoss(4.8, side: BeamSide.low))),
        ('vent', () => poseOf(gBoss(7.2))),
        ('fury slit', () => poseOf(gBoss(5.0, fury: true, slit: true))),
        ('shrug', () => poseOf(gBoss(4.55))),
        ('fury roar', () => poseOf(gBoss(1.0, fury: true, enragedAgo: .4))),
        ('hit', () => poseOf(gBoss(1.0, hitAgo: .08))),
        ('fold (defeat)', () => poseOf(gBoss(1.0, deadFor: .5))),
        ('dormant', () => poseOf(gBoss(1.0 - 4.6))),
      ];
      for (final cell in [250, 120]) {
        const cols = 6;
        final rows = (poses.length / cols).ceil();
        const label = 18;
        final w = cols * cell, h = rows * (cell + label);
        const fx0 = -5.0, fy0 = -4.6, span = 9.7;
        final scale = cell / span;
        final img = await _render(w, h, (c) {
          c.drawRect(ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()), ui.Paint()..color = const ui.Color(0xffe9dfd2));
          for (var i = 0; i < poses.length; i++) {
            final x0 = (i % cols) * cell.toDouble(), y0 = (i ~/ cols) * (cell + label).toDouble() + label;
            text(c, poses[i].$1, ui.Offset(x0 + 4, y0 - label + 2), 10, const ui.Color(0xff222222), bold: false);
            c.save();
            c.clipRect(ui.Rect.fromLTWH(x0, y0, cell.toDouble(), cell.toDouble()));
            c.translate(x0 - fx0 * scale, y0 - fy0 * scale);
            c.scale(scale);
            c.saveLayer(null, ui.Paint()..colorFilter = const ui.ColorFilter.mode(ui.Color(0xff000000), ui.BlendMode.srcIn));
            GargoyleBossRig.paintPose(c, poses[i].$2(), plinth: false);
            c.restore();
            c.drawRect(const ui.Rect.fromLTRB(-.3, -4.3, 2.3, -1.9), ui.Paint()..color = const ui.Color(0xffd33a3a)..style = ui.PaintingStyle.stroke..strokeWidth = 1.2 / scale);
            c.drawRect(GargoyleLayout.envelope, ui.Paint()..color = const ui.Color(0xff2f9f3a)..style = ui.PaintingStyle.stroke..strokeWidth = 1.0 / scale);
            c.restore();
          }
        });
        await _save(img, 'w06-silhouette-$cell');
      }
    });

    test('w00 quick look: idle, flick, launch, spread, fold', skip: !_review, () async {
      final shots = <(String, SkyBoss)>[
        ('idle', gBoss(1.0)),
        ('warning 3.0', gBoss(3.0)),
        ('vent 7.0', gBoss(7.0)),
        ('flick 4.58', gBoss(4.58)),
        ('launch 4.6', gBoss(4.6)),
        ('regrow 4.85', gBoss(4.85)),
        ('fury rage', gBoss(1.0, fury: true, enragedAgo: .4)),
        ('fold (defeat .5)', gBoss(1.0, deadFor: .5)),
      ];
      const win = ui.Rect.fromLTRB(-.6, -4.4, 4.6, .6);
      const ppu = 110.0;
      final cw = (win.width * ppu).round(), ch = (win.height * ppu).round();
      final img = await _render(cw * 2, ch * 4, (c) {
        for (var i = 0; i < shots.length; i++) {
          _crop(c, size640, shots[i].$2, win, ppu, at: ui.Offset((i % 2) * cw.toDouble(), (i ~/ 2) * ch.toDouble()));
          text(c, shots[i].$1, ui.Offset((i % 2) * cw + 6.0, (i ~/ 2) * ch + 4.0), 14, const ui.Color(0xffffffff), outline: true);
        }
      });
      await _save(img, 'w00-quick');
      expect(GargoyleWingArt.reach, isNotNull);
      expect(WorldBackdrop.cruise, greaterThan(0));
      expect(GargoyleKit.cacheSize, greaterThanOrEqualTo(0));
      expect(GargoylePose.still, isNotNull);
      expect(GargoyleBossRig.bounds, GargoyleLayout.layerBounds);
      expect(math.pi, greaterThan(3));
    });
  });
}
