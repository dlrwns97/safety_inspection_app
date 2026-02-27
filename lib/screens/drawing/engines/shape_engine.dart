import 'dart:math' as math;
import 'dart:ui';

import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';
import 'package:safety_inspection_app/screens/drawing/drawing_types.dart';

enum ShapeType { rectangle, circle, triangle, hShape }

class ShapeEngine {
  const ShapeEngine._();

  static Offset _clampNorm(Offset point) {
    return Offset(point.dx.clamp(0.0, 1.0), point.dy.clamp(0.0, 1.0));
  }

  static bool _isDegenerate(Offset a, Offset b) {
    return (a - b).distance < 1e-6;
  }

  static Path buildPath(
    ShapeType type,
    Offset startNorm,
    Offset endNorm,
    Size canvasSize, {
    // ignore: unused_parameter
    int circleSegments = 64,
  }) {
    final clampedStart = _clampNorm(startNorm);
    final clampedEnd = _clampNorm(endNorm);
    final startPx = Offset(
      clampedStart.dx * canvasSize.width,
      clampedStart.dy * canvasSize.height,
    );
    final endPx = Offset(
      clampedEnd.dx * canvasSize.width,
      clampedEnd.dy * canvasSize.height,
    );
    final path = Path();

    switch (type) {
      case ShapeType.rectangle:
        {
          final rect = Rect.fromPoints(startPx, endPx);
          path.addRect(rect);
          return path;
        }
      case ShapeType.circle:
        {
          final rect = Rect.fromPoints(startPx, endPx);
          path.addOval(rect);
          return path;
        }
      case ShapeType.triangle:
        {
          final rect = Rect.fromPoints(startPx, endPx);
          final top = Offset(rect.center.dx, rect.top);
          final left = Offset(rect.left, rect.bottom);
          final right = Offset(rect.right, rect.bottom);
          path.moveTo(top.dx, top.dy);
          path.lineTo(left.dx, left.dy);
          path.lineTo(right.dx, right.dy);
          path.close();
          return path;
        }
      case ShapeType.hShape:
        {
          final rect = Rect.fromPoints(startPx, endPx);
          final midY = rect.center.dy;
          path.moveTo(rect.left, rect.top);
          path.lineTo(rect.left, rect.bottom);
          path.moveTo(rect.left, midY);
          path.lineTo(rect.right, midY);
          path.moveTo(rect.right, rect.top);
          path.lineTo(rect.right, rect.bottom);
          return path;
        }
    }
  }

  static List<Offset> buildPointsNorm(
    ShapeType type,
    Offset startNorm,
    Offset endNorm, {
    int circleSegments = 64,
  }) {
    final clampedStart = _clampNorm(startNorm);
    final clampedEnd = _clampNorm(endNorm);

    if (_isDegenerate(clampedStart, clampedEnd)) {
      return <Offset>[clampedStart];
    }

    switch (type) {
      case ShapeType.rectangle:
        {
          final left = clampedStart.dx < clampedEnd.dx
              ? clampedStart.dx
              : clampedEnd.dx;
          final right = clampedStart.dx > clampedEnd.dx
              ? clampedStart.dx
              : clampedEnd.dx;
          final top = clampedStart.dy < clampedEnd.dy
              ? clampedStart.dy
              : clampedEnd.dy;
          final bottom = clampedStart.dy > clampedEnd.dy
              ? clampedStart.dy
              : clampedEnd.dy;
          return <Offset>[
            Offset(left, top),
            Offset(right, top),
            Offset(right, bottom),
            Offset(left, bottom),
            Offset(left, top),
          ];
        }
      case ShapeType.circle:
        {
          final center = Offset(
            (clampedStart.dx + clampedEnd.dx) * 0.5,
            (clampedStart.dy + clampedEnd.dy) * 0.5,
          );
          final radiusX = (clampedEnd.dx - clampedStart.dx).abs() * 0.5;
          final radiusY = (clampedEnd.dy - clampedStart.dy).abs() * 0.5;
          final segments = circleSegments < 12 ? 12 : circleSegments;
          final points = <Offset>[];
          for (var i = 0; i <= segments; i += 1) {
            final angle = 2 * math.pi * i / segments;
            final point = Offset(
              center.dx + math.cos(angle) * radiusX,
              center.dy + math.sin(angle) * radiusY,
            );
            points.add(_clampNorm(point));
          }
          return points;
        }
      case ShapeType.triangle:
        {
          final left = clampedStart.dx < clampedEnd.dx
              ? clampedStart.dx
              : clampedEnd.dx;
          final right = clampedStart.dx > clampedEnd.dx
              ? clampedStart.dx
              : clampedEnd.dx;
          final topY = clampedStart.dy < clampedEnd.dy
              ? clampedStart.dy
              : clampedEnd.dy;
          final bottomY = clampedStart.dy > clampedEnd.dy
              ? clampedStart.dy
              : clampedEnd.dy;
          final top = Offset((left + right) * 0.5, topY);
          final bottomLeft = Offset(left, bottomY);
          final bottomRight = Offset(right, bottomY);
          return <Offset>[
            _clampNorm(top),
            _clampNorm(bottomLeft),
            _clampNorm(bottomRight),
            _clampNorm(top),
          ];
        }
      case ShapeType.hShape:
        {
          final left = clampedStart.dx < clampedEnd.dx
              ? clampedStart.dx
              : clampedEnd.dx;
          final right = clampedStart.dx > clampedEnd.dx
              ? clampedStart.dx
              : clampedEnd.dx;
          final top = clampedStart.dy < clampedEnd.dy
              ? clampedStart.dy
              : clampedEnd.dy;
          final bottom = clampedStart.dy > clampedEnd.dy
              ? clampedStart.dy
              : clampedEnd.dy;
          final midY = (top + bottom) * 0.5;
          return <Offset>[
            Offset(left, top),
            Offset(left, bottom),
            Offset(left, midY),
            Offset(right, midY),
            Offset(right, top),
            Offset(right, bottom),
          ].map(_clampNorm).toList(growable: false);
        }
    }
  }

  static DrawingStroke toStroke(
    ShapeType type,
    int pageNumber,
    Offset startNorm,
    Offset endNorm,
    StrokeStyle style, {
    int? fillArgb,
    int circleSegments = 64,
  }) {
    return DrawingStroke(
      id: DrawingStroke.generateId(),
      pageNumber: pageNumber,
      toolType: DrawingTool.shape,
      style: style,
      shapeType: type.name,
      shapeFillArgb: fillArgb,
      pointsNorm: buildPointsNorm(
        type,
        startNorm,
        endNorm,
        circleSegments: circleSegments,
      ),
      opacity: style.opacity,
    );
  }
}
