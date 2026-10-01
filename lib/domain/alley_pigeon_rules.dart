part of 'game_rules.dart';

/// The Alley Pigeon's raid on the stars (rules version 43, New York levels
/// only; spec `reports/02-alley-pigeon.md` section 2). Everything here is
/// gated by [FlightSimulation.supportsAlleyPigeon] at its call sites and
/// reachable only through a level plan whose lineup holds a pigeon.
///
/// A formation of one to three pigeons is laid with the passage that leads
/// it, each bound to a star of that passage's trio. It hovers over the prey
/// (above or below the lane), warns for 0.80 s, dives for 0.44 s and snatches
/// the star at its centre; then it gloats and climbs away with the star
/// riding on it (the star stays in `stars`, flagged `carried`). A damaging
/// hit before the snatch spooks it; a hit after it frees the star, which
/// floats back to its gate line; a kill frees it too; a ram or a touch drops
/// it into the bird's beak. A thief that leaves the screen takes the star
/// for good. Thefts are not damage, never reset the streak, and a level's
/// pigeons may take at most [AlleyPigeon.thiefCap] stars for good.
///
/// The only random draw is one `nextInt` per formation of one or two
/// pigeons, from the plan's own `flockRandom`: the shared random is never
/// consumed, so pigeons do not move a passage, a panel or a set piece. All
/// state lives on the enemies and the stars and advances with the
/// simulation's own clocks, so replays and seeks are exact.
extension PigeonRaids on FlightSimulation {
  /// The most stars this level's pigeons may take for good: half the slack
  /// between its route stars and its three-star mark, so a player who never
  /// shoots can still earn the mark. Unlimited for a plan with no route.
  int get thiefBudget {
    final level = plan, route = this.route;
    if (level is! LevelPlan || route == null) return 1 << 30;
    return AlleyPigeon.thiefCap(
      routeStars: route.stars,
      threeStarMark: level.marks.three,
    );
  }

  /// Stars the pigeons hold or are about to take: each pigeon in its
  /// warning, dive or gloat with a star bound to it.
  int get thievesCommitted {
    var count = 0;
    for (final enemy in enemies) {
      final raid = enemy.pigeon;
      if (raid == null) continue;
      switch (raid.phase) {
        case PigeonPhase.warning || PigeonPhase.dive:
          if (raid.prey != null) count++;
        case PigeonPhase.carry:
          if (raid.loot != null) count++;
        case PigeonPhase.glide || PigeonPhase.flee:
          break;
      }
    }
    return count;
  }

  /// The screen column of the foremost bird: the one a prey ahead of the
  /// flock comes close to first. A solo bird's own column.
  double get _frontX {
    var front = lead.x;
    for (final bird in flock) {
      front = math.max(front, bird.x);
    }
    return front;
  }

  /// The bird nearest to ([x], [y]): the one a ram or a touch hands a freed
  /// star to. The solo bird, alone.
  FlightBird _nearestBird(double x, double y) {
    var best = lead, bestSquared = double.infinity;
    for (final bird in flock) {
      final dx = bird.x - x, dy = bird.y - y;
      final squared = dx * dx + dy * dy;
      if (squared < bestSquared) {
        best = bird;
        bestSquared = squared;
      }
    }
    return best;
  }

  bool _isPigeon(int appearance) =>
      EnemyKind.values[appearance % EnemyKind.values.length] ==
      EnemyKind.alleyPigeon;

  /// Lays one formation over the passage at [passageX] whose aiming lane is
  /// [lane]. [trio] holds the passage's three stars (empty without stars),
  /// whose prey the pigeons reserve; nothing is drawn from the shared random.
  void _layFlock(
    double passageX,
    double lane,
    int appearance,
    List<SkyStar> trio,
  ) {
    final entry = _pigeonEntries++;
    final level = plan;
    final size = level is LevelPlan ? level.flockSizeFor(entry) : 1;
    // One draw for a formation of one or two, from the plan's own random
    // (a level's is seeded from the level and the formation, never from the
    // flight's shared random, so pigeons move nothing else).
    final slots = trio.length == 3
        ? AlleyPigeon.preySlots(
            size,
            size == 3
                ? 0
                : (level is LevelPlan
                          ? level.flockRandom(entry, random)
                          : math.Random(entry + 1))
                      .nextInt(size == 1 ? 3 : 2),
          )
        : const <int>[];
    final side = AlleyPigeon.sideFor(lane);
    for (var j = 0; j < size; j++) {
      final prey = j < slots.length ? trio[slots[j]] : null;
      final hover = AlleyPigeon.hover(
        slot: j,
        preyX: prey?.x ?? passageX + AlleyPigeon.trioX[1],
        lane: lane,
        side: side,
      );
      final enemy = SkyEnemy(
        x: hover.x,
        y: hover.y,
        appearance: appearance,
        maxHp: _enemyHealth(appearance),
        flightPhase: (_index * 3 + j) * AlleyPigeon.phaseStep,
      );
      final raid = enemy.pigeon!
        ..slot = j
        ..flockSize = size
        ..side = side
        ..prey = prey
        ..laid = true
        ..homeX = hover.x
        ..homeY = hover.y
        ..pathX = hover.x
        ..pathY = hover.y;
      prey?.thief = enemy;
      assert(raid.phase == PigeonPhase.glide);
      enemies.add(enemy);
    }
  }

