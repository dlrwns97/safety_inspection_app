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
    ];
  }

  Widget _colorCircle(
    int argb, {
    required bool selected,
    required VoidCallback onTap,
  }) {
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
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
    );
  }

  Future<void> _selectToolAndOpenSettings(StrokeToolKind kind) async {
    if (!mounted) {
      return;
    }
    if (kDebugMode) {
      debugPrint('TOOL change: $kind');
    }
    if (_selectedToolKindForToolbar == kind) {
      _settingsPopover.hide();
      _deactivateActiveFreeDrawTool();
      return;
    }

    switch (kind) {
      case StrokeToolKind.pen:
        _activateStrokeKind(kind);
        _handleDrawingToolChanged(DrawingTool.pen);
        _showPenSettingsPopover();
        return;
      case StrokeToolKind.highlighter:
        _activateStrokeKind(kind);
        _handleDrawingToolChanged(DrawingTool.pen);
        _showHighlighterSettingsPopover();
        return;
      case StrokeToolKind.shape:
        _handleDrawingToolChanged(DrawingTool.shape);
        _showShapeSettingsPopover();
        return;
      case StrokeToolKind.eraser:
        final nextEraserTool = _activeTool == DrawingTool.strokeEraser
            ? DrawingTool.strokeEraser
            : DrawingTool.areaEraser;
        _handleDrawingToolChanged(nextEraserTool);
        _showEraserSettingsPopover();
        return;
    }
  }

  void _activateStrokeKind(StrokeToolKind kind) {
    final family = kind == StrokeToolKind.highlighter
        ? ToolFamily.highlighter
        : ToolFamily.pen;
    _safeSetState(() {
      _activeFamily = family;
      final index = _presets.indexWhere((style) => style.kind == kind);
      if (index >= 0) {
        _activePresetIndex = index;
        _syncCurrentFamilyStyleToPreset();
      }
    });
  }

  void _showPopover({required LayerLink link, required Widget child}) {
    _settingsPopover.show(context: context, link: link, child: child);
  }

  void _showEraserSettingsPopover() {
    if (!mounted) {
      return;
    }
    _showPopover(
      link: _eraserLink,
      child: EraserSettingsPopup(
        radiusPx: _areaEraserRadiusPx,
        onRadiusChanged: _handleAreaEraserRadiusChanged,
        mode: _activeTool == DrawingTool.strokeEraser
            ? DrawingTool.strokeEraser
            : DrawingTool.areaEraser,
        onModeChanged: _handleDrawingToolChanged,
        onClearPenOnly: _clearCurrentPagePenStrokes,
        onClearHighlighterOnly: _clearCurrentPageHighlighterStrokes,
        onClearAll: _clearCurrentPageAllStrokes,
        onClose: _settingsPopover.hide,
      ),
    );
  }

  void _showHighlighterSettingsPopover() {
    if (!mounted) {
      return;
    }
    _showPopover(
      link: _highlighterLink,
      child: ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[
          _highlighterVariantNotifier,
          _highlighterWidthNotifier,
          _highlighterOpacityNotifier,
          _highlighterColorNotifier,
        ]),
        builder: (context, _) => HighlighterSettingsPopup(
          currentVariant: _highlighterVariantNotifier.value,
          currentHighlighterWidth: _highlighterWidthNotifier.value,
          currentHighlighterOpacity: _highlighterOpacityNotifier.value,
          currentHighlighterColor: _highlighterColorNotifier.value,
          recentColors: _recentArgb.map(Color.new).toList(growable: false),
          standardPaletteColors: _standardPaletteArgb
              .map(Color.new)
              .toList(growable: false),
          isStraightenModeEnabled: _isStraightenModeEnabled,
          straightenSnapEnabled: _isStraightenSnapEnabled,
          onVariantChanged: _handleHighlighterVariantChanged,
          onWidthChanged: _handleHighlighterWidthChanged,
          onOpacityChanged: _handleHighlighterOpacityChanged,
          onColorChanged: _handleHighlighterColorChanged,
          onStraightenModeChanged: (enabled) {
            _safeSetState(() {
              _isStraightenModeEnabled = enabled;
              if (!enabled) {
                _straightenSnappedAngleByPointer.clear();
                _straightenStartPageByPointer.clear();
                _resetHighlighterStraightenState();
              }
            });
            unawaited(_saveDrawingSettings());
          },
          onStraightenSnapChanged: (enabled) {
            _safeSetState(() {
              _isStraightenSnapEnabled = enabled;
              if (!enabled) {
                _straightenSnappedAngleByPointer.clear();
              }
            });
            unawaited(_saveDrawingSettings());
          },
          onOpenAllColors: () {
            _settingsPopover.hide();
            _openEyedropperColorDialog();
          },
          onClose: _settingsPopover.hide,
        ),
      ),
    );
  }

  void _showPenSettingsPopover() {
    if (!mounted) {
      return;
    }
    _showPopover(
      link: _penLink,
      child: ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[
          _penVariantNotifier,
          _penWidthNotifier,
          _penColorNotifier,
        ]),
        builder: (context, _) => PenSettingsPopup(
          currentVariant: _penVariantNotifier.value,
          currentPenWidth: _penWidthNotifier.value,
          currentPenColor: _penColorNotifier.value,
          recentColors: _recentArgb.map(Color.new).toList(growable: false),
          standardPaletteColors: _standardPaletteArgb
              .map(Color.new)
              .toList(growable: false),
          isStraightenModeEnabled: _isStraightenModeEnabled,
          straightenSnapEnabled: _isStraightenSnapEnabled,
          onVariantChanged: _handlePenVariantChanged,
          onWidthChanged: _handlePenWidthChanged,
          onColorChanged: _handlePenColorChanged,
          onStraightenModeChanged: (enabled) {
            _safeSetState(() {
              _isStraightenModeEnabled = enabled;
              if (!enabled) {
                _straightenSnappedAngleByPointer.clear();
                _straightenStartPageByPointer.clear();
                _resetHighlighterStraightenState();
              }
            });
            unawaited(_saveDrawingSettings());
          },
          onStraightenSnapChanged: (enabled) {
            _safeSetState(() {
              _isStraightenSnapEnabled = enabled;
              if (!enabled) {
                _straightenSnappedAngleByPointer.clear();
              }
            });
            unawaited(_saveDrawingSettings());
          },
          onOpenAllColors: () {
            _settingsPopover.hide();
            _openEyedropperColorDialog();
          },
          onClose: _settingsPopover.hide,
        ),
      ),
    );
  }

  Future<void> _openEyedropperColorDialog() async {
    final currentStyle = _activeStrokeStyleOrFallback;
    final originalColor = Color(currentStyle.argbColor);
    final recentColors = _recentArgb.map(Color.new).toList(growable: false);

    assert(() {
      debugPrint('OPEN NEW COLOR PICKER');
      return true;
    }());

    final kept = await showDrawingColorPickerDialog(
      context,
      initialColor: originalColor,
      recentColors: recentColors,
      onLiveChanged: (color) {
        _applyCurrentStyleValues(color: color);
      },
      onCommitChanged: (color) {
        _applyCurrentStyleValues(color: color, pushRecentColor: true);
      },
    );

    if (kept) {
      return;
    }
    _applyCurrentStyleValues(color: originalColor);
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
    final int touchCount = _activeTouchPointerCount;
    final bool isTwoFingerTouch = touchCount >= 2;
    final bool isStylusActive = _isStylusActive;
    final bool enablePdfPanGestures = true;
    final bool enablePdfScaleGestures = true;
    // Keep page swipe disabled while drawing with 1 finger to prevent
    // accidental page flips. Allow swipe again when 2 fingers are down.
    final bool disablePageSwipe =
        _isFreeDrawMode && (isStylusActive || !isTwoFingerTouch);
    if (kDebugMode) {
      debugPrint(
        '[FreeDraw] touchCount: $touchCount, isStylusActive: $isStylusActive, '
        'isTwoFingerTouch: $isTwoFingerTouch, panEnabled: $enablePdfPanGestures, '
        'scaleEnabled: $enablePdfScaleGestures, swipeDisabled: $disablePageSwipe',
      );
    }
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
    if (_activeTool == DrawingTool.shape && _activeShapeManipulator != null) {
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
                        if (_activeTool == DrawingTool.shape &&
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
                              if (kDebugMode) {
                                debugPrint(
                                  'SCALE UPDATE pointerCount=${details.pointerCount}',
                                );
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
    if (_activeTool == DrawingTool.shape && _activeShapeManipulator != null) {
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

    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: DrawingCanvasMinScale,
      maxScale: DrawingCanvasMaxScale,
      panEnabled: !_isMoveMode && _isPanScaleAllowedDuringDraw,
      scaleEnabled: !_isMoveMode && _isPanScaleAllowedDuringDraw,
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
            if (_activeTool == DrawingTool.shape &&
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
                  showBounds: _activeShapeEditOp != _ShapeEditOperation.create,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showShapeSettingsPopover() {
    if (!mounted) {
      return;
    }
    _settingsPopover.hide();
    final shapeTypes = ShapeType.values.toList(growable: false);
    const fixedPalette = <int>[
      0xFFE53935, // red
      0xFFFF9800, // orange
      0xFFFFEB3B, // yellow
      0xFF43A047, // green
      0xFF1E88E5, // blue
    ];

    List<int> buildPalette() {
      final recent = <int>[];
      for (final argb in _recentArgb) {
        if (fixedPalette.contains(argb)) {
          continue;
        }
        recent.add(argb);
        if (recent.length == 2) {
          break;
        }
      }
      const fallback = <int>[0xFF000000, 0xFFFFFFFF];
      for (final argb in fallback) {
        if (recent.length == 2) {
          break;
        }
        if (!recent.contains(argb) && !fixedPalette.contains(argb)) {
          recent.add(argb);
        }
      }
      return <int>[...fixedPalette, ...recent.take(2)];
    }

    int colorToArgb(Color color) => color.toARGB32();
    var draftStrokeColor = colorToArgb(_currentShapeStrokeColor);
    int? draftFillColor = _currentShapeFillColor == null
        ? null
        : colorToArgb(_currentShapeFillColor!);
    draftFillColor ??= draftStrokeColor;
    var fillEnabled = _currentShapeFillColor != null;
    var draftWidth = _currentShapeWidth.clamp(1.0, 48.0);
    var draftOpacity = _currentShapeOpacity.clamp(0.05, 1.0);
    var lockAspect = _isShapeAspectLocked;
    var rotateSnap = _isShapeRotateSnapEnabled;

    Widget buildSliderRow({
      required String label,
      required double value,
      required double min,
      required double max,
      required int divisions,
      required String valueLabel,
      required ValueChanged<double> onChanged,
    }) {
      return Row(
        children: [
          SizedBox(width: 72, child: Text(label)),
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              label: valueLabel,
              onChanged: onChanged,
            ),
          ),
        ],
      );
    }

    _showPopover(
      link: _shapeLink,
      child: StatefulBuilder(
        builder: (context, setPopupState) {
          final palette = buildPalette();
          return ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 360, maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '도형 설정',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: IconButton(
                          onPressed: _settingsPopover.hide,
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.close, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: shapeTypes
                        .map((shapeType) {
                          return ChoiceChip(
                            label: Text(_labelForShapeType(shapeType)),
                            selected: _activeShapeType == shapeType,
                            onSelected: (_) {
                              final previousType = _activeShapeType;
                              _saveShapeType(previousType);
                              _safeSetState(() {
                                _activeShapeType = shapeType;
                                _loadShapeType(shapeType);
                              });
                              draftStrokeColor = colorToArgb(
                                _currentShapeStrokeColor,
                              );
                              draftFillColor = _currentShapeFillColor == null
                                  ? null
                                  : colorToArgb(_currentShapeFillColor!);
                              draftWidth = _currentShapeWidth.clamp(1.0, 48.0);
                              draftOpacity = _currentShapeOpacity.clamp(
                                0.05,
                                1.0,
                              );
                              setPopupState(() {});
                            },
                          );
                        })
                        .toList(growable: false),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: lockAspect,
                        onChanged: (value) {
                          final next = value ?? false;
                          setPopupState(() {
                            lockAspect = next;
                          });
                          _safeSetState(() {
                            _isShapeAspectLocked = next;
                          });
                        },
                      ),
                      const Text('비율'),
                      const SizedBox(width: 10),
                      Checkbox(
                        value: rotateSnap,
                        onChanged: (value) {
                          final next = value ?? false;
                          setPopupState(() {
                            rotateSnap = next;
                          });
                          _safeSetState(() {
                            _isShapeRotateSnapEnabled = next;
                          });
                        },
                      ),
                      const Text('스냅'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const SizedBox(
                        width: 72,
                        child: Text('선 색상'),
                      ),
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final argb in palette)
                              _colorCircle(
                                argb,
                                selected: draftStrokeColor == argb,
                                onTap: () {
                                  setPopupState(() {
                                    draftStrokeColor = argb;
                                  });
                                  _safeSetState(() {
                                    _currentShapeStrokeColor = Color(argb);
                                  });
                                  _pushRecentColor(argb);
                                  _saveShapeType(_activeShapeType);
                                },
                              ),
                            IconButton(
                              tooltip:
                                  '선 색상 직접 선택',
                              visualDensity: VisualDensity.compact,
                              onPressed: () async {
                                final originalStroke = _currentShapeStrokeColor;
                                _settingsPopover.hide();
                                await Future<void>.delayed(
                                  const Duration(milliseconds: 16),
                                );
                                if (!mounted) {
                                  return;
                                }
                                final kept = await showDrawingColorPickerDialog(
                                  Navigator.of(
                                    this.context,
                                    rootNavigator: true,
                                  ).context,
                                  initialColor: originalStroke,
                                  recentColors: _recentArgb
                                      .map((argb) => Color(argb))
                                      .toList(growable: false),
                                  onLiveChanged: (color) {
                                    _safeSetState(() {
                                      _currentShapeStrokeColor = Color(
                                        color.withAlpha(0xFF).toARGB32(),
                                      );
                                    });
                                  },
                                  onCommitChanged: (color) {
                                    final picked = color
                                        .withAlpha(0xFF)
                                        .toARGB32();
                                    _safeSetState(() {
                                      _currentShapeStrokeColor = Color(picked);
                                    });
                                    _pushRecentColor(picked);
                                    _saveShapeType(_activeShapeType);
                                  },
                                );
                                if (!kept) {
                                  _safeSetState(() {
                                    _currentShapeStrokeColor = originalStroke;
                                  });
                                }
                                _saveShapeType(_activeShapeType);
                                if (mounted) {
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (mounted) {
                                      _showShapeSettingsPopover();
                                    }
                                  });
                                }
                              },
                              icon: const Icon(Icons.colorize),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SizedBox(
                        width: 72,
                        child: InkWell(
                          onTap: () {
                            setPopupState(() {
                              fillEnabled = !fillEnabled;
                              if (fillEnabled && draftFillColor == null) {
                                draftFillColor = draftStrokeColor;
                              }
                            });
                            _safeSetState(() {
                              _currentShapeFillColor = fillEnabled
                                  ? Color(draftFillColor ?? draftStrokeColor)
                                  : null;
                            });
                            _saveShapeType(_activeShapeType);
                          },
                          child: Opacity(
                            opacity: fillEnabled ? 1.0 : 0.45,
                            child: const Text(
                              '채우기 색상',
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Opacity(
                          opacity: fillEnabled ? 1.0 : 0.45,
                          child: IgnorePointer(
                            ignoring: !fillEnabled,
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final argb in palette)
                                  _colorCircle(
                                    argb,
                                    selected: draftFillColor == argb,
                                    onTap: () {
                                      setPopupState(() {
                                        draftFillColor = argb;
                                        fillEnabled = true;
                                      });
                                      _safeSetState(() {
                                        _currentShapeFillColor = Color(argb);
                                      });
                                      _pushRecentColor(argb);
                                      _saveShapeType(_activeShapeType);
                                    },
                                  ),
                                IconButton(
                                  tooltip:
                                      '채우기 색상 직접 선택',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () async {
                                    final originalFill = _currentShapeFillColor;
                                    final seedColor = Color(
                                      draftFillColor ??
                                          _currentShapeStrokeColor.value,
                                    );
                                    _settingsPopover.hide();
                                    await Future<void>.delayed(
                                      const Duration(milliseconds: 16),
                                    );
                                    if (!mounted) {
                                      return;
                                    }
                                    final kept =
                                        await showDrawingColorPickerDialog(
                                          Navigator.of(
                                            this.context,
                                            rootNavigator: true,
                                          ).context,
                                          initialColor: seedColor,
                                          recentColors: _recentArgb
                                              .map((argb) => Color(argb))
                                              .toList(growable: false),
                                          onLiveChanged: (color) {
                                            _safeSetState(() {
                                              _currentShapeFillColor = Color(
                                                color.withAlpha(0xFF).value,
                                              );
                                            });
                                          },
                                          onCommitChanged: (color) {
                                            final picked = color
                                                .withAlpha(0xFF)
                                                .value;
                                            _safeSetState(() {
                                              _currentShapeFillColor = Color(
                                                picked,
                                              );
                                            });
                                            _pushRecentColor(picked);
                                            _saveShapeType(_activeShapeType);
                                          },
                                        );
                                    if (!kept) {
                                      _safeSetState(() {
                                        _currentShapeFillColor = originalFill;
                                      });
                                    }
                                    draftFillColor =
                                        _currentShapeFillColor == null
                                        ? null
                                        : colorToArgb(_currentShapeFillColor!);
                                    _saveShapeType(_activeShapeType);
                                    if (mounted) {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                            if (mounted) {
                                              _showShapeSettingsPopover();
                                            }
                                          });
                                    }
                                  },
                                  icon: const Icon(Icons.colorize),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  buildSliderRow(
                    label: '굵기',
                    value: draftWidth,
                    min: 1.0,
                    max: 48.0,
                    divisions: 47,
                    valueLabel: draftWidth.round().toString(),
                    onChanged: (value) {
                      setPopupState(() {
                        draftWidth = value;
                      });
                      _safeSetState(() {
                        _currentShapeWidth = value;
                      });
                      _saveShapeType(_activeShapeType);
                    },
                  ),
                  buildSliderRow(
                    label: '투명도',
                    value: draftOpacity,
                    min: 0.05,
                    max: 1.0,
                    divisions: 19,
                    valueLabel: '${(draftOpacity * 100).round()}%',
                    onChanged: (value) {
                      setPopupState(() {
                        draftOpacity = value;
                      });
                      _safeSetState(() {
                        _currentShapeOpacity = value;
                      });
                      _saveShapeType(_activeShapeType);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  ShapeType? _shapeTypeFromStored(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    for (final type in ShapeType.values) {
      if (type.name == raw) {
        return type;
      }
    }
    return null;
  }

  String _labelForShapeType(ShapeType type) {
    return switch (type) {
      ShapeType.rectangle => '사각형',
      ShapeType.circle => '원형',
      ShapeType.triangle => '삼각형',
      ShapeType.hShape => 'H 모형',
    };
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
    final GestureTapUpCallback? tapHandler =
        (_isMoveMode || (_isFreeDrawMode && !allowTapInFreeDraw))
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

