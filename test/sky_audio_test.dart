import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/audio.dart';
import 'package:push_up_bird/game/flight_voices.dart';
import 'package:push_up_bird/game/play_controller.dart';
import 'package:push_up_bird/game/regions/world_region.dart' show WorldTour;
import 'package:push_up_bird/game/sound_bank.dart';
import 'campaign_flight.dart' show levelFlight;
import 'heart_pickup_test.dart' show defeat, flight;
import 'touch_combat_test.dart' show playing;

// Model Android's per-player focus: a GAIN request pauses the previous owner.
// Unlike a SilentAudio double, this exercises SkyAudio and AudioPlayer together.
class AndroidAudioHost {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final focus = <String, int>{};
  final sources = <String, String>{};
  final playing = <String>{};
  final channels = <String>{};
  String? owner;
  final starts = <String>[];
  final volumes = <String, double>{};
  final volumeLog = <String, List<double>>{};
  final loads = <String>[];
  final modes = <String, String>{};
  Completer<void>? sourceGate;

  void install() {
    for (final name in [
      'xyz.luan/audioplayers.global',
      'xyz.luan/audioplayers.global/events',
    ]) {
      messenger.setMockMethodCallHandler(
        MethodChannel(name),
        (_) async => null,
      );
    }
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async {
        final args = Map<String, dynamic>.from(call.arguments as Map);
        final id = args['playerId'] as String;
        if (call.method == 'create') {
          final name = 'xyz.luan/audioplayers/events/$id';
          channels.add(name);
          messenger.setMockMethodCallHandler(
            MethodChannel(name),
            (_) async => null,
          );
        } else if (call.method == 'setAudioContext') {
          focus[id] = args['audioFocus'] as int;
        } else if (call.method == 'setSourceUrl') {
          sources[id] = args['url'] as String;
          loads.add(sources[id]!);
          await sourceGate?.future;
          scheduleMicrotask(
            () => messenger.handlePlatformMessage(
              'xyz.luan/audioplayers/events/$id',
              const StandardMethodCodec().encodeSuccessEnvelope({
                'event': 'audio.onPrepared',
                'value': true,
              }),
              (_) {},
            ),
          );
        } else if (call.method == 'resume') {
          if ((focus[id] ?? 1) == 1) {
            playing.remove(owner);
            owner = id;
          }
          playing.add(id);
          starts.add(id);
        } else if (call.method == 'setVolume') {
          volumes[id] = args['volume'] as double;
          (volumeLog[id] ??= []).add(volumes[id]!);
        } else if (call.method == 'setPlayerMode') {
          modes[id] = args['playerMode'] as String;
        } else if ([
          'pause',
          'stop',
          'release',
          'dispose',
        ].contains(call.method)) {
          playing.remove(id);
        } else if ([
          'getDuration',
          'getCurrentPosition',
        ].contains(call.method)) {
          return 1000;
        }
        return null;
      },
    );
    for (final file in Directory(
      'assets/audio',
    ).listSync(recursive: true).whereType<File>()) {
      final asset = file.path
          .substring('assets${Platform.pathSeparator}'.length)
          .replaceAll(Platform.pathSeparator, '/');
      AudioCache.instance.loadedFiles[asset] = file.absolute.uri;
    }
  }

  String get music =>
      sources.keys.singleWhere((id) => sources[id]!.endsWith('sky_flight.ogg'));
}

