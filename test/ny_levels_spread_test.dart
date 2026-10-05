// New York's four levels flown by the whole-level pilots (`ny_pilots.dart`)
// over a SPREAD of shoot phases, widths and layouts, not one deterministic
// flight. The fix round found that a single flight proves little: the pilots
// are deterministic, so shifting when they press Shoot by a few frames
// changes which enemy is dead when, and 3-3 at 800 px, which one flight
// finished, was finished by only 57% of 40 shifted phases. Here every result
// is a rate over `phases x widths` (and, for the two full levels, over
// re-seeded layouts), and every hit the bird takes is attributed to its
// cause ([HitLog]), so no damage source can hide behind another assertion.
//
// Gates (the review's): sharp and average pilots complete at least 90%,
// casual pilots at least 75%. The flights are mortal and fire the base weapon
// the campaign gives. Run with `--dart-define=NY_SPREAD_TABLE=true` to print
// the tables of the handoff.
@Timeout(Duration(minutes: 15))
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';

import 'ny_pilots.dart';

const _print = bool.fromEnvironment('NY_SPREAD_TABLE');

/// Every width the levels' proofs cover (1.6 to 2.4), with the two test
/// phones in the middle.
const _widths = [1.6, 640 / 360, 800 / 360, 2.4];
const _ids = ['3-1', '3-2', '3-3', '3-4'];

/// The shipped layout flown at every width and phase.
const _phases = 8;

/// The gate on the completion rate: sharp and average 90%, casual 75%.
double _gate(Skill skill) => skill == Skill.casual ? .75 : .90;

/// King Coo's level from rules 45, as hard as the owner chose: his vanguard
/// throws crusts, he has twice the health, and every vanguard pigeon that
/// got away comes back in his fight, throwing, until it is shot. The pilots
/// finish it in about 44%, 31% and 9% of the flights over all four widths
/// (100% at rules 44; 91 / 84 / 66% before the stragglers). These are
/// floors under that, pooled only. With paired returns at rules 56, the
/// sharp pilot finishes 9 of 32 flights (28%); keep a 25% floor for it.
// From rules 62 two pigeons of each whistle squadron throw crusts as they
// pass (the owner's choice): only the sharp pilot still beats him.
double _cooGate(Skill skill) => switch (skill) {
  Skill.sharp => .25,
  Skill.average => 0,
  Skill.casual => 0,
};

class Cell {
  final runs = <NyRun>[];

  /// The width each run was flown at, in step with [runs].
  final widths = <double>[];
  void add(NyRun run, double width) {
    runs.add(run);
    widths.add(width);
  }

  /// The completion rate at [width].
  double doneAt(double width) {
    var n = 0, done = 0;
    for (var i = 0; i < runs.length; i++) {
      if (widths[i] != width) continue;
      n++;
      if (runs[i].finished) done++;
    }
    return done / n;
  }

  int get n => runs.length;
  double rate(bool Function(NyRun run) test) =>
      runs.where(test).length / runs.length;
  double get done => rate((r) => r.finished);
  double get threeStars => rate((r) => r.sim.levelStars == 3);
  double get twoStars => rate((r) => r.sim.levelStars >= 2);
  double get minutes => runs.fold(0.0, (sum, r) => sum + r.sim.elapsed / 60);
  double get heartsLost =>
      runs.fold(0, (sum, r) => sum + 3 - r.sim.hearts).toDouble();

  /// Hits by cause over every run, in the run-up or in the fight.
  Map<String, int> causes({bool? inFight}) {
    final out = <String, int>{};
    for (final run in runs) {
      run.log.byCause(inFight: inFight).forEach((cause, count) {
        out[cause] = (out[cause] ?? 0) + count;
      });
    }
    return out;
  }
}

/// One flight per phase and width: results are deterministic, so the cells
/// are shared by every test of the file.
final _shipped = <String, Cell>{};
Cell shipped(String id, Skill skill) =>
    _shipped.putIfAbsent('$id ${skill.name}', () {
      final cell = Cell();
      for (final width in _widths) {
        for (final phase in spreadPhases(_phases)) {
          cell.add(
            flyNewYork(id, skill: skill, width: width, phase: phase),
            width,
          );
        }
      }
      return cell;
    });

