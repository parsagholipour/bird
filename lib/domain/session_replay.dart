import 'dart:math';
import 'game_rules.dart';
import 'tracking.dart';

/// A versioned input journal. Gameplay is reconstructed by the same simulation;
/// no rendered gameplay frames or camera landmarks are stored here.
class ReplayTape {
  ReplayTape({
    required this.mode,
    required this.practice,
    required this.seed,
    required this.cycleSeconds,
    required this.bird,
    required this.reducedMotion,
    required this.originMs,
    this.course = FlightCourse.classic,
    this.recordedVersion = version,
    this.weaponDamage = BirdRock.baseDamage,
    this.plan,
    List<List<dynamic>>? events,
  }) : events = events ?? [];
  static const version = FlightSimulation.currentRulesVersion;
  final int recordedVersion;
  final FlightCourse course;
  final PlayMode mode;
  final bool practice, reducedMotion;
  final int seed, bird;
  final int weaponDamage;

  /// The campaign level's whole plan as it was flown, from rules version
  /// 41, so a level retuned later still replays exactly. Null for endless.
  final LevelPlan? plan;
  String? get levelId => plan?.id;
  final double cycleSeconds, originMs;
  final List<List<dynamic>> events;
  double get durationMs =>
      events.isEmpty ? 0 : (events.last[0] as num).toDouble();
  FlightSimulation createSimulation() => FlightSimulation(
    rules: switch (mode) {
      PlayMode.pushUp => PushUpFlightMode(cycleSeconds: cycleSeconds),
      PlayMode.jump => recordedVersion >= 8 ? JumpFlyMode() : LegacyFlapMode(),
      PlayMode.touch => TapFlyMode(rulesVersion: recordedVersion),
      PlayMode.squat => SquatFlyMode(cycleSeconds: cycleSeconds),
    },
    practice: practice,
    course: course,
    rulesVersion: recordedVersion,
    weaponDamage: weaponDamage,
    plan: plan ?? FlightPlan.endless,
    random: Random(seed),
  );
  Map<String, dynamic> toJson() => {
    'version': recordedVersion,
    'course': course.name,
    'mode': mode.name,
    'practice': practice,
    'seed': seed,
    'cycleSeconds': cycleSeconds,
    'bird': bird,
    'reducedMotion': reducedMotion,
    'originMs': originMs,
    if (recordedVersion >= 26) 'weaponDamage': weaponDamage,
    if (recordedVersion >= 41 && plan != null) ...{
      'level': plan!.id,
      'plan': plan!.toJson(),
    },
    'events': events,
  };
  factory ReplayTape.fromJson(Map<String, dynamic> json) {
    final recordedVersion = json['version'];
    if (recordedVersion is! int ||
        recordedVersion < 1 ||
        recordedVersion > version) {
      throw const FormatException('Unsupported replay version');
    }
    final weaponDamage = recordedVersion >= 26
        ? json['weaponDamage'] ?? BirdRock.baseDamage
        : BirdRock.baseDamage;
    if (weaponDamage is! int || weaponDamage <= 0) {
      throw const FormatException('Invalid weapon damage');
    }
    // A campaign flight carries its level's plan from rules version 41.
    final planJson = recordedVersion >= 41 ? json['plan'] : null;
    final level = recordedVersion >= 41 ? json['level'] : null;
    if (planJson is! Map<String, dynamic>? ||
        (planJson == null) != (level == null)) {
      throw const FormatException('Invalid level plan');
    }
    final plan = planJson == null ? null : LevelPlan.fromJson(planJson);
    if (plan != null &&
        (plan.id != level ||
            json['mode'] != PlayMode.touch.name ||
            json['course'] != FlightCourse.starTrail.name)) {
      throw const FormatException('Invalid level plan');
    }
    final tape = ReplayTape(
      recordedVersion: recordedVersion,
      course: FlightCourse.named(json['course'] as String? ?? 'classic'),
      mode: PlayMode.fromName(json['mode'] as String),
      practice: json['practice'] as bool,
      seed: json['seed'] as int,
      cycleSeconds: (json['cycleSeconds'] as num).toDouble(),
      bird: json['bird'] as int,
      reducedMotion: json['reducedMotion'] as bool,
      originMs: (json['originMs'] as num).toDouble(),
      weaponDamage: weaponDamage,
      plan: plan,
      events: (json['events'] as List)
          .map((e) => List<dynamic>.from(e as List))
          .toList(),
    );
    if (tape.bird < 0 ||
        tape.bird > 3 ||
        !tape.originMs.isFinite ||
        !tape.cycleSeconds.isFinite ||
        tape.cycleSeconds <= 0) {
      throw const FormatException('Invalid replay configuration');
    }
    double last = 0;
    for (final event in tape.events) {
      final time = (event[0] as num).toDouble();
      if (!time.isFinite ||
          time < last ||
          ![
            'input',
            'tick',
            'break',
            'background',
            'resume',
            'end',
            if (recordedVersion >= 7) 'shoot',
            if (recordedVersion >= 26) 'weaponDamage',
            if (recordedVersion >= 28) 'charge',
            if (recordedVersion >= 29) 'sprint',
          ].contains(event[1])) {
        throw const FormatException('Invalid replay timeline');
      }
      bool number(int i) => event[i] is num && (event[i] as num).isFinite;
      final valid = switch (event[1]) {
        'input' =>
          event.length == 10 &&
              number(2) &&
              number(3) &&
              (event[4] == 'smile' ||
                  PlayMode.values.any((m) => m.name == event[4])) &&
              event[5] is bool &&
              number(6) &&
              event[7] is bool &&
              event[8] is int &&
              event[9] is String,
        'tick' =>
          event.length == 5 &&
              number(2) &&
              number(3) &&
              number(4) &&
              (event[4] as num) > 0,
        'end' =>
          event.length == 3 && EndReason.values.any((r) => r.name == event[2]),
        'weaponDamage' =>
          event.length == 3 && event[2] is int && (event[2] as int) > 0,
        _ => event.length == 2,
      };
      if (!valid) throw const FormatException('Invalid replay event');
      last = time;
    }
    return tape;
  }
}

