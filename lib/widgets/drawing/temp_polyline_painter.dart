import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';

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
    final pointsNorm = stroke.pointsNorm;
    if (pointsNorm.isEmpty) {
      return;
    }

    Offset toPageLocal(Offset normPoint) {
      return Offset(normPoint.dx * pageSize.width, normPoint.dy * pageSize.height);
    }

    final points = pointsNorm.map(toPageLocal).toList(growable: false);
    final style = stroke.style;

    if (style.kind == StrokeToolKind.pen) {
      _drawPenStroke(canvas, points, style);
      return;
    }

    _drawCenterlineStroke(canvas, points, style);
  }

  void _drawPenStroke(Canvas canvas, List<Offset> points, StrokeStyle style) {
    final resolvedOpacity = _resolvedPenOpacity(style);

    if (points.length == 1) {
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = Color(style.argbColor).withOpacity(resolvedOpacity.clamp(0.0, 1.0))
        ..blendMode = BlendMode.srcOver;
      canvas.drawCircle(points.first, style.widthPx / 2, paint);
      return;
    }

    final strokeInput = points
        .map((o) => PointVector(o.dx, o.dy))
        .toList(growable: false);

    final outline = getStroke(
      strokeInput,
      options: _optionsForPen(style),
    );

    if (outline.isEmpty) {
      return;
    }

    final fillPath = _outlineToPath(outline);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Color(style.argbColor).withOpacity(resolvedOpacity.clamp(0.0, 1.0))
      ..blendMode = BlendMode.srcOver;

    canvas.drawPath(fillPath, paint);
  }

  StrokeOptions _optionsForPen(StrokeStyle style) {
    final size = style.widthPx;

    switch (style.variant) {
      case PenVariant.fountainPen:
        return StrokeOptions(
          size: size,
          thinning: 0.55,
          smoothing: 0.75,
          streamline: 0.70,
          simulatePressure: true,
          start: StrokeEndOptions.start(cap: true),
          end: StrokeEndOptions.end(cap: true),
        );
      case PenVariant.calligraphyPen:
        return StrokeOptions(
          size: size,
          thinning: 0.75,
          smoothing: 0.55,
          streamline: 0.60,
          simulatePressure: true,
          start: StrokeEndOptions.start(cap: true),
          end: StrokeEndOptions.end(cap: true),
        );
      case PenVariant.pencil:
        return StrokeOptions(
          size: size * 0.95,
          thinning: 0.35,
          smoothing: 0.40,
          streamline: 0.35,
          simulatePressure: true,
          start: StrokeEndOptions.start(cap: true),
          end: StrokeEndOptions.end(cap: true),
        );
      case PenVariant.pen:
      default:
        return StrokeOptions(
          size: size,
          thinning: 0.60,
          smoothing: 0.65,
          streamline: 0.60,
          simulatePressure: true,
          start: StrokeEndOptions.start(cap: true),
          end: StrokeEndOptions.end(cap: true),
        );
    }
  }

  double _resolvedPenOpacity(StrokeStyle style) {
    var resolvedOpacity = style.opacity;
    if (style.variant == PenVariant.pencil) {
      resolvedOpacity *= 0.85;
    }
    return resolvedOpacity;
  }

  Path _outlineToPath(List<Offset> outline) {
    final path = Path();
    if (outline.isEmpty) {
      return path;
    }

    path.moveTo(outline.first.dx, outline.first.dy);
    for (var i = 0; i < outline.length - 1; ++i) {
      final p0 = outline[i];
      final p1 = outline[i + 1];
      path.quadraticBezierTo(
        p0.dx,
        p0.dy,
        (p0.dx + p1.dx) / 2,
        (p0.dy + p1.dy) / 2,
      );
    }
    path.close();
    return path;
  }

  void _drawCenterlineStroke(Canvas canvas, List<Offset> points, StrokeStyle style) {
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
      case PenVariant.pen:
        break;
      case PenVariant.fountainPen:
        resolvedStrokeWidth *= 1.15;
        break;
      case PenVariant.calligraphyPen:
        resolvedStrokeCap = StrokeCap.square;
        resolvedStrokeJoin = StrokeJoin.bevel;
        resolvedStrokeWidth *= 1.1;
        break;
      case PenVariant.pencil:
        resolvedOpacity *= 0.75;
        resolvedStrokeWidth *= 0.9;
        break;
      case PenVariant.highlighter:
        resolvedBlendMode = BlendMode.multiply;
        break;
      case PenVariant.highlighterChisel:
        resolvedStrokeCap = StrokeCap.square;
        resolvedStrokeJoin = StrokeJoin.bevel;
        resolvedBlendMode = BlendMode.multiply;
        break;
      case PenVariant.marker:
        resolvedBlendMode = BlendMode.srcOver;
        break;
      case PenVariant.markerChisel:
        resolvedStrokeCap = StrokeCap.square;
        resolvedStrokeJoin = StrokeJoin.bevel;
        resolvedBlendMode = BlendMode.srcOver;
        break;
    }

    final paint = Paint()
      ..color = Color(style.argbColor).withOpacity(resolvedOpacity.clamp(0.0, 1.0))
      ..strokeWidth = resolvedStrokeWidth
      ..strokeCap = resolvedStrokeCap
      ..strokeJoin = resolvedStrokeJoin
      ..style = PaintingStyle.stroke
      ..blendMode = resolvedBlendMode;

    if (points.length == 1) {
      canvas.drawCircle(points.first, paint.strokeWidth / 2, paint);
      return;
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final point = points[i];
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
