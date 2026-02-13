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
    required this.pageNumber,
    required this.pageSize,
    required this.normalized,
    required this.photoScale,
  });

  final int pageNumber;
  final Size pageSize;
  final Offset normalized;
  final double photoScale;
}

final Expando<_PendingFreeDrawMove> _pendingFreeDrawMoveByState =
    Expando<_PendingFreeDrawMove>('pendingFreeDrawMoveByState');
final Expando<bool> _isFreeDrawMoveScheduledByState =
    Expando<bool>('isFreeDrawMoveScheduledByState');
final Expando<int> _freeDrawCallsInWindowByState =
    Expando<int>('freeDrawCallsInWindowByState');
final Expando<int> _freeDrawUiMutationsInWindowByState =
    Expando<int>('freeDrawUiMutationsInWindowByState');
final Expando<DateTime> _freeDrawWindowStartByState =
    Expando<DateTime>('freeDrawWindowStartByState');

const double _kMinValidPdfPageSide = 200.0;

typedef OverlayToPageLocal = Offset? Function(Offset overlayLocal);

extension _DrawingScreenLogic on _DrawingScreenState {
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

  bool _isStylusKind(PointerDeviceKind kind) {
    return kind == PointerDeviceKind.stylus ||
        kind == PointerDeviceKind.invertedStylus;
  }

  bool _hasAnyTouchPointer() {
    return _activePointerKinds.values.any(
      (kind) => kind == PointerDeviceKind.touch,
    );
  }

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

    if (kDebugMode) {
      _debugLastPdfPointerMapping = <String, Object?>{
        'destLocal': viewportLocal,
        'pageLocal': pageLocal,
        'normalized': Offset(
          pageLocal.dx / childSize.width,
          pageLocal.dy / childSize.height,
        ),
        'position': controllerValue.position,
        'scale': controllerValue.scale,
        'viewportSize': viewportSize,
        'childSize': childSize,
      };
    }

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

    final payload = await _drawingPersistenceStore.loadSiteDrawing(siteId: targetSiteId);
    final Map<int, List<DrawingStroke>> loaded = <int, List<DrawingStroke>>{};

    final drawingStrokesJson = payload?['drawingStrokes'];
    if (drawingStrokesJson is List) {
      for (final rawStroke in drawingStrokesJson.whereType<Map>()) {
        final stroke = DrawingStroke.fromJson(rawStroke.cast<String, dynamic>());
        loaded.putIfAbsent(stroke.pageNumber, () => <DrawingStroke>[]).add(stroke);
      }
    }

    if (!mounted || _site.id != targetSiteId) {
      return;
    }

    _safeSetState(() {
      _strokesByPage
        ..clear()
        ..addAll(loaded);
      _inProgressStroke = null;
      _canUndoDrawing = false;
      _canRedoDrawing = false;
    });
    _undo.clear();
    _redo.clear();
    _drawingHistoryManager.loadPersisted(
      const <DrawingHistoryActionPersisted>[],
      const <DrawingHistoryActionPersisted>[],
    );
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
        .map(
          (stroke) => DrawingStroke(
            id: stroke.id,
            pageNumber: stroke.pageNumber,
            style: stroke.style,
            pointsNorm: List<Offset>.from(stroke.pointsNorm),
          ),
        )
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
        ..showSnackBar(const SnackBar(content: Text('저장에 실패했습니다')));
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
          const SnackBar(content: Text('저장 실패로 일부 내용이 저장되지 않았을 수 있습니다')),
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

  void _handleOverlayPointerDown(PointerDownEvent event) {
    final previousCount = _activePointerIds.length;
    _activePointerIds.add(event.pointer);
    _activePointerKinds[event.pointer] = event.kind;
    if (!_isFreeDrawMode) {
      if (previousCount != _activePointerIds.length) {
        _safeSetState(() {});
      }
      return;
    }
    final bool becameTwoFinger =
        previousCount < 2 && _activePointerIds.length >= 2;
    if (becameTwoFinger) {
      if (_isFreeDrawConsumingOneFinger && _inProgressStroke != null) {
        _handleFreeDrawPointerEnd(_inProgressStroke?.pageNumber ?? _currentPage);
      }
      _safeSetState(() {
        _isFreeDrawConsumingOneFinger = false;
        _pendingDraw = false;
        _pendingDrawDownViewportLocal = null;
      });
      return;
    }
    _safeSetState(() {});
  }