  /// One step of every formation pigeon, after the bird's contact test and
  /// before shooters fire. [scroll] is the course's speed this step.
  void _advancePigeons(double dt, double scroll, double width) {
    if (_pigeonEntries > 0) {
      // A freed star hops and floats back to its gate line.
      for (final star in stars) {
        final at = star.freedAt;
        if (at != null) {
          star.heldY = AlleyPigeon.floatY(
            elapsed - at,
            star.freedY!,
            star.gateY,
          );
        }
      }
    }
    List<SkyEnemy>? gone;
    for (final enemy in enemies) {
      final raid = enemy.pigeon;
      if (raid == null || !raid.laid) continue;
      if (!_advanceRaid(enemy, raid, dt, scroll, width)) {
        (gone ??= []).add(enemy);
      }
    }
    if (gone != null) enemies.removeWhere(gone.contains);
  }

  /// Returns false when the pigeon has left the screen.
  bool _advanceRaid(
    SkyEnemy enemy,
    PigeonFlight raid,
    double dt,
    double scroll,
    double width,
  ) {
    // A damaging hit since the last step (a rock or a shatter blast that did
    // not kill it): it spooks a hunter and frees a thief's star.
    if (enemy.lastHitAt > raid.seenHitAt) {
      raid.seenHitAt = enemy.lastHitAt;
      _pigeonStruck(enemy, raid);
    }
    raid.homeX -= scroll * dt;
    switch (raid.phase) {
      case PigeonPhase.glide:
        _glide(enemy, raid, width);
      case PigeonPhase.warning:
        _warn(enemy, raid, width);
      case PigeonPhase.dive:
        _dive(enemy, raid);
      case PigeonPhase.carry || PigeonPhase.flee:
        final off = AlleyPigeon.flee(enemy.age - raid.phaseAt, raid.side);
        _placePigeon(enemy, raid, raid.homeX + off.dx, raid.homeY + off.dy);
        if (AlleyPigeon.leaves(x: enemy.x, y: raid.pathY, width: width)) {
          if (raid.loot != null) _loseStar(enemy, raid);
          return false;
        }
        if (raid.loot case final star?) {
          // The star rides on the thief.
          star.x = enemy.x;
          star.heldY = enemy.y;
        }
    }
    return true;
  }

  void _placePigeon(SkyEnemy enemy, PigeonFlight raid, double x, double y) {
    raid.pathX = x;
    raid.pathY = y;
    enemy.placeAt(x, y);
  }

  /// Hovering over its prey, flying in from the right until its home is
  /// near the edge. It begins its warning when the prey is close enough to
  /// be seen and far enough for a fair dive; it gives the prey up when the
  /// prey is gone or already too close.
  void _glide(SkyEnemy enemy, PigeonFlight raid, double width) {
    var prey = raid.prey;
    if (prey != null && _preyGone(enemy, prey)) {
      _dropPrey(enemy, raid);
      prey = null;
    }
    if (prey != null &&
        prey.x <=
            math.min(width - AlleyPigeon.warnEdge, AlleyPigeon.warnReach)) {
      if (!AlleyPigeon.mayWarn(
        preyX: prey.x,
        birdX: _frontX,
        width: width,
        speed: speed,
      )) {
        // Too close for a fair dive (or a screen too narrow): preyless for
        // good, it glides on like a bat.
        _dropPrey(enemy, raid);
      } else if (starsLost + thievesCommitted < thiefBudget) {
        raid.phase = PigeonPhase.warning;
        raid.phaseAt = enemy.age;
        pigeonWarnings++;
      }
    }
    _hover(enemy, raid, width);
  }

  void _hover(SkyEnemy enemy, PigeonFlight raid, double width) {
    final arrival = AlleyPigeon.arrival(
      homeX: raid.homeX,
      width: width,
      side: raid.side,
    );
    _placePigeon(enemy, raid, raid.homeX + arrival.dx, raid.homeY + arrival.dy);
  }

  void _warn(SkyEnemy enemy, PigeonFlight raid, double width) {
    final prey = raid.prey;
    if (prey == null || _preyLost(enemy, prey)) {
      _flee(enemy, raid);
      return;
    }
    if (enemy.age - raid.phaseAt >= AlleyPigeon.warningSeconds) {
      raid.phase = PigeonPhase.dive;
      raid.phaseAt = enemy.age;
      pigeonDives++;
      _dive(enemy, raid);
      return;
    }
    _hover(enemy, raid, width);
  }

