import '../../domain/duel.dart' show BoxPrize;
import '../../domain/tether.dart' show CoopMode;
import '../generated/app_localizations.dart';

/// Fly Together and 1 v 1 words that several screens show (owner: slice
/// S5): the co-op modes ([CoopMode.title] stays their English twin, for
/// logs, tests and tools) and the duel's mystery-box prizes
/// ([BoxPrize.title]). The records and replay screens show the mode's name
/// too: call [coopModeName] there. test/l10n_s5_test.dart keeps the English
/// ARB equal to the twins.
extension CoopText on AppLocalizations {
  /// "Roped", "No rope" or "1 v 1".
  String coopModeName(CoopMode mode) => switch (mode) {
    CoopMode.roped => coopMode_roped,
    CoopMode.free => coopMode_free,
    CoopMode.duel => coopMode_duel,
  };

  /// What a duel's mystery box held: "Bat swarm", "Heart"...
  String duelPrizeName(BoxPrize prize) => switch (prize) {
    BoxPrize.batSwarm => duelPrize_batSwarm,
    BoxPrize.spitter => duelPrize_spitter,
    BoxPrize.meteorShower => duelPrize_meteorShower,
    BoxPrize.heart => duelPrize_heart,
    BoxPrize.shield => duelPrize_shield,
    BoxPrize.starPower => duelPrize_starPower,
  };

  /// "P1" or "P2": [player] counts from 0.
  String coopPlayerTag(int player) => coopPlayerShort(player + 1);
}
