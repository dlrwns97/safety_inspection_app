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
      pageContentKeyForPage: _pdfPageContentKeyForPage,
      buildPageOverlay:
          ({
            required pageSize,
            required pageNumber,
            required imageProvider,
            required pageContentKey,
          }) => _buildPdfPageOverlay(
                pageSize: pageSize,
                pageNumber: pageNumber,
                imageProvider: imageProvider,
                pageContentKey: pageContentKey,
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
    required Key pageContentKey,
  }) {
    final tapKey = _pdfTapRegionKeyForPage(pageNumber);
    final bool isTwoFinger = _activePointerIds.length >= 2;
    final bool enablePageLocalDrawing = _isFreeDrawMode && !isTwoFinger;
    return _wrapWithPointerHandlers(
      tapRegionKey: tapKey,
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) => _handlePdfTap(
        details,
        pageSize,
        pageNumber,
        context,
        destRect: Offset.zero & pageSize,
      ),
      onLongPressStart: (details) => _handlePdfLongPress(
        details,
        pageSize,
        pageNumber,
        context,
        destRect: Offset.zero & pageSize,
      ),
      onMovePanUpdate:
          (details) => _handleMovePdfPanUpdate(
            details,
            pageSize,
            pageNumber,
            context,
            destRect: Offset.zero & pageSize,
          ),
      child: SizedBox(
        width: pageSize.width,
        height: pageSize.height,
        child: Stack(
          children: [
            KeyedSubtree(
              key: pageContentKey,
              child: _buildMarkerLayer(
                size: pageSize,
                pageIndex: pageNumber,
                child: SizedBox.expand(
                  child: Image(
                    image: imageProvider,
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: TempPolylinePainter(
                  strokes: _strokesByPage[pageNumber] ?? const <List<Offset>>[],
                  inProgress: _inProgressPage == pageNumber ? _inProgress : null,
                  pageSize: pageSize,
                  debugLastPageLocal:
                      kDebugMode && _inProgressPage == pageNumber
                          ? _debugLastPageLocal
                          : null,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !enablePageLocalDrawing,
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
                              ..onStart = (pointerDetails) {
                                final p = pointerDetails.localPosition;
                                if (p.dx < 0 ||
                                    p.dx > pageSize.width ||
                                    p.dy < 0 ||
                                    p.dy > pageSize.height) {
                                  return;
                                }
                                _debugLastPageLocal = p;
                                final norm = Offset(
                                  p.dx / pageSize.width,
                                  p.dy / pageSize.height,
                                );
                                _handleFreeDrawPointerStart(
                                  norm,
                                  pageNumber,
                                );
                              }
                              ..onUpdate = (pointerDetails) {
                                final p = pointerDetails.localPosition;
                                if (p.dx < 0 ||
                                    p.dx > pageSize.width ||
                                    p.dy < 0 ||
                                    p.dy > pageSize.height) {
                                  return;
                                }
                                _debugLastPageLocal = p;
                                final norm = Offset(
                                  p.dx / pageSize.width,
                                  p.dy / pageSize.height,
                                );
                                _handleFreeDrawPointerUpdate(
                                  norm,
                                  pageNumber,
                                );
                              }
                              ..onEnd = () {
                                _handleFreeDrawPointerEnd(pageNumber);
                              }
                              ..onCancel = _handleFreeDrawPanCancel;
                          },
                        ),
                  },
                  child: const SizedBox.expand(),
                ),
              ),
            ),
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
        (_isMoveMode || _isFreeDrawMode) ? null : onTapUp;
    final GestureLongPressStartCallback? longPressHandler =
        (_isMoveMode || _isFreeDrawMode) ? null : onLongPressStart;
    final bool canMove = _isMoveMode && _hasMoveTarget;
    final GestureDragUpdateCallback? movePanUpdate =
        (_isFreeDrawMode || !canMove) ? null : onMovePanUpdate;
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
