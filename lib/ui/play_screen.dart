import '../domain/squat_tracking.dart';

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
import '../game/finish_celebration_art.dart';
import '../game/finish_gate_art.dart';
import '../game/knockout_art.dart';
import '../game/neferhoo_fight_art.dart';
import '../game/play_controller.dart';
import 'calibration_probe.dart' show LandmarkPainter;
import 'mini_calibration.dart';
import 'components.dart';
import 'theme.dart';
import 'mini_setup.dart';
import 'flight_score.dart';
import 'jump_glide_hud.dart';
import 'match_hud.dart';
import 'home_keys.dart' show HomeKeyColors;
import 'mini_chrome.dart';
import 'level_hud.dart';
import 'game_over_stage.dart';
import 'level_result.dart';
import 'mini_results.dart';
import 'pause_card.dart';
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

  /// Seconds to the finish line on the last change, for the "almost there"
  /// sting.
  double? previousToGo;
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

  /// Whether the level after this one was open before the flight (a finished
  /// level stays open, so a returning player may have it already).
  bool initialNextOpen = false;
  Set<SkyStamp> initialStamps = {};
  String? initialDailyKey;
  bool initialDailyComplete = false;

  /// A campaign level flies to its region's song; endless keeps the flight's.
  SkyMusic get music => SkyMusic.flightOver(widget.level?.region);

  /// The safe area the result stage's layout keeps, for where its courier
  /// sits.
  EdgeInsets _safe = EdgeInsets.zero;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    audio = ref.read(audioFactoryProvider)();
    final settings =
        ref.read(progressProvider).asData?.value.settings ??
        const GameSettings();
    audio.configure(settings, track: music);
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
      upgrades:
          ref.read(progressProvider).asData?.value.upgrades ?? const PowerUps(),
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
    // Touch flights count straight in; only camera modes need setup.
    if (controller.isTouch) {
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
      previousToGo = null;
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
      final next = level == null ? null : Campaign.after(level);
      initialNextOpen =
          next != null && (progress?.campaign.unlocked(next) ?? false);
      game = BirdGame(
        simulation: sim,
        nowMs: () => controller.nowMs,
        bird: settings.bird,
        reducedMotion: settings.reducedMotion,
        onChanged: controller.tick,
        advance: controller.advance,
        knockout: () => controller.knockout,
        finish: () => controller.celebration,
        // The celebrating bird lands where the result's courier sits.
        seat: widget.level == null
            ? null
            : (size) => LevelResultStage.courierSeat(size, _safe),
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
      // The finish gate's lights flick on with an "almost there" sting.
      final toGo = FinishGateArt.toGo(sim);
      const lights = FinishGateArt.lightsAt;
      if (toGo != null &&
          sim.phase == RunPhase.playing &&
          (previousToGo ?? double.infinity) > lights &&
          toGo <= lights) {
        audio.effect('finish_near');
      }
      previousToGo = toGo;
      final count = sim.countdown.ceil();
      if (sim.phase == RunPhase.countdown &&
          count > 0 &&
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
    // finish keeps its line and scenery without the flight's bird. A bird
    // that celebrated all the way into the courier's seat leaves on its own
    // (the calm one fades as the stage fades in) before it is put away.
    if (flight != null &&
        controller.stage == PlayStage.results &&
        widget.level != null &&
        controller.knockout == null &&
        (!controller.handedOff || controller.celebrationSettled)) {
      flight.hideBird = true;
    }
    if (flight != null &&
        controller.stage == PlayStage.results &&
        (controller.knockout != null || widget.level != null) &&
        controller.celebrationSettled &&
        !flight.paused) {
      // The knockout's last frame (or a level's settled finish) holds still
      // under the stage; stop the loop once that frame has been painted.
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
        track: music,
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
    _safe = MediaQuery.paddingOf(context);
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
        if (didPop) return;
        // Back during a level's celebration goes on to its result.
        if (controller.stage == PlayStage.celebrating) {
          controller.endCelebration();
        } else {
          unawaited(leave());
        }
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
                    if (stage == PlayStage.setup && !controller.isTouch)
                      _setup(p),
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
              if ((stage == PlayStage.flying ||
                          stage == PlayStage.celebrating) &&
                      game != null ||
                  knockedOut &&
                      (stage == PlayStage.fallen ||
                          stage == PlayStage.results) ||
                  levelResult && game != null)
                Positioned.fill(child: _flight()),
              if (stage == PlayStage.fallen && knockedOut)
                Positioned.fill(child: _knockoutSkip()),
              if (stage == PlayStage.celebrating && game != null)
                Positioned.fill(child: _celebrationSkip()),
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
                    nextWasOpen: initialNextOpen,
                    initialStamps: initialStamps,
                    initialDailyKey: initialDailyKey,
                    initialDailyComplete: initialDailyComplete,
                    onLeave: leave,
                    handoff: controller.handedOff,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(String title, {List<Widget> trailing = const []}) =>
      MiniHeader(title: title, onBack: leave, trailing: trailing);

  Widget _setup(ProgressSnapshot p) {
    final mode = widget.mode;
    final color = miniColor(mode);
    final pushUp = mode == PlayMode.pushUp, squat = mode == PlayMode.squat;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 20),
      child: Column(
        children: [
          _header(
            pushUp
                ? 'A little setup. A lot of sky.'
                : squat
                ? 'Feet planted. Wings open.'
                : 'Small jumps. Big wings.',
            trailing: [
              MiniTag(
                '${widget.course.title.toUpperCase()} · SCORED',
                icon: widget.course.collectsStars
                    ? Icons.star_rounded
                    : Icons.emoji_events_rounded,
                color: SkyColors.yellow,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: MiniCard(
                    accent: color,
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        // The picker's scene for this workout, grown into a
                        // hero: the phone watching, you moving, the bird
                        // answering.
                        Expanded(
                          child: SetupHero(
                            mode: mode,
                            color: color,
                            bird: p.settings.bird,
                            reducedMotion: controller.reducedMotion,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                          child: Column(
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  pushUp
                                      ? 'Make a little room to move.'
                                      : 'Show your whole body.',
                                  style: heading(23, weight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                pushUp
                                    ? 'Phone low. Show an arm and hip.\nFacing it? Keep both shoulders in view.'
                                    : squat
                                    ? 'Squat to descend. Stand to rise.\nKeep both feet on the floor.'
                                    : 'Jump for a boost + 3s glide.\nLand before jumping again.',
                                style: bodyText(
                                  13.5,
                                  color: SkyColors.muted,
                                  weight: FontWeight.w600,
                                ).copyWith(height: 1.3),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 9),
                              _microphoneOption(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 22),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: MiniCard(
                          accent: color,
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.flight_takeoff_rounded,
                                    size: 15,
                                    color: Color.lerp(
                                      color,
                                      SkyColors.ink,
                                      .45,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'HOW TO FLY',
                                    style: bodyText(
                                      12,
                                      weight: FontWeight.w900,
                                      color: SkyColors.muted,
                                    ).copyWith(letterSpacing: 1.4),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Long course notes or large text shrink the
                              // steps to fit rather than spill out of the card.
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, box) => FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.topLeft,
                                    child: SizedBox(
                                      width: box.maxWidth,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _step(
                                            '1',
                                            pushUp
                                                ? 'Show your arm and hip'
                                                : squat
                                                ? 'Make room to squat'
                                                : 'Make room to jump',
                                            pushUp
                                                ? 'Facing the phone? Show both shoulders, one arm and a hip.'
                                                : 'Phone in landscape. Show your body and both feet.',
                                          ),
                                          _step(
                                            '2',
                                            pushUp
                                                ? 'Find your movement range'
                                                : squat
                                                ? 'Find your comfortable squat'
                                                : 'Stand tall and still',
                                            pushUp
                                                ? 'Find a comfortable top, then move down and up twice.'
                                                : squat
                                                ? 'Stand still, squat and hold briefly, then stand back up.'
                                                : 'Hold still briefly. Then jump for a big boost.',
                                          ),
                                          _step(
                                            '3',
                                            widget.course.title,
                                            mode == PlayMode.jump &&
                                                    widget.course.collectsStars
                                                ? 'Stars add 0.75s of glide, up to 5s. Collect trios for +5 points.'
                                                : widget.course.instructions,
                                            last: true,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              SetupLives(
                                hearts: widget.course == FlightCourse.starTrail,
                                text: widget.course == FlightCourse.starTrail
                                    ? 'Three hearts + a shield. You can pause any time.'
                                    : 'A collision or losing your position ends a scored flight. You can pause any time.',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      MiniKey(
                        label: 'Set up my camera',
                        icon: Icons.camera_alt_rounded,
                        colors: miniKeyColors(mode),
                        size: 22,
                        onPressed: controller.microphoneRequestPending
                            ? null
                            : () => controller.startCamera(),
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
  }

  /// The optional microphone, as a toggle tile: a badge that lights up when
  /// replays will carry sound, the switch at the far end.
  Widget _microphoneOption() {
    final on = controller.recordAudio;
    return AnimatedContainer(
      duration:
          MediaQuery.disableAnimationsOf(context) || controller.reducedMotion
          ? Duration.zero
          : const Duration(milliseconds: 180),
      padding: const EdgeInsets.fromLTRB(8, 5, 4, 5),
      decoration: BoxDecoration(
        color: on
            ? Color.lerp(SkyColors.mint, SkyColors.cream, .55)
            : SkyColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: on ? SkyColors.teal : SkyColors.ink.withValues(alpha: .2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SetupMicBadge(on: on),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: 'Record microphone',
                        children: [
                          TextSpan(
                            text: on ? ' · On' : ' · Optional',
                            style: bodyText(
                              12.5,
                              color: on ? SkyColors.teal : SkyColors.muted,
                              weight: on ? FontWeight.w900 : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bodyText(13.5, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      controller.microphoneMessage.isEmpty
                          ? 'Add your voice and room sound to replays. Uses the microphone during flight only. Saved on this phone.'
                          : controller.microphoneMessage,
                      style: bodyText(
                        10.5,
                        color: SkyColors.muted,
                      ).copyWith(height: 1.25),
                    ),
                  ],
                ),
              ),
              Semantics(
                label: 'Record microphone for replays',
                child: Switch(
                  value: on,
                  activeTrackColor: SkyColors.teal,
                  activeThumbColor: SkyColors.white,
                  inactiveTrackColor: SkyColors.cream,
                  inactiveThumbColor: SkyColors.muted,
                  trackOutlineColor: WidgetStatePropertyAll(
                    on ? SkyColors.ink : SkyColors.ink.withValues(alpha: .5),
                  ),
                  onChanged: controller.microphoneRequestPending
                      ? null
                      : controller.setRecordAudio,
                ),
              ),
            ],
          ),
          if (controller.microphoneSettingsAvailable)
            Padding(
              padding: const EdgeInsets.only(left: 38),
              child: TextButton.icon(
                onPressed: controller.source!.openSettings,
                icon: const Icon(Icons.settings_rounded, size: 16),
                label: const Text('Microphone settings'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _step(
    String number,
    String title,
    String subtitle, {
    bool last = false,
  }) => SetupStep(
    number: number,
    title: title,
    subtitle: subtitle,
    color: miniColor(widget.mode),
    last: last,
  );
  Widget _calibration(ProgressSnapshot p) {
    final ready = controller.stage == PlayStage.ready,
        busy = controller.stage == PlayStage.starting,
        error = controller.stage == PlayStage.error;
    final mode = widget.mode, accent = miniColor(mode);
    final still = p.settings.reducedMotion;
    final title = ready
        ? 'You found your wings!'
        : busy
        ? 'Waking up your camera…'
        : error
        ? 'Let’s reconnect your camera.'
        : mode.controlsHeight
        ? 'Find your movement range.'
        : 'Stand tall and still.';
    final camera = busy
        ? CameraState.starting
        : error
        ? CameraState.offline
        : ready
        ? CameraState.ready
        : CameraState.live;
    final body = controller.body, squat = controller.squat;
    final (step, stepTitle) = ready
        ? (3, 'Try moving your bird.')
        : mode == PlayMode.pushUp
        ? switch (body.step) {
            BodyCalibrationStep.position => (1, 'Find a comfortable top.'),
            BodyCalibrationStep.lower => (2, 'Lower yourself slowly.'),
            _ => (3, 'Push back up.'),
          }
        : mode == PlayMode.squat
        ? switch (squat.step) {
            SquatCalibrationStep.standing => (1, 'Stand tall and still.'),
            SquatCalibrationStep.lower => (2, 'Squat comfortably.'),
            SquatCalibrationStep.rise => (3, 'Stand back up.'),
            SquatCalibrationStep.complete => (3, 'You found your wings!'),
          }
        : (1, 'Stand tall and still.');
    // Push-ups fill half the meter each, a little more as each one goes down
    // and comes back up; squats a third per step; jumps over the still hold.
    final (segments, progress) = switch (mode) {
      PlayMode.pushUp => (
        2,
        (body.cycles +
                switch (body.step) {
                  BodyCalibrationStep.lower => .35,
                  BodyCalibrationStep.raise => .7,
                  _ => 0.0,
                }) /
            2,
      ),
      PlayMode.squat => (3, squat.progress),
      _ => (4, controller.jump.progress),
    };
    // The way back when the camera will not start: what usually fixes it,
    // then Try again and a shortcut to the camera permission.
    final trouble = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: MiniCard(
            accent: SkyColors.coral,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: LayoutBuilder(
              builder: (context, box) => FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: box.maxWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Color.lerp(
                            SkyColors.coral,
                            SkyColors.cream,
                            .55,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: SkyColors.ink, width: 2.5),
                          boxShadow: const [
                            BoxShadow(
                              color: SkyColors.ink,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.videocam_off_rounded,
                          size: 30,
                          color: SkyColors.coralDeep,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'A fresh start usually helps.',
                        style: heading(23, weight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const CalibrationTip(
                        icon: Icons.lock_open_rounded,
                        text: 'Allow camera access in Settings.',
                      ),
                      const SizedBox(height: 10),
                      const CalibrationTip(
                        icon: Icons.apps_rounded,
                        text: 'Close any other camera app, then try again.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MiniKey(
                label: 'Try again',
                icon: Icons.refresh_rounded,
                colors: miniKeyColors(mode),
                height: 58,
                size: 20,
                onPressed: () => controller.startCamera(),
              ),
            ),
            const SizedBox(width: 12),
            MiniRoundKey(
              icon: Icons.settings_rounded,
              label: 'Camera permission settings',
              onPressed: controller.source!.openSettings,
            ),
          ],
        ),
      ],
    );
    // The step at hand, the bird following the player in its little sky, a
    // meter for how far calibration has come, and the way on.
    final guide = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CalibrationStepTitle(
          title: stepTitle,
          step: step,
          accent: accent,
          done: ready,
        ),
        const SizedBox(height: 6),
        Text(
          ready
              ? (mode == PlayMode.pushUp
                    ? 'Push up to rise. Lower to glide.'
                    : mode == PlayMode.squat
                    ? 'Squat to descend. Stand to rise.'
                    : 'Jump, then rest while your bird glides.')
              : (mode == PlayMode.pushUp
                    ? 'Keep your shoulders, one arm and a hip in view. Move comfortably.'
                    : 'Keep your shoulders, hips and both feet in view.'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: bodyText(13.5, color: SkyColors.ink, weight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: MiniCard(
            accent: ready ? SkyColors.mint : accent,
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: CalibrationPreview(
                    bird: p.settings.bird,
                    color: ready ? SkyColors.mint : accent,
                    still: still,
                    height: ready
                        ? controller.movement.height
                        : mode == PlayMode.pushUp
                        ? body.previewHeight
                        : mode == PlayMode.squat
                        ? squat.previewHeight
                        : .5,
                    caption: !ready
                        ? (mode.controlsHeight
                              ? 'Learning your range as you move.'
                              : 'Your bird moves after calibration.')
                        : mode == PlayMode.jump
                        ? (controller.movement.flap
                              ? 'Jump!'
                              : controller.movement.feedback)
                        : null,
                  ),
                ),
                DecoratedBox(
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: SkyColors.ink, width: 2),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 9, 10, 9),
                    child: Row(
                      children: [
                        Expanded(
                          child: CalibrationMeter(
                            value: ready ? 1 : progress,
                            segments: segments,
                            color: ready ? const Color(0xff69c893) : accent,
                            still: still,
                          ),
                        ),
                        const SizedBox(width: 12),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: MiniTag(
                            ready
                                ? 'CONTROL CHECK'
                                : mode == PlayMode.pushUp
                                ? '${body.cycles} / 2 PUSH-UPS'
                                : '${((mode == PlayMode.squat ? squat.progress : controller.jump.progress) * 100).round()}% CALIBRATED',
                            color: ready ? SkyColors.mint : SkyColors.yellow,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (ready)
          MiniKey(
            label: 'Ready for takeoff',
            icon: Icons.flight_takeoff_rounded,
            colors: miniKeyColors(mode),
            height: 58,
            size: 20,
            onPressed: controller.fly,
          )
        else
          MiniKey(
            label: busy ? 'Starting…' : 'Start calibration again',
            onPressed: busy ? null : () => controller.startCamera(),
            colors: HomeKeyColors.paper,
            icon: Icons.restart_alt_rounded,
            height: 58,
            size: 19,
            busy: busy,
          ),
        const SizedBox(height: 5),
        CalibrationMetrics(
          '${controller.metrics.hz.toStringAsFixed(0)} updates/s · ${controller.metrics.p95.toStringAsFixed(0)} ms p95${controller.metrics.sensorTimestamp ? '' : ' (processing only)'}',
        ),
      ],
    );
    return Stack(
      children: [
        Positioned(
          left: 28,
          right: 28,
          top: 24,
          child: _header(
            title,
            trailing: [
              MiniTag(
                ready
                    ? 'READY'
                    : busy
                    ? 'STARTING'
                    : error
                    ? 'CAMERA OFF'
                    : 'CALIBRATING',
                icon: ready
                    ? Icons.check_circle_rounded
                    : error
                    ? Icons.videocam_off_rounded
                    : Icons.center_focus_strong_rounded,
                color: ready
                    ? SkyColors.mint
                    : error
                    ? Color.lerp(SkyColors.coral, SkyColors.cream, .5)!
                    : SkyColors.cream,
              ),
              MiniRoundKey(
                icon: Icons.cameraswitch_rounded,
                label: 'Switch camera',
                onPressed: busy ? null : controller.switchCamera,
              ),
            ],
          ),
        ),
        // The camera window keeps the live preview's exact box; its frame
        // paints outside it, and only small marks sit over the picture.
        Positioned(
          left: 28,
          top: 92,
          width: 540,
          height: 322,
          child: CameraBezel(
            accent: accent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (busy || error)
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          radius: 1.1,
                          colors: [Color(0xff2b4b56), SkyColors.night],
                        ),
                      ),
                    ),
                  // While the camera wakes, its lens has the window to
                  // itself; the pose guide returns once it is watching.
                  if (!busy)
                    IgnorePointer(
                      child: CustomPaint(
                        painter: LandmarkPainter(
                          controller.latest,
                          controller.front,
                          mode,
                        ),
                      ),
                    ),
                  ViewfinderCorners(
                    color: switch (camera) {
                      CameraState.starting => SkyColors.yellow,
                      CameraState.live => SkyColors.cream,
                      CameraState.ready => const Color(0xff7fe0a8),
                      CameraState.offline => SkyColors.coral,
                    },
                  ),
                  if (busy)
                    Align(
                      alignment: const Alignment(0, -.3),
                      child: WakingLens(accent: SkyColors.yellow, still: still),
                    ),
                  if (error)
                    const Align(
                      alignment: Alignment(0, -.45),
                      child: SleepyCamera(size: 132),
                    ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 14,
                    child: CalibrationNote(
                      text: controller.message.isEmpty
                          ? 'Step into view'
                          : controller.message,
                      icon: busy
                          ? Icons.hourglass_top_rounded
                          : error
                          ? Icons.videocam_off_rounded
                          : ready
                          ? Icons.flight_rounded
                          : Icons.accessibility_new_rounded,
                      accent: error
                          ? SkyColors.coral
                          : ready
                          ? SkyColors.mint
                          : accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // The badge sits on the frame's top edge, like a camera's notch.
        Positioned(
          left: 28,
          width: 540,
          top: 92 - CameraBezel.width - 6,
          child: Center(
            child: CameraBadge(state: camera, still: still),
          ),
        ),
        Positioned(
          left: 594,
          right: 28,
          top: 92,
          bottom: 36,
          child: error ? trouble : guide,
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
                ? sim.vanguardFlying
                      ? 'Tap to flap. ${sim.vanguard!.title.toLowerCase()} '
                            'fly in ahead of their boss'
                      : 'Tap to flap'
                : 'Tap to flap. ${sim.boss!.name}: ${sim.boss!.hp} of ${sim.boss!.maxHp} health${sim.boss!.stageHint != null
                      ? '. ${sim.boss!.stageHint}'
                      : sim.boss!.isMoth
                      ? '. ${sim.boss!.shieldHint}'
                      : sim.boss!.isPirate
                      ? '. ${sim.boss!.tideHint}'
                      : sim.boss!.isDragon
                      ? '. ${sim.boss!.breathHint}'
                      : sim.boss!.isKingCoo
                      ? '. ${sim.boss!.cooHint}'
                      : sim.boss!.isGargoyle
                      ? '. ${sim.boss!.gargoyleHint}'
                      : sim.boss!.isNeferhoo
                      ? '. ${sim.boss!.neferhooHint}'
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
        // The HUD fades out as a level's celebration takes the screen.
        if (controller.stage == PlayStage.flying ||
            controller.stage == PlayStage.celebrating)
          IgnorePointer(
            ignoring: controller.stage != PlayStage.flying,
            child: Opacity(
              opacity: controller.stage == PlayStage.flying
                  ? 1
                  : FinishCelebrationArt.hudOpacity(
                      controller.celebration ?? 0,
                      reducedMotion: controller.reducedMotion,
                    ),
              child: SceneLayout(child: _flightHud()),
            ),
          ),
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

  /// Taps during a level's celebration skip to its result, but only once
  /// [FinishCelebrationArt.skipAfter] has passed, so flapping on through the
  /// line cannot dismiss it.
  Widget _celebrationSkip() => Semantics(
    button: true,
    label: 'Skip to results',
    onTap: controller.skipCelebration,
    child: Listener(
      key: const ValueKey('celebration-skip'),
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => controller.skipCelebration(),
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
            // Egypt's guardian: the plate fades while his ankh's loop
            // passes under it, so the ankh never pops out from behind it.
            child: Opacity(
              opacity: sim.boss?.isNeferhoo == true
                  ? NeferhooFightArt.hudPlateAlpha(
                      MediaQuery.sizeOf(context),
                      sim.boss!,
                      insets: MediaQuery.paddingOf(context),
                    )
                  : 1,
              child: MatchHealth(
                key: const ValueKey('match-health'),
                hearts: sim.hearts,
                shield: sim.shield,
                charge: sim.shieldCharge,
                stars: sim.shieldStars,
                recovering: sim.recoveryRemaining > 0,
                reducedMotion: controller.reducedMotion,
              ),
            ),
          ),
        // The bird flies near x = 200, so the hero score keeps to the middle.
        // A level shows its stars and marks there instead, and its route
        // where a timed flight kept its clock, centred on the pause face.
        if (!sim.bossFight && level != null) ...[
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
              approach: sim.finishLine?.crossed == true
                  ? 1
                  : FinishGateArt.approach(FinishGateArt.toGo(sim)),
              seconds: controller.reducedMotion
                  ? 0
                  : sim.elapsed + (controller.celebration ?? 0),
            ),
          ),
        ] else if (!sim.bossFight)
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
                          ? sim.magnetRemaining / sim.magnetDuration
                          : sim.magnetCharge / sim.magnetGates,
                      text: sim.magnetActive
                          ? '${sim.magnetRemaining.ceil()}s'
                          : null,
                      label: sim.magnetActive
                          ? 'Star magnet: ${sim.magnetRemaining.ceil()} seconds remaining'
                          : 'Magnet charging: ${sim.magnetCharge} of ${sim.magnetGates} perfect gates',
                      color: SkyColors.purple,
                      active: sim.magnetActive,
                      segments: sim.magnetActive ? 0 : sim.magnetGates,
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
              limit: sim.maxCharge,
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
              recharge: 1 - sim.sprintCooldownRemaining / sim.sprintCooldown,
              burst: sim.sprintRemaining / sim.sprintSeconds,
              secondsLeft: sim.sprintCooldownRemaining.ceil(),
              onPressed: sim.canSprint ? controller.sprint : null,
              reducedMotion: controller.reducedMotion,
              size: sprint,
            ),
          ),
        if (sim.phase == RunPhase.countdown && (sim.countdown > 0 || !counting))
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
                    value: counting
                        ? sim.countdown.ceil().clamp(1, sim.countdownSeconds)
                        : 0,
                    reducedMotion: controller.reducedMotion,
                    child: SizedBox.square(
                      dimension: 92,
                      child: MatchPlate(
                        color: SkyColors.yellow,
                        padding: EdgeInsets.zero,
                        child: Center(
                          child: counting
                              ? Text(
                                  '${sim.countdown.ceil().clamp(1, sim.countdownSeconds)}',
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
          PauseCard(
            reducedMotion: controller.reducedMotion,
            subtitle: level != null
                ? '${level.id} · ${level.name}. Your bird is perched and waiting.'
                : controller.isTouch
                ? 'Your bird is perched and waiting. We’ll count you back in.'
                : 'Shake it out, then get back in position. We’ll count you in.',
            actions: [
              // A level starts over or goes back to the map; either way the
              // attempt is saved.
              if (level != null) ...[
                PauseAction(
                  key: const ValueKey('pause-map'),
                  label: 'Map',
                  icon: Icons.map_rounded,
                  onPressed: () => leave('/campaign'),
                ),
                PauseAction(
                  key: const ValueKey('pause-retry'),
                  label: 'Retry',
                  icon: Icons.replay_rounded,
                  tint: SkyColors.mint,
                  onPressed: restart,
                ),
              ] else
                PauseAction(
                  label: 'Finish flight',
                  icon: Icons.flag_rounded,
                  onPressed: controller.endFlight,
                ),
            ],
            onResume: () => controller.resume(),
          ),
      ],
    );
  }

  /// A flight that ended without a bump, outside the campaign: a workout
  /// finished from the pause menu, or a whole trail flown.
  Widget _results(ProgressSnapshot p) => MiniResults(
    key: ValueKey(controller.result!.id),
    controller: controller,
    progress: p,
    mode: widget.mode,
    course: widget.course,
    initialBest: initialBest,
    initialStamps: initialStamps,
    initialDailyKey: initialDailyKey,
    initialDailyComplete: initialDailyComplete,
    onLeave: leave,
  );
}
