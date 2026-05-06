part of 'drawing_screen.dart';

extension _DrawingScreenMoveActionsLogic on _DrawingScreenState {
  void _enterMoveMode() {
    final selectedDefect = _selectedDefect;

    final selectedEquipment = _selectedEquipment;

    if (selectedDefect == null && selectedEquipment == null) {
      return;
    }

    _safeSetState(() {
      _isMoveMode = true;

      _moveTargetDefectId = selectedDefect?.id;

      _moveTargetEquipmentId = selectedEquipment?.id;

      if (selectedDefect != null) {
        _moveOriginNormalizedX = selectedDefect.normalizedX;

        _moveOriginNormalizedY = selectedDefect.normalizedY;
      } else if (selectedEquipment != null) {
        _moveOriginNormalizedX = selectedEquipment.normalizedX;

        _moveOriginNormalizedY = selectedEquipment.normalizedY;
      } else {
        _moveOriginNormalizedX = null;

        _moveOriginNormalizedY = null;
      }

      _movePreviewNormalizedX = _moveOriginNormalizedX;

      _movePreviewNormalizedY = _moveOriginNormalizedY;

      _moveLastGlobalPosition = null;
    });
  }

  void _exitMoveMode() {
    if (!_isMoveMode) {
      return;
    }

    _safeSetState(() {
      _isMoveMode = false;

      _moveTargetDefectId = null;

      _moveTargetEquipmentId = null;

      _moveOriginNormalizedX = null;

      _moveOriginNormalizedY = null;

      _movePreviewNormalizedX = null;

      _movePreviewNormalizedY = null;
    });
  }

  void _cancelMoveMode() {
    if (!_isMoveMode) {
      return;
    }

    final originX = _moveOriginNormalizedX;

    final originY = _moveOriginNormalizedY;

    _safeSetState(() {
      if (originX != null && originY != null) {
        _movePreviewNormalizedX = originX;

        _movePreviewNormalizedY = originY;
      }
    });

    _exitMoveMode();
  }

  bool get _hasPendingMove {
    final originX = _moveOriginNormalizedX;

    final originY = _moveOriginNormalizedY;

    final previewX = _movePreviewNormalizedX;

    final previewY = _movePreviewNormalizedY;

    if (originX == null ||
        originY == null ||
        previewX == null ||
        previewY == null) {
      return false;
    }

    return originX != previewX || originY != previewY;
  }

  bool _isMoveTargetItem(Object item) {
    if (!_isMoveMode) {
      return false;
    }

    final targetDefectId = _moveTargetDefectId;

    if (item is Defect && targetDefectId != null) {
      return item.id == targetDefectId;
    }

    final targetEquipmentId = _moveTargetEquipmentId;

    if (item is EquipmentMarker && targetEquipmentId != null) {
      return item.id == targetEquipmentId;
    }

    return false;
  }

  bool get _hasMoveTarget =>
      _moveTargetDefectId != null || _moveTargetEquipmentId != null;

  int? get _moveTargetPageIndex {
    final targetDefect = _moveTargetDefect;

    if (targetDefect != null) {
      return targetDefect.pageIndex;
    }

    final targetEquipment = _moveTargetEquipment;

    if (targetEquipment != null) {
      return targetEquipment.pageIndex;
    }

    return null;
  }

  bool _selectionMatchesMoveTarget(Defect? defect, EquipmentMarker? equipment) {
    final targetDefectId = _moveTargetDefectId;

    if (targetDefectId != null) {
      return defect != null && defect.id == targetDefectId;
    }

    final targetEquipmentId = _moveTargetEquipmentId;

    if (targetEquipmentId != null) {
      return equipment != null && equipment.id == targetEquipmentId;
    }

    return false;
  }

  void _handleMoveModeSelectionChange(
    Defect? defect,

    EquipmentMarker? equipment,
  ) {
    if (!_isMoveMode) {
      return;
    }

    if (!_selectionMatchesMoveTarget(defect, equipment)) {
      _cancelMoveMode();
    }
  }

