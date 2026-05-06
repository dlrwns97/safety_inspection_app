import 'dart:math' as math;
import 'dart:ui';

import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';
import 'package:safety_inspection_app/screens/drawing/drawing_types.dart';
import 'package:safety_inspection_app/screens/drawing/engines/shape_manipulator.dart';

enum ShapeInteractionOperation { none, create, translate, resize, rotate }

class ShapeTapSelection {
  const ShapeTapSelection({required this.strokeId, required this.manipulator});

  final String strokeId;
  final ShapeManipulator manipulator;
}

class ShapeInteractionStart {
  const ShapeInteractionStart({
    required this.operation,
    required this.manipulator,
    required this.handle,
    required this.startNorm,
    required this.createThresholdNorm,
    this.strokeId,
    this.rotateGestureStartAngleRad,
    this.rotateGestureStartRotationRad,
  });

  final ShapeInteractionOperation operation;
  final ShapeManipulator manipulator;
  final ShapeHandle handle;
  final Offset startNorm;
  final double createThresholdNorm;
  final String? strokeId;
  final double? rotateGestureStartAngleRad;
  final double? rotateGestureStartRotationRad;
}

class ShapeRotationUpdate {
  const ShapeRotationUpdate({
    required this.rotationRad,
    required this.snappedAngleRad,
  });

  final double rotationRad;
  final double? snappedAngleRad;
}

class ShapeInteractionCoordinator {
  const ShapeInteractionCoordinator();

  ShapeTapSelection? findTapSelection({
    required List<DrawingStroke> strokes,
    required Offset normPoint,
    Size? pageSize,
  }) {
    final hitPaddingNorm = pageSize == null || pageSize.isEmpty
        ? 0.02
        : (12.0 / pageSize.shortestSide).clamp(0.005, 0.06);
    for (var i = strokes.length - 1; i >= 0; i -= 1) {
      final stroke = strokes[i];
      if (stroke.toolType != DrawingTool.shape) {
        continue;
      }
      final rawBounds = strokeBounds(stroke.pointsNorm);
      if (rawBounds == null) {
        continue;
      }
      final hitBounds = Rect.fromLTRB(
        (rawBounds.left - hitPaddingNorm).clamp(0.0, 1.0),
        (rawBounds.top - hitPaddingNorm).clamp(0.0, 1.0),
        (rawBounds.right + hitPaddingNorm).clamp(0.0, 1.0),
        (rawBounds.bottom + hitPaddingNorm).clamp(0.0, 1.0),
      );
      if (hitBounds.contains(normPoint)) {
        return ShapeTapSelection(
          strokeId: stroke.id,
          manipulator: ShapeManipulator(boundsNorm: rawBounds),
        );
      }
    }
    return null;
  }

