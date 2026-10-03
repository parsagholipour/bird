part of 'game_rules.dart';

/// King Coo's rules inside the flight (rules version 43, campaign only; spec
/// `reports/05-king-coo.md` §2). The timing and geometry are pure ([KingCoo],
/// [CrumbLob], [SquadTrack]); this is the part that reads the bird and acts:
///
///  * a crumb bomb's ring locks on the bird's height at each lock time of the
///    cycle, and its cloud hurts like a course edge for one second;
///  * the puff plans a squadron from where the bird is, the whistle calls it
///    (unless a pop got there first), and its pigeons fly their tracks;
///  * the chest's half and double damage and the pop live in
///    `SkyBoss.strike`, so a rock and a shatter blast both use them;
///  * from rules version 54 the cycle he grows furious in ends early, once
///    its quiet tail begins ([SkyBoss.quickRestart]).
///
/// Nothing here draws a random, and every time is an exact cycle time of the
/// boss's clock, so a replay (or a seek that re-simulates) is exact at any
/// frame rate. Called once per step from `_advanceBoss`, only while he fights.
extension _KingCooRules on FlightSimulation {
  void _advanceCoo(SkyBoss coo) {
    if (coo.quickRestart) _restartCoo(coo);
    final cycle = coo.cooCycleNumber;
    if (cycle < 0) return;
    final at = coo.cooCycle;
    final cycleStart = coo.cooCycleStart(cycle);

    // Crumb bombs: each ring locks on the bird's height as it is now, and the
    // cloud it will drop 2.2 s later stays where it locked. Fury is latched at
    // a cycle's first ring, so one cycle never mixes a single cloud and a
    // bracket (the fairness proof's chains).
    if (cycle != coo.lobCycle) {
      coo.lobCycle = cycle;
      coo.lobsInCycle = 0;
    }
    if (coo.lobsInCycle == 0 && at >= KingCoo.locks(fury: false).first) {
      coo.lobFury = coo.enraged;
    }
    if (coo.lobsInCycle > 0 || at >= KingCoo.locks(fury: false).first) {
      final locks = KingCoo.locks(fury: coo.lobFury);
      while (coo.lobsInCycle < locks.length && at >= locks[coo.lobsInCycle]) {
        // Each ring takes its turn at a bird of the flock (the lead, alone).
        final aim = _target(coo.lobs.length);
        coo.lobs.add(
          CrumbLob(
            lockedAt: cycleStart + locks[coo.lobsInCycle],
            lockX: aim.x,
            lockY: aim.y.clamp(KingCoo.lockMin, KingCoo.lockMax),
            fury: coo.lobFury,
          ),
        );
        coo.lobsInCycle++;
      }
    }

    // The puff: the window opens, and the squadron is planned from where the
    // bird is now. Its lanes are fixed from here on.
    if (coo.puffs > coo.puffsLatched) {
      coo.puffsLatched = coo.puffs;
      coo.puffDamage = 0;
      coo.squadReleased = 0;
      coo.squadCalled = false;
      coo.cancelledSquad = const [];
      // A staged King Coo's warm-up puffs but plans no squadron, and his fury
      // (a long one, rules 44) brings three crumb rings but keeps the single
      // V: fury's picket behind it is the 43 fight's short finale.
      coo.squad = coo.signatureArmed(cycle)
          ? KingCoo.squad(
              cycle: cycle,
              birdY: _target(coo.puffsLatched - 1).y,
              fury: coo.enraged && !coo.staged,
            )
          : const [];
    }
    // A pop before the whistle cancels the call: no lanes, no whistle (the
    // art keeps the cancelled plan to dissolve it).
    if (coo.popped && !coo.squadCalled && coo.squad.isNotEmpty) {
      coo.cancelledSquad = coo.squad;
      coo.squad = const [];
    }
    if (coo.whistlesDue > coo.whistlesLatched) {
      coo.whistlesLatched = coo.whistlesDue;
      if (!coo.popped && coo.signatureArmed(cycle)) {
        coo.whistles++;
        coo.squadCalled = true;
      }
    }
    // The whistle releases the squadron (fury's picket a beat behind its V);
    // once called, a late pop does not recall it.
    if (coo.squadCalled) {
      final whistleAt = cycleStart + KingCoo.whistleAt;
      while (coo.squadReleased < coo.squad.length) {
        final plan = coo.squad[coo.squadReleased];
        if (coo.age < whistleAt + plan.delay) break;
        _releaseSquad(coo, plan, whistleAt + plan.delay);
        coo.squadReleased++;
      }
    }
    for (final enemy in enemies) {
      if (enemy.track case final track?) {
        enemy
          ..x = track.x(coo.age)
          ..y = track.y(coo.age);
      }
    }

    // A live cloud hurts like a course edge. It is screen-fixed (a sprint
    // cannot move it) and drawn radius is hurt radius.
    for (var i = coo.lobs.length - 1; i >= 0; i--) {
      final lob = coo.lobs[i];
      if (lob.cloudEndsAt <= coo.age) break;
      final reach = lob.cloudRadius(coo.age);
      if (reach <= 0) continue;
      final within = reach + FlightSimulation.birdRadius;
      for (final bird in flock) {
        final dx = bird.x - lob.lockX;
        final caught = lob.cloudHeights.any((y) {
          final dy = bird.y - y;
          return dx * dx + dy * dy <= within * within;
        });
        if (caught) {
          _crumbed(coo, bird);
          return;
        }
      }
    }
  }

