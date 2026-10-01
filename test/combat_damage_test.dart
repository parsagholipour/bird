import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/combat_audio_cues.dart';
import 'boss_fight_test.dart' show arena, step, hover, snapshot;
import 'recorded_flight.dart';
import 'touch_combat_test.dart' show playing, tick;

void main() {
  test(
    'partial damage consumes ammo, but only a kill awards points and audio',
    () {
      final sim = playing();
      final enemy = SkyEnemy(x: 1.2, y: .5, maxHp: 25);
      final behind = SkyEnemy(x: 1.3, y: .5, maxHp: 25);
      sim.enemies.addAll([enemy, behind]);
      final audio = CombatAudioCues()..advance(sim, silent: true);
      sim.rocks.add(BirdRock(x: 1.2, y: .5));
      tick(sim, .001);
      expect(enemy.hp, 15);
      expect(behind.hp, 25);
      expect(sim.rocks, isEmpty);
      expect(sim.enemiesDefeated, 0);
      expect(sim.score, 0);
      expect(sim.events, isEmpty);
      expect(audio.advance(sim), ['rock_hit']);

      sim.rocks.add(BirdRock(x: enemy.x, y: enemy.y, damage: 100));
      tick(sim, .001);
      expect(enemy.hp, 0);
      expect(behind.hp, 25);
      expect(sim.enemies, [behind]);
      expect(sim.enemiesDefeated, 1);
      expect(sim.score, 3);
      expect(
        sim.events.where((e) => e.kind == FlightEventKind.enemyHit),
        hasLength(1),
      );
      expect(audio.advance(sim), ['enemy_death']);
      tick(sim, .001);
      expect(audio.advance(sim), isEmpty);
      expect(sim.score, 3);
    },
  );

  test('upgrades affect new shots while airborne ammo retains its damage', () {
    final sim = playing();
    sim.shoot();
    final original = sim.rocks.single;
    expect(original.damage, 10);
    sim.setWeaponDamage(25);
    expect(sim.shoot(), isFalse, reason: 'Upgrading does not bypass cooldown');
    sim.elapsed += FlightSimulation.shotCooldown;
    expect(sim.shoot(), isTrue);
    expect(sim.rocks.map((r) => r.damage), [10, 25]);
    final enemy = SkyEnemy(x: .9, y: original.y, maxHp: 30);
    sim.enemies.add(enemy);
    tick(sim, .2);
    expect(enemy.hp, 0);
    expect(sim.enemiesDefeated, 1);
  });

  test('ordinary enemies and helpers share capped encounter health', () {
    for (final defeated in [0, 2, 10]) {
      final sim = arena(version: 26)
        ..elapsed = 0
        ..bossesDefeated = defeated;
      step(sim);
      final enemy = sim.enemies.single;
      expect(enemy.maxHp, 10 + defeated.clamp(0, 4) * 5);
      final originalHp = enemy.hp;
      sim.setWeaponDamage(100);
      expect(enemy.hp, originalHp);

      sim.elapsed = FlightSimulation.bossInterval;
      step(sim);
      final boss = sim.boss!;
      boss.age = boss.arrivalDuration;
      boss.summonIn = 0;
      step(sim);
      final helper = sim.enemies.single;
      expect(
        helper.maxHp,
        SkyEnemy.healthFor(helper.appearance, bossesDefeated: defeated),
      );
      expect(helper.hp, helper.maxHp);
    }
    expect(
      [
        for (var appearance = 0; appearance < 4; appearance++)
          SkyEnemy.healthFor(appearance),
      ],
      [10, 20, 30, 10],
    );
  });

  // The endless cycle's five bosses. New York's campaign-only mini-bosses
  // (rules 43) never appear in an endless arena: mini_boss_damage_test runs
  // the same checks through a level plan.
  for (final kind in BossKind.values.where((kind) => !kind.campaignOnly)) {
    test(
      '$kind accepts arbitrary damage, crosses half health, and pays once',
      () {
        // The pirate only exists from rules 34, the dragon from rules 38.
        final sim = arena(
          version: switch (kind) {
            BossKind.pirate => 34,
            BossKind.dragon => 38,
            _ => 26,
          },
        )..bossesDefeated = kind.index;
        step(sim);
        hover(sim, sim.boss!.arrivalDuration + .02);
        final boss = sim.boss!;
        expect(boss.kind, kind);
        expect(boss.maxHp, [120, 180, 240, 300, 360][kind.index]);
        final damage = boss.maxHp ~/ 2 + 3;
        sim.rocks.add(BirdRock(x: boss.x - .07, y: boss.y, damage: damage));
        step(sim);
        expect(boss.hp, boss.maxHp - damage);
        expect(boss.lastDamage, damage);
        expect(boss.enraged, isTrue);
        expect(boss.enragedAt, boss.lastHitAt);
        final enragedAt = boss.enragedAt;
        sim.rocks.add(BirdRock(x: boss.x - .07, y: boss.y, damage: 1));
        step(sim);
        expect(boss.enragedAt, enragedAt);
        final beforeKill = boss.hp;
        for (var i = 0; i < 3; i++) {
          sim.rocks.add(BirdRock(x: boss.x - .07, y: boss.y, damage: 1000));
        }
        step(sim);
        expect(boss.hp, 0);
        expect(boss.lastDamage, beforeKill);
        expect(boss.phase, BossPhase.defeated);
        expect(sim.bossesDefeated, kind.index + 1);
        expect(sim.score, FlightSimulation.bossBonus);
        expect(
          sim.events.where((e) => e.kind == FlightEventKind.bossDefeated),
          hasLength(1),
        );
      },
    );
  }

  test('powerful ammo still respects boss arrivals and the moth shield', () {
    final sim = arena(version: 26)..bossesDefeated = 2;
    step(sim);
    final boss = sim.boss!;
    sim.rocks.add(BirdRock(x: boss.x - .07, y: boss.y, damage: 1000));
    step(sim);
    expect(boss.hp, 240);
    sim.rocks.clear();
    hover(sim, boss.arrivalDuration + .02);
    boss.age = boss.arrivalDuration + 5.1;
    sim.rocks.add(
      BirdRock(x: boss.x - SkyBoss.shieldRadius, y: boss.y, damage: 1000),
    );
    step(sim);
    expect(boss.hp, 240);
    expect(boss.enragedAt, double.negativeInfinity);
    expect(sim.rocks, isEmpty);
    expect(boss.lastShieldHitAt, closeTo(boss.age, .02));
  });

  test('version 25 keeps one-hit enemies and one damage per boss shot', () {
    final sim = arena(version: 25)..elapsed = 0;
    step(sim);
    final enemy = sim.enemies.single;
    expect(enemy.hp, 1);
    expect(sim.weaponDamage, 1);
    sim.elapsed = FlightSimulation.bossInterval;
    step(sim);
    hover(sim, sim.boss!.arrivalDuration + .02);
    final boss = sim.boss!;
    expect(boss.hp, 12);
    sim.rocks.add(BirdRock(x: boss.x - .07, y: boss.y, damage: 1000));
    step(sim);
    expect(boss.hp, 11);
  });

  test('invalid health and damage are rejected before they change state', () {
    final sim = playing();
    final enemy = SkyEnemy(x: 1, y: .5);
    final boss = SkyBoss(number: 1, x: 1.5, maxHp: 75);
    expect(boss.hp, 75);
    for (final invalid in [0, -1]) {
      expect(() => sim.setWeaponDamage(invalid), throwsArgumentError);
      expect(() => BirdRock(x: 1, y: .5, damage: invalid), throwsArgumentError);
      expect(() => SkyEnemy(x: 1, y: .5, maxHp: invalid), throwsArgumentError);
      expect(
        () => SkyBoss(number: 1, x: 1.5, maxHp: invalid),
        throwsArgumentError,
      );
      expect(() => enemy.takeDamage(invalid), throwsArgumentError);
      expect(() => boss.takeDamage(invalid), throwsArgumentError);
    }
    expect(sim.weaponDamage, 10);
    expect(enemy.hp, 10);
    expect(boss.hp, 75);
  });

  for (final reduced in [false, true]) {
    test('loadout and mid-flight upgrades replay across seeks ($reduced)', () {
      var now = 0.0;
      final recorder = FlightRecorder(
        ReplayTape(
          mode: PlayMode.touch,
          course: FlightCourse.starTrail,
          practice: true,
          seed: 7,
          cycleSeconds: 3,
          bird: 0,
          reducedMotion: reduced,
          originMs: 0,
          weaponDamage: 15,
        ),
        () => now,
      );
      final sim = recorder.simulation;
      Object state(FlightSimulation s) => [
        snapshot(s),
        s.weaponDamage,
        s.enemies.map((e) => [e.maxHp, e.hp, e.lastHitAt]).toList(),
        s.rocks.map((r) => r.damage).toList(),
        if (s.boss case final b?) [b.maxHp, b.lastDamage, b.enragedAt],
      ];
      final checkpoints = <double, Object>{};
      for (var frame = 1; frame <= 1800; frame++) {
        now = frame * 50.0;
        recorder.apply(
          MovementInput(valid: true, flap: rideTheSky(sim)),
          TrackingSample(
            mode: PlayMode.touch,
            timestampMs: now,
            receivedMs: now,
            joints: const [],
          ),
          now,
        );
        if (frame == 1000) recorder.setWeaponDamage(37);
        if (sim.canShoot) recorder.command('shoot');
        recorder.tick(.05, now, 2.2);
        if (frame % 200 == 0) checkpoints[now] = state(sim);
      }
      expect(sim.bossesDefeated, greaterThan(0));
      final json = recorder.tape.toJson();
      final replay = ReplayPlayer(ReplayTape.fromJson(json));
      expect(replay.simulation.weaponDamage, 15);
      for (final time in [90000.0, 40000.0, 60000.0, 20000.0, 90000.0]) {
        replay.seek(time);
        expect(state(replay.simulation), checkpoints[time]);
      }
      for (final invalid in [0, -3, 2.5, '30']) {
        expect(
          () => ReplayTape.fromJson({...json, 'weaponDamage': invalid}),
          throwsFormatException,
        );
        expect(
          () => ReplayTape.fromJson({
            ...json,
            'events': [
              [0, 'weaponDamage', invalid],
            ],
          }),
          throwsFormatException,
        );
      }
    });
  }
}
