import 'dart:math' as math;
import 'dart:typed_data';

import 'package:push_up_bird/domain/game_rules.dart';

/// The fairness proof of King Coo's hazards (R2): a port of the report's
/// exhaustive tap-sequence search (`reports/05-king-coo/proof/fair.dart`).
///
/// A backward dynamic program over the bird's exact Tap & Fly physics
/// (gravity 1.1, a tap sets the velocity to -0.54, at most 5 taps a second,
/// 60 Hz) marks every state from which SOME tap sequence avoids every hazard
/// and both course edges until the hazards are over. A scenario is fair when
/// every state that survives the course edges alone is viable.
///
/// Differences from the report's script, none of them weakening it:
///  * the velocity is tracked exactly. After a tap the velocity is fixed by
///    the frames since it (a "cooling" state, `c` = 1..11, cannot tap); once
///    ready (`c` >= 12) the velocity is one of a lattice aligned with
///    gravity's step, so no velocity is ever rounded (the script rounded it
///    to 0.01, which made gravity 1.2 instead of 1.1). Only the height is
///    rounded, to 0.004, under the script's 0.008 margin on every hazard.
///  * a tap is possible every 12 frames (exactly 5 a second), the script's
///    13 frames was slightly kinder to the hazards.
///  * the hazards are the game's own: [CrumbLob], [SquadTrack] and
///    [KingCoo.squad] supply the geometry, not a copy of the numbers.

const dtFrame = 1 / 60.0;
const gravity = 1.1, flapVelocity = -.54;
const gdt = gravity * dtFrame;
const birdColumn = FlightSimulation.birdX;
const yMin = .02, yMax = .98, dy = .004;

/// Hazard margin the script used for its quantisation (two height cells).
const eps = .008;

/// Frames a tap needs to cool: 12 is 5 taps a second (the proof's tempo).
/// [useTapRate] changes it, for the casual pilot's proof (2.5 taps a second
/// is 24); a test that does must put it back (`useTapRate(5)`).
int coolFrames = 12;

/// Velocity lattice for ready states: index [kTap] is the velocity just
/// after a tap (flap + one step of gravity), and each index is one step of
/// gravity more. Index [kReady] is the velocity when a tap has just cooled.
const kTap = 5;
int get kReady => kTap + coolFrames - 1;
const velocityMin = flapVelocity + gdt * (1 - kTap);
const nk = 112; // up to about 1.42 h/s; faster birds are off the screen
int get nc => coolFrames - 1; // cooling states c = 1 .. coolFrames - 1
final ny = ((yMax - yMin) / dy).round() + 1;

double velocityAt(int k) => velocityMin + k * gdt;
double heightAt(int iy) => yMin + iy * dy;

/// A circular hazard at time `t` (seconds from the scenario's origin): its
/// centre column, height and radius, or null when it is not there.
typedef Hazard = ({double x, double y, double r})? Function(double t);

/// The height row nearest [y], or -1 outside the screen rows.
int rowOf(double y) {
  final i = ((y - yMin) / dy).round();
  return i < 0 || i >= ny ? -1 : i;
}

/// Precomputed one-frame transitions of the bird's physics.
class _Moves {
  _Moves() {
    for (var iy = 0; iy < ny; iy++) {
      final y = heightAt(iy);
      tapY[iy] = rowOf(y + (flapVelocity + gdt) * dtFrame);
      for (var k = 0; k < nk; k++) {
        freeY[iy * nk + k] = rowOf(y + (velocityAt(k) + gdt) * dtFrame);
      }
      for (var c = 1; c <= nc; c++) {
        final v = flapVelocity + gdt * c;
        coolY[iy * nc + (c - 1)] = rowOf(y + (v + gdt) * dtFrame);
      }
    }
  }

  final Int32List tapY = Int32List(ny);
  final Int32List freeY = Int32List(ny * nk);
  final Int32List coolY = Int32List(ny * nc);
}

_Moves _moves = _Moves();

/// Proves for a bird that taps at most [tapsPerSecond] times a second.
void useTapRate(double tapsPerSecond) {
  coolFrames = (60 / tapsPerSecond).round();
  _moves = _Moves();
}

/// The viable states of one scenario at every frame from 0 to [frames].
class Viability {
  Viability._(this.frames, this.ready, this.cooling);

  final int frames;

  /// Per frame: ready states (height row, velocity index) and cooling states
  /// (height row, frames since the tap 1..11), 1 when viable.
  final List<Uint8List> ready, cooling;

  bool isReady(int frame, int iy, int k) => ready[frame][iy * nk + k] == 1;
  bool isCooling(int frame, int iy, int c) =>
      cooling[frame][iy * nc + (c - 1)] == 1;
}

