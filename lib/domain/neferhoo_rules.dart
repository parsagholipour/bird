part of 'game_rules.dart';

/// Neferhoo's rules inside the flight (rules version 50, campaign only; spec
/// `egypt-ws/reports/01-egypt-guardian.md` §3, staged by
/// `egypt-int/MASTER-PLAN.md` §2). The timing and geometry are pure
/// ([Neferhoo], [NeferhooLetter], [NeferhooAnkh]); this is the part that reads
/// the bird and acts:
///
///  * each cycle's mail call locks its lane on the bird's height and deals
///    its letters down it (three; the express post's five in fury, latched
///    at the lock);
///  * from the full fight on (the staged boss's signature, see
///    [SkyBoss.signatureArmed]) the ankh locks its two lanes and is thrown
///    out and back (two mirrored ankhs in fury, latched at the lock);
///  * a rock that meets a letter in the bird's own band sends it home, where
///    it lands once for [Neferhoo.returnDamage]; a charged rock (the bulk
///    return) sends back every letter it meets and carries on; a sprinting
///    bird that meets a letter sends it back too;
///  * a letter or an ankh that touches a bird hurts it like a course edge;
///    a letter that touches a bird is spent either way;
///  * a rock on his wraps deals a third ([Neferhoo.wrapsDamage]), in
///    `SkyBoss.strike`;
///  * in the tougher fight (rules version 52, [SkyBoss.tougherNeferhoo]) the
///    letters fly [Neferhoo.tougherPace] times faster there and back, and
///    each mail call from the full fight on latches its mummy bats
///    ([Neferhoo.batsFor]), which fly in from the right edge down its lane
///    behind its letters, small enemies from then on ([EnemyKind.mummyBat]);
///  * in the faster fight (rules version 55, [SkyBoss.fasterNeferhoo]) the
///    calls follow its own clock ([NeferhooBeats.faster], `_latchFasterCalls`)
///    and a returned letter deals [Neferhoo.fasterReturnDamage].
///
/// Every latch time is an exact cycle time of the boss's clock where the
/// clock decides it (locks, releases, throws, homecomings, landings) and the
/// boss's age at the step where a rock or a bird decides it (a catch, a
/// hurt). Nothing here draws a random, so a replay, or a seek that
/// re-simulates, is exact. The boss is defeated by a landing exactly as by a
/// rock (`_defeatBoss`), and a defeat leaves nothing live: the getters the
/// art reads are empty once he stops fighting, and these entry points do
/// nothing then.
extension _NeferhooRules on FlightSimulation {
  /// Once per step while he fights (after his position is set): the mail
  /// call's lock and its letters, the ankh's lock and throw, the returned
  /// letters that land (each [SkyBoss.takeDamage] of
  /// [Neferhoo.returnDamage], then `_defeatBoss` at 0 hp), and the letters
  /// and ankhs that have gone.
  void _advanceNeferhoo(SkyBoss courier, double viewportWidth) {
    final combat = courier.combatTime;
    if (combat < 0 || courier.phase != BossPhase.attacking) return;
    final fight = courier.neferhoo;
    final start = courier.arrivalDuration;
    final age = courier.age;

    final beats = courier.neferhooBeats;
    // The faster fight (rules 55) latches its calls off its own clock.
    if (beats.isFaster) _latchFasterCalls(courier, viewportWidth);
    // The mail call: every cycle, from the warm-up on. Its lane locks on the
    // bird (the flock's take turns) and the express post is latched here,
    // so a stream never changes on its way.
    final mailDue = beats.isFaster
        ? 0
        : Neferhoo.count(combat, Neferhoo.mailLockAt);
    while (fight.mailLocks < mailDue) {
      final cycle = fight.mailLocks;
      final lockedAt = start + cycle * Neferhoo.period + Neferhoo.mailLockAt;
      final express = courier.enraged;
      final tougher = courier.tougherNeferhoo;
      final lane = Neferhoo.laneFor(_target(cycle).y);
      final gap = Neferhoo.gap(fury: express);
      final pace = Neferhoo.letterSpeedOf(fury: express, tougher: tougher);
      for (var k = 0; k < Neferhoo.streamCount(fury: express); k++) {
        fight.letters.add(
          NeferhooLetter(
            cycle: cycle,
            index: k,
            lane: lane,
            releaseAt: lockedAt + Neferhoo.windupSeconds + k * gap,
            speed: pace,
            express: express,
          ),
        );
      }
      // The tougher fight's mummy bats follow the letters down the lane:
      // latched here with the stream, so the lane drawn at the lock shows
      // where they will fly (the art keeps it until they have passed).
      final bats = tougher ? Neferhoo.batsFor(courier.stage) : 0;
      for (var k = 0; k < bats; k++) {
        fight.bats.add(
          NeferhooBat(
            cycle: cycle,
            index: k,
            lane: lane,
            launchAt:
                lockedAt +
                Neferhoo.batLaunch(k, fury: express, width: viewportWidth),
            pace: express ? Neferhoo.furyBatPace : Neferhoo.batPace,
            fury: express,
          ),
        );
      }
      fight
        ..laneY = lane
        ..mailLockedAt = lockedAt
        ..express = express
        ..mailLocks = cycle + 1;
    }
    while (fight.lettersDealt < fight.letters.length &&
        fight.letters[fight.lettersDealt].dealtBy(age)) {
      fight.lettersDealt++;
    }
    // Mummy bats fly in on their times; one that was downed, rammed, met the
    // bird or flew off the left edge is latched gone.
    while (fight.batsLaunched < fight.bats.length &&
        age >= fight.bats[fight.batsLaunched].launchAt) {
      _launchBat(courier, fight.bats[fight.batsLaunched++], viewportWidth);
    }
    for (final bat in fight.bats) {
      final enemy = bat.enemy;
      if (enemy == null) break;
      if (bat.goneAt == null && !enemies.contains(enemy)) bat.goneAt = age;
    }

    // The ankh: his signature, only in the cycles it is armed for (a staged
    // fight's warm-up throws none). Both lanes lock on the bird; fury's
    // second ankh flies the mirrored loop half a second behind.
    final ankhDue = beats.count(combat, beats.ankhLockAt);
    while (fight.ankhMoments < ankhDue) {
      final cycle = fight.ankhMoments++;
      if (!courier.signatureArmed(cycle)) continue;
      final lockedAt = start + cycle * beats.period + beats.ankhLockAt;
      final thrownAt = lockedAt + Neferhoo.ankhThrowAt - Neferhoo.ankhLockAt;
      final two = courier.enraged;
      final speed = two ? Neferhoo.furyAnkhSpeed : Neferhoo.ankhSpeed;
      final a = Neferhoo.ankhLaneFor(_target(fight.ankhLocks).y);
      final b = Neferhoo.backLane(a);
      fight.ankhs.add(
        NeferhooAnkh(
          cycle: cycle,
          laneA: a,
          laneB: b,
          lockedAt: lockedAt,
          thrownAt: thrownAt,
          speed: speed,
        ),
      );
      if (two) {
        fight.ankhs.add(
          NeferhooAnkh(
            cycle: cycle,
            laneA: b,
            laneB: a,
            lockedAt: lockedAt,
            thrownAt: thrownAt + Neferhoo.furyAnkhDelay,
            speed: speed,
            second: true,
          ),
        );
      }
      fight
        ..ankhLockedAt = lockedAt
        ..twoAnkhs = two
        ..ankhLocks += 1;
    }
    while (fight.ankhThrows < fight.ankhs.length &&
        age >= fight.ankhs[fight.ankhThrows].thrownAt) {
      fight.ankhThrows++;
    }
    final handX = courier.handX;
    final turnX = Neferhoo.turnX(FlightSimulation.birdX);
    for (final ankh in fight.ankhs) {
      if (ankh.caughtAt != null || age < ankh.thrownAt) continue;
      final home = ankh.homeAt(handX: handX, turnX: turnX);
      if (age < home) continue;
      ankh.caughtAt = home;
      fight.ankhCatches++;
    }

    // Letters: a returned one lands once, home on his chest; one that has
    // flown off the left edge is gone.
    for (final letter in fight.letters) {
      if (letter.gone || !letter.dealtBy(age)) continue;
      final home = letter.homeAt;
      if (home != null) {
        if (age < home) continue;
        // Latched at this step, as the 25 lands ([SkyBoss.lastHitAt] is
        // this age too): the art tells a landing from a scuff by it.
        letter.landedAt = age;
        fight
          ..returnsLanded += 1
          ..lastLandAt = age;
        courier.takeDamage(
          Neferhoo.returnDamageOf(faster: courier.fasterNeferhoo),
        );
        if (courier.hp == 0) {
          _defeatBoss(courier);
          return;
        }
      } else if (letter.xAt(age, handX) < -.1) {
        letter.spentAt = age;
      }
    }
  }

