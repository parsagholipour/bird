import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/boss_encounter_art.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/neferhoo_encounter_art.dart';
import 'package:push_up_bird/game/neferhoo_encounter_ui.dart';
import 'package:push_up_bird/game/neferhoo_pose.dart';

import 'neferhoo_stage_support.dart';
import 'proof/counting_canvas.dart';

/// Neferhoo's staging (A2, design §5.6): where `BossEncounterArt` puts him and
/// how he arrives (the pyramid's courier door, the sand devil, his
/// silhouette, the reveal, HOO-POO-POO, his name card) and falls (the
/// hit-stop, the mask popping off, the dead letters, the lost letter,
/// GUARDIAN DOWN!), on the shared clocks the shared cues use; one bounded
/// layer at most, no blur; Reduced Motion; a broken clock; and the door
/// bolted to the backdrop's pyramid.

const _w = [640.0, 800.0, 864.0];

/// The 2-6 flight at his arrival, its boss set to [age] (and beaten at
/// [defeatedAt]).
({FlightSimulation sim, SkyBoss boss}) _at(double age, {double width = 640, double? defeatedAt}) {
  final sim = neferhooArrival(width: width / 360);
  final boss = sim.boss!
    ..age = age
    ..defeatedAt = defeatedAt;
  return (sim: sim, boss: boss);
}

BossMotion _m(SkyBoss boss, {bool reduced = false}) => BossMotion(boss, reducedMotion: reduced);

Future<Uint8List> _paint(FlightSimulation sim, SkyBoss boss, double width, {bool reduced = false}) {
  final size = ui.Size(width, 360);
  return raster((c) => NeferhooEncounterArt.paint(c, size, sim, _m(boss, reduced: reduced)), width);
}

/// The mean brightness (0..255) of a raster.
double _bright(Uint8List a) {
  var s = 0.0;
  for (var i = 0; i < a.length; i += 4) {
    s += (a[i] + a[i + 1] + a[i + 2]) / 3 * a[i + 3] / 255;
  }
  return s / (a.length / 4);
}

