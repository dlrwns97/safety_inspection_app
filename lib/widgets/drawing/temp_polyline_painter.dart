import 'package:flutter/material.dart';
import 'package:safety_inspection_app/screens/drawing/models/drawing_stroke.dart';

class TempPolylinePainter extends CustomPainter {
  TempPolylinePainter({
    required this.strokes,
    required this.inProgress,
    required this.pageSize,
    this.debugLastPageLocal,
  });

  final List<DrawingStroke> strokes;
  final DrawingStroke? inProgress;
  final Size pageSize;
  final Offset? debugLastPageLocal;

  @override
  void paint(Canvas canvas, Size size) {
    if (pageSize.width <= 0 || pageSize.height <= 0) {
      return;
    }

    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }
    if (inProgress != null) {
      _drawStroke(canvas, inProgress!);
    }
    if (debugLastPageLocal != null) {
      final debugPaint = Paint()
        ..color = Colors.blueAccent
        ..style = PaintingStyle.fill;
      canvas.drawCircle(debugLastPageLocal!, 4, debugPaint);
    }
  }

  void _drawStroke(Canvas canvas, DrawingStroke stroke) {
    final points = stroke.pointsNorm;
    if (points.isEmpty) {
      return;
    }

    final style = stroke.style;
    final paint = Paint()
      ..color = Color(style.argbColor).withOpacity(style.opacity)
      ..strokeWidth = style.widthPx
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..blendMode = switch (style.kind) {
        StrokeToolKind.highlighter => BlendMode.multiply,
        StrokeToolKind.eraser => BlendMode.clear,
        StrokeToolKind.pen => BlendMode.srcOver,
      };

    Offset toPageLocal(Offset normPoint) {
      return Offset(normPoint.dx * pageSize.width, normPoint.dy * pageSize.height);
    }

    if (points.length == 1) {
      canvas.drawCircle(toPageLocal(points.first), paint.strokeWidth / 2, paint);
      return;
    }

    final first = toPageLocal(points.first);
    final path = Path()..moveTo(first.dx, first.dy);
    for (var i = 1; i < points.length; i++) {
      final point = toPageLocal(points[i]);
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant TempPolylinePainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.inProgress != inProgress ||
        oldDelegate.pageSize != pageSize ||
        oldDelegate.debugLastPageLocal != debugLastPageLocal;
  }
}
