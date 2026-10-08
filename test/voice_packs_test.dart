import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/campaign_story.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/campaign_voice_clips.dart';
import 'package:push_up_bird/game/campaign_voices.dart';
import 'package:push_up_bird/game/flight_voice_clips.dart';
import 'package:push_up_bird/game/flight_voice_director.dart';
import 'package:push_up_bird/game/flight_voices.dart';
import 'package:push_up_bird/game/voice_pack_seam_runtime.dart';
import 'package:push_up_bird/game/voice_packs.dart';
import 'package:push_up_bird/l10n/app_language.dart';
import 'package:push_up_bird/l10n/voice_pack_seam.dart';
import 'touch_combat_test.dart' show playing;

/// A test-only Spanish pack, never bundled: tool/l10n/prepare_localized_voices.py
/// made it from six English story takes and four in-flight takes renamed into
/// a pack (`--out test/fixtures/voice_pack`). Story: before-1-1-1,
/// before-1-1-2-pip, sprint-pip-woohoo, sprint-pip-turbo, before-5-8-4 (the
/// Dragon's name card), thanks-1-1. Flight: pip-takeoff-01 and -02 (two of
/// six), dragon-arrive-01 (one of three), pip-boss-dragon-01 (one of two).
const fixture = 'test/fixtures/voice_pack';

Map<String, dynamic> fixtureManifest() =>
    jsonDecode(File('$fixture/es_419/manifest.json').readAsStringSync())
        as Map<String, dynamic>;

ByteData bytes(String text) => ByteData.sublistView(utf8.encode(text));

/// An asset bundle holding [manifests] (asset key to JSON text).
VoiceAssetLoader loader(Map<String, String> manifests) => (key) async {
  final text = manifests[key];
  if (text == null) throw FlutterError('Unable to load asset: $key');
  return bytes(text);
};

String manifestOf(
  AppLanguage language, {
  Map<String, int> story = const {},
  Map<String, int> flight = const {},
}) => jsonEncode({
  'format': 1,
  'slug': language.slug,
  'story': {
    for (final MapEntry(:key, :value) in story.entries)
      key: {'ms': value, 'mouth': '0' * (value ~/ 50)},
  },
  'flight': {
    for (final MapEntry(:key, :value) in flight.entries)
      key: {'ms': value, 'mouth': '0' * (value ~/ 50), 'mood': 'happy'},
  },
});

/// A Play Store stand-in: an install makes the pack's manifest readable
/// unless told otherwise.
class FakeInstaller implements VoicePackInstaller {
  FakeInstaller(this.bundle);
  final Map<String, String> bundle;
  final installs = <String>[], uninstalls = <String>[];
  String? phaseNow;
  Object? error;
  bool deliver = true;
  Completer<void>? gate;

  @override
  Future<void> install(String component) async {
    installs.add(component);
    final gate = this.gate;
    if (gate != null) await gate.future;
    if (error != null) throw error!;
    if (deliver) {
      final slug = component.substring('voice_'.length);
      bundle['assets/voice/$slug/manifest.json'] = File(
        '$fixture/es_419/manifest.json',
      ).readAsStringSync().replaceAll('"es_419"', '"$slug"');
    }
  }

  @override
  Future<String?> phase(String component) async => phaseNow;

  @override
  Future<void> uninstall(String component) async => uninstalls.add(component);
}

VoicePacks packs({
  Map<String, String>? bundle,
  VoicePackInstaller? installer,
  Map<AppLanguage, FlightVoicePolicy> policies = const {},
  int minFlightLines = 1,
}) {
  final files = bundle ?? {};
  return VoicePacks(
    installer: installer ?? FakeInstaller(files),
    load: loader(files),
    policies: policies,
    minFlightLines: minFlightLines,
    startTimeout: const Duration(milliseconds: 120),
    installTimeout: const Duration(seconds: 5),
    pollEvery: const Duration(milliseconds: 10),
  );
}

/// The fixture as the installed Spanish pack.
Map<String, String> spanish() => {
  VoicePack.manifestKey(AppLanguage.es419): File(
    '$fixture/es_419/manifest.json',
  ).readAsStringSync(),
};