  void _dive(SkyEnemy enemy, PigeonFlight raid) {
    final prey = raid.prey;
    if (prey == null || _preyLost(enemy, prey)) {
      _flee(enemy, raid);
      return;
    }
    final u = (enemy.age - raid.phaseAt) / AlleyPigeon.diveSeconds;
    final at = AlleyPigeon.dive(
      u,
      (x: raid.homeX, y: raid.homeY),
      (x: prey.x, y: prey.y),
    );
    _placePigeon(enemy, raid, at.x, at.y);
    if (u < 1) return;
    // The snatch, at the star's centre.
    prey.carried = true;
    prey.x = at.x;
    prey.heldY = at.y;
    raid
      ..loot = prey
      ..phase = PigeonPhase.carry
      ..phaseAt = enemy.age
      ..snatchedAt = enemy.age
      ..homeX = at.x
      ..homeY = at.y;
    enemy.lastShotAt = enemy.age;
    starsSnatched++;
  }

  /// Whether the star this pigeon is bound to is no longer its to take.
  bool _preyGone(SkyEnemy enemy, SkyStar prey) =>
      prey.collected || prey.missed || prey.carried || prey.thief != enemy;

  /// Whether a pigeon already warning or diving must give up its prey: gone,
  /// or so close to the bird that the dive would be an ambush.
  bool _preyLost(SkyEnemy enemy, SkyStar prey) =>
      _preyGone(enemy, prey) ||
      prey.x <= _frontX + AlleyPigeon.whiffGuard;

  void _dropPrey(SkyEnemy enemy, PigeonFlight raid) {
    final prey = raid.prey;
    if (prey != null && prey.thief == enemy) prey.thief = null;
    raid.prey = null;
  }

  /// A dive whiffs, or a hunter is spooked: it leaves with nothing, from
  /// where it is.
  void _flee(SkyEnemy enemy, PigeonFlight raid) {
    _dropPrey(enemy, raid);
    raid
      ..phase = PigeonPhase.flee
      ..phaseAt = enemy.age
      ..homeX = raid.pathX
      ..homeY = raid.pathY;
  }

  /// A damaging hit that left the pigeon alive.
  void _pigeonStruck(SkyEnemy enemy, PigeonFlight raid) {
    switch (raid.phase) {
      case PigeonPhase.glide || PigeonPhase.warning || PigeonPhase.dive:
        raid.spooked = true;
        _flee(enemy, raid);
      case PigeonPhase.carry:
        // The star drops out of the beak and floats back; the climb away
        // carries on from where the gloat had got to.
        _winBack(enemy, raid, atBird: false);
        raid.phase = PigeonPhase.flee;
      case PigeonPhase.flee:
        break;
    }
  }

  /// Takes the carried star from its thief. [atBird]: a ram or a touch drops
  /// it into the bird's beak, collected on the next step; otherwise it
  /// appears at the pigeon, hops and floats back to its gate line (a freed
  /// star the bird misses does not reset the streak).
  void _winBack(SkyEnemy enemy, PigeonFlight raid, {required bool atBird}) {
    final star = raid.loot;
    if (star == null) return;
    star
      ..carried = false
      ..thief = null;
    raid
      ..loot = null
      ..prey = null;
    starsFreed++;
    star.rescued = true;
    if (atBird) {
      final bird = _nearestBird(enemy.x, enemy.y);
      star.x = bird.x + AlleyPigeon.dropX;
      star.heldY = bird.y;
    } else {
      star.freedAt = elapsed;
      star.freedY = star.y;
    }
  }

  /// The thief got away: the star is gone for good and its trio forfeited.
  /// Nothing else is lost.
  void _loseStar(SkyEnemy enemy, PigeonFlight raid) {
    final star = raid.loot;
    if (star == null) return;
    star
      ..carried = false
      ..thief = null
      ..missed = true;
    if (supportsStarTrios) star.trio?.missed = true;
    stars.remove(star);
    raid
      ..loot = null
      ..prey = null;
    starsLost++;
  }

  /// Any pigeon's defeat (a rock, a blast or a ram): counted for the audio,
  /// and a carried star is won back. King Coo's squadron pigeons count too.
  void _pigeonDefeated(SkyEnemy enemy, {required bool rammed}) {
    if (enemy.kind != EnemyKind.alleyPigeon) return;
    pigeonsDefeated++;
    final raid = enemy.pigeon;
    if (raid == null) return;
    _winBack(enemy, raid, atBird: rammed);
    _dropPrey(enemy, raid);
  }

  /// A pigeon leaves without being defeated: the bird flew into it (a touch
  /// frees its star into the bird's beak) or it drifted off the left edge (a
  /// thief takes its star for good).
  void _pigeonGone(SkyEnemy enemy, {bool atBird = false}) {
    final raid = enemy.pigeon;
    if (raid == null) return;
    if (raid.loot != null) {
      if (atBird) {
        _winBack(enemy, raid, atBird: true);
      } else {
        _loseStar(enemy, raid);
      }
    }
    _dropPrey(enemy, raid);
  }
}
