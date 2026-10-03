// M1 integration: the two guardians as test-only levels (the catalog's own 3-2
// and 3-4 carry the shipped data since R5). R2 and R3
// each built a test-only guardian level for their own boss (3-2 with King
// Coo, 3-4 with the Searchlight Gargoyle) and the story agent wrote their
// scenes against the campaign as it is. Here the pieces meet: the two
// test-only plans coexist without conflict, agree with the story on every
// key it reads, refuse a rules 41 flight, are flown to their finish by
// real flights, and the story plays for them whether or not a voice has
// been recorded.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/campaign_progress.dart';
import 'package:push_up_bird/domain/campaign_story.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/campaign_voices.dart';

import 'campaign_flight.dart' show flyLevel, levelFlight;
import 'gargoyle_pilot.dart' as garg;
import 'king_coo_helpers.dart' as coo;

/// The catalog's level [id] with R5's data for it: the guardian's plan and
/// the card line the story wrote for him.
CampaignLevel guardianOf(String id, LevelPlan plan) {
  final base = Campaign.level(id)!;
  return CampaignLevel(
    name: base.name,
    delivery: base.delivery,
    hint: base.hint,
    bossLine: CampaignStory.guardianLines[id],
    plan: plan,
  );
}

void main() {
  final levels = {
    '3-2': guardianOf('3-2', coo.cooPlan()),
    '3-4': guardianOf('3-4', garg.gargoylePlan()),
  };
  final bosses = {'3-2': BossKind.kingCoo, '3-4': BossKind.searchlightGargoyle};

  tearDown(() => Campaign.openedForTest = false);

  group('the two test-only plans', () {
    test('are two distinct guardians of one chapter, neither its boss', () {
      final chapter = Campaign.chapters[2];
      for (final MapEntry(key: id, value: level) in levels.entries) {
        expect(level.id, id);
        expect(Campaign.chapterOf(level), same(chapter));
        expect(level.plan.region, WorldRegion.newYork);
        expect(level.plan.boss, bosses[id]);
        expect(level.plan.boss!.campaignOnly, isTrue);
        expect(level.isBoss, isTrue);
        expect(level.isGuardian, isTrue, reason: id);
        expect(level.isMiniBoss, isTrue);
        expect(level.isChapterBoss, isFalse);
        expect(level.plan.hasMiniBoss, isTrue);
        expect(chapter.bossLevel.id, '3-8');
        expect(Campaign.bossLine(level), CampaignStory.guardianLines[id]);
      }
      expect(levels['3-2']!.plan.boss, isNot(levels['3-4']!.plan.boss));
      expect(levels['3-2']!.plan.seed, isNot(levels['3-4']!.plan.seed));
    });

    test('are valid rules 43 plans that a rules 41 or 42 flight refuses', () {
      for (final MapEntry(key: id, value: level) in levels.entries) {
        final plan = level.plan;
        expect(plan.problem, isNull, reason: id);
        expect(plan.usesNewYork, isTrue);
        expect(plan.minRulesVersion, FlightSimulation.newYorkRulesVersion);
        // The plan survives its own JSON, key for key.
        final again = LevelPlan.fromJson(plan.toJson());
        expect(again.toJson(), plan.toJson(), reason: id);
        expect(again.boss, plan.boss);
        for (final older in [41, 42]) {
          expect(
            () => FlightSimulation(
              rules: TapFlyMode(rulesVersion: older),
              practice: false,
              course: FlightCourse.starTrail,
              rulesVersion: older,
              plan: plan,
            ),
            throwsArgumentError,
            reason: '$id at $older',
          );
        }
      }
    });

    test('agree with the catalog on everything the story keys on', () {
      for (final MapEntry(key: id, value: level) in levels.entries) {
        final base = Campaign.level(id)!;
        expect(level.id, base.id);
        expect(level.name, base.name);
        expect(level.plan.region, base.plan.region);
        expect(level.delivery.thanks, base.delivery.thanks);
        // The story's scenes are found by the level's id alone.
        expect(CampaignStory.before(level), same(CampaignStory.before(base)));
        expect(CampaignStory.lastWord(level), isNotNull);
        expect(CampaignStory.lastWord(level)!.id, 'last-$id');
        expect(CampaignStory.lastWord(level)!.bossBeaten, isTrue);
        expect(
          CampaignStory.before(level)!.lines.map((l) => l.text),
          contains(level.bossLine),
          reason: 'the card line is the boss\'s own line at the lair',
        );
      }
      expect(CampaignStory.lastWord(levels['3-4']!)!.endsStop, isTrue);
      expect(CampaignStory.lastWord(levels['3-2']!)!.endsStop, isFalse);
    });
  });

  group('flown to the finish by real flights', () {
    void expectFinished(CampaignLevel level, FlightSimulation sim) {
      expect(sim.endReason, EndReason.completed);
      expect(sim.bossesDefeated, 1);
      expect(sim.levelStars, inInclusiveRange(1, 3));
      Campaign.openedForTest = true;
      final record = LevelRecord(
        levelId: level.id,
        bestStars: sim.levelStars,
        plays: 1,
        firstClearedAt: DateTime(2026, 10, 1),
        lastPlayedAt: DateTime(2026, 10, 1),
      );
      List<LevelRecord> upTo(String last) => [
        for (final chapter in Campaign.chapters.take(2))
          for (final l in chapter.levels)
            LevelRecord(
              levelId: l.id,
              bestStars: 3,
              plays: 1,
              firstClearedAt: DateTime(2026, 9, 1),
              lastPlayedAt: DateTime(2026, 9, 1),
            ),
        for (final id in ['3-1', '3-2', '3-3', '3-4'])
          if (id.compareTo(last) < 0) LevelRecord(levelId: id, bestStars: 3),
        record,
      ];
      final progress = CampaignProgress(upTo(level.id));
      final chapter = Campaign.chapterOf(level);
      // The guardian's last word is due, once; nothing chapter-wide is.
      final last = progress.sceneLast(level);
      expect(last, isNotNull);
      expect(last!.id, 'last-${level.id}');
      expect(
        CampaignProgress(
          upTo(level.id),
          storyWatched: {last.id},
        ).sceneLast(level),
        isNull,
      );
      expect(progress.chapterComplete(chapter), isFalse);
      expect(progress.postcardDue(chapter), isFalse);
      expect(progress.sceneAfter(chapter), isNull);
    }

    test('3-2 and King Coo: the run-up\'s pigeons, the squadron, the win', () {
      final level = levels['3-2']!;
      final sim = levelFlight(level, weaponDamage: BirdRock.baseDamage);
      flyLevel(sim, until: (s) => s.boss?.phase == BossPhase.attacking);
      expect(sim.boss!.kind, BossKind.kingCoo);
      // Unhurt: rules 45's King Coo fells many pilots, and this is the
      // level's path, not their survival (`ny_levels_spread_test`).
      coo.fightBot(sim, coo.CooBot(react: .2), protect: true, seconds: 400);
      expect(sim.boss!.phase, BossPhase.defeated);
      flyLevel(sim);
      expectFinished(level, sim);
    });

    test('3-4 and the Gargoyle: the lamp, the beams, the win', () {
      final level = levels['3-4']!;
      final sim = levelFlight(level, weaponDamage: BirdRock.baseDamage);
      flyLevel(sim);
      expectFinished(level, sim);
    });
  });

  group('the story with and without a recorded voice', () {
    final scenes = [
      for (final level in levels.values) ...[
        CampaignStory.before(level)!,
        CampaignStory.lastWord(level)!,
      ],
    ];

    test('every line has a clip name the tools know, recorded or not', () {
      final wanted = CampaignVoices.wanted;
      expect(scenes, hasLength(4));
      for (final scene in scenes) {
        for (var i = 0; i < scene.lines.length; i++) {
          for (final name in CampaignVoices.lineNames(scene, i)) {
            expect(wanted, contains(name), reason: '${scene.id} $i');
          }
        }
      }
      for (final level in levels.values) {
        expect(wanted, contains(CampaignVoices.thanksName(level)));
      }
    });

    test('a line plays a real file, or plays nothing and is paced by its '
        'text: never a missing asset', () {
      for (final scene in scenes) {
        for (var i = 0; i < scene.lines.length; i++) {
          for (var bird = 0; bird < CampaignVoices.birds.length; bird++) {
            final asset = CampaignVoices.line(scene, i, bird: bird);
            if (asset == null) continue;
            expect(
              File('assets/$asset').existsSync(),
              isTrue,
              reason: '${scene.id} line $i: $asset is named but not bundled',
            );
            expect(CampaignVoices.length(asset), isNotNull);
          }
        }
      }
      for (final level in levels.values) {
        final asset = CampaignVoices.thanks(level);
        if (asset != null) expect(File('assets/$asset').existsSync(), isTrue);
      }
    });
  });
}
