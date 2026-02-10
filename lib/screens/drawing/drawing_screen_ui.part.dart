part of 'drawing_screen.dart';

class _OneFingerDrawGestureRecognizer extends OneSequenceGestureRecognizer {
  _OneFingerDrawGestureRecognizer({
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
    required this.onCancel,
    required this.isTwoFingerNow,
    this.createDotOnTap = true,
  });

  final void Function(Offset localPos) onStart;
  final void Function(Offset localPos) onUpdate;
  final VoidCallback onEnd;
  final VoidCallback onCancel;
  final bool Function() isTwoFingerNow;
  final bool createDotOnTap;

  int? _primaryPointer;
  bool _accepted = false;
  Offset? _downLocal;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (_primaryPointer == null) {
      _primaryPointer = event.pointer;
      _downLocal = event.localPosition;
      startTrackingPointer(event.pointer);
    } else {
      resolve(GestureDisposition.rejected);
      onCancel();
      stopTrackingPointer(_primaryPointer!);
      _reset();
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    if (_primaryPointer != event.pointer) {
      return;
    }

    if (isTwoFingerNow()) {
      if (_accepted) {
        onEnd();
      } else {
        onCancel();
      }
      resolve(GestureDisposition.rejected);
      stopTrackingPointer(_primaryPointer!);
      _reset();
      return;
    }

    if (event is PointerMoveEvent) {
      if (!_accepted) {
        resolve(GestureDisposition.accepted);
        _accepted = true;
        final downLocal = _downLocal;
        if (downLocal != null) {
          onStart(downLocal);
        }
      }
      onUpdate(event.localPosition);
    } else if (event is PointerUpEvent) {
      if (_accepted) {
        onEnd();
      } else if (createDotOnTap) {
        final downLocal = _downLocal;
        if (downLocal != null) {
          onStart(downLocal);
          onUpdate(downLocal);
          onEnd();
        }
      } else {
        onCancel();
      }
      stopTrackingPointer(event.pointer);
      _reset();
    } else if (event is PointerCancelEvent) {
      onCancel();
      stopTrackingPointer(event.pointer);
      _reset();
    }
  }

  void _reset() {
    _primaryPointer = null;
    _accepted = false;
    _downLocal = null;
  }

  @override
  String get debugDescription => 'oneFingerDraw';

