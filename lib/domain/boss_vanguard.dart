import 'sky_boss.dart';
import 'sky_enemy.dart';

/// One small enemy of a vanguard wave: its kind, the height it flies at and
/// how far behind the wave's leader it enters (screen heights).
typedef VanguardMember = ({EnemyKind kind, double y, double behind});

/// A wave of a vanguard, [at] seconds after the vanguard begins.
class VanguardWave {
  const VanguardWave(this.at, this.members);
  final double at;
  final List<VanguardMember> members;
}

/// A campaign boss's vanguard (rules version 44): before Baron Bat, the
/// Spitter King, the Dusk Empress and King Coo show up, they send their
/// small enemies ahead in three waves. The boss arrives once every one of
/// them has been shot down, rammed or has flown past the bird.
///
/// The waves are fixed data, entering from the right like ordinary enemies
/// and flying like them, so a replay or a seek is exact. Nothing here draws
/// a random number.
class BossVanguard {
  BossVanguard({required this.boss, required this.startedAt})
    : waves = wavesOf(boss) {
    if (waves.isEmpty) throw ArgumentError.value(boss, 'boss', 'No vanguard');
  }

  /// The boss whose vanguard this is.
  final BossKind boss;

  /// The flight's elapsed seconds as the vanguard began.
  final double startedAt;
  final List<VanguardWave> waves;

  /// Waves sent so far, and the enemies they brought, in order. The rules
  /// keep the list; enemies leave the flight's own list as they go.
  int wavesSent = 0;
  final List<SkyEnemy> members = [];

  /// When (flight elapsed seconds) each member that has gone left the
  /// flight's enemies, and when each of those that was shot down or rammed
  /// fell. A member gone but not downed flew past the bird or into it. The
  /// rules write both; the art reads them.
  final Map<SkyEnemy, double> goneAt = {}, downedAt = {};

  /// Members shot down or rammed.
  int get downed => downedAt.length;

  /// The flight's elapsed seconds when the last member was gone, or null.
  double? clearedAt;

  /// Members that got away: gone without being shot down or rammed (they
  /// flew past the bird, or into it).
  int get escaped => goneAt.length - downed;

  // -------------------------------------------------------------------
  // Stragglers (rules version 45, King Coo only): the pigeons that got away
  // come back during his fight, a few at a time, until every one has been
  // shot down or rammed. A straggler that gets away again is owed again.

  /// Whether this boss's escaped members come back in its fight.
  static bool returnsOf(BossKind boss) => boss == BossKind.kingCoo;

  /// The stragglers sent back so far, in order, and when each that has
  /// gone left the flight's enemies and each that was downed fell (flight
  /// elapsed seconds). The rules write them; the art reads them.
  final List<SkyEnemy> stragglers = [];
  final Map<SkyEnemy, double> stragglerGoneAt = {}, stragglerDownedAt = {};

  /// Return slots that have come due in the boss's fight.
  int returnSlots = 0;

  /// Pigeons still to kill: every member that got away, less the
  /// stragglers downed since.
  int get owed => escaped - stragglerDownedAt.length;

  /// Stragglers on screen now.
  int get stragglersFlying => stragglers.length - stragglerGoneAt.length;

  /// Owed and not on screen: they wait for the next return.
  int get waiting => owed - stragglersFlying;

  /// Two returns a King Coo cycle, at these cycle times: one once his
  /// squadron has crossed, before his first crumb ring locks, and one after
  /// his second ring, so it has flown past before the next squadron. Each
  /// brings back at most [returnSize] stragglers from rules 56 (one before
  /// then), together at the next pair of [returnHeights]: above and below
  /// him, never level with his body, which would take the rocks meant for
  /// them while they fly behind him.
  static const returnTimes = [.3, 4.3];
  static const returnSize = 2;

  /// A straggler comes back winded: one ordinary shot downs it, so it can be
  /// dealt with between his crumb rings, which keep moving the bird.
  static const stragglerHp = 10;
  static const returnHeights = [.28, .72, .24, .76];

  /// The boss arrives this long after the last member is gone.
  static const bossDelay = .8;

  /// From rules version 45 King Coo's pigeons throw crusts: they fly at this
  /// share of the scroll, so each crosses slowly enough to throw more than
  /// once, and each member of a wave first throws this many seconds after
  /// the one before it, so a V never throws all at once.
  static const throwerDrift = 1.0, throwStagger = .5;

  /// How long the banner that announces the vanguard stays up.
  static const bannerSeconds = 2.6;

  /// Every member of every wave.
  int get total => [
    for (final wave in waves) wave.members.length,
  ].fold(0, (sum, count) => sum + count);

