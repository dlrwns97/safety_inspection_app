part of 'drawing_screen.dart';

extension _DrawingScreenHistoryCleanupLogic on _DrawingScreenState {
  Future<bool> _confirmClear({
    required String title,

    required String message,
  }) async {
    if (_settingsPopover.isShown) {
      _settingsPopover.hide();
    }

    final confirmed = await showDialog<bool>(
      context: context,

      useRootNavigator: true,

      builder: (context) {
        return AlertDialog(
          title: Text(title),

          content: Text(message),

          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),

              child: const Text('취소'),
            ),

            TextButton(
              onPressed: () => Navigator.of(context).pop(true),

              child: const Text('확인'),
            ),
          ],
        );
      },
    );

    return confirmed == true;
  }

  Future<void> _clearCurrentPageAllStrokes() async {
    final page = _currentPage;

    final strokes = _canvasController.getStrokes(page);

    if (strokes.isEmpty) {
      return;
    }

    if (!await _confirmClear(
      title: '현재 페이지 전체 지우기',

      message: '현재 페이지의 모든 그리기 요소를 삭제합니다. 계속하시겠습니까?',
    )) {
      return;
    }

    final removedStrokeIds = strokes
        .map((stroke) => stroke.id)
        .toList(growable: false);

    _safeSetState(() {
      _historyManager.execute(
        BatchRemoveStrokesCommand(page: page, strokeIds: removedStrokeIds),

        _canvasController,
      );

      _syncStrokesByPageFromControllerPage(page);

      _updateDrawingHistoryAvailabilityState();

      _clearSelectionAndPopup();
    });

    if (kDebugMode) {
      debugPrint(
        '[Eraser] clearAll page=$page removed=${removedStrokeIds.length}',
      );
    }

    _requestPersistDrawing();

    if (_settingsPopover.isShown) {
      _settingsPopover.hide();
    }
  }

  Future<void> _clearCurrentPageHighlighterStrokes() async {
    final page = _currentPage;

    final strokes = _canvasController.getStrokes(page);

    final removedStrokeIds = strokes
        .where((stroke) => stroke.style.kind == StrokeToolKind.highlighter)
        .map((stroke) => stroke.id)
        .toList(growable: false);

    if (removedStrokeIds.isEmpty) {
      return;
    }

    if (!await _confirmClear(
      title: '현재 페이지에서 형광펜만 지우기',

      message: '현재 페이지에서 형광펜으로 그린 요소만 삭제합니다. 계속하시겠습니까?',
    )) {
      return;
    }

    _safeSetState(() {
      _historyManager.execute(
        BatchRemoveStrokesCommand(page: page, strokeIds: removedStrokeIds),

        _canvasController,
      );

      _syncStrokesByPageFromControllerPage(page);

      _updateDrawingHistoryAvailabilityState();

      _clearSelectionAndPopup();
    });

    if (kDebugMode) {
      debugPrint(
        '[Eraser] clearHighlighter page=$page removed=${removedStrokeIds.length}',
      );
    }

    _requestPersistDrawing();

    if (_settingsPopover.isShown) {
      _settingsPopover.hide();
    }
  }

  Future<void> _clearCurrentPagePenStrokes() async {
    final page = _currentPage;

    final strokes = _canvasController.getStrokes(page);

    final removedStrokeIds = strokes
        .where((stroke) => stroke.style.kind == StrokeToolKind.pen)
        .map((stroke) => stroke.id)
        .toList(growable: false);

    if (removedStrokeIds.isEmpty) {
      return;
    }

    if (!await _confirmClear(
      title: '현재 페이지에서 펜만 지우기',

      message: '현재 페이지에서 펜으로 그린 요소만 삭제합니다. 계속하시겠습니까?',
    )) {
      return;
    }

    _safeSetState(() {
      _historyManager.execute(
        BatchRemoveStrokesCommand(page: page, strokeIds: removedStrokeIds),

        _canvasController,
      );

      _syncStrokesByPageFromControllerPage(page);

      _updateDrawingHistoryAvailabilityState();

      _clearSelectionAndPopup();
    });

    if (kDebugMode) {
      debugPrint(
        '[Eraser] clearPen page=$page removed=${removedStrokeIds.length}',
      );
    }

    _requestPersistDrawing();

    if (_settingsPopover.isShown) {
      _settingsPopover.hide();
    }
  }

  void _syncStrokesByPageFromControllerPage(int page) {
    final controllerPageStrokes = _canvasController.strokesByPage[page];

    if (controllerPageStrokes == null || controllerPageStrokes.isEmpty) {
      _strokesByPage.remove(page);

      _strokeSpatialIndexByPage.remove(page);

      _strokeSpatialIndexPageSizeByPage.remove(page);

      _strokeSpatialIndexDirtyPages.remove(page);

      return;
    }

    _strokesByPage[page] = List<DrawingStroke>.from(controllerPageStrokes);

    _strokeSpatialIndexDirtyPages.add(page);
  }

  void _syncAllStrokesByPageFromController() {
    _strokesByPage
      ..clear()
      ..addAll(
        _canvasController.strokesByPage.map(
          (page, strokes) => MapEntry(page, List<DrawingStroke>.from(strokes)),
        ),
      );

    _strokeSpatialIndexByPage.clear();

    _strokeSpatialIndexPageSizeByPage.clear();

    _strokeSpatialIndexDirtyPages
      ..clear()
      ..addAll(_strokesByPage.keys);
  }

  ({Offset localPosition, Size size})? _resolveTapPosition(
    BuildContext? tapContext,

    Offset globalPosition,
  ) {
    if (tapContext == null) {
      return null;
    }

    final renderObject = tapContext.findRenderObject();

    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return null;
    }

    final localPosition = renderObject.globalToLocal(globalPosition);

    final clampedPosition = Offset(
      localPosition.dx.clamp(0.0, renderObject.size.width),

      localPosition.dy.clamp(0.0, renderObject.size.height),
    );

    return (localPosition: clampedPosition, size: renderObject.size);
  }
}
