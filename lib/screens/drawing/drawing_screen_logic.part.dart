part of 'drawing_screen.dart';

class _PendingAreaEraserMove {
  const _PendingAreaEraserMove({
    required this.pageNumber,
    required this.pageSize,
    required this.pageLocal,
    required this.radiusPagePx,
  });

  final int pageNumber;
  final Size pageSize;
  final Offset pageLocal;
  final double radiusPagePx;
}

class _PendingFreeDrawMove {
  const _PendingFreeDrawMove({
    required this.pointerId,
    required this.pageNumber,
    required this.pageSize,
    required this.normalized,
    required this.photoScale,
  });

  final int pointerId;
  final int pageNumber;
  final Size pageSize;
  final Offset normalized;
  final double photoScale;
}

class _PendingStraightenCommit {
  const _PendingStraightenCommit({
    required this.snappedPageExact,
    required this.destSize,
    required this.photoScale,
  });

  final Offset snappedPageExact;
  final Size destSize;
  final double photoScale;
}

class _AreaEraserSession {
  const _AreaEraserSession({
    required this.radius,
    this.removedStrokeIds = const <String>{},
    this.processedStrokeIds = const <String>{},
    this.removedById = const <String, DrawingStroke>{},
    this.addedById = const <String, DrawingStroke>{},
  });

  final double radius;
  final Set<String> removedStrokeIds;
  final Set<String> processedStrokeIds;
  final Map<String, DrawingStroke> removedById;
  final Map<String, DrawingStroke> addedById;

  _AreaEraserSession copyWith({
    double? radius,
    Set<String>? removedStrokeIds,
    Set<String>? processedStrokeIds,
    Map<String, DrawingStroke>? removedById,
    Map<String, DrawingStroke>? addedById,
  }) {
    return _AreaEraserSession(
      radius: radius ?? this.radius,
      removedStrokeIds: removedStrokeIds ?? this.removedStrokeIds,
      processedStrokeIds: processedStrokeIds ?? this.processedStrokeIds,
      removedById: removedById ?? this.removedById,
      addedById: addedById ?? this.addedById,
    );
  }
}

final Expando<_PendingFreeDrawMove> _pendingFreeDrawMoveByState =
    Expando<_PendingFreeDrawMove>('pendingFreeDrawMoveByState');
final Expando<bool> _isFreeDrawMoveScheduledByState = Expando<bool>(
  'isFreeDrawMoveScheduledByState',
);
final Expando<int> _freeDrawCallsInWindowByState = Expando<int>(
  'freeDrawCallsInWindowByState',
);
final Expando<int> _freeDrawUiMutationsInWindowByState = Expando<int>(
  'freeDrawUiMutationsInWindowByState',
);
final Expando<DateTime> _freeDrawWindowStartByState = Expando<DateTime>(
  'freeDrawWindowStartByState',
);
final Expando<Map<int, _PendingStraightenCommit>>
_pendingStraightenCommitByPointerByState =
    Expando<Map<int, _PendingStraightenCommit>>(
      'pendingStraightenCommitByPointerByState',
    );

const double _kMinValidPdfPageSide = 200.0;

typedef OverlayToPageLocal = Offset? Function(Offset overlayLocal);

extension _DrawingScreenLogic on _DrawingScreenState {
  void _resetHighlighterStraightenState() {
    _straightenSnappedAngleByPointer.clear();
    _straightenStartPageByPointer.clear();
    _pendingStraightenCommitByPointer.clear();
  }

  Map<int, _PendingStraightenCommit> get _pendingStraightenCommitByPointer =>
      _pendingStraightenCommitByPointerByState[this] ??=
          <int, _PendingStraightenCommit>{};

  _PendingFreeDrawMove? get _pendingFreeDrawMove =>
      _pendingFreeDrawMoveByState[this];

  set _pendingFreeDrawMove(_PendingFreeDrawMove? value) {
    _pendingFreeDrawMoveByState[this] = value;
  }

  bool get _isFreeDrawMoveScheduled =>
      _isFreeDrawMoveScheduledByState[this] ?? false;

  set _isFreeDrawMoveScheduled(bool value) {
    _isFreeDrawMoveScheduledByState[this] = value;
  }

  void _handleCanvasCacheInvalidated() {
    final dirtyPages = _canvasController.getDirtyPagesSnapshot();
    if (dirtyPages.isEmpty) {
      return;
    }
    for (final page in dirtyPages) {
      unawaited(_rebuildStrokeCacheForPage(page));
    }
  }

  Size _canvasSizeForPage(int page) {
    if (_site.drawingType == DrawingType.pdf) {
      return _pdfPageSizes[page] ?? Size.zero;
    }
    return DrawingCanvasSize;
  }

  Future<void> _rebuildStrokeCacheForPage(int page) async {
    final canvasSize = _canvasSizeForPage(page);
    if (canvasSize.width <= 0 || canvasSize.height <= 0) {
      return;
    }

    await _strokeCacheManager.rebuildCache(
      page: page,
      size: canvasSize,
      strokes: _canvasController.getStrokes(page),
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
    );
    _canvasController.markCacheClean(page);
  }

  void _invalidateCanvasCacheForPage(int page, String reason) {
    _canvasController.invalidateCache(page, reason: reason);
  }

  void _recordFreeDrawPerfCall() {
    if (!kDebugMode) {
      return;
    }
    final now = DateTime.now();
    final windowStart = _freeDrawWindowStartByState[this];
    if (windowStart == null) {
      _freeDrawWindowStartByState[this] = now;
      _freeDrawCallsInWindowByState[this] = 1;
      _freeDrawUiMutationsInWindowByState[this] = 0;
      return;
    }

    _freeDrawCallsInWindowByState[this] =
        (_freeDrawCallsInWindowByState[this] ?? 0) + 1;
    final elapsedMs = now.difference(windowStart).inMilliseconds;
    if (elapsedMs < 1000) {
      return;
    }

    debugPrint(
      '[Perf] freeDraw: calls/s=${_freeDrawCallsInWindowByState[this] ?? 0} '
      'uiMutations/s=${_freeDrawUiMutationsInWindowByState[this] ?? 0}',
    );
    _freeDrawWindowStartByState[this] = now;
    _freeDrawCallsInWindowByState[this] = 0;
    _freeDrawUiMutationsInWindowByState[this] = 0;
  }

  void _recordFreeDrawPerfUiMutation() {
    if (!kDebugMode) {
      return;
    }
    _freeDrawUiMutationsInWindowByState[this] =
        (_freeDrawUiMutationsInWindowByState[this] ?? 0) + 1;
  }

  bool get _isPanScaleAllowedDuringDraw {
    if (!_isFreeDrawMode) {
      return true;
    }
    if (_isStylusActive ||
        _pendingDraw ||
        _inProgressStroke != null ||
        _isFreeDrawConsumingOneFinger) {
      return false;
    }
    return true;
  }

  bool _isStylusKind(PointerDeviceKind kind) {
    return kind == PointerDeviceKind.stylus ||
        kind == PointerDeviceKind.invertedStylus ||
        kind == PointerDeviceKind.touch ||
        kind == PointerDeviceKind.unknown;
  }

  bool _isStrictStylusKind(PointerDeviceKind kind) {
    return kind == PointerDeviceKind.stylus ||
        kind == PointerDeviceKind.invertedStylus ||
        kind == PointerDeviceKind.unknown;
  }

  int get _activeTouchPointerCount => _activePointerKinds.values
      .where((kind) => kind == PointerDeviceKind.touch)
      .length;

  bool get _isStylusActive => _activeStylusPointerId != null;

  Matrix4 _buildPhotoViewChildMatrix({
    required PhotoViewControllerValue value,
    required Size viewportSize,
    required Size childSize,
  }) {
    final scale = value.scale ?? 1.0;
    final position = value.position;
    final viewportCenter = viewportSize.center(Offset.zero);
    final childCenter = childSize.center(Offset.zero);

    return Matrix4.identity()
      ..translate(viewportCenter.dx, viewportCenter.dy)
      ..translate(position.dx, position.dy)
      ..scale(scale, scale, 1.0)
      ..translate(-childCenter.dx, -childCenter.dy);
  }

  Offset? _mapPdfViewportPointToPageLocal({
    required Offset viewportLocal,
    required int pageIndex,
    required Size viewportSize,
    required Size childSize,
  }) {
    if (viewportSize.isEmpty || childSize.isEmpty) {
      return null;
    }
    final controllerValue = _photoControllerForPage(pageIndex).value;
    final matrix = _buildPhotoViewChildMatrix(
      value: controllerValue,
      viewportSize: viewportSize,
      childSize: childSize,
    );
    final inverted = Matrix4.inverted(matrix);
    final pageLocal = MatrixUtils.transformPoint(inverted, viewportLocal);
    if (pageLocal.dx < 0 ||
        pageLocal.dx > childSize.width ||
        pageLocal.dy < 0 ||
        pageLocal.dy > childSize.height) {
      return null;
    }
    return pageLocal;
  }

  Offset? _overlayToNormalizedPoint({
    required Offset overlayLocal,
    required Size destSize,
  }) {
    if (destSize.isEmpty) {
      return null;
    }
    if (overlayLocal.dx < 0 ||
        overlayLocal.dx > destSize.width ||
        overlayLocal.dy < 0 ||
        overlayLocal.dy > destSize.height) {
      return null;
    }
    return Offset(
      overlayLocal.dx / destSize.width,
      overlayLocal.dy / destSize.height,
    );
  }

  bool get _isPlaceMode {
    if (_mode == DrawMode.defect) {
      return _activeCategory != null;
    }
    if (_mode == DrawMode.equipment) {
      return _activeEquipmentCategory != null;
    }
    return false;
  }

  String _pdfPageSizeCacheKeyForSite(Site site) {
    final path = site.pdfPath ?? '';
    return 'drawing_pdf_page_sizes_cache_v1:${path.hashCode}';
  }

  void _initializeDefectTabs() {
    final tabs = <DefectCategory>[];
    for (final name in _site.visibleDefectCategoryNames) {
      final matches = DefectCategory.values.where(
        (category) => category.name == name,
      );
      if (matches.isNotEmpty) {
        tabs.add(matches.first);
      }
    }
    _defectTabs
      ..clear()
      ..addAll(tabs);
  }

  void _initializeEquipmentTabs() {
    final visibleNames = _site.visibleEquipmentCategoryNames.toSet();
    final categories = kEquipmentCategoryOrder
        .where((category) => visibleNames.contains(category.name))
        .toList();
    _visibleEquipmentCategories
      ..clear()
      ..addAll(categories);
  }

  Future<void> _loadPdfPageSizeCache() async {
    final path = _site.pdfPath;
    if (path == null || path.isEmpty) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pdfPageSizeCacheKeyForSite(_site));
    if (raw == null || raw.isEmpty) {
      return;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return;
    }
    final restored = <int, Size>{};
    for (final entry in decoded.entries) {
      final page = int.tryParse(entry.key);
      final value = entry.value;
      if (page == null || value is! Map) {
        continue;
      }
      final width = (value['w'] as num?)?.toDouble();
      final height = (value['h'] as num?)?.toDouble();
      if (width == null || height == null) {
        continue;
      }
      if (width < _kMinValidPdfPageSide || height < _kMinValidPdfPageSide) {
        continue;
      }
      restored[page] = Size(width, height);
    }
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
    final path = _site.pdfPath;
    if (path == null || path.isEmpty) {
      return;
    }
    final map = <String, Map<String, double>>{};
    _pdfPageSizes.forEach((page, size) {
      map['$page'] = {'w': size.width, 'h': size.height};
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pdfPageSizeCacheKeyForSite(_site), jsonEncode(map));
  }

  Future<void> _loadPdfController() async {
    final path = _site.pdfPath;
    if (path == null || path.isEmpty) {
      return;
    }
    final previousController = _pdfController;
    _pdfController = null;
    final result = await loadPdfControllerForSite(
      site: _site,
      previousController: previousController,
    );
    if (!mounted || result == null) {
      return;
    }
    _safeSetState(() {
      _pdfController = result.controller;
      _pdfLoadError = result.error;
      if (result.error == null) {
        if (result.clearedPageSizes.isNotEmpty) {
          _pdfPageSizes
            ..clear()
            ..addAll(result.clearedPageSizes);
        }
        _pageCount = result.pageCount;
        _currentPage = result.currentPage;
      }
    });
  }

