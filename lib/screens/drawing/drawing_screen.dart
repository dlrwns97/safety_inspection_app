import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safety_inspection_app/constants/strings_ko.dart';
import 'package:safety_inspection_app/models/defect.dart';
import 'package:safety_inspection_app/models/defect_details.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/equipment_marker.dart';
import 'package:safety_inspection_app/models/rebar_spacing_group_details.dart';
import 'package:safety_inspection_app/models/site.dart';
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
import 'package:safety_inspection_app/screens/drawing/flows/drawing_lookup_helpers.dart';
import 'package:safety_inspection_app/screens/drawing/flows/equipment_updated_site_flow.dart';
import 'package:safety_inspection_app/screens/drawing/flows/marker_presenters.dart';
import 'package:safety_inspection_app/screens/drawing/flows/marker_tap_flow.dart';
import 'package:safety_inspection_app/screens/drawing/flows/pdf_controller_flow.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/canvas_marker_layer.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/drawing_local_parts.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/drawing_top_bar.dart';
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
  final TransformationController _transformationController =
      TransformationController();
  final Map<int, PhotoViewController> _pdfPhotoControllers = {};
  final Map<int, PhotoViewScaleStateController> _pdfScaleStateControllers = {};
  final GlobalKey _canvasKey = GlobalKey();
  final GlobalKey _canvasTapRegionKey = GlobalKey();
  final Map<int, GlobalKey> _pdfTapRegionKeys = <int, GlobalKey>{};
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
  Defect? _selectedDefect;
  EquipmentMarker? _selectedEquipment;
  Offset? _selectedMarkerScenePosition;
  Offset? _pointerDownPosition;
  bool _tapCanceled = false;
  bool _isDetailDialogOpen = false;
  double _markerScale = 1.0;
  double _labelScale = 1.0;
  bool _isScaleLocked = false;
  bool _didLoadScalePrefs = false;
  bool _isMoveMode = false;
  Defect? _moveTargetDefect;
  EquipmentMarker? _moveTargetEquipment;
  double? _moveOriginNormalizedX;
  double? _moveOriginNormalizedY;
  double? _movePreviewNormalizedX;
  double? _movePreviewNormalizedY;

  PhotoViewController _photoControllerForPage(int pageNumber) {
    return _pdfPhotoControllers.putIfAbsent(
      pageNumber,
      () => PhotoViewController(),
    );
  }

  PhotoViewScaleStateController _scaleStateControllerForPage(int pageNumber) {
    return _pdfScaleStateControllers.putIfAbsent(
      pageNumber,
      () => PhotoViewScaleStateController(),
    );
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
          _selectedDefect = updatedDefect;
          _selectedEquipment = null;
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
          _selectedDefect = null;
          _selectedEquipment = updatedMarker;
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
    _site = widget.site;
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
  void dispose() {
    _pdfController?.dispose();
    _resetPdfViewControllers();
    _transformationController.dispose();
    _sidePanelController.dispose();
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
    onToggleMode: _toggleMode,
    onBack: _returnToToolSelection,
    onAdd: _handleAddToolAction,
    onDefectSelected: (category) => setState(
      () => _activeCategory = _controller
          .selectDefectCategory(tabs: _defectTabs, category: category)
          .activeCategory,
    ),
    onDefectLongPress: _showDeleteDefectTabDialog,
    onEquipmentSelected: (item) => setState(
      () => _activeEquipmentCategory = _controller
          .selectEquipmentCategory(item)
          .activeCategory,
    ),
    onEquipmentLongPress: _showDeleteEquipmentTabDialog,
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
    return Scaffold(
      appBar: _buildAppBar(),
      bottomNavigationBar:
          _isMoveMode ? _buildMoveModeBottomBar() : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final showSidePanel = constraints.maxWidth >= 900;
          final drawingStack = Stack(children: _buildDrawingStackChildren());
          if (!showSidePanel) {
            return drawingStack;
          }
          final panelWidth = (constraints.maxWidth * sidePanelWidthRatio)
              .clamp(sidePanelMinWidth, sidePanelMaxWidth)
              .toDouble();
          final defectFilter =
              _sidePanelDefectCategory ??
              _activeCategory ??
              DefectCategory.values.first;
          final equipmentFilter =
              _sidePanelEquipmentCategory ??
              _activeEquipmentCategory ??
              kEquipmentCategoryOrder.first;
          return Row(
            children: [
              Expanded(child: drawingStack),
              SizedBox(
                width: panelWidth,
                child: MarkerSidePanel(
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
                    () => _sidePanelDefectCategory = category,
                  ),
                  onEquipmentCategorySelected: (category) => setState(
                    () => _sidePanelEquipmentCategory = category,
                  ),
                  visibleDefectCategories: _visibleDefectCategories,
                  visibleEquipmentCategories: _visibleEquipmentCategories,
                  onDefectVisibilityChanged: (category, visible) => setState(
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
          );
        },
      ),
    );
  }
}
