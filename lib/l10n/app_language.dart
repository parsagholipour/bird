import 'dart:ui' show Locale, TextDirection;

/// The languages Beakbound speaks (l10n-ws/BRIEF.md, "Languages"). English
/// is the source and the default; the others come in three voice ranks.
///
/// This enum is a contract shared with the voice-pack runtime and the
/// voice scripts: its values, [tag], [slug] and [voiceRank] must not change
/// without telling them. Pure Dart (dart:ui only), so data and canvas code
/// may import it.
enum AppLanguage {
  en('en', 'English', 'English', 0),
  es419('es-419', 'Español (Latinoamérica)', 'Spanish (Latin America)', 1),
  ptBR('pt-BR', 'Português (Brasil)', 'Portuguese (Brazil)', 1),
  id('id', 'Bahasa Indonesia', 'Indonesian', 1),
  fr('fr', 'Français', 'French', 1),
  de('de', 'Deutsch', 'German', 1),
  ja('ja', '日本語', 'Japanese', 2),
  ko('ko', '한국어', 'Korean', 2),
  tr('tr', 'Türkçe', 'Turkish', 2),
  zhHant('zh-Hant', '繁體中文', 'Traditional Chinese', 2),
  ru('ru', 'Русский', 'Russian', 2),
  ar('ar', 'العربية', 'Arabic', 3);

  const AppLanguage(
    this.tag,
    this.nativeName,
    this.englishName,
    this.voiceRank,
  );

  /// The BCP-47 tag, such as `es-419` or `zh-Hant`.
  final String tag;

  /// The language's name in itself, as the language picker shows it.
  final String nativeName;

  /// The language's name in English (tools, logs, store notes).
  final String englishName;

  /// 0 for English (the source); otherwise its voice rank, 1 to 3, which
  /// sets the share of in-flight lines it voices (50, 30 or 20 %).
  final int voiceRank;

  /// The Flutter locale: what MaterialApp, gen-l10n and the Material
  /// widgets' own strings use.
  Locale get locale => switch (this) {
    es419 => const Locale('es', '419'),
    ptBR => const Locale('pt', 'BR'),
    zhHant => const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    _ => Locale(tag),
  };

  /// Whether the language reads right to left (Arabic).
  bool get isRtl => this == ar;

  /// The direction its text and its menus run in.
  TextDirection get textDirection =>
      isRtl ? TextDirection.rtl : TextDirection.ltr;

  /// An asset- and pack-safe id: `en, es_419, pt_br, id, fr, de, ja, ko,
  /// tr, zh_hant, ru, ar`. Voice packs live in `assets/voice/SLUG/` and
  /// ship as the deferred component `voice_<slug>`; story captions in
  /// `assets/l10n/story/<slug>.json`.
  String get slug => tag.replaceAll('-', '_').toLowerCase();

  /// The language a saved [tag] names, or null for none (or "system").
  static AppLanguage? fromTag(String? tag) {
    if (tag == null) return null;
    for (final language in values) {
      if (language.tag == tag || language.slug == tag) return language;
    }
    return null;
  }

  /// The language a device in [locales] (most preferred first) gets when
  /// the player has not chosen one: the first locale Beakbound speaks, else
  /// English. See [forLocale].
  static AppLanguage forDevice(Iterable<Locale> locales) {
    for (final locale in locales) {
      final language = forLocale(locale);
      if (language != null) return language;
    }
    return en;
  }

  /// The language for one device [locale], or null when Beakbound does not
  /// speak it.
  ///
  /// Every Spanish gets Latin American Spanish and every Portuguese gets
  /// Brazilian. Chinese written in Traditional characters (zh-Hant, or
  /// zh-TW / zh-HK / zh-MO without a script) gets Traditional Chinese;
  /// Simplified Chinese (zh-Hans, zh-CN, zh-SG, bare zh) gets nothing, so the
  /// next preferred locale or English decides, as Android itself never
  /// crosses scripts (MASTER-PLAN.md, "Device mapping").
  static AppLanguage? forLocale(Locale locale) {
    final language = locale.languageCode.toLowerCase();
    final script = locale.scriptCode?.toLowerCase();
    final country = locale.countryCode?.toUpperCase();
    switch (language) {
      case 'en':
        return en;
      case 'es':
        return es419;
      case 'pt':
        return ptBR;
      case 'id' || 'in': // `in` is Android's legacy code for Indonesian.
        return id;
      case 'fr':
        return fr;
      case 'de':
        return de;
      case 'ja':
        return ja;
      case 'ko':
        return ko;
      case 'tr':
        return tr;
      case 'ru':
        return ru;
      case 'ar':
        return ar;
      case 'zh':
        if (script == 'hant') return zhHant;
        if (script == 'hans') return null;
        return switch (country) {
          'TW' || 'HK' || 'MO' => zhHant,
          _ => null,
        };
    }
    return null;
  }
}
