import 'dart:math' as math;

import 'game_rules.dart' show SkyStar;

/// Where an Alley Pigeon is in its raid on a star (rules version 43, New
/// York levels only). See [AlleyPigeon] for the numbers.
///
/// `FlightSimulation` (pigeon_rules.dart) drives a pigeon through these in
/// order: [glide] to [warning] to [dive], then [carry] after a snatch, or
/// [flee] when a hit spooks it or frees the star.
enum PigeonPhase {
  /// Arriving and hovering over its prey, or a pigeon with no prey at all
  /// (a boss helper, or one whose star is gone): it flaps across like a bat.
  glide,

  /// The 0.80 s telegraph: wings raised and quivering, crouch, ring on the
  /// prey. The pigeon faces right (toward its prey) from here on.
  warning,

  /// The 0.44 s dive, a quarter ellipse to the live star.
  dive,

  /// The star is in its beak: the 0.65 s gloat, then the climb away.
  carry,

  /// Leaving without a star: spooked before the snatch, or the star was
  /// freed by a hit. A second hit still kills it.
  flee,
}

/// The Alley Pigeon's constants and pure motion functions (spec:
/// `reports/02-alley-pigeon.md` §2). Every function is a pure function of
/// its arguments, so seeks and replays stay exact. Heights are screen
/// heights, x is in screen heights from the left edge, times are seconds.
abstract final class AlleyPigeon {
  /// The telegraph, the dive, the gloat in the lane after the snatch, and
  /// roughly how long a thief needs to leave the screen.
  static const warningSeconds = .80, diveSeconds = .44;
  static const gloatSeconds = .65, fleeSeconds = 2.2;

  /// A pigeon starts its warning when its prey satisfies
  /// `prey.x <= min(width - warnEdge, warnReach)` and
  /// `prey.x - warnLead * speed >= birdX + warnGuard` (see [mayWarn]).
  static const warnEdge = .10, warnReach = 1.80;
  static const warnLead = 1.3, warnGuard = .40;

  /// A dive whiffs into a flee when its prey is this close to the bird.
  static const whiffGuard = .10;

  /// A pigeon that has left the screen: above it, below it, past the right
  /// edge or (dragged back by a sprint) past the left one. A thief that gets
  /// this far away takes its star for good.
  static const leaveTop = -.10, leaveBottom = 1.10;
  static const leaveRight = .20, leaveLeft = -.10;

  /// A star won back by a ram or by touch drops into the bird's beak, this
  /// far in front of it.
  static const dropX = .035;

  /// A level's flocks have one to three pigeons.
  static const minFlock = 1, maxFlock = 3;

  /// Where slot `j` of a formation hovers: x from its prey star, and how far
  /// above (or below) the lane.
  static const hoverX = [-.19, -.10, -.27];
  static const hoverRise = [.30, .44, .16];
  static const hoverMin = .12, hoverMax = .88;

  /// The stars of a passage's trio sit at these x offsets from the passage.
  static const trioX = [-.42, -.25, -.08];

  /// Idle bob amplitude, and the per-spawn phase step of the flight clock.
  static const bob = .010, phaseStep = 2.399963;

  /// A freed star hops and floats back to its gate line.
  static const floatSeconds = .45, hopHeight = .05, hopSeconds = .30;

  /// The most stars a level's pigeons may take for good, so its three-star
  /// mark stays reachable for a player who never shoots: half of the slack
  /// between the route's stars and the mark (spec section 2, "Numbers").
  static int thiefCap({required int routeStars, required int threeStarMark}) =>
      math.max(0, (routeStars - threeStarMark) ~/ 2);

  /// Whether a pigeon at ([x], [y]) has left the screen [width] wide.
  static bool leaves({
    required double x,
    required double y,
    required double width,
  }) =>
      y < leaveTop ||
      y > leaveBottom ||
      x > width + leaveRight ||
      x < leaveLeft;

  /// The side a formation hovers on: above the lane (-1) when the lane is
  /// in the lower half of the screen, else below (+1).
  static int sideFor(double lane) => lane >= .5 ? -1 : 1;

  /// Which stars of one passage's trio (0, 1, 2) a formation of [flock]
  /// pigeons is bound to. [draw] is the one `nextInt` from the level's
  /// flock random: `nextInt(3)` for one pigeon, `nextInt(2)` for two.
  static List<int> preySlots(int flock, int draw) {
    if (flock < minFlock || flock > maxFlock) {
      throw RangeError.range(flock, minFlock, maxFlock, 'flock');
    }
    return switch (flock) {
      1 => [draw % 3],
      2 => [0, 1 + draw % 2],
      _ => const [0, 1, 2],
    };
  }

  /// Where slot [slot] hovers for prey at [preyX] on [lane], on [side].
  static ({double x, double y}) hover({
    required int slot,
    required double preyX,
    required double lane,
    required int side,
  }) {
    final room = side < 0 ? lane - hoverMin : hoverMax - lane;
    return (
      x: preyX + hoverX[slot],
      y: lane + side * math.min(hoverRise[slot], math.max(0.0, room)),
    );
  }

  /// The glide in from above-right (below-right on the low side) until the
  /// home nears the right edge: the offset from home, `a` running 1 to 0.
  static ({double dx, double dy}) arrival({
    required double homeX,
    required double width,
    required int side,
  }) {
    final a = ((homeX - (width - .30)) / .45).clamp(0.0, 1.0);
    final shift = .35 * a * a;
    return (dx: shift, dy: side * shift);
  }

