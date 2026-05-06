part of 'drawing_screen.dart';

const double _kMinValidPdfPageSide = 200.0;

typedef OverlayToPageLocal = Offset? Function(Offset overlayLocal);

extension _DrawingScreenLogic on _DrawingScreenState {
  void _resetHighlighterStraightenState() {
    _straightenSnappedAngleByPointer.clear();
    _straightenStartPageByPointer.clear();
    _pendingStraightenCommitByPointer.clear();
  }

  Map<int, PendingStraightenCommit> get _pendingStraightenCommitByPointer =>
      _gestureState.pendingStraightenCommitByPointer;

  PendingFreeDrawMove? get _pendingFreeDrawMove =>
      _gestureState.pendingFreeDrawMove;

  set _pendingFreeDrawMove(PendingFreeDrawMove? value) {
    _gestureState.pendingFreeDrawMove = value;
  }

  bool get _isFreeDrawMoveScheduled => _gestureState.isFreeDrawMoveScheduled;

  set _isFreeDrawMoveScheduled(bool value) {
    _gestureState.isFreeDrawMoveScheduled = value;
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
    return drawingCanvasSize;
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

  bool get _isPanScaleAllowedDuringDraw {
    if (!_isFreeDrawMode) {
      return true;
    }
    if (_activeTouchPointerCount >= 2) {
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
    return MarkerInputGuard.isStylusLike(kind);
  }

  bool _isStrictStylusKind(PointerDeviceKind kind) {
    return MarkerInputGuard.isStrictStylus(kind);
  }

  int get _activeTouchPointerCount => _activePointerKinds.values
      .where((kind) => kind == PointerDeviceKind.touch)
      .length;

  bool get _isStylusActive {
    final id = _activeStylusPointerId;
    return id != null && _activePointerIds.contains(id);
  }

  Offset? _mapPdfViewportPointToPageLocal({
    required Offset viewportLocal,
    required int pageIndex,
    required Size viewportSize,
    required Size childSize,
  }) {
    final controllerValue = _photoControllerForPage(pageIndex).value;
    final snapshot = PdfViewportSnapshot(
      scale: controllerValue.scale ?? 1.0,
      position: controllerValue.position,
      viewportSize: viewportSize,
      childSize: childSize,
    );
    return _pdfViewportController.mapViewportPointToPageLocal(
      snapshot: snapshot,
      viewportLocal: viewportLocal,
    );
  }

  Offset? _overlayToNormalizedPoint({
    required Offset overlayLocal,
    required Size destSize,
  }) {
    return _pdfViewportController.overlayToNormalizedPoint(
      overlayLocal: overlayLocal,
      destSize: destSize,
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

  Future<void> _handlePdfTapAt(
    Offset pageLocal,
    Size pageSize,
    int pageIndex,
    PointerDeviceKind pointerKind,
  ) async {
    if (_isStylusRequiredMarkerPlacementMode &&
        !_isMarkerPlacementPointerAllowed(pointerKind)) {
      drawingVerboseLog('[MarkerPlacement] blocked tap kind=$pointerKind');
      return;
    }
    if (_isFreeDrawMode && _activeTool == DrawingTool.shape) {
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
    drawingVerboseLog('[PDF] tap: $pageLocal');
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
      size: drawingCanvasSize,
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
    _clearShapeSelection();
    final selection = _shapeInteractionCoordinator.findTapSelection(
      strokes: _canvasController.getStrokes(pageNumber),
      normPoint: normPoint,
      pageSize: pageSize,
    );
    if (selection == null) {
      return;
    }
    _safeSetState(() {
      _selectedShapeStrokeId = selection.strokeId;
      _activeShapeManipulator = selection.manipulator;
      _activeShapeHandle = ShapeHandle.none;
      _activeShapeEditOp = ShapeInteractionOperation.none;
      _shapeInteractionStartNorm = null;
      _shapeInteractionLastNorm = null;
      _shapeCreateHasMoved = false;
      _shapeCreateThresholdNorm = 0.0;
    });
  }

  Rect? _shapeStrokeBounds(List<Offset> pointsNorm) =>
      ShapeInteractionCoordinator.strokeBounds(pointsNorm);

  void _clearShapeSelection() {
    _safeSetState(() {
      _selectedShapeStrokeId = null;
      _activeShapeManipulator = null;
      _activeShapeHandle = ShapeHandle.none;
      _activeShapeEditOp = ShapeInteractionOperation.none;
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
      _activeShapeEditOp = ShapeInteractionOperation.none;
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

    final start = _shapeInteractionCoordinator.start(
      strokes: _canvasController.getStrokes(pageNumber),
      startNorm: startNorm,
      pageSize: pageSize,
    );
    _safeSetState(() {
      _selectedShapeStrokeId = start.strokeId;
      _activeShapeManipulator = start.manipulator;
      _activeShapeHandle = start.handle;
      _activeShapeEditOp = start.operation;
      _shapeInteractionStartNorm = start.startNorm;
      _shapeInteractionLastNorm = start.startNorm;
      _shapeRotateSnappedAngleRad = null;
      _shapeRotateGestureStartAngleRad = start.rotateGestureStartAngleRad;
      _shapeRotateGestureStartRotationRad = start.rotateGestureStartRotationRad;
      _shapeCreateHasMoved = false;
      _shapeCreateThresholdNorm = start.createThresholdNorm;
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
      if (_activeShapeEditOp == ShapeInteractionOperation.create) {
        final start = _shapeInteractionStartNorm ?? norm;
        final adjustedEnd = ShapeInteractionCoordinator.constrainCreateEndNorm(
          start,
          norm,
          pageSize: pageSize,
          aspectLocked: _isShapeAspectLocked,
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
          case ShapeInteractionOperation.translate:
            manipulator.translate(delta);
            break;
          case ShapeInteractionOperation.resize:
            final currentBounds = manipulator.boundsNorm;
            final lockedAspectRatio =
                _isShapeAspectLocked &&
                    currentBounds.width > 0 &&
                    currentBounds.height > 0
                ? currentBounds.width / currentBounds.height
                : null;
            manipulator.resizeByHandle(
              _activeShapeHandle,
              delta,
              lockedAspectRatio: lockedAspectRatio,
            );
            break;
          case ShapeInteractionOperation.rotate:
            if (_isShapeRotateSnapEnabled) {
              final rotationUpdate = ShapeInteractionCoordinator.rotateWithSnap(
                manipulator: manipulator,
                norm: norm,
                pageSize: pageSize,
                gestureStartAngleRad: _shapeRotateGestureStartAngleRad,
                gestureStartRotationRad: _shapeRotateGestureStartRotationRad,
                currentSnappedAngleRad: _shapeRotateSnappedAngleRad,
              );
              _shapeRotateSnappedAngleRad = rotationUpdate.snappedAngleRad;
              manipulator.rotationRad = rotationUpdate.rotationRad;
            } else {
              _shapeRotateSnappedAngleRad = null;
              manipulator.rotationRad =
                  ShapeInteractionCoordinator.rawRotateTargetAngle(
                    manipulator: manipulator,
                    norm: norm,
                    pageSize: pageSize,
                    gestureStartAngleRad: _shapeRotateGestureStartAngleRad,
                    gestureStartRotationRad:
                        _shapeRotateGestureStartRotationRad,
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
      _clearShapeInteractionState();
      return;
    }

    if (_activeShapeEditOp == ShapeInteractionOperation.none) {
      _clearShapeInteractionState();
      return;
    }

    if (_activeShapeEditOp == ShapeInteractionOperation.create) {
      final createBounds = manipulator.boundsNorm;
      final createWidth = createBounds.width.abs();
      final createHeight = createBounds.height.abs();
      final minCreateSizeNorm = _shapeCreateThresholdNorm <= 0
          ? 0.004
          : _shapeCreateThresholdNorm;
      if (!_shapeCreateHasMoved ||
          createWidth < minCreateSizeNorm ||
          createHeight < minCreateSizeNorm) {
        _clearShapeSelection();
        return;
      }
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
        fillArgb: _currentShapeFillColor?.toARGB32(),
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
        _activeShapeEditOp = ShapeInteractionOperation.none;
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
      _clearShapeInteractionState();
      return;
    }
    final before = _canvasController.findStrokeById(pageNumber, selectedId);
    if (before == null) {
      _clearShapeInteractionState();
      return;
    }
    final beforeBounds = _shapeStrokeBounds(before.pointsNorm);
    if (beforeBounds == null) {
      _clearShapeInteractionState();
      return;
    }

    final afterPoints = ShapeInteractionCoordinator.transformPointsByBounds(
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
          : List<Object?>.from(before.erasedSegments!),
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
      _activeShapeEditOp = ShapeInteractionOperation.none;
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

  int? _createdIndexFromId(String id) {
    return int.tryParse(id);
  }

  Future<Site?> _handleTapFlow({
    required MarkerHitResult? hitResult,
    required TapDecision decision,
    required int pageIndex,
    required double normalizedX,
    required double normalizedY,
  }) {
    return _markerActionCoordinator.handleTap(
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
      deflectionMemberOptions: drawingDeflectionMemberOptions,
      nextSettlementIndex: nextSettlementIndex,
    );
  }

  bool get _isStylusRequiredMarkerPlacementMode {
    return MarkerInputGuard.requiresStylusForPlacement(_mode);
  }

  bool _isMarkerPlacementPointerAllowed(PointerDeviceKind kind) {
    return MarkerInputGuard.allowMarkerPlacementPointer(
      mode: _mode,
      kind: kind,
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
    if (distance > drawingTapSlop) {
      _tapCanceled = true;
    }
  }

  void _handlePointerUp() {
    _pointerDownPosition = null;
  }

  void _handlePointerCancel() {
    _pointerDownPosition = null;
    _tapCanceled = false;
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
      _activeStylusPointerId = null;
      _isFreeDrawConsumingOneFinger = false;
      _pendingDraw = false;
      _pendingDrawDownViewportLocal = null;
    });
    drawingVerboseLog('[Eraser] modeChanged next=$tool');
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
    drawingVerboseLog(
      '[Eraser] radiusChanged px=${nextRadius.toStringAsFixed(1)}',
    );
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
    required AreaEraserSession session,
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
    _activeAreaEraserSession = AreaEraserSession(radius: _areaEraserRadiusPx);
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
    _pendingAreaEraserMove = PendingAreaEraserMove(
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
        drawingVerboseLog(
          '[Drawing] eraserCommit page=$page candidates=${items.length} '
          'maskedDelta=$totalMaskedDelta tick=${_canvasController.cacheRebuildTick.value}',
        );
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

  AreaEraserSession _applyAreaEraserPointMask(
    AreaEraserSession session, {
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
            : List<Object?>.from(sourceStroke.erasedSegments!),
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
    _pendingFreeDrawMove = PendingFreeDrawMove(
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
    final bool isStraightenModeEnabled = isHighlighterFamily
        ? _isHighlighterStraightenModeEnabled
        : _isPenStraightenModeEnabled;
    final bool isStraightenSnapEnabled = isHighlighterFamily
        ? _isHighlighterStraightenSnapEnabled
        : _isPenStraightenSnapEnabled;
    final shouldRenderStraightPreview =
        isStraightenModeEnabled && (isPenFamily || isHighlighterFamily);
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
          isStraightenSnapEnabled && nearestDiff <= snapToleranceRad;
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

      _pendingStraightenCommitByPointer[pointerId] = PendingStraightenCommit(
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

      if (kDrawingVerboseLogging) {
        final start = inProgressStroke.pointsNorm.first;
        final dx = (normalized.dx - start.dx) * destSize.width;
        final dy = (normalized.dy - start.dy) * destSize.height;
        drawingVerboseLog(
          '[Drawing][Straighten] update rawDx=${dx.toStringAsFixed(2)} '
          'rawDy=${dy.toStringAsFixed(2)} snapped=$processedNormalized '
          'appended=$didAppend '
          'highlighter=$isHighlighterFamily',
        );
      }
      final newPoints = _buildStraightLinePointsNorm(
        startNorm: startNorm,
        endNorm: processedNormalized,
        destSize: destSize,
        photoScale: photoScale,
      );
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
    inProgressStroke.pointsNorm.addAll(additions);
    _canvasController.setLiveStroke(inProgressStroke, forceNotify: true);
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
      drawingVerboseLog(
        '[Drawing] commit stroke=${committedStroke.id} '
        'page=$pageNumber points=${committedStroke.pointsNorm.length} '
        'tick=${_canvasController.cacheRebuildTick.value}',
      );
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
    _requestPersistDrawing(immediate: true);
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
    _requestPersistDrawing(immediate: true);
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
        // Lock previous free-draw tool selection when switching tabs/modes.
        _activeTool = DrawingTool.pen;
        _activePresetIndex = null;
        _selectedShapeStrokeId = null;
        _activeShapeManipulator = null;
        _activeShapeHandle = ShapeHandle.none;
        _activeShapeEditOp = ShapeInteractionOperation.none;
        _shapeRotateSnappedAngleRad = null;
        _shapeRotateGestureStartAngleRad = null;
        _shapeRotateGestureStartRotationRad = null;
        _shapeInteractionStartNorm = null;
        _shapeInteractionLastNorm = null;
        _shapeCreateHasMoved = false;
        _shapeCreateThresholdNorm = 0.0;
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
}
