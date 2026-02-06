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
      pageSize: size,
      markerScale: _markerScale,
      isSelected:
          (defect) =>
              _selectedDefectId != null &&
              defect.id == _selectedDefectId,
      nx: (defect) => defect.normalizedX,
      ny: (defect) => defect.normalizedY,
      buildMarker:
          (defect, selected) => DefectMarkerWidget(
        label: defectDisplayLabel(defect),
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
      pageSize: size,
      markerScale: _markerScale,
      isSelected:
          (marker) =>
              _selectedEquipmentId != null &&
              marker.id == _selectedEquipmentId,
      nx: (marker) => marker.normalizedX,
      ny: (marker) => marker.normalizedY,
      buildMarker:
          (marker, selected) => EquipmentMarkerWidget(
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

  List<Widget> _buildDrawingStackChildren() {
    final isPdf = _site.drawingType == DrawingType.pdf;
    final bool canMove = _isMoveMode && _hasMoveTarget;
    return [
      if (isPdf)
        AbsorbPointer(
          absorbing: _isMoveMode,
          child: PdfViewLayer(
            pdfViewer: _buildPdfViewer(),
            currentPage: _currentPage,
            pageCount: _pageCount,
            canPrev: _currentPage > 1,
            canNext: _currentPage < _pageCount,
            onPrevPage: _handlePrevPage,
            onNextPage: _handleNextPage,
          ),
        )
      else
        _buildCanvasDrawingLayer(),
      if (canMove)
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: _handleMoveOverlayPanStart,
            onPanUpdate:
                isPdf
                    ? _handleMovePdfOverlayPanUpdate
                    : _handleMoveCanvasOverlayPanUpdate,
            onPanEnd: (_) => _handleMovePanEnd(),
            onPanCancel: _handleMovePanCancel,
          ),
        ),
    ];
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

  PdfDrawingView _buildPdfViewer() {
    _ensurePdfFallbackPageSize(context);
    final bool isTwoFinger = _activePointerIds.length >= 2;
    final bool enablePdfPanGestures = !_isFreeDrawMode || isTwoFinger;
    final bool enablePdfScaleGestures = true;
    final bool disablePageSwipe = _isFreeDrawMode && !isTwoFinger;
    return PdfDrawingView(
      key: _pdfViewerKey,
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
      buildPageOverlay:
          ({required pageSize, required pageNumber, required imageProvider}) =>
              _buildPdfPageOverlay(
                pageSize: pageSize,
                pageNumber: pageNumber,
                imageProvider: imageProvider,
              ),
    );
  }

  void _ensurePdfFallbackPageSize(BuildContext context) {
    if (_pdfPageSizes.isNotEmpty ||
        _pdfPageSizes.containsKey(_currentPage)) {
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
    required int pageNumber,
    required ImageProvider imageProvider,
  }) {
    final tapKey = _pdfTapRegionKeyForPage(pageNumber);
    return Builder(
      builder:
          (tapContext) => LayoutBuilder(
            builder: (context, constraints) {
              var overlaySize = Size(
                constraints.maxWidth,
                constraints.maxHeight,
              );
              if (!constraints.hasBoundedWidth ||
                  !constraints.hasBoundedHeight) {
                overlaySize = pageSize;
              }
              if (overlaySize.width <= 0 || overlaySize.height <= 0) {
                overlaySize = pageSize;
              }
              final fittedSizes = applyBoxFit(
                BoxFit.contain,
                pageSize,
                overlaySize,
              );
              final destRect = Alignment.center.inscribe(
                fittedSizes.destination,
                Offset.zero & overlaySize,
              );
              _pdfPageDestRects[pageNumber] = destRect;
              final bool isTwoFinger = _activePointerIds.length >= 2;
              final bool enableOverlayDrawing = _isFreeDrawMode && !isTwoFinger;
              return _wrapWithPointerHandlers(
                tapRegionKey: tapKey,
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) => _handlePdfTap(
                  details,
                  overlaySize,
                  pageNumber,
                  tapContext,
                  destRect: destRect,
                ),
                onLongPressStart: (details) => _handlePdfLongPress(
                  details,
                  overlaySize,
                  pageNumber,
                  tapContext,
                  destRect: destRect,
                ),
                onMovePanUpdate:
                    (details) => _handleMovePdfPanUpdate(
                      details,
                      overlaySize,
                      pageNumber,
                      tapContext,
                      destRect: destRect,
                    ),
                child: SizedBox(
                  width: overlaySize.width,
                  height: overlaySize.height,
                  child: Stack(
                    children: [
                      Positioned.fromRect(
                        rect: destRect,
                        child: _buildMarkerLayer(
                          size: destRect.size,
                          pageIndex: pageNumber,
                          child: SizedBox.expand(
                            child: Image(
                              image: imageProvider,
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                      ),
                      Positioned.fromRect(
                        rect: destRect,
                        child: ClipRect(
                          child: IgnorePointer(
                            ignoring: !enableOverlayDrawing,
                            child: RawGestureDetector(
                              behavior: HitTestBehavior.opaque,
                              gestures: <Type, GestureRecognizerFactory>{
                                SingleFingerPanRecognizer:
                                    GestureRecognizerFactoryWithHandlers<
                                      SingleFingerPanRecognizer
                                    >(
                                      SingleFingerPanRecognizer.new,
                                      (SingleFingerPanRecognizer recognizer) {
                                        recognizer
                                          ..onStart = (localPosition) {
                                            final contentPoint =
                                                _toPdfContentPoint(
                                                  pageNumber: pageNumber,
                                                  viewLocalPosition:
                                                      localPosition,
                                                  contentSize: destRect.size,
                                                );
                                            _handleFreeDrawPointerStart(
                                              contentPoint,
                                              pageNumber,
                                            );
                                          }
                                          ..onUpdate = (localPosition) {
                                            final contentPoint =
                                                _toPdfContentPoint(
                                                  pageNumber: pageNumber,
                                                  viewLocalPosition:
                                                      localPosition,
                                                  contentSize: destRect.size,
                                                );
                                            _handleFreeDrawPointerUpdate(
                                              contentPoint,
                                              pageNumber,
                                            );
                                          }
                                          ..onEnd = () {
                                            _handleFreeDrawPointerEnd(
                                              pageNumber,
                                            );
                                          }
                                          ..onCancel =
                                              _handleFreeDrawPanCancel;
                                      },
                                    ),
                              },
                              child: CustomPaint(
                                painter: TempPolylinePainter(
                                  strokes:
                                      _strokesByPage[pageNumber] ??
                                      const <List<Offset>>[],
                                  inProgress:
                                      _inProgressPage == pageNumber
                                      ? _inProgress
                                      : null,
                                ),
                                child: const SizedBox.expand(),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Keep pointer counting across the full overlay so
                      // two-finger detection still works outside destRect.
                      Positioned.fill(
                        child: Listener(
                          behavior: HitTestBehavior.translucent,
                          onPointerDown: _handleOverlayPointerDown,
                          onPointerUp: _handleOverlayPointerUpOrCancel,
                          onPointerCancel: _handleOverlayPointerUpOrCancel,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  Widget _buildCanvasViewer(ThemeData theme) {
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: DrawingCanvasMinScale,
      maxScale: DrawingCanvasMaxScale,
      panEnabled: !_isMoveMode,
      scaleEnabled: !_isMoveMode,
      constrained: false,
      child: SizedBox(
        key: _canvasKey,
        width: DrawingCanvasSize.width,
        height: DrawingCanvasSize.height,
        child: _buildMarkerLayer(
          size: DrawingCanvasSize,
          pageIndex: _currentPage,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: CustomPaint(
              painter: GridPainter(lineColor: theme.colorScheme.outlineVariant),
            ),
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
                  child: const Text('변경'),
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
    final GestureTapUpCallback? tapHandler =
        _isMoveMode ? null : onTapUp;
    final GestureLongPressStartCallback? longPressHandler =
        _isMoveMode ? null : onLongPressStart;
    final bool canMove = _isMoveMode && _hasMoveTarget;
    final GestureDragUpdateCallback? movePanUpdate =
        canMove ? onMovePanUpdate : null;
    return Listener(
      behavior: behavior,
      onPointerDown: (e) => _handlePointerDown(e.localPosition),
      onPointerMove: (e) => _handlePointerMove(e.localPosition),
      onPointerUp: (_) => _handlePointerUp(),
      onPointerCancel: (_) => _handlePointerCancel(),
      child: GestureDetector(
        behavior: behavior,
        onTapUp: tapHandler,
        onLongPressStart: longPressHandler,
        onPanStart: canMove ? (_) => _handleMovePanStartGlobal() : null,
        onPanUpdate: movePanUpdate,
        onPanEnd: canMove ? (_) => _handleMovePanEnd() : null,
        onPanCancel: canMove ? _handleMovePanCancel : null,
        child: KeyedSubtree(key: tapRegionKey, child: child),
      ),
    );
  }
}
