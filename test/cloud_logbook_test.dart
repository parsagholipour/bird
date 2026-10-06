import 'dart:convert';
import 'dart:io' show gzip;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/cloud_logbook.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/campaign_progress.dart';
import 'package:push_up_bird/domain/campaign_story.dart';
import 'package:push_up_bird/domain/daily_adventure.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';

import 'built_pilot.dart';

/// A phone: its own database, as in [SqliteProgressRepository.onDevice].
SqliteProgressRepository phone([DateTime Function()? clock]) =>
    SqliteProgressRepository(
      ProgressDatabase(NativeDatabase.memory()),
      clock: clock,
    );

RunResult flight(
  String id, {
  int stars = 10,
  int score = 20,
  int bird = 2,
  PlayMode mode = PlayMode.touch,
  FlightCourse course = FlightCourse.starTrail,
  DateTime? at,
  String? level,
  EndReason reason = EndReason.collision,
  double seconds = 30,
  Set<String> feats = const {},
  bool practice = false,
  int bestCombo = 0,
  int perfects = 0,
}) => RunResult(
  id: id,
  mode: mode,
  course: course,
  practice: practice,
  score: score,
  stars: stars,
  repetitions: 0,
  flaps: 5,
  durationSeconds: seconds,
  reason: reason,
  finishedAt: at ?? DateTime(2026, 10, 6, 14),
  bird: bird,
  levelId: level,
  feats: feats,
  bestCombo: bestCombo,
  perfectPasses: perfects,
);

