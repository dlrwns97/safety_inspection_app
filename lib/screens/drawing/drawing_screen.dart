import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:pdfx/pdfx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safety_inspection_app/application/drawing/use_cases/load_pdf_page_size_cache_use_case.dart';
import 'package:safety_inspection_app/application/drawing/use_cases/load_site_drawing_use_case.dart';
import 'package:safety_inspection_app/application/drawing/use_cases/persist_pdf_page_size_cache_use_case.dart';
import 'package:safety_inspection_app/application/drawing/use_cases/persist_site_drawing_use_case.dart';
import 'package:safety_inspection_app/constants/strings_ko.dart';
import 'package:safety_inspection_app/domain/drawing/repositories/drawing_repository.dart';
import 'package:safety_inspection_app/domain/drawing/repositories/pdf_page_size_cache_repository.dart';
import 'package:safety_inspection_app/domain/site/repositories/site_repository.dart';
import 'package:safety_inspection_app/infrastructure/persistence/file_store/drawing_file_repository.dart';
import 'package:safety_inspection_app/infrastructure/persistence/shared_prefs/pdf_page_size_cache_repository.dart';
import 'package:safety_inspection_app/infrastructure/persistence/shared_prefs/site_prefs_repository.dart';
import 'package:safety_inspection_app/models/defect.dart';
import 'package:safety_inspection_app/models/defect_details.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/screens/drawing/drawing_types.dart';
import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';
import 'package:safety_inspection_app/models/drawing/eraser_preview.dart';
import 'package:safety_inspection_app/screens/drawing/history/history_commands.dart';
import 'package:safety_inspection_app/screens/drawing/history/history_manager.dart';
import 'package:safety_inspection_app/screens/drawing/models/stroke_presets.dart';
import 'package:safety_inspection_app/models/equipment_marker.dart';
import 'package:safety_inspection_app/models/rebar_spacing_group_details.dart';
import 'package:safety_inspection_app/models/site.dart';
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
import 'package:safety_inspection_app/screens/drawing/drawing_verbose_logger.dart';
import 'package:safety_inspection_app/screens/drawing/engines/shape_engine.dart';
import 'package:safety_inspection_app/screens/drawing/engines/shape_interaction_coordinator.dart';
import 'package:safety_inspection_app/screens/drawing/engines/shape_manipulator.dart';
import 'package:safety_inspection_app/screens/drawing/flows/drawing_lookup_helpers.dart';
import 'package:safety_inspection_app/screens/drawing/flows/marker_presenters.dart';
import 'package:safety_inspection_app/screens/drawing/flows/pdf_controller_flow.dart';
import 'package:safety_inspection_app/presentation/drawing/states/drawing_session_state.dart';
import 'package:safety_inspection_app/presentation/drawing/controllers/marker_input_guard.dart';
import 'package:safety_inspection_app/presentation/drawing/controllers/marker_action_coordinator.dart';
import 'package:safety_inspection_app/presentation/drawing/controllers/pdf_viewport_controller.dart';
import 'package:safety_inspection_app/presentation/drawing/models/pdf_viewport_snapshot.dart';
import 'package:safety_inspection_app/presentation/drawing/controllers/pointer_intent_router.dart';
import 'package:safety_inspection_app/presentation/drawing/states/gesture_state.dart';
import 'package:safety_inspection_app/presentation/drawing/states/history_state.dart';
import 'package:safety_inspection_app/presentation/drawing/states/marker_state.dart';
import 'package:safety_inspection_app/presentation/drawing/states/persist_state.dart';
import 'package:safety_inspection_app/presentation/drawing/states/drawing_state_facade.dart';
import 'package:safety_inspection_app/presentation/drawing/states/tool_state.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/canvas_marker_layer.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/drawing_local_parts.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/drawing_top_bar.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/pen_settings_popup.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/highlighter_settings_popup.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/color_picker_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/eraser_settings_popup.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/settings_popover.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/shell/drawing_canvas_shell.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/shell/drawing_overlay_shell.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/shell/drawing_side_panel_shell.dart';
import 'package:safety_inspection_app/widgets/drawing/shape_handles_overlay.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/side_panel/marker_side_panel.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/pdf_drawing_view.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/pdf_view_layer.dart';

