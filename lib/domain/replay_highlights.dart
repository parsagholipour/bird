import 'dart:math' as math;
import 'game_rules.dart';
import 'session_replay.dart';

enum ReplayMomentKind {
  start,
  finish,
  magnet,
  streak,
  shield,
  perfect,
  milestone,
  starTrio,
  rush,
  gale,
}

class ReplayHighlight {
  const ReplayHighlight({
    required this.kind,
    required this.atMs,
    required this.title,
    required this.detail,
    required this.priority,
    this.value = 0,
  });
  final ReplayMomentKind kind;
  final double atMs;
  final String title, detail;
  final int priority, value;
  double get playFromMs => math.max(0, atMs - 1500);
}

/// Reconstruct once away from the playback UI. Journal timestamps include
/// countdowns and breaks; simulation elapsed time does not.
List<ReplayHighlight> buildReplayHighlights(ReplayTape tape) {
  final sim = tape.createSimulation();
  final moments = <ReplayHighlight>[];
  final seen = <String>{};
  void offer(ReplayHighlight moment, {String? once}) {
    if (once != null && !seen.add(once)) return;
    final sameFrame = moments.indexWhere((m) => m.atMs == moment.atMs);
    if (sameFrame >= 0) {
      if (moments[sameFrame].priority >= moment.priority) return;
      moments.removeAt(sameFrame);
    }
    moments.add(moment);
    // Keep memory and the eventual list bounded even for a long flight.
    if (moments.length > 12) {
      moments.sort((a, b) {
        final priority = b.priority.compareTo(a.priority);
        return priority != 0 ? priority : b.atMs.compareTo(a.atMs);
      });
      moments.removeLast();
    }
  }

  for (final entry in tape.events) {
    final previousTime = sim.elapsed;
    final hadStarted = sim.started;
    final phase = sim.phase;
    applyReplayEvent(sim, entry, reducedMotion: tape.reducedMotion);
    final at = (entry[0] as num).toDouble();
    if (!hadStarted && sim.started) {
      offer(
        ReplayHighlight(
          kind: ReplayMomentKind.start,
          atMs: at,
          title: 'Takeoff',
          detail: 'The sky is yours.',
          priority: 100,
        ),
      );
    }
    for (final event in sim.events.where((e) => e.at > previousTime)) {
      final moment = switch (event.kind) {
        FlightEventKind.magnet => ReplayHighlight(
          kind: ReplayMomentKind.magnet,
          atMs: at,
          title: 'Star magnet',
          detail: 'Three perfect passes bring the stars closer.',
          priority: 75,
        ),
        FlightEventKind.starTrio => ReplayHighlight(
          kind: ReplayMomentKind.starTrio,
          atMs: at,
          title: 'First star trio',
          detail: sim.subtleStarRewards
              ? 'Every star in the group collected. +5 points!'
              : 'Three stars become a constellation. +5 points!',
          priority: 65,
        ),
        FlightEventKind.streak => ReplayHighlight(
          kind: ReplayMomentKind.streak,
          atMs: at,
          title: '${event.value}× star power',
          detail: 'A sparkling streak of stars.',
          value: event.value,
          priority: event.value == 3 ? 85 : 70,
        ),
        FlightEventKind.shieldUsed => ReplayHighlight(
          kind: ReplayMomentKind.shield,
          atMs: at,
          title: 'Shield save',
          detail: 'A close call, and another chance.',
          priority: 60,
        ),
        FlightEventKind.perfect when !sim.collectsStars => ReplayHighlight(
          kind: ReplayMomentKind.perfect,
          atMs: at,
          title: 'First perfect pass',
          detail: 'Right through the aiming mark.',
          priority: 65,
        ),
        FlightEventKind.milestone when !sim.collectsStars => ReplayHighlight(
          kind: ReplayMomentKind.milestone,
          atMs: at,
          title: '${event.value} gates cleared',
          detail: 'A little farther into the sky.',
          value: event.value,
          priority: event.value == 5 ? 80 : 55,
        ),
        FlightEventKind.rushEscaped => ReplayHighlight(
          kind: ReplayMomentKind.rush,
          atMs: at,
          title: (sim.lastRushKind ?? RushPathKind.wildfire).escape,
          detail: event.value > Rush.escapeBonus
              ? 'Not a scratch. +${event.value} points!'
              : 'Sprint rings to safety. +${event.value} points!',
          value: event.value,
          priority: event.value > Rush.escapeBonus ? 90 : 78,
        ),
        FlightEventKind.galeWeathered => ReplayHighlight(
          kind: ReplayMomentKind.gale,
          atMs: at,
          title: 'Weathered the gale',
          detail: event.value > Gale.weatherBonus
              ? 'Not a scratch. +${event.value} points!'
              : 'Dodged the flying debris. +${event.value} points!',
          value: event.value,
          priority: event.value > Gale.weatherBonus ? 90 : 78,
        ),
        _ => null,
      };
      if (moment != null) {
        final once = switch (moment.kind) {
          ReplayMomentKind.magnet ||
          ReplayMomentKind.shield ||
          ReplayMomentKind.perfect ||
          ReplayMomentKind.starTrio => moment.kind.name,
          ReplayMomentKind.streak => 'streak-${moment.value}',
          _ => null,
        };
        offer(moment, once: once);
      }
    }
    if (phase != RunPhase.ended && sim.phase == RunPhase.ended) {
      offer(
        ReplayHighlight(
          kind: ReplayMomentKind.finish,
          atMs: at,
          title: sim.endReason == EndReason.completed
              ? 'Route complete'
              : 'Final moment',
          detail: switch (sim.endReason) {
            EndReason.completed => 'You reached the end of the route.',
            EndReason.collision => 'Watch the final approach.',
            _ => 'The end of this flight.',
          },
          priority: 100,
        ),
      );
    }
  }
  moments.sort((a, b) => a.atMs.compareTo(b.atMs));
  return List.unmodifiable(moments);
}
