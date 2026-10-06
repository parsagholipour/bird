import 'dart:convert';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/passport_progress.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/data/session_repository.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/campaign_story.dart';
import 'package:push_up_bird/domain/daily_adventure.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/sky_passport.dart';
import 'package:push_up_bird/domain/tracking.dart';

import 'campaign_flight.dart';

CampaignLevel level(String id) => Campaign.level(id)!;

/// A scored flight of campaign level [levelId], as the play screen saves it.
RunResult levelRun(
  String id,
  String levelId, {
  int stars = 20,
  EndReason reason = EndReason.completed,
  int score = 100,
  int gates = 8,
  int combo = 9,
  int perfects = 3,
  double duration = 85,
  int bird = 0,
  DateTime? at,
  bool practice = false,
  PlayMode mode = PlayMode.touch,
  FlightCourse course = FlightCourse.starTrail,
}) => RunResult(
  id: id,
  mode: mode,
  practice: practice,
  course: course,
  score: score,
  gates: gates,
  stars: stars,
  bestCombo: combo,
  perfectPasses: perfects,
  repetitions: 0,
  flaps: 40,
  durationSeconds: duration,
  reason: reason,
  finishedAt: at ?? DateTime(2026, 9, 20, 12),
  bird: bird,
  levelId: levelId,
);

/// An endless touch Star Trail.
RunResult trailRun(
  String id, {
  int score = 30,
  int stars = 25,
  int gates = 8,
  int combo = 6,
  int perfects = 1,
  double duration = 40,
  int bird = 0,
  DateTime? at,
}) => RunResult(
  id: id,
  mode: PlayMode.touch,
  practice: false,
  course: FlightCourse.starTrail,
  score: score,
  gates: gates,
  stars: stars,
  bestCombo: combo,
  perfectPasses: perfects,
  repetitions: 0,
  flaps: 40,
  durationSeconds: duration,
  reason: EndReason.collision,
  finishedAt: at ?? DateTime(2026, 9, 20, 12),
  bird: bird,
);

SqliteProgressRepository memoryRepo({DateTime Function()? clock}) {
  final repo = SqliteProgressRepository(
    ProgressDatabase(NativeDatabase.memory()),
    clock: clock,
  );
  addTearDown(repo.close);
  return repo;
}

/// The schema-4 tables exactly as Drift created them before the campaign.
const _schema4 = [
  'CREATE TABLE "runs" ("id" TEXT NOT NULL, "mode" INTEGER NOT NULL, '
      '"course" TEXT NOT NULL DEFAULT \'classic\', '
      '"gates" INTEGER NOT NULL DEFAULT 0, "stars" INTEGER NOT NULL DEFAULT 0, '
      '"best_combo" INTEGER NOT NULL DEFAULT 0, '
      '"perfect_passes" INTEGER NOT NULL DEFAULT 0, '
      '"practice" INTEGER NOT NULL CHECK ("practice" IN (0, 1)), '
      '"score" INTEGER NOT NULL CHECK("score" >= 0), '
      '"repetitions" INTEGER NOT NULL, "flaps" INTEGER NOT NULL, '
      '"duration" REAL NOT NULL, "reason" TEXT NOT NULL, '
      '"finished_at" INTEGER NOT NULL, "bird" INTEGER NOT NULL DEFAULT 0, '
      'PRIMARY KEY ("id"))',
  'CREATE TABLE "preferences" ("key" TEXT NOT NULL, "value" TEXT NOT NULL, '
      'PRIMARY KEY ("key"))',
];

Map<SkyStamp, int> stamps(ProgressSnapshot p) => {
  for (final stamp in p.passport) stamp.stamp: stamp.current,
};