  void _handleMovePanStart(Object item) {
    if (!_isMoveMode) {
      return;
    }

    if (_moveOriginNormalizedX != null && _moveOriginNormalizedY != null) {
      return;
    }

    if (item is Defect) {
      _moveOriginNormalizedX = item.normalizedX;

      _moveOriginNormalizedY = item.normalizedY;
    } else if (item is EquipmentMarker) {
      _moveOriginNormalizedX = item.normalizedX;

      _moveOriginNormalizedY = item.normalizedY;
    } else {
      return;
    }

    _safeSetState(() {
      _movePreviewNormalizedX = _moveOriginNormalizedX;

      _movePreviewNormalizedY = _moveOriginNormalizedY;
    });
  }

  void _handleMovePanUpdate(DragUpdateDetails details, Size pageSize) {
    if (!_isMoveMode) {
      return;
    }

    final currentX = _movePreviewNormalizedX;

    final currentY = _movePreviewNormalizedY;

    if (currentX == null || currentY == null) {
      return;
    }

    final nextX = (currentX + details.delta.dx / pageSize.width).clamp(
      0.0,

      1.0,
    );

    final nextY = (currentY + details.delta.dy / pageSize.height).clamp(
      0.0,

      1.0,
    );

    _safeSetState(() {
      _movePreviewNormalizedX = nextX.toDouble();

      _movePreviewNormalizedY = nextY.toDouble();
    });
  }

  void _handleMovePanEnd() {
    if (!_isMoveMode) {
      return;
    }

    _moveLastGlobalPosition = null;
  }

  void _handleMovePanStartGlobal() {
    if (!_isMoveMode || !_hasMoveTarget) {
      return;
    }

    if (_moveOriginNormalizedX != null && _moveOriginNormalizedY != null) {
      return;
    }

    final targetDefect = _moveTargetDefect;

    final targetEquipment = _moveTargetEquipment;

    if (targetDefect != null) {
      _moveOriginNormalizedX = targetDefect.normalizedX;

      _moveOriginNormalizedY = targetDefect.normalizedY;
    } else if (targetEquipment != null) {
      _moveOriginNormalizedX = targetEquipment.normalizedX;

      _moveOriginNormalizedY = targetEquipment.normalizedY;
    }

    _safeSetState(() {
      _movePreviewNormalizedX = _moveOriginNormalizedX;

      _movePreviewNormalizedY = _moveOriginNormalizedY;
    });
  }

  void _handleMoveOverlayPanStart(DragStartDetails details) {
    if (!_isMoveMode || !_hasMoveTarget) {
      return;
    }

    _moveLastGlobalPosition = details.globalPosition;

    _handleMovePanStartGlobal();
  }

  void _handleMoveCanvasOverlayPanUpdate(DragUpdateDetails details) {
    _updateMovePreviewFromGlobalDelta(
      globalPosition: details.globalPosition,

      pageIndex: _currentPage,

      tapContext: _canvasTapRegionKey.currentContext,

      transformToScene: true,
    );
  }

  void _handleMovePdfOverlayPanUpdate(DragUpdateDetails details) {
    final pageIndex = _currentPage;

    final tapContext = _pdfTapRegionKeyForPage(pageIndex).currentContext;

    final renderBox = tapContext?.findRenderObject() as RenderBox?;

    final overlaySize = (renderBox != null && renderBox.hasSize)
        ? renderBox.size
        : _pdfPageSizes[pageIndex];

    final destRect = overlaySize == null
        ? null
        : _pdfDestRectForPageOverlay(
            pageIndex: pageIndex,

            overlaySize: overlaySize,
          );

    _updateMovePreviewFromGlobalDelta(
      globalPosition: details.globalPosition,

      pageIndex: pageIndex,

      tapContext: tapContext,

      overlaySize: overlaySize,

      destRect: destRect,
    );
  }

