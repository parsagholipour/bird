/// A shootable panel inside an ordinary wall opening. Its parent obstacle
/// owns its position and clock, keeping collision, artwork and replays aligned.
class SkyDoor {
  static const maxHp = 40;
  static const crumbleDuration = .45;
  double age = 0;
  int hp = maxHp;
  double lastHitAt = double.negativeInfinity, lastHitY = .5;
  double? destroyedAt;

  bool get destroyed => hp == 0;
  // Intact, cracked, chipped, crumbling, destroyed: each quarter of health
  // has a distinct silhouette as well as a different crack pattern.
  int get damageStage => ((maxHp - hp) * 4 ~/ maxHp).clamp(0, 4);
  double get destructionAge => destroyedAt == null ? 0 : age - destroyedAt!;

  void takeDamage(int damage, {required double hitY}) {
    if (damage <= 0) throw ArgumentError.value(damage, 'damage');
    if (destroyed) return;
    hp = (hp - damage).clamp(0, maxHp);
    lastHitAt = age;
    lastHitY = hitY.clamp(0.0, 1.0);
    if (destroyed) destroyedAt = age;
  }
}
