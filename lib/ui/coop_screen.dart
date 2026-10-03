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
import 'flight_score.dart';
import 'home_keys.dart' show HomeKeyColors;
import 'match_hud.dart';
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
    final reducedMotion = settings.reducedMotion;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 14),
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
          const SizedBox(height: 16),
          Expanded(
            child: picked == null
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    children: [
                      Expanded(
                        child: _PlayerCard(
                          player: 0,
                          bird: picked.$1,
                          reducedMotion: reducedMotion,
                          onPick: (bird) =>
                              setState(() => picks = (bird, picks!.$2)),
                        ),
                      ),
                      SizedBox(
                        width: 110,
                        // Without the rope the cards stand apart; rivals
                        // face off.
                        child: switch (chosen) {
                          CoopMode.roped => CustomPaint(
                            painter: _RopePainter(reducedMotion: reducedMotion),
                          ),
                          CoopMode.free => null,
                          CoopMode.duel => const Center(child: _Versus()),
                        },
                      ),
                      Expanded(
                        child: _PlayerCard(
                          player: 1,
                          bird: picked.$2,
                          reducedMotion: reducedMotion,
                          onPick: (bird) =>
                              setState(() => picks = (picks!.$1, bird)),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _ModeToggle(
                mode: chosen,
                onChanged: (choice) => setState(() => mode = choice),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(switch (chosen) {
                  CoopMode.roped =>
                    'Your birds share one rope. Flap together to climb '
                        'high: a bird flapping alone lifts both, but only '
                        'a little. Sprint to drag your partner along.',
                  CoopMode.free =>
                    'No rope: each bird flies on its own and only bumps '
                        'into the other. Hearts, shield and score are '
                        'still shared.',
                  CoopMode.duel =>
                    'Fight! Each bird has its own hearts. Grab mystery '
                        'boxes: some send bats, a spitter or meteors at '
                        'your rival, others bring a heart, a shield or '
                        'star power. Last bird flying wins.',
                }, style: bodyText(13, color: SkyColors.muted)),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 210,
                child: MiniKey(
                  key: const ValueKey('coop-start'),
                  label: chosen.team ? 'Fly together' : 'Fight!',
                  icon: chosen.team
                      ? Icons.flight_takeoff_rounded
                      : Icons.sports_mma_rounded,
                  colors: chosen.team
                      ? HomeKeyColors.mint
                      : HomeKeyColors.coral,
                  height: 60,
                  onPressed: picked == null ? null : start,
                ),
              ),
            ],
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
        recharge: 1 - sim.sprintCooldownRemaining / Sprint.cooldown,
        burst: sim.sprintRemaining / Sprint.seconds,
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
          Container(
            color: SkyColors.ink.withValues(alpha: .35),
            child: Center(
              child: MatchPlate(
                radius: 28,
                padding: const EdgeInsets.fromLTRB(36, 30, 36, 26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Take a breather.', style: heading(38)),
                    const SizedBox(height: 10),
                    Text(
                      'Ready for more? We’ll count you both in.',
                      style: bodyText(16, color: SkyColors.muted),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SkyButton(
                          label: 'Finish flight',
                          onPressed: flight.endFlight,
                          color: SkyColors.cream,
                          icon: Icons.flag_outlined,
                        ),
                        const SizedBox(width: 16),
                        SkyButton(
                          label: 'Keep flying',
                          sound: 'resume',
                          onPressed: () => flight.resume(),
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
    final (first, second) = picks!;
    final best = result.score > initialBest && result.score > 0;
    final record = progress.coop.record(flight.coopMode);
    final seconds = result.durationSeconds.floor();
    final time =
        '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    Widget stat(String label, String value, [Color? color]) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          Text(value, style: heading(26, color: color ?? SkyColors.ink)),
          Text(label, style: bodyText(12, color: SkyColors.muted)),
        ],
      ),
    );
    return ColoredBox(
      color: SkyColors.ink.withValues(alpha: .38),
      child: SceneLayout(
        child: Center(
          child: MiniCard(
            accent: SkyColors.mint,
            padding: const EdgeInsets.fromLTRB(32, 22, 32, 22),
            child: SizedBox(
              width: 700,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      BirdArt(
                        bird: first,
                        size: 84,
                        reducedMotion: settings.reducedMotion,
                      ),
                      SizedBox(
                        width: 70,
                        height: 60,
                        child: flight.coopMode == CoopMode.roped
                            ? CustomPaint(
                                painter: _RopePainter(
                                  reducedMotion: settings.reducedMotion,
                                ),
                              )
                            : null,
                      ),
                      BirdArt(
                        bird: second,
                        size: 84,
                        reducedMotion: settings.reducedMotion,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              best ? 'New team best!' : 'What a team.',
                              style: heading(34),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${birdNames[first]} & ${birdNames[second]}'
                              ' · ${flight.coopMode.title}'
                              '${record.best > 0 ? ' · Team best ${record.best}' : ''}',
                              style: bodyText(15, color: SkyColors.muted),
                            ),
                          ],
                        ),
                      ),
                      MiniTag(
                        best ? 'NEW BEST!' : 'FLIGHT COMPLETE',
                        icon: Icons.emoji_events_rounded,
                        color: SkyColors.yellow,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      stat('team score', '${result.score}', SkyColors.coral),
                      stat('time', time),
                      stat('stars', '${result.stars}'),
                      stat('gates', '${result.gates}'),
                      stat(
                        'P1 flaps',
                        '${sim.lead.flaps}',
                        TetherArt.players[0],
                      ),
                      stat(
                        'P2 flaps',
                        '${sim.partner?.flaps ?? 0}',
                        TetherArt.players[1],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ..._actions(flight),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Home, new birds, the session and another go, then any save error.
  List<Widget> _actions(PlayController flight) => [
    Row(
      children: [
        for (final (i, action) in [
          MiniKey(
            key: const ValueKey('coop-home'),
            label: 'Home',
            icon: Icons.home_rounded,
            colors: HomeKeyColors.paper,
            height: 54,
            size: 17,
            onPressed: leave,
          ),
          MiniKey(
            key: const ValueKey('coop-change'),
            label: 'Change birds',
            icon: Icons.swap_horiz_rounded,
            colors: HomeKeyColors.paper,
            height: 54,
            size: 17,
            onPressed: changeBirds,
          ),
          MiniKey(
            key: const ValueKey('coop-save'),
            label: flight.sessionSaved
                ? 'Saved'
                : flight.sessionSaving
                ? 'Saving…'
                : 'Save session',
            icon: flight.sessionSaved
                ? Icons.check_rounded
                : Icons.video_library_rounded,
            colors: HomeKeyColors.paper,
            height: 54,
            size: 17,
            busy: flight.sessionSaving,
            onPressed: flight.canSaveSession && !flight.sessionSaved
                ? flight.persistSession
                : null,
          ),
          MiniKey(
            key: const ValueKey('coop-retry'),
            label: flight.duel ? 'Rematch' : 'Fly again',
            icon: flight.duel ? Icons.sports_mma_rounded : Icons.replay_rounded,
            colors: flight.duel ? HomeKeyColors.coral : HomeKeyColors.mint,
            height: 54,
            size: 17,
            onPressed: () => unawaited(flight.retry()),
          ),
        ].indexed) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: action),
        ],
      ],
    ),
    if (flight.saveError.isNotEmpty || flight.sessionError.isNotEmpty) ...[
      const SizedBox(height: 8),
      Text(
        flight.saveError.isNotEmpty ? flight.saveError : flight.sessionError,
        style: bodyText(13, color: SkyColors.coralDeep),
      ),
    ],
  ];

  /// Who won the duel, the series so far, and what each rival did.
  Widget _duelResults(PlayController flight) {
    final result = flight.result!;
    final sim = flight.simulation!;
    final (first, second) = picks!;
    final birds = [first, second];
    final winner = sim.duelWinner;
    final reducedMotion = settings.reducedMotion;
    final seconds = result.durationSeconds.floor();
    final time =
        '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    final title = switch (winner) {
      final player? => 'Player ${player + 1} wins!',
      null when result.reason == EndReason.collision => 'A draw!',
      null => 'Duel stopped',
    };
    final [one, two] = duelWins;
    Widget stat(String label, String value, [Color? color]) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Text(value, style: heading(24, color: color ?? SkyColors.ink)),
          Text(label, style: bodyText(12, color: SkyColors.muted)),
        ],
      ),
    );
    Widget rival(int player) {
      final won = winner == player;
      return Opacity(
        opacity: winner == null || won ? 1 : .55,
        child: BirdArt(
          key: ValueKey('duel-result-bird-$player'),
          bird: birds[player],
          size: won ? 96 : 72,
          reducedMotion: reducedMotion,
          bob: won,
        ),
      );
    }

    return ColoredBox(
      color: SkyColors.ink.withValues(alpha: .38),
      child: SceneLayout(
        child: Center(
          child: MiniCard(
            accent: SkyColors.coral,
            padding: const EdgeInsets.fromLTRB(32, 22, 32, 22),
            child: SizedBox(
              width: 720,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      rival(0),
                      SizedBox(
                        width: 64,
                        child: Center(
                          child: Transform.scale(
                            scale: .6,
                            child: const _Versus(),
                          ),
                        ),
                      ),
                      rival(1),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              key: const ValueKey('duel-title'),
                              style: heading(
                                34,
                                color: winner == null
                                    ? SkyColors.ink
                                    : TetherArt.players[winner],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              winner == null
                                  ? '${birdNames[first]} vs ${birdNames[second]}'
                                  : '${birdNames[birds[winner]]} beat '
                                        '${birdNames[birds[1 - winner]]}',
                              style: bodyText(15, color: SkyColors.muted),
                            ),
                          ],
                        ),
                      ),
                      MiniTag(
                        'SERIES $one–$two',
                        key: const ValueKey('duel-series'),
                        icon: Icons.emoji_events_rounded,
                        color: SkyColors.yellow,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      stat('time', time),
                      for (final (player, bird) in sim.flock.indexed) ...[
                        stat(
                          'P${player + 1} hearts',
                          '${bird.hearts}',
                          TetherArt.players[player],
                        ),
                        stat(
                          'P${player + 1} boxes',
                          '${bird.boxesOpened}',
                          TetherArt.players[player],
                        ),
                        stat(
                          'P${player + 1} hits',
                          '${bird.hitsLanded}',
                          TetherArt.players[player],
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  ..._actions(flight),
                ],
              ),
            ),
          ),
        ),
      ),
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

/// One player's bird picker: their colour, the bird they fly and a row of
/// all four birds to choose from.
class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.player,
    required this.bird,
    required this.reducedMotion,
    required this.onPick,
  });
  final int player, bird;
  final bool reducedMotion;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final color = TetherArt.players[player];
    final side = player == 0 ? 'left' : 'right';
    return MiniCard(
      accent: color,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Expanded(
            child: MiniArtBand(
              color: color,
              child: Stack(
                children: [
                  Positioned(
                    top: 12,
                    left: 14,
                    child: MiniTag(
                      'PLAYER ${player + 1}',
                      color: color,
                      foreground: SkyColors.white,
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Row(
                      children: [
                        Icon(
                          Icons.touch_app_rounded,
                          size: 15,
                          color: SkyColors.ink.withValues(alpha: .75),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tap the $side half',
                          style: bodyText(12, weight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  Positioned.fill(
                    top: 34,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: _PlayerBird(
                        bird: bird,
                        player: player,
                        reducedMotion: reducedMotion,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final i in birdOrder)
                  _BirdChoice(
                    key: ValueKey('coop-pick-$player-$i'),
                    bird: i,
                    selected: i == bird,
                    color: color,
                    label: 'Player ${player + 1}: ${birdNames[i]}',
                    onTap: () {
                      UiSounds.effect(context, 'ui_toggle');
                      onPick(i);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The bird a player flies, with its name and a line about it.
class _PlayerBird extends StatelessWidget {
  const _PlayerBird({
    required this.bird,
    required this.player,
    required this.reducedMotion,
  });
  final int bird, player;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Center(
          child: BirdArt(
            key: ValueKey('coop-bird-$player-$bird'),
            bird: bird,
            size: 132,
            reducedMotion: reducedMotion,
          ),
        ),
      ),
      SizedBox(
        width: 120,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(birdNames[bird], style: heading(26, weight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              birdDescriptions[bird],
              style: bodyText(12, color: SkyColors.ink),
            ),
          ],
        ),
      ),
    ],
  );
}

class _BirdChoice extends StatelessWidget {
  const _BirdChoice({
    super.key,
    required this.bird,
    required this.selected,
    required this.color,
    required this.label,
    required this.onTap,
  });
  final int bird;
  final bool selected;
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
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 160),
        width: 58,
        height: 58,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected
              ? Color.lerp(color, SkyColors.cream, .55)
              : SkyColors.white,
          border: Border.all(
            color: selected
                ? SkyColors.ink
                : SkyColors.ink.withValues(alpha: .2),
            width: selected ? 2.5 : 1.5,
          ),
          boxShadow: [
            if (selected) ...[
              BoxShadow(color: color, spreadRadius: 3),
              const BoxShadow(
                color: SkyColors.ink,
                spreadRadius: 4.5,
                offset: Offset(0, 2),
              ),
            ],
          ],
        ),
        child: BirdArt(bird: bird, size: 46, bob: false),
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

/// The badge between two rivals' cards.
class _Versus extends StatelessWidget {
  const _Versus();

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('coop-versus'),
    width: 74,
    height: 74,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: [.5, .5],
        colors: TetherArt.players,
      ),
      border: Border.all(color: SkyColors.ink, width: 3),
      boxShadow: [
        BoxShadow(
          color: SkyColors.ink.withValues(alpha: .18),
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Text(
      'VS',
      style: heading(
        30,
        color: SkyColors.white,
        weight: FontWeight.w700,
      ).copyWith(shadows: matchInkEdge(1.5)),
    ),
  );
}

/// Roped, no rope or 1 v 1: three chips, the chosen one filled.
class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});
  final CoopMode mode;
  final ValueChanged<CoopMode> onChanged;

  @override
  Widget build(BuildContext context) => MatchPlate(
    padding: const EdgeInsets.all(3),
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
              borderRadius: BorderRadius.circular(999),
              onTap: () {
                if (choice == mode) return;
                UiSounds.effect(context, 'ui_toggle');
                onChanged(choice);
              },
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: choice != mode
                      ? null
                      : choice.team
                      ? SkyColors.mint
                      : SkyColors.coral,
                  borderRadius: BorderRadius.circular(999),
                  border: choice != mode
                      ? null
                      : Border.all(color: SkyColors.ink, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(switch (choice) {
                      CoopMode.roped => Icons.link_rounded,
                      CoopMode.free => Icons.link_off_rounded,
                      CoopMode.duel => Icons.sports_mma_rounded,
                    }, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      choice.title,
                      style: bodyText(14, weight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
