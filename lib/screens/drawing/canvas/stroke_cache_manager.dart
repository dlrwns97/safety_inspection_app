import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';
import 'package:safety_inspection_app/screens/drawing/engines/pen_engine.dart';
import 'package:safety_inspection_app/screens/drawing/canvas/centerline_style_utils.dart';
import 'package:safety_inspection_app/screens/drawing/drawing_types.dart';

/// Builds and stores a per-page raster cache image for committed drawing strokes.
class StrokeCacheManager extends ChangeNotifier {
  final Map<int, ui.Image> _cacheByPage = <int, ui.Image>{};
  final Set<String> _debugLoggedStrokeIds = <String>{};
  final Set<int> _buildingPages = <int>{};
  final Map<int, int> _buildTokens = <int, int>{};

  /// Returns the cached image for [page], or `null` when no cache exists.
  ui.Image? getCachedImage(int page) => _cacheByPage[page];

  /// Returns whether [page] currently has a built cache image.
  bool hasCache(int page) => _cacheByPage.containsKey(page);

  /// Returns whether [page] is currently rebuilding its cache image.
  bool isBuilding(int page) => _buildingPages.contains(page);

  /// Rebuilds the raster cache image for [page] using committed [strokes].
  ///
  /// The [strokes] are assumed to be in logical normalized coordinates
  /// (`pointsNorm` in 0..1) and are rendered against [size].
  Future<void> rebuildCache({
    required int page,
    required Size size,
    required List<DrawingStroke> strokes,
    required double devicePixelRatio,
  }) async {
    final token = (_buildTokens[page] ?? 0) + 1;
    _buildTokens[page] = token;

    _buildingPages.add(page);
    notifyListeners();

    try {
      if (size.width <= 0 || size.height <= 0 || devicePixelRatio <= 0) {
        // Keep the last stable cache image instead of clearing it when the
        // viewport reports a transient invalid size.
        return;
      }

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.scale(devicePixelRatio, devicePixelRatio);

      for (final stroke in strokes) {
        if (stroke.pageNumber != page) {
          continue;
        }
        _drawStroke(canvas, size, stroke);
      }

      final picture = recorder.endRecording();
      final image = await picture.toImage(
        math.max(1, (size.width * devicePixelRatio).round()),
        math.max(1, (size.height * devicePixelRatio).round()),
      );
      picture.dispose();

      if (_buildTokens[page] != token) {
        image.dispose();
        return;
      }

      final previous = _cacheByPage[page];
      _cacheByPage[page] = image;
      previous?.dispose();
    } catch (error) {
      debugPrint(
        'StrokeCacheManager: cache rebuild failed for page $page: $error',
      );
    } finally {
      _buildingPages.remove(page);
      notifyListeners();
    }
  }

  /// Marks any in-flight build for [page] as stale while keeping the last
  /// stable cache image until a replacement is ready.
  void invalidate(int page) {
    _buildTokens[page] = (_buildTokens[page] ?? 0) + 1;
    _buildingPages.remove(page);
    notifyListeners();
  }

  /// Disposes and removes all cached page images.
  void clearAll() {
    for (final image in _cacheByPage.values) {
      image.dispose();
    }
    _cacheByPage.clear();
    _buildingPages.clear();
    _buildTokens.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    clearAll();
    super.dispose();
  }

  void _drawStroke(Canvas canvas, Size pageSize, DrawingStroke stroke) {
    final pointsNorm = stroke.pointsNorm;
    if (pointsNorm.isEmpty) {
      return;
    }

    final points = pointsNorm
        .map(
          (point) =>
              Offset(point.dx * pageSize.width, point.dy * pageSize.height),
        )
        .toList(growable: false);
    final erasedMask = stroke.ensureErasedMask();

    final style = stroke.style;
    if (kDebugMode && _debugLoggedStrokeIds.add(stroke.id)) {
      debugPrint(
        '[Drawing] StrokeCacheManager draw stroke=${stroke.id} '
        'variant=${style.variant.name}',
      );
    }

    _drawShapeFillIfNeeded(
      canvas: canvas,
      stroke: stroke,
      points: points,
      erasedMask: erasedMask,
    );

    for (var i = 0; i < points.length; i += 1) {
      if (erasedMask[i] != 0) {
        continue;
      }
      final start = i;
      var end = i;
      while (end + 1 < points.length && erasedMask[end + 1] == 0) {
        end += 1;
      }
      final segmentPoints = points.sublist(start, end + 1);
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
    _drawCenterlineSegment(canvas, stroke, style, stroke.opacity, points);
  }

  void _drawShapeFillIfNeeded({
    required Canvas canvas,
    required DrawingStroke stroke,
    required List<Offset> points,
    required List<int> erasedMask,
  }) {
    if (stroke.toolType != DrawingTool.shape || stroke.shapeFillArgb == null) {
      return;
    }
    if (erasedMask.any((value) => value != 0)) {
      return;
    }
    if (points.length < 3) {
      return;
    }
    final shapeType = stroke.shapeType ?? '';
    if (shapeType != 'rectangle' &&
        shapeType != 'circle' &&
        shapeType != 'triangle') {
      return;
    }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i += 1) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.fill
        ..color = Color(
          stroke.shapeFillArgb!,
        ).withValues(alpha: stroke.style.opacity.clamp(0.0, 1.0))
        ..blendMode = BlendMode.srcOver,
    );
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
    DrawingStroke stroke,
    StrokeStyle style,
    double strokeOpacity,
    List<Offset> points,
  ) {
    final resolved = resolveCenterlineStyle(
      style: style,
      strokeOpacity: strokeOpacity,
    );
    final paint = resolved.paint;
    final isShapeArrow =
        stroke.toolType == DrawingTool.shape && stroke.shapeType == 'arrow';
    if (isShapeArrow) {
      paint
        ..strokeCap = StrokeCap.butt
        ..strokeJoin = StrokeJoin.miter
        ..strokeMiterLimit = 6.0;
    }
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