  /// A rock that has just moved from [previousX] to its place this step,
  /// tested against Neferhoo's letters (swept over the step, the addressee
  /// rule's band): true when it caught one and is spent, false when there
  /// was nothing to catch or it carries on (a charged rock's bulk return).
  /// Called for every live rock of every step, so it returns at once unless
  /// the boss is Neferhoo, fighting, under [supportsNeferhoo].
  bool _neferhooCatches(BirdRock rock, double previousX) {
    final courier = boss;
    if (courier == null ||
        !courier.isNeferhoo ||
        !supportsNeferhoo ||
        courier.phase != BossPhase.attacking) {
      return false;
    }
    final fight = courier.neferhoo;
    final age = courier.age, handX = courier.handX;
    // The step the rock just flew (letters fly a known speed, so where each
    // was a step ago follows).
    final step = rock.velocityX > 0 ? (rock.x - previousX) / rock.velocityX : 0;
    final bulk = Neferhoo.bulkReturns(rock.charge);
    for (final letter in fight.letters) {
      if (letter.returned || letter.gone || !letter.dealtBy(age)) continue;
      if (!Neferhoo.catches(rock.y, letter.lane)) continue;
      final x = letter.xAt(age, handX);
      if (!Neferhoo.catchesAcross(
        previousX,
        rock.x,
        rock.radius,
        x + letter.speed * step,
        x,
      )) {
        continue;
      }
      _returnLetter(courier, letter, x);
      if (!bulk) return true;
    }
    return false;
  }

