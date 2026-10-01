import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/boss_audio_cues.dart';
import 'package:push_up_bird/game/boss_encounter_art.dart';
import 'package:push_up_bird/game/boss_health_bar_art.dart';
import 'package:push_up_bird/game/gargoyle_beam_art.dart';
import 'package:push_up_bird/game/gargoyle_body_art.dart';
import 'package:push_up_bird/game/gargoyle_boss_rig.dart';
import 'package:push_up_bird/game/gargoyle_encounter_art.dart';
import 'package:push_up_bird/game/gargoyle_encounter_ui.dart';
import 'package:push_up_bird/game/gargoyle_feather_art.dart';
import 'package:push_up_bird/game/gargoyle_kit.dart';
import 'package:push_up_bird/game/gargoyle_layout.dart';
import 'package:push_up_bird/game/gargoyle_pose.dart';
import 'package:push_up_bird/game/gargoyle_staging_art.dart';

import 'gargoyle_stage_support.dart';
import 'proof/counting_canvas.dart';

/// The Searchlight Gargoyle's staging (G8): where `BossEncounterArt` puts him in
/// the world and how he arrives, fights and falls. Pure assertions here (the
/// hooks, the clocks, the layers and budgets, Reduced Motion, a clock gone
/// wrong, the audio's edges against the picture's); the pixel scans (nothing
/// of him is ever clipped; a whole fight under the real rules) are in
/// `gargoyle_staging_scan_test.dart`, the review frames in
/// `gargoyle_staging_review_test.dart`.

const _size640 = ui.Size(640, 360), _size800 = ui.Size(800, 360);

/// The counting numbers of one encounter frame (backdrop, boss layer,
/// foreground and the plate).
Counting _count(SkyBoss boss, double width, {bool reduced = false, double birdY = .5, List<BossAmmo> ammo = const []}) {
  final c = Counting(ui.Canvas(ui.PictureRecorder()));
  final size = ui.Size(width, 360);
  final sim = simOf(boss, birdY: birdY, ammo: ammo);
  final m = motion(boss, reduced: reduced);
  BossEncounterArt.backdrop(c, size, boss, m);
  BossEncounterArt.paint(c, size, sim, m);
  BossEncounterArt.foreground(c, size, sim, m);
  BossHealthBarArt.paint(c, size, boss, reducedMotion: reduced);
  return c;
}

