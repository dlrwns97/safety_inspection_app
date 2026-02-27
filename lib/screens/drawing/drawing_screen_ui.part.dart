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

  Widget _buildStrokePresetPanel() {
    final theme = Theme.of(context);
    final screenW = MediaQuery.of(context).size.width;
    final panelMaxW = math.min(400.0, screenW * 0.45);
    final panelMinW = math.min(panelMaxW, screenW * 0.24);
    final toolIndexes = <int>[0, 1, 2, 3];

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
              ..showSnackBar(
                SnackBar(
                  content: Text(tooltip),
                  duration: const Duration(milliseconds: 800),
                ),
              );
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
    final isStrokeEraserSelected = _isStrokeEraserActive;
    final isAreaEraserSelected = _isAreaEraserActive;
    final isPenSelected = !isStrokeEraserSelected && !isAreaEraserSelected;
    final canAdjustStrokeStyle = hasActiveTool && isPenSelected;
    final showOpacity = style.kind == StrokeToolKind.highlighter;
    final clampedAreaEraserRadius = _areaEraserRadiusPx.clamp(6.0, 60.0);
    final previewDiameter = (clampedAreaEraserRadius * 2).clamp(16.0, 56.0);
    final colorRow = <int>[
      ..._standardPaletteArgb.take(8),
      ..._recentArgb.take(2),
    ];
    final currentPageStrokes = _canvasController.getStrokes(_currentPage);
    final hasCurrentPageStrokes = currentPageStrokes.isNotEmpty;
    final hasCurrentPageHighlighterStrokes = currentPageStrokes.any(
      (stroke) => stroke.style.kind == StrokeToolKind.highlighter,
    );
    final hasCurrentPagePenStrokes = currentPageStrokes.any(
      (stroke) => stroke.style.kind == StrokeToolKind.pen,
    );

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
                  panelButton(
                    icon: Icons.edit,
                    selected: isPenSelected,
                    tooltip: 'Pen',
                    onTap: () => _handleDrawingToolChanged(DrawingTool.pen),
                  ),
                  const SizedBox(width: 8),
                  panelButton(
                    icon: Icons.remove,
                    selected: isStrokeEraserSelected,
                    tooltip: 'Stroke eraser',
                    onTap: () =>
                        _handleDrawingToolChanged(DrawingTool.strokeEraser),
                  ),
                  const SizedBox(width: 8),
                  panelButton(
                    icon: Icons.circle_outlined,
                    selected: isAreaEraserSelected,
                    tooltip: 'Area eraser',
                    onTap: () =>
                        _handleDrawingToolChanged(DrawingTool.areaEraser),
                  ),
                  const SizedBox(width: 8),
                  panelButton(
                    icon: Icons.straighten,
                    selected: _isStraightenModeEnabled,
                    tooltip: 'Straighten',
                    onTap: () {
                      _safeSetState(() {
                        _isStraightenModeEnabled = !_isStraightenModeEnabled;
                        if (!_isStraightenModeEnabled) {
                          _straightenSnappedAngleByPointer.clear();
                          _straightenStartPageByPointer.clear();
                          _resetHighlighterStraightenState();
                        }
                      });
                      unawaited(_saveDrawingSettings());
                    },
                  ),
                ],
              ),
              if (isAreaEraserSelected) ...[
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Tooltip(
                            message: 'Area eraser radius',
                            child: const Text(
                              'Area eraser radius',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 56,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${clampedAreaEraserRadius.round()} px',
                              maxLines: 1,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4,
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 14,
                              ),
                              showValueIndicator: ShowValueIndicator.always,
                            ),
                            child: Slider(
                              value: clampedAreaEraserRadius,
                              min: 6,
                              max: 60,
                              divisions: 54,
                              label: clampedAreaEraserRadius.round().toString(),
                              onChanged: _handleAreaEraserRadiusChanged,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Center(
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 56,
                          child: Align(
                            alignment: Alignment.center,
                            child: Container(
                              width: previewDiameter,
                              height: previewDiameter,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.colorScheme.primary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final index in toolIndexes.where(
                            (i) => i < _presets.length,
                          )) ...[
                            panelButton(
                              icon: _iconForVariant(_presets[index].variant),
                              selected: _activePresetIndex == index,
                              tooltip: _labelForVariant(
                                _presets[index].variant,
                              ),
                              onTap: () => _toggleActivePreset(index),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: hasCurrentPageStrokes
                        ? _clearCurrentPageAllStrokes
                        : null,
                    icon: const Icon(Icons.delete_sweep),
                    tooltip: 'Clear all on page',
                  ),
                  IconButton(
                    onPressed: hasCurrentPageHighlighterStrokes
                        ? _clearCurrentPageHighlighterStrokes
                        : null,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints.tightFor(
                      width: 40,
                      height: 40,
                    ),
                    icon: const Icon(Icons.auto_fix_high),
                    tooltip: 'Clear highlighter on page',
                  ),
                  IconButton(
                    onPressed: hasCurrentPagePenStrokes
                        ? _clearCurrentPagePenStrokes
                        : null,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints.tightFor(
                      width: 40,
                      height: 40,
                    ),
                    icon: const Icon(Icons.edit_off),
                    tooltip: 'Clear pen on page',
                  ),
                  IconButton(
                    onPressed: () => _setToolPanelOpen(false),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed:
                        !hasActiveTool ||
                            style.widthPx <= 1 ||
                            !canAdjustStrokeStyle
                        ? null
                        : () => _updateActivePreset(
                            style.copyWith(
                              widthPx: (style.widthPx - 1)
                                  .clamp(1, 48)
                                  .toDouble(),
                            ),
                          ),
                    icon: const Icon(Icons.remove),
                  ),
                  Expanded(
                    child: Slider(
                      value: style.widthPx.clamp(1.0, 48.0),
                      min: 1,
                      max: 48,
                      divisions: 47,
                      label: style.widthPx.round().toString(),
                      onChanged: canAdjustStrokeStyle
                          ? (v) =>
                                _updateActivePreset(style.copyWith(widthPx: v))
                          : null,
                    ),
                  ),
                  IconButton(
                    onPressed: !canAdjustStrokeStyle || style.widthPx >= 48
                        ? null
                        : () => _updateActivePreset(
                            style.copyWith(
                              widthPx: (style.widthPx + 1)
                                  .clamp(1, 48)
                                  .toDouble(),
                            ),
                          ),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              if (showOpacity)
                Row(
                  children: [
                    const SizedBox(width: 8),
                    const Text('Opacity'),
                    Expanded(
                      child: Slider(
                        value: style.opacity.clamp(0.05, 1.0),
                        min: 0.05,
                        max: 1.0,
                        onChanged: canAdjustStrokeStyle
                            ? (v) => _updateActivePreset(
                                style.copyWith(opacity: v),
                              )
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
                                onTap: !canAdjustStrokeStyle
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
                    onPressed: !canAdjustStrokeStyle
                        ? null
                        : () {
                            if (style.kind == StrokeToolKind.highlighter) {
                              _showHighlighterSettingsPopover();
                              return;
                            }
                            _showPenSettingsPopover();
                          },
                    icon: const Icon(Icons.tune),
                    tooltip: 'Detailed settings',
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
      PenVariant.pen => 'Pen',
      PenVariant.fountainPen => 'Fountain Pen',
      PenVariant.calligraphyPen => 'Calligraphy Pen',
      PenVariant.pencil => 'Pencil',
      PenVariant.highlighter => 'Highlighter',
      PenVariant.marker => 'Marker',
      PenVariant.highlighterChisel => 'Highlighter Chisel',
      PenVariant.markerChisel => 'Marker Chisel',
    };
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
    if (_settingsPopover.isShown &&
        _activeToolKindForToolbar == kind &&
        kind != StrokeToolKind.shape) {
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
      case StrokeToolKind.textBox:
        _handleDrawingToolChanged(DrawingTool.textBox);
        _showTextSettingsPopover();
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

  Future<void> _openColorDialog() async {
    final style = _activeStrokeStyleOrFallback;
    final originalColor = Color(style.argbColor);
    final originalOpacity = style.opacity;
    Color selected = originalColor;
    double opacity = originalOpacity;
    HSVColor hsv = HSVColor.fromColor(selected.withAlpha(0xFF));
    bool useStandardTab = true;

    StrokeStyle buildLiveStyle() {
      final base = _activeStrokeStyleOrFallback;
      var next = base.copyWith(argbColor: selected.value);
      if (base.kind == StrokeToolKind.highlighter) {
        next = next.copyWith(opacity: opacity);
      }
      return next;
    }

    void applyLive() {
      _updateActivePreset(buildLiveStyle());
    }

    final kept = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: StatefulBuilder(
            builder: (ctx, setD) {
              void applyColor(Color c) {
                selected = c;
                hsv = HSVColor.fromColor(c.withAlpha(0xFF));
                applyLive();
                setD(() {});
              }

              void applyOpacity(double v) {
                opacity = v;
                applyLive();
                setD(() {});
              }

              Widget tabButton(String text, bool active, VoidCallback onTap) {
                return InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: active
                          ? Theme.of(ctx).colorScheme.primaryContainer
                          : Theme.of(ctx).colorScheme.surfaceContainerHighest,
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
                        Expanded(
                          child: tabButton(
                            'Palette',
                            useStandardTab,
                            () => setD(() => useStandardTab = true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: tabButton(
                            'Custom',
                            !useStandardTab,
                            () => setD(() => useStandardTab = false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (useStandardTab) ...[
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final argb in _standardPaletteArgb)
                            _colorCircle(
                              argb,
                              selected:
                                  selected.withAlpha(0xFF).value ==
                                  Color(argb).withAlpha(0xFF).value,
                              onTap: () => applyColor(Color(argb)),
                            ),
                        ],
                      ),
                      if (_recentArgb.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Recent',
                            style: Theme.of(ctx).textTheme.labelLarge,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final argb in _recentArgb)
                              _colorCircle(
                                argb,
                                selected:
                                    selected.withAlpha(0xFF).value ==
                                    Color(argb).withAlpha(0xFF).value,
                                onTap: () => applyColor(
                                  Color(argb).withAlpha(selected.alpha),
                                ),
                              ),
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
                          const Text('Opacity'),
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
                          '#${selected.withAlpha(0xFF).value.toRadixString(16).substring(2).toUpperCase()} '
                          ' R ${selected.red}  G ${selected.green}  B ${selected.blue}',
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              _applyPresetWithRecentColor(buildLiveStyle());
                              Navigator.pop(ctx, true);
                            },
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    if (kept == true) {
      return;
    }
    final base = _activeStrokeStyleOrFallback;
    var reverted = base.copyWith(argbColor: originalColor.value);
    if (base.kind == StrokeToolKind.highlighter) {
      reverted = reverted.copyWith(opacity: originalOpacity);
    }
    _updateActivePreset(reverted);
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
                        Positioned.fill(
                          child: IgnorePointer(
                            child: _buildTextBoxesOverlay(
                              pageSize: pageSize,
                              pageNumber: pageNumber,
                            ),
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
            IgnorePointer(
              child: _buildTextBoxesOverlay(
                pageSize: DrawingCanvasSize,
                pageNumber: _currentPage,
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

  String _labelForTextAlign(TextAlign align) {
    return switch (align) {
      TextAlign.left || TextAlign.start => '왼쪽',
      TextAlign.center => '가운데',
      TextAlign.right || TextAlign.end => '오른쪽',
      TextAlign.justify => '양쪽',
    };
  }

  void _showTextSettingsPopover() {
    if (!mounted) {
      return;
    }
    _settingsPopover.hide();
    final selectedStroke = _resolveSelectedTextStroke();
    final selectedData = selectedStroke?.stroke.textBoxData;
    var draftFontSize = (selectedData?.fontSize ?? _currentTextFontSize).clamp(
      10.0,
      64.0,
    );
    var draftColor = selectedData?.argbColor ?? _currentTextColor.value;
    var draftAlign = selectedData?.textAlign ?? _currentTextAlign;

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
        if (recent.length == 3) {
          break;
        }
      }
      const fallback = <int>[0xFF000000, 0xFFFFFFFF];
      for (final argb in fallback) {
        if (recent.length == 3) {
          break;
        }
        if (!recent.contains(argb) && !fixedPalette.contains(argb)) {
          recent.add(argb);
        }
      }
      return <int>[...fixedPalette, ...recent.take(3)];
    }

    _showPopover(
      link: _textLink,
      child: StatefulBuilder(
        builder: (context, setPopupState) {
          final palette = buildPalette();
          return ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 340, maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(child: Text('Text settings')),
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
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const SizedBox(width: 72, child: Text('Size')),
                      Expanded(
                        child: Slider(
                          value: draftFontSize,
                          min: 10.0,
                          max: 64.0,
                          divisions: 54,
                          label: draftFontSize.round().toString(),
                          onChanged: (value) {
                            setPopupState(() {
                              draftFontSize = value;
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        child: Text('${draftFontSize.round()}'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const SizedBox(width: 72, child: Text('Color')),
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final argb in palette)
                              _colorCircle(
                                argb,
                                selected: draftColor == argb,
                                onTap: () {
                                  setPopupState(() {
                                    draftColor = argb;
                                  });
                                },
                              ),
                            IconButton(
                              tooltip: 'Pick color',
                              visualDensity: VisualDensity.compact,
                              onPressed: () async {
                                final originalColor = draftColor;
                                _settingsPopover.hide();
                                await Future<void>.delayed(
                                  const Duration(milliseconds: 16),
                                );
                                if (!mounted) {
                                  return;
                                }
                                var liveColor = originalColor;
                                final kept = await showDrawingColorPickerDialog(
                                  Navigator.of(
                                    this.context,
                                    rootNavigator: true,
                                  ).context,
                                  initialColor: Color(originalColor),
                                  recentColors: _recentArgb
                                      .map((argb) => Color(argb))
                                      .toList(growable: false),
                                  onLiveChanged: (color) {
                                    liveColor = color
                                        .withAlpha(0xFF)
                                        .toARGB32();
                                  },
                                  onCommitChanged: (color) {
                                    liveColor = color
                                        .withAlpha(0xFF)
                                        .toARGB32();
                                  },
                                );
                                if (mounted) {
                                  setPopupState(() {
                                    draftColor = kept
                                        ? liveColor
                                        : originalColor;
                                  });
                                }
                                if (mounted) {
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (mounted) {
                                      _showTextSettingsPopover();
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
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: 72, child: Text('Align')),
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final align in const <TextAlign>[
                              TextAlign.left,
                              TextAlign.center,
                              TextAlign.right,
                            ])
                              ChoiceChip(
                                label: Text(_labelForTextAlign(align)),
                                selected: draftAlign == align,
                                onSelected: (_) {
                                  setPopupState(() {
                                    draftAlign = align;
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _settingsPopover.hide,
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            _applyTextStyle(
                              fontSize: draftFontSize,
                              argbColor: draftColor,
                              textAlign: draftAlign,
                            );
                            _settingsPopover.hide();
                          },
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextBoxesOverlay({
    required Size pageSize,
    required int pageNumber,
  }) {
    final strokes = _canvasController.getStrokes(pageNumber);
    final textStrokes = strokes.where(
      (stroke) =>
          stroke.toolType == DrawingTool.textBox && stroke.textBoxData != null,
    );
    return Stack(
      children: textStrokes
          .map((stroke) {
            final boundsNorm = _effectiveTextBoundsForStroke(stroke);
            if (boundsNorm == null || boundsNorm.isEmpty) {
              return const SizedBox.shrink();
            }
            final textData = stroke.textBoxData!;
            final isSelected = _selectedTextStrokeId == stroke.id;
            final left = boundsNorm.left * pageSize.width;
            final top = boundsNorm.top * pageSize.height;
            final width = boundsNorm.width * pageSize.width;
            final height = boundsNorm.height * pageSize.height;
            return Positioned(
              left: left,
              top: top,
              width: width,
              height: height,
              child: Container(
                alignment: Alignment.topLeft,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: isSelected ? 1.5 : 0.0,
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Text(
                      _textStrokeText(stroke),
                      textAlign: textData.textAlign,
                      style: TextStyle(
                        fontSize: textData.fontSize,
                        color: Color(textData.argbColor),
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        right: -5,
                        bottom: -5,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          })
          .toList(growable: false),
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
                      const Expanded(child: Text('Shape settings')),
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
                      const Text('비율 고정'),
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
                  Text(
                    '회전: 도형 선택 후 하단 원형 핸들을 드래그',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const SizedBox(width: 72, child: Text('테두리 색')),
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
                              tooltip: 'Pick color',
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
                            child: const Text('채우기 색'),
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
                                  tooltip: 'Pick fill color',
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
                    label: 'Line width',
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
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: canCommit ? _commitMovePreview : null,
                  child: const Text('Apply'),
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
        _isFreeDrawMode &&
        (_activeTool == DrawingTool.textBox ||
            _activeTool == DrawingTool.shape);
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
            child: CustomPaint(painter: _HsvColorSquarePainter(hsv: hsv)),
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
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    final hueColor = HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor();

    canvas.save();
    canvas.clipRRect(rrect);
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
    canvas.restore();

    final dx = (hsv.saturation * size.width).clamp(0.0, size.width).toDouble();
    final dy = ((1 - hsv.value) * size.height)
        .clamp(0.0, size.height)
        .toDouble();
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