  /// Once per physics substep while a boss is Neferhoo: a letter or an ankh
  /// that touches a bird hurts it like a course edge (`_hurt`), a sprinting
  /// bird that meets a letter returns it.
  void _neferhooHazards(SkyBoss courier) {
    if (courier.phase != BossPhase.attacking) return;
    final fight = courier.neferhoo;
    final age = courier.age, handX = courier.handX;
    for (final letter in fight.letters) {
      if (letter.returned || letter.gone || !letter.dealtBy(age)) continue;
      final x = letter.xAt(age, handX);
      for (final bird in flock) {
        if (!Neferhoo.letterTouches(
          x,
          letter.lane,
          bird.x,
          bird.y,
          FlightSimulation.birdRadius,
        )) {
          continue;
        }
        if (_rams(bird)) {
          // A ram counts as a shot.
          _returnLetter(courier, letter, x);
          break;
        }
        letter
          ..spentAt = age
          ..delivered = true;
        if (!collectsStars) {
          end(EndReason.collision);
          return;
        }
        if (viewing(bird, () => elapsed >= invulnerableUntil)) {
          fight.letterHits++;
        }
        _hurt(bird);
        if (phase == RunPhase.ended) return;
        break;
      }
    }
    final turnX = Neferhoo.turnX(FlightSimulation.birdX);
    for (final ankh in fight.ankhs) {
      if (ankh.caughtAt != null) continue;
      final at = ankh.at(age, handX: handX, turnX: turnX);
      if (at == null) continue;
      for (final bird in flock) {
        const reach = FlightSimulation.birdRadius;
        if (!Neferhoo.ankhTouches(at, bird.x, bird.y, reach)) continue;
        // Sprint or not: the ankh is gold, and it comes back.
        if (!collectsStars) {
          end(EndReason.collision);
          return;
        }
        if (viewing(bird, () => elapsed >= invulnerableUntil)) {
          fight.ankhHits++;
        }
        _hurt(bird);
        if (phase == RunPhase.ended) return;
      }
    }
  }