Future<VoicePacks> use(VoicePacks packs, AppLanguage language) async {
  VoicePacks.instance = packs;
  await packs.activate(language);
  return packs;
}

/// The bank as lib/game/flight_voices.dart built it before voice packs.
FlightVoiceBank englishAsBefore() {
  VoiceClip? story(String name) {
    final ms = campaignVoiceClips[name];
    return ms == null ? null : VoiceClip(name, 'audio/story/$name.ogg', ms);
  }

  return FlightVoiceBank.of(
    flightVoiceClips,
    extra: {
      for (final bird in CampaignVoices.birds)
        '$bird-sprint': [
          for (final call in const ['woohoo', 'turbo', 'gravity', 'whee'])
            ?story('sprint-$bird-$call'),
        ],
      for (final chapter in Campaign.chapters)
        '${FlightVoices.bossKey(chapter.boss)}-card': [
          ?story('before-${chapter.bossLevel.id}-4'),
        ],
      '${FlightVoices.bossKey(BossKind.kingCoo)}-card': [
        ?story('before-3-2-6'),
      ],
      '${FlightVoices.bossKey(BossKind.searchlightGargoyle)}-card': [
        ?story('before-3-4-4'),
      ],
      '${FlightVoices.bossKey(BossKind.neferhoo)}-card': [
        ?story('before-2-6-7'),
      ],
    },
  );
}

List<(String, String, int, String?, String?)> flat(FlightVoiceBank bank) => [
  for (final pool in bank.pools)
    for (final clip in bank[pool])
      (clip.name, clip.asset, clip.ms, clip.mouth, clip.mood),
];

