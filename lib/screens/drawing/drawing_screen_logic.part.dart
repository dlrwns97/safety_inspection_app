part of 'drawing_screen.dart';

const double _kMinValidPdfPageSide = 200.0;

extension _DrawingScreenLogic on _DrawingScreenState {
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
      final matches =
          DefectCategory.values.where((category) => category.name == name);
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
      if (width < _kMinValidPdfPageSide ||
          height < _kMinValidPdfPageSide) {
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
    await prefs.setString(
      _pdfPageSizeCacheKeyForSite(_site),
      jsonEncode(map),
    );
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

  Future<void> _handlePdfTap(
    TapUpDetails details,
    Size pageSize,
    int pageIndex,
    BuildContext tapContext,
    {required Rect destRect}
  ) async {
    if (_isMoveMode) {
      return;
    }
    final tapRegionContext = _pdfTapRegionKeyForPage(pageIndex).currentContext;
    final tapInfo = _resolveTapPosition(
      tapRegionContext ?? tapContext,
      details.globalPosition,
    );
    final localPosition = tapInfo?.localPosition ?? details.localPosition;
    final overlaySize = tapInfo?.size ?? pageSize;
    final resolvedDestRect =
        destRect.isEmpty ? Offset.zero & overlaySize : destRect;
    if (!resolvedDestRect.contains(localPosition)) {
      return;
    }
    final imageLocal = localPosition - resolvedDestRect.topLeft;
    final imageSize = resolvedDestRect.size;
    final hitResult = _hitTestMarker(
      point: imageLocal,
      size: imageSize,
      pageIndex: pageIndex,
    );
    final isPlaceMode = _isPlaceMode;
    final decision = _controller.handlePdfTapDecision(
      isDetailDialogOpen: _isDetailDialogOpen,
      tapCanceled: _tapCanceled,
      isWithinCanvas: true, // PDF taps should always be treated as within canvas.
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

  Future<void> _handlePdfLongPress(
    LongPressStartDetails details,
    Size pageSize,
    int pageIndex,
    BuildContext tapContext,
    {required Rect destRect}
  ) async {
    if (_isMoveMode) {
      return;
    }
    _tapCanceled = true;
    final tapRegionContext = _pdfTapRegionKeyForPage(pageIndex).currentContext;
    final tapInfo = _resolveTapPosition(
      tapRegionContext ?? tapContext,
      details.globalPosition,
    );
    final localPosition = tapInfo?.localPosition ?? details.localPosition;
    final overlaySize = tapInfo?.size ?? pageSize;
    final resolvedDestRect =
        destRect.isEmpty ? Offset.zero & overlaySize : destRect;
    if (!resolvedDestRect.contains(localPosition)) {
      return;
    }
    final imageLocal = localPosition - resolvedDestRect.topLeft;
    final imageSize = resolvedDestRect.size;
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
      items.sort(
        (a, b) => a.createdIndex!.compareTo(b.createdIndex!),
      );
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
      showDefectDetailsDialog:
          (_, defectId) => _showDefectDetailsDialog(defectId: defectId),
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
    _activePointerIds.add(event.pointer);
    _updateFreeDrawGestureState();
  }

  void _handleOverlayPointerUpOrCancel(PointerEvent event) {
    _activePointerIds.remove(event.pointer);
    _updateFreeDrawGestureState();
  }

  void _updateFreeDrawGestureState() {
    final bool shouldIgnore =
        _isFreeDrawMode && _activePointerIds.length >= 2;
    if (_overlayIgnoring == shouldIgnore) {
      return;
    }
    _safeSetState(() {
      _overlayIgnoring = shouldIgnore;
      if (shouldIgnore) {
        _inProgress = null;
        _inProgressPage = null;
      }
    });
  }

  void _handleDrawingToolChanged(DrawingTool tool) {
    if (_activeTool == tool) {
      return;
    }
    _safeSetState(() => _activeTool = tool);
  }

  void _handleFreeDrawPanStart(DragStartDetails details, int pageNumber) {
    if (!_isFreeDrawMode || _activePointerIds.length >= 2) {
      return;
    }
    final scenePoint = _transformationController.toScene(details.localPosition);
    _safeSetState(() {
      _inProgressPage = pageNumber;
      _inProgress = [scenePoint];
    });
  }

  void _handleFreeDrawPanUpdate(DragUpdateDetails details, int pageNumber) {
    final inProgress = _inProgress;
    if (!_isFreeDrawMode ||
        _activePointerIds.length >= 2 ||
        inProgress == null ||
        inProgress.isEmpty ||
        _inProgressPage != pageNumber) {
      return;
    }
    final scenePoint = _transformationController.toScene(details.localPosition);
    const double distanceThreshold = 2.5;
    if ((scenePoint - inProgress.last).distance < distanceThreshold) {
      return;
    }
    _safeSetState(() => inProgress.add(scenePoint));
  }

  void _handleFreeDrawPanEnd(DragEndDetails details, int pageNumber) {
    final inProgress = _inProgress;
    if (inProgress == null ||
        inProgress.isEmpty ||
        _inProgressPage != pageNumber) {
      return;
    }
    _safeSetState(() {
      _strokesByPage.putIfAbsent(pageNumber, () => <List<Offset>>[]).add(
        List<Offset>.from(inProgress),
      );
      _inProgress = null;
      _inProgressPage = null;
    });
  }

  void _handleFreeDrawPanCancel() {
    if (_inProgress == null) {
      return;
    }
    _safeSetState(() {
      _inProgress = null;
      _inProgressPage = null;
    });
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
    final toggledMode = _controller.toggleMode(_mode, nextMode);
    final enableFreeDraw =
        toggledMode == DrawMode.freeDraw || toggledMode == DrawMode.eraser;
    _safeSetState(() {
      _mode = toggledMode;
      _isFreeDrawMode = enableFreeDraw;
      if (_isFreeDrawMode) {
        _activeTool = toggledMode == DrawMode.eraser
            ? DrawingTool.eraser
            : DrawingTool.pen;
      } else {
        _activePointerIds.clear();
        _overlayIgnoring = false;
        _inProgress = null;
        _inProgressPage = null;
      }
    });
    if (_isFreeDrawMode && !_didShowFreeDrawGuide && mounted) {
      _didShowFreeDrawGuide = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('자유 그리기: 한 손가락으로 그리기, 두 손가락으로 확대/이동'),
        ),
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

  bool _selectionMatchesMoveTarget(
    Defect? defect,
    EquipmentMarker? equipment,
  ) {
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
    final nextX =
        (currentX + details.delta.dx / pageSize.width).clamp(0.0, 1.0);
    final nextY =
        (currentY + details.delta.dy / pageSize.height).clamp(0.0, 1.0);
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
      destRect: _pdfPageDestRects[pageIndex],
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
      final resolvedDestRect =
          destRect == null || destRect.isEmpty
              ? Offset.zero & resolvedOverlaySize
              : destRect;
      if (!resolvedDestRect.contains(localPosition)) {
        return;
      }
      final imageLocal = localPosition - resolvedDestRect.topLeft;
      final imageSize = resolvedDestRect.size;
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
      final resolvedDestRect =
          destRect == null || destRect.isEmpty
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
      final imagePrev = clampedPrev - resolvedDestRect.topLeft;
      final imageNext = clampedNext - resolvedDestRect.topLeft;
      final deltaImage = imageNext - imagePrev;
      deltaNormalized = Offset(
        deltaImage.dx / resolvedDestRect.width,
        deltaImage.dy / resolvedDestRect.height,
      );
    }
    final nextX =
        (currentX + deltaNormalized.dx).clamp(0.0, 1.0);
    final nextY =
        (currentY + deltaNormalized.dy).clamp(0.0, 1.0);
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
      final updatedDefects =
          _site.defects
              .map(
                (defect) =>
                    defect.id == updatedDefect.id ? updatedDefect : defect,
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
      final updatedMarkers =
          _site.equipmentMarkers
              .map(
                (marker) =>
                    marker.id == updatedMarker.id ? updatedMarker : marker,
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
        visibleDefectCategoryNames:
            updated.tabs.map((tab) => tab.name).toList(),
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
    final orderedVisible =
        _orderedVisibleEquipmentCategories(updatedCategories);
    await _applyUpdatedSite(
      _site.copyWith(
        visibleEquipmentCategoryNames:
            orderedVisible.map((category) => category.name).toList(),
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
    final orderedVisible = _orderedVisibleEquipmentCategories(visibleCategories);
    final nextActive = _nextActiveEquipmentCategory(
      _activeEquipmentCategory,
      visibleCategories,
    );
    await _applyUpdatedSite(
      _site.copyWith(
        visibleEquipmentCategoryNames:
            orderedVisible.map((category) => category.name).toList(),
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
        visibleDefectCategoryNames:
            updated.tabs.map((tab) => tab.name).toList(),
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
