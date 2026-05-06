part of 'drawing_screen.dart';

extension _DrawingScreenPersistenceLogic on _DrawingScreenState {
  Future<void> _loadPdfPageSizeCache() async {
    final restored = await _loadPdfPageSizeCacheUseCase.execute(site: _site);

    if (!mounted || restored.isEmpty) {
      return;
    }

    _safeSetState(() {
      _pdfPageSizes
        ..clear()
        ..addAll(restored);

      _pdfViewVersion += 1;
    });
  }

  Future<void> _persistPdfPageSizeCache() async {
    await _persistPdfPageSizeCacheUseCase.execute(
      site: _site,

      pageSizes: _pdfPageSizes,
    );
  }

  void _applyPdfLoadResult({
    required PdfController? controller,

    required String? error,

    required Map<int, Size> clearedPageSizes,

    required int pageCount,

    required int currentPage,
    required int restoredPage,
  }) {
    _safeSetState(() {
      _pdfViewVersion += 1;

      _pdfController = controller;

      _pdfLoadError = error;

      if (error != null) {
        return;
      }

      if (clearedPageSizes.isNotEmpty) {
        _pdfPageSizes
          ..clear()
          ..addAll(clearedPageSizes);
      }

      _pageCount = pageCount;

      final targetPage = restoredPage > 0 ? restoredPage : currentPage;
      _currentPage = targetPage;
      _pendingPdfRestorePage = targetPage > 1 ? targetPage : null;
      _didRetryPendingPdfRestoreJump = false;
    });
  }

  Future<void> _loadPdfController() async {
    final path = _site.pdfPath;

    if (path == null || path.isEmpty) {
      return;
    }
    final restoredPage = await _loadPersistedPdfPage(site: _site);

    final previousController = _pdfController;

    _safeSetState(() {
      _pdfController = null;

      _pdfLoadError = null;

      _pdfViewVersion += 1;
    });

    final result = await loadPdfControllerForSite(
      site: _site,

      previousController: previousController,
    );

    if (!mounted || result == null) {
      return;
    }

    _applyPdfLoadResult(
      controller: result.controller,

      error: result.error,

      clearedPageSizes: result.clearedPageSizes,

      pageCount: result.pageCount,

      currentPage: result.currentPage,
      restoredPage: restoredPage,
    );
  }

  Future<void> _replacePdf() async {
    final result = await replacePdfAndUpdateSite(
      site: _site,

      confirmReplace: _confirmPdfReplacement,
    );

    if (!mounted || result == null) {
      return;
    }

    if (result.updatedSite == null) {
      _safeSetState(() {
        _pdfLoadError = result.error ?? StringsKo.pdfDrawingLoadFailed;
      });

      return;
    }

    await _applyUpdatedSite(
      result.updatedSite!,

      onStateUpdated: () {
        _clearSelectionAndPopup(inSetState: false);

        _pdfPageSizes.clear();

        _currentPage = 1;
        _pendingPdfRestorePage = null;
        _didRetryPendingPdfRestoreJump = false;
        unawaited(_persistCurrentPdfPage(page: 1));
        _schedulePersistCurrentPdfPageToSite(page: 1);

        _pageCount = 1;

        _pdfLoadError = null;

        _pdfViewVersion += 1;
      },
    );

    if (!mounted) {
      return;
    }

    await _loadPdfController();
  }

