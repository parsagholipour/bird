import 'dart:math';
import 'game_rules.dart';
import 'tracking.dart';

enum SchoolControl { drag, tap }

/// Local touch sandbox. It owns no camera, recorder, repository or run result.
class FlightSchool {
  FlightSchool({required this.course, required this.control, this.seed = 27})
    : simulation = FlightSimulation(
        rules: control == SchoolControl.drag
            ? PushUpFlightMode(cycleSeconds: 3)
            : JumpFlyMode(),
        practice: true,
        course: course,
        random: Random(seed),
      );
  final FlightCourse course;
  final SchoolControl control;
  final int seed;
  final FlightSimulation simulation;
  double _clock = 0, _height = .5;
  bool _flap = false;
  bool active = false;
  void start() {
    active = true;
  }

  void dragTo(double y) {
    if (control != SchoolControl.drag ||
        !y.isFinite ||
        !active ||
        simulation.phase == RunPhase.paused ||
        simulation.phase == RunPhase.ended) {
      return;
    }
    _height = ((.85 - y.clamp(.15, .85)) / .7).clamp(0, 1);
  }

  void flap() {
    if (active &&
        control == SchoolControl.tap &&
        simulation.phase == RunPhase.playing) {
      _flap = true;
    }
  }

  void pause() {
    if (!active || simulation.phase == RunPhase.ended) return;
    simulation.takeBreak();
    _flap = false;
  }

  void resume() {
    if (!active) return;
    simulation.resume();
  }

  void advance(double dt, double width) {
    if (!active ||
        !dt.isFinite ||
        dt <= 0 ||
        simulation.phase == RunPhase.ended ||
        simulation.phase == RunPhase.paused) {
      return;
    }
    // Backgrounding or a stalled frame pauses the sandbox instead of jumping it.
    if (dt > .5) {
      pause();
      return;
    }
    _clock += dt * 1000;
    simulation.apply(
      MovementInput(valid: true, height: _height, flap: _flap),
      TrackingSample(
        mode: simulation.rules.mode,
        timestampMs: _clock,
        receivedMs: _clock,
        joints: const [],
      ),
      _clock,
    );
    _flap = false;
    simulation.tick(dt, _clock, viewportWidth: width);
  }
}
