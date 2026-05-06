part of 'drawing_screen.dart';

const String _kDrawingSettingsPrefix = 'drawing';

extension _DrawingScreenTooling on _DrawingScreenState {
  int _clampPresetIndex(int index) {
    return index.clamp(0, _presets.length - 1).toInt();
  }

  StrokeStyle? get _activeStrokeStyle {
    final index = _activePresetIndex;
    if (index == null) {
      return null;
    }
    return _presets[_clampPresetIndex(index)];
  }

  StrokeStyle get _activeStrokeStyleOrFallback =>
      _activeStrokeStyle ?? _presets.first;

  StrokeStyle get _activeShapeStrokeStyle => StrokeStyle(
    kind: StrokeToolKind.shape,
    variant: PenVariant.pen,
    widthPx: _currentShapeWidth,
    argbColor: _currentShapeStrokeColor.toARGB32(),
    opacity: _currentShapeOpacity,
  );

  Color? get _activeShapeFillColor => _shapeFillColorByType[_activeShapeType];

  StrokeToolKind get _activeToolKindForToolbar {
    if (_activeTool == DrawingTool.areaEraser ||
        _activeTool == DrawingTool.strokeEraser) {
      return StrokeToolKind.eraser;
    }
    if (_activeTool == DrawingTool.shape) {
      return StrokeToolKind.shape;
    }
    return _activeFamily == ToolFamily.highlighter
        ? StrokeToolKind.highlighter
        : StrokeToolKind.pen;
  }

  StrokeToolKind? get _selectedToolKindForToolbar {
    if (!_isFreeDrawMode) {
      return null;
    }
    if (_activeTool == DrawingTool.pen && _activePresetIndex == null) {
      return null;
    }
    return _activeToolKindForToolbar;
  }

  List<int> _buildRecentColors(List<int> current, int nextArgb) {
    final nextRgb = Color(nextArgb).withAlpha(0xFF).toARGB32();
    final updated = <int>[nextRgb, ...current.where((argb) => argb != nextRgb)];
    return updated
        .take(_DrawingScreenState._kMaxRecentColors)
        .toList(growable: false);
  }

  void _pushRecentColor(int argb) {
    final updated = _buildRecentColors(_recentArgb, argb);
    _safeSetState(() {
      _recentArgb
        ..clear()
        ..addAll(updated);
    });
  }

  bool _isHighlighterFamilyVariant(PenVariant variant) {
    return _DrawingScreenState.highlighterVariants.contains(variant);
  }

  PenUiType _penUiTypeFromVariant(PenVariant variant) {
    return switch (variant) {
      PenVariant.fountainPen => PenUiType.fountainPen,
      PenVariant.calligraphyPen => PenUiType.calligraphy,
      PenVariant.pencil => PenUiType.pencil,
      _ => PenUiType.pen,
    };
  }

  PenVariant _penVariantFromUiType(PenUiType type) {
    return switch (type) {
      PenUiType.pen => PenVariant.pen,
      PenUiType.fountainPen => PenVariant.fountainPen,
      PenUiType.calligraphy => PenVariant.calligraphyPen,
      PenUiType.pencil => PenVariant.pencil,
    };
  }

  HighlighterUiType _highlighterUiTypeFromVariant(PenVariant variant) {
    return variant == PenVariant.marker
        ? HighlighterUiType.marker
        : HighlighterUiType.highlighter;
  }

  PenVariant _highlighterVariantFromUiType(HighlighterUiType type) {
    return switch (type) {
      HighlighterUiType.highlighter => PenVariant.highlighter,
      HighlighterUiType.marker => PenVariant.marker,
    };
  }

