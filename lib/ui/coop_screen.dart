import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/progress_repository.dart';
import '../data/providers.dart';
import '../domain/game_rules.dart';
import '../domain/tracking.dart';
import '../game/audio.dart';
import '../game/bird_game.dart';
import '../game/duel_art.dart';
import '../game/play_controller.dart';
import '../game/tether_art.dart';
import 'components.dart';
import 'coop_results.dart';
import 'coop_setup.dart';
import 'flight_score.dart';
import 'home_keys.dart' show HomeKeyColors;
import 'match_hud.dart';
import 'stage_key.dart';
import 'mini_chrome.dart';
import 'theme.dart';
import 'ui_sounds.dart';

/// Fly Together: two players on one phone fly Star Trail with their birds
/// roped together ([Tether]). Player 1 taps the left half of the sky and has
/// Shoot and Sprint in the bottom-left corner; player 2 has the right half
/// and the bottom-right corner. Hearts, shield and score are shared.
///
/// In a 1 v 1 duel ([CoopMode.duel]) the same controls fight instead: each
/// player has their own hearts, mystery boxes send attacks at the rival or
/// help the bird that opens them, and the last bird flying wins.
class CoopScreen extends ConsumerStatefulWidget {
  const CoopScreen({super.key});

  @override
  ConsumerState<CoopScreen> createState() => _CoopScreenState();
}

