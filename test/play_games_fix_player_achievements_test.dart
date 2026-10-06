import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/play_games.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';

import 'play_games_sync_test.dart' show FakePlayGames, Phone;

// What the achievements sync remembers sending is one Play player's: after
// an account switch, the next player gets every earned achievement too, one
// pop-up per calm moment as usual, and the first player is not sent them
// again.

/// Signs [play] in as [player]: Play holds that player's own achievements.
void _switch(
  FakePlayGames play,
  Map<String, Map<String, PlayAchievementState>> held,
  String player,
) {
  held[play.player!] = {...play.held};
  play
    ..held.clear()
    ..held.addAll(held[player] ?? const {})
    ..unlocks.clear()
    ..player = player;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Phone p;
  tearDown(() => p.dispose());

  test('a switched account gets the achievements the first one got', () async {
    final play = FakePlayGames()..player = 'X';
    p = Phone(play);
    await p.container.read(progressProvider.future);
    await p.sync.start();
    // Three completions due: Star Chaser, Constellation, Sky Captain.
    await p.progress.save(
      RunResult(
        id: 'big',
        mode: PlayMode.touch,
        course: FlightCourse.starTrail,
        practice: false,
        score: 120,
        stars: 60,
        bestCombo: 20,
        repetitions: 0,
        flaps: 3,
        durationSeconds: 70,
        reason: EndReason.collision,
        finishedAt: p.now,
        bird: 2,
      ),
    );
    for (var i = 0; i < 4; i++) {
      await p.sync.calmMoment();
    }
    final sent = [...play.unlocks];
    expect(sent, hasLength(3));

    // Y: Play holds nothing yet. One pop-up a calm moment, all of them.
    final held = <String, Map<String, PlayAchievementState>>{};
    _switch(play, held, 'Y');
    await p.sync.calmMoment();
    expect(play.unlocks, [sent.first]);
    expect(play.calls, contains('steps id.frequentFlyerBronze 1'));
    for (var i = 0; i < 3; i++) {
      await p.sync.calmMoment();
    }
    expect(play.unlocks, sent);

    // Back to X, which holds them: nothing is sent again.
    _switch(play, held, 'X');
    play.calls.clear();
    for (var i = 0; i < 3; i++) {
      await p.sync.calmMoment();
    }
    expect(play.unlocks, isEmpty);
    expect(
      play.calls.where((c) => c.startsWith('steps') || c.startsWith('unlock')),
      isEmpty,
    );
  });

  test('without a player id, nothing is reported', () async {
    final play = FakePlayGames()..player = null;
    p = Phone(play);
    await p.container.read(progressProvider.future);
    await p.sync.start();
    await p.fly(stars: 60);
    await p.sync.calmMoment();
    expect(play.unlocks, isEmpty);
    expect(play.calls.where((c) => c.startsWith('steps')), isEmpty);

    // Play says who again: the report goes out.
    play.player = 'X';
    await p.sync.calmMoment();
    expect(play.unlocks, isNotEmpty);
  });
}
