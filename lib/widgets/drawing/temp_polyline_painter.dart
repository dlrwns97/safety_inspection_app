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
    var resolvedOpacity = style.opacity;
    var resolvedStrokeWidth = style.widthPx;
    var resolvedStrokeCap = StrokeCap.round;
    var resolvedStrokeJoin = StrokeJoin.round;
    var resolvedBlendMode = switch (style.kind) {
      StrokeToolKind.highlighter => BlendMode.multiply,
      StrokeToolKind.eraser => BlendMode.clear,
      StrokeToolKind.pen => BlendMode.srcOver,
    };

    switch (style.variant) {
      case PenVariant.pencil:
        resolvedOpacity *= 0.8;
        break;
      case PenVariant.fountain:
        resolvedStrokeWidth *= 1.15;
        break;
      case PenVariant.marker:
        resolvedStrokeWidth *= 1.10;
        resolvedOpacity *= 0.98;
        break;
      case PenVariant.calligraphy:
        resolvedStrokeCap = StrokeCap.square;
        resolvedStrokeJoin = StrokeJoin.bevel;
        break;
      case PenVariant.highlighterSoft:
        resolvedBlendMode = BlendMode.multiply;
        break;
      case PenVariant.highlighterChisel:
        resolvedStrokeCap = StrokeCap.square;
        resolvedStrokeJoin = StrokeJoin.bevel;
        resolvedBlendMode = BlendMode.multiply;
        break;
      case PenVariant.ballpoint:
        break;
    }

    final paint = Paint()
      ..color = Color(style.argbColor).withOpacity(resolvedOpacity.clamp(0.0, 1.0))
      ..strokeWidth = resolvedStrokeWidth
      ..strokeCap = resolvedStrokeCap
      ..strokeJoin = resolvedStrokeJoin
      ..style = PaintingStyle.stroke
      ..blendMode = resolvedBlendMode;

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
