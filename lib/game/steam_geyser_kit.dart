import 'dart:math' as math;
import 'dart:ui';

import '../domain/steam_geyser.dart';

/// Colours, shared measurements and the one "beat" value every part of a
/// steam vent's art reads. Hot steam (hop vents, every burst) is warm cream
/// over an amber root; soft steam (the billow, ride vents) is cool blue-white
/// with teal chevrons, so one glance says hurts or helps.
abstract final class SteamTones {
  /// New York's own ink (the gates and the roofs use it): bluish, not black.
  static const ink = Color(0xff1d2233);

  // Brick, limestone and iron shared with the New York gates.
  static const brickLit = Color(0xffc9765a), brick = Color(0xffa5553f);
  static const brickShade = Color(0xff6f3328);
  static const stone = Color(0xffe6dac3), stoneShade = Color(0xffb9a98c);
  static const iron = Color(0xff262a36), ironLit = Color(0xff4b5068);
  static const ironRim = Color(0xff7c86a6);

  // Hot steam: cream body, peach shade, amber root, ember heat.
  static const hotBody = Color(0xfffff2dc), hotHigh = Color(0xfffffaf0);
  static const hotShade = Color(0xfff0b48a), hotRoot = Color(0xffffd28c);
  static const amber = Color(0xffff9a3c), ember = Color(0xffe8662d);

  // Soft steam: pale blue-white, slate shade, teal.
  static const coolBody = Color(0xffeaf3ff), coolShade = Color(0xffb3c6ea);
  static const teal = Color(0xff2fb5a6), tealDeep = Color(0xff1c8a84);
  static const tealGlow = Color(0xff7be6d6);

  // Con Ed enamel.
  static const stripe = Color(0xffe8662d), stripeWhite = Color(0xfff6f0e4);
  static const stripeShade = Color(0xffc9bfae), stripeDeep = Color(0xffb8481f);

  // Gauge brass and the pigeon's slate.
  static const brass = Color(0xffd9a84a), dial = Color(0xfff6f0e4);
  static const valve = Color(0xffd8432f);
  static const pigeon = Color(0xff8d93b5), pigeonShade = Color(0xff676d92);
  static const beak = Color(0xffffb347), neck = Color(0xff5fc9a4);
}

/// Where a vent is in its cycle and how far through it, from the route clock
/// alone: every frame of the art is a pure function of this and of the
/// simulation clock (decoration only, frozen by Reduced Motion).
class SteamBeat {
  const SteamBeat._(this.phase, this.t, this.p);

  factory SteamBeat.of(SteamVent vent, double routeSeconds) {
    final t = SteamCycle.cycleTime(routeSeconds, vent.geyser.burstAt);
    if (t < 0) {
      return SteamBeat._(
        SteamPhase.hiss,
        t,
        (t + SteamCycle.hiss) / SteamCycle.hiss,
      );
    }
    if (t < SteamCycle.burst) {
      return SteamBeat._(SteamPhase.burst, t, t / SteamCycle.burst);
    }
    final b = t - SteamCycle.burst;
    if (b < SteamCycle.billow) {
      return SteamBeat._(SteamPhase.billow, t, b / SteamCycle.billow);
    }
    return SteamBeat._(SteamPhase.sleep, t, 0);
  }

  final SteamPhase phase;

  /// Route seconds since the burst began: negative through the hiss.
  final double t;

  /// 0 to 1 through the hiss, burst or billow; 0 asleep.
  final double p;

  bool get hiss => phase == SteamPhase.hiss;
  bool get burst => phase == SteamPhase.burst;
  bool get billow => phase == SteamPhase.billow;
  bool get asleep => phase == SteamPhase.sleep;

  /// Seconds into the billow, 0 outside it.
  double get billowT => billow ? t - SteamCycle.burst : 0;

  /// How hot the mouth glows: the pressure through a hiss, full in the burst,
  /// dying away over the first 0.7 s of the billow.
  double get heat => switch (phase) {
    SteamPhase.hiss => SteamMath.smooth(p),
    SteamPhase.burst => 1,
    SteamPhase.billow => 1 - SteamMath.smooth(billowT / .7),
    SteamPhase.sleep => 0,
  };

  /// How far the cloud has cooled from the burst's cream to the billow's
  /// blue-white: a front that climbs the column over the first 0.35 s.
  double get cooled => billow ? SteamMath.smooth(billowT / .35) : 0;

  /// The lid's lift in viewport heights: pressed down just before the burst,
  /// kicked up by it and settling in a few bounces. Reduced Motion never
  /// calls it; it sees [restLid].
  double get lid {
    switch (phase) {
      case SteamPhase.hiss:
        // Wind-up: a chatter that grows with pressure, then pressed down.
        final press = SteamMath.smooth((p - .86) / .14);
        return -.0032 * press;
      case SteamPhase.burst:
        final s = t;
        return .0125 * math.exp(-s * 7) * math.cos(s * 26) + .004;
      case SteamPhase.billow:
        final s = t - SteamCycle.burst;
        return .0036 * math.exp(-s * 8) * math.cos(s * 22);
      case SteamPhase.sleep:
        return 0;
    }
  }

  /// The lid's pose with no motion: lifted a hair while the burst lasts.
  double get restLid => burst ? .004 : 0;
}

/// Small pure helpers.
abstract final class SteamMath {
  /// A deterministic hash in [0, 1).
  static double hash(int a, int b) {
    final v = math.sin(a * 12.9898 + b * 78.233) * 43758.5453;
    return v - v.floorToDouble();
  }

  /// The smoothstep the simulation's envelopes use.
  static double smooth(double x) {
    final t = x.clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }
}
