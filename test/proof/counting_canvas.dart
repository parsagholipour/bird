import 'dart:ui' as ui;

/// Counts what a frame asks of the canvas (draw calls, clips, layers, blur and
/// shader draws), forwarding everything to [inner]. Text paints as one op.
class Counting implements ui.Canvas {
  Counting(this.inner);
  final ui.Canvas inner;
  final counts = <String, int>{};
  void _n(String k) => counts[k] = (counts[k] ?? 0) + 1;

  int get draws => counts.entries
      .where((e) => (e.key.startsWith('draw') && !e.key.contains('.')) || e.key == 'UNFORWARDED.drawParagraph')
      .fold(0, (a, e) => a + e.value);
  int get clips => (counts['clipPath'] ?? 0) + (counts['clipPath.noAA'] ?? 0) + (counts['clipRect'] ?? 0);
  int get layers => counts['saveLayer'] ?? 0;
  int get blurs => counts['maskFilter'] ?? 0;
  int get shaderDraws => counts.entries.where((e) => e.key.endsWith('.shader')).fold(0, (a, e) => a + e.value);

  @override
  void save() => inner.save();
  @override
  void restore() => inner.restore();
  @override
  void saveLayer(ui.Rect? bounds, ui.Paint paint) {
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
  void transform(dynamic matrix4) => inner.transform(matrix4);
  @override
  void clipPath(ui.Path p, {bool doAntiAlias = true}) {
    _n(doAntiAlias ? 'clipPath' : 'clipPath.noAA');
    inner.clipPath(p, doAntiAlias: doAntiAlias);
  }

  @override
  void clipRect(ui.Rect rect, {ui.ClipOp clipOp = ui.ClipOp.intersect, bool doAntiAlias = true}) {
    _n('clipRect');
    inner.clipRect(rect, clipOp: clipOp, doAntiAlias: doAntiAlias);
  }

  void _paint(String k, ui.Paint p) {
    _n(k);
    if (p.shader != null) _n('$k.shader');
    if (p.maskFilter != null) _n('maskFilter');
  }

  @override
  void drawPath(ui.Path p, ui.Paint paint) {
    _paint('drawPath', paint);
    inner.drawPath(p, paint);
  }

  @override
  void drawCircle(ui.Offset c, double r, ui.Paint paint) {
    _paint('drawCircle', paint);
    inner.drawCircle(c, r, paint);
  }

  @override
  void drawRect(ui.Rect r, ui.Paint paint) {
    _paint('drawRect', paint);
    inner.drawRect(r, paint);
  }

  @override
  void drawRRect(ui.RRect r, ui.Paint paint) {
    _paint('drawRRect', paint);
    inner.drawRRect(r, paint);
  }

  @override
  void drawOval(ui.Rect r, ui.Paint paint) {
    _paint('drawOval', paint);
    inner.drawOval(r, paint);
  }

  @override
  void drawArc(ui.Rect r, double a, double b, bool c, ui.Paint paint) {
    _paint('drawArc', paint);
    inner.drawArc(r, a, b, c, paint);
  }

  @override
  void drawLine(ui.Offset a, ui.Offset b, ui.Paint paint) {
    _paint('drawLine', paint);
    inner.drawLine(a, b, paint);
  }

  @override
  void drawDRRect(ui.RRect outer, ui.RRect inner_, ui.Paint paint) {
    _paint('drawDRRect', paint);
    inner.drawDRRect(outer, inner_, paint);
  }

  @override
  void drawVertices(ui.Vertices vertices, ui.BlendMode blendMode, ui.Paint paint) {
    _paint('drawVertices', paint);
    inner.drawVertices(vertices, blendMode, paint);
  }

  @override
  void drawPoints(ui.PointMode pointMode, List<ui.Offset> points, ui.Paint paint) {
    _paint('drawPoints', paint);
    inner.drawPoints(pointMode, points, paint);
  }

  @override
  void drawParagraph(ui.Paragraph paragraph, ui.Offset offset) {
    _n('drawParagraph.text');
    _n('UNFORWARDED.drawParagraph');
    inner.drawParagraph(paragraph, offset);
  }

  @override
  dynamic noSuchMethod(Invocation i) {
    _n('UNFORWARDED.${i.memberName}');
    return null;
  }
}
