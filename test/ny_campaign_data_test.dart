// New York's level data as the owner-approved structure (reports/01) and the
// master plan set it, pinned level by level, plus the catalog rules that
// depend on it: a boss level holds no set pieces, a guardian ends no chapter,
// a guardian's win opens the next LEVEL only (no postcard, no seal), the open
// stop's progression, the star total, and both states of the opening flag
// (`Campaign.openingEnabled`: on by default, `NEW_YORK_OPEN=false` is the
// rollback). Tests force a state with `Campaign.openedForTest` and
// `Campaign.closedForTest`, so they pass under either define.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/campaign_progress.dart';
import 'package:push_up_bird/domain/campaign_story.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/ui/campaign_screen.dart'
    show campaignStarsInBuild, campaignStops;
import 'package:push_up_bird/ui/level_intro.dart' show lockedNudge;

import 'campaign_flight.dart' show levelFlight;

CampaignLevel level(String id) => Campaign.level(id)!;

LevelRecord cleared(String id, {int stars = 2}) => LevelRecord(
  levelId: id,
  bestStars: stars,
  plays: 1,
  firstClearedAt: DateTime(2026, 9, 20),
  lastPlayedAt: DateTime(
    2026,
    9,
    20,
    int.parse(id.split('-').first),
    int.parse(id.split('-').last),
  ),
);

List<LevelRecord> chaptersOneAndTwo() => [
  for (final chapter in Campaign.chapters.take(2))
    for (final l in chapter.levels) cleared(l.id),
];

/// Chapters 1 and 2 and the New York levels in [ids], all cleared.
CampaignProgress progressAfter(
  List<String> ids, {
  Set<String> watched = const {},
}) => CampaignProgress([
  ...chaptersOneAndTwo(),
  for (final id in ids) cleared(id),
], storyWatched: watched);

