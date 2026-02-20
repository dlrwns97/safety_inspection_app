import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';

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

  /// Emits the page index whose cache should be rebuilt.
  final ValueNotifier<int?> cacheInvalidatedPage = ValueNotifier<int?>(null);

  final Set<int> _dirtyPages = <int>{};
  final Map<int, Timer> _cacheDebounceTimers = <int, Timer>{};

  /// Returns committed strokes for [page], creating an empty page bucket if absent.
  List<DrawingStroke> getStrokes(int page) {
    return strokesByPage.putIfAbsent(page, () => <DrawingStroke>[]);
  }

  /// Replaces all committed strokes for [page], typically for restore flows.
  void setStrokes(int page, List<DrawingStroke> strokes) {
    strokesByPage[page] = List<DrawingStroke>.from(strokes);
    notifyListeners();
  }

  /// Adds one committed [stroke] to [page].
  void addStroke(int page, DrawingStroke stroke) {
    getStrokes(page).add(stroke);
    notifyListeners();
  }

  /// Removes a stroke by [strokeId] in [page].
  bool removeStrokeById(int page, String strokeId) {
    final strokes = getStrokes(page);
    final index = strokes.indexWhere((stroke) => stroke.id == strokeId);
    if (index < 0) {
      return false;
    }

    strokes.removeAt(index);
    notifyListeners();
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
    notifyListeners();
    return true;
  }

  /// Clears all committed strokes for [page].
  void clearPage(int page) {
    getStrokes(page).clear();
    notifyListeners();
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

  /// Marks [page] dirty, notifies listeners immediately, and debounces rebuild signal.
  void invalidateCache(int page, {String reason = 'unknown'}) {
    if (kDebugMode) {
      debugPrint('[Drawing] invalidateCache(page=$page, reason=$reason)');
    }
    _dirtyPages.add(page);
    notifyListeners();

    _cacheDebounceTimers[page]?.cancel();
    _cacheDebounceTimers[page] = Timer(const Duration(milliseconds: 100), () {
      cacheInvalidatedPage.value = page;
    });
  }

  /// Returns whether cache for [page] is currently marked dirty.
  bool isCacheDirty(int page) => _dirtyPages.contains(page);

  /// Marks cache for [page] as clean.
  void markCacheClean(int page) {
    _dirtyPages.remove(page);
  }

  @override
  void dispose() {
    for (final timer in _cacheDebounceTimers.values) {
      timer.cancel();
    }
    _cacheDebounceTimers.clear();
    liveStroke.dispose();
    eraserCursor.dispose();
    cacheInvalidatedPage.dispose();
    super.dispose();
  }
}
