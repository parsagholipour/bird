// M1's fix round (after the W4 reviews 20-review-play-qa and 21-review-art-ux):
// the findings it closes, on real flights of level 2-6.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/campaign_story.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/boss_stage_hud_art.dart';
import 'package:push_up_bird/game/neferhoo_encounter_art.dart';
import 'package:push_up_bird/game/neferhoo_fight_art.dart';
import 'package:push_up_bird/game/neferhoo_props_art.dart';
import 'package:push_up_bird/game/neferhoo_timeline.dart';
import 'package:push_up_bird/ui/story_boss_art.dart';
import 'package:push_up_bird/ui/story_scene.dart';
import 'package:push_up_bird/ui/story_speech.dart';
import 'package:push_up_bird/ui/story_stage.dart';
import 'package:push_up_bird/ui/theme.dart';

import 'neferhoo_art_support.dart';
import 'neferhoo_stage_support.dart' as stage show changed, loadFonts, neferhooStage, rgba;

/// Rocks on his wraps (at his height, the bird held clear of the lane), one
/// at a time, until [n] more have scuffed him.
void scuff(SkyBoss boss, int n, {double birdY = .85}) {
  final sim = flightOf(boss), f = boss.neferhoo;
  for (var i = 0; i < n; i++) {
    final before = f.wrapScuffs;
    sim.rocks.add(BirdRock(x: boss.x - .3, y: boss.y));
    for (var g = 0; g < 60 && f.wrapScuffs == before; g++) {
      fightTo(boss, boss.combatTime + 1 / 60, birdY: birdY);
    }
    expect(f.wrapScuffs, before + 1, reason: 'the rock scuffed his wraps');
  }
}

const _sizes = [Size(640, 360), Size(792, 360), Size(800, 360), Size(864, 360)];
const _insets = [EdgeInsets.zero, EdgeInsets.only(left: 44, right: 44)];

Future<Uint8List> _paint(Size size, void Function(Canvas) draw) async {
  final rec = ui.PictureRecorder();
  draw(Canvas(rec));
  final pic = rec.endRecording();
  final img = await pic.toImage(size.width.round(), size.height.round());
  final data = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
  img.dispose();
  pic.dispose();
  return data;
}

int _inked(Uint8List px) {
  var n = 0;
  for (var i = 3; i < px.length; i += 4) {
    if (px[i] > 24) n++;
  }
  return n;
}

