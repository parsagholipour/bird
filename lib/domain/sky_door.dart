/// One blow the panel took. Kept only so the artwork can show where every hit
/// landed and how hard it was; nothing in the rules reads it.
class DoorHit {
  const DoorHit({
    required this.at,
    required this.y,
    required this.damage,
    required this.rammed,
  });

  /// The panel's own clock when the blow landed.
  final double at;

  /// Where the blow struck, in viewport-height units from the top of the view.
  final double y;

  /// Damage the blow carried, before it was clamped to the health left.
  final int damage;

  /// A sprinting bird ramming the panel, rather than a thrown rock.
  final bool rammed;

  /// 0 for a plain rock up to 1 for a full charge or a ram.
  double get power => rammed ? 1 : ((damage - 10) / 30).clamp(0.0, 1.0);
}

/// A shootable panel inside an ordinary wall opening. Its parent obstacle
/// owns its position and clock, keeping collision, artwork and replays aligned.
class SkyDoor {
  static const maxHp = 40;

  /// How long the breaking animation runs after the lethal blow. Collision is
  /// already gone from the first frame; this only paces the artwork.
  static const crumbleDuration = 1.0;
  double age = 0;
  int hp = maxHp;
  double lastHitAt = double.negativeInfinity, lastHitY = .5;
  double? destroyedAt;

  /// Every blow taken, oldest first. Read-only decoration state: it is filled
  /// from [takeDamage] and never consulted by collision, health or scoring.
  final List<DoorHit> hits = [];

  bool get destroyed => hp == 0;
  // Intact, cracked, chipped, crumbling, destroyed: each quarter of health
  // has a distinct silhouette as well as a different crack pattern.
  int get damageStage => ((maxHp - hp) * 4 ~/ maxHp).clamp(0, 4);
  double get destructionAge => destroyedAt == null ? 0 : age - destroyedAt!;

  /// How the lethal blow arrived, for the artwork.
  DoorHit? get lastHit => hits.isEmpty ? null : hits.last;

  void takeDamage(int damage, {required double hitY, bool rammed = false}) {
    if (damage <= 0) throw ArgumentError.value(damage, 'damage');
    if (destroyed) return;
    hp = (hp - damage).clamp(0, maxHp);
    lastHitAt = age;
    lastHitY = hitY.clamp(0.0, 1.0);
    hits.add(DoorHit(at: age, y: lastHitY, damage: damage, rammed: rammed));
    if (destroyed) destroyedAt = age;
  }
}