  ShapeInteractionStart start({
    required List<DrawingStroke> strokes,
    required Offset startNorm,
    required Size pageSize,
  }) {
    final hitPaddingNorm = (12.0 / pageSize.shortestSide).clamp(0.005, 0.06);
    final createThresholdNorm = (8.0 / pageSize.shortestSide).clamp(
      0.004,
      0.03,
    );
    DrawingStroke? handleCandidate;
    ShapeManipulator? handleManipulator;
    ShapeHandle handleHit = ShapeHandle.none;
    DrawingStroke? candidate;
    Rect? candidateBounds;

    for (var i = strokes.length - 1; i >= 0; i -= 1) {
      final stroke = strokes[i];
      if (stroke.toolType != DrawingTool.shape) {
        continue;
      }
      final bounds = strokeBounds(stroke.pointsNorm);
      if (bounds == null) {
        continue;
      }
      final manipulator = ShapeManipulator(boundsNorm: bounds);
      final minSideNorm = math.min(bounds.width.abs(), bounds.height.abs());
      final tinyShapeThresholdNorm = (manipulator.handleHitRadiusNorm * 2.2)
          .clamp(0.02, 0.10);
      final isTinyShape = minSideNorm <= tinyShapeThresholdNorm;
      final bodyHit = manipulator.hitTestBody(startNorm);
      if (isTinyShape && bodyHit) {
        candidate = stroke;
        candidateBounds = bounds;
        break;
      }

      final hitHandle = manipulator.hitTestHandle(startNorm);
      if (hitHandle != ShapeHandle.none) {
        handleCandidate = stroke;
        handleManipulator = manipulator;
        handleHit = hitHandle;
        break;
      }

      final paddedBounds = Rect.fromLTRB(
        (bounds.left - hitPaddingNorm).clamp(0.0, 1.0),
        (bounds.top - hitPaddingNorm).clamp(0.0, 1.0),
        (bounds.right + hitPaddingNorm).clamp(0.0, 1.0),
        (bounds.bottom + hitPaddingNorm).clamp(0.0, 1.0),
      );
      if (paddedBounds.contains(startNorm) || bodyHit) {
        candidate = stroke;
        candidateBounds = bounds;
        break;
      }
    }

    if (handleCandidate != null && handleManipulator != null) {
      final center = handleManipulator.boundsNorm.center;
      final gestureStartAngle = pointerAngleForPageSpace(
        centerNorm: center,
        pointerNorm: startNorm,
        pageSize: pageSize,
      );
      final isRotate = handleHit == ShapeHandle.rotate;
      return ShapeInteractionStart(
        operation: isRotate
            ? ShapeInteractionOperation.rotate
            : ShapeInteractionOperation.resize,
        manipulator: handleManipulator,
        handle: handleHit,
        startNorm: startNorm,
        createThresholdNorm: 0.0,
        strokeId: handleCandidate.id,
        rotateGestureStartAngleRad: isRotate ? gestureStartAngle : null,
        rotateGestureStartRotationRad: isRotate
            ? handleManipulator.rotationRad
            : null,
      );
    }

    if (candidate != null && candidateBounds != null) {
      final manipulator = ShapeManipulator(boundsNorm: candidateBounds);
      if (manipulator.hitTestBody(startNorm)) {
        return ShapeInteractionStart(
          operation: ShapeInteractionOperation.translate,
          manipulator: manipulator,
          handle: ShapeHandle.none,
          startNorm: startNorm,
          createThresholdNorm: 0.0,
          strokeId: candidate.id,
        );
      }
    }

    return ShapeInteractionStart(
      operation: ShapeInteractionOperation.create,
      manipulator: ShapeManipulator(
        boundsNorm: Rect.fromLTWH(startNorm.dx, startNorm.dy, 0.0, 0.0),
      ),
      handle: ShapeHandle.none,
      startNorm: startNorm,
      createThresholdNorm: createThresholdNorm,
    );
  }

