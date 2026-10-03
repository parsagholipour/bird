// Why does the casual King Coo bot take his squadron's first picket in every
// fight? An opt-in analysis (it asserts only that the probe itself is sound;
// run it with `--dart-define=NY_COO_PROBE=true` to print the table of
// docs/validation.md and the fix round's handoff).
//
// NOTE (final integration): the table below varies the SHARED policy (it lists
// every lane of every formation at once). The R2 fix round found that policy,
// not King Coo's numbers, is what hits a casual-tempo bot, and `CooBot` got a
// `sequential` option that plans one formation at a time (see
// `king_coo_casual_test.dart`); the casual pilot of `ny_pilots.dart` now uses
// it, so the probe keeps `sequential` off to keep asking the original question.
//
// The bot (`CooBot`, R2) steers for a squadron lane only once it is
// `squadLook` seconds from crossing the bird's column AND `react` seconds
// after the puff that plans the squadron. King Coo's puff is at 7.6 s of his
// 14 s cycle, the whistle at 9.2 s, and a lane crosses the column 1.2 s (at
// 1.6 screen heights wide), 1.5 s (640 px), 2.0 s (800 px) or 2.2 s (2.4 wide)
// after it: the telegraph is 2.8, 3.1, 3.6 or 3.8 s long. The proof of R2
// (`king_coo_fair_test`, 5 taps a second) and the review's port of it to 2.5
// taps a second (`reports/21-review-play/coo-viability-by-taps.txt`) say how
// long a player may ignore the puff and still have a safe path: at 2.5 taps a
// second 0.9 s (picket at 1.6 wide), 1.0 s (1.78), 1.8 s (2.22); the V 1.3,
// 1.4 and 2.0 s; the bomb 0.7 s. This probe flies the real fight with the
// bot's squadLook, margin and tap rate varied, and counts the fights in which
// the squadron hits.
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';

import 'king_coo_helpers.dart' as coo;
import 'ny_hit_log.dart';
import 'ny_pilots.dart';

const _probe = bool.fromEnvironment('NY_COO_PROBE');

/// The shared bot with its two look-ahead times named for the probe
/// (`CooBot.squadLook` and `CooBot.cloudLook`, which the R2 fix round added to
/// the bot itself; everything else is `CooBot.target` as it is).
class LookBot extends coo.CooBot {
  LookBot({
    super.react,
    super.margin,
    super.tapsPerSecond,
    super.aim,
    super.gap,
    super.squadLook,
    super.cloudLook,
    super.sequential,
  });
}

/// A fight from the real run-up of 3-2, [phase] frames of shoot shift in:
/// the squadron and cloud hits taken, and whether he fell.
({int squad, int cloud, bool won}) _fight(
  LookBot bot,
  double width,
  int phase,
) {
  // New York's fight (rules 43), the one the probe was built to study.
  final run = flyNewYork(
    '3-2',
    width: width,
    phase: phase,
    stopAtBoss: true,
    version: FlightSimulation.newYorkRulesVersion,
  );
  final sim = run.sim;
  final d = DirectDriver(sim);
  final log = HitLog();
  final boss = sim.boss!;
  var frames = 0;
  while (boss.phase == BossPhase.attacking &&
      sim.phase != RunPhase.ended &&
      frames++ < 60 * 240) {
    final flap = bot.flap(sim);
    if (bot.shoot(sim)) d.shoot();
    log.before(sim);
    d.frame(flap: flap, width: width);
    log.after(sim);
  }
  final by = log.byCause();
  return (
    squad: by['squad-pigeon'] ?? 0,
    cloud: by['crumb-cloud'] ?? 0,
    won: boss.phase == BossPhase.defeated,
  );
}

void main() {
  test('the probe is the CooBot when its look-aheads are the defaults', () {
    // Same flight, bit for bit, as the bot the pilots use (casual, which plans
    // one formation at a time since the R2 fix round).
    final a = _fight(
      LookBot(
        react: .8,
        margin: .07,
        gap: 1.3,
        aim: .06,
        tapsPerSecond: 2.5,
        sequential: true,
      ),
      800 / 360,
      0,
    );
    final run = flyNewYork(
      '3-2',
      skill: Skill.casual,
      width: 800 / 360,
      phase: 0,
      version: FlightSimulation.newYorkRulesVersion,
    );
    final b = run.fightHits;
    expect(a.squad, b.where((h) => h.cause == 'squad-pigeon').length);
    expect(a.cloud, b.where((h) => h.cause == 'crumb-cloud').length);
    expect(a.won, run.boss!.phase == BossPhase.defeated);
  });

  test(
    'squadron hits by the bot\'s tap rate and squadLook (12 phases)',
    () {
      if (!_probe) return;
      final widths = {
        '1.6': 1.6,
        '640': 640 / 360,
        '800': 800 / 360,
        '2.4': 2.4,
      };
      // ignore: avoid_print
      print(
        'taps/s  squadLook   fights with a squadron hit, of 12 phases, at '
        'width ${widths.keys.join('  ')}',
      );
      for (final taps in [2.5, 3.5, 5.0]) {
        for (final look in [1.6, 2.0, 2.4, 2.8]) {
          final row = <String>[];
          for (final width in widths.values) {
            var hit = 0;
            for (final phase in spreadPhases(12)) {
              final r = _fight(
                LookBot(
                  react: .8,
                  margin: .07,
                  gap: 1.3,
                  aim: .06,
                  tapsPerSecond: taps,
                  squadLook: look,
                ),
                width,
                phase,
              );
              if (r.squad > 0) hit++;
            }
            row.add('$hit'.padLeft(2));
          }
          // ignore: avoid_print
          print(
            '${taps.toString().padRight(7)} ${look.toString().padRight(10)}'
            ' ${row.join('    ')}',
          );
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 20)),
  );
}
