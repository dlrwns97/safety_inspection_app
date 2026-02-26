import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:pdfx/pdfx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safety_inspection_app/constants/strings_ko.dart';
import 'package:safety_inspection_app/models/defect.dart';
import 'package:safety_inspection_app/models/defect_details.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/screens/drawing/drawing_types.dart';
import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';
import 'package:safety_inspection_app/models/drawing/eraser_preview.dart';
import 'package:safety_inspection_app/models/drawing/drawing_history_action_persisted.dart';
import 'package:safety_inspection_app/screens/drawing/history/history_commands.dart';
import 'package:safety_inspection_app/screens/drawing/history/history_manager.dart';
import 'package:safety_inspection_app/screens/drawing/models/stroke_presets.dart';
import 'package:safety_inspection_app/screens/drawing/persistence/drawing_persistence_store.dart';
import 'package:safety_inspection_app/models/equipment_marker.dart';
import 'package:safety_inspection_app/models/rebar_spacing_group_details.dart';
import 'package:safety_inspection_app/models/site.dart';
import 'package:safety_inspection_app/models/site_storage.dart';
import 'package:safety_inspection_app/screens/drawing/canvas/drawing_canvas_controller.dart';
import 'package:safety_inspection_app/screens/drawing/canvas/spatial_index.dart';
import 'package:safety_inspection_app/screens/drawing/canvas/drawing_canvas_widget.dart';
import 'package:safety_inspection_app/screens/drawing/canvas/stroke_cache_manager.dart';
import 'package:safety_inspection_app/screens/drawing/drawing_constants.dart';
import 'package:safety_inspection_app/screens/drawing/drawing_controller.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/carbonation_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/core_sampling_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/delete_defect_tab_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/delete_equipment_tab_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/defect_category_picker_sheet.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/equipment_category_picker_sheet.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/defect_details_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/deflection_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/equipment_details_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/rebar_spacing_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/schmidt_hammer_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/settlement_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/structural_tilt_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/drawing_coordinate_utils.dart';
import 'package:safety_inspection_app/screens/drawing/flows/drawing_lookup_helpers.dart';
import 'package:safety_inspection_app/screens/drawing/flows/equipment_updated_site_flow.dart';
import 'package:safety_inspection_app/screens/drawing/flows/marker_presenters.dart';
import 'package:safety_inspection_app/screens/drawing/flows/marker_tap_flow.dart';
import 'package:safety_inspection_app/screens/drawing/flows/pdf_controller_flow.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/canvas_marker_layer.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/drawing_local_parts.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/drawing_top_bar.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/pen_settings_popup.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/highlighter_settings_popup.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/color_picker_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/eraser_settings_popup.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/settings_popover.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/side_panel/marker_side_panel.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/pdf_drawing_view.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/pdf_view_layer.dart';

part 'drawing_screen_scale_prefs.part.dart';
part 'drawing_screen_logic.part.dart';
part 'drawing_screen_ui.part.dart';

