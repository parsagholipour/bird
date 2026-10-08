import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'app_language.dart';
import 'generated/app_localizations.dart';
import 'language_fonts.dart';
import 'pseudo.dart';
import 'story_captions.dart';

export 'app_language.dart';
export 'generated/app_localizations.dart';
export 'language_fonts.dart';
export 'story_captions.dart';
export 'text/campaign_text.dart';
export 'text/language_text.dart';
export 'text/region_text.dart';
export 'text/shared_text.dart';
export 'text/tracking_text.dart';

/// The language the game speaks right now, for code without a
/// [BuildContext]: Flame components, canvas painters, static text caches.
///
/// Widgets use `context.l10n` ([L10nContext]) and the Riverpod providers in
/// language_providers.dart; the app root ([PushUpBirdApp]) keeps this global
/// in step with them through [apply]. Tests start in English and a test that
/// switches language calls [debugReset] in a tearDown.
///
/// ```dart
/// final l = L10n.strings;                   // AppLocalizations, never null
/// L10n.language.value;                      // AppLanguage
/// L10n.language.addListener(_cache.clear);  // or L10n.cache(...)
/// ```
abstract final class L10n {
  static final _state = _LanguageState();

  /// The current language. Notifies on every change of language or locale
  /// (a pseudo-locale switch keeps the language and changes the locale).
  static ValueListenable<AppLanguage> get language => _state;

  /// The locale the strings come from: the language's own, or the
  /// pseudo-locale in a test or a dev build.
  static Locale get locale => _state.locale;

  /// Every translated message, for the current [locale]. Missing messages
  /// are the English ones (gen-l10n's fallback).
  static AppLocalizations get strings => _state.strings;

  /// The current language's story captions (English until loaded).
  static StoryCaptions get captions => _state.captions;

  /// Which way the current language's text runs. Use it for canvas
  /// TextPainters that set words; the flight world itself always runs left
  /// to right ([FlightDirection]).
  static TextDirection get textDirection => _state.value.textDirection;

  /// The fonts the current language sets text in.
  static LanguageFonts get fonts => LanguageFonts.of(_state.value);

  /// The locales MaterialApp supports: each language's, plus the
  /// pseudo-locale (never offered to players).
  static final List<Locale> supportedLocales = [
    for (final language in AppLanguage.values) language.locale,
    pseudoLocale,
  ];

  /// Switches the global to [language] (and [locale], the language's own by
  /// default). Called by the app root when the player's choice or the
  /// device's languages change; tests may call it directly.
  static void apply(AppLanguage language, {Locale? locale}) {
    _state.set(language, locale ?? language.locale);
  }

  /// Sets the captions the app root loaded for [captions.language].
  static void applyCaptions(StoryCaptions captions) {
    if (captions.language == _state.value ||
        captions.language == AppLanguage.en) {
      _state.captions = captions;
    }
  }

  /// [cache], emptied whenever the language changes. For static text caches
  /// in canvas code whose keys are not the final words:
  ///
  /// ```dart
  /// static final _painters = L10n.cache(<String, TextPainter>{});
  /// ```
  static Map<K, V> cache<K, V>(Map<K, V> cache) {
    _state.addListener(cache.clear);
    return cache;
  }

  /// Upper case for a label in the current language: Turkish dotted i
  /// becomes İ, not I. Prefer upper-case text in the ARB where the case is
  /// part of the design; use this for words the code capitalizes.
  static String upper(String text) => _state.value == AppLanguage.tr
      ? text.replaceAll('i', 'İ').toUpperCase()
      : text.toUpperCase();

  /// Back to English, for a test's tearDown.
  @visibleForTesting
  static void debugReset() => _state.set(AppLanguage.en, AppLanguage.en.locale);
}

class _LanguageState extends ChangeNotifier
    implements ValueListenable<AppLanguage> {
  AppLanguage _language = AppLanguage.en;
  Locale locale = AppLanguage.en.locale;
  AppLocalizations strings = lookupAppLocalizations(AppLanguage.en.locale);
  StoryCaptions captions = StoryCaptions.english;

  @override
  AppLanguage get value => _language;

  void set(AppLanguage language, Locale locale) {
    if (language == _language && locale == this.locale) return;
    if (language != _language) captions = StoryCaptions.english;
    _language = language;
    this.locale = locale;
    strings = lookupAppLocalizations(locale);
    notifyListeners();
  }
}

/// `context.l10n`: the messages for the nearest [Localizations], which also
/// rebuilds the widget when the language changes. A widget pumped in a test
/// under a bare MaterialApp (no AppLocalizations delegate) gets the global
/// [L10n.strings] instead, so such tests need no setup.
extension L10nContext on BuildContext {
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      L10n.strings;
}

/// The flight world runs left to right in every language: the bird flies
/// toward the right, the route fills from the left, the HUD keeps its
/// corners. Wrap the game widget and the in-flight HUD in it. Words inside
/// that are sentences in an RTL language can restore their own direction
/// with [LanguageDirection].
class FlightDirection extends StatelessWidget {
  const FlightDirection({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Directionality(textDirection: TextDirection.ltr, child: child);
}

/// Gives [child] the current language's text direction, for a sentence
/// inside a [FlightDirection] area.
class LanguageDirection extends StatelessWidget {
  const LanguageDirection({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.maybeLocaleOf(context);
    final rtl = locale != null
        ? AppLanguage.forLocale(locale)?.isRtl ?? false
        : L10n.language.value.isRtl;
    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: child,
    );
  }
}
