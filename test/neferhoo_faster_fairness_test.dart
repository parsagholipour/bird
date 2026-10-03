import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';

import 'neferhoo_viability.dart';

/// The faster Neferhoo (rules 55, [NeferhooBeats.faster]) is still fair: the
/// design's exhaustive viability search (`neferhoo_viability.dart`) over the
/// faster clock's hazards, dodging alone (no shot fired), at 640 and 792 px
/// (the app's 2.2 sky) for the game's five taps a second, and at 1.5 taps a
/// second for the record:
///
/// - each call with its bats, by stage: the warm-up's pair, the full fight's
///   trio, fury's four behind the express post;
/// - the warm-up cycle: the call and its pair, then the wave of two bats
///   locked 5.3 s later on any lane;
/// - the full fight's and fury's cycle: the call, its bats, the ankh locked
///   4.8 s after it, and the second call locked 9.0 s after it on any lane;
/// - the join: the second call, then the next cycle's first call 1.5 s later
///   on any lane with its bats, while the ankh's last pass may still be
///   coming: judged against the ankh alone, the two locks take no way out
///   away from a bird that has one.
///
/// At five taps a second every state the course edges alone let live has a
/// way through each of them. Returning letters is always open besides (the
/// catch band is the hurt band; one rock downs a bat).
///
/// `--dart-define=NEFERHOO_FAIR_ALL=true` judges more lanes and 864 px.
const _all = bool.fromEnvironment('NEFERHOO_FAIR_ALL');

const _beats = NeferhooBeats.faster;

/// The bats of a first call locked at time [at] on [lane] in [stage] (the
/// faster fight's counts), as the rules latch them.
List<BatRun> fasterBats(
  double lane, {
  required int stage,
  required double width,
  double at = 0,
}) => [
  for (var k = 0; k < Neferhoo.batsFor(stage, faster: true); k++)
    (
      lane: lane,
      launch: at + Neferhoo.batLaunch(k, fury: stage == 2, width: width),
      start: Neferhoo.batStartX(width),
      speed: stage == 2 ? Neferhoo.furyBatPace : Neferhoo.batPace,
    ),
];

/// The warm-up's wave locked at time [at] on [lane].
List<BatRun> waveBats(double lane, {required double width, double at = 0}) => [
  for (var k = 0; k < Neferhoo.waveBats; k++)
    (
      lane: lane,
      launch: at + Neferhoo.waveLaunch(k),
      start: Neferhoo.batStartX(width),
      speed: Neferhoo.batPace,
    ),
];

/// A call's letters locked at time [at] on [lane] (the tougher pace).
List<NeferhooLetter> letters(double lane, {required bool fury, double at = 0}) => [
  for (final l in stream(lane, fury: fury, tougher: true))
    NeferhooLetter(
      cycle: 0,
      index: l.index,
      lane: lane,
      releaseAt: at + l.releaseAt,
      speed: l.speed,
      express: fury,
    ),
];

/// The ankh (fury: two) locked at time [at] on [y].
List<NeferhooAnkh> ankhsAt(double y, {required bool fury, required double at}) => [
  for (final a in ankhs(y, fury: fury))
    NeferhooAnkh(
      cycle: 0,
      laneA: a.laneA,
      laneB: a.laneB,
      lockedAt: at,
      thrownAt: at + a.thrownAt,
      speed: a.speed,
      second: a.second,
    ),
];

/// Hazards and when the last is over, from its parts.
(List<Hazard>, double) hazardsOf(
  double width, {
  List<NeferhooLetter> mail = const [],
  List<BatRun> bats = const [],
  List<NeferhooAnkh> flying = const [],
}) {
  final hand = handOf(width);
  return (
    [
      for (final l in mail) letterHazard(l, hand),
      for (final b in bats) batHazard(b),
      for (final a in flying) ankhHazard(a, hand),
    ],
    [
      if (mail.isNotEmpty) streamEnd(mail, hand),
      if (bats.isNotEmpty) batsEnd(bats),
      if (flying.isNotEmpty) ankhEnd(flying, hand),
    ].reduce(math.max),
  );
}

