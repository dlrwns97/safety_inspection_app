import 'dart:math' as math;
import 'dart:ui';

enum ShapeHandle {
  topLeft,
  top,
  topRight,
  right,
  bottomRight,
  bottom,
  bottomLeft,
  left,
  rotate,
  none,
}

class ShapeManipulator {
  ShapeManipulator({
    required this.boundsNorm,
    this.rotationRad = 0.0,
    this.minSizeNorm = 0.02,
    this.rotateHandleOffsetNorm = 0.06,
    this.handleHitRadiusNorm = 0.03,
  });

  Rect boundsNorm;
  double rotationRad;
  final double minSizeNorm;
  final double rotateHandleOffsetNorm;
  final double handleHitRadiusNorm;

  static Offset _clampNormPoint(Offset point) {
    return Offset(point.dx.clamp(0.0, 1.0), point.dy.clamp(0.0, 1.0));
  }

  static Offset _clampNormPointWithMargin(Offset point, double margin) {
    final clampedMargin = margin.clamp(0.0, 0.2);
    return Offset(
      point.dx.clamp(clampedMargin, 1.0 - clampedMargin),
      point.dy.clamp(clampedMargin, 1.0 - clampedMargin),
    );
  }

  static bool _isInNormSpace(Offset point) {
    return point.dx >= 0.0 &&
        point.dx <= 1.0 &&
        point.dy >= 0.0 &&
        point.dy <= 1.0;
  }

  static Rect _clampNormRect(Rect rect) {
    final width = rect.width.clamp(0.0, 1.0);
    final height = rect.height.clamp(0.0, 1.0);

    var left = rect.left;
    var top = rect.top;
    var right = left + width;
    var bottom = top + height;

    if (left < 0.0) {
      right -= left;
      left = 0.0;
    }
    if (right > 1.0) {
      left -= (right - 1.0);
      right = 1.0;
    }
    if (left < 0.0) {
      left = 0.0;
    }

    if (top < 0.0) {
      bottom -= top;
      top = 0.0;
    }
    if (bottom > 1.0) {
      top -= (bottom - 1.0);
      bottom = 1.0;
    }
    if (top < 0.0) {
      top = 0.0;
    }

    return Rect.fromLTRB(
      left,
      top,
      right.clamp(left, 1.0),
      bottom.clamp(top, 1.0),
    );
  }

  static double _wrapAngle(double rad) {
    final wrapped = (rad + math.pi) % (2 * math.pi);
    return (wrapped >= 0 ? wrapped : wrapped + 2 * math.pi) - math.pi;
  }

  static Offset _rotatePoint(Offset point, Offset origin, double angleRad) {
    final dx = point.dx - origin.dx;
    final dy = point.dy - origin.dy;
    final cosA = math.cos(angleRad);
    final sinA = math.sin(angleRad);
    return Offset(
      origin.dx + dx * cosA - dy * sinA,
      origin.dy + dx * sinA + dy * cosA,
    );
  }

  static Offset _rotateDelta(Offset delta, double angleRad) {
    final cosA = math.cos(angleRad);
    final sinA = math.sin(angleRad);
    return Offset(
      delta.dx * cosA - delta.dy * sinA,
      delta.dx * sinA + delta.dy * cosA,
    );
  }

  static Offset _rotateDeltaInverse(Offset delta, double angleRad) {
    return _rotateDelta(delta, -angleRad);
  }

  List<(ShapeHandle, Offset)> handlePositions() {
    final center = boundsNorm.center;
    final l = boundsNorm.left;
    final t = boundsNorm.top;
    final r = boundsNorm.right;
    final b = boundsNorm.bottom;
    final midX = (l + r) * 0.5;
    final midY = (t + b) * 0.5;

    final raw = <(ShapeHandle, Offset)>[
      (ShapeHandle.topLeft, Offset(l, t)),
      (ShapeHandle.top, Offset(midX, t)),
      (ShapeHandle.topRight, Offset(r, t)),
      (ShapeHandle.right, Offset(r, midY)),
      (ShapeHandle.bottomRight, Offset(r, b)),
      (ShapeHandle.bottom, Offset(midX, b)),
      (ShapeHandle.bottomLeft, Offset(l, b)),
      (ShapeHandle.left, Offset(l, midY)),
      (ShapeHandle.rotate, Offset(midX, b + rotateHandleOffsetNorm)),
    ];

    final rotateMargin = (handleHitRadiusNorm * 0.7).clamp(0.01, 0.04);
    final withRotation = raw.map((entry) {
      final rotated = _rotatePoint(entry.$2, center, rotationRad);
      if (entry.$1 == ShapeHandle.rotate) {
        return (entry.$1, _clampNormPointWithMargin(rotated, rotateMargin));
      }
      return (entry.$1, _clampNormPoint(rotated));
    });
    return List<(ShapeHandle, Offset)>.from(withRotation);
  }

