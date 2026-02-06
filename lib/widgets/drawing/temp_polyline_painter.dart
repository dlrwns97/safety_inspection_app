import 'package:flutter/material.dart';

class TempPolylinePainter extends CustomPainter {
  TempPolylinePainter({
    required this.strokes,
    required this.inProgress,
    required this.pageSize,
    required this.transform,
    required this.destTopLeft,
  });

  final List<List<Offset>> strokes;
  final List<Offset>? inProgress;
  final Size pageSize;
  final Matrix4 transform;
  final Offset destTopLeft;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      _drawPolyline(canvas, stroke, paint);
    }
    if (inProgress != null) {
      _drawPolyline(canvas, inProgress!, paint);
    }
  }

  void _drawPolyline(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.isEmpty || pageSize.width <= 0 || pageSize.height <= 0) {
      return;
    }

    Offset toOverlayPoint(Offset point) {
      final pageLocal = Offset(
        point.dx * pageSize.width,
        point.dy * pageSize.height,
      );
      final destLocal = MatrixUtils.transformPoint(transform, pageLocal);
      return destTopLeft + destLocal;
    }

    if (points.length == 1) {
      canvas.drawCircle(toOverlayPoint(points.first), paint.strokeWidth / 2, paint);
      return;
    }

    final first = toOverlayPoint(points.first);
    final path = Path()..moveTo(first.dx, first.dy);
    for (var i = 1; i < points.length; i++) {
      final point = toOverlayPoint(points[i]);
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant TempPolylinePainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.inProgress != inProgress ||
        oldDelegate.pageSize != pageSize ||
        oldDelegate.transform != transform ||
        oldDelegate.destTopLeft != destTopLeft;
  }
}
