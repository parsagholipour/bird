import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/campaign_story.dart' show StoryMood;
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/boss_audio_cues.dart';
import 'package:push_up_bird/game/boss_encounter_art.dart';
import 'package:push_up_bird/game/boss_health_bar_art.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/boss_power_up_art.dart';
import 'package:push_up_bird/game/boss_stage_hud_art.dart';
import 'package:push_up_bird/game/flight_voices.dart';
import 'package:push_up_bird/game/neferhoo_encounter_art.dart';
import 'package:push_up_bird/game/neferhoo_hud_art.dart';
import 'package:push_up_bird/game/neferhoo_story_art.dart';
import 'package:push_up_bird/ui/campaign_keepsake_art.dart';
import 'package:push_up_bird/ui/story_boss_art.dart';

import 'campaign_flight.dart';

/// The rules 50 scaffold (R0): Neferhoo reaches his own entry points from
/// every shared dispatch (encounter, health bar, stage HUD, power-up, story,
/// keepsake, audio, voices), never the Baron's fall-through and never a New
/// York placeholder (which throws for any other kind). The entry points were
/// R0's stubs until the W2 builders landed the real art (egypt-int/
/// MASTER-PLAN.md §3; the stub painter is gone); this test stays and keeps the
/// dispatch honest. `ny_placeholder_art_test` keeps every kind's picture
/// distinct.

/// The catalog's 2-6 flown by the shared bot until Neferhoo arrives.
FlightSimulation _arrived({double width = 2.2}) {
  final sim = FlightSimulation(
    rules: TapFlyMode(),
    practice: false,
    course: FlightCourse.starTrail,
    plan: Campaign.level('2-6')!.plan,
  );
  flyLevel(sim, viewportWidth: width, until: (sim) => sim.boss != null);
  return sim;
}

Future<List<int>> _pixels(void Function(Canvas c) paint, Size size) async {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    size.width.round(),
    size.height.round(),
  );
  final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  image.dispose();
  picture.dispose();
  return data.buffer.asUint8List();
}

