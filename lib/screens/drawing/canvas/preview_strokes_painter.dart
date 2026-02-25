import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';
import 'package:safety_inspection_app/screens/drawing/engines/pen_engine.dart';
import 'package:safety_inspection_app/screens/drawing/canvas/centerline_style_utils.dart';

class PreviewStrokesPainter extends CustomPainter {
  const PreviewStrokesPainter({required this.strokes});

  final List<DrawingStroke> strokes;
  static final Set<String> _debugLoggedStrokeIds = <String>{};

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _drawStroke(canvas, size, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant PreviewStrokesPainter oldDelegate) {
    return oldDelegate.strokes != strokes;
  }

  void _drawStroke(Canvas canvas, Size size, DrawingStroke stroke) {
    final points = stroke.pointsNorm;
    if (points.isEmpty) {
      return;
    }

    final style = stroke.style;
    if (kDebugMode && _debugLoggedStrokeIds.add(stroke.id)) {
      debugPrint(
        '[Drawing] PreviewStrokesPainter stroke=${stroke.id} '
        'variant=${style.variant.name}',
      );
    }

    final scaledPoints = points
        .map((point) => Offset(point.dx * size.width, point.dy * size.height))
        .toList(growable: false);
    final erasedMask = stroke.ensureErasedMask();

    for (var i = 0; i < scaledPoints.length; i += 1) {
      if (erasedMask[i] != 0) {
        continue;
      }
      final start = i;
      var end = i;
      while (end + 1 < scaledPoints.length && erasedMask[end + 1] == 0) {
        end += 1;
      }
      final segmentPoints = scaledPoints.sublist(start, end + 1);
      _drawSegment(canvas, stroke, segmentPoints);
      i = end;
    }
  }

  void _drawSegment(Canvas canvas, DrawingStroke stroke, List<Offset> points) {
    final style = stroke.style;
    if (style.kind == StrokeToolKind.pen) {
      _drawPenSegment(canvas, style, stroke.opacity, points);
      return;
    }
    _drawCenterlineSegment(canvas, style, stroke.opacity, points);
  }

  void _drawPenSegment(
    Canvas canvas,
    StrokeStyle style,
    double strokeOpacity,
    List<Offset> points,
  ) {
    final alpha = _resolvedOpacity(style, strokeOpacity);
    if (points.length == 1) {
      canvas.drawCircle(
        points.first,
        math.max(0.5, style.widthPx / 2),
        Paint()
          ..style = PaintingStyle.fill
          ..color = Color(style.argbColor).withValues(alpha: alpha),
      );
      return;
    }
    final input = points
        .map((point) => PointVector(point.dx, point.dy))
        .toList(growable: false);
    final outline = getStroke(input, options: PenEngine.optionsFor(style));
    if (outline.isEmpty) {
      return;
    }
    final path = Path()..moveTo(outline.first.dx, outline.first.dy);
    for (var i = 0; i < outline.length - 1; i += 1) {
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
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.fill
        ..color = Color(style.argbColor).withValues(alpha: alpha),
    );
  }

  void _drawCenterlineSegment(
    Canvas canvas,
    StrokeStyle style,
    double strokeOpacity,
    List<Offset> points,
  ) {
    final resolved = resolveCenterlineStyle(style: style, strokeOpacity: strokeOpacity);
    final paint = resolved.paint;
    if (shouldRenderCenterlineAsDot(points)) {
      canvas.drawCircle(points.first, paint.strokeWidth / 2, paint);
      return;
    }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i += 1) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  double _resolvedOpacity(StrokeStyle style, double strokeOpacity) {
    var alpha = (strokeOpacity * style.opacity).clamp(0.0, 1.0).toDouble();
    if (style.variant == PenVariant.pencil) {
      alpha *= 0.85;
    }
    return alpha.clamp(0.0, 1.0);
  }
}
