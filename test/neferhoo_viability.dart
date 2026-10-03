import 'dart:math' as math;
import 'dart:typed_data';

import 'package:push_up_bird/domain/game_rules.dart';

/// Neferhoo's fairness proof (the design's `egypt-ws/reports/
/// 01-egypt-guardian/proof/fair.dart`, after King Coo's), reading the shipped
/// pure rules ([Neferhoo], [NeferhooLetter], [NeferhooAnkh]) instead of a
/// mirror of them.
///
/// A backward dynamic program over the bird's exact Tap & Fly physics (a tap
/// sets the climb to `flapImpulse`, gravity pulls at `gravity`, one step per
/// frame of 1/60 s) computes the set of (height, velocity, tap cooldown)
/// states from which SOME tap sequence avoids every hazard and both course
/// edges until the hazards end. Taps are at most one every [Viability.gap]
/// frames: 12 is the game's five taps a second, 40 (1.5 a second) a slow,
/// coarse player. A scenario is fair when every state that survives the
/// edges alone is viable at the lock. The reaction budget is how long a bird
/// may keep hovering where the lock found it before it must move.
final _tap = TapFlyMode();
final double gravity = _tap.gravity, flapImpulse = _tap.flapImpulse;
const birdX = FlightSimulation.birdX;
const dt = 1 / 60;

/// Whether a bird of radius `r` at height `y` is hurt at time `t` (seconds
/// from the lock).
typedef Hazard = bool Function(double t, double y, double r);

/// Every hazard is grown by this much: the grid's quantisation.
const eps = .006;

/// The hand a fight at [width] screen heights deals from.
double handOf(double width) =>
    Neferhoo.anchorX(birdX, width) - Neferhoo.handOffset;

/// A mail call locked at time 0 on [lane]: its letters, as the rules deal
/// them (three, or the express post's five; [tougher]: rules 52's pace).
List<NeferhooLetter> stream(
  double lane, {
  required bool fury,
  bool tougher = false,
}) => [
  for (var k = 0; k < Neferhoo.streamCount(fury: fury); k++)
    NeferhooLetter(
      cycle: 0,
      index: k,
      lane: lane,
      releaseAt: Neferhoo.windupSeconds + k * Neferhoo.gap(fury: fury),
      speed: Neferhoo.letterSpeedOf(fury: fury, tougher: tougher),
      express: fury,
    ),
];

/// A mummy bat as the search sees it: its lane, when it flies in (seconds
/// after the call's lock), from where (screen x) and how fast.
typedef BatRun = ({double lane, double launch, double start, double speed});

/// The mummy bats of a mail call locked at time 0 on [lane] in the tougher
/// fight on a sky [width] screen heights wide ([Neferhoo.batsFor]: a pair in
/// the full fight, fury's trio), as the rules latch them: in from the right
/// edge at their pace ([Neferhoo.batPace], [Neferhoo.furyBatPace]).
List<BatRun> batsOf(
  double lane, {
  required bool fury,
  required double width,
}) => [
  for (var k = 0; k < Neferhoo.batsFor(fury ? 2 : 1); k++)
    (
      lane: lane,
      launch: Neferhoo.batLaunch(k, fury: fury, width: width),
      start: Neferhoo.batStartX(width),
      speed: fury ? Neferhoo.furyBatPace : Neferhoo.batPace,
    ),
];

/// A mummy bat flying in: a circle of [SkyEnemy.radius] flying level along
/// its lane (it has settled out of its flight bob long before it reaches
/// the bird's column: `SkyEnemy.flightRoom` is 0 within .22 of it).
Hazard batHazard(BatRun bat) => (t, y, r) {
  if (t < bat.launch) return false;
  final dx = bat.start - bat.speed * (t - bat.launch) - birdX;
  final dy = y - bat.lane;
  final reach = SkyEnemy.radius + r;
  return dx * dx + dy * dy < reach * reach;
};