  /// The cycle King Coo grows furious in (the last of his stages) ends as
  /// soon as nothing of it is left: his roar is over, the puff window has
  /// closed (or he has got over its pop), every crumb has settled and every
  /// squadron pigeon has passed the birds. His first fury cycle begins
  /// then, so its first ring locks .6 s later, not after the rest of the
  /// 14 s. Once a fight, and only in that quiet tail, which holds no beat
  /// of the cycle: the clock skips none.
  void _restartCoo(SkyBoss coo) {
    if (coo.stageReached < 2 || coo.cooRestartAt.isFinite) return;
    final cycle = coo.cooCycleNumber;
    if (cycle < 0 ||
        cycle != KingCoo.cycleNumber(coo.cooClockAt(coo.stageUpAt))) {
      return;
    }
    final age = coo.age;
    if (age < coo.stageUpAt + SkyBoss.stageRoar) return;
    final settled = coo.popped
        ? age >= coo.poppedAt! + KingCoo.popRecovery
        : coo.cooCycle >= KingCoo.windowEnd + KingCoo.puffRelease;
    if (!settled) return;
    if (coo.lobs.isNotEmpty && coo.lobs.last.crumbsEndAt > age) return;
    final column = _rearX;
    for (final enemy in enemies) {
      if (enemy.track case final track?) {
        final clear =
            track.crossesAt(column) + KingCoo.pigeonReach / KingCoo.squadSpeed;
        if (age < clear) return;
      }
    }
    coo.restartCoo();
    cooRestarts++;
  }

  /// One plan's pigeons leave the boss at boss-age [at], at the chest's x
  /// (wing slots a little behind it), on their tracks. They are Alley Pigeons
  /// that never snatch ([SkyEnemy.squad]), scroll with nothing (`drift` 0)
  /// and die like any small enemy: a rock or a ram kills, touching hurts.
  void _releaseSquad(SkyBoss coo, SquadPlan plan, double at) {
    final appearance = EnemyKind.alleyPigeon.index;
    for (final (i, slot) in plan.slots.indexed) {
      final track = SquadTrack(
        x0: coo.x + slot.behind,
        fromY: coo.y,
        lane: slot.y,
        bornAt: at,
      );
      enemies.add(
        SkyEnemy(
          x: track.x(coo.age),
          y: track.y(coo.age),
          appearance: appearance,
          maxHp: _enemyHealth(appearance),
          flightPhase:
              ((coo.whistles * 2 + coo.squadReleased) * 7 + i) * 2.399963,
          drift: 0,
          squad: true,
        )..track = track,
      );
    }
  }

  /// A crumb cloud hurts like the dragon's flame or a course edge: the
  /// recovery that follows gives [bird] time to leave the cloud.
  void _crumbed(SkyBoss coo, FlightBird bird) {
    if (!collectsStars) {
      end(EndReason.collision);
      return;
    }
    if (viewing(bird, () => elapsed >= invulnerableUntil)) coo.crumbHits++;
    _hurt(bird);
  }
}
