import 'dart:ui' show Locale;

/// The pseudo-locale: English with accents and about 40 % more length, in
/// brackets, so a test or a dev build shows what would overflow or be cut
/// before real translations exist. Its ARB (`app_en_XA.arb`) is written by
/// `tool/l10n/pseudo_arb.py` with the same rules as [pseudoLocalize]; it is
/// never offered in the language picker.
const pseudoLocale = Locale('en', 'XA');

// Only letters both Fredoka and Nunito draw, so a pseudo string is as wide
// in a test as it would be on a phone (a missing glyph would fall back to a
// wider font). Letters without such a twin stay plain.
const _accents = {
  'a': 'á',
  'c': 'ç',
  'd': 'ð',
  'e': 'é',
  'f': 'ƒ',
  'i': 'í',
  'l': 'ł',
  'n': 'ñ',
  'o': 'ö',
  'p': 'þ',
  's': 'š',
  'u': 'ü',
  'y': 'ý',
  'z': 'ž',
  'A': 'Å',
  'C': 'Ç',
  'D': 'Ð',
  'E': 'É',
  'I': 'Î',
  'L': 'Ł',
  'N': 'Ñ',
  'O': 'Ø',
  'P': 'Þ',
  'S': 'Š',
  'U': 'Û',
  'Y': 'Ý',
  'Z': 'Ž',
};

/// [text] accented and stretched by about 40 % (every other vowel
/// doubled, then padded with `~` to reach it), in `[` `]`. Plain text only:
/// the ARB tool applies the same steps to the literal parts of an ICU
/// message and leaves placeholders alone.
String pseudoLocalize(String text) {
  if (text.isEmpty) return text;
  final out = StringBuffer('[');
  var vowels = 0;
  var added = 0;
  for (final rune in text.runes) {
    final ch = String.fromCharCode(rune);
    final accented = _accents[ch] ?? ch;
    out.write(accented);
    if ('aeiouAEIOU'.contains(ch) && vowels++ % 2 == 0) {
      out.write(accented);
      added++;
    }
  }
  final letters = RegExp('[A-Za-z]').allMatches(text).length;
  final target = (letters * .4).ceil();
  if (added < target) out.write('~' * (target - added));
  out.write(']');
  return out.toString();
}