  @override
  void didStopTrackingLastPointer(int pointer) {}
}

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
      isSelected: (defect) =>
          _selectedDefectId != null && defect.id == _selectedDefectId,
      nx: (defect) => defect.normalizedX,
      ny: (defect) => defect.normalizedY,
      buildMarker: (defect, selected) => DefectMarkerWidget(
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
            onPanUpdate: isPdf
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

  Widget _buildPdfViewer() {
    _ensurePdfFallbackPageSize(context);
    final bool isTwoFinger = _activePointerIds.length >= 2;
    // PhotoView cannot reliably start pinch if gestures are disabled at first
    // pointer-down. Keep gestures enabled so the first down is delivered;
    // the drawing layer already ignores input when 2 pointers exist.
    final bool enablePdfPanGestures = true;
    final bool enablePdfScaleGestures = true;
    // Keep page swipe disabled while drawing with 1 finger to prevent
    // accidental page flips. Allow swipe again when 2 fingers are down.
    final bool disablePageSwipe = _isFreeDrawMode && !isTwoFinger;
    if (kDebugMode) {
      debugPrint(
        '[FreeDraw] isTwoFinger: $isTwoFinger, panEnabled: $enablePdfPanGestures, '
        'scaleEnabled: $enablePdfScaleGestures, swipeDisabled: $disablePageSwipe',
      );
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
    const bool createDotOnTap = true;
    final tapKey = _pdfTapRegionKeyForPage(pageNumber);
    final bool enablePageLocalDrawing = _isFreeDrawMode;
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

    bool isInsidePageOverlay(Offset overlayPos) => destRect.contains(overlayPos);

    Offset destLocalToPage(Offset destLocal) {
      if (scale == 0) {
        return Offset.zero;
      }
      return destLocal / scale;
    }

    Offset overlayToPage(Offset p) {
      if (scale == 0) {
        return Offset.zero;
      }
      return (p - destRect.topLeft) / scale;
    }

    return _wrapWithPointerHandlers(
      tapRegionKey: tapKey,
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) {
        if (!isInsidePageOverlay(details.localPosition)) {
          return;
        }
        _handlePdfTapAt(
          overlayToPage(details.localPosition),
          pageSize,
          pageNumber,
        );
      },
      onLongPressStart: (details) {
        if (!isInsidePageOverlay(details.localPosition)) {
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
                        child: CustomPaint(
                          painter: TempPolylinePainter(
                            strokes:
                                _strokesByPage[pageNumber] ??
                                const <List<Offset>>[],
                            inProgress: _inProgressPage == pageNumber
                                ? _inProgress
                                : null,
                            pageSize: pageSize,
                            debugLastPageLocal:
                                kDebugMode && _inProgressPage == pageNumber
                                ? _debugLastPageLocal
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: destRect.left,
              top: destRect.top,
              width: destRect.width,
              height: destRect.height,
              child: IgnorePointer(
                ignoring:
                    !enablePageLocalDrawing || _activePointerIds.length >= 2,
                child: RawGestureDetector(
                  behavior: HitTestBehavior.opaque,
                  gestures: {
                    _OneFingerDrawGestureRecognizer:
                        GestureRecognizerFactoryWithHandlers<
                          _OneFingerDrawGestureRecognizer
                        >(
                          () => _OneFingerDrawGestureRecognizer(
                            isTwoFingerNow: () =>
                                _activePointerIds.length >= 2,
                            createDotOnTap: createDotOnTap,
                            onStart: (destLocal) {
                              if (_activePointerIds.length >= 2) {
                                return;
                              }
                              if (kDebugMode) {
                                debugPrint(
                                  '[FreeDraw] panStart local=$destLocal '
                                  'pointers: ${_activePointerIds.length}',
                                );
                              }
                              final pageP = destLocalToPage(destLocal);
                              final normalized = _overlayToNormalizedPoint(
                                overlayLocal: pageP,
                                destSize: pageSize,
                              );
                              if (normalized == null) {
                                return;
                              }
                              _debugLastPageLocal = pageP;
                              _handleFreeDrawPointerStart(
                                normalized,
                                pageNumber,
                              );
                            },
                            onUpdate: (destLocal) {
                              if (_activePointerIds.length >= 2) {
                                return;
                              }
                              if (kDebugMode) {
                                debugPrint(
                                  '[FreeDraw] panUpdate local=$destLocal '
                                  'pointers: ${_activePointerIds.length}',
                                );
                              }
                              final pageP = destLocalToPage(destLocal);
                              final normalized = _overlayToNormalizedPoint(
                                overlayLocal: pageP,
                                destSize: pageSize,
                              );
                              if (normalized == null) {
                                return;
                              }
                              _debugLastPageLocal = pageP;
                              _handleFreeDrawPointerUpdate(
                                normalized,
                                pageNumber,
                                pageSize,
                              );
                            },
                            onEnd: () {
                              if (kDebugMode) {
                                debugPrint(
                                  '[FreeDraw] onPointerUp, pointers: '
                                  '${_activePointerIds.length}',
                                );
                              }
                              _handleFreeDrawPointerEnd(pageNumber);
                            },
                            onCancel: () {
                              if (kDebugMode) {
                                debugPrint(
                                  '[FreeDraw] onPointerCancel, pointers: '
                                  '${_activePointerIds.length}',
                                );
                              }
                              _handleFreeDrawPanCancel();
                            },
                          ),
                          (instance) {},
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
    final GestureTapUpCallback? tapHandler = (_isMoveMode || _isFreeDrawMode)
        ? null
        : onTapUp;
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