  void _seedVariantStateMaps() {
    final initialPenPreset = _presets.firstWhere(
      (style) => style.kind == StrokeToolKind.pen,
      orElse: () => const StrokeStyle(kind: StrokeToolKind.pen),
    );
    final initialHighlighterPreset = _presets.firstWhere(
      (style) => style.kind == StrokeToolKind.highlighter,
      orElse: () => const StrokeStyle(kind: StrokeToolKind.highlighter),
    );
    for (final type in PenUiType.values) {
      _penWidthByType.putIfAbsent(type, () => initialPenPreset.widthPx);
      _penColorByType.putIfAbsent(
        type,
        () => Color(initialPenPreset.argbColor),
      );
    }
    for (final type in HighlighterUiType.values) {
      _hlWidthByType.putIfAbsent(type, () => initialHighlighterPreset.widthPx);
      _hlColorByType.putIfAbsent(
        type,
        () => Color(initialHighlighterPreset.argbColor),
      );
      _hlOpacityByType.putIfAbsent(
        type,
        () => type == HighlighterUiType.marker
            ? _DrawingScreenState._kDefaultMarkerOpacity
            : _DrawingScreenState._kDefaultHighlighterOpacity,
      );
    }

    final initialStyle = _activeStrokeStyleOrFallback;
    _activeFamily = initialStyle.kind == StrokeToolKind.highlighter
        ? ToolFamily.highlighter
        : ToolFamily.pen;
    _activePenType = _penUiTypeFromVariant(initialStyle.variant);
    _activeHighlighterType = _highlighterUiTypeFromVariant(
      initialStyle.variant,
    );
    _loadPenType(_activePenType);
    _loadHighlighterType(_activeHighlighterType);
    _seedShapeTypeMaps(initialPenPreset);
    _syncPopupNotifiers();
  }

  void _seedShapeTypeMaps(StrokeStyle baseStyle) {
    for (final type in ShapeType.values) {
      _shapeWidthByType.putIfAbsent(type, () => baseStyle.widthPx);
      _shapeOpacityByType.putIfAbsent(type, () => 1.0);
      _shapeStrokeColorByType.putIfAbsent(
        type,
        () => Color(baseStyle.argbColor),
      );
      _shapeFillColorByType.putIfAbsent(type, () => null);
    }
    _loadShapeType(_activeShapeType);
  }

  void _syncPopupNotifiers() {
    _penVariantNotifier.value = _penVariantFromUiType(_activePenType);
    _penWidthNotifier.value = _currentPenWidth;
    _penColorNotifier.value = _currentPenColor;
    _highlighterVariantNotifier.value = _highlighterVariantFromUiType(
      _activeHighlighterType,
    );
    _highlighterWidthNotifier.value = _currentHlWidth;
    _highlighterOpacityNotifier.value = _currentHlOpacity;
    _highlighterColorNotifier.value = _currentHlColor;
  }

  void _savePenType(PenUiType t) {
    _penWidthByType[t] = _currentPenWidth;
    _penColorByType[t] = _currentPenColor;
    unawaited(_saveDrawingSettings());
  }

  void _loadPenType(PenUiType t) {
    _currentPenWidth = _penWidthByType[t] ?? _currentPenWidth;
    _currentPenColor = _penColorByType[t] ?? _currentPenColor;
  }

  void _saveHighlighterType(HighlighterUiType t) {
    _hlWidthByType[t] = _currentHlWidth;
    _hlOpacityByType[t] = _currentHlOpacity;
    _hlColorByType[t] = _currentHlColor;
    unawaited(_saveDrawingSettings());
  }

  String _penWidthKey(PenUiType type) =>
      '$_kDrawingSettingsPrefix.pen.${type.name}.width';

  String _penColorKey(PenUiType type) =>
      '$_kDrawingSettingsPrefix.pen.${type.name}.colorARGB';

  String _hlWidthKey(HighlighterUiType type) =>
      '$_kDrawingSettingsPrefix.hl.${type.name}.width';

  String _hlOpacityKey(HighlighterUiType type) =>
      '$_kDrawingSettingsPrefix.hl.${type.name}.opacity';

  String _hlColorKey(HighlighterUiType type) =>
      '$_kDrawingSettingsPrefix.hl.${type.name}.colorARGB';

  String _shapeWidthKey(ShapeType type) =>
      '$_kDrawingSettingsPrefix.shape.${type.name}.width';

