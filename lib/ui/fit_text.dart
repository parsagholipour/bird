import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// One line of words that shrinks to fit its width rather than wrap or cut,
/// for single-line labels that translations may lengthen: switch titles,
/// key labels, plaques (MASTER-PLAN.md, "Text fit"). It should not need to
/// shrink below [minScale]; [scaleIn] tells a test how far each one did, so
/// the pseudo-locale catches a label that has to shrink further.
///
/// When the player asked for larger system text it does not shrink: it
/// wraps like a plain [Text], so the larger words stay large and the screen
/// scrolls as it did before localization.
class FitText extends StatelessWidget {
  const FitText(
    this.text, {
    super.key,
    required this.style,
    this.textAlign,
    this.semanticsLabel,
  });
  final String text;
  final TextStyle style;
  final TextAlign? textAlign;
  final String? semanticsLabel;

  /// The smallest a label should need to shrink to. Pseudo-locale words
  /// are about 45 % longer than the English (1 / 1.45 ≈ .69), so a label
  /// that fits the pseudo-locale at this scale has room for any translation
  /// within its ARB budget.
  static const minScale = .65;

  @override
  Widget build(BuildContext context) {
    final words = Text(
      text,
      style: style,
      maxLines: 1,
      softWrap: false,
      textAlign: textAlign,
      semanticsLabel: semanticsLabel,
    );
    if (MediaQuery.textScalerOf(context).scale(10) > 10.01) {
      return Text(
        text,
        style: style,
        textAlign: textAlign,
        semanticsLabel: semanticsLabel,
      );
    }
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: words,
    );
  }

  /// How far each [FitText] under [root] shrank (1 = not at all), by text.
  static Map<String, double> scaleIn(Element root) {
    final out = <String, double>{};
    void visit(Element e) {
      final widget = e.widget;
      if (widget is FitText) {
        final box = e.findRenderObject();
        if (box is RenderFittedBox && box.hasSize && box.child != null) {
          final child = box.child!.size.width;
          out[widget.text] = child <= 0
              ? 1
              : (box.size.width / child).clamp(0, 1);
        }
      }
      e.visitChildren(visit);
    }

    visit(root);
    return out;
  }
}

/// A paragraph that keeps to [maxLines] by setting itself a little smaller
/// when a translation runs long, down to [minScale] of its size; past that
/// it ends in an ellipsis, which [RenderFitParagraph.cut] reports to tests.
/// For short card texts whose height the design fixes (MASTER-PLAN.md,
/// "Text fit"). Unlike a LayoutBuilder it answers intrinsic sizes, so it
/// works inside IntrinsicHeight panels.
///
/// With larger system text it keeps the player's size and wraps freely.
class FitParagraph extends LeafRenderObjectWidget {
  const FitParagraph(
    this.text, {
    super.key,
    required this.style,
    this.maxLines = 2,
    this.minScale = FitText.minScale,
  });
  final String text;
  final TextStyle style;
  final int maxLines;
  final double minScale;

  @override
  RenderFitParagraph createRenderObject(BuildContext context) =>
      RenderFitParagraph(
        text: text,
        style: DefaultTextStyle.of(context).style.merge(style),
        maxLines: maxLines,
        minScale: minScale,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderFitParagraph renderObject,
  ) {
    renderObject
      ..text = text
      ..style = DefaultTextStyle.of(context).style.merge(style)
      ..maxLines = maxLines
      ..minScale = minScale
      ..textDirection = Directionality.of(context)
      ..textScaler = MediaQuery.textScalerOf(context);
  }
}

class RenderFitParagraph extends RenderBox {
  RenderFitParagraph({
    required this._text,
    required this._style,
    required this._maxLines,
    required this._minScale,
    required this._textDirection,
    required this._textScaler,
  });

  final _painter = TextPainter(ellipsis: '…');
  String _text;
  TextStyle _style;
  int _maxLines;
  double _minScale;
  TextDirection _textDirection;
  TextScaler _textScaler;

  /// How far the words shrank (1 = not at all).
  double get scale => _scale;
  double _scale = 1;

  /// Whether even the smallest size could not keep to the lines.
  bool get cut => _cut;
  bool _cut = false;

  String get text => _text;
  set text(String v) => _set(_text != v, () => _text = v);
  set style(TextStyle v) => _set(_style != v, () => _style = v);
  set maxLines(int v) => _set(_maxLines != v, () => _maxLines = v);
  set minScale(double v) => _set(_minScale != v, () => _minScale = v);
  set textDirection(TextDirection v) =>
      _set(_textDirection != v, () => _textDirection = v);
  set textScaler(TextScaler v) => _set(_textScaler != v, () => _textScaler = v);

  void _set(bool changed, VoidCallback apply) {
    if (!changed) return;
    apply();
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  bool get _largeText => _textScaler.scale(10) > 10.01;

  /// Lays the words out for [width]: the largest scale, in steps of 5 %,
  /// that keeps them to the lines.
  void _fit(double width) {
    final free = _largeText;
    _painter
      ..textDirection = _textDirection
      ..textScaler = _textScaler
      ..maxLines = free ? null : _maxLines;
    for (var s = 1.0; ; s -= .05) {
      final scale = s < _minScale ? _minScale : s;
      _painter.text = TextSpan(
        text: _text,
        style: scale == 1
            ? _style
            : _style.copyWith(fontSize: (_style.fontSize ?? 14) * scale),
      );
      _painter.layout(maxWidth: width);
      _scale = scale;
      _cut = _painter.didExceedMaxLines;
      if (free || !_cut || scale <= _minScale) return;
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    _fit(0);
    return _painter.minIntrinsicWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    _fit(double.infinity);
    return _painter.maxIntrinsicWidth;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    _fit(width);
    return _painter.height;
  }

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    _fit(constraints.maxWidth);
    return constraints.constrain(Size(constraints.maxWidth, _painter.height));
  }

  @override
  void performLayout() {
    _fit(constraints.maxWidth);
    size = constraints.constrain(
      Size(
        constraints.hasBoundedWidth ? constraints.maxWidth : _painter.width,
        _painter.height,
      ),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _painter.paint(context.canvas, offset);
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..isSemanticBoundary = true
      ..label = _text
      ..textDirection = _textDirection;
  }

  @override
  void dispose() {
    _painter.dispose();
    super.dispose();
  }
}
