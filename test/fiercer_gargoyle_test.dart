@Timeout(Duration(minutes: 20))
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';

import 'campaign_flight.dart';
import 'gargoyle_pilot.dart' as gargoyle;
import 'gargoyle_viability.dart';
import 'ny_pilots.dart';

/// Rules version 46: the fiercer Searchlight Gargoyle. Asked after a
/// playtest of rules 45: "I like how hard King Coo is. I want Gargoyle to be
/// the same hard and same length, now you can kill fast", and then, of the
/// ways offered, his own attacks fiercer and no minions. See
/// docs/specification.md ("Campaign boss stages and vanguards", rules 46)
/// and docs/validation.md.
///
/// - His warm-up drops the calm cycle's stone feathers (none at 44 and 45).
/// - Once he grows stronger his beams glide and his feathers fly at fury's
///   pace, and a feather falls in the vent, over his open lamp; in fury two.
/// - 640 health (200 at 44 and 45).

/// The three cycles a fiercer Gargoyle adds, each as the beam it sweeps
/// (the fury zone sweep's beam in the full fight too) and its feathers.
final _cycles = <String, (Sweep, List<double>)>{
  'full fight': (
    Sweep.furyZone,
    SearchlightGargoyle.fierceFeathers(armed: true, fury: false, slit: false),
  ),
  'fury zone': (
    Sweep.furyZone,
    SearchlightGargoyle.fierceFeathers(armed: true, fury: true, slit: false),
  ),
  'fury slit': (
    Sweep.furySlit,
    SearchlightGargoyle.fierceFeathers(armed: true, fury: true, slit: true),
  ),
};

/// The search through the vent, to just before the next cycle.
Search _search(
  Sweep sweep,
  List<double> schedule, {
  double margin = .002,
  bool withPerch = false,
}) => Search(
  sweep,
  schedule: schedule,
  endAt: gargoyle.Pilot.fierceEnd,
  margin: margin,
  withPerch: withPerch,
);

/// Starts at the warning from which no tap sequence survives the cycle.
List<Start> _unwinnable(
  Sweep sweep,
  List<double> schedule, {
  double idle = 0,
  double margin = .002,
}) => [
  for (final start in survivableStarts())
    if (_search(sweep, schedule, margin: margin).from(start, idle: idle)
        case final result? when !result.safe)
      start,
];

CampaignLevel get _level => Campaign.level('3-4')!;

FlightSimulation _flight(int version) => FlightSimulation(
  rules: TapFlyMode(rulesVersion: version),
  practice: false,
  course: FlightCourse.starTrail,
  rulesVersion: version,
  plan: _level.plan,
);

/// 3-4 flown by the shared bot (hearts topped up, no shots) into the
/// Gargoyle's fight, then [seconds] of it; [hitAfter] knocks him out of his
/// warm-up then, and [furyAfter] into fury.
FlightSimulation _fight(
  int version, {
  required double seconds,
  double? hitAfter,
  double? furyAfter,
  void Function(FlightSimulation sim)? watch,
}) {
  final sim = _flight(version);
  flyLevel(
    sim,
    viewportWidth: 2.2,
    until: (sim) => sim.boss?.phase == BossPhase.attacking,
  );
  final boss = sim.boss!;
  flyLevel(
    sim,
    seconds: seconds,
    shootWhen: (_) => false,
    watch: (sim) {
      final t = boss.combatTime;
      final x = boss.gargoyleCycle;
      // His health only changes in the vent, as a rock's would.
      if (x >= SearchlightGargoyle.ventAt) {
        if (hitAfter != null && t >= hitAfter && boss.stage == 0) {
          boss.takeDamage(boss.hp - boss.maxHp * 2 ~/ 3);
        }
        if (furyAfter != null && t >= furyAfter && boss.stage == 1) {
          boss.takeDamage(boss.hp - boss.maxHp ~/ 3);
        }
      }
      watch?.call(sim);
    },
  );
  return sim;
}