/// The share of the states near [y] (within .03) that survive [before] and
/// the edges and still have a way through [all] (1 when the new locks take
/// no way out away).
double kept(Viability v, (List<Hazard>, double) before, (List<Hazard>, double) all, double y) {
  final end = math.max(before.$2, all.$2);
  final Uint8List a = v.solve(before.$1, end, [0.0]).first;
  final Uint8List b = v.solve(all.$1, end, [0.0]).first;
  var total = 0, ok = 0;
  for (var iy = 0; iy < v.ny; iy++) {
    final yy = Viability.yMin + iy * v.dy;
    if ((yy - y).abs() > .03) continue;
    for (var iv = 0; iv < v.nv; iv++) {
      final vv = Viability.vMin + iv * v.dv;
      if (vv < -.54 || vv > 1.0) continue;
      for (var c = 0; c < v.cdN; c++) {
        final k = v.idx(iy, iv, c);
        if (v.kernel[k] == 0 || a[k] == 0) continue;
        total++;
        if (b[k] == 1) ok++;
      }
    }
  }
  return total == 0 ? 1 : ok / total;
}

void _print(String label, Verdict v) {
  // ignore: avoid_print
  print(
    '${label.padRight(44)} near ${(v.near * 100).toStringAsFixed(2)}% '
    'anywhere ${(v.anywhere * 100).toStringAsFixed(2)}% '
    'budget ${v.budget.toStringAsFixed(1)} s',
  );
}

