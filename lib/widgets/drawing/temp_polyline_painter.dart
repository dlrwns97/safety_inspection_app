import 'package:flutter/material.dart';

class TempPolylinePainter extends CustomPainter {
  TempPolylinePainter({
    required this.strokes,
    required this.inProgress,
    required this.pageSize,
    this.debugLastPageLocal,
  });

  final List<List<Offset>> strokes;
  final List<Offset>? inProgress;
  // Kept for call-site compatibility; painting uses the runtime canvas size.
  final Size pageSize;
  final Offset? debugLastPageLocal;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      _drawPolyline(canvas, size, stroke, paint);
    }
    if (inProgress != null) {
      _drawPolyline(canvas, size, inProgress!, paint);
    }
    if (debugLastPageLocal != null) {
      final debugPaint = Paint()
        ..color = Colors.blueAccent
        ..style = PaintingStyle.fill;
      canvas.drawCircle(debugLastPageLocal!, 4, debugPaint);
    }
  }

  void _drawPolyline(
    Canvas canvas,
    Size size,
    List<Offset> points,
    Paint paint,
  ) {
    if (points.isEmpty || size.width <= 0 || size.height <= 0) {
      return;
    }

    Offset toCanvas(Offset norm, Size canvasSize) =>
        Offset(norm.dx * canvasSize.width, norm.dy * canvasSize.height);

    if (points.length == 1) {
      canvas.drawCircle(
        toCanvas(points.first, size),
        paint.strokeWidth / 2,
        paint,
      );
      return;
    }

    final first = toCanvas(points.first, size);
    final path = Path()..moveTo(first.dx, first.dy);
    for (var i = 1; i < points.length; i++) {
      final point = toCanvas(points[i], size);
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant TempPolylinePainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.inProgress != inProgress ||
        oldDelegate.debugLastPageLocal != debugLastPageLocal;
  }
}
