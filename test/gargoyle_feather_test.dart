// The Searchlight Gargoyle's stone feathers (G6): the feather in flight, the
// top-edge dust telegraph, the glance/thud sparks on the lamp and the shatter.
//
// Review renders (off unless the switch is on):
//   flutter test --dart-define=GARGOYLE_FEATHER_REVIEW=true test/gargoyle_feather_test.dart
// write build/visual-review/gargoyle-feather/.
@Timeout(Duration(minutes: 10))
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart' show HSLColor;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/boss_ammo_art.dart';
import 'package:push_up_bird/game/boss_health_bar_art.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/gargoyle_feather_art.dart';
import 'package:push_up_bird/game/gargoyle_kit.dart';
import 'package:push_up_bird/game/gargoyle_layout.dart';
import 'package:push_up_bird/game/gargoyle_pose.dart';

import 'gargoyle_pilot.dart' as pilot;
import 'proof/counting_canvas.dart';
import 'proof/gargoyle_raster.dart';
import 'proof/gargoyle_stage.dart';

const _review = bool.fromEnvironment('GARGOYLE_FEATHER_REVIEW');
const _outEnv = String.fromEnvironment('GARGOYLE_FEATHER_OUT');
final _out = _outEnv.isEmpty ? 'build/visual-review/gargoyle-feather' : _outEnv;

Future<ui.Image> _render(int w, int h, void Function(ui.Canvas) draw) async {
  final rec = ui.PictureRecorder();
  final c = ui.Canvas(rec)..clipRect(ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()));
  draw(c);
  final pic = rec.endRecording();
  final img = await pic.toImage(w, h);
  pic.dispose();
  return img;
}

Future<void> _save(ui.Image image, String name) async {
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  File('$_out/$name.png')
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(png!.buffer.asUint8List());
}

/// A real feather of the rules, [age] seconds after the launch from a bird at
/// [birdY]: the rules' own launch (`SearchlightGargoyle.featherShot`) integrated
/// the way `FlightSimulation` does.
BossAmmo featherAt(double age, {double birdY = .5, bool fury = false}) {
  final shot = SearchlightGargoyle.featherShot(birdY, enraged: fury);
  final a = BossAmmo(
    x: birdX + SearchlightGargoyle.featherOffsetX,
    y: SearchlightGargoyle.featherY,
    vx: shot.vx,
    vy: shot.vy,
    gravity: SearchlightGargoyle.featherGravity,
    radius: SearchlightGargoyle.featherRadius,
    feather: true,
  );
  const dt = 1 / 240;
  for (var t = 0.0; t < age - 1e-9; t += dt) {
    a.x += a.vx * dt;
    a.vy += a.gravity * dt;
    a.y += a.vy * dt;
  }
  return a;
}

void _text(ui.Canvas c, String s, ui.Offset at, double size, ui.Color col, {bool outline = true}) {
  text(c, s, at, size, col, outline: outline, maxW: 2000);
}