/// Solves [hazards] for [seconds] from the scenario's origin, for a bird of
/// radius [rb] (the game's .038, or inflated for a comfort margin).
Viability solve(List<Hazard> hazards, double seconds, {double rb = .038}) {
  final frames = (seconds / dtFrame).round();
  final ready = List<Uint8List>.filled(frames + 1, Uint8List(0));
  final cooling = List<Uint8List>.filled(frames + 1, Uint8List(0));
  var nextA = Uint8List(ny * nk), nextB = Uint8List(ny * nc);
  for (var f = frames; f >= 0; f--) {
    final t = f * dtFrame;
    // Each hazard once per frame, not once per height row.
    final present = <({double x, double y, double r})>[
      for (final hazard in hazards) ?hazard(t),
    ];
    final safe = Uint8List(ny);
    for (var iy = 0; iy < ny; iy++) {
      safe[iy] = _safe(present, heightAt(iy), rb) ? 1 : 0;
    }
    final curA = Uint8List(ny * nk), curB = Uint8List(ny * nc);
    for (var iy = 0; iy < ny; iy++) {
      if (safe[iy] == 0) continue;
      if (f == frames) {
        curA.fillRange(iy * nk, (iy + 1) * nk, 1);
        curB.fillRange(iy * nc, (iy + 1) * nc, 1);
        continue;
      }
      // A ready bird may tap: it then cools, with the velocity fixed.
      final tapRow = _moves.tapY[iy];
      final tapOk = tapRow >= 0 && nextB[tapRow * nc] == 1;
      for (var k = 0; k < nk; k++) {
        if (tapOk) {
          curA[iy * nk + k] = 1;
          continue;
        }
        final row = _moves.freeY[iy * nk + k];
        if (row >= 0 && nextA[row * nk + math.min(k + 1, nk - 1)] == 1) {
          curA[iy * nk + k] = 1;
        }
      }
      for (var c = 1; c <= nc; c++) {
        final row = _moves.coolY[iy * nc + (c - 1)];
        if (row < 0) continue;
        final ok = c < nc
            ? nextB[row * nc + c] == 1
            : nextA[row * nk + kReady] == 1;
        if (ok) curB[iy * nc + (c - 1)] = 1;
      }
    }
    ready[f] = curA;
    cooling[f] = curB;
    nextA = curA;
    nextB = curB;
  }
  return Viability._(frames, ready, cooling);
}

bool _safe(
  List<({double x, double y, double r})> present,
  double y,
  double rb,
) {
  if (y - rb <= .002 || y + rb >= 1 - .002) return false;
  for (final h in present) {
    final dx = birdColumn - h.x, dyy = y - h.y;
    final reach = h.r + rb + eps;
    if (dx * dx + dyy * dyy < reach * reach) return false;
  }
  return true;
}

/// The states that survive the course edges alone for a long while: the
/// audit's reference (a bird already doomed by the edges is nobody's fault).
Viability edgeKernel({double rb = .038}) => solve(const [], 6.0, rb: rb);

/// What an audit of [viability] at [frame] found among the states [kernel]
/// says survive the edges: how many, how many were not viable, and where.
class Audit {
  Audit(this.total, this.bad, this.badHeights);
  final int total, bad;
  final List<String> badHeights;
  bool get fair => bad == 0;
  double get fraction => total == 0 ? 1 : (total - bad) / total;
}

/// Audits states at [frame]: ready states with velocities from [vLo] to
/// [vHi] and every cooling state, at any height (or within .03 of [nearY]).
Audit audit(
  Viability viability,
  Viability kernel, {
  int frame = 0,
  double vLo = flapVelocity,
  double vHi = 1.0,
  double? nearY,
}) {
  var total = 0, bad = 0;
  final badRows = <int, int>{};
  for (var iy = 0; iy < ny; iy++) {
    final y = heightAt(iy);
    if (nearY != null && (y - nearY).abs() > .03) continue;
    void check(bool survives, bool viable) {
      if (!survives) return;
      total++;
      if (viable) return;
      bad++;
      final key = (y / .02).round();
      badRows[key] = (badRows[key] ?? 0) + 1;
    }

    for (var k = 0; k < nk; k++) {
      final v = velocityAt(k);
      if (v < vLo - 1e-9 || v > vHi) continue;
      check(kernel.isReady(0, iy, k), viability.isReady(frame, iy, k));
    }
    for (var c = 1; c <= nc; c++) {
      check(kernel.isCooling(0, iy, c), viability.isCooling(frame, iy, c));
    }
  }
  return Audit(total, bad, [
    for (final e in (badRows.entries.toList()..sort((a, b) => a.key - b.key)))
      '${(e.key * .02).toStringAsFixed(2)}(${e.value})',
  ]);
}

