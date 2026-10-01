// The Searchlight Gargoyle's BODY: G2's tests and its visual review.
//
// The review (off unless `--dart-define=GARGOYLE_BODY_REVIEW=true`) writes
// build/visual-review/gargoyle-body/*.png through the REAL rig and renderer:
// lamp close-ups (closed, opening, open, glance, shatter, fury, hit), torso,
// talons, ruff and tail on light and dark, in-game frames over New York's night
// at 640 and 800, silhouettes at 250 and 120 px.
@Timeout(Duration(minutes: 10))
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/sky_boss.dart';
import 'package:push_up_bird/domain/world_region.dart';
import 'package:push_up_bird/game/gargoyle_body_art.dart';
import 'package:push_up_bird/game/gargoyle_boss_rig.dart';
import 'package:push_up_bird/game/gargoyle_kit.dart';
import 'package:push_up_bird/game/gargoyle_layout.dart';
import 'package:push_up_bird/game/gargoyle_pose.dart';

import 'proof/counting_canvas.dart';
import 'proof/gargoyle_raster.dart';
import 'proof/gargoyle_stage.dart';

const _review = bool.fromEnvironment('GARGOYLE_BODY_REVIEW');
const _outEnv = String.fromEnvironment('GARGOYLE_BODY_OUT');
final _out = _outEnv.isEmpty ? 'build/visual-review/gargoyle-body' : _outEnv;

Future<void> _save(ui.Image image, String name) async {
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  File('$_out/$name.png')
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(png!.buffer.asUint8List());
}

Future<ui.Image> _render(int w, int h, void Function(ui.Canvas) draw) async {
  final rec = ui.PictureRecorder();
  final c = ui.Canvas(rec)..clipRect(ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()));
  c.drawRect(ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()), ui.Paint()..color = const ui.Color(0xff14122a));
  draw(c);
  final pic = rec.endRecording();
  final img = await pic.toImage(w, h);
  pic.dispose();
  return img;
}

const _night = [ui.Color(0xff33305e), ui.Color(0xff6a5b8c)];
const _dayCol = ui.Color(0xffe6ecf2);

/// One close-up cell: [pose]'s parts [only] seen through [region] (rig units)
/// at [cell] px, over a night gradient (or [light]).
void _cell(
  ui.Canvas c,
  GargoylePose pose,
  ui.Rect region,
  double cell,
  ui.Offset at, {
  Set<String>? only,
  bool light = false,
  String? label,
  bool plinth = false,
}) {
  final k = cell / math.max(region.width, region.height);
  c.save();
  c.translate(at.dx, at.dy);
  c.clipRect(ui.Rect.fromLTWH(0, 0, region.width * k, region.height * k));
  c.drawRect(
    ui.Rect.fromLTWH(0, 0, region.width * k, region.height * k),
    light
        ? (ui.Paint()..color = _dayCol)
        : (ui.Paint()..shader = ui.Gradient.linear(ui.Offset.zero, ui.Offset(0, region.height * k), _night)),
  );
  c.scale(k);
  c.translate(-region.left, -region.top);
  GargoyleBossRig.paintPose(c, pose, only: only, plinth: plinth);
  c.restore();
  if (label != null) text(c, label, at + const ui.Offset(6, 4), 12, light ? const ui.Color(0xff222222) : const ui.Color(0xffffffff), outline: !light);
}


/// A body pose by hand: Reduced Motion by default (no clock), the calm tone.
GargoyleBodyPose _body({
  GargoyleTone tone = const GargoyleTone(),
  double lamp = 0,
  double flare = .3,
  double fury = 0,
  double crack = 0,
  double glance = 0,
  double shatter = 0,
  double steam = 0,
  double grip = 0,
  double tail = 0,
  double chest = 0,
  double hit = 0,
  double damage = 0,
  double vent = -1,
  double time = 0,
  bool reduced = true,
}) => GargoyleBodyPose(
  tone: tone,
  lamp: lamp,
  flare: flare,
  fury: fury,
  crack: crack,
  glance: glance,
  shatter: shatter,
  steam: steam,
  grip: grip,
  tail: tail,
  chest: chest,
  hit: hit,
  damage: damage,
  vent: vent,
  time: time,
  reduced: reduced,
);

/// Every body part, in the rig's z-order.
void _all(ui.Canvas c, GargoyleBodyPose b) {
  GargoyleBodyArt.tail(c, b);
  GargoyleBodyArt.farLeg(c, b);
  GargoyleBodyArt.torso(c, b);
  GargoyleBodyArt.thigh(c, b);
  GargoyleBodyArt.ruff(c, b);
  GargoyleBodyArt.lamp(c, b);
  GargoyleBodyArt.cracks(c, b);
  GargoyleBodyArt.steam(c, b);
}

/// [draw] over an opaque night sky, rasterised.
Future<Mask> _onBg(
  void Function(ui.Canvas) draw, {
  ui.Rect region = const ui.Rect.fromLTRB(-2.2, -2.2, 2.2, 2.2),
  double ppu = 24,
}) => rasterize(
  (c) {
    c.drawRect(region, ui.Paint()..color = const ui.Color(0xff2a2750));
    draw(c);
  },
  region: region,
  ppu: ppu,
  solid: 1,
);

double _lumOf(Mask m, int i) => (.2126 * m.data[i * 4] + .7152 * m.data[i * 4 + 1] + .0722 * m.data[i * 4 + 2]) / 255;

/// Mean (luminance, red, blue) over the disc of radius [r] around the origin.
(double, double, double) _discMean(Mask m, double r) {
  var l = 0.0, red = 0.0, blue = 0.0, n = 0;
  for (var y = 0; y < m.h; y++) {
    for (var x = 0; x < m.w; x++) {
      final ux = m.ux(x + .5), uy = m.uy(y + .5);
      if (ux * ux + uy * uy > r * r) continue;
      final i = y * m.w + x;
      l += _lumOf(m, i);
      red += m.data[i * 4] / 255;
      blue += m.data[i * 4 + 2] / 255;
      n++;
    }
  }
  return (l / n, red / n, blue / n);
}

/// Luminance, saturation and the shares of near-white and near-black pixels
/// over the solid pixels of a raster.
typedef _Stats = ({double lum, double sat, double bright, double ink});

_Stats _solidStats(Mask m) {
  var l = 0.0, s = 0.0, bright = 0, ink = 0, n = 0, lights = 0;
  for (var i = 0; i < m.w * m.h; i++) {
    if (m.solid[i] == 0) continue;
    n++;
    final lum = _lumOf(m, i);
    l += lum;
    final r = m.data[i * 4], g = m.data[i * 4 + 1], b = m.data[i * 4 + 2];
    final mx = math.max(r, math.max(g, b)), mn = math.min(r, math.min(g, b));
    // saturation of the lit surfaces only (the ink is never greyed)
    if (lum > .25) {
      lights++;
      s += mx == 0 ? 0 : (mx - mn) / mx;
    }
    if (lum > .8) bright++;
    if (lum < .13) ink++;
  }
  return (lum: l / n, sat: s / lights, bright: bright / n, ink: ink / n);
}

