import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:games_services/games_services.dart' as gs;

import '../l10n/l10n.dart';
import 'builder_providers.dart';
import 'cloud_logbook.dart';
import 'passport_progress.dart';
import 'play_achievements.dart';
import 'play_games_ids.dart';
import 'progress_repository.dart';
import 'providers.dart';

/// What Play Games holds for one achievement.
typedef PlayAchievementState = ({int steps, bool unlocked});

/// Google Play Games as the sync uses it. [GooglePlayGames] is the real one;
/// tests use a fake.
abstract interface class PlayGamesService {
  /// Whether Play Games can work here at all: an Android build with a
  /// project id ([playGamesAppId]) on a phone with Play services. Nothing
  /// else is called while it is false.
  Future<bool> available();

  /// The automatic sign-in's result, read without prompting anyone.
  Future<bool> signedIn();

  /// Google's sign-in sheet, for the Connect key only.
  Future<bool> signIn();

  /// The signed-in player's id, or null when Play does not say (not signed
  /// in, hidden, an error or no answer). The cloud save is that player's.
  Future<String?> playerId();

  /// Google's own achievements screen.
  Future<void> showAchievements();

  /// What Play already holds, by achievement id.
  Future<Map<String, PlayAchievementState>> achievements();
  Future<void> unlock(String id);

  /// Raises an incremental achievement to at least [steps]; reaching its
  /// total unlocks it.
  Future<void> setSteps(String id, int steps);

  /// The saved logbook, or null when there is none yet. Throws when the
  /// cloud cannot be reached.
  Future<String?> loadLogbook();
  Future<void> saveLogbook(String data, String description);
}

/// [PlayGamesService] over the games_services plugin.
class GooglePlayGames implements PlayGamesService {
  /// Answers whether MainActivity started the Play Games SDK
  /// (PlayGamesGate.kt).
  static const _gate = MethodChannel('push_up_bird/play_games');
  static const _snapshot = 'logbook';
  static const _wait = Duration(seconds: 20);