/// One frame as the game will show it: New York's night, the beams and the rig,
/// the feathers in flight, the bird, then the telegraph at the top edge and
/// the sparks on the lamp (G8 calls these from the pose), then the health bar.
void game(
  ui.Canvas c,
  ui.Size s,
  SkyBoss boss, {
  double birdY = .5,
  List<BossAmmo> ammo = const [],
  bool reduced = false,
  bool rules = false,
  String? label,
  double? dustProgress,
  bool entry = true,
}) {
  final pose = poseOf(boss, reduced: reduced);
  paintFrame(c, s, boss, FrameOptions(birdY: birdY, reduced: reduced, ammo: ammo, hud: false, rules: rules));
  final h = s.height;
  final progress = dustProgress ?? pose.dust;
  if (progress > 0) {
    final at = entry ? GargoyleFeatherArt.entryX(birdY, fury: boss.enraged) : GargoyleLayout.birdColumn + SearchlightGargoyle.featherOffsetX;
    GargoyleFeatherArt.dust(c, s, progress, at, reducedMotion: reduced);
  }
  final centre = bossCentre(s, boss);
  final unit = h * SkyBoss.radius;
  if (pose.glance > 0) {
    GargoyleFeatherArt.glance(c, centre, unit, pose.glance, open: pose.lamp, fury: boss.enraged, reducedMotion: reduced);
  }
  if (pose.hit > 0) {
    GargoyleFeatherArt.impact(c, centre, unit, pose.hit, fury: boss.enraged, reducedMotion: reduced);
  }
  BossHealthBarArt.paint(c, s, boss, reducedMotion: reduced);
  // The HUD hook (recommended): the feathers the bar would hide are drawn again over it.
  GargoyleFeatherArt.overBar(c, s, ammo, boss, reducedMotion: reduced);
  if (label != null) _text(c, label, ui.Offset(8, h - 20), 11, const ui.Color(0xffffffff));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(family)..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
  });

  group('review renders', () {
    test('01 close-ups: the feather on light, dark and lit-window backdrops', skip: !_review, () async {
      const backs = <(String, ui.Color, ui.Color)>[
        ('night sky', ui.Color(0xff171c39), ui.Color(0xff2a3160)),
        ('lit window', ui.Color(0xffffd27a), ui.Color(0xffffb35a)),
        ('pale sky', ui.Color(0xffbfe3f0), ui.Color(0xfff2f0d8)),
        ('moonlit cloud', ui.Color(0xff6f7aa8), ui.Color(0xff9aa3cc)),
      ];
      // Native 4x (the feather's radius 40 px) along the real lob of a bird at .5.
      const ages = [.1, .3, .55, .8, 1.05, 1.3, 1.55];
      final img = await _render(1500, 4 * 190, (c) {
        for (var b = 0; b < backs.length; b++) {
          final (name, top, bottom) = backs[b];
          final box = ui.Rect.fromLTWH(0, b * 190.0, 1500, 190);
          c.drawRect(box, ui.Paint()..shader = ui.Gradient.linear(box.topCenter, box.bottomCenter, [top, bottom]));
          _text(c, name, ui.Offset(6, b * 190.0 + 4), 12, const ui.Color(0xffffffff));
          for (var i = 0; i < ages.length; i++) {
            c.save();
            c.translate(i * 205.0 + 150, b * 190.0 + 95);
            final a = featherAt(ages[i]);
            const h = 1440.0;
            c.translate(-a.x * h, -a.y * h);
            GargoyleFeatherArt.paint(c, h, a, seconds: 1);
            c.restore();
          }
        }
      });
      await _save(img, '01-closeups');
    });


    test('03 the tumble in frames (real size, blown up 5x)', skip: !_review, () async {
      const w = 640, h = 360;
      final s = ui.Size(w.toDouble(), h.toDouble());
      // The same instant of the lob every 1/30 s for 12 frames, on the night and over a lit window.
      final strip = await _render(12 * 100, 2 * 100, (c) {
        for (var row = 0; row < 2; row++) {
          for (var i = 0; i < 12; i++) {
            final a = featherAt(1.0 + i / 30, birdY: .6);
            c.save();
            c.translate(i * 100.0, row * 100.0);
            c.clipRect(const ui.Rect.fromLTWH(0, 0, 100, 100));
            c.drawRect(const ui.Rect.fromLTWH(0, 0, 100, 100), ui.Paint()..color = row == 0 ? const ui.Color(0xff222a55) : const ui.Color(0xffffd27a));
            c.translate(50 - a.x * h, 50 - a.y * h);
            GargoyleFeatherArt.paint(c, h.toDouble(), a);
            c.restore();
          }
        }
      });
      await _save(strip, '03-tumble-strip');
      expect(s.width, w);
    });

    test('06 a fall in three lanes: feathers falling toward a low, middle and high bird (640 and 800)', skip: !_review, () async {
      for (final w in [640, 800]) {
        final s = ui.Size(w.toDouble(), 360);
        final aspect = w / 360;
        final img = await _render(w, 360 * 3, (c) {
          for (var i = 0; i < 3; i++) {
            final birdY = const [.22, .52, .84][i];
            c.save();
            c.translate(0, i * 360.0);
            c.clipRect(ui.Offset.zero & s);
            // Combat 4.9: the feather launched at 4.6 is .3 s old; the three on screen are a calm one at three ages.
            final boss = gBoss(5.05, aspect: aspect);
            game(c, s, boss, birdY: birdY, ammo: [for (final age in const [.35, .75, 1.15, 1.55]) featherAt(age, birdY: birdY)],
                label: 'bird at $birdY: a feather at .35 s, .75 s, 1.15 s and 1.55 s of its fall (one launch at four moments)');
            c.restore();
          }
        });
        await _save(img, '06-fall-$w');
      }
    });

    test('07 fury: two feathers over the beam, 640 and 800', skip: !_review, () async {
      final img = await _render(640 + 800, 360 * 2, (c) {
        for (var i = 0; i < 2; i++) {
          final w = i == 0 ? 640.0 : 800.0;
          final s = ui.Size(w, 360);
          final aspect = w / 360;
          c.save();
          c.translate(i == 0 ? 0 : 640.0, 0);
          c.clipRect(ui.Offset.zero & s);
          game(c, s, gBoss(5.5, aspect: aspect, fury: true), birdY: .62, rules: false,
              ammo: [featherAt(1.15, birdY: .3, fury: true), featherAt(.5, birdY: .62, fury: true)], label: 'FURY ${w.toInt()}: two feathers over the sweep (hot frame, ember wake)');
          c.restore();
          c.save();
          c.translate(i == 0 ? 0 : 640.0, 360);
          c.clipRect(ui.Offset.zero & s);
          game(c, s, gBoss(5.5, aspect: aspect, fury: true), birdY: .62, reduced: true,
              ammo: [featherAt(1.15, birdY: .3, fury: true), featherAt(.5, birdY: .62, fury: true)], label: 'REDUCED MOTION ${w.toInt()}: the same moment, no tumble, one still frame');
          c.restore();
        }
      });
      await _save(img, '07-fury-reduced');
    });

    test('08 close-ups: calm, fury and Reduced Motion on dark and light (native 5x)', skip: !_review, () async {
      const kinds = [('calm', false, false), ('fury', true, false), ('Reduced Motion', false, true), ('fury, R.M.', true, true)];
      final img = await _render(4 * 300, 2 * 280, (c) {
        for (var row = 0; row < 2; row++) {
          for (var k = 0; k < kinds.length; k++) {
            final (name, fury, still) = kinds[k];
            c.save();
            c.translate(k * 300.0, row * 280.0);
            c.clipRect(const ui.Rect.fromLTWH(0, 0, 300, 280));
            c.drawRect(const ui.Rect.fromLTWH(0, 0, 300, 280), ui.Paint()..color = row == 0 ? const ui.Color(0xff1f2446) : const ui.Color(0xffe9dfc9));
            const h = 1800.0; // r = 50 px
            final a = featherAt(1.3, birdY: .55, fury: fury);
            c.translate(190 - a.x * h, 150 - a.y * h);
            GargoyleFeatherArt.paint(c, h, a, seconds: 1, reducedMotion: still, fury: fury);
            c.restore();
            _text(c, '$name · ${row == 0 ? 'night' : 'pale'}', ui.Offset(k * 300.0 + 6, row * 280.0 + 258), 12, row == 0 ? const ui.Color(0xffffffff) : const ui.Color(0xff222222), outline: row == 0);
          }
        }
      });
      await _save(img, '08-closeups-states');
    });

    test('02 in-game frames at 640 and 800 over New York', skip: !_review, () async {
      for (final w in [640, 800]) {
        final s = ui.Size(w.toDouble(), 360);
        final aspect = w / 360;
        BossAmmo f(double age, {double birdY = .5, bool fury = false}) => featherAt(age, birdY: birdY, fury: fury);
        final shots = <(String, SkyBoss, double, List<BossAmmo>, bool)>[
          ('PERCH: the dust at the top edge where the next feather will drop (bird .7)', gBoss(4.45, aspect: aspect), .7, [], false),
          ('a feather falls, aimed at the bird (calm, age .5 s, bird .6)', gBoss(5.1, aspect: aspect), .6, [f(.5, birdY: .6)], false),
          ('the same feather later (age 1.2 s): it crosses the bird\'s column', gBoss(5.8, aspect: aspect), .6, [f(1.2, birdY: .6)], false),
          ('FURY: two feathers over the beam (ages 1.0 and .3)', gBoss(5.5, aspect: aspect, fury: true), .3, [f(1.0, birdY: .3, fury: true), f(.3, birdY: .3, fury: true)], true),
          ('a rock clinks off the SHUT lamp (brass sparks)', gBoss(2.6, aspect: aspect, glanceAgo: .05), .5, [], false),
          ('a rock thuds on the OPEN lamp (no sparks)', gBoss(7.0, aspect: aspect, hitAgo: .06), .5, [], false),
        ];
        final img = await _render(w * 2, 360 * 3, (c) {
          for (var i = 0; i < shots.length; i++) {
            c.save();
            c.translate((i % 2) * s.width, (i ~/ 2) * s.height);
            c.clipRect(ui.Offset.zero & s);
            game(c, s, shots[i].$2, birdY: shots[i].$3, ammo: shots[i].$4, rules: shots[i].$5, label: shots[i].$1);
            c.restore();
          }
        });
        await _save(img, w == 640 ? '02-ingame-640' : '02-ingame-800');
      }
    });
    test('04 the dust telegraph at the top edge, 640 and 800 (3x)', skip: !_review, () async {
      const steps = [.12, .3, .5, .7, .85, .98];
      final img = await _render(6 * 330, 2 * 330 + 40, (c) {
        for (var row = 0; row < 2; row++) {
          final w = row == 0 ? 640.0 : 800.0;
          final s = ui.Size(w, 360);
          final boss = gBoss(4.4, aspect: w / 360);
          for (var i = 0; i < steps.length; i++) {
            c.save();
            c.translate(i * 330.0, row * 330.0);
            c.clipRect(const ui.Rect.fromLTWH(0, 0, 330, 330));
            // The frame rendered at 3x scale about the entry column's top edge.
            final at = GargoyleFeatherArt.entryX(.7) * 360;
            c.scale(3);
            c.translate(-(at - 55), 0);
            game(c, s, boss, birdY: .7, dustProgress: steps[i], rules: false);
            c.restore();
            _text(c, 'progress ${steps[i]} · ${w.toInt()} wide', ui.Offset(i * 330.0 + 6, row * 330.0 + 310), 12, const ui.Color(0xffffffff));
          }
        }
      });
      await _save(img, '04-dust-strip');
    });

    test('05 the clink and the thud on the lamp (3x)', skip: !_review, () async {
      const ages = [.01, .04, .075, .11, .14];
      final img = await _render(5 * 300, 2 * 300, (c) {
        const s = ui.Size(640, 360);
        for (var row = 0; row < 2; row++) {
          for (var i = 0; i < ages.length; i++) {
            c.save();
            c.translate(i * 300.0, row * 300.0);
            c.clipRect(const ui.Rect.fromLTWH(0, 0, 300, 300));
            final boss = row == 0 ? gBoss(2.6, glanceAgo: ages[i]) : gBoss(7.0, hitAgo: ages[i]);
            c.scale(3);
            c.translate(-(boss.x * 360 - 70), -(180.0 - 50));
            game(c, s, boss);
            c.restore();
            _text(c, '${row == 0 ? 'clink (shut)' : 'thud (open)'} +${(ages[i] * 1000).round()} ms', ui.Offset(i * 300.0 + 6, row * 300.0 + 280), 12, const ui.Color(0xffffffff));
          }
        }
      });
      await _save(img, '05-lamp-sparks');
    });

  });

  group('the promises', () {
    BossAmmo shot({double x = .5, double y = .5, double vx = -.36, double vy = 0, double? radius, double gravity = .30}) =>
        BossAmmo(x: x, y: y, vx: vx, vy: vy, gravity: gravity, radius: radius ?? SearchlightGargoyle.featherRadius, feather: true);

    /// The feather's body alone (the hook's unit-space draw) at [h], solid pixels.
    Future<Mask> body(double h, {BossAmmo? ammo, bool fury = false}) {
      final a = ammo ?? shot();
      return rasterize(
        (c) => BossAmmoArt.paint(
          c,
          center: ui.Offset(a.x * h, a.y * h),
          radius: a.radius * h,
          direction: math.atan2(a.vy, a.vx),
          attack: EnemyAttack.none,
          kind: BossKind.searchlightGargoyle,
          enraged: fury,
          seconds: 3,
          reducedMotion: true,
          showTrail: false,
        ),
        ppu: 1,
        region: ui.Rect.fromLTWH(0, 0, h, h),
        solid: 200,
      );
    }

    double lum(Mask m, int x, int y) {
      final i = (y * m.w + x) * 4;
      return .2126 * m.data[i] + .7152 * m.data[i + 1] + .0722 * m.data[i + 2];
    }

    test('the style: the Gargoyle has his own, never the pellet nor another boss\'s', () {
      expect(BossAmmoArt.styleFor(BossKind.searchlightGargoyle), BossAmmoStyle.stoneFeather);
      for (final k in BossKind.values) {
        if (k == BossKind.searchlightGargoyle) continue;
        expect(BossAmmoArt.styleFor(k), isNot(BossAmmoStyle.stoneFeather), reason: '$k');
      }
    });

    testWidgets('the solid body ends exactly on the hit circle at two screen heights, ink ring on it', (tester) async {
      await tester.runAsync(() async {
        for (final h in const [360.0, 1440.0]) {
          final a = shot();
          final m = await body(h, ammo: a);
          final r = a.radius * h;
          final cx = a.x * h, cy = a.y * h;
          // The farthest solid pixel from the centre lies on the circle, and none is beyond it.
          var far = 0.0;
          var area = 0, inDisc = 0;
          for (var y = 0; y < m.h; y++) {
            for (var x = 0; x < m.w; x++) {
              if (!m.at(x, y)) continue;
              final d = math.sqrt(math.pow(x + .5 - cx, 2) + math.pow(y + .5 - cy, 2));
              far = math.max(far, d);
              area++;
              if (d <= r) inDisc++;
            }
          }
          expect(far, inInclusiveRange(r - .8, r + .5), reason: 'h $h: the solid body reaches $far px, the hit radius is $r');
          expect(inDisc / area, greaterThan(.98), reason: 'h $h: nothing solid outside the circle');
          // It fills a good part of the circle (not a sliver, not a ball).
          final fill = area / (math.pi * r * r);
          expect(fill, inInclusiveRange(.42, .8), reason: 'h $h: fills $fill of the hit disc');
          // The tip points left along the velocity; its ink ring's outer edge is the circle.
          var tip = 0;
          while (tip < r + 3 && !(m.at((cx - 1 - tip).floor(), cy.floor()) && lum(m, (cx - 1 - tip).floor(), cy.floor()) < 70)) {
            tip++;
          }
          // Walk outward from the tip's outer side: the outermost ink pixel on the axis.
          var edge = (r + 3).floor();
          while (edge > 0 && !(m.at((cx - 1 - edge).floor(), cy.floor()) && lum(m, (cx - 1 - edge).floor(), cy.floor()) < 70)) {
            edge--;
          }
          expect(edge + 1.0, closeTo(r, .8), reason: 'h $h: the ink ring ends at ${edge + 1.0}, the circle at $r');
          expect(GargoyleFeatherArt.bodyRadius(a, h), closeTo(r, 1e-9));
        }
      });
    });

    testWidgets('with its wake: nothing SOLID is ever outside the hit circle, in any look and at any age', (tester) async {
      await tester.runAsync(() async {
        for (final h in const [360.0, 720.0]) {
          for (final fury in [false, true]) {
            for (final still in [false, true]) {
              for (final (age, birdY) in const [(1.0, .5), (1.4, .2), (.7, .8), (1.65, .5)]) {
                final a = featherAt(age, birdY: birdY, fury: fury);
                final m = await rasterize(
                  (c) => GargoyleFeatherArt.paint(c, h, a, reducedMotion: still, fury: fury),
                  ppu: 1,
                  region: ui.Rect.fromLTWH(0, 0, h * 1.2, h),
                  solid: 200,
                );
                final r = a.radius * h;
                var far = 0.0;
                for (var y = 0; y < m.h; y++) {
                  for (var x = 0; x < m.w; x++) {
                    if (!m.at(x, y)) continue;
                    far = math.max(far, math.sqrt(math.pow(x + .5 - a.x * h, 2) + math.pow(y + .5 - a.y * h, 2)));
                  }
                }
                expect(far, lessThanOrEqualTo(r + .6), reason: 'h $h fury $fury still $still age $age: solid reaches $far, hit radius $r');
                expect(far, greaterThanOrEqualTo(r - 1.2));
              }
            }
          }
        }
      });
    });

    testWidgets('it points along its velocity, in every direction a feather goes', (tester) async {
      await tester.runAsync(() async {
        const h = 720.0;
        for (final (vx, vy) in const [(-.36, 0.0), (-.36, .5), (-.36, -.3), (-.44, .7), (-.1, .9)]) {
          final a = shot(vx: vx, vy: vy);
          final m = await body(h, ammo: a);
          final dir = math.atan2(vy, vx);
          final d = ui.Offset(math.cos(dir), math.sin(dir));
          var ahead = 0.0, behind = 0.0, side = 0.0;
          for (var y = 0; y < m.h; y++) {
            for (var x = 0; x < m.w; x++) {
              if (!m.at(x, y)) continue;
              final p = ui.Offset(x + .5 - a.x * h, y + .5 - a.y * h);
              ahead = math.max(ahead, p.dx * d.dx + p.dy * d.dy);
              behind = math.max(behind, -(p.dx * d.dx + p.dy * d.dy));
              side = math.max(side, (p.dx * -d.dy + p.dy * d.dx).abs());
            }
          }
          final r = a.radius * h;
          // The kite point leads on the circle; the tail's points trail at .8 and the flanks stand .6 off.
          expect(ahead / r, closeTo(1, .05), reason: 'v ($vx,$vy)');
          expect(behind / r, closeTo(.8, .06), reason: 'v ($vx,$vy)');
          expect(side / r, closeTo(.6, .07), reason: 'v ($vx,$vy)');
        }
      });
    });

    test('age: worked out from where it is, exact for a feather the rules launched', () {
      final a = featherAt(0);
      expect(GargoyleFeatherArt.age(a), 0);
      for (final t in const [.1, .5, 1.0, 1.7]) {
        expect(GargoyleFeatherArt.age(featherAt(t)), closeTo(t, 1e-6), reason: 't $t');
        expect(GargoyleFeatherArt.age(featherAt(t, fury: true, birdY: .2)), closeTo(t, 1e-6));
      }
      for (final bad in [double.nan, double.infinity]) {
        expect(GargoyleFeatherArt.age(shot(x: bad)), 0);
        expect(GargoyleFeatherArt.age(shot(vx: bad)), 0);
      }
      expect(GargoyleFeatherArt.age(shot(vx: 0)), 0);
      expect(GargoyleFeatherArt.age(shot(x: 3)), 0, reason: 'never negative');
    });

    test('the wake runs on the feather\'s true path and bends with the lob', () {
      for (final birdY in const [.1, .5, .9]) {
        for (final fury in [false, true]) {
          final now = featherAt(1.0, birdY: birdY, fury: fury);
          for (final tau in const [.05, .2, .4]) {
            final then = featherAt(1.0 - tau, birdY: birdY, fury: fury);
            final back = GargoyleFeatherArt.trailAt(now, tau);
            expect(then.x - now.x, closeTo(back.dx, 2e-3), reason: 'x, bird $birdY fury $fury tau $tau');
            expect(then.y - now.y, closeTo(back.dy, 2e-3), reason: 'y, bird $birdY fury $fury tau $tau');
          }
        }
      }
      // Once it is falling the wake points up and to the right: the aim line.
      final falling = featherAt(1.4, birdY: .8);
      expect(falling.vy, greaterThan(0));
      final back = GargoyleFeatherArt.trailAt(falling, .3);
      expect(back.dx, greaterThan(0));
      expect(back.dy, lessThan(0));
    });

    test('entryX is where a real feather first shows under the top edge', () {
      for (final fury in [false, true]) {
        for (final birdY in const [0.0, .1, .3, .5, .7, .9, 1.0]) {
          final a = featherAt(0, birdY: birdY, fury: fury);
          var t = 0.0;
          while (a.y + a.radius < 0 && t < 3) {
            a.x += a.vx / 240;
            a.vy += a.gravity / 240;
            a.y += a.vy / 240;
            t += 1 / 240;
          }
          expect(GargoyleFeatherArt.entryX(birdY, fury: fury), closeTo(a.x, .004), reason: 'bird $birdY fury $fury');
          expect(GargoyleFeatherArt.entryX(birdY, fury: fury), lessThan(GargoyleLayout.birdColumn + SearchlightGargoyle.featherOffsetX + 1e-9));
          expect(GargoyleFeatherArt.entryX(birdY, fury: fury), greaterThan(GargoyleLayout.birdColumn), reason: 'always right of the bird');
        }
      }
      expect(GargoyleFeatherArt.entryX(double.nan), GargoyleLayout.birdColumn + SearchlightGargoyle.featherOffsetX);
    });

    test('no piece asks for more than its budget: a feather is 8 draw ops, three are 24', () {
      final before = GargoyleKit.shadersBuilt;
      var worst = 0, worstThree = 0;
      for (final h in const [300.0, 360.0, 480.0, 720.0]) {
        for (final fury in [false, true]) {
          for (final still in [false, true]) {
            for (final birdY in const [.05, .3, .6, .95]) {
              final all = <BossAmmo>[for (final age in const [.15, .6, 1.1, 1.6]) featherAt(age, birdY: birdY, fury: fury)];
              for (final a in all) {
                final c = Counting(ui.Canvas(ui.PictureRecorder()));
                GargoyleFeatherArt.paint(c, h, a, seconds: 3.3, reducedMotion: still, fury: fury);
                expect(c.layers + c.blurs + c.shaderDraws, 0, reason: '${c.counts}');
                expect(c.counts.keys.where((k) => k.startsWith('UNFORWARDED')), isEmpty, reason: '${c.counts}');
                expect(c.draws, lessThanOrEqualTo(GargoyleFeatherArt.opsPerFeather), reason: 'h $h fury $fury still $still bird $birdY: ${c.counts}');
                expect(c.clips, 0);
                worst = math.max(worst, c.draws);
              }
              final three = Counting(ui.Canvas(ui.PictureRecorder()));
              for (final a in all.take(3)) {
                GargoyleFeatherArt.paint(three, h, a, seconds: 3.3, reducedMotion: still, fury: fury);
              }
              expect(three.draws, lessThanOrEqualTo(24), reason: '${three.counts}');
              worstThree = math.max(worstThree, three.draws);
            }
          }
        }
      }
      expect(GargoyleKit.shadersBuilt, before, reason: 'no shader is ever built');
      // ignore: avoid_print
      print('feather: worst $worst ops each (budget 14), three at most $worstThree (budget 24), 0 shaders, 0 layers, 0 blur');
      // The telegraph, the clink, the thud and the shatter.
      var dustWorst = 0, glanceWorst = 0, thudWorst = 0, shatterWorst = 0;
      for (var i = 0; i <= 100; i++) {
        final u = i / 100;
        final d = Counting(ui.Canvas(ui.PictureRecorder()));
        GargoyleFeatherArt.dust(d, const ui.Size(640, 360), u, .9);
        dustWorst = math.max(dustWorst, d.draws);
        final g = Counting(ui.Canvas(ui.PictureRecorder()));
        GargoyleFeatherArt.glance(g, const ui.Offset(460, 180), 41.4, u);
        glanceWorst = math.max(glanceWorst, g.draws);
        final t = Counting(ui.Canvas(ui.PictureRecorder()));
        GargoyleFeatherArt.glance(t, const ui.Offset(460, 180), 41.4, u, open: 1, fury: i.isOdd);
        thudWorst = math.max(thudWorst, t.draws);
        final s = Counting(ui.Canvas(ui.PictureRecorder()));
        GargoyleFeatherArt.shatter(s, const ui.Offset(200, 200), 10, u * .4, fury: i.isOdd);
        shatterWorst = math.max(shatterWorst, s.draws);
        for (final c in [d, g, t, s]) {
          expect(c.layers + c.blurs + c.shaderDraws, 0);
        }
      }
      // ignore: avoid_print
      print('dust worst $dustWorst ops, clink $glanceWorst, thud $thudWorst, shatter $shatterWorst (each budget 8)');
      for (final n in [dustWorst, glanceWorst, thudWorst, shatterWorst]) {
        expect(n, inInclusiveRange(1, 8));
      }
    });

    test('cost: three feathers, their wakes and a telegraph record in well under a millisecond', () {
      final three = [featherAt(.4, birdY: .3, fury: true), featherAt(.9, birdY: .5, fury: true), featherAt(1.4, birdY: .7, fury: true)];
      void frame() {
        final c = ui.Canvas(ui.PictureRecorder());
        for (final a in three) {
          GargoyleFeatherArt.paint(c, 360, a, seconds: 3, fury: true);
        }
        GargoyleFeatherArt.dust(c, const ui.Size(640, 360), .6, .9);
      }

      for (var i = 0; i < 300; i++) {
        frame();
      }
      final watch = Stopwatch()..start();
      const n = 3000;
      for (var i = 0; i < n; i++) {
        frame();
      }
      final us = watch.elapsedMicroseconds / n;
      // ignore: avoid_print
      print('three feathers + dust: ${us.toStringAsFixed(1)} us per frame to record (debug JIT; AOT is several times faster)');
      expect(us, lessThan(1500));
    });

    Future<Uint8List> pixels(void Function(ui.Canvas) draw, {int w = 640, int h = 360, ui.Color bg = const ui.Color(0xff202448)}) async {
      final img = await _render(w, h, (c) {
        c.drawRect(ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()), ui.Paint()..color = bg);
        draw(c);
      });
      final data = (await img.toByteData())!.buffer.asUint8List();
      img.dispose();
      return data;
    }

    testWidgets('determinism: a pure function of the shot; Reduced Motion is one still frame', (tester) async {
      await tester.runAsync(() async {
        for (final fury in [false, true]) {
          final a = featherAt(.9, birdY: .4, fury: fury);
          final live = await pixels((c) => GargoyleFeatherArt.paint(c, 360, a, seconds: 1.0, fury: fury));
          // The clock is the shot's own age, not the simulation's.
          expect(await pixels((c) => GargoyleFeatherArt.paint(c, 360, a, seconds: 1.0, fury: fury)), live);
          expect(await pixels((c) => GargoyleFeatherArt.paint(c, 360, a, seconds: 77.7, fury: fury)), live, reason: 'independent of the clock');
          // Order-independent: a flood of other feathers first changes nothing.
          await pixels((c) {
            for (var i = 0; i < 50; i++) {
              GargoyleFeatherArt.paint(c, 360, featherAt(i / 30, birdY: i / 50, fury: i.isOdd), seconds: i * .1, reducedMotion: i % 3 == 0, fury: i.isOdd);
            }
          });
          expect(await pixels((c) => GargoyleFeatherArt.paint(c, 360, a, seconds: 1.0, fury: fury)), live);
          final still = await pixels((c) => GargoyleFeatherArt.paint(c, 360, a, seconds: 1.0, reducedMotion: true, fury: fury));
          expect(await pixels((c) => GargoyleFeatherArt.paint(c, 360, a, seconds: 9.9, reducedMotion: true, fury: fury)), still);
          expect(still, isNot(live), reason: 'the live feather tumbles, the still one does not');
        }
        // Tumbling: different ages are different frames; the age function is smooth.
        var last = 0.0;
        for (var i = 0; i < 40; i++) {
          final f = GargoyleFeatherArt.tumble(i / 60, 1.3);
          if (i > 0) expect((f - last).abs(), lessThan(.12), reason: 'no jump between frames');
          last = f;
        }
        expect(GargoyleFeatherArt.tumble(0, 0), 0);
        expect(GargoyleFeatherArt.tumble(1.2, .7).abs(), lessThanOrEqualTo(GargoyleFeatherArt.rockAmplitude));
      });
    });

    testWidgets('the hook: the Gargoyle\'s shots are his feathers, any other boss\'s are not', (tester) async {
      await tester.runAsync(() async {
        final a = featherAt(1.0, birdY: .6);
        SkyBoss boss(BossKind kind, {bool fury = false}) {
          final b = SkyBoss(number: 6, x: 1.2, kind: kind, cinematic: true);
          b.age = b.arrivalDuration + 5;
          if (fury) b.hp = b.maxHp ~/ 2 - 10;
          return b;
        }

        for (final fury in [false, true]) {
          final viaHook = await pixels((c) => BossAmmoArt.shot(c, 360, a, boss(BossKind.searchlightGargoyle, fury: fury), seconds: 5, reducedMotion: false));
          final direct = await pixels((c) => GargoyleFeatherArt.paint(c, 360, a, seconds: 5, fury: fury));
          expect(viaHook, direct, reason: 'the hook IS the feather (fury $fury)');
        }
        final coo = await pixels((c) => BossAmmoArt.shot(c, 360, a, boss(BossKind.kingCoo), seconds: 5, reducedMotion: false));
        final gar = await pixels((c) => BossAmmoArt.shot(c, 360, a, boss(BossKind.searchlightGargoyle), seconds: 5, reducedMotion: false));
        expect(gar, isNot(coo));
        // The muzzle/portrait path draws the same body, without a wake.
        final unit = await pixels((c) => BossAmmoArt.paint(c, center: const ui.Offset(300, 180), radius: 30, direction: math.pi, attack: EnemyAttack.none, kind: BossKind.searchlightGargoyle, seconds: 0, reducedMotion: true));
        final other = await pixels((c) => BossAmmoArt.paint(c, center: const ui.Offset(300, 180), radius: 30, direction: math.pi, attack: EnemyAttack.none, kind: BossKind.baronBat, seconds: 0, reducedMotion: true));
        expect(unit, isNot(other));
      });
    });

    testWidgets('it is a cream and steel dart: not round and not the colour of any other boss\'s shot', (tester) async {
      await tester.runAsync(() async {
        const h = 600.0;
        Future<({double fill, double sat, double light})> look(BossKind kind) async {
          final m = await rasterize(
            (c) => BossAmmoArt.paint(c, center: const ui.Offset(150, 150), radius: 60, direction: math.pi, attack: EnemyAttack.none, kind: kind, seconds: 0, reducedMotion: true, showTrail: false),
            ppu: 1,
            region: const ui.Rect.fromLTWH(0, 0, 300, 300),
            solid: 200,
          );
          var n = 0, inside = 0;
          var sat = 0.0, light = 0.0;
          for (var y = 0; y < m.h; y++) {
            for (var x = 0; x < m.w; x++) {
              if (!m.at(x, y)) continue;
              if (math.sqrt(math.pow(x + .5 - 150, 2) + math.pow(y + .5 - 150, 2)) <= 60) inside++;
              final i = (y * m.w + x) * 4;
              final hsl = HSLColor.fromColor(ui.Color.fromARGB(255, m.data[i], m.data[i + 1], m.data[i + 2]));
              // The ink ring is every shot's own; judge the colour of what is inside it.
              if (hsl.lightness < .18) continue;
              sat += hsl.saturation;
              light += hsl.lightness;
              n++;
            }
          }
          return (fill: inside / (math.pi * 3600), sat: sat / n, light: light / n);
        }

        final mine = await look(BossKind.searchlightGargoyle);
        // ignore: avoid_print
        print('feather: fills ${mine.fill.toStringAsFixed(2)} of its hit disc, mean saturation ${mine.sat.toStringAsFixed(2)}, lightness ${mine.light.toStringAsFixed(2)}');
        expect(h, greaterThan(0));
        for (final k in [BossKind.baronBat, BossKind.spitterBeetle, BossKind.duskMoth, BossKind.pirate, BossKind.dragon]) {
          final o = await look(k);
          // ignore: avoid_print
          print('  vs $k: fills ${o.fill.toStringAsFixed(2)}, saturation ${o.sat.toStringAsFixed(2)}, lightness ${o.light.toStringAsFixed(2)}');
          expect(mine.fill, lessThan(o.fill - .1), reason: 'every other shot is a round body; the feather is the only one that is not ($k)');
          final apart = (mine.sat - o.sat).abs() + (mine.light - o.light).abs();
          expect(apart, greaterThan(.1), reason: '$k: a different colour');
        }
        expect(mine.light, greaterThan(.55), reason: 'a pale shot on a navy night');
      });
    });

    testWidgets('readable: bright body, dark ring, over New York\'s night and over a lit window and the amber beam', (tester) async {
      await tester.runAsync(() async {
        final a = featherAt(1.1, birdY: .55);
        for (final (name, bg) in const [
          ('night', ui.Color(0xff1f2446)),
          ('lit window', ui.Color(0xffffd27a)),
          ('amber beam', ui.Color(0xffd9b98a)),
        ]) {
          final px = await pixels((c) => GargoyleFeatherArt.paint(c, 360, a, reducedMotion: true), bg: bg);
          final cx = (a.x * 360).round(), cy = (a.y * 360).round();
          // The ring is a dark line around the body wherever the body meets the backdrop: some
          // pixel near the centre is the cream vane, and the ring (ink) is darker than every backdrop.
          var ink = 0, cream = 0;
          for (var y = cy - 14; y <= cy + 14; y++) {
            for (var x = cx - 14; x <= cx + 14; x++) {
              final i = (y * 640 + x) * 4;
              final l = .2126 * px[i] + .7152 * px[i + 1] + .0722 * px[i + 2];
              if (l < 45) ink++;
              if (px[i] > 235 && px[i + 1] > 225 && px[i + 2] > 200) cream++;
            }
          }
          expect(ink, greaterThan(25), reason: '$name: the ink ring');
          expect(cream, greaterThan(8), reason: '$name: the cream vane');
        }
      });
    });

    testWidgets('dust: where and how it falls, never over the bird', (tester) async {
      await tester.runAsync(() async {
        const size = ui.Size(640, 360);
        for (final birdY in const [.1, .5, .9]) {
          final at = GargoyleFeatherArt.entryX(birdY);
          for (final u in const [.1, .4, .7, .95, 1.0]) {
            final px = await pixels((c) => GargoyleFeatherArt.dust(c, size, u, at), bg: const ui.Color(0x00000000));
            var minX = 640, maxX = -1, minY = 360, maxY = -1;
            for (var y = 0; y < 360; y++) {
              for (var x = 0; x < 640; x++) {
                if (px[(y * 640 + x) * 4 + 3] < 8) continue;
                minX = math.min(minX, x);
                maxX = math.max(maxX, x);
                minY = math.min(minY, y);
                maxY = math.max(maxY, y);
              }
            }
            expect(maxX, greaterThan(-1), reason: 'bird $birdY progress $u draws');
            // Under the health bar's strip, a few heights deep, a column wide, nowhere near the bird.
            final strip = BossHealthBarArt.bounds(size, gBoss(1));
            expect(minY, greaterThanOrEqualTo((strip.bottom - 4).floor()), reason: 'below the health bar strip ${strip.bottom}');
            expect(maxY, lessThan(.42 * 360));
            expect(minX, greaterThan(at * 360 - .1 * 360));
            expect(maxX, lessThan(at * 360 + .1 * 360));
            final bird = ui.Rect.fromCircle(center: ui.Offset(GargoyleLayout.birdColumn * 360, birdY * 360), radius: 1.7 * GargoyleLayout.birdRadius * 360);
            expect(bird.overlaps(ui.Rect.fromLTRB(minX.toDouble(), minY.toDouble(), maxX + 1.0, maxY + 1.0)), isFalse, reason: 'bird $birdY progress $u: the bird stays clear');
          }
        }
        // Nothing before the telegraph, nothing under Reduced Motion, a glint only in its last quarter.
        final none = Counting(ui.Canvas(ui.PictureRecorder()));
        GargoyleFeatherArt.dust(none, size, 0, .9);
        GargoyleFeatherArt.dust(none, size, -1, .9);
        GargoyleFeatherArt.dust(none, size, .6, .9, reducedMotion: true);
        expect(none.draws, 0);
        final early = Counting(ui.Canvas(ui.PictureRecorder()))..counts.clear();
        GargoyleFeatherArt.dust(early, size, .5, .9);
        final late = Counting(ui.Canvas(ui.PictureRecorder()));
        GargoyleFeatherArt.dust(late, size, .95, .9);
        expect(late.draws, greaterThan(early.draws), reason: 'the glint comes last');
      });
    });


    testWidgets('over the bar: a feather that touches the health bar\'s strip is drawn over it, nothing else is', (tester) async {
      await tester.runAsync(() async {
        const size = ui.Size(640, 360);
        final boss = gBoss(5.0);
        final strip = BossHealthBarArt.bounds(size, boss);
        // A feather in the strip, one far below it, one off the strip's side.
        final inStrip = shot(x: (strip.center.dx) / 360, y: strip.center.dy / 360, vy: .1);
        final below = shot(x: .8, y: .6, vy: .4);
        final beside = shot(x: (strip.right + 60) / 360, y: strip.center.dy / 360, vy: .1);
        Counting count(Iterable<BossAmmo> a, SkyBoss b) {
          final c = Counting(ui.Canvas(ui.PictureRecorder()));
          GargoyleFeatherArt.overBar(c, size, a, b);
          return c;
        }

        expect(count([inStrip], boss).draws, GargoyleFeatherArt.opsPerFeather);
        expect(count([below, beside], boss).draws, 0);
        expect(count([inStrip, below, beside], boss).draws, GargoyleFeatherArt.opsPerFeather, reason: 'only the one that touches the strip');
        // Half in: a feather whose body just touches the strip's lower edge counts.
        expect(count([shot(x: strip.center.dx / 360, y: (strip.bottom + 6) / 360)], boss).draws, GargoyleFeatherArt.opsPerFeather);
        // The cutscenes hide the bar: nothing is drawn over it. A boss that is not the Gargoyle: nothing.
        final arriving = gBoss(-3.0);
        expect(arriving.inCutscene, isTrue);
        expect(count([inStrip], arriving).draws, 0);
        final other = SkyBoss(number: 6, x: 1, kind: BossKind.dragon, cinematic: true)..age = 20;
        expect(count([inStrip], other).draws, 0);
        // Drawn over a plain backdrop it is the feather itself, pixel for pixel.
        final over = await pixels((c) => GargoyleFeatherArt.overBar(c, size, [inStrip], boss), bg: const ui.Color(0xff303030));
        final plain = await pixels((c) => GargoyleFeatherArt.paint(c, 360, inStrip, fury: boss.enraged), bg: const ui.Color(0xff303030));
        expect(over, plain);
        // Nonsense: nothing.
        final c = Counting(ui.Canvas(ui.PictureRecorder()));
        GargoyleFeatherArt.overBar(c, size, [shot(x: double.nan), shot(y: double.infinity)], boss);
        GargoyleFeatherArt.overBar(c, ui.Size.zero, [inStrip], boss);
        expect(c.draws, 0);
      });
    });

    testWidgets('the lamp: a brass clink on the shutter, a dull thud on the open lamp', (tester) async {
      await tester.runAsync(() async {
        const at = ui.Offset(300, 200);
        const unit = 41.4;
        Future<({double bright, int lit})> look(void Function(ui.Canvas) draw) async {
          final px = await pixels(draw, w: 600, h: 400, bg: const ui.Color(0xff808080));
          var bright = 0.0, lit = 0;
          for (var y = 0; y < 400; y++) {
            for (var x = 0; x < 600; x++) {
              final i = (y * 600 + x) * 4;
              final l = .2126 * px[i] + .7152 * px[i + 1] + .0722 * px[i + 2];
              if ((px[i] - 128).abs() + (px[i + 1] - 128).abs() + (px[i + 2] - 128).abs() > 10) {
                lit++;
                bright = math.max(bright, l);
              }
              // Nothing beyond 2 units of the lamp's rim.
              if (px[i + 3] > 0 && (px[i] != 128 || px[i + 1] != 128)) {
                expect(math.sqrt(math.pow(x - at.dx, 2) + math.pow(y - at.dy, 2)), lessThan(unit * 2.6), reason: 'the sparks stay on the lamp');
              }
            }
          }
          return (bright: bright, lit: lit);
        }

        for (final fury in [false, true]) {
          final clink = await look((c) => GargoyleFeatherArt.glance(c, at, unit, 1.0, fury: fury));
          final thud = await look((c) => GargoyleFeatherArt.glance(c, at, unit, 1.0, open: 1, fury: fury));
          final thud2 = await look((c) => GargoyleFeatherArt.impact(c, at, unit, 1.0, fury: fury));
          expect(clink.bright, greaterThan(245), reason: 'the clink is a white-hot flash');
          expect(thud.bright, lessThan(215), reason: 'the thud has nothing white-hot');
          expect(thud.lit, greaterThan(300));
          expect(thud.bright, thud2.bright, reason: 'an open lamp\'s glance IS the thud');
        }
        // The lamp half open is still a clink; it is the open lamp that thuds.
        final half = await look((c) => GargoyleFeatherArt.glance(c, at, unit, 1.0, open: .3));
        final shut = await look((c) => GargoyleFeatherArt.glance(c, at, unit, 1.0));
        expect(half.bright, shut.bright);
        // Gone at 0; Reduced Motion is a still frame (the same at any pulse height's travel).
        final none = Counting(ui.Canvas(ui.PictureRecorder()));
        GargoyleFeatherArt.glance(none, at, unit, 0);
        GargoyleFeatherArt.glance(none, at, unit, -1);
        GargoyleFeatherArt.impact(none, at, unit, 0);
        expect(none.draws, 0);
        final a = await pixels((c) => GargoyleFeatherArt.glance(c, at, unit, .8, reducedMotion: true), bg: const ui.Color(0xff808080));
        final b = await pixels((c) => GargoyleFeatherArt.glance(c, at, unit, .8, reducedMotion: true), bg: const ui.Color(0xff808080));
        expect(a, b);
      });
    });

    testWidgets('the shatter: chips fly out and fall, then it is gone', (tester) async {
      await tester.runAsync(() async {
        const at = ui.Offset(300, 200);
        Future<int> lit(double tau, {bool reduced = false}) async {
          final px = await pixels((c) => GargoyleFeatherArt.shatter(c, at, 10, tau, reducedMotion: reduced), w: 600, h: 400, bg: const ui.Color(0x00000000));
          var n = 0;
          for (var i = 3; i < px.length; i += 4) {
            if (px[i] > 8) n++;
          }
          return n;
        }

        expect(await lit(.02), greaterThan(150));
        expect(await lit(.2), greaterThan(60));
        expect(await lit(.41), 0);
        expect(await lit(-.01), 0);
        expect(await lit(double.nan), 0);
        // Reduced Motion: the chips hold the .1 s frame and only fade.
        expect(await lit(.05, reduced: true), greaterThan(60));
        expect(await lit(.3, reduced: true), greaterThan(30));
      });
    });

    test('nonsense in: nothing drawn, nothing thrown', () {
      final c = Counting(ui.Canvas(ui.PictureRecorder()));
      final bad = [double.nan, double.infinity, double.negativeInfinity];
      for (final v in bad) {
        GargoyleFeatherArt.paint(c, 360, shot(x: v));
        GargoyleFeatherArt.paint(c, 360, shot(y: v));
        GargoyleFeatherArt.paint(c, 360, shot(vx: v));
        GargoyleFeatherArt.paint(c, 360, shot(vy: v));
        GargoyleFeatherArt.paint(c, 360, shot(gravity: v));
        GargoyleFeatherArt.paint(c, 360, shot(radius: v));
        GargoyleFeatherArt.paint(c, v, shot());
        GargoyleFeatherArt.dust(c, const ui.Size(640, 360), v, .9);
        GargoyleFeatherArt.dust(c, const ui.Size(640, 360), .5, v);
        GargoyleFeatherArt.glance(c, ui.Offset(v, 0), 40, .5);
        GargoyleFeatherArt.glance(c, const ui.Offset(0, 0), v, .5);
        GargoyleFeatherArt.glance(c, const ui.Offset(0, 0), 40, v);
        GargoyleFeatherArt.impact(c, ui.Offset(0, v), 40, .5);
        GargoyleFeatherArt.shatter(c, ui.Offset(v, 0), 10, .1);
        GargoyleFeatherArt.shatter(c, const ui.Offset(0, 0), v, .1);
        GargoyleFeatherArt.entryX(v);
      }
      GargoyleFeatherArt.paint(c, 360, shot(radius: 0));
      GargoyleFeatherArt.paint(c, 0, shot());
      GargoyleFeatherArt.paint(c, -5, shot());
      expect(c.draws, 0);
      // Out of range but finite is fine and bounded.
      GargoyleFeatherArt.glance(c, ui.Offset.zero, 40, 7);
      GargoyleFeatherArt.shatter(c, ui.Offset.zero, 1e-9, .1);
      expect(c.draws, lessThan(30));
    });

    test('a real fight through the real rules: every feather in flight is drawn within budget, its age is the rules\', its telegraph comes first', () {
      final sim = pilot.arena();
      final p = pilot.Pilot();
      final boss = sim.boss!;
      final launches = <({int frame, double birdY, bool fury})>[];
      final born = <BossAmmo, int>{};
      var frames = 0, drawn = 0, worstOps = 0, worstAll = 0, dustFramesBeforeLaunch = 0;
      var lastLaunched = boss.feathersLaunched;
      var maxAgeError = 0.0;
      var entryError = 0.0;
      final entryChecked = <BossAmmo>{};
      final ages = <BossAmmo, double>{};
      while (frames < 60 * 40 && boss.phase == BossPhase.attacking) {
        p.fly(sim);
        frames++;
        final pose = GargoylePose(boss, BossMotion(boss, reducedMotion: false), gap: boss.x - .299 - GargoyleLayout.birdColumn);
        if (boss.feathersLaunched > lastLaunched) {
          for (var i = lastLaunched; i < boss.feathersLaunched; i++) {
            launches.add((frame: frames, birdY: sim.birdY, fury: boss.enraged));
          }
          lastLaunched = boss.feathersLaunched;
          // The telegraph has been running: the dust channel was high a frame before.
          if (pose.shedTau >= 0) dustFramesBeforeLaunch++;
        }
        for (final a in sim.bossAmmo.where((a) => a.feather)) {
          born.putIfAbsent(a, () => frames);
          final age = (frames - born[a]!) / 60.0;
          ages[a] = age;
          maxAgeError = math.max(maxAgeError, (GargoyleFeatherArt.age(a) - age).abs());
          final cnt = Counting(ui.Canvas(ui.PictureRecorder()));
          BossAmmoArt.shot(cnt, 360, a, boss, seconds: sim.elapsed, reducedMotion: false);
          expect(cnt.draws, lessThanOrEqualTo(8));
          worstOps = math.max(worstOps, cnt.draws);
          drawn++;
          if (a.y + a.radius >= 0 && entryChecked.add(a)) {
            final l = launches.lastWhere((l) => l.frame <= born[a]!, orElse: () => (frame: 0, birdY: .5, fury: false));
            entryError = math.max(entryError, (GargoyleFeatherArt.entryX(l.birdY, fury: l.fury) - a.x).abs());
          }
        }
        final all = Counting(ui.Canvas(ui.PictureRecorder()));
        for (final a in sim.bossAmmo) {
          BossAmmoArt.shot(all, 360, a, boss, seconds: sim.elapsed, reducedMotion: false);
        }
        worstAll = math.max(worstAll, all.draws);
      }
      // ignore: avoid_print
      print('real fight: $frames frames, ${launches.length} launches, $drawn feather frames drawn, worst $worstOps ops each, '
          '$worstAll for all in flight, age error ${maxAgeError.toStringAsFixed(3)} s, entry error ${entryError.toStringAsFixed(4)}');
      expect(launches.length, greaterThanOrEqualTo(4));
      expect(drawn, greaterThan(100));
      expect(worstAll, lessThanOrEqualTo(24));
      expect(maxAgeError, lessThan(.04), reason: 'the age worked out from where a feather is is the rules\' (within a frame or two)');
      expect(entryError, lessThan(.012), reason: 'the dust column is where the feather first shows');
      expect(dustFramesBeforeLaunch, launches.length, reason: 'the blade is leaving the fan in every launch frame (G3), as the telegraph ends (G6)');
    }, timeout: const Timeout(Duration(minutes: 4)));
  });
}