/// When the last of [bats] has left the bird's column (+.2 of slack).
double batsEnd(List<BatRun> bats) => bats
    .map((b) => b.launch + (b.start - birdX + .2) / b.speed)
    .reduce(math.max);

/// An ankh lock at time 0 on [birdY]: one ankh, or fury's mirrored two.
List<NeferhooAnkh> ankhs(double birdY, {required bool fury}) {
  final a = Neferhoo.ankhLaneFor(birdY), b = Neferhoo.backLane(a);
  const thrown = Neferhoo.ankhThrowAt - Neferhoo.ankhLockAt;
  final speed = fury ? Neferhoo.furyAnkhSpeed : Neferhoo.ankhSpeed;
  return [
    NeferhooAnkh(
      cycle: 0,
      laneA: a,
      laneB: b,
      lockedAt: 0,
      thrownAt: thrown,
      speed: speed,
    ),
    if (fury)
      NeferhooAnkh(
        cycle: 0,
        laneA: b,
        laneB: a,
        lockedAt: 0,
        thrownAt: thrown + Neferhoo.furyAnkhDelay,
        speed: speed,
        second: true,
      ),
  ];
}

Hazard letterHazard(NeferhooLetter letter, double handX) =>
    (t, y, r) =>
        letter.dealtBy(t) &&
        Neferhoo.letterTouches(letter.xAt(t, handX), letter.lane, birdX, y, r);

Hazard ankhHazard(NeferhooAnkh ankh, double handX) {
  final turnX = Neferhoo.turnX(birdX);
  return (t, y, r) {
    final at = ankh.at(t, handX: handX, turnX: turnX);
    return at != null && Neferhoo.ankhTouches(at, birdX, y, r);
  };
}

/// When the last of [letters] has left the bird's column (+.2 of slack).
double streamEnd(List<NeferhooLetter> letters, double handX) => letters
    .map((l) => l.releaseAt + (handX - birdX + .2) / l.speed)
    .reduce(math.max);

/// When the last of [flying] is home.
double ankhEnd(List<NeferhooAnkh> flying, double handX) => flying
    .map((a) => a.homeAt(handX: handX, turnX: Neferhoo.turnX(birdX)))
    .reduce(math.max);

/// What one scenario showed.
typedef Verdict = ({
  /// Share of the edge-survivable states near the lock height that are
  /// viable at the lock, and anywhere on the screen.
  double near,
  double anywhere,

  /// The reaction budget (s), or -1 when there is none.
  double budget,
});

/// The viability search on a grid of heights [yMin]..[yMax] (step [dy]) and
/// climbs [vMin]..[vMax] (step [dv]), a tap at most every [gap] frames, for a
/// bird of radius [radius].
class Viability {
  Viability({
    this.gap = 12,
    this.radius = FlightSimulation.birdRadius,
    this.dy = .004,
    this.dv = .01,
  }) : ny = ((yMax - yMin) / dy).round() + 1,
       nv = ((vMax - vMin) / dv).round() + 1 {
    _prep();
    kernel = solve(const [], 6.0, [0.0]).first;
  }
  static const yMin = .02, yMax = .98, vMin = -.60, vMax = 1.60;
  final int gap;
  final double radius, dy, dv;
  final int ny, nv;
  int get cdN => gap + 1;

  /// The states that survive the course edges alone (a 6 s horizon).
  late final Uint8List kernel;
  late final Int32List _noY, _noV, _tapY, _tapV;

  int idx(int iy, int iv, int c) => (iy * nv + iv) * cdN + c;

  void _prep() {
    _noY = Int32List(ny * nv);
    _noV = Int32List(ny * nv);
    _tapY = Int32List(ny * nv);
    _tapV = Int32List(ny * nv);
    for (var iy = 0; iy < ny; iy++) {
      for (var iv = 0; iv < nv; iv++) {
        final y = yMin + iy * dy, v = vMin + iv * dv;
        final v1 = v + gravity * dt;
        _noY[iy * nv + iv] = ((y + v1 * dt - yMin) / dy).round();
        _noV[iy * nv + iv] = ((v1 - vMin) / dv).round().clamp(0, nv - 1);
        final v2 = flapImpulse + gravity * dt;
        _tapY[iy * nv + iv] = ((y + v2 * dt - yMin) / dy).round();
        _tapV[iy * nv + iv] = ((v2 - vMin) / dv).round();
      }
    }
  }

