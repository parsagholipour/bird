import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';

import 'neferhoo_viability.dart';

/// The tougher Neferhoo (rules 52) is still fair: the design's exhaustive
/// viability search (`neferhoo_viability.dart`) over his tougher hazards,
/// at 640, 792 (main's 2.2 sky) and 864 px, for the game's five taps a
/// second and a slow 1.5. Dodging alone (no shot fired), from the lock:
///
/// - the warm-up's mail call at [Neferhoo.tougherPace] (no bats);
/// - the full fight's mail call with its pair of mummy bats in from the
///   right edge down the lane behind the letters, and fury's express post
///   with its faster trio;
/// - the whole cycle: that call, its bats, then the ankh (fury: two) locked
///   4.8 s after it on another lane, until the last ankh is home.
///
/// At five taps a second every state the course edges alone let live has a
/// way through every scenario, with a reaction budget no smaller than the
/// stream alone gives (the bats never take any of it). For the slow tapper
/// the bats change nothing either (the same verdict with and without them);
/// what the faster letters cost him is pinned as floors below. Returning the
/// letters is always open besides: the catch band is the hurt band, and a
/// shot every .32 s or more (the cooldown is .28) sends back every letter of
/// a call and downs every bat (one rock each).
///
/// `--dart-define=NEFERHOO_FAIR_ALL=true` judges every lane and ankh lane
/// (the handoff's tables); the default keeps the suite quick.
const _all = bool.fromEnvironment('NEFERHOO_FAIR_ALL');

/// The full fight's call (fury's express post) locked at 0 on [y], and its
/// bats.
(List<Hazard>, double) mailWithBats(
  double width,
  double y, {
  required bool fury,
  bool bats = true,
}) {
  final hand = handOf(width);
  final letters = stream(y, fury: fury, tougher: true);
  final flying = bats ? batsOf(y, fury: fury, width: width) : <BatRun>[];
  return (
    [
      for (final l in letters) letterHazard(l, hand),
      for (final b in flying) batHazard(b),
    ],
    flying.isEmpty
        ? streamEnd(letters, hand)
        : math.max(streamEnd(letters, hand), batsEnd(flying)),
  );
}

/// The whole cycle: the call on [y] with its bats, then the ankh (fury: two)
/// locked on [ankhY] at the ankh's lock, until the last is home.
(List<Hazard>, double) wholeCycle(
  double width,
  double y,
  double ankhY, {
  required bool fury,
}) {
  final hand = handOf(width);
  final (mail, mailEnd) = mailWithBats(width, y, fury: fury);
  const lock = Neferhoo.ankhLockAt - Neferhoo.mailLockAt;
  final flying = [
    for (final a in ankhs(ankhY, fury: fury))
      NeferhooAnkh(
        cycle: 0,
        laneA: a.laneA,
        laneB: a.laneB,
        lockedAt: lock,
        thrownAt: lock + a.thrownAt,
        speed: a.speed,
        second: a.second,
      ),
  ];
  return (
    [...mail, for (final a in flying) ankhHazard(a, hand)],
    math.max(mailEnd, ankhEnd(flying, hand)),
  );
}

/// The stream alone's reaction budgets at five taps a second, the floors
/// here: 640 px 1.8 s (1.0 at the ceiling lane), the express post 1.5 (1.0);
/// 792: 2.3 (1.7), 2.1 (1.4); 864: 2.8 (1.9), 2.4 (1.9). (Rules 50 gave
/// 2.0 (1.3) and 1.9 (1.1) at 640: the faster letters take a fifth.)
double budgetFloor(int px, double y, {required bool fury}) {
  final ceiling = y <= .16;
  return switch ((px, fury)) {
    (640, false) => ceiling ? 1.0 : 1.8,
    (640, true) => ceiling ? 1.0 : 1.5,
    (792, false) => ceiling ? 1.7 : 2.3,
    (792, true) => ceiling ? 1.4 : 2.1,
    (864, false) => ceiling ? 1.9 : 2.8,
    _ => ceiling ? 1.9 : 2.4,
  };
}

const _widths = [640, 792, 864];

