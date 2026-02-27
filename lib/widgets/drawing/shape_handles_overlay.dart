import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';
import 'package:safety_inspection_app/screens/drawing/engines/shape_engine.dart';
import 'package:safety_inspection_app/screens/drawing/engines/shape_manipulator.dart';

class ShapeHandlesOverlay extends StatelessWidget {
  const ShapeHandlesOverlay({
    super.key,
    required this.manipulator,
    required this.canvasSize,
    this.previewType,
    this.previewStroke,
    this.previewFillArgb,
    this.previewPointsNorm,
    this.createStartNorm,
    this.createCurrentNorm,
    this.showBounds = true,
  });

  final ShapeManipulator manipulator;
  final Size canvasSize;
  final ShapeType? previewType;
  final StrokeStyle? previewStroke;
  final int? previewFillArgb;
  final List<Offset>? previewPointsNorm;
  final Offset? createStartNorm;
  final Offset? createCurrentNorm;
  final bool showBounds;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ShapeHandlesPainter(
        manipulator: manipulator,
        previewType: previewType,
        previewStroke: previewStroke,
        previewFillArgb: previewFillArgb,
        previewPointsNorm: previewPointsNorm,
        createStartNorm: createStartNorm,
        createCurrentNorm: createCurrentNorm,
        showBounds: showBounds,
      ),
      child: SizedBox(width: canvasSize.width, height: canvasSize.height),
    );
  }
}

class _ShapeHandlesPainter extends CustomPainter {
  _ShapeHandlesPainter({
    required this.manipulator,
    required this.previewType,
    required this.previewStroke,
    required this.previewFillArgb,
    required this.previewPointsNorm,
    required this.createStartNorm,
    required this.createCurrentNorm,
    required this.showBounds,
  });

  final ShapeManipulator manipulator;
  final ShapeType? previewType;
  final StrokeStyle? previewStroke;
  final int? previewFillArgb;
  final List<Offset>? previewPointsNorm;
  final Offset? createStartNorm;
  final Offset? createCurrentNorm;
  final bool showBounds;

  @override
  void paint(Canvas canvas, Size size) {
    final handlePositions = manipulator.handlePositions();
    final isCreatingPreview = previewType != null && previewStroke != null;
    if (isCreatingPreview) {
      _paintShapePreview(canvas, size, previewType!, previewStroke!);
    }

    final boundsWidthPx = manipulator.boundsNorm.width * size.width;
    final boundsHeightPx = manipulator.boundsNorm.height * size.height;
    final shapeMinSidePx = math.max(
      1.0,
      math.min(boundsWidthPx.abs(), boundsHeightPx.abs()),
    );
    final handleRadius = (shapeMinSidePx * 0.09).clamp(2.0, 5.0).toDouble();
    final rotateHandleRadius = (handleRadius * 1.8).clamp(4.0, 10.0).toDouble();
    final outlineWidth = (handleRadius * 0.3).clamp(1.0, 1.8).toDouble();

    final paint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = outlineWidth
      ..style = PaintingStyle.stroke;
    final fill = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.fill;
    final highlight = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    if (showBounds) {
      final path = Path()
        ..addRect(
          Rect.fromLTWH(
            manipulator.boundsNorm.left * size.width,
            manipulator.boundsNorm.top * size.height,
            manipulator.boundsNorm.width * size.width,
            manipulator.boundsNorm.height * size.height,
          ),
        );
      canvas.drawPath(path, paint);
    }

    Offset? rotateHandle;
    for (final entry in handlePositions) {
      if (entry.$1 != ShapeHandle.rotate) {
        final point = _toCanvas(entry.$2, size);
        canvas.drawCircle(point, handleRadius, highlight);
        canvas.drawCircle(point, handleRadius, fill);
        canvas.drawCircle(point, handleRadius, paint);
        continue;
      }
      if (entry.$1 == ShapeHandle.rotate) {
        rotateHandle = _toCanvas(entry.$2, size);
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
      canvas.drawCircle(rotateHandle, rotateHandleRadius, highlight);
      canvas.drawCircle(rotateHandle, rotateHandleRadius, fill);
      canvas.drawCircle(rotateHandle, rotateHandleRadius, paint);
    }
  }

  void _paintShapePreview(
    Canvas canvas,
    Size size,
    ShapeType type,
    StrokeStyle style,
  ) {
    final bounds = manipulator.boundsNorm;
    final startNorm = bounds.topLeft;
    final endNorm = bounds.bottomRight;
    final points = previewPointsNorm == null || previewPointsNorm!.isEmpty
        ? ShapeEngine.buildPointsNorm(type, startNorm, endNorm)
        : List<Offset>.from(previewPointsNorm!);
    if (points.isEmpty) {
      return;
    }

    final strokeColor = Color(style.argbColor).withValues(alpha: style.opacity);
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.widthPx
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final centerNorm = bounds.center;
    final centerPx = Offset(
      centerNorm.dx * size.width,
      centerNorm.dy * size.height,
    );
    Offset toCanvas(Offset norm) {
      final pointPx = Offset(norm.dx * size.width, norm.dy * size.height);
      return _rotatePoint(pointPx, centerPx, manipulator.rotationRad);
    }

    final firstPoint = toCanvas(points.first);
    final path = Path()..moveTo(firstPoint.dx, firstPoint.dy);
    for (var i = 1; i < points.length; i += 1) {
      final point = toCanvas(points[i]);
      path.lineTo(point.dx, point.dy);
    }

    if (type != ShapeType.hShape) {
      if (points.length >= 3) {
        path.close();
      }
      if (previewFillArgb != null) {
        final fillPaint = Paint()
          ..color = Color(previewFillArgb!).withValues(alpha: style.opacity)
          ..style = PaintingStyle.fill;
        canvas.drawPath(path, fillPaint);
      }
    }
    canvas.drawPath(path, strokePaint);
  }

  Offset _rotatePoint(Offset point, Offset center, double angleRad) {
    if (angleRad == 0.0) {
      return point;
    }
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;
    final cosA = math.cos(angleRad);
    final sinA = math.sin(angleRad);
    return Offset(
      center.dx + dx * cosA - dy * sinA,
      center.dy + dx * sinA + dy * cosA,
    );
  }

  Offset _toCanvas(Offset norm, Size size) {
    return Offset(norm.dx * size.width, norm.dy * size.height);
  }

  @override
  bool shouldRepaint(_ShapeHandlesPainter oldDelegate) {
    return oldDelegate.manipulator.boundsNorm != manipulator.boundsNorm ||
        oldDelegate.manipulator.rotationRad != manipulator.rotationRad ||
        oldDelegate.previewType != previewType ||
        oldDelegate.previewStroke?.argbColor != previewStroke?.argbColor ||
        oldDelegate.previewStroke?.widthPx != previewStroke?.widthPx ||
        oldDelegate.previewStroke?.opacity != previewStroke?.opacity ||
        oldDelegate.previewFillArgb != previewFillArgb ||
        oldDelegate.previewPointsNorm != previewPointsNorm ||
        oldDelegate.createStartNorm != createStartNorm ||
        oldDelegate.createCurrentNorm != createCurrentNorm ||
        oldDelegate.showBounds != showBounds;
  }
}