  Rect _pdfDestRectForPageOverlay({
    required int pageIndex,

    required Size overlaySize,
  }) {
    final pageSize = _pdfPageSizes[pageIndex];

    if (pageSize == null || pageSize.isEmpty || overlaySize.isEmpty) {
      return Offset.zero & overlaySize;
    }

    final fitted = applyBoxFit(BoxFit.contain, pageSize, overlaySize);

    final destSize = fitted.destination;

    final dx = (overlaySize.width - destSize.width) / 2;

    final dy = (overlaySize.height - destSize.height) / 2;

    return Offset(dx, dy) & destSize;
  }

  void _handleMoveCanvasPanUpdate(DragUpdateDetails details) {
    _updateMovePreviewFromGlobalPosition(
      globalPosition: details.globalPosition,

      pageIndex: _currentPage,

      tapContext: _canvasTapRegionKey.currentContext,

      transformToScene: true,
    );
  }

  void _handleMovePdfPanUpdate(
    DragUpdateDetails details,

    Size overlaySize,

    int pageIndex,

    BuildContext tapContext, {

    required Rect destRect,
  }) {
    final tapRegionContext = _pdfTapRegionKeyForPage(pageIndex).currentContext;

    _updateMovePreviewFromGlobalPosition(
      globalPosition: details.globalPosition,

      pageIndex: pageIndex,

      tapContext: tapRegionContext ?? tapContext,

      overlaySize: overlaySize,

      destRect: destRect,
    );
  }

  void _updateMovePreviewFromGlobalPosition({
    required Offset globalPosition,

    required int pageIndex,

    required BuildContext? tapContext,

    bool transformToScene = false,

    Size? overlaySize,

    Rect? destRect,
  }) {
    if (!_isMoveMode || !_hasMoveTarget) {
      return;
    }

    final targetPageIndex = _moveTargetPageIndex;

    if (targetPageIndex == null || targetPageIndex != pageIndex) {
      return;
    }

    final tapInfo = _resolveTapPosition(tapContext, globalPosition);

    if (tapInfo == null) {
      return;
    }

    final localPosition = tapInfo.localPosition;

    double nextX;

    double nextY;

    if (transformToScene) {
      final scenePoint = _transformationController.toScene(localPosition);

      final normalized = toNormalized(scenePoint, drawingCanvasSize);

      nextX = normalized.dx;

      nextY = normalized.dy;
    } else {
      final resolvedOverlaySize = overlaySize ?? tapInfo.size;

      final resolvedDestRect = destRect == null || destRect.isEmpty
          ? Offset.zero & resolvedOverlaySize
          : destRect;

      if (!resolvedDestRect.contains(localPosition)) {
        return;
      }

      final destLocal = localPosition - resolvedDestRect.topLeft;

      final imageSize = _pdfPageSizes[pageIndex] ?? resolvedDestRect.size;

      final imageLocal = _mapPdfViewportPointToPageLocal(
        viewportLocal: destLocal,

        pageIndex: pageIndex,

        viewportSize: resolvedDestRect.size,

        childSize: imageSize,
      );

      if (imageLocal == null) {
        return;
      }

      final normalized = toNormalized(imageLocal, imageSize);

      nextX = normalized.dx;

      nextY = normalized.dy;
    }

    _safeSetState(() {
      _movePreviewNormalizedX = nextX.toDouble();

      _movePreviewNormalizedY = nextY.toDouble();
    });
  }