void main() {
  final widths = [640, 792, if (_all) 864];
  final lanes = _all ? [.16, .3, .5, .7, .84] : [.16, .5, .84];
  final second = _beats.secondMailAt! - _beats.mailLockAt;
  final wave = _beats.waveAt! - _beats.mailLockAt;
  final ankhLock = _beats.ankhLockAt - _beats.mailLockAt;
  final join = _beats.period + _beats.mailLockAt - _beats.secondMailAt!;

  test('the clock: the wave and the second call lock on the bird after the '
      'call\'s bats, and the next call after the second', () {
    expect(wave, closeTo(5.3, 1e-9));
    expect(ankhLock, closeTo(4.8, 1e-9));
    expect(second, closeTo(9.0, 1e-9));
    expect(join, closeTo(1.5, 1e-9));
  });

  for (final (taps, gap) in [(5, 12), (1.5, 40)]) {
    final v = Viability(gap: gap);
    final strict = gap == 12;
    for (final px in widths) {
      final width = px / 360;
      test('$px px, $taps taps a second: each call with its bats, by stage, '
          'and the warm-up cycle with its wave', () {
        for (final y in lanes) {
          for (final stage in [0, 1, 2]) {
            final fury = stage == 2;
            final s = hazardsOf(
              width,
              mail: letters(y, fury: fury),
              bats: fasterBats(y, stage: stage, width: width),
            );
            final verdict = v.judge(s.$1, s.$2, y);
            _print('$px ${taps}t stage $stage call+bats ${y.toStringAsFixed(2)}', verdict);
            if (strict) {
              expect(verdict.near, 1, reason: '$px $y stage $stage');
              expect(verdict.anywhere, 1, reason: '$px $y stage $stage');
              expect(verdict.budget, greaterThanOrEqualTo(1.0), reason: '$px $y stage $stage');
            }
          }
          for (final yW in strict ? lanes : [.5]) {
            final s = hazardsOf(
              width,
              mail: letters(y, fury: false),
              bats: [
                ...fasterBats(y, stage: 0, width: width),
                ...waveBats(yW, width: width, at: wave),
              ],
            );
            final verdict = v.judge(s.$1, s.$2, y);
            _print('$px ${taps}t warm-up cycle ${y.toStringAsFixed(2)} wave ${yW.toStringAsFixed(2)}', verdict);
            if (strict) {
              expect(verdict.near, 1, reason: '$px $y wave $yW');
              expect(verdict.anywhere, 1, reason: '$px $y wave $yW');
            }
          }
        }
      }, timeout: const Timeout(Duration(minutes: 20)));

      test('$px px, $taps taps a second: the full fight\'s and fury\'s cycle '
          '(the call, its bats, the ankh, the second call on any lane)', () {
        for (final fury in [false, true]) {
          for (final y in strict ? [.5] : [.5]) {
            for (final ankhY in [.25, .75]) {
              for (final y2 in strict ? lanes : [.5]) {
                final s = hazardsOf(
                  width,
                  mail: [
                    ...letters(y, fury: fury),
                    ...letters(y2, fury: fury, at: second),
                  ],
                  bats: fasterBats(y, stage: fury ? 2 : 1, width: width),
                  flying: ankhsAt(ankhY, fury: fury, at: ankhLock),
                );
                final verdict = v.judge(s.$1, s.$2, y);
                _print(
                  '$px ${taps}t ${fury ? 'fury' : 'full'} cycle ${y.toStringAsFixed(2)} '
                  'ankh ${ankhY.toStringAsFixed(2)} second ${y2.toStringAsFixed(2)}',
                  verdict,
                );
                if (strict) {
                  expect(verdict.near, 1, reason: '$px $fury $ankhY $y2');
                  expect(verdict.anywhere, 1, reason: '$px $fury $ankhY $y2');
                }
              }
            }
          }
        }
      }, timeout: const Timeout(Duration(minutes: 20)));

      test('$px px, $taps taps a second: the join (the second call, the next '
          'call 1.5 s later on any lane with its bats, the ankh\'s last pass)',
          () {
        var least = 1.0;
        for (final fury in [false, true]) {
          for (final ankhY in [.25, .75]) {
            for (final y3 in strict ? lanes : [.16, .5, .84]) {
              const y2 = .5;
              // (time 0: the second call's lock; the ankh locked 4.2 s before)
              final flying = ankhsAt(ankhY, fury: fury, at: -(second - ankhLock));
              final before = hazardsOf(width, flying: flying);
              final all = hazardsOf(
                width,
                mail: [
                  ...letters(y2, fury: fury),
                  ...letters(y3, fury: fury, at: join),
                ],
                bats: fasterBats(y3, stage: fury ? 2 : 1, width: width, at: join),
                flying: flying,
              );
              final share = kept(v, before, all, y2);
              least = math.min(least, share);
              // ignore: avoid_print
              print('$px ${taps}t ${fury ? 'fury' : 'full'} join ankh '
                  '${ankhY.toStringAsFixed(2)} next ${y3.toStringAsFixed(2)}: '
                  'kept ${(share * 100).toStringAsFixed(2)}%');
              if (strict) expect(share, 1, reason: '$px $fury $ankhY $y3');
            }
          }
        }
        if (!strict) {
          // ignore: avoid_print
          print('$px ${taps}t join: least kept ${(least * 100).toStringAsFixed(2)}%');
        }
      }, timeout: const Timeout(Duration(minutes: 20)));
    }
  }

  test('the bats come after their letters, are past the bird before an ankh '
      'can reach it, and no bat is still coming at any lane\'s lock, at '
      'every width', () {
    const reach = SkyEnemy.radius + FlightSimulation.birdRadius;
    const ankhReach = Neferhoo.ankhRadius + FlightSimulation.birdRadius;
    final turnX = Neferhoo.turnX(birdX);
    var toAnkh = double.infinity, toLock = double.infinity;
    for (var width = 1.6; width <= 2.4 + 1e-9; width += .05) {
      final hand = handOf(width);
      double gone(BatRun b) => b.launch + (b.start - birdX + reach) / b.speed;
      for (final stage in [0, 1, 2]) {
        final fury = stage == 2;
        final bats = fasterBats(.5, stage: stage, width: width);
        final last = bats.map(gone).reduce(math.max);
        // (seconds after the first call's lock)
        if (stage > 0) {
          final first = ankhs(.5, fury: fury).first;
          final pass = ankhLock + first.passes(handX: hand, turnX: turnX, column: birdX).$1 - ankhReach / first.speed;
          toAnkh = math.min(toAnkh, pass - last);
          expect(pass - last, greaterThan(1.5), reason: '$width $stage');
          // the second call locks after them
          toLock = math.min(toLock, second - last);
          expect(second, greaterThan(last), reason: '$width $stage');
        } else {
          // the wave locks after them, and its bats are past before the
          // next cycle's call locks
          expect(wave, greaterThan(last), reason: '$width');
          final w = waveBats(.5, width: width, at: wave).map(gone).reduce(math.max);
          toLock = math.min(toLock, _beats.period - w);
          expect(_beats.period, greaterThan(w), reason: '$width');
        }
        // never among their call's letters
        final mail = letters(.5, fury: fury);
        final release = mail.last.releaseAt;
        for (final b in bats) {
          expect(b.speed, lessThan(mail.last.speed));
          expect(
            b.start - b.speed * (release - b.launch),
            greaterThan(hand + Neferhoo.letterHalfWidth + SkyEnemy.radius),
            reason: '$width $stage',
          );
        }
      }
    }
    // ignore: avoid_print
    print('least time from the last bat to the first ankh: '
        '${toAnkh.toStringAsFixed(2)} s; from the last bat to the next lock: '
        '${toLock.toStringAsFixed(2)} s');
  });
}