void main() {
  for (final px in [640.0, 800.0, 864.0]) {
    test('at $px px every encounter slot draws his own stage, from the '
        'arrival to the defeat', () async {
      final size = Size(px, 360);
      final sim = _arrived(width: px / 360);
      final boss = sim.boss!;
      expect(boss.isNeferhoo, isTrue);
      // A letter and an ankh in flight, so the fight art has something.
      boss.neferhoo.letters.add(
        NeferhooLetter(
          cycle: 0,
          index: 0,
          lane: .5,
          releaseAt: 5,
          speed: Neferhoo.letterSpeed,
          express: false,
        ),
      );
      boss.neferhoo.ankhs.add(
        NeferhooAnkh(
          cycle: 0,
          laneA: .3,
          laneB: .62,
          lockedAt: 4.8,
          thrownAt: 5.2,
          speed: Neferhoo.ankhSpeed,
        ),
      );
      for (final (age, defeated) in [
        (.5, false),
        (2.0, false),
        (3.2, false),
        (6.0, false),
        (6.6, true),
        (8.0, true),
      ]) {
        boss.age = age;
        boss.defeatedAt = defeated ? 6.1 : null;
        for (final reduced in [false, true]) {
          final m = BossMotion(boss, reducedMotion: reduced);
          // The shared dispatch and his own entry point draw the same picture.
          final shared = await _pixels((c) {
            BossEncounterArt.backdrop(c, size, boss, m);
            BossEncounterArt.paint(c, size, sim, m);
          }, size);
          final own = await _pixels((c) {
            NeferhooEncounterArt.backdrop(c, size, boss, m);
            NeferhooEncounterArt.paint(c, size, sim, m);
          }, size);
          expect(shared, own, reason: 'age $age reduced $reduced');
          // The foreground (letterbox, omen, name card, captions) and the
          // health strip draw without a fall-through throwing.
          await _pixels((c) {
            BossEncounterArt.foreground(c, size, sim, m);
            BossHealthBarArt.paint(c, size, boss, reducedMotion: reduced);
          }, size);
        }
      }
      expect(boss.liveLetters, isEmpty, reason: 'defeated: none left');
    });
  }

  test('his strip, stage HUD and power-up use his own pieces', () {
    final boss = _arrived().boss!;
    boss.age = 6;
    expect(BossHealthBarArt.accent(boss), NeferhooHudArt.ramp[1]);
    final metal = BossStageHudArt.metal(BossKind.neferhoo);
    expect(metal.main, NeferhooHudArt.stageMetal.main);
    expect(metal.face, NeferhooHudArt.stageMetal.face);
    expect(BossPowerUpArt.colors(BossKind.neferhoo), NeferhooHudArt.powerUp);
    final frame = BossPowerUpArt.frame(
      BossMotion(boss, reducedMotion: false),
      360,
    );
    expect(frame.reach, greaterThan(0));
    expect(boss.stageMarks, [2 / 3, 1 / 3]);
  });

  test('the story stage, the keepsake and the map shield draw him', () async {
    final fit = StoryBossArt.portrait(BossKind.neferhoo);
    expect(fit.unit, NeferhooStoryArt.unit);
    expect(fit.reach, NeferhooStoryArt.reach);
    for (final mood in StoryMood.values) {
      for (final beaten in [false, true]) {
        await _pixels((c) {
          c.translate(300, 250);
          c.scale(fit.unit);
          StoryBossArt.paint(c, BossKind.neferhoo, mood, beaten: beaten);
        }, const Size(640, 360));
      }
    }
    expect(CampaignHeadwear.name(BossKind.neferhoo), 'Neferhoo');
    expect(CampaignHeadwear.field(BossKind.neferhoo), NeferhooStoryArt.field);
    await _pixels(
      (c) => CampaignHeadwear.paint(
        c,
        const Rect.fromLTWH(10, 10, 72, 72),
        BossKind.neferhoo,
      ),
      const Size(100, 100),
    );
    await _pixels(
      (c) => const CampaignStampPainter(
        BossKind.neferhoo,
        chapter: 2,
      ).paint(c, const Size(80, 96)),
      const Size(80, 96),
    );
  });

  test('his cues follow the shared clock, and a seek stays silent', () {
    final sim = _arrived();
    final boss = sim.boss!;
    final cues = BossAudioCues();
    final heard = <String>[];
    for (var age = 0.0; age < 8; age += .05) {
      boss.age = age;
      heard.addAll(cues.advance(boss));
    }
    expect(heard, contains('boss_warning'));
    // His own roar replaces the generic one (neferhoo_audio_test.dart).
    expect(heard, contains('hoopoe_roar'));
    expect(heard, isNot(contains('boss_roar')));
    boss.age = 2;
    expect(cues.advance(boss), isEmpty, reason: 'a rewind is silent');
    expect(cues.advance(null), isEmpty);
  });

  test('his voice key is his own; he is silent in flight until voiced', () {
    expect(FlightVoices.bossKey(BossKind.neferhoo), 'neferhoo');
    expect(FlightVoices.voicedBosses, isNot(contains(BossKind.neferhoo)));
    expect(FlightVoices.recorded['neferhoo-card'], isEmpty);
    expect(FlightVoices.recorded['neferhoo-taunt'], isEmpty);
    // The Spitter King's card line moved with his lair to 2-9.
    expect(
      FlightVoices.recorded['spitter-card'].map((c) => c.name),
      ['before-2-9-4'],
    );
  });

  test('the semantics hint and the name card line', () {
    final sim = _arrived();
    final boss = sim.boss!;
    boss.age = 6;
    // R1: the warm-up's open-sky line (no ankh until the full fight).
    expect(boss.neferhooHint, Neferhoo.warmUpHint);
    expect(
      BossEncounterArt.bossLine(sim),
      '“Return to sender! This route has a courier.”',
    );
    expect(BossEncounterArt.nameCardEyebrow(boss), 'GUARDIAN');
    expect(BossEncounterArt.victoryTitle(boss), 'GUARDIAN DOWN!');
  });
}