void main() {
  final fast = Viability();
  final lanes = _all ? [.16, .3, .5, .7, .78, .84] : [.16, .5, .84];

  for (final px in _widths) {
    test('$px px, five taps a second: the faster mail call, with its bats '
        'in the full fight and in fury, has a way through from every state, '
        'and the bats take none of the reaction budget', () {
      final width = px / 360;
      for (final y in lanes) {
        final warm = stream(y, fury: false, tougher: true);
        final hand = handOf(width);
        final calm = fast.judge(
          [for (final l in warm) letterHazard(l, hand)],
          streamEnd(warm, hand),
          y,
        );
        _print('$px warm-up stream ${y.toStringAsFixed(2)}', calm);
        expect(calm.near, 1);
        expect(calm.anywhere, 1);
        expect(
          calm.budget,
          greaterThanOrEqualTo(budgetFloor(px, y, fury: false) - 1e-9),
        );
        for (final fury in [false, true]) {
          final (hazards, end) = mailWithBats(width, y, fury: fury);
          final verdict = fast.judge(hazards, end, y);
          _print(
            '$px ${fury ? 'express+trio' : 'stream+pair '} '
            '${y.toStringAsFixed(2)}',
            verdict,
          );
          expect(verdict.near, 1, reason: '$px $y $fury');
          expect(verdict.anywhere, 1, reason: '$px $y $fury');
          expect(
            verdict.budget,
            greaterThanOrEqualTo(budgetFloor(px, y, fury: fury) - 1e-9),
            reason: '$px $y $fury',
          );
        }
      }
    }, timeout: const Timeout(Duration(minutes: 10)));
  }

  test('the whole cycle, five taps a second: the call, its bats and the '
      'ankh after them (two in fury) leave a way through from every state', () {
    final ankhLanes = _all ? [.25, .5, .75] : [.25, .75];
    final mailLanes = _all ? lanes : [.5];
    for (final px in _all ? _widths : [640, 864]) {
      for (final fury in [false, true]) {
        for (final y in mailLanes) {
          for (final ankhY in ankhLanes) {
            final (hazards, end) = wholeCycle(
              px / 360,
              y,
              ankhY,
              fury: fury,
            );
            final verdict = fast.judge(hazards, end, y);
            _print(
              '$px cycle ${fury ? 'fury' : 'full'} mail '
              '${y.toStringAsFixed(2)} ankh ${ankhY.toStringAsFixed(2)}',
              verdict,
            );
            expect(verdict.near, 1, reason: '$px $y $ankhY $fury');
            expect(verdict.anywhere, 1, reason: '$px $y $ankhY $fury');
          }
        }
      }
    }
  }, timeout: const Timeout(Duration(minutes: 10)));

  test('the bats come after their letters and have left the bird\'s reach '
      'long before an ankh can reach it, at every width', () {
    const reach = SkyEnemy.radius + FlightSimulation.birdRadius;
    const ankhReach = Neferhoo.ankhRadius + FlightSimulation.birdRadius;
    final turnX = Neferhoo.turnX(birdX);
    var least = double.infinity, after = double.infinity;
    var seen = double.infinity;
    for (var width = 1.6; width <= 2.4 + 1e-9; width += .05) {
      final hand = handOf(width);
      for (final fury in [false, true]) {
        {
          final bats = batsOf(.5, fury: fury, width: width);
          // (cycle seconds: the call locks at .6)
          final gone = bats
              .map(
                (b) =>
                    Neferhoo.mailLockAt +
                    b.launch +
                    (b.start - birdX + reach) / b.speed,
              )
              .reduce(math.max);
          final first = ankhs(.5, fury: fury).first;
          final pass =
              Neferhoo.ankhLockAt +
              first.passes(handX: hand, turnX: turnX, column: birdX).$1 -
              ankhReach / first.speed;
          least = math.min(least, pass - gone);
          expect(pass - gone, greaterThan(1.8), reason: '$width $fury');
          // And they never fly among the letters of their call: slower, and
          // still right of his hand as the last letter leaves it.
          final letters = stream(.5, fury: fury, tougher: true);
          final last = letters.last.releaseAt;
          for (final b in bats) {
            expect(b.speed, lessThan(letters.last.speed));
            expect(
              b.start - b.speed * (last - b.launch),
              greaterThan(hand + Neferhoo.letterHalfWidth + SkyEnemy.radius),
              reason: '$width $fury',
            );
            // Seen long before they reach the bird.
            seen = math.min(seen, (b.start - birdX) / b.speed);
          }
          // The first reaches the bird's reach after the last letter left it.
          final lettersGone =
              last + (hand - birdX + Neferhoo.letterHalfWidth + .038) /
                  letters.last.speed;
          final lead = bats.first;
          final arrives =
              lead.launch + (lead.start - birdX - reach) / lead.speed;
          after = math.min(after, arrives - lettersGone);
          expect(arrives - lettersGone, greaterThan(0), reason: '$width');
        }
      }
    }
    expect(seen, greaterThan(1.8));
    // ignore: avoid_print
    print('least time from the last bat to the first ankh: '
        '${least.toStringAsFixed(2)} s; from the last letter to the first '
        'bat: ${after.toStringAsFixed(2)} s; a bat is seen for at least '
        '${seen.toStringAsFixed(2)} s');
  });

  final slow = Viability(gap: 40);
  for (final px in _widths) {
    test('$px px, 1.5 taps a second: the bats change nothing for a slow '
        'tapper, and the faster letters leave a way through from nearly '
        'every state', () {
      final width = px / 360;
      for (final y in _all ? lanes : [.16, .5, .78, .84]) {
        for (final fury in [false, true]) {
          final (withBats, end) = mailWithBats(width, y, fury: fury);
          final (letters, lettersEnd) = mailWithBats(
            width,
            y,
            fury: fury,
            bats: false,
          );
          final verdict = slow.judge(withBats, end, y);
          final alone = slow.judge(letters, lettersEnd, y);
          _print(
            '$px coarse ${fury ? 'express+trio' : 'stream+pair '} '
            '${y.toStringAsFixed(2)}',
            verdict,
          );
          expect(verdict.near, alone.near, reason: 'the bats: $px $y $fury');
          expect(verdict.anywhere, alone.anywhere);
          expect(
            verdict.near,
            greaterThanOrEqualTo(_slowFloor(px, y, fury: fury)),
            reason: '$px $y $fury',
          );
        }
      }
    }, timeout: const Timeout(Duration(minutes: 10)));
  }
}

/// The slow tapper's floors, from the lock near its lane (the search's
/// `near`): every lane is fully viable at 792 and 864, and at 640 the upper
/// half; a lane in the lower third at 640 leaves 93% (fury) to 96% of the
/// starts a way out by flying alone (rules 50 gave 99.8% to 100%): the few
/// lost are birds falling fast just after a tap, which cannot climb clear of
/// the band before the faster stream arrives. They can still send it back.
double _slowFloor(int px, double y, {required bool fury}) {
  if (px != 640 || y < .7) return 1;
  return fury ? .93 : .96;
}

void _print(String label, Verdict v) {
  // ignore: avoid_print
  print(
    '${label.padRight(40)} near ${(v.near * 100).toStringAsFixed(2)}% '
    'anywhere ${(v.anywhere * 100).toStringAsFixed(2)}% '
    'budget ${v.budget.toStringAsFixed(1)} s',
  );
}