/// How long a bird may ignore the telegraph: the last of the times 0, .1, ...
/// up to [upTo] seconds from the origin at which every surviving state is
/// still viable, or -1 when even the start is not.
double ignoreSlack(Viability viability, Viability kernel, {double upTo = 2.0}) {
  var slack = -1.0;
  for (var s = 0.0; s <= upTo + 1e-9; s += .1) {
    final frame = (s / dtFrame).round();
    if (frame > viability.frames) break;
    if (audit(viability, kernel, frame: frame).fair) {
      slack = s;
    } else {
      break;
    }
  }
  return slack;
}

// --- hazards from the game's own geometry --------------------------------

/// Clouds of a bomb locked at time 0 on height [lockY]: the drawn radius at
/// its widest for the whole second (the script's conservative reading; the
/// game's cloud grows and shrinks inside it).
List<Hazard> cloudHazards(
  double lockY, {
  required bool fury,
  double lockAt = 0,
}) {
  final lob = CrumbLob(
    lockedAt: lockAt,
    lockX: birdColumn,
    lockY: lockY,
    fury: fury,
  );
  return [
    for (final y in lob.cloudHeights)
      (double t) => t >= lob.burstAt && t < lob.cloudEndsAt
          ? (x: birdColumn, y: y, r: KingCoo.cloudRadius)
          : null,
  ];
}

/// A squadron called at the puff (time 0) by a boss at screen column
/// [bossX], for a bird at [birdY] on cycle [cycle].
List<Hazard> squadHazards(
  int cycle,
  double birdY, {
  required bool fury,
  required double bossX,
}) {
  final out = <Hazard>[];
  for (final plan in KingCoo.squad(cycle: cycle, birdY: birdY, fury: fury)) {
    final release = KingCoo.whistleAt - KingCoo.puffAt + plan.delay;
    for (final slot in plan.slots) {
      final track = SquadTrack(
        x0: bossX + slot.behind,
        fromY: .5,
        lane: slot.y,
        bornAt: release,
      );
      out.add((double t) {
        final x = track.x(t);
        if ((x - birdColumn).abs() > .25) return null;
        return (x: x, y: track.y(t), r: SkyEnemy.radius);
      });
    }
  }
  return out;
}

/// The time (from the puff) the last squadron pigeon leaves the bird's
/// column, for a boss at [bossX].
double squadEndsAt(double bossX, {required bool fury}) {
  final crossing = (bossX - birdColumn) / KingCoo.squadSpeed;
  final release = KingCoo.whistleAt - KingCoo.puffAt;
  return release +
      (fury ? KingCoo.furyPicketDelay : 0) +
      crossing +
      .25 / KingCoo.squadSpeed +
      .1;
}

// --- following the viability tables in the real simulation --------------

/// Whether the real bird's state (height [y], velocity [v], [sinceTap]
/// frames since its last tap: 12 or more is ready) is in [viability] at
/// [frame].
bool isViable(
  Viability viability,
  int frame,
  double y,
  double v,
  int sinceTap,
) {
  if (frame > viability.frames) return false;
  final iy = rowOf(y);
  if (iy < 0) return false;
  if (sinceTap < coolFrames) return viability.isCooling(frame, iy, sinceTap);
  final k = ((v - velocityMin) / gdt).round().clamp(0, nk - 1);
  return viability.isReady(frame, iy, k);
}

/// Whether a bird that follows [viability] taps at [frame]: only when
/// holding on would leave the viable set (it cannot tap while cooling).
bool followTap(
  Viability viability,
  int frame,
  double y,
  double v,
  int sinceTap,
) {
  if (frame >= viability.frames || sinceTap < coolFrames) return false;
  final iy = rowOf(y);
  if (iy < 0) return false;
  final k = ((v - velocityMin) / gdt).round().clamp(0, nk - 1);
  final row = _moves.freeY[iy * nk + k];
  final hold =
      row >= 0 && viability.isReady(frame + 1, row, math.min(k + 1, nk - 1));
  return !hold;
}

/// A cautious bird: it follows the most inflated table (the widest safety
/// margin) in which its real state is still viable, so a few thousandths of
/// modelling error (the game steps at 120 Hz, the search at 60) never put it
/// on the edge of what the search proved. [tables] run from the widest
/// margin to none.
bool followCautiously(
  List<Viability> tables,
  int frame,
  double y,
  double v,
  int sinceTap,
) {
  for (final table in tables) {
    if (isViable(table, frame, y, v, sinceTap)) {
      return followTap(table, frame, y, v, sinceTap);
    }
  }
  return followTap(tables.last, frame, y, v, sinceTap);
}
