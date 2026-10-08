import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/game/campaign_voice_clips.dart';
import 'package:push_up_bird/game/flight_voice_clips.dart';
import 'package:push_up_bird/game/voice_packs.dart';
import 'package:push_up_bird/l10n/app_language.dart';

/// Every language with a voice pack: all but English.
final localized = [
  for (final language in AppLanguage.values)
    if (language != AppLanguage.en) language,
];

/// Checks a pack folder: a readable manifest whose every clip has its file
/// and a face as long as the take, and no file the manifest does not list.
void expectPack(Directory folder, AppLanguage language) {
  final manifest = File('${folder.path}/manifest.json');
  expect(manifest.existsSync(), isTrue, reason: manifest.path);
  final pack = VoicePack.parse(language, manifest.readAsStringSync());
  for (final (kind, takes, english) in [
    ('story', pack.story, campaignVoiceClips),
    ('flight', pack.flight, flightVoiceClips),
  ]) {
    for (final MapEntry(key: name, value: take) in takes.entries) {
      expect(english, contains(name), reason: '$kind/$name is no English clip');
      expect(
        File('${folder.path}/$kind/$name.ogg').existsSync(),
        isTrue,
        reason: '$kind/$name',
      );
      expect(take.mouth.length, closeTo(take.ms / 50, 3), reason: name);
      expect(take.mouth, matches(RegExp(r'^[0-3]*$')));
    }
    final files = Directory('${folder.path}/$kind');
    if (files.existsSync()) {
      for (final file in files.listSync()) {
        final name = file.uri.pathSegments.last.replaceAll('.ogg', '');
        expect(takes, contains(name), reason: 'stray ${file.path}');
      }
    }
  }
}

