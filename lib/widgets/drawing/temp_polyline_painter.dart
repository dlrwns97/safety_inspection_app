import 'package:flutter/material.dart';

class TempPolylinePainter extends CustomPainter {
  TempPolylinePainter({
    required this.strokes,
    required this.inProgress,
    required this.baseScale,
  });

  final List<List<Offset>> strokes;
  final List<Offset>? inProgress;
  final double baseScale;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.save();
    canvas.scale(baseScale);
    for (final stroke in strokes) {
      _drawPolyline(canvas, stroke, paint);
    }
    if (inProgress != null) {
      _drawPolyline(canvas, inProgress!, paint);
    }
    canvas.restore();
  }

  void _drawPolyline(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.isEmpty) {
      return;
    }
    if (points.length == 1) {
      canvas.drawCircle(points.first, paint.strokeWidth / 2, paint);
      return;
    }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant TempPolylinePainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.inProgress != inProgress ||
        oldDelegate.baseScale != baseScale;
  }
}