class FlightRecorder {
  FlightRecorder(this.tape, this.nowMs) : simulation = tape.createSimulation();
  final ReplayTape tape;
  final double Function() nowMs;
  final FlightSimulation simulation;
  void _add(String kind, List<dynamic> args, [double? now]) {
    final time = max(
      tape.durationMs,
      max(0.0, (now ?? nowMs()) - tape.originMs),
    );
    tape.events.add([time, kind, ...args]);
  }

  void apply(MovementInput input, TrackingSample sample, double now) {
    _add('input', [
      sample.timestampMs,
      now,
      sample.mode.name,
      input.valid,
      input.height,
      input.flap,
      input.repetitions,
      input.feedback,
    ], now);
    simulation.apply(input, sample, now);
  }

  void tick(double dt, double now, double viewportWidth) {
    if (simulation.phase == RunPhase.ended ||
        simulation.phase == RunPhase.paused) {
      return;
    }
    _add('tick', [dt, now, viewportWidth], now);
    simulation.tick(
      dt,
      now,
      viewportWidth: viewportWidth,
      reducedMotion: tape.reducedMotion,
    );
  }

  void command(String kind, [EndReason? reason]) {
    _add(kind, [if (reason != null) reason.name]);
    applyReplayEvent(
      simulation,
      tape.events.last,
      reducedMotion: tape.reducedMotion,
    );
  }

  /// Upgrade hook: record the change before any subsequently fired shots.
  void setWeaponDamage(int damage) {
    if (damage <= 0) throw ArgumentError.value(damage, 'damage');
    if (!simulation.supportsWeaponDamage) {
      throw StateError('Weapon damage requires touch combat rules version 26');
    }
    _add('weaponDamage', [damage]);
    simulation.setWeaponDamage(damage);
  }
}

void applyReplayEvent(
  FlightSimulation simulation,
  List<dynamic> e, {
  bool reducedMotion = false,
}) {
  double n(int i) => (e[i] as num).toDouble();
  switch (e[1]) {
    case 'input':
      simulation.apply(
        MovementInput(
          valid: e[5] as bool,
          height: n(6),
          flap: e[7] as bool,
          repetitions: e[8] as int,
          feedback: e[9] as String,
        ),
        TrackingSample(
          mode: PlayMode.fromName(e[4] as String),
          timestampMs: n(2),
          receivedMs: n(3),
          joints: const [],
        ),
        n(3),
      );
    case 'tick':
      simulation.tick(
        n(2),
        n(3),
        viewportWidth: n(4),
        reducedMotion: reducedMotion,
      );
    case 'break':
      simulation.takeBreak();
    case 'background':
      simulation.background();
    case 'resume':
      simulation.resume();
    case 'end':
      simulation.end(EndReason.values.byName(e[2] as String));
    case 'charge':
      simulation.startCharge();
    case 'shoot':
      simulation.shoot(reducedMotion: reducedMotion);
    case 'sprint':
      simulation.sprint();
    case 'weaponDamage':
      simulation.setWeaponDamage(e[2] as int);
  }
}

class ReplayPlayer {
  ReplayPlayer(this.tape) : simulation = tape.createSimulation();
  final ReplayTape tape;
  FlightSimulation simulation;
  int _next = 0;
  double positionMs = 0;

  /// Forward playback is incremental. A backward seek reruns the input journal,
  /// preserving random obstacles, frame substeps and tracking interruptions.
  void seek(double milliseconds) {
    final target = milliseconds.clamp(0.0, tape.durationMs);
    if (target < positionMs) {
      simulation = tape.createSimulation();
      _next = 0;
    }
    while (_next < tape.events.length &&
        (tape.events[_next][0] as num) <= target) {
      applyReplayEvent(
        simulation,
        tape.events[_next++],
        reducedMotion: tape.reducedMotion,
      );
    }
    positionMs = target;
  }

  double get aspectRatio {
    for (final e in tape.events) {
      if (e[1] == 'tick') return (e[4] as num).toDouble();
    }
    return 2.2;
  }
}
