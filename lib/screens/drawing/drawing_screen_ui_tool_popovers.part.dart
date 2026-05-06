part of 'drawing_screen.dart';

extension _DrawingScreenUiToolPopovers on _DrawingScreenState {
  Widget _buildFloatingToolSettingsButton() {
    return Opacity(
      opacity: 0.72,
      child: Material(
        color: Colors.black,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerUp: (_) => _openActiveToolSettingsPopover(),
          child: const SizedBox(
            width: 32,
            height: 32,
            child: Icon(Icons.tune, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
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
    _settingsPopover.hide();

    switch (kind) {
      case StrokeToolKind.pen:
        _activateStrokeKind(kind);
        _handleDrawingToolChanged(DrawingTool.pen);
        break;
      case StrokeToolKind.highlighter:
        _activateStrokeKind(kind);
        _handleDrawingToolChanged(DrawingTool.pen);
        break;
      case StrokeToolKind.shape:
        _handleDrawingToolChanged(DrawingTool.shape);
        break;
      case StrokeToolKind.eraser:
        final nextEraserTool = _activeTool == DrawingTool.strokeEraser
            ? DrawingTool.strokeEraser
            : DrawingTool.areaEraser;
        _handleDrawingToolChanged(nextEraserTool);
        break;
    }
    _openToolSettingsPopoverFor(kind);
  }

  void _openToolSettingsPopoverFor(StrokeToolKind kind) {
    switch (kind) {
      case StrokeToolKind.pen:
        _showPenSettingsPopover();
        return;
      case StrokeToolKind.highlighter:
        _showHighlighterSettingsPopover();
        return;
      case StrokeToolKind.shape:
        _showShapeSettingsPopover();
        return;
      case StrokeToolKind.eraser:
        _showEraserSettingsPopover();
        return;
    }
  }

  void _openActiveToolSettingsPopover() {
    if (!mounted) {
      return;
    }
    switch (_selectedToolKindForToolbar) {
      case StrokeToolKind.pen:
        _openToolSettingsPopoverFor(StrokeToolKind.pen);
        return;
      case StrokeToolKind.highlighter:
        _openToolSettingsPopoverFor(StrokeToolKind.highlighter);
        return;
      case StrokeToolKind.shape:
        _openToolSettingsPopoverFor(StrokeToolKind.shape);
        return;
      case StrokeToolKind.eraser:
        _openToolSettingsPopoverFor(StrokeToolKind.eraser);
        return;
      case null:
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
          isStraightenModeEnabled: _isHighlighterStraightenModeEnabled,
          straightenSnapEnabled: _isHighlighterStraightenSnapEnabled,
          onVariantChanged: _handleHighlighterVariantChanged,
          onWidthChanged: _handleHighlighterWidthChanged,
          onOpacityChanged: _handleHighlighterOpacityChanged,
          onColorChanged: _handleHighlighterColorChanged,
          onStraightenModeChanged: (enabled) {
            _safeSetState(() {
              _isHighlighterStraightenModeEnabled = enabled;
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
              _isHighlighterStraightenSnapEnabled = enabled;
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
          isStraightenModeEnabled: _isPenStraightenModeEnabled,
          straightenSnapEnabled: _isPenStraightenSnapEnabled,
          onVariantChanged: _handlePenVariantChanged,
          onWidthChanged: _handlePenWidthChanged,
          onColorChanged: _handlePenColorChanged,
          onStraightenModeChanged: (enabled) {
            _safeSetState(() {
              _isPenStraightenModeEnabled = enabled;
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
              _isPenStraightenSnapEnabled = enabled;
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
                      const SizedBox(width: 72, child: Text('선 색상')),
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
                              tooltip: '선 색상 직접 선택',
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
                            child: const Text('채우기 색상'),
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
                                  tooltip: '채우기 색상 직접 선택',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () async {
                                    final originalFill = _currentShapeFillColor;
                                    final seedColor = Color(
                                      draftFillColor ??
                                          _currentShapeStrokeColor.toARGB32(),
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
                                                color
                                                    .withAlpha(0xFF)
                                                    .toARGB32(),
                                              );
                                            });
                                          },
                                          onCommitChanged: (color) {
                                            final picked = color
                                                .withAlpha(0xFF)
                                                .toARGB32();
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
}