part 'drawing_screen_scale_prefs.part.dart';
part 'drawing_screen_logic.part.dart';
part 'drawing_screen_persistence.part.dart';
part 'drawing_screen_detail_dialogs.part.dart';
part 'drawing_screen_pointer_input.part.dart';
part 'drawing_screen_history_cleanup.part.dart';
part 'drawing_screen_move_actions.part.dart';
part 'drawing_screen_ui.part.dart';
part 'drawing_screen_ui_tool_popovers.part.dart';
part 'drawing_screen_tooling.part.dart';
part 'drawing_screen_marker_actions.part.dart';
part 'drawing_screen_state_accessors.part.dart';

class DrawingScreen extends StatefulWidget {
  const DrawingScreen({
    super.key,
    required this.site,
    required this.onSiteUpdated,
    this.drawingRepository,
    this.siteRepository,
    this.pdfPageSizeCacheRepository,
  });
  final Site site;
  final Future<void> Function(Site site) onSiteUpdated;
  final DrawingRepository? drawingRepository;
  final SiteRepository? siteRepository;
  final PdfPageSizeCacheRepository? pdfPageSizeCacheRepository;
  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
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
  final DrawingStateFacade _state = DrawingStateFacade();
  int _pdfViewVersion = 0;
  int? _pendingPdfRestorePage;
  bool _didRetryPendingPdfRestoreJump = false;
  Future<void> _persistPdfPageSiteTask = Future<void>.value();
  int? _queuedPdfPageForSitePersist;
  late Site _site;
  late final TabController _sidePanelController;
  DrawMode _mode = DrawMode.hand;
  String? _selectedShapeStrokeId;
  final ShapeInteractionCoordinator _shapeInteractionCoordinator =
      const ShapeInteractionCoordinator();
  ShapeManipulator? _activeShapeManipulator;
  ShapeHandle _activeShapeHandle = ShapeHandle.none;
  ShapeInteractionOperation _activeShapeEditOp = ShapeInteractionOperation.none;
  Offset? _shapeInteractionStartNorm;
  Offset? _shapeInteractionLastNorm;
  double? _shapeRotateGestureStartAngleRad;
  double? _shapeRotateGestureStartRotationRad;
  double _shapeCreateThresholdNorm = 0.0;
  bool _shapeCreateHasMoved = false;
  bool _isDetailDialogOpen = false;
  double _markerScale = 1.0;
  double _labelScale = 1.0;
  bool _isScaleLocked = false;
  bool _didLoadScalePrefs = false;
  bool _isRightPanelCollapsed = false;
  bool _isMoveMode = false;
  bool _isFreeDrawMode = false;
  ShapeType _activeShapeType = ShapeType.rectangle;
  static const double _kMinAreaEraserRadiusPx = 6.0;
  static const double _kMaxAreaEraserRadiusPx = 60.0;
  double _areaEraserRadiusPx = 24.0;
  static const double _kDrawStartSlopPx = 4.0;
  final SettingsPopoverController _settingsPopover =
      SettingsPopoverController();
  final LayerLink _penLink = LayerLink();
  final LayerLink _highlighterLink = LayerLink();
  final LayerLink _eraserLink = LayerLink();
  final LayerLink _shapeLink = LayerLink();
  final Map<int, List<DrawingStroke>> _strokesByPage =
      <int, List<DrawingStroke>>{};
  final Map<int, SpatialIndex> _strokeSpatialIndexByPage =
      <int, SpatialIndex>{};
  final Map<int, Size> _strokeSpatialIndexPageSizeByPage = <int, Size>{};
  final Set<int> _strokeSpatialIndexDirtyPages = <int>{};
  late final MarkerActionCoordinator _markerActionCoordinator;
  late final PdfViewportController _pdfViewportController;
  late final DrawingRepository _drawingRepository;
  late final SiteRepository _siteRepository;
  late final PdfPageSizeCacheRepository _pdfPageSizeCacheRepository;
  late final LoadSiteDrawingUseCase _loadSiteDrawingUseCase;
  late final PersistSiteDrawingUseCase _persistSiteDrawingUseCase;
  late final LoadPdfPageSizeCacheUseCase _loadPdfPageSizeCacheUseCase;
  late final PersistPdfPageSizeCacheUseCase _persistPdfPageSizeCacheUseCase;
  DrawingStroke? _inProgressStroke;
  int? _activePresetIndex = 0;
  final List<int> _recentArgb = <int>[];
  static const int _kMaxRecentColors = 5;
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
  static const Set<PenVariant> highlighterVariants = <PenVariant>{
    PenVariant.highlighter,
    PenVariant.marker,
  };
  late final ValueNotifier<PenVariant> _penVariantNotifier;
  late final ValueNotifier<double> _penWidthNotifier;
  late final ValueNotifier<Color> _penColorNotifier;
  late final ValueNotifier<PenVariant> _highlighterVariantNotifier;
  late final ValueNotifier<double> _highlighterWidthNotifier;
  late final ValueNotifier<double> _highlighterOpacityNotifier;
  late final ValueNotifier<Color> _highlighterColorNotifier;
  static const int kMaxHistory = 300;
  late final HistoryManager _historyManager = HistoryManager(
    maxHistory: kMaxHistory,
  );
  String? _moveTargetDefectId;
  String? _moveTargetEquipmentId;
  double? _moveOriginNormalizedX;
  double? _moveOriginNormalizedY;
  double? _movePreviewNormalizedX;
  double? _movePreviewNormalizedY;
  Offset? _moveLastGlobalPosition;