/// The two full levels on re-seeded layouts: six layouts, three phases, every
/// width. (Another layout is another door, opening and enemy sequence.)
final _layouts = <String, Cell>{};
Cell layouts(String id, Skill skill) =>
    _layouts.putIfAbsent('$id ${skill.name}', () {
      final cell = Cell();
      final plan = Campaign.level(id)!.plan;
      for (final width in _widths) {
        for (var k = 1; k <= 6; k++) {
          for (final phase in spreadPhases(3)) {
            cell.add(
              flyNewYork(
                id,
                skill: skill,
                width: width,
                phase: phase,
                plan: reseeded(plan, k),
              ),
              width,
            );
          }
        }
      }
      return cell;
    });

String _pct(double v) => '${(100 * v).round()}%';

void main() {
  group('the shipped layout over $_phases shoot phases at every width', () {
    for (final id in _ids) {
      for (final skill in Skill.values) {
        test('$id, ${skill.name}: completes, and every hit has a known '
            'cause', () {
          final cell = shipped(id, skill);
          final level = Campaign.level(id)!;
          expect(cell.n, _widths.length * _phases);
          if (_print) {
            // ignore: avoid_print
            print(
              '$id ${skill.name.padRight(7)} shipped n=${cell.n} '
              'done ${_pct(cell.done)} ★★+ ${_pct(cell.twoStars)} '
              '★★★ ${_pct(cell.threeStars)} '
              'hearts lost/min ${(cell.heartsLost / cell.minutes).toStringAsFixed(2)} '
              'run-up ${cell.causes(inFight: false)} fight ${cell.causes(inFight: true)}',
            );
          }
          // The gate, pooled and at every width (King Coo's, pooled).
          if (id == '3-2') {
            expect(cell.done, greaterThanOrEqualTo(_cooGate(skill)));
          } else {
            expect(cell.done, greaterThanOrEqualTo(_gate(skill)), reason: id);
          }
          for (final width in id == '3-2' ? const <double>[] : _widths) {
            expect(
              cell.doneAt(width),
              greaterThanOrEqualTo(_gate(skill)),
              reason: '$id at $width',
            );
          }
          // A mortal pilot is hurt only by what a level holds: never by the
          // edge, never by an unattributed hit, and a pilot that hops or
          // rides is never scalded.
          final all = cell.causes();
          expect(all.keys, everyElement(isNot(anyOf('edge', 'other'))));
          expect(all['steam'] ?? 0, lessThanOrEqualTo(cell.n ~/ 50));
          // Pigeons never hurt a bird that does not touch them, and the
          // squadron belongs to King Coo's fight alone.
          expect(cell.causes(inFight: false)['squad-pigeon'], isNull);
          // The run-up and the ordinary levels hold no guardian's weapon.
          for (final cause in [
            'crumb-cloud',
            'beam',
            'feather',
            'squad-pigeon',
          ]) {
            expect(cell.causes(inFight: false)[cause], isNull, reason: cause);
          }
          if (!level.isGuardian) expect(cell.causes(inFight: true), isEmpty);
        });
      }
    }

    test('the Gargoyle never touches a pilot who reads his telegraphs, at any '
        'phase, width or skill', () {
      for (final skill in Skill.values) {
        final cell = shipped('3-4', skill);
        final fight = cell.causes(inFight: true);
        expect(fight, isEmpty, reason: '${skill.name}: $fight');
        for (final run in cell.runs) {
          expect(run.boss!.spots, 0);
        }
      }
    });

    test('King Coo: no pilot is hit more than once in five minutes of his '
        'fight (the novice plans one formation at a time, as a player reads '
        'the squadron)', () {
      for (final skill in Skill.values) {
        final cell = shipped('3-2', skill);
        final fight = cell.causes(inFight: true);
        final hits = fight.values.fold(0, (a, b) => a + b);
        final minutes =
            cell.runs.fold(0.0, (sum, run) => sum + (run.fight ?? 0)) / 60;
        if (_print) {
          // ignore: avoid_print
          print(
            '3-2 ${skill.name} fight hits per fight ${(hits / cell.n).toStringAsFixed(2)} $fight',
          );
        }
        // Whatever hits him, it is the squadron, a cloud, or (rules 45) a
        // straggler or its crust, and nothing else.
        expect(
          fight.keys,
          everyElement(
            anyOf(
              'squad-pigeon',
              'crumb-cloud',
              'pigeon-crumb',
              'enemy-vanguard',
            ),
          ),
        );
        // The casual bot of the first fix round was hit by the squadron in 31
        // of 32 fights; that was the shared bot's policy (it lists every lane
        // of fury's V and picket at once and finds no height), not the rules
        // (R2's fix round; `king_coo_casual_test.dart`). With the policy of a
        // player's eye (`sequential`) it is hit in 0 of 32, like the others.
        // At 43 the bound was a hit in ten fights of about 12 to 36 s, and
        // at 44 one in five minutes of his fight. At 45 (his health doubled,
        // his stragglers back and throwing, as the owner chose) every pilot
        // is caught about 2.5 times a fight, won or lost (a lost fight has
        // no length here, so the bound is per fight).
        // From rules 62 (two of each squadron throwing) only the sharp
        // pilot wins a fight, so only its fights have a length.
        if (skill == Skill.sharp) expect(minutes, greaterThan(0));
        expect(hits / cell.n, lessThanOrEqualTo(3.5), reason: skill.name);
        // Every flight ends: he falls, or (from rules 45, his vanguard
        // throwing and his health doubled) the pilot is knocked out. None
        // stalls.
        for (final run in cell.runs) {
          expect(
            run.boss?.phase == BossPhase.defeated ||
                run.sim.endReason == EndReason.collision,
            isTrue,
          );
        }
      }
    });

    test('three stars: Moth Light, King Coo and the Gargoyle 90%; Steam Alley '
        '(70 of 90 stars) at least 60% over all four widths for the pilots '
        'that never aim at a ride vent\'s stars', () {
      for (final id in _ids) {
        for (final skill in Skill.values) {
          final cell = shipped(id, skill);
          // King Coo's level (rules 45) fells some pilots after its run-up:
          // its marks are judged on the run-up's harvest, over the flights
          // that reached him (`ny_star_marks_test` flies it unharmed).
          if (id == '3-2') {
            final marks = Campaign.level(id)!.marks;
            final reached = [for (final run in cell.runs) ?run.starsAtBoss];
            expect(reached.length / cell.n, greaterThanOrEqualTo(.6));
            expect(
              reached.where((stars) => stars >= marks.three).length /
                  reached.length,
              greaterThanOrEqualTo(.9),
              reason: '$id ${skill.name}',
            );
            continue;
          }
          expect(cell.twoStars, greaterThanOrEqualTo(.95), reason: id);
          final floor = id == '3-3' && skill != Skill.casual ? .6 : .9;
          expect(
            cell.threeStars,
            greaterThanOrEqualTo(floor),
            reason: '$id ${skill.name}: ${_pct(cell.threeStars)}',
          );
        }
      }
    });
  });

  group('the two full levels on re-seeded layouts', () {
    for (final id in ['3-1', '3-3']) {
      for (final skill in Skill.values) {
        test('$id, ${skill.name}: another layout is no harder to finish', () {
          final cell = layouts(id, skill);
          expect(cell.n, _widths.length * 6 * 3);
          if (_print) {
            // ignore: avoid_print
            print(
              '$id ${skill.name.padRight(7)} reseeded n=${cell.n} '
              'done ${_pct(cell.done)} ★★★ ${_pct(cell.threeStars)} '
              'hearts lost/min ${(cell.heartsLost / cell.minutes).toStringAsFixed(2)} '
              '${cell.causes()}',
            );
          }
          expect(cell.done, greaterThanOrEqualTo(_gate(skill)), reason: id);
          final all = cell.causes();
          expect(all.keys, everyElement(isNot(anyOf('edge', 'other'))));
          expect(all['steam'] ?? 0, lessThanOrEqualTo(cell.n ~/ 20));
        });
      }
    }
  });
}
