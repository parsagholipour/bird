import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/session_repository.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/campaign_progress.dart';
import 'package:push_up_bird/domain/campaign_story.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/ui/campaign_screen.dart'
    show campaignStarsInBuild, campaignStops;

/// Egypt's guardian took level 2-6 (rules version 50) and Ancient Arabia
/// moved up by one: 2-6..2-8 became 2-7..2-9. A save made before is renamed
/// once, as the database is first opened at schema 6
/// (`ProgressDatabase.renumberLevels`, `CampaignIds`), and a level once
/// finished stays open (`CampaignProgress.unlocked`), so a returning player
/// keeps Arabia and New York and finds the new 2-6 waiting as the current
/// level. See egypt-int/MASTER-PLAN.md §1.

CampaignLevel level(String id) => Campaign.level(id)!;

/// Every level of chapters 1 and 2 as the old scheme numbered them, and New
/// York's four.
const _oldIds = [
  '1-1', '1-2', '1-3', '1-4', '1-5', '1-6', '1-7', '1-8', //
  '2-1', '2-2', '2-3', '2-4', '2-5', '2-6', '2-7', '2-8', //
  '3-1', '3-2', '3-3', '3-4',
];

final _played = DateTime(2026, 9, 30, 18);

/// A schema-5 save (the old ids) written to [file]: every level in
/// [cleared] finished with [stars] stars, a flight of each Arabian level,
/// the watched scenes and the flight voices' memory.
Future<void> _oldSave(
  File file, {
  Iterable<String> cleared = _oldIds,
  Map<String, int> stars = const {'2-6': 2, '2-7': 1, '2-8': 3},
  String watched = 'before-1-1,before-2-1,before-2-4,before-2-6,before-2-8,'
      'after-2,before-3-1',
}) async {
  final db = ProgressDatabase(NativeDatabase(file));
  for (final id in cleared) {
    await db
        .into(db.levelProgress)
        .insert(
          LevelProgressCompanion.insert(
            level: id,
            bestStars: Value(stars[id] ?? 3),
            bestCollected: const Value(30),
            bestScore: Value(100 + int.parse(id.replaceAll('-', ''))),
            plays: const Value(2),
            firstClearedAt: Value(_played),
            lastPlayedAt: Value(_played),
            postcardSeen: Value(id == '2-8' || id == '1-8'),
          ),
        );
  }
  for (final id in ['2-6', '2-7', '2-8', '2-8']) {
    await db
        .into(db.runs)
        .insert(
          RunsCompanion.insert(
            id: 'run-$id-${await _count(db)}',
            mode: PlayMode.touch.index,
            course: Value(FlightCourse.starTrail.name),
            practice: false,
            score: 10,
            repetitions: 0,
            flaps: 30,
            duration: 60,
            reason: EndReason.completed.name,
            finishedAt: _played,
            level: Value(id),
          ),
        );
  }
  Future<void> put(String key, String value) => db
      .into(db.preferences)
      .insert(PreferencesCompanion.insert(key: key, value: value));
  await put('storyWatched', watched);
  await put(
    'flightVoices',
    jsonEncode({
      'said': 9,
      'flights': 3,
      'last': {
        'pip-cargo-2-6-01': 3,
        'minty-cargo-2-8-01': 7,
        'pip-hit-01': 9,
        'thanks-2-6': 1,
      },
      'lastFlight': {'pip-cargo-2-6-01': 1, 'minty-cargo-2-8-01': 2},
      'met': ['rush-wildfire'],
    }),
  );
  await put('music', 'false');
  await db.customStatement('PRAGMA user_version = 5');
  await db.close();
}

Future<int> _count(ProgressDatabase db) async =>
    (await db.select(db.runs).get()).length;

Future<int> _userVersion(ProgressDatabase db) async =>
    (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
      'user_version',
    );

Future<Map<String, String>> _prefs(ProgressDatabase db) async => {
  for (final row in await db.select(db.preferences).get()) row.key: row.value,
};

Future<List<String?>> _runLevels(ProgressDatabase db) async => [
  for (final row
      in await (db.select(db.runs)..orderBy([(r) => OrderingTerm.asc(r.id)]))
          .get())
    row.level,
];

