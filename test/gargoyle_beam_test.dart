import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart' show HSVColor;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/bird_puppet.dart';
import 'package:push_up_bird/game/regions/world_backdrop.dart';
import 'package:push_up_bird/game/sky_scenery.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/gargoyle_beam_art.dart';
import 'package:push_up_bird/game/gargoyle_boss_rig.dart';
import 'package:push_up_bird/game/gargoyle_kit.dart';
import 'package:push_up_bird/game/gargoyle_layout.dart';
import 'package:push_up_bird/game/gargoyle_pose.dart';

import 'gargoyle_pilot.dart' as pilot;
import 'proof/counting_canvas.dart';
import 'proof/gargoyle_stage.dart';

/// The Searchlight Gargoyle's beams (G5): the drawn lit band at the bird's
/// column IS the rules' hurting band, in pixels, both ways, calm / fury /
/// slit / Reduced Motion at 640 and 800 (the Ember Dragon's fire-edge test is
/// the model: light beside the bird means hurt, clear air means safe); the
/// warning's boundary is the rays the beam will come to rest on; the boss beam
/// cannot be mistaken for New York's searchlights; the SPOTTED! moment; every
/// piece stays in budget, has a Reduced Motion frame and never throws.
///
/// `GARGOYLE_REVIEW=true` also writes the review sheets (see the end).
typedef _Img = ({Uint8List px, int w, int h});

Future<_Img> _render(ui.Size size, void Function(ui.Canvas) draw) async {
  final rec = ui.PictureRecorder();
  draw(ui.Canvas(rec));
  final pic = rec.endRecording();
  final img = await pic.toImage(size.width.round(), size.height.round());
  final px = (await img.toByteData())!.buffer.asUint8List();
  img.dispose();
  pic.dispose();
  return (px: px, w: size.width.round(), h: size.height.round());
}

int _alpha(_Img i, int x, int y) => i.px[(y * i.w + x) * 4 + 3];

/// The first and last rows at pixel column [x] whose alpha is at least [min].
(int, int)? _extent(_Img i, int x, int min) {
  int? a, b;
  for (var y = 0; y < i.h; y++) {
    if (_alpha(i, x, y) >= min) {
      a ??= y;
      b = y;
    }
  }
  return a == null ? null : (a, b!);
}

ui.Offset _eye(GargoylePose p, ui.Size s, SkyBoss b, GargoyleBeam beam) {
  final o = GargoyleBossRig.beamOrigins(p);
  return bossCentre(s, b) + (beam.far ? o.far : o.near) * (s.height * SkyBoss.radius);
}

/// The look the calm, fury, slit and Reduced Motion fits are run for.
typedef _Case = (String, SkyBoss Function(double t, double aspect) make, bool reduced);

