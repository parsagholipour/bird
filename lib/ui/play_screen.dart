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
import '../domain/campaign.dart';
import '../domain/campaign_progress.dart';
import '../domain/game_rules.dart';
import '../domain/flight_goals.dart';
import '../domain/tracking.dart';
import '../game/audio.dart';
import '../game/bird_game.dart';
import '../game/knockout_art.dart';
import '../game/play_controller.dart';
import 'calibration_probe.dart' show LandmarkPainter;
import 'components.dart';
import 'theme.dart';
import 'setup_art.dart';
import 'flight_portrait.dart';
import 'flight_score.dart';
import 'jump_glide_hud.dart';
import 'match_hud.dart';
import 'level_hud.dart';
import 'flight_goals.dart';
import 'game_over_stage.dart';
import 'level_result.dart';
import 'ui_sounds.dart';

class PlayScreen extends ConsumerStatefulWidget {
  const PlayScreen({
    super.key,
    required this.mode,
    this.course = FlightCourse.starTrail,
    this.level,
  });
  final FlightCourse course;
  final PlayMode mode;

  /// The campaign level to fly (a scored touch Star Trail), or null for
  /// endless.
  final CampaignLevel? level;
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
      previousWings = 0,
      previousHearts = 3;
  double previousFlightTime = 0;
  bool previousShield = true;
  bool awardSoundPlayed = false;
  bool leaving = false;

  /// A campaign attempt is being ended from the pause card to fly again.
  bool restarting = false;

  /// The flight is ending on the way out (leaving mid-flight, or Retry from
  /// the pause card): its end is passed through, not shown as a result.
  bool passing = false;
  int initialBest = 0;

