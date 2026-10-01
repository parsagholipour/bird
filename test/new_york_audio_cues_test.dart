// Cue wiring for New York (rules version 43): the Alley Pigeon, the Steam
// Geysers, King Coo and the Searchlight Gargoyle. The rules that raise these
// counters (R1-R3) land separately, so every test drives the counters and the
// boss clock directly, which is exactly what the rules will do.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/audio.dart';
import 'package:push_up_bird/game/boss_audio_cues.dart';
import 'package:push_up_bird/game/combat_audio_cues.dart';
import 'package:push_up_bird/game/king_coo_layout.dart';
import 'package:push_up_bird/game/sound_bank.dart';
import 'sky_audio_test.dart' show AndroidAudioHost, drainAudio;
import 'touch_combat_test.dart' show playing;

/// A mini-boss [age] seconds into its encounter (4.6 s of arrival first).
SkyBoss mini(BossKind kind, {double age = 5}) =>
    SkyBoss(number: kind.index + 1, x: 1.5, cinematic: true, kind: kind)
      ..age = age;

const arrival = 4.6;

SteamVent vent(double x) => SteamVent(
  geyser: const SteamGeyser(slot: 4, x: 2, kind: SteamKind.hop, burstAt: 10),
  x: x,
  top: .3,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Alley Pigeon', () {
    test('coo at the warning, flap at the dive, snatch, rescue, defeat', () {
      final sim = playing();
      final cues = CombatAudioCues()..advance(sim, silent: true);
      sim.pigeonWarnings++;
      expect(cues.advance(sim), ['pigeon_coo']);
      expect(cues.advance(sim), isEmpty);
      sim.pigeonDives++;
      expect(cues.advance(sim), ['pigeon_flap']);
      sim.starsSnatched++;
      expect(cues.advance(sim), ['pigeon_snatch']);
      // A lost star the pigeon flew off with is silent: the snatch said it.
      sim.starsLost++;
      expect(cues.advance(sim), isEmpty);
      sim.starsFreed++;
      expect(cues.advance(sim), ['star_rescue']);
      expect(cues.advance(sim), isEmpty);
    });

    test('a pigeon has its own defeat; bats keep enemy_death', () {
      final sim = playing();
      final cues = CombatAudioCues()..advance(sim, silent: true);
      // The pigeon rules count a pigeon's death in both counters.
      sim.enemiesDefeated++;
      sim.pigeonsDefeated++;
      expect(cues.advance(sim), ['pigeon_defeat']);
      sim.enemiesDefeated++;
      expect(cues.advance(sim), ['enemy_death']);
      // Both in one step: each family sounds once.
      sim.enemiesDefeated += 2;
      sim.pigeonsDefeated++;
      expect(cues.advance(sim), ['enemy_death', 'pigeon_defeat']);
      expect(cues.advance(sim), isEmpty);
    });

    test('a pigeon warning is its coo, never the shooters enemy_charge', () {
      final sim = playing();
      final cues = CombatAudioCues()..advance(sim, silent: true);
      final pigeon = SkyEnemy(x: 1.7, y: .5, appearance: 4);
      expect(pigeon.kind, EnemyKind.alleyPigeon);
      pigeon.pigeon!.phase = PigeonPhase.warning;
      pigeon.age = .4;
      expect(pigeon.charge, greaterThan(0));
      sim.enemies.add(pigeon);
      expect(cues.advance(sim), isEmpty);
      // A beetle winding up still rings it.
      sim.enemies.add(
        SkyEnemy(x: 1.7, y: .5, appearance: 1)
          ..preparing = true
          ..fireIn = .3,
      );
      expect(cues.advance(sim), ['enemy_charge']);
    });

    test('seeks, rewinds and new flights are silent', () {
      final sim = playing();
      final cues = CombatAudioCues()..advance(sim);
      sim
        ..pigeonWarnings = 5
        ..pigeonDives = 4
        ..starsSnatched = 3
        ..starsFreed = 2
        ..enemiesDefeated = 3
        ..pigeonsDefeated = 3;
      expect(cues.advance(sim, silent: true), isEmpty);
      expect(cues.advance(sim), isEmpty);
      sim.pigeonWarnings++;
      expect(cues.advance(sim), ['pigeon_coo']);
      expect(cues.advance(playing()), isEmpty);
    });
  });

  group('Steam Geysers', () {
    test('hiss at the warning, burst with the clang, ride on the updraft', () {
      final sim = playing();
      final cues = CombatAudioCues()..advance(sim, silent: true);
      sim.steamHisses++;
      expect(cues.advance(sim), ['steam_hiss']);
      sim.steamBursts++;
      expect(cues.advance(sim), ['steam_burst', 'pipe_clang']);
      sim.steamRides++;
      expect(cues.advance(sim), ['steam_ride']);
      expect(cues.advance(sim), isEmpty);
      // Scalds and clears have no cue of their own: a scald is a hurt (bump
      // or shield_pop, from the hearts), a clear is just a vent gone by.
      sim.steamScalds++;
      sim.steamClears++;
      expect(cues.advance(sim), isEmpty);
    });

    test('only a vent near the bird sounds (a little behind to the edge)', () {
      final sim = playing();
      final cues = CombatAudioCues()..advance(sim, silent: true);
      sim.steamVents.add(vent(FlightSimulation.birdX + 2.6));
      sim.steamHisses++;
      expect(cues.advance(sim), isEmpty, reason: 'beyond the right edge');
      // The missed hiss is not replayed when the vent comes into range.
      sim.steamVents.first.x = FlightSimulation.birdX + 1.2;
      expect(cues.advance(sim), isEmpty);
      sim.steamBursts++;
      expect(cues.advance(sim), ['steam_burst', 'pipe_clang']);
      sim.steamVents.first.x = FlightSimulation.birdX - .3;
      sim.steamRides++;
      expect(cues.advance(sim), isEmpty, reason: 'well behind the bird');
      sim.steamVents.add(vent(FlightSimulation.birdX));
      sim.steamRides++;
      expect(cues.advance(sim), ['steam_ride']);
    });

    test('seeks and rewinds are silent', () {
      final sim = playing();
      final cues = CombatAudioCues()..advance(sim);
      sim
        ..steamHisses = 4
        ..steamBursts = 4
        ..steamRides = 2;
      expect(cues.advance(sim, silent: true), isEmpty);
      expect(cues.advance(sim), isEmpty);
      sim.steamBursts++;
      expect(cues.advance(sim), ['steam_burst', 'pipe_clang']);
    });
  });

  for (final kind in [BossKind.kingCoo, BossKind.searchlightGargoyle]) {
    group('$kind arrival and defeat', () {
      final coo = kind == BossKind.kingCoo;

      test('warning, then his own strike/shout, fury and ending', () {
        final boss = SkyBoss(
          number: kind.index + 1,
          x: 1.5,
          cinematic: true,
          kind: kind,
        );
        final cues = BossAudioCues();
        expect(cues.advance(boss), ['boss_warning']);
        // The Gargoyle's lightning is the generic reveal's instant (1.65 s);
        // King Coo's reveal is a flash at 1.9 s, so his cue rings just ahead
        // of that and not 0.25 s early at 1.65 s.
        boss.age = SkyBoss.revealAt + .01;
        expect(cues.advance(boss), coo ? isEmpty : ['gargoyle_strike']);
        if (coo) {
          boss.age = BossAudioCues.flashAt - BossAudioCues.flashLead + .01;
          expect(cues.advance(boss), ['boss_reveal']);
        }
        boss.age = SkyBoss.roarAt + .01;
        expect(cues.advance(boss), [coo ? 'coo_shout' : 'gargoyle_awaken']);
        boss.age = arrival + .1;
        expect(cues.advance(boss), isEmpty);
        boss.hp = boss.maxHp ~/ 2;
        boss.enragedAt = boss.age;
        expect(cues.advance(boss), [coo ? 'coo_roar' : 'gargoyle_fury']);
        boss.hp = 0;
        boss.defeatedAt = boss.age;
        expect(cues.advance(boss), ['boss_break']);
        if (coo) {
          // His chest inflates from the end of the hit-stop to the pop.
          boss.age += KingCooTimeline.hitStop + .01;
          expect(cues.advance(boss), ['coo_inflate']);
          boss.age += SkyBoss.burstAt - KingCooTimeline.hitStop;
        } else {
          boss.age += SkyBoss.burstAt + .01;
        }
        expect(cues.advance(boss), [coo ? 'coo_defeat' : 'gargoyle_shatter']);
        // Their victory card begins at 1.55 s, and the cue with it.
        boss.age = boss.defeatedAt! + 1.54;
        expect(cues.advance(boss), isEmpty);
        boss.age = boss.defeatedAt! + 1.56;
        expect(cues.advance(boss), ['boss_victory']);
        expect(cues.advance(boss), isEmpty);
      });

      test('nothing plays on a silent seek into the fight', () {
        final boss = mini(kind, age: arrival + 30);
        final cues = BossAudioCues();
        expect(cues.advance(boss, silent: true), isEmpty);
        expect(cues.advance(boss), isEmpty);
      });
    });
  }

  group('audio fix round: timing', () {
    test(
      'the reveal cue rings with the flash of the two bosses that flash',
      () {
        expect(BossAudioCues.flashAt, KingCooTimeline.flashAt);
        for (final kind in [BossKind.dragon, BossKind.kingCoo]) {
          final boss = SkyBoss(
            number: kind.index + 1,
            x: 1.5,
            cinematic: true,
            kind: kind,
          );
          final cues = BossAudioCues();
          expect(cues.advance(boss), ['boss_warning']);
          // Not at 1.65 s any more: 0.25 s ahead of the picture.
          boss.age = SkyBoss.revealAt + .02;
          expect(cues.advance(boss), isEmpty, reason: '$kind');
          boss.age = KingCooTimeline.flashAt - .02;
          expect(cues.advance(boss), ['boss_reveal'], reason: '$kind');
          boss.age = SkyBoss.roarAt + .01;
          expect(cues.advance(boss), [
            kind == BossKind.kingCoo ? 'coo_shout' : 'boss_roar',
          ]);
        }
      },
    );

    test(
      'every other boss keeps its reveal at 1.65 s and victory at 1.8 s',
      () {
        for (final kind in [
          BossKind.baronBat,
          BossKind.spitterBeetle,
          BossKind.duskMoth,
          BossKind.pirate,
          BossKind.dragon,
        ]) {
          final boss = mini(kind, age: 4.7); // arrived
          final cues = BossAudioCues()..advance(boss, silent: true);
          boss.hp = 0;
          boss.defeatedAt = boss.age;
          cues.advance(boss);
          boss.age = boss.defeatedAt! + 1.7;
          expect(cues.advance(boss), contains('boss_burst'), reason: '$kind');
          expect(cues.advance(boss), isEmpty);
          boss.age = boss.defeatedAt! + 1.81;
          expect(cues.advance(boss), ['boss_victory'], reason: '$kind');
        }
        final baron = SkyBoss(number: 1, x: 1.5, cinematic: true);
        final cues = BossAudioCues();
        cues.advance(baron);
        baron.age = SkyBoss.revealAt + .01;
        expect(cues.advance(baron), ['boss_reveal']);
      },
    );

    test('the chest inflating is silent when a seek lands past it', () {
      final boss = mini(BossKind.kingCoo, age: arrival + 5);
      final cues = BossAudioCues()..advance(boss, silent: true);
      boss.hp = 0;
      boss.defeatedAt = boss.age;
      expect(cues.advance(boss), ['boss_break']);
      boss.age += .5;
      expect(cues.advance(boss, silent: true), isEmpty);
      boss.age += .5;
      expect(cues.advance(boss), isNot(contains('coo_inflate')));
    });

    test(
      'a steam burst lands lower when a snatch is first or simultaneous',
      () {
        final sim = playing();
        final cues = CombatAudioCues()..advance(sim, silent: true);
        // The review's case: the same step.
        sim.starsSnatched++;
        sim.steamBursts++;
        expect(cues.advance(sim), [
          'pigeon_snatch',
          'steam_burst_duck',
          'pipe_clang_duck',
        ]);
        // A burst 0.2 s after a snatch: ducked.
        sim.elapsed += .2;
        sim.steamBursts++;
        expect(cues.advance(sim), ['steam_burst_duck', 'pipe_clang_duck']);
        // A burst a second later is at full level again.
        sim.elapsed += 1;
        sim.steamBursts++;
        expect(cues.advance(sim), ['steam_burst', 'pipe_clang']);
        // A star won back ducks the burst too.
        sim.elapsed += 1;
        sim.starsFreed++;
        sim.steamBursts++;
        expect(cues.advance(sim), [
          'star_rescue',
          'steam_burst_duck',
          'pipe_clang_duck',
        ]);
      },
    );

    test('a snatch 33 ms after a burst is lifted instead', () {
      final sim = playing();
      final cues = CombatAudioCues()..advance(sim, silent: true);
      sim.steamBursts++;
      expect(cues.advance(sim), ['steam_burst', 'pipe_clang']);
      sim.elapsed += .033;
      sim.starsSnatched++;
      expect(cues.advance(sim), ['pigeon_snatch_lift']);
      // Far from a burst a snatch is the ordinary cue.
      sim.elapsed += 2;
      sim.starsSnatched++;
      expect(cues.advance(sim), ['pigeon_snatch']);
      // And a rescued star alone is never lifted.
      sim.steamBursts++;
      sim.elapsed += 2;
      expect(cues.advance(sim), ['steam_burst', 'pipe_clang']);
      sim.elapsed += .1;
      sim.starsFreed++;
      expect(cues.advance(sim), ['star_rescue']);
    });

    test('seeks and rewinds forget the last snatch and burst', () {
      final sim = playing();
      final cues = CombatAudioCues()..advance(sim, silent: true);
      sim.starsSnatched++;
      expect(cues.advance(sim), ['pigeon_snatch']);
      // A rewind: elapsed goes back before the snatch; a later burst is not
      // "near" a snatch that has not happened yet.
      sim.elapsed -= .5;
      expect(cues.advance(sim), isEmpty);
      sim.steamBursts++;
      expect(cues.advance(sim), ['steam_burst', 'pipe_clang']);
      // A silent seek forgets the burst: a snatch right after is ordinary.
      expect(cues.advance(sim, silent: true), isEmpty);
      sim.starsSnatched++;
      expect(cues.advance(sim), ['pigeon_snatch']);
    });

    test('the ducked cues play the same files lower', () {
      for (final (duck, base, db) in const [
        ('steam_burst_duck', 'steam_burst', -5.0),
        ('pipe_clang_duck', 'pipe_clang', -8.0),
        ('pigeon_snatch_lift', 'pigeon_snatch', 3.0),
      ]) {
        final a = soundBank[duck]!, b = soundBank[base]!;
        expect(a.file, base);
        expect(a.variants, b.variants);
        expect(a.seconds, b.seconds);
        expect(a.priority, b.priority);
        expect(
          20 * math.log(a.volume / b.volume) / math.ln10,
          closeTo(db, .3),
          reason: duck,
        );
        for (var v = 0; v < a.variants; v++) {
          expect(soundAsset(duck, v), soundAsset(base, v));
        }
      }
    });
  });

  group('King Coo', () {
    test('puff at the window, whistle with its squadron, pop', () {
      final boss = mini(BossKind.kingCoo, age: arrival + 7.0);
      final cues = BossAudioCues()..advance(boss, silent: true);
      boss.age = arrival + KingCoo.puffAt;
      expect(cues.advance(boss), ['coo_puff']);
      expect(cues.advance(boss), isEmpty);
      // The rules blow the whistle at 9.2 s and count it.
      boss.age = arrival + KingCoo.whistleAt;
      boss.whistles++;
      expect(cues.advance(boss), ['coo_whistle', 'squad_flutter']);
      boss.pops++;
      expect(cues.advance(boss), ['coo_pop']);
      // The next cycle puffs again.
      boss.age = arrival + KingCoo.period + KingCoo.puffAt;
      expect(cues.advance(boss), ['coo_puff']);
    });

    test('a pop before the whistle cancels the whistle and its squadron', () {
      final boss = mini(BossKind.kingCoo, age: arrival + KingCoo.puffAt + .1);
      final cues = BossAudioCues()..advance(boss, silent: true);
      boss.age = arrival + 8.5;
      boss.pops++;
      expect(cues.advance(boss), ['coo_pop']);
      // The clock passes the whistle time but the rules never blew it.
      boss.age = arrival + KingCoo.whistleAt + .2;
      expect(boss.whistlesDue, 1);
      expect(cues.advance(boss), isEmpty);
    });

    test('ring locked: the wind-up, the toss, the splat', () {
      final boss = mini(BossKind.kingCoo, age: arrival + 1.0);
      final cues = BossAudioCues()..advance(boss, silent: true);
      boss.lobs.add(
        CrumbLob(lockedAt: boss.age, lockX: FlightSimulation.birdX, lockY: .5),
      );
      expect(cues.advance(boss), ['boss_charge']);
      boss.age += KingCoo.lockLead;
      expect(cues.advance(boss), ['crumb_throw']);
      boss.age += KingCoo.lobFlight;
      expect(cues.advance(boss), ['crumb_splat']);
      expect(cues.advance(boss), isEmpty);
    });

    test('a fury picket behind the V takes off with its own flutter', () {
      final boss = mini(BossKind.kingCoo, age: arrival + 9.0);
      final cues = BossAudioCues()..advance(boss, silent: true);
      boss.squad = const [
        SquadPlan(shape: SquadShape.v, slots: []),
        SquadPlan(
          shape: SquadShape.picket,
          slots: [],
          delay: KingCoo.furyPicketDelay,
        ),
      ];
      boss.age += .2;
      boss.whistles++;
      expect(cues.advance(boss), ['coo_whistle', 'squad_flutter']);
      boss.age += 1.0;
      expect(cues.advance(boss), isEmpty);
      boss.age += .5;
      expect(cues.advance(boss), ['squad_flutter']);
      boss.age += .5;
      expect(cues.advance(boss), isEmpty);
    });

    test('a rewind or seek drops a flutter still to come', () {
      final boss = mini(BossKind.kingCoo, age: arrival + 9.0);
      final cues = BossAudioCues()..advance(boss, silent: true);
      boss.squad = const [
        SquadPlan(
          shape: SquadShape.picket,
          slots: [],
          delay: KingCoo.furyPicketDelay,
        ),
      ];
      boss.whistles++;
      expect(cues.advance(boss), ['coo_whistle', 'squad_flutter']);
      boss.age -= 3; // a backward seek
      expect(cues.advance(boss), isEmpty);
      boss.age += 3;
      // Playing on live again re-crosses the puff (a real seek is silent), but
      // the flutter that was still to come stays forgotten.
      expect(
        cues.advance(boss),
        isNot(contains('squad_flutter')),
        reason: 'the flutter was forgotten',
      );
    });

    test('seeks and rewinds are silent, then edges resume', () {
      final boss = mini(BossKind.kingCoo, age: arrival + 20);
      final cues = BossAudioCues()..advance(boss);
      boss.age = arrival + 14 + 8;
      boss.whistles = 3;
      boss.pops = 1;
      expect(cues.advance(boss, silent: true), isEmpty);
      expect(cues.advance(boss), isEmpty);
      boss.age = arrival + 3; // rewinds to the first cycle
      expect(cues.advance(boss), isEmpty);
      boss.age = arrival + KingCoo.puffAt;
      boss.whistles = 0;
      expect(cues.advance(boss), ['coo_puff']);
    });

    test('the bomb, puff, whistle and pop cues need no dragon-style rules', () {
      // The generic boss edges stay quiet for him: no volleys, summons or
      // charges of the shooters' kind.
      final boss = mini(BossKind.kingCoo, age: arrival + 2);
      final cues = BossAudioCues()..advance(boss, silent: true);
      boss.age += 10;
      final heard = cues.advance(boss);
      expect(heard, isNot(contains('boss_volley')));
      expect(heard, isNot(contains('boss_summon')));
      expect(heard, isNot(contains('boss_charge')));
    });
  });

  group('Searchlight Gargoyle', () {
    test('warning, ignition, lamp opening each cycle on the clock', () {
      final boss = mini(BossKind.searchlightGargoyle, age: arrival + 1.9);
      final cues = BossAudioCues()..advance(boss, silent: true);
      boss.age = arrival + SearchlightGargoyle.warnAt + .01;
      expect(cues.advance(boss), ['beam_warning']);
      expect(cues.advance(boss), isEmpty);
      boss.age = arrival + SearchlightGargoyle.sweepAt + .01;
      expect(cues.advance(boss), ['beam_sweep']);
      boss.age = arrival + SearchlightGargoyle.ventAt + .01;
      expect(cues.advance(boss), ['lamp_vent']);
      expect(cues.advance(boss), isEmpty);
      // Nine seconds later the next cycle begins again.
      boss.age = arrival + SearchlightGargoyle.period + 2.1;
      expect(cues.advance(boss), ['beam_warning']);
    });

    test('caught, a feather dropped, a rock glancing off the shut lamp', () {
      final boss = mini(BossKind.searchlightGargoyle, age: arrival + 4);
      final cues = BossAudioCues()..advance(boss, silent: true);
      boss.spots++;
      expect(cues.advance(boss), ['beam_spot']);
      boss.feathersLaunched++;
      expect(cues.advance(boss), ['feather_drop']);
      boss.lastGlanceAt = boss.age;
      expect(cues.advance(boss), ['lamp_glance']);
      // One glance sounds once, and a stale timestamp never replays.
      expect(cues.advance(boss), isEmpty);
      boss.age += .5;
      expect(cues.advance(boss), isEmpty);
      boss.lastGlanceAt = boss.age - 3;
      expect(cues.advance(boss), isEmpty);
    });

    test('no cue in the cutscenes and none on a seek', () {
      final boss = mini(BossKind.searchlightGargoyle, age: 1);
      final cues = BossAudioCues()..advance(boss, silent: true);
      boss.age = 4.0; // still arriving: the clock counters are all zero
      expect(cues.advance(boss), isNot(contains('beam_warning')));
      boss.age = arrival + 20;
      expect(cues.advance(boss, silent: true), isEmpty);
      boss.age = arrival + 40;
      boss.spots = 4;
      boss.feathersLaunched = 9;
      expect(cues.advance(boss, silent: true), isEmpty);
      expect(cues.advance(boss), isEmpty);
      boss.age = arrival + 5; // backwards
      expect(cues.advance(boss), isEmpty);
    });

    test('a defeat silences the fight cues', () {
      final boss = mini(BossKind.searchlightGargoyle, age: arrival + 5);
      final cues = BossAudioCues()..advance(boss, silent: true);
      boss.hp = 0;
      boss.defeatedAt = boss.age;
      expect(cues.advance(boss), ['boss_break']);
      boss.age += 2;
      final heard = cues.advance(boss);
      expect(heard, isNot(contains('beam_warning')));
      expect(heard, isNot(contains('beam_sweep')));
      expect(heard, isNot(contains('lamp_vent')));
    });
  });

  group('the mixer', () {
    final cueNames = [
      'pigeon_coo',
      'pigeon_flap',
      'pigeon_snatch',
      'pigeon_defeat',
      'star_rescue',
      'steam_hiss',
      'steam_burst',
      'pipe_clang',
      'steam_ride',
      'gargoyle_strike',
      'gargoyle_awaken',
      'beam_warning',
      'beam_sweep',
      'beam_spot',
      'lamp_vent',
      'lamp_glance',
      'feather_drop',
      'coo_roar',
      'coo_whistle',
      'crumb_throw',
      'crumb_splat',
      'squad_flutter',
      'coo_puff',
      'coo_pop',
      'coo_defeat',
      'coo_shout',
      'gargoyle_fury',
      'gargoyle_shatter',
      'coo_inflate',
      'steam_burst_duck',
      'pipe_clang_duck',
      'pigeon_snatch_lift',
    ];

    test('every cue is in the bank and none outranks a boss roar', () {
      for (final name in cueNames) {
        final spec = soundBank[name];
        expect(spec, isNotNull, reason: name);
        expect(
          spec!.priority,
          lessThanOrEqualTo(soundBank['boss_roar']!.priority),
          reason: '$name must never cut a roar',
        );
        expect(spec.volume, inInclusiveRange(.1, 1.0), reason: name);
      }
    });

    test('a full mixer of New York cues never cuts a boss roar', () async {
      final host = AndroidAudioHost()..install();
      final audio = SkyAudio(effectClock: () => 0);
      addTearDown(audio.dispose);
      await audio.configure(const GameSettings(music: false));
      audio.effect('boss_roar');
      await drainAudio();
      final roar = host.sources.keys.singleWhere(
        (id) => host.sources[id]!.endsWith('boss_roar.wav'),
      );
      // The clock never advances, so no voice frees up by itself: every new
      // cue must win a voice from something of lower priority, or be dropped.
      for (final name in cueNames) {
        audio.effect(name);
        await drainAudio();
        expect(host.playing, contains(roar), reason: 'after $name');
      }
      expect(host.sources[roar], endsWith('boss_roar.wav'));
      // And the roars of the mini-bosses are just as safe from the rest.
      audio.effect('coo_roar');
      await drainAudio();
      final cooRoar = host.sources.keys.where(
        (id) => host.sources[id]!.endsWith('coo_roar.wav'),
      );
      for (final name in cueNames.reversed) {
        audio.effect(name);
        await drainAudio();
        for (final id in cooRoar) {
          if (host.playing.contains(id)) {
            expect(host.sources[id], endsWith('coo_roar.wav'));
          }
        }
        expect(host.playing, contains(roar));
      }
    });

    test('live counters load the right assets, takes rotating', () async {
      final host = AndroidAudioHost()..install();
      var now = 0;
      final audio = SkyAudio(effectClock: () => now);
      addTearDown(audio.dispose);
      await audio.configure(const GameSettings(music: false));
      final sim = playing();
      audio.syncCombat(sim); // the first sync only takes a snapshot
      List<String> loaded() => [
        for (final url in host.loads) Uri.parse(url).pathSegments.last,
      ];
      for (var i = 0; i < 3; i++) {
        sim.pigeonWarnings++;
        sim.pigeonDives++;
        sim.steamBursts++;
        audio.syncCombat(sim);
        await drainAudio();
        now += 1000;
      }
      expect(loaded().where((n) => n.startsWith('pigeon_coo')), [
        'pigeon_coo.wav',
        'pigeon_coo_2.wav',
        'pigeon_coo.wav',
      ]);
      expect(loaded().where((n) => n.startsWith('pigeon_flap')), [
        'pigeon_flap.wav',
        'pigeon_flap_2.wav',
        'pigeon_flap.wav',
      ]);
      expect(loaded().where((n) => n.startsWith('steam_burst')), [
        'steam_burst.wav',
        'steam_burst_2.wav',
        'steam_burst.wav',
      ]);
      expect(loaded().where((n) => n.startsWith('pipe_clang')), hasLength(3));
    });

    test(
      'a boss fight plays its cues through SkyAudio, muted or not',
      () async {
        final host = AndroidAudioHost()..install();
        var now = 0;
        final audio = SkyAudio(effectClock: () => now);
        addTearDown(audio.dispose);
        await audio.configure(const GameSettings(music: false));
        final boss = mini(BossKind.searchlightGargoyle, age: arrival + 1.9);
        audio.syncBoss(boss, silent: true);
        boss.age = arrival + SearchlightGargoyle.warnAt + .01;
        audio.syncBoss(boss);
        await drainAudio();
        expect(host.loads.last, endsWith('beam_warning.wav'));
        // Muted effects: nothing loads, and the edge is not saved for later.
        final before = host.loads.length;
        await audio.configure(const GameSettings(music: false, effects: false));
        now += 5000;
        boss.age = arrival + SearchlightGargoyle.sweepAt + .01;
        audio.syncBoss(boss);
        await drainAudio();
        expect(host.loads, hasLength(before));
        await audio.configure(const GameSettings(music: false));
        now += 5000;
        audio.syncBoss(boss);
        await drainAudio();
        expect(host.loads, hasLength(before), reason: 'the sweep is past');
        boss.age = arrival + SearchlightGargoyle.ventAt + .01;
        audio.syncBoss(boss);
        await drainAudio();
        expect(host.loads.last, endsWith('lamp_vent.wav'));
      },
    );

    test('pausing stops a New York cue and seeks stay silent', () async {
      final host = AndroidAudioHost()..install();
      final audio = SkyAudio(effectClock: () => 0);
      addTearDown(audio.dispose);
      await audio.configure(const GameSettings(music: false));
      final boss = mini(BossKind.kingCoo, age: arrival + 7);
      audio.syncBoss(boss, silent: true);
      boss.age = arrival + KingCoo.puffAt;
      audio.syncBoss(boss);
      await drainAudio();
      expect(host.loads.last, endsWith('coo_puff.wav'));
      expect(host.playing, hasLength(1));
      await audio.stopEffects(); // what pausing does
      expect(host.playing, isEmpty);
      // A replay seek past the whistle makes no sound.
      final starts = host.starts.length;
      boss.age = arrival + 9.3;
      boss.whistles++;
      audio.syncBoss(boss, silent: true);
      await drainAudio();
      expect(host.starts, hasLength(starts));
    });
  });
}
