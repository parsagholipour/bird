import '../../domain/world_region.dart';
import '../generated/app_localizations.dart';

/// The reference data list (MASTER-PLAN.md, "Domain data"): the domain keeps
/// the id ([WorldRegion]) and its English twin ([WorldRegion.title], still
/// used by tests and tools); every screen shows [regionName].
/// test/l10n_tables_test.dart keeps the English ARB equal to the twin.
extension RegionText on AppLocalizations {
  String regionName(WorldRegion region) => switch (region) {
    WorldRegion.jungle => region_jungle,
    WorldRegion.antarctica => region_antarctica,
    WorldRegion.aztec => region_aztec,
    WorldRegion.paris => region_paris,
    WorldRegion.egypt => region_egypt,
    WorldRegion.cyberpunk => region_cyberpunk,
    WorldRegion.china => region_china,
    WorldRegion.brazil => region_brazil,
    WorldRegion.newYork => region_newYork,
    WorldRegion.arabia => region_arabia,
    WorldRegion.rome => region_rome,
    WorldRegion.mexico => region_mexico,
    WorldRegion.sea => region_sea,
  };
}
