import 'dart:async';
import 'dart:io';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/providers.dart';
import '../data/progress_repository.dart';
import '../data/passport_progress.dart';
import '../domain/sky_passport.dart';
import '../domain/game_rules.dart';
import '../domain/flight_goals.dart';
import '../domain/tracking.dart';
import '../game/audio.dart';
import '../game/bird_game.dart';
import '../game/play_controller.dart';
import 'calibration_probe.dart' show LandmarkPainter;
import 'components.dart';
import 'theme.dart';
import 'setup_art.dart';
import 'flight_portrait.dart';
import 'record_chase.dart';
import 'flight_goals.dart';
import 'cloud_friends.dart';

class PlayScreen extends ConsumerStatefulWidget {
  const PlayScreen({
    super.key,
    required this.mode,
    bool practice = false,
    this.course = FlightCourse.classic,
  }) : practice = practice || course == FlightCourse.cloudCruise;
  final FlightCourse course;
  final PlayMode mode;
  final bool practice;
  @override
  ConsumerState<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends ConsumerState<PlayScreen>
    with WidgetsBindingObserver {
  late final PlayController controller;
  late final SkyAudio audio;
  BirdGame? game;
  int previousScore = 0,
      previousCount = 4,
      previousPerfects = 0,
      previousMultiplier = 1,
      previousMagnets = 0,
      previousTrios = 0,
      previousLetters = 0,
      previousBumps = 0,
      previousWings = 0,
      previousCloudFriends = 0,
      previousHearts = 3;
  double previousFlightTime = 0;
  double wingCelebrationUntil = 0;
  bool previousShield = true;
  bool awardSoundPlayed = false;
  bool leaving = false;
  int initialBest = 0;
  Set<SkyStamp> initialStamps = {};
  Set<int> initialBirds = {0};
  String? initialDailyKey;
  bool initialDailyComplete = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    audio = ref.read(audioFactoryProvider)();
    final settings =
        ref.read(progressProvider).asData?.value.settings ??
        const GameSettings();
    audio.configure(settings);
    initialBest =
        ref
            .read(progressProvider)
            .asData
            ?.value
            .record(widget.mode, widget.course)
            .best ??
        0;
    initialStamps =
        ref
            .read(progressProvider)
            .asData
            ?.value
            .passport
            .where((p) => p.earned)
            .map((p) => p.stamp)
            .toSet() ??
        {};
    initialBirds = Set.of(
      ref.read(progressProvider).asData?.value.unlocked ?? {0},
    );
    controller = PlayController(
      mode: widget.mode,
      course: widget.course,
      practice: widget.practice,
      source: widget.mode == PlayMode.touch
          ? null
          : ref.read(trackingSourceFactoryProvider)(),
      clock: ref.read(appClockProvider),
      audio: audio,
      bird: settings.bird,
      reducedMotion: settings.reducedMotion,
      recordAudio: settings.recordAudio,
      rememberRecordAudio: (value) => ref
          .read(progressProvider.notifier)
          .setting(SettingKey.recordAudio, value),
      saveSession: (session) async {
        await ref.read(sessionRepositoryProvider).save(session);
        ref.invalidate(sessionsProvider);
      },
      saveRun: (run) => ref.read(progressProvider.notifier).save(run),
    );
    controller.addListener(changed);
    unawaited(controller.verifyMicrophoneAccess());
  }

