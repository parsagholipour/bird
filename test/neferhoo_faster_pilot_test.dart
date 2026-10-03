import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';

import 'neferhoo_pilot.dart';
import 'neferhoo_tougher_pilot_test.dart' show coarseRuns, slowShooter;

/// The faster Neferhoo (rules 55) measured by R1's pilots against the same
/// pilots, seeds and starts at rules 54 (the tougher Neferhoo of 52), on the
/// app's 2.2 sky (every phone flies it: `ScreenFrame` letterboxes) and at
/// 640 px. Two policies: the design model's (`careful: false`, holes and
/// all: it may cross a band about to be swept, or bob into a course edge)
/// and the careful one (those two holes closed). The model pilots meet the
/// faster clock's busier sky with many more hits; the careful ones barely
/// notice it. A real player is somewhere between: both are printed, the
/// gates hold the careful ones, the practised pilot and the slow, dodge-only
/// pilot (a push-up-paced player).
///
/// The owner beat the tougher Neferhoo in about 49 s and asked for more:
/// the practised pilot's fight is clearly longer (a fifth or more) and every
/// pilot takes more hits.
///
/// `--dart-define=NEFERHOO_PILOT_SEEDS=32` flies the handoff's tables.
const seeds = int.fromEnvironment('NEFERHOO_PILOT_SEEDS', defaultValue: 16);

const _faster = FlightSimulation.fasterNeferhooRulesVersion;
const _before = FlightSimulation.cooRestartRulesVersion;

List<NeferhooFightRun> _fights(
  NeferhooSkill skill,
  double width,
  int version, {
  required bool careful,
}) => [
  for (var s = 0; s < seeds; s++)
    flyNeferhoo(
      neferhooArena(width: width, startY: variedStart(s), version: version),
      NeferhooPilot(skill, seed: 1000 + s, careful: careful),
      width: width,
      phase: s * 13,
      seconds: 480,
    ),
];

double _median(List<NeferhooFightRun> runs) =>
    quantile([for (final r in runs) ?r.fight], .5);
double _hits(List<NeferhooFightRun> runs) =>
    runs.fold(0, (s, r) => s + r.hits) / runs.length;
double _ko(List<NeferhooFightRun> runs) =>
    runs.where((r) => r.knockedOut).length / runs.length;
double _won(List<NeferhooFightRun> runs) =>
    runs.where((r) => r.fight != null).length / runs.length;

void main() {
  for (final width in [2.2, 640 / 360]) {
    final px = (width * 360).round();
    test('$px px: clearly harder than rules 54, and still won', () {
      for (final careful in [false, true]) {
        final policy = careful ? 'careful' : 'model  ';
        final rows = <String, (List<NeferhooFightRun>, List<NeferhooFightRun>)>{};
        for (final skill in [expert, family, kid, slowShooter]) {
          final before = _fights(skill, width, _before, careful: careful);
          final now = _fights(skill, width, _faster, careful: careful);
          rows[skill.name] = (before, now);
          for (final (v, runs) in [(_before, before), (_faster, now)]) {
            // ignore: avoid_print
            print('$px v$v $policy ${row(skill.name, runs)}');
          }
        }
        final (expert54, expert55) = rows['expert']!;
        // The practised pilot always wins on the app's sky (nearly always on
        // a 640 px one), and his fight is clearly longer.
        expect(
          _won(expert55),
          width == 2.2 ? 1 : greaterThanOrEqualTo(.9),
          reason: '$px $policy expert',
        );
        expect(
          _median(expert55),
          greaterThan(_median(expert54) * 1.1),
          reason: '$px $policy expert',
        );
        if (!careful) {
          // Every model pilot takes more hits a fight.
          for (final MapEntry(key: name, value: (before, now)) in rows.entries) {
            expect(_hits(now), greaterThan(_hits(before)), reason: '$px $name');
          }
        } else if (width == 2.2) {
          // On the app's sky the careful family and first-timer still win.
          final (_, family55) = rows['family']!;
          final (_, kid55) = rows['kid']!;
          expect(_ko(family55), lessThanOrEqualTo(.15), reason: 'family');
          expect(_ko(kid55), lessThanOrEqualTo(.25), reason: 'kid');
          expect(_won(family55), greaterThanOrEqualTo(.85), reason: 'family');
          expect(_won(kid55), greaterThanOrEqualTo(.6), reason: 'kid');
          expect(_median(family55), lessThan(240), reason: 'family');
        }
      }
    }, timeout: const Timeout(Duration(minutes: 30)));
  }

  test('the slow, dodge-only pilot on the app\'s 2.2 sky: under 1.5 hits '
      'a minute, rarely knocked out in two minutes of the full fight', () {
    for (final width in [2.2, 640 / 360]) {
      final px = (width * 360).round();
      final before = coarseRuns(width, _before, count: seeds);
      final now = coarseRuns(width, _faster, count: seeds);
      for (final (v, r) in [(_before, before), (_faster, now)]) {
        // ignore: avoid_print
        print(
          '$px v$v coarse ${r.perMinute.toStringAsFixed(2)} hits/min, '
          'knocked out in 120 s: ${(r.knockOuts * 100).toStringAsFixed(0)}%',
        );
      }
      // (the tougher fight's gates: under 1.5 hits a minute, a knock-out in
      // at most one run in seven; 55 measured .67 and 6% over 32 seeds,
      // against .27 and none at 54)
      if (width == 2.2) {
        expect(now.perMinute, lessThan(1.5));
        expect(now.knockOuts, lessThanOrEqualTo(.15));
      }
    }
  }, timeout: const Timeout(Duration(minutes: 20)));
}