  ShapeHandle hitTestHandle(Offset pNorm) {
    final target = pNorm;
    var closest = ShapeHandle.none;
    var closestDist = double.infinity;

    for (final (handle, point) in handlePositions()) {
      final dist = (point - target).distance;
      if (dist <= handleHitRadiusNorm && dist < closestDist) {
        closestDist = dist;
        closest = handle;
      }
    }
    return closest;
  }

  bool hitTestBody(Offset pNorm) {
    if (!_isInNormSpace(pNorm)) {
      return false;
    }
    final point = pNorm;
    final center = boundsNorm.center;
    final localPoint = _rotatePoint(point, center, -rotationRad);
    return boundsNorm.contains(localPoint);
  }

  void resizeByHandle(ShapeHandle handle, Offset deltaNorm) {
    if (handle == ShapeHandle.none || handle == ShapeHandle.rotate) {
      return;
    }

    final localDelta = _rotateDeltaInverse(deltaNorm, rotationRad);
    final moveLeft =
        handle == ShapeHandle.topLeft ||
        handle == ShapeHandle.left ||
        handle == ShapeHandle.bottomLeft;
    final moveRight =
        handle == ShapeHandle.topRight ||
        handle == ShapeHandle.right ||
        handle == ShapeHandle.bottomRight;
    final moveTop =
        handle == ShapeHandle.topLeft ||
        handle == ShapeHandle.top ||
        handle == ShapeHandle.topRight;
    final moveBottom =
        handle == ShapeHandle.bottomLeft ||
        handle == ShapeHandle.bottom ||
        handle == ShapeHandle.bottomRight;

    var l = boundsNorm.left;
    var t = boundsNorm.top;
    var r = boundsNorm.right;
    var b = boundsNorm.bottom;

    if (moveLeft) {
      l += localDelta.dx;
      if (r - l < minSizeNorm) {
        l = r - minSizeNorm;
      }
      if (l < 0.0) {
        l = 0.0;
      }
    }
    if (moveRight) {
      r += localDelta.dx;
      if (r - l < minSizeNorm) {
        r = l + minSizeNorm;
      }
      if (r > 1.0) {
        r = 1.0;
      }
    }
    if (!moveLeft && !moveRight && (l < 0.0 || r > 1.0)) {
      l = l.clamp(0.0, 1.0);
      r = r.clamp(l + minSizeNorm, 1.0);
    }

    if (moveTop) {
      t += localDelta.dy;
      if (b - t < minSizeNorm) {
        t = b - minSizeNorm;
      }
      if (t < 0.0) {
        t = 0.0;
      }
    }
    if (moveBottom) {
      b += localDelta.dy;
      if (b - t < minSizeNorm) {
        b = t + minSizeNorm;
      }
      if (b > 1.0) {
        b = 1.0;
      }
    }
    if (!moveTop && !moveBottom && (t < 0.0 || b > 1.0)) {
      t = t.clamp(0.0, 1.0);
      b = b.clamp(t + minSizeNorm, 1.0);
    }

    if (r - l < minSizeNorm) {
      if (moveLeft && !moveRight) {
        l = r - minSizeNorm;
      } else if (moveRight && !moveLeft) {
        r = l + minSizeNorm;
      }
    }
    if (b - t < minSizeNorm) {
      if (moveTop && !moveBottom) {
        t = b - minSizeNorm;
      } else if (moveBottom && !moveTop) {
        b = t + minSizeNorm;
      }
    }

    boundsNorm = _clampNormRect(Rect.fromLTRB(l, t, r, b));
  }

  void rotateTo(Offset pNorm) {
    final center = boundsNorm.center;
    final target = _clampNormPoint(pNorm);
    rotationRad = _wrapAngle(
      math.atan2(target.dy - center.dy, target.dx - center.dx),
    );
  }

  void translate(Offset deltaNorm) {
    boundsNorm = _clampNormRect(boundsNorm.shift(deltaNorm));
  }

  Rect get rotatedBoundsNormApprox {
    if (rotationRad == 0.0) {
      return boundsNorm;
    }

    final center = boundsNorm.center;
    final corners = <Offset>[
      Offset(boundsNorm.left, boundsNorm.top),
      Offset(boundsNorm.right, boundsNorm.top),
      Offset(boundsNorm.right, boundsNorm.bottom),
      Offset(boundsNorm.left, boundsNorm.bottom),
    ];
    final rotated = corners
        .map((corner) => _rotatePoint(corner, center, rotationRad))
        .toList(growable: false);

    final xs = rotated.map((point) => point.dx);
    final ys = rotated.map((point) => point.dy);
    final left = xs.reduce(math.min);
    final right = xs.reduce(math.max);
    final top = ys.reduce(math.min);
    final bottom = ys.reduce(math.max);

    return _clampNormRect(Rect.fromLTRB(left, top, right, bottom));
  }
}
