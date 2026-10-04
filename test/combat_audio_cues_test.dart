import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/boss_audio_cues.dart';
import 'package:push_up_bird/game/combat_audio_cues.dart';
import 'touch_combat_test.dart' show playing, tick;

void main() {
  test(
    'accepted shots and actual kills each sound once; departures do not',
    () {
      final sim = playing();
      final cues = CombatAudioCues()..advance(sim, silent: true);
      expect(sim.shoot(), isTrue);
      expect(cues.advance(sim), ['shoot']);
      expect(sim.shoot(), isFalse);
      expect(cues.advance(sim), isEmpty);
      sim.enemies.add(SkyEnemy(x: 1.2, y: .5));
      sim.rocks.add(BirdRock(x: 1.2, y: .5));
      tick(sim, .001);
      expect(cues.advance(sim), ['enemy_death']);
      expect(cues.advance(sim), isEmpty);
      sim.enemies.add(SkyEnemy(x: -.2, y: .5));
      tick(sim, .001);
      expect(cues.advance(sim), isEmpty);
    },
  );

  test('warning, volley and projectile interception survive a frame', () {
    final sim = playing();
    final cues = CombatAudioCues()..advance(sim, silent: true);
    final enemy = SkyEnemy(x: 1.7, y: .5, appearance: 1)..fireIn = .1;
    sim.enemies.add(enemy);
    tick(sim, .01);
    expect(cues.advance(sim), ['enemy_charge']);
    expect(cues.advance(sim), isEmpty);
    tick(sim, .10);
    expect(cues.advance(sim), ['enemy_shoot']);
    sim.rocks.add(BirdRock(x: 1.1, y: .3));
    sim.enemyAmmo.add(
      EnemyAmmo(x: 1.1, y: .3, vx: -.4, vy: 0, attack: EnemyAttack.aimed),
    );
    tick(sim, .001);
    expect(cues.advance(sim), ['deflect']);
    expect(cues.advance(sim), isEmpty);
  });

  test('every ring of a run chimes once, with a fresh turbo whoosh', () {
    final sim = playing();
    final cues = CombatAudioCues()..advance(sim, silent: true);
    sim.allRingsBonuses++;
    expect(cues.advance(sim), ['streak', 'sprint']);
    expect(cues.advance(sim), isEmpty);
    sim.allRingsBonuses = 5;
    expect(cues.advance(sim, silent: true), isEmpty);
    expect(cues.advance(sim), isEmpty);
  });

  test('silent seeks, rewinds and new runs never play historical combat', () {
    final sim = playing();
    final cues = CombatAudioCues()..advance(sim);
    sim.shots = 12;
    sim.enemiesDefeated = 9;
    sim.enemyShots = 20;
    expect(cues.advance(sim, silent: true), isEmpty);
    expect(cues.advance(sim), isEmpty);
    sim.shots++;
    expect(cues.advance(sim), ['shoot']);
    expect(cues.advance(playing()), isEmpty);
  });

  test(
    'boss blocks, summons, rage and complete death sequence are distinct',
    () {
      for (final kind in BossKind.values) {
        final boss = SkyBoss(number: 1, x: 1.5, cinematic: true, kind: kind)
          ..age = 5;
        final cues = BossAudioCues()..advance(boss, silent: true);
        boss.lastShieldHitAt = boss.age;
        expect(cues.advance(boss), contains('boss_block'));
        expect(cues.advance(boss), isEmpty);
        boss.summons++;
        expect(cues.advance(boss), ['boss_summon']);
        boss.hp = boss.maxHp ~/ 2;
        boss.enragedAt = boss.age;
        // The mini-bosses have their own fury and ending (see
        // new_york_audio_cues_test): King Coo roars and deflates, the
        // Gargoyle's fury and shattering are in the mids a phone plays, and
        // Neferhoo's cry, mask pop and found letter are his own
        // (neferhoo_audio_test).
        expect(
          cues.advance(boss),
          contains(switch (kind) {
            BossKind.kingCoo => 'coo_roar',
            BossKind.searchlightGargoyle => 'gargoyle_fury',
            BossKind.neferhoo => 'mummy_fury',
            _ => 'boss_enrage',
          }),
        );
        boss.hp = 0;
        boss.defeatedAt = boss.age;
        expect(cues.advance(boss), ['boss_break']);
        boss.age += .9;
        expect(cues.advance(boss), switch (kind) {
          // He inflates from the end of the hit-stop, then pops.
          BossKind.kingCoo => ['coo_inflate', 'coo_defeat'],
          BossKind.searchlightGargoyle => ['gargoyle_shatter'],
          BossKind.neferhoo => ['mask_pop'],
          _ => ['boss_burst'],
        });
        boss.age += 1;
        expect(cues.advance(boss), ['boss_victory']);
        // His found letter chimes once the victory stinger has rung out.
        if (kind == BossKind.neferhoo) {
          boss.age = boss.defeatedAt! + 3.25;
          expect(cues.advance(boss), ['lost_letter']);
        }
        expect(cues.advance(boss), isEmpty);
      }
    },
  );
}