  void _updateMovePreviewFromGlobalDelta({
    required Offset globalPosition,

    required int pageIndex,

    required BuildContext? tapContext,

    bool transformToScene = false,

    Size? overlaySize,

    Rect? destRect,
  }) {
    if (!_isMoveMode || !_hasMoveTarget) {
      return;
    }

    final targetPageIndex = _moveTargetPageIndex;

    if (targetPageIndex == null || targetPageIndex != pageIndex) {
      return;
    }

    final lastGlobalPosition = _moveLastGlobalPosition;

    if (lastGlobalPosition == null) {
      _moveLastGlobalPosition = globalPosition;

      return;
    }

    final prevTapInfo = _resolveTapPosition(tapContext, lastGlobalPosition);

    final nextTapInfo = _resolveTapPosition(tapContext, globalPosition);

    _moveLastGlobalPosition = globalPosition;

    if (prevTapInfo == null || nextTapInfo == null) {
      return;
    }

    final currentX = _movePreviewNormalizedX;

    final currentY = _movePreviewNormalizedY;

    if (currentX == null || currentY == null) {
      return;
    }

    Offset deltaNormalized;

    if (transformToScene) {
      final prevScene = _transformationController.toScene(
        prevTapInfo.localPosition,
      );

      final nextScene = _transformationController.toScene(
        nextTapInfo.localPosition,
      );

      final deltaScene = nextScene - prevScene;

      deltaNormalized = Offset(
        deltaScene.dx / drawingCanvasSize.width,

        deltaScene.dy / drawingCanvasSize.height,
      );
    } else {
      final resolvedOverlaySize = overlaySize ?? prevTapInfo.size;

      final resolvedDestRect = destRect == null || destRect.isEmpty
          ? Offset.zero & resolvedOverlaySize
          : destRect;

      if (resolvedDestRect.isEmpty) {
        return;
      }

      final clampedPrev = _clampOffsetToRect(
        prevTapInfo.localPosition,

        resolvedDestRect,
      );

      final clampedNext = _clampOffsetToRect(
        nextTapInfo.localPosition,

        resolvedDestRect,
      );

      final imageSize = _pdfPageSizes[pageIndex] ?? resolvedDestRect.size;

      final imagePrev = _mapPdfViewportPointToPageLocal(
        viewportLocal: clampedPrev - resolvedDestRect.topLeft,

        pageIndex: pageIndex,

        viewportSize: resolvedDestRect.size,

        childSize: imageSize,
      );

      final imageNext = _mapPdfViewportPointToPageLocal(
        viewportLocal: clampedNext - resolvedDestRect.topLeft,

        pageIndex: pageIndex,

        viewportSize: resolvedDestRect.size,

        childSize: imageSize,
      );

      if (imagePrev == null || imageNext == null) {
        return;
      }

      final deltaImage = imageNext - imagePrev;

      deltaNormalized = Offset(
        deltaImage.dx / imageSize.width,

        deltaImage.dy / imageSize.height,
      );

      final currentScale =
          (_photoControllerForPage(pageIndex).value.scale ?? 1.0)
              .clamp(1.0, 4.0)
              .toDouble();

      deltaNormalized = Offset(
        deltaNormalized.dx * currentScale,

        deltaNormalized.dy * currentScale,
      );
    }

    final nextX = (currentX + deltaNormalized.dx).clamp(0.0, 1.0);

    final nextY = (currentY + deltaNormalized.dy).clamp(0.0, 1.0);

    _safeSetState(() {
      _movePreviewNormalizedX = nextX.toDouble();

      _movePreviewNormalizedY = nextY.toDouble();
    });
  }

  Offset _clampOffsetToRect(Offset offset, Rect rect) {
    return Offset(
      offset.dx.clamp(rect.left, rect.right),

      offset.dy.clamp(rect.top, rect.bottom),
    );
  }

  void _handleMovePanCancel() {
    if (!_isMoveMode) {
      return;
    }

    _moveLastGlobalPosition = null;

    final originX = _moveOriginNormalizedX;

    final originY = _moveOriginNormalizedY;

    if (originX == null || originY == null) {
      return;
    }

    _safeSetState(() {
      _movePreviewNormalizedX = originX;

      _movePreviewNormalizedY = originY;
    });
  }

  Size? _pageSizeForMoveTarget(int pageIndex) {
    if (_site.drawingType == DrawingType.pdf) {
      return _pdfPageSizes[pageIndex];
    }

    return drawingCanvasSize;
  }

