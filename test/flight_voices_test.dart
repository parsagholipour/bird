import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/flight_voice_director.dart';
import 'package:push_up_bird/domain/campaign_story.dart' show StoryMood;
import 'package:push_up_bird/game/flight_voice_faces.dart';
import 'package:push_up_bird/game/flight_voices.dart';
import 'touch_combat_test.dart' show playing;

/// A bank of [count] one-second lines in every pool named.
FlightVoiceBank bank(Map<String, int> pools, {int ms = 1000}) =>
    FlightVoiceBank.of({
      for (final MapEntry(key: pool, value: count) in pools.entries)
        for (var i = 1; i <= count; i++)
          '$pool-${i.toString().padLeft(2, '0')}': ms,
    });

/// Offers [kind] from [pool] every [every] seconds for [seconds], and lists
/// what was said.
List<String> run(
  FlightVoiceDirector director,
  String kind,
  String pool, {
  double every = 20,
  double seconds = 2000,
}) => [
  for (var t = 0.0; t < seconds; t += every)
    ?director.offer(VoiceCue.of(kind, pool), t)?.clip.name,
];

void main() {
  group('director', () {
    test('a pool plays every line before any returns, then rests it', () {
      final director = FlightVoiceDirector(
        talk: 1,
        bank: bank({'pip-takeoff': 6}),
        memory: FlightVoiceMemory(),
        random: Random(1),
      );
      final said = run(director, 'takeoff', 'pip-takeoff', seconds: 120);
      expect(said, hasLength(6));
      expect(said.toSet(), hasLength(6));
      // The pool is spent: nothing fresh until 12 other lines are said.
      expect(
        director.offer(VoiceCue.of('takeoff', 'pip-takeoff'), 200),
        isNull,
      );
    });

    test('no clip repeats while fewer than its rest of lines were said', () {
      final memory = FlightVoiceMemory();
      // A realistic spread: many pools of one to eight lines.
      final sizes = [1, 1, 2, 2, 3, 3, 4, 5, 6, 8];
      final pools = [for (var i = 0; i < 30; i++) 'pip-moment$i'];
      final director = FlightVoiceDirector(
        talk: 1,
        bank: bank({
          for (var i = 0; i < pools.length; i++) pools[i]: sizes[i % 10],
        }),
        memory: memory,
        random: Random(7),
      );
      final said = <String>[];
      final random = Random(3);
      for (var t = 0.0; t < 20000; t += 9) {
        final pool = pools[random.nextInt(pools.length)];
        final line = director.offer(VoiceCue.of('takeoff', pool), t);
        if (line != null) said.add(line.clip.name);
      }
      expect(said.length, greaterThan(1000));
      for (var i = 0; i < said.length; i++) {
        final pool = FlightVoiceBank.poolOf(said[i]);
        final rest = FlightVoiceDirector.rest(director.bank[pool].length);
        final next = said.indexOf(said[i], i + 1);
        if (next >= 0) expect(next - i, greaterThanOrEqualTo(rest));
      }
    });

    test('memory carries freshness into the next flight', () {
      final memory = FlightVoiceMemory();
      final pools = bank({'pip-takeoff': 6});
      final first = FlightVoiceDirector(
        talk: 1,
        bank: pools,
        memory: memory,
        random: Random(2),
      );
      final opened = first.offer(VoiceCue.of('takeoff', 'pip-takeoff'), 0)!;
      final restored = FlightVoiceMemory.decode(memory.encode());
      expect(restored.said, 1);
      expect(restored.since(opened.clip.name), 0);
      for (var seed = 0; seed < 30; seed++) {
        final next = FlightVoiceDirector(
          talk: 1,
          bank: pools,
          memory: FlightVoiceMemory.decode(memory.encode()),
          random: Random(seed),
        );
        expect(
          next.offer(VoiceCue.of('takeoff', 'pip-takeoff'), 0)!.clip.name,
          isNot(opened.clip.name),
        );
      }
      expect(FlightVoiceMemory.decode('not json').said, 0);
    });

    test('a quiet mode never falls silent for good', () {
      final memory = FlightVoiceMemory();
      final pools = bank({'pip-takeoff': 6});
      final said = <String>[];
      for (var flight = 0; flight < 40; flight++) {
        memory.flights++;
        final line = FlightVoiceDirector(
          talk: 1,
          bank: pools,
          memory: memory,
          random: Random(flight),
        ).offer(VoiceCue.of('takeoff', 'pip-takeoff'), 0);
        if (line != null) said.add(line.clip.name);
      }
      // Six lines, never the same twice within two flights.
      expect(said.length, greaterThan(30));
      for (var i = 1; i < said.length; i++) {
        expect(said[i], isNot(said[i - 1]));
      }
    });

    test('lines keep a gap and a budget; the campaign talks more', () {
      int lines(bool campaign) => run(
        FlightVoiceDirector(
          talk: 1,
          bank: bank({'pip-panel-break': 300}),
          memory: FlightVoiceMemory(),
          campaign: campaign,
          random: Random(5),
        ),
        'no-ammo',
        'pip-panel-break',
        every: 1,
        seconds: 600,
      ).length;
      final endless = lines(false), campaign = lines(true);
      // One line per cooldown at most: 30 s in endless, 21 s in a level.
      expect(endless, lessThanOrEqualTo(21));
      expect(campaign, greaterThan(endless));
    });

    test('an urgent warning cuts chatter, but not a line that matters', () {
      final director = FlightVoiceDirector(
        talk: 1,
        bank: bank({
          'pip-idle': 4,
          'pip-rush-wildfire': 3,
          'pip-last-heart': 2,
        }, ms: 3000),
        memory: FlightVoiceMemory(),
        random: Random(1),
      );
      expect(director.offer(VoiceCue.of('idle', 'pip-idle'), 0), isNotNull);
      final fire = director.offer(VoiceCue.of('rush', 'pip-rush-wildfire'), 1);
      expect(fire?.urgency, VoiceUrgency.urgent);
      // A last heart waits for the warning to end, then gets the word.
      expect(
        director.offer(VoiceCue.of('last-heart', 'pip-last-heart'), 1.1),
        isNull,
      );
      final second = director.offer(
        VoiceCue.of('rush', 'pip-rush-wildfire'),
        2,
      );
      expect(second, isNull, reason: 'an urgent line never cuts another');
      expect(director.tick(3.5), isNull, reason: 'held past its patience');
    });

    test('a line that matters waits briefly for the voice', () {
      final director = FlightVoiceDirector(
        talk: 1,
        bank: bank({'pip-streak': 2, 'pip-last-heart': 2}, ms: 1500),
        memory: FlightVoiceMemory(),
        random: Random(1),
      );
      expect(
        director.offer(VoiceCue.of('final-stretch', 'pip-streak'), 0),
        isNotNull,
      );
      expect(
        director.offer(VoiceCue.of('last-heart', 'pip-last-heart'), 1),
        isNull,
      );
      expect(director.tick(1.6), isNull, reason: 'still inside the gap');
      expect(director.tick(2.6)?.clip.name, startsWith('pip-last-heart'));
    });

    test('a reply follows its line without the usual gap', () {
      final director = FlightVoiceDirector(
        talk: 1,
        bank: bank({'baron-taunt': 80, 'pip-retort': 50}),
        memory: FlightVoiceMemory(),
        random: Random(4),
      );
      var replies = 0;
      for (var t = 0.0; t < 3000; t += 30) {
        final taunt = director.offer(
          VoiceCue.of(
            'taunt',
            'baron-taunt',
            then: VoiceCue.of('retort', 'pip-retort'),
          ),
          t,
        );
        if (taunt == null) continue;
        expect(director.tick(t + 1.1), isNull);
        final reply = director.tick(t + 1.4);
        if (reply != null) {
          replies++;
          expect(reply.clip.name, startsWith('pip-retort'));
        }
      }
      expect(replies, greaterThan(5));
    });
  });

  group('flight', () {
    FlightVoices voices({
      Map<String, int> pools = const {},
      CampaignLevel? level,
      bool retry = false,
      int best = 0,
      FlightVoiceMemory? memory,
      int seed = 1,
    }) => FlightVoices(
      talk: 1,
      bird: 0,
      mode: PlayMode.touch,
      level: level,
      retry: retry,
      best: best,
      memory: memory,
      bank: bank(pools),
      random: Random(seed),
    );

    test('the bird says one takeoff line as the flight gets going', () {
      final sim = playing();
      final v = voices(pools: {'pip-takeoff': 6, 'pip-retry': 5});
      final start = sim.elapsed;
      v.update(sim, mute: true);
      expect(v.update(sim), isNull);
      sim.elapsed = start + 1;
      expect(v.update(sim)?.clip.name, startsWith('pip-takeoff'));
      sim.elapsed += 30;
      expect(v.update(sim), isNull);

      final again = voices(
        pools: {'pip-takeoff': 6, 'pip-retry': 5},
        retry: true,
      );
      final next = playing();
      again.update(next, mute: true);
      next.elapsed += 1;
      expect(again.update(next)?.clip.name, startsWith('pip-retry'));
    });

    test('a campaign level opens on its cargo, then falls back', () {
      final level = Campaign.chapters.first.levels.first;
      final memory = FlightVoiceMemory();
      final pools = {'pip-takeoff': 6, 'pip-cargo-${level.id}': 1};
      String? takeoff() {
        final sim = playing();
        final v = voices(pools: pools, level: level, memory: memory);
        v.update(sim, mute: true);
        sim.elapsed += 1;
        return v.update(sim)?.clip.name;
      }

      expect(takeoff(), 'pip-cargo-${level.id}-01');
      expect(takeoff(), startsWith('pip-takeoff'));
    });

    test('muted flights are followed, never replayed when voices return', () {
      final sim = playing();
      final v = voices(pools: {'pip-takeoff': 6, 'pip-hit': 6});
      v.update(sim, mute: true);
      sim.elapsed += 1;
      sim.hearts = 2;
      expect(v.update(sim, mute: true), isNull);
      sim.elapsed += 1;
      expect(v.update(sim), isNull);
      expect(v.memory.said, 0);
    });

    test('fire gets its own hit line; the last heart outranks it', () {
      final sim = playing();
      final v = voices(
        pools: {'pip-hit-fire': 3, 'pip-hit': 6, 'pip-last-heart': 5},
      );
      v.update(sim, mute: true);
      sim.elapsed += 20;
      sim.shield = false;
      v.update(sim, mute: true);
      sim.hearts = 2;
      sim.breathBurns++;
      sim.elapsed += 1;
      final burn = v.update(sim);
      // Hits are said often, not always.
      if (burn != null) expect(burn.clip.name, startsWith('pip-hit-fire'));
      sim.hearts = 1;
      sim.elapsed += 20;
      expect(v.update(sim)?.clip.name, startsWith('pip-last-heart'));
    });

    test('a rush gets a first-time line once, then its warnings', () {
      final memory = FlightVoiceMemory();
      final pools = {'pip-rush-first-wildfire': 1, 'pip-rush-wildfire': 3};
      String? warn() {
        final sim = playing();
        final v = voices(pools: pools, memory: memory);
        v.update(sim, mute: true);
        sim.rushPath = RushPath(
          kind: RushPathKind.wildfire,
          number: 1,
          startDistance: 0,
          endDistance: 99,
          resumeDistance: 99,
          heights: const [.5, .5],
        );
        sim.rushWarnings++;
        sim.elapsed += 1;
        return v.update(sim)?.clip.name;
      }

      expect(warn(), 'pip-rush-first-wildfire-01');
      expect(warn(), startsWith('pip-rush-wildfire-'));
      expect(memory.met, contains('rush-wildfire'));
    });

    test('a boss speaks first as it arrives, and the bird answers', () {
      final sim = playing();
      final v = voices(pools: {'dragon-arrive': 3, 'pip-boss-dragon': 2});
      v.update(sim, mute: true);
      sim.boss = SkyBoss(number: 1, x: 1.2, kind: BossKind.dragon);
      sim.elapsed += 10;
      expect(v.update(sim), isNull);
      sim.boss!.age = 1;
      final boss = v.update(sim)!;
      expect(boss.clip.name, startsWith('dragon-arrive'));
      sim.elapsed += boss.clip.seconds + .5;
      expect(v.update(sim)?.clip.name, startsWith('pip-boss-dragon'));
    });

    test('a bird that speaks for a silent boss is not said twice', () {
      final sim = playing();
      final v = voices(pools: {'pip-boss-dragon': 2});
      v.update(sim, mute: true);
      sim.boss = SkyBoss(number: 1, x: 1.2, kind: BossKind.dragon)..age = 1;
      sim.elapsed += 10;
      final bird = v.update(sim)!;
      expect(bird.clip.name, startsWith('pip-boss-dragon'));
      for (var t = 0.0; t < 4; t += .25) {
        sim.elapsed += .25;
        expect(v.update(sim), isNull);
      }
    });

    test('ordinary lines share a budget; warnings stay outside it', () {
      final director = FlightVoiceDirector(
        talk: 1,
        bank: bank({'pip-hit': 40, 'pip-gale': 40, 'pip-enemy-down': 40}),
        memory: FlightVoiceMemory(),
        random: Random(2),
      );
      var ordinary = 0, warnings = 0;
      for (var t = 0.0; t < 60; t += 1) {
        final kind = t % 2 == 0 ? 'hit' : 'enemy-down';
        if (director.offer(VoiceCue.of(kind, 'pip-$kind'), t) != null) {
          ordinary++;
        }
        if (t % 10 == 5 &&
            director.offer(VoiceCue.of('gale', 'pip-gale'), t + .5) != null) {
          warnings++;
        }
      }
      expect(ordinary, lessThanOrEqualTo(5));
      expect(warnings, greaterThanOrEqualTo(5));
    });

    test('in a level, the boss says its name-card line', () {
      final chapter = Campaign.chapters.last;
      final card = FlightVoices.recorded['dragon-card'];
      expect(card.single.name, 'before-${chapter.number}-8-4');
      final lair = chapter.levels.last;
      expect(lair.boss, chapter.boss);
    });

    test('an endless record is called once, only over a real best', () {
      final sim = playing();
      final v = voices(pools: {'pip-record': 4}, best: 12);
      v.update(sim, mute: true);
      sim.elapsed += 30;
      sim.score = 12;
      expect(v.update(sim), isNull);
      sim.score = 13;
      expect(v.update(sim)?.clip.name, startsWith('pip-record'));
      sim.score = 40;
      sim.elapsed += 30;
      expect(v.update(sim), isNull);
      final first = voices(pools: {'pip-record': 4});
      final other = playing();
      first.update(other, mute: true);
      other.score = 5;
      other.elapsed += 30;
      expect(first.update(other), isNull);
    });

    test('the face of whoever talks follows the take, then falls quiet', () {
      var clock = 100.0;
      final sim = playing();
      final v = FlightVoices(
        talk: 1,
        bird: 0,
        mode: PlayMode.touch,
        bank: FlightVoices.recorded,
        random: Random(1),
        clock: () => clock,
      );
      v.update(sim, mute: true);
      expect(v.speech, isNull);
      sim.boss = SkyBoss(number: 1, x: 1.2, kind: BossKind.dragon)..age = 1;
      sim.elapsed += 10;
      final line = v.update(sim)!;
      final curve = flightVoiceMouths[line.clip.name]!;
      expect(line.speaker, 'dragon');
      var opened = false;
      for (var frame = 0; frame < curve.length; frame++) {
        clock = 100 + frame * .05 + .01;
        final face = v.speech!;
        expect(face.boss, BossKind.dragon);
        expect(face.mouth, int.parse(curve[frame]));
        opened |= face.mouth == FlightSpeech.mouths;
      }
      expect(opened, isTrue);
      clock = 100 + line.clip.seconds + .1;
      expect(v.speech!.mouth, 0, reason: 'settling after the last word');
      expect(v.speech!.talking, isFalse);
      clock = 100 + line.clip.seconds + 1;
      expect(v.speech, isNull);
      clock = 100.2;
      v.hush();
      expect(v.speech, isNull);
    });

    test('a line\'s mood comes from its direction', () {
      final tagged = flightVoiceMoods.entries.firstWhere(
        (e) => e.value == 'surprised' && e.key.startsWith('pip-'),
      );
      expect(StoryMood.values.byName(tagged.value), StoryMood.surprised);
      for (final mood in flightVoiceMoods.values) {
        expect(StoryMood.values.asNameMap(), contains(mood));
      }
      // Every played clip, story extras included, has its mouth frames.
      for (final pool in FlightVoices.recorded.pools) {
        for (final clip in FlightVoices.recorded[pool]) {
          final curve = flightVoiceMouths[clip.name];
          expect(curve, isNotNull, reason: clip.name);
          expect(curve!.length, closeTo(clip.ms / 50, 3), reason: clip.name);
        }
      }
    });

    test('names map to clip keys', () {
      expect(FlightVoices.regionKey(WorldRegion.newYork), 'new-york');
      expect(FlightVoices.regionKey(WorldRegion.jungle), 'jungle');
      expect(FlightVoices.bossKey(BossKind.duskMoth), 'empress');
      expect(
        FlightVoices.recorded['pip-sprint'].length,
        greaterThanOrEqualTo(4),
      );
    });
  });
}