  /// The level's bests before this attempt, for its result's "New best".
  LevelRecord? initialRecord;
  Set<SkyStamp> initialStamps = {};
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
    controller = PlayController(
      mode: widget.mode,
      course: widget.course,
      level: widget.level,
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
      best: initialBest,
      voiceMemory: ref.read(flightVoiceMemoryProvider).asData?.value,
      rememberVoices: (memory) => ref
          .read(progressRepositoryProvider)
          .saveFlightVoices(memory.encode()),
    );
    // The memory is loaded long before a first flight; this covers the
    // rare cold start that flies before it arrives.
    if (!ref.read(flightVoiceMemoryProvider).hasValue) {
      unawaited(
        ref.read(flightVoiceMemoryProvider.future).then((memory) {
          if (mounted) controller.useVoiceMemory(memory);
        }, onError: (_) {}),
      );
    }
    controller.addListener(changed);
    unawaited(controller.verifyMicrophoneAccess());
    // A level's card was on the map, so its flight counts straight in.
    if (widget.level != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(controller.fly());
      });
    }
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
      previousWings = 0;
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
      initialDailyKey = progress?.today?.dayKey;
      initialDailyComplete = progress?.today?.complete ?? false;
      final level = widget.level;
      initialRecord = level == null
          ? null
          : progress?.campaign.record(level) ?? LevelRecord(levelId: level.id);
      game = BirdGame(
        simulation: sim,
        nowMs: () => controller.nowMs,
        bird: settings.bird,
        reducedMotion: settings.reducedMotion,
        onChanged: controller.tick,
        advance: controller.advance,
        knockout: () => controller.knockout,
        speech: () => controller.speech,
      );
    }
    if (sim != null) {
      // A level's collection marks take the place of flight wings, with
      // the same chime, and it never chases the endless record.
      final wings = controller.level == null
          ? FlightGoals.earned(FlightGoals.forSimulation(sim))
          : controller.level!.marks.reached(sim.collectedStars);
      final earnedWing = wings > previousWings;
      if (controller.level == null &&
          initialBest > 0 &&
          previousScore <= initialBest &&
          sim.score > initialBest) {
        audio.effect('record');
      } else if (earnedWing && sim.phase == RunPhase.playing) {
        audio.effect('wing');
      } else if (sim.magnetActivations > previousMagnets) {
        audio.effect('magnet');
      } else if (sim.collectsStars && sim.collectedStars > previousStars) {
        audio.effect('star');
      } else if (sim.multiplier > previousMultiplier) {
        audio.effect('streak');
      } else if (sim.perfectPasses > previousPerfects) {
        audio.effect('perfect');
      } else if (!sim.collectsStars && sim.score > previousScore) {
        audio.effect('point');
      }
      previousScore = sim.score;
      previousStars = sim.collectedStars;
      previousWings = wings;
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
        // A knockout's award chime waits for its game-over stage.
        controller.stage != PlayStage.fallen &&
        controller.result != null) {
      final progress = ref.read(progressProvider).asData?.value;
      if (progress != null &&
          (progress.passport.any(
                (p) => p.earned && !initialStamps.contains(p.stamp),
              ) ||
              (progress.today?.complete == true &&
                  (initialDailyKey != progress.today?.dayKey ||
                      !initialDailyComplete)))) {
        awardSoundPlayed = true;
        audio.effect('unlock');
      }
    }
    final flight = game;
    // A level's result brings its own courier on a cloud, so the frozen
    // finish keeps its line and scenery without the flight's bird.
    if (flight != null &&
        controller.stage == PlayStage.results &&
        widget.level != null &&
        controller.knockout == null) {
      flight.hideBird = true;
    }
    if (flight != null &&
        controller.stage == PlayStage.results &&
        (controller.knockout != null || widget.level != null) &&
        !flight.paused) {
      // The knockout's last frame (or a level's finish) holds still under
      // the stage; stop the loop once that frame has been painted.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            identical(game, flight) &&
            controller.stage == PlayStage.results) {
          flight.pauseEngine();
        }
      });
    }
    setState(() {});
  }

  /// Leaves the flight, saving an attempt in progress. A level goes back to
  /// the map unless told otherwise.
  Future<void> leave([String? destination]) async {
    if (leaving) return;
    leaving = true;
    passing = controller.stage == PlayStage.flying;
    await controller.exit();
    if (mounted) {
      context.go(destination ?? (widget.level == null ? '/' : '/campaign'));
    }
  }

  /// Ends a paused level attempt and flies it again at once. The attempt is
  /// saved like any other that stops short.
  Future<void> restart() async {
    if (restarting || leaving) return;
    restarting = passing = true;
    controller.endFlight();
    await controller.retry();
    restarting = passing = false;
    if (mounted) setState(() {});
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
    // A fatal bump keeps the frozen flight on screen for its knockout and
    // the game-over stage that follows; a level's result stages over it too.
    final knockedOut = controller.knockout != null && game != null;
    final level = widget.level;
    final levelResult =
        level != null && stage == PlayStage.results && !knockedOut;
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
                        stage != PlayStage.fallen &&
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
                    // A level counts straight in; its card was on the map.
                    if (stage == PlayStage.setup && level == null)
                      controller.isTouch ? _touchSetup() : _setup(p),
                    if (stage == PlayStage.starting ||
                        stage == PlayStage.calibration ||
                        stage == PlayStage.ready ||
                        stage == PlayStage.error)
                      _calibration(p),
                    if (stage == PlayStage.results &&
                        !knockedOut &&
                        level == null)
                      _results(p),
                  ],
                ),
              ),
              if (stage == PlayStage.flying && game != null ||
                  knockedOut &&
                      (stage == PlayStage.fallen ||
                          stage == PlayStage.results) ||
                  levelResult && game != null)
                Positioned.fill(child: _flight()),
              if (stage == PlayStage.fallen && knockedOut)
                Positioned.fill(child: _knockoutSkip()),
              if (stage == PlayStage.results && knockedOut)
                Positioned.fill(
                  child: GameOverStage(
                    controller: controller,
                    progress: p,
                    mode: widget.mode,
                    course: widget.course,
                    initialBest: initialBest,
                    initialStamps: initialStamps,
                    initialDailyKey: initialDailyKey,
                    initialDailyComplete: initialDailyComplete,
                    onLeave: leave,
                    splash: KnockoutArt.atSea(controller.simulation!),
                  ),
                ),
              if (levelResult && !passing)
                Positioned.fill(
                  child: LevelResultStage(
                    key: ValueKey(controller.result!.id),
                    controller: controller,
                    level: level,
                    progress: p,
                    before: initialRecord ?? LevelRecord(levelId: level.id),
                    initialStamps: initialStamps,
                    initialDailyKey: initialDailyKey,
                    initialDailyComplete: initialDailyComplete,
                    onLeave: leave,
                  ),
                ),
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
                      Text('Flap. Aim. Fire!', style: heading(32)),
                      const SizedBox(height: 12),
                      Text(
                        'Tap the sky to flap. Tap Shoot to fire at bats.\nHold Shoot for a bigger rock. Rapid fire drains ammo.\nSprint to smash bats and stone panels. Beware of bosses!',
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
                      SkyButton(
                        label: 'Start touch flight',
                        icon: Icons.touch_app_rounded,
                        color: SkyColors.mint,
                        onPressed: () => controller.fly(),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Scored flight · Pause any time · Separate touch records',
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
            '${widget.course.title.toUpperCase()} · SCORED',
            icon: Icons.emoji_events_outlined,
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
                      widget.course == FlightCourse.starTrail
                          ? 'Three hearts + a shield. You can pause any time.'
                          : 'A collision or losing your position ends a scored flight. You can pause any time.',
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
                : 'Tap to flap. ${sim.boss!.name}: ${sim.boss!.hp} of ${sim.boss!.maxHp} health${sim.boss!.isMoth
                      ? '. ${sim.boss!.shieldHint}'
                      : sim.boss!.isPirate
                      ? '. ${sim.boss!.tideHint}'
                      : sim.boss!.isDragon
                      ? '. ${sim.boss!.breathHint}'
                      : sim.boss!.isKingCoo
                      ? '. ${sim.boss!.cooHint}'
                      : sim.boss!.isGargoyle
                      ? '. ${sim.boss!.gargoyleHint}'
                      : sim.boss!.screeches
                      ? '. ${sim.boss!.screechHint}'
                      : ''}',
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
        if (controller.stage == PlayStage.flying)
          SceneLayout(child: _flightHud()),
      ],
    );
  }

  /// Taps during the knockout skip to the stage, but only once
  /// [KnockoutArt.skipAfter] has passed, so mashing cannot dismiss it.
  Widget _knockoutSkip() => Semantics(
    button: true,
    label: 'Skip to results',
    onTap: controller.skipKnockout,
    child: Listener(
      key: const ValueKey('knockout-skip'),
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => controller.skipKnockout(),
    ),
  );

  Widget _flightHud() {
    final sim = controller.simulation!;
    final paused = sim.phase == RunPhase.paused;
    const edge = MatchLayout.edge, gap = MatchLayout.gap;
    // Bottom faces sit a little higher so their lips clear the edge too.
    const bottom = edge + 6, shot = 96.0, sprint = 80.0;
    // The pause face shares the top row; its slop reaches into the corner so
    // the target stays over 48 dp on the smallest phones.
    const pauseSize = MatchLayout.height;
    final menu = Positioned(
      top: 0,
      right: 0,
      child: MatchAction(
        symbol: MatchSymbol.pause,
        label: 'Pause flight',
        onPressed: () {
          UiSounds.effect(context, 'pause');
          controller.pause();
        },
        reducedMotion: controller.reducedMotion,
        size: pauseSize,
        hitSlop: edge,
      ),
    );
    if (sim.bossCutscene && sim.phase == RunPhase.playing) {
      return Stack(children: [menu]);
    }
    final finalStretch = sim.remainingSeconds <= 10;
    final counting = controller.isTouch || sim.trackingFresh(controller.nowMs);
    final magnet =
        sim.supportsMagnet && (sim.magnetActive || sim.magnetCharge > 0);
    final level = controller.level;
    final hint = counting
        ? (controller.isTouch
              ? (level != null && !sim.offersShoot
                    ? 'Tap the sky to flap. Fly through the stars.'
                    : level != null && !sim.offersSprint
                    ? 'Tap the sky to flap. Hold Shoot to charge.'
                    : sim.supportsCombat
                    ? 'Tap the sky to flap. Hold Shoot to charge. Sprint to smash!'
                    : 'Tap to flap. Release between taps.')
              : sim.isTrail
              ? 'Follow the stars. Your shield is ready.'
              : 'The sky is yours.')
        : sim.trackingFeedback;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (sim.isTrail)
          _flightReadout(
            left: edge,
            top: edge,
            child: MatchHealth(
              key: const ValueKey('match-health'),
              hearts: sim.hearts,
              shield: sim.shield,
              charge: sim.shieldCharge,
              recovering: sim.recoveryRemaining > 0,
              reducedMotion: controller.reducedMotion,
            ),
          ),
        // The bird flies near x = 200, so the hero score keeps to the middle.
        // A level shows its stars and marks there instead, and its route
        // where a timed flight kept its clock, centred on the pause face.
        if (sim.boss == null && level != null) ...[
          _flightReadout(
            top: edge - 4,
            left: 300,
            right: 300,
            child: MatchLevelStars(
              key: const ValueKey('level-stars'),
              stars: sim.collectedStars,
              two: level.marks.two,
              three: level.marks.three,
              reducedMotion: controller.reducedMotion,
            ),
          ),
          _flightReadout(
            top: edge + (pauseSize - MatchRoute.plateHeight) / 2,
            right: edge + pauseSize + gap,
            child: MatchRoute(
              key: const ValueKey('level-route'),
              progress: sim.routeProgress,
              bird: controller.bird,
              boss: level.boss,
            ),
          ),
        ] else if (sim.boss == null)
          _flightReadout(
            top: edge - 4,
            left: 330,
            right: 330,
            child: FlightScore(
              score: sim.score,
              multiplier: sim.collectsStars ? sim.multiplier : 1,
              symbol: MatchSymbol.star,
              reducedMotion: controller.reducedMotion,
            ),
          ),
        menu,
        // Endless flights do not need a running clock or a pace readout.
        if (sim.timed)
          _flightReadout(
            top: edge,
            right: edge + pauseSize + gap,
            // The final ten seconds turn coral and tick with a pop.
            child: MatchPulse(
              value: finalStretch ? sim.clockLabel : '',
              reducedMotion: controller.reducedMotion,
              child: MatchPlate(
                key: const ValueKey('flight-clock'),
                color: finalStretch ? SkyColors.coral : SkyColors.cream,
                padding: const EdgeInsets.fromLTRB(9, 6, 12, 6),
                child: Semantics(
                  label: '${sim.clockLabel} remaining',
                  excludeSemantics: true,
                  child: SizedBox(
                    height: 44,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const MatchIcon(MatchSymbol.clock, size: 30),
                        const SizedBox(width: 5),
                        ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 44),
                          child: Text(
                            sim.clockLabel,
                            textAlign: TextAlign.center,
                            style:
                                matchDigits(
                                  28,
                                  color: finalStretch
                                      ? SkyColors.white
                                      : SkyColors.ink,
                                ).copyWith(
                                  shadows: finalStretch
                                      ? matchInkEdge(1.2)
                                      : null,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        // Powers stack upward from the corner, clear of the bird's column.
        _flightReadout(
          left: edge,
          bottom: bottom,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (magnet)
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
                      active: sim.magnetActive,
                      segments: sim.magnetActive ? 0 : 3,
                    ),
                  ),
                ),
              if (magnet && sim.supportsJumpGlide)
                const SizedBox(height: MatchLayout.stack),
              if (sim.supportsJumpGlide)
                JumpGlideHud(
                  simulation: sim,
                  reducedMotion: controller.reducedMotion,
                ),
            ],
          ),
        ),
        if (!controller.isTouch &&
            !sim.trackingFresh(controller.nowMs) &&
            sim.phase == RunPhase.playing)
          _flightReadout(
            right: edge,
            bottom: bottom,
            child: MatchPlate(
              color: SkyColors.yellow,
              padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
              child: SizedBox(
                height: 44,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const MatchIcon(MatchSymbol.eye, size: 36),
                    const SizedBox(width: 8),
                    Text(
                      'Finding you…',
                      style: heading(22, weight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
        // A level may hold Shoot and Sprint back; endless offers both. The
        // bird coasts through a boss level's victory glide without them.
        if (sim.offersShoot && !sim.victoryGlide)
          Positioned(
            right: edge,
            bottom: bottom,
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
              size: shot,
            ),
          ),
        if (sim.offersSprint && !sim.victoryGlide)
          Positioned(
            right: edge + shot + gap + 4,
            bottom: bottom + (shot - sprint) / 2,
            child: MatchSprintButton(
              key: const ValueKey('touch-sprint'),
              label: 'Sprint',
              recharge: 1 - sim.sprintCooldownRemaining / Sprint.cooldown,
              burst: sim.sprintRemaining / Sprint.seconds,
              secondsLeft: sim.sprintCooldownRemaining.ceil(),
              onPressed: sim.canSprint ? controller.sprint : null,
              reducedMotion: controller.reducedMotion,
              size: sprint,
            ),
          ),
        if (sim.phase == RunPhase.countdown)
          Center(
            child: MatchPlate(
              radius: 28,
              padding: const EdgeInsets.fromLTRB(32, 16, 32, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    counting ? 'Ready, steady…' : 'Find your position',
                    style: heading(28),
                  ),
                  const SizedBox(height: 12),
                  // Each number pops in once; while tracking is lost the
                  // badge looks for the player instead.
                  MatchPulse(
                    value: counting ? sim.countdown.ceil().clamp(1, 3) : 0,
                    reducedMotion: controller.reducedMotion,
                    child: SizedBox.square(
                      dimension: 92,
                      child: MatchPlate(
                        color: SkyColors.yellow,
                        padding: EdgeInsets.zero,
                        child: Center(
                          child: counting
                              ? Text(
                                  '${sim.countdown.ceil().clamp(1, 3)}',
                                  style: matchDigits(62),
                                )
                              : const MatchIcon(MatchSymbol.eye, size: 56),
                        ),
                      ),
                    ),
                  ),
                  if (hint.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      hint,
                      style: bodyText(16, color: SkyColors.muted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        if (paused)
          Container(
            color: SkyColors.ink.withValues(alpha: .35),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 34),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    MatchPlate(
                      radius: 28,
                      padding: const EdgeInsets.fromLTRB(36, 46, 36, 26),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Take a breather.', style: heading(38)),
                          const SizedBox(height: 10),
                          Text(
                            level != null
                                ? '${level.id} · ${level.name}. Ready for more?'
                                : controller.isTouch
                                ? 'Ready for more? We’ll count you in.'
                                : 'Get back in position. We’ll count you in.',
                            style: bodyText(16, color: SkyColors.muted),
                          ),
                          const SizedBox(height: 22),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // A level starts over or goes back to the map;
                              // either way the attempt is saved.
                              if (level != null) ...[
                                SkyButton(
                                  key: const ValueKey('pause-map'),
                                  label: 'Map',
                                  onPressed: () => leave('/campaign'),
                                  color: SkyColors.cream,
                                  icon: Icons.map_outlined,
                                ),
                                const SizedBox(width: 12),
                                SkyButton(
                                  key: const ValueKey('pause-retry'),
                                  label: 'Retry',
                                  onPressed: restart,
                                  color: SkyColors.cream,
                                  icon: Icons.replay_rounded,
                                ),
                              ] else
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
                    // The paused badge crowns the card.
                    const Positioned(
                      top: -34,
                      child: ExcludeSemantics(
                        child: SizedBox.square(
                          dimension: 68,
                          child: MatchPlate(
                            color: SkyColors.yellow,
                            padding: EdgeInsets.zero,
                            child: Center(
                              child: MatchIcon(MatchSymbol.pause, size: 34),
                            ),
                          ),
                        ),
                      ),
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
    final nextStamp = p.nextStamp;
    final newDailyCard =
        controller.saved &&
        p.today?.complete == true &&
        (initialDailyKey != p.today?.dayKey || !initialDailyComplete);
    final isBest = r.score > initialBest;
    final reason = switch (r.reason) {
      EndReason.collision => 'A little bump in the clouds.',
      EndReason.trackingLost => 'We lost sight of you for a moment.',
      EndReason.postureLost => 'Your position moved out of range.',
      EndReason.backgrounded => 'You stepped away from the sky.',
      EndReason.breakTaken => 'A well-earned breather.',
      EndReason.quit => 'Until the next adventure.',
      EndReason.stalled => 'The game was interrupted.',
      EndReason.completed => 'A whole sky of stars. All yours.',
    };
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          _header(
            'Every flight counts.',
            trailing: Pill(
              isBest ? 'NEW PERSONAL BEST!' : 'FLIGHT COMPLETE',
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
                        bird: p.settings.bird,
                        reducedMotion: p.settings.reducedMotion,
                        arrivedCourse:
                            r.reason == EndReason.completed &&
                                r.course.legacyTimed
                            ? r.course
                            : null,
                        celebrate:
                            isBest ||
                            FlightGoals.earned(goals) == 3 ||
                            newDailyCard ||
                            newStamps.isNotEmpty ||
                            r.reason == EndReason.completed,
                      ),
                      Text(
                        isBest
                            ? 'Look at you go!'
                            : r.reason == EndReason.completed
                            ? 'Trail complete!'
                            : 'Nice flying.',
                        style: heading(40),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        reason,
                        style: bodyText(16, color: SkyColors.muted),
                        textAlign: TextAlign.center,
                      ),
                      if (newDailyCard) ...[
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
                      ] else if (newStamps.isNotEmpty) ...[
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
                                        'PERSONAL BEST',
                                        '${p.record(widget.mode, widget.course).best}',
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
                                    controller.saved
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
