import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// Counts what a paint asks of the canvas: draw calls, clips, layers, and
/// paints that carry a shader, blur or image filter. Everything is forwarded
/// to [inner], so the picture is the real one.
class CountingCanvas implements Canvas {
  CountingCanvas(this.inner);
  final Canvas inner;
  final counts = <String, int>{};

  void _n(String k) => counts[k] = (counts[k] ?? 0) + 1;

  /// Draw calls of any kind (paths, circles, rects, lines...).
  int get draws => counts.entries
      .where((e) => e.key.startsWith('draw') && !e.key.contains('.'))
      .fold(0, (a, e) => a + e.value);
  int get layers => counts['saveLayer'] ?? 0;
  int get clips => (counts['clipPath'] ?? 0) + (counts['clipRect'] ?? 0);
  int get shaders => counts.entries
      .where((e) => e.key.endsWith('.shader'))
      .fold(0, (a, e) => a + e.value);
  int get blurs => (counts['maskFilter'] ?? 0) + (counts['imageFilter'] ?? 0);
  int get unforwarded => counts.entries
      .where((e) => e.key.startsWith('UNFORWARDED'))
      .fold(0, (a, e) => a + e.value);

  void _paint(String k, Paint p) {
    _n(k);
    if (p.shader != null) _n('$k.shader');
    if (p.maskFilter != null) _n('maskFilter');
    if (p.imageFilter != null) _n('imageFilter');
  }

  @override
  void save() => inner.save();
  @override
  void restore() => inner.restore();
  @override
  void saveLayer(Rect? bounds, Paint paint) {
    _n('saveLayer');
    inner.saveLayer(bounds, paint);
  }

  @override
  void translate(double dx, double dy) => inner.translate(dx, dy);
  @override
  void scale(double sx, [double? sy]) => inner.scale(sx, sy);
  @override
  void rotate(double r) => inner.rotate(r);
  @override
  void clipRect(
    Rect rect, {
    ui.ClipOp clipOp = ui.ClipOp.intersect,
    bool doAntiAlias = true,
  }) {
    _n('clipRect');
    inner.clipRect(rect, clipOp: clipOp, doAntiAlias: doAntiAlias);
  }

  @override
  void clipPath(Path path, {bool doAntiAlias = true}) {
    _n('clipPath');
    inner.clipPath(path, doAntiAlias: doAntiAlias);
  }

  @override
  void drawPath(Path p, Paint paint) {
    _paint('drawPath', paint);
    inner.drawPath(p, paint);
  }

  @override
  void drawCircle(Offset c, double r, Paint paint) {
    _paint('drawCircle', paint);
    inner.drawCircle(c, r, paint);
  }

  @override
  void drawRect(Rect r, Paint paint) {
    _paint('drawRect', paint);
    inner.drawRect(r, paint);
  }

  @override
  void drawRRect(RRect r, Paint paint) {
    _paint('drawRRect', paint);
    inner.drawRRect(r, paint);
  }

  @override
  void drawOval(Rect r, Paint paint) {
    _paint('drawOval', paint);
    inner.drawOval(r, paint);
  }

  @override
  void drawArc(Rect r, double a, double b, bool c, Paint paint) {
    _paint('drawArc', paint);
    inner.drawArc(r, a, b, c, paint);
  }

  @override
  void drawLine(Offset a, Offset b, Paint paint) {
    _paint('drawLine', paint);
    inner.drawLine(a, b, paint);
  }

  @override
  void drawPoints(ui.PointMode mode, List<Offset> points, Paint paint) {
    _paint('drawPoints', paint);
    inner.drawPoints(mode, points, paint);
  }

  @override
  void drawDRRect(RRect outer, RRect innerRect, Paint paint) {
    _paint('drawDRRect', paint);
    inner.drawDRRect(outer, innerRect, paint);
  }

  @override
  dynamic noSuchMethod(Invocation i) {
    _n('UNFORWARDED.${i.memberName}');
    return null;
  }
}
