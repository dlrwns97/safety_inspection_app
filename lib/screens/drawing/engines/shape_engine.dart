import 'dart:math' as math;
import 'dart:ui';

import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';
import 'package:safety_inspection_app/screens/drawing/drawing_types.dart';

enum ShapeType {
  arrow,
  rectangle,
  circle,
  triangle,
}

class ShapeEngine {
  const ShapeEngine._();

  static const double _kAssumedCanvasShortSidePx = 900.0;

  static Offset _clampNorm(Offset point) {
    return Offset(
      point.dx.clamp(0.0, 1.0),
      point.dy.clamp(0.0, 1.0),
    );
  }

  static bool _isDegenerate(Offset a, Offset b) {
    return (a - b).distance < 1e-6;
  }

  static Path buildPath(
    ShapeType type,
    Offset startNorm,
    Offset endNorm,
    Size canvasSize, {
    double arrowHeadLengthPx = 18.0,
    double arrowHeadAngleRad = 0.55,
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
      case ShapeType.arrow: {
        final vector = startPx - endPx;
        final len = vector.distance.clamp(1e-6, double.infinity);
        final dir = vector / len;
        final cosA = math.cos(arrowHeadAngleRad);
        final sinA = math.sin(arrowHeadAngleRad);
        final rotatedDir1 = Offset(
          dir.dx * cosA - dir.dy * sinA,
          dir.dx * sinA + dir.dy * cosA,
        );
        final rotatedDir2 = Offset(
          dir.dx * cosA + dir.dy * sinA,
          -dir.dx * sinA + dir.dy * cosA,
        );
        final headLenPx = math.min(arrowHeadLengthPx, len * 0.45);
        final head1Px = endPx + rotatedDir1 * headLenPx;
        final head2Px = endPx + rotatedDir2 * headLenPx;

        path.moveTo(startPx.dx, startPx.dy);
        path.lineTo(endPx.dx, endPx.dy);
        path.moveTo(endPx.dx, endPx.dy);
        path.lineTo(head1Px.dx, head1Px.dy);
        path.moveTo(endPx.dx, endPx.dy);
        path.lineTo(head2Px.dx, head2Px.dy);
        return path;
      }
      case ShapeType.rectangle: {
        final rect = Rect.fromPoints(startPx, endPx);
        path.addRect(rect);
        return path;
      }
      case ShapeType.circle: {
        final rect = Rect.fromPoints(startPx, endPx);
        path.addOval(rect);
        return path;
      }
      case ShapeType.triangle: {
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
    }
  }

  static List<Offset> buildPointsNorm(
    ShapeType type,
    Offset startNorm,
    Offset endNorm, {
    double arrowHeadLengthPx = 18.0,
    double arrowHeadAngleRad = 0.55,
    int circleSegments = 64,
  }) {
    final clampedStart = _clampNorm(startNorm);
    final clampedEnd = _clampNorm(endNorm);

    if (_isDegenerate(clampedStart, clampedEnd)) {
      return <Offset>[clampedStart];
    }

    switch (type) {
      case ShapeType.rectangle: {
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
      case ShapeType.circle: {
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
      case ShapeType.triangle: {
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
      case ShapeType.arrow: {
        final lengthNorm = (clampedEnd - clampedStart).distance;
        final baseHeadLengthNorm =
            arrowHeadLengthPx / _kAssumedCanvasShortSidePx;
        final headLengthNorm = baseHeadLengthNorm.clamp(0.010, lengthNorm * 0.35);
        final baseAngle = math.atan2(
          clampedStart.dy - clampedEnd.dy,
          clampedStart.dx - clampedEnd.dx,
        );
        final head1 = Offset(
          clampedEnd.dx + math.cos(baseAngle + arrowHeadAngleRad) * headLengthNorm,
          clampedEnd.dy + math.sin(baseAngle + arrowHeadAngleRad) * headLengthNorm,
        );
        final head2 = Offset(
          clampedEnd.dx + math.cos(baseAngle - arrowHeadAngleRad) * headLengthNorm,
          clampedEnd.dy + math.sin(baseAngle - arrowHeadAngleRad) * headLengthNorm,
        );
        return <Offset>[
          clampedStart,
          clampedEnd,
          _clampNorm(head1),
          clampedEnd,
          _clampNorm(head2),
        ];
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
    double arrowHeadLengthPx = 18.0,
    double arrowHeadAngleRad = 0.55,
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
        arrowHeadLengthPx: arrowHeadLengthPx,
        arrowHeadAngleRad: arrowHeadAngleRad,
        circleSegments: circleSegments,
      ),
      opacity: style.opacity,
    );
  }
}