  /// The faster fight's calls (rules 55, [NeferhooBeats.faster]), latched
  /// at each call moment of its clock in time order: the cycle's first mail
  /// call (its letters, then its mummy bats behind them: a pair from the
  /// warm-up on, a trio in the full fight, four in fury); in a cycle the
  /// ankh does not run in (the warm-up), a wave of [Neferhoo.waveBats] bats
  /// down a lane locked on the bird; in a cycle it runs in, the second mail
  /// call (letters alone) once its return pass is over. Each lane locks on
  /// the bird, the express post is latched at the lock, and each call is kept
  /// as a [NeferhooCall] for the art's telegraphs.
  void _latchFasterCalls(SkyBoss courier, double viewportWidth) {
    final fight = courier.neferhoo;
    final beats = courier.neferhooBeats;
    final moments = beats.callMoments;
    final combat = courier.combatTime;
    final start = courier.arrivalDuration;
    while (true) {
      final k = fight.callMoments;
      final cycle = k ~/ moments.length;
      final (at, kind) = moments[k % moments.length];
      if (beats.count(combat, at) <= cycle) return;
      fight.callMoments = k + 1;
      final armed = courier.signatureArmed(cycle);
      if (kind == NeferhooCallKind.wave && armed) continue;
      if (kind == NeferhooCallKind.second && !armed) continue;
      final lockedAt = start + cycle * beats.period + at;
      final express = courier.enraged;
      final lane = Neferhoo.laneFor(_target(fight.mailLocks + fight.waves).y);
      final number = fight.calls.length;
      final letters = kind == NeferhooCallKind.wave
          ? 0
          : Neferhoo.streamCount(fury: express);
      fight.calls.add(
        NeferhooCall(
          number: number,
          cycle: cycle,
          kind: kind,
          lane: lane,
          lockedAt: lockedAt,
          express: express,
          letters: letters,
        ),
      );
      if (kind == NeferhooCallKind.wave) {
        for (var b = 0; b < Neferhoo.waveBats; b++) {
          fight.bats.add(
            NeferhooBat(
              cycle: cycle,
              index: b,
              lane: lane,
              launchAt: lockedAt + Neferhoo.waveLaunch(b),
              pace: Neferhoo.batPace,
              fury: false,
              call: number,
            ),
          );
        }
        fight
          ..waves += 1
          ..waveLockedAt = lockedAt;
        continue;
      }
      final gap = Neferhoo.gap(fury: express);
      final pace = Neferhoo.letterSpeedOf(fury: express, tougher: true);
      for (var l = 0; l < letters; l++) {
        fight.letters.add(
          NeferhooLetter(
            cycle: cycle,
            index: l,
            lane: lane,
            releaseAt: lockedAt + Neferhoo.windupSeconds + l * gap,
            speed: pace,
            express: express,
            call: number,
          ),
        );
      }
      final bats = kind == NeferhooCallKind.first
          ? Neferhoo.batsFor(courier.stage, faster: true)
          : 0;
      for (var b = 0; b < bats; b++) {
        fight.bats.add(
          NeferhooBat(
            cycle: cycle,
            index: b,
            lane: lane,
            launchAt:
                lockedAt +
                Neferhoo.batLaunch(b, fury: express, width: viewportWidth),
            pace: express ? Neferhoo.furyBatPace : Neferhoo.batPace,
            fury: express,
            call: number,
          ),
        );
      }
      fight
        ..laneY = lane
        ..mailLockedAt = lockedAt
        ..express = express
        ..mailLocks += 1;
    }
  }

  /// A mummy bat flies in from the right edge ([Neferhoo.batStartX], the
  /// pyramid's side) at the height of its call's lane, a small enemy from
  /// now on: the simple bat's flight arc (its own phase), settling into the
  /// lane on its final approach, closing in at its drift of the scroll
  /// speed set so that it flies at its pace (the scroll speed now, without a
  /// sprint's boost). A rock of any weapon downs it.
  void _launchBat(SkyBoss courier, NeferhooBat bat, double viewportWidth) {
    final enemy = SkyEnemy(
      x: Neferhoo.batStartX(viewportWidth),
      y: bat.lane,
      appearance: EnemyKind.mummyBat.index,
      maxHp: Neferhoo.batHp,
      flightPhase:
          ((bat.call >= 0 ? bat.call : bat.cycle) * 3 + bat.index) * 2.399963,
      drift: bat.pace / speed,
    );
    enemies.add(enemy);
    bat.enemy = enemy;
    courier.neferhoo.lastBatAt = courier.age;
  }

  /// Sends [letter], struck at screen x [x], home: harmless from now on, it
  /// lands on his chest [Neferhoo.returnSecondsOf] of its distance later.
  void _returnLetter(SkyBoss courier, NeferhooLetter letter, double x) {
    final dx = courier.x - x, dy = courier.y - letter.lane;
    final age = courier.age;
    // Letters sent back together (a bulk return near his hand) land one
    // after another, never two in one step: each landing is its own thud,
    // cue and line.
    var home =
        age +
        Neferhoo.returnSecondsOf(
          math.sqrt(dx * dx + dy * dy),
          tougher: courier.tougherNeferhoo,
        );
    for (var moved = true; moved;) {
      moved = false;
      for (final other in courier.neferhoo.letters) {
        final pending = other.homeAt;
        if (pending == null || other.landedAt != null) continue;
        if ((home - pending).abs() < Neferhoo.landingGap - 1e-9) {
          home = pending + Neferhoo.landingGap;
          moved = true;
        }
      }
    }
    letter
      ..returnedAt = age
      ..struckX = x
      ..struckY = letter.lane
      ..homeAt = home;
    courier.neferhoo
      ..lettersReturned += 1
      ..scuffsSinceReturn = 0
      ..lastReturnAt = age;
  }
}
