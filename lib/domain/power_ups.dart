/// The four upgrades bought with collected stars (rules version 60).
///
/// Each runs from level 0 to [PowerUp.maxLevel]. Shot power, sprint and
/// shield top out at exactly how they flew before upgrades existed; the
/// magnet flew one level below its top, which lasts longer and reaches
/// further.
enum PowerUp {
  shot,
  sprint,
  shield,
  magnet;

  static const maxLevel = 4;

  /// Stars the next level costs, from level 0 to 1 onwards.
  static const costs = [50, 120, 250, 450];

  /// Stars to buy the level after [level], or null once it is the top.
  static int? costFrom(int level) =>
      level >= 0 && level < maxLevel ? costs[level] : null;

  String get title => switch (this) {
    shot => 'Shot power',
    sprint => 'Sprint',
    shield => 'Shield',
    magnet => 'Magnet',
  };

  /// What the upgrade does, in a sentence.
  String get blurb => switch (this) {
    shot => 'Hold Shoot to charge a bigger, harder rock.',
    sprint => 'A speed burst that smashes enemies in your way.',
    shield => 'Blocks one hit for you. Collect stars in flight to refill it.',
    magnet => 'Fly perfectly through gates to earn it. It pulls stars to you.',
  };

  /// What [level] gives, as short label and value pairs.
  List<(String, String)> stats(int level) {
    final l = level.clamp(0, maxLevel);
    String s(double seconds) =>
        '${seconds == seconds.roundToDouble() ? seconds.toInt() : seconds} s';
    return switch (this) {
      shot => [('Max charge', '${(ShotPower.maxCharge(l) * 100).round()}%')],
      sprint => [
        ('Burst length', s(SprintPower.seconds(l))),
        ('Cooldown', s(SprintPower.cooldown(l))),
      ],
      shield => [
        ('Stars to refill', '${ShieldPower.stars(l)}'),
        ('Safe time after it breaks', s(ShieldPower.cover(l))),
      ],
      // Reach is measured against a star's plain pickup radius.
      magnet => [
        ('Perfect gates needed', '${MagnetPower.gates(l)}'),
        ('Lasts', s(MagnetPower.seconds(l))),
        ('Reach', '${(MagnetPower.radius(l) / .085).toStringAsFixed(1)}×'),
      ],
    };
  }
}

/// How far a held shot may charge: enough at level 0 to see the rock grow
/// and shatter a pellet, a full second's power ([maxCharge] 1) at the top,
/// as before upgrades.
abstract final class ShotPower {
  static const _charge = [.40, .55, .70, .85, 1.0];
  static double maxCharge(int level) => _charge[level];
}

/// A touch sprint's burst and cooldown. The top is [Sprint.seconds] (1.2)
/// and [Sprint.cooldown] (15), as before upgrades.
abstract final class SprintPower {
  static const _seconds = [.7, .8, .95, 1.05, 1.2];
  static const _cooldown = [25.0, 22.0, 19.0, 17.0, 15.0];
  static double seconds(int level) => _seconds[level];
  static double cooldown(int level) => _cooldown[level];
}

/// Stars that restore a Star Trail shield, and the hit recovery after it
/// takes a hit. The top is every 9 stars and 1.5 s, as before upgrades. A
/// lost heart keeps the full 1.5 s at every level.
abstract final class ShieldPower {
  static const _stars = [15, 13, 11, 10, 9];
  static const _cover = [.6, .8, 1.0, 1.25, 1.5];
  static int stars(int level) => _stars[level];
  static double cover(int level) => _cover[level];
}

/// The star magnet: perfect gates to earn it, how long it pulls and how far.
/// Level 3 is 3 gates, 8 s and 0.20, as before upgrades; the top lasts
/// 10 s and reaches 10% further.
abstract final class MagnetPower {
  static const _gates = [5, 4, 4, 3, 3];
  static const _seconds = [5.0, 6.0, 7.0, 8.0, 10.0];
  static const _radius = [.16, .17, .185, .20, .22];
  static int gates(int level) => _gates[level];
  static double seconds(int level) => _seconds[level];
  static double radius(int level) => _radius[level];
}

/// The upgrade levels a flight is flown with. Recorded in its replay.
class PowerUps {
  const PowerUps({
    this.shot = 0,
    this.sprint = 0,
    this.shield = 0,
    this.magnet = 0,
  });

  /// Exactly how every flight flew before upgrades: shot power, sprint and
  /// shield at the top, the magnet one level below it. Flights recorded
  /// under rules older than 60 always fly with these.
  static const legacy = PowerUps(shot: 4, sprint: 4, shield: 4, magnet: 3);

  /// Every upgrade at the top.
  static const max = PowerUps(shot: 4, sprint: 4, shield: 4, magnet: 4);

  final int shot, sprint, shield, magnet;

  int operator [](PowerUp p) => switch (p) {
    PowerUp.shot => shot,
    PowerUp.sprint => sprint,
    PowerUp.shield => shield,
    PowerUp.magnet => magnet,
  };

  PowerUps withLevel(PowerUp p, int level) => PowerUps(
    shot: p == PowerUp.shot ? level : shot,
    sprint: p == PowerUp.sprint ? level : sprint,
    shield: p == PowerUp.shield ? level : shield,
    magnet: p == PowerUp.magnet ? level : magnet,
  );

  bool get valid =>
      PowerUp.values.every((p) => this[p] >= 0 && this[p] <= PowerUp.maxLevel);

  Map<String, int> toJson() => {
    for (final p in PowerUp.values) p.name: this[p],
  };

  /// Throws [FormatException] for anything but four levels in range.
  factory PowerUps.fromJson(Object? json) {
    if (json is! Map) throw const FormatException('Invalid upgrades');
    int level(PowerUp p) {
      final value = json[p.name];
      if (value is! int || value < 0 || value > PowerUp.maxLevel) {
        throw const FormatException('Invalid upgrades');
      }
      return value;
    }

    return PowerUps(
      shot: level(PowerUp.shot),
      sprint: level(PowerUp.sprint),
      shield: level(PowerUp.shield),
      magnet: level(PowerUp.magnet),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PowerUps && PowerUp.values.every((p) => other[p] == this[p]);

  @override
  int get hashCode => Object.hash(shot, sprint, shield, magnet);

  @override
  String toString() => 'PowerUps(${toJson()})';
}
