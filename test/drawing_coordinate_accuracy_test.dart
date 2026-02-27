import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:safety_inspection_app/screens/drawing/drawing_coordinate_utils.dart';
import 'package:safety_inspection_app/screens/drawing/engines/shape_manipulator.dart';

void main() {
  group('Coordinate utils', () {
    test('toNormalized clamps to 0..1 range', () {
      const size = Size(100, 200);

      expect(toNormalized(const Offset(50, 100), size), const Offset(0.5, 0.5));
      expect(toNormalized(const Offset(-10, -20), size), const Offset(0, 0));
      expect(toNormalized(const Offset(120, 240), size), const Offset(1, 1));
    });

    test('toNormalized returns zero for invalid size', () {
      expect(toNormalized(const Offset(10, 20), const Size(0, 100)), Offset.zero);
      expect(toNormalized(const Offset(10, 20), const Size(100, 0)), Offset.zero);
    });
  });

  group('ShapeManipulator coordinate accuracy', () {
    test('translate keeps bounds in normalized canvas', () {
      final manipulator = ShapeManipulator(
        boundsNorm: const Rect.fromLTWH(0.8, 0.8, 0.25, 0.25),
      );

      manipulator.translate(const Offset(0.2, 0.2));

      final b = manipulator.boundsNorm;
      expect(b.left >= 0.0, isTrue);
      expect(b.top >= 0.0, isTrue);
      expect(b.right <= 1.0, isTrue);
      expect(b.bottom <= 1.0, isTrue);
    });

    test('resizeByHandle respects minSizeNorm', () {
      final manipulator = ShapeManipulator(
        boundsNorm: const Rect.fromLTWH(0.2, 0.2, 0.2, 0.2),
        minSizeNorm: 0.1,
      );

      manipulator.resizeByHandle(ShapeHandle.right, const Offset(-0.5, 0.0));
      manipulator.resizeByHandle(ShapeHandle.bottom, const Offset(0.0, -0.5));

      final b = manipulator.boundsNorm;
      expect(b.width >= 0.1, isTrue);
      expect(b.height >= 0.1, isTrue);
    });

    test('hitTestBody works with rotation', () {
      final manipulator = ShapeManipulator(
        boundsNorm: const Rect.fromLTWH(0.3, 0.3, 0.2, 0.2),
      );

      manipulator.rotationRad = math.pi / 4;

      expect(manipulator.hitTestBody(const Offset(0.4, 0.4)), isTrue);
      expect(manipulator.hitTestBody(const Offset(0.05, 0.05)), isFalse);
    });

    test('rotateTo wraps angle into -pi..pi', () {
      final manipulator = ShapeManipulator(
        boundsNorm: const Rect.fromLTWH(0.4, 0.4, 0.2, 0.2),
      );

      manipulator.rotateTo(const Offset(1.0, 0.5));
      expect(manipulator.rotationRad, closeTo(0.0, 1e-6));

      manipulator.rotateTo(const Offset(0.0, 0.5));
      expect(manipulator.rotationRad.abs(), closeTo(math.pi, 1e-6));
    });
  });
}
