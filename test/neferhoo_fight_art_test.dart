import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/neferhoo_fight_art.dart';
import 'package:push_up_bird/game/neferhoo_fx.dart';
import 'package:push_up_bird/game/neferhoo_props_art.dart';
import 'package:push_up_bird/game/neferhoo_timeline.dart';

import 'neferhoo_art_support.dart';

/// Neferhoo's fight art draws exactly what the rules judge (A1): a letter's
/// body is the rules' rectangle within a pixel at 640 and 800 px (its
/// rocking is calmed where it can touch the bird), the mail lane's corridor
/// is the band in which a letter hurts the bird, the ankh's loop is the rules'
/// path and its numbered bands the reach in which an ankh hurts the bird, the
/// drawn ankh is the rules' ankh; nothing is drawn outside the fight; Reduced
/// Motion keeps the telegraphs and drops the motes. Every fight here is a REAL
/// flight of level 2-6 (R1's rules latch what is drawn; M1's integration).

Future<Uint8List> _pixels(Size size, void Function(Canvas) draw) async {
  final rec = ui.PictureRecorder();
  draw(Canvas(rec));
  final pic = rec.endRecording();
  final img = await pic.toImage(size.width.round(), size.height.round());
  final data = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
  img.dispose();
  pic.dispose();
  return data;
}

/// The bounding box (px) of pixels with alpha above [alpha] inside [win].
Rect? _box(Uint8List px, int w, Rect win, {int alpha = 200}) {
  var l = 1 << 30, t = 1 << 30, r = -1, b = -1;
  for (var y = math.max(0, win.top.floor()); y < win.bottom.ceil(); y++) {
    for (var x = math.max(0, win.left.floor()); x < math.min(w, win.right.ceil()); x++) {
      if (px[(y * w + x) * 4 + 3] > alpha) {
        l = math.min(l, x);
        r = math.max(r, x);
        t = math.min(t, y);
        b = math.max(b, y);
      }
    }
  }
  return r < 0 ? null : Rect.fromLTRB(l.toDouble(), t.toDouble(), r + 1.0, b + 1.0);
}

/// Rows of column [x] darker than [lum] (0..255), on a white ground.
List<int> _darkRows(Uint8List px, int w, int x, {int lum = 110, int from = 0, int to = 360}) => [
  for (var y = from; y < to; y++)
    if ((px[(y * w + x) * 4] * .3 + px[(y * w + x) * 4 + 1] * .59 + px[(y * w + x) * 4 + 2] * .11) < lum) y,
];