void main() {
  group('the rules', () {
    test('rules 46 is the fiercer Gargoyle, in a campaign level only', () {
      // 47-49 came after it, 50 (Egypt's guardian, Neferhoo), 51 (the
      // all-rings bonus), 52 (a tougher Neferhoo), 53 (growing endless
      // bosses), 54 (King Coo's quick fury) and 55 (a faster Neferhoo).
      expect(FlightSimulation.currentRulesVersion, greaterThanOrEqualTo(55));
      expect(FlightSimulation.fiercerGargoyleRulesVersion, 46);
      expect(_flight(45).supportsFiercerGargoyle, isFalse);
      expect(_flight(46).supportsFiercerGargoyle, isTrue);
      final endless = FlightSimulation(
        rules: TapFlyMode(),
        practice: false,
        course: FlightCourse.starTrail,
      );
      expect(endless.supportsFiercerGargoyle, isFalse);
    });

    test('640 health from rules 46; 200 at 44 and 45', () {
      expect(SkyBoss.campaignHealthFor(BossKind.searchlightGargoyle), 640);
      expect(
        SkyBoss.campaignHealthFor(
          BossKind.searchlightGargoyle,
          fiercerGargoyle: false,
        ),
        200,
      );
      for (final (version, hp, fierce) in [
        (44, 200, false),
        (45, 200, false),
        (46, 640, true),
      ]) {
        final sim = _flight(version);
        flyLevel(sim, viewportWidth: 2.2, until: (sim) => sim.boss != null);
        final boss = sim.boss!;
        expect(boss.maxHp, hp, reason: '$version');
        expect(boss.fierce, fierce, reason: '$version');
        expect(boss.staged, isTrue);
      }
      // No other boss is fierce, and none changes its health.
      for (final kind in BossKind.values) {
        if (kind == BossKind.searchlightGargoyle) continue;
        expect(
          SkyBoss.campaignHealthFor(kind),
          SkyBoss.campaignHealthFor(kind, fiercerGargoyle: false),
        );
      }
    });

    test('his schedules: the calm cycle in the warm-up, then the vent too', () {
      List<double> f({
        bool armed = true,
        bool fury = false,
        bool slit = false,
      }) => SearchlightGargoyle.fierceFeathers(
        armed: armed,
        fury: fury,
        slit: slit,
      );
      expect(f(armed: false), SearchlightGargoyle.calmFeathers);
      expect(f(armed: false, fury: true), SearchlightGargoyle.calmFeathers);
      expect(f(), [.2, 4.6, 7.0]);
      expect(f(fury: true), [.2, 4.5, 5.2, 6.5, 7.4]);
      expect(f(fury: true, slit: true), [.2, 6.5, 7.4]);
      // The vent's feathers leave while the lamp is open, and each has
      // crossed the bird's column (at fury's pace, which they fly at) before
      // the cycle ends, with the pilot's plan.
      final flight = SearchlightGargoyle.featherShot(.5, enraged: true).flight;
      for (final at in [
        ...SearchlightGargoyle.ventFeathers,
        ...SearchlightGargoyle.furyVentFeathers,
      ]) {
        expect(SearchlightGargoyle.lampOpen(at), isTrue);
        expect(at + flight, lessThan(gargoyle.Pilot.fierceEnd - .1));
      }
    });

    test('in his fight: feathers in the warm-up, fury\'s pace and the vent\'s '
        'feathers once he grows stronger, two in fury', () {
      final launches =
          <(int stage, double x, double speed, bool open, bool aimFury)>[];
      var seen = 0;
      final sim = _fight(
        46,
        seconds: 110,
        hitAfter: 25,
        furyAfter: 70,
        watch: (sim) {
          final boss = sim.boss!;
          if (boss.feathersLaunched > seen) {
            seen = boss.feathersLaunched;
            final feather = sim.bossAmmo.lastWhere((a) => a.feather);
            launches.add((
              boss.stage,
              boss.gargoyleCycle,
              -feather.vx,
              boss.lampOpen,
              boss.aimFury,
            ));
          }
        },
      );
      final boss = sim.boss!;
      expect(boss.stage, 2);
      // The warm-up drops the calm cycle's two, at the calm speed, and none
      // in the vent.
      final warm = [
        for (final l in launches)
          if (l.$1 == 0) l,
      ];
      expect(warm.length, greaterThanOrEqualTo(4));
      for (final l in warm) {
        expect(l.$3, closeTo(SearchlightGargoyle.featherSpeed, 1e-9));
        expect(l.$4, isFalse);
      }
      // Once armed, every feather flies at fury's pace, and the vent drops
      // one a cycle in the full fight and two in fury.
      final vent = [
        for (final l in launches)
          if (l.$4) l,
      ];
      expect(vent.where((l) => l.$1 == 1).length, greaterThanOrEqualTo(3));
      expect(vent.where((l) => l.$1 == 2).length, greaterThanOrEqualTo(4));
      for (final l in launches.skipWhile((l) => !l.$4)) {
        expect(l.$3, closeTo(SearchlightGargoyle.furyFeatherSpeed, 1e-9));
      }
      // The vent's schedule is the one latched as the sweep was aimed: a
      // fury that begins in the vent waits for the next cycle.
      for (final l in vent) {
        final times = l.$5
            ? SearchlightGargoyle.furyVentFeathers
            : SearchlightGargoyle.ventFeathers;
        expect(
          times.any((at) => (l.$2 - at).abs() < .02),
          isTrue,
          reason: '$l',
        );
      }
      // His full fight sweeps at fury's pace: the fury band and glide.
      expect(boss.furyPace, isTrue);
      expect(boss.beamHalf, SearchlightGargoyle.furyLitHalf);
    });

    test('rules 45 keeps his old fight: no feathers in the warm-up, none in '
        'the vent, the calm pace until fury', () {
      var warmFeathers = 0, ventFeathers = 0, calmFast = 0;
      _fight(
        45,
        seconds: 60,
        hitAfter: 20,
        watch: (sim) {
          final boss = sim.boss!;
          if (boss.stage == 0) warmFeathers = boss.feathersLaunched;
          if (boss.lampOpen &&
              boss.featherCycle == boss.gargoyleCycleNumber &&
              boss.featherSlot >
                  SearchlightGargoyle.launchesDue(
                    SearchlightGargoyle.ventAt - 1e-6,
                    enraged: boss.enraged,
                    slit: boss.slitSweep,
                  )) {
            ventFeathers++;
          }
          if (!boss.enraged && boss.furyPace) calmFast++;
        },
      );
      expect(warmFeathers, 0);
      expect(ventFeathers, 0);
      expect(calmFast, 0);
    });
  });

  group('fair: a safe path through every new cycle, the vent included', () {
    for (final MapEntry(key: name, value: (sweep, schedule))
        in _cycles.entries) {
      test('$name: from all 117 starts at the warning', () {
        expect(survivableStarts(), hasLength(117));
        expect(_unwinnable(sweep, schedule), isEmpty);
      });

      test('$name: after .3 s and .45 s without a tap', () {
        for (final idle in [.3, .45]) {
          expect(
            _unwinnable(sweep, schedule, idle: idle),
            isEmpty,
            reason: '$idle',
          );
        }
      });

      test('$name: with a wider margin (.012)', () {
        expect(_unwinnable(sweep, schedule, margin: .012), isEmpty);
      });

      test('$name: the whole cycle from the perch feather\'s launch', () {
        final bad = [
          for (final start in survivableStarts())
            if (!_search(
              sweep,
              schedule,
              withPerch: true,
            ).fromPerch(start).safe)
              start,
        ];
        expect(bad, isEmpty);
      });
    }
  });

  group('as long as King Coo, and harder than before', () {
    // A pilot that knows his cycle by heart (`ny_pilots.dart`, the one New
    // York's level tests fly) is never touched; one that reacts as King
    // Coo's bots do (.3, .55 and .8 s; 5, 3.5 and 2.5 taps a second) is
    // caught more often than by the rules 45 Gargoyle, and the slowest of
    // them rarely wins. Measured over 4 widths x 2 shoot phases at the
    // fiercer Gargoyle's handoff (docs/validation.md): sharp 8/8 and no hit,
    // average 8/8 and .5 hits a flight, casual 0/8 (5 hits a flight); at 45
    // 4/4, 4/4 and 3/4.
    gargoyle.Pilot reacting(Skill skill) => switch (skill) {
      Skill.sharp => gargoyle.Pilot(
        cadence: .3,
        fireFrom: 0,
        window: .09,
        react: .3,
      ),
      Skill.average => gargoyle.Pilot(
        cadence: .45,
        fireFrom: .6,
        window: .3,
        offTarget: .3,
        react: .55,
        tapGap: 17,
      ),
      Skill.casual => gargoyle.Pilot(
        cadence: .8,
        fireFrom: 1.0,
        window: .35,
        offTarget: .3,
        react: .8,
        tapGap: 24,
      ),
    };

    NyRun fly(Skill skill, int version, {double width = 2.2}) => flyNewYork(
      '3-4',
      skill: skill,
      width: width,
      version: version,
      seconds: 900,
      wardenOf: reacting,
    );

    test('a sharp and an average reacting pilot still beat him', () {
      for (final skill in [Skill.sharp, Skill.average]) {
        for (final width in [1.6, 2.4]) {
          final run = fly(skill, 46, width: width);
          expect(run.finished, isTrue, reason: '${skill.name} $width');
          expect(run.fight, greaterThan(90), reason: '${skill.name} $width');
        }
      }
    });

    test('the slowest reacting pilot is caught more than at rules 45', () {
      final before = fly(Skill.casual, 45);
      final after = fly(Skill.casual, 46);
      expect(
        after.fightHits.length,
        greaterThan(before.fightHits.length),
        reason: '${before.fightHits} / ${after.fightHits}',
      );
      // Only his beam and his feathers.
      expect(
        after.fightHits.map((hit) => hit.cause),
        everyElement(anyOf('beam', 'feather')),
      );
    });
  });
}
