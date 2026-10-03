import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';

import 'neferhoo_pilot.dart';

/// The tougher Neferhoo (rules 52: 600 health, letters 1.4 times faster,
/// mummy bats from the full fight on) measured by R1's pilots (the design
/// model's policy, `neferhoo_pilot.dart`, who learned the bats: they stay
/// in the lane to shoot one down with their return chance, else keep out of
/// its band; the slow dodge-only pilot is the careful one, as in R1's gate) on
/// main's 792 x 360 sky (2.2 wide) and at 640 px, against the same pilots,
/// seeds and starts at rules 50. The owner played 2-6 and said "It's so
/// easy": the gates below hold it clearly harder (every pilot's fight at
/// least half as long again, more hits a fight) yet fair (every hazard is
/// telegraphed and dodgeable: `neferhoo_tougher_fairness_test.dart`), the
/// family pilot never knocked out more than one fight in ten and a
/// first-timer winning most fights.
///
/// `--dart-define=NEFERHOO_PILOT_SEEDS=100` flies the handoff's tables (the
/// default keeps the suite quick); the rows are printed either way.
const seeds = int.fromEnvironment('NEFERHOO_PILOT_SEEDS', defaultValue: 16);

const _tougher = FlightSimulation.tougherNeferhooRulesVersion;
const _fifty = FlightSimulation.neferhooRulesVersion;

/// A slow-tapping first-timer who shoots: the kid's eye and aim at 1.5 taps
/// a second (QA's "slow 1.5-taps shooter").
const slowShooter = NeferhooSkill(
  'slow shooter',
  react: .80,
  jitter: .30,
  tapsPerSecond: 1.5,
  aimTol: .06,
  fireRate: 1.0,
  margin: .06,
  returnChance: .45,
  noise: .07,
);

/// [seeds] mortal fights of [skill] at [width] and [version], each with its
/// own seed, start and shot phase (13 frames apart).
List<NeferhooFightRun> fights(
  NeferhooSkill skill,
  double width,
  int version, {
  int count = seeds,
}) => [
  for (var s = 0; s < count; s++)
    flyNeferhoo(
      neferhooArena(width: width, startY: variedStart(s), version: version),
      NeferhooPilot(skill, seed: 1000 + s),
      width: width,
      phase: s * 13,
      seconds: 420,
    ),
];

/// Hits a minute and the knock-out share of the slow, dodge-only pilot (1.5
/// taps a second, never shoots) through two minutes of his full fight (the
/// ankh and, at 52, a pair of bats with every call), from varied starts.
({double perMinute, double knockOuts}) coarseRuns(
  double width,
  int version, {
  int count = seeds,
}) {
  var hits = 0, seconds = 0.0, knockOuts = 0;
  for (var s = 0; s < count; s++) {
    for (final immortal in [true, false]) {
      final run = flyNeferhoo(
        neferhooArena(width: width, startY: variedStart(s), version: version),
        NeferhooPilot(coarse, seed: 2000 + s, careful: true),
        width: width,
        phase: s * 13,
        seconds: 120,
        keepAlive: immortal,
        stage: 1,
      );
      if (immortal) {
        hits += run.hits;
        seconds += run.seconds;
      } else if (run.knockedOut) {
        knockOuts++;
      }
    }
  }
  return (perMinute: hits / seconds * 60, knockOuts: knockOuts / count);
}

double _median(List<NeferhooFightRun> runs) =>
    quantile([for (final r in runs) ?r.fight], .5);

double _hits(List<NeferhooFightRun> runs) =>
    runs.fold(0, (s, r) => s + r.hits) / runs.length;

double _ko(List<NeferhooFightRun> runs) =>
    runs.where((r) => r.knockedOut).length / runs.length;

void main() {
  for (final width in [2.2, 640 / 360]) {
    final px = (width * 360).round();
    test('$px px: clearly harder than rules 50 for every pilot, and still '
        'won', () {
      final rows = <String, (List<NeferhooFightRun>, List<NeferhooFightRun>)>{};
      for (final skill in [kid, family, expert, slowShooter]) {
        final before = fights(skill, width, _fifty);
        final now = fights(skill, width, _tougher);
        rows[skill.name] = (before, now);
        for (final (v, runs) in [(_fifty, before), (_tougher, now)]) {
          // ignore: avoid_print
          print('$px v$v ${row(skill.name, runs)}');
        }
      }
      for (final MapEntry(key: name, value: (before, now)) in rows.entries) {
        final won = now.where((r) => r.fight != null).toList();
        // Clearly harder: half as long again (or more), and more hits.
        expect(
          _median(won),
          greaterThan(_median(before) * 1.5),
          reason: '$px $name',
        );
        expect(_hits(now), greaterThan(_hits(before)), reason: '$px $name');
        // Every win grows stronger twice.
        for (final r in won) {
          expect(r.furyAt, isNotNull, reason: '$px $name');
        }
      }
      final (_, family52) = rows['family']!;
      final (_, kid52) = rows['kid']!;
      final (_, expert52) = rows['expert']!;
      // The practised player always wins, the family nearly always (a
      // knock-out in at most one fight in ten), and a first-timer wins
      // most fights.
      expect(expert52.every((r) => r.fight != null), isTrue);
      expect(_ko(family52), lessThanOrEqualTo(.1), reason: '$px family');
      expect(_ko(kid52), lessThanOrEqualTo(.5), reason: '$px kid');
      // A guardian's length for a family (King Coo's staged fight is 2.5
      // to 3 minutes for an average pilot), well under five minutes for a
      // first-timer.
      expect(_median(family52), lessThan(180), reason: '$px family');
      expect(_median(kid52), lessThan(300), reason: '$px kid');
    }, timeout: const Timeout(Duration(minutes: 20)));
  }

  test('the slow, dodge-only pilot: more hits a minute than at 50, rarely '
      'knocked out in two minutes of the full fight', () {
    for (final width in [2.2, 640 / 360]) {
      final px = (width * 360).round();
      final before = coarseRuns(width, _fifty);
      final now = coarseRuns(width, _tougher);
      for (final (v, r) in [(_fifty, before), (_tougher, now)]) {
        // ignore: avoid_print
        print(
          '$px v$v coarse ${r.perMinute.toStringAsFixed(2)} hits/min, '
          'knocked out in 120 s: ${(r.knockOuts * 100).toStringAsFixed(0)}%',
        );
      }
      expect(now.perMinute, lessThan(1.5), reason: '$px');
      expect(now.knockOuts, lessThanOrEqualTo(.15), reason: '$px');
    }
  }, timeout: const Timeout(Duration(minutes: 20)));
}
