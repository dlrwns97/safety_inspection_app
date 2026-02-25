import 'package:flutter/rendering.dart';

import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';

class HighlighterEngine {
  static bool shouldUseForStyle(StrokeStyle style) {
    if (style.kind == StrokeToolKind.highlighter) {
      return true;
    }
    return switch (style.variant) {
      PenVariant.highlighter ||
      PenVariant.highlighterChisel ||
      PenVariant.marker ||
      PenVariant.markerChisel => true,
      _ => false,
    };
  }

  static Paint paintForStyle({
    required StrokeStyle style,
    required double strokeOpacity,
  }) {
    final isChisel =
        style.variant == PenVariant.highlighterChisel ||
        style.variant == PenVariant.markerChisel;
    final blendMode =
        style.variant == PenVariant.marker || style.variant == PenVariant.markerChisel
        ? BlendMode.srcOver
        : BlendMode.multiply;

    return Paint()
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true
      ..strokeWidth = style.widthPx
      ..strokeCap = isChisel ? StrokeCap.square : StrokeCap.round
      ..strokeJoin = isChisel ? StrokeJoin.bevel : StrokeJoin.round
      ..blendMode = blendMode
      ..color = Color(style.argbColor).withValues(
        alpha: (style.opacity * strokeOpacity).clamp(0.0, 1.0).toDouble(),
      );
  }
}
