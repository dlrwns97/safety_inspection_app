part of 'drawing_screen.dart';

extension _DrawingScreenUi on _DrawingScreenState {
  List<Widget> _buildMarkerWidgetsForPage({
    required Size size,
    required int pageIndex,
  }) => [
    ..._buildMarkersForPage(
      items: _site.defects.where(
        (defect) => _visibleDefectCategories.contains(defect.category),
      ),
      pageIndex: pageIndex,
      pageOf: (defect) => defect.pageIndex,
      pageSize: size,
      markerScale: _markerScale,
      isSelected: (defect) =>
          _selectedDefectId != null && defect.id == _selectedDefectId,
      nx: (defect) => defect.normalizedX,
      ny: (defect) => defect.normalizedY,
      buildMarker: (defect, selected) => DefectMarkerWidget(
        label: defectDisplayLabel(defect, allDefects: _site.defects),
        category: defect.category,
        color: defectCategoryConfig(defect.category).color,
        isSelected: selected,
        scale: _markerScale,
        labelScale: _labelScale,
      ),
    ),
    ..._buildMarkersForPage(
      items: _site.equipmentMarkers.where(
        (marker) => _visibleEquipmentCategories.contains(marker.category),
      ),
      pageIndex: pageIndex,
      pageOf: (marker) => marker.pageIndex,
      pageSize: size,
      markerScale: _markerScale,
      isSelected: (marker) =>
          _selectedEquipmentId != null && marker.id == _selectedEquipmentId,
      nx: (marker) => marker.normalizedX,
      ny: (marker) => marker.normalizedY,
      buildMarker: (marker, selected) => EquipmentMarkerWidget(
        label: equipmentDisplayLabel(marker, _site.equipmentMarkers),
        category: marker.category,
        color: equipmentColor(marker.category),
        isSelected: selected,
        scale: _markerScale,
        labelScale: _labelScale,
      ),
    ),
  ];

  PreferredSizeWidget _buildAppBar() {
    final drawingTopBar = _buildDrawingTopBar();
    return AppBar(
      title: Text(_site.name),
      actions: [
        if (_site.drawingType == DrawingType.pdf)
          IconButton(
            tooltip: StringsKo.replacePdfTooltip,
            icon: const Icon(Icons.upload_file_outlined),
            onPressed: _replacePdf,
          ),
      ],
      bottom: drawingTopBar,
    );
  }

  Widget _buildDrawingOverlayShell() {
    final isPdf = _site.drawingType == DrawingType.pdf;
    final bool canMove = _isMoveMode && _hasMoveTarget;
    final bool showFloatingToolSettings =
        isPdf && _isFreeDrawMode && _selectedToolKindForToolbar != null;
    return DrawingOverlayShell(
      isPdf: isPdf,
      canMove: canMove,
      showFloatingToolSettings: showFloatingToolSettings,
      pdfLayer: PdfViewLayer(
        pdfViewer: _buildPdfViewer(),
        currentPage: _currentPage,
        pageCount: _pageCount,
        canPrev: _currentPage > 1,
        canNext: _currentPage < _pageCount,
        onPrevPage: _handlePrevPage,
        onNextPage: _handleNextPage,
      ),
      canvasLayer: _buildCanvasDrawingLayer(),
      floatingToolSettingsButton: _buildFloatingToolSettingsButton(),
      onMovePanStart: _handleMoveOverlayPanStart,
      onMovePanUpdate: isPdf
          ? _handleMovePdfOverlayPanUpdate
          : _handleMoveCanvasOverlayPanUpdate,
      onMovePanEnd: _handleMovePanEnd,
      onMovePanCancel: _handleMovePanCancel,
    );
  }

  Widget _buildCanvasDrawingLayer() {
    final theme = Theme.of(context);
    return _wrapWithPointerHandlers(
      tapRegionKey: _canvasTapRegionKey,
      onTapUp: _handleCanvasTap,
      onLongPressStart: _handleCanvasLongPress,
      onMovePanUpdate: _handleMoveCanvasPanUpdate,
      child: _buildCanvasViewer(theme),
    );
  }