void main() {
  late Directory temp;
  late File file;
  setUp(() {
    temp = Directory.systemTemp.createTempSync('egypt-migration');
    file = File(p.join(temp.path, 'sky_club.sqlite'));
  });
  tearDown(() => temp.deleteSync(recursive: true));

  group('the id maps', () {
    test('Arabia moves up by one, highest first; nothing else moves', () {
      expect(CampaignIds.renumbered.entries.map((e) => (e.key, e.value)), [
        ('2-8', '2-9'),
        ('2-7', '2-8'),
        ('2-6', '2-7'),
      ]);
      for (final id in ['1-1', '2-5', '2-9', '3-1', '5-8']) {
        expect(CampaignIds.level(id), id);
      }
      // Each moved level is the same level: name, seed, everything but id.
      expect(level('2-7').name, 'Lantern Bazaar');
      expect(level('2-8').name, 'The Long Caravan');
      expect(level('2-9').name, 'Spitter King');
      expect(level('2-9').isChapterBoss, isTrue);
      expect([for (final id in ['2-7', '2-8', '2-9']) level(id).plan.seed], [
        2106,
        2107,
        2108,
      ]);
      expect(level('2-6').name, 'Return to Sender');
      expect(level('2-6').boss, BossKind.neferhoo);
      expect(level('2-6').isGuardian, isTrue);
    });

    test('scenes and clips named by a moved level move with it', () {
      expect(CampaignIds.scene('before-2-6'), 'before-2-7');
      expect(CampaignIds.scene('before-2-8'), 'before-2-9');
      expect(CampaignIds.scene('after-2'), 'after-2');
      expect(CampaignIds.scene('before-2-4'), 'before-2-4');
      expect(CampaignIds.clip('pip-cargo-2-6-01'), 'pip-cargo-2-7-01');
      expect(CampaignIds.clip('orbit-cargo-2-8-01'), 'orbit-cargo-2-9-01');
      expect(CampaignIds.clip('before-2-8-3-pip'), 'before-2-9-3-pip');
      expect(CampaignIds.clip('before-2-6-0'), 'before-2-7-0');
      expect(CampaignIds.clip('thanks-2-7'), 'thanks-2-8');
      // Lines 6 and 7 of scene after-2 are not named by a level.
      expect(CampaignIds.clip('after-2-6'), 'after-2-6');
      expect(CampaignIds.clip('pip-cargo-2-5-01'), 'pip-cargo-2-5-01');
      expect(CampaignIds.clip('pip-hit-01'), 'pip-hit-01');
      // The scenes exist under their new ids, and the new 2-6 is
      // Neferhoo's.
      expect(CampaignStory.before(level('2-7'))!.id, 'before-2-7');
      expect(CampaignStory.before(level('2-9'))!.id, 'before-2-9');
      expect(CampaignStory.before(level('2-6'))!.boss, BossKind.neferhoo);
      expect(CampaignStory.lastWord(level('2-6'))!.id, 'last-2-6');
      expect(CampaignStory.before(level('2-8')), isNull);
    });
  });

  group('a schema-5 save opened at schema 6', () {
    test('renames records, flights, watched scenes and the voices\' memory', () async {
      await _oldSave(file);
      final db = ProgressDatabase(NativeDatabase(file));
      final repo = SqliteProgressRepository(db);
      addTearDown(repo.close);
      final p = await repo.load();
      expect(await _userVersion(db), 6);
      final c = p.campaign;
      // The Lantern Bazaar's two stars, the Caravan's one and the Spitter
      // King's three (with its postcard seen) moved with their levels.
      expect(c.stars(level('2-7')), 2);
      expect(c.stars(level('2-8')), 1);
      expect(c.stars(level('2-9')), 3);
      expect(c.record(level('2-9')).postcardSeen, isTrue);
      expect(c.record(level('2-9')).bestScore, 128);
      expect(c.record(level('2-7')).bestScore, 126);
      // Nobody has flown the new 2-6.
      expect(c.records.containsKey('2-6'), isFalse);
      expect(c.cleared(level('2-6')), isFalse);
      expect(c.records.keys.toSet(), {
        for (final id in _oldIds) CampaignIds.level(id),
      });
      expect(await _runLevels(db), ['2-7', '2-8', '2-9', '2-9']);
      final prefs = await _prefs(db);
      expect(prefs['levelIds'], '2');
      expect(prefs['music'], 'false');
      expect(
        prefs['storyWatched']!.split(','),
        [
          'before-1-1',
          'before-2-1',
          'before-2-4',
          'before-2-7',
          'before-2-9',
          'after-2',
          'before-3-1',
        ],
      );
      final voices = jsonDecode(prefs['flightVoices']!) as Map;
      expect(voices['last'], {
        'pip-cargo-2-7-01': 3,
        'minty-cargo-2-9-01': 7,
        'pip-hit-01': 9,
        'thanks-2-7': 1,
      });
      expect(voices['lastFlight'], {
        'pip-cargo-2-7-01': 1,
        'minty-cargo-2-9-01': 2,
      });
      expect(voices['said'], 9);
      expect(voices['met'], ['rush-wildfire']);
    });

    test('a returning player keeps Arabia and New York, and the new 2-6 is '
        'open and current', () async {
      await _oldSave(file);
      final repo = SqliteProgressRepository(ProgressDatabase(NativeDatabase(file)));
      addTearDown(repo.close);
      final c = (await repo.load()).campaign;
      for (final id in [
        '2-5', '2-6', '2-7', '2-8', '2-9', '3-1', '3-2', '3-3', '3-4',
      ]) {
        expect(c.unlocked(level(id)), isTrue, reason: id);
      }
      expect(c.unlocked(level('3-5')), isFalse, reason: 'Paris: coming soon');
      expect(c.current.id, '2-6');
      expect(c.chapterComplete(Campaign.chapters[1]), isTrue);
      expect(c.postcardDue(Campaign.chapters[1]), isFalse);
      // Neferhoo's lair scene plays before his card; Arabia's do not again.
      expect(c.sceneBefore(level('2-6'))!.id, 'before-2-6');
      expect(c.sceneBefore(level('2-7')), isNull);
      expect(c.sceneBefore(level('2-9')), isNull);
      expect(c.sceneLast(level('2-6')), isNull, reason: 'not beaten yet');
      // 17 levels of three stars and the moved ones' 2 + 1 + 3.
      expect(c.totalStars, 17 * 3 + 2 + 1 + 3);
    });

    test('a player who stopped before Arabia now meets Neferhoo next, and '
        'Arabia waits behind him', () async {
      await _oldSave(
        file,
        cleared: _oldIds.where((id) => id.compareTo('2-6') < 0),
        watched: 'before-1-1,before-2-1,before-2-4',
      );
      final repo = SqliteProgressRepository(ProgressDatabase(NativeDatabase(file)));
      addTearDown(repo.close);
      final c = (await repo.load()).campaign;
      expect(c.current.id, '2-6');
      expect(c.unlocked(level('2-6')), isTrue);
      expect(c.unlocked(level('2-7')), isFalse);
      expect(c.unlocked(level('3-1')), isFalse);
    });

    test('runs once: a second rename changes nothing', () async {
      await _oldSave(file);
      final db = ProgressDatabase(NativeDatabase(file));
      addTearDown(db.close);
      await db.select(db.preferences).get(); // opens and migrates
      final before = (
        await _prefs(db),
        await _runLevels(db),
        [for (final r in await db.select(db.levelProgress).get()) r.level],
      );
      await db.renumberLevels();
      await db.renumberLevels();
      expect(await _prefs(db), before.$1);
      expect(await _runLevels(db), before.$2);
      expect([
        for (final r in await db.select(db.levelProgress).get()) r.level,
      ], before.$3);
    });

    test('a save already at schema 6 is never renamed again', () async {
      await _oldSave(file);
      var db = ProgressDatabase(NativeDatabase(file));
      await db.select(db.preferences).get();
      await db.close();
      db = ProgressDatabase(NativeDatabase(file));
      addTearDown(db.close);
      expect(await _runLevels(db), ['2-7', '2-8', '2-9', '2-9']);
      expect(await _userVersion(db), 6);
    });

    test('a new save never meets the rename: 2-6 is Neferhoo\'s', () async {
      final repo = SqliteProgressRepository(ProgressDatabase(NativeDatabase(file)));
      await repo.saveRun(_levelRun('fresh', '2-6'));
      await repo.close();
      final reopened = SqliteProgressRepository(
        ProgressDatabase(NativeDatabase(file)),
      );
      addTearDown(reopened.close);
      final c = (await reopened.load()).campaign;
      expect(c.records.keys, ['2-6']);
      expect(c.record(level('2-6')).plays, 1);
    });
  });

  group('the unlock rule: a finished level stays open', () {
    LevelRecord done(String id) => LevelRecord(levelId: id, bestStars: 1);
    test('even when a level before it is new and unfinished', () {
      final c = CampaignProgress([
        for (final l in Campaign.levels.take(5 + 8)) done(l.id), // to 2-5
        done('2-7'),
      ]);
      expect(c.unlocked(level('2-6')), isTrue);
      expect(c.unlocked(level('2-7')), isTrue, reason: 'finished');
      expect(c.unlocked(level('2-8')), isTrue, reason: 'after a finished one');
      expect(c.unlocked(level('2-9')), isFalse);
      expect(c.current.id, '2-6');
    });

    test('a level never finished still waits for the one before', () {
      final c = CampaignProgress([done('1-1')]);
      expect(c.unlocked(level('1-2')), isTrue);
      expect(c.unlocked(level('1-3')), isFalse);
      expect(c.current.id, '1-2');
    });

    test('a level the build does not open stays locked, finished or not', () {
      Campaign.closedForTest = true;
      addTearDown(() => Campaign.closedForTest = false);
      final c = CampaignProgress([
        for (final l in Campaign.levels.take(21)) done(l.id),
      ]);
      expect(c.unlocked(level('3-1')), isFalse);
      expect(c.unlocked(level('2-9')), isTrue);
    });
  });

  group('the map and the totals', () {
    test('Egypt shows three stops, the last Neferhoo\'s guardian shield', () {
      final stops = campaignStops(CampaignProgress(const []));
      final egypt = stops.singleWhere((s) => s.region == WorldRegion.egypt);
      expect(egypt.nodes.map((n) => n.id), ['2-4', '2-5', '2-6']);
      expect(egypt.nodes.last.isGuardian, isTrue);
      expect(egypt.nodes.last.boss, BossKind.neferhoo);
      expect(egypt.nodes.last.name, 'Return to Sender');
      final arabia = stops.singleWhere((s) => s.region == WorldRegion.arabia);
      expect(arabia.nodes.map((n) => n.id), ['2-7', '2-8', '2-9']);
      expect(arabia.nodes.last.isBoss, isTrue);
      expect(arabia.nodes.first.lockNote, 'Beat Neferhoo to unlock');
    });

    test('chapter 2 has nine levels; the build counts 63 stars', () {
      expect(Campaign.chapters[1].levels, hasLength(9));
      expect(Campaign.chapters[1].bossLevel.id, '2-9');
      expect(Campaign.playableLevels, hasLength(21));
      expect(campaignStarsInBuild, 63);
      Campaign.closedForTest = true;
      addTearDown(() => Campaign.closedForTest = false);
      expect(campaignStarsInBuild, 51);
    });
  });

  group('the replay library', () {
    test('a session saved before the move is titled by the level it flew', () async {
      final sessions = SessionRepository(Directory(p.join(temp.path, 's')));
      final tape = ReplayTape(
        mode: PlayMode.touch,
        practice: false,
        seed: 1,
        cycleSeconds: 3,
        bird: 0,
        reducedMotion: false,
        originMs: 0,
        course: FlightCourse.starTrail,
      );
      await sessions.save(
        SavedSession(result: _levelRun('old', '2-8'), tape: tape, clips: const []),
      );
      await sessions.save(
        SavedSession(result: _levelRun('new', '2-8'), tape: tape, clips: const []),
      );
      // The old build wrote no `ids`: rewrite "old" as it would have.
      for (final name in ['summary.json', 'session.json']) {
        final f = File(p.join(temp.path, 's', 'old', name));
        final json = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
        final result = name == 'summary.json'
            ? json
            : json['result'] as Map<String, dynamic>;
        expect(result['ids'], CampaignIds.scheme);
        result.remove('ids');
        f.writeAsStringSync(jsonEncode(json));
      }
      final reopened = SessionRepository(Directory(p.join(temp.path, 's')));
      final listed = {for (final r in await reopened.list()) r.id: r.levelId};
      expect(listed, {'old': '2-9', 'new': '2-8'});
      expect((await reopened.load('old')).result.levelId, '2-9');
      expect((await reopened.load('new')).result.levelId, '2-8');
    });
  });
}

RunResult _levelRun(String id, String levelId) => RunResult(
  id: id,
  mode: PlayMode.touch,
  practice: false,
  course: FlightCourse.starTrail,
  score: 100,
  gates: 8,
  stars: 30,
  bestCombo: 5,
  perfectPasses: 1,
  repetitions: 0,
  flaps: 40,
  durationSeconds: 80,
  reason: EndReason.completed,
  finishedAt: DateTime(2026, 10, 3, 12),
  levelId: levelId,
);
