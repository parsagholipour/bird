/// The places a flight tours, in flight order. Each owns a sky, parallax
/// skyline, weather and obstacle materials, painted procedurally
/// (lib/game/regions). Rules only need a region's identity: a campaign level
/// names the one region it flies.
///
/// The order alternates warm and cold, day and night, so every hand-off is a
/// strong contrast. It opens on a neutral jungle morning, then polar
/// twilight, an Aztec sunrise, a Paris night, Egyptian noon, the neon night
/// of a cyberpunk megacity, a Chinese dusk, bright Brazil, a New York night,
/// a teal dawn over an ancient Arabian city, golden Rome, a Mexican dusk and
/// an ocean dawn that leads back to the jungle.
// l10n-english-twin: the titles are the English twins of the region_* ARB
// keys; screens show AppLocalizations.regionName (lib/l10n/text/).
enum WorldRegion {
  jungle('Jungle'),
  antarctica('Antarctica'),
  aztec('Aztec'),
  paris('Paris'),
  egypt('Egypt'),
  cyberpunk('Cyberpunk City'),
  china('China'),
  brazil('Brazil'),
  newYork('New York'),
  arabia('Ancient Arabia'),
  rome('Ancient Rome'),
  mexico('Mexico'),
  sea('Open Sea');

  const WorldRegion(this.title);
  final String title;

  WorldRegion get next => values[(index + 1) % values.length];
}
