import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import 'package:safety_inspection_app/screens/drawing/drawing_types.dart';
import 'package:safety_inspection_app/screens/drawing/models/drawing_stroke.dart';

/// Paints only the in-progress stroke as a live overlay above cached content.
class LiveStrokePainter extends CustomPainter {
  const LiveStrokePainter({
    required this.liveStroke,
    required this.devicePixelRatio,
    Listenable? repaint,
  }) : super(repaint: repaint);

  final DrawingStroke? liveStroke;
  final double devicePixelRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = liveStroke;
    if (stroke == null) {
      return;
    }

    if (_isEraserTool(stroke.toolType)) {
      return;
    }

    final points = stroke.pointsNorm;
    if (points.isEmpty) {
      return;
    }

    final path = _buildPath(points, size);
    final paint = _buildPaint(stroke);
    final scaledPoints = points
        .map(
          (point) => Offset(point.dx * size.width, point.dy * size.height),
        )
        .toList(growable: false);

    if (points.length == 1) {
      canvas.drawPoints(ui.PointMode.points, scaledPoints, paint);
      return;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant LiveStrokePainter oldDelegate) {
    final current = liveStroke;
    final previous = oldDelegate.liveStroke;

    if (identical(current, previous) &&
        devicePixelRatio == oldDelegate.devicePixelRatio) {
      return false;
    }

    if (current == null || previous == null) {
      return current != previous ||
          devicePixelRatio != oldDelegate.devicePixelRatio;
    }

    final currentLast = current.pointsNorm.isNotEmpty ? current.pointsNorm.last : null;
    final previousLast =
        previous.pointsNorm.isNotEmpty ? previous.pointsNorm.last : null;

    return current.id != previous.id ||
        current.pointsNorm.length != previous.pointsNorm.length ||
        currentLast != previousLast ||
        current.style != previous.style ||
        current.opacity != previous.opacity ||
        current.toolType != previous.toolType ||
        devicePixelRatio != oldDelegate.devicePixelRatio;
  }

  bool _isEraserTool(DrawingTool tool) {
    return tool == DrawingTool.strokeEraser || tool == DrawingTool.areaEraser;
  }

  Path _buildPath(List<Offset> points, Size size) {
    final first = Offset(
      points.first.dx * size.width,
      points.first.dy * size.height,
    );
    final path = Path()..moveTo(first.dx, first.dy);
    for (var i = 1; i < points.length; i += 1) {
      path.lineTo(points[i].dx * size.width, points[i].dy * size.height);
    }
    return path;
  }

  Paint _buildPaint(DrawingStroke stroke) {
    final baseColor = Color(stroke.style.argbColor);
    final effectiveOpacity =
        (stroke.style.opacity * stroke.opacity).clamp(0.0, 1.0).toDouble();

    return Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke.style.widthPx
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..color = baseColor.withValues(alpha: effectiveOpacity);
  }
}
