import 'dart:math' as math;

import 'flight_plan.dart';
import 'sky_boss.dart';

/// What a duel's mystery box holds: an attack sent after the rival of the
/// bird that opened it, or a help for that bird.
enum BoxPrize {
  /// A line of swarm bats streams in at the rival's height.
  batSwarm,

  /// A spitter beetle lingers ahead of the rival and spits at it.
  spitter,

  /// Meteors fall where the rival is flying, one after another.
  meteorShower,

  /// One more heart, up to [Duel.maxHearts].
  heart,

  /// A shield that takes the next hit.
  shield,

  /// [Duel.starPowerSeconds] of star power: nothing hurts the bird, it
  /// smashes what it touches, and touching its rival hurts the rival.
  starPower;

  /// Whether it is sent after the rival rather than kept.
  bool get attack => index < heart.index;

  String get title => switch (this) {
    batSwarm => 'Bat swarm',
    spitter => 'Spitter beetle',
    meteorShower => 'Meteor shower',
    heart => 'Heart',
    shield => 'Shield',
    starPower => 'Star power',
  };
}

/// A mystery box floating on a duel's course. A bird opens it by flying
/// into it or by hitting it with a rock, and the [prize] is that bird's.
class MysteryBox {
  MysteryBox({required this.x, required this.y, required this.phase});

  /// Screen position in viewport heights; the box scrolls with the course.
  double x;
  final double y;

  /// Where the box's bob starts. Presentation only.
  final double phase;

  /// When it was opened, by which player, and what it held.
  double? openedAt;
  int? opener;
  BoxPrize? prize;
  bool get opened => openedAt != null;

  static const radius = .042;

  /// How long an opened box stays for its burst.
  static const burstSeconds = 1.0;
}

/// Meteors a [BoxPrize.meteorShower] has still to drop on [sender]'s rival.
class MeteorShower {
  MeteorShower({required this.sender, required this.nextAt});
  final int sender;
  double nextAt;
  int left = Duel.showerMeteors;
}

/// Duel tuning (rules version 42).
///
/// Two birds fly the same column, one above the other, so neither starts
/// with a shot at the other: a bird's rock can only hit its rival once one
/// has surged ahead, as a sprint does. From rules version 63 they fly
/// through each other rather than bump. Each bird has its own hearts and
/// shield; its own stars charge its shield. Every other passage carries a
/// [MysteryBox] off its star line, and nothing else attacks: no boss, no
/// set piece and no ordinary enemy, so every enemy in the sky was sent by
/// one of the players. The first bird to lose its last heart loses; two
/// knocked out on the same step draw.
abstract final class Duel {
  /// Where players 1 and 2 start, above and below the middle of the sky.
  static const startHeights = [.38, .62];

  /// Hearts a box's heart can heal up to, as in a solo flight.
  static const maxHearts = 5;

  /// The first passage (counted from 1) that carries a box, and how many
  /// passages apart they follow.
  static const firstBoxPassage = 2, boxEvery = 2;

  /// A box floats this far ahead of its passage, where an endless enemy
  /// would lead it, and [boxOffset] plus up to [boxSpread] above or below
  /// the passage's aiming height.
  static const boxLead = .55, boxOffset = .15, boxSpread = .07;

  /// The highest and lowest a box floats.
  static const boxTop = .14, boxBottom = .86;

  /// A [BoxPrize.batSwarm] sends this many bats, [batSpacing] apart.
  static const swarmSize = 5, batSpacing = .09;

  /// A sent spitter beetle closes in at this share of the course speed, so
  /// it stays in range for a few volleys.
  static const spitterDrift = .42;

  /// A [BoxPrize.meteorShower] drops this many meteors, [showerInterval]
  /// seconds apart, the first [showerDelay] after the box opens.
  static const showerMeteors = 3, showerInterval = .6, showerDelay = .3;

  static const starPowerSeconds = 5.0;

  /// What a box holds: an attack or a help, even odds, then one of three.
  /// A help the bird cannot use (a heart at full hearts, a second shield)
  /// becomes one it can.
  static BoxPrize roll(
    math.Random random, {
    required int hearts,
    required bool shield,
  }) {
    final attack = random.nextBool();
    final pick = random.nextInt(3);
    if (attack) return BoxPrize.values[pick];
    var prize = BoxPrize.values[BoxPrize.heart.index + pick];
    if (prize == BoxPrize.heart && hearts >= maxHearts) {
      prize = shield ? BoxPrize.starPower : BoxPrize.shield;
    }
    if (prize == BoxPrize.shield && shield) {
      prize = hearts < maxHearts ? BoxPrize.heart : BoxPrize.starPower;
    }
    return prize;
  }

  /// The height of a box ahead of a passage aimed at [target]: above or
  /// below it as [random] says, flipped when that side has no room.
  static double boxHeight(double target, math.Random random) {
    final above = random.nextBool();
    final offset = boxOffset + random.nextDouble() * boxSpread;
    var y = above ? target - offset : target + offset;
    if (y < boxTop || y > boxBottom) {
      y = above ? target + offset : target - offset;
    }
    return y.clamp(boxTop, boxBottom);
  }
}

/// A duel's course: the endless one, without its bosses, set pieces,
/// ordinary enemies and heart pickups. Boxes bring the fight instead.
class DuelPlan extends EndlessPlan {
  const DuelPlan();

  @override
  int? enemyIndex(int passage) => null;
  @override
  double get firstBossAt => double.infinity;
  @override
  bool get heartPickups => false;
  @override
  double get firstRushAt => double.infinity;
  @override
  double? galeAfter(BossKind kind) => null;
}
