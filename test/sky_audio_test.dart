import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/audio.dart';
import 'package:push_up_bird/game/play_controller.dart';
import 'package:push_up_bird/game/sound_bank.dart';

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

  test('sprints play one of four voices without repeating the last', () async {
    final host = AndroidAudioHost()..install();
    var now = 0;
    final audio = SkyAudio(effectClock: () => now, random: Random(7));
    addTearDown(audio.dispose);
    await audio.configure(const GameSettings(music: false));
    final voicePaths = <String>[];
    for (var sprint = 0; sprint < 32; sprint++) {
      audio.effect('sprint');
      audio.effect('sprint'); // A duplicate cue cannot start another voice.
      for (var i = 0; i < 100 && voicePaths.length <= sprint; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 2));
        voicePaths
          ..clear()
          ..addAll(host.loads.where((path) => path.endsWith('.mp3')));
      }
      expect(voicePaths, hasLength(sprint + 1));
      now += 15000;
    }
    final chosen = voicePaths.map((path) => Uri.parse(path).path).toList();
    expect(chosen.map((path) => path.split('/').last).toSet(), {
      'sprint_03.mp3',
      'sprint_01.mp3',
      'sprint_08.mp3',
      'whee_04.mp3',
    });
    for (var i = 1; i < chosen.length; i++) {
      expect(chosen[i], isNot(chosen[i - 1]));
    }
    expect(
      host.sources.entries.where((entry) => entry.value.endsWith('.mp3')),
      hasLength(1),
    );
    await audio.stopEffects();
    expect(host.playing, isEmpty);
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
      practice: false,
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
}