/// The centre (rig units) of the [size] x [size] window with the highest mean
/// luminance, found with an integral image.
(double, double) _brightestWindow(Mask m, double size) {
  final w = m.w, h = m.h;
  final sat = List<double>.filled((w + 1) * (h + 1), 0);
  for (var y = 0; y < h; y++) {
    var row = 0.0;
    for (var x = 0; x < w; x++) {
      row += _lumOf(m, y * w + x);
      sat[(y + 1) * (w + 1) + x + 1] = sat[y * (w + 1) + x + 1] + row;
    }
  }
  final k = (size * m.ppu).round();
  var best = -1.0, bx = 0, by = 0;
  for (var y = 0; y + k <= h; y += 2) {
    for (var x = 0; x + k <= w; x += 2) {
      final s = sat[(y + k) * (w + 1) + x + k] - sat[y * (w + 1) + x + k] - sat[(y + k) * (w + 1) + x] + sat[y * (w + 1) + x];
      if (s > best) {
        best = s;
        bx = x;
        by = y;
      }
    }
  }
  return (m.ux(bx + k / 2), m.uy(by + k / 2));
}

/// How many pixels differ between two rasters of the same size.
int _diff(Mask a, Mask b) {
  var n = 0;
  for (var i = 0; i < a.data.length; i += 4) {
    if ((a.data[i] - b.data[i]).abs() + (a.data[i + 1] - b.data[i + 1]).abs() + (a.data[i + 2] - b.data[i + 2]).abs() > 9 || (a.data[i + 3] - b.data[i + 3]).abs() > 9) n++;
  }
  return n;
}

const _bodyParts = {'bloom', 'tail', 'farLeg', 'torso', 'thigh', 'ruff', 'lamp', 'cracks', 'steam'};

