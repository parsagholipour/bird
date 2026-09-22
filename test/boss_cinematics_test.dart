import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/boss_audio_cues.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'boss_fight_test.dart' show arena, step, hover, hitBoss;

void main() {
  test(
    'new cinematics coast safely and return control without queued shots',
    () {
      final sim = arena(version: 17)
        ..elapsed = FlightSimulation.bossInterval - .001
        ..birdY = .95
        ..velocity = 3;
      step(sim);
      final boss = sim.boss!;
      expect(boss.cinematic, isTrue);
      expect(sim.bossCutscene, isTrue);
      final hearts = sim.hearts;
      for (var i = 0; i < 200; i++) {
        final now = (sim.elapsed + .02) * 1000;
        sim.apply(
          const MovementInput(valid: true, flap: true),
          TrackingSample(
            mode: PlayMode.touch,
            timestampMs: now,
            receivedMs: now,
            joints: const [],
          ),
          now,
        );
        expect(sim.shoot(), isFalse);
        sim.tick(.02, now);
      }
      expect(sim.hearts, hearts);
      expect(sim.shield, isTrue);
      expect(sim.flaps, 0);
      expect(sim.shots, 0);
      expect(sim.birdY, closeTo(.52, .001));
      expect(sim.velocity, 0);
      expect(sim.bossAmmo, isEmpty);
      hover(sim, .7);
      expect(boss.phase, BossPhase.attacking);
      expect(sim.canShoot, isTrue);
      expect(sim.flaps, 0);
      expect(sim.rocks, isEmpty);
      hitBoss(sim, count: boss.maxHp);
      final score = sim.score;
      expect(sim.bossCutscene, isTrue);
      for (var i = 0; i < 180; i++) {
        step(sim);
      }
      expect(sim.boss, isNotNull);
      expect(sim.hearts, hearts);
      expect(sim.birdY, closeTo(.52, .001));
      expect(sim.score, score);
      hover(sim, .3);
      expect(sim.boss, isNull);
      expect(sim.canShoot, isTrue);
    },
  );

  test('motion stages are distinct, finite and repeatable after a seek', () {
    final boss = SkyBoss(number: 1, x: 1.5, cinematic: true);
    final poses = <Object>[];
    for (final age in [.3, 1.4, 2.1, 2.95, 4.2, 5.0]) {
      boss.age = age;
      final m = BossMotion(boss, reducedMotion: false);
      poses.add([m.bodyScale, m.rotation, m.folded, m.reveal, m.roar]);
      expect(m.bodyScale.isFinite, isTrue);
      expect(m.shake.distance, lessThan(.01));
    }
    expect(poses.toSet().length, 6);
    boss.age = 2.1;
    final again = BossMotion(boss, reducedMotion: false);
    expect([
      again.bodyScale,
      again.rotation,
      again.folded,
      again.reveal,
      again.roar,
    ], poses[2]);
    boss.defeatedAt = 5;
    boss.age = 6.2;
    final burst = BossMotion(boss, reducedMotion: false);
    expect(burst.opacity, 0);
    expect(burst.shake.distance, greaterThan(0));
    final quiet = BossMotion(boss, reducedMotion: true);
    expect(quiet.shake.distance, 0);
    expect(quiet.rotation, 0);
    expect(quiet.wingBeat, 0);
    expect(quiet.bodyScale, 1);
  });

  test(
    'sound cues fire once, freeze with the clock, and do not replay on seeks',
    () {
      final cues = BossAudioCues();
      final boss = SkyBoss(number: 1, x: 1.5, cinematic: true)..age = .02;
      expect(cues.advance(boss), ['boss_warning']);
      expect(cues.advance(boss), isEmpty);
      boss.age = 1.7;
      expect(cues.advance(boss), ['boss_reveal']);
      boss.age = 2.7;
      expect(cues.advance(boss), ['boss_roar']);
      boss.age = 5;
      boss.fireIn = .5;
      expect(cues.advance(boss), ['boss_charge']);
      boss.volleys++;
      boss.age += .5;
      boss.fireIn = 2;
      expect(cues.advance(boss), ['boss_volley']);
      boss.hp = 0;
      boss.defeatedAt = boss.age;
      expect(cues.advance(boss), ['boss_break']);
      boss.age += .9;
      expect(cues.advance(boss), ['boss_burst']);
      boss.age += 1;
      expect(cues.advance(boss), ['boss_victory']);
      expect(cues.advance(boss), isEmpty);
      boss.age = 2;
      boss.defeatedAt = null;
      expect(cues.advance(boss, silent: true), isEmpty);
      expect(cues.advance(boss), isEmpty);
      boss.age = 2.7;
      expect(cues.advance(boss), ['boss_roar']);
    },
  );
}
