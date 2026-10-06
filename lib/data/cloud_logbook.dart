import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:math' as math;

import '../domain/campaign_progress.dart';
import '../domain/power_ups.dart';
import 'progress_repository.dart';

/// One phone's lifetime totals in the [Logbook], keyed by its random device
/// id. A phone only ever writes its own row, so the game adds the rows
/// together: two phones that each collected 300 stars have 600.
class DeviceTotals {
  const DeviceTotals({
    this.records = const {},
    this.birdFlights = const {},
    this.builtWorkouts = const {},
    this.coop = const {},
  });

  /// Endless records by [recordKeys] and the campaign flights.
  final Map<String, ModeRecord> records;

  /// Scored flights per bird index.
  final Map<int, int> birdFlights;

  /// Repetitions and jumps done on built levels, by [PlayMode] name.
  final Map<String, int> builtWorkouts;

  /// Co-op bests and flights by [CoopMode] name.
  final Map<String, CoopRecord> coop;

  /// The [records] keys: the eight endless records, then the campaign.
  static const recordKeys = [
    'pushUp',
    'jump',
    'touch',
    'squat',
    'trailPushUp',
    'trailJump',
    'trailTouch',
    'trailSquat',
    'campaign',
  ];

  ModeRecord record(String key) => records[key] ?? const ModeRecord();

  /// Two copies of the same phone's row. Every field only grows while the
  /// phone keeps its id, so the field-wise max is the newer copy, whatever
  /// either clock said.
  DeviceTotals newest(DeviceTotals other) => DeviceTotals(
    records: _zip(records, other.records, (a, b) => a.max(b)),
    birdFlights: _zip(birdFlights, other.birdFlights, math.max),
    builtWorkouts: _zip(builtWorkouts, other.builtWorkouts, math.max),
    coop: _zip(
      coop,
      other.coop,
      (a, b) => CoopRecord(
        best: math.max(a.best, b.best),
        flights: math.max(a.flights, b.flights),
      ),
    ),
  );

  /// Keys sorted, so the same totals always encode the same.
  Map<String, Object?> toJson() => {
    'records': {
      for (final MapEntry(:key, :value) in _sorted(records).entries)
        key: _modeToJson(value),
    },
    'birdFlights': {
      for (final bird in birdFlights.keys.toList()..sort())
        '$bird': birdFlights[bird],
    },
    'builtWorkouts': _sorted(builtWorkouts),
    'coop': {
      for (final MapEntry(:key, :value) in _sorted(coop).entries)
        key: {'best': value.best, 'flights': value.flights},
    },
  };

  factory DeviceTotals.fromJson(Object? json) {
    final map = _map(json);
    return DeviceTotals(
      records: {
        for (final MapEntry(:key, :value) in _map(map['records']).entries)
          key: _modeFromJson(value),
      },
      birdFlights: {
        for (final MapEntry(:key, :value) in _map(map['birdFlights']).entries)
          if (int.tryParse(key) case final bird? when bird >= 0)
            bird: _count(value),
      },
      builtWorkouts: {
        for (final MapEntry(:key, :value) in _map(map['builtWorkouts']).entries)
          key: _count(value),
      },
      coop: {
        for (final MapEntry(:key, :value) in _map(map['coop']).entries)
          key: CoopRecord(
            best: _count(_map(value)['best']),
            flights: _count(_map(value)['flights']),
          ),
      },
    );
  }

  /// Every other phone's rows, as kept in the `carried` preference.
  static Map<String, DeviceTotals> decodeAll(String? saved) {
    if (saved == null || saved.isEmpty) return const {};
    try {
      return {
        for (final MapEntry(:key, :value) in _map(jsonDecode(saved)).entries)
          key: DeviceTotals.fromJson(value),
      };
    } on FormatException {
      return const {};
    }
  }

  static String encodeAll(Map<String, DeviceTotals> rows) => jsonEncode({
    for (final MapEntry(:key, :value) in rows.entries) key: value.toJson(),
  });
}

/// The `logbook` saved game: the player's status, never their history.
/// No sessions, replays, clips or per-flight rows ever go in it
/// (docs/specification.md, "Google Play Games").
class Logbook {
  const Logbook({
    this.epoch = 0,
    this.devices = const {},
    this.levels = const {},
    this.upgrades = const PowerUps(),
    this.birds = const {},
    this.storyWatched = const {},
    this.feats = const {},
    this.builtLevels = const {},
    this.builtDeleted = const {},
  });

  /// The blob format. A newer one than this build knows is never
  /// overwritten. Any new field or enum value (a bird, a power-up, a play
  /// mode) needs a bump: older builds drop what they do not know on save.
  static const schema = 1;

  /// Raised when a reset clears progress while connected: a higher epoch
  /// replaces a lower one instead of merging with it.
  final int epoch;

  /// Every phone's totals row, by device id.
  final Map<String, DeviceTotals> devices;

