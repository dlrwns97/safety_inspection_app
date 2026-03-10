import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'package:safety_inspection_app/models/drawing/eraser_preview.dart';
import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';
import 'package:safety_inspection_app/screens/drawing/drawing_verbose_logger.dart';

/// Manages per-page drawing strokes and cache invalidation signals.
class DrawingCanvasController extends ChangeNotifier {
  /// Stores committed strokes by page.
  final Map<int, List<DrawingStroke>> strokesByPage =
      <int, List<DrawingStroke>>{};

  /// Holds the temporary in-progress stroke.
  final ValueNotifier<DrawingStroke?> liveStroke =
      ValueNotifier<DrawingStroke?>(null);

  /// Holds the current eraser cursor position.
  final ValueNotifier<Offset?> eraserCursor = ValueNotifier<Offset?>(null);

  /// Holds live eraser preview state without mutating committed strokes.
  final ValueNotifier<EraserPreview?> eraserPreview =
      ValueNotifier<EraserPreview?>(null);

  /// Emits the page index whose cache should be rebuilt.
  final ValueNotifier<int?> cacheInvalidatedPage = ValueNotifier<int?>(null);

  /// Monotonic tick that signals cache-layer rebuilds, even on same-page updates.
  final ValueNotifier<int> cacheRebuildTick = ValueNotifier<int>(0);

  final Set<int> _dirtyPages = <int>{};

  /// Snapshot of pages currently waiting for cache rebuild.
  List<int> getDirtyPagesSnapshot() => List<int>.from(_dirtyPages);

  /// Returns committed strokes for [page], creating an empty page bucket if absent.
  List<DrawingStroke> getStrokes(int page) {
    return strokesByPage.putIfAbsent(page, () => <DrawingStroke>[]);
  }

  /// Replaces all committed strokes for [page], typically for restore flows.
  void setStrokes(int page, List<DrawingStroke> strokes) {
    strokesByPage[page] = List<DrawingStroke>.from(strokes);
  }

  /// Restores all committed strokes for [page] using deep copied snapshots.
  void restoreStrokes(int page, List<DrawingStroke> strokes) {
    // Must remain growable because undo/redo and erase commands mutate this list.
    strokesByPage[page] = strokes.map((stroke) => stroke.deepCopy()).toList();
  }

  /// Adds one committed [stroke] to [page].
  void addStroke(int page, DrawingStroke stroke) {
    insertStroke(page, stroke);
  }

  /// Inserts one committed [stroke] to [page] at [index] if provided.
  void insertStroke(int page, DrawingStroke stroke, {int? index}) {
    final strokes = getStrokes(page);
    if (index == null || index < 0 || index > strokes.length) {
      strokes.add(stroke);
      return;
    }
    strokes.insert(index, stroke);
  }

  /// Removes a stroke by [strokeId] in [page].
  bool removeStrokeById(int page, String strokeId) {
    final strokes = getStrokes(page);
    final index = strokes.indexWhere((stroke) => stroke.id == strokeId);
    if (index < 0) {
      return false;
    }

    strokes.removeAt(index);
    return true;
  }

  /// Finds a stroke by [strokeId] within [page].
  DrawingStroke? findStrokeById(int page, String strokeId) {
    final strokes = getStrokes(page);
    for (final stroke in strokes) {
      if (stroke.id == strokeId) {
        return stroke;
      }
    }
    return null;
  }

  /// Updates a committed stroke by id in [page].
  bool updateStroke(int page, DrawingStroke updated) {
    final strokes = getStrokes(page);
    final index = strokes.indexWhere((stroke) => stroke.id == updated.id);
    if (index < 0) {
      return false;
    }

    strokes[index] = updated;
    return true;
  }

  /// Updates erased mask using bool semantics for history commands.
  bool setErasedMaskBool(int page, String strokeId, List<bool> mask) {
    final existing = findStrokeById(page, strokeId);
    if (existing == null) {
      return false;
    }

    final pointCount = existing.pointsNorm.length;
    final intMask = List<int>.generate(pointCount, (index) {
      if (index >= mask.length) {
        return 0;
      }
      return mask[index] ? 1 : 0;
    }, growable: false);
    final updated = DrawingStroke(
      id: existing.id,
      pageNumber: existing.pageNumber,
      style: existing.style,
      pointsNorm: List<Offset>.from(existing.pointsNorm),
      toolType: existing.toolType,
      opacity: existing.opacity,
      isStraightened: existing.isStraightened,
      penVariant: existing.penVariant,
      highlighterVariant: existing.highlighterVariant,
      erasedMaskVersion: (existing.erasedMaskVersion ?? 0) + 1,
      erasedMask: intMask,
      erasedSegments: existing.erasedSegments == null
          ? null
          : List<dynamic>.from(existing.erasedSegments!),
    );
    return updateStroke(page, updated);
  }

  /// Clears all committed strokes for [page].
  void clearPage(int page) {
    getStrokes(page).clear();
  }

  /// Sets or clears the temporary in-progress stroke.
  void setLiveStroke(DrawingStroke? stroke, {bool forceNotify = false}) {
    final didChangeReference = liveStroke.value != stroke;
    liveStroke.value = stroke;
    if (forceNotify && !didChangeReference) {
      liveStroke.notifyListeners();
    }
  }

  /// Sets or clears the eraser cursor position.
  void setEraserCursor(Offset? position) {
    eraserCursor.value = position;
  }

  /// Sets or clears the current eraser preview.
  void setEraserPreview(EraserPreview? preview) {
    eraserPreview.value = preview;
  }

  /// Marks [page] dirty and emits a single cache rebuild signal.
  void invalidateCache(int page, {String reason = 'unknown'}) {
    _dirtyPages.add(page);
    notifyListeners();

    cacheInvalidatedPage.value = page;
    cacheRebuildTick.value++;
    drawingVerboseLog(
      '[Drawing] invalidateCache(page=$page, reason=$reason, '
      'tick=${cacheRebuildTick.value})',
    );
  }

  /// Returns whether cache for [page] is currently marked dirty.
  bool isCacheDirty(int page) => _dirtyPages.contains(page);

  /// Marks cache for [page] as clean.
  void markCacheClean(int page) {
    _dirtyPages.remove(page);
  }

  @override
  void dispose() {
    liveStroke.dispose();
    eraserCursor.dispose();
    eraserPreview.dispose();
    cacheInvalidatedPage.dispose();
    cacheRebuildTick.dispose();
    super.dispose();
  }
}