  String _shapeOpacityKey(ShapeType type) =>
      '$_kDrawingSettingsPrefix.shape.${type.name}.opacity';

  String _shapeStrokeColorKey(ShapeType type) =>
      '$_kDrawingSettingsPrefix.shape.${type.name}.strokeColorARGB';

  String _shapeFillColorKey(ShapeType type) =>
      '$_kDrawingSettingsPrefix.shape.${type.name}.fillColorARGB';

  Future<void> _loadDrawingSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final loadedPenWidthByType = <PenUiType, double>{};
    final loadedPenColorByType = <PenUiType, Color>{};
    final loadedHlWidthByType = <HighlighterUiType, double>{};
    final loadedHlOpacityByType = <HighlighterUiType, double>{};
    final loadedHlColorByType = <HighlighterUiType, Color>{};
    final loadedShapeWidthByType = <ShapeType, double>{};
    final loadedShapeOpacityByType = <ShapeType, double>{};
    final loadedShapeStrokeColorByType = <ShapeType, Color>{};
    final loadedShapeFillColorByType = <ShapeType, Color?>{};

    for (final type in PenUiType.values) {
      final width = prefs.getDouble(_penWidthKey(type));
      final colorArgb = prefs.getInt(_penColorKey(type));
      if (width != null) {
        loadedPenWidthByType[type] = width;
      }
      if (colorArgb != null) {
        loadedPenColorByType[type] = Color(colorArgb);
      }
    }

    for (final type in HighlighterUiType.values) {
      final width = prefs.getDouble(_hlWidthKey(type));
      final opacity = prefs.getDouble(_hlOpacityKey(type));
      final colorArgb = prefs.getInt(_hlColorKey(type));
      if (width != null) {
        loadedHlWidthByType[type] = width;
      }
      if (opacity != null) {
        loadedHlOpacityByType[type] = opacity;
      }
      if (colorArgb != null) {
        loadedHlColorByType[type] = Color(colorArgb);
      }
    }

    for (final type in ShapeType.values) {
      final width = prefs.getDouble(_shapeWidthKey(type));
      final opacity = prefs.getDouble(_shapeOpacityKey(type));
      final strokeColorArgb = prefs.getInt(_shapeStrokeColorKey(type));
      final hasFillKey = prefs.containsKey(_shapeFillColorKey(type));
      final fillColorArgb = hasFillKey
          ? prefs.getInt(_shapeFillColorKey(type))
          : null;
      if (width != null) {
        loadedShapeWidthByType[type] = width;
      }
      if (opacity != null) {
        loadedShapeOpacityByType[type] = opacity;
      }
      if (strokeColorArgb != null) {
        loadedShapeStrokeColorByType[type] = Color(strokeColorArgb);
      }
      if (hasFillKey) {
        loadedShapeFillColorByType[type] = fillColorArgb == null
            ? null
            : Color(fillColorArgb);
      }
    }

    final legacyStraightenEnabled = prefs.getBool(
      '$_kDrawingSettingsPrefix.straighten.enabled',
    );
    final legacyStraightenSnapEnabled = prefs.getBool(
      '$_kDrawingSettingsPrefix.straighten.snapEnabled',
    );
    final penStraightenEnabled =
        prefs.getBool('$_kDrawingSettingsPrefix.straighten.pen.enabled') ??
        legacyStraightenEnabled;
    final penStraightenSnapEnabled =
        prefs.getBool('$_kDrawingSettingsPrefix.straighten.pen.snapEnabled') ??
        legacyStraightenSnapEnabled;
    final highlighterStraightenEnabled =
        prefs.getBool(
          '$_kDrawingSettingsPrefix.straighten.highlighter.enabled',
        ) ??
        legacyStraightenEnabled;
    final highlighterStraightenSnapEnabled =
        prefs.getBool(
          '$_kDrawingSettingsPrefix.straighten.highlighter.snapEnabled',
        ) ??
        legacyStraightenSnapEnabled;
    final activePenTypeName = prefs.getString(
      '$_kDrawingSettingsPrefix.last.penType',
    );
    final activeHlTypeName = prefs.getString(
      '$_kDrawingSettingsPrefix.last.hlType',
    );