class _CoopScreenState extends ConsumerState<CoopScreen>
    with WidgetsBindingObserver {
  late final SkyAudio audio;
  PlayController? controller;
  BirdGame? game;

  /// The birds players 1 and 2 have picked, once the saved ones load.
  (int, int)? picks;

  /// Roped or not, once the saved choice loads.
  CoopMode? mode;
  int initialBest = 0, previousScore = 0, previousStars = 0;
  int previousHearts = 3, previousCount = 4;
  bool previousShield = true, leaving = false;

  /// Duels won by players 1 and 2 since this screen opened, and the result
  /// last counted.
  final duelWins = [0, 0];
  RunResult? countedDuel;

  /// Each duel bird's hearts and shield on the last frame, and the boxes
  /// opened so far, for their sounds.
  var previousRivals = [(3, true), (3, true)];
  int previousBoxes = 0;

  /// The prize each duel player last took out of a box, and when, for the
  /// banner under their hearts.
  final prizes = <int, (BoxPrize, double)>{};

  GameSettings get settings =>
      ref.read(progressProvider).asData?.value.settings ?? const GameSettings();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    audio = ref.read(audioFactoryProvider)();
    audio.configure(settings, track: SkyMusic.menu);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.removeListener(changed);
    controller?.dispose();
    audio.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      controller?.background();
    }
    if (state == AppLifecycleState.resumed) {
      audio.configure(
        settings,
        track: controller == null ? SkyMusic.menu : SkyMusic.flight,
      );
    }
  }

  Future<void> start() async {
    final (first, second) = picks!;
    final coopMode = mode ?? CoopMode.roped;
    final progress = ref.read(progressProvider.notifier);
    unawaited(progress.chooseCoop(first, second, coopMode).catchError((_) {}));
    initialBest =
        ref.read(progressProvider).asData?.value.coop.record(coopMode).best ??
        0;
    await audio.configure(settings);
    final flight = controller = PlayController(
      mode: PlayMode.touch,
      course: FlightCourse.starTrail,
      source: null,
      clock: ref.read(appClockProvider),
      audio: audio,
      bird: first,
      partner: second,
      coopMode: coopMode,
      upgrades:
          ref.read(progressProvider).asData?.value.upgrades ?? const PowerUps(),
      reducedMotion: settings.reducedMotion,
      // Each co-op mode keeps its own best, apart from the solo records.
      saveRun: (run) => progress.saveCoop(coopMode, run),
      saveSession: (session) async {
        await ref.read(sessionRepositoryProvider).save(session);
        ref.invalidate(sessionsProvider);
      },
      best: initialBest,
      voiceMemory: ref.read(flightVoiceMemoryProvider).asData?.value,
      rememberVoices: (memory) => ref
          .read(progressRepositoryProvider)
          .saveFlightVoices(memory.encode()),
    )..addListener(changed);
    setState(() {});
    await flight.fly();
  }

  void changed() {
    final flight = controller;
    if (!mounted || flight == null) return;
    final sim = flight.simulation;
    if (sim != null &&
        flight.stage == PlayStage.flying &&
        game?.simulation != sim) {
      final (first, second) = picks!;
      previousScore = previousStars = 0;
      previousHearts = 3;
      previousShield = true;
      previousCount = 4;
      previousRivals = [(3, true), (3, true)];
      previousBoxes = 0;
      prizes.clear();
      game = BirdGame(
        simulation: sim,
        nowMs: () => flight.nowMs,
        bird: first,
        partnerBird: second,
        reducedMotion: settings.reducedMotion,
        onChanged: flight.tick,
        advance: flight.advance,
        knockout: () => flight.knockout,
        speech: () => flight.speech,
      );
    }
    if (sim != null && sim.duel) {
      _duelCues(sim);
    } else if (sim != null) {
      if (initialBest > 0 &&
          previousScore <= initialBest &&
          sim.score > initialBest) {
        audio.effect('record');
      } else if (sim.collectedStars > previousStars) {
        audio.effect('star');
      }
      if (sim.hearts < previousHearts) audio.effect('bump');
      if (sim.hearts > previousHearts) audio.effect('heart');
      if (sim.shield && !previousShield) audio.effect('shield');
      if (!sim.shield && previousShield) audio.effect('shield_pop');
    }
    if (sim != null) {
      previousScore = sim.score;
      previousStars = sim.collectedStars;
      previousHearts = sim.hearts;
      previousShield = sim.shield;
      final count = sim.countdown.ceil();
      if (sim.phase == RunPhase.countdown &&
          count > 0 &&
          count != previousCount) {
        audio.effect('ready');
        previousCount = count;
      }
    }
    final result = flight.result;
    if (flight.duel && result != null && !identical(result, countedDuel)) {
      countedDuel = result;
      if (sim?.duelWinner case final winner?) duelWins[winner]++;
    }
    final frozen = game;
    if (frozen != null && flight.stage == PlayStage.results && !frozen.paused) {
      // The last frame holds still under the results.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            identical(game, frozen) &&
            controller?.stage == PlayStage.results) {
          frozen.pauseEngine();
        }
      });
    }
    setState(() {});
  }

  /// A duel's sounds: each bird's own hearts and shield, its stars, and
  /// every box: a fanfare for a help, a summons for an attack. New prizes
  /// raise their player's banner.
  void _duelCues(FlightSimulation sim) {
    if (sim.collectedStars > previousStars) audio.effect('star');
    for (final (player, bird) in sim.flock.indexed) {
      final (hearts, shield) = previousRivals[player];
      if (bird.hearts < hearts) audio.effect('bump');
      if (bird.hearts > hearts) audio.effect('heart');
      if (bird.shield && !shield) audio.effect('shield');
      if (!bird.shield && shield) audio.effect('shield_pop');
    }
    previousRivals = [for (final bird in sim.flock) (bird.hearts, bird.shield)];
    if (sim.boxesOpened > previousBoxes) {
      for (final box in sim.boxes) {
        final (opener, prize) = (box.opener, box.prize);
        if (opener == null || prize == null) continue;
        final shown = prizes[opener];
        if (shown == null || shown.$2 < box.openedAt!) {
          prizes[opener] = (prize, box.openedAt!);
          audio.effect(prize.attack ? 'boss_summon' : 'unlock');
        }
      }
      previousBoxes = sim.boxesOpened;
    }
  }

  /// Ends the pair's flight and returns to the bird pickers.
  Future<void> changeBirds() async {
    final flight = controller;
    if (flight == null) return;
    await flight.exit();
    if (!mounted) return;
    flight
      ..removeListener(changed)
      ..dispose();
    setState(() {
      controller = null;
      game = null;
    });
    await audio.configure(settings, track: SkyMusic.menu);
  }

  Future<void> leave() async {
    if (leaving) return;
    leaving = true;
    await controller?.exit();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        ref.watch(progressProvider).asData?.value ?? const ProgressSnapshot();
    picks ??= ref.read(progressProvider).asData?.value.coop.birds;
    mode ??= ref.read(progressProvider).asData?.value.coop.mode;
    final flight = controller;
    final stage = flight?.stage;
    final showFlight =
        game != null &&
        (stage == PlayStage.flying ||
            stage == PlayStage.fallen ||
            stage == PlayStage.results);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(leave());
      },
      child: Scaffold(
        body: SkyBackdrop(
          reducedMotion: settings.reducedMotion,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (flight == null)
                SceneLayout(child: _setup(progress))
              else if (showFlight)
                Positioned.fill(child: _flight(flight)),
              if (stage == PlayStage.fallen)
                Positioned.fill(
                  child: Listener(
                    key: const ValueKey('coop-knockout-skip'),
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (_) => flight!.skipKnockout(),
                  ),
                ),
              if (stage == PlayStage.results && flight!.result != null)
                Positioned.fill(child: _results(flight, progress)),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- setup --

  Widget _setup(ProgressSnapshot progress) {
    final picked = picks;
    final chosen = mode ?? CoopMode.roped;
    final best = progress.coop.record(chosen).best;
    final duels = progress.coop.duels;
    final reducedMotion =
        settings.reducedMotion || MediaQuery.disableAnimationsOf(context);
    // The space between the two cards, where the rope hangs or the rivals'
    // badge sits.
    const gap = 104.0;
    final (lead, body) = switch (chosen) {
      CoopMode.roped => (
        'Your birds share one rope.',
        'Flap together to climb high: a bird flapping alone lifts both, but '
            'only a little. Sprint to drag your partner along.',
      ),
      CoopMode.free => (
        'No rope:',
        'each bird flies on its own and only bumps into the other. Hearts, '
            'shield and score are still shared.',
      ),
      CoopMode.duel => (
        'Fight!',
        'Each bird has its own hearts. Grab mystery boxes: some send bats, a '
            'spitter or meteors at your rival, others bring a heart, a shield '
            'or star power. Last bird flying wins.',
      ),
    };
    Widget card(int player, int bird) => _PlayerCard(
      player: player,
      bird: bird,
      mode: chosen,
      reducedMotion: reducedMotion,
      onPick: (bird) => setState(
        () => picks = player == 0 ? (bird, picks!.$2) : (picks!.$1, bird),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 12),
      child: Column(
        children: [
          MiniHeader(
            title: 'Fly Together',
            onBack: leave,
            leading: const [
              MiniTag(
                'TWO PLAYERS · ONE PHONE',
                icon: Icons.people_alt_rounded,
                color: SkyColors.mint,
              ),
            ],
            trailing: [
              MiniTag(
                chosen.team
                    ? '${chosen.title.toUpperCase()}'
                          '${best > 0 ? ' BEST $best' : ': NO BEST YET'}'
                    : '1 V 1${duels > 0 ? ' · $duels DUELS' : ': FIRST DUEL'}',
                key: const ValueKey('coop-best'),
                icon: chosen.team
                    ? Icons.emoji_events_rounded
                    : Icons.sports_mma_rounded,
                color: SkyColors.yellow,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: picked == null
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      Row(
                        children: [
                          Expanded(child: card(0, picked.$1)),
                          const SizedBox(width: gap),
                          Expanded(child: card(1, picked.$2)),
                        ],
                      ),
                      // The rope is tied to rings on the cards' inner
                      // frames, so it paints over both of them; without it
                      // the cut ends hang loose, and rivals face off.
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedSwitcher(
                            duration: reducedMotion
                                ? Duration.zero
                                : const Duration(milliseconds: 260),
                            switchInCurve: Curves.easeOutBack,
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: ScaleTransition(
                                    scale: Tween(
                                      begin: .85,
                                      end: 1.0,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                ),
                            child: Stack(
                              key: ValueKey(chosen),
                              fit: StackFit.expand,
                              children: [
                                CoopTether(
                                  mode: chosen,
                                  gap: gap,
                                  reducedMotion: reducedMotion,
                                  rope: CustomPaint(
                                    painter: _RopePainter(
                                      reducedMotion: reducedMotion,
                                    ),
                                  ),
                                ),
                                if (chosen == CoopMode.duel)
                                  const Align(
                                    alignment: Alignment(0, -.24),
                                    child: SizedBox.square(
                                      dimension: 92,
                                      child: _Versus(),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 70,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ModeToggle(
                  mode: chosen,
                  onChanged: (choice) => setState(() => mode = choice),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: CoopBubble(
                      lead: lead,
                      body: body,
                      accent: chosen.team ? SkyColors.mint : SkyColors.coral,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 224,
                  child: CoopStartKey(
                    key: const ValueKey('coop-start'),
                    label: chosen.team ? 'Fly together' : 'Fight!',
                    icon: chosen.team
                        ? Icons.flight_takeoff_rounded
                        : Icons.sports_mma_rounded,
                    colors: chosen.team
                        ? HomeKeyColors.mint
                        : HomeKeyColors.coral,
                    reducedMotion: reducedMotion,
                    onPressed: picked == null ? null : start,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- flight --

  Widget _flight(PlayController flight) {
    final sim = flight.simulation!;
    return Focus(
      autofocus: true,
      onKeyEvent: (_, event) => _key(flight, event),
      child: Stack(
        fit: StackFit.expand,
        children: [
          LayoutBuilder(
            builder: (context, constraints) => Semantics(
              label:
                  'Player 1 taps the left half to flap, player 2 the right half',
              child: Listener(
                key: const ValueKey('coop-flight'),
                behavior: HitTestBehavior.opaque,
                onPointerDown: (event) => flight.flap(
                  player: event.localPosition.dx < constraints.maxWidth / 2
                      ? 0
                      : 1,
                ),
                child: GameWidget(game: game!),
              ),
            ),
          ),
          if (sim.phase == RunPhase.countdown && sim.countdown > 0)
            const _SideHints(),
          if (flight.stage == PlayStage.flying)
            SceneLayout(child: _hud(flight, sim)),
        ],
      ),
    );
  }

  /// Keys for a keyboard or two: player 1 flaps with W, sprints with A and
  /// holds D to shoot; player 2 uses Up, Left and Right.
  KeyEventResult _key(PlayController flight, KeyEvent event) {
    final key = event.logicalKey;
    final player = switch (key) {
      LogicalKeyboardKey.keyW ||
      LogicalKeyboardKey.keyA ||
      LogicalKeyboardKey.keyD => 0,
      LogicalKeyboardKey.arrowUp ||
      LogicalKeyboardKey.arrowLeft ||
      LogicalKeyboardKey.arrowRight => 1,
      _ => null,
    };
    if (player == null) return KeyEventResult.ignored;
    final shootKey =
        key == LogicalKeyboardKey.keyD || key == LogicalKeyboardKey.arrowRight;
    if (event is KeyUpEvent) {
      if (shootKey) flight.shoot(player: player);
      return KeyEventResult.handled;
    }
    if (event is! KeyDownEvent) return KeyEventResult.handled;
    if (shootKey) {
      flight.startCharge(player: player);
    } else if (key == LogicalKeyboardKey.keyA ||
        key == LogicalKeyboardKey.arrowLeft) {
      flight.sprint(player: player);
    } else {
      flight.flap(player: player);
    }
    return KeyEventResult.handled;
  }

  Widget _hud(PlayController flight, FlightSimulation sim) {
    const edge = MatchLayout.edge, gap = MatchLayout.gap;
    const bottom = edge + 6, shot = 92.0, sprint = 76.0;
    final reducedMotion = flight.reducedMotion;
    final paused = sim.phase == RunPhase.paused;
    final pause = MatchAction(
      symbol: MatchSymbol.pause,
      label: 'Pause flight',
      onPressed: () {
        UiSounds.effect(context, 'pause');
        flight.pause();
      },
      reducedMotion: reducedMotion,
      size: MatchLayout.height,
      hitSlop: edge,
    );
    // A duel's top corners belong to the rivals' hearts.
    final menu = sim.duel
        ? Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [pause],
            ),
          )
        : Positioned(top: 0, right: 0, child: pause);
    if (sim.bossCutscene && sim.phase == RunPhase.playing) {
      return Stack(children: [menu]);
    }
    Widget controls(int player) => sim.viewing(sim.flock[player], () {
      final left = player == 0;
      final shootButton = MatchShotButton(
        key: ValueKey('coop-shoot-$player'),
        label: 'Player ${player + 1} shoot',
        reserve: sim.ammo,
        charge: sim.shotCharge,
        spend: sim.charging && !sim.outOfAmmo ? sim.shotCost : 0,
        hold: sim.fullHoldLeft,
        limit: sim.maxCharge,
        charging: sim.charging,
        empty: sim.outOfAmmo,
        onPress: sim.phase == RunPhase.playing
            ? () => flight.startCharge(player: player)
            : null,
        onRelease: () => flight.shoot(player: player),
        reducedMotion: reducedMotion,
        size: shot,
      );
      final sprintButton = MatchSprintButton(
        key: ValueKey('coop-sprint-$player'),
        label: 'Player ${player + 1} sprint',
        recharge: 1 - sim.sprintCooldownRemaining / sim.sprintCooldown,
        burst: sim.sprintRemaining / sim.sprintSeconds,
        secondsLeft: sim.sprintCooldownRemaining.ceil(),
        onPressed: sim.canSprint ? () => flight.sprint(player: player) : null,
        reducedMotion: reducedMotion,
        size: sprint,
      );
      return Positioned(
        left: left ? edge : null,
        right: left ? null : edge,
        bottom: bottom,
        child: Column(
          crossAxisAlignment: left
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          children: [
            IgnorePointer(
              child: Pill(
                'P${player + 1}',
                color: TetherArt.players[player],
                foreground: SkyColors.white,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Shoot sits in the corner under each player's thumb.
                if (left) ...[
                  shootButton,
                  const SizedBox(width: gap + 4),
                  sprintButton,
                ] else ...[
                  sprintButton,
                  const SizedBox(width: gap + 4),
                  shootButton,
                ],
              ],
            ),
          ],
        ),
      );
    });

    final magnet =
        sim.supportsMagnet && (sim.magnetActive || sim.magnetCharge > 0);
    return Stack(
      fit: StackFit.expand,
      children: [
        if (sim.duel)
          for (final player in [0, 1])
            Positioned(
              left: player == 0 ? edge : null,
              right: player == 0 ? null : edge,
              top: edge,
              child: _rival(sim, player, reducedMotion),
            )
        else
          Positioned(
            left: edge,
            top: edge,
            child: IgnorePointer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MatchHealth(
                    key: const ValueKey('coop-health'),
                    hearts: sim.hearts,
                    shield: sim.shield,
                    charge: sim.shieldCharge,
                    stars: sim.shieldStars,
                    recovering: sim.recoveryRemaining > 0,
                    reducedMotion: reducedMotion,
                  ),
                  if (magnet) ...[
                    const SizedBox(height: MatchLayout.stack),
                    MatchPlate(
                      color: sim.magnetActive
                          ? SkyColors.lavender
                          : SkyColors.cream,
                      child: MatchMeter(
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
                  ],
                ],
              ),
            ),
          ),
        if (sim.boss == null && !sim.duel)
          Positioned(
            top: edge - 4,
            left: 330,
            right: 330,
            child: IgnorePointer(
              child: FlightScore(
                score: sim.score,
                multiplier: sim.multiplier,
                symbol: MatchSymbol.star,
                reducedMotion: reducedMotion,
              ),
            ),
          ),
        menu,
        if (!sim.victoryGlide) ...[controls(0), controls(1)],
        if (sim.phase == RunPhase.countdown && sim.countdown > 0)
          Center(
            child: MatchPlate(
              radius: 28,
              padding: const EdgeInsets.fromLTRB(32, 16, 32, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(switch (flight.coopMode) {
                    CoopMode.roped => 'Rope on. Ready, steady…',
                    CoopMode.free => 'Ready, steady…',
                    CoopMode.duel => 'Ready to duel…',
                  }, style: heading(28)),
                  const SizedBox(height: 12),
                  MatchPulse(
                    value: sim.countdown.ceil().clamp(1, sim.countdownSeconds),
                    reducedMotion: reducedMotion,
                    child: SizedBox.square(
                      dimension: 92,
                      child: MatchPlate(
                        color: SkyColors.yellow,
                        padding: EdgeInsets.zero,
                        child: Center(
                          child: Text(
                            '${sim.countdown.ceil().clamp(1, sim.countdownSeconds)}',
                            style: matchDigits(62),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    switch (flight.coopMode) {
                      CoopMode.roped =>
                        'Flap together to climb high.\n'
                            'Sprint to drag your partner along!',
                      CoopMode.free =>
                        'Each bird flies on its own.\n'
                            'Share the hearts, beat the gates!',
                      CoopMode.duel =>
                        'Grab the mystery boxes!\n'
                            'Last bird flying wins.',
                    },
                    style: bodyText(16, color: SkyColors.muted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        if (paused)
          CoopPauseCard(
            birds: picks!,
            onFinish: flight.endFlight,
            onResume: () => flight.resume(),
          ),
      ],
    );
  }

  /// How long a prize's banner shows under its player's hearts.
  static const _prizeSeconds = 1.8;

  /// One duel player's corner: their tag and hearts, their star power while
  /// it lasts, and the prize they just took out of a box.
  Widget _rival(FlightSimulation sim, int player, bool reducedMotion) {
    final left = player == 0;
    final prize = prizes[player];
    return IgnorePointer(
      child: sim.viewing(
        sim.flock[player],
        () => Column(
          crossAxisAlignment: left
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          children: [
            Pill(
              'PLAYER ${player + 1}',
              color: TetherArt.players[player],
              foreground: SkyColors.white,
            ),
            const SizedBox(height: 6),
            MatchHealth(
              key: ValueKey('duel-health-$player'),
              hearts: sim.hearts,
              shield: sim.shield,
              charge: sim.shieldCharge,
              stars: sim.shieldStars,
              recovering: sim.recoveryRemaining > 0,
              reducedMotion: reducedMotion,
            ),
            if (sim.starPowered) ...[
              const SizedBox(height: MatchLayout.stack),
              MatchPlate(
                key: ValueKey('duel-star-power-$player'),
                color: SkyColors.yellow,
                child: MatchMeter(
                  symbol: MatchSymbol.star,
                  value: sim.starPowerRemaining / Duel.starPowerSeconds,
                  text: '${sim.starPowerRemaining.ceil()}s',
                  label:
                      'Player ${player + 1} star power: '
                      '${sim.starPowerRemaining.ceil()} seconds left',
                  color: SkyColors.gold,
                ),
              ),
            ],
            if (prize != null && sim.elapsed - prize.$2 < _prizeSeconds) ...[
              const SizedBox(height: MatchLayout.stack),
              _PrizeBanner(
                key: ValueKey('duel-prize-$player'),
                player: player,
                prize: prize.$1,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------- results --

  Widget _results(PlayController flight, ProgressSnapshot progress) {
    if (flight.duel) return _duelResults(flight);
    final result = flight.result!;
    final sim = flight.simulation!;
    return CoopTeamStage(
      birds: picks!,
      mode: flight.coopMode,
      score: result.score,
      previousBest: initialBest,
      best: progress.coop.record(flight.coopMode).best,
      durationSeconds: result.durationSeconds,
      stars: result.stars,
      gates: result.gates,
      flaps: (sim.lead.flaps, sim.partner?.flaps ?? 0),
      keys: _actions(flight),
      reducedMotion: settings.reducedMotion,
      status: coopStatus(flight),
    );
  }

  /// Home, new birds, the session and another go. The smaller keys are
  /// tall enough to stay 48 dp on the smallest phone.
  List<Widget> _actions(PlayController flight) => [
    StageKey(
      key: const ValueKey('coop-home'),
      height: 76,
      label: 'Home',
      icon: Icons.home_rounded,
      onPressed: leave,
    ),
    StageKey(
      key: const ValueKey('coop-change'),
      height: 76,
      label: 'Change birds',
      icon: Icons.swap_horiz_rounded,
      onPressed: changeBirds,
    ),
    StageKey(
      key: const ValueKey('coop-save'),
      height: 76,
      label: flight.sessionSaved
          ? 'Saved'
          : flight.sessionSaving
          ? 'Saving…'
          : 'Save session',
      icon: flight.sessionSaved ? Icons.check_rounded : Icons.save_alt_rounded,
      busy: flight.sessionSaving,
      onPressed: flight.canSaveSession && !flight.sessionSaved
          ? flight.persistSession
          : null,
    ),
    StageKey(
      key: const ValueKey('coop-retry'),
      label: flight.duel ? 'Rematch' : 'Fly again',
      icon: flight.duel ? Icons.sports_mma_rounded : Icons.replay_rounded,
      hero: true,
      onPressed: () => unawaited(flight.retry()),
    ),
  ];

  /// Who won the duel, the series so far, and what each rival did.
  Widget _duelResults(PlayController flight) {
    final result = flight.result!;
    final sim = flight.simulation!;
    final (first, second) = picks!;
    final birds = [first, second];
    final winner = sim.duelWinner;
    final [one, two] = duelWins;
    return CoopDuelStage(
      birds: picks!,
      winner: winner,
      title: switch (winner) {
        final player? => 'Player ${player + 1} wins!',
        null when result.reason == EndReason.collision => 'A draw!',
        null => 'Duel stopped',
      },
      caption: winner == null
          ? '${birdNames[first]} vs ${birdNames[second]}'
          : '${birdNames[birds[winner]]} beat '
                '${birdNames[birds[1 - winner]]}',
      wins: (one, two),
      stopped: winner == null && result.reason != EndReason.collision,
      durationSeconds: result.durationSeconds,
      lines: [
        for (final bird in sim.flock)
          (hearts: bird.hearts, boxes: bird.boxesOpened, hits: bird.hitsLanded),
      ],
      keys: _actions(flight),
      reducedMotion: settings.reducedMotion,
      status: coopStatus(flight),
    );
  }
}

/// What a box gave, in its player's colour: an attack names the rival it
/// went after.
class _PrizeBanner extends StatelessWidget {
  const _PrizeBanner({super.key, required this.player, required this.prize});
  final int player;
  final BoxPrize prize;

  @override
  Widget build(BuildContext context) => MatchPlate(
    color: TetherArt.players[player],
    padding: const EdgeInsets.fromLTRB(10, 6, 14, 7),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The prize's own sticker, as it burst out of the box in the sky.
        SizedBox.square(
          dimension: 28,
          child: CustomPaint(
            painter: DuelPrizePainter(prize, color: TetherArt.players[player]),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          prize.attack
              ? '${prize.title} at P${2 - player}!'
              : '${prize.title}!',
          style: heading(
            18,
            color: SkyColors.white,
            weight: FontWeight.w700,
          ).copyWith(shadows: matchInkEdge(1.2)),
        ),
      ],
    ),
  );
}

/// One player's card: a banner with their number, the bird they fly in a
/// sunburst window with its name, and a tray of all four birds to choose
/// from. The two cards face each other, so player 2's is mirrored: its
/// bird stands on the inner side, near player 1's, and in a duel turns to
/// face its rival.
class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.player,
    required this.bird,
    required this.mode,
    required this.reducedMotion,
    required this.onPick,
  });
  final int player, bird;
  final CoopMode mode;
  final bool reducedMotion;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final color = TetherArt.players[player];
    final mirrored = player == 1;
    return CoopCard(
      color: color,
      art: CoopArtWindow(
        color: color,
        focus: Alignment(mirrored ? -.42 : .42, .12),
        child: Stack(
          children: [
            Positioned(
              top: 10,
              left: mirrored ? null : 0,
              right: mirrored ? 0 : null,
              child: CoopRibbon(
                label: 'PLAYER ${player + 1}',
                color: color,
                mirrored: mirrored,
              ),
            ),
            Positioned(
              top: 12,
              left: mirrored ? 10 : null,
              right: mirrored ? null : 10,
              child: CoopHint(
                text: 'Tap the ${mirrored ? 'right' : 'left'} half',
              ),
            ),
            Positioned.fill(
              top: 38,
              child: _PlayerBird(
                bird: bird,
                player: player,
                facing: mirrored && !mode.team,
                reducedMotion: reducedMotion,
              ),
            ),
          ],
        ),
      ),
      tray: CoopTray(
        color: color,
        children: [
          for (final i in birdOrder)
            _BirdChoice(
              key: ValueKey('coop-pick-$player-$i'),
              bird: i,
              selected: i == bird,
              color: color,
              reducedMotion: reducedMotion,
              label: 'Player ${player + 1}: ${birdNames[i]}',
              onTap: () {
                UiSounds.effect(context, 'ui_toggle');
                onPick(i);
              },
            ),
        ],
      ),
    );
  }
}

/// The bird a player flies, with its name and a line about it on the outer
/// side of the card. [facing] turns it to face the other card.
class _PlayerBird extends StatelessWidget {
  const _PlayerBird({
    required this.bird,
    required this.player,
    required this.facing,
    required this.reducedMotion,
  });
  final int bird, player;
  final bool facing, reducedMotion;

  @override
  Widget build(BuildContext context) {
    final mirrored = player == 1;
    final align = mirrored ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final art = AnimatedSwitcher(
      duration: reducedMotion
          ? Duration.zero
          : const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutBack,
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: Tween(begin: .6, end: 1.0).animate(animation),
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: Transform.flip(
        key: ValueKey(bird),
        flipX: facing,
        child: BirdArt(
          key: ValueKey('coop-bird-$player-$bird'),
          bird: bird,
          size: 126,
          reducedMotion: reducedMotion,
        ),
      ),
    );
    final about = Padding(
      padding: EdgeInsets.only(
        left: mirrored ? 0 : 16,
        right: mirrored ? 16 : 0,
        bottom: 18,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: align,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              birdNames[bird],
              maxLines: 1,
              style: heading(30, weight: FontWeight.w700).copyWith(
                height: 1.05,
                shadows: const [
                  Shadow(color: SkyColors.cream, offset: Offset(0, 2)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 3),
          Container(
            width: 34,
            height: 5,
            decoration: BoxDecoration(
              color: TetherArt.players[player],
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: SkyColors.ink, width: 1.2),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            birdDescriptions[bird],
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: mirrored ? TextAlign.right : TextAlign.left,
            style: bodyText(
              12.5,
              color: SkyColors.ink.withValues(alpha: .82),
            ).copyWith(height: 1.2),
          ),
        ],
      ),
    );
    final children = [
      Expanded(flex: 5, child: about),
      Expanded(flex: 6, child: Center(child: art)),
    ];
    return Row(children: mirrored ? children.reversed.toList() : children);
  }
}

/// One bird in a player's tray: a coin to tap, raised in their colour with a
/// check when it is the bird they fly.
class _BirdChoice extends StatelessWidget {
  const _BirdChoice({
    super.key,
    required this.bird,
    required this.selected,
    required this.color,
    required this.reducedMotion,
    required this.label,
    required this.onTap,
  });
  final int bird;
  final bool selected, reducedMotion;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    excludeSemantics: true,
    child: InkResponse(
      onTap: onTap,
      radius: 34,
      child: CoopPickCoin(
        selected: selected,
        color: color,
        reducedMotion: reducedMotion,
        child: BirdArt(bird: bird, size: 44, bob: false),
      ),
    ),
  );
}

/// A length of the co-op rope, hanging between the two sides of its box.
class _RopePainter extends CustomPainter {
  const _RopePainter({required this.reducedMotion});
  final bool reducedMotion;

  @override
  void paint(Canvas canvas, Size size) {
    // Each player's knot sits just inside the box, so neither neighbour
    // hides it, and the span between them is a comfortably slack one.
    const inset = .017;
    final unit = size.width / (Tether.length * .78 + inset * 2);
    final y = size.height / 2 / unit - .03;
    TetherArt.between(
      canvas,
      unit,
      Offset(inset, y),
      Offset(size.width / unit - inset, y),
      seconds: 0,
      reducedMotion: true,
    );
  }

  @override
  bool shouldRepaint(_RopePainter oldDelegate) =>
      oldDelegate.reducedMotion != reducedMotion;
}

/// During the countdown each half of the sky shows whose it is.
class _SideHints extends StatelessWidget {
  const _SideHints();

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Row(
      children: [
        for (final player in [0, 1])
          Expanded(
            child: Container(
              color: TetherArt.players[player].withValues(alpha: .1),
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.only(bottom: 150),
              child: Text(
                'P${player + 1} · tap this side',
                style:
                    heading(
                      22,
                      color: SkyColors.white,
                      weight: FontWeight.w700,
                    ).copyWith(
                      shadows: const [
                        Shadow(color: SkyColors.ink, offset: Offset(0, 2)),
                      ],
                    ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// The badge between two rivals' cards: a burst split between their
/// colours. It fills the box it is given, up to 92 across.
class _Versus extends StatelessWidget {
  const _Versus();

  @override
  Widget build(BuildContext context) => const SizedBox(
    key: ValueKey('coop-versus'),
    width: 92,
    height: 92,
    child: CoopVersusBurst(),
  );
}

/// Roped, no rope or 1 v 1: a strip of three stickers, each a little picture
/// of the mode over its name, the chosen one raised in its colour.
class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});
  final CoopMode mode;
  final ValueChanged<CoopMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return MatchPlate(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(5, 5, 5, 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final choice in CoopMode.values)
            Semantics(
              button: true,
              selected: choice == mode,
              label: switch (choice) {
                CoopMode.roped => 'Roped: the birds share a rope',
                CoopMode.free => 'No rope: each bird flies on its own',
                CoopMode.duel => '1 v 1: the birds fight each other',
              },
              excludeSemantics: true,
              child: InkWell(
                key: ValueKey('coop-mode-${choice.name}'),
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  if (choice == mode) return;
                  UiSounds.effect(context, 'ui_toggle');
                  onChanged(choice);
                },
                child: SizedBox(
                  width: 84,
                  child: CustomPaint(
                    painter: choice == mode
                        ? CoopStickerPainter(
                            color: choice.team
                                ? SkyColors.mint
                                : SkyColors.coral,
                          )
                        : null,
                    child: AnimatedSlide(
                      duration: still
                          ? Duration.zero
                          : const Duration(milliseconds: 160),
                      offset: Offset(0, choice == mode ? -.03 : 0),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(4, 5, 4, 7),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CoopModeGlyph(choice, muted: choice != mode),
                            const SizedBox(height: 3),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                choice.title,
                                maxLines: 1,
                                style: bodyText(
                                  14,
                                  weight: FontWeight.w900,
                                  color: choice == mode
                                      ? SkyColors.ink
                                      : SkyColors.ink.withValues(alpha: .6),
                                ).copyWith(height: 1.1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
