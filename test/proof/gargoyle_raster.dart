// Raster helpers for the Gargoyle's contract tests: where the solid pixels of a
// drawing are (the envelope scan), how much of a box is empty (the silhouette
// gates' negative spaces) and how full the figure's bounding box is.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

/// A rasterised drawing: one byte per pixel (1 = solid), in rig units.
class Mask {
  Mask(this.w, this.h, this.ppu, this.x0, this.y0, this.solid, this.data);
  final int w, h;
  final double ppu, x0, y0;
  final Uint8List solid; // 0/1
  final Uint8List data; // RGBA

  double ux(num px) => px / ppu + x0;
  double uy(num py) => py / ppu + y0;
  bool at(int x, int y) => x >= 0 && y >= 0 && x < w && y < h && solid[y * w + x] == 1;

  /// The bounds of the solid pixels, with the pixel reaching furthest on each
  /// side (left, top, right, bottom), in rig units; null when nothing is drawn.
  ({ui.Rect rect, ui.Offset atLeft, ui.Offset atTop, ui.Offset atRight, ui.Offset atBottom})? get bounds {
    var minX = w, minY = h, maxX = -1, maxY = -1;
    var left = 0, top = 0, right = 0, bottom = 0;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        if (solid[y * w + x] == 0) continue;
        if (x < minX) {
          minX = x;
          left = y;
        }
        if (x > maxX) {
          maxX = x;
          right = y;
        }
        if (y < minY) {
          minY = y;
          top = x;
        }
        if (y > maxY) {
          maxY = y;
          bottom = x;
        }
      }
    }
    if (maxX < 0) return null;
    ui.Offset p(int x, int y) => ui.Offset(ux(x + .5), uy(y + .5));
    return (
      rect: ui.Rect.fromLTRB(ux(minX), uy(minY), ux(maxX + 1), uy(maxY + 1)),
      atLeft: p(minX, left),
      atTop: p(top, minY),
      atRight: p(maxX, right),
      atBottom: p(bottom, maxY),
    );
  }

  int get area => solid.fold(0, (a, b) => a + b);

  /// The solid area over the bounding box's.
  double get fill {
    final b = bounds;
    if (b == null) return 0;
    return area / (b.rect.width * ppu * b.rect.height * ppu);
  }

  /// The diameter (rig units) of the largest disc, centred in [box], that
  /// touches no solid pixel and lies inside [box].
  double largestEmptyDisc(ui.Rect box) {
    var best = 0.0;
    final x0p = ((box.left - x0) * ppu).floor(), x1p = ((box.right - x0) * ppu).ceil();
    final y0p = ((box.top - y0) * ppu).floor(), y1p = ((box.bottom - y0) * ppu).ceil();
    final maxR = (math.min(box.width, box.height) / 2 * ppu).ceil();
    for (var y = y0p; y < y1p; y++) {
      for (var x = x0p; x < x1p; x++) {
        if (at(x, y)) continue;
        final cx = ux(x + .5), cy = uy(y + .5);
        var r = math.min(
          math.min(cx - box.left, box.right - cx),
          math.min(cy - box.top, box.bottom - cy),
        );
        if (r <= best / 2) continue;
        final rp = math.min((r * ppu).ceil(), maxR);
        var d2 = rp * rp * 1.0;
        for (var dy = -rp; dy <= rp && d2 > 0; dy++) {
          for (var dx = -rp; dx <= rp; dx++) {
            final q = dx * dx + dy * dy;
            if (q < d2 && at(x + dx, y + dy)) d2 = q.toDouble();
          }
        }
        r = math.min(r, math.sqrt(d2) / ppu);
        if (r * 2 > best) best = r * 2;
      }
    }
    return best;
  }
}

/// Rasterises [draw] (rig units: the canvas is scaled by [ppu] and shifted so
/// [region]'s top left is the origin). A pixel is solid at alpha >= [solid].
Future<Mask> rasterize(
  void Function(ui.Canvas) draw, {
  double ppu = 24,
  ui.Rect region = const ui.Rect.fromLTRB(-7, -7, 8, 8),
  int solid = 200,
}) async {
  final rec = ui.PictureRecorder();
  final c = ui.Canvas(rec);
  c.scale(ppu);
  c.translate(-region.left, -region.top);
  draw(c);
  final pic = rec.endRecording();
  final w = (region.width * ppu).round(), h = (region.height * ppu).round();
  final img = await pic.toImage(w, h);
  final data = (await img.toByteData())!.buffer.asUint8List();
  img.dispose();
  pic.dispose();
  final s = Uint8List(w * h);
  for (var i = 0; i < w * h; i++) {
    s[i] = data[i * 4 + 3] >= solid ? 1 : 0;
  }
  return Mask(w, h, ppu, region.left, region.top, s, data);
}
