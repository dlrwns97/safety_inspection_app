import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'package:safety_inspection_app/screens/drawing/drawing_types.dart';
import 'package:safety_inspection_app/screens/drawing/models/drawing_stroke.dart';

/// Paints only the in-progress stroke as a live overlay above cached content.
class LiveStrokePainter extends CustomPainter {
  const LiveStrokePainter({
    required this.liveStroke,
    required this.devicePixelRatio,
    super.repaint,
  });

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

    final paint = _buildPaint(stroke);
    final scaledPoints = points
        .map(
          (point) => Offset(point.dx * size.width, point.dy * size.height),
        )
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
        canvas.drawPoints(ui.PointMode.points, <Offset>[scaledPoints[start]], paint);
      } else {
        final path = _buildPath(scaledPoints, start: start, end: end);
        canvas.drawPath(path, paint);
      }
      i = end;
    }
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
        current.erasedMaskVersion != previous.erasedMaskVersion ||
        !listEquals(current.erasedMask, previous.erasedMask) ||
        devicePixelRatio != oldDelegate.devicePixelRatio;
  }

  bool _isEraserTool(DrawingTool tool) {
    return tool == DrawingTool.strokeEraser || tool == DrawingTool.areaEraser;
  }

  Path _buildPath(List<Offset> points, {required int start, required int end}) {
    final path = Path()..moveTo(points[start].dx, points[start].dy);
    for (var i = start + 1; i <= end; i += 1) {
      path.lineTo(points[i].dx, points[i].dy);
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
