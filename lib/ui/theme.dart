import 'package:flutter/material.dart';
import '../l10n/l10n.dart';

abstract final class SkyColors {
  static const sky = Color(0xffbde9f6), skyDeep = Color(0xff90d5ee);
  static const cream = Color(0xfffff9ed),
      ink = Color(0xff203b45),
      muted = Color(0xff385a64),
      night = Color(0xff18313b);
  static const coral = Color(0xfff47d64), coralDeep = Color(0xffd75e4f);
  static const yellow = Color(0xffffd45b), gold = Color(0xffe8a73c);
  static const mint = Color(0xffa8d8b4), teal = Color(0xff53aa99);
  static const lavender = Color(0xffb9aaf2), purple = Color(0xff8572c5);
  static const white = Colors.white,
      sand = Color(0xffd9b998),
      rock = Color(0xffab8b73);
}

abstract final class SkyLayout {
  static const xs = 4.0,
      sm = 8.0,
      md = 16.0,
      lg = 24.0,
      xl = 32.0,
      button = 16.0,
      panel = 24.0,
      pill = 999.0;
}

/// Fredoka lettering, with the current language's fallback fonts for the
/// glyphs Fredoka lacks (lib/l10n/language_fonts.dart; English and the other
/// Latin languages get exactly the old style).
TextStyle heading(
  double size, {
  Color color = SkyColors.ink,
  FontWeight weight = FontWeight.w600,
}) => TextStyle(
  fontFamily: L10n.fonts.heading,
  fontFamilyFallback: L10n.fonts.headingFallback,
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: 1.08,
);

/// Nunito body text, with the current language's fallback fonts.
TextStyle bodyText(
  double size, {
  Color color = SkyColors.ink,
  FontWeight weight = FontWeight.w600,
}) => TextStyle(
  fontFamily: 'Nunito',
  fontFamilyFallback: L10n.fonts.bodyFallback,
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: 1.25,
);

/// The app's theme; [language] picks the fallback fonts Material's own
/// text (dialog buttons, snack bars) uses.
ThemeData skyTheme([AppLanguage language = AppLanguage.en]) => ThemeData(
  useMaterial3: true,
  fontFamily: 'Nunito',
  fontFamilyFallback: LanguageFonts.of(language).bodyFallback,
  scaffoldBackgroundColor: SkyColors.sky,
  colorScheme: ColorScheme.fromSeed(
    seedColor: SkyColors.coral,
    primary: SkyColors.ink,
    secondary: SkyColors.coral,
    surface: SkyColors.cream,
    onSurface: SkyColors.ink,
  ),
  textTheme: const TextTheme(bodyMedium: TextStyle(color: SkyColors.ink)),
  splashFactory: NoSplash.splashFactory,
  dialogTheme: DialogThemeData(
    backgroundColor: SkyColors.cream,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
  ),
);
