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
    final erasedMask = stroke.ensureErasedMask();

    for (var i = 0; i < scaledPoints.length; i += 1) {
      if (erasedMask[i] != 0) {
        continue;
      }
      final start = i;
      var end = i;
      while (end + 1 < scaledPoints.length && erasedMask[end + 1] == 0) {
        end += 1;
      }
      if (start == end) {
        canvas.drawCircle(
          scaledPoints[start],
          math.max(0.5, paint.strokeWidth / 2),
          paint,
        );
      } else {
        final path = Path()
          ..moveTo(scaledPoints[start].dx, scaledPoints[start].dy);
        for (var j = start + 1; j <= end; j += 1) {
          path.lineTo(scaledPoints[j].dx, scaledPoints[j].dy);
        }
        canvas.drawPath(path, paint);
      }
      i = end;
    }
  }
}
