import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/progress_repository.dart' show birdNames;
import 'package:push_up_bird/domain/neferhoo.dart' show Neferhoo;
import 'package:push_up_bird/domain/sky_boss.dart' show BossKind;
import 'package:push_up_bird/domain/tracking.dart' show PlayMode;
import 'package:push_up_bird/domain/world_region.dart';
import 'package:push_up_bird/l10n/l10n.dart';
import 'package:push_up_bird/ui/theme.dart';

/// The font table and the domain's English twins stay in step with the
/// files the localization tools read (MASTER-PLAN.md).
void main() {
  tearDown(L10n.debugReset);
  final config =
      jsonDecode(File('tool/l10n/fonts.json').readAsStringSync())
          as Map<String, dynamic>;

  test('LanguageFonts matches tool/l10n/fonts.json', () {
    final languages = config['languages'] as Map<String, dynamic>;
    expect(languages.keys, AppLanguage.values.map((l) => l.slug));
    for (final language in AppLanguage.values) {
      final want = languages[language.slug] as Map<String, dynamic>;
      final fonts = LanguageFonts.of(language);
      expect(fonts.heading, want['heading'], reason: language.tag);
      expect(
        fonts.headingFallback ?? const <String>[],
        want['headingFallback'],
        reason: language.tag,
      );
      expect(
        fonts.bodyFallback ?? const <String>[],
        want['bodyFallback'],
        reason: language.tag,
      );
    }
  });

  test('every font family is bundled, licensed and declared', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final families = config['families'] as Map<String, dynamic>;
    for (final MapEntry(key: family, value: spec as Map<String, dynamic>)
        in families.entries) {
      expect(File(spec['asset'] as String).existsSync(), isTrue);
      expect(File(spec['license'] as String).existsSync(), isTrue);
      expect(pubspec, contains('family: $family\n'), reason: family);
      expect(pubspec, contains(spec['asset'] as String), reason: family);
      expect(pubspec, contains(spec['license'] as String), reason: family);
    }
    for (final family in LanguageFonts.allScripts) {
      expect(families, contains(family));
    }
  });

  test('English and the Latin languages keep the exact old styles', () {
    for (final language in [AppLanguage.en, AppLanguage.de, AppLanguage.fr]) {
      L10n.apply(language);
      expect(heading(20).fontFamily, 'Fredoka');
      expect(heading(20).fontFamilyFallback, isNull);
      expect(bodyText(14).fontFamily, 'Nunito');
      expect(bodyText(14).fontFamilyFallback, isNull);
    }
    L10n.apply(AppLanguage.ja);
    expect(heading(20).fontFamilyFallback, [LanguageFonts.mPlus]);
    expect(bodyText(14).fontFamilyFallback, [LanguageFonts.mPlus]);
    L10n.apply(AppLanguage.tr);
    expect(heading(20).fontFamily, LanguageFonts.baloo);
    expect(bodyText(14).fontFamily, 'Nunito');
  });

  group('English ARB and the domain twins', () {
    final en = lookupAppLocalizations(const Locale('en'));

    test('region names', () {
      for (final region in WorldRegion.values) {
        expect(en.regionName(region), region.title, reason: region.name);
      }
    });

    test('shared vocabulary: bosses, birds, flight modes', () {
      // SkyBoss.name needs a live boss; these are its English words.
      const bosses = {
        BossKind.baronBat: 'Baron Bat',
        BossKind.spitterBeetle: 'Spitter King',
        BossKind.duskMoth: 'Dusk Empress',
        BossKind.pirate: 'Pirate Captain',
        BossKind.dragon: 'Ember Dragon',
        BossKind.kingCoo: 'King Coo',
        BossKind.searchlightGargoyle: 'Searchlight Gargoyle',
        BossKind.neferhoo: Neferhoo.name,
      };
      for (final kind in BossKind.values) {
        expect(en.bossName(kind), bosses[kind], reason: kind.name);
      }
      for (var bird = 0; bird < birdNames.length; bird++) {
        expect(en.birdName(bird), birdNames[bird]);
      }
      for (final mode in PlayMode.values) {
        expect(en.playModeName(mode), mode.title);
      }
    });

    test('every language has a name in the picker', () {
      final names = {
        for (final language in AppLanguage.values) en.languageName(language),
      };
      expect(names, hasLength(AppLanguage.values.length));
      for (final language in AppLanguage.values) {
        expect(en.languageName(language), language.englishName);
      }
    });

    test('every key has a translator description', () {
      final arb =
          jsonDecode(File('lib/l10n/arb/app_en.arb').readAsStringSync())
              as Map<String, dynamic>;
      for (final key in arb.keys.where((k) => !k.startsWith('@'))) {
        final meta = arb['@$key'] as Map<String, dynamic>?;
        expect(meta?['description'], isNotEmpty, reason: key);
      }
    });
  });
}
