import 'dart:async';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/providers.dart';
import '../data/progress_repository.dart';
import '../domain/flight_school.dart';
import '../domain/game_rules.dart';
import '../game/bird_game.dart';
import '../game/audio.dart';
import 'components.dart';
import 'theme.dart';

class FlightSchoolScreen extends ConsumerStatefulWidget {
  const FlightSchoolScreen({super.key, required this.course});
  final FlightCourse course;
  @override
  ConsumerState<FlightSchoolScreen> createState() => _FlightSchoolScreenState();
}

class _FlightSchoolScreenState extends ConsumerState<FlightSchoolScreen>
    with WidgetsBindingObserver {
  late FlightSchool school;
  late BirdGame game;
  late SkyAudio audio;
  late GameSettings settings;
  SchoolControl control = SchoolControl.drag;
  late FlightCourse course;
  bool _refreshQueued = false, _finishedNotified = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    settings =
        ref.read(progressProvider).asData?.value.settings ??
        const GameSettings();
    audio = ref.read(audioFactoryProvider)();
    unawaited(audio.configure(settings, active: false));
    course = widget.course;
    _reset();
  }

  void _reset() {
    _finishedNotified = false;
    school = FlightSchool(course: course, control: control);
    game = BirdGame(
      simulation: school.simulation,
      nowMs: () => 0,
      bird: settings.bird,
      reducedMotion: settings.reducedMotion,
      advance: (dt, _, width) => _advance(dt, width),
      onChanged: _refresh,
    );
    unawaited(audio.stop());
    unawaited(audio.stopEffects());
  }

  void _refresh() {
    if (!mounted || _refreshQueued) return;
    if (school.simulation.phase == RunPhase.ended) {
      if (_finishedNotified) return;
      _finishedNotified = true;
      game.pauseEngine();
    }
    // Flame may publish an update during its LayoutBuilder. Refresh the HUD
    // after that layout, and only once for the completed lesson.
    _refreshQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshQueued = false;
      if (mounted) setState(() {});
    });
  }

  void _advance(double dt, double width) {
    final sim = school.simulation;
    final before = sim.elapsed, phase = sim.phase, flaps = sim.flaps;
    school.advance(dt, width);
    if (sim.phase != phase && sim.phase == RunPhase.playing) audio.effect('go');
    if (sim.flaps > flaps) audio.effect('flap');
    if (sim.phase == RunPhase.ended && phase != RunPhase.ended) {
      audio.effect(
        sim.endReason == EndReason.completed ? 'complete' : 'finish',
      );
      unawaited(audio.stop());
    } else if (sim.phase == RunPhase.paused && phase != RunPhase.paused) {
      game.pauseEngine();
      unawaited(audio.stop());
      unawaited(audio.stopEffects());
    }
    final events = sim.events
        .where((e) => e.at > before)
        .map((e) => e.kind)
        .toSet();
    for (final (kind, sound) in [
      (FlightEventKind.hit, 'bump'),
      (FlightEventKind.letterLost, 'bump'),
      (FlightEventKind.shieldUsed, 'shield_pop'),
      (FlightEventKind.cloudFriend, 'cloud'),
      (FlightEventKind.delivery, 'delivery'),
      (FlightEventKind.letter, 'letter'),
      (FlightEventKind.magnet, 'magnet'),
      (FlightEventKind.streak, 'streak'),
      (FlightEventKind.starTrio, 'trio'),
      (FlightEventKind.perfect, 'perfect'),
      (FlightEventKind.shieldReady, 'shield'),
      (FlightEventKind.star, 'star'),
    ]) {
      if (events.contains(kind)) {
        audio.effect(sound);
        break;
      }
    }
  }

  void _pause() {
    school.pause();
    game.pauseEngine();
    unawaited(audio.stop());
    unawaited(audio.stopEffects());
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(audio.dispose());
    super.dispose();
  }

  String get _hint => control == SchoolControl.drag
      ? 'Drag anywhere to move up and down.'
      : 'Tap anywhere to flap. Release between taps.';
  String get _lesson => switch (course) {
    FlightCourse.classic =>
      'Follow each aiming mark through the gap. A perfect pass blooms with gold flowers.',
    FlightCourse.starTrail =>
      'Collect a whole star trio for +5. Follow the gaps, charge a magnet and keep your shield.',
    FlightCourse.skyCourier =>
      'Fly through a pickup with an empty pouch, then reach a postbox to deliver the letter.',
    FlightCourse.cloudCruise =>
      'Follow the stars and meet three cloud friends. The open rings never cause a crash.',
  };
  void _camera(String mode) =>
      context.go('/play/$mode?practice=true&course=${course.name}');

  @override
  Widget build(BuildContext context) {
    final sim = school.simulation;
    final overlay =
        !school.active ||
        sim.phase == RunPhase.paused ||
        sim.phase == RunPhase.ended;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            Semantics(
              label: control == SchoolControl.tap
                  ? 'Tap to flap'
                  : 'Drag to move the bird',
              onTap: control == SchoolControl.tap ? school.flap : null,
              onIncrease: control == SchoolControl.drag
                  ? () => school.dragTo(sim.birdY - .1)
                  : null,
              onDecrease: control == SchoolControl.drag
                  ? () => school.dragTo(sim.birdY + .1)
                  : null,
              child: GestureDetector(
                key: const ValueKey('school-flight'),
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) {
                  if (control == SchoolControl.tap) {
                    school.flap();
                  } else {
                    school.dragTo(d.localPosition.dy / constraints.maxHeight);
                  }
                },
                onPanDown: control == SchoolControl.drag
                    ? (d) => school.dragTo(
                        d.localPosition.dy / constraints.maxHeight,
                      )
                    : null,
                onPanUpdate: control == SchoolControl.drag
                    ? (d) => school.dragTo(
                        d.localPosition.dy / constraints.maxHeight,
                      )
                    : null,
                child: GameWidget(key: ObjectKey(game), game: game),
              ),
            ),
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  RoundButton(
                    icon: Icons.arrow_back,
                    label: 'Leave flight school',
                    onPressed: () => context.go('/'),
                  ),
                  const SizedBox(width: 10),
                  Pill(
                    constraints.maxWidth < 750 ? 'SCHOOL' : 'FLIGHT SCHOOL',
                    icon: Icons.touch_app_rounded,
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: SkyColors.cream,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<FlightCourse>(
                        key: const ValueKey('school-course'),
                        value: course,
                        style: bodyText(14, weight: FontWeight.w900),
                        items: [
                          for (final item in FlightCourse.values)
                            DropdownMenuItem(
                              value: item,
                              child: Text(item.shortTitle),
                            ),
                        ],
                        onChanged: (value) {
                          if (value == null || value == course) return;
                          setState(() {
                            course = value;
                            _reset();
                          });
                        },
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (school.active) ...[
                    if (constraints.maxWidth >= 750)
                      Pill(
                        '${sim.score} ${course.scoreUnit}',
                        color: SkyColors.yellow,
                      ),
                    const SizedBox(width: 8),
                    RoundButton(
                      icon: Icons.refresh_rounded,
                      label: 'Restart lesson',
                      onPressed: () => setState(_reset),
                    ),
                    if (!overlay) ...[
                      const SizedBox(width: 8),
                      RoundButton(
                        icon: Icons.pause_rounded,
                        label: 'Pause lesson',
                        onPressed: _pause,
                      ),
                    ],
                  ],
                ],
              ),
            ),
            if (!overlay && sim.phase == RunPhase.countdown)
              Center(
                child: IgnorePointer(
                  child: Pill(
                    '${sim.countdown.ceil()}',
                    color: SkyColors.yellow,
                  ),
                ),
              ),
            if (school.active && constraints.maxWidth < 750)
              Positioned(
                top: 72,
                right: 16,
                child: IgnorePointer(
                  child: Pill(
                    '${sim.score} ${course.scoreUnit}',
                    color: SkyColors.yellow,
                  ),
                ),
              ),
            if (!overlay)
              Positioned(
                bottom: 60,
                right: 16,
                child: IgnorePointer(
                  child: Pill(switch (course) {
                    FlightCourse.classic =>
                      '${sim.perfectPasses} perfect passes',
                    FlightCourse.starTrail =>
                      '${sim.hearts} hearts · ${sim.multiplier}× · ${sim.shield ? 'Shield ready' : 'Collect 9 stars for a shield'}',
                    FlightCourse.skyCourier =>
                      sim.carryingLetter
                          ? 'Letter aboard · Find a postbox'
                          : 'Find a pickup gate',
                    FlightCourse.cloudCruise =>
                      '${sim.cloudFriends.length}/3 cloud friends',
                  }, color: SkyColors.cream),
                ),
              ),
            if (!overlay)
              Positioned(
                bottom: 12,
                left: 16,
                right: 16,
                child: IgnorePointer(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Pill(
                          _hint,
                          icon: control == SchoolControl.drag
                              ? Icons.swap_vert_rounded
                              : Icons.touch_app_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (overlay)
              Positioned.fill(
                top: 70,
                bottom: 12,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 6,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Panel(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              !school.active
                                  ? 'A little flight lesson'
                                  : sim.phase == RunPhase.paused
                                  ? 'Take your time.'
                                  : sim.endReason == EndReason.completed
                                  ? 'Lesson complete!'
                                  : 'Another go?',
                              style: heading(28),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _lesson,
                              textAlign: TextAlign.center,
                              style: bodyText(14, color: SkyColors.muted),
                            ),
                            const SizedBox(height: 10),
                            if (!school.active) ...[
                              SegmentedButton<SchoolControl>(
                                segments: const [
                                  ButtonSegment(
                                    value: SchoolControl.drag,
                                    icon: Icon(Icons.swap_vert_rounded),
                                    label: Text('Drag to steer'),
                                  ),
                                  ButtonSegment(
                                    value: SchoolControl.tap,
                                    icon: Icon(Icons.touch_app_rounded),
                                    label: Text('Tap to flap'),
                                  ),
                                ],
                                selected: {control},
                                onSelectionChanged: (value) => setState(() {
                                  control = value.single;
                                  _reset();
                                }),
                              ),
                              const SizedBox(height: 10),
                            ],
                            Text(
                              'Touch controls · No camera · Progress stays in this lesson',
                              style: bodyText(12, color: SkyColors.muted),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            SkyButton(
                              label: !school.active
                                  ? 'Start lesson'
                                  : sim.phase == RunPhase.paused
                                  ? 'Continue lesson'
                                  : 'Try again',
                              color: SkyColors.yellow,
                              onPressed: () {
                                setState(() {
                                  if (sim.phase == RunPhase.ended) _reset();
                                  if (school.simulation.phase ==
                                      RunPhase.paused) {
                                    school.resume();
                                  } else {
                                    school.start();
                                  }
                                });
                                unawaited(audio.configure(settings));
                                game.resumeEngine();
                              },
                            ),
                            if (school.active) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton(
                                    onPressed: () => _camera('push-up'),
                                    child: const Text('Try with push-ups'),
                                  ),
                                  TextButton(
                                    onPressed: () => _camera('smile'),
                                    child: const Text('Try with smiles'),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