  Future<void> _commitMovePreview() async {
    if (!_isMoveMode) {
      return;
    }

    final previewX = _movePreviewNormalizedX;

    final previewY = _movePreviewNormalizedY;

    if (previewX == null || previewY == null) {
      return;
    }

    final targetDefect = _moveTargetDefect;

    if (targetDefect != null) {
      final updatedDefect = Defect(
        id: targetDefect.id,

        label: targetDefect.label,

        pageIndex: targetDefect.pageIndex,

        category: targetDefect.category,

        normalizedX: previewX,

        normalizedY: previewY,

        details: targetDefect.details,
      );

      final updatedDefects = _site.defects
          .map(
            (defect) => defect.id == updatedDefect.id ? updatedDefect : defect,
          )
          .toList();

      final updatedSite = _site.copyWith(defects: updatedDefects);

      final pageSize = _pageSizeForMoveTarget(updatedDefect.pageIndex);

      await _applyUpdatedSite(
        updatedSite,

        onStateUpdated: () {
          _selectedDefectId = updatedDefect.id;

          _selectedEquipmentId = null;

          _selectedMarkerScenePosition = pageSize == null
              ? null
              : Offset(
                  updatedDefect.normalizedX * pageSize.width,

                  updatedDefect.normalizedY * pageSize.height,
                );
        },
      );

      _exitMoveMode();

      return;
    }

    final targetEquipment = _moveTargetEquipment;

    if (targetEquipment != null) {
      final updatedMarker = targetEquipment.copyWith(
        normalizedX: previewX,

        normalizedY: previewY,
      );

      final updatedMarkers = _site.equipmentMarkers
          .map(
            (marker) => marker.id == updatedMarker.id ? updatedMarker : marker,
          )
          .toList();

      final updatedSite = _site.copyWith(equipmentMarkers: updatedMarkers);

      final pageSize = _pageSizeForMoveTarget(updatedMarker.pageIndex);

      await _applyUpdatedSite(
        updatedSite,

        onStateUpdated: () {
          _selectedDefectId = null;

          _selectedEquipmentId = updatedMarker.id;

          _selectedMarkerScenePosition = pageSize == null
              ? null
              : Offset(
                  updatedMarker.normalizedX * pageSize.width,

                  updatedMarker.normalizedY * pageSize.height,
                );
        },
      );

      _exitMoveMode();
    }
  }

  void _returnToToolSelection() {
    _safeSetState(() {
      _mode = _controller.returnToToolSelection();
    });
  }

  void _handleAddToolAction() {
    if (_controller.shouldShowDefectCategoryPicker(_mode)) {
      _showDefectCategoryPicker();

      return;
    }

    if (_mode == DrawMode.equipment) {
      _showEquipmentCategoryPicker();
    }
  }

  Future<void> _showDefectCategoryPicker() async {
    final selectedCategory = await showDefectCategoryPickerSheet(
      context: context,

      selectedCategories: _defectTabs,
    );

    if (selectedCategory == null || !mounted) {
      return;
    }

    final updated = _controller.addDefectCategory(
      tabs: _defectTabs,

      selectedCategory: selectedCategory,
    );

    await _applyUpdatedSite(
      _site.copyWith(
        visibleDefectCategoryNames: updated.tabs
            .map((tab) => tab.name)
            .toList(),
      ),

      onStateUpdated: () {
        _defectTabs
          ..clear()
          ..addAll(updated.tabs);

        _activeCategory = updated.activeCategory;
      },
    );
  }

