@Timeout(Duration(minutes: 20))
library;

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/gargoyle_feather_art.dart';
import 'package:push_up_bird/game/gargoyle_layout.dart';

import 'campaign_flight.dart';
import 'gargoyle_pilot.dart' as gargoyle;
import 'gargoyle_viability.dart';

/// Rules version 49: the Searchlight Gargoyle's level feathers. Asked after a
/// playtest of 3-4: "The gargoyl boss shots cover more when they shoot at the
/// bottom half of the screen and it is unfair. If the bird is on top, it's
/// easier to dodge. we should reduce the covering point in the bottom half",
/// confirmed as his stone feathers (not his beam).
///
/// A feather leaves the top edge .62 ahead of the bird and crosses its column
/// where the bird was. Aimed at a low bird it fell nearly twice as steep as at
/// a high one, so it lit a taller band at the column, and a bird pinned
/// against the bottom edge had to climb into it, starting earlier. From 49 no
/// feather crosses steeper than [SearchlightGargoyle.maxFeatherSlope] (a
/// calm feather's slope at height .3): one that would leaves further ahead
/// and flies faster, in the same flight time. Everything else flies as at 48.

const _r = FlightSimulation.birdRadius, _fr = SearchlightGargoyle.featherRadius;
const _g = SearchlightGargoyle.featherGravity;

typedef _Shot = ({double vx, double vy, double flight, double ahead});

_Shot _shot(double y, {required bool fury, bool level = true}) =>
    SearchlightGargoyle.featherShot(y, enraged: fury, level: level);

/// Drop over run as the feather crosses the bird's column.
double _slope(_Shot s) => (s.vy + _g * s.flight) / -s.vx;

/// Half the band of heights a still bird is touched in at the column.
double _band(_Shot s) => (_r + _fr) * math.sqrt(1 + _slope(s) * _slope(s));

/// The latest a Tap & Fly bird holding still at [y] (v 0) can start dodging
/// feather [s] aimed at it, as seconds before the feather reaches its column:
/// a search over every tap plan of at most five taps a second, the sky's
/// edges hurting.
double _lead(double y, _Shot s) {
  final tap = TapFlyMode();
  final gravity = tap.gravity, flap = tap.flapImpulse;
  const dt = 1 / 60, gap = 12, margin = .002, wall = .005;
  final end = ((s.flight + .6) / dt).round();
  bool hit(int step, double by) {
    if (by - _r <= wall || by + _r >= 1 - wall) return true;
    final t = step * dt;
    final px = s.ahead + s.vx * t;
    final py = SearchlightGargoyle.featherY + s.vy * t + _g / 2 * t * t;
    return math.sqrt(px * px + (py - by) * (py - by)) < _r + _fr + margin;
  }

  bool viable(int start) {
    final dead = <(int, int, int, int)>{};
    bool go(int step, double by, double bv, int since) {
      if (hit(step, by)) return false;
      if (step >= end) return true;
      final key = (step, (by / .002).round(), (bv / .01).round(), since);
      if (dead.contains(key)) return false;
      for (final flapNow in [false, true]) {
        if (flapNow && since < gap) continue;
        final v = (flapNow ? flap : bv) + gravity * dt;
        if (go(
          step + 1,
          by + v * dt,
          v,
          flapNow ? 1 : math.min(since + 1, gap),
        )) {
          return true;
        }
      }
      dead.add(key);
      return false;
    }

    for (var k = 0; k < start; k++) {
      if (hit(k, y)) return false;
    }
    return go(start, y, 0, gap);
  }

  var lo = 0, hi = (s.flight / dt).round();
  expect(viable(0), isTrue, reason: 'a dodge from the launch at $y');
  while (lo < hi) {
    final mid = (lo + hi + 1) ~/ 2;
    if (viable(mid)) {
      lo = mid;
    } else {
      hi = mid - 1;
    }
  }
  return s.flight - lo * dt;
}

CampaignLevel get _level => Campaign.level('3-4')!;

FlightSimulation _flight(int version) => FlightSimulation(
  rules: TapFlyMode(rulesVersion: version),
  practice: false,
  course: FlightCourse.starTrail,
  rulesVersion: version,
  plan: _level.plan,
);

