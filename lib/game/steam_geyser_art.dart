import 'dart:math' as math;
import 'dart:ui';

import '../domain/game_rules.dart';
import 'steam_geyser_emitter_art.dart';
import 'steam_geyser_kit.dart';
import 'steam_geyser_plume_art.dart';

export 'steam_geyser_kit.dart' show SteamBeat;

/// Steam Geysers: rooftop vents that hiss, burst and billow (rules version
/// 43, "New York").
///
/// A vent's STATE (which phase, how high the plume stands, how hard the
/// billow lifts) is a pure function of the route clock, `sim.routeSeconds`;
/// its DECORATION (wisps, sway, chatter, climbing chevrons) is a pure
/// function of the simulation clock, `sim.elapsed`, and Reduced Motion holds
/// that still while the state carries on, so each phase keeps its own still
/// frame. No `DateTime`, no random, no shader, no blur, no `saveLayer`; a
/// vent costs at most [maxOpsPerVent] draw calls in any state.
///
/// Drawn after the obstacles and before the stars, enemies and the bird, so
/// steam never hides the bird or a star; `BirdGame` makes the two calls.
abstract final class SteamGeyserArt {
  /// The budget: draw calls for one vent in any state, and for a frame.
  static const maxOpsPerVent = 80, maxOpsPerFrame = 160;

  /// The vents on screen: each one's emitter and steam, behind the stars,
  /// the enemies and the bird.
  static void vents(
    Canvas canvas,
    Size size,
    FlightSimulation sim, {
    required bool reducedMotion,
  }) {
    final h = size.height, w = size.width;
    if (h <= 0) return;
    final clock = reducedMotion ? 0.0 : sim.elapsed;
    for (final vent in sim.steamVents) {
      final cx = vent.x * h;
      if (cx < -h * .45 || cx > w + h * .45) continue;
      paintVent(canvas, h, cx, vent, sim.routeSeconds, clock, reducedMotion);
    }
  }

  /// One vent at route time [route] with decoration clock [clock], for the
  /// previews and the tests as well as the game.
  static void paintVent(
    Canvas c,
    double h,
    double cx,
    SteamVent v,
    double route,
    double simClock,
    bool rm,
  ) {
    // Reduced Motion holds the decoration still whatever the clock says.
    final clock = rm ? 0.0 : simClock;
    final b = SteamBeat.of(v, route);
    // Where the steam shows: the mouth, or a tall stack's lip a little above.
    final mouthY = SteamEmitterArt.lipY(v, h), topY = v.top * h;
    final seed = (v.top * 977).round() + v.geyser.slot * 31;
    final hot = v.kind == SteamKind.hop;
    final tone = SteamEmitterArt.mouthTone(v.kind, b);
    final roofY = h * (SteamEmitterArt.slab - .004);
    // How far the cloud has taken over from the burst: it starts to rise
    // round the jet at +0.30 s, so by the time the jet falls (from +0.42 s)
    // the silhouette is already whole and never dips.
    final cross = SteamMath.smooth((b.t - .30) / .14);
    final body = hot ? SteamTones.hotBody : SteamTones.coolBody;
    // The cloud's foot spreads to full width only once the jet is gone.
    final settle = SteamMath.smooth((b.t - .44) / .12);
    final foot = .88 + .12 * settle;

    if (b.heat > 0) {
      // A ride vent's light is teal from first to last: nothing warm on it.
      SteamPlumeArt.glow(
        c,
        h,
        Offset(cx, mouthY),
        b.heat,
        !hot
            ? SteamTones.tealGlow
            : b.billow
            ? Color.lerp(SteamTones.amber, SteamTones.coolBody, b.cooled)!
            : tone,
      );
    }
    switch (b.phase) {
      case SteamPhase.hiss:
        SteamPlumeArt.ghost(c, h, cx, mouthY, topY, b.p, clock, rm, hot: hot);
        SteamPlumeArt.wisps(
          c,
          h,
          cx,
          mouthY,
          b.p,
          clock,
          seed,
          rm,
          body,
          n: 2 + (b.p * 1.6).floor(),
        );
      case SteamPhase.burst:
        final top = v.plumeTop(route) * h;
        if (!rm) SteamPlumeArt.flash(c, h, cx, mouthY, b.p, hot: hot);
        if (hot) {
          SteamPlumeArt.mist(c, h, cx, mouthY, b.p, rm);
          SteamPlumeArt.burst(c, h, cx, mouthY, top, b.p, clock, seed, rm);
          // The cloud rises round the jet, in front of it, so the jet sinks
          // into the cloud: no empty lid, no hole, no ghost of the jet's rim.
          if (cross > 0) {
            SteamPlumeArt.billow(
              c,
              h,
              cx,
              mouthY,
              topY,
              clock,
              seed,
              cross,
              0,
              rm,
              crossing: true,
              updraft: 0,
              foot: foot,
            );
          }
        } else {
          // A ride vent never scalds: its burst is this same soft cool
          // cloud swelling up, so the shape says "helps" before the colour.
          final frac = ((mouthY - top) / (mouthY - topY)).clamp(0.0, 1.0);
          final own = cross > 0
              ? .30 + .70 * SteamMath.smooth(cross / .9)
              : 0.0;
          SteamPlumeArt.billow(
            c,
            h,
            cx,
            mouthY,
            topY,
            clock,
            seed,
            1,
            1,
            rm,
            height: math.max(frac, own),
            updraft: SteamMath.smooth((b.t - .10) / .2),
            foot: foot,
          );
        }
        // The warning outline lingers a moment over the first beats of the
        // bang (it is what the steam is filling), so nothing pops.
        if (b.t < .10) {
          SteamPlumeArt.ghost(
            c,
            h,
            cx,
            mouthY,
            topY,
            1,
            clock,
            rm,
            hot: hot,
            fade: 1 - b.t / .10,
            lite: true,
          );
        }
        if (!rm) {
          SteamPlumeArt.spray(c, h, cx, top, roofY, b.p, seed, rm, hot: hot);
        }
      case SteamPhase.billow:
        final e = v.geyser.liftAt(route);
        SteamPlumeArt.billow(
          c,
          h,
          cx,
          mouthY,
          topY,
          clock,
          seed,
          // (the cloud's first beats follow the burst's cross-dissolve; once the
          // lift is up only the lift's own envelope shapes it)
          b.billowT < .3 ? math.max(e, cross) : e,
          hot ? b.cooled : 1,
          rm,
          updraft: settle,
          foot: foot,
        );
      case SteamPhase.sleep:
        SteamPlumeArt.wisps(c, h, cx, mouthY, .15, clock, seed, rm, body, n: 2);
    }
    // The spurts come out from under the lid, so they go in before it.
    if (b.hiss) {
      SteamPlumeArt.spurts(c, h, cx, mouthY, b.p, clock, rm, hot: hot);
    }
    SteamEmitterArt.paint(c, h, cx, v, b, clock, rm, seed);
    // The glare over the lid: white-hot as the steam leaves it.
    if (b.burst) SteamPlumeArt.nozzle(c, h, cx, mouthY, b.p, clock, rm, hot);
  }

