import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';

class PreviewStrokesPainter extends CustomPainter {
  const PreviewStrokesPainter({required this.strokes});

  final List<DrawingStroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _drawStroke(canvas, size, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant PreviewStrokesPainter oldDelegate) {
    return oldDelegate.strokes != strokes;
  }

  void _drawStroke(Canvas canvas, Size size, DrawingStroke stroke) {
    final points = stroke.pointsNorm;
    if (points.isEmpty) {
      return;
    }

    final style = stroke.style;
    final alpha = (stroke.opacity * style.opacity).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = Color(style.argbColor).withValues(alpha: alpha)
      ..strokeWidth = math.max(0.5, style.widthPx)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..blendMode =
          style.kind == StrokeToolKind.highlighter
              ? BlendMode.multiply
              : BlendMode.srcOver;

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