/// The classic clock's beats are scripted here (12 s cycles, the gag's room,
/// the hint and lane moments): rules 54, the last rules on that clock. The
/// faster clock (rules 55) has its own checks (`neferhoo_faster_art_test`).
const _classic = FlightSimulation.cooRestartRulesVersion;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(family)..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
  });

  group('drawn = judged, within a pixel at 640 and 800 px', () {
    test('a letter\'s body is the rules\' rectangle where it can touch the bird', () async {
      for (final px in [640.0, 800.0]) {
        for (final stage in [1, 2]) {
          final size = Size(px, 360);
          final boss = courier(px: px, stage: stage, version: _classic);
          // the lane locks on the bird; then it leaves the lane, so the letters fly past
          fightTo(boss, 12.7);
          var checked = 0;
          for (var t = 13.6; t < 18; t += 1 / 30) {
            fightTo(boss, t, birdY: .8);
            final letters = boss.liveLetters.where((l) => !l.returned).toList();
            for (final letter in letters) {
              final x = letter.xAt(boss.age, boss.handX);
              if ((x - FlightSimulation.birdX).abs() > Neferhoo.letterHalfWidth + FlightSimulation.birdRadius + .02) continue;
              // this letter alone, as the fight draws it
              final keep = boss.neferhoo.letters.toList();
              boss.neferhoo.letters
                ..clear()
                ..add(letter);
              final img = await _pixels(size, (c) => NeferhooFightArt.over(c, size, boss, BossMotion(boss, reducedMotion: false)));
              boss.neferhoo.letters
                ..clear()
                ..addAll(keep);
              final rule = NeferhooFightArt.letterRect(letter, boss, 360);
              // (the body's ink and paper; the speed whiskers behind it are at most .8 alpha)
              final got = _box(img, px.round(), rule.inflate(12), alpha: 240)!;
              for (final (name, d) in [('left', got.left - rule.left), ('top', got.top - rule.top), ('right', got.right - rule.right), ('bottom', got.bottom - rule.bottom)]) {
                expect(d.abs(), lessThanOrEqualTo(1.0), reason: '${px.round()} px stage $stage t $t: $name edge ${d.toStringAsFixed(2)} px off ($got vs $rule)');
              }
              checked++;
            }
          }
          expect(checked, greaterThan(3), reason: 'letters passed the bird at ${px.round()} px');
        }
      }
    });

    test('everywhere else a letter is centred on the rules\' place, its body the rules\' size', () async {
      for (final px in [640.0, 800.0]) {
        final size = Size(px, 360);
        final boss = courier(px: px, version: _classic);
        fightTo(boss, 12.7);
        for (final t in [13.7, 14.4, 15.2]) {
          fightTo(boss, t, birdY: .8);
          final letter = boss.liveLetters.first;
          final keep = boss.neferhoo.letters.toList();
          boss.neferhoo.letters
            ..clear()
            ..add(letter);
          final img = await _pixels(size, (c) => NeferhooFightArt.over(c, size, boss, BossMotion(boss, reducedMotion: true)));
          boss.neferhoo.letters
            ..clear()
            ..addAll(keep);
          final rule = NeferhooFightArt.letterRect(letter, boss, 360);
          final got = _box(img, px.round(), rule.inflate(12))!;
          expect((got.center - rule.center).distance, lessThanOrEqualTo(1.0), reason: '${px.round()} px t $t: $got vs $rule');
          expect((got.width - rule.width).abs(), lessThanOrEqualTo(1.0), reason: 'width');
          expect((got.height - rule.height).abs(), lessThanOrEqualTo(1.0), reason: 'height');
        }
      }
    });

    test('the mail lane\'s corridor is the band in which a letter hurts the bird', () async {
      expect(NeferhooFightArt.laneHalfBand, Neferhoo.letterHalfHeight + FlightSimulation.birdRadius);
      for (final px in [640.0, 800.0]) {
        for (final (lane, stage) in [(.46, 1), (.3, 2), (.7, 1)]) {
          final size = Size(px, 360);
          final boss = courier(px: px, stage: stage, version: _classic);
          fightTo(boss, 12.6 + .7, birdY: lane);
          expect(boss.laneY, lane);
          final img = await _pixels(size, (c) {
            c.drawRect(Offset.zero & size, Paint()..color = const Color(0xffffffff));
            NeferhooFightArt.under(c, size, boss, BossMotion(boss, reducedMotion: true));
          });
          final column = (FlightSimulation.birdX * 360).round();
          final band = NeferhooFightArt.laneHalfBand * 360;
          final rows = _darkRows(img, px.round(), column, from: ((lane * 360) - band - 8).round(), to: ((lane * 360) + band + 8).round());
          final top = rows.first + .5, bottom = rows.last + .5;
          expect((top - (lane * 360 - band)).abs(), lessThanOrEqualTo(1.0), reason: '${px.round()} px lane $lane: top keyline at $top, rules ${lane * 360 - band}');
          expect((bottom - (lane * 360 + band)).abs(), lessThanOrEqualTo(1.0), reason: '${px.round()} px lane $lane: bottom keyline at $bottom, rules ${lane * 360 + band}');
        }
      }
    });

    test('the ankh\'s loop is the rules\' path; its numbered bands are the ankh\'s reach; the drawn ankh is the rules\' ankh', () async {
      expect(NeferhooFightArt.ankhReach, Neferhoo.ankhRadius + FlightSimulation.birdRadius);
      for (final px in [640.0, 800.0]) {
        final size = Size(px, 360);
        final boss = courier(px: px, stage: 2, version: _classic);
        fightTo(boss, 12 + 5.0, birdY: .3);
        fightTo(boss, 12 + 6.2, birdY: .3);
        final ankh = boss.neferhoo.ankhs.firstWhere((a) => !a.second && a.cycle == 1);
        // the loop: NeferhooFx.ankhLoop samples the rules' NeferhooAnkh.at
        final turn = Neferhoo.turnX(FlightSimulation.birdX);
        final loop = NeferhooFx.ankhLoop(boss.handX, ankh.laneA, ankh.laneB, n: 200);
        final length = ankh.length(boss.handX, turn);
        for (var k = 0; k <= 200; k++) {
          final at = ankh.at(ankh.thrownAt + math.max(0.0, length * k / 200 - 1e-9) / ankh.speed, handX: boss.handX, turnX: turn)!;
          expect((loop[k] - Offset(at.$1, at.$2)).distance * 360, lessThan(.01), reason: 'sample $k');
        }
        // the bands at the bird's column
        final img = await _pixels(size, (c) {
          c.drawRect(Offset.zero & size, Paint()..color = const Color(0xffffffff));
          NeferhooFightArt.under(c, size, boss, BossMotion(boss, reducedMotion: true));
        });
        final reach = NeferhooFightArt.ankhReach * 360;
        // (the band's outline is a stroke .0085 h wide centred on the band's edge)
        const half = .0085 * 360 / 2;
        for (final lane in [ankh.laneA, ankh.laneB]) {
          final rows = _darkRows(img, px.round(), (FlightSimulation.birdX * 360).round(), lum: 254, from: (lane * 360 - reach - 6).round(), to: (lane * 360 + reach + 6).round());
          expect((rows.first + half - (lane * 360 - reach)).abs(), lessThanOrEqualTo(1.0), reason: '${px.round()} px band $lane top: ${rows.first}');
          expect((rows.last + 1 - half - (lane * 360 + reach)).abs(), lessThanOrEqualTo(1.0), reason: '${px.round()} px band $lane bottom: ${rows.last}');
        }
        // the ankh in flight where the rules have it, from .22 s after the throw
        // until its last .3 s, when it glides from lane B into his hand (M1's
        // fix round: the catch met a bare hand when the lane was low), always
        // far right of where it can hit the bird
        var glided = 0;
        for (var t = 12 + 7.1; t < 12 + 10.5; t += 1 / 30) {
          fightTo(boss, t, birdY: .3);
          for (final a in boss.liveAnkhs) {
            final drawn = NeferhooFightArt.ankhCentre(a, boss);
            final rule = a.at(boss.age, handX: boss.handX, turnX: turn);
            if (rule == null || boss.age - a.thrownAt < NeferhooTimeline.ankhEase) continue;
            expect(drawn, isNotNull);
            final home = a.homeAt(handX: boss.handX, turnX: turn);
            if (boss.age < home - NeferhooFightArt.catchEase) {
              expect((drawn! - Offset(rule.$1, rule.$2)).distance * 360, lessThan(1.0), reason: '${px.round()} px t $t');
            } else {
              glided++;
              expect(drawn!.dx, greaterThan(FlightSimulation.birdX + NeferhooFightArt.ankhReach + .2), reason: 'the glide stays clear of the bird');
              expect(rule.$1, greaterThan(FlightSimulation.birdX + NeferhooFightArt.ankhReach + .2));
              final hand = NeferhooFightArt.handPoint(boss);
              final k = (boss.age - (home - NeferhooFightArt.catchEase)) / NeferhooFightArt.catchEase;
              // it closes on the hand as it comes home
              expect((drawn - hand).distance, lessThanOrEqualTo((Offset(rule.$1, rule.$2) - hand).distance + 1e-9), reason: 'k $k');
            }
          }
        }
        expect(glided, greaterThan(4), reason: 'the catch glide was sampled');
      }
    });

    test('a drawn ankh is centred on its centre (the solid body, no spin)', () async {
      const size = Size(640, 360);
      final img = await _pixels(size, (c) => NeferhooPropsArt.flyingAnkh(c, const Offset(.8, .5), 360, 0));
      final got = _box(img, 640, const Rect.fromLTWH(240, 130, 100, 100), alpha: 230)!;
      expect((got.center - const Offset(288, 180)).dx.abs(), lessThanOrEqualTo(1.0), reason: '$got');
    });
  });

  group('the hint tags keep clear of the play screen\'s HUD (M1)', () {
    test('at every lane height and width the MAIL CALL and THE ANKH tags miss the hearts plate and their own band', () {
      for (final px in [576.0, 640.0, 720.0, 800.0, 864.0, 960.0]) {
        final size = Size(px, 360);
        final plate = neferhooHudPlate(size);
        final strip = NeferhooFightArt.hudStrip(size, courier(px: px, version: _classic));
        for (var lane = Neferhoo.laneTop; lane <= Neferhoo.laneBottom + 1e-9; lane += .01) {
          final band = NeferhooFightArt.laneHalfBand * 360;
          final top = lane * 360 - band, bottom = lane * 360 + band;
          for (final (title, sub, icon) in [('MAIL CALL', 'Shoot them back!', 'mail'), ('EXPRESS POST', 'Shoot them back!', 'mail'), ('THE ANKH', 'It comes back!', 'ankh'), ('TWO ANKHS', 'It comes back!', 'ankh')]) {
            final r = NeferhooPropsArt.tagRect(title, sub, top, bottom, size, icon: icon, clear: [strip]);
            expect(r.overlaps(plate), isFalse, reason: '${px.round()} px lane ${lane.toStringAsFixed(2)} $title: $r under the HUD plate $plate');
            expect(r.overlaps(strip), isFalse, reason: '${px.round()} px lane ${lane.toStringAsFixed(2)} $title: $r under his health strip $strip');
            expect(r.top, greaterThanOrEqualTo(0));
            expect(r.bottom, lessThanOrEqualTo(360));
            expect(r.bottom <= top + .5 || r.top >= bottom - .5, isTrue, reason: '${px.round()} px lane ${lane.toStringAsFixed(2)}: $r covers its band $top..$bottom');
            expect(r.right, lessThan(size.width * .6), reason: 'the tag stays on the bird\'s side');
          }
        }
      }
    });
  });

  group('when and where', () {
    test('nothing is drawn outside the fight', () async {
      const size = Size(640, 360);
      final boss = courier(stage: 1, version: _classic);
      fightTo(boss, 12 + 2.5);
      final m = BossMotion(boss, reducedMotion: false);
      final blank = await _pixels(size, (c) {});
      for (final (age, dead) in [(1.0, false), (boss.age, true)]) {
        final keep = boss.age;
        boss.age = age;
        boss.defeatedAt = dead ? keep - .1 : null;
        final img = await _pixels(size, (c) {
          NeferhooFightArt.under(c, size, boss, m);
          NeferhooFightArt.over(c, size, boss, m);
        });
        expect(img, blank, reason: dead ? 'defeated' : 'arriving');
        boss
          ..age = keep
          ..defeatedAt = null;
      }
    });

    test('the lane shows from the lock until the last letter is past the bird, then fades (rules 50)', () {
      final boss = courier(stage: 1, version: FlightSimulation.neferhooRulesVersion);
      fightTo(boss, 12.57);
      expect(NeferhooFightArt.mailLane(boss), isNull);
      fightTo(boss, 12.615);
      final lane = NeferhooFightArt.mailLane(boss)!;
      expect(lane.reveal, lessThan(.1));
      expect(lane.express, isFalse);
      var last = 0.0;
      for (var t = 12.61; t < 18; t += 1 / 60) {
        fightTo(boss, t);
        final l = NeferhooFightArt.mailLane(boss);
        if (l == null) break;
        last = t;
        expect(l.alpha, inInclusiveRange(0.0, 1.0));
      }
      // the last of three letters (1.6 + .8 s) .15 past the bird
      final end = 12 + 1.6 + .8 + (boss.handX - FlightSimulation.birdX + .15) / Neferhoo.letterSpeed;
      expect((last - end).abs(), lessThan(.05));
    });

    test('rules 52: the lane stays until its mummy bats are past the bird too (or down), then fades', () {
      for (final px in [640.0, 864.0]) {
        for (final shootThem in [false, true]) {
          final boss = courier(px: px, stage: 1, version: _classic);
          final sim = flightOf(boss);
          final f = boss.neferhoo;
          fightTo(boss, 12.615, birdY: .3);
          expect(NeferhooFightArt.mailLane(boss), isNotNull);
          final lane = f.laneY;
          final bats = [for (final b in f.bats) if (b.cycle == 1) b];
          expect(bats, hasLength(2));
          // The letters' own end, at their real (faster) speed.
          final letter = f.letters.last;
          final lettersEnd = letter.releaseAt + (boss.handX - FlightSimulation.birdX + .15) / letter.speed - boss.arrivalDuration;
          expect(letter.speed, greaterThan(Neferhoo.letterSpeed));
          double? past, last;
          var fading = false;
          for (var t = 12.62; t < 21; t += 1 / 60) {
            // Clear of the lane; or in it once the letters are by, shooting.
            final inLane = shootThem && t > lettersEnd - .1 && bats.every((b) => b.launched);
            fightTo(boss, t, birdY: inLane ? lane : (lane < .5 ? .85 : .15));
            if (inLane && sim.canShoot) sim.shoot();
            final l = NeferhooFightArt.mailLane(boss);
            final live = bats.where((b) => b.goneAt == null && (!b.launched || b.enemy!.x > FlightSimulation.birdX - .15));
            if (l == null) {
              past ??= t;
              break;
            }
            last = t;
            if (l.alpha < 1) fading = true;
            if (t > lettersEnd + .3) expect(live, isNotEmpty, reason: '${px.round()} lane kept for the bats at $t');
          }
          expect(past, isNotNull);
          expect(last, greaterThan(lettersEnd), reason: 'the bats keep it');
          expect(fading || shootThem, isTrue, reason: 'it fades as the last bat passes');
          if (shootThem) {
            expect(bats.every((b) => b.goneAt != null), isTrue);
            expect(bats.every((b) => b.enemy!.hp == 0), isTrue, reason: 'shot down');
          }
        }
      }
    });

    test('the loop shows from the lock until the last ankh is home; two ankhs in fury', () {
      for (final stage in [1, 2]) {
        final boss = courier(stage: stage, version: _classic);
        fightTo(boss, 12 + 5.37);
        expect(NeferhooFightArt.ankhLoop(boss), isNull);
        fightTo(boss, 12 + 5.415);
        final loop = NeferhooFightArt.ankhLoop(boss)!;
        expect(loop.two, stage == 2);
        expect(loop.alpha, 1);
        fightTo(boss, 12 + 7.2);
        expect(NeferhooFightArt.ankhLoop(boss)!.alpha, closeTo(.65, .01));
        fightTo(boss, 12 + 11.9);
        expect(NeferhooFightArt.ankhLoop(boss), isNull);
      }
    });

    test('the warm-up throws no ankh and draws no loop', () {
      final boss = courier(stage: 0, version: _classic);
      for (var t = 12.0; t < 24; t += .25) {
        fightTo(boss, t);
        expect(NeferhooFightArt.ankhLoop(boss), isNull);
        expect(boss.liveAnkhs, isEmpty);
      }
    });

    test('a returned letter flies home on the rules\' clock and curve and bursts as it lands', () {
      final boss = courier(stage: 1, version: _classic);
      fightTo(boss, 12 + 2.6);
      final letter = boss.liveLetters.first;
      returnLetter(boss, letter);
      final hp = boss.hp;
      var t = boss.combatTime;
      var k = 0.0;
      while (letter.landedAt == null && t < 12 + 4) {
        k = NeferhooFightArt.returnProgress(letter, boss);
        // the rules' own clock (homeAt latched at the catch) and the rules' own point
        expect(k, letter.homeward(boss.age));
        final (rx, ry) = letter.returnAt(boss.age, chestX: boss.x, chestY: boss.y);
        expect((NeferhooFightArt.returnedAt(letter, boss) - Offset(rx, ry)).distance, lessThan(1e-12));
        t += 1 / 60;
        fightTo(boss, t);
      }
      expect(letter.landedAt, isNotNull);
      expect(letter.landedAt, greaterThanOrEqualTo(letter.homeAt! - 1e-9));
      expect(k, greaterThan(.95), reason: 'it reached his chest as it landed');
      expect(boss.hp, hp - Neferhoo.returnDamage);
      expect(boss.lastLandAt, letter.landedAt);
      expect(boss.lastHitAt, letter.landedAt, reason: 'the landing is the hit the rig recoils from in full');
    });

    test('letters sent back together land apart, each drawn on its own latched clock', () {
      final boss = courier(stage: 2, version: _classic);
      fightTo(boss, 12 + 2.3);
      final live = boss.liveLetters.where((l) => !l.returned).toList();
      expect(live.length, greaterThanOrEqualTo(3), reason: 'the express post in flight');
      // a fully charged rock in their lane returns every letter it meets (bulk return)
      final sim = flightOf(boss);
      sim.rocks.add(BirdRock(x: live.first.xAt(boss.age, boss.handX) - .1, y: live.first.lane, charge: 1, damage: 40));
      for (var i = 0; i < 40 && live.where((l) => l.returned).length < 2; i++) {
        fightTo(boss, boss.combatTime + 1 / 60);
      }
      final back = live.where((l) => l.returned).toList();
      expect(back.length, greaterThanOrEqualTo(2));
      for (var i = 0; i < 90 && back.any((l) => l.landedAt == null); i++) {
        for (final l in back.where((l) => l.landedAt == null)) {
          expect(NeferhooFightArt.returnProgress(l, boss), l.homeward(boss.age));
        }
        fightTo(boss, boss.combatTime + 1 / 60);
      }
      final lands = back.map((l) => l.landedAt!).toList()..sort();
      for (var i = 1; i < lands.length; i++) {
        expect(lands[i] - lands[i - 1], greaterThanOrEqualTo(Neferhoo.landingGap - 1 / 60 - 1e-9), reason: 'one landing per step and burst');
      }
    });

    test('Reduced Motion keeps the telegraphs and the letters still, and drops the motes', () async {
      const size = Size(640, 360);
      final boss = courier(stage: 2, version: _classic);
      fightTo(boss, 12 + 5.3);
      expect(boss.liveLetters, isEmpty);
      final quiet = await _pixels(size, (c) => NeferhooFightArt.over(c, size, boss, BossMotion(boss, reducedMotion: true)));
      expect(quiet.every((v) => v == 0), isTrue, reason: 'no motes under Reduced Motion');
      final busy = await _pixels(size, (c) => NeferhooFightArt.over(c, size, boss, BossMotion(boss, reducedMotion: false)));
      expect(busy.any((v) => v != 0), isTrue, reason: 'the motes when motion is on');
      fightTo(boss, 12 + 6.2, birdY: .3);
      final loop = await _pixels(size, (c) => NeferhooFightArt.under(c, size, boss, BossMotion(boss, reducedMotion: true)));
      expect(loop.any((v) => v != 0), isTrue, reason: 'the loop stays');
    });
  });
}
