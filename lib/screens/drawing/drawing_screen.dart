import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
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
import 'package:safety_inspection_app/screens/drawing/dialogs/defect_category_picker_sheet.dart';
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
  final Set<EquipmentCategory> _visibleEquipmentCategories =
      EquipmentCategory.values.toSet();
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
  bool _isMarkerScaleLocked = false;
  @override
  void initState() {
    super.initState();
    _site = widget.site;
    _sidePanelController = TabController(length: 4, vsync: this);
    _loadPdfController();
  }
  @override
  void dispose() {
    _pdfController?.dispose();
    _transformationController.dispose();
    _sidePanelController.dispose();
    super.dispose();
  }
  Future<void> _loadPdfController() async {
    final path = _site.pdfPath;
    if (path == null || path.isEmpty) {
      return;
    }
    final previousController = _pdfController;
    _pdfController = null;
    final result = await loadPdfControllerForSite(
      site: _site,
      previousController: previousController,
    );
    if (!mounted || result == null) {
      return;
    }
    setState(() {
      _pdfController = result.controller;
      _pdfLoadError = result.error;
      if (result.error == null) {
        _pdfPageSizes
          ..clear()
          ..addAll(result.clearedPageSizes);
        _pageCount = result.pageCount;
        _currentPage = result.currentPage;
      }
    });
  }
  Future<void> _replacePdf() async {
    final result = await replacePdfAndUpdateSite(site: _site);
    if (!mounted || result == null) {
      return;
    }
    if (result.updatedSite == null) {
      setState(() {
        _pdfLoadError = result.error ?? StringsKo.pdfDrawingLoadFailed;
      });
      return;
    }
    await _applyUpdatedSite(
      result.updatedSite!,
      onStateUpdated: () {
        _clearSelectionAndPopup(inSetState: false);
        _pdfPageSizes.clear();
        _currentPage = 1;
        _pageCount = 1;
      },
    );
    if (!mounted) {
      return;
    }
    await _loadPdfController();
  }
  Future<void> _handleCanvasTap(TapUpDetails details) async {
    final scenePoint = _transformationController.toScene(details.localPosition);
    final hitResult = _hitTestMarker(
      point: scenePoint,
      size: DrawingCanvasSize,
      pageIndex: _currentPage,
    );
    final decision = _controller.handleCanvasTapDecision(
      isDetailDialogOpen: _isDetailDialogOpen,
      tapCanceled: _tapCanceled,
      isWithinCanvas: _isTapWithinCanvas(details.globalPosition),
      hasHitResult: hitResult != null,
      mode: _mode,
      hasActiveDefectCategory: _activeCategory != null,
      hasActiveEquipmentCategory: _activeEquipmentCategory != null,
    );
    final normalizedX = (scenePoint.dx / DrawingCanvasSize.width).clamp(
      0.0,
      1.0,
    );
    final normalizedY = (scenePoint.dy / DrawingCanvasSize.height).clamp(
      0.0,
      1.0,
    );
    final updatedSite = await _handleTapFlow(
      hitResult: hitResult,
      decision: decision,
      pageIndex: _currentPage,
      normalizedX: normalizedX,
      normalizedY: normalizedY,
    );
    await _applyUpdatedSiteIfMounted(updatedSite);
  }
  Future<void> _applyUpdatedSiteIfMounted(Site? updatedSite) async {
    if (!mounted || updatedSite == null) {
      return;
    }
    await _applyUpdatedSite(updatedSite);
  }
  Future<void> _applyUpdatedSite(
    Site updatedSite, {
    VoidCallback? onStateUpdated,
  }) async {
    setState(() {
      _site = updatedSite;
      onStateUpdated?.call();
    });
    await widget.onSiteUpdated(_site);
  }
  void _setPdfState(VoidCallback callback) {
    if (!mounted) {
      return;
    }
    setState(callback);
  }
  void _clearSelectionAndPopup({bool inSetState = true}) {
    if (_selectedDefect == null &&
        _selectedEquipment == null &&
        _selectedMarkerScenePosition == null)
      return;
    void clearSelection() {
      _selectedDefect = null;
      _selectedEquipment = null;
      _selectedMarkerScenePosition = null;
    }
    if (inSetState) {
      setState(clearSelection);
    } else {
      clearSelection();
    }
  }
  void _selectMarker(MarkerHitResult result) {
    setState(() {
      _selectedDefect = result.defect;
      _selectedEquipment = result.equipment;
      _selectedMarkerScenePosition = result.position;
    });
    _switchToDetailTab();
  }

  void _selectDefectFromPanel(Defect defect) {
    setState(() {
      _selectedDefect = defect;
      _selectedEquipment = null;
      _selectedMarkerScenePosition = null;
    });
    _switchToDetailTab();
  }

  void _selectEquipmentFromPanel(EquipmentMarker marker) {
    setState(() {
      _selectedDefect = null;
      _selectedEquipment = marker;
      _selectedMarkerScenePosition = null;
    });
    _switchToDetailTab();
  }

  void _switchToDetailTab() {
    if (_sidePanelController.index != 2) {
      _sidePanelController.animateTo(2);
    }
  }
  MarkerHitResult? _hitTestMarker({
    required Offset point,
    required Size size,
    required int pageIndex,
  }) {
    const hitRadius = 24.0;
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
  bool _isTapWithinCanvas(Offset globalPosition) {
    final context = _canvasKey.currentContext;
    final renderObject = context?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return false;
    }
    final localPosition = renderObject.globalToLocal(globalPosition);
    return localPosition.dx >= 0 &&
        localPosition.dy >= 0 &&
        localPosition.dx <= renderObject.size.width &&
        localPosition.dy <= renderObject.size.height;
  }
  Future<DefectDetails?> _showDefectDetailsDialog() async {
    final defectCategory = _activeCategory ?? DefectCategory.generalCrack;
    final defectConfig = defectCategoryConfig(defectCategory);
    return _showDetailDialog(
      () => showDefectDetailsDialog(
        context: context,
        title: defectConfig.dialogTitle,
        typeOptions: defectConfig.typeOptions,
        causeOptions: defectConfig.causeOptions,
      ),
    );
  }
  Future<EquipmentDetails?> _showEquipmentDetailsDialog({
    required String title,
    String? initialMemberType,
    List<String>? initialSizeValues,
  }) async {
    return _showDetailDialog(
      () => showEquipmentDetailsDialog(
        context: context,
        title: title,
        memberOptions: DrawingEquipmentMemberOptions,
        sizeLabelsByMember: DrawingEquipmentMemberSizeLabels,
        initialMemberType: initialMemberType,
        initialSizeValues: initialSizeValues,
      ),
    );
  }
  Future<RebarSpacingDetails?> _showRebarSpacingDialog({
    required String title,
    String? initialMemberType,
    String? initialNumberText,
  }) async {
    return _showDetailDialog(
      () => showRebarSpacingDialog(
        context: context,
        title: title,
        memberOptions: DrawingRebarSpacingMemberOptions,
        initialMemberType: initialMemberType,
        initialNumberText: initialNumberText,
      ),
    );
  }
  Future<SchmidtHammerDetails?> _showSchmidtHammerDialog({
    required String title,
    String? initialMemberType,
    String? initialMaxValueText,
    String? initialMinValueText,
  }) async {
    return _showDetailDialog(
      () => showSchmidtHammerDialog(
        context: context,
        title: title,
        memberOptions: DrawingSchmidtHammerMemberOptions,
        initialMemberType: initialMemberType,
        initialMaxValueText: initialMaxValueText,
        initialMinValueText: initialMinValueText,
      ),
    );
  }
  Future<CoreSamplingDetails?> _showCoreSamplingDialog({
    required String title,
    String? initialMemberType,
    String? initialAvgValueText,
  }) async {
    return _showDetailDialog(
      () => showCoreSamplingDialog(
        context: context,
        title: title,
        memberOptions: DrawingCoreSamplingMemberOptions,
        initialMemberType: initialMemberType,
        initialAvgValueText: initialAvgValueText,
      ),
    );
  }
  Future<CarbonationDetails?> _showCarbonationDialog({
    required String title,
    String? initialMemberType,
    String? initialCoverThicknessText,
    String? initialDepthText,
  }) async {
    return _showDetailDialog(
      () => showCarbonationDialog(
        context: context,
        title: title,
        memberOptions: DrawingCarbonationMemberOptions,
        initialMemberType: initialMemberType,
        initialCoverThicknessText: initialCoverThicknessText,
        initialDepthText: initialDepthText,
      ),
    );
  }
  Future<StructuralTiltDetails?> _showStructuralTiltDialog({
    required String title,
    String? initialDirection,
    String? initialDisplacementText,
  }) async {
    return _showDetailDialog(
      () => showStructuralTiltDialog(
        context: context,
        title: title,
        initialDirection: initialDirection,
        initialDisplacementText: initialDisplacementText,
      ),
    );
  }
  Future<SettlementDetails?> _showSettlementDialog({
    required String baseTitle,
    required Map<String, int> nextIndexByDirection,
    String? initialDirection,
    String? initialDisplacementText,
  }) async {
    return _showDetailDialog(
      () => showSettlementDialog(
        context: context,
        baseTitle: baseTitle,
        nextIndexByDirection: nextIndexByDirection,
        initialDirection: initialDirection,
        initialDisplacementText: initialDisplacementText,
      ),
    );
  }
  Future<DeflectionDetails?> _showDeflectionDialog({
    required String title,
    String? initialMemberType,
    String? initialEndAText,
    String? initialMidBText,
    String? initialEndCText,
  }) async {
    return _showDetailDialog(
      () => showDeflectionDialog(
        context: context,
        title: title,
        memberOptions: DrawingDeflectionMemberOptions,
        initialMemberType: initialMemberType,
        initialEndAText: initialEndAText,
        initialMidBText: initialMidBText,
        initialEndCText: initialEndCText,
      ),
    );
  }
  Future<void> _handlePdfTap(
    TapUpDetails details,
    Size pageSize,
    int pageIndex,
  ) async {
    final localPosition = details.localPosition;
    final hitResult = _hitTestMarker(
      point: localPosition,
      size: pageSize,
      pageIndex: pageIndex,
    );
    final decision = _controller.handlePdfTapDecision(
      isDetailDialogOpen: _isDetailDialogOpen,
      tapCanceled: _tapCanceled,
      hasHitResult: hitResult != null,
      mode: _mode,
      hasActiveDefectCategory: _activeCategory != null,
      hasActiveEquipmentCategory: _activeEquipmentCategory != null,
    );
    final normalizedX = (localPosition.dx / pageSize.width).clamp(0.0, 1.0);
    final normalizedY = (localPosition.dy / pageSize.height).clamp(0.0, 1.0);
    final updatedSite = await _handleTapFlow(
      hitResult: hitResult,
      decision: decision,
      pageIndex: pageIndex,
      normalizedX: normalizedX,
      normalizedY: normalizedY,
    );
    await _applyUpdatedSiteIfMounted(updatedSite);
  }
  Future<Site?> _handleTapFlow({
    required MarkerHitResult? hitResult,
    required TapDecision decision,
    required int pageIndex,
    required double normalizedX,
    required double normalizedY,
  }) {
    return handleTapCore(
      context: context,
      hitResult: hitResult,
      decision: decision,
      pageIndex: pageIndex,
      normalizedX: normalizedX,
      normalizedY: normalizedY,
      site: _site,
      mode: _mode,
      activeCategory: _activeCategory,
      activeEquipmentCategory: _activeEquipmentCategory,
      onResetTapCanceled: () {
        _tapCanceled = false;
      },
      onSelectHit: _selectMarker,
      onClearSelection: _clearSelectionAndPopup,
      onShowDefectCategoryHint: _showSelectDefectCategoryHint,
      showDefectDetailsDialog: (_) => _showDefectDetailsDialog(),
      showEquipmentDetailsDialog: _showEquipmentDetailsDialog,
      showRebarSpacingDialog:
          (context, {required title, initialMemberType, initialNumberText}) =>
              _showRebarSpacingDialog(
                title: title,
                initialMemberType: initialMemberType,
                initialNumberText: initialNumberText,
              ),
      showSchmidtHammerDialog:
          (
            context, {
            required title,
            initialMemberType,
            initialMaxValueText,
            initialMinValueText,
          }) => _showSchmidtHammerDialog(
            title: title,
            initialMemberType: initialMemberType,
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
      showSettlementDialog:
          ({required baseTitle, required nextIndexByDirection}) =>
              _showSettlementDialog(
                baseTitle: baseTitle,
                nextIndexByDirection: nextIndexByDirection,
              ),
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
      deflectionMemberOptions: DrawingDeflectionMemberOptions,
      nextSettlementIndex: nextSettlementIndex,
    );
  }
  void _handlePointerDown(Offset position) {
    _pointerDownPosition = position;
    _tapCanceled = false;
  }
  void _handlePointerMove(Offset position) {
    if (_pointerDownPosition == null) {
      return;
    }
    final distance = (position - _pointerDownPosition!).distance;
    if (distance > DrawingTapSlop) {
      _tapCanceled = true;
    }
  }
  void _handlePointerUp() => _pointerDownPosition = null;
  void _handlePointerCancel() {
    _pointerDownPosition = null;
    _tapCanceled = false;
  }
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
      isSelected:
          (defect) =>
              _selectedDefect != null &&
              _isSameDefect(defect, _selectedDefect!),
      nx: (defect) => defect.normalizedX,
      ny: (defect) => defect.normalizedY,
      buildMarker:
          (defect, selected) => DefectMarkerWidget(
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
      isSelected:
          (marker) =>
              _selectedEquipment != null &&
              _isSameEquipment(marker, _selectedEquipment!),
      nx: (marker) => marker.normalizedX,
      ny: (marker) => marker.normalizedY,
      buildMarker:
          (marker, selected) => EquipmentMarkerWidget(
        label: equipmentDisplayLabel(marker, _site.equipmentMarkers),
        category: marker.category,
        color: equipmentColor(marker.category),
        isSelected: selected,
        scale: _markerScale,
        labelScale: _labelScale,
      ),
    ),
  ];
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
  bool _isSameDefect(Defect first, Defect second) {
    if (first.id.isNotEmpty && second.id.isNotEmpty) {
      return first.id == second.id;
    }
    return identical(first, second);
  }
  bool _isSameEquipment(EquipmentMarker first, EquipmentMarker second) {
    if (first.id.isNotEmpty && second.id.isNotEmpty) {
      return first.id == second.id;
    }
    return identical(first, second);
  }
  void _toggleMode(DrawMode nextMode) {
    setState(() {
      _mode = _controller.toggleMode(_mode, nextMode);
    });
  }
  void _returnToToolSelection() {
    setState(() {
      _mode = _controller.returnToToolSelection();
    });
  }
  void _handleAddToolAction() {
    if (_controller.shouldShowDefectCategoryPicker(_mode)) {
      _showDefectCategoryPicker();
    }
  }
  Future<void> _showDeleteDefectTabDialog(DefectCategory category) async {
    final shouldDelete = await showDeleteDefectTabDialog(
      context: context,
      category: category,
    );
    if (shouldDelete != true || !mounted) {
      return;
    }
    setState(() {
      final updated = _controller.removeDefectCategory(
        tabs: _defectTabs,
        category: category,
        activeCategory: _activeCategory,
      );
      _defectTabs
        ..clear()
        ..addAll(updated.tabs);
      _activeCategory = updated.activeCategory;
    });
  }
  void _showSelectDefectCategoryHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(StringsKo.selectDefectCategoryHint),
        duration: Duration(seconds: 2),
      ),
    );
  }
  Future<void> _showDefectCategoryPicker() async {
    final selectedCategory = await showDefectCategoryPickerSheet(
      context: context,
      selectedCategories: _defectTabs,
    );
    if (selectedCategory == null || !mounted) {
      return;
    }
    setState(() {
      final updated = _controller.addDefectCategory(
        tabs: _defectTabs,
        selectedCategory: selectedCategory,
      );
      _defectTabs
        ..clear()
        ..addAll(updated.tabs);
      _activeCategory = updated.activeCategory;
    });
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
  PreferredSizeWidget _buildAppBar() {
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
      bottom: _buildDrawingTopBar(),
    );
  }
  DrawingTopBar _buildDrawingTopBar() => DrawingTopBar(
    mode: _mode,
    isToolSelectionMode: _controller.isToolSelectionMode(_mode),
    defectTabs: _defectTabs,
    activeCategory: _activeCategory,
    activeEquipmentCategory: _activeEquipmentCategory,
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
  );
  List<Widget> _buildDrawingStackChildren() {
    final isPdf = _site.drawingType == DrawingType.pdf;
    return [
      if (isPdf)
        PdfViewLayer(
          pdfViewer: _buildPdfViewer(),
          currentPage: _currentPage,
          pageCount: _pageCount,
          canPrev: _currentPage > 1,
          canNext: _currentPage < _pageCount,
          onPrevPage: _handlePrevPage,
          onNextPage: _handleNextPage,
        )
      else
        _buildCanvasDrawingLayer(),
    ];
  }
  PdfDrawingView _buildPdfViewer() => PdfDrawingView(
    pdfController: _pdfController,
    pdfLoadError: _pdfLoadError,
    sitePdfName: _site.pdfName,
    onPageChanged: _handlePdfPageChanged,
    onDocumentLoaded: _handlePdfDocumentLoaded,
    onDocumentError: _handlePdfDocumentError,
    pageSizes: _pdfPageSizes,
    pdfViewVersion: _pdfViewVersion,
    onUpdatePageSize: _handleUpdatePageSize,
    buildPageOverlay:
        ({required pageSize, required pageNumber, required imageProvider}) =>
            _buildPdfPageOverlay(
              pageSize: pageSize,
              pageNumber: pageNumber,
              imageProvider: imageProvider,
            ),
  );
  Widget _buildPdfPageOverlay({
    required Size pageSize,
    required int pageNumber,
    required ImageProvider imageProvider,
  }) {
    return _wrapWithPointerHandlers(
      behavior: HitTestBehavior.translucent,
      onTapUp: (details) => _handlePdfTap(details, pageSize, pageNumber),
      child: _buildMarkerLayer(
        size: pageSize,
        pageIndex: pageNumber,
        child: Image(
          image: imageProvider,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
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
  Widget _buildCanvasDrawingLayer() {
    final theme = Theme.of(context);
    return _wrapWithPointerHandlers(
      onTapUp: _handleCanvasTap,
      child: _buildCanvasViewer(theme),
    );
  }
  Widget _buildCanvasViewer(ThemeData theme) {
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: DrawingCanvasMinScale,
      maxScale: DrawingCanvasMaxScale,
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
  Widget _wrapWithPointerHandlers({
    required Widget child,
    required GestureTapUpCallback onTapUp,
    HitTestBehavior behavior = HitTestBehavior.deferToChild,
  }) {
    return Listener(
      onPointerDown: (e) => _handlePointerDown(e.localPosition),
      onPointerMove: (e) => _handlePointerMove(e.localPosition),
      onPointerUp: (_) => _handlePointerUp(),
      onPointerCancel: (_) => _handlePointerCancel(),
      child: GestureDetector(
        behavior: behavior,
        onTapUp: onTapUp,
        child: child,
      ),
    );
  }
  void _handlePdfPageChanged(int page) =>
      _setPdfState(() => _currentPage = page);
  void _handlePdfDocumentLoaded(PdfDocument document) async {
    final pageCount = document.pagesCount;
    final sizes = await _prefetchPdfPageSizes(document);
    if (!mounted) {
      return;
    }
    _setPdfState(() {
      _pageCount = pageCount;
      if (_currentPage > _pageCount) {
        _currentPage = 1;
      }
      _pdfLoadError = null;
      if (sizes.isNotEmpty) {
        _pdfPageSizes
          ..clear()
          ..addAll(sizes);
        _pdfViewVersion += 1;
      }
    });
    debugPrint('PDF loaded with ${document.pagesCount} pages.');
  }
  void _handlePdfDocumentError(Object error) {
    debugPrint('Failed to load PDF: $error');
    _setPdfState(() {
      _pdfLoadError = StringsKo.pdfDrawingLoadFailed;
    });
  }
  void _handleUpdatePageSize(int pageNumber, Size pageSize) =>
      _setPdfState(() => _pdfPageSizes[pageNumber] = pageSize);
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
  void _handlePrevPage() {
    final nextPage = _currentPage - 1;
    setState(() => _currentPage = nextPage);
    _pdfController?.jumpToPage(nextPage);
  }
  void _handleNextPage() {
    final nextPage = _currentPage + 1;
    setState(() => _currentPage = nextPage);
    _pdfController?.jumpToPage(nextPage);
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
              EquipmentCategory.values.first;
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
                  onEquipmentVisibilityChanged: (category, visible) => setState(
                    () {
                      if (visible) {
                        _visibleEquipmentCategories.add(category);
                      } else {
                        _visibleEquipmentCategories.remove(category);
                      }
                    },
                  ),
                  markerScale: _markerScale,
                  labelScale: _labelScale,
                  onMarkerScaleChanged: (value) {
                    if (_isMarkerScaleLocked) {
                      return;
                    }
                    setState(() => _markerScale = value.clamp(0.2, 2.0));
                  },
                  onLabelScaleChanged: (value) {
                    if (_isMarkerScaleLocked) {
                      return;
                    }
                    setState(() => _labelScale = value.clamp(0.2, 2.0));
                  },
                  isMarkerScaleLocked: _isMarkerScaleLocked,
                  onToggleMarkerScaleLock: () => setState(
                    () => _isMarkerScaleLocked = !_isMarkerScaleLocked,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
