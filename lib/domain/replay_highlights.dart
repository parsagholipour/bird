import 'dart:math' as math;
import 'cloud_friends.dart';
import 'game_rules.dart';
import 'session_replay.dart';

enum ReplayMomentKind {
  start,
  finish,
  cloud,
  delivery,
  magnet,
  streak,
  shield,
  perfect,
  milestone,
  droppedLetter,
  starTrio,
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
    // Keep memory and the eventual list bounded even for an hours-long Cruise.
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
        FlightEventKind.cloudFriend => ReplayHighlight(
          kind: ReplayMomentKind.cloud,
          atMs: at,
          title: CloudFriend.values[event.value].title,
          detail: 'A new friend in the clouds.',
          value: event.value,
          priority: 90,
        ),
        FlightEventKind.delivery => ReplayHighlight(
          kind: ReplayMomentKind.delivery,
          atMs: at,
          title: event.value == 1
              ? 'First delivery'
              : 'Delivery ${event.value}',
          detail: 'A letter reaches its postbox.',
          value: event.value,
          priority: event.value == 1 ? 85 : 55,
        ),
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
          detail: 'Three stars become a constellation. +5 points!',
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
        FlightEventKind.perfect when !sim.collectsStars && !sim.isCourier =>
          ReplayHighlight(
            kind: ReplayMomentKind.perfect,
            atMs: at,
            title: 'First perfect pass',
            detail: 'Right through the aiming mark.',
            priority: 65,
          ),
        FlightEventKind.milestone when !sim.collectsStars && !sim.isCourier =>
          ReplayHighlight(
            kind: ReplayMomentKind.milestone,
            atMs: at,
            title: '${event.value} gates cleared',
            detail: 'A little farther into the sky.',
            value: event.value,
            priority: event.value == 5 ? 80 : 55,
          ),
        FlightEventKind.letterLost => ReplayHighlight(
          kind: ReplayMomentKind.droppedLetter,
          atMs: at,
          title: 'Letter dropped',
          detail: 'See where the route got tricky.',
          priority: 45,
        ),
        _ => null,
      };
      if (moment != null) {
        final once = switch (moment.kind) {
          ReplayMomentKind.magnet ||
          ReplayMomentKind.shield ||
          ReplayMomentKind.perfect ||
          ReplayMomentKind.starTrio ||
          ReplayMomentKind.droppedLetter => moment.kind.name,
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
