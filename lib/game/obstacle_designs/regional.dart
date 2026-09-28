import 'package:flutter/painting.dart';

import '../../domain/obstacle.dart';
import '../regions/world_region.dart';
import 'antarctica.dart';
import 'aztec.dart';
import 'brazil.dart';
import 'china.dart';
import 'dubai.dart';
import 'egypt.dart';
import 'jungle.dart';
import 'kit.dart';
import 'mexico.dart';
import 'new_york.dart';
import 'paris.dart';
import 'rome.dart';
import 'sea.dart';

/// Routes every obstacle to the skin of the region it spawned in. Collision
/// geometry never changes; only materials, motifs and effects do.
abstract final class RegionalObstacles {
  static void column(
    WorldRegion region,
    Canvas c,
    Rect r, {
    required ObstacleKind kind,
    required bool top,
    required double seconds,
    required bool reducedMotion,
    required PassState pass,
    required int appearance,
  }) {
    if (!r.isFinite || r.isEmpty) return;
    final paint = switch (region) {
      WorldRegion.egypt => EgyptObstacles.column,
      WorldRegion.antarctica => AntarcticaObstacles.column,
      WorldRegion.jungle => JungleObstacles.column,
      WorldRegion.china => ChinaObstacles.column,
      WorldRegion.newYork => NewYorkObstacles.column,
      WorldRegion.sea => SeaObstacles.column,
      WorldRegion.aztec => AztecObstacles.column,
      WorldRegion.paris => ParisObstacles.column,
      WorldRegion.brazil => BrazilObstacles.column,
      WorldRegion.dubai => DubaiObstacles.column,
      WorldRegion.rome => RomeObstacles.column,
      WorldRegion.mexico => MexicoObstacles.column,
    };
    paint(
      c,
      r,
      kind: kind,
      top: top,
      seconds: seconds.isFinite ? seconds : 0,
      reducedMotion: reducedMotion,
      pass: pass,
      appearance: appearance,
    );
  }

  static void orb(
    WorldRegion region,
    Canvas c,
    double radius, {
    required ObstacleKind kind,
    required bool upper,
    required double seconds,
    required bool reducedMotion,
    required PassState pass,
    required int appearance,
  }) {
    if (!radius.isFinite || radius <= 0) return;
    final paint = switch (region) {
      WorldRegion.egypt => EgyptObstacles.orb,
      WorldRegion.antarctica => AntarcticaObstacles.orb,
      WorldRegion.jungle => JungleObstacles.orb,
      WorldRegion.china => ChinaObstacles.orb,
      WorldRegion.newYork => NewYorkObstacles.orb,
      WorldRegion.sea => SeaObstacles.orb,
      WorldRegion.aztec => AztecObstacles.orb,
      WorldRegion.paris => ParisObstacles.orb,
      WorldRegion.brazil => BrazilObstacles.orb,
      WorldRegion.dubai => DubaiObstacles.orb,
      WorldRegion.rome => RomeObstacles.orb,
      WorldRegion.mexico => MexicoObstacles.orb,
    };
    paint(
      c,
      radius,
      kind: kind,
      upper: upper,
      seconds: seconds.isFinite ? seconds : 0,
      reducedMotion: reducedMotion,
      pass: pass,
      appearance: appearance,
    );
  }

  /// A lantern's tether: (cord, twist marks). Palm fibre in Egypt, a
  /// frosted line in Antarctica, a green vine in the jungle, red silk cord in
  /// China, a black iron chain in New York, tarred hemp at sea, a woven cord
  /// in Aztec lands, a wrought-iron line in Paris, green braid in Brazil,
  /// steel cable in Dubai, rope in Rome and papel picado string in Mexico.
  static (Color, Color) tether(WorldRegion region) => switch (region) {
    WorldRegion.egypt => (const Color(0xff8a5f38), const Color(0xffe9c58a)),
    WorldRegion.antarctica => (
      const Color(0xff5d7896),
      const Color(0xfff1f8ff),
    ),
    WorldRegion.jungle => (const Color(0xff3f7a3a), const Color(0xff9fd07a)),
    WorldRegion.china => (const Color(0xffa62a24), const Color(0xffffc95a)),
    WorldRegion.newYork => (const Color(0xff1e1d2b), const Color(0xff8c8aa8)),
    WorldRegion.sea => (const Color(0xff7a5a3a), const Color(0xffe8d2a0)),
    WorldRegion.aztec => (const Color(0xff9a6a3a), const Color(0xff49c1b0)),
    WorldRegion.paris => (const Color(0xff2a2a3a), const Color(0xffffd36b)),
    WorldRegion.brazil => (const Color(0xff2f8f4a), const Color(0xffffdc2e)),
    WorldRegion.dubai => (const Color(0xff8a8f9a), const Color(0xffe8f3ff)),
    WorldRegion.rome => (const Color(0xff8a5a3a), const Color(0xffe6c98a)),
    WorldRegion.mexico => (const Color(0xffe6407a), const Color(0xffffc93f)),
  };
}
