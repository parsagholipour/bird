import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/campaign_story.dart';
import 'package:push_up_bird/domain/sky_boss.dart' show BossKind;
import 'package:push_up_bird/game/neferhoo_pose.dart';
import 'package:push_up_bird/game/neferhoo_rig.dart';
import 'package:push_up_bird/game/neferhoo_story_art.dart';
import 'package:push_up_bird/ui/story_boss_art.dart';
import 'package:push_up_bird/ui/story_cast_art.dart';

import 'neferhoo_stage_support.dart';

/// Neferhoo on the story stage (A2, design §5.8): his own pose for every
/// mood, masked and beaten, painted by his own rig through the shared
/// `StoryBossArt`/`StoryBoss` path (which records the portrait at unit
/// scale: the rig's level of detail must not come from that canvas), the
/// gestures the design gives each mood (HALT!, the letter, the spectacles),
/// and a reach that holds everything he draws (a listener's shade is cut to
/// it).

const _pad = 4.5;

/// [paint] in rig units, as the stage records it (unit scale) and replays it
/// (scaled by the stage's unit), on a canvas wide enough for any pose; the
/// inked bounds back in rig units.
Future<ui.Rect?> _reach(void Function(ui.Canvas c) paint, {double unit = NeferhooStoryArt.unit}) async {
  final rec = ui.PictureRecorder();
  paint(ui.Canvas(rec));
  final picture = rec.endRecording();
  final w = (unit * 2 * _pad * 1.4).roundToDouble(), h = (unit * 2 * _pad).roundToDouble();
  final o = ui.Offset(w / 2 - unit, h / 2);
  final bytes = await raster((c) {
    c.translate(o.dx, o.dy);
    c.scale(unit);
    c.drawPicture(picture);
  }, w, h);
  picture.dispose();
  final px = inked(bytes, w.toInt());
  if (px == null) return null;
  return ui.Rect.fromLTRB((px.left - o.dx) / unit, (px.top - o.dy) / unit, (px.right - o.dx) / unit, (px.bottom - o.dy) / unit);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the stage fits him with his own numbers (design §5.8)', () {
    final fit = StoryBossArt.portrait(BossKind.neferhoo);
    // (M1's fix round: 40 px a unit and 24 px lower than the design's 43 and
    // -114, so his raised wing and streamers keep off the Skip key)
    expect(fit.unit, 40);
    expect(fit.origin, const ui.Offset(-30, -90));
    expect(fit.reach, NeferhooStoryArt.reach);
    expect(StoryBossArt.portrait(BossKind.neferhoo, beaten: true).reach, NeferhooStoryArt.reach);
  });

  test('each mood carries the design\'s gesture, masked and beaten', () {
    final masked = {for (final m in StoryMood.values) m: NeferhooStoryArt.gestureOf(m, beaten: false)};
    final beaten = {for (final m in StoryMood.values) m: NeferhooStoryArt.gestureOf(m, beaten: true)};
    expect(masked, {
      StoryMood.plain: NeferhooGesture.none,
      StoryMood.happy: NeferhooGesture.none,
      StoryMood.surprised: NeferhooGesture.none,
      StoryMood.angry: NeferhooGesture.halt,
      StoryMood.sad: NeferhooGesture.letter,
    });
    expect(beaten, {
      StoryMood.plain: NeferhooGesture.letter,
      StoryMood.happy: NeferhooGesture.letter,
      StoryMood.surprised: NeferhooGesture.specsUp,
      StoryMood.angry: NeferhooGesture.none,
      StoryMood.sad: NeferhooGesture.letter,
    });
    // The poses say so.
    expect(NeferhooStoryArt.poseOf(StoryMood.angry).wing, -1, reason: 'HALT!: the near wing up like a stop sign');
    expect(NeferhooStoryArt.poseOf(StoryMood.sad).prop, 'letter', reason: '"One letter left in my bag"');
    expect(NeferhooStoryArt.poseOf(StoryMood.happy, beaten: true).prop, 'letter', reason: '"Off to the Sphinx!"');
    expect(NeferhooStoryArt.poseOf(StoryMood.surprised, beaten: true).specsUp, 1, reason: '"I can see!"');
  });

  test('masked he wears the gold mask; beaten it is gone, spectacles on', () {
    for (final mood in StoryMood.values) {
      final m = NeferhooStoryArt.poseOf(mood);
      final b = NeferhooStoryArt.poseOf(mood, beaten: true);
      expect(m.mask, isTrue, reason: '$mood');
      expect(m.specs, isFalse, reason: '$mood');
      expect(b.mask, isFalse, reason: '$mood beaten');
      expect(b.specs, isTrue, reason: '$mood beaten');
      expect(b.unwrap, greaterThan(0), reason: 'the wraps loose as a scarf');
    }
  });

  test('talking opens the beak, a blink shuts the eye; poses are pure', () {
    for (final beaten in [false, true]) {
      for (final mood in StoryMood.values) {
        final still = NeferhooStoryArt.poseOf(mood, beaten: beaten);
        final talk = NeferhooStoryArt.poseOf(mood, beaten: beaten, talk: 1);
        final blink = NeferhooStoryArt.poseOf(mood, beaten: beaten, blink: 1);
        expect(talk.beak, greaterThanOrEqualTo(still.beak));
        expect(talk.beak, greaterThanOrEqualTo(.34));
        expect(blink.lid, 1);
        final again = NeferhooStoryArt.poseOf(mood, beaten: beaten);
        expect([again.crest, again.wing, again.lean, again.brow, again.lid], [still.crest, still.wing, still.lean, still.brow, still.lid]);
      }
    }
  });

  test('the portrait is painted at the stage\'s level of detail, not the recorder\'s', () {
    final rec = ui.PictureRecorder();
    final c = ui.Canvas(rec);
    expect(NeferhooPainter(c, NeferhooPose(), lod: NeferhooStoryArt.lod).lod, 2);
    expect(NeferhooStoryArt.lod, 2, reason: '43 px per unit is the play level');
    rec.endRecording().dispose();
  });

  test('every mood draws a different picture, and talking and blinking change it', () async {
    final seen = <String, Uint8List>{};
    for (final beaten in [false, true]) {
      for (final mood in StoryMood.values) {
        final bytes = await raster((c) {
          c.translate(260, 240);
          c.scale(43);
          StoryBossArt.paint(c, BossKind.neferhoo, mood, beaten: beaten);
        }, 520, 360);
        final key = '${mood.name}${beaten ? ' beaten' : ''}';
        // (a beaten plain line looks sheepish: the shared stage turns it sad)
        if (!(beaten && mood == StoryMood.plain)) {
          for (final e in seen.entries) {
            expect(changed(bytes, e.value), greaterThan(800), reason: '$key vs ${e.key}');
          }
          seen[key] = bytes;
        }
        final talking = await raster((c) {
          c.translate(260, 240);
          c.scale(43);
          StoryBossArt.paint(c, BossKind.neferhoo, mood, beaten: beaten, talk: 1);
        }, 520, 360);
        if (NeferhooStoryArt.poseOf(mood, beaten: beaten).beak < .3) {
          expect(changed(bytes, talking), greaterThan(30), reason: '$key: the beak opens');
        }
        final blinking = await raster((c) {
          c.translate(260, 240);
          c.scale(43);
          StoryBossArt.paint(c, BossKind.neferhoo, mood, beaten: beaten, blink: 1);
        }, 520, 360);
        expect(changed(bytes, blinking), greaterThan(10), reason: '$key: the eye shuts');
      }
    }
  });

  test('his reach holds everything he draws in every pose, talking or not', () async {
    var union = ui.Rect.zero;
    for (final beaten in [false, true]) {
      for (final mood in StoryMood.values) {
        for (final talk in [0.0, 1.0]) {
          final r = await _reach((c) => StoryBossArt.paint(c, BossKind.neferhoo, mood, beaten: beaten, talk: talk));
          // (and his card line's stamp, acted in that mood)
          final stamp = await _reach((c) => StoryBossArt.paint(c, BossKind.neferhoo, mood, beaten: beaten, talk: talk, line: NeferhooStoryArt.cardLine));
          expect(NeferhooStoryArt.reach.inflate(.02).contains(stamp!.topLeft) && NeferhooStoryArt.reach.inflate(.02).contains(stamp.bottomRight - const ui.Offset(1e-6, 1e-6)), isTrue,
              reason: 'stamp ${mood.name}: $stamp outside ${NeferhooStoryArt.reach}');
          expect(r, isNotNull);
          union = union == ui.Rect.zero ? r! : union.expandToInclude(r!);
          final reach = NeferhooStoryArt.reach.inflate(.02);
          expect(reach.contains(r.topLeft) && reach.contains(r.bottomRight - const ui.Offset(1e-6, 1e-6)), isTrue,
              reason: '${mood.name}${beaten ? ' beaten' : ''} talk $talk: $r outside ${NeferhooStoryArt.reach}');
        }
      }
    }
    // ignore: avoid_print
    print('story union $union');
    // The reach is not wildly larger than he is (the shade layer stays tight).
    expect(NeferhooStoryArt.reach.width, lessThan(union.width + 1.2), reason: 'union $union');
    expect(NeferhooStoryArt.reach.height, lessThan(union.height + 1.2), reason: 'union $union');
  });

  group('his card line acts the stamp (M1: the story stage gives a boss its line, not only its mood)', () {
    final scene = CampaignStory.before(Campaign.level('2-6')!)!;
    final halt = scene.lines[1], card = scene.lines[7];

    test('"Return to sender!" is his card line, angry like his HALT!', () {
      expect(card.text, NeferhooStoryArt.cardLine);
      expect(card.text, Campaign.bossLine(Campaign.level('2-6')!));
      expect(card.mood, StoryMood.angry);
      expect(halt.mood, StoryMood.angry);
      expect(halt.text, startsWith('HALT!'));
    });

    test('the card line asks for the stamp and a fan of letters; HALT! keeps the wing up; beaten he acts by mood', () {
      expect(NeferhooStoryArt.gestureOf(StoryMood.angry, beaten: false, line: card.text), NeferhooGesture.stamp);
      expect(NeferhooStoryArt.gestureOf(StoryMood.angry, beaten: false, line: halt.text), NeferhooGesture.halt);
      expect(NeferhooStoryArt.gestureOf(StoryMood.angry, beaten: true, line: card.text), NeferhooGesture.none);
      final p = NeferhooStoryArt.poseOf(StoryMood.angry, line: card.text);
      expect(p.stamp, 1);
      expect(p.cards, 3);
      expect(p.satchelOpen, 1);
      expect(p.wing, isNot(-1), reason: 'not the HALT! wing');
    });

    test('only Neferhoo acts a line beyond its mood: every other boss is posed by the mood alone', () {
      for (final kind in BossKind.values) {
        expect(StoryBossArt.actsLine(kind, card.text), kind == BossKind.neferhoo, reason: kind.name);
        expect(StoryBossArt.actsLine(kind, halt.text), isFalse, reason: kind.name);
        const plain = StoryBoss(BossKind.baronBat);
        expect(identical(StoryBoss(kind).acting(card.text).kind, kind), isTrue);
        if (kind != BossKind.neferhoo) {
          final actor = StoryBoss(kind);
          expect(actor.acting(card.text), actor);
          expect(actor.acting(card.text).line, isNull);
        }
        expect(plain.acting(card.text), plain);
      }
      expect(const StoryBoss(BossKind.neferhoo).acting(card.text).line, card.text);
      expect(const StoryBoss(BossKind.neferhoo).acting(halt.text).line, isNull);
      expect(const StoryBoss(BossKind.neferhoo, beaten: true).acting(card.text).line, isNull);
    });

    test('on the stage his card line and his HALT! are different pictures (both angry)', () async {
      Future<Uint8List> actor(String text) => raster((c) {
        c.translate(400, 300);
        const StoryBoss(BossKind.neferhoo).acting(text).paint(c, (mood: StoryMood.angry, mouth: 1, blink: false));
      }, 800, 360);
      final a = await actor(halt.text), b = await actor(card.text);
      expect(changed(a, b), greaterThan(1500), reason: 'the stamp pose is not the HALT! pose');
    });
  });

  test('the story actor (recorded at unit scale) paints him at the stage size', () async {
    const actor = StoryBoss(BossKind.neferhoo);
    final box = actor.box;
    expect(box.width, closeTo(NeferhooStoryArt.reach.width * NeferhooStoryArt.unit, 1e-6));
    final bytes = await raster((c) {
      c.translate(400, 300);
      actor.paint(c, (mood: StoryMood.plain, mouth: 0, blink: false));
    }, 800, 360);
    final ink = inked(bytes, 800)!;
    expect(ink.width, greaterThan(205), reason: 'about 7 units at 40 px');
    expect(ink.height, greaterThan(170));
  });
}