/// Every feather the Gargoyle launches in 3-4 at [version], flown by the
/// shared bot into his fight and through [seconds] of it (knocked out of his
/// warm-up after 12 s): its ahead of the lead bird, its flight time and its
/// slope at the column, worked out from its launch.
List<({double ahead, double flight, double slope, double speed})> _launches(
  int version, {
  double seconds = 45,
}) {
  final sim = _flight(version);
  flyLevel(
    sim,
    viewportWidth: 2.2,
    until: (sim) => sim.boss?.phase == BossPhase.attacking,
  );
  final boss = sim.boss!;
  final seen = <BossAmmo>{};
  final out = <({double ahead, double flight, double slope, double speed})>[];
  flyLevel(
    sim,
    seconds: seconds,
    shootWhen: (_) => false,
    viewportWidth: 2.2,
    watch: (sim) {
      if (boss.combatTime >= 12 &&
          boss.stage == 0 &&
          boss.gargoyleCycle >= SearchlightGargoyle.ventAt) {
        boss.takeDamage(boss.hp - boss.maxHp * 2 ~/ 3);
      }
      for (final a in sim.bossAmmo.where((a) => a.feather)) {
        if (!seen.add(a)) continue;
        final from = a.launchX!;
        final speed = -a.vx;
        final age = (from - a.x) / speed;
        final flight = (from - sim.lead.x) / speed;
        final vy0 = a.vy - a.gravity * age;
        out.add((
          ahead: from - sim.lead.x,
          flight: flight,
          slope: (vy0 + a.gravity * flight) / speed,
          speed: speed,
        ));
      }
    },
  );
  return out;
}

/// The search through a cycle with level feathers: to the vent's end for the
/// cycles that drop feathers in it.
Search _search(
  Sweep sweep,
  List<double>? schedule, {
  double margin = .002,
  bool withPerch = false,
}) => Search(
  sweep,
  schedule: schedule,
  endAt: schedule == null ? null : gargoyle.Pilot.fierceEnd,
  margin: margin,
  withPerch: withPerch,
  level: true,
);