class DrawingScreen extends StatefulWidget {
  const DrawingScreen({
    super.key,
    required this.site,
    required this.onSiteUpdated,
  });
  final Site site;
  final Future<void> Function(Site site) onSiteUpdated;
  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen>
    with SingleTickerProviderStateMixin {
  final DrawingController _controller = DrawingController();
  late final DrawingCanvasController _canvasController;
  late final StrokeCacheManager _strokeCacheManager;
  final TransformationController _transformationController =
      TransformationController();
  final Map<int, PhotoViewController> _pdfPhotoControllers = {};
  final Map<int, PhotoViewScaleStateController> _pdfScaleStateControllers = {};
  final Set<String> _basePhotoViewDebugLogOnceKeys = <String>{};
  final GlobalKey _canvasKey = GlobalKey();
  final GlobalKey<State<StatefulWidget>> _pdfViewerKey =
      GlobalKey<State<StatefulWidget>>();
  final GlobalKey _canvasTapRegionKey = GlobalKey();
  final Map<int, GlobalKey> _pdfTapRegionKeys = <int, GlobalKey>{};
  final Map<int, GlobalKey> _pdfPageContentKeys = <int, GlobalKey>{};
  final Map<int, Size> _pdfPageSizes = {};
  int _pdfViewVersion = 0;
  late Site _site;
  late final TabController _sidePanelController;
  PdfController? _pdfController;
  String? _pdfLoadError;
  DrawMode _mode = DrawMode.hand;
  DefectCategory? _activeCategory;
  EquipmentCategory? _activeEquipmentCategory;
  DefectCategory? _sidePanelDefectCategory;
  EquipmentCategory? _sidePanelEquipmentCategory;
  final Set<DefectCategory> _visibleDefectCategories =
      DefectCategory.values.toSet();
  final Set<EquipmentCategory> _visibleEquipmentCategories = {};
  final List<DefectCategory> _defectTabs = [];
  int _currentPage = 1;
  int _pageCount = 1;
  String? _selectedDefectId;
  String? _selectedEquipmentId;
  Offset? _selectedMarkerScenePosition;
  Offset? _pointerDownPosition;
  bool _tapCanceled = false;
  bool _isDetailDialogOpen = false;
  double _markerScale = 1.0;
  double _labelScale = 1.0;
  bool _isScaleLocked = false;
  bool _didLoadScalePrefs = false;
  bool _isRightPanelCollapsed = false;
  bool _isMoveMode = false;
  bool _isFreeDrawMode = false;
  bool _isToolPanelOpen = true;
  DrawingTool _activeTool = DrawingTool.pen;
  static const double _kMinAreaEraserRadiusPx = 6.0;
  static const double _kMaxAreaEraserRadiusPx = 60.0;
  double _areaEraserRadiusPx = 24.0;
  Offset? _eraserCursorPageLocal;
  int? _eraserCursorPageNumber;
  int? _activeAreaEraserPointerId;
  _AreaEraserSession? _activeAreaEraserSession;
  int? _activeStrokeEraserPointerId;
  final Set<String> _erasedStrokeIdsThisDrag = <String>{};
  int _erasedStrokeCountThisDrag = 0;
  _PendingAreaEraserMove? _pendingAreaEraserMove;
  final List<_PendingAreaEraserMove> _areaEraserPath =
      <_PendingAreaEraserMove>[];
  bool _isAreaEraserFrameScheduled = false;
  final Set<int> _activePointerIds = <int>{};
  final Map<int, PointerDeviceKind> _activePointerKinds =
      <int, PointerDeviceKind>{};
  int? _activeStylusPointerId;
  bool _isStraightenModeEnabled = false;
  bool _isStraightenSnapEnabled = true;
  final Map<int, double?> _straightenSnappedAngleByPointer =
      <int, double?>{};
  final Map<int, Offset> _straightenStartPageByPointer = <int, Offset>{};
  static const double kMinDragToConsiderSnapPx = 12.0;
  static const double kEnterSnapDeg = 7.0;
  static const double kExitSnapDeg = 12.0;
  static const List<double> kAnglesDeg = <double>[0, 45, 90, 135, 180];
  bool _isFreeDrawConsumingOneFinger = false;
  PhotoViewControllerValue? _navStartValue;
  int? _navStartPage;
  Offset _navAccumDelta = Offset.zero;
  int _debugNavUpdateLogCount = 0;
  Offset? _pendingDrawDownViewportLocal;
  bool _pendingDraw = false;
  static const double _kDrawStartSlopPx = 4.0;
  bool _didShowFreeDrawGuide = false;
  final SettingsPopoverController _settingsPopover = SettingsPopoverController();
  final LayerLink _penLink = LayerLink();
  final LayerLink _highlighterLink = LayerLink();
  final LayerLink _eraserLink = LayerLink();
  final Map<int, List<DrawingStroke>> _strokesByPage = <int, List<DrawingStroke>>{};
  final Map<int, SpatialIndex> _strokeSpatialIndexByPage = <int, SpatialIndex>{};
  final Map<int, Size> _strokeSpatialIndexPageSizeByPage = <int, Size>{};
  final Set<int> _strokeSpatialIndexDirtyPages = <int>{};
  final DrawingPersistenceStore _drawingPersistenceStore =
      DrawingPersistenceStore();
  DrawingStroke? _inProgressStroke;
  bool _hasUnsavedChanges = false;
  Timer? _persistDebounce;
  bool _persistInFlight = false;
  bool _persistPending = false;
  int _persistEpoch = 0;
  bool _didWarnUnsavedOnExit = false;
  int? _activePresetIndex = 0;
  final List<int> _recentArgb = <int>[];
  static const int _kMaxRecentColors = 12;
  final List<int> _standardPaletteArgb = const <int>[
    0xFF000000,
    0xFFFFFFFF,
    0xFFBDBDBD,
    0xFFE53935,
    0xFFFF9800,
    0xFFFFEB3B,
    0xFF43A047,
    0xFF00BCD4,
    0xFF1E88E5,
    0xFF3F51B5,
    0xFF8E24AA,
    0xFF6D4C41,
  ];
  late final List<StrokeStyle> _presets = StrokePresets.defaults();
  static const double _kDefaultHighlighterOpacity = 0.35;
  static const double _kDefaultMarkerOpacity = 0.80;
  final Map<PenVariant, double> _highlighterOpacityByVariant =
      <PenVariant, double>{
        PenVariant.highlighter: _kDefaultHighlighterOpacity,
        PenVariant.highlighterChisel: _kDefaultHighlighterOpacity,
        PenVariant.marker: _kDefaultMarkerOpacity,
        PenVariant.markerChisel: _kDefaultMarkerOpacity,
      };
  bool _canUndoDrawing = false;
  bool _canRedoDrawing = false;
  static const int kMaxHistory = 300;
  late final HistoryManager _historyManager =
      HistoryManager(maxHistory: kMaxHistory);
  String? _moveTargetDefectId;
  String? _moveTargetEquipmentId;
  double? _moveOriginNormalizedX;
  double? _moveOriginNormalizedY;
  double? _movePreviewNormalizedX;
  double? _movePreviewNormalizedY;
  Offset? _moveLastGlobalPosition;

  Defect? get _selectedDefect =>
      _selectedDefectId == null
          ? null
          : _findDefectById(_site, _selectedDefectId!);

  EquipmentMarker? get _selectedEquipment =>
      _selectedEquipmentId == null
          ? null
          : _findEquipmentById(_site, _selectedEquipmentId!);

  Defect? get _moveTargetDefect =>
      _moveTargetDefectId == null
          ? null
          : _findDefectById(_site, _moveTargetDefectId!);

  EquipmentMarker? get _moveTargetEquipment =>
      _moveTargetEquipmentId == null
          ? null
          : _findEquipmentById(_site, _moveTargetEquipmentId!);

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

  StrokeToolKind get _activeToolKindForToolbar {
    if (_activeTool == DrawingTool.areaEraser ||
        _activeTool == DrawingTool.strokeEraser) {
      return StrokeToolKind.eraser;
    }
    return _activeStrokeStyleOrFallback.kind;
  }

  void _setToolPanelOpen(bool value) =>
      _safeSetState(() => _isToolPanelOpen = value);

  void _toggleActivePreset(int index) {
    final normalizedIndex = _clampPresetIndex(index);
    final shouldUnselect = _activePresetIndex == normalizedIndex;
    if (shouldUnselect && _inProgressStroke != null) {
      _handleFreeDrawEnd(_inProgressStroke?.pageNumber ?? _currentPage);
    }
    _safeSetState(() {
      _activePresetIndex = shouldUnselect ? null : normalizedIndex;
      if (!shouldUnselect) {
        _activeTool = DrawingTool.pen;
      }
      if (_activePresetIndex == null) {
        _isFreeDrawConsumingOneFinger = false;
        _pendingDraw = false;
        _pendingDrawDownViewportLocal = null;
        _activeStylusPointerId = null;
      }
    });
  }

  void _pushRecentColor(int argb) {
    final rgb = Color(argb).withAlpha(0xFF).value;
    _safeSetState(() {
      _recentArgb.remove(rgb);
      _recentArgb.insert(0, rgb);
      if (_recentArgb.length > _kMaxRecentColors) {
        _recentArgb.removeRange(_kMaxRecentColors, _recentArgb.length);
      }
    });
  }

  bool _isMarkerVariant(PenVariant variant) {
    return variant == PenVariant.marker || variant == PenVariant.markerChisel;
  }

  bool _isHighlighterFamilyVariant(PenVariant variant) {
    return variant == PenVariant.highlighter ||
        variant == PenVariant.highlighterChisel ||
        variant == PenVariant.marker ||
        variant == PenVariant.markerChisel;
  }

  PenVariant _normalizedHighlighterVariant(PenVariant variant) {
    return _isMarkerVariant(variant) ? PenVariant.marker : PenVariant.highlighter;
  }

  double _defaultOpacityForHighlighterVariant(PenVariant variant) {
    return _isMarkerVariant(variant)
        ? _kDefaultMarkerOpacity
        : _kDefaultHighlighterOpacity;
  }

  StrokeStyle _styleForHighlighterVariantSwitch({
    required StrokeStyle current,
    required PenVariant nextVariant,
  }) {
    if (!_isHighlighterFamilyVariant(nextVariant)) {
      return current.copyWith(variant: nextVariant);
    }
    final currentVariant = _normalizedHighlighterVariant(current.variant);
    if (_isHighlighterFamilyVariant(current.variant)) {
      _highlighterOpacityByVariant[currentVariant] = current.opacity;
    }
    final normalizedNextVariant = _normalizedHighlighterVariant(nextVariant);
    final nextOpacity =
        _highlighterOpacityByVariant[normalizedNextVariant] ??
        _defaultOpacityForHighlighterVariant(normalizedNextVariant);
    _highlighterOpacityByVariant[normalizedNextVariant] = nextOpacity;
    return current.copyWith(variant: nextVariant, opacity: nextOpacity);
  }

  void _updateActivePreset(StrokeStyle next) {
    final index = _activePresetIndex;
    if (index == null) {
      return;
    }
    final normalizedIndex = _clampPresetIndex(index);
    _safeSetState(() {
      _presets[normalizedIndex] = next;
      if (kDebugMode) {
        debugPrint(
          '[Drawing] updateActivePreset index=$normalizedIndex '
          'kind=${next.kind.name} variant=${next.variant.name} '
          'width=${next.widthPx.toStringAsFixed(1)} color=${next.argbColor}',
        );
      }
    });
  }


  void _applyPresetWithRecentColor(StrokeStyle next) {
    final index = _activePresetIndex;
    if (index == null) {
      return;
    }
    final normalizedIndex = _clampPresetIndex(index);
    _safeSetState(() {
      _presets[normalizedIndex] = next;
      if (kDebugMode) {
        debugPrint(
          '[Drawing] applyPresetWithRecentColor index=$normalizedIndex '
          'kind=${next.kind.name} variant=${next.variant.name} '
          'width=${next.widthPx.toStringAsFixed(1)} color=${next.argbColor}',
        );
      }
      final rgb = Color(next.argbColor).withAlpha(0xFF).value;
      _recentArgb.remove(rgb);
      _recentArgb.insert(0, rgb);
      if (_recentArgb.length > _kMaxRecentColors) {
        _recentArgb.removeRange(_kMaxRecentColors, _recentArgb.length);
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

  void _handleEditPressed() async {
    final selectedDefect = _selectedDefect;
    final selectedEquipment = _selectedEquipment;
    if (selectedDefect == null && selectedEquipment == null) {
      return;
    }
    if (selectedDefect != null) {
      final detailsResult = await _showDefectDetailsDialog(
        category: selectedDefect.category,
        initialDetails: selectedDefect.details,
      );
      if (detailsResult == null) {
        return;
      }
      final updatedDefect = Defect(
        id: selectedDefect.id,
        label: selectedDefect.label,
        pageIndex: selectedDefect.pageIndex,
        category: selectedDefect.category,
        normalizedX: selectedDefect.normalizedX,
        normalizedY: selectedDefect.normalizedY,
        details: detailsResult,
      );
      final updatedDefects =
          _site.defects
              .map(
                (defect) =>
                    defect.id == updatedDefect.id ? updatedDefect : defect,
              )
              .toList();
      final updatedSite = _site.copyWith(defects: updatedDefects);
      await _applyUpdatedSite(
        updatedSite,
        onStateUpdated: () {
          _selectedDefectId = updatedDefect.id;
          _selectedEquipmentId = null;
        },
      );
      return;
    }
    if (selectedEquipment != null) {
      final updatedMarker = await _editEquipmentMarker(selectedEquipment);
      if (updatedMarker == null) {
        return;
      }
      final updatedMarkers =
          _site.equipmentMarkers
              .map(
                (marker) =>
                    marker.id == updatedMarker.id ? updatedMarker : marker,
              )
              .toList();
      final updatedSite = _site.copyWith(equipmentMarkers: updatedMarkers);
      await _applyUpdatedSite(
        updatedSite,
        onStateUpdated: () {
          _selectedDefectId = null;
          _selectedEquipmentId = updatedMarker.id;
        },
      );
    }
  }

  Future<EquipmentMarker?> _editEquipmentMarker(
    EquipmentMarker marker,
  ) async {
    if (marker.category == EquipmentCategory.equipment8) {
      final nextIndexByDirection = {
        'Lx': nextSettlementIndex(_site, 'Lx'),
        'Ly': nextSettlementIndex(_site, 'Ly'),
      };
      final details = await _showSettlementDialog(
        baseTitle: '부동침하',
        nextIndexByDirection: nextIndexByDirection,
        initialDirection: settlementDirection(marker),
        initialDisplacementText: marker.displacementText,
      );
      if (details == null) {
        return null;
      }
      return marker.copyWith(
        equipmentTypeId: details.direction,
        tiltDirection: details.direction,
        displacementText: details.displacementText,
      );
    }
    final siteWithoutMarker = _site.copyWith(
      equipmentMarkers:
          _site.equipmentMarkers
              .where((item) => item.id != marker.id)
              .toList(),
    );
    final updatedSite = await createEquipmentUpdatedSite(
      context: context,
      site: siteWithoutMarker,
      activeEquipmentCategory: marker.category,
      pendingMarker: marker,
      prefix: equipmentLabelPrefix(marker.category),
      allowRebarSpacingMulti: true,
      deflectionMemberOptions: DrawingDeflectionMemberOptions,
      showEquipmentDetailsDialog: _showEquipmentDetailsDialog,
      showRebarSpacingDialog:
          (
            context, {
            required title,
            initialMemberType,
            initialMeasurements,
            allowMultiple = false,
            baseLabelIndex,
            labelPrefix,
          }) => _showRebarSpacingDialog(
            title: title,
            initialMemberType: initialMemberType,
            initialMeasurements: initialMeasurements,
            allowMultiple: allowMultiple,
            baseLabelIndex: baseLabelIndex,
            labelPrefix: labelPrefix,
          ),
      showSchmidtHammerDialog:
          (
            context, {
            required title,
            initialMemberType,
            initialAngleDeg,
            initialMaxValueText,
            initialMinValueText,
          }) => _showSchmidtHammerDialog(
            title: title,
            initialMemberType: initialMemberType,
            initialAngleDeg: initialAngleDeg,
            initialMaxValueText: initialMaxValueText,
            initialMinValueText: initialMinValueText,
          ),
      showCoreSamplingDialog:
          (context, {required title, initialMemberType, initialAvgValueText}) =>
              _showCoreSamplingDialog(
                title: title,
                initialMemberType: initialMemberType,
                initialAvgValueText: initialAvgValueText,
              ),
      showCarbonationDialog: _showCarbonationDialog,
      showStructuralTiltDialog: _showStructuralTiltDialog,
      showDeflectionDialog:
          ({
            required title,
            required memberOptions,
            initialMemberType,
            initialEndAText,
            initialMidBText,
            initialEndCText,
          }) => _showDeflectionDialog(
            title: title,
            initialMemberType: initialMemberType,
            initialEndAText: initialEndAText,
            initialMidBText: initialMidBText,
            initialEndCText: initialEndCText,
          ),
    );
    if (updatedSite == null) {
      return null;
    }
    for (final item in updatedSite.equipmentMarkers) {
      if (item.id == marker.id) {
        return item;
      }
    }
    return null;
  }

  void _handleMovePressed() {
    if (_isMoveMode) {
      _cancelMoveMode();
      return;
    }
    if (_selectedDefect == null && _selectedEquipment == null) {
      return;
    }
    _enterMoveMode();
  }

  void _handleDeletePressed() {
    _confirmDeleteSelectedMarker();
  }

  Future<void> _confirmDeleteSelectedMarker() async {
    final selectedDefect = _selectedDefect;
    final selectedEquipment = _selectedEquipment;
    if (selectedDefect == null && selectedEquipment == null) {
      return;
    }
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: const Text('정말로 삭제 하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('아니오'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('예'),
            ),
          ],
        );
      },
    );
    if (shouldDelete != true || !mounted) {
      return;
    }
    if (selectedDefect != null) {
      final updatedDefects =
          _site.defects
              .where((defect) => defect.id != selectedDefect.id)
              .toList();
      await _applyUpdatedSite(
        _site.copyWith(defects: updatedDefects),
        onStateUpdated: () {
          _clearSelectionAndPopup(inSetState: false);
        },
      );
      return;
    }
    if (selectedEquipment != null) {
      final updatedMarkers =
          _site.equipmentMarkers
              .where((marker) => marker.id != selectedEquipment.id)
              .toList();
      await _applyUpdatedSite(
        _site.copyWith(equipmentMarkers: updatedMarkers),
        onStateUpdated: () {
          _clearSelectionAndPopup(inSetState: false);
        },
      );
    }
  }

  GlobalKey _pdfTapRegionKeyForPage(int pageNumber) {
    return _pdfTapRegionKeys.putIfAbsent(pageNumber, () => GlobalKey());
  }
  @override
  void initState() {
    super.initState();
    _canvasController = DrawingCanvasController();
    _strokeCacheManager = StrokeCacheManager();
    _canvasController.cacheRebuildTick.addListener(
      _handleCanvasCacheInvalidated,
    );
    if (kDebugMode) {
      debugPrint('legacy painter removed / using DrawingCanvasWidget');
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _canvasController.invalidateCache(_currentPage, reason: 'initial');
    });
    _site = widget.site;
    final initialHighlighterPreset = _presets.firstWhere(
      (style) => style.kind == StrokeToolKind.highlighter,
      orElse: () => const StrokeStyle(kind: StrokeToolKind.highlighter),
    );
    final initialVariant =
        _normalizedHighlighterVariant(initialHighlighterPreset.variant);
    _highlighterOpacityByVariant[initialVariant] = initialHighlighterPreset.opacity;
    unawaited(_loadStrokesFromSite());
    _initializeDefectTabs();
    _initializeEquipmentTabs();
    _sidePanelController = TabController(length: 4, vsync: this);
    _resetScalePreferences(notify: false);
    _loadPdfPageSizeCache();
    _loadPdfController();
    _loadScalePreferences();
  }
  @override
  void didUpdateWidget(covariant DrawingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.site == oldWidget.site) {
      return;
    }
    final didChangeDrawing =
        _drawingIdentityKey(widget.site) != _drawingIdentityKey(oldWidget.site);
    _site = widget.site;
    final initialHighlighterPreset = _presets.firstWhere(
      (style) => style.kind == StrokeToolKind.highlighter,
      orElse: () => const StrokeStyle(kind: StrokeToolKind.highlighter),
    );
    final initialVariant =
        _normalizedHighlighterVariant(initialHighlighterPreset.variant);
    _highlighterOpacityByVariant[initialVariant] = initialHighlighterPreset.opacity;
    unawaited(_loadStrokesFromSite());
    _initializeDefectTabs();
    _initializeEquipmentTabs();
    if (didChangeDrawing) {
      _resetScalePreferences();
      _loadScalePreferences();
      _loadPdfPageSizeCache();
      _loadPdfController();
    }
  }

  Defect? _findDefectById(Site updatedSite, String defectId) {
    for (final defect in updatedSite.defects) {
      if (defect.id == defectId) {
        return defect;
      }
    }
    return null;
  }

  EquipmentMarker? _findEquipmentById(Site updatedSite, String markerId) {
    for (final marker in updatedSite.equipmentMarkers) {
      if (marker.id == markerId) {
        return marker;
      }
    }
    return null;
  }
  @override
  void dispose() {
    _persistDebounce?.cancel();
    _canvasController.cacheRebuildTick.removeListener(
      _handleCanvasCacheInvalidated,
    );
    _canvasController.dispose();
    _strokeCacheManager.dispose();
    _pdfController?.dispose();
    _resetPdfViewControllers();
    _transformationController.dispose();
    _sidePanelController.dispose();
    _settingsPopover.hide();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }
  MarkerHitResult? _hitTestMarker({
    required Offset point,
    required Size size,
    required int pageIndex,
  }) {
    const baseHitRadius = 24.0;
    const minHitRadius = 16.0;
    final hitRadius = math.max(minHitRadius, baseHitRadius * _markerScale);
    final hitRadiusSquared = hitRadius * hitRadius;
    double closestDistance = hitRadiusSquared;
    Defect? defectHit;
    EquipmentMarker? equipmentHit;
    Offset? positionHit;
    for (final defect in _site.defects.where(
      (defect) => defect.pageIndex == pageIndex,
    )) {
      final position = Offset(
        defect.normalizedX * size.width,
        defect.normalizedY * size.height,
      );
      final distance = (point - position).distanceSquared;
      if (distance <= closestDistance) {
        closestDistance = distance;
        defectHit = defect;
        equipmentHit = null;
        positionHit = position;
      }
    }
    for (final marker in _site.equipmentMarkers.where(
      (marker) => marker.pageIndex == pageIndex,
    )) {
      final position = Offset(
        marker.normalizedX * size.width,
        marker.normalizedY * size.height,
      );
      final distance = (point - position).distanceSquared;
      if (distance <= closestDistance) {
        closestDistance = distance;
        defectHit = null;
        equipmentHit = marker;
        positionHit = position;
      }
    }
    if (positionHit == null) {
      return null;
    }
    return MarkerHitResult(
      defect: defectHit,
      equipment: equipmentHit,
      position: positionHit,
    );
  }

  List<MarkerHitResult> _hitTestMarkers({
    required Offset point,
    required Size size,
    required int pageIndex,
  }) {
    const baseHitRadius = 24.0;
    const minHitRadius = 16.0;
    final hitRadius = math.max(minHitRadius, baseHitRadius * _markerScale);
    final hitRadiusSquared = hitRadius * hitRadius;
    final results = <MarkerHitResult>[];
    for (final defect in _site.defects.where(
      (defect) => defect.pageIndex == pageIndex,
    )) {
      final position = Offset(
        defect.normalizedX * size.width,
        defect.normalizedY * size.height,
      );
      final distance = (point - position).distanceSquared;
      if (distance <= hitRadiusSquared) {
        results.add(
          MarkerHitResult(defect: defect, equipment: null, position: position),
        );
      }
    }
    for (final marker in _site.equipmentMarkers.where(
      (marker) => marker.pageIndex == pageIndex,
    )) {
      final position = Offset(
        marker.normalizedX * size.width,
        marker.normalizedY * size.height,
      );
      final distance = (point - position).distanceSquared;
      if (distance <= hitRadiusSquared) {
        results.add(
          MarkerHitResult(defect: null, equipment: marker, position: position),
        );
      }
    }
    return results;
  }
  List<Widget> _buildMarkersForPage<T extends Object>({
    required Iterable<T> items,
    required int pageIndex,
    required Size pageSize,
    required bool Function(T) isSelected,
    required double Function(T) nx,
    required double Function(T) ny,
    required Widget Function(T, bool) buildMarker,
    required double markerScale,
  }) {
    const double baseMarkerSize = 30.0;
    const double dragHitBoxSize = 56.0;
    final scaledSize = (baseMarkerSize * markerScale)
        .clamp(baseMarkerSize * 0.2, 44.0);
    final centerOffset = scaledSize / 2;
    final filteredItems = items
        .where((item) => (item as dynamic).pageIndex == pageIndex)
        .toList();
    return filteredItems
        .map(
          (item) {
            final isTarget = _isMoveTargetItem(item);
            final isDraggable = isTarget && isSelected(item);
            final effectiveCenterOffset =
                isDraggable ? dragHitBoxSize / 2 : centerOffset;
            final resolvedX =
                isTarget && _movePreviewNormalizedX != null
                    ? _movePreviewNormalizedX!
                    : nx(item);
            final resolvedY =
                isTarget && _movePreviewNormalizedY != null
                    ? _movePreviewNormalizedY!
                    : ny(item);
            Widget markerChild = buildMarker(item, isSelected(item));
            if (isDraggable) {
              markerChild = GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (_) => _handleMovePanStart(item),
                onPanUpdate:
                    (details) => _handleMovePanUpdate(details, pageSize),
                onPanEnd: (_) => _handleMovePanEnd(),
                onPanCancel: _handleMovePanCancel,
                child: SizedBox.square(
                  dimension: dragHitBoxSize,
                  child: Center(child: markerChild),
                ),
              );
            }
            return Positioned(
              left: resolvedX * pageSize.width - effectiveCenterOffset,
              top: resolvedY * pageSize.height - effectiveCenterOffset,
              child: markerChild,
            );
          },
        )
        .toList();
  }
  EquipmentCategory? _nextActiveEquipmentCategory(
    EquipmentCategory? current,
    Set<EquipmentCategory> visibleCategories,
  ) {
    if (visibleCategories.isEmpty) {
      return current;
    }
    if (current == null) {
      return null;
    }
    if (visibleCategories.contains(current)) {
      return current;
    }
    final orderedVisible = _orderedVisibleEquipmentCategories(visibleCategories);
    return orderedVisible.isNotEmpty ? orderedVisible.first : current;
  }

  Future<T?> _showDetailDialog<T>(Future<T?> Function() dialogBuilder) async {
    if (_isDetailDialogOpen) {
      return null;
    }
    _isDetailDialogOpen = true;
    try {
      return await dialogBuilder();
    } finally {
      _isDetailDialogOpen = false;
    }
  }
  DrawingTopBar _buildDrawingTopBar() => DrawingTopBar(
    mode: _mode,
    isToolSelectionMode: _controller.isToolSelectionMode(_mode),
    defectTabs: _defectTabs,
    activeCategory: _activeCategory,
    activeEquipmentCategory: _activeEquipmentCategory,
    equipmentTabs: kEquipmentCategoryOrder
        .where((category) => _visibleEquipmentCategories.contains(category))
        .toList(),
    onToggleMode: (nextMode) {
      if (nextMode == DrawMode.freeDraw &&
          (_mode == DrawMode.freeDraw || _mode == DrawMode.eraser)) {
        _toggleMode(DrawMode.hand);
        return;
      }
      _toggleMode(nextMode);
    },
    onBack: _returnToToolSelection,
    onAdd: _handleAddToolAction,
    onDefectSelected: (category) => setState(() {
      if (_activeCategory == category) {
        _activeCategory = null;
        _sidePanelDefectCategory = null;
        return;
      }
      _activeCategory = _controller
          .selectDefectCategory(tabs: _defectTabs, category: category)
          .activeCategory;
      _sidePanelDefectCategory = category;
    }),
    onDefectLongPress: _showDeleteDefectTabDialog,
    onEquipmentSelected: (item) => setState(() {
      if (_activeEquipmentCategory == item) {
        _activeEquipmentCategory = null;
        _sidePanelEquipmentCategory = null;
        return;
      }
      _activeEquipmentCategory = _controller
          .selectEquipmentCategory(item)
          .activeCategory;
      _sidePanelEquipmentCategory = item;
    }),
    onEquipmentLongPress: _showDeleteEquipmentTabDialog,
    activeStrokeTool: _activeToolKindForToolbar,
    canUndoDrawing: _canUndoDrawing,
    canRedoDrawing: _canRedoDrawing,
    onDrawingToolSelected: _selectToolAndOpenSettings,
    onUndoDrawing: _handleUndoDrawing,
    onRedoDrawing: _handleRedoDrawing,
    penToolLink: _penLink,
    highlighterToolLink: _highlighterLink,
    eraserToolLink: _eraserLink,
  );
  CanvasMarkerLayer _buildMarkerLayer({
    required Widget child,
    required Size size,
    required int pageIndex,
  }) {
    return CanvasMarkerLayer(
      childPdfOrCanvas: child,
      markerWidgets: _buildMarkerWidgetsForPage(
        size: size,
        pageIndex: pageIndex,
      ),
    );
  }
  Future<Map<int, Size>> _prefetchPdfPageSizes(PdfDocument document) async {
    const double baseWidth = 1000;
    final Map<int, Size> sizes = {};
    for (var pageNumber = 1; pageNumber <= document.pagesCount; pageNumber++) {
      final page = await document.getPage(pageNumber);
      try {
        final pageWidth = page.width.toDouble();
        final pageHeight = page.height.toDouble();
        if (pageWidth > 0 && pageHeight > 0) {
          sizes[pageNumber] = Size(
            baseWidth,
            baseWidth * (pageHeight / pageWidth),
          );
        }
      } finally {
        await page.close();
      }
    }
    return sizes;
  }
  @override
  Widget build(BuildContext context) {
    const double sidePanelWidthRatio = 0.20;
    const double sidePanelMinWidth = 260;
    const double sidePanelMaxWidth = 320;
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) {
          return;
        }
        await _handleExit();
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        bottomNavigationBar:
            _isMoveMode ? _buildMoveModeBottomBar() : null,
        body: LayoutBuilder(
        builder: (context, constraints) {
          final showSidePanel = constraints.maxWidth >= 900;
          final drawingStack = SizedBox.expand(
            key: _pdfViewerKey,
            child: Stack(children: _buildDrawingStackChildren()),
          );
          if (!showSidePanel) {
            return drawingStack;
          }
          final panelWidth = (constraints.maxWidth * sidePanelWidthRatio)
              .clamp(sidePanelMinWidth, sidePanelMaxWidth)
              .toDouble();
          final defectFilter = _sidePanelDefectCategory ?? _activeCategory;
          final equipmentFilter =
              _sidePanelEquipmentCategory ?? _activeEquipmentCategory;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                children: [
                  Expanded(child: drawingStack),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    width: _isRightPanelCollapsed ? 0 : panelWidth,
                    child:
                        _isRightPanelCollapsed
                            ? null
                            : MarkerSidePanel(
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
                              onDefectCategorySelected: (category) => setState(
                                () {
                                  if (_activeCategory == category) {
                                    _activeCategory = null;
                                    _sidePanelDefectCategory = null;
                                  } else {
                                    _activeCategory = category;
                                    _sidePanelDefectCategory = category;
                                  }
                                },
                              ),
                              onEquipmentCategorySelected:
                                  (category) => setState(
                                    () {
                                      if (_activeEquipmentCategory ==
                                          category) {
                                        _activeEquipmentCategory = null;
                                        _sidePanelEquipmentCategory = null;
                                      } else {
                                        _activeEquipmentCategory = category;
                                        _sidePanelEquipmentCategory = category;
                                      }
                                    },
                                  ),
                              visibleDefectCategories: _visibleDefectCategories,
                              visibleEquipmentCategories:
                                  _visibleEquipmentCategories,
                              onDefectVisibilityChanged:
                                  (category, visible) => setState(
                                    () {
                                      if (visible) {
                                        _visibleDefectCategories.add(category);
                                      } else {
                                        _visibleDefectCategories.remove(category);
                                      }
                                    },
                                  ),
                              onEquipmentVisibilityChanged:
                                  _handleEquipmentVisibilityChanged,
                              markerScale: _markerScale,
                              labelScale: _labelScale,
                              onMarkerScaleChanged: _handleMarkerScaleChanged,
                              onLabelScaleChanged: _handleLabelScaleChanged,
                              isMarkerScaleLocked: _isScaleLocked,
                              onToggleMarkerScaleLock: _toggleScaleLock,
                              onEditPressed: _handleEditPressed,
                              onMovePressed: _handleMovePressed,
                              onDeletePressed: _handleDeletePressed,
                            ),
                  ),
                ],
              ),
              Positioned(
                right: _isRightPanelCollapsed ? -16 : panelWidth - 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _buildRightPanelOverlayToggle(
                    isCollapsed: _isRightPanelCollapsed,
                    onToggle: () => setState(
                      () => _isRightPanelCollapsed = !_isRightPanelCollapsed,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        ),
      ),
    );
  }
}