/// The classic clock's beats are scripted here (12 s cycles, the gag's room,
/// the hint and lane moments): rules 54, the last rules on that clock. The
/// faster clock (rules 55) has its own checks (`neferhoo_faster_art_test`).
const _classic = FlightSimulation.cooRestartRulesVersion;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(stage.loadFonts);
  tearDown(() => NeferhooScreen.insets = EdgeInsets.zero);

  group('the hint lines are drawn (both reviews\' major)', () {
    test('after eight rocks on his wraps without a return the adaptive line hangs under his strip; a return swaps it for RETURN TO SENDER!, which goes after 1.5 s', () {
      final boss = courier(stage: 1, version: _classic);
      fightTo(boss, 12 + 3.0, birdY: .85);
      const size = Size(640, 360);
      scuff(boss, Neferhoo.scuffsBeforeHint - 1);
      expect(NeferhooFightArt.hintPill(size, boss), isNull, reason: 'seven scuffs: not yet');
      scuff(boss, 1);
      expect(boss.neferhooHint, Neferhoo.neferhooScuffHint);
      final first = NeferhooFightArt.hintPill(size, boss);
      expect(first, isNotNull);
      expect(first!.text, Neferhoo.neferhooScuffHint);
      expect(first.alpha, lessThan(.5), reason: 'it fades in');
      fightTo(boss, boss.combatTime + .4, birdY: .85);
      expect(NeferhooFightArt.hintPill(size, boss)!.alpha, 1);
      // the next mail call: the letters are the cure; one sent back swaps the line
      fightTo(boss, 12 + 12.7, birdY: .46);
      fightTo(boss, 12 + 14.1, birdY: .85);
      expect(NeferhooFightArt.hintPill(size, boss)!.text, Neferhoo.neferhooScuffHint, reason: 'shown through the mail call');
      final letter = boss.liveLetters.firstWhere((l) => !l.returned);
      returnLetter(boss, letter, birdY: .85);
      final back = NeferhooFightArt.hintPill(size, boss)!;
      expect(back.text, Neferhoo.returnHint);
      expect(boss.neferhoo.scuffsSinceReturn, 0);
      fightTo(boss, boss.combatTime + .5, birdY: .85);
      expect(NeferhooFightArt.hintPill(size, boss)!.alpha, 1);
      fightTo(boss, boss.combatTime + 1.2, birdY: .85);
      expect(NeferhooFightArt.hintPill(size, boss), isNull, reason: 'gone after 1.5 s');
    });

    test('the adaptive line gives way to the ankh\'s telegraph and comes back once it is home', () {
      final boss = courier(stage: 1, version: _classic);
      fightTo(boss, 12 + 3.0, birdY: .85);
      const size = Size(800, 360);
      scuff(boss, Neferhoo.scuffsBeforeHint);
      fightTo(boss, 12 + 5.3, birdY: .85);
      expect(NeferhooFightArt.hintPill(size, boss)!.alpha, 1);
      fightTo(boss, 12 + 5.52, birdY: .85);
      final out = NeferhooFightArt.hintPill(size, boss);
      expect(out == null || out.alpha < .6, isTrue, reason: 'fading as the ankh locks');
      fightTo(boss, 12 + 6.0, birdY: .85);
      expect(NeferhooFightArt.hintPill(size, boss), isNull, reason: 'the ankh has the word');
      final home = boss.neferhoo.ankhs.last.homeAt(handX: boss.handX, turnX: Neferhoo.turnX(FlightSimulation.birdX));
      fightTo(boss, home - boss.arrivalDuration + .5, birdY: .85);
      expect(NeferhooFightArt.hintPill(size, boss)?.text, Neferhoo.neferhooScuffHint, reason: 'back once the ankh is home');
    });

    test('it yields to the STRONGER! card that hangs from the same strip', () {
      final boss = courier(stage: 0, version: _classic);
      fightTo(boss, .7, birdY: .46);
      // send letters home until one lands across two thirds
      boss.hp = boss.maxHp * 2 ~/ 3 + 5;
      fightTo(boss, 1.7, birdY: .85);
      returnLetter(boss, boss.liveLetters.first, birdY: .85);
      for (var i = 0; i < 120 && boss.stageReached == 0; i++) {
        fightTo(boss, boss.combatTime + 1 / 60, birdY: .85);
      }
      expect(boss.stageReached, 1);
      fightTo(boss, boss.combatTime + .3, birdY: .85);
      expect(BossStageHudArt.strongerAge(boss), lessThan(BossStageHudArt.tagSeconds));
      expect(NeferhooFightArt.hintPill(const Size(640, 360), boss), isNull, reason: 'the card has the place');
    });

    test('hung centred under his health strip: clear of the hearts plate and the lane and loop tags, at 640-864 px with and without notch insets', () {
      final boss = courier(stage: 1, version: _classic);
      fightTo(boss, 12 + 3.0, birdY: .85);
      scuff(boss, Neferhoo.scuffsBeforeHint);
      fightTo(boss, boss.combatTime + .4, birdY: .85);
      for (final size in _sizes) {
        for (final inset in _insets) {
          NeferhooScreen.insets = inset;
          final pill = NeferhooFightArt.hintPill(size, boss)!;
          final strip = NeferhooFightArt.hudStrip(size, boss);
          expect(pill.rect.overlaps(neferhooHudPlate(size, inset)), isFalse, reason: '$size $inset pill ${pill.rect} plate ${neferhooHudPlate(size, inset)} strip $strip');
          expect((pill.rect.center.dx - strip.center.dx).abs(), lessThan(.5), reason: 'centred under the strip');
          expect(pill.rect.overlaps(neferhooHudPause(size, inset)), isFalse, reason: '$size $inset: the pause key');
          expect(pill.rect.top, greaterThan(strip.top));
          expect(pill.rect.left, greaterThan(inset.left), reason: 'inside the safe area');
          expect(pill.rect.right, lessThan(size.width - inset.right));
          // the lane tags keep clear of it at every lane height
          for (var lane = Neferhoo.laneTop; lane <= Neferhoo.laneBottom; lane += .02) {
            final band = NeferhooFightArt.laneHalfBand * 360;
            final tag = NeferhooPropsArt.tagRect('MAIL CALL', 'Shoot them back!', lane * 360 - band, lane * 360 + band, size, icon: 'mail', clear: [strip, pill.rect]);
            expect(tag.overlaps(pill.rect), isFalse, reason: '$size $inset lane $lane');
            expect(tag.overlaps(neferhooHudPlate(size, inset)), isFalse, reason: '$size $inset lane $lane');
            expect(tag.left, greaterThanOrEqualTo(inset.left + 14 - 1e-9), reason: 'inside the safe area');
          }
        }
      }
    });

    testWidgets('it is in the frame the game itself renders, under the letters', (tester) async {
      await stage.loadFonts();
      final s = await stage.neferhooStage(tester, 640);
      final boss = s.boss;
      s.birdY = .85;
      s.fightTo(3.0);
      for (var i = 0; i < Neferhoo.scuffsBeforeHint; i++) {
        final before = boss.neferhoo.wrapScuffs;
        s.sim.rocks.add(BirdRock(x: boss.x - .3, y: boss.y));
        for (var g = 0; g < 60 && boss.neferhoo.wrapScuffs == before; g++) {
          s.tick();
        }
      }
      s.fightTo(boss.combatTime + .4);
      final pill = NeferhooFightArt.hintPill(const Size(640, 360), boss)!;
      final shown = (await tester.runAsync(() async => stage.rgba(await s.render())))!;
      final keep = boss.neferhoo.scuffsSinceReturn;
      boss.neferhoo.scuffsSinceReturn = 0;
      final bare = (await tester.runAsync(() async => stage.rgba(await s.render())))!;
      boss.neferhoo.scuffsSinceReturn = keep;
      var changed = 0, all = 0;
      for (var y = pill.rect.top.ceil(); y < pill.rect.bottom.floor(); y++) {
        for (var x = pill.rect.left.ceil(); x < pill.rect.right.floor(); x++) {
          all++;
          final i = (y * 640 + x) * 4;
          if ((shown[i] - bare[i]).abs() + (shown[i + 1] - bare[i + 1]).abs() + (shown[i + 2] - bare[i + 2]).abs() > 30) changed++;
        }
      }
      expect(changed / all, greaterThan(.5), reason: 'the pill is on screen');
      expect(stage.changed(shown, bare), lessThan(all * 1.3), reason: 'and nothing else changed');
    });
  });

  group('the ankh never hides under the hearts plate (QA major M3)', () {
    for (final (birdY, under) in [(.22, true), (.6, true), (.46, false)]) {
      test('a lock at $birdY ${under ? 'passes under the plate: it fades for the whole flight' : 'stays clear of it: it stays'}', () {
        for (final px in [640.0, 792.0, 864.0]) {
          for (final inset in _insets) {
            final size = Size(px, 360);
            final boss = courier(px: px, stage: 1, version: _classic);
            fightTo(boss, 12 + 5.0, birdY: birdY);
            fightTo(boss, 12 + 5.42, birdY: birdY);
            final ankh = boss.neferhoo.ankhs.last;
            final turn = Neferhoo.turnX(FlightSimulation.birdX);
            final home = ankh.homeAt(handX: boss.handX, turnX: turn);
            if (inset == EdgeInsets.zero) expect(NeferhooFightArt.loopUnderPlate(size, boss, [ankh], insets: inset), under, reason: '${px.round()}');
            var hiddenFrames = 0;
            for (var t = 12 + 5.42; boss.age < home + .5; t += 1 / 60) {
              fightTo(boss, t, birdY: .85);
              final alpha = NeferhooFightArt.hudPlateAlpha(size, boss, insets: inset);
              final p = NeferhooFightArt.ankhCentre(ankh, boss);
              if (p == null) continue;
              final r = Rect.fromCircle(center: p * 360, radius: Neferhoo.ankhRadius * 360);
              if (r.overlaps(neferhooHudPlate(size, inset))) {
                // wherever the ankh is under the plate, the plate is faded
                expect(alpha, lessThanOrEqualTo(NeferhooFightArt.plateFaded + 1e-9), reason: '${px.round()} $inset t $t');
                hiddenFrames++;
              }
            }
            if (!under && inset == EdgeInsets.zero) {
              expect(hiddenFrames, 0);
              expect(NeferhooFightArt.hudPlateAlpha(size, boss), 1);
            }
            if (under && inset == EdgeInsets.zero) expect(hiddenFrames, greaterThan(0), reason: '${px.round()}: this lock does pass under it');
          }
        }
      });
    }

    test('the plate comes back once the ankh is home, and is whole outside his fight', () {
      final boss = courier(stage: 1, version: _classic);
      fightTo(boss, 12 + 5.0, birdY: .22);
      fightTo(boss, 12 + 5.42, birdY: .22);
      final ankh = boss.neferhoo.ankhs.last;
      final home = ankh.homeAt(handX: boss.handX, turnX: Neferhoo.turnX(FlightSimulation.birdX));
      fightTo(boss, home - boss.arrivalDuration + .4, birdY: .85);
      expect(NeferhooFightArt.hudPlateAlpha(const Size(640, 360), boss), 1);
      final calm = courier(stage: 0, version: _classic);
      expect(NeferhooFightArt.hudPlateAlpha(const Size(640, 360), calm), 1);
    });
  });

  group('Reduced Motion', () {
    test('he does not bob: two idle moments paint him in the same place (the rules\' circle still bobs)', () async {
      const size = Size(640, 360);
      final boss = courier(stage: 0, version: _classic);
      fightTo(boss, 12 + 9.0, birdY: .85);
      final y1 = boss.y;
      final a = await _paint(size, (c) => NeferhooEncounterArt.paint(c, size, flightOf(boss), BossMotion(boss, reducedMotion: true)));
      final moving = await _paint(size, (c) => NeferhooEncounterArt.paint(c, size, flightOf(boss), BossMotion(boss, reducedMotion: false)));
      fightTo(boss, 12 + 9.9, birdY: .85);
      expect((boss.y - y1).abs(), greaterThan(.01), reason: 'the rules bob');
      final b = await _paint(size, (c) => NeferhooEncounterArt.paint(c, size, flightOf(boss), BossMotion(boss, reducedMotion: true)));
      expect(b, a, reason: 'drawn still under Reduced Motion');
      expect(NeferhooFightArt.drawnY(boss, reduced: true), NeferhooFightArt.restY);
      expect(NeferhooFightArt.drawnY(boss, reduced: false), boss.y);
      expect(moving, isNot(a));
    });

    test('a landing under Reduced Motion shows the postmark and the damage without the flash, rings and confetti', () async {
      const size = Size(640, 360);
      for (final t in [.05, .2, .4]) {
        final full = _inked(await _paint(size, (c) => NeferhooPropsArt.returnBurst(c, const Offset(.9, .5), 360, t)));
        final still = _inked(await _paint(size, (c) => NeferhooPropsArt.returnBurst(c, const Offset(.9, .5), 360, t, reduced: true)));
        expect(still, lessThan(full * .6), reason: 't $t');
        expect(still, greaterThan(200), reason: 'the postmark and the -25 stay');
      }
    });
  });

  test('the stage-up beak opens on the cue\'s syllables: three hoots into the full fight, fury\'s two phrases', () {
    double beak(double t, {bool fury = false}) =>
        NeferhooTimeline(ct: 3 + t, phase: 40 + t, roarAt: 3, furyRoar: fury, fury: fury).pose().beak;
    // hoopoe_roar's hoots start at +.02/.17/.32 s and last .15 s
    for (final peak in [.075, .225, .375]) {
      expect(beak(peak), greaterThan(.8), reason: 'open at $peak');
    }
    for (final gap in [.0, .15, .30, .46, .6, .9, 1.1]) {
      expect(beak(gap), lessThan(.06), reason: 'shut at $gap');
    }
    // mummy_fury: 0-.52 s and .6-.88 s
    expect(beak(.26, fury: true), greaterThan(.85));
    expect(beak(.74, fury: true), greaterThan(.7));
    expect(beak(.56, fury: true), lessThan(.06));
    expect(beak(1.0, fury: true), lessThan(.06));
  });

  testWidgets('the story\'s Skip key no longer sits on his wing: a feather tip at 640 and 792, nothing at 800-864', (tester) async {
    await stage.loadFonts();
    final scenes = [(CampaignStory.before(Campaign.level('2-6')!)!, false), (CampaignStory.lastWord(Campaign.level('2-6')!)!, true)];
    final worst = <double, int>{};
    for (final px in [640.0, 792.0, 800.0, 864.0]) {
      tester.view.physicalSize = Size(px, 360);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(MaterialApp(theme: skyTheme(), home: StoryScenePlayer(scene: scenes.first.$1, bird: 0, reducedMotion: true, voices: false, onDone: () {})));
      await tester.pump(const Duration(milliseconds: 300));
      final skip = tester.getRect(find.byType(StorySkipKey));
      final layout = StoryLayout(Size(px, 360), EdgeInsets.zero, lair: true);
      final fit = StoryBossArt.portrait(BossKind.neferhoo);
      for (final (scene, beaten) in scenes) {
        for (final line in scene.lines) {
          final talking = line.speaker == StorySpeaker.boss;
          // his place on the floor, lifted by the most a hop and a drift lift him
          final lift = talking ? 12.0 : 3.0;
          final img = (await tester.runAsync(() => _paint(Size(px, 360), (c) {
            c.translate(layout.boss + fit.origin.dx, layout.floor - lift + fit.origin.dy);
            c.scale(fit.unit);
            StoryBossArt.paint(c, BossKind.neferhoo, line.mood, beaten: beaten, talk: talking ? 1 : 0, line: line.text);
          })))!;
          var over = 0;
          for (var y = skip.top.ceil(); y < skip.bottom.floor(); y++) {
            for (var x = skip.left.ceil(); x < skip.right.floor() && x < px; x++) {
              if (img[(y * px.round() + x) * 4 + 3] > 40) over++;
            }
          }
          worst[px] = (worst[px] ?? 0) > over ? worst[px]! : over;
        }
      }
    }
    tester.view.reset();
    // ignore: avoid_print
    print('pixels of him under the Skip key, worst line: $worst');
    expect(worst[640]!, lessThanOrEqualTo(100), reason: 'it was 745 px²');
    expect(worst[792]!, lessThanOrEqualTo(12), reason: 'a feather tip at 792 (the main tree\'s sky)');
    for (final px in [800.0, 864.0]) {
      expect(worst[px], 0, reason: '${px.round()} px');
    }
  });
}