Future<void> waitForTrack(AndroidAudioHost host, String asset) async {
  for (var i = 0; i < 100; i++) {
    if (host.playing.any((id) => host.sources[id]!.endsWith(asset))) return;
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
  fail(
    'Expected playing music $asset; active sources: ${host.playing.map((id) => host.sources[id])}',
  );
}

Future<void> drainAudio() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'dense combat preserves cinematic cues, music and a bounded voice count',
    () async {
      final host = AndroidAudioHost()..install();
      final audio = SkyAudio(effectClock: () => 0);
      addTearDown(audio.dispose);
      await audio.configure(const GameSettings());
      for (final cue in [
        'boss_roar',
        'flap',
        'shoot',
        'star',
        'rock_hit',
        'deflect',
        'enemy_charge',
        'enemy_shoot',
      ]) {
        audio.effect(cue);
      }
      await drainAudio();
      final boss = host.sources.keys.singleWhere(
        (id) => host.sources[id]!.endsWith('boss_roar.wav'),
      );
      audio.effect('bump');
      audio.effect('ui_tap');
      await drainAudio();
      expect(host.sources[boss], endsWith('boss_roar.wav'));
      expect(host.playing, containsAll([host.music, boss]));
      expect(host.playing.length, lessThanOrEqualTo(9));
      expect(host.sources.values, contains(endsWith('bump.wav')));
      for (final id in host.playing.where((id) => id != host.music)) {
        expect(host.focus[id], 0);
        expect(host.modes[id], 'PlayerMode.lowLatency');
      }
    },
  );

  test(
    'rapid duplicates coalesce; every accepted shot uses the same sound',
    () async {
      final host = AndroidAudioHost()..install();
      var now = 0;
      final audio = SkyAudio(effectClock: () => now);
      addTearDown(audio.dispose);
      await audio.configure(const GameSettings(music: false));
      for (var take = 0; take < 4; take++) {
        final before = host.starts.length;
        audio.effect('shoot');
        audio.effect('shoot');
        await drainAudio();
        expect(host.starts.length, before + 1);
        now += 500;
      }
      expect(host.loads.map((url) => Uri.parse(url).pathSegments.last), [
        'shoot.wav',
        'shoot.wav',
        'shoot.wav',
        'shoot.wav',
      ]);
    },
  );

  for (final (bird, name) in const [(0, 'pip'), (3, 'orbit')]) {
    test('$name sprints with one of its own four calls, never the last one '
        'again', () async {
      final host = AndroidAudioHost()..install();
      var now = 0;
      final audio = SkyAudio(effectClock: () => now, random: Random(7));
      addTearDown(audio.dispose);
      await audio.configure(GameSettings(music: false, bird: bird));
      bool isCall(String path) => path.contains('/story/sprint-');
      final voicePaths = <String>[];
      for (var sprint = 0; sprint < 32; sprint++) {
        audio.effect('sprint');
        audio.effect('sprint'); // A duplicate cue cannot start another voice.
        for (var i = 0; i < 100 && voicePaths.length <= sprint; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 2));
          voicePaths
            ..clear()
            ..addAll(host.loads.where(isCall));
        }
        expect(voicePaths, hasLength(sprint + 1));
        now += 15000;
      }
      final chosen = voicePaths.map((path) => Uri.parse(path).path).toList();
      expect(chosen.map((path) => path.split('/').last).toSet(), {
        'sprint-$name-woohoo.ogg',
        'sprint-$name-turbo.ogg',
        'sprint-$name-gravity.ogg',
        'sprint-$name-whee.ogg',
      });
      for (var i = 1; i < chosen.length; i++) {
        expect(chosen[i], isNot(chosen[i - 1]));
      }
      expect(
        host.sources.entries.where((entry) => isCall(entry.value)),
        hasLength(1),
      );
      await audio.stopEffects();
      expect(host.playing, isEmpty);
    });
  }

  test('with voices off a sprint only whooshes', () async {
    final host = AndroidAudioHost()..install();
    final audio = SkyAudio(effectClock: () => 0);
    addTearDown(audio.dispose);
    await audio.configure(const GameSettings(music: false, voices: false));
    audio.effect('sprint');
    await drainAudio();
    expect(host.loads, isNot(contains(contains('audio/story/'))));
    expect(host.loads, contains(endsWith('sprint.wav')));
  });

  test(
    'a live flight\'s voices take the sprint call and duck lighter',
    () async {
      final host = AndroidAudioHost()..install();
      final audio = SkyAudio(effectClock: () => 0, random: Random(3));
      addTearDown(audio.dispose);
      await audio.configure(const GameSettings());
      await waitForTrack(host, 'sky_flight.ogg');
      final sim = playing();
      audio.voices = FlightVoices(
        talk: 1,
        bird: 0,
        mode: PlayMode.touch,
        random: Random(1),
      );
      audio.syncCombat(sim, silent: true);
      expect(sim.sprint(), isTrue);
      audio.syncCombat(sim);
      await drainAudio();
      final calls = [
        for (final path in host.loads)
          if (path.contains('/story/sprint-pip-')) path,
      ];
      expect(calls, hasLength(1), reason: 'said once, by the voices');
      expect(host.loads, contains(endsWith('sprint.wav')));
      expect(host.volumes[host.music], closeTo(.42, 1e-9));
      await audio.stopEffects();
      await drainAudio();
      expect(host.volumes[host.music], .70);
    },
  );

  test('a spoken line ducks the music until it ends or is hushed', () async {
    final host = AndroidAudioHost()..install();
    final audio = SkyAudio(effectClock: () => 0);
    addTearDown(audio.dispose);
    await audio.configure(const GameSettings(), track: SkyMusic.menu);
    await waitForTrack(host, 'sky_menu.ogg');
    final music = host.sources.keys.singleWhere(
      (id) => host.sources[id]!.endsWith('sky_menu.ogg'),
    );
    expect(host.volumes[music], .70);
    audio.speak('audio/story/before-1-1-1.ogg');
    await drainAudio();
    final speech = host.sources.keys.singleWhere(
      (id) => host.sources[id]!.endsWith('before-1-1-1.ogg'),
    );
    expect(host.playing, containsAll([music, speech]));
    expect(host.focus[speech], 0, reason: 'speech never takes focus');
    expect(host.volumes[music], closeTo(.245, 1e-9));
    // The next line cuts the first off on the same player.
    audio.speak('audio/story/before-1-1-2-pip.ogg');
    await drainAudio();
    expect(host.sources[speech], endsWith('before-1-1-2-pip.ogg'));
    expect(host.volumes[music], closeTo(.245, 1e-9));
    // It ends by itself: the music comes back up.
    host.messenger.handlePlatformMessage(
      'xyz.luan/audioplayers/events/$speech',
      const StandardMethodCodec().encodeSuccessEnvelope({
        'event': 'audio.onComplete',
      }),
      (_) {},
    );
    await drainAudio();
    expect(host.volumes[music], .70);
    audio.speak('audio/story/before-1-1-3.ogg');
    await drainAudio();
    expect(host.volumes[music], closeTo(.245, 1e-9));
    await audio.hush();
    await drainAudio();
    expect(host.playing, isNot(contains(speech)));
    expect(host.volumes[music], .70);
    // Nothing is said with voices off.
    await audio.configure(
      const GameSettings(voices: false),
      track: SkyMusic.menu,
    );
    final loads = host.loads.length;
    audio.speak('audio/story/before-1-1-4.ogg');
    await drainAudio();
    expect(host.loads, hasLength(loads));
    expect(host.volumes[music], .70);
  });

  test('a ducking effect lowers the music, under a line too, until '
      'stopped', () async {
    final host = AndroidAudioHost()..install();
    final audio = SkyAudio(effectClock: () => 0);
    addTearDown(audio.dispose);
    await audio.configure(const GameSettings());
    await waitForTrack(host, 'sky_flight.ogg');
    final music = host.music;
    final duck = soundBank['finish_cheer']!.duck!;
    expect(duck, inExclusiveRange(0, 1));
    audio.effect('complete');
    await drainAudio();
    expect(host.volumes[music], .70, reason: 'an ordinary cue never ducks');
    audio.effect('finish_cheer');
    await drainAudio();
    expect(host.volumes[music], closeTo(.70 * duck, 1e-9));
    // A line said over the cheer ducks the music further.
    audio.speak('audio/story/before-1-1-1.ogg', duck: SkyAudio.flightDuck);
    await drainAudio();
    expect(
      host.volumes[music],
      closeTo(.70 * duck * SkyAudio.flightDuck, 1e-9),
    );
    await audio.hush();
    await drainAudio();
    expect(host.volumes[music], closeTo(.70 * duck, 1e-9));
    await audio.stopEffects();
    await drainAudio();
    expect(host.volumes[music], .70);
    // With effects off the cue does not play, so nothing ducks.
    await audio.configure(const GameSettings(effects: false));
    audio.effect('finish_cheer');
    await drainAudio();
    expect(host.volumes[music], .70);
  });

  test('the music swells back when the ducking cue ends; a later one '
      'extends it or cuts the swell short', () async {
    final host = AndroidAudioHost()..install();
    var now = 0;
    final audio = SkyAudio(effectClock: () => now);
    addTearDown(audio.dispose);
    await audio.configure(const GameSettings());
    await waitForTrack(host, 'sky_flight.ogg');
    final music = host.music;
    final cheer = soundBank['finish_cheer']!;
    final ducked = .70 * cheer.duck!;
    // At double speed the cue, and so the duck, lasts half its length.
    await audio.setRate(2);
    final length = (cheer.seconds * 1000 / 2).ceil();
    final clock = Stopwatch()..start();
    audio.effect('finish_cheer');
    await drainAudio();
    expect(host.volumes[music], closeTo(ducked, 1e-9));
    await Future<void>.delayed(Duration(milliseconds: length ~/ 2));
    now += cheer.cooldownMs;
    audio.effect('finish_cheer');
    final again = clock.elapsedMilliseconds;
    // Past the end of the first cue, inside the second.
    await Future<void>.delayed(
      Duration(milliseconds: max(0, length + 150 - again)),
    );
    await drainAudio();
    expect(host.volumes[music], closeTo(ducked, 1e-9));
    // The swell starts as the second cue ends; a third cue cuts it short.
    while (host.volumes[music]! < ducked + 1e-6 &&
        clock.elapsedMilliseconds < 6000) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(
      clock.elapsedMilliseconds,
      greaterThanOrEqualTo(again + length - 50),
    );
    expect(host.volumes[music], lessThan(.70));
    now += cheer.cooldownMs;
    audio.effect('finish_cheer');
    final last = clock.elapsedMilliseconds;
    await drainAudio();
    expect(host.volumes[music], closeTo(ducked, 1e-9));
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(
      host.volumes[music],
      closeTo(ducked, 1e-9),
      reason: 'the cut swell takes no more steps',
    );
    final mark = host.volumeLog[music]!.length;
    while (host.volumes[music] != .70 && clock.elapsedMilliseconds < 9000) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(host.volumes[music], .70);
    expect(
      clock.elapsedMilliseconds,
      greaterThanOrEqualTo(last + length + 550),
      reason: 'the swell takes about 0.6 s',
    );
    // Up in a few small steps, each above the last and none past full.
    final swell = host.volumeLog[music]!.sublist(mark);
    expect(swell.length, greaterThanOrEqualTo(4));
    for (var i = 0; i < swell.length; i++) {
      expect(swell[i], greaterThan(i == 0 ? ducked : swell[i - 1]));
      expect(swell[i], lessThanOrEqualTo(.70));
    }
  });

  test(
    'muting and disposal cancel effects still waiting for native loading',
    () async {
      final host = AndroidAudioHost()..install();
      final audio = SkyAudio();
      await audio.configure(const GameSettings(music: false));
      host.sourceGate = Completer<void>();
      audio.effect('boss_burst');
      await drainAudio();
      await audio.configure(const GameSettings(music: false, effects: false));
      host.sourceGate!.complete();
      await audio.stopEffects();
      expect(host.starts, isEmpty);
      await audio.configure(const GameSettings(music: false));
      host.sourceGate = Completer<void>();
      audio.effect('shoot');
      await drainAudio();
      final disposal = audio.dispose();
      host.sourceGate!.complete();
      await disposal;
      expect(host.starts, isEmpty);
      expect(host.playing, isEmpty);
    },
  );

  test('every sound and variation is a short, nonempty PCM asset', () {
    for (final entry in soundBank.entries) {
      for (var variant = 0; variant < entry.value.variants; variant++) {
        final bytes = File(
          'assets/${soundAsset(entry.key, variant)}',
        ).readAsBytesSync();
        expect(String.fromCharCodes(bytes.take(4)), 'RIFF');
        expect(bytes.length, greaterThan(1000));
        // SoundPool has a small decoded-buffer budget; keep all cues below it.
        expect(bytes.length, lessThan(1000000));
      }
    }
  });

  test('chained sprint rings climb through their takes and hold', () async {
    final host = AndroidAudioHost()..install();
    var now = 0;
    final audio = SkyAudio(effectClock: () => now);
    addTearDown(audio.dispose);
    await audio.configure(const GameSettings(music: false));
    final sim = FlightSimulation(
      rules: TapFlyMode(),
      practice: true,
      course: FlightCourse.starTrail,
    );
    audio.syncCombat(sim);
    for (var chain = 1; chain <= 4; chain++) {
      sim
        ..ringSprints = chain
        ..ringChain = chain;
      audio.syncCombat(sim);
      await drainAudio();
      now += 500;
    }
    expect(
      host.loads
          .map((url) => Uri.parse(url).pathSegments.last)
          .where((name) => name.startsWith('sprint_ring')),
      [
        'sprint_ring.wav',
        'sprint_ring_2.wav',
        'sprint_ring_3.wav',
        'sprint_ring_3.wav',
      ],
    );
  });

  test('star pickups rotate the original cues without a trio variant', () {
    expect(soundBank['star']!.variants, 3);
    expect(soundBank.containsKey('trio'), isFalse);
    for (var variant = 0; variant < 3; variant++) {
      final selected = File(
        'assets/${soundAsset('star', variant)}',
      ).readAsBytesSync();
      expect(String.fromCharCodes(selected.take(4)), 'RIFF');
      expect(selected.length, greaterThan(20000));
    }
  });

  test('game-over cue pauses flight music until the next run', () async {
    final host = AndroidAudioHost()..install();
    final audio = SkyAudio();
    addTearDown(audio.dispose);
    await audio.configure(const GameSettings());
    final music = host.music;

    audio.effect('game_over');
    await drainAudio();
    expect(host.playing, isNot(contains(music)));
    expect(host.sources.values, contains(endsWith('game_over.wav')));

    await audio.resumeMusic();
    await waitForTrack(host, 'sky_flight.ogg');
  });

  test('losing a flight plays the game-over sound once', () async {
    final host = AndroidAudioHost()..install();
    final audio = SkyAudio();
    final controller = PlayController(
      mode: PlayMode.touch,
      source: null,
      audio: audio,
      saveRun: (_) async {},
      saveSession: (_) async {},
    );
    addTearDown(() async {
      controller.dispose();
      await audio.dispose();
    });

    await audio.configure(const GameSettings());
    await controller.fly();
    controller.simulation!.end(EndReason.collision);
    await controller.finish();
    await drainAudio();

    final cueStarts = host.starts.where(
      (id) => host.sources[id]?.endsWith('game_over.wav') ?? false,
    );
    expect(cueStarts, hasLength(1));
    expect(host.playing, contains(cueStarts.single));
    expect(host.playing, isNot(contains(host.music)));

    await controller.finish();
    await drainAudio();
    expect(
      host.starts.where(
        (id) => host.sources[id]?.endsWith('game_over.wav') ?? false,
      ),
      hasLength(1),
    );
  });

  for (final kind in BossKind.values) {
    test(
      '$kind switches to boss music once and restores flight after departure',
      () async {
        final host = AndroidAudioHost()..install();
        final audio = SkyAudio();
        addTearDown(audio.dispose);
        await audio.configure(const GameSettings(effects: false));
        final music = host.music;
        final boss = SkyBoss(number: 1, x: 1, kind: kind, cinematic: true);
        audio.syncBoss(boss);
        await waitForTrack(host, 'sky_boss.ogg');
        expect(host.volumes[music], .14);
        boss.age = 5;
        for (var frame = 0; frame < 100; frame++) {
          audio.syncBoss(boss);
        }
        await drainAudio();
        expect(host.volumes[music], .70);
        expect(
          host.loads.where((s) => s.endsWith('sky_boss.ogg')),
          hasLength(1),
        );
        boss.defeatedAt = boss.age;
        audio.syncBoss(boss);
        await drainAudio();
        expect(host.sources[music], endsWith('sky_boss.ogg'));
        expect(host.volumes[music], .14);
        audio.syncBoss(null);
        await waitForTrack(host, 'sky_flight.ogg');
        expect(host.volumes[music], .70);
      },
    );
  }

  test(
    'paused replay seeks remember the boss track without starting audio',
    () async {
      final host = AndroidAudioHost()..install();
      final audio = SkyAudio();
      addTearDown(audio.dispose);
      await audio.configure(const GameSettings(effects: false));
      final music = host.music;
      await audio.stop();
      final starts = host.starts.length;
      audio.syncBoss(SkyBoss(number: 1, x: 1)..age = 6, silent: true);
      await drainAudio();
      expect(host.playing, isEmpty);
      expect(host.starts.length, starts);
      await audio.resumeMusic();
      expect(host.sources[music], endsWith('sky_boss.ogg'));
      await audio.configure(const GameSettings(music: false, effects: false));
      audio.syncBoss(null, silent: true);
      await drainAudio();
      expect(host.playing, isEmpty);
      await audio.configure(const GameSettings(effects: false));
      expect(host.sources[music], endsWith('sky_flight.ogg'));
    },
  );

  test('late boss updates cannot restart stopped or disposed music', () async {
    final host = AndroidAudioHost()..install();
    final audio = SkyAudio();
    await audio.configure(const GameSettings(effects: false));
    audio.syncBoss(SkyBoss(number: 1, x: 1)..age = 6);
    await audio.stop();
    await drainAudio();
    expect(host.playing, isEmpty);
    await audio.dispose();
    audio.syncBoss(null);
    await drainAudio();
    expect(host.playing, isEmpty);
  });

  test(
    'ready, flap, reward and boss effects do not silence gameplay music',
    () async {
      final host = AndroidAudioHost()..install();
      final audio = SkyAudio();
      addTearDown(audio.dispose);
      await audio.configure(const GameSettings());
      expect(host.playing, contains(host.music));
      for (final effect in ['ready', 'flap', 'star', 'boss_roar']) {
        final previous = host.starts.length;
        audio.effect(effect);
        for (var i = 0; i < 100 && host.starts.length == previous; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 1));
        }
        expect(
          host.starts.length,
          previous + 1,
          reason: '$effect must actually play',
        );
        expect(
          host.playing,
          contains(host.music),
          reason: '$effect must mix with music',
        );
      }
      await audio.stop();
      expect(host.playing, isEmpty);
      await audio.resumeMusic();
      expect(host.playing, contains(host.music));
      await audio.configure(const GameSettings(music: false));
      expect(host.playing, isNot(contains(host.music)));
    },
  );

  test(
    'menu and flight use different assets and music mute preserves effects',
    () async {
      final host = AndroidAudioHost()..install();
      final audio = SkyAudio();
      addTearDown(audio.dispose);
      await audio.configure(const GameSettings(), track: SkyMusic.menu);
      expect(host.sources.values.single, endsWith('sky_menu.ogg'));
      await audio.configure(const GameSettings(), track: SkyMusic.flight);
      expect(host.sources.values.single, endsWith('sky_flight.ogg'));
      await audio.configure(const GameSettings(music: false));
      final before = host.starts.length;
      audio.effect('star');
      for (var i = 0; i < 100 && host.starts.length == before; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      expect(host.playing, hasLength(1));
      expect(host.sources[host.playing.single], endsWith('star.wav'));
    },
  );

  test('every campaign region but the jungle flies to its own song', () {
    expect(SkyMusic.flightOver(null), SkyMusic.flight);
    expect(SkyMusic.flightOver(WorldRegion.jungle), SkyMusic.flight);
    final songs = {
      for (final region in Campaign.journey)
        region: SkyMusic.flightOver(region),
    };
    expect(songs.keys.toSet(), WorldRegion.values.toSet());
    for (final MapEntry(key: region, value: song) in songs.entries) {
      expect(song.inFlight, isTrue);
      if (region == WorldRegion.jungle) continue;
      expect(song.region, region);
      final bytes = File('assets/${song.asset}').readAsBytesSync();
      expect(String.fromCharCodes(bytes.take(4)), 'OggS', reason: '$song');
      expect(bytes.length, greaterThan(500000), reason: '$song');
    }
    expect(
      SkyMusic.values.map((m) => m.asset).toSet(),
      hasLength(SkyMusic.values.length),
      reason: 'every song is its own file',
    );
    expect(SkyMusic.menu.inFlight, isFalse);
    expect(SkyMusic.boss.inFlight, isFalse);
  });

  test('a region\'s song gives way to boss music and comes back', () async {
    final host = AndroidAudioHost()..install();
    final audio = SkyAudio();
    addTearDown(audio.dispose);
    await audio.configure(
      const GameSettings(effects: false),
      track: SkyMusic.newYork,
    );
    await waitForTrack(host, 'sky_new_york.ogg');
    final boss = SkyBoss(number: 1, x: 1)..age = 6;
    audio.syncBoss(boss);
    await waitForTrack(host, 'sky_boss.ogg');
    audio.syncBoss(null);
    await waitForTrack(host, 'sky_new_york.ogg');
    await audio.stop();
    await audio.resumeMusic();
    await waitForTrack(host, 'sky_new_york.ogg');
  });

  test('an endless flight records when its latest boss flew off', () {
    final sim = flight();
    expect(sim.bossLeftAt, isNull);
    expect(SkyAudio.tourSong(sim), isNull);
    defeat(sim);
    final left = sim.bossLeftAt!;
    expect(left, closeTo(sim.elapsed, .05));
    expect(
      SkyAudio.tourSong(sim),
      SkyMusic.flightOver(WorldTour.at(left).dominant),
    );
  });

  test(
    'after an endless boss leaves, the music plays the region showing',
    () async {
      final host = AndroidAudioHost()..install();
      final audio = SkyAudio();
      addTearDown(audio.dispose);
      await audio.configure(const GameSettings(effects: false));
      final sim = flight();
      audio.syncCombat(sim, silent: true);
      await waitForTrack(host, 'sky_flight.ogg');

      // The first boss leaves over New York, the tour's ninth region.
      sim.bossLeftAt = 8 * WorldTour.leg + 5;
      expect(WorldTour.at(sim.bossLeftAt!).dominant, WorldRegion.newYork);
      audio.syncCombat(sim, silent: true);
      await waitForTrack(host, 'sky_new_york.ogg');
      for (var frame = 0; frame < 50; frame++) {
        audio.syncCombat(sim, silent: true);
      }
      await drainAudio();
      expect(
        host.loads.where((s) => s.endsWith('sky_new_york.ogg')),
        hasLength(1),
        reason: 'the region song starts once, not every frame',
      );

      // The next boss brings its own music, and leaves over the jungle on the
      // tour's second lap, which keeps the flight's song.
      sim.boss = SkyBoss(number: 2, x: 1)..age = 6;
      audio.syncCombat(sim, silent: true);
      await waitForTrack(host, 'sky_boss.ogg');
      sim.boss = null;
      sim.bossLeftAt = WorldTour.loop + 5;
      audio.syncCombat(sim, silent: true);
      await waitForTrack(host, 'sky_flight.ogg');

      // A new flight starts on the flight's song again.
      sim.bossLeftAt = 8 * WorldTour.leg + 5;
      audio.syncCombat(sim, silent: true);
      await waitForTrack(host, 'sky_new_york.ogg');
      audio.syncCombat(flight(), silent: true);
      await waitForTrack(host, 'sky_flight.ogg');
    },
  );

  test('a campaign level keeps its region\'s song after its boss', () {
    final sim = levelFlight(Campaign.level('1-3')!)..bossLeftAt = 100;
    expect(SkyAudio.tourSong(sim), isNull);
  });
}
