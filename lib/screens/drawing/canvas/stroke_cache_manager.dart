import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';

/// Builds and stores a per-page raster cache image for committed drawing strokes.
class StrokeCacheManager extends ChangeNotifier {
  final Map<int, ui.Image> _cacheByPage = <int, ui.Image>{};
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
      debugPrint('StrokeCacheManager: cache rebuild failed for page $page: $error');
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
          (point) => Offset(
            point.dx * pageSize.width,
            point.dy * pageSize.height,
          ),
        )
        .toList(growable: false);
    final erasedMask = stroke.ensureErasedMask();

    final style = stroke.style;
    final alpha = (stroke.opacity * style.opacity).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = Color(style.argbColor).withValues(alpha: alpha)
      ..strokeWidth = style.widthPx
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..blendMode =
          style.kind == StrokeToolKind.highlighter
              ? BlendMode.multiply
              : BlendMode.srcOver;

    for (var i = 0; i < points.length; i += 1) {
      if (erasedMask[i] != 0) {
        continue;
      }
      final start = i;
      var end = i;
      while (end + 1 < points.length && erasedMask[end + 1] == 0) {
        end += 1;
      }
      if (start == end) {
        canvas.drawCircle(points[start], math.max(0.5, style.widthPx / 2), paint);
      } else {
        final path = Path()..moveTo(points[start].dx, points[start].dy);
        for (var j = start + 1; j <= end; j += 1) {
          path.lineTo(points[j].dx, points[j].dy);
        }
        canvas.drawPath(path, paint);
      }
      i = end;
    }
  }
}