  Widget _buildRightPanelOverlayToggle({
    required bool isCollapsed,
    required VoidCallback onToggle,
  }) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: theme.colorScheme.surface,
        shape: const CircleBorder(),
        elevation: 2,
        child: InkResponse(
          onTap: onToggle,
          customBorder: const CircleBorder(),
          child: Center(
            child: Icon(
              isCollapsed ? Icons.chevron_left : Icons.chevron_right,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMarkerSidePanel({
    required DefectCategory? defectFilter,
    required EquipmentCategory? equipmentFilter,
  }) {
    return MarkerSidePanel(
      tabController: _sidePanelController,
      currentPage: _currentPage,
      defects: _site.defects,
      equipmentMarkers: _site.equipmentMarkers,
      selectedDefect: _selectedDefect,
      selectedEquipment: _selectedEquipment,
      selectedDefectCategory: defectFilter,
      selectedEquipmentCategory: equipmentFilter,
      onSelectDefect: _selectDefectFromPanel,
      onSelectEquipment: _selectEquipmentFromPanel,
      onDefectCategorySelected: (category) => _safeSetState(() {
        if (_activeCategory == category) {
          _activeCategory = null;
          _sidePanelDefectCategory = null;
        } else {
          _activeCategory = category;
          _sidePanelDefectCategory = category;
        }
      }),
      onEquipmentCategorySelected: (category) => _safeSetState(() {
        if (_activeEquipmentCategory == category) {
          _activeEquipmentCategory = null;
          _sidePanelEquipmentCategory = null;
        } else {
          _activeEquipmentCategory = category;
          _sidePanelEquipmentCategory = category;
        }
      }),
      visibleDefectCategories: _visibleDefectCategories,
      visibleEquipmentCategories: _visibleEquipmentCategories,
      onDefectVisibilityChanged: (category, visible) => _safeSetState(() {
        if (visible) {
          _visibleDefectCategories.add(category);
        } else {
          _visibleDefectCategories.remove(category);
        }
      }),
      onEquipmentVisibilityChanged: _handleEquipmentVisibilityChanged,
      markerScale: _markerScale,
      labelScale: _labelScale,
      onMarkerScaleChanged: _handleMarkerScaleChanged,
      onLabelScaleChanged: _handleLabelScaleChanged,
      isMarkerScaleLocked: _isScaleLocked,
      onToggleMarkerScaleLock: _toggleScaleLock,
      onEditPressed: _handleEditPressed,
      onMovePressed: _handleMovePressed,
      onDeletePressed: _handleDeletePressed,
    );
  }

  Widget _buildPdfViewer() {
    _ensurePdfFallbackPageSize(context);
    // Keep touch behavior identical to defect/equipment modes:
    // finger can swipe pages and pinch pan/zoom.
    // Stylus navigation is still blocked by stylus arena blocker in free-draw.
    final bool enablePdfPanGestures = true;
    final bool enablePdfScaleGestures = true;
    final bool disablePageSwipe = false;
    if (kDebugMode && enablePdfPanGestures && enablePdfScaleGestures) {
      _debugLogPhotoViewBaseStateOnce('viewer-build');
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return PdfDrawingView(
          pdfController: _pdfController,
          pdfLoadError: _pdfLoadError,
          sitePdfName: _site.pdfName,
          onPageChanged: _handlePdfPageChanged,
          onDocumentLoaded: _handlePdfDocumentLoaded,
          onDocumentError: _handlePdfDocumentError,
          pageSizes: _pdfPageSizes,
          pdfViewVersion: _pdfViewVersion,
          onUpdatePageSize: _handleUpdatePageSize,
          photoControllerForPage: _photoControllerForPage,
          scaleStateControllerForPage: _scaleStateControllerForPage,
          enablePdfPanGestures: enablePdfPanGestures,
          enablePdfScaleGestures: enablePdfScaleGestures,
          disablePageSwipe: disablePageSwipe,
          viewportSize: constraints.biggest,
          pageContentKeyForPage: _pdfPageContentKeyForPage,
          buildPageOverlay:
              ({
                required pageSize,
                required renderSize,
                required pageNumber,
                required imageProvider,
                required pageContentKey,
              }) => _buildPdfPageOverlay(
                pageSize: pageSize,
                renderSize: renderSize,
                pageNumber: pageNumber,
                imageProvider: imageProvider,
                pageContentKey: pageContentKey,
              ),
        );
      },
    );
  }

  void _ensurePdfFallbackPageSize(BuildContext context) {
    if (_pdfPageSizes.isNotEmpty || _pdfPageSizes.containsKey(_currentPage)) {
      return;
    }
    final mq = MediaQuery.of(context).size;
    final fallbackSize = Size(
      math.max(_kMinValidPdfPageSide, mq.width * 0.9),
      math.max(_kMinValidPdfPageSide, mq.height * 0.9),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _pdfPageSizes.isNotEmpty ||
          _pdfPageSizes.containsKey(_currentPage)) {
        return;
      }
      _safeSetState(() => _pdfPageSizes[_currentPage] = fallbackSize);
    });
  }

