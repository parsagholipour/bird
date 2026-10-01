import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/gargoyle_layout.dart';
import 'package:push_up_bird/game/gargoyle_pose.dart';

import 'campaign_flight.dart';
import 'ny_plans.dart';

/// The pose against the REAL rules: a level with the Gargoyle flown by the
/// shared bot through `FlightSimulation`, the pose built from `sim.boss` after
/// every frame. Whatever the rules latch (aim, slit, fury) and count (feathers
/// launched, lamp, warning, beam), the art must follow at the very frame:
///
///  * the lamp and the warning are the rules' (`lampOpenness`, `sweepWarning`);
///  * while a beam burns, the drawn bands are `SkyBoss.beamCentres` and
///    `beamHalf`, the side and kind the warning shows are the latched ones;
///  * the blade leaves the fan at the frame the rules launch a feather.
///
/// With the scaffold's stub rules (no feathers, no latching) the feather check
/// is vacuous; with R3's rules it holds for every launch of the fight.
void main() {
  test('through the real rules the pose follows the boss frame by frame', () {
    final plan = nyPlan(
      id: '3-4',
      seed: 3104,
      lineup: const [EnemyKind.simpleBat, EnemyKind.caveBat],
      boss: BossKind.searchlightGargoyle,
    );
    final sim = nyFlight(plan, weaponDamage: BirdRock.baseDamage);
    var frames = 0, beamFrames = 0, warningFrames = 0, lampFrames = 0, launches = 0, aligned = 0;
    var lastLaunched = 0;
    var cycles = <int>{};
    final problems = <String>[];
    flyLevel(
      sim,
      seconds: 300,
      // Nobody shoots: he lives through five cycles, calm for the first two and
      // a half and enraged (zone sweep, then slit, ...) after.
      shootWhen: (s) => false,
      until: (s) {
        final b = s.boss;
        return b != null && b.isGargoyle && (b.phase == BossPhase.defeated || b.combatTime > 50);
      },
      watch: (s) {
        final b = s.boss;
        if (b == null || !b.isGargoyle) return;
        if (b.phase == BossPhase.attacking && b.combatTime > 22 && !b.enraged) b.hp = b.maxHp ~/ 2 - 10;
        final gap = b.x - .299 - GargoyleLayout.birdColumn;
        final pose = GargoylePose(b, BossMotion(b, reducedMotion: false), gap: gap);
        for (final e in pose.channels.entries) {
          if (!e.value.isFinite) problems.add('t${b.age} ${e.key} not finite');
        }
        frames++;
        if (b.phase == BossPhase.attacking) {
          cycles.add(b.gargoyleCycleNumber);
          if ((pose.lamp - b.lampOpenness).abs() > 1e-12) problems.add('t${b.age}: lamp ${pose.lamp} vs ${b.lampOpenness}');
          if ((pose.warning - b.sweepWarning).abs() > 1e-12) problems.add('t${b.age}: warning');
          if (pose.stone != 0) problems.add('t${b.age}: stone in combat');
          if (pose.lamp > 0) lampFrames++;
          if (b.sweepWarning > 0) warningFrames++;
          if (b.beamOn) {
            beamFrames++;
            final rules = b.beamCentres;
            if (pose.beams.length != rules.length) {
              problems.add('t${b.age}: ${pose.beams.length} drawn beams vs ${rules.length}');
            } else {
              for (var i = 0; i < rules.length; i++) {
                if ((pose.beams[i].centre - rules[i]).abs() > 1e-12) problems.add('t${b.age}: beam $i centre');
                if (pose.beams[i].half != b.beamHalf) problems.add('t${b.age}: beam $i half');
              }
            }
          }
          if (b.beamOn || b.sweepWarning > 0) {
            if (pose.warnSide != b.beamSide) problems.add('t${b.age}: side ${pose.warnSide} vs ${b.beamSide}');
            if (pose.warnSlit != b.slitSweep) problems.add('t${b.age}: slit');
          }
          if (b.feathersLaunched > lastLaunched) {
            launches += b.feathersLaunched - lastLaunched;
            // The blade leaves in the frame the rules launch (a frame is .02 s).
            if (pose.shedTau >= 0 && pose.shedTau <= .03) aligned++;
            lastLaunched = b.feathersLaunched;
          }
        }
      },
    );
    // ignore: avoid_print
    print('rules sync: $frames frames, $beamFrames with a beam, $warningFrames in a warning, '
        '$lampFrames with the lamp open, ${cycles.length} cycles, $launches feather launches '
        '($aligned aligned with a blade leaving)');
    expect(problems.take(6), isEmpty);
    expect(frames, greaterThan(2000));
    expect(beamFrames, greaterThan(500));
    expect(warningFrames, greaterThan(300));
    expect(lampFrames, greaterThan(300));
    expect(cycles.length, greaterThanOrEqualTo(5));
    expect(aligned, launches, reason: 'every launch of a real fight has the blade leaving the fan in that frame');
  }, timeout: const Timeout(Duration(minutes: 4)));
}
