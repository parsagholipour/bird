import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/campaign_story.dart';
import 'package:push_up_bird/game/campaign_voices.dart';
import 'package:push_up_bird/l10n/l10n.dart';
import 'package:push_up_bird/l10n/language_providers.dart';
import 'package:push_up_bird/l10n/pseudo.dart';

void main() {
  tearDown(L10n.debugReset);

  group('AppLanguage contract (l10n-ws/BRIEF.md)', () {
    test('values, tags, slugs and voice ranks', () {
      expect(AppLanguage.values.map((l) => l.name), [
        'en', 'es419', 'ptBR', 'id', 'fr', 'de', //
        'ja', 'ko', 'tr', 'zhHant', 'ru', 'ar',
      ]);
      expect(AppLanguage.values.map((l) => l.tag), [
        'en', 'es-419', 'pt-BR', 'id', 'fr', 'de', //
        'ja', 'ko', 'tr', 'zh-Hant', 'ru', 'ar',
      ]);
      expect(AppLanguage.values.map((l) => l.slug), [
        'en', 'es_419', 'pt_br', 'id', 'fr', 'de', //
        'ja', 'ko', 'tr', 'zh_hant', 'ru', 'ar',
      ]);
      expect(AppLanguage.values.map((l) => l.voiceRank), [
        0, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, //
      ]);
      expect(
        [
          for (final l in AppLanguage.values)
            if (l.isRtl) l,
        ],
        [AppLanguage.ar],
      );
      expect(AppLanguage.ar.textDirection, TextDirection.rtl);
      expect(AppLanguage.de.textDirection, TextDirection.ltr);
      for (final l in AppLanguage.values) {
        expect(l.nativeName, isNotEmpty);
        expect(l.englishName, isNotEmpty);
        expect(AppLanguage.fromTag(l.tag), l);
        expect(AppLanguage.fromTag(l.slug), l);
      }
    });

    test('locales are the ones gen-l10n and Material know', () {
      expect(AppLanguage.es419.locale, const Locale('es', '419'));
      expect(AppLanguage.ptBR.locale, const Locale('pt', 'BR'));
      expect(
        AppLanguage.zhHant.locale,
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      );
      expect(AppLanguage.ar.locale, const Locale('ar'));
      for (final l in AppLanguage.values) {
        expect(L10n.supportedLocales, contains(l.locale));
        // Every language has its own strings class (English until
        // translated) rather than a silent fallback to another language.
        expect(
          lookupAppLocalizations(l.locale).localeName,
          l.locale.toString(),
        );
      }
      expect(L10n.supportedLocales, contains(pseudoLocale));
      expect(
        AppLocalizations.supportedLocales.toSet(),
        containsAll(L10n.supportedLocales),
      );
    });
  });

  group('device mapping', () {
    AppLanguage? one(String tag) {
      final parts = tag.split('-');
      String? script, country;
      for (final part in parts.skip(1)) {
        if (part.length == 4) {
          script = part;
        } else {
          country = part;
        }
      }
      return AppLanguage.forLocale(
        Locale.fromSubtags(
          languageCode: parts.first,
          scriptCode: script,
          countryCode: country,
        ),
      );
    }

    test('regional variants map to the one we ship', () {
      expect(one('es-ES'), AppLanguage.es419);
      expect(one('es-MX'), AppLanguage.es419);
      expect(one('es'), AppLanguage.es419);
      expect(one('pt-PT'), AppLanguage.ptBR);
      expect(one('pt-BR'), AppLanguage.ptBR);
      expect(one('en-GB'), AppLanguage.en);
      expect(one('fr-CA'), AppLanguage.fr);
      expect(one('de-AT'), AppLanguage.de);
      expect(one('in-ID'), AppLanguage.id); // Android's legacy code
      expect(one('ar-EG'), AppLanguage.ar);
      expect(one('ru-UA'), AppLanguage.ru);
    });

    test('Chinese follows its script', () {
      expect(one('zh-TW'), AppLanguage.zhHant);
      expect(one('zh-HK'), AppLanguage.zhHant);
      expect(one('zh-MO'), AppLanguage.zhHant);
      expect(one('zh-Hant-CN'), AppLanguage.zhHant);
      expect(one('zh-Hant'), AppLanguage.zhHant);
      expect(one('zh-CN'), isNull);
      expect(one('zh-Hans-HK'), isNull);
      expect(one('zh-SG'), isNull);
      expect(one('zh'), isNull);
    });

    test('the first language we speak wins, else English', () {
      expect(
        AppLanguage.forDevice(const [Locale('it'), Locale('fr', 'FR')]),
        AppLanguage.fr,
      );
      expect(
        AppLanguage.forDevice(const [Locale('zh', 'CN'), Locale('ja')]),
        AppLanguage.ja,
      );
      // Dropped from the program (2026-10-07): Hindi, Thai, Vietnamese.
      for (final tag in ['hi', 'th', 'vi', 'it', 'pl', 'nl']) {
        expect(AppLanguage.forDevice([Locale(tag)]), AppLanguage.en);
      }
      expect(AppLanguage.forDevice(const []), AppLanguage.en);
    });
  });

  group('English fallback for missing translations', () {
    test('an untranslated message reads in English in every language', () {
      final en = lookupAppLocalizations(const Locale('en'));
      for (final l in AppLanguage.values) {
        final strings = lookupAppLocalizations(l.locale);
        // Until translators fill the ARBs every message is English; once
        // they do, a key they skip still is (gen-l10n's template fallback).
        expect(strings.region_jungle, isNotEmpty);
        expect(strings.calloutNiceShotPoints(5), contains('5'));
        if (strings.settingsTitle == en.settingsTitle) {
          expect(strings.languageSystemDefault, en.languageSystemDefault);
        }
      }
    });

    test('the pseudo-locale stretches and accents every message', () {
      final pseudo = lookupAppLocalizations(pseudoLocale);
      final en = lookupAppLocalizations(const Locale('en'));
      expect(pseudo.settingsTitle, startsWith('['));
      expect(pseudo.settingsTitle, endsWith(']'));
      expect(
        pseudo.settingsTitle.length,
        greaterThan(en.settingsTitle.length * 1.3),
      );
      expect(pseudo.calloutNiceShotPoints(7), contains('+7'));
      expect(pseudo.calloutGates(20), contains('20'));
      expect(pseudoLocalize('Hello'), startsWith('[Héé'));
    });

    test(
      'context.l10n falls back to the global strings without a delegate',
      () {
        L10n.apply(AppLanguage.en, locale: pseudoLocale);
        expect(L10n.strings.settingsReset, startsWith('['));
        expect(L10n.language.value, AppLanguage.en);
        L10n.apply(AppLanguage.ar);
        expect(L10n.textDirection, TextDirection.rtl);
        expect(L10n.strings.localeName, 'ar');
        L10n.debugReset();
        expect(L10n.strings.settingsReset, 'Reset local progress');
      },
    );

    testWidgets('context.l10n without a delegate', (tester) async {
      late String title;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) {
              title = context.l10n.settingsTitle;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(title, 'Make yourself at home.');
    });

    test('counts group the local way, always in Western digits', () {
      String count(AppLanguage l) =>
          lookupAppLocalizations(l.locale).formatCount(12345);
      expect(count(AppLanguage.en), '12,345');
      expect(count(AppLanguage.de), '12.345');
      expect(count(AppLanguage.fr), '12\u00a0345');
      expect(count(AppLanguage.ar), '12,345');
      for (final l in AppLanguage.values) {
        expect(count(l), matches(RegExp(r'^12\D?345$')), reason: l.tag);
      }
    });

    test('Turkish capitals keep their dots', () {
      L10n.apply(AppLanguage.tr);
      expect(L10n.upper('sesler ve ışık'), 'SESLER VE IŞIK');
      expect(L10n.upper('ilk'), 'İLK');
      L10n.apply(AppLanguage.de);
      expect(L10n.upper('ilk'), 'ILK');
    });

    test('a cache handed to L10n.cache empties on a language change', () {
      final cache = L10n.cache(<String, int>{'x': 1});
      L10n.apply(AppLanguage.fr);
      expect(cache, isEmpty);
    });
  });

  group('language persistence', () {
    late SqliteProgressRepository repo;
    setUp(() {
      repo = SqliteProgressRepository(
        ProgressDatabase(NativeDatabase.memory()),
      );
    });
    tearDown(() => repo.close());

    test('the choice saves, follows the device when cleared, and survives '
        'a reset', () async {
      expect((await repo.load()).settings.language, isNull);
      await repo.setLanguage(AppLanguage.de);
      expect((await repo.load()).settings.language, AppLanguage.de);
      await repo.setLanguage(AppLanguage.zhHant);
      expect((await repo.load()).settings.language, AppLanguage.zhHant);
      await repo.reset();
      expect((await repo.load()).settings.language, AppLanguage.zhHant);
      await repo.setLanguage(null);
      expect((await repo.load()).settings.language, isNull);
    });

    test('the providers: the choice wins, else the device', () async {
      final container = ProviderContainer(
        overrides: [
          progressRepositoryProvider.overrideWithValue(repo),
          deviceLocalesProvider.overrideWith(_JapanesePhone.new),
        ],
      );
      addTearDown(container.dispose);
      await container.read(progressProvider.future);
      expect(container.read(appLanguageProvider), AppLanguage.ja);
      expect(container.read(appLocaleProvider), const Locale('ja'));
      await container
          .read(progressProvider.notifier)
          .setLanguage(AppLanguage.ar);
      expect(container.read(languageChoiceProvider), AppLanguage.ar);
      expect(container.read(appLanguageProvider), AppLanguage.ar);
      await container.read(progressProvider.notifier).setLanguage(null);
      expect(container.read(appLanguageProvider), AppLanguage.ja);
      container.read(deviceLocalesProvider.notifier).update(const [
        Locale('pt', 'PT'),
      ]);
      expect(container.read(appLanguageProvider), AppLanguage.ptBR);
    });
  });

  group('story captions', () {
    final scene = CampaignStory.scenes.firstWhere(
      (s) => s.lines.any((l) => l.speaker == StorySpeaker.courier),
    );
    final courier = scene.lines.indexWhere(
      (l) => l.speaker == StorySpeaker.courier,
    );
    final level = Campaign.levels.first;

    test('a caption is found by clip, per bird, else English', () {
      final pip = CampaignVoices.lineName(scene, courier, bird: 0);
      final orbit = CampaignVoices.lineName(scene, courier, bird: 3);
      final captions = StoryCaptions.of(AppLanguage.de, {
        pip: 'Pip sagt es.',
        CampaignVoices.thanksName(level): 'Danke!',
      });
      expect(captions.line(scene, courier, bird: 0), 'Pip sagt es.');
      // Orbit has no caption of its own: another bird's words, not English.
      expect(orbit, isNot(pip));
      expect(captions.line(scene, courier, bird: 3), 'Pip sagt es.');
      expect(captions.thanks(level), 'Danke!');
      final other = scene.lines.indexWhere(
        (l) => l.speaker != StorySpeaker.courier,
      );
      expect(captions.line(scene, other, bird: 0), scene.lines[other].text);
      expect(
        StoryCaptions.english.line(scene, courier, bird: 1),
        scene.lines[courier].text,
      );
    });

    test('the loader reads the bundle and falls back to English', () async {
      final bundle = _Bundle({
        StoryCaptions.indexAsset: jsonEncode({
          'languages': ['de'],
        }),
        StoryCaptions.assetFor(AppLanguage.de): jsonEncode({
          '@@language': 'de',
          CampaignVoices.thanksName(level): 'Danke!',
        }),
      });
      final de = await StoryCaptions.load(AppLanguage.de, bundle: bundle);
      expect(de.language, AppLanguage.de);
      expect(de.length, 1);
      expect(de.thanks(level), 'Danke!');
      // Not in the index, or no index at all: English, no throw.
      final fr = await StoryCaptions.load(AppLanguage.fr, bundle: bundle);
      expect(fr.thanks(level), level.delivery.thanks);
      final none = await StoryCaptions.load(
        AppLanguage.fr,
        bundle: _Bundle(const {}),
      );
      expect(none.length, 0);
      // The real bundle ships an index and the translated captions.
      final real = await StoryCaptions.load(AppLanguage.ja);
      expect(real.thanks(level), isNotEmpty);
    });

    test('pseudo captions cover every line and thank-you', () {
      final pseudo = StoryCaptions.pseudo();
      expect(pseudo.line(scene, courier, bird: 2), startsWith('['));
      expect(pseudo.thanks(level), startsWith('['));
    });
  });
}

class _JapanesePhone extends DeviceLocales {
  @override
  List<Locale> build() => const [Locale('ja', 'JP')];
}

class _Bundle extends CachingAssetBundle {
  _Bundle(this.files);
  final Map<String, String> files;

  @override
  Future<ByteData> load(String key) async {
    final text = files[key];
    if (text == null) throw FlutterError('missing $key');
    return ByteData.sublistView(utf8.encode(text));
  }
}