BossAmmo _feather(double x, double y) => BossAmmo(x: x, y: y, vx: -.36, vy: .3, gravity: .3, radius: .028, feather: true);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);

  // ------------------------------------------------------------ the hooks --
  group('the hooks are wired, explicitly, for him alone', () {
    test('the shared encounter draws his layer and his backdrop, not the placeholder or the Baron', () async {
      for (final w in const [640.0, 800.0]) {
        final boss = bossAt(4.5, width: w);
        final sim = simOf(boss);
        final size = ui.Size(w, 360);
        final shared = await raster((c) {
          BossEncounterArt.backdrop(c, size, boss, motion(boss));
          BossEncounterArt.paint(c, size, sim, motion(boss));
        }, w);
        final own = await raster((c) {
          GargoyleEncounterArt.backdrop(c, size, boss, motion(boss));
          GargoyleEncounterArt.paint(c, size, sim, motion(boss));
        }, w);
        expect(changed(shared, own), 0, reason: 'the shared encounter dispatches to the Gargoyle branches ($w)');
        // ... and that is not what the Baron's fall-through would draw there.
        final baron = SkyBoss(number: 1, x: boss.x, kind: BossKind.baronBat, cinematic: true)..age = boss.age;
        final baronSim = simOf(baron);
        final other = await raster((c) => BossEncounterArt.paint(c, size, baronSim, motion(baron)), w);
        expect(changed(shared, other), greaterThan(5000));
      }
    });

    test('the name card is his own, lands on the roar beat and carries the level\'s story line', () async {
      final sim = simOf(bossAt(-4.6 + 3.3, width: 800));
      expect(sim.levelId, '3-4', reason: 'the shared flight is level 3-4: a guardian level with a card line');
      expect(BossEncounterArt.bossLine(sim), '“${GargoyleEncounterUi.line}”');
      expect(BossEncounterArt.nameCardEyebrow(sim.boss!), 'GUARDIAN');
      Future<Uint8List> card(double age) {
        final b = bossAt(-4.6 + age, width: 800);
        final s = simOf(b);
        return raster((c) => BossEncounterArt.foreground(c, _size800, s, motion(b)), 800);
      }

      final before = await card(2.80), after = await card(2.95), none = await raster((c) {}, 800);
      expect(changed(before, none), lessThan(40000), reason: 'before the slam only the letterbox and the caption');
      // The card's own words, not the shared card's 'ENCOUNTER NN': the shared one would draw them at 1.65 s on.
      // Only the card's own region (the letterbox bars differ with the roar's opening).
      int inCard(Uint8List a, Uint8List b) {
        var n = 0;
        for (var y = 40; y < 220; y++) {
          for (var x = 0; x < 560; x++) {
            final i = (y * 800 + x) * 4;
            if (a[i] != b[i] || a[i + 1] != b[i + 1] || a[i + 2] != b[i + 2]) n++;
          }
        }
        return n;
      }

      final early = await card(2.2);
      expect(inCard(early, before), 0, reason: 'nothing of a card between 1.55 and 2.85 s');
      expect(inCard(after, before), greaterThan(8000));
    });

    test('the sky\'s light is the held region\'s: New York at night', () {
      final sim = simOf(bossAt(1));
      expect(sim.region, WorldRegion.newYork);
      expect(GargoyleEncounterArt.light(sim).dark, greaterThan(.6));
    });

    test('the warning and the beams come from the backdrop, the lens flares from the layer over his head', () async {
      final calm = bossAt(1.0), warn = bossAt(3.0), sweep = bossAt(4.5);
      int ops(SkyBoss b) {
        final rec = Rec();
        BossEncounterArt.backdrop(rec, _size640, b, motion(b));
        return rec.draws;
      }

      expect(ops(calm), lessThan(ops(warn)), reason: 'the warning is in the backdrop');
      expect(ops(calm), lessThan(ops(sweep)), reason: 'and so is the beam');
      final base = await raster((c) {}, 640);
      final flare = await raster((c) => GargoyleBeamArt.overBoss(c, _size640, sweep, motion(sweep)), 640);
      expect(changed(flare, base), greaterThan(150));
    });

    test('his feathers are drawn AFTER the rig: a feather over his head shows on top of it', () async {
      final boss = bossAt(1.0);
      final over = await raster((c) => encounter(c, boss, 640, ammo: [_feather(380 / 360, 90 / 360)]), 640);
      final plain = await raster((c) => encounter(c, boss, 640), 640);
      var n = 0;
      for (var y = 80; y < 100; y++) {
        for (var x = 370; x < 390; x++) {
          final i = (y * 640 + x) * 4;
          if ((over[i] - plain[i]).abs() + (over[i + 1] - plain[i + 1]).abs() > 30) n++;
        }
      }
      expect(n, greaterThan(60), reason: 'the feather is on top of the head');
    });

    test('the plate never hides a feather: a feather that touches it is drawn again over it', () async {
      final boss = bossAt(1.2);
      final feather = _feather(400 / 360, 14 / 360);
      final strip = BossHealthBarArt.bounds(_size640, boss);
      expect(strip.contains(ui.Offset(feather.x * 360, feather.y * 360)), isTrue, reason: 'the feather is under the plate\'s strip');
      final plain = await raster((c) => BossHealthBarArt.paint(c, _size640, boss), 640);
      final over = await raster((c) {
        BossHealthBarArt.paint(c, _size640, boss);
        GargoyleFeatherArt.overBar(c, _size640, [feather], boss);
      }, 640);
      expect(changed(plain, over), greaterThan(40));
    });

    testWidgets('the game itself paints it: BirdGame.render hits every hook (plate, feather over the plate, beams)', (tester) async {
      final s = await stage(tester, 640);
      s.fightTo(.3);
      s.sim.bossAmmo.add(_feather(400 / 360, 14 / 360));
      final without = await tester.runAsync(() async => rgba(await s.render()));
      s.sim.bossAmmo.clear();
      final plain = await tester.runAsync(() async => rgba(await s.render()));
      expect(changed(without!, plain!), greaterThan(40), reason: 'the feather shows through the plate in the real game');
    });
  });

  // ------------------------------------------------------- his health shows --
  group('his damage shows on the stone', () {
    test('the pose\'s damage is the share of health lost (a pure function of the rules); the cracks grow with it', () {
      GargoylePose at(int hp) {
        final b = bossAt(1.0)..hp = hp;
        return GargoylePose(b, motion(b));
      }

      expect(at(160).damage, 0);
      expect(at(120).damage, closeTo(.25, 1e-12));
      expect(at(80).damage, closeTo(.5, 1e-12));
      expect(at(0).damage, 1);
      expect(at(160).channels['damage'], 0);
      int ops(int hp) {
        final rec = Rec();
        GargoyleBodyArt.cracks(rec, GargoyleBodyPose.of(at(hp)));
        return rec.draws;
      }

      expect(ops(160), 0, reason: 'a whole statue has no crack');
      expect(ops(140), greaterThan(0), reason: 'hairlines from the first hits');
      expect(ops(100), greaterThan(0));
      // The rig draws more of him cracked at a third of his health gone than whole.
      double ink(int hp) {
        final b = bossAt(1.0)..hp = hp;
        final c = Counting(ui.Canvas(ui.PictureRecorder()));
        GargoyleBossRig.paintPose(c, GargoylePose(b, motion(b)));
        return c.draws.toDouble();
      }

      expect(ink(100), greaterThan(ink(160)));
    });

    test('a crack never drops to nothing at the killing blow', () {
      for (final fury in const [false, true]) {
        final live = bossAt(1.0, fury: fury)..hp = fury ? 80 : 20;
        final killed = bossAt(1.0, fury: fury, deadFor: 0)..hp = 0;
        final after = bossAt(1.0, fury: fury, deadFor: .1)..hp = 0;
        final c0 = GargoylePose(live, motion(live)).crack, c1 = GargoylePose(killed, motion(killed)).crack, c2 = GargoylePose(after, motion(after)).crack;
        expect(c1, greaterThanOrEqualTo(c0 - 1e-9), reason: 'fury $fury: the blow');
        expect(c2, greaterThanOrEqualTo(c1 - 1e-9), reason: 'fury $fury: just after');
      }
    });
  });

  // ------------------------------------------------------ the arrival clock --
  group('the arrival: stone to life', () {
    test('he is not drawn before the tower begins to slide (.95 s) and fades in over .25 s', () async {
      Future<int> solid(double age) async {
        final b = bossAt(age - 4.6);
        final sim = simOf(b);
        final px = await raster((c) => GargoyleEncounterArt.paint(c, _size640, sim, motion(b)), 640);
        final bg = await raster((c) {}, 640);
        return changed(px, bg);
      }

      expect(await solid(.2), 0, reason: 'nothing before .95 s: no sliver of beak at the edge');
      expect(await solid(.94), 0);
      final a = await solid(1.0), b = await solid(1.1), c = await solid(1.3);
      expect(a, greaterThan(0));
      expect(b, greaterThanOrEqualTo(a));
      expect(c, greaterThan(b));
    });

    test('the strike is the instant of the audio cue: the flash and the bolt begin at the frame the roar of the thunder does', () {
      Rec paintAt(double age, {bool reduced = false}) {
        final b = bossAt(age - 4.6);
        final rec = Rec();
        GargoyleEncounterArt.paint(rec, _size640, simOf(b), motion(b, reduced: reduced));
        return rec;
      }

      bool flash(Rec r) => r.rects.any((x) => x.rect == const ui.Rect.fromLTWH(0, 0, 640, 360) && x.color.a > .25);
      expect(flash(paintAt(1.64)), isFalse);
      expect(flash(paintAt(1.66)), isTrue);
      expect(flash(paintAt(1.66, reduced: true)), isFalse, reason: 'Reduced Motion never flashes');
      expect(flash(paintAt(1.95)), isFalse, reason: 'it is over in .25 s');
      // The bolt: draws before and after .. a path or two more once struck.
      expect(paintAt(1.66).draws, greaterThan(paintAt(1.64).draws + 3));
      expect(paintAt(1.66, reduced: true).draws, greaterThan(paintAt(1.64, reduced: true).draws), reason: 'a static bolt under Reduced Motion');
      expect(SkyBoss.revealAt, 1.65);
    });

    test('the letterbox is the dragon\'s: in for the storm, open for the roar, out 0.2 s early; his own after the blow', () {
      double bar(double age, {bool reduced = false, int? kind}) => GargoyleEncounterArt.focus(motion(bossAt(age - 4.6), reduced: reduced));
      double dragonBar(double age) {
        final d = SkyBoss(number: 5, x: 0, kind: BossKind.dragon, cinematic: true)..age = age;
        return BossEncounterArt.dragonFocus(motion(d));
      }

      for (var age = 0.0; age < 4.6; age += .05) {
        expect(bar(age), closeTo(dragonBar(age), 1e-9), reason: 'the dragon\'s timing at $age s');
      }
      expect(bar(.1), lessThan(bar(.5)));
      expect(bar(2.9), lessThan(bar(2.3) * .4), reason: 'open for the roar');
      expect(bar(4.2), lessThan(motion(bossAt(4.2 - 4.6)).focus), reason: 'it leaves .2 s earlier than the shared one');
      expect(bar(2.9, reduced: true), closeTo(GargoyleEncounterArt.reducedBars, 1e-9), reason: 'a still frame under Reduced Motion: thinner bars, no opening');
      expect(bar(1.2, reduced: true), closeTo(GargoyleEncounterArt.reducedBars, 1e-9));
      // After the blow it slides in behind the crumbling statue (.4 to 1.1 s).
      double dead(double d) => GargoyleEncounterArt.focus(motion(bossAt(1.0, deadFor: d)));
      expect(dead(.2), closeTo(0, 1e-6));
      expect(dead(.4), closeTo(0, 1e-6));
      expect(dead(.75), inInclusiveRange(.3, .7));
      expect(dead(1.1), closeTo(1, 1e-9));
      expect(dead(2.0), closeTo(1, 1e-9));
      expect(dead(3.8), lessThan(.01));
      expect(GargoyleEncounterArt.focus(motion(bossAt(2.0))), closeTo(0, 1e-9), reason: 'none in the fight');
      // Every other boss keeps the shared letterbox.
      final baron = SkyBoss(number: 1, x: 0, kind: BossKind.baronBat, cinematic: true)..age = 4.2;
      expect(motion(baron).focus, isNot(closeTo(bar(4.2), 1e-6)));
    });

    test('the tower\'s nest pigeon sleeps until the stone wakes, then wakes; the roost pigeons are the ones that fly', () {
      GargoylePose pose(double age, {bool reduced = false}) => GargoylePose(bossAt(age - 4.6), motion(bossAt(age - 4.6), reduced: reduced));
      expect(GargoyleStagingArt.pigeonState(pose(1.5)).sleep, 1);
      expect(GargoyleStagingArt.pigeonState(pose(2.5)).sleep, 0);
      expect(GargoyleStagingArt.pigeonState(pose(2.15)).sleep, inExclusiveRange(0, 1), reason: 'it lifts its head over .3 s, no pop');
      expect(GargoyleStagingArt.pigeonState(pose(1.5, reduced: true)).sleep, 0, reason: 'Reduced Motion sits awake');
      expect(GargoyleStagingArt.pigeonState(pose(1.5)).alpha, 1);
      // The roost: nine pigeons that stay until their own take-off, one every .05 s from 2.0 s.
      Future<int> roost(double age) async {
        final rec = Rec();
        GargoyleEncounterUi.roost(rec, const ui.Offset(300, 180), 360, age, reduced: false);
        return rec.draws;
      }

      return Future.wait([roost(1.5), roost(2.0), roost(2.5)]).then((r) {
        expect(r[0], greaterThan(0));
        expect(r[2], 0, reason: 'all nine have flown by 2.45 s');
      });
    });
  });

  // ----------------------------------------------------------- local jolts --
  group('his own jolts (never the shared camera)', () {
    test('a hit shivers him 1.5 px for .1 s, the killing blow 2.5 px for .12 s, the burst 3 px; Reduced Motion none', () {
      double j(SkyBoss b, {bool reduced = false}) => GargoyleEncounterArt.jolt(motion(b, reduced: reduced), 360).distance;
      expect(j(bossAt(1.0)), 0, reason: 'a perched statue is still');
      final hit = bossAt(7.0, hitAgo: .02);
      expect(j(hit), inInclusiveRange(.1, 2.5), reason: 'under the shared camera\'s own shake he shows .4 of it');
      expect(j(bossAt(7.0, hitAgo: .15)), 0);
      expect(j(hit, reduced: true), 0);
      expect(j(bossAt(1.0, deadFor: .03)), inInclusiveRange(1.0, 3.0));
      expect(j(bossAt(1.0, deadFor: .3)), 0);
      expect(j(bossAt(1.0, deadFor: .87)), inInclusiveRange(.3, 4.0), reason: 'the burst: 3 px decaying (.4 of it under the shared camera\'s shake)');
      expect(j(bossAt(1.0, deadFor: 2.0)), lessThan(.01));
      // At 800 x 360 the same; at a taller screen it scales.
      expect(GargoyleEncounterArt.jolt(motion(hit), 720).distance, closeTo(2 * GargoyleEncounterArt.jolt(motion(hit), 360).distance, 1e-9));
      // The shared camera's shake takes the rest: only .4 of his own while it shakes.
      final shaking = bossAt(1.0, deadFor: .87);
      expect(motion(shaking).shake, isNot(ui.Offset.zero));
      expect(GargoyleEncounterArt.underCamera(motion(shaking)), .4);
      expect(GargoyleEncounterArt.underCamera(motion(bossAt(1.0))), 1);
    });

    test('his heart is pinned: the rules\' x and the anchor\'s y, whatever the motion says', () {
      for (final (b, w) in [(bossAt(1.0), 640.0), (bossAt(-4.6 + 2.8, width: 800), 800.0), (bossAt(1.0, deadFor: .5), 640.0)]) {
        final m = motion(b);
        final f = GargoyleEncounterArt.frame(m, 360);
        expect(f.heart, ui.Offset(b.x * 360, SearchlightGargoyle.anchorY * 360));
        expect(f.unit, 360 * SkyBoss.radius);
        b.y = .9; // a wrong y from anywhere never moves him
        expect(GargoyleEncounterArt.frame(m, 360).heart.dy, SearchlightGargoyle.anchorY * 360, reason: 'w $w');
      }
    });
  });

  // -------------------------------------------------- layers and budgets --
  group('layers, blur and budgets', () {
    test('at most one layer, bounded to the rig, ever; no blur anywhere (card, bar and tags included)', () {
      var worstLayers = 0;
      for (final (name, mk) in encounterStates()) {
        for (final w in const [640.0, 800.0]) {
          final boss = mk(w);
          final sim = simOf(boss);
          final rec = Rec();
          final m = motion(boss);
          BossEncounterArt.backdrop(rec, ui.Size(w, 360), boss, m);
          BossEncounterArt.paint(rec, ui.Size(w, 360), sim, m);
          BossEncounterArt.foreground(rec, ui.Size(w, 360), sim, m);
          BossHealthBarArt.paint(rec, ui.Size(w, 360), boss);
          expect(rec.maxLayerDepth, lessThanOrEqualTo(1), reason: '$name @ $w: layers never stack');
          expect(rec.layers.length, lessThanOrEqualTo(1), reason: '$name @ $w');
          for (final l in rec.layers) {
            expect(l.bounds, GargoyleBossRig.bounds, reason: '$name @ $w: the layer is bounded to the rig');
          }
          expect(rec.blurs, 0, reason: '$name @ $w: no blur');
          worstLayers = math.max(worstLayers, rec.layers.length);
        }
      }
      expect(worstLayers, 1, reason: 'the white-out and the fade-in are the layer');
    });

    test('draw ops per frame stay inside the budget in every state (reported)', () {
      var worst = 0;
      var worstAt = '';
      for (final (name, mk) in encounterStates()) {
        for (final w in const [640.0, 800.0]) {
          final boss = mk(w);
          final ammo = boss.phase == BossPhase.attacking && boss.defeatedAt == null ? [_feather(.9, .3), _feather(1.1, .5)] : <BossAmmo>[];
          final c = _count(boss, w, ammo: ammo);
          expect(c.layers, lessThanOrEqualTo(1), reason: '$name @ $w');
          expect(c.blurs, 0, reason: '$name @ $w');
          if (c.draws > worst) {
            worst = c.draws;
            worstAt = '$name @ $w';
          }
        }
      }
      // ignore: avoid_print
      print('encounter frame: worst $worst ops at $worstAt');
      expect(worst, lessThanOrEqualTo(600), reason: 'rig 260 + tower 60 + beams 60 + HUD 60 + effects, whole frame (worst at $worstAt)');
    });

    test('the tower and its nest stay inside their share: <= 60 ops, 2 shaders, 1 clip, no layer', () {
      GargoyleKit.clearCaches();
      for (final (name, mk) in encounterStates()) {
        final pose = GargoylePose(mk(640), motion(mk(640)));
        final c = Counting(ui.Canvas(ui.PictureRecorder()));
        GargoyleStagingArt.ledge(c, pose);
        expect(c.draws, lessThanOrEqualTo(60), reason: name);
        expect(c.clips, lessThanOrEqualTo(1), reason: name);
        expect(c.layers, 0, reason: name);
        expect(c.blurs, 0, reason: name);
      }
      expect(GargoyleKit.built.where((k) => '$k'.startsWith('stage.')).length, 2, reason: 'the cornice\'s stone and the tower\'s own gradient');
    });

    test('a warm frame builds no shader: the first arrival frame builds them all, once, for the screen\'s own size', () {
      for (final w in const [640.0, 800.0]) {
        GargoyleKit.clearCaches();
        GargoyleEncounterArt.prewarm(ui.Size(w, 360));
        final before = GargoyleKit.built.length;
        // Every state of the arrival, the fight and the defeat, through the real
        // encounter (the tower and the rig, the beams, the feathers, the card, the
        // plate and every effect): nothing new is built after the prewarm.
        for (final (name, mk) in encounterStates()) {
          final boss = mk(w);
          final ammo = boss.phase == BossPhase.attacking && boss.defeatedAt == null ? [_feather(.9, .3)] : <BossAmmo>[];
          final sim = simOf(boss, ammo: ammo);
          final m = motion(boss);
          final c = ui.Canvas(ui.PictureRecorder());
          final size = ui.Size(w, 360);
          BossEncounterArt.backdrop(c, size, boss, m);
          BossEncounterArt.paint(c, size, sim, m);
          BossEncounterArt.foreground(c, size, sim, m);
          BossHealthBarArt.paint(c, size, boss);
          expect(GargoyleKit.built.length - before, 0, reason: '$name @ $w built ${GargoyleKit.built.skip(before).toList()} after the prewarm');
        }
      }
    });
  });

  // ------------------------------------------------------ reduced motion --
  group('Reduced Motion', () {
    test('the staging holds still: idle frames are identical at any age, the storm never flickers, the nest pigeon sits', () async {
      Future<Uint8List> frame(double combat) {
        final b = bossAt(combat);
        return raster((c) => encounter(c, b, 640, reduced: true), 640);
      }

      // Cycle-periodic idle moments 9 s apart (no feather, no beam): identical pixels.
      final a = await frame(1.05), b = await frame(1.05 + 9), c = await frame(1.05 + 27);
      expect(changed(a, b), 0);
      expect(changed(a, c), 0);
      // ... while the same moments with motion differ (the sway, the storm).
      Future<Uint8List> live(double combat) {
        final bb = bossAt(combat);
        return raster((cv) => encounter(cv, bb, 640), 640);
      }

      expect(changed(await live(1.05), await live(1.05 + 1.3)), greaterThan(0));
    });

    test('every state still tells: a warning, a hit, fury and the defeat all differ from the idle', () async {
      final idle = await raster((c) => encounter(c, bossAt(1.0), 640, reduced: true), 640);
      for (final b in [bossAt(3.0), bossAt(4.5), bossAt(7.0), bossAt(1.0, fury: true), bossAt(1.0, deadFor: 1.4)]) {
        final px = await raster((c) => encounter(c, b, 640, reduced: true), 640);
        expect(changed(px, idle), greaterThan(1500), reason: 'age ${b.age}');
      }
    });

    test('the arrival: a .25 s stone fade, a static bolt and no flash, no rain, no rings, no sweep', () {
      Rec rec(double age, bool reduced) {
        final b = bossAt(age - 4.6);
        final r = Rec();
        encounter(r, b, 640, reduced: reduced);
        return r;
      }

      for (final age in const [.6, 1.7, 2.8, 3.6, 3.95]) {
        final calm = rec(age, true), moving = rec(age, false);
        expect(calm.draws, lessThan(moving.draws), reason: 'age $age: the moving frame draws the extra (rain, rings, sweep, flush, flash)');
      }
      final b = bossAt(2.8 - 4.6);
      expect(GargoylePose(b, motion(b, reduced: true)).stone, 0);
      final c = bossAt(1.7 - 4.6);
      final p = GargoylePose(c, motion(c, reduced: true));
      expect(p.stone, inInclusiveRange(.2, .8), reason: 'the .25 s fade from 1.65 s');
    });

    test('the defeat: the white-out only holds, no burst flash, no tumbling visor, no flight', () {
      final b = bossAt(1.0, deadFor: .87);
      final sim = simOf(b);
      final rec = Rec();
      GargoyleEncounterArt.foreground(rec, _size640, sim, motion(b, reduced: true));
      expect(rec.draws, 0, reason: 'no screen flash');
      expect(GargoyleEncounterArt.jolt(motion(b, reduced: true), 360), ui.Offset.zero);
      expect(GargoyleStagingArt.pigeonState(GargoylePose(b, motion(b, reduced: true))).flight, 0, reason: 'the nest pigeon just goes');
    });
  });

  // -------------------------------------------------------------- defeat --
  group('the defeat', () {
    test('the white-out is the one layer, from the blow to .12 s; the fury\'s cracks do not pop at the blow', () {
      Rec at(double d) {
        final b = bossAt(1.0, deadFor: d);
        final r = Rec();
        GargoyleEncounterArt.paint(r, _size640, simOf(b), motion(b));
        return r;
      }

      expect(at(.05).layers.length, 1);
      expect(at(.05).layers.single.bounds, GargoyleBossRig.bounds);
      expect(at(.2).layers.length, 0, reason: 'clear by .12 s');
      // The fury's seam cracks carry through the blow (they used to drop to 0 and regrow).
      final live = GargoylePose(bossAt(1.0, fury: true), motion(bossAt(1.0, fury: true)));
      final killed = bossAt(1.0, fury: true, deadFor: 0)..hp = 0;
      final dying = GargoylePose(killed, motion(killed));
      expect(dying.crack, greaterThanOrEqualTo(live.crack - 1e-9), reason: 'no pop at the killing blow');
      final soon = bossAt(1.0, fury: true, deadFor: .02)..hp = 0;
      expect(GargoylePose(soon, motion(soon)).crack, greaterThanOrEqualTo(live.crack - 1e-9));
    });

    test('the burst flashes the whole screen .5 -> 0 over .18 s, at the burst, under the letterbox', () {
      double flash(double d) {
        final b = bossAt(1.0, deadFor: d);
        final r = Rec();
        GargoyleEncounterArt.foreground(r, _size640, simOf(b), motion(b));
        return r.rects.isEmpty ? 0 : r.rects.single.color.a;
      }

      expect(flash(.84), 0);
      expect(flash(.852), closeTo(.5, .02));
      expect(flash(.95), inInclusiveRange(.05, .4));
      expect(flash(1.05), 0);
      // The shared foreground draws no cream pop for him on top.
      final b = bossAt(1.0, deadFor: .852);
      final r = Rec();
      BossEncounterArt.foreground(r, _size640, simOf(b), motion(b));
      expect(r.rects.where((x) => x.color.a > .25 && x.rect == const ui.Rect.fromLTWH(0, 0, 640, 360)).length, 1);
    });

    test('the visor starts exactly on the slumped head and falls off the left of the ledge', () {
      final start = GargoyleBossRig.visorDrop(GargoyleTimeline.visorLostAt);
      final head = GargoylePose.atDeath(GargoyleTimeline.visorLostAt).headPoint(GargoyleLayout.visorSeat);
      expect((start.at - head).distance, lessThan(1e-9));
      // Drawn where the rig puts it (not the rest pose's anchor): the head is slumped by .3 s.
      expect((start.at - GargoylePose.still.headPoint(GargoyleLayout.visorSeat)).distance, greaterThan(.4));
    });

    test('the defeat never draws the shared generic death: no cream poof, no overload, no headwear tumble', () {
      // The generic death draws ten converging lines (the overload) before the burst.
      final b = bossAt(1.0, deadFor: .6);
      final gen = Rec(), own = Rec();
      GargoyleEncounterArt.paint(own, _size640, simOf(b), motion(b));
      BossEncounterArt.paint(gen, _size640, simOf(b), motion(b));
      expect(gen.draws, own.draws);
      expect(gen.layers.length, own.layers.length);
    });
  });

  // ---------------------------------------------------- a clock gone wrong --
  group('a boss the clock has broken draws nothing and throws nothing', () {
    test('NaN and infinite ages, places and sizes, in every layer', () async {
      for (final age in [double.nan, double.infinity, double.negativeInfinity, 1e300, -1e300]) {
        final b = bossAt(1.0)..age = age;
        final sim = simOf(b);
        final rec = Rec();
        expect(() {
          BossEncounterArt.backdrop(rec, _size640, b, motion(b));
          BossEncounterArt.paint(rec, _size640, sim, motion(b));
          BossEncounterArt.foreground(rec, _size640, sim, motion(b));
        }, returnsNormally, reason: 'age $age');
      }
      for (final x in [double.nan, double.infinity]) {
        final b = bossAt(1.0)..x = x;
        final rec = Rec();
        BossEncounterArt.paint(rec, _size640, simOf(b), motion(b));
        expect(rec.draws, 0, reason: 'x $x draws nothing');
      }
      final dying = bossAt(1.0, deadFor: .5)..defeatedAt = double.nan;
      final rec = Rec();
      expect(() => BossEncounterArt.paint(rec, _size640, simOf(dying), motion(dying)), returnsNormally);
      final b = bossAt(4.5);
      expect(() {
        final r = Rec();
        BossEncounterArt.paint(r, const ui.Size(double.nan, 360), simOf(b), motion(b));
        BossEncounterArt.backdrop(r, const ui.Size(0, 0), b, motion(b));
        BossEncounterArt.foreground(r, const ui.Size(640, double.infinity), simOf(b), motion(b));
      }, returnsNormally);
      // A NaN flight clock lights him neutrally.
      final cold = simOf(bossAt(1.0))..elapsed = double.nan;
      expect(GargoyleEncounterArt.light(cold).dark, GargoyleSkyLight.neutral.dark);
      expect(() => BossEncounterArt.paint(Rec(), _size640, cold, motion(cold.boss!)), returnsNormally);
      cold.elapsed = 40;
      // A NaN bird height and NaN ammo.
      final sim = simOf(bossAt(1.0), birdY: double.nan, ammo: [_feather(double.nan, double.nan)]);
      expect(() => BossEncounterArt.paint(Rec(), _size640, sim, motion(sim.boss!)), returnsNormally);
    });
  });

  // ------------------------------------------------ the picture is the audio --
  group('the audio\'s edges and the picture\'s', () {
    testWidgets('every cue fires in the frame its picture begins, in a flight under the real rules', (tester) async {
      final s = await stage(tester, 640);
      s.hold = true;
      final cues = BossAudioCues();
      // The tick (boss age) each cue first fires at, and each picture's first tick.
      final fired = <String, double>{};
      final seen = <String, double>{};
      void note(Map<String, double> into, String k, bool when, double age) {
        if (when) into.putIfAbsent(k, () => age);
      }

      void tick() {
        s.tick();
        final boss = s.boss;
        for (final cue in cues.advance(boss)) {
          fired.putIfAbsent(cue, () => boss.age);
        }
        final m = motion(boss);
        final pose = GargoylePose(boss, m);
        final age = boss.age;
        note(seen, 'gargoyle_strike', m.arriving && age - SkyBoss.revealAt >= 0, age);
        note(seen, 'gargoyle_awaken', m.arriving && pose.roar > 0, age);
        note(seen, 'beam_warning', pose.warning > 0, age);
        note(seen, 'beam_sweep', pose.beams.isNotEmpty && boss.beamOn && !m.defeated, age);
        note(seen, 'lamp_vent', pose.lamp > 0 && boss.phase == BossPhase.attacking, age);
        note(seen, 'feather_drop', pose.shedTau >= 0 && boss.phase == BossPhase.attacking, age);
        note(seen, 'boss_hit', pose.hit > 0 && boss.lastDamage > 0, age);
        note(seen, 'lamp_glance', pose.glance > 0, age);
        note(seen, 'gargoyle_fury', pose.rage > 0 && !m.defeated, age);
        note(seen, 'boss_break', m.defeated && m.death >= 0, age);
        note(seen, 'gargoyle_shatter', m.defeated && m.death >= SkyBoss.burstAt, age);
        note(seen, 'beam_spot', GargoyleBeamArt.spotOf(s.sim) != null, age);
        note(seen, 'boss_victory', m.defeated && m.death >= 1.55, age);
      }

      void runTo(double age) {
        var guard = 0;
        while (s.sim.boss != null && s.boss.age < age - 1e-6 && guard++ < 6000) {
          tick();
        }
      }

      runTo(s.boss.arrivalDuration);
      final t0 = s.boss.arrivalDuration;
      // A glance on the shut lamp; the first feather launches at .2 s.
      s.birdY = .5;
      runTo(t0 + .9);
      s.rock();
      runTo(t0 + 1.9);
      s.birdY = .28; // aim HIGH at the warning (latched at 2.0 s from where the bird is)
      runTo(t0 + 3.6);
      s.birdY = .8;
      runTo(t0 + 4.4);
      // The bird caught in the lit band.
      s.birdY = .31;
      s.vulnerable = true;
      runTo(t0 + 4.8);
      s.vulnerable = false;
      s.birdY = .56;
      runTo(t0 + 7.0);
      s.rock(); // a hit on the open lamp
      runTo(t0 + 7.4);
      // The blow that crosses into fury.
      s.boss.hp = s.boss.maxHp ~/ 2 + 5;
      s.rock();
      runTo(t0 + 8.6);
      // Then the killing blow in the next vent.
      runTo(t0 + 9 + 7.0);
      s.boss.hp = 10;
      s.rock();
      runTo(t0 + 9 + 7.0 + 3.0);

      final tickSeconds = 1 / 60;
      // Cues whose picture begins on the same tick (or the next one: the cue is
      // raised by the step, the picture is read after it).
      for (final cue in ['gargoyle_strike', 'gargoyle_awaken', 'beam_warning', 'beam_sweep', 'beam_spot', 'lamp_vent', 'feather_drop', 'boss_hit', 'lamp_glance', 'gargoyle_fury', 'boss_break', 'gargoyle_shatter']) {
        expect(fired.containsKey(cue), isTrue, reason: 'the flight raised $cue');
        expect(seen.containsKey(cue), isTrue, reason: 'the picture of $cue appeared');
        expect((fired[cue]! - seen[cue]!).abs(), lessThanOrEqualTo(tickSeconds + 1e-6), reason: '$cue: cue at ${fired[cue]}, picture at ${seen[cue]}');
      }
      // The victory sound rings with its card (it was .25 s after it, the dragon's offset: the
      // audio fix round moved the mini-bosses' to 1.55 s).
      expect((fired['boss_victory']! - seen['boss_victory']!).abs(), lessThanOrEqualTo(tickSeconds + 1e-6));
    }, timeout: const Timeout(Duration(minutes: 3)));
  });
}