  /// Whether a pigeon with prey at [preyX] may begin its warning: on screen
  /// enough, and far enough from the bird that the dive is fair at [speed].
  static bool mayWarn({
    required double preyX,
    required double birdX,
    required double width,
    required double speed,
  }) =>
      preyX <= math.min(width - warnEdge, warnReach) &&
      preyX - warnLead * speed >= birdX + warnGuard;

  /// The dive at [u] (0 to 1) from the hover [home] to the live star [star]:
  /// vertical start, horizontal finish, accelerating.
  static ({double x, double y}) dive(
    double u,
    ({double x, double y}) home,
    ({double x, double y}) star,
  ) {
    final theta = math.pi / 2 * math.pow(u.clamp(0.0, 1.0), 1.7);
    return (
      x: star.x - (star.x - home.x) * math.cos(theta),
      y: home.y + (star.y - home.y) * math.sin(theta),
    );
  }

  /// The gloat and climb, [tau] seconds after the snatch: the offset from the
  /// snatch point. The thief drifts right, then climbs away on its [side].
  static ({double dx, double dy}) flee(double tau, int side) {
    final t = math.max(0.0, tau);
    final late = math.max(0.0, t - gloatSeconds);
    return (dx: .70 * t, dy: side * .30 * late * late);
  }

  /// A freed star, [tau] seconds after the hit: it hops and floats back to
  /// its gate line [lane] from [y0].
  static double floatY(double tau, double y0, double lane) {
    final t = math.max(0.0, tau);
    return lane +
        (y0 - lane) * math.exp(-t / floatSeconds) -
        hopHeight * math.sin(math.pi * math.min(t / hopSeconds, 1.0));
  }
}

/// One Alley Pigeon's raid, the state the art, audio and UI read from
/// `SkyEnemy.pigeon`. Phases advance with the enemy's own `age` clock: the
/// time in a phase is `age - phaseAt`, so every pose is a pure function of
/// the simulation and seeks are exact.
///
/// The rules (pigeon_rules.dart) write everything here; nothing else does.
class PigeonFlight {
  PigeonFlight({this.slot = 0, this.flockSize = 1, this.side = -1});

  /// Its place in the formation (0 to 2), the formation's size (1 to 3), and
  /// the side it hovers on: -1 above the lane, +1 below. Set once, when the
  /// formation is laid.
  int slot, flockSize, side;

  PigeonPhase phase = PigeonPhase.glide;

  /// The enemy's `age` when [phase] began. A hit that frees a thief's star
  /// leaves it, so the climb away carries on smoothly.
  double phaseAt = 0;

  /// The star this pigeon is bound to, reserved for it from the moment the
  /// formation is laid, or null for a pigeon with no prey (or one that has
  /// lost it: collected, missed, too close to dive at, or spooked off).
  SkyStar? prey;

  /// The star in its beak while [PigeonPhase.carry]s, else null.
  SkyStar? loot;

  /// When it snatched (the enemy's `age`), or negative infinity.
  double snatchedAt = double.negativeInfinity;

  /// A damaging hit before the snatch spooked it: it flees with no star.
  bool spooked = false;

  /// Its home: the spot it hovers over (x scrolls with the course), or from
  /// where a flee or a gloat starts; [pathX] and [pathY] are where the raid
  /// put it last, before the flight bob. Rules bookkeeping, render-free.
  double homeX = 0, homeY = .5;
  double pathX = 0, pathY = .5;

  /// The latest hit of the enemy this raid has seen (`SkyEnemy.lastHitAt`).
  double seenHitAt = double.negativeInfinity;

  /// Whether a level laid this pigeon as part of a formation. A pigeon that
  /// did not come that way (a boss helper drawn from a lineup) has no home
  /// and no prey: it flies the course like a bat that fires nothing.
  bool laid = false;

  /// Whether a star rides in its beak.
  bool get carrying => loot != null && phase == PigeonPhase.carry;

  /// Whether it has a star it still means to take.
  bool get hunting =>
      prey != null &&
      (phase == PigeonPhase.warning ||
          phase == PigeonPhase.dive ||
          phase == PigeonPhase.glide);

  /// The pigeon faces left until its warning, then right toward its prey.
  bool get facingRight => phase != PigeonPhase.glide;

  double _since(double age) => math.max(0.0, age - phaseAt);

  /// 0 to 1 through the warning, else 0. The enemy's `charge` for a pigeon.
  double warning(double age) => phase == PigeonPhase.warning
      ? (_since(age) / AlleyPigeon.warningSeconds).clamp(0.0, 1.0)
      : 0;

  /// 0 to 1 through the dive, else 0.
  double dive(double age) => phase == PigeonPhase.dive
      ? (_since(age) / AlleyPigeon.diveSeconds).clamp(0.0, 1.0)
      : 0;

  /// Seconds since the snatch (or since it began to flee), else 0.
  double fleeTime(double age) =>
      phase == PigeonPhase.carry || phase == PigeonPhase.flee ? _since(age) : 0;

  /// 1 at the snatch, falling to 0 over 0.24 s: the beak's kick.
  double kick(double age) {
    if (!snatchedAt.isFinite) return 0;
    return (1 - (age - snatchedAt) / .24).clamp(0.0, 1.0);
  }
}