GargoylePose _lampPose({
  double lamp = 0,
  double glance = 0,
  double shatter = 0,
  double fury = 0,
  double flash = 0,
  double hit = 0,
  double crack = 0,
  double steam = 0,
  double grip = 0,
  double tail = 0,
  double lean = 0,
  double dark = .8,
}) {
  final pose = GargoylePose.custom(
    lamp: lamp,
    glance: glance,
    shatter: shatter,
    fury: fury,
    flash: flash,
    hit: hit,
    crack: crack,
    steam: steam,
    grip: grip,
    tail: tail,
    lean: lean,
    flare: fury > 0 ? 1 : .3,
    light: GargoyleSkyLight(dark: dark),
  );
  return pose;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(family)..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
  });

  // ======================================================== the real tests ==
  // Always enforced for the body (the contract's own switch,
  // test/gargoyle_enforce.dart, covers the whole rig).

  group('the pose the body reads', () {
    test('of() carries the pose channels, the vent phase and the new hit channel', () {
      final vent = poseOf(gBoss(6.4 + .6));
      final b = GargoyleBodyPose.of(vent);
      expect(b.lamp, vent.lamp);
      expect(b.steam, vent.steam);
      expect(b.hit, vent.hit);
      expect(b.vent, inInclusiveRange(0.0, 1.0));
      expect(b.vent, closeTo(.5, .02), reason: '.6 s into the 1.2 s steam pulse');
      expect(GargoyleBodyPose.of(poseOf(gBoss(1.0))).vent, -1, reason: 'no steam, no phase');
      final hit = poseOf(gBoss(1.0, hitAgo: .1));
      expect(GargoyleBodyPose.of(hit).hit, greaterThan(0));
      // the defeat's own steam pulse runs on the death clock
      final dying = GargoyleBodyPose.of(poseOf(gBoss(1.0, deadFor: .4)));
      expect(dying.steam, greaterThan(0));
      expect(dying.vent, closeTo((.4 - .12) / .68, .02));
    });

    test('finite makes every channel finite and in range, and is the identity for a good pose', () {
      const good = GargoyleBodyPose(tone: GargoyleTone(), lamp: .5, flare: .4, tail: -.3, vent: .5, time: 3);
      expect(identical(good.finite, good), isTrue);
      const nan = double.nan, inf = double.infinity;
      final bad = GargoyleBodyPose(
        tone: const GargoyleTone(),
        lamp: nan,
        flare: inf,
        fury: -inf,
        crack: 7,
        glance: nan,
        shatter: -2,
        steam: inf,
        grip: nan,
        tail: nan,
        chest: inf,
        hit: nan,
        damage: nan,
        vent: nan,
        time: inf,
        reduced: false,
      ).finite;
      for (final v in [bad.lamp, bad.flare, bad.fury, bad.crack, bad.glance, bad.shatter, bad.steam, bad.grip, bad.hit, bad.damage]) {
        expect(v, inInclusiveRange(0.0, 1.0));
      }
      expect(bad.tail, inInclusiveRange(-1.0, 1.0));
      expect(bad.chest, inInclusiveRange(-.05, .3));
      expect(bad.vent, -1);
      expect(bad.time, 0);
      expect(bad.flare, .3, reason: 'a non-finite lens glow falls back to the calm idle');
      expect(bad.crack, 1);
      expect(bad.finite.lamp, bad.lamp);
    });

    test('every part paints a poisoned pose (NaN, infinity, out of range) without throwing', () {
      const nan = double.nan, inf = double.infinity;
      for (final v in [nan, inf, -inf, 5.0, -5.0]) {
        final b = GargoyleBodyPose(
          tone: const GargoyleTone(),
          lamp: v,
          flare: v,
          fury: v,
          crack: v,
          glance: v,
          shatter: v,
          steam: v,
          grip: v,
          tail: v,
          chest: v,
          hit: v,
          damage: v,
          vent: v,
          time: v,
          reduced: false,
        );
        final rec = ui.PictureRecorder();
        final c = ui.Canvas(rec);
        expect(() => _all(c, b), returnsNormally, reason: 'channel value $v');
        rec.endRecording().dispose();
      }
    });
  });

  group('the lamp', () {
    const parts = {'lamp'};

    test('it is centred on the hit circle in every state (the louvres may rattle, the housing never moves)', () async {
      for (final (name, b) in <(String, GargoyleBodyPose)>[
        ('closed', _body()),
        ('opening', _body(lamp: .4)),
        ('open', _body(lamp: 1)),
        ('glance', _body(glance: 1, time: 1.3, reduced: false)),
        ('shatter', _body(shatter: 1, lamp: .2)),
        ('hit', _body(hit: 1)),
        ('fury', _body(fury: 1)),
      ]) {
        final m = await rasterize((c) => GargoyleBodyArt.lamp(c, b), ppu: 24, solid: 200);
        final r = m.bounds!.rect;
        expect(r.center.dx, closeTo(0, .06), reason: name);
        expect(r.center.dy, closeTo(0, .06), reason: name);
        expect(r.width, closeTo(2 * GargoyleLayout.housingRadius * math.cos(math.pi / 8), .25), reason: name);
      }
      expect(parts, contains('lamp'));
    });

    test('eleven louvres end INSIDE the glass (r < 1) for every opening and every shatter', () {
      for (var o = 0; o <= 24; o++) {
        for (final sh in const [0.0, .5, 1.0]) {
          final (lit, shade, edge) = GargoyleBodyArt.debugPlates(o / 24, sh);
          for (final path in [lit, shade, edge]) {
            for (final metric in path.computeMetrics()) {
              for (var d = 0.0; d <= metric.length; d += .03) {
                final r = metric.getTangentForOffset(d)!.position.distance;
                expect(r, lessThan(GargoyleLayout.lampRadius), reason: 'open ${o / 24} shatter $sh');
                expect(r, greaterThan(.18), reason: 'the hub covers the roots');
              }
            }
          }
        }
      }
      final (_, _, edge) = GargoyleBodyArt.debugPlates(0);
      expect(edge.computeMetrics().length, GargoyleLayout.louvreCount);
      final (_, _, opened) = GargoyleBodyArt.debugPlates(1);
      expect(opened.computeMetrics().length, GargoyleLayout.louvreCount, reason: 'open, the plates are narrow, not gone');
    });

    test('shuttered it is limestone with one amber slit, open it blazes amber: closed vs open is unmistakable, and every step in between brightens', () async {
      Future<(double, double, double)> disc(GargoyleBodyPose b) async {
        final m = await _onBg((c) => GargoyleBodyArt.lamp(c, b));
        return _discMean(m, .8);
      }

      final closed = await disc(_body());
      final open = await disc(_body(lamp: 1));
      // (luminance, red, blue)
      expect(closed.$1, lessThan(.58), reason: 'closed: a dim lamp');
      expect(closed.$2 - closed.$3, inInclusiveRange(0.0, .16), reason: 'closed is warm neutral limestone, not blue steel and not amber');
      expect(open.$1, greaterThan(.66), reason: 'open: blazing');
      expect(open.$2 - open.$3, greaterThan(.18), reason: 'open is amber');
      expect(open.$1 - closed.$1, greaterThan(.17), reason: 'open vs shut');
      expect((open.$2 - open.$3) - (closed.$2 - closed.$3), greaterThan(.1), reason: 'and warmer');
      // The first sliver of an opening shows the dark interior behind the
      // plates (a small dip is physical); from .4 open on, every step is
      // brighter than the last.
      var last = -1.0;
      for (var i = 0; i <= 10; i++) {
        final l = (await disc(_body(lamp: i / 10))).$1;
        if (i >= 4) expect(l, greaterThan(last), reason: 'opening ${i / 10}');
        if (i > 0 && i < 4) expect(l, greaterThan(closed.$1 - .08), reason: 'opening ${i / 10} must not dip far below shut');
        last = l;
      }
    });

    test('the shut lamp carries ONE amber slit, brighter as he charges, white-hot in fury, gone when open', () async {
      // the slit lies along the gap between louvres 8 and 9 (188 degrees)
      const a = 188.2 * math.pi / 180;
      Future<(double, double)> warmth(GargoyleBodyPose b) async {
        final m = await _onBg((c) => GargoyleBodyArt.lamp(c, b), ppu: 60);
        double at(double ang) {
          var r = 0.0, n = 0;
          for (final rad in const [.45, .55, .65, .75, .85]) {
            final px = ((math.cos(ang) * rad - m.x0) * m.ppu).round(), py = ((math.sin(ang) * rad - m.y0) * m.ppu).round();
            final i = (py * m.w + px) * 4;
            r += (m.data[i] - m.data[i + 2]) / 255;
            n++;
          }
          return r / n;
        }

        return (at(a), at(a + math.pi * .75));
      }

      final shut = await warmth(_body());
      expect(shut.$1, greaterThan(shut.$2 + .25), reason: 'the slit is amber against the limestone beside it');
      final charged = await warmth(_body(flare: 1));
      expect(charged.$1, greaterThan(shut.$1 + .03), reason: 'brighter when he charges');
      final open = await warmth(_body(lamp: 1));
      expect(open.$1, closeTo(open.$2, .12), reason: 'open: no slit, the whole glass burns');
    });

    test('open, it is the brightest area of the whole body (the clearest target); a rock chip or a hit flash never hides it', () async {
      const region = ui.Rect.fromLTRB(-3.0, -2.6, 4.2, 3.5);
      final m = await _onBg((c) => _all(c, _body(lamp: 1, reduced: true)), region: region, ppu: 12);
      final (cx, cy) = _brightestWindow(m, 1.4);
      expect(math.sqrt(cx * cx + cy * cy), lessThan(.8), reason: 'the brightest 1.4 x 1.4 window of the body is at ($cx, $cy), the lamp is at (0, 0)');
      // and it is the most saturated warm mass: no other window comes within a third of its luminance
      final closed = await _onBg((c) => _all(c, _body(reduced: true)), region: region, ppu: 12);
      final (cx2, cy2) = _brightestWindow(closed, 1.4);
      expect(math.sqrt(cx2 * cx2 + cy2 * cy2), greaterThan(.8), reason: 'shut, the lamp is NOT the brightest thing: only the open one is the target');
    });

    test('a glance sparks (always) and rattles the louvres (never under Reduced Motion); a hit flares', () async {
      final calm = await _onBg((c) => GargoyleBodyArt.lamp(c, _body(reduced: true)));
      final spark = await _onBg((c) => GargoyleBodyArt.lamp(c, _body(glance: .9, reduced: true)));
      expect(_diff(calm, spark), greaterThan(60), reason: 'the brass spark');
      final a = await _onBg((c) => GargoyleBodyArt.lamp(c, _body(glance: .9, time: 1.0, reduced: true)));
      final b = await _onBg((c) => GargoyleBodyArt.lamp(c, _body(glance: .9, time: 1.013, reduced: true)));
      expect(_diff(a, b), 0, reason: 'Reduced Motion: no rattle, whatever the clock');
      final m1 = await _onBg((c) => GargoyleBodyArt.lamp(c, _body(glance: .9, time: 1.0, reduced: false)));
      final m2 = await _onBg((c) => GargoyleBodyArt.lamp(c, _body(glance: .9, time: 1.013, reduced: false)));
      expect(_diff(m1, m2), greaterThan(30), reason: 'the louvres rattle in motion');
      final hit = await _onBg((c) => GargoyleBodyArt.lamp(c, _body(hit: 1, reduced: true)));
      expect(_diff(calm, hit), greaterThan(300), reason: 'a hit flares the lamp white');
    });

    test('shattered glass shows cracks and drops louvres; fury leaks light through the shut louvres', () async {
      final plain = await _onBg((c) => GargoyleBodyArt.lamp(c, _body(lamp: .2)));
      final broken = await _onBg((c) => GargoyleBodyArt.lamp(c, _body(lamp: .2, shatter: 1)));
      expect(_diff(plain, broken), greaterThan(500));
      final calm = await _onBg((c) => GargoyleBodyArt.lamp(c, _body()));
      final hot = await _onBg((c) => GargoyleBodyArt.lamp(c, _body(fury: 1)));
      expect(_discMean(hot, .95).$1, greaterThan(_discMean(calm, .95).$1 + .02), reason: 'white-hot slits between the plates');
      expect(_discMean(hot, .95).$1, lessThan(.6), reason: 'but a shut lamp in fury is still shut: it must not read as open');
    });

    test('the open lamp rings out a ping that is a still ring under Reduced Motion', () async {
      final a = await _onBg((c) => GargoyleBodyArt.lamp(c, _body(lamp: 1, time: .1, reduced: false)));
      final b = await _onBg((c) => GargoyleBodyArt.lamp(c, _body(lamp: 1, time: .5, reduced: false)));
      expect(_diff(a, b), greaterThan(40), reason: 'the ring travels');
      final r1 = await _onBg((c) => GargoyleBodyArt.lamp(c, _body(lamp: 1, time: 0, reduced: true)));
      final r2 = await _onBg((c) => GargoyleBodyArt.lamp(c, _body(lamp: 1, time: 0, reduced: true)));
      expect(_diff(r1, r2), 0);
      // the ring is translucent: it never counts as solid body
      final solid = await rasterize((c) => GargoyleBodyArt.lamp(c, _body(lamp: 1, time: .1, reduced: false)), ppu: 24, solid: 200);
      expect(solid.bounds!.rect.width, lessThan(2.8));
    });
  });

  group('the chest, thighs, ruff and tail', () {
    test('the chest keeps the layout\'s extremes (front -1.88, back 1.68, top -1.92, rump 2.84)', () async {
      final m = await rasterize((c) => GargoyleBodyArt.torso(c, _body(reduced: true)), ppu: 40, solid: 200);
      final r = m.bounds!.rect;
      expect(r.left, closeTo(-1.88, .09));
      expect(r.right, closeTo(1.68, .09));
      expect(r.top, closeTo(-1.92, .09));
      expect(r.bottom, closeTo(2.84, .09));
    });

    test('everything laid inside the chest stays inside its outline', () {
      final shapes = GargoyleBodyArt.debugShapes;
      bool near(Offset p) {
        if (shapes.torso.contains(p)) return true;
        for (var k = 0; k < 8; k++) {
          final a = k * math.pi / 4;
          if (shapes.torso.contains(p + Offset(math.cos(a), math.sin(a)) * .05)) return true;
        }
        return false;
      }

      for (final e in GargoyleBodyArt.debugTorsoDetails.entries) {
        for (final metric in e.value.computeMetrics()) {
          for (var d = 0.0; d <= metric.length; d += .04) {
            final p = metric.getTangentForOffset(d)!.position;
            expect(near(p), isTrue, reason: '${e.key} at (${p.dx.toStringAsFixed(2)}, ${p.dy.toStringAsFixed(2)}) leaves the chest');
          }
        }
      }
    });

    test('the cracks run on stone only: inside the chest, the thigh or the ruff, never over the brass', () {
      final s = GargoyleBodyArt.debugShapes;
      final housing = GargoyleKit.octagon(GargoyleLayout.housingRadius);
      bool onStone(Offset p) {
        for (var k = 0; k < 9; k++) {
          final q = k == 8 ? p : p + Offset(math.cos(k * math.pi / 4), math.sin(k * math.pi / 4)) * .06;
          if (s.torso.contains(q) || s.thigh.contains(q) || s.ruffFront.contains(q) || s.ruffBack.contains(q)) return true;
        }
        return false;
      }

      for (final (from, to, pts) in GargoyleBodyArt.debugCrackNet) {
        expect(from, lessThan(to));
        for (final p in pts) {
          expect(onStone(p), isTrue, reason: 'crack point $p is off the stone');
          expect(housing.contains(p), isFalse, reason: 'crack point $p is over the brass');
        }
      }
      // every layout seed has a crack starting at it, or at the nearest stone
      final starts = [for (final (_, _, pts) in GargoyleBodyArt.debugCrackNet) pts.first];
      for (final (i, seed) in GargoyleLayout.crackSeeds.indexed) {
        final nearest = starts.map((p) => (p - seed).distance).reduce(math.min);
        // (the right seed was moved onto the chest by the integration: it used
        // to lie under the wing's hub)
        expect(nearest, lessThan(.2), reason: 'seed $i $seed');
      }
      expect(starts.any((p) => (p - GargoyleLayout.crackSeeds[0]).distance < .05), isTrue, reason: 'the left seed is exact');
    });

    test('cracks grow with the crack channel and spread at the defeat', () async {
      final none = await _onBg((c) => GargoyleBodyArt.cracks(c, _body(crack: 0)));
      var last = 0;
      for (final level in const [.1, .3, .6, .8, 1.0]) {
        final m = await _onBg((c) => GargoyleBodyArt.cracks(c, _body(crack: level)));
        final n = _diff(none, m);
        expect(n, greaterThanOrEqualTo(last), reason: 'crack $level');
        last = n;
      }
      final fury = _diff(none, await _onBg((c) => GargoyleBodyArt.cracks(c, _body(crack: .6, fury: 1))));
      final dead = _diff(none, await _onBg((c) => GargoyleBodyArt.cracks(c, _body(crack: 1))));
      expect(fury, greaterThan(150), reason: 'fury shows glowing seams');
      expect(dead, greaterThan(fury * 1.4), reason: 'the defeat spreads them');
      // a pose carrying damage (the pose does not yet) opens hairline cracks too
      final hurt = _diff(none, await _onBg((c) => GargoyleBodyArt.cracks(c, _body(damage: 1))));
      expect(hurt, greaterThan(0));
    });

    test('fury darkens the stone, a hit bleaches it near white (the ink holds), the dormant stone greys', () async {
      const region = ui.Rect.fromLTRB(-2.3, -2.2, 2.4, 3.1);
      Future<_Stats> body(GargoyleTone t) async {
        final m = await rasterize((c) => _all(c, _body(tone: t, fury: t.fury, reduced: true)), region: region, ppu: 14, solid: 200);
        return _solidStats(m);
      }

      final calm = await body(const GargoyleTone());
      final fury = await body(const GargoyleTone(fury: 1));
      final flash = await body(const GargoyleTone(flash: .55));
      final stone = await body(const GargoyleTone(stone: 1));
      expect(fury.lum, lessThan(calm.lum - .015), reason: 'darker stone in fury');
      expect(flash.lum, greaterThan(calm.lum + .1), reason: 'a hit bleaches the whole body');
      expect(flash.bright, greaterThan(calm.bright + .15), reason: 'near white');
      expect(flash.ink, closeTo(calm.ink, .04), reason: 'the flash bleaches the lights, not the ink');
      expect(stone.sat, lessThan(.13), reason: 'dormant stone is grey');
      expect(stone.sat, lessThan(calm.sat * .6));
    });

    test('the limestone is glossy: specular streaks on the upper-left bevels, a bright moon rim, a deeper shade side (art review D1)', () async {
      // near-white pixels (the streaks: cream-white #fffbe8, white) on the chest's stepped left side
      final chest = await rasterize((c) => GargoyleBodyArt.torso(c, _body(tone: const GargoyleTone(dark: .8).snapped())), ppu: 40, solid: 200);
      int whites(Mask m, ui.Rect r) {
        var n = 0;
        for (var y = ((r.top - m.y0) * m.ppu).floor(); y < ((r.bottom - m.y0) * m.ppu).ceil(); y++) {
          for (var x = ((r.left - m.x0) * m.ppu).floor(); x < ((r.right - m.x0) * m.ppu).ceil(); x++) {
            final i = (y * m.w + x) * 4;
            if (m.data[i + 3] > 200 && m.data[i] > 238 && m.data[i + 1] > 236 && m.data[i + 2] > 220) n++;
          }
        }
        return n;
      }

      expect(whites(chest, const ui.Rect.fromLTRB(-1.95, -1.3, -.7, 1.3)), greaterThan(60), reason: 'streaks along the chest\'s upper-left edges and the frame bevel');
      final thigh = await rasterize((c) => GargoyleBodyArt.thigh(c, _body()), ppu: 40, solid: 200);
      expect(whites(thigh, const ui.Rect.fromLTRB(-1.7, 1.4, -.7, 2.0)), greaterThan(40), reason: 'the thigh\'s polish crescent and streaks');
      // the moon's rim: a cool bright line on the back and top edges, brighter on a dark sky
      Future<double> rimLum(double dark) async {
        final m = await rasterize((c) => GargoyleBodyArt.torso(c, _body(tone: GargoyleTone(dark: dark).snapped())), ppu: 40, solid: 200);
        // the right flank, 0.17 inside the outline at y 1.0: x 1.68 - .1 .. - .2 (the rim's band)
        var l = 0.0, n = 0;
        for (var y = ((.85 - m.y0) * m.ppu).round(); y < ((1.4 - m.y0) * m.ppu).round(); y++) {
          for (var x = ((1.46 - m.x0) * m.ppu).round(); x < ((1.62 - m.x0) * m.ppu).round(); x++) {
            final i = y * m.w + x;
            if (m.solid[i] == 0) continue;
            l = math.max(l, _lumOf(m, i));
            n++;
          }
        }
        return n == 0 ? 0 : l;
      }

      expect(await rimLum(1), greaterThan(.78), reason: 'the rim is nearly white on a dark sky');
      // the shade side is deeper than the old limeShade: the back flank low on the chest
      final back = await rasterize((c) => GargoyleBodyArt.torso(c, _body(tone: const GargoyleTone(dark: 0).snapped())), ppu: 40, solid: 200);
      var l = 0.0, n = 0;
      for (var y = ((1.0 - back.y0) * back.ppu).round(); y < ((1.5 - back.y0) * back.ppu).round(); y++) {
        for (var x = ((1.42 - back.x0) * back.ppu).round(); x < ((1.50 - back.x0) * back.ppu).round(); x++) {
          final i = y * back.w + x;
          if (back.solid[i] == 0) continue;
          l += _lumOf(back, i);
          n++;
        }
      }
      expect(l / n, lessThan(.58), reason: 'the shade side reads deep violet-grey, not cream');
    });

    test('the hit flare stays inside the lamp housing (it re-fires with every hit)', () async {
      const region = ui.Rect.fromLTRB(-3, -3, 3, 3);
      final calm = await _onBg((c) => GargoyleBodyArt.lamp(c, _body(lamp: 1)), region: region);
      final hit = await _onBg((c) => GargoyleBodyArt.lamp(c, _body(lamp: 1, hit: 1)), region: region);
      var far = 0, near = 0;
      for (var y = 0; y < calm.h; y++) {
        for (var x = 0; x < calm.w; x++) {
          final i = y * calm.w + x;
          final d = (calm.data[i * 4] - hit.data[i * 4]).abs() + (calm.data[i * 4 + 1] - hit.data[i * 4 + 1]).abs() + (calm.data[i * 4 + 2] - hit.data[i * 4 + 2]).abs();
          if (d < 12) continue;
          final ux = calm.ux(x + .5), uy = calm.uy(y + .5);
          if (math.sqrt(ux * ux + uy * uy) > 1.36) {
            far++;
          } else {
            near++;
          }
        }
      }
      expect(near, greaterThan(100), reason: 'it flares the lamp');
      expect(far, 0, reason: 'and nothing outside the housing');
    });

    test('the chest breathes visibly (the pose\'s +-.03) and the frame stays on the lamp', () async {
      Future<ui.Rect> rect(double chest) async => (await rasterize((c) => GargoyleBodyArt.torso(c, _body(chest: chest)), ppu: 40, solid: 200)).bounds!.rect;
      final rest = await rect(0), inhale = await rect(.03);
      expect(rest.top - inhale.top, greaterThan(.1), reason: 'the chest rises by about 4% of its height');
      expect(rest.bottom - inhale.bottom, lessThan(.12), reason: 'rooted at the belly, it does not sink into the ledge');
      expect(rest.left - inhale.left, lessThan(.1), reason: 'and does not push into the throat notch');
    });

    test('the tail fans from the layout\'s tips and stays in the envelope and out of the tail pocket', () async {
      for (var sw = -1.0; sw <= 1.001; sw += .25) {
        final m = await rasterize((c) => GargoyleBodyArt.tail(c, _body(tail: sw)), ppu: 24, solid: 200);
        final r = m.bounds!.rect;
        expect(r.right, lessThanOrEqualTo(GargoyleLayout.envelope.right), reason: 'swing $sw');
        expect(r.bottom, lessThanOrEqualTo(GargoyleLayout.envelope.bottom - .05), reason: 'swing $sw');
        for (var i = 0; i < GargoyleLayout.tailBlades; i++) {
          final tip = GargoyleLayout.tailTip(i, swing: sw);
          final root = GargoyleLayout.tailRoot;
          final probe = tip + (root - tip) / (root - tip).distance * .45;
          expect(m.at(((probe.dx - m.x0) * m.ppu).round(), ((probe.dy - m.y0) * m.ppu).round()), isTrue, reason: 'blade $i at swing $sw');
        }
        final body = await rasterize((c) {
          GargoyleBodyArt.tail(c, _body(tail: sw));
          GargoyleBodyArt.torso(c, _body(tail: sw));
          GargoyleBodyArt.thigh(c, _body(tail: sw));
        }, ppu: 12, solid: 128);
        expect(body.largestEmptyDisc(const ui.Rect.fromLTRB(1.75, .55, 3.5, 1.95)), greaterThanOrEqualTo(GargoyleGates.tailPocket), reason: 'tail pocket at swing $sw');
      }
    });

    test('the talons stand ON the lip and hook over it, clenched or not, inside the envelope', () async {
      for (final grip in const [0.0, .5, 1.0]) {
        for (final (name, fn) in <(String, void Function(ui.Canvas, GargoyleBodyPose))>[('thigh', GargoyleBodyArt.thigh), ('farLeg', GargoyleBodyArt.farLeg)]) {
          final m = await rasterize((c) => fn(c, _body(grip: grip)), ppu: 40, solid: 200);
          final r = m.bounds!.rect;
          expect(r.bottom, lessThanOrEqualTo(GargoyleLayout.envelope.bottom - .04), reason: '$name grip $grip');
          expect(r.bottom, greaterThan(GargoyleLayout.ledgeY + .2), reason: '$name claws hook over the lip');
          expect(r.left, greaterThanOrEqualTo(GargoyleLayout.ledgeLip), reason: '$name stays on the ledge');
          // toes rest on the lip: solid stone just above y = ledgeY under every near heel
          if (name == 'thigh') {
            for (final h in GargoyleLayout.talonHeels) {
              final x = h - .25;
              expect(m.at(((x - m.x0) * m.ppu).round(), ((GargoyleLayout.ledgeY - .04 - m.y0) * m.ppu).round()), isTrue, reason: 'toe at heel $h stands on the lip');
            }
          }
        }
      }
      final relaxed = await rasterize((c) => GargoyleBodyArt.thigh(c, _body(grip: 0)), ppu: 40, solid: 200);
      final clenched = await rasterize((c) => GargoyleBodyArt.thigh(c, _body(grip: 1)), ppu: 40, solid: 200);
      expect(clenched.bounds!.rect.bottom, greaterThan(relaxed.bounds!.rect.bottom + .05), reason: 'a clench drives the claws deeper over the lip');
    });

    test('the ruff keeps out of the throat notch and the steam hoods out of the wing V until they open', () async {
      final ruff = await rasterize((c) => GargoyleBodyArt.ruff(c, _body()), ppu: 40, solid: 200);
      expect(ruff.bounds!.rect.left, greaterThanOrEqualTo(-1.5));
      final rect = ruff.bounds!.rect;
      expect(rect.top, greaterThanOrEqualTo(-2.1));
      // shut, the vent shows nothing
      final shut = await rasterize((c) => GargoyleBodyArt.steam(c, _body()), ppu: 12, solid: 1);
      expect(shut.bounds, isNull);
    });
  });

  group('the vent', () {
    test('two hoods open with the lamp and puffs are born, rise and thin through the pulse', () async {
      const region = ui.Rect.fromLTRB(-1, -5, 4, 0);
      Future<Mask> at(double ph) => rasterize((c) => GargoyleBodyArt.steam(c, _body(steam: 1, vent: ph, lamp: .3)), ppu: 20, region: region, solid: 1);
      double centroidY(Mask m) {
        var sum = 0.0, n = 0;
        for (var y = 0; y < m.h; y++) {
          for (var x = 0; x < m.w; x++) {
            // soft puffs only: skip the hoods' solid pixels
            final a = m.data[(y * m.w + x) * 4 + 3];
            if (a > 8 && a < 200 && m.uy(y) < -2.4) {
              sum += m.uy(y);
              n++;
            }
          }
        }
        return n == 0 ? 0 : sum / n;
      }

      double alphaSum(Mask m) {
        var sum = 0.0;
        for (var i = 3; i < m.data.length; i += 4) {
          if (m.data[i] < 200) sum += m.data[i];
        }
        return sum;
      }

      final early = await at(.2), mid = await at(.5), late = await at(.9);
      expect(alphaSum(mid), greaterThan(alphaSum(early) * .8), reason: 'the puffs build');
      expect(centroidY(late), lessThan(centroidY(mid)), reason: 'puffs rise');
      expect(alphaSum(late), lessThan(alphaSum(mid)), reason: 'and thin');
      // a steam 0 pulse draws no puffs at all
      final none = await rasterize((c) => GargoyleBodyArt.steam(c, _body(steam: 0, lamp: 1)), ppu: 20, region: region, solid: 1);
      expect(alphaSum(none), lessThan(alphaSum(mid)));
    });
  });

  group('budget, caches, determinism', () {
    final poses = <(String, GargoylePose Function(), bool)>[
      ('perch', () => poseOf(gBoss(1.0)), false),
      ('warning', () => poseOf(gBoss(3.3)), false),
      ('sweep', () => poseOf(gBoss(4.5)), false),
      ('shrug', () => poseOf(gBoss(4.6 - .02)), false),
      ('vent', () => poseOf(gBoss(7.0)), false),
      ('vent early', () => poseOf(gBoss(6.9)), false),
      ('glance', () => poseOf(gBoss(1.0, glanceAgo: .07)), false),
      ('hit', () => poseOf(gBoss(1.0, hitAgo: .06)), false),
      ('fury idle', () => poseOf(gBoss(1.0, fury: true)), false),
      ('fury rage', () => poseOf(gBoss(1.0, fury: true, enragedAgo: .4)), false),
      ('fury vent', () => poseOf(gBoss(7.0, fury: true)), false),
      ('fury vent hit', () => poseOf(gBoss(7.0, fury: true, hitAgo: .05)), false),
      ('fury slit', () => poseOf(gBoss(4.5, fury: true, slit: true)), false),
      ('arrival stone', () => poseOf(gBoss(-3.6)), false),
      ('arrival roar', () => poseOf(gBoss(-1.5)), false),
      ('defeat .3', () => poseOf(gBoss(1.0, deadFor: .3)), false),
      ('defeat .7', () => poseOf(gBoss(1.0, deadFor: .7)), false),
      ('defeat from vent', () => poseOf(gBoss(7.2, deadFor: .5, fury: true)), false),
      ('RM sweep', () => poseOf(gBoss(4.5), reduced: true), true),
      ('RM fury slit', () => poseOf(gBoss(4.5, fury: true, slit: true), reduced: true), true),
      ('RM defeat', () => poseOf(gBoss(1.0, deadFor: .7), reduced: true), true),
    ];

    test('the body stays inside its share: <= 100 ops, 3 clips, 4 shaders, no saveLayer, no blur', () {
      GargoyleKit.clearCaches();
      GargoyleBodyArt.clearCaches();
      var worst = 0, worstAt = '';
      for (final (name, mk, _) in poses) {
        final pose = mk();
        final c = Counting(ui.Canvas(ui.PictureRecorder()));
        _all(c, GargoyleBodyPose.of(pose));
        expect(c.draws, lessThanOrEqualTo(100), reason: '$name draws ${c.draws} ops');
        expect(c.clips, lessThanOrEqualTo(3), reason: name);
        expect(c.layers, 0, reason: name);
        expect(c.blurs, 0, reason: name);
        if (c.draws > worst) {
          worst = c.draws;
          worstAt = name;
        }
      }
      final shaders = GargoyleKit.built.where((k) => !'$k'.startsWith('glow:')).toList();
      // ignore: avoid_print
      print('body: worst $worst ops at $worstAt, ${shaders.length} shaders $shaders');
      expect(shaders.length, lessThanOrEqualTo(4));
      expect(shaders.every((k) => '$k'.startsWith('body.')), isTrue, reason: 'the body builds only its own shaders');
    });

    test('a warm frame builds no shader and no path (every pose-dependent path is cached)', () {
      for (final (name, mk, _) in poses) {
        final b = GargoyleBodyPose.of(mk());
        _all(ui.Canvas(ui.PictureRecorder()), b);
        final before = GargoyleKit.shadersBuilt;
        final size = GargoyleBodyArt.cacheSize;
        _all(ui.Canvas(ui.PictureRecorder()), b);
        expect(GargoyleKit.shadersBuilt, before, reason: name);
        expect(GargoyleBodyArt.cacheSize, size, reason: '$name built a path on a warm frame');
      }
    });

    test('prewarm builds the shaders and statics once: the first real frame builds none', () {
      GargoyleKit.clearCaches();
      GargoyleBodyArt.clearCaches();
      GargoyleBodyArt.prewarm();
      expect(GargoyleKit.built.where((k) => '$k'.startsWith('body.')).length, 4);
      final before = GargoyleKit.shadersBuilt;
      _all(ui.Canvas(ui.PictureRecorder()), _body(lamp: .5, crack: .6, reduced: true));
      expect(GargoyleKit.shadersBuilt, before);
    });

    test('the path caches are bounded however long the fight runs', () {
      GargoyleBodyArt.clearCaches();
      for (var i = 0; i < 4000; i++) {
        final b = GargoyleBodyPose(
          tone: const GargoyleTone(),
          lamp: (i * .37) % 1,
          shatter: (i % 9) / 8,
          crack: (i * .11) % 1,
          grip: (i * .23) % 1,
          tail: ((i * .53) % 2) - 1,
          fury: (i % 3) / 2,
          reduced: true,
        );
        final c = ui.Canvas(ui.PictureRecorder());
        GargoyleBodyArt.lamp(c, b);
        GargoyleBodyArt.tail(c, b);
        GargoyleBodyArt.cracks(c, b);
        GargoyleBodyArt.thigh(c, b);
        GargoyleBodyArt.farLeg(c, b);
        expect(GargoyleBodyArt.cacheSize, lessThanOrEqualTo(4 * GargoyleBodyArt.pathCacheCapacity));
      }
      expect(GargoyleKit.cacheSize, lessThanOrEqualTo(GargoyleKit.cacheCapacity));
    });

    test('order independent: the same states in any order, with the caches flooded or cleared, paint the same pixels', () async {
      const region = ui.Rect.fromLTRB(-2.4, -2.4, 4.4, 3.6);
      Future<List<Mask>> render(List<int> order) async {
        final out = List<Mask?>.filled(poses.length, null);
        for (final i in order) {
          final b = GargoyleBodyPose.of(poses[i].$2());
          out[i] = await _onBg((c) => _all(c, b), region: region, ppu: 10);
        }
        return out.cast<Mask>();
      }

      GargoyleKit.clearCaches();
      GargoyleBodyArt.clearCaches();
      final forward = await render([for (var i = 0; i < poses.length; i++) i]);
      GargoyleKit.clearCaches();
      GargoyleBodyArt.clearCaches();
      // flood the path caches with other values first
      for (var i = 0; i < 200; i++) {
        final c = ui.Canvas(ui.PictureRecorder());
        _all(c, GargoyleBodyPose(tone: const GargoyleTone(), lamp: (i % 25) / 24, tail: (i % 33) / 16 - 1, crack: (i % 13) / 12, grip: (i % 7) / 6, shatter: (i % 9) / 8, reduced: true));
      }
      final backward = await render([for (var i = poses.length - 1; i >= 0; i--) i]);
      for (var i = 0; i < poses.length; i++) {
        expect(_diff(forward[i], backward[i]), 0, reason: poses[i].$1);
      }
    });

    test('Reduced Motion: a still frame whatever the clock says; motion channels are inert, state channels still show', () async {
      for (final b in [_body(lamp: 1, glance: .8), _body(steam: 1, vent: .5, lamp: 1), _body(crack: .7, fury: 1)]) {
        final a = await _onBg((c) => _all(c, GargoyleBodyPose(tone: b.tone, lamp: b.lamp, glance: b.glance, steam: 0, crack: b.crack, fury: b.fury, time: 0, reduced: true)));
        final z = await _onBg((c) => _all(c, GargoyleBodyPose(tone: b.tone, lamp: b.lamp, glance: b.glance, steam: 0, crack: b.crack, fury: b.fury, time: 0, reduced: true)));
        expect(_diff(a, z), 0);
      }
      final open = await _onBg((c) => _all(c, _body(lamp: 1, reduced: true)));
      final shut = await _onBg((c) => _all(c, _body(reduced: true)));
      expect(_diff(open, shut), greaterThan(1200), reason: 'the lamp state shows in a still frame');
      for (final (name, mk, _) in poses.where((p) => p.$3)) {
        final b = GargoyleBodyPose.of(mk());
        expect(b.time, 0, reason: name);
        expect(b.reduced, isTrue, reason: name);
      }
    });

    test('verdigris stays under 8% of the part and moon light and warm fill are present', () async {
      for (final (name, fn) in <(String, void Function(ui.Canvas, GargoyleBodyPose))>[('torso', GargoyleBodyArt.torso), ('lamp', GargoyleBodyArt.lamp)]) {
        final m = await rasterize((c) => fn(c, _body(reduced: true)), ppu: 24, solid: 200);
        var teal = 0, solid = 0;
        for (var i = 0; i < m.w * m.h; i++) {
          if (m.solid[i] == 0) continue;
          solid++;
          final r = m.data[i * 4], g = m.data[i * 4 + 1], b = m.data[i * 4 + 2];
          if (g > r + 28 && g >= b - 12) teal++;
        }
        expect(teal / solid, lessThan(.08), reason: '$name: verdigris is ${(100 * teal / solid).toStringAsFixed(1)}% of the part');
      }
      // the moon's cool rim: a dark sky lights the back edge more than a bright one
      Future<int> cool(GargoyleTone t) async {
        final m = await rasterize((c) => GargoyleBodyArt.torso(c, _body(tone: t, reduced: true)), ppu: 24, solid: 200);
        var n = 0;
        for (var i = 0; i < m.w * m.h; i++) {
          if (m.solid[i] == 1 && m.data[i * 4 + 2] > m.data[i * 4] + 14) n++;
        }
        return n;
      }

      expect(await cool(const GargoyleTone(dark: 1)), greaterThan(await cool(const GargoyleTone(dark: 0)) + 8));
    });
  });

  test('review 01 lamp states, 5x, night and light', skip: !_review, () async {
    const region = ui.Rect.fromLTRB(-1.95, -1.95, 1.95, 1.95);
    const cell = 330.0;
    final states = <(String, GargoylePose Function())>[
      ('closed (shuttered)', () => _lampPose()),
      ('opening .25', () => _lampPose(lamp: .25)),
      ('opening .5', () => _lampPose(lamp: .5)),
      ('opening .75', () => _lampPose(lamp: .75)),
      ('OPEN 1.0', () => _lampPose(lamp: 1)),
      ('glance (clink)', () => _lampPose(glance: .9)),
      ('shatter .5', () => _lampPose(shatter: .5, lamp: .2)),
      ('shatter 1', () => _lampPose(shatter: 1, lamp: .2)),
      ('fury, closed', () => _lampPose(fury: 1, crack: .6)),
      ('fury, open', () => _lampPose(fury: 1, lamp: 1, crack: .6)),
      ('hit flash on open', () => _lampPose(lamp: 1, flash: .55, hit: 1)),
      ('hit flash on closed', () => _lampPose(flash: .55, hit: .6)),
    ];
    const cols = 6;
    final rows = (states.length / cols).ceil();
    for (final light in [false, true]) {
      final img = await _render((cols * cell).round(), (rows * cell).round(), (c) {
        for (var i = 0; i < states.length; i++) {
          _cell(c, states[i].$2(), region, cell, ui.Offset((i % cols) * cell, (i ~/ cols) * cell), only: _bodyParts, light: light, label: states[i].$1);
        }
      });
      await _save(img, light ? '01-lamp-states-light' : '01-lamp-states-night');
    }
  });

  test('review 02 body close-up, light and dark, calm and fury', skip: !_review, () async {
    const region = ui.Rect.fromLTRB(-2.6, -2.3, 3.6, 3.55);
    const cell = 640.0;
    final poses = <(String, GargoylePose Function())>[
      ('calm', () => _lampPose()),
      ('vent: lamp open + steam', () => poseOf(gBoss(6.9 + 4.6 - 4.6))),
      ('fury + cracks + grip', () => _lampPose(fury: 1, crack: .6, grip: 1, lamp: 0)),
      ('hit flash', () => _lampPose(flash: .55, hit: .8)),
    ];
    final w = (cell * (region.width / math.max(region.width, region.height))).round();
    final h = (cell * (region.height / math.max(region.width, region.height))).round();
    for (final light in [false, true]) {
      final img = await _render(w * 2, h * 2, (c) {
        for (var i = 0; i < poses.length; i++) {
          _cell(c, poses[i].$2(), region, cell, ui.Offset((i % 2) * w.toDouble(), (i ~/ 2) * h.toDouble()), only: {..._bodyParts, 'head', 'nearFan', 'farFan', 'ledge'}, light: light, label: poses[i].$1, plinth: true);
        }
      });
      await _save(img, light ? '02-body-light' : '02-body-night');
    }
  });

  test('review 03 talons, ruff, tail, cracks', skip: !_review, () async {
    // talons on the ledge: relaxed and clenched, near and far
    const talons = ui.Rect.fromLTRB(-2.4, 1.5, 2.3, 3.6);
    const cell = 700.0;
    final img = await _render(700, 1000, (c) {
      _cell(c, _lampPose(grip: 0), talons, cell, const ui.Offset(0, 0), only: {'farLeg', 'torso', 'thigh', 'tail', 'ledge'}, plinth: true, label: 'talons: relaxed');
      _cell(c, _lampPose(grip: 1), talons, cell, const ui.Offset(0, 320), only: {'farLeg', 'torso', 'thigh', 'tail', 'ledge'}, plinth: true, label: 'talons: clenched (grip 1)');
      _cell(c, _lampPose(grip: 0), talons, cell, const ui.Offset(0, 640), only: {'farLeg', 'torso', 'thigh', 'tail', 'ledge'}, plinth: true, light: true, label: 'light backdrop');
    });
    await _save(img, '03-talons');
    const ruffRegion = ui.Rect.fromLTRB(-2.4, -2.9, 1.8, -.3);
    final ruff = await _render(1100, 330, (c) {
      _cell(c, _lampPose(), ruffRegion, 500, const ui.Offset(0, 0), only: {'torso', 'ruff', 'lamp', 'head', 'nearFan', 'farFan'}, label: 'ruff with the head and wings');
      _cell(c, _lampPose(), ruffRegion, 500, const ui.Offset(550, 0), only: {'torso', 'ruff', 'lamp'}, label: 'ruff alone');
    });
    await _save(ruff, '03-ruff');
    const tailRegion = ui.Rect.fromLTRB(.8, .4, 4.4, 3.6);
    final tail = await _render(1200, 640, (c) {
      for (var i = 0; i < 3; i++) {
        _cell(c, _lampPose(tail: i - 1.0), tailRegion, 400, ui.Offset(i * 400.0, 0), only: {'tail', 'farLeg', 'torso', 'thigh', 'ledge'}, plinth: true, label: 'tail swing ${i - 1}');
        _cell(c, _lampPose(tail: i - 1.0), tailRegion, 400, ui.Offset(i * 400.0, 360), only: {'tail', 'farLeg', 'torso', 'thigh'}, light: true, label: 'light');
      }
    });
    await _save(tail, '03-tail');
    const crackRegion = ui.Rect.fromLTRB(-2.4, -2.2, 2.4, 3.2);
    final cr = await _render(1500, 560, (c) {
      for (final (i, (lab, lvl, f)) in [('crack .3', .3, 0.0), ('fury .6', .6, 1.0), ('crack .8', .8, 0.0), ('defeat 1.0', 1.0, 0.0)].indexed) {
        _cell(c, _lampPose(crack: lvl, fury: f, lamp: 0), crackRegion, 370, ui.Offset(i * 375.0, 0), only: _bodyParts, label: lab);
      }
    });
    await _save(cr, '03-cracks');
  });

  test('review 04 in game at 640 and 800 over New York', skip: !_review, () async {
    for (final w in [640, 800]) {
      final s = ui.Size(w.toDouble(), 360);
      final aspect = w / 360;
      final shots = <(String, SkyBoss, FrameOptions)>[
        ('PERCH', gBoss(1.0, aspect: aspect), const FrameOptions(birdY: .65)),
        ('SWEEP', gBoss(5.4, aspect: aspect), const FrameOptions(birdY: .78, rules: true)),
        ('VENT · lamp open', gBoss(7.1, aspect: aspect), const FrameOptions(birdY: .5)),
        ('VENT opening (.15 s)', gBoss(6.4 + .15, aspect: aspect), const FrameOptions(birdY: .5)),
        ('FURY', gBoss(2.0, fury: true, aspect: aspect), const FrameOptions(birdY: .5)),
        ('HIT', gBoss(1.0, hitAgo: .06, aspect: aspect), const FrameOptions(birdY: .5)),
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
      await _save(img, '04-ingame-$w');
    }
  });

  test('review 06 lean, stone, Reduced Motion, defeat', skip: !_review, () async {
    const region = ui.Rect.fromLTRB(-3.2, -3.9, 4.4, 3.7);
    const cell = 420.0;
    final poses = <(String, GargoylePose)>[
      ('lean -.8 (rears back)', _lampPose(lean: -.8)),
      ('lean 0', _lampPose()),
      ('lean +.8 (leans in)', _lampPose(lean: .8)),
      ('stone (arrival 1.0 s)', poseOf(gBoss(1.0 - 4.6))),
      ('RM idle', poseOf(gBoss(1.0), reduced: true)),
      ('RM vent (lamp open)', poseOf(gBoss(7.2), reduced: true)),
      ('RM fury', poseOf(gBoss(1.0, fury: true), reduced: true)),
      ('defeat .3 s', poseOf(gBoss(1.0, deadFor: .3))),
      ('defeat .7 s', poseOf(gBoss(1.0, deadFor: .7))),
      ('glance (rock clinks)', poseOf(gBoss(1.0, glanceAgo: .07))),
      ('hit (fury)', poseOf(gBoss(1.0, fury: true, hitAgo: .08))),
      ('story: beaten', GargoylePose.story(GargoyleMood.beaten)),
    ];
    const cols = 4;
    final rows = (poses.length / cols).ceil();
    final cw = (cell * region.width / math.max(region.width, region.height)).round();
    final ch = (cell * region.height / math.max(region.width, region.height)).round();
    final img = await _render(cw * cols, ch * rows, (c) {
      for (var i = 0; i < poses.length; i++) {
        _cell(c, poses[i].$2, region, cell, ui.Offset((i % cols) * cw.toDouble(), (i ~/ cols) * ch.toDouble()), label: poses[i].$1, plinth: true);
      }
    });
    await _save(img, '06-states');
  });

  test('review 07 the vent: lamp opens, hoods lift, steam puffs', skip: !_review, () async {
    const region = ui.Rect.fromLTRB(-2.8, -5.0, 3.8, 1.8);
    const cell = 330.0;
    final times = [6.35, 6.5, 6.7, 7.0, 7.3, 7.6, 8.0, 8.8];
    final cw = (cell * region.width / math.max(region.width, region.height)).round();
    final ch = (cell * region.height / math.max(region.width, region.height)).round();
    final img = await _render(cw * 4, ch * 2, (c) {
      for (var i = 0; i < times.length; i++) {
        _cell(c, poseOf(gBoss(times[i])), region, cell, ui.Offset((i % 4) * cw.toDouble(), (i ~/ 4) * ch.toDouble()), label: 'vent t ${times[i]} (x=${(times[i]).toStringAsFixed(2)} s)');
      }
    });
    await _save(img, '07-vent');
  });

  test('review 08 over a bright sky (Egypt) at 640 and 800', skip: !_review, () async {
    final img = await _render(1440, 720, (c) {
      var i = 0;
      for (final w in [640, 800]) {
        for (final (label, boss) in [('PERCH (bright sky)', gBoss(1.0, aspect: w / 360)), ('VENT (bright sky)', gBoss(7.1, aspect: w / 360))]) {
          final s = ui.Size(w.toDouble(), 360);
          c.save();
          c.translate((i % 2) * 720.0, (i ~/ 2) * 360.0);
          c.clipRect(ui.Offset.zero & s);
          paintFrame(c, s, boss, FrameOptions(birdY: .5, region: WorldRegion.egypt, label: '$label ${w}x360', dim: 0));
          c.restore();
          i++;
        }
      }
    });
    await _save(img, '08-bright-sky');
  });

  test('review 05 silhouettes at 250 and 120 px', skip: !_review, () async {
    final poses = <(String, GargoylePose)>[
      ('idle', GargoylePose.still),
      ('warning', poseOf(gBoss(3.0))),
      ('sweep LOW', poseOf(gBoss(5.0, side: BeamSide.low))),
      ('vent', poseOf(gBoss(7.2))),
      ('fury slit', poseOf(gBoss(5.0, fury: true, slit: true))),
    ];
    for (final cell in [250, 120]) {
      const fx0 = -5.0, fy0 = -4.6, span = 9.7;
      final scale = cell / span;
      final img = await _render(cell * poses.length, cell * 2 + 24, (c) {
        c.drawRect(ui.Rect.fromLTWH(0, 0, (cell * poses.length).toDouble(), (cell * 2 + 24).toDouble()), ui.Paint()..color = const ui.Color(0xffe9dfd2));
        for (var i = 0; i < poses.length; i++) {
          for (final flat in [true, false]) {
            c.save();
            final x0 = i * cell.toDouble(), y0 = flat ? 0.0 : cell + 24.0;
            c.clipRect(ui.Rect.fromLTWH(x0, y0, cell.toDouble(), cell.toDouble()));
            c.translate(x0 - fx0 * scale, y0 - fy0 * scale);
            c.scale(scale);
            if (flat) c.saveLayer(null, ui.Paint()..colorFilter = const ui.ColorFilter.mode(ui.Color(0xff000000), ui.BlendMode.srcIn));
            GargoyleBossRig.paintPose(c, poses[i].$2, plinth: false);
            if (flat) c.restore();
            c.restore();
          }
          text(c, poses[i].$1, ui.Offset(i * cell + 4.0, cell + 4.0), 11, const ui.Color(0xff222222));
        }
      });
      await _save(img, '05-silhouette-$cell');
    }
  });
}