  bool unsafe(List<Hazard> hazards, double t, double y) {
    if (y - radius <= .002 || y + radius >= .998) return true;
    for (final h in hazards) {
      if (h(t, y, radius + eps)) return true;
    }
    return false;
  }

  /// Backward viability from [t1] to 0: the viable sets at the [report]
  /// times.
  List<Uint8List> solve(List<Hazard> hazards, double t1, List<double> report) {
    final frames = (t1 / dt).round();
    final size = ny * nv * cdN;
    var next = Uint8List(size)..fillRange(0, size, 1);
    final out = <int, Uint8List>{};
    final want = {for (final r in report) (r / dt).round()};
    final last = cdN - 1;
    for (var f = frames - 1; f >= 0; f--) {
      final t = f * dt;
      final cur = Uint8List(size);
      for (var iy = 0; iy < ny; iy++) {
        if (unsafe(hazards, t, yMin + iy * dy)) continue;
        for (var iv = 0; iv < nv; iv++) {
          final k = iy * nv + iv;
          final ay = _noY[k], av = _noV[k];
          final by = _tapY[k], bv = _tapV[k];
          final noOk = ay >= 0 && ay < ny;
          final tapOk = by >= 0 && by < ny && bv >= 0 && bv < nv;
          final base = k * cdN;
          // Without a tap the cooldown counts on: cooldown c is viable when
          // the state a frame on, at c + 1, is (a block copy).
          if (noOk) {
            final noBase = (ay * nv + av) * cdN;
            cur.setRange(base, base + last, next, noBase + 1);
            cur[base + last] = next[noBase + last];
          }
          // Once the cooldown is over a tap may come instead.
          if (tapOk && cur[base + last] == 0) {
            cur[base + last] = next[(by * nv + bv) * cdN];
          }
        }
      }
      if (want.contains(f)) out[f] = cur;
      next = cur;
    }
    if (want.contains(frames)) {
      out[frames] = Uint8List(size)..fillRange(0, size, 1);
    }
    return [for (final r in report) out[(r / dt).round()]!];
  }

  /// Share of the edge-survivable states (climbs −.54 to 1.0) near [nearY]
  /// (within [band]), or anywhere, that are [viable].
  double audit(Uint8List viable, {double? nearY, double band = .03}) {
    var total = 0, ok = 0;
    for (var iy = 0; iy < ny; iy++) {
      final y = yMin + iy * dy;
      if (nearY != null && (y - nearY).abs() > band) continue;
      for (var iv = 0; iv < nv; iv++) {
        final v = vMin + iv * dv;
        if (v < -.54 || v > 1.0) continue;
        for (var c = 0; c < cdN; c++) {
          if (kernel[idx(iy, iv, c)] == 0) continue;
          total++;
          if (viable[idx(iy, iv, c)] == 1) ok++;
        }
      }
    }
    return total == 0 ? 1 : ok / total;
  }

  /// The reaction budget: the bird keeps hovering where it was at the lock
  /// (a tap whenever it sinks .03 below that height and the tap rate
  /// allows), ignoring the hazard, for D seconds; is the state it is then in
  /// still viable? The largest D (in .1 s steps) for which every start near
  /// [startY] (climbs −.3 to .3, any cooldown) still has a way out, or −1.
  double budget(
    List<Hazard> hazards,
    double t1,
    double startY, {
    double most = 3.0,
  }) => _budget(hazards, t1, startY, most: most).budget;

