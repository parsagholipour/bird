import 'app_language.dart';

/// Which bundled fonts set a language's text (MASTER-PLAN.md, "Fonts").
///
/// Fredoka (headings) and Nunito (body) stay first wherever they have the
/// letters, so digits, Latin names and punctuation look the same in every
/// language. A script they lack comes from a rounded OFL family subset to
/// the glyphs the translations use (`tool/l10n/subset_fonts.py`), through
/// Flutter's per-glyph `fontFamilyFallback`. Turkish is the exception:
/// Fredoka lacks ğ, ş and İ, and a word set in two fonts looks broken, so a
/// Turkish heading is set wholly in Baloo Bhaijaan 2.
///
/// The table must match `tool/l10n/fonts.json` (checked by
/// test/l10n_tables_test.dart): the subset and coverage tools read that file.
class LanguageFonts {
  const LanguageFonts({
    this.heading = fredoka,
    this.headingFallback,
    this.bodyFallback,
  });

  static const fredoka = 'Fredoka', nunito = 'Nunito';
  static const baloo = 'BalooBhaijaan2', mPlus = 'MPLUSRounded1c';
  static const jua = 'Jua', huninn = 'Huninn';

  /// The family a heading asks for first.
  final String heading;

  /// Families tried, in order, for the glyphs [heading] lacks; null when
  /// it has them all (Latin languages keep their exact styles).
  final List<String>? headingFallback;

  /// Families tried for the glyphs Nunito lacks.
  final List<String>? bodyFallback;

  /// Nunito sets every body text.
  String get body => nunito;

  static const _latin = LanguageFonts();

  static LanguageFonts of(AppLanguage language) => switch (language) {
    AppLanguage.en ||
    AppLanguage.es419 ||
    AppLanguage.ptBR ||
    AppLanguage.id ||
    AppLanguage.fr ||
    AppLanguage.de => _latin,
    AppLanguage.tr => const LanguageFonts(
      heading: baloo,
      headingFallback: [nunito],
    ),
    AppLanguage.ru => const LanguageFonts(headingFallback: [mPlus, nunito]),
    AppLanguage.ja => const LanguageFonts(
      headingFallback: [mPlus],
      bodyFallback: [mPlus],
    ),
    AppLanguage.ko => const LanguageFonts(
      headingFallback: [jua],
      bodyFallback: [jua],
    ),
    AppLanguage.zhHant => const LanguageFonts(
      headingFallback: [huninn],
      bodyFallback: [huninn],
    ),
    AppLanguage.ar => const LanguageFonts(
      headingFallback: [baloo],
      bodyFallback: [baloo],
    ),
  };

  /// Every family the localization adds, for text that may hold any
  /// language at once (the language picker's own names).
  static const allScripts = [baloo, mPlus, jua, huninn];

  /// The family that draws the arrow keys' glyphs (← ↑ → ↓) where a label
  /// names keyboard keys (Fly Together's key hints): Fredoka, Nunito and
  /// Jua have none. A label that may hold them adds it as its last
  /// fallback; the ARB key says so with `"x-fontFallback"`, which
  /// tool/l10n/check_arb.py reads.
  static const keySymbols = baloo;
}