  Defect? get _selectedDefect => _selectedDefectId == null
      ? null
      : _findDefectById(_site, _selectedDefectId!);

  EquipmentMarker? get _selectedEquipment => _selectedEquipmentId == null
      ? null
      : _findEquipmentById(_site, _selectedEquipmentId!);

  Defect? get _moveTargetDefect => _moveTargetDefectId == null
      ? null
      : _findDefectById(_site, _moveTargetDefectId!);

  EquipmentMarker? get _moveTargetEquipment => _moveTargetEquipmentId == null
      ? null
      : _findEquipmentById(_site, _moveTargetEquipmentId!);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _markerActionCoordinator = const MarkerActionCoordinator();
    _pdfViewportController = const PdfViewportController();
    _drawingRepository = widget.drawingRepository ?? DrawingFileRepository();
    _siteRepository = widget.siteRepository ?? SitePrefsRepository();
    _pdfPageSizeCacheRepository =
        widget.pdfPageSizeCacheRepository ??
        SharedPrefsPdfPageSizeCacheRepository();
    _loadSiteDrawingUseCase = LoadSiteDrawingUseCase(
      drawingRepository: _drawingRepository,
    );
    _persistSiteDrawingUseCase = PersistSiteDrawingUseCase(
      drawingRepository: _drawingRepository,
      siteRepository: _siteRepository,
    );
    _loadPdfPageSizeCacheUseCase = LoadPdfPageSizeCacheUseCase(
      repository: _pdfPageSizeCacheRepository,
      minValidPageSide: _kMinValidPdfPageSide,
    );
    _persistPdfPageSizeCacheUseCase = PersistPdfPageSizeCacheUseCase(
      repository: _pdfPageSizeCacheRepository,
      minValidPageSide: _kMinValidPdfPageSide,
    );
    _canvasController = DrawingCanvasController();
    _strokeCacheManager = StrokeCacheManager();
    _canvasController.cacheRebuildTick.addListener(
      _handleCanvasCacheInvalidated,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _canvasController.invalidateCache(_currentPage, reason: 'initial');
    });
    _site = widget.site;
    _penVariantNotifier = ValueNotifier<PenVariant>(PenVariant.pen);
    _penWidthNotifier = ValueNotifier<double>(_currentPenWidth);
    _penColorNotifier = ValueNotifier<Color>(_currentPenColor);
    _highlighterVariantNotifier = ValueNotifier<PenVariant>(
      PenVariant.highlighter,
    );
    _highlighterWidthNotifier = ValueNotifier<double>(_currentHlWidth);
    _highlighterOpacityNotifier = ValueNotifier<double>(_currentHlOpacity);
    _highlighterColorNotifier = ValueNotifier<Color>(_currentHlColor);
    _seedVariantStateMaps();
    unawaited(_loadDrawingSettings());
    unawaited(_loadStrokesFromSite());
    _initializeDefectTabs();
    _initializeEquipmentTabs();
    _sidePanelController = TabController(
      length: 4,
      vsync: this,
      initialIndex: _sidePanelTabIndex,
    );
    _sidePanelController.addListener(_handleSidePanelTabChanged);
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
    _seedVariantStateMaps();
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_persistCurrentPdfPage(page: _currentPage));
      _schedulePersistCurrentPdfPageToSite(page: _currentPage);
      if (_persistPending || _hasUnsavedChanges) {
        _requestPersistDrawing(immediate: true);
      }
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
    WidgetsBinding.instance.removeObserver(this);
    _state.dispose();
    _canvasController.cacheRebuildTick.removeListener(
      _handleCanvasCacheInvalidated,
    );
    _canvasController.dispose();
    _strokeCacheManager.dispose();
    _resetPdfViewControllers();
    _transformationController.dispose();
    _sidePanelController.removeListener(_handleSidePanelTabChanged);
    _sidePanelController.dispose();
    _settingsPopover.hide();
    _penVariantNotifier.dispose();
    _penWidthNotifier.dispose();
    _penColorNotifier.dispose();
    _highlighterVariantNotifier.dispose();
    _highlighterWidthNotifier.dispose();
    _highlighterOpacityNotifier.dispose();
    _highlighterColorNotifier.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
    _syncPopupNotifiers();
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
    required int Function(T) pageOf,
    required Size pageSize,
    required bool Function(T) isSelected,
    required double Function(T) nx,
    required double Function(T) ny,
    required Widget Function(T, bool) buildMarker,
    required double markerScale,
  }) {
    const double baseMarkerSize = 30.0;
    const double dragHitBoxSize = 56.0;
    final scaledSize = (baseMarkerSize * markerScale).clamp(
      baseMarkerSize * 0.2,
      44.0,
    );
    final centerOffset = scaledSize / 2;
    final filteredItems = items
        .where((item) => pageOf(item) == pageIndex)
        .toList();
    return filteredItems.map((item) {
      final isTarget = _isMoveTargetItem(item);
      final isDraggable = isTarget && isSelected(item);
      final effectiveCenterOffset = isDraggable
          ? dragHitBoxSize / 2
          : centerOffset;
      final resolvedX = isTarget && _movePreviewNormalizedX != null
          ? _movePreviewNormalizedX!
          : nx(item);
      final resolvedY = isTarget && _movePreviewNormalizedY != null
          ? _movePreviewNormalizedY!
          : ny(item);
      Widget markerChild = buildMarker(item, isSelected(item));
      if (isDraggable) {
        markerChild = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (_) => _handleMovePanStart(item),
          onPanUpdate: (details) => _handleMovePanUpdate(details, pageSize),
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
    }).toList();
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
    final orderedVisible = _orderedVisibleEquipmentCategories(
      visibleCategories,
    );
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
    activeStrokeTool: _selectedToolKindForToolbar,
    canUndoDrawing: _canUndoDrawing,
    canRedoDrawing: _canRedoDrawing,
    onDrawingToolSelected: _selectToolAndOpenSettings,
    onUndoDrawing: _handleUndoDrawing,
    onRedoDrawing: _handleRedoDrawing,
    penToolLink: _penLink,
    highlighterToolLink: _highlighterLink,
    eraserToolLink: _eraserLink,
    shapeToolLink: _shapeLink,
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
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }
        await _handleExit();
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        bottomNavigationBar: _isMoveMode ? _buildMoveModeBottomBar() : null,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final showSidePanel = constraints.maxWidth >= 900;
            final drawingStack = SizedBox.expand(
              key: _pdfViewerKey,
              child: _buildDrawingOverlayShell(),
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
            return DrawingSidePanelShell(
              drawingContent: drawingStack,
              panelWidth: panelWidth,
              isCollapsed: _isRightPanelCollapsed,
              panelContent: _buildMarkerSidePanel(
                defectFilter: defectFilter,
                equipmentFilter: equipmentFilter,
              ),
              toggleButton: _buildRightPanelOverlayToggle(
                isCollapsed: _isRightPanelCollapsed,
                onToggle: () => setState(
                  () => _isRightPanelCollapsed = !_isRightPanelCollapsed,
                ),
              ),
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