void main() {
  tearDown(() => VoicePacks.instance = VoicePacks());

  group('English is unchanged', () {
    test('the flight draws from the very bank it always had', () {
      expect(VoicePacks.instance.language, AppLanguage.en);
      expect(VoicePacks.instance.flightSource, FlightVoiceSource.english);
      expect(identical(FlightVoices.current, FlightVoices.recorded), isTrue);
      final before = englishAsBefore();
      expect(FlightVoices.recorded.pools.toList(), before.pools.toList());
      expect(flat(FlightVoices.recorded), flat(before));
      for (final clip in flat(FlightVoices.recorded)) {
        expect(clip.$4, isNull, reason: 'English faces come from the tables');
        expect(clip.$5, isNull);
      }
    });

    test('a flight without a bank uses it, line for line', () {
      List<String?> said(FlightVoiceBank? bank) {
        final sim = playing();
        final voices = FlightVoices(
          talk: 1,
          bird: 0,
          mode: PlayMode.touch,
          bank: bank,
          random: Random(9),
        );
        voices.update(sim, mute: true);
        final out = <String?>[];
        for (var i = 0; i < 40; i++) {
          sim.elapsed += 3;
          if (i == 5) sim.hearts = 2;
          if (i == 9) {
            sim.boss = SkyBoss(number: 1, x: 1.2, kind: BossKind.dragon)
              ..age = 1;
          }
          out.add(voices.update(sim)?.clip.asset);
        }
        return out;
      }

      expect(said(null), said(FlightVoices.recorded));
      expect(said(null).nonNulls, isNotEmpty);
    });

    test(
      'story clips are the English assets, whatever packs are loaded',
      () async {
        final scene = CampaignStory.prologue;
        final english = [
          for (var i = 0; i < scene.lines.length; i++)
            CampaignVoices.line(scene, i, bird: 0),
        ];
        // A Spanish pack loaded and then left for English changes nothing.
        final p = await use(packs(bundle: spanish()), AppLanguage.es419);
        await p.activate(AppLanguage.en);
        expect([
          for (var i = 0; i < scene.lines.length; i++)
            CampaignVoices.line(scene, i, bird: 0),
        ], english);
        expect(english[1], 'audio/story/before-1-1-1.ogg');
        expect(
          CampaignVoices.length('audio/story/before-1-1-1.ogg'),
          Duration(milliseconds: campaignVoiceClips['before-1-1-1']!),
        );
        expect(identical(FlightVoices.current, FlightVoices.recorded), isTrue);
      },
    );
  });

  group('story in a language with a pack', () {
    test(
      'a clip the pack has plays it; any other falls back to English',
      () async {
        await use(packs(bundle: spanish()), AppLanguage.es419);
        final scene = CampaignStory.prologue;
        expect(
          CampaignVoices.line(scene, 0, bird: 0),
          'audio/story/before-1-1-0.ogg',
        );
        final localized = CampaignVoices.line(scene, 1, bird: 0)!;
        expect(localized, 'voice/es_419/story/before-1-1-1.ogg');
        final ms = fixtureManifest()['story']['before-1-1-1']['ms'] as int;
        expect(CampaignVoices.length(localized), Duration(milliseconds: ms));
        // The courier's line: Pip's take is in the pack, Minty's is not.
        expect(
          CampaignVoices.line(scene, 2, bird: 0),
          'voice/es_419/story/before-1-1-2-pip.ogg',
        );
        expect(
          CampaignVoices.line(scene, 2, bird: 2),
          'audio/story/before-1-1-2-minty.ogg',
        );
        final level = Campaign.levels.firstWhere((l) => l.id == '1-1');
        expect(
          CampaignVoices.thanks(level),
          'voice/es_419/story/thanks-1-1.ogg',
        );
        expect(CampaignVoices.sprints(0), [
          'voice/es_419/story/sprint-pip-woohoo.ogg',
          'voice/es_419/story/sprint-pip-turbo.ogg',
          'audio/story/sprint-pip-gravity.ogg',
          'audio/story/sprint-pip-whee.ogg',
        ]);
      },
    );

    test('a clip pending in English stays silent in every language', () async {
      await use(packs(bundle: spanish()), AppLanguage.es419);
      final scene = CampaignStory.scene('before-3-2')!;
      expect(campaignVoiceClips, isNot(contains('before-3-2-0')));
      expect(CampaignVoices.line(scene, 0, bird: 0), isNull);
    });

    test('until the pack is in, every clip is English', () async {
      final bundle = <String, String>{};
      final installer = FakeInstaller(bundle)..gate = Completer();
      final p = packs(bundle: bundle, installer: installer);
      VoicePacks.instance = p;
      final done = p.activate(AppLanguage.es419);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(p.status(AppLanguage.es419).state, VoicePackState.downloading);
      expect(
        CampaignVoices.line(CampaignStory.prologue, 1, bird: 0),
        'audio/story/before-1-1-1.ogg',
      );
      installer.gate!.complete();
      await done;
      expect(
        CampaignVoices.line(CampaignStory.prologue, 1, bird: 0),
        'voice/es_419/story/before-1-1-1.ogg',
      );
    });
  });

  group('flight in a language with a pack', () {
    test('the pools hold only that language\'s lines', () async {
      await use(packs(bundle: spanish()), AppLanguage.es419);
      final packs0 = VoicePacks.instance;
      expect(packs0.flightSource, FlightVoiceSource.pack);
      final bank = FlightVoices.current;
      expect(identical(bank, FlightVoices.current), isTrue, reason: 'cached');
      for (final clip in flat(bank)) {
        expect(clip.$2, startsWith('voice/es_419/'), reason: clip.$1);
        expect(clip.$4, isNotNull, reason: 'its own mouth: ${clip.$1}');
      }
      expect(bank['pip-takeoff'].map((c) => c.name), [
        'pip-takeoff-01',
        'pip-takeoff-02',
      ]);
      expect(bank['dragon-arrive'].single.name, 'dragon-arrive-01');
      expect(bank['pip-hit'], isEmpty);
      expect(bank['pip-sprint'].map((c) => c.name), [
        'sprint-pip-woohoo',
        'sprint-pip-turbo',
      ]);
      expect(
        bank['dragon-card'].single.asset,
        'voice/es_419/story/before-5-8-4.ogg',
      );
      expect(bank['baron-card'], isEmpty, reason: 'no English stand-in');
    });

    test(
      'an empty pool is silence, and the rest keep their freshness',
      () async {
        await use(packs(bundle: spanish()), AppLanguage.es419);
        final director = FlightVoiceDirector(
          talk: 1,
          bank: FlightVoices.current,
          memory: FlightVoiceMemory(),
          random: Random(3),
        );
        final said = <String>[];
        for (var t = 0.0; t < 2000; t += 20) {
          final line = director.offer(VoiceCue.of('takeoff', 'pip-takeoff'), t);
          if (line != null) said.add(line.clip.name);
          expect(director.offer(VoiceCue.of('hit', 'pip-hit'), t + 10), isNull);
        }
        // Two lines, then each rests 24 lines: none of which can come.
        expect(said.toSet(), {'pip-takeoff-01', 'pip-takeoff-02'});
        expect(said, hasLength(2));
        expect(FlightVoiceDirector.rest(2), 24);
      },
    );

    test('the bird takes off in Spanish with its Spanish face', () async {
      await use(packs(bundle: spanish()), AppLanguage.es419);
      var clock = 50.0;
      final sim = playing();
      final voices = FlightVoices(
        talk: 1,
        bird: 0,
        mode: PlayMode.touch,
        random: Random(1),
        clock: () => clock,
      );
      voices.update(sim, mute: true);
      sim.elapsed += 1;
      final line = voices.update(sim)!;
      expect(line.clip.asset, 'voice/es_419/flight/${line.clip.name}.ogg');
      final take = fixtureManifest()['flight'][line.clip.name] as Map;
      final curve = take['mouth'] as String;
      expect(line.clip.ms, take['ms']);
      for (var frame = 0; frame < curve.length; frame += 7) {
        clock = 50 + frame * .05 + .01;
        expect(voices.speech!.mouth, int.parse(curve[frame]));
      }
      expect(voices.speech!.mood.name, take['mood'] ?? 'plain');
    });

    test(
      'any share of the lines, from none to all, keeps to the pack',
      () async {
        final names = flightVoiceClips.keys.toList()..shuffle(Random(4));
        for (final share in [0.0, .001, .2, .3, .5, 1.0]) {
          final kept = names.take((names.length * share).ceil()).toList();
          final bundle = {
            VoicePack.manifestKey(AppLanguage.ja): manifestOf(
              AppLanguage.ja,
              flight: {for (final name in kept) name: flightVoiceClips[name]!},
            ),
          };
          for (final policy in FlightVoicePolicy.values) {
            await use(
              packs(bundle: bundle, policies: {AppLanguage.ja: policy}),
              AppLanguage.ja,
            );
            final bank = FlightVoices.current;
            if (kept.isEmpty) {
              expect(
                VoicePacks.instance.flightSource,
                policy == FlightVoicePolicy.english
                    ? FlightVoiceSource.english
                    : FlightVoiceSource.silent,
              );
              if (policy == FlightVoicePolicy.english) {
                expect(identical(bank, FlightVoices.recorded), isTrue);
              } else {
                expect(flat(bank), isEmpty);
              }
              continue;
            }
            final lines = flat(bank).map((c) => c.$1).toSet();
            expect(lines, kept.toSet(), reason: 'share $share');
            for (final pool in bank.pools) {
              expect(
                bank[pool].length,
                lessThanOrEqualTo(FlightVoices.recorded[pool].length),
              );
            }
          }
        }
      },
    );

    test('too few lines of its own: the language\'s policy speaks', () async {
      final bundle = {
        VoicePack.manifestKey(AppLanguage.ar): manifestOf(
          AppLanguage.ar,
          flight: {'pip-takeoff-01': 1000, 'pip-hit-01': 900},
        ),
      };
      await use(packs(bundle: bundle, minFlightLines: 3), AppLanguage.ar);
      expect(VoicePacks.instance.flightSource, FlightVoiceSource.english);
      await use(
        packs(
          bundle: bundle,
          minFlightLines: 3,
          policies: {AppLanguage.ar: FlightVoicePolicy.silent},
        ),
        AppLanguage.ar,
      );
      expect(VoicePacks.instance.flightSource, FlightVoiceSource.silent);
      await use(packs(bundle: bundle, minFlightLines: 2), AppLanguage.ar);
      expect(VoicePacks.instance.flightSource, FlightVoiceSource.pack);
    });

    test('while the pack is missing, the policy speaks too', () async {
      final bundle = <String, String>{};
      final installer = FakeInstaller(bundle)..gate = Completer();
      VoicePacks.instance = packs(
        bundle: bundle,
        installer: installer,
        policies: {AppLanguage.ko: FlightVoicePolicy.silent},
      );
      unawaited(VoicePacks.instance.activate(AppLanguage.ko));
      expect(VoicePacks.instance.flightSource, FlightVoiceSource.silent);
      VoicePacks.instance = packs(bundle: bundle, installer: installer);
      unawaited(VoicePacks.instance.activate(AppLanguage.ko));
      expect(identical(FlightVoices.current, FlightVoices.recorded), isTrue);
      installer.gate!.complete();
    });

    test('lines the English script no longer has are left out', () {
      final pack = VoicePack.parse(
        AppLanguage.fr,
        manifestOf(
          AppLanguage.fr,
          flight: {'pip-takeoff-01': 1000, 'pip-retired-01': 1000},
        ),
      );
      expect(pack.flight.keys, ['pip-takeoff-01']);
      expect(
        () => VoicePack.parse(AppLanguage.de, manifestOf(AppLanguage.fr)),
        throwsFormatException,
      );
      expect(
        () => VoicePack.parse(AppLanguage.fr, '{"format": 2}'),
        throwsFormatException,
      );
    });
  });

  group('pack states', () {
    test('English is built in and installs nothing', () async {
      final bundle = <String, String>{};
      final installer = FakeInstaller(bundle);
      final p = await use(
        packs(bundle: bundle, installer: installer),
        AppLanguage.en,
      );
      expect(p.status(AppLanguage.en).state, VoicePackState.installed);
      expect(p.status(AppLanguage.en).builtIn, isTrue);
      expect(installer.installs, isEmpty);
      expect(p.status(AppLanguage.de).state, VoicePackState.absent);
    });

    test('a pack inside the app is found without a download', () async {
      final bundle = spanish();
      final installer = FakeInstaller(bundle);
      final p = await use(
        packs(bundle: bundle, installer: installer),
        AppLanguage.es419,
      );
      expect(installer.installs, isEmpty);
      final status = p.status(AppLanguage.es419);
      expect(status.state, VoicePackState.installed);
      expect(status.storyClips, 6);
      expect(status.flightLines, 4);
    });

    test('absent, downloading with Play\'s steps, then installed', () async {
      final bundle = <String, String>{};
      final installer = FakeInstaller(bundle)
        ..gate = Completer()
        ..phaseNow = 'pending';
      final p = packs(bundle: bundle, installer: installer);
      final seen = <VoicePackInfo>[];
      p.addListener(() => seen.add(p.status(AppLanguage.fr)));
      expect(p.status(AppLanguage.fr).state, VoicePackState.absent);
      final first = p.activate(AppLanguage.fr);
      final second = p.activate(AppLanguage.fr);
      await Future<void>.delayed(const Duration(milliseconds: 40));
      installer.phaseNow = 'downloading:50/200';
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(p.status(AppLanguage.fr).progress, .25);
      installer.gate!.complete();
      await Future.wait([first, second]);
      expect(installer.installs, ['voice_fr'], reason: 'one install at a time');
      final states = seen.map((s) => (s.state, s.phase)).toSet().toList();
      expect(states, [
        (VoicePackState.absent, null),
        (VoicePackState.downloading, null),
        (VoicePackState.downloading, 'pending'),
        (VoicePackState.downloading, 'downloading'),
        (VoicePackState.installed, null),
      ]);
      expect(p.status(AppLanguage.fr).flightLines, 4);
    });

    test('a failed download can be retried', () async {
      final bundle = <String, String>{};
      final installer = FakeInstaller(bundle)
        ..error = PlatformException(code: 'DeferredComponent Install failure');
      final p = await use(
        packs(bundle: bundle, installer: installer),
        AppLanguage.tr,
      );
      expect(p.status(AppLanguage.tr).state, VoicePackState.failed);
      expect(p.status(AppLanguage.tr).error, contains('Install failure'));
      expect(p.flightSource, FlightVoiceSource.english);
      installer.error = null;
      await p.retry();
      expect(p.status(AppLanguage.tr).state, VoicePackState.installed);
      expect(installer.installs, ['voice_tr', 'voice_tr']);
    });

    test('a download that never starts, or that Play fails, fails', () async {
      final bundle = <String, String>{};
      final silent = FakeInstaller(bundle)..gate = Completer();
      final p = await use(
        packs(bundle: bundle, installer: silent),
        AppLanguage.ru,
      );
      expect(p.status(AppLanguage.ru).error, 'the download did not start');
      final failing = FakeInstaller(bundle)
        ..gate = Completer()
        ..phaseNow = 'failed';
      final q = await use(
        packs(bundle: bundle, installer: failing),
        AppLanguage.ru,
      );
      expect(q.status(AppLanguage.ru).state, VoicePackState.failed);
      expect(q.status(AppLanguage.ru).error, contains('failed'));
      final asking = FakeInstaller(bundle)
        ..gate = Completer()
        ..phaseNow = 'requiresUserConfirmation';
      final r = await use(
        packs(bundle: bundle, installer: asking),
        AppLanguage.ru,
      );
      expect(r.status(AppLanguage.ru).state, VoicePackState.failed);
    });

    test(
      'an install that brings no manifest, or a broken one, fails',
      () async {
        final bundle = <String, String>{};
        final empty = FakeInstaller(bundle)..deliver = false;
        final p = await use(
          packs(bundle: bundle, installer: empty),
          AppLanguage.de,
        );
        expect(p.status(AppLanguage.de).state, VoicePackState.failed);
        final broken = {VoicePack.manifestKey(AppLanguage.de): '{"story": 3'};
        final installer = FakeInstaller(broken);
        final q = await use(
          packs(bundle: broken, installer: installer),
          AppLanguage.de,
        );
        expect(q.status(AppLanguage.de).state, VoicePackState.failed);
        expect(
          installer.installs,
          isEmpty,
          reason: 'a download would not fix it',
        );
        expect(q.pack, isNull);
        expect(q.flightSource, FlightVoiceSource.english);
      },
    );

    test(
      'an earlier language\'s pack can be removed, never the active one',
      () async {
        final bundle = spanish();
        final installer = FakeInstaller(bundle);
        final p = await use(
          packs(bundle: bundle, installer: installer),
          AppLanguage.es419,
        );
        await p.remove(AppLanguage.es419);
        expect(p.status(AppLanguage.es419).state, VoicePackState.installed);
        await p.activate(AppLanguage.en);
        await p.remove(AppLanguage.es419);
        expect(p.status(AppLanguage.es419).state, VoicePackState.absent);
        expect(installer.uninstalls, ['voice_es_419']);
        // Its assets may still read until Play removes it: choosing it again
        // asks Play to keep it.
        await p.activate(AppLanguage.es419);
        expect(installer.installs, ['voice_es_419']);
        expect(p.status(AppLanguage.es419).state, VoicePackState.installed);
      },
    );

    test('the voices follow the game\'s language', () async {
      final language = ValueNotifier(AppLanguage.en);
      final bundle = spanish();
      final p = packs(bundle: bundle);
      VoicePacks.instance = p..follow(language);
      expect(p.language, AppLanguage.en);
      language.value = AppLanguage.es419;
      await Future<void>.delayed(Duration.zero);
      await p.ensure(AppLanguage.es419);
      expect(p.language, AppLanguage.es419);
      expect(p.pack?.language, AppLanguage.es419);
      language.value = AppLanguage.en;
      expect(p.pack, isNull);
    });

    test('widgets see each change of a pack', () async {
      final bundle = <String, String>{};
      final installer = FakeInstaller(bundle)..gate = Completer();
      final p = packs(bundle: bundle, installer: installer);
      final container = ProviderContainer(
        overrides: [voicePacksProvider.overrideWithValue(p)],
      );
      addTearDown(container.dispose);
      final seen = <VoicePackState>[];
      container.listen(
        voicePackInfoProvider(AppLanguage.id),
        (_, next) => seen.add(next.state),
        fireImmediately: true,
      );
      final done = p.activate(AppLanguage.id);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      installer.gate!.complete();
      await done;
      await Future<void>.delayed(Duration.zero);
      expect(seen.toSet().toList(), [
        VoicePackState.absent,
        VoicePackState.downloading,
        VoicePackState.installed,
      ]);
    });
  });

  group('the packs\' index and the picker', () {
    String index(Map<String, (int, int)> packs) => jsonEncode({
      'format': 1,
      'packs': {
        for (final MapEntry(:key, :value) in packs.entries)
          key: {'story': value.$1, 'flight': value.$2, 'bytes': 1000},
      },
    });

    test('an empty pack is never downloaded: English voices', () async {
      final bundle = {
        VoicePack.indexKey: index({'ko': (0, 0), 'fr': (372, 637)}),
      };
      final installer = FakeInstaller(bundle);
      final p = await use(
        packs(bundle: bundle, installer: installer),
        AppLanguage.ko,
      );
      expect(installer.installs, isEmpty);
      expect(p.status(AppLanguage.ko).state, VoicePackState.unrecorded);
      expect(
        voicePackView(p.status(AppLanguage.ko)).status,
        VoicePackStatus.englishVoices,
      );
      expect(p.flightSource, FlightVoiceSource.english);
      // A pack with takes is absent until downloaded, with its size known.
      final fr = p.status(AppLanguage.fr);
      expect(fr.state, VoicePackState.absent);
      expect((fr.storyClips, fr.flightLines, fr.bytes), (372, 637, 1000));
      expect(voicePackView(fr).status, VoicePackStatus.available);
      await p.ensure(AppLanguage.fr);
      expect(installer.installs, ['voice_fr']);
      expect(
        voicePackView(p.status(AppLanguage.fr)).status,
        VoicePackStatus.installed,
      );
    });

    test('Play\'s step and byte counts', () {
      expect(VoicePacks.step(null), (null, null));
      expect(VoicePacks.step('Requested'), ('requested', null));
      expect(VoicePacks.step('downloading:5/20'), ('downloading', .25));
      expect(VoicePacks.step('downloading:0/0'), ('downloading', null));
    });

    test('every state has its badge', () {
      VoicePackInfo info(VoicePackState state, {int story = 1}) =>
          VoicePackInfo(AppLanguage.de, state, storyClips: story);
      expect(
        voicePackView(VoicePacks().status(AppLanguage.en)).status,
        VoicePackStatus.none,
      );
      expect(
        voicePackView(info(VoicePackState.absent)).status,
        VoicePackStatus.available,
      );
      final downloading = voicePackView(
        VoicePackInfo(AppLanguage.de, VoicePackState.downloading, progress: .5),
      );
      expect(downloading.status, VoicePackStatus.downloading);
      expect(downloading.progress, .5);
      expect(
        voicePackView(info(VoicePackState.installed)).status,
        VoicePackStatus.installed,
      );
      expect(
        voicePackView(info(VoicePackState.installed, story: 0)).status,
        VoicePackStatus.englishVoices,
      );
      expect(
        voicePackView(info(VoicePackState.failed)).status,
        VoicePackStatus.failed,
      );
      expect(
        voicePackView(info(VoicePackState.unrecorded)).status,
        VoicePackStatus.englishVoices,
      );
    });

    test('the picker\'s choices reach the packs', () async {
      final bundle = spanish();
      final installer = FakeInstaller(bundle);
      final p = packs(bundle: bundle, installer: installer);
      final container = ProviderContainer(
        overrides: [
          voicePacksProvider.overrideWithValue(p),
          ...voicePackSeamOverrides,
        ],
      );
      addTearDown(container.dispose);
      final actions = container.read(voicePackActionsProvider);
      actions.badgeTapped(AppLanguage.de);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(installer.installs, ['voice_de'], reason: 'a download');
      expect(p.language, AppLanguage.en, reason: 'without switching');
      actions.languageChosen(null, AppLanguage.es419);
      await p.ensure(AppLanguage.es419);
      expect(p.language, AppLanguage.es419);
      expect(
        container.read(voicePackViewProvider(AppLanguage.es419)).status,
        VoicePackStatus.installed,
      );
    });
  });
}