  void changed() {
    if (!mounted) return;
    final sim = controller.simulation;
    if (sim != null &&
        controller.stage == PlayStage.flying &&
        game?.simulation != sim) {
      final settings =
          ref.read(progressProvider).asData?.value.settings ??
          const GameSettings();
      previousScore = 0;
      previousPerfects = 0;
      previousMultiplier = 1;
      previousMagnets = 0;
      previousTrios = 0;
      previousLetters = 0;
      previousBumps = 0;
      previousWings = 0;
      previousCloudFriends = 0;
      wingCelebrationUntil = 0;
      previousFlightTime = 0;
      previousHearts = 3;
      previousShield = true;
      previousCount = 4;
      awardSoundPlayed = false;
      final progress = ref.read(progressProvider).asData?.value;
      initialBest = progress?.record(widget.mode, widget.course).best ?? 0;
      initialStamps =
          progress?.passport
              .where((p) => p.earned)
              .map((p) => p.stamp)
              .toSet() ??
          {};
      initialBirds = Set.of(progress?.unlocked ?? {0});
      initialDailyKey = progress?.today?.dayKey;
      initialDailyComplete = progress?.today?.complete ?? false;
      game = BirdGame(
        simulation: sim,
        nowMs: () => controller.nowMs,
        bird: settings.bird,
        reducedMotion: settings.reducedMotion,
        onChanged: controller.tick,
        advance: controller.advance,
      );
    }
    if (sim != null) {
      final wings = FlightGoals.earned(FlightGoals.forSimulation(sim));
      final earnedWing = wings > previousWings;
      if (earnedWing && sim.phase == RunPhase.playing) {
        wingCelebrationUntil = sim.elapsed + 1.8;
      }
      if (!widget.practice &&
          initialBest > 0 &&
          previousScore <= initialBest &&
          sim.score > initialBest) {
        audio.effect('record');
      } else if (earnedWing && sim.phase == RunPhase.playing) {
        audio.effect('wing');
      } else if (sim.cloudFriends.length > previousCloudFriends) {
        audio.effect('cloud');
      } else if (sim.isCourier && sim.score > previousScore) {
        audio.effect('delivery');
      } else if (sim.lettersCollected > previousLetters) {
        audio.effect('letter');
      } else if (sim.magnetActivations > previousMagnets) {
        audio.effect('magnet');
      } else if (sim.multiplier > previousMultiplier) {
        audio.effect('streak');
      } else if (sim.completedTrios > previousTrios) {
        audio.effect('trio');
      } else if (sim.perfectPasses > previousPerfects) {
        audio.effect('perfect');
      } else if (sim.score > previousScore) {
        audio.effect(sim.collectsStars ? 'star' : 'point');
      }
      previousScore = sim.score;
      if (sim.courierBumps > previousBumps) audio.effect('bump');
      previousLetters = sim.lettersCollected;
      previousBumps = sim.courierBumps;
      previousWings = wings;
      previousCloudFriends = sim.cloudFriends.length;
      if (sim.isTrail && sim.hearts < previousHearts) audio.effect('bump');
      if (sim.isTrail && sim.shield && !previousShield) audio.effect('shield');
      if (sim.isTrail && !sim.shield && previousShield) {
        audio.effect('shield_pop');
      }
      previousHearts = sim.hearts;
      previousShield = sim.shield;
      previousPerfects = sim.perfectPasses;
      previousMultiplier = sim.multiplier;
      previousMagnets = sim.magnetActivations;
      previousTrios = sim.completedTrios;
      if (sim.timed &&
          previousFlightTime < sim.course.duration - 10 &&
          sim.elapsed >= sim.course.duration - 10) {
        audio.effect('final_stretch');
      }
      previousFlightTime = sim.elapsed;
      final count = sim.countdown.ceil();
      if (sim.phase == RunPhase.countdown &&
          count != previousCount &&
          sim.hasTracking) {
        audio.effect('ready');
        previousCount = count;
      }
    }
    if (!awardSoundPlayed &&
        controller.saved &&
        controller.result?.practice == false) {
      final progress = ref.read(progressProvider).asData?.value;
      if (progress != null &&
          (progress.passport.any(
                (p) => p.earned && !initialStamps.contains(p.stamp),
              ) ||
              progress.unlocked.any((bird) => !initialBirds.contains(bird)) ||
              (progress.today?.complete == true &&
                  (initialDailyKey != progress.today?.dayKey ||
                      !initialDailyComplete)))) {
        awardSoundPlayed = true;
        audio.effect('unlock');
      }
    }
    setState(() {});
  }

