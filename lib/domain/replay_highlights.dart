import 'dart:math' as math;
import 'game_rules.dart';
import 'session_replay.dart';

// l10n-english-twin: [ReplayHighlight.title] and [ReplayHighlight.detail]
// are the English twins of the replayMoment* keys; the highlights sheet
// words a moment with ReplayText (lib/l10n/text/replay_text.dart).

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

/// One moment worth replaying. It records what happened ([kind], [value]
/// and the fields below), so any language can word it; [title] and
/// [detail] are its English words.
class ReplayHighlight {
  const ReplayHighlight({
    required this.kind,
    required this.atMs,
    required this.priority,
    this.value = 0,
    this.rush,
    this.endReason,
    this.flawless = false,
    this.subtleStars = false,
  });
  final ReplayMomentKind kind;
  final double atMs;
  final int priority, value;

  /// The rush path escaped, for a [ReplayMomentKind.rush] moment.
  final RushPathKind? rush;

  /// How the flight ended, for a [ReplayMomentKind.finish] moment.
  final EndReason? endReason;

  /// A rush or gale got through without a hit (the bigger bonus).
  final bool flawless;

  /// A star trio under the calmer star rewards.
  final bool subtleStars;
  double get playFromMs => math.max(0, atMs - 1500);

  String get title => switch (kind) {
    ReplayMomentKind.start => 'Takeoff',
    ReplayMomentKind.magnet => 'Star magnet',
    ReplayMomentKind.starTrio => 'First star trio',
    ReplayMomentKind.streak => '$value× star power',
    ReplayMomentKind.shield => 'Shield save',
    ReplayMomentKind.perfect => 'First perfect pass',
    ReplayMomentKind.milestone => '$value gates cleared',
    ReplayMomentKind.rush => (rush ?? RushPathKind.wildfire).escape,
    ReplayMomentKind.gale => 'Weathered the gale',
    ReplayMomentKind.finish =>
      endReason == EndReason.completed ? 'Route complete' : 'Final moment',
  };

  String get detail => switch (kind) {
    ReplayMomentKind.start => 'The sky is yours.',
    ReplayMomentKind.magnet => 'Three perfect passes bring the stars closer.',
    ReplayMomentKind.starTrio =>
      subtleStars
          ? 'Every star in the group collected. +5 points!'
          : 'Three stars become a constellation. +5 points!',
    ReplayMomentKind.streak => 'A sparkling streak of stars.',
    ReplayMomentKind.shield => 'A close call, and another chance.',
    ReplayMomentKind.perfect => 'Right through the aiming mark.',
    ReplayMomentKind.milestone => 'A little farther into the sky.',
    ReplayMomentKind.rush =>
      flawless
          ? 'Not a scratch. +$value points!'
          : 'Sprint rings to safety. +$value points!',
    ReplayMomentKind.gale =>
      flawless
          ? 'Not a scratch. +$value points!'
          : 'Dodged the flying debris. +$value points!',
    ReplayMomentKind.finish => switch (endReason) {
      EndReason.completed => 'You reached the end of the route.',
      EndReason.collision => 'Watch the final approach.',
      _ => 'The end of this flight.',
    },
  };
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
        ReplayHighlight(kind: ReplayMomentKind.start, atMs: at, priority: 100),
      );
    }
    for (final event in sim.events.where((e) => e.at > previousTime)) {
      final moment = switch (event.kind) {
        FlightEventKind.magnet => ReplayHighlight(
          kind: ReplayMomentKind.magnet,
          atMs: at,
          priority: 75,
        ),
        FlightEventKind.starTrio => ReplayHighlight(
          kind: ReplayMomentKind.starTrio,
          atMs: at,
          priority: 65,
          subtleStars: sim.subtleStarRewards,
        ),
        FlightEventKind.streak => ReplayHighlight(
          kind: ReplayMomentKind.streak,
          atMs: at,
          value: event.value,
          priority: event.value == 3 ? 85 : 70,
        ),
        FlightEventKind.shieldUsed => ReplayHighlight(
          kind: ReplayMomentKind.shield,
          atMs: at,
          priority: 60,
        ),
        FlightEventKind.perfect when !sim.collectsStars => ReplayHighlight(
          kind: ReplayMomentKind.perfect,
          atMs: at,
          priority: 65,
        ),
        FlightEventKind.milestone when !sim.collectsStars => ReplayHighlight(
          kind: ReplayMomentKind.milestone,
          atMs: at,
          value: event.value,
          priority: event.value == 5 ? 80 : 55,
        ),
        FlightEventKind.rushEscaped => ReplayHighlight(
          kind: ReplayMomentKind.rush,
          atMs: at,
          value: event.value,
          priority: event.value > Rush.escapeBonus ? 90 : 78,
          rush: sim.lastRushKind ?? RushPathKind.wildfire,
          flawless: event.value > Rush.escapeBonus,
        ),
        FlightEventKind.galeWeathered => ReplayHighlight(
          kind: ReplayMomentKind.gale,
          atMs: at,
          value: event.value,
          priority: event.value > Gale.weatherBonus ? 90 : 78,
          flawless: event.value > Gale.weatherBonus,
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
          priority: 100,
          endReason: sim.endReason,
        ),
      );
    }
  }
  moments.sort((a, b) => a.atMs.compareTo(b.atMs));
  return List.unmodifiable(moments);
}
