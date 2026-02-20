import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';
import 'package:safety_inspection_app/models/drawing/eraser_preview.dart';

class EraserPreviewPainter extends CustomPainter {
  const EraserPreviewPainter({required this.preview});

  final EraserPreview? preview;

  @override
  void paint(Canvas canvas, Size size) {
    final activePreview = preview;
    if (activePreview == null) {
      return;
    }

    for (final stroke in activePreview.strokesToMask) {
      _drawStroke(
        canvas,
        size,
        stroke,
        forceBlendMode: BlendMode.clear,
        widthScale: 1.2,
      );
    }

    for (final stroke in activePreview.virtualStrokesToRender) {
      _drawStroke(canvas, size, stroke);
    }

    final cursor = activePreview.cursor;
    final radius = activePreview.radius;
    if (cursor != null && radius != null && radius > 0) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = const Color(0xFF1E88E5);
      canvas.drawCircle(cursor, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant EraserPreviewPainter oldDelegate) {
    return oldDelegate.preview != preview;
  }

  void _drawStroke(
    Canvas canvas,
    Size size,
    DrawingStroke stroke, {
    BlendMode? forceBlendMode,
    double widthScale = 1.0,
  }) {
    final points = stroke.pointsNorm;
    if (points.isEmpty) {
      return;
    }

    final style = stroke.style;
    final alpha = (stroke.opacity * style.opacity).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = Color(style.argbColor).withValues(alpha: alpha)
      ..strokeWidth = math.max(0.5, style.widthPx * widthScale)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..blendMode =
          forceBlendMode ??
          (style.kind == StrokeToolKind.highlighter
              ? BlendMode.multiply
              : BlendMode.srcOver);

    final scaledPoints = points
        .map((point) => Offset(point.dx * size.width, point.dy * size.height))
        .toList(growable: false);

    if (scaledPoints.length == 1) {
      canvas.drawCircle(
        scaledPoints.first,
        math.max(0.5, paint.strokeWidth / 2),
        paint,
      );
      return;
    }

    final path = Path()..moveTo(scaledPoints.first.dx, scaledPoints.first.dy);
    for (var i = 1; i < scaledPoints.length; i++) {
      path.lineTo(scaledPoints[i].dx, scaledPoints[i].dy);
    }
    canvas.drawPath(path, paint);
  }
}