  @override
  Future<bool> available() async {
    if (playGamesAppId.isEmpty || kIsWeb || !Platform.isAndroid) return false;
    try {
      return await _gate.invokeMethod<bool>('ready') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<bool> signedIn() async {
    try {
      return await gs.GameAuth.isSignedIn.timeout(_wait);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> signIn() async {
    try {
      await gs.GameAuth.signIn();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> playerId() async {
    try {
      final id = await gs.Player.getPlayerID().timeout(_wait);
      return id == null || id.isEmpty ? null : id;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> showAchievements() => gs.Achievements.showAchievements();

  @override
  Future<Map<String, PlayAchievementState>> achievements() async {
    final items = await gs.Achievements.loadAchievements(
      ignoreImages: true,
    ).timeout(_wait);
    return {
      for (final a in items ?? const <gs.AchievementItemData>[])
        a.id: (steps: a.completedSteps, unlocked: a.unlocked),
    };
  }

  @override
  Future<void> unlock(String id) => gs.Achievements.unlock(
    achievement: gs.Achievement(androidID: id),
  ).timeout(_wait);

  @override
  Future<void> setSteps(String id, int steps) => gs.Achievements.setSteps(
    achievement: gs.Achievement(androidID: id, steps: steps),
  ).timeout(_wait);

  @override
  Future<String?> loadLogbook() async {
    try {
      return await gs.SaveGame.loadGame(name: _snapshot).timeout(_wait);
    } on PlatformException {
      // A missing snapshot fails like an unreachable cloud; only a list
      // fresh from Play's servers tells them apart. Offline, Play answers
      // from its cache, which may predate another phone's save: the gate
      // says null then (PlayGamesGate.kt), and nothing is decided.
      final listed = await _gate
          .invokeMethod<bool>('listed', {'name': _snapshot})
          .timeout(_wait);
      if (listed == false) return null;
      rethrow;
    }
  }

  @override
  Future<void> saveLogbook(String data, String description) =>
      gs.SaveGame.saveGame(
        data: data,
        name: _snapshot,
        description: description,
      ).timeout(_wait);
}

/// What the Settings strip shows.
@immutable
class PlayGamesStatus {
  const PlayGamesStatus({
    this.available = false,
    this.connected = false,
    this.saving = false,
    this.offline = false,
    this.restored = false,
    this.resetElsewhere = false,
    this.updateNeeded = false,
    this.unreadable = false,
    this.savedAt,
  });

  /// False hides the strip: not configured, not Android, or no Play
  /// services.
  final bool available;
  final bool connected;

  /// A cloud save is under way.
  final bool saving;

  /// The last cloud save failed; it is retried at the next calm moment.
  final bool offline;

  /// The last sync brought progress from the cloud.
  final bool restored;

  /// The last sync started this phone afresh: the progress was reset on
  /// another phone.
  final bool resetElsewhere;

  /// The cloud save is from a newer Beakbound: it is left alone, and this
  /// phone keeps playing on its own until it is updated.
  final bool updateNeeded;

  /// The cloud save cannot be read (damaged): it is left alone, this phone
  /// keeps its own progress, and the read is tried again like any sync.
  final bool unreadable;

  /// When the cloud last matched this phone; null while neither holds
  /// anything to save.
  final DateTime? savedAt;

  PlayGamesStatus copyWith({
    bool? available,
    bool? connected,
    bool? saving,
    bool? offline,
    bool? restored,
    bool? resetElsewhere,
    bool? updateNeeded,
    bool? unreadable,
    DateTime? savedAt,
  }) => PlayGamesStatus(
    available: available ?? this.available,
    connected: connected ?? this.connected,
    saving: saving ?? this.saving,
    offline: offline ?? this.offline,
    restored: restored ?? this.restored,
    resetElsewhere: resetElsewhere ?? this.resetElsewhere,
    updateNeeded: updateNeeded ?? this.updateNeeded,
    unreadable: unreadable ?? this.unreadable,
    savedAt: savedAt ?? this.savedAt,
  );
}

final playGamesServiceProvider = Provider<PlayGamesService>(
  (ref) => GooglePlayGames(),
);

/// The achievements' Play ids (play_games_ids.dart); tests give their own.
final playAchievementIdsProvider = Provider<Map<PlayAchievement, String>>(
  (ref) => playAchievementIds,
);

final playGamesProvider = NotifierProvider<PlayGamesSync, PlayGamesStatus>(
  PlayGamesSync.new,
);

/// Play Games in the background: the silent launch check and restore, the
/// cloud logbook flushed at calm moments, and the achievements reported
/// with Google's own pop-up, one per calm moment. Nothing here ever runs
/// during a flight, a boss, a story scene or a camera session: only the
/// calm screens call [calmMoment], and the app's pause calls [paused].
class PlayGamesSync extends Notifier<PlayGamesStatus> {
  /// The least time between two cloud saves at calm moments.
  static const throttle = Duration(seconds: 60);

  /// How long Connect waits for Google's sign-in sheet. A real person may
  /// pick an account and make a Play Games profile, so it is generous, but
  /// bounded: games_services 5.3.0 never answers a null sign-in result, and
  /// Connect holds the queue. A late answer is dropped (Future.timeout), so
  /// it never starts a second catch-up; the next Connect asks again.
  static const signInWait = Duration(minutes: 3);

  PlayGamesService get _service => ref.read(playGamesServiceProvider);
  ProgressRepository get _repo => ref.read(progressRepositoryProvider);
  DateTime _now() => ref.read(appClockProvider)();

  Future<void> _queue = Future.value();
  bool _started = false;

  /// The logbook the cloud last matched, and when.
  String? _synced;
  DateTime? _syncedAt;

  /// What Play holds, read once a session for each player, and whose.
  Map<String, PlayAchievementState>? _play;
  String? _playOf;

  /// A reset asked for the cloud save to go and the cloud has not taken it
  /// yet: until it does, its fresh logbook may replace a save this build
  /// cannot read. Only [afterReset] sets it, never a normal sync.
  bool _resetDue = false;

  /// Achievement ids Play turned down this session (a typo, or standard in
  /// Play Console while the code sends steps): skipped until next launch.
  final _rejected = <String>{};

  /// Whether the moment is still calm: home or Settings on screen, or a
  /// settled results stage. The router and the results stage keep it, and
  /// the app opens on home. Google's pop-up and a cloud restore land only
  /// while it holds (or, for a restore, while the app is away off-flight);
  /// a job that outlives its moment leaves them for the next one.
  bool calm = true;

  /// The app went to the background off-flight and has not come back yet.
  bool _away = false;

  /// The calm-moment job waiting its turn; more calls join it.
  Future<void>? _calmJob;

  @override
  PlayGamesStatus build() => const PlayGamesStatus();

  /// One job at a time, in order. A failed job only logs: Play Games never
  /// gets in the way of the game.
  Future<T?> _run<T>(Future<T> Function() job) {
    final next = _queue.then<T?>((_) => ref.mounted ? job() : null).catchError((
      Object e,
    ) {
      debugPrint('Play Games: $e');
      return null;
    });
    _queue = next;
    return next;
  }

  /// At launch: reads the automatic sign-in and, when it worked, restores
  /// the cloud logbook and reports what is due. Never prompts. The app's
  /// first screen is a calm moment of its own (the router announces it
  /// while this runs); when one waits behind, it reports instead, so the
  /// launch shows Google's pop-up once.
  Future<void> start() => _run(() async {
    if (_started) return;
    _started = true;
    if (!await _service.available()) return;
    state = state.copyWith(available: true, savedAt: (await _memory()).savedAt);
    if (!await _service.signedIn()) return;
    state = state.copyWith(connected: true);
    await _sync(force: true);
    if (_calmJob == null) await _report(all: false);
  });

  /// The Connect key: Google's sign-in, then one catch-up that merges the
  /// logbook and reports every earned achievement at once.
  Future<bool> connect() async =>
      await _run(() async {
        if (!state.available) return false;
        // A timeout fails the job: connect() answers false.
        if (!await _service.signIn().timeout(signInWait)) return false;
        state = state.copyWith(connected: true);
        await _sync(force: true);
        await _report(all: true);
        return true;
      }) ??
      false;

  /// A calm moment (home, Settings, a settled results stage): saves the
  /// logbook if it changed and a minute has passed, and reports what is
  /// due with at most one unlock.
  Future<void> calmMoment() => _calmJob ??= _run(() async {
    _calmJob = null;
    if (!state.connected) return;
    await _sync();
    await _report(all: false);
  });

  /// The app went to the background: saves the logbook if it changed. No
  /// unlocks, since their pop-up would go unseen. Until [resumed], the
  /// restore may land: no one is watching.
  Future<void> paused() {
    _away = true;
    return _run(() async {
      if (state.connected) await _sync(now: true);
    });
  }

  /// The app is back on screen.
  void resumed() => _away = false;

  /// Progress was reset: the cloud copy is replaced at once when connected,
  /// even one this build cannot read (damaged, or from a newer Beakbound),
  /// since the player asked for it to go.
  Future<void> afterReset() => _run(() async {
    _synced = null;
    _syncedAt = null;
    _resetDue = true;
    if (state.connected) await _sync(force: true);
  });

  Future<void> showAchievements() async {
    try {
      await _service.showAchievements();
    } catch (e) {
      debugPrint('Play Games achievements: $e');
    }
  }

  Future<void> _sync({bool force = false, bool now = false}) async {
    try {
      final mine = await _repo.exportLogbook();
      final local = jsonEncode(mine.toJson());
      if (!force && local == _synced) return;
      final last = _syncedAt;
      if (!force &&
          !now &&
          last != null &&
          _now().difference(last) < throttle) {
        return;
      }
      state = state.copyWith(saving: true);
      // The cloud and this phone's sync memory are one player's: without
      // knowing who, nothing is decided this round.
      final player = await _service.playerId();
      if (player == null) throw StateError('no Play player id');
      final raw = await _service.loadLogbook();
      Logbook? cloud;
      var replace = false;
      try {
        cloud = Logbook.decode(raw);
      } on Exception catch (e) {
        if (e is! NewerLogbook && e is! FormatException) rethrow;
        // A copy this build cannot read: a newer Beakbound's, or damaged.
        // It may hold another phone's progress, so it is never written
        // over: connected, not offline, its own quiet line, and tried again
        // like any sync, after a change here and a minute. Only a reset,
        // which asked for the cloud save to go, replaces it, and only in
        // the cloud this phone synced with (the one its dialog named).
        if (!_resetDue || !await _repo.cloudSynced(player: player)) {
          _synced = local;
          _syncedAt = _now();
          state = PlayGamesStatus(
            available: true,
            connected: true,
            updateNeeded: e is NewerLogbook,
            unreadable: e is FormatException,
            savedAt: state.savedAt,
          );
          return;
        }
        replace = true;
      }
      if (!calm && !_away) {
        // The moment ended while the cloud answered (a flight began): the
        // restore and the save wait, whole, for the next calm moment.
        _synced = null;
        _syncedAt = null;
        state = state.copyWith(saving: false);
        return;
      }
      // As importLogbook decides it: a reset on another phone clears this
      // one when it has synced with this player before.
      final elsewhere =
          cloud != null &&
          cloud.epoch > mine.epoch &&
          await _repo.cloudSynced(player: player);
      final (merged, changed) = await _repo.importLogbook(
        cloud,
        player: player,
      );
      final mergedJson = jsonEncode(merged.toJson());
      if (changed) {
        await ref.read(progressProvider.notifier).refresh();
        ref.invalidate(builtShelfProvider);
        ref.invalidate(builtLevelProvider);
      }
      // No cloud save and no progress here: nothing to keep, so nothing
      // goes up, and no save is claimed. A reset's fresh logbook replacing
      // an unreadable copy always goes up: its epoch carries the reset.
      final nothing = cloud == null && merged.isEmpty && !replace;
      if (!nothing && jsonEncode(cloud?.toJson()) != mergedJson) {
        await _service.saveLogbook(
          merged.encode(),
          _describe(await ref.read(progressProvider.future)),
        );
      }
      _resetDue = false;
      final at = _now();
      final savedAt = nothing ? null : at;
      // What this phone now holds: the merge, or, when the import wrote
      // nothing, its own logbook (cloud entries this build cannot import
      // must not leave it looking unsaved).
      _synced = changed ? mergedJson : local;
      _syncedAt = at;
      final memory = await _memory();
      await _remember(memory.reported, savedAt, player: memory.player);
      state = PlayGamesStatus(
        available: true,
        connected: true,
        restored: changed,
        resetElsewhere: elsewhere,
        savedAt: savedAt,
      );
    } catch (e) {
      // Offline, or Play does not say who is signed in: nothing is written
      // over, the change stays and is tried again at the next calm moment.
      debugPrint('Play Games save: $e');
      state = state.copyWith(saving: false, offline: true);
    }
  }

  /// Reports earned achievements Play does not hold yet, in table order.
  /// Steps short of a target go out silently; one completion (Google's
  /// pop-up) per calm moment, or all of them after Connect.
  Future<void> _report({required bool all}) async {
    final ids = ref.read(playAchievementIdsProvider);
    if (ids.values.every((id) => id.isEmpty)) return;
    try {
      // What was sent is one player's: after a switch, another player's
      // record starts from what Play holds for them.
      final player = await _service.playerId();
      if (player == null) return;
      if (player != _playOf) {
        _play = null;
        _playOf = player;
      }
      final progress = await ref.read(progressProvider.future);
      final memory = await _memory();
      final reported = {if (memory.player == player) ...memory.reported};
      try {
        _play ??= await _service.achievements();
      } catch (e) {
        debugPrint('Play Games achievements: $e');
      }
      for (final a in PlayAchievement.values) {
        final id = ids[a] ?? '';
        if (_play?[id] case final held?) {
          reported[id] = math.max(
            reported[id] ?? 0,
            held.unlocked ? a.goal : held.steps,
          );
        }
      }
      var popped = false;
      var failures = 0;
      for (final a in PlayAchievement.values) {
        final id = ids[a] ?? '';
        if (id.isEmpty || _rejected.contains(id)) continue;
        final want = a.progress(progress);
        if (want <= (reported[id] ?? 0)) continue;
        final completes = want >= a.goal;
        if (completes && popped && !all) continue;
        // The moment ended: the rest waits for the next one.
        if (!calm) break;
        try {
          if (a.steps == null) {
            await _service.unlock(id);
          } else {
            await _service.setSteps(id, want);
          }
        } catch (e) {
          debugPrint('Play Games achievement ${a.name} ($id): $e');
          // Play turned down this one id: the others go on.
          if (_turnedDown(e)) {
            _rejected.add(id);
            continue;
          }
          // No answer, or several failures in a row (offline, signed out):
          // the rest waits for the next calm moment.
          if (e is TimeoutException || ++failures >= 3) break;
          continue;
        }
        failures = 0;
        reported[id] = want;
        if (completes) popped = true;
      }
      if (memory.player != player ||
          jsonEncode(reported) != jsonEncode(memory.reported)) {
        await _remember(reported, memory.savedAt, player: player);
      }
    } catch (e) {
      debugPrint('Play Games achievements: $e');
    }
  }

  /// Whether Play rejected the achievement itself: unknown id, not
  /// incremental, or not unlockable. The plugin's message starts with
  /// Play's status code (GamesClientStatusCodes 26560 to 26563).
  static bool _turnedDown(Object e) {
    if (e is! PlatformException) return false;
    final code = int.tryParse(e.message?.split(':').first ?? '') ?? 0;
    return code >= 26560 && code <= 26563;
  }

  /// The saved game's line in Google's list: "38★ · 12 medals · at 3-2",
  /// in the language the game speaks when it saves.
  static String _describe(ProgressSnapshot p) =>
      L10n.strings.playGamesSaveDescription(
        p.earnedMedals,
        p.campaign.totalStars,
        p.campaign.current.id,
      );

  /// The sync's memory on this phone: the player the achievements went to
  /// and what was sent, and when the cloud was last saved.
  Future<({String? player, Map<String, int> reported, DateTime? savedAt})>
  _memory() async {
    try {
      final json = jsonDecode(await _repo.loadPlayGamesMemory() ?? '{}');
      final player = json is Map ? json['player'] : null;
      final reported = json is Map ? json['reported'] : null;
      final savedAt = json is Map ? json['savedAt'] : null;
      return (
        player: player is String ? player : null,
        reported: {
          if (reported is Map)
            for (final MapEntry(:key, :value) in reported.entries)
              if (key is String && value is int) key: value,
        },
        savedAt: savedAt is int
            ? DateTime.fromMillisecondsSinceEpoch(savedAt)
            : null,
      );
    } on FormatException {
      return (player: null, reported: <String, int>{}, savedAt: null);
    }
  }

  Future<void> _remember(
    Map<String, int> reported,
    DateTime? savedAt, {
    String? player,
  }) => _repo.savePlayGamesMemory(
    jsonEncode({
      'player': ?player,
      'reported': reported,
      'savedAt': ?savedAt?.millisecondsSinceEpoch,
    }),
  );
}