  static Rect? strokeBounds(List<Offset> pointsNorm) {
    if (pointsNorm.isEmpty) {
      return null;
    }
    var left = 1.0;
    var right = 0.0;
    var top = 1.0;
    var bottom = 0.0;
    for (final point in pointsNorm) {
      final clamped = Offset(
        point.dx.clamp(0.0, 1.0),
        point.dy.clamp(0.0, 1.0),
      );
      left = left < clamped.dx ? left : clamped.dx;
      right = right > clamped.dx ? right : clamped.dx;
      top = top < clamped.dy ? top : clamped.dy;
      bottom = bottom > clamped.dy ? bottom : clamped.dy;
    }
    if (left > right || top > bottom) {
      return null;
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  static Offset constrainCreateEndNorm(
    Offset start,
    Offset current, {
    required Size pageSize,
    required bool aspectLocked,
  }) {
    if (!aspectLocked) {
      return current;
    }
    final dx = current.dx - start.dx;
    final dy = current.dy - start.dy;
    if (dx.abs() < 1e-6 || dy.abs() < 1e-6) {
      return current;
    }
    final dxPx = dx * pageSize.width;
    final dyPx = dy * pageSize.height;
    final lockedPx = math.max(dxPx.abs(), dyPx.abs());
    final lockedDx = (lockedPx / pageSize.width) * (dx.isNegative ? -1.0 : 1.0);
    final lockedDy =
        (lockedPx / pageSize.height) * (dy.isNegative ? -1.0 : 1.0);
    final adjusted = Offset(start.dx + lockedDx, start.dy + lockedDy);
    return Offset(adjusted.dx.clamp(0.0, 1.0), adjusted.dy.clamp(0.0, 1.0));
  }

  static ShapeRotationUpdate rotateWithSnap({
    required ShapeManipulator manipulator,
    required Offset norm,
    required Size pageSize,
    required double? gestureStartAngleRad,
    required double? gestureStartRotationRad,
    required double? currentSnappedAngleRad,
  }) {
    final rawAngle = rawRotateTargetAngle(
      manipulator: manipulator,
      norm: norm,
      pageSize: pageSize,
      gestureStartAngleRad: gestureStartAngleRad,
      gestureStartRotationRad: gestureStartRotationRad,
    );
    const enterSnapDeg = 7.0;
    const exitSnapDeg = 11.0;
    final enterSnapRad = degToRad(enterSnapDeg);
    final exitSnapRad = degToRad(exitSnapDeg);

    final snapped = currentSnappedAngleRad;
    if (snapped != null) {
      final diff = wrapAngleDiff(rawAngle, snapped).abs();
      if (diff <= exitSnapRad) {
        return ShapeRotationUpdate(
          rotationRad: snapped,
          snappedAngleRad: snapped,
        );
      }
    }

    final candidateAngles = <double>[];
    const divisions = 24;
    for (var i = 0; i < divisions; i += 1) {
      candidateAngles.add(-math.pi + (2 * math.pi * i / divisions));
    }

    var nearest = candidateAngles.first;
    var minDiff = wrapAngleDiff(rawAngle, nearest).abs();
    for (final angle in candidateAngles.skip(1)) {
      final diff = wrapAngleDiff(rawAngle, angle).abs();
      if (diff < minDiff) {
        minDiff = diff;
        nearest = angle;
      }
    }

    if (minDiff <= enterSnapRad) {
      return ShapeRotationUpdate(
        rotationRad: nearest,
        snappedAngleRad: nearest,
      );
    }

    return ShapeRotationUpdate(rotationRad: rawAngle, snappedAngleRad: null);
  }

  static double rawRotateTargetAngle({
    required ShapeManipulator manipulator,
    required Offset norm,
    required Size pageSize,
    required double? gestureStartAngleRad,
    required double? gestureStartRotationRad,
  }) {
    final center = manipulator.boundsNorm.center;
    final pointerAngle = pointerAngleForPageSpace(
      centerNorm: center,
      pointerNorm: norm,
      pageSize: pageSize,
    );
    if (gestureStartAngleRad == null || gestureStartRotationRad == null) {
      return pointerAngle;
    }
    return gestureStartRotationRad +
        wrapAngleDiff(pointerAngle, gestureStartAngleRad);
  }

  static List<Offset> transformPointsByBounds({
    required List<Offset> points,
    required Rect fromBounds,
    required Rect toBounds,
    required double rotationRad,
    required Size pageSize,
  }) {
    final fromWidth = fromBounds.width <= 0 ? 1.0 : fromBounds.width;
    final fromHeight = fromBounds.height <= 0 ? 1.0 : fromBounds.height;
    final toWidth = toBounds.width;
    final toHeight = toBounds.height;
    final toLeft = toBounds.left;
    final toTop = toBounds.top;
    final toCenter = toBounds.center;
    return points
        .map((point) {
          final ratioX = (point.dx - fromBounds.left) / fromWidth;
          final ratioY = (point.dy - fromBounds.top) / fromHeight;
          final scaled = Offset(
            toLeft + ratioX * toWidth,
            toTop + ratioY * toHeight,
          );
          final rotated = rotateAroundCenterInPageSpace(
            point: scaled,
            center: toCenter,
            angleRad: rotationRad,
            pageSize: pageSize,
          );
          return Offset(rotated.dx.clamp(0.0, 1.0), rotated.dy.clamp(0.0, 1.0));
        })
        .toList(growable: false);
  }

  static Offset rotateAroundCenterInPageSpace({
    required Offset point,
    required Offset center,
    required double angleRad,
    required Size pageSize,
  }) {
    if (pageSize.width <= 0 || pageSize.height <= 0) {
      return point;
    }
    final pointPx = Offset(
      point.dx * pageSize.width,
      point.dy * pageSize.height,
    );
    final centerPx = Offset(
      center.dx * pageSize.width,
      center.dy * pageSize.height,
    );
    final cosA = math.cos(angleRad);
    final sinA = math.sin(angleRad);
    final dx = pointPx.dx - centerPx.dx;
    final dy = pointPx.dy - centerPx.dy;
    final rotatedPx = Offset(
      centerPx.dx + dx * cosA - dy * sinA,
      centerPx.dy + dx * sinA + dy * cosA,
    );
    return Offset(
      rotatedPx.dx / pageSize.width,
      rotatedPx.dy / pageSize.height,
    );
  }

  static double pointerAngleForPageSpace({
    required Offset centerNorm,
    required Offset pointerNorm,
    required Size pageSize,
  }) {
    final dx = (pointerNorm.dx - centerNorm.dx) * pageSize.width;
    final dy = (pointerNorm.dy - centerNorm.dy) * pageSize.height;
    if (dx.abs() < 1e-9 && dy.abs() < 1e-9) {
      return 0.0;
    }
    return math.atan2(dy, dx);
  }

  static double degToRad(double deg) => deg * math.pi / 180.0;

  static double wrapAngleDiff(double a, double b) {
    final twoPi = 2 * math.pi;
    var diff = (a - b) % twoPi;
    if (diff > math.pi) {
      diff -= twoPi;
    } else if (diff < -math.pi) {
      diff += twoPi;
    }
    return diff;
  }
}
