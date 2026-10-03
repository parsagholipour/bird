// W3 integration: Neferhoo's cue layer against the REAL rules. The audio
// agent wired his cues to the contract's latches and counters before the
// rules (R1) filled them in, and tested them by setting those by hand
// (neferhoo_audio_test.dart). Here a real flight of level 2-6, flown by the
// shared bot, raises them, and after every step the cue class is fed the way
// SkyAudio feeds it: each cue must play on the step its edge happens and on
// no other, and at the end every cue has sounded exactly as often as the
// rules say it happened (a counter the rules never raise, or raise under
// another meaning, fails here).
//
// M1 merged the rules (R1): the test no longer skips itself. R1's counters
// rise once per event (`mailLocks` per lock, `ankhThrows` per ankh,
// `returnsLanded` at most once a step), so those cues are counted exactly;
// the same flight also feeds S1's flight-voice director, whose Neferhoo
// moments (attack = a mail call, summon = an ankh thrown, hurt = a returned
// letter landing) must each follow such a rise.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/boss_audio_cues.dart';
import 'package:push_up_bird/game/flight_voices.dart';

import 'campaign_flight.dart' show flyLevel, levelFlight;

/// The edges a step can raise, read straight off the boss.
class Edges {
  Edges(SkyBoss boss) {
    final fight = boss.neferhoo;
    final fighting = boss.phase == BossPhase.attacking;
    mailLocks = fight.mailLocks;
    mailLockedAt = fight.mailLockedAt;
    ankhLockedAt = fight.ankhLockedAt;
    returned = fight.lettersReturned;
    landed = fight.returnsLanded;
    scuffs = fight.wrapScuffs;
    caught = fight.ankhCatches;
    throws = fight.ankhThrows;
    released = fighting
        ? fight.letters.where((l) => l.dealtBy(boss.age)).length
        : 0;
    thrown = fighting
        ? fight.ankhs.where((a) => boss.age >= a.thrownAt).length
        : 0;
  }

  late final int mailLocks, returned, landed, scuffs, caught, throws;
  late final int released, thrown;
  late final double mailLockedAt, ankhLockedAt;
}

/// A bank with his own pools only (no taunt), two clips each: any line
/// heard is one of his.
FlightVoiceBank _his() => FlightVoiceBank.of({
  for (final moment in const [
    'arrive',
    'card',
    'attack',
    'summon',
    'hurt',
    'gloat',
    'mad',
    'defeated',
  ])
    for (final n in const ['01', '02']) 'neferhoo-$moment-$n': 800,
});