  Future<void> _showEquipmentCategoryPicker() async {
    if (kEquipmentCategoryOrder.isEmpty) {
      return;
    }

    final selectedCategory = await showEquipmentCategoryPickerSheet(
      context: context,

      selectedCategories: _visibleEquipmentCategories,
    );

    if (selectedCategory == null || !mounted) {
      return;
    }

    final updatedCategories = Set<EquipmentCategory>.from(
      _visibleEquipmentCategories,
    )..add(selectedCategory);

    final orderedVisible = _orderedVisibleEquipmentCategories(
      updatedCategories,
    );

    await _applyUpdatedSite(
      _site.copyWith(
        visibleEquipmentCategoryNames: orderedVisible
            .map((category) => category.name)
            .toList(),
      ),

      onStateUpdated: () {
        _visibleEquipmentCategories
          ..clear()
          ..addAll(updatedCategories);

        _activeEquipmentCategory = selectedCategory;
      },
    );
  }

  Future<void> _updateVisibleEquipmentCategories(
    Set<EquipmentCategory> visibleCategories,
  ) async {
    final orderedVisible = _orderedVisibleEquipmentCategories(
      visibleCategories,
    );

    final nextActive = _nextActiveEquipmentCategory(
      _activeEquipmentCategory,

      visibleCategories,
    );

    await _applyUpdatedSite(
      _site.copyWith(
        visibleEquipmentCategoryNames: orderedVisible
            .map((category) => category.name)
            .toList(),
      ),

      onStateUpdated: () {
        _visibleEquipmentCategories
          ..clear()
          ..addAll(visibleCategories);

        _activeEquipmentCategory = nextActive;
      },
    );
  }

  void _handleEquipmentVisibilityChanged(
    EquipmentCategory category,

    bool visible,
  ) {
    final updatedCategories = Set<EquipmentCategory>.from(
      _visibleEquipmentCategories,
    );

    if (visible) {
      updatedCategories.add(category);
    } else {
      updatedCategories.remove(category);
    }

    _updateVisibleEquipmentCategories(updatedCategories);
  }