    if (!mounted) {
      return;
    }

    _safeSetState(() {
      _penWidthByType.addAll(loadedPenWidthByType);
      _penColorByType.addAll(loadedPenColorByType);
      _hlWidthByType.addAll(loadedHlWidthByType);
      _hlOpacityByType.addAll(loadedHlOpacityByType);
      _hlColorByType.addAll(loadedHlColorByType);
      _shapeWidthByType.addAll(loadedShapeWidthByType);
      _shapeOpacityByType.addAll(loadedShapeOpacityByType);
      _shapeStrokeColorByType.addAll(loadedShapeStrokeColorByType);
      _shapeFillColorByType.addAll(loadedShapeFillColorByType);

      PenUiType? savedPenType;
      for (final type in PenUiType.values) {
        if (type.name == activePenTypeName) {
          savedPenType = type;
          break;
        }
      }
      HighlighterUiType? savedHlType;
      for (final type in HighlighterUiType.values) {
        if (type.name == activeHlTypeName) {
          savedHlType = type;
          break;
        }
      }
      if (savedPenType != null) {
        _activePenType = savedPenType;
      }
      if (savedHlType != null) {
        _activeHighlighterType = savedHlType;
      }

      if (penStraightenEnabled != null) {
        _isPenStraightenModeEnabled = penStraightenEnabled;
      }
      if (penStraightenSnapEnabled != null) {
        _isPenStraightenSnapEnabled = penStraightenSnapEnabled;
      }
      if (highlighterStraightenEnabled != null) {
        _isHighlighterStraightenModeEnabled = highlighterStraightenEnabled;
      }
      if (highlighterStraightenSnapEnabled != null) {
        _isHighlighterStraightenSnapEnabled = highlighterStraightenSnapEnabled;
      }

      _loadPenType(_activePenType);
      _loadHighlighterType(_activeHighlighterType);
      _loadShapeType(_activeShapeType);
      _syncCurrentFamilyStyleToPreset();
      _syncPopupNotifiers();
    });
  }

  Future<void> _saveDrawingSettings() async {
    final prefs = await SharedPreferences.getInstance();

    for (final type in PenUiType.values) {
      await prefs.setDouble(
        _penWidthKey(type),
        _penWidthByType[type] ?? _currentPenWidth,
      );
      await prefs.setInt(
        _penColorKey(type),
        (_penColorByType[type] ?? _currentPenColor).toARGB32(),
      );
    }
    for (final type in HighlighterUiType.values) {
      await prefs.setDouble(
        _hlWidthKey(type),
        _hlWidthByType[type] ?? _currentHlWidth,
      );
      await prefs.setDouble(
        _hlOpacityKey(type),
        _hlOpacityByType[type] ??
            (type == HighlighterUiType.marker
                ? _DrawingScreenState._kDefaultMarkerOpacity
                : _DrawingScreenState._kDefaultHighlighterOpacity),
      );
      await prefs.setInt(
        _hlColorKey(type),
        (_hlColorByType[type] ?? _currentHlColor).toARGB32(),
      );
    }
    for (final type in ShapeType.values) {
      await prefs.setDouble(
        _shapeWidthKey(type),
        _shapeWidthByType[type] ?? _currentShapeWidth,
      );
      await prefs.setDouble(
        _shapeOpacityKey(type),
        _shapeOpacityByType[type] ?? _currentShapeOpacity,
      );
      await prefs.setInt(
        _shapeStrokeColorKey(type),
        (_shapeStrokeColorByType[type] ?? _currentShapeStrokeColor).toARGB32(),
      );
      final fill = _shapeFillColorByType[type];
      if (fill == null) {
        await prefs.remove(_shapeFillColorKey(type));
      } else {
        await prefs.setInt(_shapeFillColorKey(type), fill.toARGB32());
      }
    }

    await prefs.setBool(
      '$_kDrawingSettingsPrefix.straighten.pen.enabled',
      _isPenStraightenModeEnabled,
    );
    await prefs.setBool(
      '$_kDrawingSettingsPrefix.straighten.pen.snapEnabled',
      _isPenStraightenSnapEnabled,
    );
    await prefs.setBool(
      '$_kDrawingSettingsPrefix.straighten.highlighter.enabled',
      _isHighlighterStraightenModeEnabled,
    );
    await prefs.setBool(
      '$_kDrawingSettingsPrefix.straighten.highlighter.snapEnabled',
      _isHighlighterStraightenSnapEnabled,
    );
    await prefs.setString(
      '$_kDrawingSettingsPrefix.last.penType',
      _activePenType.name,
    );
    await prefs.setString(
      '$_kDrawingSettingsPrefix.last.hlType',
      _activeHighlighterType.name,
    );
  }

  void _loadHighlighterType(HighlighterUiType t) {
    _currentHlWidth = _hlWidthByType[t] ?? _currentHlWidth;
    _currentHlOpacity = _hlOpacityByType[t] ?? _currentHlOpacity;
    _currentHlColor = _hlColorByType[t] ?? _currentHlColor;
  }

  void _saveShapeType(ShapeType type) {
    _shapeWidthByType[type] = _currentShapeWidth;
    _shapeOpacityByType[type] = _currentShapeOpacity;
    _shapeStrokeColorByType[type] = _currentShapeStrokeColor;
    _shapeFillColorByType[type] = _currentShapeFillColor;
    unawaited(_saveDrawingSettings());
  }

  void _loadShapeType(ShapeType type) {
    _currentShapeWidth = _shapeWidthByType[type] ?? _currentShapeWidth;
    _currentShapeOpacity = _shapeOpacityByType[type] ?? _currentShapeOpacity;
    _currentShapeStrokeColor =
        _shapeStrokeColorByType[type] ?? _currentShapeStrokeColor;
    _currentShapeFillColor = _shapeFillColorByType[type];
  }

  void _syncCurrentFamilyStyleToPreset() {
    final index = _activePresetIndex;
    if (index == null) {
      return;
    }
    final normalizedIndex = _clampPresetIndex(index);
    final baseStyle = _presets[normalizedIndex];
    if (_activeFamily == ToolFamily.highlighter) {
      _presets[normalizedIndex] = baseStyle.copyWith(
        kind: StrokeToolKind.highlighter,
        variant: _highlighterVariantFromUiType(_activeHighlighterType),
        widthPx: _currentHlWidth,
        opacity: _currentHlOpacity,
        argbColor: _currentHlColor.toARGB32(),
      );
      return;
    }
    _presets[normalizedIndex] = baseStyle.copyWith(
      kind: StrokeToolKind.pen,
      variant: _penVariantFromUiType(_activePenType),
      widthPx: _currentPenWidth,
      argbColor: _currentPenColor.toARGB32(),
    );
  }

  void _switchPenType(PenUiType newType) {
    if (_activePenType == newType) {
      return;
    }
    _savePenType(_activePenType);
    _safeSetState(() {
      _activeFamily = ToolFamily.pen;
      _activePenType = newType;
      _loadPenType(newType);
      _syncCurrentFamilyStyleToPreset();
    });
    unawaited(_saveDrawingSettings());
  }

  void _switchHighlighterType(HighlighterUiType newType) {
    if (_activeHighlighterType == newType) {
      return;
    }
    _saveHighlighterType(_activeHighlighterType);
    _safeSetState(() {
      _activeFamily = ToolFamily.highlighter;
      _activeHighlighterType = newType;
      _loadHighlighterType(newType);
      _syncCurrentFamilyStyleToPreset();
    });
    unawaited(_saveDrawingSettings());
  }

  void _handlePenVariantChanged(PenVariant variant) {
    final nextType = _penUiTypeFromVariant(variant);
    if (_activeFamily != ToolFamily.pen) {
      _safeSetState(() => _activeFamily = ToolFamily.pen);
    }
    _switchPenType(nextType);
  }

  void _handleHighlighterVariantChanged(PenVariant variant) {
    final nextType = _highlighterUiTypeFromVariant(variant);
    if (_activeFamily != ToolFamily.highlighter) {
      _safeSetState(() => _activeFamily = ToolFamily.highlighter);
    }
    _switchHighlighterType(nextType);
  }

  void _handlePenWidthChanged(double width) {
    _safeSetState(() {
      _activeFamily = ToolFamily.pen;
      _currentPenWidth = width;
      _savePenType(_activePenType);
      _syncCurrentFamilyStyleToPreset();
    });
  }

  void _handlePenColorChanged(Color color) {
    _safeSetState(() {
      _activeFamily = ToolFamily.pen;
      _currentPenColor = color;
      _savePenType(_activePenType);
      _syncCurrentFamilyStyleToPreset();

      final updatedRecent = _buildRecentColors(_recentArgb, color.toARGB32());
      _recentArgb
        ..clear()
        ..addAll(updatedRecent);
    });
  }

  void _handleHighlighterWidthChanged(double width) {
    _safeSetState(() {
      _activeFamily = ToolFamily.highlighter;
      _currentHlWidth = width;
      _saveHighlighterType(_activeHighlighterType);
      _syncCurrentFamilyStyleToPreset();
    });
  }

  void _handleHighlighterOpacityChanged(double opacity) {
    _safeSetState(() {
      _activeFamily = ToolFamily.highlighter;
      _currentHlOpacity = opacity;
      _saveHighlighterType(_activeHighlighterType);
      _syncCurrentFamilyStyleToPreset();
    });
  }

  void _handleHighlighterColorChanged(Color color) {
    _safeSetState(() {
      _activeFamily = ToolFamily.highlighter;
      _currentHlColor = color;
      _saveHighlighterType(_activeHighlighterType);
      _syncCurrentFamilyStyleToPreset();

      final updatedRecent = _buildRecentColors(_recentArgb, color.toARGB32());
      _recentArgb
        ..clear()
        ..addAll(updatedRecent);
    });
  }

  void _applyCurrentStyleValues({
    double? width,
    double? opacity,
    Color? color,
    bool pushRecentColor = false,
  }) {
    _safeSetState(() {
      if (_activeFamily == ToolFamily.highlighter) {
        _currentHlWidth = width ?? _currentHlWidth;
        _currentHlOpacity = opacity ?? _currentHlOpacity;
        _currentHlColor = color ?? _currentHlColor;
        _saveHighlighterType(_activeHighlighterType);
      } else {
        _currentPenWidth = width ?? _currentPenWidth;
        _currentPenColor = color ?? _currentPenColor;
        _savePenType(_activePenType);
      }
      _syncCurrentFamilyStyleToPreset();
      if (pushRecentColor && color != null) {
        final updatedRecent = _buildRecentColors(_recentArgb, color.toARGB32());
        _recentArgb
          ..clear()
          ..addAll(updatedRecent);
      }
    });
  }

  PhotoViewController _photoControllerForPage(int pageNumber) {
    final controller = _pdfPhotoControllers.putIfAbsent(
      pageNumber,
      () => PhotoViewController(),
    );
    return controller;
  }

  PhotoViewScaleStateController _scaleStateControllerForPage(int pageNumber) {
    final controller = _pdfScaleStateControllers.putIfAbsent(
      pageNumber,
      () => PhotoViewScaleStateController(),
    );
    return controller;
  }

  GlobalKey _pdfPageContentKeyForPage(int pageNumber) {
    return _pdfPageContentKeys.putIfAbsent(pageNumber, GlobalKey.new);
  }

  void _resetPdfViewControllers() {
    for (final controller in _pdfPhotoControllers.values) {
      controller.dispose();
    }
    for (final controller in _pdfScaleStateControllers.values) {
      controller.dispose();
    }
    _pdfPhotoControllers.clear();
    _pdfScaleStateControllers.clear();
    _basePhotoViewDebugLogOnceKeys.clear();
    _pdfPageContentKeys.clear();
  }
}