  bool get allSent => wavesSent == waves.length;
  bool get cleared => clearedAt != null;

  /// What the banner calls them.
  String get title => titleOf(boss);

  /// The bosses that send a vanguard, and its waves. The Pirate Captain, the
  /// Ember Dragon, the Searchlight Gargoyle and Neferhoo send none.
  static List<VanguardWave> wavesOf(BossKind boss) => switch (boss) {
    BossKind.baronBat => const [
      VanguardWave(.8, [
        (kind: EnemyKind.simpleBat, y: .38, behind: 0),
        (kind: EnemyKind.simpleBat, y: .62, behind: .2),
      ]),
      VanguardWave(4.0, [
        (kind: EnemyKind.caveBat, y: .3, behind: 0),
        (kind: EnemyKind.simpleBat, y: .5, behind: .16),
        (kind: EnemyKind.caveBat, y: .7, behind: .32),
      ]),
      VanguardWave(7.4, [
        (kind: EnemyKind.simpleBat, y: .26, behind: 0),
        (kind: EnemyKind.caveBat, y: .74, behind: .1),
        (kind: EnemyKind.simpleBat, y: .42, behind: .28),
        (kind: EnemyKind.caveBat, y: .58, behind: .38),
      ]),
    ],
    BossKind.spitterBeetle => const [
      VanguardWave(.8, [(kind: EnemyKind.spitterBeetle, y: .5, behind: 0)]),
      VanguardWave(4.2, [
        (kind: EnemyKind.simpleBat, y: .3, behind: 0),
        (kind: EnemyKind.spitterBeetle, y: .64, behind: .22),
      ]),
      VanguardWave(7.8, [
        (kind: EnemyKind.spitterBeetle, y: .3, behind: 0),
        (kind: EnemyKind.caveBat, y: .52, behind: .16),
        (kind: EnemyKind.spitterBeetle, y: .72, behind: .34),
      ]),
    ],
    BossKind.duskMoth => const [
      VanguardWave(.8, [(kind: EnemyKind.duskMoth, y: .5, behind: 0)]),
      VanguardWave(4.6, [
        (kind: EnemyKind.caveBat, y: .3, behind: 0),
        (kind: EnemyKind.simpleBat, y: .7, behind: .14),
      ]),
      VanguardWave(7.6, [
        (kind: EnemyKind.duskMoth, y: .34, behind: 0),
        (kind: EnemyKind.duskMoth, y: .66, behind: .4),
      ]),
    ],
    // His squadron's pigeons (they never snatch), in V formations.
    BossKind.kingCoo => const [
      VanguardWave(.8, [
        (kind: EnemyKind.alleyPigeon, y: .5, behind: 0),
        (kind: EnemyKind.alleyPigeon, y: .42, behind: .12),
        (kind: EnemyKind.alleyPigeon, y: .58, behind: .12),
      ]),
      VanguardWave(4.2, [
        (kind: EnemyKind.alleyPigeon, y: .3, behind: 0),
        (kind: EnemyKind.alleyPigeon, y: .22, behind: .12),
        (kind: EnemyKind.alleyPigeon, y: .38, behind: .12),
        (kind: EnemyKind.alleyPigeon, y: .7, behind: .5),
        (kind: EnemyKind.alleyPigeon, y: .62, behind: .62),
        (kind: EnemyKind.alleyPigeon, y: .78, behind: .62),
      ]),
      VanguardWave(8.4, [
        (kind: EnemyKind.alleyPigeon, y: .5, behind: 0),
        (kind: EnemyKind.alleyPigeon, y: .42, behind: .12),
        (kind: EnemyKind.alleyPigeon, y: .58, behind: .12),
        (kind: EnemyKind.alleyPigeon, y: .34, behind: .24),
        (kind: EnemyKind.alleyPigeon, y: .66, behind: .24),
      ]),
    ],
    // Neferhoo's warm-up is where the return rule is learned: he sends
    // none (egypt-int/MASTER-PLAN.md §2).
    BossKind.pirate ||
    BossKind.dragon ||
    BossKind.searchlightGargoyle ||
    BossKind.neferhoo => const [],
  };

  static String titleOf(BossKind boss) => switch (boss) {
    BossKind.baronBat => "BARON BAT'S BATS",
    BossKind.spitterBeetle => "THE SPITTER KING'S BROOD",
    BossKind.duskMoth => "THE DUSK EMPRESS'S MOTHS",
    BossKind.kingCoo => "KING COO'S SQUADRON",
    BossKind.pirate ||
    BossKind.dragon ||
    BossKind.searchlightGargoyle ||
    BossKind.neferhoo => '',
  };
}
