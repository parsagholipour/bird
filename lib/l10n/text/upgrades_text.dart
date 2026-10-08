import 'package:intl/intl.dart' show NumberFormat;

import '../../domain/power_ups.dart';
import '../generated/app_localizations.dart';

/// The upgrades' words (slice S6). The domain keeps its English twins
/// ([PowerUp.title], [PowerUp.blurb], [PowerUp.stats]); the screens show
/// these. test/l10n_menus_test.dart keeps them equal.
extension UpgradesText on AppLocalizations {
  /// "Shot power".
  String powerUpName(PowerUp power) => switch (power) {
    PowerUp.shot => power_shot_name,
    PowerUp.sprint => power_sprint_name,
    PowerUp.shield => power_shield_name,
    PowerUp.magnet => power_magnet_name,
  };

  /// What the upgrade does, in a sentence.
  String powerUpBlurb(PowerUp power) => switch (power) {
    PowerUp.shot => power_shot_blurb,
    PowerUp.sprint => power_sprint_blurb,
    PowerUp.shield => power_shield_blurb,
    PowerUp.magnet => power_magnet_blurb,
  };

  /// A stat row's label: "Cooldown".
  String powerStatLabel(PowerStat stat) => switch (stat) {
    PowerStat.maxCharge => power_stat_maxCharge,
    PowerStat.burstLength => power_stat_burstLength,
    PowerStat.cooldown => power_stat_cooldown,
    PowerStat.starsToRefill => power_stat_starsToRefill,
    PowerStat.safeTime => power_stat_safeTime,
    PowerStat.perfectGates => power_stat_perfectGates,
    PowerStat.lasts => power_stat_lasts,
    PowerStat.reach => power_stat_reach,
  };

  /// A stat's value with its unit, its decimals in the language's own
  /// style: "85%", "1.2 s" (de "1,2 s"), "9", "2.4×".
  String powerStatValue(PowerStat stat, num value) => switch (stat.unit) {
    PowerStatUnit.percent => upgradesStatPercent('$value'),
    PowerStatUnit.seconds => upgradesStatSeconds(_number('0.##', value)),
    PowerStatUnit.count => '$value',
    PowerStatUnit.times => upgradesStatTimes(_number('0.0', value)),
  };

  /// What [power] gives at [level], worded: (label, value) rows.
  List<(String, String)> powerStats(PowerUp power, int level) => [
    for (final (stat, value) in power.statValues(level))
      (powerStatLabel(stat), powerStatValue(stat, value)),
  ];

  String _number(String pattern, num value) => NumberFormat(
    pattern,
    localeName,
  ).format(value).replaceAll(' ', ' ');
}
