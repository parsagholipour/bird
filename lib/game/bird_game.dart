import 'dart:math' as math;
import 'package:flutter/painting.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart' show MediaQuery;
import '../domain/game_rules.dart';
import '../domain/bird_motion.dart';
import '../ui/theme.dart';
import 'regions/region_burst.dart';
import 'sky_scenery.dart';
import 'bird_trail.dart';
import 'bird_puppet.dart';
import 'star_trio_art.dart';
import 'star_group_aura.dart';
import 'neferhoo_encounter_art.dart' show NeferhooEncounterArt;
import 'neferhoo_props_art.dart' show NeferhooScreen;
import 'star_pickup_art.dart';
import 'star_art.dart';
import 'alley_pigeon_overlay_art.dart';
import 'arrival_art.dart';
import 'gargoyle_feather_art.dart';
import 'gate_art.dart';
import 'obstacle_art.dart';
import 'combat_art.dart';
import 'boss_art.dart';
import 'boss_power_up_art.dart';
import 'boss_vanguard_art.dart';
import 'heart_pickup_art.dart';
import 'door_art.dart';
import 'duel_art.dart';
import 'finish_celebration_art.dart';
import 'gale_art.dart';
import 'rush_art.dart';
import 'sprint_art.dart';
import 'knockout_art.dart';
import 'steam_geyser_art.dart';
import 'straggler_art.dart';
import 'tether_art.dart';
import 'flight_voices.dart' show FlightSpeech;

class BirdGame extends FlameGame {
  BirdGame({
    required this.simulation,
    required this.nowMs,
    required this.bird,
    required this.reducedMotion,
    required this.onChanged,
    this.advance,
    this.playback = false,
    this.transparent = false,
    this.knockout,
    this.finish,
    this.seat,
    this.speech,
    this.partnerBird,
  });
  FlightSimulation simulation;
  final void Function(double dt, double now, double width)? advance;
  final bool playback;
  bool transparent;
  final double Function() nowMs;
  final int bird;

  /// Player 2's bird on a co-op flight; null flies [bird] as its partner.
  final int? partnerBird;
  int _birdOf(int player) => player == 0 ? bird : partnerBird ?? bird;
  final bool reducedMotion;
  final void Function() onChanged;

  /// Seconds since a fatal bump while its knockout plays, held at the end
  /// under the game-over stage. Null keeps the plain ended frame (replays).
  final double? Function()? knockout;

  /// Seconds since the bird crossed a campaign level's finish line while
  /// its celebration plays ([FinishCelebrationArt]), held once it settles.
  /// Null for every other frame.
  final double? Function()? finish;

  /// Where the level result's courier sits on a [size] screen, for the
  /// celebrating bird to land in; null leaves it hovering past the gate.
  final CourierSeat? Function(Size size)? seat;

  /// Who is talking this frame (the bird or the boss), with the mood and
  /// mouth to draw; null in silence, and always in replays.
  final FlightSpeech? Function()? speech;

  /// Leaves the flight's bird, and everything drawn around it, out of the
  /// frame. A campaign level's result shows its own courier over the frozen
  /// finish.
  bool hideBird = false;
  double _notify = 0;
  // Decorative motion follows the simulation clock, including pause and seek.
  double get _time => simulation.elapsed;
  final List<double> _frameDurations = [];
  double get renderHz => _frameDurations.isEmpty
      ? 0
      : _frameDurations.length / _frameDurations.reduce((a, b) => a + b);
  double get p95FrameMs {
    if (_frameDurations.isEmpty) return 0;
    final frames = [..._frameDurations]..sort();
    return frames[((frames.length - 1) * .95).ceil()] * 1000;
  }

  @override
  Color backgroundColor() =>
      transparent ? const Color(0x00000000) : SkyColors.sky;
  @override
  void update(double dt) {
    super.update(dt);
    if (size.y <= 0) return;
    if (simulation.phase == RunPhase.playing && dt > 0) {
      _frameDurations.add(dt);
      if (_frameDurations.length > 600) _frameDurations.removeAt(0);
    }
    // Egypt's guardian builds his art's caches before the run-up starts:
    // on the arrival's first frame the build can outlast the half second
    // after which a playing flight ends as stalled (see
    // [NeferhooEncounterArt.prewarmAhead]).
    if (simulation.plan case LevelPlan(boss: BossKind.neferhoo)
        when simulation.phase == RunPhase.countdown &&
            !NeferhooEncounterArt.warm) {
      NeferhooEncounterArt.prewarmAhead();
    }
    if (playback) return;
    if (advance != null) {
      advance!(dt, nowMs(), size.x / size.y);
    } else {
      simulation.tick(
        dt,
        nowMs(),
        viewportWidth: size.x / size.y,
        reducedMotion: reducedMotion,
      );
    }
    _notify += dt;
    if (_notify >= .05 || simulation.phase == RunPhase.ended) {
      _notify = 0;
      onChanged();
    }
  }