/// One sync of [repo] against the [cloud] string, as PlayGamesSync does it:
/// load, merge in one transaction, save back.
Future<String> sync(ProgressRepository repo, String? cloud) async {
  final (merged, _) = await repo.importLogbook(Logbook.decode(cloud));
  return merged.encode();
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  group('merge', () {
    const me = 'aaaa', other = 'bbbb';
    DeviceTotals row(int runs, int stars, {int best = 0}) => DeviceTotals(
      records: {
        'trailTouch': ModeRecord(
          runs: runs,
          stars: stars,
          best: best,
          bestCombo: best ~/ 10,
        ),
      },
      birdFlights: {2: runs},
    );

    test('without a cloud copy this phone is the logbook', () {
      final local = Logbook(devices: {me: row(1, 5)});
      expect(Logbook.merge(local, null, me: me), same(local));
    });

    test('each phone keeps its own row; copies of one row take the max', () {
      final local = Logbook(
        devices: {me: row(5, 50, best: 90), other: row(2, 10, best: 40)},
      );
      final cloud = Logbook(
        devices: {me: row(3, 30, best: 70), other: row(4, 30, best: 60)},
      );
      final merged = Logbook.merge(local, cloud, me: me);
      expect(merged.devices.keys, unorderedEquals([me, other]));
      expect(merged.devices[me]!.record('trailTouch').runs, 5);
      expect(merged.devices[me]!.record('trailTouch').best, 90);
      expect(merged.devices[other]!.record('trailTouch').runs, 4);
      expect(merged.devices[other]!.record('trailTouch').stars, 30);
      expect(merged.devices[other]!.birdFlights[2], 4);
    });

    test('a higher local epoch (reset while connected) replaces the cloud', () {
      final local = Logbook(epoch: 9, devices: {me: row(1, 2)});
      final cloud = Logbook(
        epoch: 3,
        devices: {other: row(50, 500)},
        feats: {'night'},
        upgrades: const PowerUps(shot: 4),
      );
      final merged = Logbook.merge(local, cloud, me: me);
      expect(merged.epoch, 9);
      expect(merged.devices.keys, [me]);
      expect(merged.feats, isEmpty);
      expect(merged.upgrades.shot, 0);
    });

    test('a higher cloud epoch drops the rows this phone carried', () {
      final local = Logbook(
        epoch: 3,
        devices: {me: row(7, 70), other: row(50, 500)},
        feats: {'pigeonFreed'},
      );
      final cloud = Logbook(
        epoch: 9,
        devices: {'cccc': row(1, 1)},
        feats: {'night'},
      );
      final merged = Logbook.merge(local, cloud, me: me);
      expect(merged.epoch, 9);
      expect(merged.devices.keys, unorderedEquals([me, 'cccc']));
      expect(merged.devices[me]!.record('trailTouch').runs, 7);
      // What this phone holds itself comes along.
      expect(merged.feats, {'night', 'pigeonFreed'});
    });

    test('levels keep bests, the first clear and the last flight', () {
      final local = Logbook(
        levels: {
          '1-1': LevelRecord(
            levelId: '1-1',
            bestStars: 2,
            bestCollected: 30,
            bestScore: 10,
            plays: 4,
            firstClearedAt: DateTime(2026, 9, 2),
            lastPlayedAt: DateTime(2026, 9, 5),
          ),
        },
      );
      final cloud = Logbook(
        levels: {
          '1-1': LevelRecord(
            levelId: '1-1',
            bestStars: 3,
            bestCollected: 20,
            bestScore: 40,
            plays: 2,
            firstClearedAt: DateTime(2026, 9, 1),
            lastPlayedAt: DateTime(2026, 9, 3),
            postcardSeen: true,
          ),
          '1-2': const LevelRecord(levelId: '1-2', plays: 1),
        },
      );
      final merged = Logbook.merge(local, cloud, me: me).levels;
      final l = merged['1-1']!;
      expect(
        [l.bestStars, l.bestCollected, l.bestScore, l.plays],
        [3, 30, 40, 4],
      );
      expect(l.firstClearedAt, DateTime(2026, 9, 1));
      expect(l.lastPlayedAt, DateTime(2026, 9, 5));
      expect(l.postcardSeen, isTrue);
      expect(merged['1-2']!.plays, 1);
    });

    test('purchases and sets only grow; deleted built levels stay gone', () {
      final local = Logbook(
        upgrades: const PowerUps(shot: 2, magnet: 1),
        birds: {0},
        storyWatched: {'a'},
        builtLevels: {
          'u-1': {'name': 'Mine', 'updatedAt': 2000},
          'u-2': {'name': 'Old', 'updatedAt': 1000},
        },
      );
      final cloud = Logbook(
        upgrades: const PowerUps(shot: 1, sprint: 3),
        birds: {3},
        storyWatched: {'b'},
        builtLevels: {
          'u-1': {'name': 'Older', 'updatedAt': 1000},
          'u-2': {'name': 'Edited elsewhere', 'updatedAt': 3000},
          'u-3': {'name': 'Gone', 'updatedAt': 3000},
        },
        builtDeleted: {'u-3'},
      );
      final merged = Logbook.merge(local, cloud, me: me);
      expect(merged.upgrades.toJson(), {
        'shot': 2,
        'sprint': 3,
        'shield': 0,
        'magnet': 1,
      });
      expect(merged.birds, {0, 3});
      expect(merged.storyWatched, {'a', 'b'});
      expect(merged.builtLevels.keys, unorderedEquals(['u-1', 'u-2']));
      expect(merged.builtLevels['u-1']!['name'], 'Mine');
      expect(merged.builtLevels['u-2']!['name'], 'Edited elsewhere');
    });

    test('the blob round-trips and holds status only', () {
      final book = Logbook(
        epoch: 4,
        devices: {me: row(3, 9, best: 50)},
        levels: {'2-1': const LevelRecord(levelId: '2-1', bestStars: 1)},
        upgrades: const PowerUps(shield: 2),
        birds: {0},
        storyWatched: {'s'},
        feats: {'boss:dragon', 'day:2026-10-06'},
        builtDeleted: {'u-9'},
      );
      final back = Logbook.decode(book.encode())!;
      expect(jsonEncode(back.toJson()), jsonEncode(book.toJson()));
      expect(book.toJson().keys, {
        'schema',
        'epoch',
        'devices',
        'levels',
        'upgrades',
        'unlockedBirds',
        'storyWatched',
        'feats',
        'builtLevels',
        'builtDeleted',
      });
    });

    test('an unreadable copy or a newer format is never written over', () {
      expect(Logbook.decode(null), isNull);
      expect(() => Logbook.decode('not base64 at all!'), throwsFormatException);
      final newer = base64.encode(
        gzip.encode(utf8.encode(jsonEncode({'schema': Logbook.schema + 1}))),
      );
      expect(() => Logbook.decode(newer), throwsA(isA<NewerLogbook>()));
    });
  });

  group('two phones', () {
    test('totals add up, bests stay bests, and nothing counts twice', () async {
      final a = phone(), b = phone();
      addTearDown(a.close);
      addTearDown(b.close);
      await a.saveRun(flight('a1', stars: 300, score: 80));
      await a.saveRun(flight('a2', stars: 0, score: 10, bird: 0));
      await b.saveRun(flight('b1', stars: 300, score: 120, bird: 3));

      var cloud = await sync(a, null);
      cloud = await sync(b, cloud);
      cloud = await sync(a, cloud);
      // Syncing again and again changes nothing.
      for (var i = 0; i < 3; i++) {
        cloud = await sync(b, cloud);
        cloud = await sync(a, cloud);
      }
      for (final repo in [a, b]) {
        final p = await repo.load();
        expect(p.trailTouch.runs, 3);
        expect(p.starsEarned, 600);
        expect(p.trailTouch.best, 120);
        expect(p.birdFlights, {2: 1, 0: 1, 3: 1});
        expect(p.birdsFlown, {0, 2, 3});
        expect(p.flightsFlown, 3);
      }
      // Each phone's own flights stay its own history.
      expect((await a.load()).recent, hasLength(2));
      expect((await b.load()).recent, hasLength(1));
    });

    test(
      'a new phone restores everything, and its row joins the old',
      () async {
        final a = phone(), b = phone();
        addTearDown(a.close);
        addTearDown(b.close);
        await a.saveRun(flight('a1', stars: 700));
        await a.saveRun(
          flight(
            'a2',
            stars: 40,
            level: '1-1',
            reason: EndReason.completed,
            feats: {'pigeonFreed'},
          ),
        );
        await a.buyUpgrade(PowerUp.shot);
        await a.unlockBird(0);
        await a.markStoryWatched(CampaignStory.prologue);
        await a.saveCoop(CoopMode.roped, flight('c1', score: 33));
        final cloud = await sync(a, null);

        final (_, changed) = await b.importLogbook(Logbook.decode(cloud));
        expect(changed, isTrue);
        final p = await b.load();
        expect(p.starsEarned, 740);
        expect(p.campaign.cleared(Campaign.level('1-1')!), isTrue);
        expect(p.upgrades.shot, 1);
        expect(p.unlockedBirds, contains(0));
        expect(p.starsSpent, PowerUp.costs.first + birdPrices[0]);
        expect(p.starWallet, 740 - PowerUp.costs.first - birdPrices[0]);
        expect(p.campaign.storyWatched, {CampaignStory.prologue.id});
        expect(p.feats, contains('pigeonFreed'));
        expect(p.coop.record(CoopMode.roped).flights, 1);
        expect(p.coop.record(CoopMode.roped).best, 33);
        // The restored stars pay for the next purchase here too.
        await b.buyUpgrade(PowerUp.magnet);
        expect((await b.load()).upgrades.magnet, 1);
      },
    );

    test('the same upgrade bought on both phones is paid once', () async {
      final a = phone(), b = phone();
      addTearDown(a.close);
      addTearDown(b.close);
      await a.saveRun(flight('a1', stars: 60));
      await b.saveRun(flight('b1', stars: 60));
      await a.buyUpgrade(PowerUp.shot);
      await b.buyUpgrade(PowerUp.shot);
      var cloud = await sync(a, null);
      cloud = await sync(b, cloud);
      await sync(a, cloud);
      for (final repo in [a, b]) {
        final p = await repo.load();
        expect(p.upgrades.shot, 1);
        expect(p.starWallet, 120 - PowerUp.costs.first);
      }
    });

    test(
      'different upgrades with the same stars floor the wallet at 0',
      () async {
        final a = phone(), b = phone();
        addTearDown(a.close);
        addTearDown(b.close);
        // A phone that collected 50 stars, restored on a second phone, where
        // both spend the same 50 stars on different upgrades.
        await a.saveRun(flight('a1', stars: 50));
        await sync(b, await sync(a, null));
        await a.buyUpgrade(PowerUp.shot);
        await b.buyUpgrade(PowerUp.magnet);
        var cloud = await sync(a, null);
        cloud = await sync(b, cloud);
        await sync(a, cloud);
        for (final repo in [a, b]) {
          final p = await repo.load();
          expect(p.upgrades.shot, 1);
          expect(p.upgrades.magnet, 1);
          expect(p.starsSpent, 2 * PowerUp.costs.first);
          expect(p.starWallet, 0);
        }
      },
    );

    test('a reset while connected clears the cloud and every phone that '
        'synced', () async {
      var now = DateTime(2026, 10, 6, 12);
      final a = phone(() => now), b = phone(() => now);
      addTearDown(a.close);
      addTearDown(b.close);
      await a.saveRun(flight('a1', stars: 100));
      await b.saveRun(flight('b1', stars: 30));
      var cloud = await sync(a, null);
      cloud = await sync(b, cloud);
      cloud = await sync(a, cloud);
      expect((await a.load()).starsEarned, 130);

      now = now.add(const Duration(minutes: 5));
      await a.reset(cloud: true);
      cloud = await sync(a, cloud);
      final fresh = Logbook.decode(cloud)!;
      expect(fresh.epoch, greaterThan(0));
      expect(
        fresh.devices.values.single.records.values.every((r) => r.runs == 0),
        isTrue,
      );
      // Merging the old cloud back does not undo the reset.
      expect((await a.load()).starsEarned, 0);

      // Phone B synced before, so it starts afresh too.
      cloud = await sync(b, cloud);
      expect((await b.load()).starsEarned, 0);
      await sync(a, cloud);
      expect((await a.load()).starsEarned, 0);
    });

    test(
      'a reset that leaves the cloud alone restores on connecting',
      () async {
        final a = phone(), b = phone();
        addTearDown(a.close);
        addTearDown(b.close);
        await a.saveRun(flight('a1', stars: 100));
        final cloud = await sync(a, null);
        await b.saveRun(flight('b1', stars: 5));
        await b.reset();
        await sync(b, cloud);
        expect((await b.load()).starsEarned, 100);
      },
    );

    test('built levels travel, edits win by time, deletions stick', () async {
      var now = DateTime(2026, 10, 6, 12);
      final a = phone(() => now), b = phone(() => now);
      addTearDown(a.close);
      addTearDown(b.close);
      final plan = sampleLevel(
        PlayMode.touch,
        id: 'u-loop000001',
      ).copyWith(name: 'Loop');
      await a.builtLevels.create(plan);
      await a.builtLevels.markCleared('u-loop000001', 1);
      var cloud = await sync(a, null);
      await sync(b, cloud);
      final restored = await b.builtLevels.level('u-loop000001');
      expect(restored?.plan.name, 'Loop');
      expect(restored?.clearedRevision, 1);
      expect((await b.load()).builtCleared, isTrue);

      now = now.add(const Duration(minutes: 1));
      await b.builtLevels.save(plan.copyWith(name: 'Loop the loop'));
      cloud = await sync(b, cloud);
      await sync(a, cloud);
      expect(
        (await a.builtLevels.level('u-loop000001'))?.plan.name,
        'Loop the loop',
      );

      await a.builtLevels.delete('u-loop000001');
      cloud = await sync(a, cloud);
      await sync(b, cloud);
      expect(await b.builtLevels.level('u-loop000001'), isNull);
      // B's next sync must not bring it back to A either.
      await sync(a, await sync(b, cloud));
      expect(await a.builtLevels.level('u-loop000001'), isNull);
    });

    test('sessions and runs never go to the cloud', () async {
      final a = phone();
      addTearDown(a.close);
      await a.saveRun(flight('a1', stars: 3));
      // Every key and string in the logbook, whole: the random device id
      // may hold "a1" by chance, but never as the run's id.
      final strings = <String>{};
      void collect(Object? json) => switch (json) {
        Map() => json.forEach((key, value) {
          strings.add('$key');
          collect(value);
        }),
        List() => json.forEach(collect),
        String() => strings.add(json),
        _ => null,
      };
      collect(jsonDecode(jsonEncode((await a.exportLogbook()).toJson())));
      expect(strings, isNot(contains('a1')));
      expect(strings.where((s) => s.contains('finishedAt')), isEmpty);
      expect(strings.where((s) => s.contains('session')), isEmpty);
    });
  });

  group('feats', () {
    test(
      'a saved flight notes its feats, the hour and a stamped day',
      () async {
        final repo = phone();
        addTearDown(repo.close);
        await repo.saveRun(
          flight(
            'n1',
            at: DateTime(2026, 10, 6, 2, 30),
            feats: {'boss:dragon'},
            stars: 1,
          ),
        );
        var p = await repo.load();
        expect(p.feats, {'boss:dragon', 'night'});
        // Practice flights note nothing.
        await repo.saveRun(
          flight('p1', practice: true, feats: {'pigeonFreed'}),
        );
        expect((await repo.load()).feats, {'boss:dragon', 'night'});
        // Enough flying to finish the day's three tasks, whichever they are.
        RunResult busy(int i) => flight(
          'd$i',
          at: DateTime(2026, 10, 6, 15, i),
          stars: 20,
          score: 30,
          seconds: 70,
          bestCombo: 12,
          perfects: 2,
        );
        final day = DailyAdventure.forDate(DateTime(2026, 10, 6), [
          for (var i = 0; i < 3; i++) busy(i),
        ]);
        expect(day.complete, isTrue);
        await repo.saveRun(busy(0));
        expect((await repo.load()).feats, isNot(contains('day:2026-10-06')));
        for (var i = 1; i < 3; i++) {
          await repo.saveRun(busy(i));
        }
        expect((await repo.load()).feats, contains('day:2026-10-06'));
      },
    );
  });
}