  Widget _buildPdfPageOverlay({
    required Size pageSize,
    required Size renderSize,
    required int pageNumber,
    required ImageProvider imageProvider,
    required Key pageContentKey,
  }) {
    final tapKey = _pdfTapRegionKeyForPage(pageNumber);
    final Size overlaySize = renderSize;
    final FittedSizes fitted = applyBoxFit(
      BoxFit.contain,
      pageSize,
      overlaySize,
    );
    final Size destSize = fitted.destination;
    final double dx = (overlaySize.width - destSize.width) / 2;
    final double dy = (overlaySize.height - destSize.height) / 2;
    final Rect destRect = Offset(dx, dy) & destSize;
    final double scale = pageSize.width == 0
        ? 0
        : destSize.width / pageSize.width;

    Offset overlayToPage(Offset overlayLocal) {
      if (scale == 0) {
        return Offset.zero;
      }
      return (overlayLocal - destRect.topLeft) / scale;
    }

    Offset? drawingLocalToPageLocal(Offset overlayLocal) {
      if (!destRect.contains(overlayLocal)) {
        return null;
      }
      return overlayToPage(overlayLocal);
    }

    double currentPhotoScale() {
      final s = _photoControllerForPage(pageNumber).value.scale;
      return (s == null || s <= 0) ? 1.0 : s;
    }

    final stylusOverlayBehavior = (_isFreeDrawMode && _isStylusActive)
        ? HitTestBehavior.opaque
        : HitTestBehavior.translucent;
    ShapeType? overlayPreviewType;
    StrokeStyle? overlayPreviewStroke;
    int? overlayPreviewFillArgb;
    List<Offset>? overlayPreviewPointsNorm;
    if (_isFreeDrawMode &&
        _activeTool == DrawingTool.shape &&
        _activeShapeManipulator != null) {
      if (_activeShapeEditOp == _ShapeEditOperation.create) {
        overlayPreviewType = _activeShapeType;
        overlayPreviewStroke = _activeShapeStrokeStyle;
        overlayPreviewFillArgb = _activeShapeFillColor?.value;
      } else if (_selectedShapeStrokeId != null) {
        final selected = _canvasController.findStrokeById(
          pageNumber,
          _selectedShapeStrokeId!,
        );
        final resolvedType = _shapeTypeFromStored(selected?.shapeType);
        if (selected != null && resolvedType != null) {
          overlayPreviewType = resolvedType;
          overlayPreviewStroke = selected.style;
          overlayPreviewFillArgb = selected.shapeFillArgb;
          overlayPreviewPointsNorm = selected.pointsNorm;
        }
      }
    }
    final blockStylusFromPdfGestures =
        _isFreeDrawMode || _isStylusRequiredMarkerPlacementMode;

    return _wrapWithPointerHandlers(
      tapRegionKey: tapKey,
      behavior: HitTestBehavior.opaque,
      // Marker tap mapping must remain overlayToPage(details.localPosition) to keep marker under finger. Do not change.
      onTapUp: (details) {
        if (_isStrokeEraserActive || _isAreaEraserActive) {
          return;
        }
        if (!destRect.contains(details.localPosition)) {
          return;
        }
        _handlePdfTapAt(
          overlayToPage(details.localPosition),
          pageSize,
          pageNumber,
          details.kind,
        );
      },
      onLongPressStart: (details) {
        if (!destRect.contains(details.localPosition)) {
          return;
        }
        _handlePdfLongPressAt(
          overlayToPage(details.localPosition),
          pageSize,
          pageNumber,
        );
      },
      onMovePanUpdate: (details) => _handleMovePdfPanUpdate(
        details,
        overlaySize,
        pageNumber,
        context,
        destRect: destRect,
      ),
      child: RawGestureDetector(
        behavior: HitTestBehavior.translucent,
        gestures: blockStylusFromPdfGestures
            ? <Type, GestureRecognizerFactory>{
                _StylusArenaBlocker:
                    GestureRecognizerFactoryWithHandlers<_StylusArenaBlocker>(
                      () => _StylusArenaBlocker(),
                      (_StylusArenaBlocker instance) {},
                    ),
              }
            : const <Type, GestureRecognizerFactory>{},
        child: SizedBox.expand(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              KeyedSubtree(
                key: pageContentKey,
                child: SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: pageSize.width,
                      height: pageSize.height,
                      child: Image(image: imageProvider, fit: BoxFit.fill),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: destRect.left,
                top: destRect.top,
                width: destRect.width,
                height: destRect.height,
                child: FittedBox(
                  fit: BoxFit.fill,
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: pageSize.width,
                    height: pageSize.height,
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        ..._buildMarkerWidgetsForPage(
                          size: pageSize,
                          pageIndex: pageNumber,
                        ),
                        Positioned.fill(
                          child: DrawingCanvasWidget(
                            controller: _canvasController,
                            cacheManager: _strokeCacheManager,
                            page: pageNumber,
                            canvasSize: pageSize,
                            devicePixelRatio: MediaQuery.devicePixelRatioOf(
                              context,
                            ),
                            eraserRadius: _areaEraserRadiusPx,
                          ),
                        ),
                        if (_isFreeDrawMode &&
                            _activeTool == DrawingTool.shape &&
                            _activeShapeManipulator != null)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: ShapeHandlesOverlay(
                                manipulator: _activeShapeManipulator!,
                                canvasSize: pageSize,
                                previewType: overlayPreviewType,
                                previewStroke: overlayPreviewStroke,
                                previewFillArgb: overlayPreviewFillArgb,
                                previewPointsNorm: overlayPreviewPointsNorm,
                                createStartNorm:
                                    _activeShapeEditOp ==
                                        _ShapeEditOperation.create
                                    ? _shapeInteractionStartNorm
                                    : null,
                                createCurrentNorm:
                                    _activeShapeEditOp ==
                                        _ShapeEditOperation.create
                                    ? _shapeInteractionLastNorm
                                    : null,
                                showBounds:
                                    _activeShapeEditOp !=
                                    _ShapeEditOperation.create,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!_isFreeDrawMode)
                Positioned.fill(
                  child: RawGestureDetector(
                    behavior: HitTestBehavior.opaque,
                    gestures: <Type, GestureRecognizerFactory>{
                      _TouchOnlyScaleGestureRecognizer:
                          GestureRecognizerFactoryWithHandlers<
                            _TouchOnlyScaleGestureRecognizer
                          >(_TouchOnlyScaleGestureRecognizer.new, (
                            _TouchOnlyScaleGestureRecognizer instance,
                          ) {
                            instance
                              ..onStart = (details) {
                                if (_isStylusActive) {
                                  return;
                                }
                                _handlePdfNavigationScaleStart(details);
                              }
                              ..onUpdate = (details) {
                                if (_isStylusActive) {
                                  return;
                                }
                                _handlePdfNavigationScaleUpdate(details);
                              }
                              ..onEnd = (details) {
                                if (_isStylusActive) {
                                  return;
                                }
                                _handlePdfNavigationScaleEnd(details);
                              };
                          }),
                    },
                    child: const ColoredBox(color: Colors.transparent),
                  ),
                ),
              Positioned.fill(
                child: Listener(
                  behavior: stylusOverlayBehavior,
                  onPointerDown: (e) {
                    _handleOverlayPointerDownWithStylusDrawing(
                      e,
                      pageNumber: pageNumber,
                      pageSize: pageSize,
                      drawingLocalToPageLocal: drawingLocalToPageLocal,
                      photoScale: currentPhotoScale(),
                    );
                  },
                  onPointerMove: (e) {
                    _handleOverlayPointerMoveWithStylusDrawing(
                      e,
                      pageNumber: pageNumber,
                      pageSize: pageSize,
                      drawingLocalToPageLocal: drawingLocalToPageLocal,
                      photoScale: currentPhotoScale(),
                    );
                  },
                  onPointerUp: (e) {
                    _handleOverlayPointerUpOrCancelWithStylusDrawing(
                      e,
                      pageNumber: pageNumber,
                      pageSize: pageSize,
                      drawingLocalToPageLocal: drawingLocalToPageLocal,
                    );
                  },
                  onPointerCancel: (e) {
                    _handleOverlayPointerUpOrCancelWithStylusDrawing(
                      e,
                      pageNumber: pageNumber,
                      pageSize: pageSize,
                      drawingLocalToPageLocal: drawingLocalToPageLocal,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCanvasViewer(ThemeData theme) {
    Offset? drawingLocalToPageLocal(Offset local) {
      if (local.dx < 0 ||
          local.dy < 0 ||
          local.dx > DrawingCanvasSize.width ||
          local.dy > DrawingCanvasSize.height) {
        return null;
      }
      return local;
    }

    double currentCanvasPhotoScale() {
      final scale = _transformationController.value.getMaxScaleOnAxis();
      if (!scale.isFinite || scale <= 0) {
        return 1.0;
      }
      return scale;
    }

    ShapeType? overlayPreviewType;
    StrokeStyle? overlayPreviewStroke;
    int? overlayPreviewFillArgb;
    List<Offset>? overlayPreviewPointsNorm;
    if (_isFreeDrawMode &&
        _activeTool == DrawingTool.shape &&
        _activeShapeManipulator != null) {
      if (_activeShapeEditOp == _ShapeEditOperation.create) {
        overlayPreviewType = _activeShapeType;
        overlayPreviewStroke = _activeShapeStrokeStyle;
        overlayPreviewFillArgb = _activeShapeFillColor?.value;
      } else if (_selectedShapeStrokeId != null) {
        final selected = _canvasController.findStrokeById(
          _currentPage,
          _selectedShapeStrokeId!,
        );
        final resolvedType = _shapeTypeFromStored(selected?.shapeType);
        if (selected != null && resolvedType != null) {
          overlayPreviewType = resolvedType;
          overlayPreviewStroke = selected.style;
          overlayPreviewFillArgb = selected.shapeFillArgb;
          overlayPreviewPointsNorm = selected.pointsNorm;
        }
      }
    }

    final blockStylusFromCanvasGestures = _isFreeDrawMode;
    return RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: blockStylusFromCanvasGestures
          ? <Type, GestureRecognizerFactory>{
              _StylusArenaBlocker:
                  GestureRecognizerFactoryWithHandlers<_StylusArenaBlocker>(
                    () => _StylusArenaBlocker(),
                    (_StylusArenaBlocker instance) {},
                  ),
            }
          : const <Type, GestureRecognizerFactory>{},
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: DrawingCanvasMinScale,
        maxScale: DrawingCanvasMaxScale,
        panEnabled:
            !_isMoveMode && (_isFreeDrawMode || _isPanScaleAllowedDuringDraw),
        scaleEnabled:
            !_isMoveMode && (_isFreeDrawMode || _isPanScaleAllowedDuringDraw),
        constrained: false,
        child: SizedBox(
          key: _canvasKey,
          width: DrawingCanvasSize.width,
          height: DrawingCanvasSize.height,
          child: Stack(
            children: [
              _buildMarkerLayer(
                size: DrawingCanvasSize,
                pageIndex: _currentPage,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: CustomPaint(
                    painter: GridPainter(
                      lineColor: theme.colorScheme.outlineVariant,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DrawingCanvasWidget(
                  controller: _canvasController,
                  cacheManager: _strokeCacheManager,
                  page: _currentPage,
                  canvasSize: DrawingCanvasSize,
                  devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
                  eraserRadius: _areaEraserRadiusPx,
                ),
              ),
              Positioned.fill(
                child: Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (e) {
                    _handleOverlayPointerDownWithStylusDrawing(
                      e,
                      pageNumber: _currentPage,
                      pageSize: DrawingCanvasSize,
                      drawingLocalToPageLocal: drawingLocalToPageLocal,
                      photoScale: currentCanvasPhotoScale(),
                    );
                  },
                  onPointerMove: (e) {
                    _handleOverlayPointerMoveWithStylusDrawing(
                      e,
                      pageNumber: _currentPage,
                      pageSize: DrawingCanvasSize,
                      drawingLocalToPageLocal: drawingLocalToPageLocal,
                      photoScale: currentCanvasPhotoScale(),
                    );
                  },
                  onPointerUp: (e) {
                    _handleOverlayPointerUpOrCancelWithStylusDrawing(
                      e,
                      pageNumber: _currentPage,
                      pageSize: DrawingCanvasSize,
                      drawingLocalToPageLocal: drawingLocalToPageLocal,
                    );
                  },
                  onPointerCancel: (e) {
                    _handleOverlayPointerUpOrCancelWithStylusDrawing(
                      e,
                      pageNumber: _currentPage,
                      pageSize: DrawingCanvasSize,
                      drawingLocalToPageLocal: drawingLocalToPageLocal,
                    );
                  },
                ),
              ),
              if (_isFreeDrawMode &&
                  _activeTool == DrawingTool.shape &&
                  _activeShapeManipulator != null)
                IgnorePointer(
                  child: ShapeHandlesOverlay(
                    manipulator: _activeShapeManipulator!,
                    canvasSize: DrawingCanvasSize,
                    previewType: overlayPreviewType,
                    previewStroke: overlayPreviewStroke,
                    previewFillArgb: overlayPreviewFillArgb,
                    previewPointsNorm: overlayPreviewPointsNorm,
                    createStartNorm:
                        _activeShapeEditOp == _ShapeEditOperation.create
                        ? _shapeInteractionStartNorm
                        : null,
                    createCurrentNorm:
                        _activeShapeEditOp == _ShapeEditOperation.create
                        ? _shapeInteractionLastNorm
                        : null,
                    showBounds:
                        _activeShapeEditOp != _ShapeEditOperation.create,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoveModeBottomBar() {
    final theme = Theme.of(context);
    final canCommit = _hasPendingMove;
    return SafeArea(
      top: false,
      child: Material(
        elevation: 8,
        color: theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _cancelMoveMode,
                  child: const Text('취소'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: canCommit ? _commitMovePreview : null,
                  child: const Text('적용'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _wrapWithPointerHandlers({
    required Widget child,
    required GestureTapUpCallback onTapUp,
    GestureLongPressStartCallback? onLongPressStart,
    GestureDragUpdateCallback? onMovePanUpdate,
    HitTestBehavior behavior = HitTestBehavior.opaque,
    Key? tapRegionKey,
  }) {
    final bool allowTapInFreeDraw =
        _isFreeDrawMode && (_activeTool == DrawingTool.shape);
    return DrawingCanvasShell(
      behavior: behavior,
      tapRegionKey: tapRegionKey,
      child: child,
      isMoveMode: _isMoveMode,
      isFreeDrawMode: _isFreeDrawMode,
      allowTapInFreeDraw: allowTapInFreeDraw,
      hasMoveTarget: _hasMoveTarget,
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      onTapUp: onTapUp,
      onLongPressStart: onLongPressStart,
      onMovePanUpdate: onMovePanUpdate,
      onMovePanStart: _handleMovePanStartGlobal,
      onMovePanEnd: _handleMovePanEnd,
      onMovePanCancel: _handleMovePanCancel,
    );
  }
}

class _StylusArenaBlocker extends OneSequenceGestureRecognizer {
  @override
  String get debugDescription => 'stylusArenaBlocker';

  bool _isStylus(PointerDeviceKind kind) {
    return kind == PointerDeviceKind.stylus ||
        kind == PointerDeviceKind.invertedStylus;
  }

  @override
  bool isPointerAllowed(PointerDownEvent event) {
    return _isStylus(event.kind);
  }

  @override
  void addAllowedPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer);
    resolve(GestureDisposition.accepted);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {}
}

class _TouchOnlyScaleGestureRecognizer extends ScaleGestureRecognizer {
  @override
  bool isPointerAllowed(PointerEvent event) {
    if (event.kind != PointerDeviceKind.touch) {
      return false;
    }

    if (event is PointerDownEvent) {
      return super.isPointerAllowed(event);
    }

    // For non-down events, allow; the arena decision is made on down.
    return true;
  }
}