  /// The world's zoom while the camera is shaken by [shake] (pixels) on a
  /// [w] by [h] screen. The shaken world is slid by the offset, so it has to be
  /// scaled up a little about the screen's centre or its edge shows; the zoom
  /// is that much and no more: exactly 1 at rest, `1 + 2.2 * max(|dx| / w,
  /// |dy| / h)` while it shakes (2.2 is a little over the 2.0 the edges
  /// need). It used to be a constant 1.018 whenever the offset was not zero,
  /// which popped the whole picture 1.8% on the first frame of every hit
  /// and back on the last, however small the shake.
  static double shakeZoom(Offset shake, double w, double h) {
    if (shake == Offset.zero ||
        !(w > 0 && h > 0) ||
        !(shake.dx.isFinite && shake.dy.isFinite)) {
      return 1.0;
    }
    return 1 + 2.2 * math.max(shake.dx.abs() / w, shake.dy.abs() / h);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final w = size.x, h = size.y;
    if (h <= 0) return;
    // Egypt's guardian keeps his tags clear of the HUD in the safe area.
    NeferhooScreen.insets =
        buildContext
            ?.getInheritedWidgetOfExactType<MediaQuery>()
            ?.data
            .padding ??
        EdgeInsets.zero;
    final ko = knockout?.call();
    final fin = ko == null ? finish?.call() : null;
    // Who is talking: the boss's face and the bird's follow the line.
    final said = speech?.call();
    if (ko != null) _knockoutWorld(canvas, ko, w, h);
    if (fin != null) _finishWorld(canvas, fin, w, h);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w, h));
    final shake =
        (BossArt.cameraOffset(simulation.boss, reducedMotion) +
            RushArt.cameraOffset(simulation, reducedMotion) +
            GaleArt.cameraOffset(simulation, reducedMotion) +
            (ko == null
                ? Offset.zero
                : KnockoutArt.cameraOffset(ko, reducedMotion: reducedMotion)) +
            (fin == null
                ? Offset.zero
                : FinishCelebrationArt.cameraOffset(
                    fin,
                    reducedMotion: reducedMotion,
                  ))) *
        h;
    if (shake != Offset.zero) {
      canvas.translate(w / 2, h / 2);
      canvas.scale(shakeZoom(shake, w, h));
      canvas.translate(-w / 2 + shake.dx, -h / 2 + shake.dy);
    }
    if (!transparent) {
      SkyScenery.paint(
        canvas,
        Size(w, h),
        seconds: simulation.elapsed,
        distance: simulation.distance,
        reducedMotion: reducedMotion,
        held: simulation.region,
      );
    }
    BossArt.backdrop(canvas, Size(w, h), simulation.boss, reducedMotion);
    RushArt.backdrop(
      canvas,
      Size(w, h),
      simulation,
      reducedMotion: reducedMotion,
    );
    GaleArt.backdrop(
      canvas,
      Size(w, h),
      simulation,
      reducedMotion: reducedMotion,
    );
    ArrivalArt.gate(
      canvas,
      h,
      simulation,
      reducedMotion: reducedMotion,
      celebration: fin,
    );
    SprintArt.streaks(
      canvas,
      Size(w, h),
      simulation,
      reducedMotion: reducedMotion,
    );
    for (final o in simulation.obstacles) {
      if (o.rubble) {
        RushArt.rubble(
          canvas,
          Size(w, h),
          o,
          simulation,
          reducedMotion: reducedMotion,
        );
        continue;
      }
      if (o.smashed) {
        RushArt.debris(
          canvas,
          h,
          o,
          simulation.elapsed - o.smashedAt!,
          reducedMotion: reducedMotion,
        );
        continue;
      }
      final x = o.x * h, width = o.width * h;
      final cleared = o.scored && !o.hit;
      final perfect = cleared && o.maxDeviation <= .075;
      if (o.hit) {
        canvas.saveLayer(
          Rect.fromLTWH(x - 8, 0, width + 16, h),
          Paint()..color = const Color(0x66ffffff),
        );
      }
      if (simulation.rulesVersion >= 13) {
        ObstacleArt.paint(
          canvas,
          o,
          h,
          seconds: simulation.elapsed,
          reducedMotion: reducedMotion,
          cleared: cleared,
          perfect: perfect,
          refined: simulation.rulesVersion >= 14,
          gardenStructures: simulation.rulesVersion >= 16,
          held: simulation.region,
        );
      } else {
        for (final passage in o.passages) {
          _tower(
            canvas,
            Rect.fromLTWH(
              passage.x * h,
              -10,
              passage.width * h,
              passage.top * h + 10,
            ),
            true,
            cleared: cleared,
            perfect: perfect,
            kind: o.kind,
          );
          _tower(
            canvas,
            Rect.fromLTWH(
              passage.x * h,
              passage.bottom * h,
              passage.width * h,
              h - passage.bottom * h + 10,
            ),
            false,
            cleared: cleared,
            perfect: perfect,
            kind: o.kind,
          );
        }
      }
      if (o.door != null) {
        DoorArt.paint(canvas, h, o, reducedMotion: reducedMotion);
      }
      if (cleared) {
        ObstacleArt.seal(
          canvas,
          Offset(x + width / 2, o.target * h),
          h,
          WorldTour.of(o, held: simulation.region),
          perfect: perfect,
        );
      }
      if (o.hit) canvas.restore();
      if (!o.scored) {
        final center = Offset(x + width / 2, o.target * h);
        final paint = Paint()
          ..color = SkyColors.white.withValues(alpha: .55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        // A closed panel shows its own health in place of the aiming mark.
        // The mark returns once the broken panel's debris has cleared.
        final open =
            o.door == null ||
            (o.door!.destroyed &&
                (reducedMotion || o.door!.destructionAge > .45));
        if (open && !o.hit) {
          canvas.drawCircle(center, h * .035, paint);
          canvas.drawCircle(
            center,
            h * .008,
            Paint()..color = SkyColors.white.withValues(alpha: .7),
          );
        }
        // The dotted approach line makes the safe height readable at a glance.
        for (var i = 1; i <= 4; i++) {
          canvas.drawCircle(
            center - Offset(h * (.10 + i * .06), 0),
            h * .003,
            Paint()..color = SkyColors.white.withValues(alpha: .25 + i * .05),
          );
        }
      }
    }
    SteamGeyserArt.vents(
      canvas,
      Size(w, h),
      simulation,
      reducedMotion: reducedMotion,
    );
    if (simulation.magnetActive) {
      for (final body in simulation.flock) {
        simulation.viewing(body, () => _magnet(canvas, h));
      }
    }
    for (final trio in simulation.starTrios) {
      if ((trio.x - .2) * h > w) continue;
      if (simulation.subtleStarRewards) {
        StarGroupAura.paint(
          canvas,
          h,
          trio,
          seconds: _time,
          reducedMotion: reducedMotion,
        );
      } else {
        StarTrioArt.paint(
          canvas,
          h,
          trio,
          seconds: _time,
          reducedMotion: reducedMotion,
        );
      }
    }
    for (final star in simulation.stars) {
      if (star.collected && simulation.subtleStarRewards) {
        StarPickupArt.paint(
          canvas,
          h,
          star,
          simulation,
          reducedMotion: reducedMotion,
        );
      }
      // A star in a pigeon's beak is drawn by the pigeon (rules version 43).
      if (star.collected ||
          star.carried ||
          star.x * h > w + h * StarArt.reach) {
        continue;
      }
      StarArt.paint(
        canvas,
        Offset(star.x * h, star.y * h),
        h * StarArt.radius,
        seconds: _time,
        reducedMotion: reducedMotion,
        // A star's course position never changes, so neither does its rhythm.
        phase: star.x + simulation.distance,
      );
      if (star.freedAt != null) {
        AlleyPigeonOverlayArt.freed(
          canvas,
          h,
          star,
          simulation.elapsed,
          reducedMotion: reducedMotion,
        );
      }
    }
    for (final heart in simulation.missedHearts) {
      HeartPickupArt.paint(
        canvas,
        h,
        heart,
        seconds: _time,
        reducedMotion: reducedMotion,
        opacity: HeartPickupArt.missedOpacity,
      );
    }
    for (final heart in simulation.heartPickups) {
      if (heart.x * h > w + h * .07) continue;
      HeartPickupArt.paint(
        canvas,
        h,
        heart,
        seconds: _time,
        reducedMotion: reducedMotion,
      );
    }
    if (simulation.duel) {
      DuelArt.boxes(
        canvas,
        Size(w, h),
        simulation,
        reducedMotion: reducedMotion,
      );
    }
    RushArt.vents(canvas, Size(w, h), simulation, reducedMotion: reducedMotion);
    RushArt.rings(canvas, Size(w, h), simulation, reducedMotion: reducedMotion);
    // A staged boss growing stronger glows behind its figure, and its rings
    // and chevrons break over it.
    BossPowerUpArt.under(
      canvas,
      Size(w, h),
      simulation,
      reducedMotion: reducedMotion,
    );
    BossArt.paint(
      canvas,
      Size(w, h),
      simulation,
      reducedMotion: reducedMotion,
      speech: said,
    );
    BossPowerUpArt.over(
      canvas,
      Size(w, h),
      simulation,
      reducedMotion: reducedMotion,
    );
    if (simulation.duel) {
      DuelArt.marks(
        canvas,
        Size(w, h),
        simulation,
        reducedMotion: reducedMotion,
      );
    }
    CombatArt.paint(canvas, h, simulation, reducedMotion: reducedMotion);
    RushArt.swarm(canvas, Size(w, h), simulation, reducedMotion: reducedMotion);
    RushArt.meteors(
      canvas,
      Size(w, h),
      simulation,
      reducedMotion: reducedMotion,
    );
    GaleArt.debris(
      canvas,
      Size(w, h),
      simulation,
      reducedMotion: reducedMotion,
    );
    // A knockout draws its own tumbling bird over the dimmed world, and the
    // finish its celebrating one over the warmed world.
    if (ko == null && fin == null && !hideBird) {
      TetherArt.rope(canvas, h, simulation, reducedMotion: reducedMotion);
      // Player 1's bird flies behind and is drawn over its partner. Only
      // player 1's bird talks.
      for (final (player, body) in simulation.flock.indexed.toList().reversed) {
        simulation.viewing(body, () {
          if (simulation.duel) {
            DuelArt.starPower(
              canvas,
              h,
              simulation,
              reducedMotion: reducedMotion,
            );
          }
          _paintFlyer(
            canvas,
            h,
            bird: player == 0 ? bird : partnerBird ?? bird,
            said: player == 0 ? said : null,
          );
          if (simulation.paired) {
            TetherArt.badge(canvas, h, simulation, player: player);
          }
        });
      }
    }
    if (simulation.duel && ko == null) {
      DuelArt.bursts(
        canvas,
        Size(w, h),
        simulation,
        reducedMotion: reducedMotion,
      );
    }
    RushArt.effects(canvas, h, simulation, reducedMotion: reducedMotion);
    GaleArt.impacts(canvas, h, simulation, reducedMotion: reducedMotion);
    RushArt.fire(canvas, Size(w, h), simulation, reducedMotion: reducedMotion);
    GaleArt.warnings(
      canvas,
      Size(w, h),
      simulation,
      reducedMotion: reducedMotion,
    );
    if (ko == null) _feedback(canvas, h);
    canvas.restore();
    BossArt.foreground(canvas, Size(w, h), simulation, reducedMotion);
    // The boss plate and banners are HUD; a knockout and its stage hide them.
    if (simulation.boss case final boss? when ko == null) {
      BossArt.healthBar(canvas, Size(w, h), boss, reducedMotion: reducedMotion);
      // The Gargoyle's feathers enter at the top edge, under the bar's strip:
      // the ones that touch it are drawn again over it (G6).
      GargoyleFeatherArt.overBar(
        canvas,
        Size(w, h),
        simulation.bossAmmo,
        boss,
        reducedMotion: reducedMotion,
      );
    }
    if (ko == null) {
      // A campaign boss's vanguard: its card, and its plate in the boss
      // plate's place until the boss arrives.
      BossVanguardArt.paint(
        canvas,
        Size(w, h),
        simulation,
        reducedMotion: reducedMotion,
      );
      // King Coo's vanguard pigeons that got away and are still owed.
      StragglerArt.owedTag(
        canvas,
        Size(w, h),
        simulation,
        reducedMotion: reducedMotion,
      );
      RushArt.banner(
        canvas,
        Size(w, h),
        simulation,
        reducedMotion: reducedMotion,
      );
    }
    if (ko != null) {
      canvas.restore();
      KnockoutArt.rope(
        canvas,
        Size(w, h),
        simulation,
        seconds: ko,
        reducedMotion: reducedMotion,
        shake: shake,
      );
      // A co-op pair tumbles together, each bird from where it was. A duel's
      // winner stays up, bright over the dimmed world, by its player tag.
      for (final (player, body) in simulation.flock.indexed.toList().reversed) {
        if (simulation.duel && body.downAt == null) {
          simulation.viewing(body, () {
            _paintFlyer(canvas, h, bird: _birdOf(player), said: null);
            TetherArt.badge(canvas, h, simulation, player: player);
          });
          continue;
        }
        simulation.viewing(
          body,
          () => KnockoutArt.paint(
            canvas,
            Size(w, h),
            simulation,
            bird: player == 0 ? bird : partnerBird ?? bird,
            seconds: ko,
            reducedMotion: reducedMotion,
            shake: shake,
            // Only player 1's bird talks.
            beak: player == 0 && said != null && said.bird ? said.mouth : 0,
          ),
        );
      }
    }
    if (fin != null) {
      canvas.restore();
      FinishCelebrationArt.paint(
        canvas,
        Size(w, h),
        simulation,
        bird: bird,
        seconds: fin,
        reducedMotion: reducedMotion,
        seat: seat?.call(Size(w, h)),
        hideBird: hideBird,
        shake: shake,
        beak: !reducedMotion && said != null && said.bird ? said.mouth : 0,
      );
    }
  }

  /// The bird [simulation] describes, with everything drawn around it: its
  /// recovery arc, star power, trail, shield, sprint and charge. A co-op
  /// flight draws each of its birds this way inside [FlightSimulation.viewing].
  void _paintFlyer(
    Canvas canvas,
    double h, {
    required int bird,
    required FlightSpeech? said,
  }) {
    final cx = simulation.birdScreenX * h, cy = simulation.birdY * h;
    // Flown lines keep their world place, measured from the solo column.
    final column = FlightSimulation.birdX * h;
    final pose = BirdPose.forFlight(
      simulation,
      reducedMotion: reducedMotion,
      bird: bird,
    );
    if (simulation.recoveryRemaining > 0) {
      // A shrinking arc explains the brief hit protection without flashing
      // the bird or making its collision position harder to read.
      final recovery = Rect.fromCircle(
        center: Offset(cx, cy),
        radius: h * .096,
      );
      canvas.drawCircle(
        recovery.center,
        recovery.width / 2,
        Paint()..color = SkyColors.cream.withValues(alpha: .2),
      );
      canvas.drawArc(
        recovery,
        -math.pi / 2,
        math.pi * 2 * (simulation.recoveryRemaining / 1.5).clamp(0, 1),
        false,
        Paint()
          ..color = SkyColors.cream
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
    if (simulation.collectsStars &&
        !simulation.subtleStarRewards &&
        simulation.multiplier == 3) {
      // Star power is a visible reward, with a quiet static form in Reduced Motion.
      for (var i = 0; i < 3; i++) {
        final angle =
            -math.pi / 2 +
            i * math.pi * 2 / 3 +
            (reducedMotion ? 0 : _time * .7);
        final sparkle =
            Offset(cx, cy) +
            Offset(math.cos(angle), math.sin(angle)) * h * .095;
        // Small collectibles circle the bird, each point facing outward.
        StarArt.mini(canvas, sparkle, h * .015, rotation: angle + math.pi / 2);
      }
    }
    if (simulation.phase == RunPhase.playing) {
      BirdTrail.paint(
        canvas,
        bird: bird,
        anchor: Offset(cx, cy),
        unit: h * .014,
        seconds: _time,
        animate: !reducedMotion,
        empowered: !simulation.subtleStarRewards && simulation.multiplier > 1,
        // Reduced Motion keeps the rigid trail instead of a swinging tail.
        path: reducedMotion
            ? null
            : [
                for (final p in simulation.flightPath.recent)
                  Offset(
                    column + (p.distance - simulation.distance) * h,
                    p.y * h,
                  ),
              ],
        flown: simulation.flightPath.flown * h,
      );
    }
    if (simulation.isTrail && simulation.shield) {
      canvas.drawCircle(
        Offset(cx, cy),
        h * .078,
        Paint()..color = SkyColors.cream.withValues(alpha: .16),
      );
      canvas.drawCircle(
        Offset(cx, cy),
        h * .078,
        Paint()
          ..color = SkyColors.teal.withValues(alpha: .8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: h * .068),
        -2.6,
        .7,
        false,
        Paint()
          ..color = SkyColors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
    final bw = h * BirdFlightMotion.size;
    // While the bird says a line its face takes the line's mood and the
    // beak follows the words; Reduced Motion keeps the beak shut.
    final voice = said != null && said.bird ? said : null;
    final beak = reducedMotion ? 0 : voice?.mouth ?? 0;
    void paintBird(Offset center) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(pose.tilt);
      canvas.scale(1 + pose.spring, 1 - pose.spring);
      BirdPuppet.paint(
        canvas,
        Rect.fromLTWH(-bw * .48, -bw * .43, bw, bw * 224 / 256),
        bird: bird,
        wing: pose.wing,
        expression: pose.expression,
        mood: voice?.mood,
        beak: beak,
      );
      canvas.restore();
    }

    RushArt.afterimages(
      canvas,
      h,
      simulation,
      reducedMotion: reducedMotion,
      paint: (center, alpha, tint) {
        canvas.saveLayer(
          Rect.fromCircle(center: center, radius: bw),
          Paint()
            ..color = SkyColors.white.withValues(alpha: alpha)
            ..colorFilter = ColorFilter.mode(
              tint.withValues(alpha: .55),
              BlendMode.srcATop,
            ),
        );
        paintBird(center);
        canvas.restore();
      },
    );
    GaleArt.buffet(canvas, h, simulation, reducedMotion: reducedMotion);
    SprintArt.aura(canvas, h, simulation, reducedMotion: reducedMotion);
    paintBird(Offset(cx, cy));
    SteamGeyserArt.feedback(
      canvas,
      Size(size.x, h),
      simulation,
      reducedMotion: reducedMotion,
    );
    CombatArt.paintCharge(canvas, h, simulation, reducedMotion: reducedMotion);
    if (pose.flapWake > 0) {
      final t = pose.flapWake;
      final fadeIn = (t / .18).clamp(0.0, 1.0);
      final opacity = ((1 - t) * .7 * fadeIn * fadeIn * (3 - 2 * fadeIn)).clamp(
        0.0,
        .7,
      );
      final wake = Paint()
        ..color = SkyColors.cream.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 2; i++) {
        final offset = h * (.024 + i * .018 + t * .03);
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(cx - h * .039, cy + offset),
            width: h * (.055 + t * .045),
            height: h * .03,
          ),
          .3,
          math.pi * .7,
          false,
          wake,
        );
      }
    }
  }

  /// Opens the layer the frozen world is drawn into during a knockout: it
  /// dims and desaturates and the camera pushes in on the bump.
  void _knockoutWorld(Canvas canvas, double ko, double w, double h) {
    final layer = KnockoutArt.worldLayer(ko, reducedMotion: reducedMotion);
    if (layer == null) {
      canvas.save();
    } else {
      canvas.saveLayer(Rect.fromLTWH(0, 0, w, h), layer);
    }
    final zoom = KnockoutArt.zoom(ko, reducedMotion: reducedMotion);
    if (zoom != 1) {
      // A duel zooms in on the bird that went down.
      final fallen = simulation.flock.firstWhere(
        (bird) => bird.downAt != null,
        orElse: () => simulation.lead,
      );
      final focus = simulation.viewing(
        fallen,
        () => KnockoutArt.focus(simulation, h),
      );
      canvas.translate(focus.dx, focus.dy);
      canvas.scale(zoom);
      canvas.translate(-focus.dx, -focus.dy);
    }
  }

  /// Opens the layer the frozen world is drawn into while the finish is
  /// celebrated: it warms and brightens and the camera punches in on the
  /// crossing.
  void _finishWorld(Canvas canvas, double t, double w, double h) {
    final layer = FinishCelebrationArt.worldLayer(
      t,
      reducedMotion: reducedMotion,
    );
    if (layer == null) {
      canvas.save();
    } else {
      canvas.saveLayer(Rect.fromLTWH(0, 0, w, h), layer);
    }
    final zoom = FinishCelebrationArt.zoom(t, reducedMotion: reducedMotion);
    if (zoom != 1) {
      final focus = FinishCelebrationArt.focus(simulation, h);
      canvas.translate(focus.dx, focus.dy);
      canvas.scale(zoom);
      canvas.translate(-focus.dx, -focus.dy);
    }
  }

  void _magnet(Canvas canvas, double h) {
    final center = Offset(simulation.birdScreenX * h, simulation.birdY * h);
    final radius = simulation.pickupRadius * h;
    final field = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            SkyColors.lavender.withValues(alpha: .02),
            SkyColors.lavender.withValues(alpha: .18),
            SkyColors.cream.withValues(alpha: .06),
          ],
          stops: const [0, .88, 1],
        ).createShader(field),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = SkyColors.cream.withValues(alpha: .30)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
    final turn = reducedMotion ? 0.0 : _time * .7;
    final arc = Paint()
      ..color = SkyColors.lavender
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      canvas.drawArc(field, turn + i * math.pi * 2 / 3, .8, false, arc);
    }
    // Field lines show which nearby stars the expanded pickup halo will catch.
    for (final star in simulation.stars) {
      if (star.collected || star.missed || star.carried) continue;
      final position = Offset(star.x * h, star.y * h);
      final separation = (position - center).distance / h;
      if (separation > .34) continue;
      final path = Path()
        ..moveTo(position.dx, position.dy)
        ..quadraticBezierTo(
          (position.dx + center.dx) / 2,
          math.min(position.dy, center.dy) - h * .04,
          center.dx,
          center.dy,
        );
      canvas.drawPath(
        path,
        Paint()
          ..color = SkyColors.cream.withValues(
            alpha: (1 - separation / .34) * .8,
          )
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _feedback(Canvas canvas, double h) {
    final dark =
        SkyPalette.at(
          simulation.elapsed,
          held: simulation.region,
        ).top.computeLuminance() <
        .22;
    final active = simulation.events
        .where(
          (e) =>
              simulation.elapsed - e.at < 1.3 &&
              // Star feedback stays at the completed group, away from the bird.
              !(simulation.subtleStarRewards &&
                  (e.kind == FlightEventKind.star ||
                      e.kind == FlightEventKind.starTrio ||
                      e.kind == FlightEventKind.streak)) &&
              !(simulation.boss?.cinematic == true &&
                  e.kind == FlightEventKind.bossDefeated) &&
              // Rush and gale banners are drawn large at the top of the screen.
              e.kind != FlightEventKind.rushWarning &&
              e.kind != FlightEventKind.rushEscaped &&
              e.kind != FlightEventKind.galeWarning &&
              e.kind != FlightEventKind.galeWeathered,
        )
        .toList();
    final messages = active
        .where((e) => e.kind != FlightEventKind.star)
        .toList();
    // A heart or the all-rings bonus outranks the smashes that follow it.
    final callouts = messages
        .where(
          (e) =>
              e.kind == FlightEventKind.heart ||
              e.kind == FlightEventKind.allRings,
        )
        .toList();
    final major = callouts.isNotEmpty
        ? callouts.last
        : messages.isEmpty
        ? null
        : messages.last;
    for (final event in active) {
      final age = simulation.elapsed - event.at;
      final t = (age / 1.3).clamp(0.0, 1.0);
      final alpha = (1 - t * t).clamp(0.0, 1.0);
      final center = Offset(FlightSimulation.birdX * h, event.y * h);
      final color = switch (event.kind) {
        FlightEventKind.hit ||
        FlightEventKind.heart ||
        FlightEventKind.scorched => SkyColors.coral,
        FlightEventKind.sprintRing ||
        FlightEventKind.allRings => SkyColors.yellow,
        FlightEventKind.shieldReady ||
        FlightEventKind.shieldUsed => SkyColors.teal,
        FlightEventKind.magnet => SkyColors.purple,
        _ => SkyColors.gold,
      };
      final gate =
          event.kind == FlightEventKind.perfect ||
          event.kind == FlightEventKind.milestone;
      if (!reducedMotion && gate) {
        // Gate rewards burst in the materials of the region they happened in.
        RegionBurst.paint(
          canvas,
          WorldTour.at(event.at, held: simulation.region).dominant,
          center,
          h,
          t: t,
          alpha: alpha,
          perfect: event.kind == FlightEventKind.perfect,
        );
      } else if (!reducedMotion) {
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          final radius = h * (.05 + t * .13);
          final pos = center + Offset(math.cos(a), math.sin(a)) * radius;
          StarArt.sparkle(
            canvas,
            pos,
            h * .01 * (1 - t),
            color.withValues(alpha: alpha),
            rotation: a + math.pi / 2,
          );
        }
      }
      // Keep one major callout plus pickup points, so simultaneous rewards stay legible.
      if (event.kind != FlightEventKind.star && major != event) {
        continue;
      }
      final label = switch (event.kind) {
        FlightEventKind.star => '+${event.value}',
        FlightEventKind.heart => '+1 LIFE!',
        FlightEventKind.starTrio => 'STAR TRIO +${event.value}!',
        FlightEventKind.enemyHit =>
          event.value > 0 ? 'NICE SHOT +${event.value}!' : 'NICE SHOT!',
        FlightEventKind.enemyRammed =>
          event.value > 0 ? 'SMASH +${event.value}!' : 'SMASH!',
        FlightEventKind.bossDefeated =>
          event.value > 0 ? 'BOSS DOWN +${event.value}!' : 'BOSS DOWN!',
        FlightEventKind.streak => '${event.value}× STAR POWER!',
        FlightEventKind.perfect =>
          event.value > 1 ? 'PERFECT ×${event.value}' : 'PERFECT!',
        FlightEventKind.shieldReady => 'SHIELD READY',
        FlightEventKind.shieldUsed => 'SHIELD SAVE!',
        FlightEventKind.hit => 'KEEP FLYING!',
        FlightEventKind.milestone => '${event.value} GATES!',
        FlightEventKind.finalStretch => '10 SECONDS LEFT',
        FlightEventKind.magnet => 'STAR MAGNET!',
        FlightEventKind.sprintRing =>
          event.value > 1 ? 'RUSH ×${event.value}!' : 'SPRINT RING!',
        FlightEventKind.smashed =>
          event.value > 1
              ? 'SMASH ×${event.value}!'
              : 'SMASH +${Rush.smashPoints}!',
        FlightEventKind.meteorSmashed =>
          event.value > 1
              ? 'SMASH ×${event.value}!'
              : 'METEOR +${Rush.meteorPoints}!',
        FlightEventKind.swarmSmashed =>
          event.value > 1
              ? 'SMASH ×${event.value}!'
              : 'BAT +${Rush.batPoints}!',
        FlightEventKind.scorched => 'SCORCHED!',
        FlightEventKind.allRings => 'ALL RINGS! +${event.value}s BOOST',
        FlightEventKind.rushWarning ||
        FlightEventKind.rushEscaped ||
        FlightEventKind.galeWarning ||
        FlightEventKind.galeWeathered => '',
      };
      final text = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w600,
            fontSize: h * (event.kind == FlightEventKind.star ? .045 : .038),
            color: (dark ? SkyColors.cream : SkyColors.ink).withValues(
              alpha: alpha,
            ),
            shadows: [
              Shadow(
                color: (dark ? SkyColors.ink : SkyColors.white).withValues(
                  alpha: alpha,
                ),
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final rise = reducedMotion ? 0.0 : t * h * .06;
      final labelY = event.kind == FlightEventKind.star
          ? center.dy + h * .025
          : center.dy + h * (event.y < .3 ? .16 : -.14);
      text.paint(
        canvas,
        Offset(center.dx + h * .09, (labelY - rise).clamp(h * .16, h * .85)),
      );
    }
  }

  void _tower(
    Canvas canvas,
    Rect bounds,
    bool top, {
    required bool cleared,
    required bool perfect,
    ObstacleKind kind = ObstacleKind.garden,
  }) {
    if (bounds.right < 0 || bounds.left > size.x) return;
    GateArt.paint(
      canvas,
      bounds,
      top: top,
      kind: kind,
      seconds: simulation.elapsed,
      held: simulation.region,
      reducedMotion: reducedMotion,
      cleared: cleared,
      perfect: perfect,
    );
  }
}
