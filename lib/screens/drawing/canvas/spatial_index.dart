import 'dart:math' as math;
import 'dart:ui';

import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';

class SpatialIndex {
  SpatialIndex({int gridSize = 32}) : assert(gridSize > 0), _gridSize = gridSize;

  final int _gridSize;
  Size? _pageSize;
  final Map<int, Set<String>> _cellToStrokeIds = <int, Set<String>>{};
  final Map<String, List<int>> _strokeIdToCellKeys = <String, List<int>>{};

  void setPageSize(Size? pageSize) {
    _pageSize = pageSize;
  }

  void updatePageSize(Size? pageSize) {
    _pageSize = pageSize;
  }

  void clear() {
    _cellToStrokeIds.clear();
    _strokeIdToCellKeys.clear();
  }

  void insertStroke(DrawingStroke stroke) {
    final strokeId = stroke.id;
    if (_strokeIdToCellKeys.containsKey(strokeId)) {
      removeStroke(strokeId);
    }

    if (_pageSize == null) {
      return;
    }

    final bounds = _computeStrokeBounds(stroke);
    if (bounds == null) {
      return;
    }

    final startCx = _cellCoord(bounds.left);
    final endCx = _cellCoord(bounds.right);
    final startCy = _cellCoord(bounds.top);
    final endCy = _cellCoord(bounds.bottom);

    final touchedKeys = <int>[];
    final touchedKeySet = <int>{};

    for (var cx = startCx; cx <= endCx; cx += 1) {
      for (var cy = startCy; cy <= endCy; cy += 1) {
        final key = _cellKey(cx, cy);
        if (touchedKeySet.add(key)) {
          touchedKeys.add(key);
        }
        final strokeIds = _cellToStrokeIds.putIfAbsent(key, () => <String>{});
        strokeIds.add(strokeId);
      }
    }

    _strokeIdToCellKeys[strokeId] = touchedKeys;
  }

  void removeStroke(String strokeId) {
    final keys = _strokeIdToCellKeys.remove(strokeId);
    if (keys == null) {
      return;
    }

    for (final key in keys) {
      final strokeIds = _cellToStrokeIds[key];
      if (strokeIds == null) {
        continue;
      }

      strokeIds.remove(strokeId);
      if (strokeIds.isEmpty) {
        _cellToStrokeIds.remove(key);
      }
    }
  }

  void updateStroke(DrawingStroke stroke) {
    removeStroke(stroke.id);
    if (_pageSize == null) {
      return;
    }
    insertStroke(stroke);
  }

  Set<String> queryRect(Rect rect) {
    if (_pageSize == null) {
      return <String>{};
    }

    if (rect.isEmpty) {
      return <String>{};
    }

    final startCx = _cellCoord(math.min(rect.left, rect.right));
    final endCx = _cellCoord(math.max(rect.left, rect.right));
    final startCy = _cellCoord(math.min(rect.top, rect.bottom));
    final endCy = _cellCoord(math.max(rect.top, rect.bottom));

    final result = <String>{};
    for (var cx = startCx; cx <= endCx; cx += 1) {
      for (var cy = startCy; cy <= endCy; cy += 1) {
        final key = _cellKey(cx, cy);
        final strokeIds = _cellToStrokeIds[key];
        if (strokeIds == null || strokeIds.isEmpty) {
          continue;
        }
        result.addAll(strokeIds);
      }
    }

    return <String>{...result};
  }

  Set<String> queryNear(Offset point, double radius) {
    if (_pageSize == null) {
      return <String>{};
    }

    final safeRadius = radius < 0 ? 0.0 : radius;
    final rect = Rect.fromLTRB(
      point.dx - safeRadius,
      point.dy - safeRadius,
      point.dx + safeRadius,
      point.dy + safeRadius,
    );
    return queryRect(rect);
  }

  Rect? _computeStrokeBounds(DrawingStroke stroke) {
    if (stroke.pointsNorm.isEmpty) {
      return null;
    }

    var minX = stroke.pointsNorm.first.dx;
    var maxX = stroke.pointsNorm.first.dx;
    var minY = stroke.pointsNorm.first.dy;
    var maxY = stroke.pointsNorm.first.dy;

    for (var i = 1; i < stroke.pointsNorm.length; i += 1) {
      final point = stroke.pointsNorm[i];
      if (point.dx < minX) minX = point.dx;
      if (point.dx > maxX) maxX = point.dx;
      if (point.dy < minY) minY = point.dy;
      if (point.dy > maxY) maxY = point.dy;
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  int _cellCoord(double value) => (value / _gridSize).floor();

  int _cellKey(int cx, int cy) {
    final a = cx * 73856093;
    final b = cy * 19349663;
    return a ^ b;
  }
}
