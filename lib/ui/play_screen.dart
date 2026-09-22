import '../domain/squat_tracking.dart';
import 'squat_setup_art.dart';
import 'jump_setup_art.dart';
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
import 'flight_score.dart';
import 'jump_glide_hud.dart';
import 'match_hud.dart';
import 'flight_goals.dart';
import 'cloud_friends.dart';
import 'ui_sounds.dart';

class PlayScreen extends ConsumerStatefulWidget {
  const PlayScreen({
    super.key,
    required this.mode,
    bool practice = false,
    this.course = FlightCourse.starTrail,
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
      previousStars = 0,
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
      previousStars = 0;
      previousPerfects = 0;
      previousMultiplier = 1;
      previousMagnets = 0;
      previousTrios = 0;
      previousLetters = 0;
      previousBumps = 0;
      previousWings = 0;
      previousCloudFriends = 0;
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
      } else if (sim.collectsStars
          ? sim.collectedStars > previousStars
          : sim.score > previousScore) {
        audio.effect(sim.collectsStars ? 'star' : 'point');
      }
      previousScore = sim.score;
      previousStars = sim.collectedStars;
      if (sim.courierBumps > previousBumps) audio.effect('bump');
      previousLetters = sim.lettersCollected;
      previousBumps = sim.courierBumps;
      previousWings = wings;
      previousCloudFriends = sim.cloudFriends.length;
      if (sim.isTrail && sim.hearts < previousHearts) audio.effect('bump');
      if (sim.isTrail && sim.hearts > previousHearts) audio.effect('heart');
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
          child: Stack(
            fit: StackFit.expand,
            children: [
              SceneLayout(
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
                    if (stage == PlayStage.results) _results(p),
                  ],
                ),
              ),
              if (stage == PlayStage.flying && game != null)
                Positioned.fill(child: _flight()),
            ],
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
                      Text(
                        widget.course.relaxed
                            ? 'A little tap. A lot of sky.'
                            : 'Flap. Aim. Fire!',
                        style: heading(32),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.course.relaxed
                            ? 'Tap anywhere in the sky to flap upward.\nRelease and tap again to keep flying.'
                            : 'Tap the sky to flap. Tap Shoot to fire at bats.\nHold Shoot for a bigger rock. Rapid fire drains ammo.\nSprint to smash bats and stone panels. Beware of bosses!',
                        style: bodyText(18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.course.subtitle,
                        style: bodyText(
                          15,
                          weight: FontWeight.w800,
                          color: SkyColors.ink,
                        ),
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
              : widget.mode == PlayMode.squat
              ? 'Feet planted. Wings open.'
              : 'Small jumps. Big wings.',
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
                            : CustomPaint(
                                size: const Size(
                                  double.infinity,
                                  double.infinity,
                                ),
                                painter: widget.mode == PlayMode.squat
                                    ? const SquatSetupArt()
                                    : const JumpSetupArt(),
                              ),
                      ),
                      Text(
                        widget.mode == PlayMode.pushUp
                            ? 'Make a little room to move.'
                            : 'Show your whole body.',
                        style: heading(25),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.mode == PlayMode.pushUp
                            ? 'Phone low. Show an arm and hip.\nFacing it? Keep both shoulders in view.'
                            : widget.mode == PlayMode.squat
                            ? 'Squat to descend. Stand to rise.\nKeep both feet on the floor.'
                            : 'Jump for a boost + 3s glide.\nLand before jumping again.',
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
                          : widget.mode == PlayMode.squat
                          ? 'Make room to squat'
                          : 'Make room to jump',
                      widget.mode == PlayMode.pushUp
                          ? 'Facing the phone? Show both shoulders, one arm and a hip.'
                          : 'Phone in landscape. Show your body and both feet.',
                    ),
                    _step(
                      '2',
                      widget.mode == PlayMode.pushUp
                          ? 'Find your movement range'
                          : widget.mode == PlayMode.squat
                          ? 'Find your comfortable squat'
                          : 'Stand tall and still',
                      widget.mode == PlayMode.pushUp
                          ? 'Find a comfortable top, then move down and up twice.'
                          : widget.mode == PlayMode.squat
                          ? 'Stand still, squat and hold briefly, then stand back up.'
                          : 'Hold still briefly. Then jump for a big boost.',
                    ),
                    _step(
                      '3',
                      widget.course.title,
                      widget.mode == PlayMode.jump &&
                              widget.course.collectsStars
                          ? 'Stars add 0.75s of glide, up to 5s. Collect trios for +5 points.'
                          : widget.course.instructions,
                    ),
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
        : widget.mode.controlsHeight
        ? 'Find your movement range.'
        : 'Stand tall and still.';
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
                      : widget.mode == PlayMode.squat
                      ? switch (controller.squat.step) {
                          SquatCalibrationStep.standing =>
                            'Stand tall and still.',
                          SquatCalibrationStep.lower => 'Squat comfortably.',
                          SquatCalibrationStep.rise => 'Stand back up.',
                          SquatCalibrationStep.complete =>
                            'You found your wings!',
                        }
                      : 'Stand tall and still.',
                  style: heading(27),
                ),
                const SizedBox(height: 8),
                Text(
                  ready
                      ? (widget.mode == PlayMode.pushUp
                            ? 'Push up to rise. Lower to glide.'
                            : widget.mode == PlayMode.squat
                            ? 'Squat to descend. Stand to rise.'
                            : 'Jump, then rest while your bird glides.')
                      : (widget.mode == PlayMode.pushUp
                            ? 'Keep your shoulders, one arm and a hip in view. Move comfortably.'
                            : 'Keep your shoulders, hips and both feet in view.'),
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
                                : '${((widget.mode == PlayMode.squat ? controller.squat.progress : controller.jump.progress) * 100).round()}% CALIBRATED',
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
                                : widget.mode == PlayMode.squat
                                ? .8 - controller.squat.previewHeight * 1.6
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
                              widget.mode.controlsHeight
                                  ? 'Learning your range as you move.'
                                  : 'Your bird moves after calibration.',
                              style: bodyText(12, color: SkyColors.muted),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        if (ready && widget.mode == PlayMode.jump)
                          Positioned(
                            bottom: 4,
                            left: 0,
                            right: 0,
                            child: Text(
                              controller.movement.flap
                                  ? 'Jump!'
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

  Widget _flightReadout({
    double? left,
    double? top,
    double? right,
    double? bottom,
    double? width,
    required Widget child,
  }) => Positioned(
    left: left,
    top: top,
    right: right,
    bottom: bottom,
    width: width,
    child: IgnorePointer(child: child),
  );

  Widget _flight() {
    final sim = controller.simulation!;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (controller.isTouch)
          Semantics(
            label: sim.boss == null
                ? 'Tap to flap'
                : 'Tap to flap. ${sim.boss!.name}: ${sim.boss!.hp} of ${sim.boss!.maxHp} health${sim.boss!.isMoth ? '. ${sim.boss!.shieldHint}' : ''}',
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
        // The sky fills the display; only controls use the safe, scaled layout.
        SceneLayout(child: _flightHud()),
      ],
    );
  }

  Widget _flightHud() {
    final sim = controller.simulation!;
    final paused = sim.phase == RunPhase.paused;
    final menu = MatchAction(
      symbol: widget.practice ? MatchSymbol.pause : MatchSymbol.stop,
      label: widget.practice ? 'Pause practice' : 'End scored flight',
      onPressed: () {
        UiSounds.effect(context, 'pause');
        controller.pause();
      },
      reducedMotion: controller.reducedMotion,
    );
    if (sim.bossCutscene && sim.phase == RunPhase.playing) {
      return Stack(children: [Positioned(top: 18, right: 24, child: menu)]);
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        if (sim.isTrail)
          _flightReadout(
            left: 24,
            top: 20,
            child: MatchHealth(
              key: const ValueKey('match-health'),
              hearts: sim.hearts,
              shield: sim.shield,
              charge: sim.shieldCharge,
              recovering: sim.recoveryRemaining > 0,
              reducedMotion: controller.reducedMotion,
            ),
          ),
        if (sim.boss == null)
          _flightReadout(
            top: 18,
            left: 380,
            right: 380,
            child: FlightScore(
              score: sim.score,
              multiplier: sim.collectsStars ? sim.multiplier : 1,
              symbol: sim.isCourier ? MatchSymbol.letter : MatchSymbol.star,
              reducedMotion: controller.reducedMotion,
            ),
          ),
        Positioned(top: 18, right: 24, child: menu),
        // Endless flights do not need a running clock or a pace readout.
        if (sim.timed)
          _flightReadout(
            top: 28,
            right: 112,
            child: MatchPlate(
              key: const ValueKey('flight-clock'),
              color: sim.remainingSeconds <= 10
                  ? SkyColors.coral
                  : SkyColors.cream,
              child: Semantics(
                label: '${sim.clockLabel} remaining',
                excludeSemantics: true,
                child: Text(sim.clockLabel, style: heading(24)),
              ),
            ),
          ),
        _flightReadout(
          left: 24,
          bottom: 24,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (sim.supportsJumpGlide) ...[
                JumpGlideHud(
                  simulation: sim,
                  reducedMotion: controller.reducedMotion,
                ),
                const SizedBox(width: 12),
              ],
              if (sim.supportsMagnet &&
                  (sim.magnetActive || sim.magnetCharge > 0))
                MatchPulse(
                  value: (sim.magnetActive, sim.magnetCharge),
                  reducedMotion: controller.reducedMotion,
                  child: MatchPlate(
                    color: sim.magnetActive
                        ? SkyColors.lavender
                        : SkyColors.cream,
                    child: MatchMeter(
                      key: const ValueKey('match-magnet'),
                      symbol: MatchSymbol.magnet,
                      value: sim.magnetActive
                          ? sim.magnetRemaining /
                                FlightSimulation.magnetDuration
                          : sim.magnetCharge / 3,
                      text: sim.magnetActive
                          ? '${sim.magnetRemaining.ceil()}s'
                          : null,
                      label: sim.magnetActive
                          ? 'Star magnet: ${sim.magnetRemaining.ceil()} seconds remaining'
                          : 'Magnet charging: ${sim.magnetCharge} of 3 perfect gates',
                      color: SkyColors.purple,
                    ),
                  ),
                ),
              if (sim.isCourier)
                MatchPulse(
                  value: sim.carryingLetter,
                  reducedMotion: controller.reducedMotion,
                  child: MatchPlate(
                    color: sim.carryingLetter
                        ? SkyColors.yellow
                        : SkyColors.cream,
                    child: Semantics(
                      label: sim.carryingLetter
                          ? 'Letter aboard. Find a postbox gate.'
                          : 'Find a pickup gate to collect a letter.',
                      excludeSemantics: true,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MatchIcon(
                            MatchSymbol.letter,
                            muted: !sim.carryingLetter,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            sim.carryingLetter ? 'Deliver' : 'Pick up',
                            style: heading(21),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (!controller.isTouch &&
            !sim.trackingFresh(controller.nowMs) &&
            sim.phase == RunPhase.playing)
          _flightReadout(
            right: 24,
            bottom: 24,
            child: const Pill(
              'Finding you…',
              icon: Icons.visibility_outlined,
              color: SkyColors.yellow,
            ),
          ),
        if (sim.supportsCombat)
          Positioned(
            right: 24,
            bottom: 24,
            child: MatchShotButton(
              key: const ValueKey('touch-shoot'),
              label: 'Shoot',
              reserve: sim.ammo,
              charge: sim.shotCharge,
              spend: sim.charging && !sim.outOfAmmo ? sim.shotCost : 0,
              hold: sim.fullHoldLeft,
              charging: sim.charging,
              empty: sim.outOfAmmo,
              onPress: sim.phase == RunPhase.playing
                  ? controller.startCharge
                  : null,
              onRelease: controller.shoot,
              reducedMotion: controller.reducedMotion,
            ),
          ),
        if (sim.supportsSprint)
          Positioned(
            right: 140,
            bottom: 34,
            child: MatchSprintButton(
              key: const ValueKey('touch-sprint'),
              label: 'Sprint',
              recharge: 1 - sim.sprintCooldownRemaining / Sprint.cooldown,
              burst: sim.sprintRemaining / Sprint.seconds,
              secondsLeft: sim.sprintCooldownRemaining.ceil(),
              onPressed: sim.canSprint ? controller.sprint : null,
              reducedMotion: controller.reducedMotion,
            ),
          ),
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
                              ? (sim.supportsCombat
                                    ? 'Tap the sky to flap. Hold Shoot to charge. Sprint to smash!'
                                    : 'Tap to flap. Release between taps.')
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
                          sound: 'resume',
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
                            r.reason == EndReason.completed &&
                                r.course.legacyTimed
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
                                            : widget.mode == PlayMode.squat
                                            ? 'SQUATS'
                                            : widget.mode == PlayMode.jump
                                            ? 'JUMPS'
                                            : 'FLAPS',
                                        '${widget.mode.controlsHeight ? r.repetitions : r.flaps}',
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
