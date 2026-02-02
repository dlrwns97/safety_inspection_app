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
      _selectedDefect = null;
      _selectedEquipment = null;
      _selectedMarkerScenePosition = null;
    }
    if (inSetState) {
      _safeSetState(clearSelection);
    } else {
      clearSelection();
    }
  }

  Future<void> _handleCanvasTap(TapUpDetails details) async {
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
    final normalizedX = (scenePoint.dx / DrawingCanvasSize.width).clamp(
      0.0,
      1.0,
    );
    final normalizedY = (scenePoint.dy / DrawingCanvasSize.height).clamp(
      0.0,
      1.0,
    );
    final updatedSite = await _handleTapFlow(
      hitResult: hitResult,
      decision: decision,
      pageIndex: _currentPage,
      normalizedX: normalizedX,
      normalizedY: normalizedY,
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
      _selectedDefect = result.defect;
      _selectedEquipment = result.equipment;
      _selectedMarkerScenePosition = result.position;
    });
    _switchToDetailTab();
  }

  void _switchToDetailTab() {
    if (_sidePanelController.index != 2) {
      _sidePanelController.animateTo(2);
    }
  }

  void _selectDefectFromPanel(Defect defect) {
    _safeSetState(() {
      _selectedDefect = defect;
      _selectedEquipment = null;
      _selectedMarkerScenePosition = null;
    });
    _switchToDetailTab();
  }

  void _selectEquipmentFromPanel(EquipmentMarker marker) {
    _safeSetState(() {
      _selectedDefect = null;
      _selectedEquipment = marker;
      _selectedMarkerScenePosition = null;
    });
    _switchToDetailTab();
  }

  bool _isTapWithinCanvas(Offset globalPosition) {
    return _resolveTapPosition(
          _canvasTapRegionKey.currentContext,
          globalPosition,
        ) !=
        null;
  }

  Future<DefectDetails?> _showDefectDetailsDialog() async {
    final defectCategory = _activeCategory ?? DefectCategory.generalCrack;
    final defectConfig = defectCategoryConfig(defectCategory);
    return _showDetailDialog(
      () => showDefectDetailsDialog(
        context: context,
        title: defectConfig.dialogTitle,
        typeOptions: defectConfig.typeOptions,
        causeOptions: defectConfig.causeOptions,
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

  Future<RebarSpacingDetails?> _showRebarSpacingDialog({
    required String title,
    String? initialMemberType,
    String? initialRemarkLeft,
    String? initialRemarkRight,
    String? initialNumberPrefix,
    String? initialNumberValue,
  }) async {
    return _showDetailDialog(
      () => showRebarSpacingDialog(
        context: context,
        title: title,
        memberOptions: DrawingRebarSpacingMemberOptions,
        initialMemberType: initialMemberType,
        initialRemarkLeft: initialRemarkLeft,
        initialRemarkRight: initialRemarkRight,
        initialNumberPrefix: initialNumberPrefix,
        initialNumberValue: initialNumberValue,
      ),
    );
  }

  Future<SchmidtHammerDetails?> _showSchmidtHammerDialog({
    required String title,
    String? initialMemberType,
    String? initialMaxValueText,
    String? initialMinValueText,
  }) async {
    return _showDetailDialog(
      () => showSchmidtHammerDialog(
        context: context,
        title: title,
        memberOptions: DrawingSchmidtHammerMemberOptions,
        initialMemberType: initialMemberType,
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
    final normalizedX = (imageLocal.dx / imageSize.width).clamp(0.0, 1.0);
    final normalizedY = (imageLocal.dy / imageSize.height).clamp(0.0, 1.0);
    final updatedSite = await _handleTapFlow(
      hitResult: hitResult,
      decision: decision,
      pageIndex: pageIndex,
      normalizedX: normalizedX,
      normalizedY: normalizedY,
    );
    await _applyUpdatedSiteIfMounted(updatedSite);
  }

  Future<void> _handleCanvasLongPress(LongPressStartDetails details) async {
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
      showDefectDetailsDialog: (_) => _showDefectDetailsDialog(),
      showEquipmentDetailsDialog: _showEquipmentDetailsDialog,
      showRebarSpacingDialog:
          (
            context, {
            required title,
            initialMemberType,
            initialRemarkLeft,
            initialRemarkRight,
            initialNumberPrefix,
            initialNumberValue,
          }) => _showRebarSpacingDialog(
            title: title,
            initialMemberType: initialMemberType,
            initialRemarkLeft: initialRemarkLeft,
            initialRemarkRight: initialRemarkRight,
            initialNumberPrefix: initialNumberPrefix,
            initialNumberValue: initialNumberValue,
          ),
      showSchmidtHammerDialog:
          (
            context, {
            required title,
            initialMemberType,
            initialMaxValueText,
            initialMinValueText,
          }) => _showSchmidtHammerDialog(
            title: title,
            initialMemberType: initialMemberType,
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

  bool _isSameDefect(Defect first, Defect second) {
    if (first.id.isNotEmpty && second.id.isNotEmpty) {
      return first.id == second.id;
    }
    return identical(first, second);
  }

  bool _isSameEquipment(EquipmentMarker first, EquipmentMarker second) {
    if (first.id.isNotEmpty && second.id.isNotEmpty) {
      return first.id == second.id;
    }
    return identical(first, second);
  }

  void _toggleMode(DrawMode nextMode) {
    _safeSetState(() {
      _mode = _controller.toggleMode(_mode, nextMode);
    });
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
