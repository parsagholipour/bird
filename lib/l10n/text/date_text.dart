import 'package:intl/intl.dart';

import '../generated/app_localizations.dart';

/// Dates and times the menus show (slice S6: Daily Adventure, Records,
/// saved sessions), in the current language's own order and month names
/// (intl's CLDR skeletons). Digits stay Western in every language.
///
/// English keeps the forms the game has always shown ("7 OCT", "7/10",
/// "2026-10-07 18:30"), and every language falls back to them while intl
/// has no date data for it (a test under a bare MaterialApp).
extension DateText on AppLocalizations {
  /// The intl locale for dates: Traditional Chinese reads Taiwan's data.
  String get _dateLocale => switch (localeName) {
    'zh_Hant' => 'zh_TW',
    final name => name,
  };

  bool get _english => localeName == 'en' || localeName.startsWith('en_');

  DateFormat _format(String english, DateFormat Function(String) local) {
    if (!_english) {
      final locale = _dateLocale;
      if (_loaded(locale)) return local(locale);
      final language = locale.split('_').first;
      if (_loaded(language)) return local(language);
    }
    return DateFormat(english, 'en_US');
  }

  /// Whether intl has [locale]'s date data (Material's localizations load
  /// it; until then intl knows only en_US and throws for the rest).
  static bool _loaded(String locale) {
    try {
      return DateFormat.localeExists(locale);
    } on Exception {
      return false;
    }
  }

  /// Day and short month, in capitals: "7 OCT", "7. OKT.", "10月7日".
  String dayMonthCaps(DateTime date) =>
      _upper(_format('d MMM', DateFormat.MMMd).format(date));

  /// Day and month in digits: "7/10", "7.10.", "10/7".
  String dayMonthDigits(DateTime date) =>
      _format('d/M', DateFormat.Md).format(date);

  /// A whole date in digits: "2026-10-07", "7.10.2026".
  String dateDigits(DateTime date) =>
      _format('y-MM-dd', DateFormat.yMd).format(date);

  /// Date and time of day in digits: "2026-10-07 18:30".
  String dateTimeDigits(DateTime date) =>
      _format('y-MM-dd HH:mm', (l) => DateFormat.yMd(l).add_Hm()).format(date);

  /// The weekday's one-letter name: "M", "D", "月".
  String weekdayLetter(DateTime date) =>
      _format('EEEEE', (l) => DateFormat('ccccc', l)).format(date);

  /// Turkish capitals keep their dotted İ.
  String _upper(String text) => localeName.startsWith('tr')
      ? text.replaceAll('i', 'İ').toUpperCase()
      : text.toUpperCase();
}
