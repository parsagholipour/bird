/// Hold-to-charge tuning for touch combat (rules version 28).
///
/// Charge is a continuous amount from 0 (a tap) to 1 (a full second held).
/// Damage, rock size and the share of the ammo reserve spent all interpolate
/// linearly with it, so every hold length produces a distinct shot. A shot
/// that has reached 1 fires on its own after [maxFullHoldSeconds].
abstract final class PowerShot {
  static const fullChargeSeconds = 1.0;

  /// How long a fully charged rock may stay held before it releases itself.
  static const maxFullHoldSeconds = .5;

  /// Shares of a reserve of 1. A tap spends a tenth; a full charge nearly half.
  static const tapCost = .10, fullCost = .45;

  /// Every shot restarts the refill delay, so firing faster than this drains
  /// the reserve without any recovery in between.
  static const refillDelay = .45, refillPerSecond = .40;

  static const fullDamageScale = 4.0, fullRadiusScale = 2.4;

  static double cost(double charge) => tapCost + (fullCost - tapCost) * charge;

  static int damage(int weaponDamage, double charge) =>
      (weaponDamage * (1 + (fullDamageScale - 1) * charge)).round();

  static double radiusScale(double charge) =>
      1 + (fullRadiusScale - 1) * charge;

  // Repeated tenths do not sum exactly; a full reserve still pays ten taps.
  static bool canAfford(double reserve) => reserve >= tapCost - 1e-9;

  /// The strongest charge the reserve can pay for.
  static double affordable(double reserve) =>
      ((reserve - tapCost) / (fullCost - tapCost)).clamp(0.0, 1.0);
}