class SingleFingerPanRecognizer extends OneSequenceGestureRecognizer {
  SingleFingerPanRecognizer({
    this.onStart,
    this.onUpdate,
    this.onEnd,
    this.onCancel,
    super.supportedDevices,
  });

  ValueChanged<PanPointerDetails>? onStart;
  ValueChanged<PanPointerDetails>? onUpdate;
  VoidCallback? onEnd;
  VoidCallback? onCancel;

  int? _primaryPointer;
  bool _accepted = false;
  bool _didCancel = false;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (_primaryPointer == null) {
      _primaryPointer = event.pointer;
      _accepted = false;
      _didCancel = false;
      startTrackingPointer(event.pointer);
      return;
    }
    _cancelAndRejectAll();
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event.pointer != _primaryPointer) {
      return;
    }
    if (event is PointerMoveEvent) {
      if (!_accepted) {
        resolve(GestureDisposition.accepted);
        _accepted = true;
        onStart?.call(
          PanPointerDetails(
            localPosition: event.localPosition,
            globalPosition: event.position,
          ),
        );
      }
      onUpdate?.call(
        PanPointerDetails(
          localPosition: event.localPosition,
          globalPosition: event.position,
        ),
      );
      return;
    }
    if (event is PointerUpEvent) {
      if (_accepted) {
        onEnd?.call();
      }
      _stopAndReset();
      return;
    }
    if (event is PointerCancelEvent) {
      _cancelAndRejectAll();
    }
  }

  void _cancelAndRejectAll() {
    if (_primaryPointer != null) {
      stopTrackingPointer(_primaryPointer!);
    }
    if (!_didCancel) {
      _didCancel = true;
      onCancel?.call();
    }
    resolve(GestureDisposition.rejected);
    _stopAndReset();
  }

  void _stopAndReset() {
    final primary = _primaryPointer;
    if (primary != null) {
      stopTrackingPointer(primary);
    }
    _primaryPointer = null;
    _accepted = false;
    _didCancel = false;
  }

  @override
  String get debugDescription => 'single_finger_pan';

  @override
  void didStopTrackingLastPointer(int pointer) {
    _primaryPointer = null;
    _accepted = false;
    _didCancel = false;
  }
}

class PanPointerDetails {
  const PanPointerDetails({
    required this.localPosition,
    required this.globalPosition,
  });

  final Offset localPosition;
  final Offset globalPosition;
}
