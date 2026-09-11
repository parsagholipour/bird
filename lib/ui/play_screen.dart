import 'dart:async';
import 'dart:io';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/providers.dart';
import '../data/progress_repository.dart';
import '../domain/game_rules.dart';
import '../domain/tracking.dart';
import '../game/audio.dart';
import '../game/bird_game.dart';
import '../game/play_controller.dart';
import '../tracking/native_tracking_source.dart';
import 'calibration_probe.dart' show LandmarkPainter;
import 'components.dart';
import 'theme.dart';

class PlayScreen extends ConsumerStatefulWidget {
  const PlayScreen({super.key, required this.mode, this.practice = false});
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
  int previousScore = 0, previousCount = 4;
  bool leaving = false;
  int initialBest = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    audio = SkyAudio();
    final settings =
        ref.read(progressProvider).asData?.value.settings ??
        const GameSettings();
    audio.configure(settings);
    initialBest =
        ref.read(progressProvider).asData?.value.record(widget.mode).best ?? 0;
    controller = PlayController(
      mode: widget.mode,
      practice: widget.practice,
      source: NativeTrackingSource(),
      audio: audio,
      saveRun: (run) => ref.read(progressProvider.notifier).save(run),
    );
    controller.addListener(changed);
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
      previousCount = 4;
      game = BirdGame(
        simulation: sim,
        nowMs: () => controller.source.nowMs,
        bird: settings.bird,
        reducedMotion: settings.reducedMotion,
        onChanged: controller.tick,
      );
    }
    if (sim != null) {
      if (sim.score > previousScore) {
        audio.effect('point');
        previousScore = sim.score;
      }
      final count = sim.countdown.ceil();
      if (sim.phase == RunPhase.countdown &&
          count != previousCount &&
          sim.hasTracking) {
        audio.effect('ready');
        previousCount = count;
      }
    }
    setState(() {});
  }

  Future<void> leave() async {
    if (leaving) return;
    leaving = true;
    await controller.exit();
    if (mounted) context.go('/');
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
                if (Platform.isAndroid &&
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
                if (stage == PlayStage.setup) _setup(p),
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
  Widget _setup(ProgressSnapshot p) => Padding(
    padding: const EdgeInsets.all(28),
    child: Column(
      children: [
        _header(
          widget.mode == PlayMode.pushUp
              ? 'A little setup. A lot of sky.'
              : 'Your smile has wings.',
          trailing: Pill(
            widget.practice ? 'PRACTICE FLIGHT' : 'SCORED FLIGHT',
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
                                painter: LandmarkPainter(
                                  null,
                                  false,
                                  PlayMode.pushUp,
                                ),
                              )
                            : const Center(child: BirdArt(bird: 1, size: 160)),
                      ),
                      Text(
                        widget.mode == PlayMode.pushUp
                            ? 'Side-on. Screen facing you.'
                            : 'Take a seat. Face the camera.',
                        style: heading(25),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.mode == PlayMode.pushUp
                            ? 'Prop the phone low, facing you or beside you.\nYour face can look down.'
                            : 'One smile gives one flap.\nRelax your face before the next one.',
                        style: bodyText(15, color: SkyColors.muted),
                        textAlign: TextAlign.center,
                      ),
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
                    const Pill(
                      'YOUR CAMERA STAYS ON THIS PHONE',
                      icon: Icons.shield_outlined,
                      color: SkyColors.cream,
                    ),
                    const SizedBox(height: 20),
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
                    _step(
                      '3',
                      'We’ll count you in',
                      'After calibration, a 3-second countdown starts the flight.',
                    ),
                    const Spacer(),
                    Text(
                      widget.practice
                          ? 'Practice can pause. It does not change records or unlocks.'
                          : 'A collision, a break or leaving the app ends a scored flight.',
                      style: bodyText(13, color: SkyColors.muted),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: SkyButton(
                        label: 'Set up my camera',
                        icon: Icons.camera_alt_outlined,
                        onPressed: () => controller.startCamera(),
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
  Widget _step(String number, String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
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
                      onPressed: controller.source.openSettings,
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
    return Stack(
      fit: StackFit.expand,
      children: [
        GameWidget(game: game!),
        Positioned(
          left: 24,
          top: 20,
          child: Pill(
            widget.practice
                ? 'PRACTICE'
                : widget.mode == PlayMode.pushUp
                ? 'PUSH-UP FLIGHT'
                : 'GRIN & GLIDE',
            icon: widget.practice
                ? Icons.spa_outlined
                : Icons.local_fire_department_outlined,
            color: SkyColors.cream,
          ),
        ),
        Positioned(
          top: 18,
          left: 430,
          right: 430,
          child: Center(
            child: Text(
              '${sim.score}',
              style: heading(64, weight: FontWeight.w700),
            ),
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
        Positioned(
          left: 24,
          bottom: 20,
          child: Pill(
            widget.mode == PlayMode.pushUp
                ? '${sim.repetitions} push-ups'
                : '${sim.flaps} flaps',
            icon: widget.mode == PlayMode.pushUp
                ? Icons.fitness_center_rounded
                : Icons.sentiment_satisfied_alt_rounded,
            color: SkyColors.cream,
          ),
        ),
        Positioned(
          right: 24,
          bottom: 20,
          child: Pill(
            sim.trackingFresh(controller.source.nowMs)
                ? 'Tracking you'
                : 'Finding you…',
            icon: sim.trackingFresh(controller.source.nowMs)
                ? Icons.check_circle_outline
                : Icons.visibility_outlined,
            color: sim.trackingFresh(controller.source.nowMs)
                ? SkyColors.mint
                : SkyColors.yellow,
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
                    sim.trackingFresh(controller.source.nowMs)
                        ? 'Ready, steady…'
                        : 'Find your position',
                    style: heading(28),
                  ),
                  Text(
                    sim.trackingFresh(controller.source.nowMs)
                        ? '${sim.countdown.ceil().clamp(1, 3)}'
                        : '',
                    style: heading(84),
                  ),
                  Text(
                    sim.trackingFresh(controller.source.nowMs)
                        ? 'The sky is yours.'
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
                      'Get back in position. We’ll count you in.',
                      style: bodyText(16, color: SkyColors.muted),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SkyButton(
                          label: 'Home',
                          onPressed: leave,
                          color: SkyColors.cream,
                          icon: Icons.home_outlined,
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
    final isBest = !r.practice && r.score > initialBest;
    final reason = switch (r.reason) {
      EndReason.collision => 'A little bump in the clouds.',
      EndReason.trackingLost => 'We lost sight of you for a moment.',
      EndReason.postureLost => 'Your position moved out of range.',
      EndReason.backgrounded => 'You stepped away from the sky.',
      EndReason.breakTaken => 'A well-earned breather.',
      EndReason.quit => 'Until the next adventure.',
      EndReason.stalled => 'The game was interrupted.',
    };
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          _header(
            widget.practice
                ? 'Practice makes a happy bird.'
                : 'Every flight counts.',
            trailing: Pill(
              isBest
                  ? 'NEW PERSONAL BEST!'
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
                      BirdArt(
                        bird: p.settings.bird,
                        size: 190,
                        reducedMotion: p.settings.reducedMotion,
                      ),
                      Text(
                        isBest ? 'Look at you go!' : 'Nice flying.',
                        style: heading(40),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        reason,
                        style: bodyText(16, color: SkyColors.muted),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 26),
                Expanded(
                  flex: 5,
                  child: Panel(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _stat(
                                'OBSTACLES',
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
                                'PERSONAL BEST',
                                '${p.record(widget.mode).best}',
                                large: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
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
                        const Spacer(),
                        if (controller.saveError.isNotEmpty)
                          TextButton(
                            onPressed: controller.persist,
                            child: Text(
                              controller.saveError,
                              style: bodyText(13, color: SkyColors.coralDeep),
                            ),
                          )
                        else
                          Text(
                            r.practice
                                ? 'Practice flights leave your records untouched.'
                                : controller.saved
                                ? 'Saved on this phone · ${p.totalObstacles} total obstacles'
                                : 'Saving your flight…',
                            style: bodyText(13, color: SkyColors.muted),
                          ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: SkyButton(
                                label: 'Home',
                                onPressed: leave,
                                color: SkyColors.cream,
                                icon: Icons.home_outlined,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: SkyButton(
                                label: 'Fly again',
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
      Text(value, style: heading(large ? 58 : 28)),
    ],
  );
}
