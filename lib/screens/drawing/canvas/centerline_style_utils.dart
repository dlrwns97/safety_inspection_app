import 'package:flutter/rendering.dart';

import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';
import 'package:safety_inspection_app/screens/drawing/engines/highlighter_engine.dart';

class ResolvedCenterlineStyle {
  const ResolvedCenterlineStyle({
    required this.paint,
    required this.usesHighlighterEngine,
  });

  final Paint paint;
  final bool usesHighlighterEngine;
}

ResolvedCenterlineStyle resolveCenterlineStyle({
  required StrokeStyle style,
  required double strokeOpacity,
}) {
  final usesHighlighterEngine = HighlighterEngine.shouldUseForStyle(style);
  final paint = usesHighlighterEngine
      ? HighlighterEngine.paintForStyle(style: style, strokeOpacity: strokeOpacity)
      : _fallbackPaintForStyle(style: style, strokeOpacity: strokeOpacity);

  paint.strokeWidth = paint.strokeWidth < 0.5 ? 0.5 : paint.strokeWidth;

  return ResolvedCenterlineStyle(
    paint: paint,
    usesHighlighterEngine: usesHighlighterEngine,
  );
}

Paint _fallbackPaintForStyle({
  required StrokeStyle style,
  required double strokeOpacity,
}) {
  var width = style.widthPx;
  var cap = StrokeCap.round;
  var join = StrokeJoin.round;
  var blendMode =
      style.kind == StrokeToolKind.highlighter ? BlendMode.multiply : BlendMode.srcOver;

  switch (style.variant) {
    case PenVariant.fountainPen:
      width *= 1.15;
      break;
    case PenVariant.calligraphyPen:
      width *= 1.1;
      cap = StrokeCap.square;
      join = StrokeJoin.bevel;
      break;
    case PenVariant.pencil:
      width *= 0.9;
      break;
    case PenVariant.highlighterChisel:
    case PenVariant.markerChisel:
      cap = StrokeCap.square;
      join = StrokeJoin.bevel;
      break;
    case PenVariant.highlighter:
      blendMode = BlendMode.multiply;
      break;
    case PenVariant.marker:
      blendMode = BlendMode.srcOver;
      break;
    case PenVariant.pen:
      break;
  }

  return Paint()
    ..style = PaintingStyle.stroke
    ..isAntiAlias = true
    ..color = Color(style.argbColor).withValues(alpha: _resolvedOpacity(style, strokeOpacity))
    ..strokeWidth = width
    ..strokeCap = cap
    ..strokeJoin = join
    ..blendMode = blendMode;
}

double _resolvedOpacity(StrokeStyle style, double strokeOpacity) {
  var alpha = (strokeOpacity * style.opacity).clamp(0.0, 1.0).toDouble();
  if (style.variant == PenVariant.pencil) {
    alpha *= 0.85;
  }
  return alpha.clamp(0.0, 1.0);
}