  Future<void> _replacePdf() async {
    final result = await replacePdfAndUpdateSite(site: _site);
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
        _pageCount = 1;
      },
    );
    if (!mounted) {
      return;
    }
    await _loadPdfController();
  }

  void _clearSelectionAndPopup({bool inSetState = true}) {
    if (_selectedDefect == null &&
        _selectedEquipment == null &&
        _selectedMarkerScenePosition == null)
      return;
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
    if (_activeTool == DrawingTool.shape) {
      final tapInfo = _resolveTapPosition(
        _canvasTapRegionKey.currentContext,
        details.globalPosition,
      );
      final localPosition = tapInfo?.localPosition ?? details.localPosition;
      final scenePoint = _transformationController.toScene(localPosition);
      final normalized = toNormalized(scenePoint, DrawingCanvasSize);
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
      size: DrawingCanvasSize,
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
    final normalized = toNormalized(scenePoint, DrawingCanvasSize);
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

  Future<void> _loadStrokesFromSite() async {
    final targetSiteId = _site.id;
    await _cleanupLegacyDrawingPrefsForSite(targetSiteId);

    final payload = await _drawingPersistenceStore.loadSiteDrawing(
      siteId: targetSiteId,
    );
    final Map<int, List<DrawingStroke>> loaded = <int, List<DrawingStroke>>{};

    final drawingStrokesJson = payload?['drawingStrokes'];
    if (drawingStrokesJson is List) {
      for (final rawStroke in drawingStrokesJson.whereType<Map>()) {
        final stroke = DrawingStroke.fromJson(
          rawStroke.cast<String, dynamic>(),
        );
        loaded
            .putIfAbsent(stroke.pageNumber, () => <DrawingStroke>[])
            .add(stroke);
      }
    }

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

  void _requestPersistDrawing() {
    _persistPending = true;
    _persistDebounce?.cancel();
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
    final flatList = _strokesByPage.entries
        .expand((entry) => entry.value)
        .map((stroke) => stroke.deepCopy())
        .toList();
    await _drawingPersistenceStore.saveSiteDrawing(
      siteId: _site.id,
      payloadJson: <String, dynamic>{
        'drawingStrokes': flatList.map((stroke) => stroke.toJson()).toList(),
      },
    );
    final updatedSite = _site.copyWith(
      drawingStrokes: const <DrawingStroke>[],
      drawingUndoHistory: const <DrawingHistoryActionPersisted>[],
      drawingRedoHistory: const <DrawingHistoryActionPersisted>[],
    );
    try {
      final sites = await SiteStorage.loadSites();
      final existingIndex = sites.indexWhere((s) => s.id == updatedSite.id);
      final updatedSites = List<Site>.from(sites);
      if (existingIndex >= 0) {
        updatedSites[existingIndex] = updatedSite;
      } else {
        updatedSites.add(updatedSite);
      }
      await SiteStorage.saveSites(updatedSites);
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

  void _selectMarker(MarkerHitResult result) {
    _safeSetState(() {
      _selectedDefectId = result.defect?.id;
      _selectedEquipmentId = result.equipment?.id;
      _selectedMarkerScenePosition = result.position;
    });
    _handleMoveModeSelectionChange(result.defect, result.equipment);
    _switchToDetailTab();
  }

  void _switchToDetailTab() {
    if (_sidePanelController.index != 2) {
      _sidePanelController.animateTo(2);
    }
  }

  void _selectDefectFromPanel(Defect defect) {
    _safeSetState(() {
      _selectedDefectId = defect.id;
      _selectedEquipmentId = null;
      _selectedMarkerScenePosition = null;
    });
    _handleMoveModeSelectionChange(defect, null);
    _switchToDetailTab();
  }

  void _selectEquipmentFromPanel(EquipmentMarker marker) {
    _safeSetState(() {
      _selectedDefectId = null;
      _selectedEquipmentId = marker.id;
      _selectedMarkerScenePosition = null;
    });
    _handleMoveModeSelectionChange(null, marker);
    _switchToDetailTab();
  }

  bool _isTapWithinCanvas(Offset globalPosition) {
    return _resolveTapPosition(
          _canvasTapRegionKey.currentContext,
          globalPosition,
        ) !=
        null;
  }

  Future<DefectDetails?> _showDefectDetailsDialog({
    String? defectId,
    DefectCategory? category,
    DefectDetails? initialDetails,
  }) async {
    final defectCategory =
        category ?? _activeCategory ?? DefectCategory.generalCrack;
    final defectConfig = defectCategoryConfig(defectCategory);
    final resolvedDefectId =
        defectId ??
        _selectedDefect?.id ??
        DateTime.now().microsecondsSinceEpoch.toString();
    return _showDetailDialog(
      () => showDefectDetailsDialog(
        context: context,
        title: defectConfig.dialogTitle,
        typeOptions: defectConfig.typeOptions,
        causeOptions: defectConfig.causeOptions,
        siteId: _site.id,
        defectId: resolvedDefectId,
        initialDetails: initialDetails,
      ),
    );
  }

  Future<EquipmentDetails?> _showEquipmentDetailsDialog({
    required String title,
    String? initialMemberType,
    List<String>? initialSizeValues,
    String? initialRemark,
    bool? initialWComplete,
    bool? initialHComplete,
    bool? initialDComplete,
  }) async {
    return _showDetailDialog(
      () => showEquipmentDetailsDialog(
        context: context,
        title: title,
        memberOptions: DrawingEquipmentMemberOptions,
        sizeLabelsByMember: DrawingEquipmentMemberSizeLabels,
        initialMemberType: initialMemberType,
        initialSizeValues: initialSizeValues,
        initialRemark: initialRemark,
        initialWComplete: initialWComplete,
        initialHComplete: initialHComplete,
        initialDComplete: initialDComplete,
      ),
    );
  }

  Future<RebarSpacingGroupDetails?> _showRebarSpacingDialog({
    required String title,
    String? initialMemberType,
    List<RebarSpacingMeasurement>? initialMeasurements,
    bool allowMultiple = false,
    int? baseLabelIndex,
    String? labelPrefix,
  }) async {
    return _showDetailDialog(
      () => showRebarSpacingDialog(
        context: context,
        title: title,
        memberOptions: DrawingRebarSpacingMemberOptions,
        initialMemberType: initialMemberType,
        initialMeasurements: initialMeasurements,
        allowMultiple: allowMultiple,
        baseLabelIndex: baseLabelIndex,
        labelPrefix: labelPrefix,
      ),
    );
  }

  Future<SchmidtHammerDetails?> _showSchmidtHammerDialog({
    required String title,
    String? initialMemberType,
    int? initialAngleDeg,
    String? initialMaxValueText,
    String? initialMinValueText,
  }) async {
    return _showDetailDialog(
      () => showSchmidtHammerDialog(
        context: context,
        title: title,
        memberOptions: DrawingSchmidtHammerMemberOptions,
        initialMemberType: initialMemberType,
        initialAngleDeg: initialAngleDeg,
        initialMaxValueText: initialMaxValueText,
        initialMinValueText: initialMinValueText,
      ),
    );
  }

  Future<CoreSamplingDetails?> _showCoreSamplingDialog({
    required String title,
    String? initialMemberType,
    String? initialAvgValueText,
  }) async {
    return _showDetailDialog(
      () => showCoreSamplingDialog(
        context: context,
        title: title,
        memberOptions: DrawingCoreSamplingMemberOptions,
        initialMemberType: initialMemberType,
        initialAvgValueText: initialAvgValueText,
      ),
    );
  }

  Future<CarbonationDetails?> _showCarbonationDialog({
    required String title,
    String? initialMemberType,
    String? initialCoverThicknessText,
    String? initialDepthText,
  }) async {
    return _showDetailDialog(
      () => showCarbonationDialog(
        context: context,
        title: title,
        memberOptions: DrawingCarbonationMemberOptions,
        initialMemberType: initialMemberType,
        initialCoverThicknessText: initialCoverThicknessText,
        initialDepthText: initialDepthText,
      ),
    );
  }

  Future<StructuralTiltDetails?> _showStructuralTiltDialog({
    required String title,
    String? initialDirection,
    String? initialDisplacementText,
  }) async {
    return _showDetailDialog(
      () => showStructuralTiltDialog(
        context: context,
        title: title,
        initialDirection: initialDirection,
        initialDisplacementText: initialDisplacementText,
      ),
    );
  }

  Future<SettlementDetails?> _showSettlementDialog({
    required String baseTitle,
    required Map<String, int> nextIndexByDirection,
    String? initialDirection,
    String? initialDisplacementText,
  }) async {
    return _showDetailDialog(
      () => showSettlementDialog(
        context: context,
        baseTitle: baseTitle,
        nextIndexByDirection: nextIndexByDirection,
        initialDirection: initialDirection,
        initialDisplacementText: initialDisplacementText,
      ),
    );
  }

  Future<DeflectionDetails?> _showDeflectionDialog({
    required String title,
    String? initialMemberType,
    String? initialEndAText,
    String? initialMidBText,
    String? initialEndCText,
  }) async {
    return _showDetailDialog(
      () => showDeflectionDialog(
        context: context,
        title: title,
        memberOptions: DrawingDeflectionMemberOptions,
        initialMemberType: initialMemberType,
        initialEndAText: initialEndAText,
        initialMidBText: initialMidBText,
        initialEndCText: initialEndCText,
      ),
    );
  }

  Future<void> _handlePdfTapAt(
    Offset pageLocal,
    Size pageSize,
    int pageIndex,
  ) async {
    if (_activeTool == DrawingTool.shape) {
      final normalized = toNormalized(pageLocal, pageSize);
      _handleShapeTapSelection(
        normPoint: normalized,
        pageNumber: pageIndex,
        pageSize: pageSize,
      );
      return;
    }
    if (_isMoveMode || _isStrokeEraserActive || _isAreaEraserActive) {
      return;
    }
    if (kDebugMode) {
      debugPrint('[PDF] tap: $pageLocal');
    }
    final localPosition = pageLocal;
    final imageSize = pageSize;
    final imageLocal = localPosition;
    final hitResult = _hitTestMarker(
      point: imageLocal,
      size: imageSize,
      pageIndex: pageIndex,
    );
    final isPlaceMode = _isPlaceMode;
    final decision = _controller.handlePdfTapDecision(
      isDetailDialogOpen: _isDetailDialogOpen,
      tapCanceled: _tapCanceled,
      isWithinCanvas:
          true, // PDF taps should always be treated as within canvas.
      hasHitResult: !isPlaceMode && hitResult != null,
      mode: _mode,
      hasActiveDefectCategory: _activeCategory != null,
      hasActiveEquipmentCategory: _activeEquipmentCategory != null,
    );
    final normalized = toNormalized(imageLocal, imageSize);
    final updatedSite = await _handleTapFlow(
      hitResult: hitResult,
      decision: decision,
      pageIndex: pageIndex,
      normalizedX: normalized.dx,
      normalizedY: normalized.dy,
    );
    await _applyUpdatedSiteIfMounted(updatedSite);
  }

  Future<void> _handleCanvasLongPress(LongPressStartDetails details) async {
    if (_isMoveMode) {
      return;
    }
    _tapCanceled = true;
    final tapInfo = _resolveTapPosition(
      _canvasTapRegionKey.currentContext,
      details.globalPosition,
    );
    final localPosition = tapInfo?.localPosition ?? details.localPosition;
    final scenePoint = _transformationController.toScene(localPosition);
    final hits = _hitTestMarkers(
      point: scenePoint,
      size: DrawingCanvasSize,
      pageIndex: _currentPage,
    );
    await _handleOverlapSelection(hits);
  }

  Future<void> _handlePdfLongPressAt(
    Offset pageLocal,
    Size pageSize,
    int pageIndex,
  ) async {
    if (_isMoveMode) {
      return;
    }
    _tapCanceled = true;
    final localPosition = pageLocal;
    final imageSize = pageSize;
    final imageLocal = localPosition;
    final hits = _hitTestMarkers(
      point: imageLocal,
      size: imageSize,
      pageIndex: pageIndex,
    );
    await _handleOverlapSelection(hits);
  }

  void _handleShapeTapSelection({
    required Offset normPoint,
    required int pageNumber,
    Size? pageSize,
  }) {
    this._clearShapeSelection();
    final pageStrokes = _canvasController.getStrokes(pageNumber);
    final hitPaddingNorm = pageSize == null || pageSize.isEmpty
        ? 0.02
        : (12.0 / pageSize.shortestSide).clamp(0.005, 0.06);
    for (var i = pageStrokes.length - 1; i >= 0; i -= 1) {
      final stroke = pageStrokes[i];
      if (stroke.toolType != DrawingTool.shape) {
        continue;
      }
      final rawBounds = _shapeStrokeBounds(stroke.pointsNorm);
      if (rawBounds == null) {
        continue;
      }
      final hitBounds = Rect.fromLTRB(
        (rawBounds.left - hitPaddingNorm).clamp(0.0, 1.0),
        (rawBounds.top - hitPaddingNorm).clamp(0.0, 1.0),
        (rawBounds.right + hitPaddingNorm).clamp(0.0, 1.0),
        (rawBounds.bottom + hitPaddingNorm).clamp(0.0, 1.0),
      );
      if (hitBounds.contains(normPoint)) {
        _safeSetState(() {
          _selectedShapeStrokeId = stroke.id;
          _activeShapeManipulator = ShapeManipulator(
            boundsNorm: rawBounds,
            rotationRad: 0.0,
          );
          _activeShapeHandle = ShapeHandle.none;
          _activeShapeEditOp = _ShapeEditOperation.none;
          _shapeInteractionStartNorm = null;
          _shapeInteractionLastNorm = null;
          _shapeCreateHasMoved = false;
          _shapeCreateThresholdNorm = 0.0;
        });
        return;
      }
    }
  }

  Rect? _shapeStrokeBounds(List<Offset> pointsNorm) {
    if (pointsNorm.isEmpty) {
      return null;
    }
    var left = 1.0;
    var right = 0.0;
    var top = 1.0;
    var bottom = 0.0;
    for (final point in pointsNorm) {
      final clamped = Offset(
        point.dx.clamp(0.0, 1.0),
        point.dy.clamp(0.0, 1.0),
      );
      left = left < clamped.dx ? left : clamped.dx;
      right = right > clamped.dx ? right : clamped.dx;
      top = top < clamped.dy ? top : clamped.dy;
      bottom = bottom > clamped.dy ? bottom : clamped.dy;
    }
    if (left > right || top > bottom) {
      return null;
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  void _clearShapeSelection() {
    _safeSetState(() {
      _selectedShapeStrokeId = null;
      _activeShapeManipulator = null;
      _activeShapeHandle = ShapeHandle.none;
      _activeShapeEditOp = _ShapeEditOperation.none;
      _shapeRotateSnappedAngleRad = null;
      _shapeRotateGestureStartAngleRad = null;
      _shapeRotateGestureStartRotationRad = null;
      _shapeInteractionStartNorm = null;
      _shapeInteractionLastNorm = null;
      _shapeCreateHasMoved = false;
      _shapeCreateThresholdNorm = 0.0;
    });
  }

  void _clearShapeInteractionState() {
    _safeSetState(() {
      _activeShapeHandle = ShapeHandle.none;
      _activeShapeEditOp = _ShapeEditOperation.none;
      _shapeRotateSnappedAngleRad = null;
      _shapeRotateGestureStartAngleRad = null;
      _shapeRotateGestureStartRotationRad = null;
      _shapeInteractionStartNorm = null;
      _shapeInteractionLastNorm = null;
      _shapeCreateHasMoved = false;
      _shapeCreateThresholdNorm = 0.0;
    });
  }

  void _handleShapeStrokeInteractionStart({
    required int pointerId,
    required int pageNumber,
    required Size pageSize,
    required Offset startNorm,
    required StrokeStyle style,
  }) {
    if (_activeStylusPointerId == null || _activeStylusPointerId != pointerId) {
      return;
    }

    final pageStrokes = _canvasController.getStrokes(pageNumber);
    final hitPaddingNorm = (12.0 / pageSize.shortestSide).clamp(0.005, 0.06);
    DrawingStroke? handleCandidate;
    ShapeManipulator? handleManipulator;
    ShapeHandle handleHit = ShapeHandle.none;
    DrawingStroke? candidate;
    Rect? candidateBounds;
    for (var i = pageStrokes.length - 1; i >= 0; i -= 1) {
      final stroke = pageStrokes[i];
      if (stroke.toolType != DrawingTool.shape) {
        continue;
      }
      final bounds = _shapeStrokeBounds(stroke.pointsNorm);
      if (bounds == null) {
        continue;
      }
      final manipulator = ShapeManipulator(
        boundsNorm: bounds,
        rotationRad: 0.0,
      );
      final hitHandle = manipulator.hitTestHandle(startNorm);
      if (hitHandle != ShapeHandle.none) {
        handleCandidate = stroke;
        handleManipulator = manipulator;
        handleHit = hitHandle;
        break;
      }
      final paddedBounds = Rect.fromLTRB(
        (bounds.left - hitPaddingNorm).clamp(0.0, 1.0),
        (bounds.top - hitPaddingNorm).clamp(0.0, 1.0),
        (bounds.right + hitPaddingNorm).clamp(0.0, 1.0),
        (bounds.bottom + hitPaddingNorm).clamp(0.0, 1.0),
      );
      if (paddedBounds.contains(startNorm)) {
        candidate = stroke;
        candidateBounds = bounds;
        break;
      }
    }

    if (handleCandidate != null && handleManipulator != null) {
      final center = handleManipulator.boundsNorm.center;
      final gestureStartAngle = _shapePointerAngleForPageSpace(
        centerNorm: center,
        pointerNorm: startNorm,
        pageSize: pageSize,
      );
      final gestureStartRotation = handleManipulator.rotationRad;
      _safeSetState(() {
        _selectedShapeStrokeId = handleCandidate!.id;
        _activeShapeManipulator = handleManipulator;
        _activeShapeHandle = handleHit;
        _activeShapeEditOp = handleHit == ShapeHandle.rotate
            ? _ShapeEditOperation.rotate
            : _ShapeEditOperation.resize;
        _shapeInteractionStartNorm = startNorm;
        _shapeInteractionLastNorm = startNorm;
        _shapeRotateSnappedAngleRad = null;
        _shapeRotateGestureStartAngleRad = handleHit == ShapeHandle.rotate
            ? gestureStartAngle
            : null;
        _shapeRotateGestureStartRotationRad = handleHit == ShapeHandle.rotate
            ? gestureStartRotation
            : null;
        _shapeCreateHasMoved = false;
        _shapeCreateThresholdNorm = 0.0;
      });
      return;
    }

    if (candidate != null && candidateBounds != null) {
      final manipulator = ShapeManipulator(
        boundsNorm: candidateBounds,
        rotationRad: 0.0,
      );
      if (manipulator.hitTestBody(startNorm)) {
        _safeSetState(() {
          _selectedShapeStrokeId = candidate!.id;
          _activeShapeManipulator = manipulator;
          _activeShapeHandle = ShapeHandle.none;
          _activeShapeEditOp = _ShapeEditOperation.translate;
          _shapeInteractionStartNorm = startNorm;
          _shapeInteractionLastNorm = startNorm;
          _shapeRotateSnappedAngleRad = null;
          _shapeRotateGestureStartAngleRad = null;
          _shapeRotateGestureStartRotationRad = null;
          _shapeCreateHasMoved = false;
          _shapeCreateThresholdNorm = 0.0;
        });
        return;
      }
    }

    _safeSetState(() {
      _activeShapeManipulator = ShapeManipulator(
        boundsNorm: Rect.fromLTWH(startNorm.dx, startNorm.dy, 0.0, 0.0),
      );
      _selectedShapeStrokeId = null;
      _activeShapeHandle = ShapeHandle.none;
      _activeShapeEditOp = _ShapeEditOperation.create;
      _shapeInteractionStartNorm = startNorm;
      _shapeInteractionLastNorm = startNorm;
      _shapeRotateSnappedAngleRad = null;
      _shapeRotateGestureStartAngleRad = null;
      _shapeRotateGestureStartRotationRad = null;
      _shapeCreateHasMoved = false;
      _shapeCreateThresholdNorm = 0.0;
    });
  }

  void _handleShapeStrokeInteractionUpdate({
    required int pointerId,
    required int pageNumber,
    required Size pageSize,
    required Offset norm,
    required StrokeStyle style,
  }) {
    if (_activeStylusPointerId != pointerId ||
        _activeShapeManipulator == null ||
        _shapeInteractionLastNorm == null) {
      return;
    }

    final manipulator = _activeShapeManipulator!;
    final last = _shapeInteractionLastNorm!;
    final delta = norm - last;

    _safeSetState(() {
      if (_activeShapeEditOp == _ShapeEditOperation.create) {
        final start = _shapeInteractionStartNorm ?? norm;
        final adjustedEnd = _constrainShapeCreateEndNorm(
          start,
          norm,
          pageSize: pageSize,
        );
        final bounds = Rect.fromPoints(start, adjustedEnd);
        manipulator.boundsNorm = Rect.fromLTRB(
          bounds.left.clamp(0.0, 1.0),
          bounds.top.clamp(0.0, 1.0),
          bounds.right.clamp(0.0, 1.0),
          bounds.bottom.clamp(0.0, 1.0),
        );
      } else {
        switch (_activeShapeEditOp) {
          case _ShapeEditOperation.translate:
            manipulator.translate(delta);
            break;
          case _ShapeEditOperation.resize:
            manipulator.resizeByHandle(_activeShapeHandle, delta);
            break;
          case _ShapeEditOperation.rotate:
            if (_isShapeRotateSnapEnabled) {
              _rotateShapeManipulatorWithSnap(
                manipulator,
                norm,
                pageSize: pageSize,
              );
            } else {
              _shapeRotateSnappedAngleRad = null;
              manipulator.rotationRad = _shapeRawRotateTargetAngle(
                manipulator,
                norm,
                pageSize: pageSize,
              );
            }
            break;
          default:
            break;
        }
      }
      _shapeInteractionLastNorm = norm;
      _activeShapeManipulator = manipulator;
      final start = _shapeInteractionStartNorm;
      if (!_shapeCreateHasMoved &&
          start != null &&
          (norm - start).distance > _shapeCreateThresholdNorm) {
        _shapeCreateHasMoved = true;
      }
    });
  }

  void _handleShapeStrokeInteractionEnd({
    required int pointerId,
    required int pageNumber,
    required Size pageSize,
    required Offset pageLocalNorm,
  }) {
    if (_activeStylusPointerId != pointerId) {
      return;
    }
    final manipulator = _activeShapeManipulator;
    if (manipulator == null) {
      this._clearShapeInteractionState();
      return;
    }

    if (_activeShapeEditOp == _ShapeEditOperation.create ||
        _activeShapeEditOp == _ShapeEditOperation.none) {
      final createBounds = manipulator.boundsNorm;
      final createStart = createBounds.topLeft;
      final createEnd = createBounds.bottomRight;
      final effectiveStart = createStart;
      final effectiveEnd = createEnd;
      final created = ShapeEngine.toStroke(
        _activeShapeType,
        pageNumber,
        effectiveStart,
        effectiveEnd,
        _activeShapeStrokeStyle,
        fillArgb: _currentShapeFillColor?.value,
      );
      _historyManager.execute(
        AddStrokeCommand(page: pageNumber, strokeSnapshot: created.deepCopy()),
        _canvasController,
      );
      _safeSetState(() {
        _selectedShapeStrokeId = created.id;
        _activeShapeManipulator = ShapeManipulator(
          boundsNorm:
              _shapeStrokeBounds(created.pointsNorm) ??
              Rect.fromLTWH(effectiveStart.dx, effectiveStart.dy, 0.0, 0.0),
          rotationRad: 0.0,
        );
        _activeShapeHandle = ShapeHandle.none;
        _activeShapeEditOp = _ShapeEditOperation.none;
        _shapeInteractionStartNorm = null;
        _shapeInteractionLastNorm = null;
        _shapeRotateSnappedAngleRad = null;
        _shapeRotateGestureStartAngleRad = null;
        _shapeRotateGestureStartRotationRad = null;
        _shapeCreateHasMoved = false;
        _shapeCreateThresholdNorm = 0.0;
      });
      _syncStrokesByPageFromControllerPage(pageNumber);
      _updateDrawingHistoryAvailabilityState();
      _requestPersistDrawing();
      return;
    }

    final selectedId = _selectedShapeStrokeId;
    if (selectedId == null) {
      this._clearShapeInteractionState();
      return;
    }
    final before = _canvasController.findStrokeById(pageNumber, selectedId);
    if (before == null) {
      this._clearShapeInteractionState();
      return;
    }
    final beforeBounds = _shapeStrokeBounds(before.pointsNorm);
    if (beforeBounds == null) {
      this._clearShapeInteractionState();
      return;
    }

    final afterPoints = _transformShapePointsByBounds(
      points: before.pointsNorm,
      fromBounds: beforeBounds,
      toBounds: manipulator.boundsNorm,
      rotationRad: manipulator.rotationRad,
      pageSize: pageSize,
    );
    final after = DrawingStroke(
      id: before.id,
      pageNumber: before.pageNumber,
      style: before.style,
      pointsNorm: afterPoints,
      toolType: before.toolType,
      opacity: before.opacity,
      isStraightened: before.isStraightened,
      penVariant: before.penVariant,
      highlighterVariant: before.highlighterVariant,
      shapeType: before.shapeType,
      shapeFillArgb: before.shapeFillArgb,
      erasedMaskVersion: before.erasedMaskVersion,
      erasedMask: before.erasedMask == null
          ? null
          : List<int>.from(before.erasedMask!),
      erasedSegments: before.erasedSegments == null
          ? null
          : List<dynamic>.from(before.erasedSegments!),
    );
    _historyManager.execute(
      ReplaceStrokeCommand(
        page: pageNumber,
        beforeSnapshot: before.deepCopy(),
        afterSnapshot: after,
      ),
      _canvasController,
    );
    _safeSetState(() {
      _activeShapeManipulator = manipulator;
      _activeShapeHandle = ShapeHandle.none;
      _activeShapeEditOp = _ShapeEditOperation.none;
      _shapeRotateSnappedAngleRad = null;
      _shapeRotateGestureStartAngleRad = null;
      _shapeRotateGestureStartRotationRad = null;
      _shapeInteractionStartNorm = null;
      _shapeInteractionLastNorm = null;
      _shapeCreateHasMoved = false;
      _shapeCreateThresholdNorm = 0.0;
    });
    _syncStrokesByPageFromControllerPage(pageNumber);
    _updateDrawingHistoryAvailabilityState();
    _requestPersistDrawing();
  }

  Offset _constrainShapeCreateEndNorm(
    Offset start,
    Offset current, {
    required Size pageSize,
  }) {
    if (!_isShapeAspectLocked) {
      return current;
    }
    final dx = current.dx - start.dx;
    final dy = current.dy - start.dy;
    if (dx.abs() < 1e-6 || dy.abs() < 1e-6) {
      return current;
    }
    final dxPx = dx * pageSize.width;
    final dyPx = dy * pageSize.height;
    final lockedPx = math.max(dxPx.abs(), dyPx.abs());
    final lockedDx = (lockedPx / pageSize.width) * (dx.isNegative ? -1.0 : 1.0);
    final lockedDy =
        (lockedPx / pageSize.height) * (dy.isNegative ? -1.0 : 1.0);
    final adjusted = Offset(start.dx + lockedDx, start.dy + lockedDy);
    return Offset(adjusted.dx.clamp(0.0, 1.0), adjusted.dy.clamp(0.0, 1.0));
  }

  void _rotateShapeManipulatorWithSnap(
    ShapeManipulator manipulator,
    Offset norm, {
    required Size pageSize,
  }) {
    final rawAngle = _shapeRawRotateTargetAngle(
      manipulator,
      norm,
      pageSize: pageSize,
    );
    const enterSnapDeg = 7.0;
    const exitSnapDeg = 11.0;
    final enterSnapRad = _degToRad(enterSnapDeg);
    final exitSnapRad = _degToRad(exitSnapDeg);

    final snapped = _shapeRotateSnappedAngleRad;
    if (snapped != null) {
      final diff = _wrapAngleDiff(rawAngle, snapped).abs();
      if (diff <= exitSnapRad) {
        manipulator.rotationRad = snapped;
        return;
      }
      _shapeRotateSnappedAngleRad = null;
    }

    final candidateAngles = <double>[];
    const divisions = 24; // 15-degree increments
    for (var i = 0; i < divisions; i += 1) {
      candidateAngles.add(-math.pi + (2 * math.pi * i / divisions));
    }

    var nearest = candidateAngles.first;
    var minDiff = _wrapAngleDiff(rawAngle, nearest).abs();
    for (final angle in candidateAngles.skip(1)) {
      final diff = _wrapAngleDiff(rawAngle, angle).abs();
      if (diff < minDiff) {
        minDiff = diff;
        nearest = angle;
      }
    }

    if (minDiff <= enterSnapRad) {
      _shapeRotateSnappedAngleRad = nearest;
      manipulator.rotationRad = nearest;
      return;
    }

    manipulator.rotationRad = rawAngle;
  }

  double _shapeRawRotateTargetAngle(
    ShapeManipulator manipulator,
    Offset norm, {
    required Size pageSize,
  }) {
    final center = manipulator.boundsNorm.center;
    final pointerAngle = _shapePointerAngleForPageSpace(
      centerNorm: center,
      pointerNorm: norm,
      pageSize: pageSize,
    );
    final gestureStartAngle = _shapeRotateGestureStartAngleRad;
    final gestureStartRotation = _shapeRotateGestureStartRotationRad;
    if (gestureStartAngle == null || gestureStartRotation == null) {
      return pointerAngle;
    }
    return gestureStartRotation +
        _wrapAngleDiff(pointerAngle, gestureStartAngle);
  }

  List<Offset> _transformShapePointsByBounds({
    required List<Offset> points,
    required Rect fromBounds,
    required Rect toBounds,
    required double rotationRad,
    required Size pageSize,
  }) {
    final fromWidth = fromBounds.width <= 0 ? 1.0 : fromBounds.width;
    final fromHeight = fromBounds.height <= 0 ? 1.0 : fromBounds.height;
    final toWidth = toBounds.width;
    final toHeight = toBounds.height;
    final toLeft = toBounds.left;
    final toTop = toBounds.top;
    final toCenter = toBounds.center;
    return points
        .map((point) {
          final ratioX = (point.dx - fromBounds.left) / fromWidth;
          final ratioY = (point.dy - fromBounds.top) / fromHeight;
          final scaled = Offset(
            toLeft + ratioX * toWidth,
            toTop + ratioY * toHeight,
          );
          final rotated = _rotateAroundCenterInPageSpace(
            point: scaled,
            center: toCenter,
            angleRad: rotationRad,
            pageSize: pageSize,
          );
          return Offset(rotated.dx.clamp(0.0, 1.0), rotated.dy.clamp(0.0, 1.0));
        })
        .toList(growable: false);
  }

  Offset _rotateAroundCenterInPageSpace({
    required Offset point,
    required Offset center,
    required double angleRad,
    required Size pageSize,
  }) {
    if (pageSize.width <= 0 || pageSize.height <= 0) {
      return point;
    }
    final pointPx = Offset(
      point.dx * pageSize.width,
      point.dy * pageSize.height,
    );
    final centerPx = Offset(
      center.dx * pageSize.width,
      center.dy * pageSize.height,
    );
    final cosA = math.cos(angleRad);
    final sinA = math.sin(angleRad);
    final dx = pointPx.dx - centerPx.dx;
    final dy = pointPx.dy - centerPx.dy;
    final rotatedPx = Offset(
      centerPx.dx + dx * cosA - dy * sinA,
      centerPx.dy + dx * sinA + dy * cosA,
    );
    return Offset(
      rotatedPx.dx / pageSize.width,
      rotatedPx.dy / pageSize.height,
    );
  }

  double _shapePointerAngleForPageSpace({
    required Offset centerNorm,
    required Offset pointerNorm,
    required Size pageSize,
  }) {
    final dx = (pointerNorm.dx - centerNorm.dx) * pageSize.width;
    final dy = (pointerNorm.dy - centerNorm.dy) * pageSize.height;
    if (dx.abs() < 1e-9 && dy.abs() < 1e-9) {
      return 0.0;
    }
    return math.atan2(dy, dx);
  }

  int? _createdIndexFromId(String id) {
    return int.tryParse(id);
  }

  Future<void> _handleOverlapSelection(List<MarkerHitResult> hits) async {
    if (hits.isEmpty || _isDetailDialogOpen) {
      return;
    }
    if (hits.length == 1) {
      _selectMarker(hits.first);
      return;
    }
    final ordered = _orderOverlapHits(hits);
    await _showOverlapSelectorSheet(ordered);
  }

  List<MarkerHitResult> _orderOverlapHits(List<MarkerHitResult> hits) {
    final items = hits
        .asMap()
        .entries
        .map(
          (entry) => (
            index: entry.key,
            createdIndex: entry.value.defect != null
                ? _createdIndexFromId(entry.value.defect!.id)
                : _createdIndexFromId(entry.value.equipment!.id),
            hit: entry.value,
          ),
        )
        .toList();
    final hasCreatedIndex = items.every((item) => item.createdIndex != null);
    if (hasCreatedIndex) {
      items.sort((a, b) => a.createdIndex!.compareTo(b.createdIndex!));
    } else {
      items.sort((a, b) => a.index.compareTo(b.index));
    }
    return items.map((item) => item.hit).toList();
  }

  String _overlapMarkerTitle(MarkerHitResult hit) {
    final defect = hit.defect;
    if (defect != null) {
      return defectPanelTitle(defect);
    }
    return equipmentPanelTitle(hit.equipment!, _site.equipmentMarkers);
  }

  Future<void> _showOverlapSelectorSheet(
    List<MarkerHitResult> orderedHits,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: orderedHits.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final hit = orderedHits[index];
              return ListTile(
                title: Text(
                  _overlapMarkerTitle(hit),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _selectMarker(hit);
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<Site?> _handleTapFlow({
    required MarkerHitResult? hitResult,
    required TapDecision decision,
    required int pageIndex,
    required double normalizedX,
    required double normalizedY,
  }) {
    return handleTapCore(
      context: context,
      hitResult: hitResult,
      decision: decision,
      pageIndex: pageIndex,
      normalizedX: normalizedX,
      normalizedY: normalizedY,
      site: _site,
      mode: _mode,
      activeCategory: _activeCategory,
      activeEquipmentCategory: _activeEquipmentCategory,
      onResetTapCanceled: () {
        _tapCanceled = false;
      },
      onSelectHit: _selectMarker,
      onClearSelection: _clearSelectionAndPopup,
      onShowDefectCategoryHint: _showSelectDefectCategoryHint,
      showDefectDetailsDialog: (_, defectId) =>
          _showDefectDetailsDialog(defectId: defectId),
      showEquipmentDetailsDialog: _showEquipmentDetailsDialog,
      showRebarSpacingDialog:
          (
            context, {
            required title,
            initialMemberType,
            initialMeasurements,
            allowMultiple = false,
            baseLabelIndex,
            labelPrefix,
          }) => _showRebarSpacingDialog(
            title: title,
            initialMemberType: initialMemberType,
            initialMeasurements: initialMeasurements,
            allowMultiple: allowMultiple,
            baseLabelIndex: baseLabelIndex,
            labelPrefix: labelPrefix,
          ),
      showSchmidtHammerDialog:
          (
            context, {
            required title,
            initialMemberType,
            initialAngleDeg,
            initialMaxValueText,
            initialMinValueText,
          }) => _showSchmidtHammerDialog(
            title: title,
            initialMemberType: initialMemberType,
            initialAngleDeg: initialAngleDeg,
            initialMaxValueText: initialMaxValueText,
            initialMinValueText: initialMinValueText,
          ),
      showCoreSamplingDialog:
          (context, {required title, initialMemberType, initialAvgValueText}) =>
              _showCoreSamplingDialog(
                title: title,
                initialMemberType: initialMemberType,
                initialAvgValueText: initialAvgValueText,
              ),
      showCarbonationDialog: _showCarbonationDialog,
      showStructuralTiltDialog: _showStructuralTiltDialog,
      showSettlementDialog:
          ({required baseTitle, required nextIndexByDirection}) =>
              _showSettlementDialog(
                baseTitle: baseTitle,
                nextIndexByDirection: nextIndexByDirection,
              ),
      showDeflectionDialog:
          ({
            required title,
            required memberOptions,
            initialMemberType,
            initialEndAText,
            initialMidBText,
            initialEndCText,
          }) => _showDeflectionDialog(
            title: title,
            initialMemberType: initialMemberType,
            initialEndAText: initialEndAText,
            initialMidBText: initialMidBText,
            initialEndCText: initialEndCText,
          ),
      deflectionMemberOptions: DrawingDeflectionMemberOptions,
      nextSettlementIndex: nextSettlementIndex,
    );
  }

  void _handlePointerDown(Offset position) {
    _pointerDownPosition = position;
    _tapCanceled = false;
  }

  void _handlePointerMove(Offset position) {
    if (_pointerDownPosition == null) {
      return;
    }
    final distance = (position - _pointerDownPosition!).distance;
    if (distance > DrawingTapSlop) {
      _tapCanceled = true;
    }
  }

  void _handlePointerUp() => _pointerDownPosition = null;

  void _handlePointerCancel() {
    _pointerDownPosition = null;
    _tapCanceled = false;
  }

  void _handlePdfNavigationScaleStart(ScaleStartDetails details) {
    if (!_isFreeDrawMode ||
        _isStylusActive ||
        _activeStylusPointerId != null ||
        _inProgressStroke != null ||
        _pendingDraw) {
      _cancelFreeDrawNavGesture();
      return;
    }
    _navStartPage = _currentPage;
    final controller = _photoControllerForPage(_navStartPage!);
    _navStartValue = controller.value;
    _navAccumDelta = Offset.zero;
    _debugNavUpdateLogCount = 0;
  }

  void _handlePdfNavigationScaleUpdate(ScaleUpdateDetails details) {
    if (!_isFreeDrawMode ||
        _isStylusActive ||
        _activeStylusPointerId != null ||
        _inProgressStroke != null ||
        _pendingDraw) {
      return;
    }
    if (_navStartPage == null || _navStartValue == null) {
      return;
    }
    final page = _navStartPage!;
    final controller = _photoControllerForPage(page);
    final start = _navStartValue!;
    _navAccumDelta += details.focalPointDelta;
    final double startScale = start.scale ?? 1.0;
    final bool isTwoFinger = details.pointerCount >= 2;
    final double desiredScale = isTwoFinger
        ? startScale * details.scale
        : startScale;
    final double minScale = _freeDrawMinScaleForPage(page);
    final double maxScale = _freeDrawMaxScaleForPage(page);
    final double effectiveScale;
    if (desiredScale < minScale) {
      final over = minScale - desiredScale;
      effectiveScale = minScale - (over * 0.15);
    } else if (desiredScale > maxScale) {
      final over = desiredScale - maxScale;
      effectiveScale = maxScale + (over * 0.15);
    } else {
      effectiveScale = desiredScale;
    }
    final double s = effectiveScale;
    final double panBoost = (s <= 1.0) ? 1.0 : (1.0 + (s - 1.0) * 0.35);
    final Offset desiredPos = start.position + (_navAccumDelta * panBoost);

    if (kDebugMode && _debugNavUpdateLogCount < 3) {
      _debugNavUpdateLogCount += 1;
      // ignore: avoid_print
      print(
        'NAV update page=$page pointers=${details.pointerCount} '
        'scale=$effectiveScale pos=$desiredPos',
      );
    }

    controller.value = PhotoViewControllerValue(
      position: desiredPos,
      rotation: start.rotation,
      scale: effectiveScale,
      rotationFocusPoint: start.rotationFocusPoint,
    );
  }

  void _handlePdfNavigationScaleEnd(ScaleEndDetails details) {
    _endFreeDrawNavigationGesture();
  }

  void _endFreeDrawNavigationGesture() {
    if (_isFreeDrawMode) {
      _snapFreeDrawScaleBackIfOutOfBounds(
        _navStartPage ?? _currentPage,
        start: _navStartValue,
      );
    }
    _cancelFreeDrawNavGesture();
  }

  void _cancelFreeDrawNavGesture() {
    _navStartPage = null;
    _navStartValue = null;
    _navAccumDelta = Offset.zero;
    _debugNavUpdateLogCount = 0;
  }

  double _resolveFreeDrawScale(dynamic value, {required double fallback}) {
    if (value is num) {
      return value.toDouble();
    }
    return fallback;
  }

  double _freeDrawMinScaleForPage(int pageNumber) {
    final minScale = _resolveFreeDrawScale(PdfDrawingMinScale, fallback: 1.0);
    if (!minScale.isFinite || minScale <= 0) {
      return 1.0;
    }
    return minScale;
  }

  double _freeDrawMaxScaleForPage(int pageNumber) {
    final minScale = _freeDrawMinScaleForPage(pageNumber);
    final maxScale = minScale * PdfDrawingMaxScaleMultiplier;
    if (!maxScale.isFinite || maxScale <= minScale) {
      return 5.0;
    }
    return maxScale;
  }

  double _freeDrawInitialScaleForPage(int pageNumber) {
    final minScale = _freeDrawMinScaleForPage(pageNumber);
    final initialScale = _resolveFreeDrawScale(
      PdfDrawingInitialScale,
      fallback: minScale,
    );
    if (!initialScale.isFinite || initialScale <= 0) {
      return minScale;
    }
    return initialScale;
  }

  void _snapFreeDrawScaleBackIfOutOfBounds(
    int pageNumber, {
    PhotoViewControllerValue? start,
  }) {
    final controller = _photoControllerForPage(pageNumber);
    final value = controller.value;
    final scale = value.scale ?? 1.0;
    final minScale = _freeDrawMinScaleForPage(pageNumber);
    final maxScale = _freeDrawMaxScaleForPage(pageNumber);
    if (scale >= minScale && scale <= maxScale) {
      return;
    }
    final snapshot = start ?? value;
    if (scale > maxScale) {
      controller.value = PhotoViewControllerValue(
        position: value.position,
        rotation: snapshot.rotation,
        scale: maxScale,
        rotationFocusPoint: snapshot.rotationFocusPoint,
      );
      return;
    }
    final snapScale = _freeDrawInitialScaleForPage(
      pageNumber,
    ).clamp(minScale, maxScale);
    controller.value = PhotoViewControllerValue(
      position: Offset.zero,
      rotation: snapshot.rotation,
      scale: snapScale,
      rotationFocusPoint: snapshot.rotationFocusPoint,
    );
  }

  void _debugLogPhotoViewBaseStateOnce(String tag) {
    if (!kDebugMode || !mounted || _isFreeDrawMode) {
      return;
    }
    final key = '$tag:$_currentPage';
    if (!_basePhotoViewDebugLogOnceKeys.add(key)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isFreeDrawMode) {
        return;
      }
      final controller = _photoControllerForPage(_currentPage);
      final v = controller.value;
      debugPrint(
        '[$tag] page=$_currentPage scale=${v.scale} '
        'pos=${v.position} rot=${v.rotation}',
      );
      debugPrint(
        '[$tag] bounds min=$PdfDrawingMinScale '
        'initial=$PdfDrawingInitialScale '
        'maxMul=$PdfDrawingMaxScaleMultiplier',
      );
    });
  }

  void _handleOverlayPointerDown(PointerDownEvent event) {
    if (!_isFreeDrawMode && event.kind == PointerDeviceKind.touch) {
      return;
    }
    final previousCount = _activePointerIds.length;
    final previousTouchCount = _activeTouchPointerCount;
    _activePointerIds.add(event.pointer);
    _activePointerKinds[event.pointer] = event.kind;
    if (!_isFreeDrawMode) {
      if (previousCount != _activePointerIds.length) {
        _safeSetState(() {});
      }
      return;
    }
    final touchCount = _activeTouchPointerCount;
    final bool becameTwoFingerTouch = previousTouchCount < 2 && touchCount >= 2;
    if (becameTwoFingerTouch) {
      if (_isFreeDrawConsumingOneFinger && _inProgressStroke != null) {
        _handleFreeDrawPointerEnd(
          _inProgressStroke?.pageNumber ?? _currentPage,
          pointerId: event.pointer,
        );
      }
      _safeSetState(() {
        _isFreeDrawConsumingOneFinger = false;
        _pendingDraw = false;
        _pendingDrawDownViewportLocal = null;
      });
      return;
    }
  }

  void _handleOverlayPointerDownWithStylusDrawing(
    PointerDownEvent event, {
    required int pageNumber,
    required Size pageSize,
    required OverlayToPageLocal drawingLocalToPageLocal,
    required double photoScale,
  }) {
    _handleOverlayPointerDown(event);

    if (!_isStylusKind(event.kind)) {
      return;
    }
    if (_activeTool == DrawingTool.shape) {
      if (!_isStrictStylusKind(event.kind)) {
        return;
      }
      _activeStylusPointerId = event.pointer;
      final pageLocal = drawingLocalToPageLocal(event.localPosition);
      if (pageLocal == null) {
        return;
      }
      final downNorm = _overlayToNormalizedPoint(
        overlayLocal: pageLocal,
        destSize: pageSize,
      );
      if (downNorm == null) {
        return;
      }
      this._handleShapeStrokeInteractionStart(
        pointerId: event.pointer,
        pageNumber: pageNumber,
        pageSize: pageSize,
        startNorm: downNorm,
        style: _activeShapeStrokeStyle,
      );
      return;
    }

    final activeToolKind = _activeToolKindForToolbar;
    final eraserMode = _activeTool == DrawingTool.strokeEraser
        ? DrawingTool.strokeEraser
        : DrawingTool.areaEraser;
    if (kDebugMode) {
      debugPrint('POINTER DOWN tool=$activeToolKind mode=$eraserMode');
    }

    if (activeToolKind == StrokeToolKind.eraser) {
      _handleEraserPointerDown(
        event,
        pageNumber: pageNumber,
        drawingLocalToPageLocal: drawingLocalToPageLocal,
      );
      return;
    }

    if (!_isFreeDrawMode || _activeStrokeStyle == null) return;

    _cancelFreeDrawNavGesture();
    _activeStylusPointerId = event.pointer;

    _safeSetState(() {
      _pendingDraw = true;
      _pendingDrawDownViewportLocal = event.localPosition;
    });
  }

  void _handleOverlayPointerMoveWithStylusDrawing(
    PointerMoveEvent event, {
    required int pageNumber,
    required Size pageSize,
    required OverlayToPageLocal drawingLocalToPageLocal,
    required double photoScale,
  }) {
    if (_activeTool == DrawingTool.shape) {
      if (_activeStylusPointerId == null ||
          event.pointer != _activeStylusPointerId ||
          !_isStrictStylusKind(event.kind)) {
        return;
      }
      final pageLocal = drawingLocalToPageLocal(event.localPosition);
      if (pageLocal == null) {
        return;
      }
      final norm = _overlayToNormalizedPoint(
        overlayLocal: pageLocal,
        destSize: pageSize,
      );
      if (norm == null) {
        return;
      }
      this._handleShapeStrokeInteractionUpdate(
        pointerId: event.pointer,
        pageNumber: pageNumber,
        pageSize: pageSize,
        norm: norm,
        style: _activeShapeStrokeStyle,
      );
      return;
    }

    if (event.kind == PointerDeviceKind.touch) {
      return;
    }

    if (!_isFreeDrawMode) {
      return;
    }

    if (!_isStylusKind(event.kind)) {
      return;
    }

    if (_activeToolKindForToolbar == StrokeToolKind.eraser) {
      _handleEraserPointerMove(
        event,
        pageNumber: pageNumber,
        pageSize: pageSize,
        drawingLocalToPageLocal: drawingLocalToPageLocal,
      );
      return;
    }

    if (_activeStrokeStyle == null) {
      if (_isFreeDrawConsumingOneFinger && _inProgressStroke != null) {
        _handleFreeDrawPointerEnd(
          _inProgressStroke?.pageNumber ?? _currentPage,
          pointerId: event.pointer,
        );
      }
      _safeSetState(() {
        _isFreeDrawConsumingOneFinger = false;
        _pendingDraw = false;
        _pendingDrawDownViewportLocal = null;
        _activeStylusPointerId = null;
      });
      return;
    }

    if (_activeStylusPointerId == null ||
        event.pointer != _activeStylusPointerId ||
        !_isStylusKind(event.kind)) {
      return;
    }

    final pendingDown = _pendingDrawDownViewportLocal;
    if (pendingDown == null) {
      _safeSetState(() {
        _pendingDraw = true;
        _pendingDrawDownViewportLocal = event.localPosition;
      });
      return;
    }

    if (!_isFreeDrawConsumingOneFinger && _pendingDraw) {
      final distance = (event.localPosition - pendingDown).distance;
      if (distance < _DrawingScreenState._kDrawStartSlopPx) return;

      final downPageLocal = drawingLocalToPageLocal(pendingDown);
      if (downPageLocal == null) {
        _safeSetState(() {
          _pendingDraw = false;
          _pendingDrawDownViewportLocal = null;
          _activeStylusPointerId = null;
        });
        return;
      }

      final downNorm = _overlayToNormalizedPoint(
        overlayLocal: downPageLocal,
        destSize: pageSize,
      );
      if (downNorm == null) {
        _safeSetState(() {
          _pendingDraw = false;
          _pendingDrawDownViewportLocal = null;
          _activeStylusPointerId = null;
        });
        return;
      }

      _safeSetState(() {
        _isFreeDrawConsumingOneFinger = true;
        _pendingDraw = false;
      });
      _handleFreeDrawPointerStart(downNorm, pageNumber);
    }

    if (!_isFreeDrawConsumingOneFinger) return;

    final inProgressStroke = _inProgressStroke;
    if (inProgressStroke == null || inProgressStroke.pointsNorm.isEmpty) return;

    final pageLocal = drawingLocalToPageLocal(event.localPosition);
    if (pageLocal == null) {
      return;
    }

    final norm = _overlayToNormalizedPoint(
      overlayLocal: pageLocal,
      destSize: pageSize,
    );
    if (norm == null) {
      return;
    }

    _queueFreeDrawMove(
      pointerId: event.pointer,
      pageNumber: pageNumber,
      pageSize: pageSize,
      normalized: norm,
      photoScale: photoScale,
    );
  }

  void _handleOverlayPointerUpOrCancelWithStylusDrawing(
    PointerEvent event, {
    required int pageNumber,
    required Size pageSize,
    required OverlayToPageLocal drawingLocalToPageLocal,
  }) {
    if (_activeTool == DrawingTool.shape &&
        (event is PointerUpEvent || event is PointerCancelEvent)) {
      final wasShapeStylus = _activeStylusPointerId == event.pointer;
      if (!wasShapeStylus) {
        return;
      }
      final pageLocal = drawingLocalToPageLocal(event.localPosition);
      if (pageLocal != null) {
        final norm = _overlayToNormalizedPoint(
          overlayLocal: pageLocal,
          destSize: pageSize,
        );
        if (norm != null) {
          this._handleShapeStrokeInteractionEnd(
            pointerId: event.pointer,
            pageNumber: pageNumber,
            pageSize: pageSize,
            pageLocalNorm: norm,
          );
        }
      } else {
        this._clearShapeInteractionState();
      }
      _shapeCreateHasMoved = false;
      return;
    }

    final wasStylus = _activeStylusPointerId == event.pointer;
    final wasAreaSession = _activeAreaEraserPointerId == event.pointer;
    if (wasStylus) {
      _flushPendingFreeDrawMove();
    }

    _handleOverlayPointerUpOrCancel(event);

    if (!_isFreeDrawMode) {
      return;
    }

    if (_activeToolKindForToolbar == StrokeToolKind.eraser) {
      _handleEraserPointerUpOrCancel(
        event,
        pageNumber: pageNumber,
        pageSize: pageSize,
        drawingLocalToPageLocal: drawingLocalToPageLocal,
        wasStylus: wasStylus,
        wasAreaSession: wasAreaSession,
      );
      return;
    }

    if (wasStylus) {
      _flushPendingFreeDrawMove();
      if (_isFreeDrawConsumingOneFinger) {
        _handleFreeDrawPointerEnd(pageNumber, pointerId: event.pointer);
      }
      _safeSetState(() {
        _isFreeDrawConsumingOneFinger = false;
        _pendingDraw = false;
        _pendingDrawDownViewportLocal = null;
        _activeStylusPointerId = null;
      });
      _resetFreeDrawMoveCoalescing();
    }
  }

  void _handleEraserPointerDown(
    PointerDownEvent event, {
    required int pageNumber,
    required OverlayToPageLocal drawingLocalToPageLocal,
  }) {
    if (!_isFreeDrawMode) {
      return;
    }
    if (_activeTool == DrawingTool.strokeEraser) {
      if (kDebugMode) {
        debugPrint('[Eraser] down mode=stroke');
      }
      _cancelFreeDrawNavGesture();
      _activeStylusPointerId = event.pointer;
      _safeSetState(() {
        _activeStrokeEraserPointerId = event.pointer;
        _erasedStrokeIdsThisDrag.clear();
        _erasedStrokeCountThisDrag = 0;
      });
      return;
    }
    if (kDebugMode) {
      debugPrint('[Eraser] down mode=area');
    }
    _cancelFreeDrawNavGesture();
    final pageLocal = drawingLocalToPageLocal(event.localPosition);
    if (pageLocal == null) {
      return;
    }
    _safeSetState(() {
      _eraserCursorPageNumber = pageNumber;
      _eraserCursorPageLocal = pageLocal;
      _canvasController.setEraserCursor(
        _currentPage == pageNumber ? pageLocal : null,
      );
      _startAreaEraserSession(event.pointer);
    });
  }

  void _handleEraserPointerMove(
    PointerMoveEvent event, {
    required int pageNumber,
    required Size pageSize,
    required OverlayToPageLocal drawingLocalToPageLocal,
  }) {
    const double kStrokeEraserHitRadiusPx = 10.0;
    if (_activeTool == DrawingTool.strokeEraser) {
      if (_activeStrokeEraserPointerId != event.pointer) {
        return;
      }
      final pageLocal = drawingLocalToPageLocal(event.localPosition);
      if (pageLocal == null) {
        return;
      }
      final radiusPagePx = _viewportDistanceToPageDistance(
        viewportLocal: event.localPosition,
        viewportDistancePx: kStrokeEraserHitRadiusPx,
        drawingLocalToPageLocal: drawingLocalToPageLocal,
      );
      final closestResult = _findClosestStrokeAtPageLocal(
        pageNumber: pageNumber,
        pageLocal: pageLocal,
        pageSize: pageSize,
        queryRadiusPx: math.max(
          radiusPagePx,
          _strokeEraserBaseThresholdForPage(
            strokes: _strokesByPage[pageNumber],
            pageSize: pageSize,
          ),
        ),
      );
      if (closestResult == null ||
          closestResult.distanceSquared > radiusPagePx * radiusPagePx ||
          _erasedStrokeIdsThisDrag.contains(closestResult.stroke.id)) {
        return;
      }
      _safeSetState(() {
        _erasedStrokeIdsThisDrag.add(closestResult.stroke.id);
        _erasedStrokeCountThisDrag += 1;
        _removeStrokeWithUndoSnapshot(closestResult.stroke);
      });
      return;
    }
    if (_activeAreaEraserPointerId != event.pointer) {
      return;
    }
    final pageLocal = drawingLocalToPageLocal(event.localPosition);
    if (pageLocal == null) {
      return;
    }
    final rightOffset = drawingLocalToPageLocal(
      event.localPosition + Offset(_areaEraserRadiusPx, 0),
    );
    final leftOffset = drawingLocalToPageLocal(
      event.localPosition - Offset(_areaEraserRadiusPx, 0),
    );
    final radiusPagePx = (rightOffset != null)
        ? (rightOffset - pageLocal).distance
        : (leftOffset != null)
        ? (leftOffset - pageLocal).distance
        : _areaEraserRadiusPx;
    _queueAreaEraserMove(
      pageNumber: pageNumber,
      pageSize: pageSize,
      pageLocal: pageLocal,
      radiusPagePx: radiusPagePx,
    );
  }

  void _handleEraserPointerUpOrCancel(
    PointerEvent event, {
    required int pageNumber,
    required Size pageSize,
    required OverlayToPageLocal drawingLocalToPageLocal,
    required bool wasStylus,
    required bool wasAreaSession,
  }) {
    if (_activeTool == DrawingTool.areaEraser && wasAreaSession) {
      if (kDebugMode) {
        debugPrint('[Eraser] up mode=area');
      }
      _flushPendingAreaEraserMove();
      _safeSetState(() {
        _eraserCursorPageLocal = null;
        _eraserCursorPageNumber = null;
        _canvasController.setEraserCursor(null);
        _canvasController.setEraserPreview(null);
      });
      _commitAreaEraserSession();
      return;
    }

    if (_activeTool == DrawingTool.strokeEraser && wasStylus) {
      if (kDebugMode) {
        debugPrint(
          '[Eraser] up mode=stroke removed=$_erasedStrokeCountThisDrag',
        );
      }
      _safeSetState(() {
        _activeStrokeEraserPointerId = null;
        _erasedStrokeIdsThisDrag.clear();
        _erasedStrokeCountThisDrag = 0;
        _activeStylusPointerId = null;
      });
    }
  }

  List<Offset> _interpolateNormalizedPoints({
    required Offset from,
    required Offset to,
    required Size pageSize,
    required double photoScale,
  }) {
    const double targetSpacingPx = 1.2;

    final s = (photoScale <= 0) ? 1.0 : photoScale;
    final double spacingNorm = (targetSpacingPx / s) / pageSize.shortestSide;

    final double dist = (to - from).distance;
    if (dist <= spacingNorm) return <Offset>[to];

    final int steps = (dist / spacingNorm).ceil().clamp(1, 24);

    final List<Offset> out = <Offset>[];
    for (int i = 1; i <= steps; i++) {
      final double t = i / steps;
      out.add(
        Offset(
          from.dx + (to.dx - from.dx) * t,
          from.dy + (to.dy - from.dy) * t,
        ),
      );
    }
    return out;
  }

  void _handleOverlayPointerUpOrCancel(PointerEvent event) {
    if (!_isFreeDrawMode && event.kind == PointerDeviceKind.touch) {
      return;
    }
    final didRemove = _activePointerIds.remove(event.pointer);
    if (!didRemove) {
      return;
    }
    _activePointerKinds.remove(event.pointer);
    if (_activeStylusPointerId == event.pointer) {
      _activeStylusPointerId = null;
    }
    _straightenSnappedAngleByPointer.remove(event.pointer);
    _straightenStartPageByPointer.remove(event.pointer);
    _pendingStraightenCommitByPointer.remove(event.pointer);
    if (_isFreeDrawMode) {
      if (_activePointerIds.isEmpty && _inProgressStroke != null) {
        _handleFreeDrawPointerEnd(
          _inProgressStroke?.pageNumber ?? _currentPage,
          pointerId: event.pointer,
        );
      }
      _safeSetState(() {});
      return;
    }
    _safeSetState(() {});
  }

  void _handleDrawingToolChanged(DrawingTool tool) {
    if (_activeTool == tool) {
      return;
    }
    if (_activeTool == DrawingTool.areaEraser) {
      _resetAreaEraserMoveCoalescing();
    }
    if (_activeTool == DrawingTool.pen) {
      _resetFreeDrawMoveCoalescing();
    }
    _safeSetState(() {
      _activeTool = tool;
      if (tool == DrawingTool.shape) {
        _loadShapeType(_activeShapeType);
      }
      _eraserCursorPageLocal = null;
      _eraserCursorPageNumber = null;
      _canvasController.setEraserCursor(null);
      _canvasController.setEraserPreview(null);
      _activeAreaEraserPointerId = null;
      _activeAreaEraserSession = null;
      _activeStrokeEraserPointerId = null;
      _erasedStrokeIdsThisDrag.clear();
      _erasedStrokeCountThisDrag = 0;
      _pendingDraw = false;
      _pendingDrawDownViewportLocal = null;
    });
    if (kDebugMode) {
      debugPrint('[Eraser] modeChanged next=$tool');
    }
  }

  void _deactivateActiveFreeDrawTool() {
    if (_inProgressStroke != null) {
      _handleFreeDrawEnd(_inProgressStroke?.pageNumber ?? _currentPage);
    }
    _clearShapeSelection();
    _safeSetState(() {
      _activeTool = DrawingTool.pen;
      _activePresetIndex = null;
      _isFreeDrawConsumingOneFinger = false;
      _pendingDraw = false;
      _pendingDrawDownViewportLocal = null;
      _activeStylusPointerId = null;
      _eraserCursorPageLocal = null;
      _eraserCursorPageNumber = null;
      _canvasController.setEraserCursor(null);
      _canvasController.setEraserPreview(null);
      _activeAreaEraserPointerId = null;
      _activeAreaEraserSession = null;
      _activeStrokeEraserPointerId = null;
      _erasedStrokeIdsThisDrag.clear();
      _erasedStrokeCountThisDrag = 0;
    });
  }

  void _handleAreaEraserRadiusChanged(double value) {
    final nextRadius = value.clamp(
      _DrawingScreenState._kMinAreaEraserRadiusPx,
      _DrawingScreenState._kMaxAreaEraserRadiusPx,
    );
    _safeSetState(() {
      _areaEraserRadiusPx = nextRadius;
      final session = _activeAreaEraserSession;
      if (session != null) {
        _activeAreaEraserSession = session.copyWith(
          radius: _areaEraserRadiusPx,
        );
      }
    });
    if (kDebugMode) {
      debugPrint('[Eraser] radiusChanged px=${nextRadius.toStringAsFixed(1)}');
    }
  }

  bool get _isAreaEraserActive =>
      _isFreeDrawMode && _activeTool == DrawingTool.areaEraser;

  bool get _isStrokeEraserActive =>
      _isFreeDrawMode && _activeTool == DrawingTool.strokeEraser;

  double _strokeEraserBaseThresholdForPage({
    required List<DrawingStroke>? strokes,
    required Size pageSize,
  }) {
    final pageShortest = pageSize.shortestSide <= 0
        ? 1.0
        : pageSize.shortestSide;
    var maxStrokeWidthNorm = 0.0;
    for (final stroke in strokes ?? const <DrawingStroke>[]) {
      final widthNorm = stroke.style.widthPx / pageShortest;
      if (widthNorm > maxStrokeWidthNorm) {
        maxStrokeWidthNorm = widthNorm;
      }
    }
    const widthFactor = 1.6;
    return math.max(6.0, maxStrokeWidthNorm * pageShortest * widthFactor);
  }

  double _viewportDistanceToPageDistance({
    required Offset viewportLocal,
    required double viewportDistancePx,
    required OverlayToPageLocal drawingLocalToPageLocal,
  }) {
    final center = drawingLocalToPageLocal(viewportLocal);
    if (center == null) {
      return viewportDistancePx;
    }
    final right = drawingLocalToPageLocal(
      viewportLocal + Offset(viewportDistancePx, 0),
    );
    if (right != null) {
      return (right - center).distance;
    }
    final left = drawingLocalToPageLocal(
      viewportLocal - Offset(viewportDistancePx, 0),
    );
    if (left != null) {
      return (left - center).distance;
    }
    return viewportDistancePx;
  }

  ({DrawingStroke stroke, double distanceSquared})?
  _findClosestStrokeAtPageLocal({
    required int pageNumber,
    required Offset pageLocal,
    required Size pageSize,
    required double queryRadiusPx,
  }) {
    if (pageSize.isEmpty) {
      return null;
    }

    final strokes = _strokesByPage[pageNumber];
    if (strokes == null || strokes.isEmpty) {
      return null;
    }

    final spatialIndex = _strokeSpatialIndexByPage.putIfAbsent(
      pageNumber,
      () => SpatialIndex(),
    );
    final lastPageSize = _strokeSpatialIndexPageSizeByPage[pageNumber];
    if (_strokeSpatialIndexDirtyPages.contains(pageNumber) ||
        lastPageSize == null ||
        lastPageSize != pageSize) {
      spatialIndex
        ..setPageSize(pageSize)
        ..clear();
      for (final stroke in strokes) {
        spatialIndex.insertStroke(stroke);
      }
      _strokeSpatialIndexPageSizeByPage[pageNumber] = pageSize;
      _strokeSpatialIndexDirtyPages.remove(pageNumber);
    }

    final candidateIds = spatialIndex.queryNear(pageLocal, queryRadiusPx);
    if (candidateIds.isEmpty) {
      return null;
    }

    DrawingStroke? closest;
    var minDistanceSquared = double.infinity;
    for (final candidateId in candidateIds) {
      final stroke = _canvasController.findStrokeById(pageNumber, candidateId);
      if (stroke == null) {
        continue;
      }
      final distanceSquared = _minDistanceSquaredToStrokePolylinePx(
        stroke: stroke,
        centerPx: pageLocal,
        pageSize: pageSize,
      );
      if (distanceSquared < minDistanceSquared ||
          (distanceSquared == minDistanceSquared &&
              closest != null &&
              stroke.id.compareTo(closest.id) < 0)) {
        closest = stroke;
        minDistanceSquared = distanceSquared;
      }
    }

    if (closest == null) {
      return null;
    }
    return (stroke: closest, distanceSquared: minDistanceSquared);
  }

  double _minDistanceSquaredToStrokePolylinePx({
    required DrawingStroke stroke,
    required Offset centerPx,
    required Size pageSize,
  }) {
    final points = stroke.pointsNorm;
    if (points.isEmpty) {
      return double.infinity;
    }

    final erasedMask = stroke.ensureErasedMask();
    final pageWidth = pageSize.width;
    final pageHeight = pageSize.height;
    var minDistanceSquared = double.infinity;

    for (var i = 0; i < points.length; i += 1) {
      if (erasedMask[i] != 0) {
        continue;
      }

      final pointPx = Offset(
        points[i].dx * pageWidth,
        points[i].dy * pageHeight,
      );
      final pointDelta = pointPx - centerPx;
      final pointDistanceSquared =
          (pointDelta.dx * pointDelta.dx) + (pointDelta.dy * pointDelta.dy);
      if (pointDistanceSquared < minDistanceSquared) {
        minDistanceSquared = pointDistanceSquared;
      }

      if (i == 0 || erasedMask[i - 1] != 0) {
        continue;
      }
      final prev = points[i - 1];
      final p1 = Offset(prev.dx * pageWidth, prev.dy * pageHeight);
      final distanceSquared = _distanceSquaredToSegment(centerPx, p1, pointPx);
      if (distanceSquared < minDistanceSquared) {
        minDistanceSquared = distanceSquared;
      }
    }

    return minDistanceSquared;
  }

  double _distanceSquaredToSegment(Offset point, Offset start, Offset end) {
    final segment = end - start;
    final segmentLengthSquared =
        (segment.dx * segment.dx) + (segment.dy * segment.dy);
    if (segmentLengthSquared <= 0) {
      final delta = point - start;
      return (delta.dx * delta.dx) + (delta.dy * delta.dy);
    }
    final projection =
        ((point.dx - start.dx) * segment.dx +
            (point.dy - start.dy) * segment.dy) /
        segmentLengthSquared;
    final t = projection.clamp(0.0, 1.0);
    final nearest = Offset(
      start.dx + segment.dx * t,
      start.dy + segment.dy * t,
    );
    final delta = point - nearest;
    return (delta.dx * delta.dx) + (delta.dy * delta.dy);
  }

  void _removeStrokeWithUndoSnapshot(DrawingStroke stroke) {
    final existing = _canvasController.findStrokeById(
      stroke.pageNumber,
      stroke.id,
    );
    if (existing == null) {
      return;
    }
    final deletedStrokeSnapshot = existing.deepCopy();
    _historyManager.execute(
      DeleteStrokeCommand(
        page: existing.pageNumber,
        deletedSnapshot: deletedStrokeSnapshot,
      ),
      _canvasController,
    );
    _syncStrokesByPageFromControllerPage(existing.pageNumber);
    _updateDrawingHistoryAvailabilityState();
    _requestPersistDrawing();
  }

  void _publishAreaEraserPreview({
    required int pageNumber,
    required Offset pageLocal,
    required double radiusPagePx,
    required _AreaEraserSession session,
  }) {
    final baseStrokes = _canvasController.getStrokes(pageNumber);
    final previewStrokes = baseStrokes
        .map((stroke) => session.addedById[stroke.id] ?? stroke)
        .toList(growable: false);

    _canvasController.setEraserPreview(
      EraserPreview(
        page: pageNumber,
        previewStrokes: previewStrokes,
        virtualStrokesToRender: session.addedById.values
            .map((stroke) => stroke.deepCopy())
            .toList(growable: false),
        hiddenStrokeIds: const <String>{},
        strokesToMask: session.removedById.values
            .map((stroke) => stroke.deepCopy())
            .toList(growable: false),
        cursor: _currentPage == pageNumber ? pageLocal : null,
        radius: radiusPagePx,
      ),
    );
  }

  void _startAreaEraserSession(int pointer) {
    _activeAreaEraserPointerId = pointer;
    _activeAreaEraserSession = _AreaEraserSession(radius: _areaEraserRadiusPx);
    _areaEraserPath.clear();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _canvasController.setEraserPreview(null);
    });
    _resetAreaEraserMoveCoalescing();
  }

  void _queueAreaEraserMove({
    required int pageNumber,
    required Size pageSize,
    required Offset pageLocal,
    required double radiusPagePx,
  }) {
    _pendingAreaEraserMove = _PendingAreaEraserMove(
      pageNumber: pageNumber,
      pageSize: pageSize,
      pageLocal: pageLocal,
      radiusPagePx: radiusPagePx,
    );
    if (_isAreaEraserFrameScheduled) {
      return;
    }
    _isAreaEraserFrameScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _isAreaEraserFrameScheduled = false;
      _flushPendingAreaEraserMove();
    });
  }

  void _flushPendingAreaEraserMove() {
    final pending = _pendingAreaEraserMove;
    if (pending == null) {
      return;
    }
    _pendingAreaEraserMove = null;

    final session = _activeAreaEraserSession;
    if (session == null) {
      return;
    }

    final updatedSession = _applyAreaEraserPointMask(
      session.copyWith(radius: pending.radiusPagePx),
      pageNumber: pending.pageNumber,
      pageSize: pending.pageSize,
      center: pending.pageLocal,
      radiusPagePx: pending.radiusPagePx,
    );
    _activeAreaEraserSession = updatedSession;

    _areaEraserPath.add(pending);
    _safeSetState(() {
      _eraserCursorPageNumber = pending.pageNumber;
      _eraserCursorPageLocal = pending.pageLocal;
      _canvasController.setEraserCursor(
        _currentPage == pending.pageNumber ? pending.pageLocal : null,
      );
      _publishAreaEraserPreview(
        pageNumber: pending.pageNumber,
        pageLocal: pending.pageLocal,
        radiusPagePx: pending.radiusPagePx,
        session: updatedSession,
      );
    });
  }

  void _resetAreaEraserMoveCoalescing() {
    _pendingAreaEraserMove = null;
    _isAreaEraserFrameScheduled = false;
  }

  void _commitAreaEraserSession() {
    final session = _activeAreaEraserSession;
    if (session != null && session.addedById.isNotEmpty) {
      final itemsByPage = <int, List<BatchEraseCommandItem>>{};
      var totalMaskedDelta = 0;
      for (final entry in session.addedById.entries) {
        final updated = entry.value;
        final previous = session.removedById[entry.key];
        if (previous == null) {
          continue;
        }
        final previousMask = previous.erasedMaskAsBool();
        final nextMask = updated.erasedMaskAsBool();
        if (listEquals(previousMask, nextMask)) {
          continue;
        }
        final pageItems = itemsByPage.putIfAbsent(
          updated.pageNumber,
          () => <BatchEraseCommandItem>[],
        );
        pageItems.add(
          BatchEraseCommandItem(
            strokeId: updated.id,
            beforeMask: previousMask,
            afterMask: nextMask,
          ),
        );
        totalMaskedDelta +=
            _countMaskedTrue(nextMask) - _countMaskedTrue(previousMask);
      }

      for (final entry in itemsByPage.entries) {
        final page = entry.key;
        final items = entry.value;
        if (items.isEmpty) {
          continue;
        }
        _historyManager.execute(
          BatchEraseCommand(page: page, items: items),
          _canvasController,
        );
        _syncStrokesByPageFromControllerPage(page);
        if (kDebugMode) {
          debugPrint(
            '[Drawing] eraserCommit page=$page candidates=${items.length} '
            'maskedDelta=$totalMaskedDelta tick=${_canvasController.cacheRebuildTick.value}',
          );
        }
      }
      if (itemsByPage.isNotEmpty) {
        _updateDrawingHistoryAvailabilityState();
        _requestPersistDrawing();
      }
    }
    _activeAreaEraserPointerId = null;
    _activeAreaEraserSession = null;
    _areaEraserPath.clear();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _canvasController.setEraserPreview(null);
    });
    _resetAreaEraserMoveCoalescing();
  }

  int _countMaskedTrue(List<bool> mask) {
    var count = 0;
    for (final value in mask) {
      if (value) {
        count += 1;
      }
    }
    return count;
  }

  _AreaEraserSession _applyAreaEraserPointMask(
    _AreaEraserSession session, {
    required int pageNumber,
    required Size pageSize,
    required Offset center,
    required double radiusPagePx,
  }) {
    if (pageSize.isEmpty) {
      return session;
    }

    final candidateIds = _queryStrokeCandidateIds(
      pageNumber: pageNumber,
      pageSize: pageSize,
      pageLocal: center,
      queryRadiusPx: radiusPagePx,
    ).toList(growable: false)..sort();
    if (candidateIds.isEmpty) {
      return session;
    }

    final removedById = Map<String, DrawingStroke>.from(session.removedById);
    final addedById = Map<String, DrawingStroke>.from(session.addedById);
    final removedStrokeIds = Set<String>.from(session.removedStrokeIds);
    final processedStrokeIds = Set<String>.from(session.processedStrokeIds);
    final radiusSq = radiusPagePx * radiusPagePx;

    for (final candidateId in candidateIds) {
      final sourceStroke =
          addedById[candidateId] ??
          _canvasController.findStrokeById(pageNumber, candidateId);
      if (sourceStroke == null) {
        continue;
      }

      final nextMask = sourceStroke.ensureErasedMask();
      var changed = false;
      for (var i = 0; i < sourceStroke.pointsNorm.length; i += 1) {
        if (nextMask[i] != 0) {
          continue;
        }
        final norm = sourceStroke.pointsNorm[i];
        final dx = norm.dx * pageSize.width - center.dx;
        final dy = norm.dy * pageSize.height - center.dy;
        final distanceSquared = (dx * dx) + (dy * dy);
        if (distanceSquared <= radiusSq) {
          nextMask[i] = 1;
          changed = true;
        }
      }
      if (!changed) {
        continue;
      }

      final originalStroke = _canvasController.findStrokeById(
        pageNumber,
        candidateId,
      );
      if (originalStroke != null) {
        removedById.putIfAbsent(candidateId, originalStroke.deepCopy);
      }
      addedById[candidateId] = DrawingStroke(
        id: sourceStroke.id,
        pageNumber: sourceStroke.pageNumber,
        style: sourceStroke.style,
        pointsNorm: List<Offset>.from(sourceStroke.pointsNorm),
        toolType: sourceStroke.toolType,
        opacity: sourceStroke.opacity,
        isStraightened: sourceStroke.isStraightened,
        penVariant: sourceStroke.penVariant,
        highlighterVariant: sourceStroke.highlighterVariant,
        erasedMaskVersion: (sourceStroke.erasedMaskVersion ?? 0) + 1,
        erasedMask: nextMask,
        erasedSegments: sourceStroke.erasedSegments == null
            ? null
            : List<dynamic>.from(sourceStroke.erasedSegments!),
      );
      removedStrokeIds.add(candidateId);
      processedStrokeIds.add(candidateId);
    }

    return session.copyWith(
      removedStrokeIds: removedStrokeIds,
      processedStrokeIds: processedStrokeIds,
      removedById: removedById,
      addedById: addedById,
    );
  }

  Set<String> _queryStrokeCandidateIds({
    required int pageNumber,
    required Size pageSize,
    required Offset pageLocal,
    required double queryRadiusPx,
  }) {
    final strokes = _strokesByPage[pageNumber];
    if (strokes == null || strokes.isEmpty) {
      return <String>{};
    }
    final spatialIndex = _strokeSpatialIndexByPage.putIfAbsent(
      pageNumber,
      () => SpatialIndex(),
    );
    final lastPageSize = _strokeSpatialIndexPageSizeByPage[pageNumber];
    if (_strokeSpatialIndexDirtyPages.contains(pageNumber) ||
        lastPageSize == null ||
        lastPageSize != pageSize) {
      spatialIndex
        ..setPageSize(pageSize)
        ..clear();
      for (final stroke in strokes) {
        spatialIndex.insertStroke(stroke);
      }
      _strokeSpatialIndexPageSizeByPage[pageNumber] = pageSize;
      _strokeSpatialIndexDirtyPages.remove(pageNumber);
    }
    return spatialIndex.queryNear(pageLocal, queryRadiusPx);
  }

  void _queueFreeDrawMove({
    required int pointerId,
    required int pageNumber,
    required Size pageSize,
    required Offset normalized,
    required double photoScale,
  }) {
    _pendingFreeDrawMove = _PendingFreeDrawMove(
      pointerId: pointerId,
      pageNumber: pageNumber,
      pageSize: pageSize,
      normalized: normalized,
      photoScale: photoScale,
    );
    if (_isFreeDrawMoveScheduled) {
      return;
    }
    _isFreeDrawMoveScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _isFreeDrawMoveScheduled = false;
      _flushPendingFreeDrawMove();
    });
  }

  void _flushPendingFreeDrawMove() {
    final pending = _pendingFreeDrawMove;
    if (pending == null) {
      return;
    }
    _pendingFreeDrawMove = null;
    _recordFreeDrawPerfCall();
    _handleFreeDrawPointerUpdate(
      pending.normalized,
      pending.pageNumber,
      pending.pageSize,
      pointerId: pending.pointerId,
      photoScale: pending.photoScale,
      shouldInterpolateFromLastPoint: true,
    );
    if (_pendingFreeDrawMove != null && !_isFreeDrawMoveScheduled) {
      _isFreeDrawMoveScheduled = true;
      SchedulerBinding.instance.scheduleFrameCallback((_) {
        _isFreeDrawMoveScheduled = false;
        _flushPendingFreeDrawMove();
      });
    }
  }

  void _resetFreeDrawMoveCoalescing() {
    _pendingFreeDrawMove = null;
    _isFreeDrawMoveScheduled = false;
  }

  void _handleFreeDrawPointerStart(Offset normalized, int pageNumber) {
    final style = _activeStrokeStyle;
    if (!_isFreeDrawMode || _activePointerIds.length >= 2 || style == null) {
      return;
    }
    _safeSetState(() {
      final stroke = DrawingStroke(
        id: DrawingStroke.generateId(),
        pageNumber: pageNumber,
        style: style,
        pointsNorm: <Offset>[normalized],
      );
      _inProgressStroke = stroke;
      if (kDebugMode) {
        debugPrint(
          '[Drawing] NEW STROKE style: kind=${style.kind.name}, '
          'variant=${style.variant.name}, width=${style.widthPx.toStringAsFixed(1)}, '
          'color=${style.argbColor}, id=${stroke.id}',
        );
      }
      _canvasController.setLiveStroke(stroke);
    });
  }

  void _handleFreeDrawPointerUpdate(
    Offset normalized,
    int pageNumber,
    Size destSize, {
    required int pointerId,
    required double photoScale,
    bool shouldInterpolateFromLastPoint = false,
  }) {
    final inProgressStroke = _inProgressStroke;
    if (!_isFreeDrawMode ||
        _activePointerIds.length >= 2 ||
        inProgressStroke == null ||
        inProgressStroke.pointsNorm.isEmpty ||
        inProgressStroke.pageNumber != pageNumber) {
      return;
    }
    if (_activeStylusPointerId != null && _activeStylusPointerId != pointerId) {
      return;
    }

    final isHighlighterFamily = _isHighlighterFamilyVariant(
      inProgressStroke.style.variant,
    );
    final bool isPenFamily =
        inProgressStroke.style.kind == StrokeToolKind.pen &&
        !isHighlighterFamily;
    final shouldRenderStraightPreview =
        _isStraightenModeEnabled && (isPenFamily || isHighlighterFamily);
    if (shouldRenderStraightPreview) {
      if (destSize.shortestSide <= 0) {
        return;
      }
      final startNorm = inProgressStroke.pointsNorm.first;
      final startPage = Offset(
        startNorm.dx * destSize.width,
        startNorm.dy * destSize.height,
      );
      final rawPage = Offset(
        normalized.dx * destSize.width,
        normalized.dy * destSize.height,
      );
      final dx = rawPage.dx - startPage.dx;
      final dy = rawPage.dy - startPage.dy;
      final rawAngle = math.atan2(dy, dx);
      final snapToleranceRad = _degToRad(12);
      const targetAngles = <double>[
        0,
        math.pi / 4,
        math.pi / 2,
        3 * math.pi / 4,
        math.pi,
        5 * math.pi / 4,
        3 * math.pi / 2,
        7 * math.pi / 4,
      ];

      var nearestTarget = targetAngles.first;
      var nearestDiff = _wrapAngleDiff(rawAngle, nearestTarget).abs();
      for (final candidate in targetAngles.skip(1)) {
        final candidateDiff = _wrapAngleDiff(rawAngle, candidate).abs();
        if (candidateDiff < nearestDiff) {
          nearestDiff = candidateDiff;
          nearestTarget = candidate;
        }
      }

      final didSnap =
          _isStraightenSnapEnabled && nearestDiff <= snapToleranceRad;
      final snappedPageExact = didSnap
          ? Offset(
              startPage.dx +
                  math.cos(nearestTarget) * math.sqrt(dx * dx + dy * dy),
              startPage.dy +
                  math.sin(nearestTarget) * math.sqrt(dx * dx + dy * dy),
            )
          : rawPage;
      final clampedSnappedPageExact = Offset(
        snappedPageExact.dx.clamp(0.0, destSize.width).toDouble(),
        snappedPageExact.dy.clamp(0.0, destSize.height).toDouble(),
      );
      var snappedPageRender = clampedSnappedPageExact;
      if (didSnap) {
        const epsilonPx = 0.25;
        final isHorizontalSnap = nearestTarget == 0 || nearestTarget == math.pi;
        final isVerticalSnap =
            nearestTarget == (math.pi / 2) ||
            nearestTarget == (3 * math.pi / 2);
        if (isHorizontalSnap) {
          snappedPageRender = Offset(
            clampedSnappedPageExact.dx,
            clampedSnappedPageExact.dy + epsilonPx,
          );
        } else if (isVerticalSnap) {
          snappedPageRender = Offset(
            clampedSnappedPageExact.dx + epsilonPx,
            clampedSnappedPageExact.dy,
          );
        }
        snappedPageRender = Offset(
          snappedPageRender.dx.clamp(0.0, destSize.width).toDouble(),
          snappedPageRender.dy.clamp(0.0, destSize.height).toDouble(),
        );
      }

      _pendingStraightenCommitByPointer[pointerId] = _PendingStraightenCommit(
        snappedPageExact: clampedSnappedPageExact,
        destSize: destSize,
        photoScale: photoScale,
      );
      final processedNormalized = Offset(
        snappedPageRender.dx / destSize.width,
        snappedPageRender.dy / destSize.height,
      );
      if (!processedNormalized.dx.isFinite ||
          !processedNormalized.dy.isFinite) {
        return;
      }

      const double straightenAppendEpsilonPx = 0.5;
      final double straightenAppendEpsilonNorm =
          straightenAppendEpsilonPx / destSize.shortestSide;
      final previousEnd = inProgressStroke.pointsNorm.last;
      final bool didAppend =
          (processedNormalized - previousEnd).distance >=
          straightenAppendEpsilonNorm;

      assert(() {
        final start = inProgressStroke.pointsNorm.first;
        final dx = (normalized.dx - start.dx) * destSize.width;
        final dy = (normalized.dy - start.dy) * destSize.height;
        debugPrint(
          '[Drawing][Straighten] update rawDx=${dx.toStringAsFixed(2)} '
          'rawDy=${dy.toStringAsFixed(2)} snapped=$processedNormalized '
          'appended=$didAppend '
          'highlighter=$isHighlighterFamily',
        );
        return true;
      }());
      final newPoints = _buildStraightLinePointsNorm(
        startNorm: startNorm,
        endNorm: processedNormalized,
        destSize: destSize,
        photoScale: photoScale,
      );
      _recordFreeDrawPerfUiMutation();
      inProgressStroke.pointsNorm
        ..clear()
        ..addAll(newPoints);
      final livePreviewStroke = isHighlighterFamily
          ? DrawingStroke(
              id: inProgressStroke.id,
              pageNumber: inProgressStroke.pageNumber,
              style: inProgressStroke.style.copyWith(
                kind: StrokeToolKind.pen,
                variant:
                    inProgressStroke.style.variant ==
                            PenVariant.highlighterChisel ||
                        inProgressStroke.style.variant ==
                            PenVariant.markerChisel
                    ? PenVariant.markerChisel
                    : PenVariant.marker,
              ),
              pointsNorm: inProgressStroke.pointsNorm,
              toolType: inProgressStroke.toolType,
              opacity: inProgressStroke.opacity,
              isStraightened: inProgressStroke.isStraightened,
              penVariant: inProgressStroke.penVariant,
              highlighterVariant: inProgressStroke.highlighterVariant,
              erasedMaskVersion: inProgressStroke.erasedMaskVersion,
              erasedMask: inProgressStroke.erasedMask,
              erasedSegments: inProgressStroke.erasedSegments,
            )
          : inProgressStroke;
      _canvasController.setLiveStroke(livePreviewStroke, forceNotify: true);
      return;
    }

    final processedNormalized = normalized;

    final candidates = shouldInterpolateFromLastPoint
        ? _interpolateNormalizedPoints(
            from: inProgressStroke.pointsNorm.last,
            to: processedNormalized,
            pageSize: destSize,
            photoScale: photoScale,
          )
        : <Offset>[processedNormalized];

    const double thresholdScreenPx = 1.2;
    final effectiveScale = (photoScale <= 0) ? 1.0 : photoScale;
    final double thresholdNorm =
        (thresholdScreenPx / effectiveScale) / destSize.shortestSide;
    final additions = <Offset>[];
    var last = inProgressStroke.pointsNorm.last;
    for (final candidate in candidates) {
      if ((candidate - last).distance < thresholdNorm) {
        continue;
      }
      additions.add(candidate);
      last = candidate;
    }
    if (additions.isEmpty) {
      return;
    }
    _recordFreeDrawPerfUiMutation();
    inProgressStroke.pointsNorm.addAll(additions);
    _canvasController.setLiveStroke(inProgressStroke, forceNotify: true);
    if (kDebugMode) {
      debugPrint(
        '[Drawing] liveStroke move page=$pageNumber points=${inProgressStroke.pointsNorm.length}',
      );
    }
  }

  double _degToRad(double deg) => deg * math.pi / 180.0;

  double _wrapAngleDiff(double a, double b) {
    final twoPi = 2 * math.pi;
    var diff = (a - b) % twoPi;
    if (diff > math.pi) {
      diff -= twoPi;
    } else if (diff < -math.pi) {
      diff += twoPi;
    }
    return diff;
  }

  List<Offset> _buildStraightLinePointsNorm({
    required Offset startNorm,
    required Offset endNorm,
    required Size destSize,
    required double photoScale,
  }) {
    if (destSize.width <= 0 || destSize.height <= 0) {
      return <Offset>[startNorm, endNorm];
    }

    final startPage = Offset(
      startNorm.dx * destSize.width,
      startNorm.dy * destSize.height,
    );
    final endPage = Offset(
      endNorm.dx * destSize.width,
      endNorm.dy * destSize.height,
    );
    final distancePx = (endPage - startPage).distance;
    final effectiveScale = math.max(photoScale, 1.0);
    final stepPx = math.max(1.2 / effectiveScale, 0.5) * 2.0;
    if (distancePx <= stepPx) {
      return <Offset>[startNorm, endNorm];
    }

    final steps = math.max(1, (distancePx / stepPx).floor());
    if (steps <= 1) {
      return <Offset>[startNorm, endNorm];
    }

    final points = <Offset>[startNorm];
    for (int i = 1; i < steps; i++) {
      final t = i / steps;
      points.add(
        Offset(
          startNorm.dx + (endNorm.dx - startNorm.dx) * t,
          startNorm.dy + (endNorm.dy - startNorm.dy) * t,
        ),
      );
    }
    points.add(endNorm);
    return points;
  }

  void _handleFreeDrawPointerEnd(int pageNumber, {required int pointerId}) {
    if (_activeStylusPointerId == pointerId) {
      _activeStylusPointerId = null;
    }
    _handleFreeDrawEnd(pageNumber, pointerId: pointerId);
    _straightenSnappedAngleByPointer.remove(pointerId);
    _straightenStartPageByPointer.remove(pointerId);
    _pendingStraightenCommitByPointer.remove(pointerId);
  }

  void _handleFreeDrawEnd(int pageNumber, {int? pointerId}) {
    final inProgressStroke = _inProgressStroke;
    if (inProgressStroke == null ||
        inProgressStroke.pointsNorm.isEmpty ||
        inProgressStroke.pageNumber != pageNumber) {
      return;
    }
    _safeSetState(() {
      var committedPoints = List<Offset>.from(inProgressStroke.pointsNorm);
      final pendingStraightenCommit = pointerId != null
          ? _pendingStraightenCommitByPointer[pointerId]
          : null;
      if (pendingStraightenCommit != null &&
          pendingStraightenCommit.destSize.width > 0 &&
          pendingStraightenCommit.destSize.height > 0) {
        final startNorm = inProgressStroke.pointsNorm.first;
        final endNormExact = Offset(
          pendingStraightenCommit.snappedPageExact.dx /
              pendingStraightenCommit.destSize.width,
          pendingStraightenCommit.snappedPageExact.dy /
              pendingStraightenCommit.destSize.height,
        );
        committedPoints = _buildStraightLinePointsNorm(
          startNorm: startNorm,
          endNorm: endNormExact,
          destSize: pendingStraightenCommit.destSize,
          photoScale: pendingStraightenCommit.photoScale,
        );
      }
      final committedStroke = DrawingStroke(
        id: inProgressStroke.id,
        pageNumber: pageNumber,
        style: inProgressStroke.style,
        pointsNorm: committedPoints,
      );
      _historyManager.execute(
        AddStrokeCommand(
          page: pageNumber,
          strokeSnapshot: committedStroke.deepCopy(),
        ),
        _canvasController,
      );
      if (kDebugMode) {
        debugPrint(
          '[Drawing] commit stroke=${committedStroke.id} '
          'page=$pageNumber points=${committedStroke.pointsNorm.length} '
          'tick=${_canvasController.cacheRebuildTick.value}',
        );
      }
      _syncStrokesByPageFromControllerPage(pageNumber);
      _updateDrawingHistoryAvailabilityState();
      _inProgressStroke = null;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _canvasController.setLiveStroke(null);
      });
    });
    _requestPersistDrawing();
  }

  void _updateDrawingHistoryAvailabilityState() {
    _canUndoDrawing = _historyManager.canUndo;
    _canRedoDrawing = _historyManager.canRedo;
  }

  void _handleUndoDrawing() {
    if (!_historyManager.canUndo) {
      return;
    }
    _safeSetState(() {
      final affectedPage = _historyManager.undo(_canvasController);
      if (affectedPage == null) {
        _syncAllStrokesByPageFromController();
      } else {
        _syncStrokesByPageFromControllerPage(affectedPage);
      }
      _updateDrawingHistoryAvailabilityState();
    });
  }

  void _handleRedoDrawing() {
    if (!_historyManager.canRedo) {
      return;
    }
    _safeSetState(() {
      final affectedPage = _historyManager.redo(_canvasController);
      if (affectedPage == null) {
        _syncAllStrokesByPageFromController();
      } else {
        _syncStrokesByPageFromControllerPage(affectedPage);
      }
      _updateDrawingHistoryAvailabilityState();
    });
  }

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
      message:
          '현재 페이지의 모든 그리기 요소를 삭제합니다. 계속하시겠습니까?',
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
      title:
          '현재 페이지에서 형광펜만 지우기',
      message:
          '현재 페이지에서 형광펜으로 그린 요소만 삭제합니다. 계속하시겠습니까?',
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
      title:
          '현재 페이지에서 펜만 지우기',
      message:
          '현재 페이지에서 펜으로 그린 요소만 삭제합니다. 계속하시겠습니까?',
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

  void _toggleMode(DrawMode nextMode) {
    final previousMode = _mode;
    final toggledMode = _controller.toggleMode(_mode, nextMode);
    final enableFreeDraw =
        toggledMode == DrawMode.freeDraw || toggledMode == DrawMode.eraser;
    if (!enableFreeDraw) {
      _resetAreaEraserMoveCoalescing();
    }
    _safeSetState(() {
      _mode = toggledMode;
      _isFreeDrawMode = enableFreeDraw;
      _activePointerIds.clear();
      _activePointerKinds.clear();
      _activeStylusPointerId = null;
      if (previousMode == DrawMode.defect && toggledMode == DrawMode.hand) {
        _activeCategory = null;
        _sidePanelDefectCategory = null;
      }
      if (previousMode == DrawMode.equipment && toggledMode == DrawMode.hand) {
        _activeEquipmentCategory = null;
        _sidePanelEquipmentCategory = null;
      }
      if (_isFreeDrawMode) {
        _activeTool = toggledMode == DrawMode.eraser
            ? DrawingTool.strokeEraser
            : DrawingTool.pen;
      } else {
        _inProgressStroke = null;
        _isFreeDrawConsumingOneFinger = false;
        _pendingDraw = false;
        _pendingDrawDownViewportLocal = null;
        _eraserCursorPageLocal = null;
        _eraserCursorPageNumber = null;
        _canvasController.setLiveStroke(null);
        _canvasController.setEraserCursor(null);
        _canvasController.setEraserPreview(null);
        _activeAreaEraserPointerId = null;
        _activeAreaEraserSession = null;
      }
    });
    if (!_isFreeDrawMode) {
      _debugLogPhotoViewBaseStateOnce('mode-toggle');
    }
  }

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
    _updateMovePreviewFromGlobalDelta(
      globalPosition: details.globalPosition,
      pageIndex: pageIndex,
      tapContext: _pdfTapRegionKeyForPage(pageIndex).currentContext,
      overlaySize: _pdfPageSizes[pageIndex],
      destRect: (_pdfPageSizes[pageIndex] == null)
          ? null
          : (Offset.zero & _pdfPageSizes[pageIndex]!),
    );
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
      final normalized = toNormalized(scenePoint, DrawingCanvasSize);
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
        deltaScene.dx / DrawingCanvasSize.width,
        deltaScene.dy / DrawingCanvasSize.height,
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
    return DrawingCanvasSize;
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
    _setPdfState(() {
      _currentPage = page;
      _activePointerIds.clear();
      _activePointerKinds.clear();
      _activeStylusPointerId = null;
      _isFreeDrawConsumingOneFinger = false;
      _pendingDraw = false;
      _pendingDrawDownViewportLocal = null;
      _canvasController.setLiveStroke(null);
      _canvasController.setEraserCursor(
        _eraserCursorPageNumber == page ? _eraserCursorPageLocal : null,
      );
    });
    if (!_isFreeDrawMode) {
      _debugLogPhotoViewBaseStateOnce('page-change');
    }
  }

  void _handlePdfDocumentLoaded(PdfDocument document) async {
    final pageCount = document.pagesCount;
    final sizes = await _prefetchPdfPageSizes(document);
    if (!mounted) {
      return;
    }
    _setPdfState(() {
      _pageCount = pageCount;
      if (_currentPage > _pageCount) {
        _currentPage = 1;
      }
      _pdfLoadError = null;
      if (sizes.isNotEmpty) {
        _pdfPageSizes
          ..clear()
          ..addAll(sizes);
        _pdfViewVersion += 1;
      }
    });
    debugPrint('PDF loaded with ${document.pagesCount} pages.');
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
    _setPdfState(() => _pdfPageSizes[pageNumber] = pageSize);
    _persistPdfPageSizeCache();
  }

  void _handlePrevPage() {
    final nextPage = _currentPage - 1;
    _safeSetState(() => _currentPage = nextPage);
    _pdfController?.jumpToPage(nextPage);
  }

  void _handleNextPage() {
    final nextPage = _currentPage + 1;
    _safeSetState(() => _currentPage = nextPage);
    _pdfController?.jumpToPage(nextPage);
  }
}

