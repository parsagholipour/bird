import 'package:flutter/painting.dart';

import '../../domain/obstacle.dart';
import '../regions/world_region.dart';
import 'antarctica.dart';
import 'china.dart';
import 'egypt.dart';
import 'jungle.dart';
import 'kit.dart';
import 'new_york.dart';
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
  /// China, a black iron chain in New York and tarred hemp at sea.
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
  };
}
