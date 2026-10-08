import 'dart:math' as math;
import 'sky_door.dart';

/// [title] is an English twin: screens show `AppLocalizations.obstacleName`
/// (lib/l10n/text/flight_text.dart).
// l10n-english-twin: obstacle_* keys.
enum ObstacleKind {
  garden('Garden gate'),
  windLift('Wind lift'),
  petalGate('Petal shutters'),
  switchback('Switchback'),
  lanternDrift('Lantern drift'),
  sunWheels('Sun wheels'),
  crystalSteps('Crystal steps');

  const ObstacleKind(this.title);
  final String title;

  bool get floating => this == lanternDrift || this == sunWheels;
  double get width => switch (this) {
    switchback || lanternDrift => .24,
    sunWheels || crystalSteps => .30,
    _ => .14,
  };
}

/// Floating hazards use the same circles for artwork, bird hits and rock hits.
class ObstacleOrb {
  const ObstacleOrb(this.x, this.y, this.radius, {required this.upper});
  final double x, y, radius;
  final bool upper;
}

/// A passage is shared by painting and collision detection, including the two
/// offset openings of a switchback. All distances use viewport height units.
class ObstaclePassage {
  const ObstaclePassage(this.x, this.width, this.center, this.gap);
  final double x, width, center, gap;
  double get top => math.max(0, center - gap / 2);
  double get bottom => math.min(1, center + gap / 2);
}

class Obstacle {
  Obstacle({
    required this.x,
    required double center,
    required double gap,
    double? width,
    double? target,
    this.kind = ObstacleKind.garden,
    this.amplitude = 0,
    this.period = 7,
    this.phaseOffset = 0,
    this.bornAt = 0,
    this.fixedTarget = false,
    this.appearance = 0,
    this.door,
    this.rubble = false,
  }) : width = width ?? kind.width,
       baseCenter = center,
       baseGap = gap,
       _target = target ?? center;

  double x;
  final double baseCenter, baseGap, width, _target;
  final double amplitude, period, phaseOffset, bornAt;
  final bool fixedTarget;
  final int appearance;
  final ObstacleKind kind;
  final SkyDoor? door;

  /// A rush-path barrier that any sprint breaks. A ring sprint also smashes
  /// ordinary walls; a smashed obstacle has no collision left.
  final bool rubble;
  double? smashedAt;
  double smashY = .5;
  bool get smashed => smashedAt != null;
  double _age = 0;
  bool scored = false, hit = false;
  double maxDeviation = 0;

  void advance(double elapsed) {
    _age = math.max(0, elapsed - bornAt);
    door?.age = _age;
  }

  double get angle => _age * math.pi * 2 / period + phaseOffset;
  double get motion => math.sin(angle);
  double get center =>
      baseCenter +
      (kind == ObstacleKind.windLift || kind == ObstacleKind.lanternDrift
          ? amplitude * motion
          : 0);
  double get gap =>
      baseGap -
      (kind == ObstacleKind.petalGate || kind == ObstacleKind.sunWheels
          ? amplitude * (1 + motion)
          : 0);
  double get target => fixedTarget ? _target : _target + center - baseCenter;
  double get top => math.max(0, center - gap / 2);
  double get bottom => math.min(1, center + gap / 2);

  Iterable<ObstaclePassage> get passages sync* {
    if (kind.floating) return;
    if (kind == ObstacleKind.crystalSteps) {
      for (var i = 0; i < 3; i++) {
        yield ObstaclePassage(
          x + i * width / 3,
          width / 3,
          center + amplitude * math.sin(angle + i * 1.1),
          gap,
        );
      }
    } else if (kind == ObstacleKind.switchback) {
      final offset = amplitude * motion;
      yield ObstaclePassage(x, width * .42, center - offset, gap);
      yield ObstaclePassage(x + width * .58, width * .42, center + offset, gap);
    } else {
      yield ObstaclePassage(x, width, center, gap);
    }
  }

  Iterable<ObstacleOrb> get orbs sync* {
    if (!kind.floating) return;
    final radius = kind == ObstacleKind.lanternDrift ? .075 : .082;
    final sway = (width / 2 - radius - .01) * math.cos(angle);
    yield ObstacleOrb(
      x + width / 2 + sway,
      center - gap / 2 - radius,
      radius,
      upper: true,
    );
    yield ObstacleOrb(
      x + width / 2 - sway,
      center + gap / 2 + radius,
      radius,
      upper: false,
    );
  }
}
