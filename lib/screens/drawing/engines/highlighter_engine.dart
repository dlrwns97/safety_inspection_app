import 'package:flutter/rendering.dart';

import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';

class HighlighterEngine {
  static Paint getHighlighterPaint(Color color, double opacity) {
    return Paint()
      ..color = color.withValues(alpha: opacity)
      ..blendMode = BlendMode.multiply
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke;
  }

  static Paint getMarkerPaint(Color color, double opacity) {
    return Paint()
      ..color = color.withValues(alpha: opacity)
      ..blendMode = BlendMode.srcOver
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke;
  }

  static Paint paintForStyle(StrokeStyle style, double strokeOpacity) {
    final resolvedOpacity =
        (style.opacity * strokeOpacity).clamp(0.0, 1.0).toDouble();
    final variant = style.variant;
    final isMarker =
        variant == PenVariant.marker || variant == PenVariant.markerChisel;
    final isHighlighter =
        style.kind == StrokeToolKind.highlighter ||
        variant == PenVariant.highlighter ||
        variant == PenVariant.highlighterChisel;
    final base = isHighlighter && !isMarker
        ? getHighlighterPaint(Color(style.argbColor), resolvedOpacity)
        : getMarkerPaint(Color(style.argbColor), resolvedOpacity);
    return base
      ..strokeCap = capForVariant(variant)
      ..strokeJoin = joinForVariant(variant)
      ..blendMode = blendForVariant(variant);
  }

  static StrokeCap capForVariant(PenVariant variant) {
    switch (variant) {
      case PenVariant.highlighter:
      case PenVariant.highlighterChisel:
      case PenVariant.markerChisel:
        return StrokeCap.square;
      case PenVariant.marker:
        return StrokeCap.round;
      case PenVariant.pen:
      case PenVariant.fountainPen:
      case PenVariant.calligraphyPen:
      case PenVariant.pencil:
        return StrokeCap.round;
    }
  }

  static StrokeJoin joinForVariant(PenVariant variant) {
    switch (variant) {
      case PenVariant.highlighterChisel:
      case PenVariant.markerChisel:
        return StrokeJoin.bevel;
      case PenVariant.highlighter:
      case PenVariant.marker:
      case PenVariant.pen:
      case PenVariant.fountainPen:
      case PenVariant.calligraphyPen:
      case PenVariant.pencil:
        return StrokeJoin.round;
    }
  }

  static BlendMode blendForVariant(PenVariant variant) {
    switch (variant) {
      case PenVariant.highlighter:
      case PenVariant.highlighterChisel:
        return BlendMode.multiply;
      case PenVariant.marker:
      case PenVariant.markerChisel:
      case PenVariant.pen:
      case PenVariant.fountainPen:
      case PenVariant.calligraphyPen:
      case PenVariant.pencil:
        return BlendMode.srcOver;
    }
  }
}