void main() {
  test(
    'a schema-4 database keeps every flight and setting and gains an empty campaign',
    () async {
      final touch = PlayMode.touch.index;
      final db = ProgressDatabase(
        NativeDatabase.memory(
          setup: (raw) {
            _schema4.forEach(raw.execute);
            raw.execute(
              "INSERT INTO runs VALUES ('trail',$touch,'starTrail',5,40,12,3,0,90,0,30,65.0,'collision',1758000000,2)",
            );
            raw.execute(
              "INSERT INTO runs VALUES ('classic',0,'classic',7,0,0,1,0,7,9,0,20.0,'collision',1758000100,1)",
            );
            raw.execute(
              "INSERT INTO runs VALUES ('practice',$touch,'starTrail',1,99,99,9,1,999,0,10,30.0,'quit',1758000200,3)",
            );
            raw.execute(
              "INSERT INTO preferences VALUES ('bird','2'),('reducedMotion','true'),('music','false')",
            );
            raw.execute('PRAGMA user_version = 4');
          },
        ),
      );
      final repo = SqliteProgressRepository(db);
      addTearDown(repo.close);
      var p = await repo.load();
      expect(
        (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
          'user_version',
        ),
        7, // schema 7: the level builder (6 renumbered Arabia, 2-6..2-8)
      );
      expect(p.trailTouch.best, 90);
      expect(p.trailTouch.stars, 40);
      expect(p.trailTouch.completions, 1);
      expect(p.pushUp.best, 7);
      expect(p.totalRuns, 2);
      expect(p.birdsFlown, {1, 2});
      expect(p.settings.bird, 2);
      expect(p.settings.reducedMotion, isTrue);
      expect(p.settings.music, isFalse);
      expect(p.recent.map((r) => r.id), ['classic', 'trail']);
      expect(p.recent.every((r) => r.levelId == null), isTrue);
      expect(p.campaign.records, isEmpty);
      expect(p.campaign.current.id, '1-1');
      expect(p.campaignFlights.runs, 0);

      // The new table and column work on the migrated database.
      await repo.saveRun(levelRun('level', '1-1', score: 500));
      p = await repo.load();
      expect(p.campaign.cleared(level('1-1')), isTrue);
      expect(p.trailTouch.best, 90);
      expect(p.totalRuns, 2);
    },
  );

  test('saving a level keeps its bests and counts each flight once', () async {
    final repo = memoryRepo();
    final first = level('1-1');
    final marks = first.marks;
    // A lost level counts as a play but earns no stars and unlocks nothing.
    await repo.saveRun(
      levelRun(
        'lost',
        '1-1',
        stars: marks.three + 5,
        score: 400,
        reason: EndReason.collision,
        at: DateTime(2026, 9, 20, 10),
      ),
    );
    var p = await repo.load();
    var record = p.campaign.record(first);
    expect(record.plays, 1);
    expect(record.bestStars, 0);
    // Only a finished flight sets bests, so a lost one's stars never show
    // as the level's best.
    expect(record.bestCollected, 0);
    expect(record.bestScore, 0);
    expect(record.firstClearedAt, isNull);
    expect(record.lastPlayedAt, DateTime(2026, 9, 20, 10));
    expect(p.campaign.unlocked(level('1-2')), isFalse);
    expect(p.campaign.current, first);

    final two = levelRun(
      'two',
      '1-1',
      stars: marks.two,
      score: 150,
      at: DateTime(2026, 9, 20, 11),
    );
    await repo.saveRun(two);
    await repo.saveRun(two);
    p = await repo.load();
    record = p.campaign.record(first);
    expect(record.plays, 2, reason: 'A retried save is not another play');
    expect(record.bestStars, 2);
    expect(record.bestCollected, marks.two);
    expect(record.bestScore, 150);
    expect(record.firstClearedAt, DateTime(2026, 9, 20, 11));
    expect(p.campaign.unlocked(level('1-2')), isTrue);
    expect(p.campaign.current.id, '1-2');
    expect(p.campaignFlights.runs, 2);

    await repo.saveRun(
      levelRun('one', '1-1', stars: 0, at: DateTime(2026, 9, 21)),
    );
    p = await repo.load();
    record = p.campaign.record(first);
    expect(record.bestStars, 2, reason: 'A worse finish keeps the best');
    expect(record.plays, 3);
    expect(record.firstClearedAt, DateTime(2026, 9, 20, 11));
    expect(record.lastPlayedAt, DateTime(2026, 9, 21));

    await repo.saveRun(
      levelRun('three', '1-1', stars: marks.three, at: DateTime(2026, 9, 22)),
    );
    p = await repo.load();
    expect(p.campaign.stars(first), 3);
    expect(p.campaign.totalStars, 3);
    expect(p.campaignFlights.completions, 3);
  });

  test('campaign flights never make endless records', () async {
    final repo = memoryRepo();
    await repo.saveRun(levelRun('level', '1-1', score: 500, stars: 70));
    var p = await repo.load();
    expect(p.record(PlayMode.touch, FlightCourse.starTrail).best, 0);
    expect(p.record(PlayMode.touch).best, 0);
    expect(p.totalRuns, 0);
    expect(p.totalStars, 0);
    expect(p.totalObstacles, 0);
    expect(p.recent, isEmpty);
    expect(p.flightsFlown, 1);
    expect(p.campaignFlights.best, 500);

    await repo.saveRun(trailRun('trail', score: 30));
    p = await repo.load();
    expect(p.record(PlayMode.touch, FlightCourse.starTrail).best, 30);
    expect(p.trailTouch.runs, 1);
    expect(p.recent.single.id, 'trail');
    expect(p.flightsFlown, 2);
  });

  test(
    'only a scored touch Star Trail of a real level carries a level',
    () async {
      final repo = memoryRepo();
      for (final run in [
        levelRun('unknown', '9-9'),
        levelRun('practice', '1-1', practice: true),
        levelRun('camera', '1-1', mode: PlayMode.pushUp),
        levelRun('classic', '1-1', course: FlightCourse.classic),
      ]) {
        await expectLater(repo.saveRun(run), throwsArgumentError);
      }
      final p = await repo.load();
      expect(p.campaignFlights.runs, 0);
      expect(p.campaign.records, isEmpty);
    },
  );

  test("a chapter's postcard is marked seen once its boss falls", () async {
    final repo = memoryRepo();
    final chapter = Campaign.chapters.first;
    await repo.markPostcardSeen(chapter);
    expect((await repo.load()).campaign.records, isEmpty);

    await repo.saveRun(levelRun('boss', chapter.bossLevel.id));
    var p = await repo.load();
    expect(p.campaign.postcardDue(chapter), isTrue);
    await repo.markPostcardSeen(chapter);
    p = await repo.load();
    expect(p.campaign.postcardDue(chapter), isFalse);
    expect(p.campaign.record(chapter.bossLevel).postcardSeen, isTrue);

    await repo.saveRun(levelRun('boss-again', chapter.bossLevel.id));
    p = await repo.load();
    expect(p.campaign.postcardDue(chapter), isFalse);
    expect(p.campaign.record(chapter.bossLevel).plays, 2);
  });

  test('a watched story scene is saved once and plays no more', () async {
    final repo = memoryRepo();
    final prologue = CampaignStory.prologue;
    final arrival = CampaignStory.before(level('1-4'))!;
    var p = await repo.load();
    expect(p.campaign.storyWatched, isEmpty);
    expect(p.campaign.prologueDue, same(prologue));

    await repo.markStoryWatched(prologue);
    await repo.markStoryWatched(prologue);
    p = await repo.load();
    expect(p.campaign.storyWatched, {prologue.id});
    expect(p.campaign.prologueDue, isNull);

    // Watching more keeps what was there, beside the other preferences.
    await repo.setSetting(SettingKey.music, false);
    await repo.equipBird(2);
    await repo.markStoryWatched(arrival);
    await repo.saveRun(levelRun('first', '1-1'));
    p = await repo.load();
    expect(p.campaign.storyWatched, {prologue.id, arrival.id});
    expect(p.settings.music, isFalse);
    expect(p.settings.bird, 2);
    expect(p.campaign.cleared(level('1-1')), isTrue);

    // A fallen boss's scene waits with its postcard until it is watched.
    final chapter = Campaign.chapters.first;
    await repo.saveRun(levelRun('boss', chapter.bossLevel.id));
    p = await repo.load();
    expect(p.campaign.sceneAfter(chapter), same(CampaignStory.after(chapter)));
    await repo.markStoryWatched(CampaignStory.after(chapter));
    p = await repo.load();
    expect(p.campaign.sceneAfter(chapter), isNull);
    expect(p.campaign.postcardDue(chapter), isTrue);
  });

  test('the progress controller saves levels and postcards', () async {
    final repo = memoryRepo();
    final container = ProviderContainer(
      overrides: [progressRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    final chapter = Campaign.chapters.first;
    await container.read(progressProvider.future);
    final progress = container.read(progressProvider.notifier);
    await progress.save(levelRun('boss', chapter.bossLevel.id));
    expect(
      container.read(progressProvider).value!.campaign.postcardDue(chapter),
      isTrue,
    );
    await progress.postcardSeen(chapter);
    expect(
      container.read(progressProvider).value!.campaign.postcardDue(chapter),
      isFalse,
    );
    await progress.storyWatched(CampaignStory.prologue);
    expect(container.read(progressProvider).value!.campaign.storyWatched, {
      CampaignStory.prologue.id,
    });
  });

  test('resetting local progress clears the campaign', () async {
    final repo = memoryRepo();
    final chapter = Campaign.chapters.first;
    await repo.saveRun(levelRun('first', '1-1'));
    await repo.saveRun(levelRun('boss', chapter.bossLevel.id));
    await repo.markPostcardSeen(chapter);
    await repo.markStoryWatched(CampaignStory.prologue);
    await repo.reset();
    final p = await repo.load();
    expect(p.campaign.records, isEmpty);
    // The story starts over with the campaign.
    expect(p.campaign.storyWatched, isEmpty);
    expect(p.campaign.prologueDue, same(CampaignStory.prologue));
    expect(p.campaign.totalStars, 0);
    expect(p.campaign.current.id, '1-1');
    expect(p.campaignFlights.runs, 0);
  });

  test('daily adventures count campaign flights except the whole journey', () {
    for (var d = 1; d <= 12; d++) {
      final date = DateTime(2026, 10, d, 12);
      final campaign = DailyAdventure.forDate(date, [
        levelRun('level', '1-1', at: date),
      ]);
      final endless = DailyAdventure.forDate(date, [
        trailRun(
          'trail',
          at: date,
          stars: 20,
          gates: 8,
          combo: 9,
          perfects: 3,
          duration: 85,
        ),
      ]);
      for (final goal in campaign.goals) {
        expect(goal.current, switch (goal.task) {
          DailyTask.flights => 1,
          DailyTask.gates => 8,
          DailyTask.stars => 20,
          DailyTask.streak => 9,
          DailyTask.perfects => 3,
          DailyTask.finishTrail => 0,
        }, reason: '${goal.task} on day $d');
      }
      expect(
        endless.goals.map((g) => g.current),
        campaign.goals.map(
          (g) => g.task == DailyTask.finishTrail ? 1 : g.current,
        ),
        reason: 'The same endless flight counts for everything',
      );
    }
    expect(
      const DailyGoal(DailyTask.stars, 18, 0).description,
      'Collect 18 stars across today’s flights.',
    );
  });

  test('saved campaign flights reach the daily adventure', () async {
    final now = DateTime(2026, 9, 20, 18);
    final repo = memoryRepo(clock: () => now);
    await repo.saveRun(levelRun('level', '1-1', at: now, combo: 9));
    final today = (await repo.load()).today!;
    for (final goal in today.goals) {
      expect(goal.current, switch (goal.task) {
        DailyTask.flights => 1,
        DailyTask.gates => 8,
        DailyTask.stars => 20,
        DailyTask.streak => 9,
        DailyTask.perfects => 3,
        DailyTask.finishTrail => 0,
      }, reason: '${goal.task}');
    }
  });

  test(
    'passport stamps count campaign flights only where the doc says',
    () async {
      final repo = memoryRepo();
      await repo.saveRun(
        levelRun(
          'level',
          '1-1',
          stars: 60,
          combo: 12,
          perfects: 10,
          score: 200,
          duration: 85,
          bird: 3,
        ),
      );
      var p = await repo.load();
      expect(stamps(p), {
        SkyStamp.frequentFlyer: 1,
        SkyStamp.onTheDot: 10,
        SkyStamp.starChaser: 60,
        SkyStamp.constellation: 12,
        SkyStamp.skyCaptain: 0,
        SkyStamp.trailblazer: 0,
        SkyStamp.flockTogether: 1,
        SkyStamp.allRounder: 0,
      });

      await repo.saveRun(
        trailRun('trail', score: 55, stars: 5, combo: 4, duration: 61),
      );
      p = await repo.load();
      expect(stamps(p), {
        SkyStamp.frequentFlyer: 2,
        SkyStamp.onTheDot: 11,
        SkyStamp.starChaser: 65,
        SkyStamp.constellation: 12,
        SkyStamp.skyCaptain: 55,
        SkyStamp.trailblazer: 1,
        SkyStamp.flockTogether: 2,
        SkyStamp.allRounder: 0,
      });
      expect(SkyStamp.starChaser.goal(StampMedal.bronze), 'Collect 50 stars.');
    },
  );

  test(
    'a saved campaign session keeps its level and replays to the same result',
    () async {
      final temp = await Directory.systemTemp.createTemp('campaign-session');
      addTearDown(() => temp.delete(recursive: true));
      final (:tape, :simulation) = recordLevel(level('1-5'));
      expect(simulation.endReason, EndReason.completed);
      expect(simulation.levelStars, greaterThan(0));
      final result = RunResult(
        id: 'campaign-1-5',
        mode: PlayMode.touch,
        practice: false,
        course: FlightCourse.starTrail,
        score: simulation.score,
        gates: simulation.gates,
        stars: simulation.collectedStars,
        bestCombo: simulation.bestCombo,
        perfectPasses: simulation.perfectPasses,
        repetitions: simulation.repetitions,
        flaps: simulation.flaps,
        durationSeconds: simulation.elapsed,
        reason: simulation.endReason!,
        finishedAt: DateTime(2026, 9, 20),
        bird: 2,
        levelId: simulation.levelId,
      );
      await SessionRepository(
        temp,
      ).save(SavedSession(result: result, tape: tape, clips: []));
      final reopened = SessionRepository(temp);
      final loaded = await reopened.load(result.id);
      for (final summary in [loaded.result, (await reopened.list()).single]) {
        expect(summary.levelId, '1-5');
        expect(summary.stars, simulation.collectedStars);
      }
      expect(loaded.tape.levelId, '1-5');

      final player = ReplayPlayer(loaded.tape)..seek(loaded.tape.durationMs);
      expect(player.simulation.endReason, simulation.endReason);
      expect(player.simulation.score, simulation.score);
      expect(player.simulation.collectedStars, simulation.collectedStars);
      expect(player.simulation.levelStars, simulation.levelStars);

      // The map rates the saved flight exactly as the flight rated itself.
      final repo = memoryRepo();
      await repo.saveRun(loaded.result);
      expect(
        (await repo.load()).campaign.stars(level('1-5')),
        simulation.levelStars,
      );
    },
  );

  test('endless session summaries are saved as before', () async {
    final temp = await Directory.systemTemp.createTemp('endless-session');
    addTearDown(() => temp.delete(recursive: true));
    final result = trailRun('endless');
    await SessionRepository(temp).save(
      SavedSession(
        result: result,
        tape: ReplayTape(
          mode: PlayMode.touch,
          practice: false,
          course: FlightCourse.starTrail,
          seed: 3,
          cycleSeconds: 3,
          bird: 0,
          reducedMotion: false,
          originMs: 0,
        ),
        clips: [],
      ),
    );
    final summary =
        jsonDecode(
              await File('${temp.path}/endless/summary.json').readAsString(),
            )
            as Map<String, dynamic>;
    expect(summary.containsKey('level'), isFalse);
    expect((await SessionRepository(temp).list()).single.levelId, isNull);
  });
}