void main() {
  tearDown(() {
    Campaign.openedForTest = false;
    Campaign.closedForTest = false;
  });

  group('the four levels, as the structure report writes them', () {
    const road = [
      ObstacleKind.garden,
      ObstacleKind.windLift,
      ObstacleKind.petalGate,
      ObstacleKind.switchback,
      ObstacleKind.lanternDrift,
    ];
    const gates = [
      ObstacleKind.garden,
      ObstacleKind.windLift,
      ObstacleKind.petalGate,
      ObstacleKind.sunWheels,
    ];
    const pigeon = EnemyKind.alleyPigeon, bat = EnemyKind.simpleBat;
    const moth = EnemyKind.duskMoth, beetle = EnemyKind.spitterBeetle;
    const cave = EnemyKind.caveBat;

    test(
      '3-1 Moth Light: a finish line at 60 s, a moth every fourth enemy',
      () {
        final l = level('3-1');
        expect(l.name, 'Moth Light');
        expect(l.plan.toJson(), {
          'id': '3-1',
          'region': 'newYork',
          // 70 s and moths on half the enemy passages until the fix round: the
          // review found it the hardest ordinary level (casual hearts lost per
          // minute 0.66 to 0.90, against 0.25 to 0.48 for 2-6 and 2-7).
          'length': 60.0,
          'start': 75.0,
          'seed': 3101,
          'families': [
            for (final k in [...road]) k.name,
          ],
          'lineup': ['simpleBat', 'duskMoth', 'caveBat', 'spitterBeetle'],
          'cadence': 2,
          'toughness': 2,
          'shoot': true,
          'sprint': true,
          'panels': .25,
          'pieces': <Object>[],
          'boss': null,
          'marks': [40, 65],
        });
        // The NEW hint stays true: a moth leads the second enemy passage (3),
        // and one in four enemies after it.
        expect(l.plan.enemyIndex(3), 1);
        expect(l.plan.lineup[1], EnemyKind.duskMoth);
        expect(l.hint, 'Moths fire fans of three. Slip between them.');
        expect(l.hintIsNew, isTrue);
        expect(l.bossLine, isNull);
        expect(l.plan.minRulesVersion, 41, reason: 'rules 41 data');
      },
    );

    test('3-2 Wheels in the Rain: a 30 s run-up with pigeons, King Coo', () {
      final l = level('3-2');
      final p = l.plan;
      expect(l.name, 'Wheels in the Rain');
      expect(l.isGuardian, isTrue);
      expect(
        (p.region, p.length, p.start, p.seed),
        (WorldRegion.newYork, 30.0, 85.0, 3102),
      );
      expect(p.families, gates);
      expect(p.lineup, [pigeon, bat, pigeon, moth]);
      expect(p.cadence, 2);
      expect(p.flocks, [1, 1, 1]);
      expect(p.steam, SteamPlan.none, reason: 'the pigeon lesson stays clean');
      expect(p.pieces, isEmpty);
      expect((p.toughness, p.panels), (2, .25));
      expect((p.shoot, p.sprint), (true, true));
      expect(p.boss, BossKind.kingCoo);
      expect((p.marks.two, p.marks.three), (20, 30));
      expect(l.hint, 'Alley pigeons swoop in to grab stars. Shoot them first!');
      expect(l.hintIsNew, isTrue);
      expect(l.bossLine, 'Nobody flies till the bread cart is found!');
      expect(p.minRulesVersion, 43);
    });

    test('3-3 Steam Alley: 65 s, seven vents, pigeons, no set piece', () {
      final l = level('3-3');
      final p = l.plan;
      expect(l.name, 'Steam Alley', reason: 'renamed from Swarm Alley');
      expect(l.id, '3-3', reason: 'the id stays: voice clips are named by it');
      expect(l.isBoss, isFalse);
      expect(
        (p.region, p.length, p.start, p.seed),
        // 80 s and seed 3103 until the fix round: with no heart recovery in
        // the level a casual pilot finished 72% (640 px) and 55% (800 px) of
        // shoot phases, and steam was only 6% of the hearts lost. 65 s lifts
        // that to 100%; seed 3111 has no stone door before passage 10.
        (WorldRegion.newYork, 65.0, 100.0, 3111),
      );
      expect(p.families, gates);
      expect(p.lineup, [bat, pigeon, moth, beetle, pigeon, cave]);
      // The flocks and the steady layer are proportional to the 65 s route:
      // the same lists lay five formations (1+2+2+2+2 = 9 pigeons) and seven
      // vents (the layer is cut by the route's 30 passages).
      expect(p.flocks, [1, 2, 2, 2, 2, 2]);
      expect(p.steam, SteamPlan.steady);
      expect(
        (p.steam.first, p.steam.every, p.steam.last, p.steam.pattern),
        (4, 4, 34, 'HR'),
      );
      expect(p.pieces, isEmpty, reason: 'the Swarm rush moved to Paris');
      expect(p.boss, isNull);
      expect((p.marks.two, p.marks.three), (45, 70));
      expect(
        l.hint,
        'Vents hiss, then burst. Hop the hot ones, ride the soft ones.',
      );
      expect(l.hintIsNew, isTrue);
      expect(l.bossLine, isNull);
      expect(p.minRulesVersion, 43);
    });

    test('3-4 Storm Warning: a 30 s run-up with steam, the Gargoyle', () {
      final l = level('3-4');
      final p = l.plan;
      expect(l.name, 'Storm Warning');
      expect(l.isGuardian, isTrue);
      expect(
        (p.region, p.length, p.start, p.seed),
        (WorldRegion.newYork, 30.0, 90.0, 3104),
      );
      expect(p.families, [
        ObstacleKind.garden,
        ObstacleKind.windLift,
        ObstacleKind.switchback,
        ObstacleKind.sunWheels,
      ]);
      expect(p.lineup, [bat, pigeon, moth, beetle, pigeon, cave]);
      expect(p.flocks, [1, 2]);
      expect(p.steam, SteamPlan.sparse);
      expect(
        (p.steam.first, p.steam.every, p.steam.last, p.steam.pattern),
        (4, 4, 12, 'RH'),
      );
      expect(p.pieces, isEmpty, reason: 'the gale moved to Paris');
      expect(p.boss, BossKind.searchlightGargoyle);
      expect(p.sprint, isFalse, reason: 'a sprint outruns his feathers\' aim');
      // 20 and 27, not the usual 30 (see campaign.dart): 3-4's run-up is the
      // only guardian's with steam, and its third star was out of reach for
      // 35 to 62% of casual pilots against 0 to 5% on 3-2.
      expect((p.marks.two, p.marks.three), (20, 27));
      expect(
        l.hint,
        'Stay out of the light. Shoot the lamp when it opens! No Sprint here.',
      );
      expect(l.hintIsNew, isTrue);
      expect(l.bossLine, 'Hold still! Nobody ever stays in the light.');
      expect(p.minRulesVersion, 43);
    });

    test('the two guardian card lines are the story\'s own', () {
      for (final id in ['3-2', '3-4']) {
        expect(level(id).bossLine, CampaignStory.guardianLines[id], reason: id);
        expect(Campaign.bossLine(level(id)), level(id).bossLine);
        // They are also the guardian's line at his lair.
        expect(
          CampaignStory.before(level(id))!.lines.map((line) => line.text),
          contains(level(id).bossLine),
        );
      }
    });

    test('every level id, delivery and thank-you is as it was', () {
      const deliveries = {
        '3-1': (
          'Light bulbs for the theatre marquee',
          'The stage manager',
          'The show goes on! Front row for you.',
        ),
        '3-2': (
          'Umbrellas for the newsstand pigeons',
          'The newsstand pigeons',
          'Dry feathers at last. You’re a hero.',
        ),
        '3-3': (
          'Hot pretzels for the night-shift cabbies',
          'The night cabbies',
          'Still warm! How fast do you fly?',
        ),
        '3-4': (
          'A weather vane for the tallest tower',
          'The tower keeper',
          'It spins! It points! It’s perfect.',
        ),
      };
      for (final MapEntry(key: id, value: (cargo, from, thanks))
          in deliveries.entries) {
        final d = level(id).delivery;
        expect((d.cargo, d.from, d.thanks), (cargo, from, thanks), reason: id);
      }
      expect(Campaign.chapters[2].levels.map((l) => l.id), [
        for (var i = 1; i <= 8; i++) '3-$i',
      ]);
    });

    test('the plans round-trip their JSON, the new keys last', () {
      for (final id in ['3-1', '3-2', '3-3', '3-4']) {
        final json = level(id).plan.toJson();
        final again = LevelPlan.fromJson(
          jsonDecode(jsonEncode(json)) as Map<String, dynamic>,
        );
        expect(jsonEncode(again.toJson()), jsonEncode(json), reason: id);
        expect(again.problem, isNull, reason: id);
      }
      expect(level('3-2').plan.toJson().keys.skip(15), ['flocks']);
      expect(level('3-3').plan.toJson().keys.skip(15), ['flocks', 'steam']);
      expect(level('3-4').plan.toJson().keys.skip(15), ['flocks', 'steam']);
      expect(level('3-1').plan.toJson().keys, hasLength(15));
    });
  });

  group('the pigeons and the vents lie where the reports put them', () {
    // Enemy-led passages are the odd ones (cadence 2): lineup entry n is
    // passage 2n + 1.
    List<int> pigeonPassages(String id) {
      final plan = level(id).plan;
      return [
        for (var n = 1; n <= levelFlight(level(id)).route!.passages.length; n++)
          if (plan.enemyIndex(n) case final index?
              when plan.lineup[index % plan.lineup.length] ==
                  EnemyKind.alleyPigeon)
            n,
      ];
    }

    test('formations: 3-2 at 1, 5, 9; 3-3 at 3, 9 ... 27; 3-4 at 3, 9', () {
      expect(pigeonPassages('3-1'), isEmpty);
      expect(pigeonPassages('3-2'), [1, 5, 9]);
      expect(pigeonPassages('3-3'), [3, 9, 15, 21, 27]);
      expect(pigeonPassages('3-4'), [3, 9]);
      // At least four passages apart, so no two flocks share a screen.
      for (final id in ['3-2', '3-3', '3-4']) {
        final at = pigeonPassages(id);
        for (var i = 1; i < at.length; i++) {
          expect(at[i] - at[i - 1], greaterThanOrEqualTo(4), reason: id);
        }
      }
    });

    test('worst cases: 3, 9 and 3 pigeons against caps of 3, 10 and 4', () {
      // Flocks cycle per pigeon entry: 3-2 lays 1+1+1, 3-3 lays 1+2+2+2+2
      // and 3-4 lays 1+2 (route stars, cap from the third mark, worst case).
      for (final (id, stars, cap, worst) in [
        ('3-2', 36, 3, 3),
        ('3-3', 90, 10, 9),
        ('3-4', 36, 4, 3),
      ]) {
        final l = level(id);
        final sim = levelFlight(l);
        expect(sim.route!.stars, stars, reason: id);
        expect(sim.thiefBudget, cap, reason: id);
        expect(
          AlleyPigeon.thiefCap(routeStars: stars, threeStarMark: l.marks.three),
          cap,
        );
        var laid = 0;
        for (var k = 0; k < pigeonPassages(id).length; k++) {
          laid += l.plan.flockSizeFor(k);
        }
        expect(laid, worst, reason: id);
        expect(laid, lessThanOrEqualTo(cap), reason: id);
        // The worst case still leaves the third mark (with as much again).
        expect(stars - laid, greaterThanOrEqualTo(l.marks.three), reason: id);
      }
    });

    test('steam slots: 3-3 has seven, 3-4 three, none elsewhere', () {
      String slots(String id) => levelFlight(level(id)).route!.geysers
          .map((g) => '${g.slot}${g.kind == SteamKind.hop ? 'H' : 'R'}')
          .join(' ');
      expect(slots('3-1'), isEmpty);
      expect(slots('3-2'), isEmpty);
      expect(slots('3-3'), '4H 8R 12H 16R 20H 24R 28H');
      expect(slots('3-4'), '4R 8H 12R');
      for (final id in ['3-3', '3-4']) {
        final l = level(id);
        final route = levelFlight(l).route!;
        // A vent never takes an enemy-led passage, and the last is passed at
        // least two seconds before the goal or the boss arrives.
        for (final g in route.geysers) {
          expect(l.plan.enemyIndex(g.slot), isNull, reason: '$id ${g.slot}');
        }
        expect(l.plan.steam.routeProblem(route, l.plan.length), isNull);
      }
    });
  });

  group('Paris keeps the set pieces New York gave up, and introduces them', () {
    test('3-6 keeps its gale and wildfire, 3-7 its swarm and gale', () {
      final a = level('3-6').plan, b = level('3-7').plan;
      expect(
        [for (final p in a.pieces) (p.kind, p.at, p.after)],
        [(SetPieceKind.gale, 20.0, false), (SetPieceKind.wildfire, 8.0, true)],
      );
      expect(
        [for (final p in b.pieces) (p.kind, p.at, p.after)],
        [(SetPieceKind.swarm, 20.0, false), (SetPieceKind.gale, 55.0, false)],
      );
      expect((a.marks.two, a.marks.three), (35, 55));
      expect((b.marks.two, b.marks.three), (40, 60));
      expect(a.minRulesVersion, 41);
      expect(b.minRulesVersion, 41);
    });

    test('the new hints name the mechanics they now introduce', () {
      expect(level('3-6').hint, 'Gale! Watch the ! and take the open side.');
      expect(level('3-7').hint, 'Sprint through the flocks.');
      for (final id in ['3-6', '3-7']) {
        expect(level(id).hintIsNew, isTrue, reason: id);
      }
      // 3-5 and the Dusk Empress's own level carry no hint, as before.
      expect(level('3-5').hint, isNull);
      expect(level('3-8').hint, isNull);
    });

    test('Paris stays closed: nothing of chapter 3 after 3-4 is playable', () {
      Campaign.openedForTest = true;
      for (final id in ['3-5', '3-6', '3-7', '3-8']) {
        expect(Campaign.playable(level(id)), isFalse, reason: id);
      }
      expect(Campaign.comingSoon(WorldRegion.paris), isTrue);
    });
  });

  group('a boss level holds no set pieces', () {
    final bossLevels = [
      for (final l in Campaign.levels)
        if (l.isBoss) l,
    ];

    test('the seven boss levels: a 30 s run-up, no piece, an enemy lineup', () {
      expect(
        [for (final l in bossLevels) l.id],
        ['1-8', '2-8', '3-2', '3-4', '3-8', '4-8', '5-8'],
      );
      for (final l in bossLevels) {
        expect(l.plan.length, 30, reason: l.id);
        expect(l.plan.pieces, isEmpty, reason: l.id);
        expect(l.plan.lineup, isNotEmpty, reason: l.id);
        expect(l.plan.problem, isNull, reason: l.id);
        expect(levelFlight(l).route!.pieces, isEmpty, reason: l.id);
      }
    });

    test('a set piece on a guardian\'s level is refused (the Gale, the '
        'Swarm)', () {
      for (final (id, piece) in [
        ('3-2', const SetPiece(SetPieceKind.gale, at: 10)),
        ('3-4', const SetPiece(SetPieceKind.swarm, at: 10)),
      ]) {
        final p = level(id).plan;
        final spoiled = LevelPlan(
          id: p.id,
          region: p.region,
          length: p.length,
          start: p.start,
          seed: p.seed,
          families: p.families,
          lineup: p.lineup,
          flocks: p.flocks,
          steam: p.steam,
          toughness: p.toughness,
          panels: p.panels,
          boss: p.boss,
          pieces: [piece],
          marks: p.marks,
        );
        expect(spoiled.problem, 'boss', reason: id);
        expect(
          () => LevelPlan.fromJson(spoiled.toJson()),
          throwsFormatException,
          reason: id,
        );
      }
    });

    test('a guardian\'s run-up may hold steam and pigeons: a slot is no set '
        'piece', () {
      expect(level('3-4').plan.steam.isEmpty, isFalse);
      expect(level('3-4').plan.flocks, isNotEmpty);
      expect(level('3-4').plan.problem, isNull);
    });
  });

  group('guardian levels end their chapter\'s flow correctly', () {
    test('only 3-8 is the chapter\'s boss level', () {
      final chapter = Campaign.chapters[2];
      expect(chapter.bossLevel.id, '3-8');
      expect(chapter.boss, BossKind.duskMoth);
      for (final l in chapter.levels) {
        expect(l.isChapterBoss, l.id == '3-8', reason: l.id);
        expect(l.isGuardian, l.id == '3-2' || l.id == '3-4', reason: l.id);
        expect(l.isMiniBoss, l.isGuardian, reason: l.id);
      }
      expect(Campaign.bossLine(level('3-8')), chapter.bossLine);
    });

    test('a guardian has a lair scene and a last word; no chapter scene', () {
      expect(CampaignStory.before(level('3-2'))!.boss, BossKind.kingCoo);
      expect(
        CampaignStory.before(level('3-4'))!.boss,
        BossKind.searchlightGargoyle,
      );
      expect(CampaignStory.lastWord(level('3-2'))!.id, 'last-3-2');
      expect(CampaignStory.lastWord(level('3-4'))!.id, 'last-3-4');
      expect(CampaignStory.lastWord(level('3-4'))!.endsStop, isTrue);
      expect(CampaignStory.lastWord(level('3-2'))!.endsStop, isFalse);
      expect(CampaignStory.lastWord(level('3-1')), isNull);
      expect(CampaignStory.lastWord(level('3-3')), isNull);
      // The chapter's own scene after its boss is still 3-8's.
      expect(CampaignStory.after(Campaign.chapters[2]).id, 'after-3');
    });

    test('a flight of each guardian level ends at its boss, not at a line '
        'first', () {
      for (final id in ['3-2', '3-4']) {
        final sim = levelFlight(level(id));
        expect(sim.route!.boss, isTrue, reason: id);
        expect(sim.plan.firstBossAt, 30, reason: id);
      }
    });
  });

  group('a guardian win unlocks the next level only', () {
    setUp(() => Campaign.openedForTest = true);

    test('King Coo opens 3-3: no chapter, no postcard, no seal', () {
      final before = progressAfter(['3-1']);
      expect(before.unlocked(level('3-2')), isTrue);
      expect(before.unlocked(level('3-3')), isFalse);
      final after = progressAfter(['3-1', '3-2']);
      expect(after.unlocked(level('3-3')), isTrue);
      expect(after.unlocked(level('3-4')), isFalse);
      expect(after.unlocked(level('3-8')), isFalse);
      final chapter = Campaign.chapters[2];
      expect(after.chapterComplete(chapter), isFalse);
      expect(after.postcardDue(chapter), isFalse);
      expect(after.sceneAfter(chapter), isNull);
      expect(after.chapterUnlocked(Campaign.chapters[3]), isFalse);
      // Flame seals follow finished chapters: still the two Dragon-era ones.
      expect(Campaign.chapters.where(after.chapterComplete), hasLength(2));
    });

    test('the Gargoyle opens nothing: Paris is not in the build', () {
      final after = progressAfter(['3-1', '3-2', '3-3', '3-4']);
      final chapter = Campaign.chapters[2];
      expect(after.unlocked(level('3-5')), isFalse, reason: 'Paris waits');
      expect(after.chapterComplete(chapter), isFalse);
      expect(after.postcardDue(chapter), isFalse);
      expect(after.sceneAfter(chapter), isNull);
      expect(after.chapterUnlocked(Campaign.chapters[3]), isFalse);
      expect(Campaign.chapters.where(after.chapterComplete), hasLength(2));
      // The courier stays on the last New York level.
      expect(after.current.id, '3-4');
    });

    test('each guardian\'s last word plays once, after its first win', () {
      var progress = progressAfter(['3-1']);
      expect(progress.sceneLast(level('3-2')), isNull, reason: 'not beaten');
      progress = progressAfter(['3-1', '3-2']);
      expect(progress.sceneLast(level('3-2'))!.id, 'last-3-2');
      expect(progress.sceneLast(level('3-4')), isNull);
      progress = progressAfter(['3-1', '3-2'], watched: {'last-3-2'});
      expect(progress.sceneLast(level('3-2')), isNull, reason: 'heard once');
      progress = progressAfter(['3-1', '3-2', '3-3', '3-4']);
      expect(progress.sceneLast(level('3-4'))!.id, 'last-3-4');
      // A chapter boss has no last word; its scene is the chapter's.
      expect(progress.sceneLast(level('3-8')), isNull);
      expect(progress.sceneLast(level('2-8')), isNull);
    });
  });

  group('the open stop: progression and the star total', () {
    setUp(() => Campaign.openedForTest = true);

    test('2-8 to 3-1 to 3-4, level by level', () {
      var progress = CampaignProgress(chaptersOneAndTwo());
      expect(progress.current.id, '3-1');
      const path = ['3-1', '3-2', '3-3', '3-4'];
      for (final (i, id) in path.indexed) {
        expect(progress.unlocked(level(id)), isTrue, reason: id);
        for (final later in path.skip(i + 1)) {
          expect(progress.unlocked(level(later)), isFalse, reason: later);
        }
        expect(progress.current.id, id);
        progress = CampaignProgress([...progress.records.values, cleared(id)]);
      }
      expect(progress.current.id, '3-4');
    });

    test('the lock notes name what opens each level', () {
      expect(lockedNudge(level('3-2')), 'Finish 3-1 to unlock');
      expect(lockedNudge(level('3-3')), 'Beat King Coo to unlock');
      expect(lockedNudge(level('3-4')), 'Finish 3-3 to unlock');
      expect(lockedNudge(level('3-5')), 'Coming soon');
    });

    test('the star total is 60: 20 levels', () {
      expect(Campaign.playableLevels, hasLength(20));
      expect(campaignStarsInBuild, 60);
      final full = CampaignProgress([
        for (final chapter in Campaign.chapters.take(2))
          for (final l in chapter.levels) cleared(l.id, stars: 3),
        for (final id in ['3-1', '3-2', '3-3', '3-4']) cleared(id, stars: 3),
      ]);
      expect(full.starsInRegion(WorldRegion.newYork), 12);
      expect(full.starsInChapter(Campaign.chapters[2]), 12);
      expect(full.totalStars, 60);
    });

    test('the map draws New York as two plain levels and two shields', () {
      final stops = campaignStops(progressAfter(['3-1']));
      final ny = stops.firstWhere((s) => s.region == WorldRegion.newYork);
      expect([for (final n in ny.nodes) n.id], ['3-1', '3-2', '3-3', '3-4']);
      expect(
        [for (final n in ny.nodes) n.isGuardian],
        [false, true, false, true],
      );
      expect([for (final n in ny.nodes) n.isBoss], everyElement(isFalse));
      expect(ny.nodes[1].boss, BossKind.kingCoo);
      expect(ny.nodes[3].boss, BossKind.searchlightGargoyle);
      expect(ny.comingSoon, isFalse);
      expect(ny.postcard, isFalse, reason: 'a guardian brings no postcard');
      final paris = stops.firstWhere((s) => s.region == WorldRegion.paris);
      expect(paris.comingSoon, isTrue);
      expect(paris.soonNote, 'Paris — coming soon');
      expect(paris.nodes.any((n) => n.isGuardian), isFalse);
    });
  });

  group('the opening flag: both states', () {
    test('the build ships open: no hook, New York is playable, 60 stars', () {
      // `NEW_YORK_OPEN` defaults to true; only `--dart-define=
      // NEW_YORK_OPEN=false` (the rollback) closes the stop. Under that
      // define this same test asserts the closed numbers.
      const defined = bool.hasEnvironment('NEW_YORK_OPEN');
      const value = bool.fromEnvironment('NEW_YORK_OPEN');
      final open = !defined || value;
      expect(Campaign.openingEnabled, open);
      expect(Campaign.stopsOpen, open);
      expect(Campaign.playableLevels, hasLength(open ? 20 : 16));
      expect(campaignStarsInBuild, open ? 60 : 48);
      final progress = CampaignProgress(chaptersOneAndTwo());
      expect(progress.unlocked(level('3-1')), open);
      expect(progress.current.id, open ? '3-1' : '2-8');
      expect(Campaign.comingSoon(WorldRegion.newYork), !open);
      expect(Campaign.comingSoon(WorldRegion.paris), isTrue);
    });

    test('closed (NEW_YORK_OPEN=false): four locked coins, 48 stars', () {
      // The rollback state: the same code with the stop shut.
      Campaign.closedForTest = true;
      expect(Campaign.stopsOpen, isFalse);
      for (final l in Campaign.levels) {
        expect(Campaign.playable(l), l.chapter <= 2, reason: l.id);
      }
      expect(Campaign.playableLevels, hasLength(16));
      expect(campaignStarsInBuild, 48);
      final progress = CampaignProgress(chaptersOneAndTwo());
      expect(progress.unlocked(level('3-1')), isFalse);
      expect(progress.current.id, '2-8');
      expect(lockedNudge(level('3-1')), 'Coming soon');
      expect(Campaign.comingSoon(WorldRegion.newYork), isTrue);
      final stops = campaignStops(progress);
      final ny = stops.firstWhere((s) => s.region == WorldRegion.newYork);
      // Four plain locked coins: no shield for a guardian nobody can meet.
      expect(ny.comingSoon, isTrue);
      expect(ny.soonNote, 'Coming soon');
      expect([for (final n in ny.nodes) n.boss], everyElement(isNull));
      expect(ny.nodes.every((n) => n.locked), isTrue);
    });

    test('closed: the star total ignores stars a New York save earned', () {
      final records = [
        ...chaptersOneAndTwo(),
        for (final id in ['3-1', '3-2', '3-3', '3-4']) cleared(id, stars: 3),
      ];
      final progress = CampaignProgress(records);
      Campaign.openedForTest = true;
      expect(progress.totalStars, 16 * 2 + 12);
      Campaign.openedForTest = false;
      Campaign.closedForTest = true;
      // Never "N / 48" with N above 48: the closed build counts only what it
      // can fly.
      expect(progress.totalStars, 16 * 2);
      expect(progress.totalStars, lessThanOrEqualTo(campaignStarsInBuild));
    });

    test('open: the same data opens, 60 stars, Paris still soon', () {
      Campaign.openedForTest = true;
      expect(Campaign.playableLevels, hasLength(20));
      expect(campaignStarsInBuild, 60);
      final progress = CampaignProgress(chaptersOneAndTwo());
      expect(progress.unlocked(level('3-1')), isTrue);
      expect(progress.current.id, '3-1');
      expect(Campaign.comingSoon(WorldRegion.newYork), isFalse);
      expect(Campaign.comingSoon(WorldRegion.paris), isTrue);
      // Closing it again leaves no trace.
      Campaign.openedForTest = false;
      Campaign.closedForTest = true;
      expect(Campaign.playableLevels, hasLength(16));
      expect(progress.unlocked(level('3-1')), isFalse);
    });

    test('closed wins over open, and false hands back to the build', () {
      Campaign.openedForTest = true;
      Campaign.closedForTest = true;
      expect(Campaign.stopsOpen, isFalse);
      Campaign.closedForTest = false;
      expect(Campaign.stopsOpen, isTrue);
      Campaign.openedForTest = false;
      expect(Campaign.stopsOpen, Campaign.openingEnabled);
    });

    test('the level data itself does not depend on the flag', () {
      Campaign.closedForTest = true;
      final closed = [
        for (final id in ['3-1', '3-2', '3-3', '3-4'])
          jsonEncode(level(id).plan.toJson()),
      ];
      Campaign.closedForTest = false;
      Campaign.openedForTest = true;
      final open = [
        for (final id in ['3-1', '3-2', '3-3', '3-4'])
          jsonEncode(level(id).plan.toJson()),
      ];
      expect(open, closed);
    });
  });
}