/// Counts what one encounter frame asks of the canvas (backdrop and his
/// layer, then the foreground with the cards).
({Counting paint, Counting fore}) _count(FlightSimulation sim, SkyBoss boss, double width, {bool reduced = false}) {
  final size = ui.Size(width, 360);
  final m = _m(boss, reduced: reduced);
  final p = Counting(ui.Canvas(ui.PictureRecorder()));
  BossEncounterArt.backdrop(p, size, boss, m);
  BossEncounterArt.paint(p, size, sim, m);
  final f = Counting(ui.Canvas(ui.PictureRecorder()));
  BossEncounterArt.foreground(f, size, sim, m);
  return (paint: p, fore: f);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);

  group('the hooks are his', () {
    test('the shared encounter dispatches every slot to his own, never the Baron\'s', () async {
      for (final w in _w) {
        for (final (age, dead) in const [(1.2, null), (3.2, null), (6.0, null), (6.9, 5.9), (8.0, 5.9)]) {
          final s = _at(age, width: w, defeatedAt: dead);
          final size = ui.Size(w, 360);
          final m = _m(s.boss);
          final shared = await raster((c) {
            BossEncounterArt.backdrop(c, size, s.boss, m);
            BossEncounterArt.paint(c, size, s.sim, m);
          }, w);
          final own = await raster((c) {
            NeferhooEncounterArt.backdrop(c, size, s.boss, m);
            NeferhooEncounterArt.paint(c, size, s.sim, m);
          }, w);
          expect(changed(shared, own, tolerance: 0), 0, reason: '$w at $age');
        }
      }
    });

    test('his words: the omen, the caption, GUARDIAN, the level\'s line', () {
      final s = _at(3.3);
      expect(NeferhooEncounterArt.omenLine, 'The pyramid’s dust is stirring…');
      expect(NeferhooEncounterArt.caption, contains('SHOOT HIS LETTERS BACK'));
      expect(BossEncounterArt.nameCardEyebrow(s.boss), 'GUARDIAN');
      expect(BossEncounterArt.bossLine(s.sim), NeferhooEncounterUi.line);
      expect(BossEncounterArt.victoryTitle(s.boss), NeferhooEncounterUi.victoryTitle);
    });
  });

  group('the arrival keeps the shared clocks', () {
    test('a silhouette in the whirl until the reveal (1.65 s, boss_reveal); his colours fade in through one bounded layer by 2.45 s', () {
      expect(SkyBoss.revealAt, 1.65);
      for (final w in _w) {
        final before = _at(SkyBoss.revealAt - .02, width: w);
        expect(_count(before.sim, before.boss, w).paint.layers, 0, reason: 'only the silhouette ($w)');
        final during = _at(SkyBoss.revealAt + .2, width: w);
        expect(_count(during.sim, during.boss, w).paint.layers, 1, reason: 'the colour fading in ($w)');
        final after = _at(2.5, width: w);
        expect(_count(after.sim, after.boss, w).paint.layers, 0, reason: 'drawn straight once revealed ($w)');
      }
    });

    test('HOO-POO-POO: three beak pulses from the roar (2.65 s), .15 s apart, over by 3.1 s', () {
      expect(NeferhooEncounterArt.syllables.first, SkyBoss.roarAt);
      expect(NeferhooEncounterArt.beakPulse(SkyBoss.roarAt - .01), 0);
      for (final s in NeferhooEncounterArt.syllables) {
        expect(NeferhooEncounterArt.beakPulse(s + .075), closeTo(1, 1e-9));
      }
      expect(NeferhooEncounterArt.beakPulse(3.1), 0);
      expect(NeferhooEncounterArt.arrivalPose(SkyBoss.roarAt + .075).beak, closeTo(1, 1e-9));
    });

    test('the arrival\'s last frame is the fight\'s first: his place and his pose', () {
      for (final w in _w) {
        final size = ui.Size(w, 360);
        final sim = neferhooArrival(width: w / 360);
        final boss = sim.boss!;
        expect(boss.arrivalDuration, NeferhooEncounterArt.arrivalSeconds);
        // Fly the real rules to the first frame of the fight.
        while (boss.phase == BossPhase.arriving) {
          sim
            ..birdY = .5
            ..invulnerableUntil = sim.elapsed + 1;
          frame(sim, width: w / 360);
        }
        final staged = NeferhooEncounterArt.arrivalAt(size, NeferhooEncounterArt.arrivalSeconds);
        expect(staged.dx, closeTo(boss.x * 360, .5), reason: 'x ($w)');
        expect(staged.dy, closeTo(Neferhoo.hoverY(0) * 360, 1e-9), reason: 'y ($w)');
        expect(boss.y * 360, closeTo(staged.dy, 360 * .04 * .85 / 60 + .01), reason: 'the hover moves on from there ($w)');
        final m = _m(boss);
        final fight = NeferhooPose.fight(boss, m);
        final last = NeferhooEncounterArt.arrivalPose(NeferhooEncounterArt.arrivalSeconds, fight: fight);
        for (final (name, a, b) in [
          ('crest', last.crest, fight.crest),
          ('wing', last.wing, fight.wing),
          ('glow', last.glow, fight.glow),
          ('brow', last.brow, fight.brow),
          ('lean', last.lean, fight.lean),
          ('ribbons', last.ribbons, fight.ribbons),
        ]) {
          expect(a, closeTo(b, 1e-9), reason: '$name ($w)');
        }
      }
    });

    test('the name card is his own: nothing before 2.85 s, landed by 3.3 s, gone by 4.5 s; never the shared card', () async {
      for (final w in _w) {
        final size = ui.Size(w, 360);
        Future<Uint8List> card(double age) {
          final s = _at(age, width: w);
          return raster((c) {
            final own = NeferhooEncounterUi.nameCard(c, size, s.boss, _m(s.boss), birdY: .5, line: BossEncounterArt.bossLine(s.sim));
            expect(own, isTrue, reason: 'the card is his through the arrival ($age)');
          }, w);
        }

        final blank = await raster((c) {}, w);
        expect(changed(await card(2.80), blank), 0, reason: 'before the roar\'s last syllable ($w)');
        final landed = await card(3.4);
        final rect = NeferhooEncounterUi.cardRect(size);
        expect(changed(landed, blank), greaterThan(rect.width * rect.height * .7), reason: 'the card fills its plate ($w)');
        final ink = inked(landed, w.toInt())!;
        expect(rect.inflate(40).contains(ink.topLeft) && rect.inflate(40).contains(ink.bottomRight), isTrue, reason: '$ink in $rect');
        expect(ink.right, lessThan(NeferhooEncounterArt.arrivalAt(size, 3.4).dx - 360 * .115 * 1.2), reason: 'left of centre, clear of his head ($w)');
        expect(changed(await card(4.5), blank), 0, reason: 'gone before control returns ($w)');
        // In the fight the card is not his to draw.
        final fight = _at(6.0, width: w);
        expect(NeferhooEncounterUi.nameCard(ui.Canvas(ui.PictureRecorder()), size, fight.boss, _m(fight.boss), birdY: .5), isFalse);
      }
    });

    test('the level\'s number and line only in the campaign', () async {
      expect(NeferhooEncounterUi.levelId, '2-6');
      expect(NeferhooEncounterUi.ribbon(campaign: true), 'GUARDIAN · 2-6');
      expect(NeferhooEncounterUi.ribbon(campaign: false), 'GUARDIAN');
      const size = ui.Size(640, 360);
      final s = _at(3.6);
      Future<Uint8List> card(String? line) => raster(
        (c) => NeferhooEncounterUi.nameCard(c, size, s.boss, _m(s.boss), birdY: .5, line: line),
        640,
      );
      final campaign = await card(BossEncounterArt.bossLine(s.sim));
      final none = await card(null);
      expect(changed(campaign, none), greaterThan(400), reason: 'the ribbon\'s number and the inked line');
    });
  });

  group('the defeat keeps the shared clocks', () {
    test('the hit-stop flashes to .12 s; the mask pops at the burst (.85 s); the lost letter rises from .95 s', () async {
      expect(SkyBoss.burstAt, .85);
      expect(NeferhooEncounterArt.defeatPose(.84).mask, isTrue);
      expect(NeferhooEncounterArt.defeatPose(.86).mask, isFalse);
      expect(NeferhooEncounterArt.defeatPose(.86).specs, isTrue, reason: 'a kindly old hoopoe with spectacles');
      for (final w in _w) {
        Future<Uint8List> at(double d, {bool reduced = false}) {
          final s = _at(6 + d, width: w, defeatedAt: 6);
          return _paint(s.sim, s.boss, w, reduced: reduced);
        }

        expect(_bright(await at(.02)) - _bright(await at(.2)), greaterThan(60), reason: 'the white hit-stop ($w)');
        final pre = await at(SkyBoss.burstAt - .01), post = await at(SkyBoss.burstAt + .03);
        expect(changed(pre, post), greaterThan(8000), reason: 'the pop: mask off, flash, ring, letters ($w)');
        expect(changed(await at(.93), await at(1.05)), greaterThan(2000), reason: 'the lost letter rising ($w)');
        final blank = await raster((c) {}, w);
        expect(changed(await at(3.95), blank), 0, reason: 'all gone by 3.9 s ($w)');
      }
    });

    test('GUARDIAN DOWN! · THE LOST LETTER IS FOUND from 1.55 s, his own card', () async {
      for (final w in _w) {
        final size = ui.Size(w, 360);
        Future<Uint8List> fore(double d) {
          final s = _at(6 + d, width: w, defeatedAt: 6);
          return raster((c) => NeferhooEncounterUi.victory(c, size, _m(s.boss)), w);
        }

        final blank = await raster((c) {}, w);
        expect(changed(await fore(1.5), blank), 0);
        expect(changed(await fore(2.2), blank), greaterThan(12000), reason: '$w');
        expect(changed(await fore(3.85), blank), 0);
        // The shared victory slot draws his.
        final s = _at(8.2, width: w, defeatedAt: 6);
        final shared = await raster((c) => BossEncounterArt.foreground(c, size, s.sim, _m(s.boss)), w);
        expect(changed(shared, blank), greaterThan(12000));
      }
    });

    test('the letterbox slides in behind him (.4 to 1.1 s) instead of cutting across the hit-stop', () {
      final s = _at(6.3, defeatedAt: 6);
      expect(NeferhooEncounterArt.focus(_m(s.boss)), 0);
      s.boss.age = 7.2;
      expect(NeferhooEncounterArt.focus(_m(s.boss)), closeTo(_m(s.boss).focus, 1e-9));
    });
  });

  group('cost, Reduced Motion, a broken clock', () {
    test('every 1/30 s of the arrival and the defeat: at most one bounded layer in his layer, one in the cards, no blur; none in the fight', () {
      for (final w in _w) {
        for (final reduced in [false, true]) {
          for (var t = 0.0; t < 4.6; t += 1 / 30) {
            final s = _at(t, width: w);
            final c = _count(s.sim, s.boss, w, reduced: reduced);
            expect(c.paint.layers, lessThanOrEqualTo(1), reason: 'arrival $t ($w, $reduced)');
            expect(c.fore.layers, lessThanOrEqualTo(1), reason: 'card $t ($w, $reduced)');
            expect(c.paint.blurs + c.fore.blurs, 0);
          }
          for (var d = 0.0; d < 3.9; d += 1 / 30) {
            final s = _at(6 + d, width: w, defeatedAt: 6);
            final c = _count(s.sim, s.boss, w, reduced: reduced);
            expect(c.paint.layers + c.fore.layers, lessThanOrEqualTo(2), reason: 'defeat $d ($w, $reduced): ${c.paint.layers} + ${c.fore.layers}');
            expect(c.paint.layers, lessThanOrEqualTo(1), reason: 'defeat $d ($w, $reduced)');
            expect(c.paint.blurs + c.fore.blurs, 0);
          }
          for (var t = 0.0; t < 12; t += .25) {
            final s = _at(4.6 + t, width: w);
            expect(_count(s.sim, s.boss, w, reduced: reduced).paint.layers, 0, reason: 'fight $t');
          }
        }
      }
    });

    test('the arrival\'s and the defeat\'s busiest frames stay under 700 draws', () {
      var arrival = 0, defeat = 0;
      for (var t = 0.0; t < 4.6; t += 1 / 30) {
        final s = _at(t);
        final c = _count(s.sim, s.boss, 640);
        arrival = c.paint.draws + c.fore.draws > arrival ? c.paint.draws + c.fore.draws : arrival;
      }
      for (var d = 0.0; d < 3.9; d += 1 / 30) {
        final s = _at(6 + d, defeatedAt: 6);
        final c = _count(s.sim, s.boss, 640);
        defeat = c.paint.draws + c.fore.draws > defeat ? c.paint.draws + c.fore.draws : defeat;
      }
      // ignore: avoid_print
      print('peak draws: arrival $arrival, defeat $defeat');
      expect(arrival, lessThan(700));
      expect(defeat, lessThan(700));
    });

    test('Reduced Motion: no flashes, the whirl holds still, he still arrives and falls', () async {
      for (final w in _w) {
        Future<Uint8List> arr(double t, bool reduced) {
          final s = _at(t, width: w);
          return _paint(s.sim, s.boss, w, reduced: reduced);
        }

        Future<Uint8List> dead(double d, bool reduced) {
          final s = _at(6 + d, width: w, defeatedAt: 6);
          return _paint(s.sim, s.boss, w, reduced: reduced);
        }

        // The reveal's white flash, the hit-stop's and the pop's: not under RM.
        expect((_bright(await arr(1.67, true)) - _bright(await arr(1.62, true))).abs(), lessThan(8), reason: 'reveal ($w)');
        expect(_bright(await arr(1.67, false)) - _bright(await arr(1.62, false)), greaterThan(15), reason: 'the normal flash ($w)');
        expect((_bright(await dead(.02, true)) - _bright(await dead(.2, true))).abs(), lessThan(10), reason: 'hit-stop ($w)');
        // A thirtieth of a second in the whirl changes far less under RM.
        final normal = changed(await arr(1.9, false), await arr(1.9 + 1 / 30, false));
        final still = changed(await arr(1.9, true), await arr(1.9 + 1 / 30, true));
        expect(still, lessThan(normal * .5), reason: 'whirl ($w): $still vs $normal');
        // ... and the story still happens: revealed, then gone.
        final blank = await raster((c) {}, w);
        expect(changed(await arr(3.0, true), blank), greaterThan(20000));
        expect(changed(await dead(2.0, true), blank), greaterThan(10000));
        expect(changed(await dead(3.95, true), blank), 0);
      }
    });

    test('pure: the same moment paints the same pixels', () async {
      for (final (t, d) in const [(1.3, null), (2.8, null), (7.1, 6.0)]) {
        final a = _at(t, defeatedAt: d), b = _at(t, defeatedAt: d);
        expect(changed(await _paint(a.sim, a.boss, 640), await _paint(b.sim, b.boss, 640), tolerance: 0), 0, reason: '$t');
      }
    });

    test('a broken clock or place draws nothing and never throws', () async {
      final blank = await raster((c) {}, 640);
      for (final bad in [double.nan, double.infinity]) {
        final s = _at(2);
        s.boss.age = bad;
        expect(changed(await _paint(s.sim, s.boss, 640), blank), 0);
        final t = _at(3);
        t.boss.x = bad;
        expect(changed(await _paint(t.sim, t.boss, 640), blank), 0);
        expect(NeferhooEncounterArt.focus(_m(s.boss)), 0);
        await raster((c) => BossEncounterArt.foreground(c, const ui.Size(640, 360), s.sim, _m(s.boss)), 640);
      }
    });
  });

  group('the courier door is bolted to the pyramid', () {
    test('the backdrop\'s Khufu is where the door expects it', () {
      final egypt = File('lib/game/regions/egypt.dart').readAsStringSync();
      expect(egypt, contains('_pyramids(c, w * .535, h, w)'));
      expect(NeferhooEncounterArt.khufuShare, .535);
    });

    test('it follows the far band\'s drift; none outside Egypt', () {
      for (final w in _w) {
        final s = _at(.6, width: w);
        final size = ui.Size(w, 360);
        final door = NeferhooEncounterArt.doorAt(size, s.sim, reduced: false);
        expect(door, isNotNull, reason: '$w');
        expect(door!.dy, closeTo(360 * .575, 1e-9));
        expect(door.dx, inInclusiveRange(0, w), reason: 'on screen ($w)');
        // Reduced Motion: the bands stand still, the door is on the opening
        // composition's pyramid.
        final still = NeferhooEncounterArt.doorAt(size, s.sim, reduced: true)!;
        expect(still.dx, closeTo(w * .535 - 360 * .147, 1e-6));
        expect(door.dx, lessThan(still.dx), reason: 'the band has drifted left over the run-up');
      }
    });
  });
}