void main() {
  test('every language has a pack folder with a valid manifest', () {
    for (final language in localized) {
      expectPack(Directory('assets/voice/${language.slug}'), language);
    }
    final folders = Directory('assets/voice')
        .listSync()
        .whereType<Directory>()
        .map((d) => d.uri.pathSegments.where((s) => s.isNotEmpty).last)
        .toSet();
    expect(folders, {for (final l in localized) l.slug});
  });

  test('the packs\' index matches the packs', () {
    final index =
        jsonDecode(File('assets/voice/index.json').readAsStringSync())
            as Map<String, dynamic>;
    final packs = index['packs'] as Map<String, dynamic>;
    expect(packs.keys, [for (final l in localized) l.slug]);
    for (final language in localized) {
      final pack = VoicePack.parse(
        language,
        File('assets/voice/${language.slug}/manifest.json').readAsStringSync(),
      );
      final entry = packs[language.slug] as Map<String, dynamic>;
      expect(
        (entry['story'], entry['flight']),
        (pack.story.length, pack.flight.length),
        reason: 'run tool/l10n/prepare_localized_voices.py --wire',
      );
    }
  });

  test('the test-only pack is a valid pack, outside the app\'s assets', () {
    expectPack(Directory('test/fixtures/voice_pack/es_419'), AppLanguage.es419);
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, isNot(contains('test/fixtures')));
  });

  test('every pack is listed: the release state, no dev subset', () {
    // tool/l10n/dev_voice_packs.py --only/--none trims the packs a dev build
    // carries; the committed tree and every Play build list all of them.
    const restore =
        'dev subset of the voice packs: run '
        'python3 tool/l10n/dev_voice_packs.py --all before a release build';
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final settings = File('android/settings.gradle.kts').readAsStringSync();
    expect(pubspec, isNot(contains('voice-packs:dev-subset')), reason: restore);
    expect(settings, isNot(contains('voice-packs:dev-subset')), reason: restore);
    for (final language in localized) {
      final name = VoicePack.component(language);
      expect(pubspec, contains('    - name: $name\n'), reason: restore);
      expect(settings, contains('include(":$name")'), reason: restore);
    }
    // And `flutter build appbundle` refuses a subset (the Gradle guard).
    final app = File('android/app/build.gradle.kts').readAsStringSync();
    expect(app, contains('providers.gradleProperty("deferred-component-names")'));
    expect(app, contains('dev_voice_packs.py --all'));
  });

  test('pubspec makes each pack a deferred component of its own', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final block = RegExp(
      r'# voice-packs:begin\n(.*?)  # voice-packs:end',
      dotAll: true,
    ).firstMatch(pubspec)![1]!;
    final components = RegExp(
      r'- name: (\S+)\n      assets:\n((?:        - \S+\n)+)',
    ).allMatches(block).toList();
    expect(components.map((m) => m[1]), [
      for (final l in localized) VoicePack.component(l),
    ]);
    for (final (i, language) in localized.indexed) {
      final assets = RegExp(
        r'- (\S+)',
      ).allMatches(components[i][2]!).map((m) => m[1]).toList();
      final slug = language.slug;
      expect(assets.first, 'assets/voice/$slug/');
      for (final kind in ['story', 'flight']) {
        final folder = Directory('assets/voice/$slug/$kind');
        final has = folder.existsSync() && folder.listSync().isNotEmpty;
        expect(
          assets.contains('assets/voice/$slug/$kind/'),
          has,
          reason:
              '$slug/$kind: run tool/l10n/prepare_localized_voices.py --wire',
        );
      }
    }
    // Only the index sits in the base bundle's own asset list.
    final base = pubspec.substring(0, pubspec.indexOf('# voice-packs:begin'));
    expect(
      RegExp(r'assets/voice\S*').allMatches(base).map((m) => m[0]).toList(),
      ['assets/voice/index.json'],
    );
  });

  test('Android has a feature module per pack, and Play delivery', () {
    final settings = File('android/settings.gradle.kts').readAsStringSync();
    expect(settings, contains('id("com.android.dynamic-feature")'));
    final strings = File(
      'android/app/src/main/res/values/strings.xml',
    ).readAsStringSync();
    for (final language in localized) {
      final name = VoicePack.component(language);
      expect(settings, contains('include(":$name")'));
      final module = File('android/$name/src/main/AndroidManifest.xml');
      expect(module.readAsStringSync(), contains('<dist:on-demand />'));
      expect(module.readAsStringSync(), contains('@string/${name}Name'));
      final gradle = File('android/$name/build.gradle.kts').readAsStringSync();
      expect(gradle, contains('com.android.dynamic-feature'));
      expect(gradle, contains('deferred_assets'));
      // Flutter's deferred components check wants the title to be the name.
      expect(strings, contains('<string name="${name}Name">$name</string>'));
    }
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    // Not FlutterPlayStoreSplitApplication: Flutter's own manager is built
    // on Play Core 1.x (VoicePackDelivery.kt says why).
    expect(manifest, contains('android:name=".BeakboundApplication"'));
    final delivery = File(
      'android/app/src/main/kotlin/com/ravanix/push_up_bird/VoicePackDelivery.kt',
    ).readAsStringSync();
    expect(
      delivery,
      contains('class BeakboundApplication : SplitCompatApplication()'),
    );
    expect(
      delivery,
      contains('setDeferredComponentManager(VoicePackDelivery(this))'),
    );
    expect(manifest, contains('DeferredComponentManager.loadingUnitMapping'));
    final app = File('android/app/build.gradle.kts').readAsStringSync();
    expect(app, contains('com.google.android.play:feature-delivery:'));
    expect(app, contains('isMinifyEnabled = true'));
  });

  test('the mastering tool knows the same languages', () {
    final tool = File(
      'tool/l10n/prepare_localized_voices.py',
    ).readAsStringSync();
    final slugs = RegExp(
      r"^    '(\w+)': \('([\w-]+)', '(\w+)', (\d)\),$",
      multiLine: true,
    ).allMatches(tool).toList();
    expect(slugs.map((m) => m[1]), [for (final l in localized) l.slug]);
    for (final (i, language) in localized.indexed) {
      expect(slugs[i][2], language.tag);
      expect(int.parse(slugs[i][4]!), language.voiceRank);
    }
  });
}
