part of 'game_rules.dart';

/// Built levels (rules version 64, [BuiltPlan]). The plan's items are laid
/// in route order as they come within reach, each at its own world
/// position, with nothing drawn from a random: what the creator placed is
/// what every attempt meets. The level's [LevelRoute.built] holds only the
/// goal, so the finish line, the route line and a boss's victory glide work
/// as on a campaign level.
extension BuiltRules on FlightSimulation {
  /// Lays what has come within reach. Gates have already scrolled this
  /// step; pickups and enemies scroll after this, by [travel], so they are
  /// laid that much further on and every item sits exactly at its place.
  void _layBuilt(BuiltPlan plan, double viewportWidth, {double travel = 0}) {
    final reach = distance + _passageEntryX(viewportWidth);
    final items = plan.items;
    while (_builtNext < items.length && items[_builtNext].worldX <= reach) {
      final item = items[_builtNext++];
      final y = item.y / BuiltPlan.unit;
      final x = item.worldX - distance + (item is BuiltGate ? 0 : travel);
      switch (item) {
        case BuiltGate gate:
          _layBuiltGate(gate, x, y);
        case BuiltStar():
          stars.add(SkyStar(x: x, y: y));
          starsLaid++;
        case BuiltTrio():
          const spacing = BuiltTrio.spacing / BuiltPlan.unit;
          final trio = supportsStarTrios ? StarTrio(x: x, y: y) : null;
          if (trio != null) starTrios.add(trio);
          for (var i = 0; i < 3; i++) {
            stars.add(
              SkyStar(x: x + (i - 1) * spacing, y: y, trio: trio, trioSlot: i),
            );
          }
          starsLaid += 3;
        case BuiltHeart():
          heartPickups.add(SkyHeart(x: x, y: y));
        case BuiltEnemy enemy:
          if (!supportsCombat) break;
          final appearance = enemy.kind.index;
          enemies.add(
            SkyEnemy(
              x: x,
              y: y,
              appearance: appearance,
              maxHp: _enemyHealth(appearance),
              flightPhase: _builtNext * 2.399963,
            ),
          );
      }
    }
    // The boss arrives when the bird reaches its mark; the rest of its
    // fight (vanguard, stages, victory glide, the line after it) is the
    // campaign's.
    if (plan.boss != null &&
        !_builtBossCalled &&
        distance + FlightSimulation.birdX >= plan.finishX) {
      _builtBossCalled = true;
      _nextBossAt = _scheduleClock;
    }
  }

  /// A gate's swing is a function of the flight clock, timed so that a
  /// cruising bird reaches the gate's middle at its [BuiltGate.phase]: the
  /// swing covers one [BuiltGate.cycle] of route distance, whatever the
  /// course speed, so the gate looks the same to every player (and in the
  /// editor) when the bird gets there.
  void _layBuiltGate(BuiltGate gate, double x, double y) {
    final kind = gate.kind;
    final cycle = gate.cycle / BuiltPlan.unit;
    final middle = gate.worldX + kind.width / 2 - FlightSimulation.birdX;
    final obstacle = Obstacle(
      x: x,
      center: y,
      gap: gate.gap / BuiltPlan.unit,
      target: BuiltPlan.laneTarget(rules.mode, y),
      width: kind.width,
      kind: kind,
      amplitude: gate.amp / BuiltPlan.unit,
      period: cycle / speed,
      phaseOffset: gate.phase * math.pi / 180 - middle / cycle * math.pi * 2,
      fixedTarget: rules.mode.controlsHeight,
      appearance: gate.look,
      door: gate.door && supportsCombat ? SkyDoor() : null,
    )..advance(elapsed);
    obstacles.add(obstacle);
  }
}
