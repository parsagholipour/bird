import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/sky_boss.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/gargoyle_encounter_ui.dart';
import 'package:push_up_bird/game/gargoyle_feather_art.dart';
import 'package:push_up_bird/game/gargoyle_hud_art.dart';
import 'package:push_up_bird/game/gargoyle_kit.dart';
import 'package:push_up_bird/game/gargoyle_layout.dart';
import 'package:push_up_bird/game/gargoyle_staging_art.dart';
import 'package:push_up_bird/game/gargoyle_wing_art.dart';

import 'proof/counting_canvas.dart';
import 'proof/gargoyle_raster.dart';
import 'proof/gargoyle_stage.dart';

/// The small parts: feathers (G6), HUD skin and card (G7), staging (G8) and the
/// wings' flying blade (G3): their first cuts keep the contract each owner must
/// keep. (The budget, envelope, determinism and silhouette tests cover them as
/// part of the rig and the frame.)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Fredoka')..addFont(rootBundle.load('assets/fonts/Fredoka.ttf'))).load();
  });

  group('the stone feather (G6)', () {
    Future<Mask> scan(BossAmmo a, {double h = 360, bool reduced = false}) =>
        rasterize((c) => GargoyleFeatherArt.paint(c, h, a, seconds: 2, reducedMotion: reduced), ppu: 1, region: const ui.Rect.fromLTRB(0, 0, 640, 360), solid: 200);

    testWidgets('its solid body ends ON the hit circle: what you see is what hurts', (tester) async {
      await tester.runAsync(() async {
        for (final h in const [360.0, 720.0]) {
          final a = BossAmmo(x: .6, y: .5, vx: -.36, vy: 0, gravity: .30, radius: .028, feather: true);
          final m = await rasterize((c) => GargoyleFeatherArt.paint(c, h, a, reducedMotion: true), ppu: 1, region: ui.Rect.fromLTRB(0, 0, h * 2, h), solid: 200);
          final cx = a.x * h, cy = a.y * h;
          var far = 0.0;
          for (var y = 0; y < m.h; y++) {
            for (var x = 0; x < m.w; x++) {
              if (!m.at(x, y)) continue;
              far = math.max(far, math.sqrt(math.pow(x + .5 - cx, 2) + math.pow(y + .5 - cy, 2)));
            }
          }
          final r = a.radius * h;
          expect(far, inInclusiveRange(r - 1.5, r + r * .3), reason: 'h $h: the solid body reaches $far px, the hit radius is $r');
          expect(GargoyleFeatherArt.bodyRadius(a, h), closeTo(r, 1e-9));
        }
      });
    });

    testWidgets('it points along its velocity; Reduced Motion does not flutter', (tester) async {
      await tester.runAsync(() async {
        final a = BossAmmo(x: .9, y: .3, vx: -.36, vy: .3, gravity: .30, radius: .028, feather: true);
        final live = await scan(a);
        final rm = await scan(a, reduced: true);
        final rm2 = await rasterize((c) => GargoyleFeatherArt.paint(c, 360, a, seconds: 7.3, reducedMotion: true), ppu: 1, region: const ui.Rect.fromLTRB(0, 0, 640, 360), solid: 200);
        expect(rm.solid, rm2.solid, reason: 'still under Reduced Motion');
        expect(live.area, closeTo(rm.area, rm.area * .25));
      });
    });

    test('dust: nothing without progress or under Reduced Motion, a few puffs bounded otherwise', () {
      final counting = Counting(ui.Canvas(ui.PictureRecorder()));
      GargoyleFeatherArt.dust(counting, const ui.Size(640, 360), 0, .47 + .62);
      GargoyleFeatherArt.dust(counting, const ui.Size(640, 360), .5, 1.09, reducedMotion: true);
      expect(counting.draws, 0);
      GargoyleFeatherArt.dust(counting, const ui.Size(640, 360), .5, 1.09);
      expect(counting.draws, inInclusiveRange(1, 8));
    });

    test('glance sparks: bounded and gone at 0', () {
      final counting = Counting(ui.Canvas(ui.PictureRecorder()));
      GargoyleFeatherArt.glance(counting, ui.Offset.zero, 40, 0);
      expect(counting.draws, 0);
      GargoyleFeatherArt.glance(counting, ui.Offset.zero, 40, .5);
      expect(counting.draws, inInclusiveRange(1, 8));
    });
  });

  group('the health bar skin and the card (G7)', () {
    test('the gauge ramps run light, main, deep: brass to amber, and white-hot to orange in fury', () {
      for (final fury in [false, true]) {
        final r = GargoyleHudArt.ramp(fury: fury);
        expect(r.length, 3);
        expect(r[0].computeLuminance(), greaterThan(r[1].computeLuminance()));
        expect(r[1].computeLuminance(), greaterThan(r[2].computeLuminance()));
      }
      expect(GargoyleHudArt.label, 'GARGOYLE');
      expect(GargoyleHudArt.label.length, lessThanOrEqualTo(9), reason: 'the 84 px name field');
    });

    testWidgets('the medallion is a lens that glows; fury rings it orange', (tester) async {
      await tester.runAsync(() async {
        Future<Mask> m(bool fury, double glow) => rasterize(
          (c) => GargoyleHudArt.crest(c, const ui.Offset(20, 20), 10, fury: fury, glow: glow),
          ppu: 1,
          region: const ui.Rect.fromLTRB(0, 0, 40, 40),
          solid: 200,
        );
        final calm = await m(false, .3);
        final furious = await m(true, 1);
        // The medallion is a brass octagon (the lamp's own housing) with his second
        // lens docked on it: about twice the lens's radius, never beyond 3x.
        expect(calm.bounds!.rect.width, inInclusiveRange(19, 30));
        var diff = 0;
        for (var i = 0; i < calm.data.length; i++) {
          if ((calm.data[i] - furious.data[i]).abs() > 20) diff++;
        }
        expect(diff, greaterThan(20));
      });
    });

    test('the card is his own while he arrives (true) and the shared card stays at any other time (false); its words are the report\'s', () {
      // G7's real card: true during the entrance (so the shared card must not
      // show early), false once he is fighting. (The contract's first cut
      // returned false always and said MINI-BOSS; R5 made the word GUARDIAN.)
      final fighting = gBoss(3.0), arriving = gBoss(-1.5);
      final canvas = ui.Canvas(ui.PictureRecorder());
      expect(GargoyleEncounterUi.nameCard(canvas, const ui.Size(640, 360), fighting, BossMotion(fighting, reducedMotion: false)), isFalse);
      expect(GargoyleEncounterUi.nameCard(canvas, const ui.Size(640, 360), arriving, BossMotion(arriving, reducedMotion: false)), isTrue);
      expect(GargoyleEncounterUi.tag, 'GUARDIAN');
      expect(GargoyleEncounterUi.epithet, fighting.title);
      expect(GargoyleEncounterUi.line, 'Hold still! Nobody ever stays in the light.');
      expect(GargoyleEncounterUi.line.length, 43);
      expect(GargoyleEncounterUi.fightCaption, contains('STAY OUT OF THE LIGHT'));
    });
  });

  group('the stage (G8)', () {
    testWidgets('the ledge lip is at y 2.95, the pier starts at x 3.55 (and runs well off the top), the vane mount is empty and on the lip', (tester) async {
      await tester.runAsync(() async {
        final pose = poseOf(gBoss(1.0));
        final m = await rasterize((c) => GargoyleStagingArt.ledge(c, pose), ppu: 20, region: const ui.Rect.fromLTRB(-7, -6, 8, 6), solid: 200);
        bool solidAt(double x, double y) => m.at(((x - m.x0) * m.ppu).floor(), ((y - m.y0) * m.ppu).floor());
        expect(solidAt(0, GargoyleLayout.ledgeY + .15), isTrue, reason: 'the lip');
        expect(solidAt(0, GargoyleLayout.ledgeY - .3), isFalse, reason: 'air above the lip (the talons are the creature\'s)');
        expect(solidAt(GargoyleLayout.pierX + .3, -4), isTrue, reason: 'the pier runs off the top');
        expect(solidAt(GargoyleLayout.pierX - .3, -4), isFalse);
        expect(solidAt(GargoyleLayout.vaneMount.dx, 2.2), isTrue, reason: 'the vane rod');
        expect(solidAt(GargoyleLayout.vaneMount.dx, 1.2), isFalse, reason: 'and nothing on it: the courier brings the vane');
        expect(solidAt(GargoyleLayout.ledgeLip - .3, GargoyleLayout.ledgeY + .15), isFalse, reason: 'the lip starts at ledgeLip (-3.0)');
      });
    });

    test('the dormant stone greys the ledge with the creature', () {
      final a = poseOf(gBoss(1.0 - 4.6)).tone, b = poseOf(gBoss(1.0)).tone;
      expect(a.stone, 1);
      expect(b.stone, 0);
    });
  });

  group('the wings\' flying blade (G3)', () {
    testWidgets('it leaves the near fan\'s top blade and flies up and away; nothing before the launch or after .6 s', (tester) async {
      await tester.runAsync(() async {
        final pose = poseOf(gBoss(4.6 + .3));
        final wing = GargoyleWing.nearOf(pose);
        final tip = wing.tips[GargoyleLayout.shedBlade];
        ui.Offset centre(double tau) {
          return tip + GargoyleLayout.shedVelocity * tau + ui.Offset(0, 9 * tau * tau);
        }

        expect(centre(.4).dy, lessThan(tip.dy - 1.0), reason: 'up and away');
        expect(centre(.6).dy, lessThan(tip.dy), reason: 'still above the fan when it has faded');
        for (final tau in const [-.1, .7]) {
          final counting = Counting(ui.Canvas(ui.PictureRecorder()));
          GargoyleWingArt.shedBlade(counting, wing, tau);
          expect(counting.draws, 0, reason: 'tau $tau');
        }
        final counting = Counting(ui.Canvas(ui.PictureRecorder()));
        GargoyleWingArt.shedBlade(counting, wing, .3);
        expect(counting.draws, 2);
        expect(GargoyleKit.cacheSize, greaterThanOrEqualTo(0));
      });
    });
  });
}
