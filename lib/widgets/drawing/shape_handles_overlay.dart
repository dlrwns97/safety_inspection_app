import 'package:flutter/material.dart';
import 'package:safety_inspection_app/screens/drawing/engines/shape_manipulator.dart';

class ShapeHandlesOverlay extends StatelessWidget {
  const ShapeHandlesOverlay({
    super.key,
    required this.manipulator,
    required this.canvasSize,
  });

  final ShapeManipulator manipulator;
  final Size canvasSize;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ShapeHandlesPainter(manipulator: manipulator),
      child: SizedBox(
        width: canvasSize.width,
        height: canvasSize.height,
      ),
    );
  }
}

class _ShapeHandlesPainter extends CustomPainter {
  _ShapeHandlesPainter({required this.manipulator});

  final ShapeManipulator manipulator;

  @override
  void paint(Canvas canvas, Size size) {
    final handlePositions = manipulator.handlePositions();
    if (handlePositions.isEmpty) {
      return;
    }

    final paint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final fill = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.fill;
    final path = Path()
      ..addRect(manipulator.boundsNorm.scaleToCanvas(size));
    canvas.drawPath(path, paint);

    final centerPoints = handlePositions
        .map((entry) => _toCanvas(entry.$2, size))
        .toList(growable: false);
    for (final point in centerPoints) {
      canvas.drawCircle(point, 4, fill);
      canvas.drawCircle(point, 4, paint);
    }

    Offset? rotateHandle;
    for (final entry in handlePositions) {
      if (entry.$1 == ShapeHandle.rotate) {
        rotateHandle = _toCanvas(entry.$2, size);
        break;
      }
    }
    if (rotateHandle != null) {
      final bottomCenter = _toCanvas(
        Offset(
          manipulator.boundsNorm.left + manipulator.boundsNorm.width * 0.5,
          manipulator.boundsNorm.bottom,
        ),
        size,
      );
      canvas.drawLine(bottomCenter, rotateHandle, paint);
      canvas.drawCircle(rotateHandle, 4, fill);
      canvas.drawCircle(rotateHandle, 4, paint);
    }
  }

  Offset _toCanvas(Offset norm, Size size) {
    return Offset(norm.dx * size.width, norm.dy * size.height);
  }

  @override
  bool shouldRepaint(_ShapeHandlesPainter oldDelegate) {
    return oldDelegate.manipulator.boundsNorm != manipulator.boundsNorm ||
        oldDelegate.manipulator.rotationRad != manipulator.rotationRad;
  }
}

extension _ShapeBoundsCanvas on Rect {
  Rect scaleToCanvas(Size size) {
    return Rect.fromLTWH(
      left * size.width,
      top * size.height,
      width * size.width,
      height * size.height,
    );
  }
}
