import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// At most [maxWidth] wide, like `ConstrainedBox(maxWidth:)`, but asked
/// for its height it measures at the width it will really get.
///
/// AuraPage sizes its body from the body's intrinsic height (a sliver that
/// fills the rest of the page). `ConstrainedBox` measures that height at
/// the full offered width, so text that wraps only at [maxWidth] (a badge
/// name on two lines) is measured on one line and the body overflows. Use
/// this for any narrow box that holds text inside a page body.
class MaxWidth extends SingleChildRenderObjectWidget {
  const MaxWidth({
    super.key,
    required this.maxWidth,
    this.minHeight = 0,
    super.child,
  });

  final double maxWidth;
  final double minHeight;

  @override
  RenderMaxWidth createRenderObject(BuildContext context) =>
      RenderMaxWidth(maxWidth: maxWidth, minHeight: minHeight);

  @override
  void updateRenderObject(BuildContext context, RenderMaxWidth renderObject) {
    renderObject
      ..maxWidth = maxWidth
      ..minHeight = minHeight;
  }
}

class RenderMaxWidth extends RenderProxyBox {
  RenderMaxWidth({required this._maxWidth, required this._minHeight});

  double _maxWidth;
  set maxWidth(double v) {
    if (v == _maxWidth) return;
    _maxWidth = v;
    markNeedsLayout();
  }

  double _minHeight;
  set minHeight(double v) {
    if (v == _minHeight) return;
    _minHeight = v;
    markNeedsLayout();
  }

  BoxConstraints _limit(BoxConstraints c) =>
      c.enforce(BoxConstraints(maxWidth: _maxWidth, minHeight: _minHeight));

  double _w(double width) => math.min(width, _maxWidth);

  @override
  double computeMinIntrinsicWidth(double height) =>
      math.min(super.computeMinIntrinsicWidth(height), _maxWidth);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      math.min(super.computeMaxIntrinsicWidth(height), _maxWidth);

  @override
  double computeMinIntrinsicHeight(double width) =>
      math.max(super.computeMinIntrinsicHeight(_w(width)), _minHeight);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      math.max(super.computeMaxIntrinsicHeight(_w(width)), _minHeight);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final c = _limit(constraints);
    return constraints.constrain(child?.getDryLayout(c) ?? c.smallest);
  }

  @override
  void performLayout() {
    final c = _limit(constraints);
    if (child == null) {
      size = constraints.constrain(c.smallest);
      return;
    }
    child!.layout(c, parentUsesSize: true);
    size = constraints.constrain(child!.size);
  }
}
