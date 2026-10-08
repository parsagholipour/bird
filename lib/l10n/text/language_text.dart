import '../app_language.dart';
import '../generated/app_localizations.dart';

/// The languages' names in the current language (the picker's small line).
extension LanguageText on AppLocalizations {
  String languageName(AppLanguage language) => switch (language) {
    AppLanguage.en => languageName_en,
    AppLanguage.es419 => languageName_es_419,
    AppLanguage.ptBR => languageName_pt_br,
    AppLanguage.id => languageName_id,
    AppLanguage.fr => languageName_fr,
    AppLanguage.de => languageName_de,
    AppLanguage.ja => languageName_ja,
    AppLanguage.ko => languageName_ko,
    AppLanguage.tr => languageName_tr,
    AppLanguage.zhHant => languageName_zh_hant,
    AppLanguage.ru => languageName_ru,
    AppLanguage.ar => languageName_ar,
  };
}
