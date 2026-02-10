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
      if (_isFreeDrawMode)
        Positioned(
          left: 12,
          top: 12,
          child: _buildStrokePresetPanel(),
        ),
    ];
  }

  Widget _buildStrokePresetPanel() {
    final theme = Theme.of(context);
    final filteredEntries = _presets.asMap().entries.where((entry) {
      return switch (_presetGroup) {
        PresetGroup.pen => entry.value.kind == StrokeToolKind.pen,
        PresetGroup.highlighter =>
          entry.value.kind == StrokeToolKind.highlighter,
      };
    }).toList();

    return Material(
      color: theme.colorScheme.surface.withOpacity(0.96),
      elevation: 3,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 150,
              child: SegmentedButton<PresetGroup>(
                segments: const [
                  ButtonSegment<PresetGroup>(
                    value: PresetGroup.pen,
                    label: Text('펜'),
                  ),
                  ButtonSegment<PresetGroup>(
                    value: PresetGroup.highlighter,
                    label: Text('형광펜'),
                  ),
                ],
                selected: <PresetGroup>{_presetGroup},
                onSelectionChanged: (selection) {
                  if (selection.isEmpty) {
                    return;
                  }
                  setState(() => _presetGroup = selection.first);
                },
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 68,
              height: 304,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: filteredEntries.map((entry) {
                    final index = entry.key;
                    final style = entry.value;
                    final selected = _activePresetIndex == index;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: GestureDetector(
                        onLongPress: () => _showPresetEditorSheet(index),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => setState(() => _activePresetIndex = index),
                          child: Container(
                            width: 60,
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outlineVariant,
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(_iconForVariant(style.variant), size: 16),
                                const SizedBox(height: 4),
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(style.argbColor).withOpacity(
                                      style.opacity,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  height: style.widthPx.clamp(1, 6).toDouble(),
                                  width: 28,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100),
                                    color: Color(style.argbColor),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForVariant(PenVariant variant) {
    return switch (variant) {
      PenVariant.ballpoint => Icons.edit,
      PenVariant.fountain => Icons.create,
      PenVariant.pencil => Icons.draw,
      PenVariant.marker => Icons.brush,
      PenVariant.calligraphy => Icons.gesture,
      PenVariant.highlighterSoft => Icons.highlight,
      PenVariant.highlighterChisel => Icons.highlight_alt,
    };
  }

  Future<void> _showPresetEditorSheet(int index) async {
    StrokeStyle draft = _presets[index];
    final selected = await showModalBottomSheet<StrokeStyle>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            const palette = <int>[
              0xFF000000,
              0xFFE53935,
              0xFF1E88E5,
              0xFF43A047,
              0xFFFFEB3B,
              0xFFFB8C00,
            ];
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('프리셋 ${index + 1} 편집', style: Theme.of(context).textTheme.titleMedium),
                    Slider(
                      min: 1,
                      max: 24,
                      value: draft.widthPx.clamp(1, 24).toDouble(),
                      label: '두께 ${draft.widthPx.toStringAsFixed(1)}',
                      onChanged: (v) => setModalState(() => draft = draft.copyWith(widthPx: v)),
                    ),
                    Slider(
                      min: 0.1,
                      max: 1.0,
                      value: draft.opacity.clamp(0.1, 1.0).toDouble(),
                      label: '불투명도 ${draft.opacity.toStringAsFixed(2)}',
                      onChanged: (v) => setModalState(() => draft = draft.copyWith(opacity: v)),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...palette.map(
                          (color) => GestureDetector(
                            onTap: () => setModalState(() => draft = draft.copyWith(argbColor: color)),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(color),
                                border: Border.all(
                                  color: draft.argbColor == color
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () async {
                            final color = await _showCustomColorPickerDialog(draft.argbColor);
                            if (color == null) return;
                            setModalState(() => draft = draft.copyWith(argbColor: color));
                          },
                          child: const Text('커스텀'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: () => Navigator.of(sheetContext).pop(draft),
                        child: const Text('적용'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (selected == null) {
      return;
    }
    setState(() => _presets[index] = selected);
  }

  Future<int?> _showCustomColorPickerDialog(int initialColor) async {
    int red = (initialColor >> 16) & 0xFF;
    int green = (initialColor >> 8) & 0xFF;
    int blue = initialColor & 0xFF;
    return showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final selected = 0xFF000000 | (red << 16) | (green << 8) | blue;
            return AlertDialog(
              title: const Text('색상 선택'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 64, height: 32, color: Color(selected)),
                  Slider(
                    min: 0,
                    max: 255,
                    value: red.toDouble(),
                    onChanged: (v) => setDialogState(() => red = v.round()),
                    activeColor: Colors.red,
                  ),
                  Slider(
                    min: 0,
                    max: 255,
                    value: green.toDouble(),
                    onChanged: (v) => setDialogState(() => green = v.round()),
                    activeColor: Colors.green,
                  ),
                  Slider(
                    min: 0,
                    max: 255,
                    value: blue.toDouble(),
                    onChanged: (v) => setDialogState(() => blue = v.round()),
                    activeColor: Colors.blue,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(selected),
                  child: const Text('선택'),
                ),
              ],
            );
          },
        );
      },
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

  Widget _buildPdfViewer() {
    _ensurePdfFallbackPageSize(context);
    final bool isTwoFinger = _activePointerIds.length >= 2;
    const bool enablePdfPanGestures = true;
    const bool enablePdfScaleGestures = true;
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

    return _wrapWithPointerHandlers(
      tapRegionKey: tapKey,
      behavior: HitTestBehavior.opaque,
      // Marker tap mapping must remain overlayToPage(details.localPosition) to keep marker under finger. Do not change.
      onTapUp: (details) {
        if (!destRect.contains(details.localPosition)) {
          return;
        }
        _handlePdfTapAt(
          overlayToPage(details.localPosition),
          pageSize,
          pageNumber,
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
        gestures: <Type, GestureRecognizerFactory>{
          _StylusArenaBlocker:
              GestureRecognizerFactoryWithHandlers<_StylusArenaBlocker>(
                () => _StylusArenaBlocker(),
                (_StylusArenaBlocker instance) {},
              ),
        },
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
                                const <DrawingStroke>[],
                            inProgress: _inProgressStroke?.pageNumber == pageNumber
                                ? _inProgressStroke
                                : null,
                            pageSize: pageSize,
                            debugLastPageLocal:
                                kDebugMode && _inProgressStroke?.pageNumber == pageNumber
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
              Positioned.fill(
                child: Listener(
                  behavior: (_isFreeDrawMode &&
                          _activeStylusPointerId != null &&
                          !_hasAnyTouchPointer())
                      ? HitTestBehavior.opaque
                      : HitTestBehavior.translucent,
                  onPointerDown:
                      (e) => _handleOverlayPointerDownWithStylusDrawing(
                    e,
                    pageNumber: pageNumber,
                    pageSize: pageSize,
                    drawingLocalToPageLocal: drawingLocalToPageLocal,
                    photoScale: currentPhotoScale(),
                  ),
                  onPointerMove:
                      (e) => _handleOverlayPointerMoveWithStylusDrawing(
                    e,
                    pageNumber: pageNumber,
                    pageSize: pageSize,
                    drawingLocalToPageLocal: drawingLocalToPageLocal,
                    photoScale: currentPhotoScale(),
                  ),
                  onPointerUp:
                      (e) => _handleOverlayPointerUpOrCancelWithStylusDrawing(
                    e,
                    pageNumber: pageNumber,
                  ),
                  onPointerCancel: (e) =>
                      _handleOverlayPointerUpOrCancelWithStylusDrawing(
                        e,
                        pageNumber: pageNumber,
                      ),
                ),
              ),
            ],
          ),
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