  Future<bool> _confirmPdfReplacement(String fileName) async {
    final confirmed = await showDialog<bool>(
      context: context,

      barrierDismissible: true,

      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('PDF 교체 확인'),

          content: Text("'$fileName' 파일로 도면을 교체하시겠습니까?"),

          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),

              child: const Text('취소'),
            ),

            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),

              child: const Text('교체'),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  void _clearSelectionAndPopup({bool inSetState = true}) {
    if (_selectedDefect == null &&
        _selectedEquipment == null &&
        _selectedMarkerScenePosition == null) {
      return;
    }

    void clearSelection() {
      _selectedDefectId = null;

      _selectedEquipmentId = null;

      _selectedMarkerScenePosition = null;
    }

    if (inSetState) {
      _safeSetState(clearSelection);
    } else {
      clearSelection();
    }

    if (_isMoveMode) {
      _cancelMoveMode();
    }
  }

  Future<void> _handleCanvasTap(TapUpDetails details) async {
    if (_isMoveMode) {
      return;
    }

    if (_isStylusRequiredMarkerPlacementMode &&
        !_isMarkerPlacementPointerAllowed(details.kind)) {
      drawingVerboseLog('[MarkerPlacement] blocked tap kind=${details.kind}');

      return;
    }

    if (_isFreeDrawMode && _activeTool == DrawingTool.shape) {
      final tapInfo = _resolveTapPosition(
        _canvasTapRegionKey.currentContext,

        details.globalPosition,
      );

      final localPosition = tapInfo?.localPosition ?? details.localPosition;

      final scenePoint = _transformationController.toScene(localPosition);

      final normalized = toNormalized(scenePoint, drawingCanvasSize);

      _handleShapeTapSelection(normPoint: normalized, pageNumber: _currentPage);

      return;
    }

    final tapInfo = _resolveTapPosition(
      _canvasTapRegionKey.currentContext,

      details.globalPosition,
    );

    final localPosition = tapInfo?.localPosition ?? details.localPosition;

    final scenePoint = _transformationController.toScene(localPosition);

    final hitResult = _hitTestMarker(
      point: scenePoint,

      size: drawingCanvasSize,

      pageIndex: _currentPage,
    );

    final isPlaceMode = _isPlaceMode;

    final decision = _controller.handleCanvasTapDecision(
      isDetailDialogOpen: _isDetailDialogOpen,

      tapCanceled: _tapCanceled,

      isWithinCanvas: _isTapWithinCanvas(details.globalPosition),

      hasHitResult: !isPlaceMode && hitResult != null,

      mode: _mode,

      hasActiveDefectCategory: _activeCategory != null,

      hasActiveEquipmentCategory: _activeEquipmentCategory != null,
    );

    final normalized = toNormalized(scenePoint, drawingCanvasSize);

    final updatedSite = await _handleTapFlow(
      hitResult: hitResult,

      decision: decision,

      pageIndex: _currentPage,

      normalizedX: normalized.dx,

      normalizedY: normalized.dy,
    );

    await _applyUpdatedSiteIfMounted(updatedSite);
  }

  Future<void> _applyUpdatedSiteIfMounted(Site? updatedSite) async {
    if (!mounted || updatedSite == null) {
      return;
    }

    await _applyUpdatedSite(updatedSite);
  }

  Future<void> _applyUpdatedSite(
    Site updatedSite, {

    VoidCallback? onStateUpdated,
  }) async {
    final didChangeDrawing =
        _drawingIdentityKey(_site) != _drawingIdentityKey(updatedSite);

    _safeSetState(() {
      _site = updatedSite;

      onStateUpdated?.call();
    });

    if (didChangeDrawing) {
      _resetPdfViewControllers();

      _resetScalePreferences();

      await _loadScalePreferences();
    }

    await widget.onSiteUpdated(_site);
  }

  void _schedulePersistCurrentPdfPageToSite({required int page}) {
    if (_site.drawingType != DrawingType.pdf) {
      return;
    }
    final safePage = page <= 0 ? 1 : page;
    if (_queuedPdfPageForSitePersist == safePage &&
        _site.lastViewedPdfPage == safePage) {
      return;
    }
    _queuedPdfPageForSitePersist = safePage;
    _persistPdfPageSiteTask = _persistPdfPageSiteTask.then((_) async {
      final targetPage = _queuedPdfPageForSitePersist;
      _queuedPdfPageForSitePersist = null;
      if (!mounted || targetPage == null) {
        return;
      }
      if (_site.drawingType != DrawingType.pdf) {
        return;
      }
      if (_site.lastViewedPdfPage == targetPage) {
        return;
      }
      final updatedSite = _site.copyWith(lastViewedPdfPage: targetPage);
      _site = updatedSite;
      try {
        await widget.onSiteUpdated(updatedSite);
      } catch (_) {
        // Ignore metadata save failure to avoid blocking draw flow.
      }
    });
  }

  Future<void> _loadStrokesFromSite() async {
    final targetSiteId = _site.id;

    await _cleanupLegacyDrawingPrefsForSite(targetSiteId);

    final loaded = await _loadSiteDrawingUseCase.execute(siteId: targetSiteId);

    if (!mounted || _site.id != targetSiteId) {
      return;
    }

    _canvasController.strokesByPage.clear();

    for (final entry in loaded.entries) {
      _canvasController.setStrokes(entry.key, entry.value);
    }

    _safeSetState(() {
      _syncAllStrokesByPageFromController();

      _inProgressStroke = null;

      _historyManager.clear();

      _canUndoDrawing = _historyManager.canUndo;

      _canRedoDrawing = _historyManager.canRedo;
    });

    for (final page in loaded.keys) {
      _invalidateCanvasCacheForPage(page, 'restore');
    }

    _canvasController.setLiveStroke(null);
  }

  void _requestPersistDrawing({bool immediate = false}) {
    _hasUnsavedChanges = true;

    _didWarnUnsavedOnExit = false;

    _persistPending = true;

    _persistDebounce?.cancel();

    if (immediate) {
      _persistDebounce = null;

      if (!mounted || _persistInFlight) {
        return;
      }

      unawaited(_runPersistLoop());

      return;
    }

    _persistDebounce = Timer(const Duration(milliseconds: 120), () {
      if (!mounted) {
        return;
      }

      if (_persistInFlight) {
        return;
      }

      unawaited(_runPersistLoop());
    });
  }

  Future<void> _runPersistLoop() async {
    _persistInFlight = true;

    while (_persistPending && mounted) {
      _persistPending = false;

      final int epoch = ++_persistEpoch;

      await _persistDrawingEpoch(epoch);
    }

    _persistInFlight = false;
  }

  Future<void> _persistDrawingEpoch(int epoch) async {
    try {
      final updatedSite = await _persistSiteDrawingUseCase.execute(
        site: _site,

        strokesByPage: _strokesByPage,
        lastViewedPdfPage: _site.drawingType == DrawingType.pdf
            ? _currentPage
            : null,
      );

      if (!mounted || epoch != _persistEpoch) {
        return;
      }

      _safeSetState(() {
        _site = updatedSite;

        _hasUnsavedChanges = false;
      });

      await widget.onSiteUpdated(updatedSite);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _safeSetState(() {
        _hasUnsavedChanges = true;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('?????묎덩?????됰꽡???怨?????덊렡')),
        );
    }
  }

  Future<void> _cleanupLegacyDrawingPrefsForSite(String siteId) async {
    final prefs = await SharedPreferences.getInstance();

    final keys = <String>{
      'drawing_$siteId',

      'undo_$siteId',

      'redo_$siteId',

      'drawing_json',

      'undo_redo_json',

      'site_json',
    };

    for (final key in keys) {
      if (prefs.containsKey(key)) {
        await prefs.remove(key);
      }
    }
  }

  Future<void> _handleExit() async {
    if (_hasUnsavedChanges && !_didWarnUnsavedOnExit && mounted) {
      _didWarnUnsavedOnExit = true;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              '????????됰꽡????? ???⑤챶裕?????潁뺛깾逾녜뇡??? ????⒱봼???????怨?????덊렡',
            ),
          ),
        );
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _setPdfState(VoidCallback callback) {
    if (!mounted) {
      return;
    }

    _safeSetState(callback);
  }
}
