import 'package:intl/intl.dart' show NumberFormat;

import '../../domain/sky_boss.dart' show BossKind;
import '../../domain/tracking.dart' show PlayMode;
import '../generated/app_localizations.dart';

/// Names several slices show (MASTER-PLAN.md, "Shared vocabulary"): use
/// these rather than the domain's English ([SkyBoss.name], `birdNames`,
/// [PlayMode.title]), which stay as English twins for tests and logs.
/// test/l10n_tables_test.dart keeps the English ARB equal to them.
extension SharedText on AppLocalizations {
  String bossName(BossKind kind) => switch (kind) {
    BossKind.baronBat => boss_baronBat_name,
    BossKind.spitterBeetle => boss_spitterBeetle_name,
    BossKind.duskMoth => boss_duskMoth_name,
    BossKind.pirate => boss_pirate_name,
    BossKind.dragon => boss_dragon_name,
    BossKind.kingCoo => boss_kingCoo_name,
    BossKind.searchlightGargoyle => boss_searchlightGargoyle_name,
    BossKind.neferhoo => boss_neferhoo_name,
  };

  /// Bird [bird]'s name (0 Pip, 1 Peaches, 2 Minty, 3 Orbit).
  String birdName(int bird) => switch (bird % 4) {
    0 => bird_0_name,
    1 => bird_1_name,
    2 => bird_2_name,
    _ => bird_3_name,
  };

  String playModeName(PlayMode mode) => switch (mode) {
    PlayMode.pushUp => playMode_pushUp,
    PlayMode.jump => playMode_jump,
    PlayMode.touch => playMode_touch,
    PlayMode.squat => playMode_squat,
  };

  /// [n] with the current language's thousands separator: 5,000 / 5.000 /
  /// 5 000. Digits stay Western in every language, Arabic included (intl's
  /// `ar` uses them; scores match the HUD). French's narrow no-break space
  /// becomes a plain no-break space, which Fredoka and Nunito draw.
  String formatCount(int n) => NumberFormat.decimalPattern(
    localeName,
  ).format(n).replaceAll('\u202f', '\u00a0');
}