  Future<void> _showDeleteDefectTabDialog(DefectCategory category) async {
    final shouldDelete = await showDeleteDefectTabDialog(
      context: context,

      category: category,
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    final updated = _controller.removeDefectCategory(
      tabs: _defectTabs,

      category: category,

      activeCategory: _activeCategory,
    );

    await _applyUpdatedSite(
      _site.copyWith(
        visibleDefectCategoryNames: updated.tabs
            .map((tab) => tab.name)
            .toList(),
      ),

      onStateUpdated: () {
        _defectTabs
          ..clear()
          ..addAll(updated.tabs);

        _activeCategory = updated.activeCategory;
      },
    );
  }

  Future<void> _showDeleteEquipmentTabDialog(EquipmentCategory category) async {
    final shouldDelete = await showDeleteEquipmentTabDialog(
      context: context,

      category: category,
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    final updatedCategories = Set<EquipmentCategory>.from(
      _visibleEquipmentCategories,
    )..remove(category);

    await _updateVisibleEquipmentCategories(updatedCategories);
  }

  void _showSelectDefectCategoryHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(StringsKo.selectDefectCategoryHint),

        duration: Duration(seconds: 2),
      ),
    );
  }

  List<EquipmentCategory> _orderedVisibleEquipmentCategories(
    Set<EquipmentCategory> visibleCategories,
  ) {
    return kEquipmentCategoryOrder
        .where((category) => visibleCategories.contains(category))
        .toList();
  }

  void _handlePdfPageChanged(int page) {
    final normalizedPage = page <= 0 ? 1 : page;
    final pendingRestorePage = _pendingPdfRestorePage;
    if (pendingRestorePage != null) {
      if (normalizedPage == pendingRestorePage) {
        _pendingPdfRestorePage = null;
        _didRetryPendingPdfRestoreJump = false;
      } else if (pendingRestorePage > 1 && normalizedPage == 1) {
        if (!_didRetryPendingPdfRestoreJump) {
          _didRetryPendingPdfRestoreJump = true;
          _pdfController?.jumpToPage(pendingRestorePage);
          return;
        }
        _pendingPdfRestorePage = null;
        _didRetryPendingPdfRestoreJump = false;
      }
    }

    _setPdfState(() {
      _currentPage = normalizedPage;

      _activePointerIds.clear();

      _activePointerKinds.clear();

      _activeStylusPointerId = null;

      _isFreeDrawConsumingOneFinger = false;

      _pendingDraw = false;

      _pendingDrawDownViewportLocal = null;

      _canvasController.setLiveStroke(null);

      _canvasController.setEraserCursor(
        _eraserCursorPageNumber == normalizedPage
            ? _eraserCursorPageLocal
            : null,
      );
    });

    final hasPageStrokes = _canvasController
        .getStrokes(normalizedPage)
        .isNotEmpty;

    if (hasPageStrokes &&
        (_canvasController.isCacheDirty(normalizedPage) ||
            !_strokeCacheManager.hasCache(normalizedPage))) {
      unawaited(_rebuildStrokeCacheForPage(normalizedPage));
    }

    if (!_isFreeDrawMode) {
      _debugLogPhotoViewBaseStateOnce('page-change');
    }

    unawaited(_persistCurrentPdfPage(page: normalizedPage));
    _schedulePersistCurrentPdfPageToSite(page: normalizedPage);
  }

  void _handlePdfDocumentLoaded(PdfDocument document) async {
    final pageCount = document.pagesCount;

    final sizes = await _prefetchPdfPageSizes(document);

    if (!mounted) {
      return;
    }
    final requestedRestorePage = _pendingPdfRestorePage;
    final basePage =
        requestedRestorePage ?? (_currentPage <= 0 ? 1 : _currentPage);
    final resolvedPage = basePage.clamp(1, pageCount).toInt();

    _setPdfState(() {
      _pageCount = pageCount;
      _currentPage = resolvedPage;

      _pdfLoadError = null;

      if (sizes.isNotEmpty) {
        _pdfPageSizes
          ..clear()
          ..addAll(sizes);

        _pdfViewVersion += 1;
      }
    });

    if (resolvedPage > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _pdfController?.jumpToPage(resolvedPage);
      });
    } else {
      _pendingPdfRestorePage = null;
      _didRetryPendingPdfRestoreJump = false;
    }
    unawaited(_persistCurrentPdfPage(page: resolvedPage));
    _schedulePersistCurrentPdfPageToSite(page: resolvedPage);
  }

  void _handlePdfDocumentError(Object error) {
    debugPrint('Failed to load PDF: $error');

    _setPdfState(() {
      _pdfLoadError = StringsKo.pdfDrawingLoadFailed;
    });
  }

  void _handleUpdatePageSize(int pageNumber, Size pageSize) {
    if (pageSize.width < _kMinValidPdfPageSide ||
        pageSize.height < _kMinValidPdfPageSide) {
      return;
    }

    final previousSize = _pdfPageSizes[pageNumber];

    _setPdfState(() => _pdfPageSizes[pageNumber] = pageSize);

    if (previousSize == null ||
        previousSize.width != pageSize.width ||
        previousSize.height != pageSize.height) {
      _invalidateCanvasCacheForPage(pageNumber, 'pdf-page-size-updated');
    }

    _persistPdfPageSizeCache();
  }

  void _handlePrevPage() {
    final nextPage = (_currentPage - 1).clamp(1, _pageCount).toInt();

    _safeSetState(() => _currentPage = nextPage);

    _pdfController?.jumpToPage(nextPage);
    unawaited(_persistCurrentPdfPage(page: nextPage));
    _schedulePersistCurrentPdfPageToSite(page: nextPage);
  }

  void _handleNextPage() {
    final nextPage = (_currentPage + 1).clamp(1, _pageCount).toInt();

    _safeSetState(() => _currentPage = nextPage);

    _pdfController?.jumpToPage(nextPage);
    unawaited(_persistCurrentPdfPage(page: nextPage));
    _schedulePersistCurrentPdfPageToSite(page: nextPage);
  }
}