  /// The bird's side of the steam, drawn over the world after the bird: a
  /// ring of puffs around a scald, and lift streaks under a bird riding a
  /// billow. Small and outline-only, never over the bird itself.
  static void feedback(
    Canvas canvas,
    Size size,
    FlightSimulation sim, {
    required bool reducedMotion,
  }) {
    if (sim.steamVents.isEmpty) return;
    final h = size.height;
    if (h <= 0) return;
    final bird = Offset(sim.birdScreenX * h, sim.birdY * h);
    final clock = reducedMotion ? 0.0 : sim.elapsed;
    final since = sim.recoverySeconds - sim.recoveryRemaining;
    for (final vent in sim.steamVents) {
      final dx = (vent.x - sim.birdScreenX).abs();
      if (dx > .25) continue;
      final b = SteamBeat.of(vent, sim.routeSeconds);
      // A scald: the burst (or its last steam) just caught the bird.
      if (!reducedMotion &&
          sim.recoveryRemaining > 0 &&
          since >= 0 &&
          since < .35 &&
          (b.burst || (b.billow && b.billowT < .35)) &&
          sim.birdY > vent.top - .10) {
        _scaldRing(canvas, h, bird, since / .35);
        break;
      }
    }
    for (final vent in sim.steamVents) {
      final dx = (vent.x - sim.birdScreenX).abs();
      if (dx > SteamCycle.liftHalfWidth) continue;
      final b = SteamBeat.of(vent, sim.routeSeconds);
      final lift = vent.geyser.liftAt(sim.routeSeconds);
      if (b.billow &&
          lift > 0 &&
          sim.birdY > vent.top - .03 &&
          sim.birdY < vent.mouth) {
        _liftStreaks(canvas, h, bird, lift, clock, reducedMotion);
        break;
      }
    }
  }

  /// Six puffs ring the bird for 0.35 s, growing and fading: steam did it.
  static void _scaldRing(Canvas c, double h, Offset bird, double k) {
    final rim = Path(), fill = Path();
    final radius = h * (.075 + .055 * SteamMath.smooth(k));
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3 + .4;
      final o = bird + Offset(math.cos(a), math.sin(a)) * radius;
      final r = h * .014 * (1 - .4 * k);
      rim.addOval(Rect.fromCircle(center: o, radius: r + h * .003));
      fill.addOval(Rect.fromCircle(center: o, radius: r));
    }
    final a = 1 - k * k;
    c.drawPath(rim, Paint()..color = SteamTones.ink.withValues(alpha: .85 * a));
    c.drawPath(fill, Paint()..color = SteamTones.hotBody.withValues(alpha: a));
  }

  /// Three soft streaks falling away under a bird the billow is lifting.
  static void _liftStreaks(
    Canvas c,
    double h,
    Offset bird,
    double lift,
    double clock,
    bool rm,
  ) {
    final streaks = Path();
    for (var i = -1; i <= 1; i++) {
      final life = rm ? .4 + .1 * i * i : (clock * 1.6 + (i + 1) / 3) % 1;
      final y = bird.dy + h * (.045 + .075 * life);
      streaks
        ..moveTo(bird.dx + i * h * .026, y)
        ..lineTo(bird.dx + i * h * .026, y + h * .022);
    }
    c.drawPath(
      streaks,
      Paint()
        ..color = SteamTones.teal.withValues(alpha: .8 * lift)
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0055
        ..strokeCap = StrokeCap.round,
    );
  }
}
