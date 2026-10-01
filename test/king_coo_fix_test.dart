import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/boss_encounter_art.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/enemy_designs/alley_pigeon.dart';
import 'package:push_up_bird/game/king_coo_body_art.dart';
import 'package:push_up_bird/game/king_coo_boss_rig.dart';
import 'package:push_up_bird/game/king_coo_encounter_ui.dart';
import 'package:push_up_bird/game/king_coo_hud_art.dart';
import 'package:push_up_bird/game/king_coo_hide_art.dart';
import 'package:push_up_bird/game/king_coo_kit.dart';
import 'package:push_up_bird/game/king_coo_layout.dart';
import 'package:push_up_bird/game/king_coo_pose.dart';
import 'package:push_up_bird/game/king_coo_staging_art.dart';

import 'king_coo_budget_test.dart' show Counting;
import 'king_coo_staging_test.dart' show Stage, stage;
import 'king_coo_test_kit.dart';

/// The King Coo fix round (K8): a bigger victory payoff, the puffed chest sold
/// (a bold ring, a warm heart, feathers standing up as it swells and an "x2"
/// roundel while his rocks count double; the hit circle stays exactly r 1.00),
/// the name card's quote on a plank, the letterbox of the other bosses, and a
/// squadron of individuals (the letterbox is pinned in
/// `king_coo_staging_test.dart`).

const h = 360.0;

BossMotion motion(Stage s, {bool reduced = false}) =>
    BossMotion(s.boss, reducedMotion: reduced);

int differing(Uint8List a, Uint8List b, [int tolerance = 40]) {
  var n = 0;
  for (var i = 0; i < a.length; i += 4) {
    if ((a[i] - b[i]).abs() +
            (a[i + 1] - b[i + 1]).abs() +
            (a[i + 2] - b[i + 2]).abs() +
            (a[i + 3] - b[i + 3]).abs() >
        tolerance) {
      n++;
    }
  }
  return n;
}

Rect boundsOf(Uint8List px, int w, int hh, {int min = 100}) {
  var l = w, t = hh, r = -1, b = -1;
  for (var y = 0; y < hh; y++) {
    for (var x = 0; x < w; x++) {
      if (px[(y * w + x) * 4 + 3] > min) {
        if (x < l) l = x;
        if (x > r) r = x;
        if (y < t) t = y;
        if (y > b) b = y;
      }
    }
  }
  return r < 0 ? Rect.zero : Rect.fromLTRB(l * 1.0, t * 1.0, r + 1.0, b + 1.0);
}

/// WCAG relative luminance of an RGB triple (0..255).
double luminance(int r, int g, int b) {
  double c(int v) {
    final s = v / 255;
    return s <= .03928 ? s / 12.92 : math.pow((s + .055) / 1.055, 2.4).toDouble();
  }

  return .2126 * c(r) + .7152 * c(g) + .0722 * c(b);
}

