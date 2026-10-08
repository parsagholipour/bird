import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import 'app_language.dart';
import 'pseudo.dart';
import 'story_captions.dart';

/// The device's languages, most preferred first. The app root refreshes it
/// when Android's language list changes; tests override it.
final deviceLocalesProvider = NotifierProvider<DeviceLocales, List<Locale>>(
  DeviceLocales.new,
);

class DeviceLocales extends Notifier<List<Locale>> {
  @override
  List<Locale> build() => PlatformDispatcher.instance.locales;

  void update(List<Locale>? locales) {
    if (locales != null && locales.isNotEmpty) state = locales;
  }
}

/// The language the player chose in Settings, or null for "System default"
/// (also while the settings are loading).
final languageChoiceProvider = Provider<AppLanguage?>(
  (ref) => ref.watch(
    progressProvider.select((p) => p.asData?.value.settings.language),
  ),
);

/// The language the game speaks: the player's choice, else the device's
/// first language Beakbound speaks, else English
/// ([AppLanguage.forDevice]). A dev build's [forcedLocaleTag] wins.
final appLanguageProvider = Provider<AppLanguage>(
  (ref) =>
      AppLanguage.fromTag(forcedLocaleTag) ??
      ref.watch(languageChoiceProvider) ??
      AppLanguage.forDevice(ref.watch(deviceLocalesProvider)),
);

/// A locale forced by `--dart-define=L10N_LOCALE=<tag>` for a dev build or a
/// screenshot run: any [AppLanguage] tag, or `en-XA` for the pseudo-locale.
/// Empty in every normal build.
const forcedLocaleTag = String.fromEnvironment('L10N_LOCALE');

/// The locale MaterialApp and the strings use: [appLanguageProvider]'s,
/// unless [forcedLocaleTag] says otherwise.
final appLocaleProvider = Provider<Locale>((ref) {
  final language = ref.watch(appLanguageProvider);
  if (forcedLocaleTag == 'en-XA') return pseudoLocale;
  return language.locale;
});

/// The current language's story captions; English (the domain's own lines)
/// until they load or for a language not yet translated.
final storyCaptionsProvider = FutureProvider<StoryCaptions>((ref) {
  final language = ref.watch(appLanguageProvider);
  if (forcedLocaleTag == 'en-XA') return StoryCaptions.pseudo();
  return StoryCaptions.load(language);
});