/// His four cycles at 49 (a campaign Gargoyle is fierce): the warm-up's calm
/// sweep and feathers, then the three he adds once he grows stronger.
final _cycles = <String, (Sweep, List<double>?)>{
  'warm-up': (Sweep.calm, null),
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

void main() {
  group('the rules', () {
    test('rules 49 levels the campaign Gargoyle\'s feathers; 48 and endless '
        'flights do not', () {
      // 50 (Egypt's guardian, Neferhoo), 51 (the all-rings bonus), 52 (a
      // tougher Neferhoo), 53 (growing endless bosses), 54 (King Coo's
      // quick fury) and 55 (a faster Neferhoo) came after it.
      expect(FlightSimulation.currentRulesVersion, greaterThanOrEqualTo(55));
      expect(FlightSimulation.levelFeathersRulesVersion, 49);
      expect(SearchlightGargoyle.maxFeatherSlope, 1.3);
      expect(_flight(48).supportsLevelFeathers, isFalse);
      expect(_flight(49).supportsLevelFeathers, isTrue);
      final endless = FlightSimulation(
        rules: TapFlyMode(),
        practice: false,
        course: FlightCourse.starTrail,
      );
      expect(endless.supportsLevelFeathers, isFalse);
      for (final (version, level) in [(48, false), (49, true)]) {
        final sim = _flight(version);
        flyLevel(sim, viewportWidth: 2.2, until: (sim) => sim.boss != null);
        expect(sim.boss!.isGargoyle, isTrue);
        expect(sim.boss!.levelFeathers, level, reason: '$version');
      }
    });

    test('a level feather crosses where it was aimed, in the same time, '
        'never steeper than 1.3; the high sky\'s are unchanged', () {
      for (final fury in [false, true]) {
        for (var i = 0; i <= 20; i++) {
          final y = i / 20;
          final plain = _shot(y, fury: fury, level: false);
          final level = _shot(y, fury: fury);
          final why = 'y $y fury $fury';
          expect(plain.ahead, SearchlightGargoyle.featherOffsetX);
          expect(level.flight, plain.flight, reason: why);
          expect(level.vy, plain.vy, reason: why);
          // It reaches the bird's column at the flight's end, at height y.
          final t = level.flight;
          expect(level.ahead + level.vx * t, closeTo(0, 1e-12), reason: why);
          expect(
            SearchlightGargoyle.featherY + level.vy * t + _g / 2 * t * t,
            closeTo(y, 1e-12),
            reason: why,
          );
          expect(
            _slope(level),
            lessThanOrEqualTo(SearchlightGargoyle.maxFeatherSlope + 1e-12),
            reason: why,
          );
          if (_slope(plain) <= SearchlightGargoyle.maxFeatherSlope) {
            expect(level, plain, reason: why);
          } else {
            expect(
              _slope(level),
              closeTo(SearchlightGargoyle.maxFeatherSlope, 1e-12),
              reason: why,
            );
            expect(level.ahead, greaterThan(plain.ahead), reason: why);
          }
        }
      }
      // Calm feathers are levelled from just below .3, fury's from .45.
      expect(_shot(.3, fury: false).ahead, SearchlightGargoyle.featherOffsetX);
      expect(_shot(.31, fury: false).ahead, greaterThan(.62));
      expect(_shot(.44, fury: true).ahead, SearchlightGargoyle.featherOffsetX);
      expect(_shot(.46, fury: true).ahead, greaterThan(.62));
    });

    test('the bottom half lights no taller a band than height .3 does', () {
      // 1.3 is .3's slope, rounded up a hair.
      final top = _band(_shot(.3, fury: false, level: false));
      expect(top, closeTo(.108, .001));
      for (final fury in [false, true]) {
        // Before: from .1 to .9 the band nearly doubled.
        final low = _band(_shot(.9, fury: fury, level: false));
        final high = _band(_shot(.1, fury: fury, level: false));
        expect(low / high, greaterThan(1.75), reason: 'fury $fury');
        for (var y = .5; y <= 1 - _r; y += .01) {
          expect(
            _band(_shot(y, fury: fury)),
            lessThanOrEqualTo(top + .0002),
            reason: 'y $y fury $fury',
          );
        }
      }
    });

    test('a level feather still falls from in front of him, on the screen, '
        'about as fast as other bosses\' shots at most', () {
      final perch = SearchlightGargoyle.anchorX(GargoyleLayout.birdColumn, 2.2);
      for (final fury in [false, true]) {
        for (final y in [
          for (var i = 0; i <= 20; i++) _r + (1 - 2 * _r) * i / 20,
        ]) {
          final s = _shot(y, fury: fury);
          expect(GargoyleLayout.birdColumn + s.ahead, lessThan(perch - .05));
          // The Dusk Empress's fury shot flies .72 a second; a fury feather
          // at the very bottom .7205.
          expect(-s.vx, lessThan(.721), reason: 'y $y fury $fury');
        }
      }
    });
  });

  group('in his fight', () {
    test('at 49 every feather crosses no steeper than 1.3, in its pace\'s '
        'time; low ones leave further ahead', () {
      final launches = _launches(49);
      expect(launches.length, greaterThanOrEqualTo(6));
      final calm =
          SearchlightGargoyle.featherOffsetX / SearchlightGargoyle.featherSpeed;
      final fury =
          SearchlightGargoyle.featherOffsetX /
          SearchlightGargoyle.furyFeatherSpeed;
      for (final l in launches) {
        expect(
          [calm, fury].any((f) => (l.flight - f).abs() < 1e-6),
          isTrue,
          reason: '$l',
        );
        expect(
          l.slope,
          lessThanOrEqualTo(SearchlightGargoyle.maxFeatherSlope + 1e-6),
          reason: '$l',
        );
        expect(l.ahead, greaterThanOrEqualTo(.62 - 1e-9), reason: '$l');
      }
      expect(launches.where((l) => l.ahead > .65), isNotEmpty);
    });

    test('at 48 every feather still leaves .62 ahead at its pace\'s speed', () {
      final launches = _launches(48, seconds: 30);
      expect(launches.length, greaterThanOrEqualTo(4));
      for (final l in launches) {
        expect(l.ahead, closeTo(SearchlightGargoyle.featherOffsetX, 1e-9));
        expect(
          [
            SearchlightGargoyle.featherSpeed,
            SearchlightGargoyle.furyFeatherSpeed,
          ].any((v) => (l.speed - v).abs() < 1e-9),
          isTrue,
          reason: '$l',
        );
      }
    });
  });

  group('as fair low as high', () {
    test('a bird near the bottom can start its dodge as late as one near the '
        'top (it had to start about .2 s earlier)', () {
      for (final fury in [false, true]) {
        double worst(Iterable<double> ys, {required bool level}) => ys
            .map((y) => _lead(y, _shot(y, fury: fury, level: level)))
            .reduce(math.max);
        const high = [.1, .2, .3, .4], low = [.6, .7, .8, .9];
        final top = worst(high, level: false);
        // Before: the bottom of the sky needed the dodge well before.
        expect(
          worst(low, level: false),
          greaterThan(top + .08),
          reason: 'fury $fury',
        );
        // Now: no later than the top's, within a frame and a half.
        expect(
          worst(high, level: true),
          lessThanOrEqualTo(top + 1e-9),
          reason: 'fury $fury',
        );
        expect(
          worst(low, level: true),
          lessThanOrEqualTo(top + 1.5 / 60),
          reason: 'fury $fury',
        );
      }
    });
  });

  group('fair: a safe path through every cycle with level feathers', () {
    for (final MapEntry(key: name, value: (sweep, schedule))
        in _cycles.entries) {
      test('$name: from all 117 starts at the warning', () {
        expect(survivableStarts(), hasLength(117));
        final bad = [
          for (final start in survivableStarts())
            if (_search(sweep, schedule).from(start) case final result?
                when !result.safe)
              start,
        ];
        expect(bad, isEmpty);
      });

      test('$name: after .3 s and .45 s without a tap, and with a wider '
          'margin (.012)', () {
        for (final (idle, margin) in [(.3, .002), (.45, .002), (0.0, .012)]) {
          final bad = [
            for (final start in survivableStarts())
              if (_search(
                    sweep,
                    schedule,
                    margin: margin,
                  ).from(start, idle: idle)
                  case final result? when !result.safe)
                start,
          ];
          expect(bad, isEmpty, reason: 'idle $idle margin $margin');
        }
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

  group('the art follows', () {
    test('a level feather\'s age is counted from where it left, and its dust '
        'falls where it first shows', () {
      for (final fury in [false, true]) {
        for (final birdY in const [.1, .5, .7, .9]) {
          final s = _shot(birdY, fury: fury);
          final from = GargoyleLayout.birdColumn + s.ahead;
          final a = BossAmmo(
            x: from,
            y: SearchlightGargoyle.featherY,
            vx: s.vx,
            vy: s.vy,
            gravity: _g,
            radius: _fr,
            feather: true,
            launchX: from,
          );
          var t = 0.0, entry = double.nan;
          const dt = 1 / 240;
          while (t < 1.6) {
            a.x += a.vx * dt;
            a.vy += a.gravity * dt;
            a.y += a.vy * dt;
            t += dt;
            if (entry.isNaN && a.y + a.radius >= 0) entry = a.x;
          }
          final why = 'y $birdY fury $fury';
          expect(GargoyleFeatherArt.age(a), closeTo(t, 1e-6), reason: why);
          expect(
            GargoyleFeatherArt.entryX(birdY, fury: fury, level: true),
            closeTo(entry, .004),
            reason: why,
          );
        }
      }
      // A feather the rules gave no launch keeps the old reckoning.
      final old = _shot(.5, fury: false, level: false);
      final a = BossAmmo(
        x: GargoyleLayout.birdColumn + old.ahead + old.vx,
        y: .2,
        vx: old.vx,
        vy: old.vy,
        gravity: _g,
        radius: _fr,
        feather: true,
      );
      expect(GargoyleFeatherArt.age(a), closeTo(1, 1e-9));
    });
  });
}
