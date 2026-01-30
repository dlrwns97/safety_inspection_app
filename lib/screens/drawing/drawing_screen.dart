import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safety_inspection_app/constants/strings_ko.dart';
import 'package:safety_inspection_app/models/defect.dart';
import 'package:safety_inspection_app/models/defect_details.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/equipment_marker.dart';
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
import 'package:safety_inspection_app/screens/drawing/flows/marker_presenters.dart';
import 'package:safety_inspection_app/screens/drawing/flows/marker_tap_flow.dart';
import 'package:safety_inspection_app/screens/drawing/flows/pdf_controller_flow.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/canvas_marker_layer.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/drawing_local_parts.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/drawing_top_bar.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/side_panel/marker_side_panel.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/pdf_drawing_view.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/pdf_view_layer.dart';

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
    _loadPdfController();
    _loadScalePreferences();
  }
  @override
  void dispose() {
    _pdfController?.dispose();
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
  List<Widget> _buildMarkersForPage<T>({
    required Iterable<T> items,
    required int pageIndex,
    required Size pageSize,
    required bool Function(T) isSelected,
    required double Function(T) nx,
    required double Function(T) ny,
    required Widget Function(T, bool) buildMarker,
  }) {
    final filteredItems = items
        .where((item) => (item as dynamic).pageIndex == pageIndex)
        .toList();
    return filteredItems
        .map(
          (item) => Positioned(
            left: nx(item) * pageSize.width - 18,
            top: ny(item) * pageSize.height - 18,
            child: buildMarker(item, isSelected(item)),
          ),
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