  /// Campaign level bests by level id.
  final Map<String, LevelRecord> levels;

  /// Upgrade levels bought.
  final PowerUps upgrades;

  /// Birds bought with stars (the free ones are left out).
  final Set<int> birds;

  final Set<String> storyWatched, feats;

  /// Built levels by id: their `built_levels` columns, times in
  /// milliseconds.
  final Map<String, Map<String, Object?>> builtLevels;

  /// Ids of built levels deleted on some phone, so a merge never brings one
  /// back.
  final Set<String> builtDeleted;

  /// Merges [cloud] into [local], this phone's own logbook ([me] is its
  /// device id). Progress only moves forward: bests take the max, sets the
  /// union, each upgrade its higher level, and each phone's totals row its
  /// newest copy. A higher [epoch] (a reset while connected) wins: if it is
  /// this phone's, the cloud copy is replaced outright; if it is the
  /// cloud's, this phone drops the other phones' rows it carried from
  /// before that reset and adds only what it holds itself.
  static Logbook merge(Logbook local, Logbook? cloud, {required String me}) {
    if (cloud == null || local.epoch > cloud.epoch) return local;
    final mine = local.epoch < cloud.epoch
        ? local.only(me).withEpoch(cloud.epoch)
        : local;
    return mine._mergedWith(cloud);
  }

  Logbook _mergedWith(Logbook other) {
    final deleted = {...builtDeleted, ...other.builtDeleted};
    final built = _zip(
      builtLevels,
      other.builtLevels,
      (a, b) => _count(b['updatedAt']) > _count(a['updatedAt']) ? b : a,
    )..removeWhere((id, _) => deleted.contains(id));
    return Logbook(
      epoch: math.max(epoch, other.epoch),
      devices: _zip(devices, other.devices, (a, b) => a.newest(b)),
      levels: _zip(levels, other.levels, mergeLevels),
      upgrades: PowerUps(
        shot: math.max(upgrades.shot, other.upgrades.shot),
        sprint: math.max(upgrades.sprint, other.upgrades.sprint),
        shield: math.max(upgrades.shield, other.upgrades.shield),
        magnet: math.max(upgrades.magnet, other.upgrades.magnet),
      ),
      birds: {...birds, ...other.birds},
      storyWatched: {...storyWatched, ...other.storyWatched},
      feats: {...feats, ...other.feats},
      builtLevels: built,
      builtDeleted: deleted,
    );
  }

  /// The same level on two phones: max, max, max, max, earliest, latest,
  /// either. A level's plays can so undercount across phones; nothing
  /// depends on them.
  static LevelRecord mergeLevels(LevelRecord a, LevelRecord b) {
    DateTime? pick(DateTime? x, DateTime? y, bool later) => x == null
        ? y
        : y == null
        ? x
        : (y.isAfter(x) == later ? y : x);
    return LevelRecord(
      levelId: a.levelId,
      bestStars: math.max(a.bestStars, b.bestStars).clamp(0, 3),
      bestCollected: math.max(a.bestCollected, b.bestCollected),
      bestScore: math.max(a.bestScore, b.bestScore),
      plays: math.max(a.plays, b.plays),
      firstClearedAt: pick(a.firstClearedAt, b.firstClearedAt, false),
      lastPlayedAt: pick(a.lastPlayedAt, b.lastPlayedAt, true),
      postcardSeen: a.postcardSeen || b.postcardSeen,
    );
  }

  /// This logbook with [me]'s totals row only.
  Logbook only(String me) => Logbook(
    epoch: epoch,
    devices: {me: ?devices[me]},
    levels: levels,
    upgrades: upgrades,
    birds: birds,
    storyWatched: storyWatched,
    feats: feats,
    builtLevels: builtLevels,
    builtDeleted: builtDeleted,
  );

  Logbook withEpoch(int value) => Logbook(
    epoch: value,
    devices: devices,
    levels: levels,
    upgrades: upgrades,
    birds: birds,
    storyWatched: storyWatched,
    feats: feats,
    builtLevels: builtLevels,
    builtDeleted: builtDeleted,
  );

  Map<String, Object?> toJson() => {
    'schema': schema,
    'epoch': epoch,
    'devices': {
      for (final MapEntry(:key, :value) in _sorted(devices).entries)
        key: value.toJson(),
    },
    'levels': {
      for (final MapEntry(:key, :value) in _sorted(levels).entries)
        key: {
          'bestStars': value.bestStars,
          'bestCollected': value.bestCollected,
          'bestScore': value.bestScore,
          'plays': value.plays,
          'firstClearedAt': value.firstClearedAt?.millisecondsSinceEpoch,
          'lastPlayedAt': value.lastPlayedAt?.millisecondsSinceEpoch,
          'postcardSeen': value.postcardSeen,
        },
    },
    'upgrades': upgrades.toJson(),
    'unlockedBirds': birds.toList()..sort(),
    'storyWatched': storyWatched.toList()..sort(),
    'feats': feats.toList()..sort(),
    'builtLevels': _sorted(builtLevels),
    'builtDeleted': builtDeleted.toList()..sort(),
  };