  ({List<Uint8List> sets, double budget}) _budget(
    List<Hazard> hazards,
    double t1,
    double startY, {
    double most = 3.0,
  }) {
    final times = [for (var i = 0; i <= (most * 10).round(); i++) i / 10];
    final sets = solve(hazards, t1, times);
    var best = -1.0;
    for (var i = 0; i < times.length; i++) {
      var allOk = true;
      for (final y0 in [startY - .02, startY, startY + .02]) {
        for (final v0 in const [-.3, -.15, 0.0, .15, .3]) {
          for (final c0 in [0, cdN ~/ 2, cdN - 1]) {
            final ky = ((y0 - yMin) / dy).round();
            final kv = ((v0 - vMin) / dv).round();
            if (kernel[idx(ky, kv, c0)] == 0) continue;
            var y = y0, v = v0, c = c0;
            var dead = false;
            for (var f = 0; f < (times[i] / dt).round(); f++) {
              if (c >= cdN - 1 && y > startY + .03) {
                v = flapImpulse + gravity * dt;
                c = 0;
              } else {
                v += gravity * dt;
                c = math.min(c + 1, cdN - 1);
              }
              y += v * dt;
              if (unsafe(hazards, (f + 1) * dt, y)) {
                dead = true;
                break;
              }
            }
            final jy = ((y - yMin) / dy).round();
            final jv = ((v - vMin) / dv).round();
            if (dead ||
                jy < 0 ||
                jy >= ny ||
                jv < 0 ||
                jv >= nv ||
                sets[i][idx(jy, jv, c)] == 0) {
              allOk = false;
            }
          }
        }
      }
      if (!allOk) break;
      best = times[i];
    }
    return (sets: sets, budget: best);
  }

  /// One scenario: the viable set at the lock, audited near [startY] and
  /// anywhere, and the reaction budget.
  Verdict judge(List<Hazard> hazards, double t1, double startY) {
    final (:sets, :budget) = _budget(hazards, t1, startY);
    final viable = sets.first;
    return (
      near: audit(viable, nearY: startY),
      anywhere: audit(viable),
      budget: budget,
    );
  }
}

/// One hazard scenario of his fight, locked at time 0 on [y].
class Scenario {
  const Scenario(this.stage, this.kind, this.y);

  /// The stage it belongs to (0 warm-up, 1 full, 2 fury) and what it is.
  final int stage;
  final ScenarioKind kind;
  final double y;

  bool get fury =>
      kind == ScenarioKind.express || kind == ScenarioKind.twoAnkhs;

  String get label => '${kind.name} ${y.toStringAsFixed(2)}';

  /// Its hazards, and when the last of them is over, at [width].
  (List<Hazard>, double) at(double width) {
    final hand = handOf(width);
    switch (kind) {
      case ScenarioKind.stream || ScenarioKind.express:
        final letters = stream(y, fury: fury);
        return (
          [for (final l in letters) letterHazard(l, hand)],
          streamEnd(letters, hand),
        );
      case ScenarioKind.ankh || ScenarioKind.twoAnkhs:
        final flying = ankhs(y, fury: fury);
        return (
          [for (final a in flying) ankhHazard(a, hand)],
          ankhEnd(flying, hand),
        );
    }
  }
}

enum ScenarioKind { stream, ankh, express, twoAnkhs }

/// The design's scenarios, by stage: the warm-up's mail call (and the full
/// fight's: the same stream), the full fight's ankh, fury's express post and
/// two ankhs. [few] keeps the lanes at the edges and the middle.
List<Scenario> scenarios({bool few = false}) => [
  for (final y in few ? [.16, .5, .84] : [.16, .3, .5, .7, .84])
    Scenario(0, ScenarioKind.stream, y),
  for (final y in few ? [.25, .5, .75] : [.25, .35, .5, .65, .75])
    Scenario(1, ScenarioKind.ankh, y),
  for (final y in few ? [.16, .84] : [.16, .5, .84])
    Scenario(2, ScenarioKind.express, y),
  for (final y in few ? [.25, .75] : [.25, .5, .75])
    Scenario(2, ScenarioKind.twoAnkhs, y),
];
