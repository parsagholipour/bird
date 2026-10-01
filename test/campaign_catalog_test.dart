import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';

import 'campaign_flight.dart';

LevelRoute routeOf(CampaignLevel level) {
  final sim = levelFlight(level);
  return sim.route!;
}

/// Marks at [low] and [high] of the stars laid, rounded to fives.
(int, int) marksFor(int stars, double low, double high) {
  int five(double value) => (value / 5).round() * 5;
  return (five(stars * low), five(stars * high));
}

void main() {
  test('five chapters of eight levels, one boss each, in boss order', () {
    expect(Campaign.chapters, hasLength(5));
    expect(Campaign.levels, hasLength(40));
    for (final (i, chapter) in Campaign.chapters.indexed) {
      expect(chapter.number, i + 1);
      expect(chapter.boss, BossKind.values[i]);
      expect(chapter.levels, hasLength(8));
      expect(chapter.playable, chapter.number <= 2);
      expect(chapter.bossLine, isNotEmpty);
      expect(chapter.postcard, startsWith('Dear courier, '));
      expect(chapter.postscript, startsWith('P.S. '));
      for (final (j, level) in chapter.levels.indexed) {
        expect(level.id, '${chapter.number}-${j + 1}');
        expect(level.chapter, chapter.number);
        expect(level.number, j + 1);
        expect(Campaign.chapterOf(level), same(chapter));
        expect(Campaign.level(level.id), same(level));
        // Only the last level is the chapter's boss; New York's two
        // guardians (3-2 King Coo, 3-4 the Searchlight Gargoyle) also end in
        // a boss, a campaign-only mini-boss. `isBoss` means any boss.
        expect(level.isChapterBoss, j == 7, reason: level.id);
        expect(
          level.isBoss,
          j == 7 || level.id == '3-2' || level.id == '3-4',
          reason: level.id,
        );
        expect(level.isGuardian, level.isBoss && j != 7, reason: level.id);
      }
      expect(chapter.bossLevel.boss, chapter.boss);
      expect(
        chapter.bossLevel.name,
        SkyBoss(number: 1, x: 0, kind: chapter.boss).name,
      );
    }
    expect(Campaign.levels.map((l) => l.id).toSet(), hasLength(40));
    expect(Campaign.levels.map((l) => l.plan.seed).toSet(), hasLength(40));
    expect(Campaign.level('6-1'), isNull);
    expect(Campaign.after(Campaign.level('1-8')!)!.id, '2-1');
    expect(Campaign.before(Campaign.level('2-1')!)!.id, '1-8');
    expect(Campaign.before(Campaign.levels.first), isNull);
    expect(Campaign.after(Campaign.levels.last), isNull);
  });

  test('the map goes region by region, in the order of the journey', () {
    const journey = [
      (WorldRegion.jungle, 3),
      (WorldRegion.brazil, 2),
      (WorldRegion.aztec, 3),
      (WorldRegion.rome, 3),
      (WorldRegion.egypt, 2),
      (WorldRegion.arabia, 3),
      (WorldRegion.newYork, 4),
      (WorldRegion.paris, 4),
      (WorldRegion.mexico, 3),
      (WorldRegion.sea, 5),
      (WorldRegion.antarctica, 2),
      (WorldRegion.cyberpunk, 3),
      (WorldRegion.china, 3),
    ];
    expect(Campaign.journey, [for (final (region, _) in journey) region]);
    expect(Campaign.journey.toSet(), WorldRegion.values.toSet());
    expect(Campaign.levels.map((l) => l.region).toList(), [
      for (final (region, count) in journey) ...List.filled(count, region),
    ]);
    for (final chapter in Campaign.chapters) {
      expect(
        chapter.levels.map((l) => l.region).toSet().toList(),
        chapter.regions,
      );
    }
  });

  test('lengths, starts and set pieces fit the level', () {
    for (final level in Campaign.levels) {
      final plan = level.plan;
      final id = level.id;
      expect(plan.problem, isNull, reason: id);
      if (level.isBoss) {
        // A boss level (a chapter's or a guardian's) is a 30 s run-up with
        // no set pieces; it may hold pigeons and, in a guardian's run-up,
        // a light steam layer (a steam slot is not a set piece).
        expect(level.length, 30, reason: id);
        expect(plan.pieces, isEmpty, reason: id);
      } else {
        expect(level.length, inInclusiveRange(60, 90), reason: id);
      }
      expect(level.start, inInclusiveRange(0, 270), reason: id);
      expect(plan.toughness, level.chapter - 1, reason: id);
      final route = routeOf(level);
      var clear = route.passages.first;
      for (final piece in route.pieces) {
        // Each piece starts past the one before and ends well before the
        // finish, with passages on both sides.
        expect(piece.start, greaterThan(clear + 1), reason: id);
        expect(piece.end, greaterThan(piece.start), reason: id);
        expect(
          route.passages.where((x) => x > piece.start && x < piece.end),
          isEmpty,
          reason: id,
        );
        clear = piece.end;
      }
      expect(route.goal - clear, greaterThan(1.5), reason: id);
      expect(route.passages.last, lessThan(route.goal - FinishLine.clearance));
    }
  });

  test('mechanics arrive chapter by chapter', () {
    for (final level in Campaign.levels) {
      final plan = level.plan;
      final id = level.id;
      final chapter = level.chapter;
      final kinds = plan.families.toSet();
      final enemies = plan.lineup.toSet();
      final rushes = {for (final p in plan.pieces) p.kind};
      expect(kinds, contains(ObstacleKind.garden), reason: id);
      if (chapter < 3) {
        expect(kinds, isNot(contains(ObstacleKind.sunWheels)), reason: id);
        expect(kinds, isNot(contains(ObstacleKind.crystalSteps)));
        expect(enemies, isNot(contains(EnemyKind.duskMoth)), reason: id);
        expect(rushes, isNot(contains(SetPieceKind.gale)), reason: id);
        expect(rushes, isNot(contains(SetPieceKind.swarm)), reason: id);
      }
      if (chapter < 2) {
        expect(kinds, isNot(contains(ObstacleKind.switchback)), reason: id);
        expect(kinds, isNot(contains(ObstacleKind.lanternDrift)));
        expect(enemies, isNot(contains(EnemyKind.spitterBeetle)));
        expect(plan.panels, 0, reason: id);
        expect(rushes, isEmpty, reason: id);
      }
      if (chapter < 4) {
        expect(rushes, isNot(contains(SetPieceKind.eruption)), reason: id);
      }
      if (chapter < 5) {
        expect(rushes, isNot(contains(SetPieceKind.shuffled)), reason: id);
      }
      expect(plan.shoot, chapter > 1 || level.number >= 3, reason: id);
      // Sprint is on from 1-5, except in the Searchlight Gargoyle's level
      // (3-4): a sprint makes his feathers close faster than the lane they
      // were aimed for, which his fairness proof assumes away.
      expect(
        plan.sprint,
        (chapter > 1 || level.number >= 5) && id != '3-4',
        reason: id,
      );
      // New York's additions (rules 43) come in order: the Alley Pigeon at
      // 3-2, steam at 3-3; nothing before, nothing in Paris yet.
      final newYork = level.region == WorldRegion.newYork;
      final pigeons = enemies.contains(EnemyKind.alleyPigeon);
      expect(pigeons, id == '3-2' || id == '3-3' || id == '3-4', reason: id);
      expect(plan.flocks.isNotEmpty, pigeons, reason: id);
      expect(plan.steam.isEmpty, id != '3-3' && id != '3-4', reason: id);
      expect(plan.usesNewYork, newYork && level.number > 1, reason: id);
      expect(
        plan.minRulesVersion,
        newYork && level.number > 1 ? 43 : 41,
        reason: id,
      );
    }
    CampaignLevel at(String id) => Campaign.level(id)!;
    expect(at('1-1').plan.families, [ObstacleKind.garden]);
    expect(at('1-1').plan.lineup, isEmpty);
    expect(at('1-2').plan.lineup, isEmpty);
    expect(at('1-2').plan.families, contains(ObstacleKind.windLift));
    expect(at('1-3').plan.cadence, 4);
    expect(at('1-4').plan.families, contains(ObstacleKind.petalGate));
    expect(at('2-1').plan.lineup, contains(EnemyKind.spitterBeetle));
    expect(at('2-1').plan.panels, 0);
    expect(at('2-2').plan.panels, .35);
    expect(at('2-3').plan.pieces.single.kind, SetPieceKind.wildfire);
    expect(at('2-3').plan.pieces.single.at, 25);
    expect(at('2-4').plan.families, contains(ObstacleKind.switchback));
    expect(at('2-5').plan.pieces.single.kind, SetPieceKind.skyfall);
    expect(at('2-6').plan.families, contains(ObstacleKind.lanternDrift));
    expect(at('2-7').plan.pieces.map((p) => (p.kind, p.at)), [
      (SetPieceKind.wildfire, 25),
      (SetPieceKind.skyfall, 60),
    ]);
    expect(at('3-1').plan.lineup, contains(EnemyKind.duskMoth));
    // New York: two guardians and two full levels, none with a set piece.
    // The Swarm rush and the Gale moved to Paris (3-7 and 3-6).
    for (final id in ['3-1', '3-2', '3-3', '3-4']) {
      expect(at(id).plan.pieces, isEmpty, reason: id);
    }
    expect(at('3-2').boss, BossKind.kingCoo);
    expect(at('3-4').boss, BossKind.searchlightGargoyle);
    expect(at('3-3').plan.steam, SteamPlan.steady);
    expect(at('3-4').plan.steam, SteamPlan.sparse);
    expect(at('3-6').plan.pieces.first.kind, SetPieceKind.gale);
    expect(at('3-7').plan.pieces.map((p) => p.kind), [
      SetPieceKind.swarm,
      SetPieceKind.gale,
    ]);
    expect(at('4-2').plan.pieces.single.kind, SetPieceKind.eruption);
    expect(at('5-1').plan.pieces.single.kind, SetPieceKind.shuffled);
    for (final id in [
      '1-1', '1-2', '1-3', '1-5', '2-1', '2-2', '2-3', '2-5',
      // New York: moths, the Alley Pigeon, steam and the Gargoyle's lamp;
      // Paris introduces the Gale and the Swarm rush the stop gave up.
      '3-1', '3-2', '3-3', '3-4', '3-6', '3-7',
    ]) {
      expect(at(id).hint, isNotNull, reason: id);
      expect(at(id).hintIsNew, isTrue, reason: id);
    }
    expect(at('3-2').hint, contains('pigeons'));
    expect(at('3-3').hint, contains('Hop the hot ones'));
    expect(at('3-3').hint, contains('ride the soft ones'));
    expect(at('3-4').hint, contains('light'));
    expect(at('3-6').hint, contains('Gale'));
    expect(at('3-7').hint, contains('flocks'));
    expect(at('1-4').hint, isNull);
    expect(at('5-1').hintIsNew, isFalse);
  });

  test('star marks sit at their share of the stars laid on the route', () {
    // Every level, including the locked chapters, so their marks are ready
    // when they open.
    for (final level in Campaign.levels) {
      final stars = routeOf(level).stars;
      final marks = level.marks;
      expect(marks.two, greaterThan(0), reason: level.id);
      expect(marks.two, lessThan(marks.three), reason: level.id);
      // Pinned from the route (a boss level's run-up): 45% and 75% in
      // chapter 1, 50% and 80% from chapter 2, rounded to fives.
      final (two, three) = level.chapter == 1
          ? marksFor(stars, .45, .75)
          : marksFor(stars, .5, .8);
      if (level.id == '3-4') {
        // The one exception: the Gargoyle's steam run-up has its third mark
        // at 75% (27 of 36), not 30. Its steam arcs and pigeons cost a casual
        // pilot two stars more than King Coo's run-up, and the review found
        // 30 out of reach for 35 to 62% of them (see docs/validation.md). Its
        // thief cap, (36 - 27) / 2 = 4, still covers the three pigeons.
        expect((marks.two, marks.three), (two, 27), reason: level.id);
        expect(marks.three, (stars * .75).round(), reason: level.id);
      } else {
        expect((marks.two, marks.three), (two, three), reason: level.id);
      }
      expect(marks.three, lessThan(stars), reason: level.id);
    }
    int stars(String id) => routeOf(Campaign.level(id)!).stars;
    expect(stars('1-1'), 81);
    expect(stars('1-8'), 36);
    expect(stars('2-7'), 111);
    // New York (real routes): 3-1 81 (27 passages; 96 at 70 s before the fix
    // round); the two run-ups 12 passages, 36; Steam Alley 30 passages, 90
    // (114 at 80 s), the same as without its vents (a vent keeps its slot's
    // three stars). The gale and the swarm that used to shorten 3-4 and 3-3
    // moved to Paris: 3-6's gale lays no stars for 14 passages.
    expect(stars('3-1'), 81);
    expect(stars('3-2'), 36);
    expect(stars('3-3'), 90);
    expect(stars('3-4'), 36);
    expect(stars('3-6'), 69);
    expect(stars('4-3'), 69);
    expect(stars('5-8'), 36);
  });

  test('a plan survives JSON exactly and rejects anything malformed', () {
    for (final level in Campaign.levels) {
      final json = jsonDecode(jsonEncode(level.plan.toJson()));
      final plan = LevelPlan.fromJson(json as Map<String, dynamic>);
      expect(plan.toJson(), level.plan.toJson(), reason: level.id);
    }
    final good = Campaign.level('2-7')!.plan.toJson();
    Map<String, dynamic> spoiled(String key, Object? value) =>
        jsonDecode(jsonEncode({...good, key: value})) as Map<String, dynamic>;
    for (final (key, value) in [
      ('id', ''),
      ('id', 7),
      ('region', 'atlantis'),
      ('length', -1),
      ('length', 'long'),
      ('start', null),
      ('seed', 1.5),
      ('families', []),
      ('families', ['garden', 'moat']),
      ('lineup', ['dragon']),
      ('cadence', 0),
      ('toughness', 9),
      ('shoot', 'yes'),
      ('panels', 2),
      (
        'pieces',
        [
          {'kind': 'tornado', 'at': 10, 'after': false},
        ],
      ),
      (
        'pieces',
        [
          {'kind': 'wildfire', 'at': 10},
        ],
      ),
      ('pieces', 'wildfire'),
      ('boss', 'kraken'),
      ('marks', [80, 50]),
      ('marks', [50]),
    ]) {
      expect(
        () => LevelPlan.fromJson(spoiled(key, value)),
        throwsFormatException,
        reason: '$key: $value',
      );
    }
    // A boss level lays no set pieces.
    expect(
      () => LevelPlan.fromJson({
        ...Campaign.level('1-8')!.plan.toJson(),
        'pieces': [
          {'kind': 'skyfall', 'at': 10, 'after': false},
        ],
      }),
      throwsFormatException,
    );
  });
}
