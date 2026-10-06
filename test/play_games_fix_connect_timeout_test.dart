import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/play_games.dart';

/// Play Games whose sign-in sheet answers only when [answer] does, or
/// never: games_services 5.3.0 drops a null sign-in result without
/// answering. Every other call is logged.
class _SilentSheet implements PlayGamesService {
  final answer = Completer<bool>();
  final calls = <String>[];

  @override
  Future<bool> available() async => true;
  @override
  Future<bool> signedIn() async {
    calls.add('signedIn');
    return false;
  }

  @override
  Future<bool> signIn() {
    calls.add('signIn');
    return answer.future;
  }

  @override
  Future<String?> playerId() async {
    calls.add('player');
    return 'player-1';
  }

  @override
  Future<void> showAchievements() async => calls.add('show');
  @override
  Future<Map<String, PlayAchievementState>> achievements() async {
    calls.add('achievements');
    return {};
  }

  @override
  Future<void> unlock(String id) async => calls.add('unlock $id');
  @override
  Future<void> setSteps(String id, int steps) async => calls.add('steps $id');
  @override
  Future<String?> loadLogbook() async {
    calls.add('load');
    return null;
  }

  @override
  Future<void> saveLogbook(String data, String description) async =>
      calls.add('save');
}

/// The sync after a launch that found Play Games but no automatic sign-in,
/// so the strip offers Connect.
class _NotConnected extends PlayGamesSync {
  @override
  PlayGamesStatus build() => const PlayGamesStatus(available: true);
}

void main() {
  testWidgets('a sign-in sheet that never answers gives up, and nothing '
      'waits behind it', (tester) async {
    final play = _SilentSheet();
    final container = ProviderContainer(
      overrides: [
        playGamesServiceProvider.overrideWithValue(play),
        playGamesProvider.overrideWith(_NotConnected.new),
      ],
    );
    addTearDown(container.dispose);
    final sync = container.read(playGamesProvider.notifier);

    bool? connected;
    final done = <String>[];
    unawaited(sync.connect().then((ok) => connected = ok));
    unawaited(sync.paused().then((_) => done.add('paused')));
    unawaited(sync.calmMoment().then((_) => done.add('calm')));
    unawaited(sync.afterReset().then((_) => done.add('reset')));

    // A real person gets two whole minutes in Google's sheet.
    await tester.pump(const Duration(minutes: 2));
    expect(connected, isNull);
    expect(done, isEmpty);

    // Then Connect gives up (the strip shows "Couldn't connect") and the
    // queued jobs run.
    await tester.pump(const Duration(minutes: 1));
    expect(connected, isFalse);
    expect(done, ['paused', 'calm', 'reset']);
    expect(container.read(playGamesProvider).connected, isFalse);

    // A late yes from the plugin starts no catch-up behind the strip.
    play.answer.complete(true);
    await tester.pump();
    expect(container.read(playGamesProvider).connected, isFalse);
    expect(play.calls, ['signIn']);

    // Later jobs still run straight away.
    var calm = false;
    unawaited(sync.calmMoment().then((_) => calm = true));
    await tester.pump();
    expect(calm, isTrue);
    expect(play.calls, ['signIn']);
  });
}
