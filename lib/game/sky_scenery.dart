import 'dart:math' as math;
import 'dart:ui';
import 'regions/region_scene.dart';
import 'regions/world_backdrop.dart';
import 'regions/world_region.dart';

export 'regions/world_region.dart'
    show RegionBlend, SkyPalette, WorldRegion, WorldRegionPalette, WorldTour;

/// The flight backdrop: the world tour of regions behind every gameplay
/// layer, driven only by the replayable clock and the flown distance. A
/// campaign level passes the one region it holds as `held`.
class SkyScenery {
  static void paint(
    Canvas c,
    Size size, {
    double seconds = 0,
    double distance = 0,
    bool reducedMotion = false,
    WorldRegion? held,
  }) {
    WorldBackdrop.paint(
      c,
      SceneFrame(
        size,
        seconds: seconds.isFinite ? seconds : 0,
        distance: distance.isFinite ? distance : 0,
        reducedMotion: reducedMotion,
        region: held,
      ),
    );
  }

  static Path star(
    Offset center,
    double radius, {
    double rotation = -math.pi / 2,
  }) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = rotation + i * math.pi / 5;
      final r = radius * (i.isEven ? 1 : .46);
      final p = center + Offset(math.cos(a) * r, math.sin(a) * r);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }
}