  factory Logbook.fromJson(Object? json) {
    final map = _map(json);
    final version = _count(map['schema']);
    if (version > schema) throw NewerLogbook(version);
    DateTime? time(Object? ms) =>
        ms is int ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
    final upgrades = _map(map['upgrades']);
    int level(PowerUp p) => _count(upgrades[p.name]).clamp(0, PowerUp.maxLevel);
    return Logbook(
      epoch: _count(map['epoch']),
      devices: {
        for (final MapEntry(:key, :value) in _map(map['devices']).entries)
          key: DeviceTotals.fromJson(value),
      },
      levels: {
        for (final MapEntry(:key, :value) in _map(map['levels']).entries)
          key: () {
            final l = _map(value);
            return LevelRecord(
              levelId: key,
              bestStars: _count(l['bestStars']).clamp(0, 3),
              bestCollected: _count(l['bestCollected']),
              bestScore: _count(l['bestScore']),
              plays: _count(l['plays']),
              firstClearedAt: time(l['firstClearedAt']),
              lastPlayedAt: time(l['lastPlayedAt']),
              postcardSeen: l['postcardSeen'] == true,
            );
          }(),
      },
      upgrades: PowerUps(
        shot: level(PowerUp.shot),
        sprint: level(PowerUp.sprint),
        shield: level(PowerUp.shield),
        magnet: level(PowerUp.magnet),
      ),
      birds: {
        for (final b in _list(map['unlockedBirds']))
          if (b is int && b >= 0 && b < birdNames.length) b,
      },
      storyWatched: {...?_strings(map['storyWatched'])},
      feats: {...?_strings(map['feats'])},
      builtLevels: {
        for (final MapEntry(:key, :value) in _map(map['builtLevels']).entries)
          if (value is Map) key: Map<String, Object?>.from(value),
      },
      builtDeleted: {...?_strings(map['builtDeleted'])},
    );
  }

  /// Gzipped JSON in base64: what the saved game holds.
  String encode() => base64.encode(gzip.encode(utf8.encode(jsonEncode(this))));

  /// Reads a saved game. Null only when it is empty. A copy this build
  /// cannot read throws a [FormatException], and a format it does not know
  /// a [NewerLogbook]: either may hold another phone's progress, so it is
  /// never written over.
  static Logbook? decode(String? data) {
    if (data == null || data.isEmpty) return null;
    try {
      return Logbook.fromJson(
        jsonDecode(utf8.decode(gzip.decode(base64.decode(data)))),
      );
    } on TypeError {
      throw const FormatException('Unreadable logbook');
    }
  }

  /// No progress at all, like a fresh install's: every count zero and
  /// every list empty. The epoch alone is not progress.
  bool get isEmpty => _blank({...toJson(), 'schema': 0, 'epoch': 0});
}

/// The cloud logbook was written by a newer build.
class NewerLogbook implements Exception {
  const NewerLogbook(this.schema);
  final int schema;
  @override
  String toString() => 'NewerLogbook($schema)';
}

Map<String, Object?> _modeToJson(ModeRecord r) => {
  'best': r.best,
  'runs': r.runs,
  'obstacles': r.obstacles,
  'repetitions': r.repetitions,
  'stars': r.stars,
  'perfectPasses': r.perfectPasses,
  'bestCombo': r.bestCombo,
  'completions': r.completions,
};

ModeRecord _modeFromJson(Object? json) {
  final m = _map(json);
  return ModeRecord(
    best: _count(m['best']),
    runs: _count(m['runs']),
    obstacles: _count(m['obstacles']),
    repetitions: _count(m['repetitions']),
    stars: _count(m['stars']),
    perfectPasses: _count(m['perfectPasses']),
    bestCombo: _count(m['bestCombo']),
    completions: _count(m['completions']),
  );
}

Map<K, V> _zip<K, V>(Map<K, V> a, Map<K, V> b, V Function(V, V) both) => {
  ...a,
  for (final MapEntry(:key, :value) in b.entries)
    key: a.containsKey(key) ? both(a[key] as V, value) : value,
};

Map<String, V> _sorted<V>(Map<String, V> map) => {
  for (final key in map.keys.toList()..sort()) key: map[key] as V,
};

Map<String, Object?> _map(Object? json) =>
    json is Map ? Map<String, Object?>.from(json) : const {};

List<Object?> _list(Object? json) => json is List ? json : const [];

Iterable<String>? _strings(Object? json) => _list(json).whereType<String>();

int _count(Object? n) => n is int && n > 0 ? n : 0;

/// Only zeros, falses, nulls and empty lists in [json].
bool _blank(Object? json) => switch (json) {
  Map() => json.values.every(_blank),
  List() => json.isEmpty,
  num() => json == 0,
  bool() => !json,
  null => true,
  _ => false,
};