  void _handleOverlayPointerDownWithStylusDrawing(
    PointerDownEvent event, {
    required int pageNumber,
    required Size pageSize,
    required OverlayToPageLocal drawingLocalToPageLocal,
    required double photoScale,
  }) {
    _handleOverlayPointerDown(event);

    if (!_isStylusKind(event.kind) || _hasAnyTouchPointer()) {
      return;
    }

    final activeTool = _activeTool;

    if (_isFreeDrawMode && activeTool == DrawingTool.strokeEraser) {
      _activeStylusPointerId = event.pointer;
      _safeSetState(() {
        _pendingDraw = true;
        _pendingDrawDownViewportLocal = event.localPosition;
      });
      return;
    }

    if (_isFreeDrawMode && activeTool == DrawingTool.areaEraser) {
      final pageLocal = drawingLocalToPageLocal(event.localPosition);
      if (pageLocal == null) {
        return;
      }
      _safeSetState(() {
        _eraserCursorPageNumber = pageNumber;
        _eraserCursorPageLocal = pageLocal;
        _startAreaEraserSession(event.pointer);
      });
      return;
    }

    if (!_isFreeDrawMode || _activeStrokeStyle == null) return;

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
    if (!_isFreeDrawMode) {
      return;
    }

    final activeTool = _activeTool;

    if (_hasAnyTouchPointer()) {
      _resetFreeDrawMoveCoalescing();
      _resetAreaEraserMoveCoalescing();
      _safeSetState(() {
        _isFreeDrawConsumingOneFinger = false;
        _pendingDraw = false;
        _pendingDrawDownViewportLocal = null;
        _activeStylusPointerId = null;
        _eraserCursorPageLocal = null;
      });
      return;
    }

    if (activeTool == DrawingTool.areaEraser) {
      if (_activeAreaEraserPointerId != event.pointer || !_isStylusKind(event.kind)) {
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
      return;
    }

    if (activeTool == DrawingTool.strokeEraser) {
      return;
    }

    if (_activeStrokeStyle == null) {
      if (_isFreeDrawConsumingOneFinger && _inProgressStroke != null) {
        _handleFreeDrawPointerEnd(_inProgressStroke?.pageNumber ?? _currentPage);
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
      _debugLastPageLocal = downPageLocal;
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

    _debugLastPageLocal = pageLocal;
    _queueFreeDrawMove(
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
    final wasStylus = _activeStylusPointerId == event.pointer;
    final wasAreaSession = _activeAreaEraserPointerId == event.pointer;
    if (wasStylus) {
      _flushPendingFreeDrawMove();
    }

    _handleOverlayPointerUpOrCancel(event);

    if (!_isFreeDrawMode) {
      return;
    }

    final activeTool = _activeTool;

    if (activeTool == DrawingTool.areaEraser && wasAreaSession) {
      _flushPendingAreaEraserMove();
      _safeSetState(() {
        _eraserCursorPageLocal = null;
        _eraserCursorPageNumber = null;
      });
      _commitAreaEraserSession();
      return;
    }

    if (activeTool == DrawingTool.strokeEraser && wasStylus) {
      final down = _pendingDrawDownViewportLocal;
      if (down != null && event is PointerUpEvent) {
        final movedEnough = (event.localPosition - down).distance >= _DrawingScreenState._kDrawStartSlopPx;
        if (!movedEnough) {
          final pageLocal = drawingLocalToPageLocal(event.localPosition);
          final radiusPagePx = _viewportDistanceToPageDistance(
            viewportLocal: event.localPosition,
            viewportDistancePx: _areaEraserRadiusPx,
            drawingLocalToPageLocal: drawingLocalToPageLocal,
          );
          if (pageLocal != null) {
            final closest = _findClosestStrokeAtPageLocal(
              pageNumber: pageNumber,
              pageLocal: pageLocal,
              pageSize: pageSize,
              thresholdPx: math.max(
                radiusPagePx,
                _strokeEraserBaseThresholdForPage(strokes: _strokesByPage[pageNumber], pageSize: pageSize),
              ),
            );
            if (closest != null) {
              _safeSetState(() {
                _removeStrokeWithUndoSnapshot(closest);
              });
            }
          }
        }
      }
      _safeSetState(() {
        _pendingDraw = false;
        _pendingDrawDownViewportLocal = null;
        _activeStylusPointerId = null;
      });
      return;
    }

    if (wasStylus) {
      _flushPendingFreeDrawMove();
      if (_isFreeDrawConsumingOneFinger) {
        _handleFreeDrawPointerEnd(pageNumber);
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
    final didRemove = _activePointerIds.remove(event.pointer);
    if (!didRemove) {
      return;
    }
    _activePointerKinds.remove(event.pointer);
    if (_activeStylusPointerId == event.pointer) {
      _activeStylusPointerId = null;
    }
    if (_isFreeDrawMode) {
      if (_activePointerIds.isEmpty && _inProgressStroke != null) {
        _handleFreeDrawPointerEnd(_inProgressStroke?.pageNumber ?? _currentPage);
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
      _eraserCursorPageLocal = null;
      _eraserCursorPageNumber = null;
    });
  }

  void _handleAreaEraserRadiusChanged(double value) {
    _safeSetState(() {
      _areaEraserRadiusPx = value.clamp(
        _DrawingScreenState._kMinAreaEraserRadiusPx,
        _DrawingScreenState._kMaxAreaEraserRadiusPx,
      );
    });
  }

  bool get _isAreaEraserActive =>
      _isFreeDrawMode && _activeTool == DrawingTool.areaEraser;

  bool get _isStrokeEraserActive =>
      _isFreeDrawMode && _activeTool == DrawingTool.strokeEraser;

  double _strokeEraserBaseThresholdForPage({
    required List<DrawingStroke>? strokes,
    required Size pageSize,
  }) {
    final pageShortest = pageSize.shortestSide <= 0 ? 1.0 : pageSize.shortestSide;
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

  DrawingStroke? _findClosestStrokeAtPageLocal({
    required int pageNumber,
    required Offset pageLocal,
    required Size pageSize,
    required double thresholdPx,
  }) {
    final strokes = _strokesByPage[pageNumber];
    if (strokes == null || strokes.isEmpty) {
      return null;
    }
    DrawingStroke? closest;
    double minDistance = double.infinity;
    for (final stroke in strokes) {
      final distance = _distanceToStrokePolyline(
        stroke: stroke,
        point: pageLocal,
        pageSize: pageSize,
      );
      if (distance < minDistance) {
        minDistance = distance;
        closest = stroke;
      }
    }
    if (minDistance > thresholdPx) {
      return null;
    }
    return closest;
  }

  double _distanceToStrokePolyline({
    required DrawingStroke stroke,
    required Offset point,
    required Size pageSize,
  }) {
    final points = stroke.pointsNorm;
    if (points.isEmpty) {
      return double.infinity;
    }
    if (points.length == 1) {
      final single = Offset(points.first.dx * pageSize.width, points.first.dy * pageSize.height);
      return (single - point).distance;
    }

    var minDistanceSquared = double.infinity;
    for (var i = 0; i < points.length - 1; i += 1) {
      final p1 = Offset(points[i].dx * pageSize.width, points[i].dy * pageSize.height);
      final p2 = Offset(
        points[i + 1].dx * pageSize.width,
        points[i + 1].dy * pageSize.height,
      );
      final distanceSquared = _distanceSquaredToSegment(point, p1, p2);
      if (distanceSquared < minDistanceSquared) {
        minDistanceSquared = distanceSquared;
      }
    }
    return math.sqrt(minDistanceSquared);
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
        ((point.dx - start.dx) * segment.dx + (point.dy - start.dy) * segment.dy) /
        segmentLengthSquared;
    final t = projection.clamp(0.0, 1.0);
    final nearest = Offset(start.dx + segment.dx * t, start.dy + segment.dy * t);
    final delta = point - nearest;
    return (delta.dx * delta.dx) + (delta.dy * delta.dy);
  }

  void _removeStrokeWithUndoSnapshot(DrawingStroke stroke) {
    final removed = _removeStrokeById(stroke);
    if (!removed) {
      return;
    }
    _recordUndoAction(DrawingHistoryAction.single(stroke: stroke, wasAdd: false));
    _redo.clear();
    _syncDrawingHistoryAvailability();
    _requestPersistDrawing();
  }

  void _startAreaEraserSession(int pointer) {
    _activeAreaEraserPointerId = pointer;
    _activeAreaEraserSession = _eraserEngine.startSession(
      mode: EraserMode.area,
      radius: _areaEraserRadiusPx,
    );
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

    final previousSession = _activeAreaEraserSession;
    if (previousSession == null) {
      return;
    }
    final strokes = List<DrawingStroke>.from(
      _strokesByPage[pending.pageNumber] ?? const <DrawingStroke>[],
    );
    final updatedSession = _eraserEngine.updateSession(
      previousSession.copyWith(radius: pending.radiusPagePx),
      center: pending.pageLocal,
      pageSize: pending.pageSize,
      strokes: strokes,
    );

    final removedIds = updatedSession.removedById.keys.toSet();
    final addedIds = updatedSession.addedById.keys.toSet();
    final prevRemovedIds = previousSession.removedById.keys.toSet();
    final prevAddedIds = previousSession.addedById.keys.toSet();
    final changed = removedIds.length != prevRemovedIds.length ||
        addedIds.length != prevAddedIds.length;
    if (changed) {
      final removeTargets = <DrawingStroke>[];
      for (final stroke in strokes) {
        final shouldRemove = removedIds.contains(stroke.id) ||
            (prevAddedIds.contains(stroke.id) && !addedIds.contains(stroke.id));
        if (shouldRemove) {
          removeTargets.add(stroke);
        }
      }
      for (final stroke in removeTargets) {
        _removeStrokeById(stroke);
      }
      for (final stroke in updatedSession.addedById.values) {
        if (!prevAddedIds.contains(stroke.id)) {
          _addStrokeToMemory(stroke);
        }
      }
    }

    _activeAreaEraserSession = updatedSession;
    _eraserEngine.recordUiMutation();
    _safeSetState(() {
      _eraserCursorPageNumber = pending.pageNumber;
      _eraserCursorPageLocal = pending.pageLocal;
    });
  }

  void _resetAreaEraserMoveCoalescing() {
    _pendingAreaEraserMove = null;
    _isAreaEraserFrameScheduled = false;
  }

  void _commitAreaEraserSession() {
    final session = _activeAreaEraserSession;
    if (session != null) {
      final result = _eraserEngine.commit(session);
      if (result.hasChanges) {
        _drawingHistoryManager.recordReplace(result.removed, result.added);
        _requestPersistDrawing();
      }
    }
    _activeAreaEraserPointerId = null;
    _activeAreaEraserSession = null;
    _resetAreaEraserMoveCoalescing();
  }

  void _queueFreeDrawMove({
    required int pageNumber,
    required Size pageSize,
    required Offset normalized,
    required double photoScale,
  }) {
    _pendingFreeDrawMove = _PendingFreeDrawMove(
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
      if (_pendingFreeDrawMove != null && !_isFreeDrawMoveScheduled) {
        _isFreeDrawMoveScheduled = true;
        SchedulerBinding.instance.scheduleFrameCallback((_) {
          _isFreeDrawMoveScheduled = false;
          _flushPendingFreeDrawMove();
        });
      }
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
      photoScale: pending.photoScale,
      shouldInterpolateFromLastPoint: true,
    );
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
      _inProgressStroke = DrawingStroke(
        id: DrawingStroke.generateId(),
        pageNumber: pageNumber,
        style: style,
        pointsNorm: <Offset>[normalized],
      );
    });
  }

  void _handleFreeDrawPointerUpdate(
    Offset normalized,
    int pageNumber,
    Size destSize, {
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
    final candidates = shouldInterpolateFromLastPoint
        ? _interpolateNormalizedPoints(
            from: inProgressStroke.pointsNorm.last,
            to: normalized,
            pageSize: destSize,
            photoScale: photoScale,
          )
        : <Offset>[normalized];

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
    _safeSetState(() {
      inProgressStroke.pointsNorm.addAll(additions);
    });
  }

  void _handleFreeDrawPointerEnd(int pageNumber) {
    _handleFreeDrawEnd(pageNumber);
  }

  void _handleFreeDrawEnd(int pageNumber) {
    final inProgressStroke = _inProgressStroke;
    if (inProgressStroke == null ||
        inProgressStroke.pointsNorm.isEmpty ||
        inProgressStroke.pageNumber != pageNumber) {
      return;
    }
    _safeSetState(() {
      final committedStroke = DrawingStroke(
        id: inProgressStroke.id,
        pageNumber: pageNumber,
        style: inProgressStroke.style,
        pointsNorm: List<Offset>.from(inProgressStroke.pointsNorm),
      );
      _strokesByPage.putIfAbsent(pageNumber, () => <DrawingStroke>[]).add(
        committedStroke,
      );
      _recordUndoAction(
        DrawingHistoryAction.single(stroke: committedStroke, wasAdd: true),
      );
      _redo.clear();
      _syncDrawingHistoryAvailability();
      _debugLastPageLocal = null;
      _inProgressStroke = null;
    });
    _requestPersistDrawing();
  }


  void _recordUndoAction(DrawingHistoryAction action) {
    _drawingHistoryManager.recordUndoAction(action);
  }

  // ignore: unused_element
  void _recordRedoAction(DrawingHistoryAction action) {
    _drawingHistoryManager.recordRedoAction(action);
  }

  void _syncDrawingHistoryAvailability() {
    _drawingHistoryManager.syncHistoryAvailability();
  }

  void _updateDrawingHistoryAvailabilityState() {
    _canUndoDrawing = _undo.isNotEmpty;
    _canRedoDrawing = _redo.isNotEmpty;
  }

  bool _removeStrokeById(DrawingStroke stroke) {
    final strokes = _strokesByPage[stroke.pageNumber];
    if (strokes == null || strokes.isEmpty) {
      return false;
    }
    final index = strokes.lastIndexWhere((entry) => entry.id == stroke.id);
    if (index < 0) {
      return false;
    }
    strokes.removeAt(index);
    if (strokes.isEmpty) {
      _strokesByPage.remove(stroke.pageNumber);
    }
    return true;
  }

  void _addStrokeToMemory(DrawingStroke stroke) {
    _strokesByPage.putIfAbsent(stroke.pageNumber, () => <DrawingStroke>[]).add(
      stroke,
    );
  }

  DrawingStroke? _findStrokeById(String id) {
    for (final pageStrokes in _strokesByPage.values) {
      for (final stroke in pageStrokes) {
        if (stroke.id == id) {
          return stroke;
        }
      }
    }
    return null;
  }

  void _replaceStrokesInMemory(
    List<DrawingStroke> removed,
    List<DrawingStroke> added,
  ) {
    for (final stroke in removed) {
      _removeStrokeById(stroke);
    }
    for (final stroke in added) {
      _addStrokeToMemory(stroke);
    }
  }

  void _handleUndoDrawing() {
    if (_undo.isEmpty) {
      return;
    }
    _safeSetState(_drawingHistoryManager.undo);
  }

  void _handleRedoDrawing() {
    if (_redo.isEmpty) {
      return;
    }
    _safeSetState(_drawingHistoryManager.redo);
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
        _activePointerIds.clear();
        _debugLastPageLocal = null;
        _inProgressStroke = null;
        _isFreeDrawConsumingOneFinger = false;
        _pendingDraw = false;
        _pendingDrawDownViewportLocal = null;
        _eraserCursorPageLocal = null;
        _eraserCursorPageNumber = null;
        _activeAreaEraserPointerId = null;
        _activeAreaEraserSession = null;
      }
    });
    if (_isFreeDrawMode && !_didShowFreeDrawGuide && mounted) {
      _didShowFreeDrawGuide = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('자유 그리기: 한 손가락으로 그리기, 두 손가락으로 확대/이동')),
      );
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

  void _handlePdfPageChanged(int page) =>
      _setPdfState(() => _currentPage = page);

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