final _cases = <_Case>[
  ('calm HIGH', (t, a) => gBoss(t, aspect: a), false),
  ('calm LOW', (t, a) => gBoss(t, side: BeamSide.low, aspect: a), false),
  ('fury HIGH', (t, a) => gBoss(t, fury: true, aspect: a), false),
  ('fury LOW', (t, a) => gBoss(t, fury: true, side: BeamSide.low, aspect: a), false),
  ('slit', (t, a) => gBoss(t, fury: true, slit: true, aspect: a), false),
  ('RM calm HIGH', (t, a) => gBoss(t, aspect: a), true),
  ('RM calm LOW', (t, a) => gBoss(t, side: BeamSide.low, aspect: a), true),
  ('RM slit', (t, a) => gBoss(t, fury: true, slit: true, aspect: a), true),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Fredoka')..addFont(rootBundle.load('assets/fonts/Fredoka.ttf'))).load();
    await (FontLoader('Nunito')..addFont(rootBundle.load('assets/fonts/Nunito.ttf'))).load();
  });

  // ------------------------------------------------------------ the band --

  group('the lit band is the rules\' hurting band', () {
    testWidgets('at the bird\'s column: stops short by at most 3 px, never beyond the band (calm, fury, slit, Reduced Motion; 640 and 800)', (tester) async {
      // Fairness, both ways. Light beside the bird means hurt: the solid light
      // (alpha >= .16) reaches to within 3 px of the rules' edge at the column.
      // Clear air means safe: no light at all (alpha >= 4%) more than 1 px
      // past the edge, every frame of the glide and the hold.
      const short = 3.0, beyondLit = 1.0, beyondAny = 1.5;
      var worstShort = 0.0, worstBeyond = 0.0, frames = 0;
      await tester.runAsync(() async {
        for (final width in const [640.0, 800.0]) {
          final size = ui.Size(width, 360);
          final col = (GargoyleLayout.birdColumn * 360).floor();
          for (final (name, make, reduced) in _cases) {
            for (var t = 3.52; t < 6.4; t += .12) {
              final boss = make(t, width / 360);
              final pose = poseOf(boss, reduced: reduced);
              expect(pose.beams, isNotEmpty, reason: '$name t=$t');
              for (final b in pose.beams) {
                final img = await _render(size, (c) => GargoyleBeamArt.beam(c, size, b, _eye(pose, size, boss, b), time: pose.time));
                final eye = _eye(pose, size, boss, b);
                // The edges at this pixel column's centre (the rays lean).
                final cx = GargoyleLayout.birdColumn * 360, px = col + .5;
                final top = _rayY(eye, cx, (b.centre - b.half) * 360, px), bottom = _rayY(eye, cx, (b.centre + b.half) * 360, px);
                final lean = ((bottom - top) / 2 - b.half * 360).abs();
                final slope = ((_rayY(eye, cx, (b.centre + b.half) * 360, px + 1) - bottom)).abs();
                final lit = _extent(img, col, 40), any = _extent(img, col, 10);
                final why = '$name t=${t.toStringAsFixed(2)} at $width (beam ${b.centre.toStringAsFixed(3)}, lean $lean)';
                expect(lit, isNotNull, reason: why);
                final sh = math.max(lit!.$1 - top, bottom - (lit.$2 + 1));
                final be = math.max(top - any!.$1, (any.$2 + 1) - bottom);
                final bl = math.max(top - lit.$1, (lit.$2 + 1) - bottom);
                worstShort = math.max(worstShort, sh);
                worstBeyond = math.max(worstBeyond, be);
                // A pixel column is 1 px wide and the edge leans by `slope`
                // across it, so a leaning edge may show half a slope more.
                expect(sh, lessThanOrEqualTo(short + slope / 2), reason: 'light stops short by $sh px: $why');
                expect(bl, lessThanOrEqualTo(beyondLit + slope / 2), reason: 'solid light past the band by $bl px: $why');
                expect(be, lessThanOrEqualTo(beyondAny + slope / 2), reason: 'any light past the band by $be px: $why');
                frames++;
              }
            }
          }
        }
      });
      expect(frames, greaterThan(400));
      // ignore: avoid_print
      print('band fit at the column: light stops at most ${worstShort.toStringAsFixed(1)} px short and at most ${worstBeyond.toStringAsFixed(1)} px beyond the rules\' band ($frames beam frames)');
    });

    testWidgets('a bird\'s circle touching the drawn light is (within a hair) a bird the rules hurt, from above and below', (tester) async {
      // The circle against the slanted wedge: the light reaches the circle
      // first by r(sqrt(1 + slope^2) - 1) at most (the wedge leans, the rules'
      // slab does not), and never later than 3 px after the rules' touch.
      var worstLate = 0.0, worstEarly = 0.0, n = 0;
      await tester.runAsync(() async {
        for (final width in const [640.0, 800.0]) {
          final size = ui.Size(width, 360);
          final r = GargoyleLayout.birdRadius * 360, cx = GargoyleLayout.birdColumn * 360;
          for (final (name, make, reduced) in _cases.take(5)) {
            for (final t in const [3.52, 4.0, 5.0, 6.3]) {
              final boss = make(t, width / 360);
              final pose = poseOf(boss, reduced: reduced);
              for (final b in pose.beams) {
                final eye = _eye(pose, size, boss, b);
                final img = await _render(size, (c) => GargoyleBeamArt.beam(c, size, b, eye, time: pose.time));
                bool touches(double cy) {
                  for (var y = (cy - r).floor(); y <= (cy + r).ceil(); y++) {
                    for (var x = (cx - r).floor(); x <= (cx + r).ceil(); x++) {
                      if (y < 0 || y >= img.h) continue;
                      final dx = x + .5 - cx, dy = y + .5 - cy;
                      if (dx * dx + dy * dy <= r * r && _alpha(img, x, y) >= 40) return true;
                    }
                  }
                  return false;
                }

                for (final above in const [true, false]) {
                  final edgeY = (above ? b.centre - b.half : b.centre + b.half) * 360;
                  final slope = (edgeY - eye.dy) / (cx - eye.dx);
                  final slack = r * (math.sqrt(1 + slope * slope) - 1);
                  final rulesTouch = above ? edgeY - r : edgeY + r;
                  // Walk the bird's centre toward the band until the light touches it.
                  double? drawn;
                  for (var k = 60.0; k >= -40; k -= .5) {
                    final cy = above ? rulesTouch - k : rulesTouch + k;
                    if (cy < -r || cy > 360 + r) continue;
                    if (touches(cy)) {
                      drawn = k;
                      break;
                    }
                  }
                  // k is how far beyond the rules' touch the bird is when the
                  // light first touches it: positive = the light came first.
                  expect(drawn, isNotNull, reason: '$name t=$t above=$above at $width');
                  final why = '$name t=$t above=$above at $width: light touches the circle ${drawn!.toStringAsFixed(1)} px before the rules do (slack ${slack.toStringAsFixed(1)})';
                  expect(drawn, lessThanOrEqualTo(slack + 2.5), reason: why);
                  expect(drawn, greaterThanOrEqualTo(-3.0), reason: why);
                  worstEarly = math.max(worstEarly, drawn - slack);
                  worstLate = math.max(worstLate, -drawn);
                  n++;
                }
              }
            }
          }
        }
      });
      expect(n, greaterThan(90));
      // ignore: avoid_print
      print('circle against light: the light is at most ${worstLate.toStringAsFixed(1)} px late and at most ${worstEarly.toStringAsFixed(1)} px earlier than the wedge geometry allows ($n touches)');
    });

    testWidgets('the body is exactly the band at the column and the core half of it; nothing beyond', (tester) async {
      await tester.runAsync(() async {
        final size = const ui.Size(640, 360);
        final boss = gBoss(4.4);
        final pose = poseOf(boss);
        final b = pose.beams.single;
        final col = (GargoyleLayout.birdColumn * 360).floor();
        final widths = <int, int>{};
        for (final layers in const [GargoyleBeamArt.layerBody, GargoyleBeamArt.layerCore]) {
          final img = await _render(size, (c) => GargoyleBeamArt.beam(c, size, b, _eye(pose, size, boss, b), layers: layers));
          final e = _extent(img, col, 6)!;
          widths[layers] = e.$2 - e.$1 + 1;
        }
        final band = b.half * 2 * 360;
        expect(widths[GargoyleBeamArt.layerBody]!, closeTo(band, 1.6));
        expect(widths[GargoyleBeamArt.layerCore]!, closeTo(band * GargoyleBeamLook.coreGrow, 2.5));
        expect(GargoyleBeamLook.hazeGrow, greaterThan(1), reason: 'the kit still names a haze; this art draws none (nothing past the band)');
      });
    });

    testWidgets('the hairline edges lie inside the band: their outer side is the rules\' edge, and they run past the column by 12 px', (tester) async {
      await tester.runAsync(() async {
        final size = const ui.Size(640, 360);
        for (final (boss, n) in [(gBoss(4.4), 1), (gBoss(5.0, fury: true, slit: true), 2)]) {
          final pose = poseOf(boss);
          expect(pose.beams.length, n);
          for (final b in pose.beams) {
            final eye = _eye(pose, size, boss, b);
            final img = await _render(size, (c) => GargoyleBeamArt.beam(c, size, b, eye, layers: GargoyleBeamArt.layerEdges));
            final col = (GargoyleLayout.birdColumn * 360).floor();
            final e = _extent(img, col, 100)!;
            final top = (b.centre - b.half) * 360, bottom = (b.centre + b.half) * 360;
            expect(e.$1, greaterThanOrEqualTo(top.floor()), reason: 'the top hairline does not pass the band');
            expect(e.$2 + 1, lessThanOrEqualTo(bottom.ceil()), reason: 'the bottom hairline does not pass the band');
            expect(e.$1, closeTo(top, 2.5));
            expect(e.$2 + 1, closeTo(bottom, 2.5));
            // They end 12 px past the column: nothing at the far left.
            expect(_extent(img, 40, 6), isNull, reason: 'the hairlines stop past the column');
            // and they start at the lens and never run right of it
            expect(_extent(img, (eye.dx + 6).round(), 6), isNull);
          }
        }
      });
    });

    testWidgets('it passes through the lens: widest to the left, ends at the screen edge, nothing right of the lens', (tester) async {
      await tester.runAsync(() async {
        final size = const ui.Size(640, 360);
        final boss = gBoss(4.4);
        final pose = poseOf(boss);
        final b = pose.beams.single;
        final eye = _eye(pose, size, boss, b);
        final img = await _render(size, (c) => GargoyleBeamArt.beam(c, size, b, eye, layers: GargoyleBeamArt.layerBody));
        double width(int x) {
          final e = _extent(img, x, 6);
          return e == null ? 0 : (e.$2 - e.$1 + 1).toDouble();
        }

        expect(width((eye.dx - 10).round()), lessThan(width(200)));
        expect(width(200), lessThan(width(40)));
        expect(_extent(img, (eye.dx + 30).round(), 6), isNull);
        expect(width(2), greaterThan(0), reason: 'it reaches the left edge');
      });
    });
  });

  // ------------------------------------------------------------ the look --

  group('the look', () {
    testWidgets('not New York\'s searchlights: amber, saturated, brighter, hard-edged, over the same night sky', (tester) async {
      await tester.runAsync(() async {
        final size = const ui.Size(640, 360);
        const night = ui.Color(0xff2c3055);
        final col = (GargoyleLayout.birdColumn * 360).floor();
        for (final (name, boss) in [('calm', gBoss(4.4)), ('fury', gBoss(4.4, fury: true))]) {
          final pose = poseOf(boss);
          final b = pose.beams.single;
          final img = await _render(size, (c) {
            c.drawRect(ui.Offset.zero & size, ui.Paint()..color = night);
            GargoyleBeamArt.beam(c, size, b, _eye(pose, size, boss, b), layers: GargoyleBeamArt.layerBody | GargoyleBeamArt.layerCore);
          });
          HSVColor at(double frac) {
            final y = ((b.centre + frac * b.half) * 360).round();
            final i = (y * img.w + col) * 4;
            return HSVColor.fromColor(ui.Color.fromARGB(255, img.px[i], img.px[i + 1], img.px[i + 2]));
          }

          // the hot core (axis) and the amber body between core and edge
          final core = at(0), mine = at(.75);
          final cream = ui.Color.alphaBlend(GargoyleBeamLook.regionCream.withValues(alpha: .22), night);
          final region = HSVColor.fromColor(cream);
          // ignore: avoid_print
          print('boss beam ($name) over night at the column: body hue ${mine.hue.toStringAsFixed(0)} sat ${mine.saturation.toStringAsFixed(2)} val ${mine.value.toStringAsFixed(2)}, '
              'core sat ${core.saturation.toStringAsFixed(2)} val ${core.value.toStringAsFixed(2)}; '
              'region beam: hue ${region.hue.toStringAsFixed(0)} sat ${region.saturation.toStringAsFixed(2)} val ${region.value.toStringAsFixed(2)}');
          final dh = (mine.hue - region.hue).abs();
          expect(math.min(dh, 360 - dh), greaterThan(40), reason: '$name: a warm beam against a cool wash');
          expect(mine.value, greaterThanOrEqualTo(region.value - .02), reason: '$name: no dimmer than the region\'s beam, even in its body');
          expect(core.value, greaterThan(region.value + .25), reason: '$name: with a much brighter core');
          expect(mine.hue, inInclusiveRange(10, 60), reason: '$name: amber, not cream or white');
          expect(mine.saturation, greaterThan(name == 'calm' ? .30 : .22), reason: '$name: saturated (cream is .14 to .22)');
        }
      });
    });

    testWidgets('layers never exceed the maximum alpha; the composite at the lens axis stays under .65; the edges are at full from the ignition frame', (tester) async {
      await tester.runAsync(() async {
        final size = const ui.Size(640, 360);
        for (final (boss, what) in [(gBoss(3.5005), 'calm ignition'), (gBoss(5.0, fury: true, slit: true), 'fury slit')]) {
          final pose = poseOf(boss);
          for (final (name, layers) in const [('body', GargoyleBeamArt.layerBody), ('core', GargoyleBeamArt.layerCore)]) {
            final img = await _render(size, (c) {
              for (final b in pose.beams) {
                GargoyleBeamArt.beam(c, size, b, _eye(pose, size, boss, b), layers: layers);
              }
            });
            var maxA = 0;
            for (var i = 3; i < img.px.length; i += 4) {
              maxA = math.max(maxA, img.px[i]);
            }
            expect(maxA, lessThanOrEqualTo((GargoyleBeamLook.maxAlpha * 255).ceil() + 1), reason: '$what $name');
          }
        }
        // The whole beam (no edges, no motes) at its full strength hides at
        // most 40% of what is behind it: the body is the only layer that
        // covers (the core ADDS light), so black and white stripes behind the
        // axis (the worst case: pure black against pure white, at the brightest
        // point, near the lens) still differ by at least 38% of their own
        // difference.
        for (final (boss, what) in [(gBoss(4.6), 'calm'), (gBoss(4.6, fury: true), 'fury')]) {
          final pose = poseOf(boss);
          final b = pose.beams.single;
          final eye = _eye(pose, size, boss, b);
          final img = await _render(size, (c) {
            for (var x = 0; x < 640; x += 8) {
              c.drawRect(ui.Rect.fromLTWH(x.toDouble(), 0, 4, 360), ui.Paint()..color = const ui.Color(0xff000000));
              c.drawRect(ui.Rect.fromLTWH(x + 4.0, 0, 4, 360), ui.Paint()..color = const ui.Color(0xffffffff));
            }
            GargoyleBeamArt.beam(c, size, b, eye, layers: GargoyleBeamArt.layerBody | GargoyleBeamArt.layerCore);
          });
          final frame = GargoyleKit.beamFrame(eye: eye, columnX: GargoyleLayout.birdColumn * 360, centre: b.centre * 360, half: b.half * 360, reachX: -18)!;
          final axis = (ui.Offset(GargoyleLayout.birdColumn * 360, b.centre * 360) - eye) * frame.reach;
          // along the axis, from the lens out to the bird's column
          var worst = 1.0;
          for (final u in const [.2, .3, .4, 1 / 2.0]) {
            final p = eye + axis * u;
            final x0 = (p.dx / 8).floor() * 8, y = p.dy.round();
            int lum(int x) => img.px[(y * img.w + x) * 4] + img.px[(y * img.w + x) * 4 + 1] + img.px[(y * img.w + x) * 4 + 2];
            worst = math.min(worst, (lum(x0 + 5) - lum(x0 + 1)) / (3 * 255));
          }
          // ignore: avoid_print
          print('$what beam: black/white stripes behind the axis keep ${(worst * 100).toStringAsFixed(0)}% of their contrast');
          expect(worst, greaterThanOrEqualTo(.38), reason: '$what: what is behind the beam keeps at least 38% of its contrast, at the brightest point of the beam');
        }
        // The ignition frame: the body is faint, the hairlines full.
        final boss = gBoss(3.5005);
        final pose = poseOf(boss);
        final b = pose.beams.single;
        expect(b.intensity, closeTo(GargoyleBeamLook.igniteFloor, .01));
        final col = (GargoyleLayout.birdColumn * 360).floor();
        final edges = await _render(size, (c) => GargoyleBeamArt.beam(c, size, b, _eye(pose, size, boss, b), layers: GargoyleBeamArt.layerEdges));
        expect(_extent(edges, col, 150), isNotNull, reason: 'hairlines at full alpha at the ignition frame');
        final body = await _render(size, (c) => GargoyleBeamArt.beam(c, size, b, _eye(pose, size, boss, b), layers: GargoyleBeamArt.layerBody));
        var maxA = 0;
        for (var i = 3; i < body.px.length; i += 4) {
          maxA = math.max(maxA, body.px[i]);
        }
        expect(maxA, lessThan(.3 * 255), reason: 'the body is faint while it ramps in');
      });
    });

    testWidgets('dust and rain glints stay INSIDE the beam, at every clock, and they move', (tester) async {
      await tester.runAsync(() async {
        final size = const ui.Size(640, 360);
        for (final width in const [640.0, 800.0]) {
          final sz = ui.Size(width, 360);
          for (final (name, mk) in <(String, SkyBoss Function(double))>[
            ('HIGH', (t) => gBoss(t, aspect: width / 360)),
            ('LOW', (t) => gBoss(t, side: BeamSide.low, aspect: width / 360)),
            ('slit', (t) => gBoss(t, fury: true, slit: true, aspect: width / 360)),
          ]) {
            for (final t in const [3.6, 4.3, 5.0, 5.9]) {
              final boss = mk(t);
              final pose = poseOf(boss);
              for (final b in pose.beams) {
                final eye = _eye(pose, sz, boss, b);
                final img = await _render(sz, (c) => GargoyleBeamArt.beam(c, sz, b, eye, layers: GargoyleBeamArt.layerMotes, time: t * 3.7));
                final frame = GargoyleKit.beamFrame(eye: eye, columnX: GargoyleLayout.birdColumn * 360, centre: b.centre * 360, half: b.half * 360, reachX: -18)!;
                final axis = (ui.Offset(GargoyleLayout.birdColumn * 360, b.centre * 360) - eye) * frame.reach;
                final halfV = b.half * 360 * frame.reach;
                var dots = 0;
                for (var y = 0; y < img.h; y++) {
                  for (var x = 0; x < img.w; x++) {
                    if (_alpha(img, x, y) < 20) continue;
                    dots++;
                    final u = (x + .5 - eye.dx) / axis.dx;
                    final v = ((y + .5 - eye.dy) - axis.dy * u) / (halfV * u);
                    // a mote pixel (AA included) is inside the wedge: |v| <= 1
                    // with a pixel of slack at the wedge's narrowest
                    expect(v.abs(), lessThanOrEqualTo(1 + 1.6 / (halfV * u).abs()), reason: '$name t=$t at $width: a mote at ($x,$y) is outside the beam (v=$v)');
                  }
                }
                expect(dots, greaterThan(12), reason: '$name t=$t: there is dust');
              }
            }
          }
        }
        // They move with the boss clock, and hold still at time 0.
        final boss = gBoss(4.4);
        final pose = poseOf(boss);
        final b = pose.beams.single;
        Future<_Img> at(double time) => _render(size, (c) => GargoyleBeamArt.beam(c, size, b, _eye(pose, size, boss, b), layers: GargoyleBeamArt.layerMotes, time: time));
        final a = await at(10), a2 = await at(10), c = await at(10.4);
        expect(a.px, a2.px, reason: 'a pure function of the clock');
        expect(a.px, isNot(c.px), reason: 'the dust drifts');
      });
    });

    testWidgets('it lights the scenery it crosses: a lit window inside the beam is brighter than the same window outside it', (tester) async {
      await tester.runAsync(() async {
        final size = const ui.Size(640, 360);
        final boss = gBoss(4.6, side: BeamSide.low);
        final pose = poseOf(boss);
        final b = pose.beams.single;
        final eye = _eye(pose, size, boss, b);
        final frame = GargoyleKit.beamFrame(eye: eye, columnX: GargoyleLayout.birdColumn * 360, centre: b.centre * 360, half: b.half * 360, reachX: -18)!;
        final axis = (ui.Offset(GargoyleLayout.birdColumn * 360, b.centre * 360) - eye) * frame.reach;
        final inside = eye + axis * .7;
        // A mid-grey "window" patch under the beam and away from it.
        const window = ui.Color(0xffd9a441);
        final img = await _render(size, (c) {
          c.drawRect(ui.Offset.zero & size, ui.Paint()..color = window);
          GargoyleBeamArt.beam(c, size, b, eye, layers: GargoyleBeamArt.layerBody | GargoyleBeamArt.layerCore);
        });
        int lum(ui.Offset p) {
          final i = ((p.dy.round()) * img.w + p.dx.round()) * 4;
          return img.px[i] + img.px[i + 1] + img.px[i + 2];
        }

        final out = ui.Offset(inside.dx, math.max(4, inside.dy - 110));
        expect(lum(inside), greaterThan(lum(out)), reason: 'light added to a lit window brightens it (plus blend)');
      });
    });
  });

  // ------------------------------------------------------------ warning --

  group('the warning', () {
    testWidgets('its boundary is the ray the beam comes to rest on: the dashed safe line passes the rules\' extreme edge at the column', (tester) async {
      await tester.runAsync(() async {
        for (final width in const [640.0, 800.0]) {
          final size = ui.Size(width, 360);
          final col = GargoyleLayout.birdColumn * 360;
          for (final (name, boss, expectY) in <(String, SkyBoss, List<(double, bool)>)>[
            ('HIGH', gBoss(3.3, aspect: width / 360), [((SearchlightGargoyle.highTo + SearchlightGargoyle.litHalf) * 360, false)]),
            ('LOW', gBoss(3.3, side: BeamSide.low, aspect: width / 360), [((SearchlightGargoyle.lowTo - SearchlightGargoyle.litHalf) * 360, false)]),
            (
              'slit',
              gBoss(3.3, fury: true, slit: true, aspect: width / 360),
              [
                ((SearchlightGargoyle.slitUpper.$2 + SearchlightGargoyle.furyLitHalf) * 360, true),
                ((SearchlightGargoyle.slitLower.$2 - SearchlightGargoyle.furyLitHalf) * 360, false),
              ],
            ),
          ]) {
            final pose = poseOf(boss);
            final img = await _render(size, (c) => GargoyleBeamArt.warning(c, size, pose, bossCentre(size, boss)));
            for (final (want, far) in expectY) {
              final eye = bossCentre(size, boss) + (far ? GargoyleBossRig.beamOrigins(pose).far : GargoyleBossRig.beamOrigins(pose).near) * (360 * SkyBoss.radius);
              // The dashed cool line is cyan: the pixels around the bird's
              // column that are, and how far each is from the ray.
              var best = 99.0, hits = 0;
              for (var x = col.floor() - 30; x <= col.floor() + 30; x++) {
                final ey = _rayY(eye, col, want, x + .5);
                for (var y = math.max(0, (ey - 16).floor()); y < math.min(360, (ey + 16).ceil()); y++) {
                  final i = (y * img.w + x) * 4;
                  if (img.px[i + 3] > 200 && img.px[i + 2] > 200 && img.px[i + 1] > 200 && img.px[i] < 190) {
                    hits++;
                    best = math.min(best, (y + .5 - ey).abs());
                  }
                }
              }
              expect(hits, greaterThan(20), reason: '$name at $width: the dashed safe line is drawn');
              expect(best, lessThanOrEqualTo(3.0), reason: '$name at $width: a dashed pixel lies on the boundary ray (nearest ${best.toStringAsFixed(1)} px)');
            }
          }
        }
      });
    });

    testWidgets('the safe side is darkened and the danger side is not: a veil of deep blue below (HIGH), above (LOW), between the fans (slit)', (tester) async {
      await tester.runAsync(() async {
        final size = const ui.Size(640, 360);
        final col = (GargoyleLayout.birdColumn * 360).round();
        Future<({double dark, double lit})> probe(SkyBoss boss, double darkY, double litY) async {
          final pose = poseOf(boss);
          final img = await _render(size, (c) => GargoyleBeamArt.warning(c, size, pose, bossCentre(size, boss)));
          // the veil is the navy: blue above red, alpha well over a third
          double navy(double y) {
            var sum = 0.0;
            for (var x = col - 6; x <= col + 6; x += 3) {
              final i = (y.round() * img.w + x) * 4;
              final a = img.px[i + 3];
              sum += img.px[i + 2] >= img.px[i] ? a / 255 : 0;
            }
            return sum / 5;
          }

          return (dark: navy(darkY), lit: navy(litY));
        }

        final high = await probe(gBoss(3.3), 330, 100);
        expect(high.dark, greaterThan(.4), reason: 'HIGH: the dark side is veiled');
        expect(high.lit, lessThan(.15), reason: 'HIGH: the swept side is amber, not veiled');
        final low = await probe(gBoss(3.3, side: BeamSide.low), 30, 300);
        expect(low.dark, greaterThan(.4), reason: 'LOW: the dark side is veiled');
        expect(low.lit, lessThan(.15), reason: 'LOW: the swept side is amber');
        final slit = await probe(gBoss(3.3, fury: true, slit: true), 180, 40);
        expect(slit.dark, greaterThan(.4), reason: 'slit: the corridor between the beams is veiled');
        expect(slit.lit, lessThan(.15), reason: 'slit: the swept top is not');
      });
    });

    testWidgets('over any backdrop the safe side reads darker and the swept side lighter, at once and by a lot (the under-a-second test)', (tester) async {
      await tester.runAsync(() async {
        const size = ui.Size(640, 360);
        const backdrop = ui.Color(0xff3b4170); // New York's mid night sky
        final col = (GargoyleLayout.birdColumn * 360).round();
        double lum(_Img i, int x0, int y0, int x1, int y1) {
          var sum = 0.0, n = 0;
          for (var y = y0; y < y1; y++) {
            for (var x = x0; x < x1; x++) {
              final k = (y * i.w + x) * 4;
              sum += .2126 * i.px[k] + .7152 * i.px[k + 1] + .0722 * i.px[k + 2];
              n++;
            }
          }
          return sum / n;
        }

        final base = await _render(size, (c) => c.drawRect(ui.Offset.zero & size, ui.Paint()..color = backdrop));
        for (final (name, boss, safe, swept) in <(String, SkyBoss, (int, int), (int, int))>[
          ('HIGH', gBoss(3.4), (250, 340), (60, 130)),
          ('LOW', gBoss(3.4, side: BeamSide.low), (20, 100), (240, 330)),
          ('slit', gBoss(3.4, fury: true, slit: true), (160, 200), (30, 90)),
        ]) {
          final pose = poseOf(boss);
          final img = await _render(size, (c) {
            c.drawRect(ui.Offset.zero & size, ui.Paint()..color = backdrop);
            GargoyleBeamArt.warning(c, size, pose, bossCentre(size, boss));
          });
          // away from the tag, around the bird's column
          final x0 = col - 40, x1 = col + 40;
          final b0 = lum(base, x0, safe.$1, x1, safe.$2), s1 = lum(img, x0, safe.$1, x1, safe.$2);
          final bw = lum(base, x0, swept.$1, x1, swept.$2), w1 = lum(img, x0, swept.$1, x1, swept.$2);
          // ignore: avoid_print
          print('warning $name: the safe side is ${(100 * (1 - s1 / b0)).toStringAsFixed(0)}% darker, the swept side ${(100 * (w1 / bw - 1)).toStringAsFixed(0)}% lighter than the bare sky');
          expect(s1, lessThan(b0 * .6), reason: '$name: the safe side is at least 40% darker');
          expect(w1, greaterThan(bw * 1.05), reason: '$name: the swept side is lighter (amber)');
        }
      });
    });

    testWidgets('hazard tape borders the dark side: amber and ink stripes beside the veil, none on the far side', (tester) async {
      await tester.runAsync(() async {
        final size = const ui.Size(640, 360);
        final boss = gBoss(3.3);
        final pose = poseOf(boss);
        final img = await _render(size, (c) => GargoyleBeamArt.warning(c, size, pose, bossCentre(size, boss)));
        final col = (GargoyleLayout.birdColumn * 360).round();
        final y1 = (SearchlightGargoyle.highTo + SearchlightGargoyle.litHalf) * 360;
        // just above the boundary at the column: alternating amber and ink
        final amber = <bool>[];
        for (var x = col - 40; x <= col + 40; x++) {
          final y = _rayY(bossCentre(size, boss) + GargoyleBossRig.beamOrigins(pose).near * (360 * SkyBoss.radius), GargoyleLayout.birdColumn * 360, y1, x + .5) - 4;
          final i = (y.round() * img.w + x) * 4;
          amber.add(img.px[i] > 200 && img.px[i + 1] > 120 && img.px[i + 2] < 120 && img.px[i + 3] > 200);
        }
        var changes = 0;
        for (var i = 1; i < amber.length; i++) {
          if (amber[i] != amber[i - 1]) changes++;
        }
        expect(changes, greaterThanOrEqualTo(4), reason: 'stripes alternate along the tape');
        expect(amber.where((a) => a).length, inInclusiveRange(20, 60), reason: 'about half of it is amber');
      });
    });

    testWidgets('the dodge tag never covers the bird\'s column, at either width and for every tag', (tester) async {
      await tester.runAsync(() async {
        for (final w in const [640.0, 800.0]) {
          final size = ui.Size(w, 360);
          for (final (t, side, slit, fury) in const [
            (3.2, BeamSide.high, false, false),
            (3.2, BeamSide.low, false, false),
            (3.4, BeamSide.high, true, true),
          ]) {
            final boss = gBoss(t, side: side, slit: slit, fury: fury, aspect: w / 360);
            final pose = poseOf(boss);
            final img = await _render(size, (c) => GargoyleBeamArt.warningTag(c, size, pose));
            final cx = GargoyleLayout.birdColumn * 360;
            final r = GargoyleLayout.birdRadius * 360 + 4;
            var opaque = 0;
            for (var cy = 20; cy < 340; cy += 4) {
              for (var y = (cy - r).floor(); y <= (cy + r).ceil(); y++) {
                for (var x = (cx - r).floor(); x <= (cx + r).ceil(); x++) {
                  final dx = x - cx, dy = y - cy;
                  if (dx * dx + dy * dy > r * r) continue;
                  if (_alpha(img, x, y) > 10) opaque++;
                }
              }
            }
            expect(opaque, 0, reason: 'the tag overlaps the bird\'s column at $w (t $t, $side, slit $slit)');
            var any = 0;
            for (var i = 3; i < img.px.length; i += 4) {
              if (img.px[i] > 10) any++;
            }
            expect(any, greaterThan(500), reason: 'and it is drawn');
          }
        }
      });
    });

    testWidgets('the warning builds from nothing to full over its 1.5 s and quickens; it never hides the bird\'s column from the far side', (tester) async {
      await tester.runAsync(() async {
        final size = const ui.Size(640, 360);
        var last = -1.0;
        for (final t in const [2.02, 2.15, 2.4, 2.8, 3.2, 3.49]) {
          final boss = gBoss(t);
          final pose = poseOf(boss);
          final img = await _render(size, (c) => GargoyleBeamArt.warning(c, size, pose, bossCentre(size, boss)));
          var sum = 0.0;
          for (var i = 3; i < img.px.length; i += 4) {
            sum += img.px[i];
          }
          expect(sum, greaterThan(last * .9), reason: 'it only builds (t=$t)');
          last = sum;
        }
        // Outside the warning and the sweep, nothing.
        for (final t in const [1.0, 7.0]) {
          final boss = gBoss(t);
          final img = await _render(size, (c) => GargoyleBeamArt.under(c, size, poseOf(boss), bossCentre(size, boss)));
          expect(img.px.every((v) => v == 0), isTrue, reason: 't=$t draws nothing');
        }
      });
    });
  });

  // ---------------------------------------------------------- the flare --

  testWidgets('the lens flare is the only beam art over the head: a burning beam and the warning\'s charging lens, nothing else', (tester) async {
    await tester.runAsync(() async {
      final size = const ui.Size(640, 360);
      final calm = gBoss(1.0);
      final a = await _render(size, (c) => GargoyleBeamArt.over(c, size, poseOf(calm), bossCentre(size, calm)));
      expect(a.px.every((v) => v == 0), isTrue);
      final burning = gBoss(4.5);
      final p = poseOf(burning);
      final b = await _render(size, (c) => GargoyleBeamArt.over(c, size, p, bossCentre(size, burning)));
      final eye = _eye(p, size, burning, p.beams.single);
      final i = (eye.dy.round() * b.w + eye.dx.round()) * 4;
      expect(b.px[i + 3], greaterThan(150), reason: 'bright at the lens');
      // the warning: the lens charges (and the shutter clacks at the start)
      var last = -1;
      for (final t in const [2.05, 2.5, 3.0, 3.45]) {
        final w = gBoss(t);
        final pw = poseOf(w);
        final img = await _render(size, (c) => GargoyleBeamArt.over(c, size, pw, bossCentre(size, w)));
        var sum = 0;
        for (var k = 3; k < img.px.length; k += 4) {
          sum += img.px[k];
        }
        expect(sum, greaterThan(0), reason: 't=$t: the lens shows it charges');
        // ignore: avoid_print
        print('lens at t=$t: $sum');
        if (t > 2.6) expect(sum, greaterThan(last * .9), reason: 'and climbs (the beat rides on it)');
        if (t > 2.4) last = sum;
      }
    });
  });

  // ------------------------------------------------------------ spotted --

  group('SPOTTED!', () {
    const size = ui.Size(640, 360);
    Future<_Img> spot(double since, {ui.Offset? bird, GargoyleSpotCost cost = GargoyleSpotCost.shield, bool reduced = false, bool fury = false}) => _render(
      size,
      (c) => GargoyleBeamArt.spotted(c, size, bird: bird ?? const ui.Offset(169.2, 180), since: since, cost: cost, reduced: reduced, fury: fury),
    );
    int ink(_Img i, [ui.Rect? r, bool circle = false]) {
      var n = 0;
      for (var y = 0; y < i.h; y++) {
        for (var x = 0; x < i.w; x++) {
          if (r != null && !r.contains(ui.Offset(x + .5, y + .5))) continue;
          if (r != null && circle && (ui.Offset(x + .5, y + .5) - r.center).distance > r.width / 2) continue;
          if (_alpha(i, x, y) > 12) n++;
        }
      }
      return n;
    }

    testWidgets('it lasts the 1.5 s recovery: a flash first, the halo and the words through it, nothing before or after', (tester) async {
      await tester.runAsync(() async {
        for (final s in const [-.1, 1.51, 3.0, double.nan, double.infinity]) {
          expect(ink(await spot(s)), 0, reason: 'since=$s draws nothing');
        }
        final early = await spot(.05), mid = await spot(.6), late = await spot(1.3);
        final bird = const ui.Offset(169.2, 180);
        final around = ui.Rect.fromCircle(center: bird, radius: 26);
        expect(ink(early, around, true), greaterThan(400), reason: 'the flash covers the bird at first');
        expect(ink(mid), greaterThan(1500), reason: 'halo, words and cost at mid');
        expect(ink(late), lessThan(ink(mid)), reason: 'fading out');
        expect(ink(late), greaterThan(0));
      });
    });

    testWidgets('after the flash nothing is drawn over the bird itself; everything stays on screen, at every bird height', (tester) async {
      await tester.runAsync(() async {
        for (final y in const [18.0, 40.0, 100.0, 180.0, 260.0, 335.0, 350.0]) {
          for (final since in const [.2, .5, 1.0, 1.4]) {
            final bird = ui.Offset(169.2, y);
            final img = await spot(since, bird: bird);
            // the bird's sprite is about 26 px from its centre
            expect(ink(img, ui.Rect.fromCircle(center: bird, radius: 26), true), 0, reason: 'nothing over the bird (y=$y, t=$since)');
            expect(ink(img), greaterThan(300), reason: 'something is drawn (y=$y)');
            // not over the health bar's strip
            expect(ink(img, const ui.Rect.fromLTWH(0, 0, 640, 30)), lessThan(ink(img) ~/ 2 + 1), reason: 'most of it clear of the bar');
          }
        }
      });
    });

    testWidgets('the cost is shown: a shield and a heart read differently, a lost run shows only the catch', (tester) async {
      await tester.runAsync(() async {
        final shield = await spot(.7), heart = await spot(.7, cost: GargoyleSpotCost.heart), run = await spot(.7, cost: GargoyleSpotCost.run);
        expect(shield.px, isNot(heart.px));
        expect(ink(run), lessThan(ink(shield)), reason: 'no chip for a run that ended');
        // teal for the shield, coral for the heart, in the chip's pixels
        bool has(_Img i, bool Function(int r, int g, int b) f) {
          for (var k = 0; k < i.px.length; k += 4) {
            if (i.px[k + 3] > 200 && f(i.px[k], i.px[k + 1], i.px[k + 2])) return true;
          }
          return false;
        }

        expect(has(shield, (r, g, b) => g > 200 && b > 190 && r < 160), isTrue, reason: 'teal');
        expect(has(heart, (r, g, b) => r > 230 && g < 140 && b < 140), isTrue, reason: 'coral');
        expect(has(heart, (r, g, b) => g > 200 && b > 190 && r < 160), isFalse);
      });
    });

    testWidgets('Reduced Motion: no flash, no expanding ring, no pop; halo, words and cost hold still', (tester) async {
      await tester.runAsync(() async {
        final a = await spot(.05, reduced: true), b = await spot(.2, reduced: true);
        final normal = await spot(.05);
        final bird = const ui.Offset(169.2, 180);
        expect(ink(normal, ui.Rect.fromCircle(center: bird, radius: 26), true), greaterThan(400), reason: 'the flash covers the bird');
        expect(ink(a, ui.Rect.fromCircle(center: bird, radius: 26), true), 0, reason: 'no flash under Reduced Motion');
        // the still frame: the same from .4 to 1.1 s (only the fade-out moves)
        final s1 = await spot(.4, reduced: true), s2 = await spot(1.1, reduced: true);
        expect(s1.px, s2.px);
        final s3 = await spot(1.4, reduced: true);
        expect(ink(s3), lessThan(ink(s1)));
        expect(a.px, b.px, reason: 'under Reduced Motion the whole moment is there from the first frame, as it stays');
        // and with motion the halo turns and pulses
        final m1 = await spot(.4), m2 = await spot(.9);
        expect(m1.px, isNot(m2.px));
      });
    });

    testWidgets('it is a pure function of its inputs and ignores what was drawn before', (tester) async {
      await tester.runAsync(() async {
        final a = await spot(.33, fury: true);
        GargoyleKit.clearCaches();
        final b = await spot(.33, fury: true);
        expect(a.px, b.px);
        final calm = await spot(.33);
        expect(calm.px, isNot(a.px), reason: 'fury has its own colours');
      });
    });

    test('budget: at most 24 ops, no layer, no blur, no shader', () {
      for (final (since, cost, reduced) in [
        (.05, GargoyleSpotCost.shield, false),
        (.3, GargoyleSpotCost.heart, false),
        (.9, GargoyleSpotCost.shield, true),
        (1.3, GargoyleSpotCost.heart, false),
      ]) {
        final before = GargoyleKit.shadersBuilt;
        final f = Counting(ui.Canvas(ui.PictureRecorder()));
        GargoyleBeamArt.spotted(f, size, bird: const ui.Offset(169, 120), since: since, cost: cost, reduced: reduced);
        expect(f.draws, lessThanOrEqualTo(24), reason: 'since=$since');
        expect(f.layers + f.blurs + f.shaderDraws, 0);
        expect(GargoyleKit.shadersBuilt - before, 0);
      }
    });

    testWidgets('spotOf reads the flight: a real spotting is found with its cost and time, a feather hit or an old one is not', (tester) async {
      await tester.runAsync(() async {
        final sim = pilot.arena();
        final boss = sim.boss!;
        boss
          ..beamSide = BeamSide.high
          ..slitSweep = false
          ..sweepsAimed = 1
          ..featherCycle = 0
          ..featherSlot = 9;
        pilot.fightAt(boss, 4.5);
        expect(GargoyleBeamArt.spotOf(sim), isNull, reason: 'nothing has happened');
        // a bird held in the light: the shield goes
        double y() => .42;
        void hold() {
          sim
            ..birdY = y()
            ..velocity = 0;
          pilot.frame(sim, dt: 1 / 60);
        }

        for (var i = 0; i < 3; i++) {
          hold();
        }
        expect(boss.spots, 1);
        final first = GargoyleBeamArt.spotOf(sim)!;
        expect(first.cost, GargoyleSpotCost.shield);
        expect(first.since, lessThan(.1));
        for (var i = 0; i < 60; i++) {
          hold();
        }
        expect(GargoyleBeamArt.spotOf(sim)!.since, closeTo(first.since + 1.0, .05), reason: 'the same spotting, one second on');
        // recovered and still lit: a heart goes
        while (sim.hearts == 3 && sim.elapsed < sim.invulnerableUntil + 1) {
          hold();
        }
        final second = GargoyleBeamArt.spotOf(sim)!;
        expect(second.cost, GargoyleSpotCost.heart);
        expect(second.since, lessThan(.1));
        // after 1.5 s it is over
        sim.birdY = .9;
        for (var i = 0; i < 100; i++) {
          pilot.frame(sim, dt: 1 / 60);
        }
        pilot.frame(sim, dt: 1 / 60);
        expect(GargoyleBeamArt.spotOf(sim), isNull);
        // a hit by something else while no beam burns is not a spotting
        final other = pilot.arena();
        pilot.fightAt(other.boss!, 1.0);
        other.events.add(FlightEvent(FlightEventKind.hit, other.elapsed, .4));
        expect(GargoyleBeamArt.spotOf(other), isNull);
        // nor is one outside the Gargoyle's fight
        expect(GargoyleBeamArt.spotOf(FlightSimulation(rules: TapFlyMode(), practice: true)), isNull);
      });
    });
  });

  // ----------------------------------------------------------- budgets --

  group('budgets', () {
    const size = ui.Size(640, 360);
    ({int ops, int clips, int layers, int blurs, int shaders, int built}) measure(SkyBoss boss, {bool reduced = false}) {
      final pose = poseOf(boss, reduced: reduced);
      final centre = bossCentre(size, boss);
      final before = GargoyleKit.shadersBuilt;
      final f = Counting(ui.Canvas(ui.PictureRecorder()));
      GargoyleBeamArt.under(f, size, pose, centre);
      GargoyleBeamArt.over(f, size, pose, centre);
      return (ops: f.draws, clips: f.clips, layers: f.layers, blurs: f.blurs, shaders: f.shaderDraws, built: GargoyleKit.shadersBuilt - before);
    }

    test('a beam is at most 6 ops (twin: 12), the warning at most 50 with one clip, every frame at most 60; no layer, no blur', () {
      var worstBeam = 0, worstWarn = 0;
      for (var t = 2.0; t < 6.6; t += .05) {
        for (final (name, mk) in <(String, SkyBoss Function())>[
          ('HIGH', () => gBoss(t)),
          ('LOW', () => gBoss(t, side: BeamSide.low)),
          ('fury', () => gBoss(t, fury: true)),
          ('slit', () => gBoss(t, fury: true, slit: true)),
        ]) {
          final boss = mk();
          final pose = poseOf(boss);
          final m = measure(boss);
          final why = '$name t=${t.toStringAsFixed(2)}';
          expect(m.layers, 0, reason: why);
          expect(m.blurs, 0, reason: why);
          expect(m.clips, lessThanOrEqualTo(1), reason: why);
          expect(m.ops, lessThanOrEqualTo(60), reason: why);
          if (pose.beams.isNotEmpty) {
            // The first .15 s of a beam the warning dissolves UNDER it (at most 50 ops more).
            final tail = pose.warnRelease > 0 ? 50 : 0;
            expect(m.ops, lessThanOrEqualTo(GargoyleBeamLook.maxOps * pose.beams.length + tail), reason: '$why: a beam is at most ${GargoyleBeamLook.maxOps} ops (+ the dissolving warning)');
            if (pose.warnRelease <= 0) worstBeam = math.max(worstBeam, m.ops);
          } else if (pose.warning > 0) {
            expect(m.ops, lessThanOrEqualTo(50), reason: why);
            worstWarn = math.max(worstWarn, m.ops);
          }
        }
      }
      // ignore: avoid_print
      print('beams: worst frame $worstBeam ops; warning: worst frame $worstWarn ops (budget 6 per beam, 50, 60 in all)');
    });

    test('a beam stays inside the vertex budget (<= ${GargoyleBeamLook.maxVertices}: 2 wedges, 2 edges, 2 rim lines, 9 specks, 3 glints) at every clock', () {
      var worst = 0;
      for (var t = 3.5; t < 6.45; t += .013) {
        for (final mk in <SkyBoss Function()>[() => gBoss(t), () => gBoss(t, side: BeamSide.low), () => gBoss(t, fury: true, slit: true)]) {
          final boss = mk();
          final pose = poseOf(boss);
          GargoyleBeamArt.under(Counting(ui.Canvas(ui.PictureRecorder())), size, pose, bossCentre(size, boss));
          worst = math.max(worst, GargoyleBeamArt.lastBeamVertices);
          expect(GargoyleBeamArt.lastBeamVertices, lessThanOrEqualTo(GargoyleBeamLook.maxVertices), reason: 't=$t');
        }
      }
      // ignore: avoid_print
      print('beam vertices: at most $worst per beam (budget ${GargoyleBeamLook.maxVertices})');
      expect(worst, greaterThan(30), reason: 'and the dust is there');
    });

    test('cost: recording a frame of the warning, a beam and the slit stays cheap (reported; JIT debug harness, bound loose for a loaded machine)', () {
      for (final (name, boss) in [('warning HIGH', gBoss(3.3)), ('zone beam', gBoss(4.5)), ('fury slit', gBoss(5.0, fury: true, slit: true))]) {
        final pose = poseOf(boss);
        final centre = bossCentre(size, boss);
        // warm
        for (var i = 0; i < 50; i++) {
          final rec = ui.PictureRecorder();
          final c = ui.Canvas(rec);
          GargoyleBeamArt.under(c, size, pose, centre);
          GargoyleBeamArt.over(c, size, pose, centre);
          rec.endRecording().dispose();
        }
        final sw = Stopwatch()..start();
        const n = 300;
        for (var i = 0; i < n; i++) {
          final rec = ui.PictureRecorder();
          final c = ui.Canvas(rec);
          GargoyleBeamArt.under(c, size, pose, centre);
          GargoyleBeamArt.over(c, size, pose, centre);
          rec.endRecording().dispose();
        }
        final us = sw.elapsedMicroseconds / n;
        // ignore: avoid_print
        print('cost: $name records in ${us.toStringAsFixed(0)} us (JIT debug harness)');
        expect(us, lessThan(12000), reason: name);
      }
    });

    test('over a whole fight the beams need at most 6 distinct shaders; a warm frame builds none', () {
      GargoyleKit.clearCaches();
      for (final boss in [gBoss(3.3), gBoss(3.3, side: BeamSide.low), gBoss(3.3, fury: true, slit: true), gBoss(4.5), gBoss(5.0, fury: true, slit: true)]) {
        measure(boss);
      }
      final own = GargoyleKit.built;
      // ignore: avoid_print
      print('beam shaders: ${own.length} $own');
      expect(own.length, lessThanOrEqualTo(6));
      for (final boss in [gBoss(3.3), gBoss(4.5), gBoss(5.0, fury: true, slit: true), gBoss(6.45)]) {
        expect(measure(boss).built, 0, reason: 'a warm frame builds no shader');
      }
    });

    test('Reduced Motion draws the same ops', () {
      for (final boss in [gBoss(3.3), gBoss(4.5), gBoss(5.0, fury: true, slit: true)]) {
        final a = measure(boss), b = measure(boss, reduced: true);
        expect(b.ops, lessThanOrEqualTo(a.ops + 1));
      }
    });
  });

  // ------------------------------------------------------ reduced motion --

  group('Reduced Motion and determinism', () {
    const size = ui.Size(640, 360);
    Future<_Img> frame(SkyBoss boss, {bool reduced = false}) {
      final pose = poseOf(boss, reduced: reduced);
      final centre = bossCentre(size, boss);
      return _render(size, (c) {
        GargoyleBeamArt.under(c, size, pose, centre);
        GargoyleBeamArt.over(c, size, pose, centre);
      });
    }

    testWidgets('every state has a still frame: the same pixels at any clock with the same state, and the safe side stays readable', (tester) async {
      await tester.runAsync(() async {
        for (final (name, mk) in <(String, SkyBoss Function(double))>[
          ('warning HIGH', (t) => gBoss(t + 3.3)),
          ('warning LOW', (t) => gBoss(t + 3.3, side: BeamSide.low)),
          ('warning slit', (t) => gBoss(t + 3.3, fury: true, slit: true)),
          ('sweep HIGH', (t) => gBoss(t + 4.5)),
          ('sweep LOW hold', (t) => gBoss(t + 6.0, side: BeamSide.low)),
          ('slit sweep', (t) => gBoss(t + 5.0, fury: true, slit: true)),
        ]) {
          // the same instant of a cycle, whole cycles apart: the clock the
          // dust, the tape and the beat would run on differs, the frame must not
          final a = await frame(mk(0), reduced: true), b = await frame(mk(9), reduced: true), c = await frame(mk(27), reduced: true);
          expect(b.px, a.px, reason: name);
          expect(c.px, a.px, reason: name);
          var n = 0;
          for (var i = 3; i < a.px.length; i += 4) {
            if (a.px[i] > 10) n++;
          }
          expect(n, greaterThan(3000), reason: '$name: the still frame says something');
        }
        // and with motion the same state moves (tape march, beat, dust)
        for (final mk in <SkyBoss Function(double)>[(t) => gBoss(3.0 + t), (t) => gBoss(4.5 + t)]) {
          final a = await frame(mk(0)), b = await frame(mk(.21));
          expect(a.px, isNot(b.px));
        }
      });
    });

    testWidgets('a pure function of the boss clock: the same pose twice, and after every cache is flooded, gives the same pixels', (tester) async {
      await tester.runAsync(() async {
        for (final boss in [gBoss(3.3), gBoss(4.5), gBoss(5.0, fury: true, slit: true)]) {
          final a = await frame(boss);
          GargoyleKit.clearCaches();
          final b = await frame(boss);
          expect(b.px, a.px);
        }
      });
    });
  });

  // ----------------------------------------------------- non-finite input --

  test('NaN or infinite sizes, centres, eyes, bands and clocks draw nothing and never throw', () {
    final bad = [double.nan, double.infinity, double.negativeInfinity];
    final boss = gBoss(4.5);
    final pose = poseOf(boss);
    final centre = bossCentre(const ui.Size(640, 360), boss);
    final rec = ui.PictureRecorder();
    final c = ui.Canvas(rec);
    for (final v in bad) {
      final sizes = [ui.Size(v, 360), ui.Size(640, v), ui.Size.zero];
      for (final s in sizes) {
        GargoyleBeamArt.under(c, s, pose, centre);
        GargoyleBeamArt.over(c, s, pose, centre);
        GargoyleBeamArt.warning(c, s, poseOf(gBoss(3.3)), centre);
        GargoyleBeamArt.warningTag(c, s, poseOf(gBoss(3.3)));
        GargoyleBeamArt.spotted(c, s, bird: const ui.Offset(169, 100), since: .2);
      }
      GargoyleBeamArt.under(c, const ui.Size(640, 360), pose, ui.Offset(v, 100));
      GargoyleBeamArt.over(c, const ui.Size(640, 360), pose, ui.Offset(100, v));
      GargoyleBeamArt.warning(c, const ui.Size(640, 360), poseOf(gBoss(3.3)), ui.Offset(v, v));
      GargoyleBeamArt.spotted(c, const ui.Size(640, 360), bird: ui.Offset(v, 100), since: .2);
      GargoyleBeamArt.spotted(c, const ui.Size(640, 360), bird: const ui.Offset(100, 100), since: v);
      GargoyleBeamArt.beam(c, const ui.Size(640, 360), GargoyleBeam(centre: v, half: .09, far: false, fury: false, intensity: 1), const ui.Offset(400, 80));
      GargoyleBeamArt.beam(c, const ui.Size(640, 360), GargoyleBeam(centre: .3, half: v, far: false, fury: false, intensity: 1), const ui.Offset(400, 80));
      GargoyleBeamArt.beam(c, const ui.Size(640, 360), GargoyleBeam(centre: .3, half: .09, far: false, fury: false, intensity: v), const ui.Offset(400, 80));
      GargoyleBeamArt.beam(c, const ui.Size(640, 360), GargoyleBeam(centre: .3, half: .09, far: false, fury: false, intensity: 1), ui.Offset(v, 80));
      GargoyleBeamArt.beam(c, const ui.Size(640, 360), GargoyleBeam(centre: .3, half: .09, far: false, fury: false, intensity: 1), const ui.Offset(400, 80), time: v);
      // a hostile boss clock: the pose makes it harmless first
      final hostile = gBoss(4.5)..age = v;
      GargoyleBeamArt.under(c, const ui.Size(640, 360), poseOf(hostile), centre);
      GargoyleBeamArt.underBoss(c, const ui.Size(640, 360), hostile, BossMotion(hostile, reducedMotion: false));
      GargoyleBeamArt.overBoss(c, const ui.Size(640, 360), hostile, BossMotion(hostile, reducedMotion: false));
    }
    // an eye at or left of the column draws no beam (and no fan)
    GargoyleBeamArt.beam(c, const ui.Size(640, 360), const GargoyleBeam(centre: .3, half: .09, far: false, fury: false, intensity: 1), const ui.Offset(100, 80));
    rec.endRecording().dispose();
  });

  // ------------------------------------------------- the staging's hooks --

  group('staging hooks', () {
    const size = ui.Size(640, 360);

    testWidgets('underBoss and overBoss draw exactly what under and over draw from the rig\'s own pose, and nothing in the perch, vent or arrival', (tester) async {
      await tester.runAsync(() async {
        for (final (t, draws) in const [(1.0, false), (3.0, true), (4.5, true), (6.45, true), (7.0, false), (-2.0, false)]) {
          final boss = gBoss(t);
          final m = BossMotion(boss, reducedMotion: false);
          final via = await _render(size, (c) {
            GargoyleBeamArt.underBoss(c, size, boss, m);
            GargoyleBeamArt.overBoss(c, size, boss, m);
          });
          final pose = GargoyleBeamArt.poseFor(boss, m);
          final direct = await _render(size, (c) {
            GargoyleBeamArt.under(c, size, pose, bossCentre(size, boss));
            GargoyleBeamArt.over(c, size, pose, bossCentre(size, boss));
          });
          expect(via.px, direct.px, reason: 't=$t');
          expect(via.px.any((v) => v != 0), draws, reason: 't=$t');
          expect(GargoyleBeamArt.active(boss, m), draws, reason: 't=$t');
        }
        // the defeat's .3 s stutter, and nothing under Reduced Motion
        final dying = gBoss(4.5, deadFor: .05);
        expect(GargoyleBeamArt.active(dying, BossMotion(dying, reducedMotion: false)), isTrue);
        expect(GargoyleBeamArt.active(dying, BossMotion(dying, reducedMotion: true)), isFalse);
        final dead = gBoss(4.5, deadFor: .5);
        expect(GargoyleBeamArt.active(dead, BossMotion(dead, reducedMotion: false)), isFalse);
        // and only for the Gargoyle
        final baron = SkyBoss(number: 1, x: .8, kind: BossKind.baronBat, cinematic: true);
        expect(GargoyleBeamArt.active(baron, BossMotion(baron, reducedMotion: false)), isFalse);
      });
    });

    test('the beam a hook draws is the rules\': the pose\'s band equals SkyBoss.beamCentres at every clock', () {
      for (var t = 3.5; t < 6.4; t += .07) {
        for (final (side, slit, fury) in const [(BeamSide.high, false, false), (BeamSide.low, false, true), (BeamSide.high, true, true)]) {
          final boss = gBoss(t, side: side, slit: slit, fury: fury);
          final pose = GargoyleBeamArt.poseFor(boss, BossMotion(boss, reducedMotion: false));
          expect([for (final b in pose.beams) b.centre], boss.beamCentres, reason: 't=$t');
          for (final b in pose.beams) {
            expect(b.half, boss.beamHalf);
          }
        }
      }
    });
  });

  // ------------------------------------------------------------ review --

  // Off unless GARGOYLE_REVIEW=true (or GARGOYLE_OUT names the folder): renders
  // the beams through the real renderer over New York's night backdrop and
  // writes the evidence sheets:
  //   flutter test --no-pub --dart-define=GARGOYLE_REVIEW=true test/gargoyle_beam_test.dart
  const review = bool.fromEnvironment('GARGOYLE_REVIEW');
  const outEnv = String.fromEnvironment('GARGOYLE_OUT');
  final out = outEnv.isEmpty ? 'build/visual-review/gargoyle-beam' : outEnv;

  test('review sheets', skip: !review, timeout: const Timeout(Duration(minutes: 10)), () async {
    await Directory(out).create(recursive: true);
    Future<void> save(ui.Image image, String name) async {
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$out/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    }

    Future<ui.Image> draw(int w, int h, void Function(ui.Canvas) paint) async {
      final rec = ui.PictureRecorder();
      final c = ui.Canvas(rec)..clipRect(ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()));
      paint(c);
      final pic = rec.endRecording();
      final img = await pic.toImage(w, h);
      pic.dispose();
      return img;
    }

    /// One full game frame (the real renderer, New York's backdrop, the rig,
    /// the HUD), then the SPOTTED! moment if [spot] is set.
    void game(
      ui.Canvas c,
      ui.Size size,
      SkyBoss boss, {
      double birdY = .5,
      double seconds = 38,
      bool reduced = false,
      double? spot,
      GargoyleSpotCost cost = GargoyleSpotCost.shield,
      bool rules = false,
      WorldRegion region = WorldRegion.newYork,
    }) {
      paintFrame(c, size, boss, FrameOptions(birdY: birdY, seconds: seconds, reduced: reduced, rules: rules, region: region));
      if (spot != null) {
        GargoyleBeamArt.spotted(c, size, bird: ui.Offset(GargoyleLayout.birdColumn * size.height, birdY * size.height), since: spot, cost: cost, fury: boss.enraged, reduced: reduced);
      }
    }

    /// Cells in a grid at native pixels (a 640 frame beside an 800 one), each
    /// frame clipped to its own size, with a label.
    Future<ui.Image> sheet(List<(String, double, void Function(ui.Canvas, ui.Size))> cells, {int cols = 2}) async {
      const label = 24.0;
      final cellW = cells.map((e) => e.$2).reduce(math.max), cellH = 360.0;
      final rows = (cells.length / cols).ceil();
      final w = (cols * cellW).round(), h = (rows * (cellH + label)).round();
      return draw(w, h, (c) {
        c.drawRect(ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()), ui.Paint()..color = const ui.Color(0xff101226));
        for (var i = 0; i < cells.length; i++) {
          final (name, width, paint) = cells[i];
          final x = (i % cols) * cellW, y = (i ~/ cols) * (cellH + label);
          text(c, name, ui.Offset(x + 6, y + 3), 13, const ui.Color(0xffffffff), outline: true);
          c.save();
          c.translate(x, y + label);
          c.clipRect(ui.Rect.fromLTWH(0, 0, width, cellH));
          paint(c, ui.Size(width, 360));
          c.restore();
        }
      });
    }

    const w640 = ui.Size(640, 360), w800 = ui.Size(800, 360);

    // 01 the warning: HIGH, LOW, the slit, over a dark and a lit-window section.
    await save(
      await sheet([
        ('WARNING HIGH 640 (t 3.2): amber hatched fan above, tape on the boundary, the dark side below, FLY LOW', 640, (c, s) => game(c, s, gBoss(3.2), birdY: .30, seconds: 20)),
        ('WARNING HIGH 800 (t 3.2, dark section)', 800, (c, s) => game(c, s, gBoss(3.2, aspect: 800 / 360), birdY: .30, seconds: 120)),
        ('WARNING LOW 640 (t 3.0, lit windows)', 640, (c, s) => game(c, s, gBoss(3.0, side: BeamSide.low), birdY: .72, seconds: 60)),
        ('WARNING LOW 800 (t 3.4)', 800, (c, s) => game(c, s, gBoss(3.4, side: BeamSide.low, aspect: 800 / 360), birdY: .70, seconds: 20)),
        ('WARNING SLIT 640 (t 3.3): slip between the beams', 640, (c, s) => game(c, s, gBoss(3.3, fury: true, slit: true), birdY: .5, seconds: 20)),
        ('WARNING SLIT 800 (t 2.6, early)', 800, (c, s) => game(c, s, gBoss(2.6, fury: true, slit: true, aspect: 800 / 360), birdY: .5, seconds: 120)),
      ]),
      '01-warning',
    );

    // 02 the sweep and the hold, calm.
    await save(
      await sheet([
        ('SWEEP HIGH 640 (t 4.2)', 640, (c, s) => game(c, s, gBoss(4.2), birdY: .80, seconds: 20)),
        ('SWEEP HIGH 800 (t 4.2, dark section)', 800, (c, s) => game(c, s, gBoss(4.2, aspect: 800 / 360), birdY: .80, seconds: 120)),
        ('SWEEP LOW 640 (t 4.2, lit windows)', 640, (c, s) => game(c, s, gBoss(4.2, side: BeamSide.low), birdY: .25, seconds: 60)),
        ('SWEEP LOW 800 (t 4.0)', 800, (c, s) => game(c, s, gBoss(4.0, side: BeamSide.low, aspect: 800 / 360), birdY: .25, seconds: 20)),
        ('HOLD HIGH 640 (t 6.0)', 640, (c, s) => game(c, s, gBoss(6.0), birdY: .80, seconds: 38)),
        ('HOLD LOW 800 (t 6.2)', 800, (c, s) => game(c, s, gBoss(6.2, side: BeamSide.low, aspect: 800 / 360), birdY: .25, seconds: 38)),
      ]),
      '02-sweep-hold',
    );

    // 03 fury: the slit sweep, its hold, and the fury zone beam.
    await save(
      await sheet([
        ('FURY SLIT 640 (t 4.4): the beams close on the gap', 640, (c, s) => game(c, s, gBoss(4.4, fury: true, slit: true), birdY: .5, seconds: 20)),
        ('FURY SLIT 800 (t 4.4, dark section)', 800, (c, s) => game(c, s, gBoss(4.4, fury: true, slit: true, aspect: 800 / 360), birdY: .5, seconds: 120)),
        ('FURY SLIT HOLD 640 (t 5.6): the gap the bird must hold', 640, (c, s) => game(c, s, gBoss(5.6, fury: true, slit: true), birdY: .5, seconds: 60)),
        ('FURY SLIT HOLD 800 (t 6.2)', 800, (c, s) => game(c, s, gBoss(6.2, fury: true, slit: true, aspect: 800 / 360), birdY: .5, seconds: 38)),
        ('FURY ZONE 640 (t 4.2): arc-white core, orange edge', 640, (c, s) => game(c, s, gBoss(4.2, fury: true, side: BeamSide.low), birdY: .22, seconds: 20)),
        ('FURY ZONE 800 HIGH (t 4.6)', 800, (c, s) => game(c, s, gBoss(4.6, fury: true, aspect: 800 / 360), birdY: .8, seconds: 60)),
      ]),
      '03-fury-slit',
    );

    // 04 SPOTTED!: the moment, in time order, plus a heart, a fury catch and Reduced Motion.
    await save(
      await sheet(
        [
          ('SPOTTED! .04 s: the flash', 640, (c, s) => game(c, s, gBoss(4.6), birdY: .32, spot: .04, seconds: 20)),
          ('.16 s: ring out, the shield breaks', 640, (c, s) => game(c, s, gBoss(4.6), birdY: .32, spot: .16, seconds: 20)),
          ('.45 s: halo, words, cost', 640, (c, s) => game(c, s, gBoss(4.7), birdY: .32, spot: .45, seconds: 20)),
          ('1.2 s: fading with the recovery', 640, (c, s) => game(c, s, gBoss(5.4), birdY: .32, spot: 1.2, seconds: 20)),
          ('a heart goes (800)', 800, (c, s) => game(c, s, gBoss(5.0, aspect: 800 / 360), birdY: .36, spot: .5, cost: GargoyleSpotCost.heart, seconds: 60)),
          ('fury catch in the slit gap edge (640)', 640, (c, s) => game(c, s, gBoss(5.0, fury: true, slit: true), birdY: .36, spot: .5, cost: GargoyleSpotCost.heart, seconds: 120)),
          ('Reduced Motion .16 s (still)', 640, (c, s) => game(c, s, gBoss(4.6), birdY: .32, spot: .16, reduced: true, seconds: 20)),
          ('bird at the top (words below)', 640, (c, s) => game(c, s, gBoss(4.7), birdY: .10, spot: .5, seconds: 20)),
        ],
        cols: 2,
      ),
      '04-spotted',
    );

    // 05 close-ups at 3x: the band at the bird's column against the rules' edges (red).
    Future<ui.Image> closeup(SkyBoss boss, double birdY, double seconds, ui.Size size) async {
      final pose = poseOf(boss);
      const zoom = 3.0;
      final b = pose.beams.first;
      final col = GargoyleLayout.birdColumn * 360;
      final y0 = math.max(0.0, (b.centre - .22) * 360);
      final img = await draw(900, 420, (c) {
        c.save();
        c.scale(zoom);
        c.translate(-(col - 150), -y0);
        paintFrame(c, size, boss, FrameOptions(birdY: birdY, seconds: seconds, hud: false));
        // the rules' band at the column (red) and the bird's circle
        for (final y in [(b.centre - b.half) * 360, (b.centre + b.half) * 360]) {
          c.drawLine(ui.Offset(col - 30, y), ui.Offset(col + 30, y), ui.Paint()
            ..color = const ui.Color(0xffff2a3a)
            ..strokeWidth = .6);
        }
        c.drawCircle(ui.Offset(col, birdY * 360), GargoyleLayout.birdRadius * 360, ui.Paint()
          ..color = const ui.Color(0xffffffff)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = .5);
        c.restore();
      });
      return img;
    }

    final closeups = [
      await closeup(gBoss(4.4), .62, 20, w640),
      await closeup(gBoss(4.4, side: BeamSide.low), .38, 60, w640),
      await closeup(gBoss(5.0, fury: true, slit: true), .5, 120, w800),
    ];

    // extra: the build-up of the warning and the ignition and fade of the beam, 640.
    await save(
      await sheet(
        [
          for (final t in const [2.03, 2.12, 2.3, 2.7, 3.1, 3.49]) ('warning t $t', 640, (c, s) => game(c, s, gBoss(t, side: BeamSide.low), birdY: .6, seconds: 20)),
          for (final t in const [3.5005, 3.55, 3.62, 6.38, 6.42, 6.47]) ('beam t $t', 640, (c, s) => game(c, s, gBoss(t, side: BeamSide.low), birdY: .25, seconds: 20)),
        ],
        cols: 3,
      ),
      'x-timeline',
    );

    // 05 Reduced Motion (every state, still) over the 3x close-ups of the band
    // at the bird's column against the rules' edges (red) and the bird's circle.
    final rm = await sheet(
      [
        ('RM warning HIGH', 640, (c, s) => game(c, s, gBoss(3.2), birdY: .30, reduced: true, seconds: 20)),
        ('RM warning LOW', 640, (c, s) => game(c, s, gBoss(3.2, side: BeamSide.low), birdY: .70, reduced: true, seconds: 20)),
        ('RM warning slit', 640, (c, s) => game(c, s, gBoss(3.3, fury: true, slit: true), birdY: .5, reduced: true, seconds: 20)),
        ('RM sweep HIGH', 640, (c, s) => game(c, s, gBoss(4.4), birdY: .80, reduced: true, seconds: 20)),
        ('RM sweep LOW', 640, (c, s) => game(c, s, gBoss(4.4, side: BeamSide.low), birdY: .25, reduced: true, seconds: 20)),
        ('RM fury slit', 640, (c, s) => game(c, s, gBoss(4.8, fury: true, slit: true), birdY: .5, reduced: true, seconds: 20)),
      ],
      cols: 3,
    );
    await save(
      await draw(rm.width, rm.height + 24 + 300, (c) {
        c.drawRect(ui.Rect.fromLTWH(0, 0, rm.width.toDouble(), rm.height + 324.0), ui.Paint()..color = const ui.Color(0xff101226));
        c.drawImage(rm, ui.Offset.zero, ui.Paint());
        text(c, 'FIT at the bird\'s column, 3x: the lit band against the rules\' edges (red lines) and the bird\'s circle (white): HIGH, LOW (640), the fury slit (800)', ui.Offset(6, rm.height + 3.0), 13, const ui.Color(0xffffffff), outline: true);
        for (var i = 0; i < closeups.length; i++) {
          c.save();
          c.translate(i * rm.width / 3, rm.height + 24.0);
          c.scale(rm.width / 3 / 900);
          c.drawImage(closeups[i], ui.Offset.zero, ui.Paint());
          c.restore();
        }
      }),
      '05-reduced-motion-and-fit',
    );

    // 07 against New York's own searchlights, and over the brightest sky.
    /// The backdrop's own two searchlights, their exact shapes and paints
    /// (`new_york.dart` `_nightBeams`) at full presence, over the same sky.
    void regionBeams(ui.Canvas c, ui.Size s, double clock) {
      final outer = ui.Paint()
        ..shader = ui.Gradient.linear(ui.Offset.zero, const ui.Offset(0, -1), const [ui.Color(0x38f5ecd2), ui.Color(0x1cf5ecd2), ui.Color(0x00f5ecd2)], const [0, .55, 1]);
      final core = ui.Paint()
        ..shader = ui.Gradient.linear(ui.Offset.zero, const ui.Offset(0, -1), const [ui.Color(0x40f8f1dc), ui.Color(0x22f8f1dc), ui.Color(0x00f8f1dc)], const [0, .6, 1]);
      final spot = ui.Paint()
        ..shader = ui.Gradient.radial(ui.Offset.zero, 1, const [ui.Color(0x50fff3d9), ui.Color(0x26fff3d9), ui.Color(0x00fff3d9)], const [0, .5, 1]);
      final h = s.height, w = s.width;
      ui.Path poly(List<double> v) {
        final p = ui.Path()..moveTo(v[0], v[1]);
        for (var i = 2; i < v.length; i += 2) {
          p.lineTo(v[i], v[i + 1]);
        }
        return p..close();
      }

      for (final (fx, speed, phase) in const [(.3, .23, 0.0), (.66, .19, 2.2)]) {
        final base = ui.Offset(w * fx, h * .72);
        final a = math.sin(clock * speed + phase) * .42;
        final reach = (base.dy - h * .33) / math.cos(a);
        c.save();
        c.translate(base.dx, base.dy);
        c.rotate(a);
        c.save();
        c.scale(h, reach);
        c.drawPath(poly(const [-.006, 0, -.04, -1, .04, -1, .006, 0]), outer);
        c.drawPath(poly(const [-.003, 0, -.02, -1, .02, -1, .003, 0]), core);
        c.restore();
        c.translate(0, -reach);
        c.rotate(-a);
        c.scale(h * .13, h * .03);
        c.drawCircle(ui.Offset.zero, 1, spot);
        c.restore();
      }
    }

    await save(
      await sheet(
        [
          ('A  New York\'s own searchlights (cream #f5ecd2, alpha <= .22, soft, no edge, from the skyline), exact paints', 640, (c, s) {
            SkyScenery.paint(c, s, seconds: 60, distance: 60 * WorldBackdrop.cruise, held: WorldRegion.newYork);
            regionBeams(c, s, 3);
            BirdPuppet.paint(c, ui.Rect.fromLTWH(GargoyleLayout.birdColumn * 360 - 25, .25 * 360 - 22, 52, 46), bird: 0, wing: .3);
          }),
          ('B  the boss beam: amber, hard edged, from his lens, with dust and a lit rim, over the same sky', 640, (c, s) => game(c, s, gBoss(4.4, side: BeamSide.low), birdY: .25, seconds: 60)),
          ('C  over a bright sky (Egypt): the amber, the hairlines and the dark ring of the rim carry it', 640, (c, s) => game(c, s, gBoss(4.4, side: BeamSide.low), birdY: .25, region: WorldRegion.egypt, seconds: 30)),
          ('D  the vent: the beam is gone, the lamp is open (no beam art left)', 640, (c, s) => game(c, s, gBoss(7.0), birdY: .5, seconds: 20)),
        ],
        cols: 2,
      ),
      '06-against-the-backdrop',
    );
    expect(Directory(out).listSync().length, greaterThan(5));
  });
}

/// The height (px) at screen x [x] of the ray from [eye] through the bird's
/// column at height [y].
double _rayY(ui.Offset eye, double col, double y, double x) => eye.dy + (y - eye.dy) * (eye.dx - x) / (eye.dx - col);