  Future<void> leave([String destination = '/']) async {
    if (leaving) return;
    leaving = true;
    await controller.exit();
    if (mounted) context.go(destination);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      controller.background();
    }
    if (state == AppLifecycleState.resumed) {
      audio.configure(
        ref.read(progressProvider).asData?.value.settings ??
            const GameSettings(),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.removeListener(changed);
    controller.dispose();
    audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p =
        ref.watch(progressProvider).asData?.value ?? const ProgressSnapshot();
    final stage = controller.stage;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(leave());
      },
      child: Scaffold(
        body: SkyBackdrop(
          child: SceneLayout(
            child: Stack(
              children: [
                if (!controller.isTouch &&
                    Platform.isAndroid &&
                    stage != PlayStage.setup &&
                    stage != PlayStage.results)
                  const Positioned(
                    left: 28,
                    top: 92,
                    width: 540,
                    height: 322,
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(24)),
                      child: AndroidView(
                        key: ValueKey('camera-preview'),
                        viewType: 'push_up_bird/camera',
                      ),
                    ),
                  ),
                if (stage == PlayStage.setup)
                  controller.isTouch ? _touchSetup() : _setup(p),
                if (stage == PlayStage.starting ||
                    stage == PlayStage.calibration ||
                    stage == PlayStage.ready ||
                    stage == PlayStage.error)
                  _calibration(p),
                if (stage == PlayStage.flying && game != null)
                  Positioned.fill(child: _flight()),
                if (stage == PlayStage.results) _results(p),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(String title, {Widget? trailing}) => Row(
    children: [
      RoundButton(
        icon: Icons.arrow_back_rounded,
        label: 'Back home',
        onPressed: leave,
      ),
      const SizedBox(width: 16),
      Text(title, style: heading(30)),
      const Spacer(),
      ?trailing,
    ],
  );
  Widget _touchSetup() => Padding(
    padding: const EdgeInsets.all(28),
    child: Column(
      children: [
        _header(
          'Tap & Fly',
          trailing: Pill(
            widget.course.title,
            icon: Icons.touch_app_rounded,
            color: SkyColors.mint,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Panel(
            child: Row(
              children: [
                Expanded(
                  child: BirdArt(
                    size: 200,
                    bird: controller.bird,
                    reducedMotion: controller.reducedMotion,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('A little tap. A lot of sky.', style: heading(32)),
                      const SizedBox(height: 12),
                      Text(
                        'Tap anywhere in the sky to flap upward.\nRelease and tap again to keep flying.',
                        style: bodyText(18),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No camera needed · Save your flight as a replay',
                        style: bodyText(14, color: SkyColors.muted),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          SkyButton(
                            label: 'Start touch flight',
                            icon: Icons.touch_app_rounded,
                            color: SkyColors.mint,
                            onPressed: () => controller.fly(),
                          ),
                          if (!widget.practice) ...[
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: () => context.go(
                                '/play/touch?practice=true&course=${widget.course.name}',
                              ),
                              child: const Text('Try a practice flight'),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.practice
                            ? 'Practice · Pause whenever you like'
                            : 'Scored flight · Separate touch records',
                        style: bodyText(13, color: SkyColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _setup(ProgressSnapshot p) => Padding(
    padding: const EdgeInsets.all(28),
    child: Column(
      children: [
        _header(
          widget.mode == PlayMode.pushUp
              ? 'A little setup. A lot of sky.'
              : 'Your smile has wings.',
          trailing: Pill(
            '${widget.course.title.toUpperCase()} · ${widget.practice ? 'PRACTICE' : 'SCORED'}',
            icon: widget.practice
                ? Icons.spa_outlined
                : Icons.emoji_events_outlined,
            color: SkyColors.yellow,
          ),
        ),
        const SizedBox(height: 22),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Panel(
                  color: const Color(0xffe5f3db),
                  child: Column(
                    children: [
                      Expanded(
                        child: widget.mode == PlayMode.pushUp
                            ? CustomPaint(
                                size: const Size(
                                  double.infinity,
                                  double.infinity,
                                ),
                                painter: const PushUpSetupArt(),
                              )
                            : Center(
                                child: FittedBox(
                                  child: BirdArt(
                                    bird: 1,
                                    size: 160,
                                    reducedMotion: p.settings.reducedMotion,
                                  ),
                                ),
                              ),
                      ),
                      Text(
                        widget.mode == PlayMode.pushUp
                            ? 'Make a little room to move.'
                            : 'Take a seat. Face the camera.',
                        style: heading(25),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.mode == PlayMode.pushUp
                            ? 'Phone low. Show an arm and hip.\nFacing it? Keep both shoulders in view.'
                            : 'One smile gives one flap.\nRelax your face before the next one.',
                        style: bodyText(15, color: SkyColors.muted),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      _microphoneOption(),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HOW TO FLY',
                      style: bodyText(
                        12,
                        weight: FontWeight.w900,
                        color: SkyColors.muted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _step(
                      '1',
                      widget.mode == PlayMode.pushUp
                          ? 'Show your arm and hip'
                          : 'Find a comfortable seat',
                      widget.mode == PlayMode.pushUp
                          ? 'Facing the phone? Show both shoulders, one arm and a hip.'
                          : 'Prop the phone at face height in landscape.',
                    ),
                    _step(
                      '2',
                      widget.mode == PlayMode.pushUp
                          ? 'Find your movement range'
                          : 'Teach us your smile',
                      widget.mode == PlayMode.pushUp
                          ? 'Find a comfortable top, then move down and up twice.'
                          : 'Hold a neutral expression, then a smile.',
                    ),
                    _step('3', widget.course.title, widget.course.instructions),
                    const Spacer(),
                    Text(
                      widget.practice
                          ? 'Practice can pause. Save a local camera replay after your flight.'
                          : widget.course == FlightCourse.starTrail
                          ? 'Three hearts + a shield. A break or leaving ends the flight.'
                          : widget.course == FlightCourse.skyCourier
                          ? 'Bumps drop your letter. A break or leaving ends the route.'
                          : 'A collision, a break or leaving the app ends a scored flight.',
                      style: bodyText(13, color: SkyColors.muted),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: SkyButton(
                        label: 'Set up my camera',
                        icon: Icons.camera_alt_outlined,
                        onPressed: controller.microphoneRequestPending
                            ? null
                            : () => controller.startCamera(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  Widget _microphoneOption() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: SkyColors.cream,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.mic_none_rounded, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Record microphone · Optional',
                style: bodyText(14, weight: FontWeight.w800),
              ),
            ),
            Semantics(
              label: 'Record microphone for replays',
              child: Switch(
                value: controller.recordAudio,
                onChanged: controller.microphoneRequestPending
                    ? null
                    : controller.setRecordAudio,
              ),
            ),
          ],
        ),
        Text(
          controller.microphoneMessage.isEmpty
              ? 'Add your voice and room sound to replays. Uses the microphone during flight only. Saved on this phone.'
              : controller.microphoneMessage,
          style: bodyText(12, color: SkyColors.muted),
        ),
        if (controller.microphoneSettingsAvailable)
          TextButton(
            onPressed: controller.source!.openSettings,
            child: const Text('Microphone settings'),
          ),
      ],
    ),
  );

  Widget _step(String number, String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: SkyColors.yellow,
            shape: BoxShape.circle,
          ),
          child: Text(number, style: bodyText(16, weight: FontWeight.w900)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: heading(20)),
              const SizedBox(height: 4),
              Text(subtitle, style: bodyText(14, color: SkyColors.muted)),
            ],
          ),
        ),
      ],
    ),
  );
  Widget _calibration(ProgressSnapshot p) {
    final ready = controller.stage == PlayStage.ready,
        busy = controller.stage == PlayStage.starting,
        error = controller.stage == PlayStage.error;
    final title = ready
        ? 'You found your wings!'
        : busy
        ? 'Waking up your camera…'
        : error
        ? 'Let’s reconnect your camera.'
        : widget.mode == PlayMode.pushUp
        ? 'Find your movement range.'
        : 'Find your smile.';
    return Stack(
      children: [
        Positioned(
          left: 28,
          right: 28,
          top: 24,
          child: _header(
            title,
            trailing: Row(
              children: [
                RoundButton(
                  icon: Icons.cameraswitch_outlined,
                  label: 'Switch camera',
                  onPressed: busy ? null : controller.switchCamera,
                ),
                const SizedBox(width: 10),
                Pill(
                  ready
                      ? 'READY'
                      : busy
                      ? 'STARTING'
                      : 'CALIBRATING',
                  icon: ready
                      ? Icons.check_circle_outline
                      : Icons.center_focus_strong,
                  color: ready ? SkyColors.mint : SkyColors.cream,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 28,
          top: 92,
          width: 540,
          height: 322,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (busy || error) Container(color: SkyColors.ink),
                IgnorePointer(
                  child: CustomPaint(
                    painter: LandmarkPainter(
                      controller.latest,
                      controller.front,
                      widget.mode,
                    ),
                  ),
                ),
                if (busy)
                  const Center(
                    child: CircularProgressIndicator(color: SkyColors.yellow),
                  ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: SkyColors.ink.withValues(alpha: .9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      controller.message.isEmpty
                          ? 'Step into view'
                          : controller.message,
                      style: bodyText(
                        18,
                        color: SkyColors.white,
                        weight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 594,
          right: 28,
          top: 92,
          bottom: 36,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (error) ...[
                Expanded(
                  child: Panel(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.videocam_off_outlined,
                          size: 46,
                          color: SkyColors.coralDeep,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'A fresh start usually helps.',
                          style: heading(24),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Allow camera access in Settings. Close any other camera app, then try again.',
                          style: bodyText(15, color: SkyColors.muted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SkyButton(
                        label: 'Try again',
                        onPressed: () => controller.startCamera(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    RoundButton(
                      icon: Icons.settings_outlined,
                      label: 'Camera permission settings',
                      onPressed: controller.source!.openSettings,
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  ready
                      ? 'Try moving your bird.'
                      : widget.mode == PlayMode.pushUp
                      ? controller.body.step == BodyCalibrationStep.position
                            ? 'Find a comfortable top.'
                            : controller.body.step == BodyCalibrationStep.lower
                            ? 'Lower yourself slowly.'
                            : 'Push back up.'
                      : controller.face.neutral == null
                      ? 'Relax your face.'
                      : 'Now hold a smile.',
                  style: heading(27),
                ),
                const SizedBox(height: 8),
                Text(
                  ready
                      ? (widget.mode == PlayMode.pushUp
                            ? 'Push up to rise. Lower to glide.'
                            : 'Relax, then smile to flap.')
                      : (widget.mode == PlayMode.pushUp
                            ? 'Keep your shoulders, one arm and a hip in view. Move comfortably.'
                            : 'Keep your face centered for a moment.'),
                  style: bodyText(14, color: SkyColors.muted),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Panel(
                    padding: const EdgeInsets.all(12),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Pill(
                            ready
                                ? 'CONTROL CHECK'
                                : widget.mode == PlayMode.pushUp
                                ? '${controller.body.cycles} / 2 PUSH-UPS'
                                : '${controller.face.neutral == null ? 0 : 1} / 2 EXPRESSIONS',
                            color: ready ? SkyColors.mint : SkyColors.yellow,
                          ),
                        ),
                        Align(
                          alignment: Alignment(
                            -.45,
                            ready
                                ? .8 - controller.movement.height * 1.6
                                : widget.mode == PlayMode.pushUp
                                ? .8 - controller.body.previewHeight * 1.6
                                : 0,
                          ),
                          child: BirdArt(
                            bird: p.settings.bird,
                            size: 100,
                            bob: false,
                          ),
                        ),
                        if (!ready)
                          Positioned(
                            bottom: 4,
                            left: 0,
                            right: 0,
                            child: Text(
                              widget.mode == PlayMode.pushUp
                                  ? 'Learning your range as you move.'
                                  : 'Your bird moves after calibration.',
                              style: bodyText(12, color: SkyColors.muted),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        if (ready && widget.mode == PlayMode.smile)
                          Positioned(
                            bottom: 4,
                            left: 0,
                            right: 0,
                            child: Text(
                              controller.movement.flap
                                  ? 'Flap!'
                                  : controller.movement.feedback,
                              style: bodyText(12, color: SkyColors.muted),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (ready)
                  SizedBox(
                    width: double.infinity,
                    child: SkyButton(
                      label: 'Ready for takeoff',
                      onPressed: controller.fly,
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: SkyButton(
                      label: busy ? 'Starting…' : 'Start calibration again',
                      onPressed: busy ? null : () => controller.startCamera(),
                      color: SkyColors.cream,
                      icon: Icons.restart_alt_rounded,
                      busy: busy,
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  '${controller.metrics.hz.toStringAsFixed(0)} updates/s · ${controller.metrics.p95.toStringAsFixed(0)} ms p95${controller.metrics.sensorTimestamp ? '' : ' (processing only)'}',
                  style: bodyText(11, color: SkyColors.muted),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _flight() {
    final sim = controller.simulation!;
    final paused = sim.phase == RunPhase.paused;
    final goals = FlightGoals.forSimulation(sim);
    return Stack(
      fit: StackFit.expand,
      children: [
        if (controller.isTouch)
          Semantics(
            label: 'Tap to flap',
            button: true,
            onTap: controller.flap,
            child: Listener(
              key: const ValueKey('touch-flight'),
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) => controller.flap(),
              child: GameWidget(game: game!),
            ),
          )
        else
          GameWidget(game: game!),
        Positioned(
          left: 24,
          top: 20,
          child: Pill(
            widget.course.relaxed
                ? 'CLOUD CRUISE'
                : widget.practice
                ? '${widget.course.title.toUpperCase()} · PRACTICE'
                : widget.course == FlightCourse.starTrail
                ? 'STAR TRAIL'
                : widget.course == FlightCourse.skyCourier
                ? 'SKY COURIER'
                : widget.mode.title.toUpperCase(),
            icon: widget.practice
                ? Icons.spa_outlined
                : Icons.local_fire_department_outlined,
            color: SkyColors.cream,
          ),
        ),
        Positioned(
          top: 18,
          left: 400,
          right: 400,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 3),
              decoration: BoxDecoration(
                color: SkyColors.cream.withValues(alpha: .94),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(
                '${sim.score}',
                style: heading(48, weight: FontWeight.w700),
              ),
            ),
          ),
        ),
        if (sim.discoversClouds)
          Positioned(
            top: 18,
            left: 284,
            width: 120,
            child: CloudFriendsHud(friends: sim.cloudFriends),
          ),
        if (goals.isNotEmpty)
          Positioned(
            top: 18,
            left: 284,
            width: 120,
            child: FlightGoalHud(
              goals: goals,
              celebrating: sim.elapsed < wingCelebrationUntil,
              reducedMotion: controller.reducedMotion,
            ),
          ),
        Positioned(
          top: 20,
          right: 24,
          child: RoundButton(
            icon: widget.practice ? Icons.pause_rounded : Icons.stop_rounded,
            label: widget.practice ? 'Pause practice' : 'End scored flight',
            onPressed: controller.pause,
          ),
        ),
        if (!widget.practice && initialBest > 0)
          Positioned(
            top: 18,
            left: 600,
            width: 188,
            child: RecordChase(
              best: initialBest,
              score: sim.score,
              reducedMotion: controller.reducedMotion,
            ),
          ),
        Positioned(
          left: 24,
          bottom: 20,
          child: Pill(
            widget.mode == PlayMode.pushUp
                ? '${sim.repetitions} push-ups'
                : '${sim.flaps} flaps',
            icon: widget.mode == PlayMode.pushUp
                ? Icons.fitness_center_rounded
                : controller.isTouch
                ? Icons.touch_app_rounded
                : Icons.sentiment_satisfied_alt_rounded,
            color: SkyColors.cream,
          ),
        ),
        Positioned(
          right: 24,
          bottom: 20,
          child: Pill(
            controller.isTouch
                ? 'Tap anywhere to flap'
                : sim.trackingFresh(controller.nowMs)
                ? 'Tracking you'
                : 'Finding you…',
            icon: controller.isTouch
                ? Icons.touch_app_rounded
                : sim.trackingFresh(controller.nowMs)
                ? Icons.check_circle_outline
                : Icons.visibility_outlined,
            color: controller.isTouch || sim.trackingFresh(controller.nowMs)
                ? SkyColors.mint
                : SkyColors.yellow,
          ),
        ),
        Positioned(
          left: sim.isTrail ? null : 24,
          right: sim.isTrail ? 24 : null,
          top: sim.isTrail ? 76 : 66,
          child: Row(
            children: [
              if (sim.isTrail) ...[
                Semantics(
                  label: '${sim.hearts} hearts remaining',
                  child: Row(
                    children: [
                      for (var i = 0; i < 3; i++)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            i < sim.hearts
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: i < sim.hearts
                                ? SkyColors.coralDeep
                                : SkyColors.muted,
                            size: 22,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Pill(
                  sim.recoveryRemaining > 0
                      ? 'Recovering · ${sim.recoveryRemaining.toStringAsFixed(1)}s'
                      : sim.shield
                      ? 'Shield ready'
                      : '${sim.shieldCharge}/9 recharge',
                  icon: sim.shield
                      ? Icons.shield_rounded
                      : Icons.shield_outlined,
                  color: sim.shield ? SkyColors.mint : SkyColors.cream,
                ),
              ] else
                Pill(sim.regionName, color: SkyColors.cream),
            ],
          ),
        ),
        if (sim.timed)
          Positioned(
            top: 22,
            right: 86,
            child: Pill(
              '${sim.remainingSeconds.ceil()}s',
              icon: Icons.timer_outlined,
              color: sim.remainingSeconds <= 10
                  ? SkyColors.coral
                  : SkyColors.cream,
            ),
          ),
        if (sim.isCourier)
          Positioned(
            left: 300,
            right: 300,
            bottom: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Pill(
                  sim.carryingLetter
                      ? 'Letter aboard · find a postbox gate'
                      : 'Find a pickup gate to collect a letter',
                  icon: sim.carryingLetter
                      ? Icons.mark_email_read_outlined
                      : Icons.local_post_office_outlined,
                  color: sim.carryingLetter
                      ? SkyColors.yellow
                      : SkyColors.cream,
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: sim.elapsed / sim.course.duration,
                    minHeight: 5,
                    backgroundColor: SkyColors.white.withValues(alpha: .6),
                    valueColor: const AlwaysStoppedAnimation(SkyColors.teal),
                  ),
                ),
              ],
            ),
          ),
        if (sim.isTrail) ...[
          Positioned(
            top: 84,
            left: 400,
            right: 400,
            child: Center(
              child: Pill(
                '${sim.collectedStars} stars · ${sim.multiplier}×',
                icon: Icons.star_rounded,
                color: sim.multiplier > 1 ? SkyColors.yellow : SkyColors.cream,
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 320,
            right: 310,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Pill(
                  sim.magnetActive
                      ? 'Star magnet · ${sim.magnetRemaining.ceil()}s'
                      : sim.supportsMagnet && sim.magnetCharge > 0
                      ? '${sim.magnetCharge}/3 perfect gates · charging magnet'
                      : sim.combo == 0
                      ? 'Follow the stars. Find your streak.'
                      : '${sim.combo} in a row${sim.multiplier < 3 ? ' · ${6 - sim.combo % 6} to ${sim.multiplier + 1}×' : ' · MAX MULTIPLIER'}',
                  color: sim.magnetActive
                      ? SkyColors.lavender
                      : SkyColors.cream,
                  icon: sim.magnetActive ? Icons.auto_awesome_rounded : null,
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: sim.magnetActive
                        ? sim.magnetRemaining / FlightSimulation.magnetDuration
                        : sim.elapsed / FlightSimulation.trailDuration,
                    minHeight: 5,
                    backgroundColor: SkyColors.white.withValues(alpha: .6),
                    valueColor: AlwaysStoppedAnimation(
                      sim.magnetActive ? SkyColors.purple : SkyColors.teal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (sim.isCruise) ...[
          Positioned(
            top: 84,
            left: 360,
            right: 360,
            child: Center(
              child: Pill(
                '${sim.collectedStars} stars · ${sim.multiplier}×',
                icon: Icons.star_rounded,
                color: SkyColors.yellow,
              ),
            ),
          ),
          Positioned(
            bottom: 22,
            left: 300,
            right: 300,
            child: Center(
              child: Pill(
                sim.magnetActive
                    ? 'Star magnet · ${sim.magnetRemaining.ceil()}s'
                    : sim.supportsMagnet && sim.magnetCharge > 0
                    ? '${sim.magnetCharge}/3 perfect rings · charging magnet'
                    : sim.discoversClouds && sim.cloudFriends.length < 3
                    ? 'Fly close to meet a cloud friend.'
                    : 'Open sky. Move at your pace.',
                color: sim.magnetActive ? SkyColors.lavender : SkyColors.cream,
                icon: sim.magnetActive ? Icons.auto_awesome_rounded : null,
              ),
            ),
          ),
        ],
        if (sim.phase == RunPhase.countdown)
          Center(
            child: Panel(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    (controller.isTouch || sim.trackingFresh(controller.nowMs))
                        ? 'Ready, steady…'
                        : 'Find your position',
                    style: heading(28),
                  ),
                  Text(
                    (controller.isTouch || sim.trackingFresh(controller.nowMs))
                        ? '${sim.countdown.ceil().clamp(1, 3)}'
                        : '',
                    style: heading(84),
                  ),
                  Text(
                    (controller.isTouch || sim.trackingFresh(controller.nowMs))
                        ? (controller.isTouch
                              ? 'Tap to flap. Release between taps.'
                              : sim.isCruise
                              ? 'Breathe. Move. Follow the stars.'
                              : sim.isTrail
                              ? 'Follow the stars. Your shield is ready.'
                              : sim.isCourier
                              ? 'Pickup gate. Postbox gate. Make a delivery!'
                              : 'The sky is yours.')
                        : sim.trackingFeedback,
                    style: bodyText(16, color: SkyColors.muted),
                  ),
                ],
              ),
            ),
          ),
        if (paused)
          Container(
            color: SkyColors.ink.withValues(alpha: .25),
            child: Center(
              child: Panel(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Take a breather.', style: heading(38)),
                    const SizedBox(height: 12),
                    Text(
                      controller.isTouch
                          ? 'Ready for more? We’ll count you in.'
                          : 'Get back in position. We’ll count you in.',
                      style: bodyText(16, color: SkyColors.muted),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SkyButton(
                          label: 'Finish flight',
                          onPressed: controller.endFlight,
                          color: SkyColors.cream,
                          icon: Icons.flag_outlined,
                        ),
                        const SizedBox(width: 16),
                        SkyButton(
                          label: 'Keep flying',
                          onPressed: () => controller.resume(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _results(ProgressSnapshot p) {
    final r = controller.result!;
    final goals = FlightGoals.forRun(r);
    final newStamps = p.passport
        .where((p) => p.earned && !initialStamps.contains(p.stamp))
        .toList();
    final nextStamp = r.practice ? null : p.nextStamp;
    final newBirds =
        r.practice
              ? <int>[]
              : p.unlocked
                    .where((bird) => !initialBirds.contains(bird))
                    .toList()
          ..sort();
    final newBird = newBirds.isEmpty ? null : newBirds.first;
    final newDailyCard =
        !r.practice &&
        controller.saved &&
        p.today?.complete == true &&
        (initialDailyKey != p.today?.dayKey || !initialDailyComplete);
    final isBest = !r.practice && r.score > initialBest;
    final reason = switch (r.reason) {
      EndReason.collision => 'A little bump in the clouds.',
      EndReason.trackingLost => 'We lost sight of you for a moment.',
      EndReason.postureLost => 'Your position moved out of range.',
      EndReason.backgrounded => 'You stepped away from the sky.',
      EndReason.breakTaken => 'A well-earned breather.',
      EndReason.quit => 'Until the next adventure.',
      EndReason.stalled => 'The game was interrupted.',
      EndReason.completed =>
        r.course == FlightCourse.skyCourier
            ? 'Little letters. A sky full of joy.'
            : 'A whole sky of stars. All yours.',
    };
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          _header(
            widget.course.relaxed
                ? 'A little time among the clouds.'
                : widget.practice
                ? 'Practice makes a happy bird.'
                : 'Every flight counts.',
            trailing: Pill(
              isBest
                  ? 'NEW PERSONAL BEST!'
                  : widget.course.relaxed
                  ? 'CRUISE COMPLETE'
                  : widget.practice
                  ? 'PRACTICE COMPLETE'
                  : 'FLIGHT COMPLETE',
              icon: Icons.emoji_events_outlined,
              color: SkyColors.yellow,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FlightPortrait(
                        key: ValueKey(r.id),
                        bird: newBird ?? p.settings.bird,
                        reducedMotion: p.settings.reducedMotion,
                        arrivedCourse:
                            r.reason == EndReason.completed && r.course.timed
                            ? r.course
                            : null,
                        celebrate:
                            isBest ||
                            FlightGoals.earned(goals) == 3 ||
                            newBird != null ||
                            newDailyCard ||
                            (!r.practice &&
                                (newStamps.isNotEmpty ||
                                    r.reason == EndReason.completed)),
                      ),
                      Text(
                        newBird != null
                            ? 'Meet ${birdNames[newBird]}!'
                            : isBest
                            ? 'Look at you go!'
                            : r.reason == EndReason.completed
                            ? r.course == FlightCourse.skyCourier
                                  ? 'Welcome home!'
                                  : 'Trail complete!'
                            : 'Nice flying.',
                        style: heading(40),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        reason,
                        style: bodyText(16, color: SkyColors.muted),
                        textAlign: TextAlign.center,
                      ),
                      if (newBird != null) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => leave('/birds'),
                          icon: const Icon(
                            Icons.flutter_dash_rounded,
                            color: SkyColors.coralDeep,
                          ),
                          label: Text(
                            '${birdNames[newBird]} joined your flock!',
                            style: bodyText(13, weight: FontWeight.w900),
                          ),
                        ),
                      ] else if (newDailyCard) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => leave('/daily'),
                          icon: const Icon(
                            Icons.local_post_office_outlined,
                            color: SkyColors.teal,
                          ),
                          label: Text(
                            'Today’s postcard stamped!',
                            style: bodyText(13, weight: FontWeight.w900),
                          ),
                        ),
                      ] else if (!r.practice && newStamps.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => leave('/passport'),
                          icon: const Icon(
                            Icons.workspace_premium_rounded,
                            color: SkyColors.gold,
                          ),
                          label: Text(
                            'Stamp earned: ${newStamps.first.stamp.title}',
                            style: bodyText(13, weight: FontWeight.w900),
                          ),
                        ),
                      ] else if (controller.saved && nextStamp != null) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => leave('/passport'),
                          icon: const Icon(Icons.explore_outlined, size: 22),
                          label: Column(
                            children: [
                              Text(
                                'Next stamp: ${nextStamp.stamp.title} · ${nextStamp.current}/${nextStamp.stamp.target}',
                                style: bodyText(13, weight: FontWeight.w900),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                nextStamp.stamp.description,
                                style: bodyText(11, color: SkyColors.muted),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 26),
                Expanded(
                  flex: 5,
                  child: Panel(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                if (controller.simulation!.discoversClouds)
                                  CloudFriendsAlbum(
                                    friends:
                                        controller.simulation!.cloudFriends,
                                  ),
                                if (goals.isNotEmpty)
                                  TextButton(
                                    key: const ValueKey('result-flight-goals'),
                                    onPressed: () => showFlightGoals(
                                      context,
                                      r.course,
                                      progress: goals,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        FlightWings(goals: goals),
                                        const SizedBox(width: 10),
                                        Text(
                                          '${FlightGoals.earned(goals)}/3 flight wings',
                                          style: bodyText(
                                            13,
                                            weight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _stat(
                                        widget.course.scoreLabel,
                                        '${r.score}',
                                        large: true,
                                      ),
                                    ),
                                    Container(
                                      height: 70,
                                      width: 1,
                                      color: SkyColors.sand,
                                    ),
                                    Expanded(
                                      child: _stat(
                                        widget.course.relaxed
                                            ? 'STARS FOUND'
                                            : 'PERSONAL BEST',
                                        widget.course.relaxed
                                            ? '${r.stars}'
                                            : '${p.record(widget.mode, widget.course).best}',
                                        large: true,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _stat(
                                        widget.mode == PlayMode.pushUp
                                            ? 'PUSH-UPS'
                                            : 'FLAPS',
                                        '${widget.mode == PlayMode.pushUp ? r.repetitions : r.flaps}',
                                      ),
                                    ),
                                    Expanded(
                                      child: _stat(
                                        'FLIGHT TIME',
                                        '${r.durationSeconds.round()}s',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Pill(
                                      '${r.perfectPasses} perfect',
                                      icon: Icons.center_focus_strong_rounded,
                                      color: SkyColors.mint,
                                    ),
                                    const SizedBox(width: 8),
                                    if (r.course.collectsStars)
                                      Pill(
                                        '${r.bestCombo} best streak',
                                        icon: Icons.auto_awesome,
                                        color: SkyColors.yellow,
                                      )
                                    else if (r.course ==
                                        FlightCourse.skyCourier)
                                      Pill(
                                        '${r.gates} gates cleared',
                                        icon: Icons.local_post_office_outlined,
                                        color: SkyColors.yellow,
                                      )
                                    else if (r.score >= 5)
                                      Pill(
                                        r.score >= 25
                                            ? 'Sky captain'
                                            : r.score >= 10
                                            ? 'Cloud explorer'
                                            : 'First wings',
                                        icon: Icons.workspace_premium_outlined,
                                        color: SkyColors.yellow,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (controller.saveError.isNotEmpty)
                                  TextButton(
                                    onPressed: controller.persist,
                                    child: Text(
                                      controller.saveError,
                                      style: bodyText(
                                        13,
                                        color: SkyColors.coralDeep,
                                      ),
                                    ),
                                  )
                                else
                                  Text(
                                    r.practice
                                        ? 'Practice flights leave your records untouched.'
                                        : controller.saved
                                        ? 'Saved on this phone · ${p.totalObstacles} total gates'
                                        : 'Saving your flight…',
                                    style: bodyText(13, color: SkyColors.muted),
                                  ),
                                if (controller.sessionSaved)
                                  Text(
                                    'Session saved · Watch in Records',
                                    style: bodyText(12, color: SkyColors.teal),
                                  ),
                                if (controller.sessionError.isNotEmpty ||
                                    controller.cameraRecordingError.isNotEmpty)
                                  Text(
                                    controller.sessionError.isNotEmpty
                                        ? controller.sessionError
                                        : controller.cameraRecordingError,
                                    style: bodyText(
                                      11,
                                      color: SkyColors.coralDeep,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: SkyButton(
                                label: 'Home',
                                compact: true,
                                onPressed: leave,
                                color: SkyColors.cream,
                                icon: Icons.home_outlined,
                              ),
                            ),
                            if (controller.simulation?.started == true) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: SkyButton(
                                  key: const ValueKey('save-or-watch-session'),
                                  label: controller.sessionSaved
                                      ? 'Watch replay'
                                      : controller.preparingReplay
                                      ? 'Preparing…'
                                      : controller.sessionSaving
                                      ? 'Saving…'
                                      : 'Save session',
                                  compact: true,
                                  color: SkyColors.yellow,
                                  icon: null,
                                  busy:
                                      controller.preparingReplay ||
                                      controller.sessionSaving,
                                  onPressed: controller.sessionSaved
                                      ? () => leave('/replay/${r.id}')
                                      : controller.canSaveSession &&
                                            !controller.sessionSaving
                                      ? controller.persistSession
                                      : null,
                                ),
                              ),
                            ],
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: SkyButton(
                                label: 'Fly again',
                                compact: true,
                                onPressed: () => controller.retry(),
                                icon: Icons.replay_rounded,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, {bool large = false}) => Column(
    children: [
      Text(
        label,
        style: bodyText(12, color: SkyColors.muted, weight: FontWeight.w900),
      ),
      const SizedBox(height: 4),
      Text(value, style: heading(large ? 42 : 24)),
    ],
  );
}