void main() {
  for (final width in [1.78, 2.22]) {
    test(
      'the cues are his edges, once each, in a real fight at $width',
      () {
        final sim = levelFlight(Campaign.level('2-6')!);
        final ear = BossAudioCues();
        // S1's director with his own pools only (every chance rolled in):
        // what he says follows from what happens.
        final voices = FlightVoices(
          bird: 0,
          mode: PlayMode.touch,
          level: Campaign.level('2-6'),
          bank: _his(),
          random: Random(3),
          clock: () => sim.elapsed,
          talk: 10,
        );
        final said = <(String, double)>[];
        final rises = <String, List<double>>{
          'attack': [],
          'summon': [],
          'hurt': [],
        };
        final played = <String>[];
        SkyBoss? seen;
        Edges? before;
        var steps = 0;
        var fightSteps = 0;
        flyLevel(
          sim,
          viewportWidth: width,
          sprintWhen: (sim, frame) => false,
          seconds: 300,
          watch: (s) {
            final boss = s.boss;
            final cues = ear.advance(boss);
            final line = voices.update(s);
            if (line != null) said.add((line.clip.name, s.elapsed));
            steps++;
            if (boss == null || !boss.isNeferhoo) return;
            seen = boss;
            played.addAll(cues);
            final now = Edges(boss);
            final was = before;
            before = now;
            if (was == null) return;
            if (now.mailLocks > was.mailLocks) rises['attack']!.add(s.elapsed);
            if (now.throws > was.throws) rises['summon']!.add(s.elapsed);
            if (now.landed > was.landed) rises['hurt']!.add(s.elapsed);
            if (boss.phase != BossPhase.attacking) return;
            fightSteps++;
            void edge(
              String cue,
              bool happened, {
              List<String> also = const [],
            }) {
              final heard = cues.contains(cue) || also.any(cues.contains);
              expect(
                heard,
                happened,
                reason:
                    '$cue at ${boss.age.toStringAsFixed(3)} s of his encounter: '
                    'heard $cues',
              );
            }

            edge('mail_call', now.mailLockedAt > was.mailLockedAt);
            edge('letter_flick', now.released > was.released);
            edge('letter_return', now.returned > was.returned);
            edge(
              'postage_due',
              now.landed > was.landed,
              also: const ['postage_due_duck'],
            );
            edge(
              'wrap_scuff',
              now.scuffs > was.scuffs,
              also: const ['wrap_scuff_duck'],
            );
            edge('ankh_raise', now.ankhLockedAt > was.ankhLockedAt);
            edge('ankh_whir', now.thrown > was.thrown);
            edge('ankh_catch', now.caught > was.caught);
          },
        );
        final boss = seen;
        expect(boss, isNotNull, reason: 'the flight met Neferhoo ($steps steps)');
        expect(fightSteps, greaterThan(0), reason: 'he fought');
        final fight = boss!.neferhoo;
        expect(boss.defeatedAt, isNotNull, reason: 'the shared bot beat him');
        expect(sim.endReason, EndReason.completed);
        expect(fight.mailLocks, greaterThan(0), reason: 'the real rules deal');
        expect(fight.returnsLanded, greaterThan(0));
        expect(fight.ankhThrows, greaterThan(0));
        int count(String cue) => played.where((c) => c == cue).length;
        // The totals. The rules raise these once per event and never two in
        // one step (a lock, a flick, an ankh's lock, throw and homecoming, a
        // landing: R1's `landingGap`), so each is heard exactly as often; a
        // bulk return can send several letters back in one step (one cue).
        expect(count('mail_call'), fight.mailLocks);
        expect(count('ankh_raise'), fight.ankhLocks);
        expect(
          count('postage_due') + count('postage_due_duck'),
          fight.returnsLanded,
        );
        // M1's fix round: his hits never ring the generic boss_hit (a rock on
        // his wraps is only the cloth thud), fury's cry is never followed by
        // a second roar, a landing in the cry's frame is ducked under it,
        // and the lost letter chimes after the victory stinger.
        expect(count('boss_hit'), 0);
        expect(count('hoopoe_roar'), 2, reason: 'the arrival and the full fight');
        expect(count('mummy_fury'), 1);
        expect(count('letter_flick'), fight.lettersDealt);
        expect(count('ankh_whir'), fight.ankhThrows);
        expect(count('ankh_catch'), fight.ankhCatches);
        expect(
          count('letter_return'),
          allOf(greaterThan(0), lessThanOrEqualTo(fight.lettersReturned)),
        );
        expect(count('mask_pop'), 1);
        expect(count('lost_letter'), 1);
        // S1's flight voices: each of his moments right after its rise (a
        // line may wait for the one before it to finish), never otherwise.
        String moment(String clip) => FlightVoiceBank.poolOf(clip);
        for (final (clip, at) in said) {
          final kind = moment(clip).replaceFirst('neferhoo-', '');
          final edges = rises[kind];
          if (edges == null) continue;
          expect(
            edges.any((e) => at >= e - 1e-9 && at - e < 3),
            isTrue,
            reason: '$clip at ${at.toStringAsFixed(2)} s follows no $kind '
                'rise (${edges.map((e) => e.toStringAsFixed(2))})',
          );
        }
        // ignore: avoid_print
        print(
          '$width: defeated at combat ${(boss.defeatedAt! - boss.arrivalDuration).toStringAsFixed(1)} s; '
          'locks ${fight.mailLocks}/${fight.ankhLocks}, dealt ${fight.lettersDealt}, '
          'returned ${fight.lettersReturned}, landed ${fight.returnsLanded}, '
          'throws ${fight.ankhThrows}, catches ${fight.ankhCatches}, scuffs ${fight.wrapScuffs}; '
          'cues ${{for (final c in played) c: count(c)}}; '
          'voice lines ${said.map((l) => '${l.$1}@${l.$2.toStringAsFixed(1)}').join(' ')}',
        );
        final heard = {for (final (clip, _) in said) moment(clip)};
        expect(
          heard,
          containsAll(['neferhoo-attack', 'neferhoo-summon', 'neferhoo-hurt']),
          reason: 'heard ${said.map((l) => l.$1)}',
        );
        expect(
          count('wrap_scuff') + count('wrap_scuff_duck'),
          lessThanOrEqualTo(fight.wrapScuffs),
        );
        expect(count('letter_flick'), greaterThan(0));
        // His own roar, fury and burst replace the generic ones.
        expect(count('hoopoe_roar'), greaterThanOrEqualTo(1));
        expect(
          count('boss_roar') + count('boss_enrage') + count('boss_burst'),
          0,
        );
      },
      timeout: const Timeout(Duration(minutes: 4)),
    );
  }
}
