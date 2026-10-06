import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/cloud_logbook.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';

import 'play_games_sync_test.dart' show FakePlayGames, Phone;

/// A built level from a newer build: a mode this build does not know, so
/// it cannot become a `built_levels` row here.
const _future = <String, Object?>{
  'name': 'Moon Hop',
  'mode': 99,
  'json': '{}',
  'fingerprint': 'f',
  'revision': 1,
  'origin': 'created',
  'createdAt': 1000,
  'updatedAt': 2000,
};

/// A logbook from a future build.
class _Newer extends Logbook {
  const _Newer();
  @override
  Map<String, Object?> toJson() => {...super.toJson(), 'schema': 99};
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late List<Phone> phones;
  Future<Phone> phone(FakePlayGames play) async {
    final p = Phone(play);
    phones.add(p);
    await p.container.read(progressProvider.future);
    await p.sync.start();
    return p;
  }

  setUp(() => phones = []);
  tearDown(() async {
    for (final p in phones) {
      await p.dispose();
    }
  });

  test('what this build cannot import is no change here', () async {
    final repo = SqliteProgressRepository(
      ProgressDatabase(NativeDatabase.memory()),
    );
    addTearDown(repo.close);
    final (merged, changed) = await repo.importLogbook(
      const Logbook(builtLevels: {'u-future': _future}),
    );
    expect(changed, isFalse);
    // The cloud copy keeps it for the phones that can play it.
    expect(merged.builtLevels, contains('u-future'));
    final (_, again) = await repo.importLogbook(merged);
    expect(again, isFalse);
  });

  test('an unimportable built level never loops the sync', () async {
    final play = FakePlayGames()
      ..cloud = const Logbook(builtLevels: {'u-future': _future}).encode();
    final p = await phone(play);
    expect(p.status.restored, isFalse);
    final loads = play.loads;
    for (var i = 0; i < 3; i++) {
      p.wait(const Duration(minutes: 2));
      await p.sync.calmMoment();
    }
    expect(play.loads, loads, reason: 'nothing changed here');
    expect(p.status.restored, isFalse);

    // Real progress still goes up, and the newer level rides along.
    await p.fly();
    p.wait(const Duration(minutes: 2));
    await p.sync.calmMoment();
    expect(play.loads, loads + 1);
    expect(p.status.restored, isFalse);
    final cloud = Logbook.decode(play.cloud)!;
    expect(cloud.builtLevels, contains('u-future'));
    expect(cloud.devices.values.single.record('trailTouch').runs, 1);
  });

  test('a real restore beside it settles instead of looping', () async {
    final play = FakePlayGames()
      ..cloud = const Logbook(
        builtLevels: {'u-future': _future},
        feats: {'pigeonFreed'},
      ).encode();
    final p = await phone(play);
    expect(p.status.restored, isTrue);
    expect(
      (await p.container.read(progressProvider.future)).feats,
      contains('pigeonFreed'),
    );
    p.wait(const Duration(minutes: 2));
    await p.sync.calmMoment();
    final loads = play.loads;
    for (var i = 0; i < 3; i++) {
      p.wait(const Duration(minutes: 2));
      await p.sync.calmMoment();
    }
    expect(play.loads, loads);
    expect(p.status.restored, isFalse);
    expect(Logbook.decode(play.cloud)!.builtLevels, contains('u-future'));
  });

  test('an older build never saves over a newer logbook', () async {
    final play = FakePlayGames()..cloud = const _Newer().encode();
    final newer = play.cloud;
    final p = await phone(play);
    await p.fly(stars: 30);
    p.wait(const Duration(minutes: 2));
    await p.sync.calmMoment();
    await p.sync.paused();
    expect(play.saves, 0);
    expect(play.cloud, newer);
    // It still plays here.
    expect((await p.container.read(progressProvider.future)).starsEarned, 30);
  });
}