double contrast(double a, double b) {
  final hi = math.max(a, b), lo = math.min(a, b);
  return (hi + .05) / (lo + .05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ------------------------------------------------- the puffed chest (D6) --

  group('the double-damage window as a pose state', () {
    test('it is the rules\' puffWindow, eased .15 s each side, and kept under Reduced Motion', () {
      final s = stage(800);
      final boss = s.boss;
      final cuts = <double>[];
      var seenOpen = false, seenShut = false, steps = 0;
      var wasWindow = false;
      for (var t = 0.0; t < 30; t += 1 / 30) {
        s.toCombat(t);
        final p = KingCooPose(boss, motion(s));
        final r = KingCooPose(boss, motion(s, reduced: true));
        steps++;
        expect(r.doubleDamage, closeTo(p.doubleDamage, 1e-12), reason: 'a state: the same in Reduced Motion at $t');
        expect(p.doubleDamage, inInclusiveRange(0.0, 1.0));
        final rules = boss.puffWindow;
        if (rules != wasWindow) cuts.add(t);
        wasWindow = rules;
        if (rules && p.doubleDamage > .99) seenOpen = true;
        // Well inside the window: fully on; well outside: fully off.
        final inside = boss.cooCycle >= KingCoo.puffAt + .2 && boss.cooCycle < KingCoo.windowEnd - .2;
        final outside = boss.cooCycle < KingCoo.puffAt - .02 || boss.cooCycle >= KingCoo.windowEnd + .02;
        if (inside) expect(p.doubleDamage, closeTo(1, 1e-9), reason: 'inside at $t');
        if (outside) {
          expect(p.doubleDamage, closeTo(0, 1e-9), reason: 'outside at $t');
          seenShut = true;
        }
      }
      expect(seenOpen && seenShut && steps > 800, isTrue);
      expect(cuts.length, greaterThanOrEqualTo(4), reason: 'two cycles of window edges');
    });

    test('a pop closes it, the arrival and the defeat never open it', () {
      final s = stage(800);
      s.toCombat(8.3);
      final boss = s.boss;
      expect(KingCooPose(boss, motion(s)).doubleDamage, closeTo(1, 1e-9));
      s.hit(30);
      s.run(.3);
      expect(boss.popped, isTrue);
      expect(KingCooPose(boss, motion(s)).doubleDamage, closeTo(0, 1e-9));
      for (var a = 0.0; a < 4.6; a += .1) {
        final b = stage(800);
        b.toAge(a);
        expect(KingCooPose(b.boss, motion(b)).doubleDamage, 0, reason: 'arrival $a');
      }
      final d = stage(800);
      d.toCombat(8.3);
      d.hit(1000);
      for (var x = .0; x < 3; x += .25) {
        d.boss.age = d.boss.defeatedAt! + x;
        expect(KingCooPose(d.boss, motion(d)).doubleDamage, 0, reason: 'defeat $x');
      }
      expect(KingCooPose.story(KingCooMood.angry).doubleDamage, 0);
    });

    test('no jump: sampled every 1/480 s through a window and a pop', () {
      final s = stage(800);
      final boss = s.boss;
      for (final popAt in [null, 8.4]) {
        final b = stage(800).boss;
        b.age = b.arrivalDuration + 7.0;
        if (popAt != null) b.poppedAt = b.arrivalDuration + popAt;
        var prev = KingCooPose(b, BossMotion(b, reducedMotion: false)).doubleDamage;
        var worst = 0.0;
        for (var i = 1; i < 480 * 4; i++) {
          b.age = b.arrivalDuration + 7.0 + i / 480;
          final v = KingCooPose(b, BossMotion(b, reducedMotion: false)).doubleDamage;
          worst = math.max(worst, (v - prev).abs());
          prev = v;
        }
        expect(worst, lessThan(.06), reason: 'the .15 s ease is at most .035 a step; pop $popAt');
      }
      expect(boss.kind, BossKind.kingCoo);
    });
  });

  group('the puffed chest', () {
    KingCooBodyPose body(double puff, double damage) => KingCooBodyPose(
      puff: puff,
      tailFan: .5,
      tailWag: 0,
      pedal: 0,
      sackSwing: 0,
      stomp: 0,
      tone: KingCooTone.calm,
      damage: damage,
      time: 1.3,
    );

    Future<double> radius(KingCooBodyPose b, double angle) async {
      const ppu = 60.0;
      final px = await rawPixels(300, 300, (c) {
        c.translate(150, 150);
        c.scale(ppu);
        KingCooBodyArt.chest(c, b);
      });
      var reach = 0.0;
      for (var d = 0.0; d < 3.0; d += .01) {
        final x = (150 + math.cos(angle) * d * ppu).round(), y = (150 + math.sin(angle) * d * ppu).round();
        if (x < 0 || y < 0 || x >= 300 || y >= 300) break;
        if (px[(y * 300 + x) * 4 + 3] > 128) reach = d;
      }
      return reach;
    }

    testWidgets('with every new brush on, the outline is still exactly the hit circle (r 1.00 within .05)', (tester) async {
      await tester.runAsync(() async {
        var worst = 0.0;
        for (final damage in [0.0, 1.0]) {
          for (var a = 0.0; a < 2 * math.pi; a += math.pi / 45) {
            final r = await radius(body(1.0, damage), a) - KingCooLayout.inkHero / 2;
            worst = math.max(worst, (r - KingCooLayout.hitRadius).abs());
          }
        }
        expect(worst, lessThan(.05), reason: 'the ring, the glow and the roundel stay inside / off the isolated chest');
        expect(KingCooLayout.chestRadiusAt(1), KingCooLayout.hitRadius);
      });
    });

    testWidgets('the ring is bold and amber inside the window and thin outside it; the heart is warmer', (tester) async {
      await tester.runAsync(() async {
        Future<Uint8List> chest(double damage) => rawPixels(240, 240, (c) {
          c.translate(120, 120);
          c.scale(100);
          KingCooBodyArt.chest(c, body(1.0, damage));
        });
        final off = await chest(0), on = await chest(1);
        // Amber ring pixels along the circle at .86 (inside) vs .80 (outside).
        int amber(Uint8List px) {
          var n = 0;
          for (var i = 0; i < px.length; i += 4) {
            final r = px[i], g = px[i + 1], b = px[i + 2];
            if (px[i + 3] > 200 && r > 200 && g > 120 && g < 200 && b < 90) n++;
          }
          return n;
        }

        expect(amber(on), greaterThan(amber(off) * 2 + 400), reason: 'a bolder amber ring');
        // The centre of the globe is warmer (a lower blue) with the window on.
        int blueAt(Uint8List px, int x, int y) => px[(y * 240 + x) * 4 + 2];
        expect(blueAt(on, 85, 140), lessThan(blueAt(off, 85, 140)));
        expect(differing(off, on), greaterThan(1500));
      });
    });

    testWidgets('feathers stand up while it swells and are gone when it is taut or fluffed', (tester) async {
      await tester.runAsync(() async {
        Future<int> outside(double puff) async {
          final b = body(puff, 1);
          final px = await rawPixels(360, 360, (c) {
            c.translate(180, 180);
            c.scale(100);
            KingCooBodyArt.chestRuffle(c, b);
          });
          return [for (var i = 3; i < px.length; i += 4) if (px[i] > 20) 1].length;
        }

        expect(await outside(0), 0, reason: 'fluffed: no ruffle');
        expect(await outside(.5), greaterThan(300), reason: 'half swollen: the feathers are up');
        expect(await outside(.5), greaterThan(await outside(.1)));
        expect(await outside(.99), 0, reason: 'taut: the chest is exactly the circle again');
        expect(await outside(1.0), 0);
        expect(await outside(1.3), 0, reason: 'the defeat\'s inflating is not a ruffle');
        // They flutter (motion) and hold still without a clock.
        Future<Uint8List> at(double time) => rawPixels(360, 360, (c) {
          c.translate(180, 180);
          c.scale(100);
          KingCooBodyArt.chestRuffle(
            c,
            KingCooBodyPose(
              puff: .5,
              tailFan: .5,
              tailWag: 0,
              pedal: 0,
              sackSwing: 0,
              stomp: 0,
              tone: KingCooTone.calm,
              damage: 1,
              time: time,
            ),
          );
        });
        expect(differing(await at(1.0), await at(1.07)), greaterThan(20));
        expect(await at(0), equals(await at(0)));
      });
    });

    testWidgets('the x2 roundel pops in with the window, reads at 41 px a unit and at 19 (120 px tall)', (tester) async {
      await tester.runAsync(() async {
        Future<Uint8List> hide(double damage, double ppu) => rawPixels(400, 400, (c) {
          c.translate(200, 200);
          c.scale(ppu);
          KingCooHide(body(1.0, damage)).paint(c);
        });
        for (final ppu in [41.4, 19.0]) {
          final off = await hide(0, ppu), on = await hide(1, ppu);
          // The roundel sits at (-.76,.66) rig units, .43 radius (x 1.14 ink).
          final cx = 200 + (-.76 * ppu), cy = 200 + (.66 * ppu);
          int gold(Uint8List px) {
            var n = 0;
            for (var y = (cy - 1.3 * .43 * ppu).round(); y < (cy + 1.3 * .43 * ppu).round(); y++) {
              for (var x = (cx - 1.3 * .43 * ppu).round(); x < (cx + 1.3 * .43 * ppu).round(); x++) {
                final i = (y * 400 + x) * 4;
                if (px[i + 3] > 200 && px[i] > 200 && px[i + 1] > 150 && px[i + 2] < 150) n++;
              }
            }
            return n;
          }

          expect(gold(on), greaterThan(gold(off) + (ppu > 30 ? 25 : 6)), reason: 'a gold x2 at $ppu px a unit');
          // And it is a medal: navy inside its ring.
          final navy = on[((cy + .5 * .43 * ppu).round() * 400 + (cx + .5 * .43 * ppu).round()) * 4 + 2];
          expect(navy, greaterThan(90));
          // At half scale (the figure at 120 px) the medal is still 14 px across.
          expect(2 * 1.14 * .43 * ppu, greaterThan(ppu > 30 ? 30 : 14));
        }
        // Absent in the arrival's rear (puffed, no window) and at the defeat's swell.
        final rear = KingCooPose(
          stage(800).boss..age = 2.8,
          BossMotion(stage(800).boss..age = 2.8, reducedMotion: false),
        );
        expect(rear.doubleDamage, 0);
        expect(rear.puff, greaterThan(.9), reason: 'the chest IS taut then');
      });
    });
  });

  group('the stage lights the weak point', () {
    testWidgets('a gold halo and swell feathers while the window is open; none in the arrival, in any motion mode', (tester) async {
      await tester.runAsync(() async {
        Future<Uint8List> pass(Stage s, {bool reduced = false}) => rawPixels(800, 360, (c) {
          KingCooStaging.paint(c, const Size(800, 360), s.sim, motion(s, reduced: reduced));
        });
        // Gold-amber pixels (the ring, the roundel's rim, the halo's warmth)
        // within 2.6 units of the chest.
        int gold(Uint8List px, Stage s) {
          const unit = h * SkyBoss.radius;
          final at = Offset(s.boss.x * h, s.boss.y * h);
          var n = 0;
          for (var y = (at.dy - 2.6 * unit).round(); y < (at.dy + 2.6 * unit).round(); y++) {
            for (var x = (at.dx - 2.6 * unit).round(); x < (at.dx + 2.6 * unit).round(); x++) {
              if (x < 0 || y < 0 || x >= 800 || y >= 360) continue;
              final i = (y * 800 + x) * 4;
              final a = px[i + 3];
              if (a < 60) continue;
              final r = px[i] * 255 ~/ a, g = px[i + 1] * 255 ~/ a, b = px[i + 2] * 255 ~/ a;
              if (r > 200 && g > 130 && g < 215 && b < 120) n++;
            }
          }
          return n;
        }

        final a = stage(800)..toCombat(9.0);
        final inWindow = await pass(a);
        final b = stage(800)..toCombat(6.0);
        final calm = await pass(b);
        expect(gold(inWindow, a), greaterThan(gold(calm, b) + 250), reason: 'the ring, the x2 rim and the halo\'s warmth');
        // Under Reduced Motion the state stays.
        final r = stage(800, reduced: true)..toCombat(9.0);
        final rm = await pass(r, reduced: true);
        expect(gold(rm, r), greaterThan(gold(calm, b) + 250));
        // The arrival's rear: puffed, no window: no roundel and no halo.
        int roundel(Uint8List px, Stage st) {
          final m = motion(st);
          final pose = KingCooStaging.poseOf(st.sim, m, h);
          const unit = h * SkyBoss.radius;
          final at = KingCooStaging.heart(m, h) +
              (KingCooBossRig.chestCenter(pose) + const Offset(-.76, .66)) * unit;
          var n = 0;
          for (var y = (at.dy - .3 * unit).round(); y < (at.dy + .3 * unit).round(); y++) {
            for (var x = (at.dx - .3 * unit).round(); x < (at.dx + .3 * unit).round(); x++) {
              final i = (y * 800 + x) * 4;
              final a = px[i + 3];
              if (a < 200) continue;
              // The medal's navy (premultiplied bytes are opaque here).
              if (px[i + 2] > px[i] + 40 && px[i] < 90 && px[i + 2] < 150) n++;
            }
          }
          return n;
        }

        final arr = stage(800)..toAge(2.9);
        final rear = await pass(arr);
        expect(roundel(inWindow, a), greaterThan(150), reason: 'the x2 medal in the window');
        expect(roundel(rear, arr), lessThan(40), reason: 'none on the arrival\'s rear');
        expect(roundel(calm, b), lessThan(40));
        expect(roundel(rm, r), greaterThan(150), reason: 'the state stays under Reduced Motion');
        // Swell feathers: a frame mid-swell has loose feathers off the chest.
        final swell = stage(800)..toCombat(8.0);
        final during = await pass(swell);
        final taut = stage(800)..toCombat(9.3);
        final after = await pass(taut);
        expect(during.any((v) => v != 0), isTrue);
        expect(after.any((v) => v != 0), isTrue);
      });
    });

    testWidgets('the HUD tag is bigger (11.5 px at 640) and still inside its width budget', (tester) async {
      await tester.runAsync(() async {
      await loadFonts();
      expect(KingCooHudArt.tagType, greaterThanOrEqualTo(11.5));
      final box = KingCooHudArt.tagBox(const Rect.fromLTWH(60, 6, 380, 34), const Rect.fromLTWH(90, 14, 330, 12), 1);
      expect(box.width, lessThanOrEqualTo(KingCooHudArt.tagWidthMax));
      expect(box.width, lessThanOrEqualTo(130), reason: 'left of the bird\'s column (the brief)');
      });
    });
  });

  // ---------------------------------------------------- the name card (D9) --

  group('the name card', () {
    testWidgets('the quote reads at 640 over the skyline and over the bird: contrast >= 7, 2 lines of >= 14 px type', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        final s = stage(640);
        s.toAge(3.75);
        final boss = s.boss;
        for (final birdY in [.5, .2]) {
          final px = await rawPixels(640, 360, (c) {
            KingCooEncounterUi.nameCard(
              c,
              const Size(640, 360),
              boss,
              motion(s),
              birdY: birdY,
              line: BossEncounterArt.bossLine(s.sim),
            );
          });
          // The quote's box: under the plate (the plate's bottom is about .43 h).
          // Text pixels are the cream fill; backdrop pixels are the plank.
          final text = <double>[], plank = <double>[];
          var top = 360, bottom = 0;
          for (var y = 150; y < 260; y++) {
            for (var x = 40; x < 420; x++) {
              final i = (y * 640 + x) * 4;
              final a = px[i + 3];
              if (a < 120) continue;
              // The bytes are premultiplied: back to the colour drawn.
              final r = math.min(255, px[i] * 255 ~/ a),
                  g = math.min(255, px[i + 1] * 255 ~/ a),
                  b = math.min(255, px[i + 2] * 255 ~/ a);
              final lum = luminance(r, g, b);
              if (lum > .3) {
                text.add(lum);
                if (y < top) top = y;
                if (y > bottom) bottom = y;
              } else if (lum < .08) {
                plank.add(lum);
              }
            }
          }
          expect(text.length, greaterThan(400), reason: 'quote glyphs are drawn (bird $birdY)');
          expect(plank.length, greaterThan(2000), reason: 'a plank behind them');
          text.sort();
          plank.sort();
          final c = contrast(text[text.length ~/ 2], plank[plank.length ~/ 2]);
          expect(c, greaterThan(7), reason: 'contrast $c (bird $birdY)');
          // Two lines of type, each at least 14 px: the block is at least 28 px
          // high plus leading.
          expect(bottom - top, greaterThan(24), reason: 'two lines of 14 px type');
        }
      });
    });

    testWidgets('the name types in from 3.2 s: the plate is empty on the COO!, lettered by 3.6 s', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        Future<int> letters(double age) async {
          final s = stage(640)..toAge(age);
          final px = await rawPixels(640, 360, (c) {
            KingCooEncounterUi.nameCard(c, const Size(640, 360), s.boss, motion(s), birdY: .9, line: null);
          });
          var n = 0;
          // Bright cream-white letter fills inside the plate.
          for (var y = 60; y < 130; y++) {
            for (var x = 40; x < 400; x++) {
              final i = (y * 640 + x) * 4;
              final a = px[i + 3];
              if (a > 200 && px[i] * 255 ~/ a > 240 && px[i + 1] * 255 ~/ a > 225 && px[i + 2] * 255 ~/ a > 170) n++;
            }
          }
          return n;
        }

        expect(await letters(2.95), lessThan(200), reason: 'no letters on the shout');
        expect(await letters(3.15), lessThan(300));
        expect(await letters(3.7), greaterThan(900));
      });
    });
  });

  // ------------------------------------------------- the squadron (D10) --

  group('the squadron are individuals', () {
    test('the coat and the bank follow the call\'s slot: neighbours always differ, all three coats in a V', () {
      expect(AlleyPigeonArtCoats.count, AlleyPigeonArt.coatCount);
      for (var base = 0; base < 40; base += 7) {
        final coats = <int>[];
        for (var i = 0; i < 9; i++) {
          final enemy = SkyEnemy(
            x: 1,
            y: .5,
            appearance: EnemyKind.alleyPigeon.index,
            flightPhase: (base + i) * 2.399963,
            squad: true,
          );
          final pose = PigeonPose.of(enemy, hitAge: double.infinity);
          coats.add(pose.coat);
          expect(pose.tilt.abs(), lessThanOrEqualTo(.0701), reason: 'about +-4 degrees');
          expect(pose.stage, PigeonStage.glide);
        }
        for (var i = 1; i < coats.length; i++) {
          expect(coats[i], isNot(coats[i - 1]), reason: 'neighbours differ: $coats');
        }
        expect(coats.take(5).toSet().length, 3, reason: 'a V of five wears all three coats: $coats');
      }
      // A star-raiding pigeon and a plain bat are unchanged by this.
      final raider = SkyEnemy(x: 1, y: .5, appearance: EnemyKind.alleyPigeon.index, flightPhase: 1.0);
      expect(PigeonPose.of(raider, hitAge: double.infinity).tilt, 0);
    });

    test('in a real fight the five pigeons of the V are not clones', () {
      final s = stage(800);
      s.toCombat(9.6);
      final squad = s.sim.enemies.where((e) => e.squad).toList();
      expect(squad.length, greaterThanOrEqualTo(4));
      final coats = {
        for (final e in squad) PigeonPose.of(e, hitAge: double.infinity).coat,
      };
      expect(coats.length, 3, reason: 'all three plumages in the call');
    });

    testWidgets('at 640 (16 px radius) two gliders of different coats differ by more than a handful of pixels; each is <= 30 ops', (tester) async {
      await tester.runAsync(() async {
        final shots = <Uint8List>[];
        for (var coat = 0; coat < 3; coat++) {
          shots.add(await rawPixels(80, 80, (c) {
            c.translate(40, 40);
            AlleyPigeonArt.paint(
              c,
              16,
              seconds: 0,
              reducedMotion: true,
              pose: PigeonPose(coat: coat, tilt: PigeonPose.squadTilt(coat)),
              glider: true,
            );
          }));
          final rec = ui.PictureRecorder();
          final counting = Counting(Canvas(rec));
          AlleyPigeonArt.paint(
            counting,
            16,
            seconds: 0,
            reducedMotion: true,
            pose: PigeonPose(coat: coat, tilt: PigeonPose.squadTilt(coat)),
            glider: true,
          );
          rec.endRecording().dispose();
          expect(counting.draws, lessThanOrEqualTo(30), reason: 'coat $coat glider ops');
          expect(counting.counts['saveLayer'] ?? 0, 0);
        }
        for (var i = 0; i < 3; i++) {
          for (var j = i + 1; j < 3; j++) {
            expect(differing(shots[i], shots[j], 60), greaterThan(30), reason: 'coats $i and $j are told apart at 640');
          }
        }
      });
    });

    testWidgets('the ghost and the queue wear the coats too, inside K6\'s budget (the squad test measures the frames)', (tester) async {
      await tester.runAsync(() async {
        final s = stage(640);
        s.toCombat(8.5);
        Future<Uint8List> pass() => rawPixels(640, 360, (c) {
          KingCooStaging.paint(c, const Size(640, 360), s.sim, motion(s));
        });
        await pass();
        // The queue is under the figure: the frame has pigeon-coloured pixels
        // behind his chest in more than one hue (necks).
        final rec = ui.PictureRecorder();
        final counting = Counting(Canvas(rec));
        BossEncounterArt.backdrop(counting, const Size(640, 360), s.boss, motion(s));
        rec.endRecording().dispose();
        expect(counting.draws, lessThanOrEqualTo(KingCooBudget.lanes + 6 * KingCooBudget.squadPigeon + 150));
      });
    });
  });

  // ------------------------------------------------- the victory payoff --

  group('the victory payoff', () {
    Stage killed(double width, {bool reduced = false}) {
      final s = stage(width, reduced: reduced);
      s.toCombat(3.0);
      s.hit(150);
      s.toCombat(5.0);
      s.hit(1000);
      return s;
    }

    Future<Uint8List> pass(Stage s, double death, {bool reduced = false}) {
      s.boss.age = s.boss.defeatedAt! + death;
      return rawPixels(s.width.toInt(), 360, (c) {
        KingCooStaging.paint(c, Size(s.width, 360), s.sim, motion(s, reduced: reduced));
      });
    }

    testWidgets('the shower: crumbs and feathers across the sky, bounded and still under Reduced Motion', (tester) async {
      await tester.runAsync(() async {
        for (final reduced in [false, true]) {
          var worstOps = 0, worstLayers = 0;
          for (var k = 0.0; k < 3.4; k += .1) {
            final rec = ui.PictureRecorder();
            final counting = Counting(Canvas(rec));
            KingCooEncounterUi.shower(counting, const Size(640, 360), k, 520, reduced: reduced);
            rec.endRecording().dispose();
            worstOps = math.max(worstOps, counting.draws);
            worstLayers = math.max(worstLayers, counting.counts['saveLayer'] ?? 0);
          }
          expect(worstOps, lessThanOrEqualTo(12), reason: 'a handful of batched paths');
          expect(worstLayers, 0);
        }
        Future<Uint8List> at(double k, {bool reduced = false}) => rawPixels(640, 360, (c) {
          KingCooEncounterUi.shower(c, const Size(640, 360), k, 520, reduced: reduced);
        });
        final mid = await at(1.6), early = await at(.12), late = await at(3.25);
        int n(Uint8List px) => [for (var i = 3; i < px.length; i += 4) if (px[i] > 100) 1].length;
        expect(n(mid), greaterThan(900), reason: 'a downpour at 1.6 s');
        expect(n(mid), greaterThan(n(early) * 3));
        expect(n(late), lessThan(n(mid) ~/ 3), reason: 'a last few');
        // Spread across the screen, not a cluster: crumbs in both halves.
        int half(Uint8List px, bool left) {
          var c = 0;
          for (var y = 0; y < 360; y++) {
            for (var x = left ? 0 : 320; x < (left ? 320 : 640); x++) {
              if (px[(y * 640 + x) * 4 + 3] > 100) c++;
            }
          }
          return c;
        }

        expect(half(mid, true), greaterThan(150));
        expect(half(mid, false), greaterThan(150));
        // Reduced Motion: a still scatter (identical across a small step).
        expect(await at(1.5, reduced: true), equals(await at(1.52, reduced: true)));
        expect(n(await at(1.5, reduced: true)), greaterThan(300));
        // Deterministic.
        expect(await at(1.6), equals(mid));
      });
    });

    testWidgets('the cap lands in the middle of the screen at 1.4x, spins like a coin, and lies lit by its siren', (tester) async {
      await tester.runAsync(() async {
        for (final width in [640.0, 800.0]) {
          final s = killed(width);
          Future<Rect> capBox(double d) async {
            final px = await pass(s, d);
            final navy = Uint8List(px.length);
            // Only the ground's band: the badge (navy too) floats above it.
            for (var y = 262; y < 340; y++) {
              for (var x = (width / 2 - 80).round(); x < (width / 2 + 80).round(); x++) {
                final i = (y * width.toInt() + x) * 4;
                navy[i + 3] = px[i + 3] > 220 && px[i + 2] > px[i] + 25 && px[i] < 110 && px[i + 2] < 200 ? 255 : 0;
              }
            }
            return boundsOf(navy, width.toInt(), 360, min: 100);
          }

          // On his head the cap is up in the figure, not on the ground band.
          Future<Rect> capBoxHead(double d) async {
            final px = await pass(s, d);
            final navy = Uint8List(px.length);
            for (var y = 20; y < 160; y++) {
              for (var x = (width * .45).round(); x < width.toInt(); x++) {
                final i = (y * width.toInt() + x) * 4;
                navy[i + 3] = px[i + 3] > 60 && px[i + 2] > px[i] + 25 && px[i] < 110 && px[i + 2] < 200 ? 255 : 0;
              }
            }
            return boundsOf(navy, width.toInt(), 360, min: 100);
          }

          final head = await capBoxHead(.31);
          // Resting (death 3.05: the spin is done): the middle of the screen.
          final rest = await capBox(3.05);
          expect(rest.center.dx, closeTo(width / 2, 26), reason: 'x .5 w at $width');
          // At 1x a tilted cap is about 85 px across at a unit of 41 px; at 1.4x
          // about 120 (the cap's reach is 1.62 units wide).
          const unit = h * SkyBoss.radius;
          expect(rest.width, greaterThan(1.62 * 1.25 * unit), reason: 'grown to 1.4x on the ground: ${rest.width}');
          expect(head, isNot(Rect.zero));
          // (The mask sees the navy crown, not the ink rim and the black visor
          // under it, so it ends a few pixels above the rim: 5 to 20 px.)
          expect(rest.bottom, inInclusiveRange(360 * .865 - 22, 360 * .865 + 4), reason: 'its rim on the ground line: ${rest.bottom}');
          // The spin: its outline is not the same at 1.7 s (mid-spin) as at rest.
          final spin = await capBox(1.75);
          expect((spin.size.width - rest.size.width).abs() + (spin.size.height - rest.size.height).abs(), greaterThan(8),
              reason: 'tumbling on the ground at 1.75 s');
          // Lit by its siren: the ground round it is red or blue (a pool), then gone.
          final lit = await pass(s, 2.7);
          int tinted(Uint8List px) {
            var n = 0;
            for (var y = 250; y < 330; y++) {
              for (var x = (width / 2 - 60).round(); x < (width / 2 + 60).round(); x++) {
                final i = (y * width.toInt() + x) * 4;
                if (px[i + 3] > 20 && ((px[i] > px[i + 2] + 40) || (px[i + 2] > px[i] + 60))) n++;
              }
            }
            return n;
          }

          expect(tinted(lit), greaterThan(700), reason: 'a siren pool round the cap at $width');
        }
      });
    });

    testWidgets('the badge floats beside the cap to 3.1 s and is gone by 3.55', (tester) async {
      await tester.runAsync(() async {
        for (final reduced in [false, true]) {
          Future<int> brass(double k) async {
            final rest = Offset(320 + 2.3 * 41.4, 311 - 2.3 * 41.4);
            final px = await rawPixels(640, 360, (c) {
              KingCooEncounterUi.victoryBadge(c, const Offset(450, 200), h, k, reduced: reduced, restAt: rest);
            });
            var n = 0;
            for (var y = (rest.dy - 40).round(); y < (rest.dy + 40).round(); y++) {
              for (var x = (rest.dx - 40).round(); x < (rest.dx + 40).round(); x++) {
                final i = (y * 640 + x) * 4;
                if (px[i + 3] > 120 && px[i] > 200 && px[i + 1] > 140 && px[i + 2] < 140) n++;
              }
            }
            return n;
          }

          expect(await brass(2.25), greaterThan(60), reason: 'at rest beside the cap (reduced $reduced)');
          expect(await brass(2.4), greaterThan(60));
          expect(await brass(2.75), 0, reason: 'gone (3.6 s of the defeat)');
        }
      });
    });

    testWidgets('three pigeons drop in, stand on the ground line and peck at the crumbs, each its own plumage; gone by 4 s', (tester) async {
      await tester.runAsync(() async {
        final s = killed(800);
        final land = KingCooStaging.capLanding(const Size(800, 360));
        // Pigeon-coloured (blue-grey/white) pixels in three columns at the
        // ground line, away from the cap.
        int column(Uint8List px, double cx) {
          var n = 0;
          for (var y = 270; y < 330; y++) {
            for (var x = (cx - 34).round(); x < (cx + 34).round(); x++) {
              final i = (y * 800 + x) * 4;
              if (px[i + 3] > 200 && px[i] > 120 && px[i + 2] > 140 && (px[i + 2] - px[i]).abs() < 70) n++;
            }
          }
          return n;
        }

        const unit = h * SkyBoss.radius;
        final xs = [land.dx - 3.2 * unit, land.dx + 3.0 * unit, land.dx + 5.2 * unit];
        final standing = await pass(s, 2.9);
        for (final x in xs) {
          expect(column(standing, x), greaterThan(250), reason: 'a pigeon at x $x');
        }
        final gone = await pass(s, 4.0);
        for (final x in xs) {
          expect(column(gone, x), lessThan(60), reason: 'it flew off');
        }
        // They peck: the frame changes between two beats of the peck.
        final a = await pass(s, 2.7), b = await pass(s, 2.95);
        expect(differing(a, b), greaterThan(300));
        // Individuals: the three pigeons are not the same picture.
        Uint8List crop(Uint8List px, double cx) {
          final out = Uint8List(68 * 60 * 4);
          for (var y = 0; y < 60; y++) {
            for (var x = 0; x < 68; x++) {
              final i = ((270 + y) * 800 + (cx - 34).round() + x) * 4;
              final o = (y * 68 + x) * 4;
              out.setRange(o, o + 4, px.sublist(i, i + 4));
            }
          }
          return out;
        }

        final shots = [for (final x in xs) crop(standing, x)];
        expect(differing(shots[0], shots[1], 50), greaterThan(150));
        expect(differing(shots[1], shots[2], 50), greaterThan(150));
      });
    });

    testWidgets('Reduced Motion: the cap is cross-faded to the ground, the pigeons simply stand, nothing flies', (tester) async {
      await tester.runAsync(() async {
        final s = killed(640, reduced: true);
        final ground = await pass(s, 3.02, reduced: true);
        final ground2 = await pass(s, 3.08, reduced: true);
        // The same standing picture (the cap, three pigeons): only the burst's
        // dust and the badge differ.
        expect(differing(ground, ground2, 80), lessThan(400), reason: 'standing still');
        expect(ground.any((v) => v != 0), isTrue);
        // No pigeon is mid-air: the three columns where they stand are empty
        // above the ground band (the scatter's crumbs and feathers are small).
        final land = KingCooStaging.capLanding(const Size(640, 360));
        const unit = h * SkyBoss.radius;
        var air = 0;
        for (final dx in [-3.2, 3.0, 5.2]) {
          final cx = land.dx + dx * unit;
          for (var y = 60; y < 250; y++) {
            for (var x = (cx - 30).round(); x < (cx + 30).round(); x++) {
              final i = (y * 640 + x) * 4;
              if (ground2[i + 3] > 200 && ground2[i] > 150 && ground2[i + 2] > 170 && (ground2[i + 2] - ground2[i]).abs() < 60) air++;
            }
          }
        }
        expect(air, lessThan(300), reason: 'nothing pigeon-sized in the air (no flight)');
      });
    });

    testWidgets('every victory frame is deterministic, with the caches emptied, at both widths', (tester) async {
      await tester.runAsync(() async {
        for (final width in [640.0, 800.0]) {
          Future<List<Uint8List>> run() async {
            final s = killed(width);
            return [for (final d in [.5, 1.2, 1.8, 2.4, 3.0, 3.5]) await pass(s, d)];
          }

          final a = await run();
          KingCooKit.clearCaches();
          final b = await run();
          for (var i = 0; i < a.length; i++) {
            expect(b[i], equals(a[i]), reason: 'frame $i at $width');
          }
        }
      });
    });
  });
}
