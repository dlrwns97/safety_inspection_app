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
      if (_isFreeDrawMode && _isToolPanelOpen)
        Positioned(
          left: 12,
          right: 12,
          top: 12,
          child: _buildStrokePresetPanel(),
        ),
      if (_isFreeDrawMode && !_isToolPanelOpen)
        Positioned(
          top: 12,
          right: 12,
          child: FloatingActionButton.small(
            heroTag: 'tool-panel-open',
            onPressed: () => _setToolPanelOpen(true),
            child: const Icon(Icons.edit),
          ),
        ),
    ];
  }

  Widget _buildStrokePresetPanel() {
    final theme = Theme.of(context);
    final screenW = MediaQuery.of(context).size.width;
    final panelMaxW = screenW * 0.52;
    final panelMinW = screenW * 0.34;
    final toolIndexes = <int>[0, 1, 4, 5];

    Widget panelButton({
      required IconData icon,
      required bool selected,
      required VoidCallback onTap,
      String? tooltip,
    }) {
      return Tooltip(
        message: tooltip ?? '',
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          onLongPress: () {
            if (tooltip == null || tooltip.isEmpty) {
              return;
            }
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(tooltip), duration: const Duration(milliseconds: 800)));
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: selected
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
            ),
            child: Icon(
              icon,
              size: 20,
              color: selected
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final style = _activeStrokeStyleOrFallback;
    final hasActiveTool = _activeStrokeStyle != null;
    final showOpacity = style.kind == StrokeToolKind.highlighter;
    final colorRow = <int>[
      ..._standardPaletteArgb.take(8),
      ..._recentArgb.take(2),
    ];

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: panelMaxW, minWidth: panelMinW),
      child: Material(
        elevation: 4,
        color: theme.colorScheme.surface.withOpacity(0.98),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final index in toolIndexes) ...[
                            panelButton(
                              icon: _iconForVariant(_presets[index].variant),
                              selected: _activePresetIndex == index,
                              tooltip: _labelForVariant(_presets[index].variant),
                              onTap: () => _toggleActivePreset(index),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _setToolPanelOpen(false),
                    icon: const Icon(Icons.close),
                    tooltip: '닫기',
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: !hasActiveTool || style.widthPx <= 1
                      ? null
                      : () => _updateActivePreset(style.copyWith(widthPx: (style.widthPx - 1).clamp(1, 48).toDouble())),
                  icon: const Icon(Icons.remove),
                ),
                Expanded(
                  child: Slider(
                    value: style.widthPx.clamp(1.0, 48.0),
                    min: 1,
                    max: 48,
                    divisions: 47,
                    label: style.widthPx.round().toString(),
                    onChanged: hasActiveTool
                        ? (v) => _updateActivePreset(style.copyWith(widthPx: v))
                        : null,
                  ),
                ),
                IconButton(
                  onPressed: !hasActiveTool || style.widthPx >= 48
                      ? null
                      : () => _updateActivePreset(style.copyWith(widthPx: (style.widthPx + 1).clamp(1, 48).toDouble())),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            if (showOpacity)
              Row(
                children: [
                  const SizedBox(width: 8),
                  const Text('투명도'),
                  Expanded(
                    child: Slider(
                      value: style.opacity.clamp(0.05, 1.0),
                      min: 0.05,
                      max: 1.0,
                      onChanged: hasActiveTool
                          ? (v) =>
                              _updateActivePreset(style.copyWith(opacity: v))
                          : null,
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    child: Text('${(style.opacity * 100).round()}%'),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final argb in colorRow)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _colorCircle(
                              argb,
                              selected: style.argbColor == argb,
                              onTap: !hasActiveTool
                                  ? () {}
                                  : () {
                                      _updateActivePreset(
                                        style.copyWith(argbColor: argb),
                                      );
                                      _pushRecentColor(argb);
                                    },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: hasActiveTool ? _openColorDialog : null,
                  icon: const Icon(Icons.colorize),
                  tooltip: '색상 선택',
                ),
              ],
            ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForVariant(PenVariant variant) {
    return switch (variant) {
      PenVariant.fountainPen => Icons.edit,
      PenVariant.calligraphyPen => Icons.brush,
      PenVariant.pen => Icons.edit_outlined,
      PenVariant.pencil => Icons.create_outlined,
      PenVariant.highlighter => Icons.highlight,
      PenVariant.highlighterChisel => Icons.highlight_alt,
      PenVariant.marker => Icons.border_color,
      PenVariant.markerChisel => Icons.draw,
    };
  }

  String _labelForVariant(PenVariant variant) {
    return switch (variant) {
      PenVariant.fountainPen => '펜 라운드',
      PenVariant.calligraphyPen => '펜 치즐',
      PenVariant.pen => '펜',
      PenVariant.pencil => '연필',
      PenVariant.highlighter => '형광펜 라운드',
      PenVariant.highlighterChisel => '형광펜 치즐',
      PenVariant.marker => '마커 펜',
      PenVariant.markerChisel => '직선 마커 펜',
    };
  }

  Widget _colorCircle(int argb, {required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color(argb),
          border: Border.all(
            width: selected ? 3 : 1,
            color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
    );
  }

  Future<void> _openColorDialog() async {
    final style = _activeStrokeStyleOrFallback;
    Color selected = Color(style.argbColor);
    double opacity = style.opacity;
    HSVColor hsv = HSVColor.fromColor(selected.withOpacity(1));
    bool useStandardTab = true;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: StatefulBuilder(
            builder: (ctx, setD) {
              void applyColor(Color c) {
                selected = c;
                hsv = HSVColor.fromColor(c.withOpacity(1));
                setD(() {});
              }

              void applyOpacity(double v) {
                opacity = v;
                setD(() {});
              }

              Widget tabButton(String text, bool active, VoidCallback onTap) {
                return InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: active ? Theme.of(ctx).colorScheme.primaryContainer : Theme.of(ctx).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(text),
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(child: tabButton('표준', useStandardTab, () => setD(() => useStandardTab = true))),
                        const SizedBox(width: 8),
                        Expanded(child: tabButton('사용자 지정', !useStandardTab, () => setD(() => useStandardTab = false))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (useStandardTab) ...[
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final argb in _standardPaletteArgb)
                            _colorCircle(argb, selected: selected.value == argb, onTap: () => applyColor(Color(argb))),
                        ],
                      ),
                      if (_recentArgb.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Align(alignment: Alignment.centerLeft, child: Text('최근', style: Theme.of(ctx).textTheme.labelLarge)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final argb in _recentArgb)
                              _colorCircle(argb, selected: selected.value == argb, onTap: () => applyColor(Color(argb))),
                          ],
                        ),
                      ],
                    ] else ...[
                      _HsvColorSquare(
                        hsv: hsv,
                        onChanged: (next) {
                          hsv = next;
                          applyColor(next.toColor());
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text('Hue'),
                          Expanded(
                            child: Slider(
                              min: 0,
                              max: 360,
                              value: hsv.hue,
                              onChanged: (v) {
                                hsv = hsv.withHue(v);
                                applyColor(hsv.toColor());
                              },
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text('투명도'),
                          Expanded(
                            child: Slider(
                              min: 0.05,
                              max: 1.0,
                              value: opacity.clamp(0.05, 1.0),
                              onChanged: applyOpacity,
                            ),
                          ),
                          Text('${(opacity * 100).round()}%'),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '#${selected.value.toRadixString(16).padLeft(8, '0').toUpperCase()}  R ${selected.red}  G ${selected.green}  B ${selected.blue}',
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('취소'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              final argb = selected.value;
                              final base = _activeStrokeStyleOrFallback;
                              var next = base.copyWith(argbColor: argb);
                              if (base.kind == StrokeToolKind.highlighter) {
                                next = next.copyWith(opacity: opacity);
                              }
                              _updateActivePreset(next);
                              _pushRecentColor(argb);
                              Navigator.pop(ctx);
                            },
                            child: const Text('완료'),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
          ),
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


class _HsvColorSquare extends StatelessWidget {
  const _HsvColorSquare({required this.hsv, required this.onChanged});

  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, 180);

        void update(Offset localPosition) {
          final s = (localPosition.dx / size.width).clamp(0.0, 1.0);
          final v = (1 - (localPosition.dy / size.height)).clamp(0.0, 1.0);
          onChanged(hsv.withSaturation(s).withValue(v));
        }

        return SizedBox(
          width: double.infinity,
          height: size.height,
          child: GestureDetector(
            onPanDown: (d) => update(d.localPosition),
            onPanUpdate: (d) => update(d.localPosition),
            onTapDown: (d) => update(d.localPosition),
            child: CustomPaint(
              painter: _HsvColorSquarePainter(hsv: hsv),
            ),
          ),
        );
      },
    );
  }
}

class _HsvColorSquarePainter extends CustomPainter {
  const _HsvColorSquarePainter({required this.hsv});

  final HSVColor hsv;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final hueColor = HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor();

    canvas.drawRect(rect, Paint()..color = hueColor);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Colors.white, Colors.transparent],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(rect),
    );

    final dx = hsv.saturation * size.width;
    final dy = (1 - hsv.value) * size.height;
    final thumb = Offset(dx, dy);
    canvas.drawCircle(
      thumb,
      8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );
    canvas.drawCircle(
      thumb,
      10,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.black54,
    );
  }

  @override
  bool shouldRepaint(covariant _HsvColorSquarePainter oldDelegate) {
    return oldDelegate.hsv != hsv;
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
