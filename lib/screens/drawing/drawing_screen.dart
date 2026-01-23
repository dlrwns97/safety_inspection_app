import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
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
import 'package:safety_inspection_app/screens/drawing/flows/drawing_dialogs_adapter.dart';
import 'package:safety_inspection_app/screens/drawing/flows/defect_marker_flow.dart';
import 'package:safety_inspection_app/screens/drawing/flows/equipment_pack_d_flow.dart';
import 'package:safety_inspection_app/screens/drawing/flows/equipment_updated_site_flow.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/canvas_marker_layer.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/drawing_local_parts.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/drawing_scaffold_body.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/drawing_top_bar.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/mini_marker_popup.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/pdf_drawing_view.dart';

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

class _DrawingScreenState extends State<DrawingScreen> {
  final DrawingController _controller = DrawingController();
  final TransformationController _transformationController =
      TransformationController();
  final GlobalKey _canvasKey = GlobalKey();
  final Map<int, Size> _pdfPageSizes = {};
  late final DrawingDialogsAdapter _dialogs = DrawingDialogsAdapter(
    equipmentDetails: ({
      required title,
      initialMemberType,
      initialSizeValues,
    }) =>
        _showEquipmentDetailsDialog(
      title: title,
      initialMemberType: initialMemberType,
      initialSizeValues: initialSizeValues,
    ),
    rebarSpacing: ({
      required title,
      initialMemberType,
      initialNumberText,
    }) =>
        _showRebarSpacingDialog(
      title: title,
      initialMemberType: initialMemberType,
      initialNumberText: initialNumberText,
    ),
    schmidtHammer: ({
      required title,
      initialMemberType,
      initialMaxValueText,
      initialMinValueText,
    }) =>
        _showSchmidtHammerDialog(
      title: title,
      initialMemberType: initialMemberType,
      initialMaxValueText: initialMaxValueText,
      initialMinValueText: initialMinValueText,
    ),
    coreSampling: ({
      required title,
      initialMemberType,
      initialAvgValueText,
    }) =>
        _showCoreSamplingDialog(
      title: title,
      initialMemberType: initialMemberType,
      initialAvgValueText: initialAvgValueText,
    ),
    carbonation: ({
      required title,
      initialMemberType,
      initialCoverThicknessText,
      initialDepthText,
    }) =>
        _showCarbonationDialog(
      title: title,
      initialMemberType: initialMemberType,
      initialCoverThicknessText: initialCoverThicknessText,
      initialDepthText: initialDepthText,
    ),
    structuralTilt: ({
      required title,
      initialDirection,
      initialDisplacementText,
    }) =>
        _showStructuralTiltDialog(
      title: title,
      initialDirection: initialDirection,
      initialDisplacementText: initialDisplacementText,
    ),
    settlement: ({
      required baseTitle,
      required nextIndexByDirection,
      initialDirection,
      initialDisplacementText,
    }) =>
        _showSettlementDialog(
      baseTitle: baseTitle,
      nextIndexByDirection: nextIndexByDirection,
      initialDirection: initialDirection,
      initialDisplacementText: initialDisplacementText,
    ),
    deflection: ({
      required title,
      initialMemberType,
      initialEndAText,
      initialMidBText,
      initialEndCText,
    }) =>
        _showDeflectionDialog(
      title: title,
      initialMemberType: initialMemberType,
      initialEndAText: initialEndAText,
      initialMidBText: initialMidBText,
      initialEndCText: initialEndCText,
    ),
  );

  late Site _site;
  PdfController? _pdfController;
  String? _pdfLoadError;
  DrawMode _mode = DrawMode.hand;
  DefectCategory? _activeCategory;
  EquipmentCategory? _activeEquipmentCategory;
  final List<DefectCategory> _defectTabs = [];
  int _currentPage = 1;
  int _pageCount = 1;
  Defect? _selectedDefect;
  EquipmentMarker? _selectedEquipment;
  Offset? _selectedMarkerScenePosition;
  Offset? _pointerDownPosition;
  bool _tapCanceled = false;
  bool _isDetailDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _site = widget.site;
    _loadPdfController();
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _loadPdfController() async {
    final path = _site.pdfPath;
    if (path == null || path.isEmpty) {
      return;
    }
    final previousController = _pdfController;
    _pdfController = null;
    previousController?.dispose();
    final file = File(path);
    final exists = await file.exists();
    if (!mounted) {
      return;
    }
    if (!exists) {
      setState(() {
        _pdfLoadError = StringsKo.pdfDrawingLoadFailed;
      });
      debugPrint('PDF file not found at $path');
      return;
    }
    final fileSize = await file.length();
    debugPrint(
      'Loading PDF: name=${_site.pdfName ?? file.uri.pathSegments.last}, '
      'path=$path, bytes=$fileSize',
    );
    setState(() {
      _pdfController = PdfController(
        document: PdfDocument.openFile(path),
      );
      _pdfLoadError = null;
      _pdfPageSizes.clear();
      _pageCount = 1;
      _currentPage = 1;
    });
  }

  Future<void> _replacePdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    final file = result.files.first;
    String? pdfPath = file.path;
    if (pdfPath == null && file.bytes != null) {
      pdfPath = await _persistPickedPdf(file);
    }
    if (!mounted) {
      return;
    }
    if (pdfPath == null || pdfPath.isEmpty) {
      setState(() {
        _pdfLoadError = StringsKo.pdfDrawingLoadFailed;
      });
      return;
    }
    setState(() {
      _site = _site.copyWith(pdfPath: pdfPath, pdfName: file.name);
      _selectedDefect = null;
      _selectedEquipment = null;
      _selectedMarkerScenePosition = null;
      _pdfPageSizes.clear();
      _currentPage = 1;
      _pageCount = 1;
    });
    await widget.onSiteUpdated(_site);
    if (!mounted) {
      return;
    }
    await _loadPdfController();
  }

  Future<String?> _persistPickedPdf(PlatformFile file) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final blueprintDirectory = Directory(
        '${directory.path}${Platform.pathSeparator}blueprints',
      );
      if (!await blueprintDirectory.exists()) {
        await blueprintDirectory.create(recursive: true);
      }
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'drawing_${timestamp}_${file.name}';
      final savedFile = File(
        '${blueprintDirectory.path}${Platform.pathSeparator}$filename',
      );
      await savedFile.writeAsBytes(file.bytes!, flush: true);
      return savedFile.path;
    } catch (error) {
      debugPrint('Failed to persist picked PDF: $error');
      return null;
    }
  }

  Future<void> _handleTapCore({
    required MarkerHitResult? hitResult,
    required TapDecision decision,
    required int pageIndex,
    required double normalizedX,
    required double normalizedY,
  }) async {
    final shouldCreate = _applyTapDecision(
      decision: decision,
      hitResult: hitResult,
    );
    if (!shouldCreate) {
      return;
    }
    await _createMarkerFromTap(
      pageIndex: pageIndex,
      normalizedX: normalizedX,
      normalizedY: normalizedY,
    );
  }

  Future<void> _handleCanvasTap(TapUpDetails details) async {
    final scenePoint = _transformationController.toScene(details.localPosition);
    final hitResult = _hitTestMarkerOnCanvas(scenePoint);
    final decision = _controller.handleCanvasTapDecision(
      isDetailDialogOpen: _isDetailDialogOpen,
      tapCanceled: _tapCanceled,
      isWithinCanvas: _isTapWithinCanvas(details.globalPosition),
      hasHitResult: hitResult != null,
      mode: _mode,
      hasActiveDefectCategory: _activeCategory != null,
      hasActiveEquipmentCategory: _activeEquipmentCategory != null,
    );
    final normalizedX = (scenePoint.dx / DrawingCanvasSize.width).clamp(0.0, 1.0);
    final normalizedY = (scenePoint.dy / DrawingCanvasSize.height).clamp(0.0, 1.0);

    await _handleTapCore(
      hitResult: hitResult,
      decision: decision,
      pageIndex: _currentPage,
      normalizedX: normalizedX,
      normalizedY: normalizedY,
    );
  }

  bool _applyTapDecision({
    required TapDecision decision,
    required MarkerHitResult? hitResult,
  }) {
    if (decision.resetTapCanceled) {
      _tapCanceled = false;
      return false;
    }
    if (decision.shouldSelectHit) {
      _selectMarker(hitResult!);
      return false;
    }
    if (decision.shouldClearSelection) {
      _clearSelectedMarker();
    }
    if (decision.shouldShowDefectCategoryHint) {
      _showSelectDefectCategoryHint();
      return false;
    }
    if (!decision.shouldCreateMarker) {
      return false;
    }
    return true;
  }

  Future<void> _createMarkerFromTap({
    required int pageIndex,
    required double normalizedX,
    required double normalizedY,
  }) async {
    if (_mode == DrawMode.defect) {
      await _addDefectMarker(
        pageIndex: pageIndex,
        normalizedX: normalizedX,
        normalizedY: normalizedY,
      );
      return;
    }
    await _addEquipmentMarker(
      pageIndex: pageIndex,
      normalizedX: normalizedX,
      normalizedY: normalizedY,
    );
  }

  Future<void> _applyUpdatedSiteIfMounted(Site? updatedSite) async {
    if (!mounted || updatedSite == null) {
      return;
    }

    setState(() {
      _site = updatedSite;
    });
    await widget.onSiteUpdated(_site);
  }

  Future<void> _addDefectMarker({
    required int pageIndex,
    required double normalizedX,
    required double normalizedY,
  }) async {
    final updatedSite = await createDefectIfConfirmed(
      context: context,
      site: _site,
      pageIndex: pageIndex,
      normalizedX: normalizedX,
      normalizedY: normalizedY,
      activeCategory: _activeCategory!,
      showDefectDetailsDialog: (_) => _showDefectDetailsDialog(),
    );
    await _applyUpdatedSiteIfMounted(updatedSite);
  }

  Future<void> _addEquipmentMarker({
    required int pageIndex,
    required double normalizedX,
    required double normalizedY,
  }) async {
    if (_activeEquipmentCategory == EquipmentCategory.equipment8) {
      await _addEquipment8Marker(
        pageIndex: pageIndex,
        normalizedX: normalizedX,
        normalizedY: normalizedY,
      );
      return;
    }
    final equipmentCount = _site.equipmentMarkers
        .where((marker) => marker.category == _activeEquipmentCategory)
        .length;
    final prefix = _equipmentLabelPrefix(_activeEquipmentCategory!);
    final label = '$prefix${equipmentCount + 1}';
    final pendingMarker = EquipmentMarker(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      label: label,
      pageIndex: pageIndex,
      category: _activeEquipmentCategory!,
      normalizedX: normalizedX,
      normalizedY: normalizedY,
      equipmentTypeId: prefix,
    );

    final updatedSite = await createEquipmentUpdatedSite(
      context: context,
      site: _site,
      activeEquipmentCategory: _activeEquipmentCategory,
      pendingMarker: pendingMarker,
      prefix: prefix,
      equipmentDisplayLabel: _equipmentDisplayLabel,
      deflectionMemberOptions: DrawingDeflectionMemberOptions,
      showEquipmentDetailsDialog: _dialogs.equipmentDetails,
      showRebarSpacingDialog: (
        context, {
        required title,
        initialMemberType,
        initialNumberText,
      }) =>
          _dialogs.rebarSpacing(
        title: title,
        initialMemberType: initialMemberType,
        initialNumberText: initialNumberText,
      ),
      showSchmidtHammerDialog: (
        context, {
        required title,
        initialMemberType,
        initialMaxValueText,
        initialMinValueText,
      }) =>
          _dialogs.schmidtHammer(
        title: title,
        initialMemberType: initialMemberType,
        initialMaxValueText: initialMaxValueText,
        initialMinValueText: initialMinValueText,
      ),
      showCoreSamplingDialog: (
        context, {
        required title,
        initialMemberType,
        initialAvgValueText,
      }) =>
          _dialogs.coreSampling(
        title: title,
        initialMemberType: initialMemberType,
        initialAvgValueText: initialAvgValueText,
      ),
      showCarbonationDialog: ({
        required title,
        initialMemberType,
        initialCoverThicknessText,
        initialDepthText,
      }) =>
          _dialogs.carbonation(
        title: title,
        initialMemberType: initialMemberType,
        initialCoverThicknessText: initialCoverThicknessText,
        initialDepthText: initialDepthText,
      ),
      showStructuralTiltDialog: ({
        required title,
        initialDirection,
        initialDisplacementText,
      }) =>
          _dialogs.structuralTilt(
        title: title,
        initialDirection: initialDirection,
        initialDisplacementText: initialDisplacementText,
      ),
      showDeflectionDialog: ({
        required title,
        required memberOptions,
        initialMemberType,
        initialEndAText,
        initialMidBText,
        initialEndCText,
      }) =>
          _dialogs.deflection(
        title: title,
        initialMemberType: initialMemberType,
        initialEndAText: initialEndAText,
        initialMidBText: initialMidBText,
        initialEndCText: initialEndCText,
      ),
    );
    if (updatedSite == null) {
      return;
    }
    await _applyUpdatedSiteIfMounted(updatedSite);
  }

  Future<void> _addEquipment8Marker({
    required int pageIndex,
    required double normalizedX,
    required double normalizedY,
  }) async {
    final nextIndices = {
      'Lx': _nextSettlementIndex('Lx'),
      'Ly': _nextSettlementIndex('Ly'),
    };
    final updatedSite = await createEquipment8IfConfirmed(
      context: context,
      site: _site,
      pageIndex: pageIndex,
      normalizedX: normalizedX,
      normalizedY: normalizedY,
      nextIndexByDirection: nextIndices,
      nextSettlementIndex: _nextSettlementIndex,
      showSettlementDialog: ({
        required baseTitle,
        required nextIndexByDirection,
        initialDirection,
        initialDisplacementText,
      }) =>
          _dialogs.settlement(
        baseTitle: baseTitle,
        nextIndexByDirection: nextIndexByDirection,
        initialDirection: initialDirection,
        initialDisplacementText: initialDisplacementText,
      ),
    );
    await _applyUpdatedSiteIfMounted(updatedSite);
  }

  void _selectMarker(MarkerHitResult result) {
    setState(() {
      _selectedDefect = result.defect;
      _selectedEquipment = result.equipment;
      _selectedMarkerScenePosition = result.position;
    });
  }

  void _clearSelectedMarker() {
    if (_selectedDefect == null &&
        _selectedEquipment == null &&
        _selectedMarkerScenePosition == null) {
      return;
    }
    setState(() {
      _selectedDefect = null;
      _selectedEquipment = null;
      _selectedMarkerScenePosition = null;
    });
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

  MarkerHitResult? _hitTestMarkerOnCanvas(Offset scenePoint) {
    return _hitTestMarker(
      point: scenePoint,
      size: _canvasSize,
      pageIndex: _currentPage,
    );
  }

  MarkerHitResult? _hitTestMarkerOnPage(
    Offset pagePoint,
    Size pageSize,
    int pageIndex,
  ) {
    return _hitTestMarker(
      point: pagePoint,
      size: pageSize,
      pageIndex: pageIndex,
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
    return _showDetailDialog(
      () => showDefectDetailsDialog(
        context: context,
        title: _defectDialogTitle(defectCategory),
        typeOptions: _defectTypeOptions(defectCategory),
        causeOptions: _defectCauseOptions(defectCategory),
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

  Widget _buildPdfPageOverlay({
    required Size pageSize,
    required int pageNumber,
    required ImageProvider imageProvider,
  }) {
    return CanvasMarkerLayer(
      onPointerDown: (event) => _handlePointerDown(event.localPosition),
      onPointerMove: (event) => _handlePointerMove(event.localPosition),
      onPointerUp: (_) => _handlePointerUp(),
      onPointerCancel: (_) => _handlePointerCancel(),
      onTapUp: (details) => _handlePdfTap(
        details,
        pageSize,
        pageNumber,
      ),
      hitTestBehavior: HitTestBehavior.translucent,
      childPdfOrCanvas: Image(
        image: imageProvider,
        fit: BoxFit.contain,
      ),
      markerWidgets: [
        ..._buildDefectMarkersForPage(
          pageSize,
          pageNumber,
        ),
        ..._buildEquipmentMarkersForPage(
          pageSize,
          pageNumber,
        ),
      ],
      miniPopup: _buildMarkerPopupForPage(
        pageSize,
        pageNumber,
      ),
    );
  }

  Widget _buildDrawingBackground() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: CustomPaint(
        painter: GridPainter(lineColor: theme.colorScheme.outlineVariant),
      ),
    );
  }

  Future<void> _handlePdfTap(
    TapUpDetails details,
    Size pageSize,
    int pageIndex,
  ) async {
    final localPosition = details.localPosition;
    final hitResult = _hitTestMarkerOnPage(
      localPosition,
      pageSize,
      pageIndex,
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

    await _handleTapCore(
      hitResult: hitResult,
      decision: decision,
      pageIndex: pageIndex,
      normalizedX: normalizedX,
      normalizedY: normalizedY,
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

  void _handlePointerUp() {
    _pointerDownPosition = null;
  }

  void _handlePointerCancel() {
    _pointerDownPosition = null;
    _tapCanceled = false;
  }

  Widget _buildMarkerPopup(Size viewportSize) {
    if (_selectedMarkerScenePosition == null ||
        (_selectedDefect == null && _selectedEquipment == null)) {
      return const SizedBox.shrink();
    }

    final lines = _selectedDefect != null
        ? _defectPopupLines(_selectedDefect!)
        : _equipmentPopupLines(_selectedEquipment!);

    final markerViewportPosition = MatrixUtils.transformPoint(
      _transformationController.value,
      _selectedMarkerScenePosition!,
    );
    return _buildMiniPopup(
      markerPosition: markerViewportPosition,
      containerSize: viewportSize,
      lines: lines,
    );
  }

  Widget _buildMarkerPopupForPage(Size pageSize, int pageIndex) {
    final selectedDefect = _selectedDefect;
    final selectedEquipment = _selectedEquipment;
    if (selectedDefect == null && selectedEquipment == null) {
      return const SizedBox.shrink();
    }
    final selectedPage =
        selectedDefect?.pageIndex ?? selectedEquipment?.pageIndex;
    if (selectedPage != pageIndex) {
      return const SizedBox.shrink();
    }

    final lines = selectedDefect != null
        ? _defectPopupLines(selectedDefect)
        : _equipmentPopupLines(selectedEquipment!);

    final normalizedX =
        selectedDefect?.normalizedX ?? selectedEquipment!.normalizedX;
    final normalizedY =
        selectedDefect?.normalizedY ?? selectedEquipment!.normalizedY;
    final markerPosition = Offset(
      normalizedX * pageSize.width,
      normalizedY * pageSize.height,
    );
    return _buildMiniPopup(
      markerPosition: markerPosition,
      containerSize: pageSize,
      lines: lines,
    );
  }

  MiniMarkerPopup _buildMiniPopup({
    required Offset markerPosition,
    required Size containerSize,
    required List<String> lines,
  }) {
    const popupMaxWidth = MiniMarkerPopup.maxWidth;
    const popupMargin = MiniMarkerPopup.margin;
    const lineHeight = MiniMarkerPopup.lineHeight;
    const verticalPadding = MiniMarkerPopup.verticalPadding;
    final estimatedHeight = lines.length * lineHeight + verticalPadding * 2;

    final desiredLeft = markerPosition.dx + 16;
    final desiredTop = markerPosition.dy - estimatedHeight - 12;

    final maxLeft = (containerSize.width - popupMaxWidth - popupMargin).clamp(
      0.0,
      double.infinity,
    );
    final maxTop = (containerSize.height - estimatedHeight - popupMargin).clamp(
      0.0,
      double.infinity,
    );

    final left = desiredLeft.clamp(
      popupMargin,
      maxLeft == 0 ? popupMargin : maxLeft,
    );
    final top = desiredTop.clamp(
      popupMargin,
      maxTop == 0 ? popupMargin : maxTop,
    );

    return MiniMarkerPopup(
      left: left,
      top: top,
      lines: lines,
    );
  }

  List<String> _defectPopupLines(Defect defect) {
    final details = defect.details;
    return [
      defect.label,
      '${defect.category.label} / ${details.crackType}',
      '${_formatNumber(details.widthMm)} / ${_formatNumber(details.lengthMm)}',
      details.cause,
    ];
  }

  List<String> _equipmentPopupLines(EquipmentMarker marker) {
    List<String> baseLines(EquipmentMarker marker) =>
        <String>[_equipmentDisplayLabel(marker)];
    void addMemberTypeIfPresent(EquipmentMarker marker, List<String> lines) {
      if (marker.memberType != null && marker.memberType!.isNotEmpty) {
        lines.add(marker.memberType!);
      }
    }

    final buildersByType = <String, List<String> Function(EquipmentMarker)>{
      'F': (marker) {
        final lines = baseLines(marker);
        addMemberTypeIfPresent(marker, lines);
        if (marker.numberText != null && marker.numberText!.isNotEmpty) {
          lines.add('번호: ${marker.numberText}');
        }
        return lines;
      },
      'SH': (marker) {
        final lines = baseLines(marker);
        addMemberTypeIfPresent(marker, lines);
        if (marker.maxValueText != null && marker.maxValueText!.isNotEmpty) {
          lines.add('최댓값: ${marker.maxValueText}');
        }
        if (marker.minValueText != null && marker.minValueText!.isNotEmpty) {
          lines.add('최솟값: ${marker.minValueText}');
        }
        return lines;
      },
      'Co': (marker) {
        final lines = baseLines(marker);
        addMemberTypeIfPresent(marker, lines);
        if (marker.avgValueText != null && marker.avgValueText!.isNotEmpty) {
          lines.add('평균값: ${marker.avgValueText}');
        }
        return lines;
      },
      'Ch': (marker) {
        final lines = baseLines(marker);
        addMemberTypeIfPresent(marker, lines);
        if (marker.coverThicknessText != null &&
            marker.coverThicknessText!.isNotEmpty) {
          lines.add('피복두께: ${marker.coverThicknessText}');
        }
        if (marker.depthText != null && marker.depthText!.isNotEmpty) {
          lines.add('깊이: ${marker.depthText}');
        }
        return lines;
      },
      'Tr': (marker) {
        final lines = baseLines(marker);
        if (marker.tiltDirection != null && marker.tiltDirection!.isNotEmpty) {
          lines.add('방향: ${marker.tiltDirection}');
        }
        if (marker.displacementText != null &&
            marker.displacementText!.isNotEmpty) {
          lines.add('변위량: ${marker.displacementText}');
        }
        return lines;
      },
      'L': (marker) {
        final lines = baseLines(marker);
        addMemberTypeIfPresent(marker, lines);
        if (marker.deflectionEndAText != null &&
            marker.deflectionEndAText!.isNotEmpty) {
          lines.add('A(단부): ${marker.deflectionEndAText}');
        }
        if (marker.deflectionMidBText != null &&
            marker.deflectionMidBText!.isNotEmpty) {
          lines.add('B(중앙): ${marker.deflectionMidBText}');
        }
        if (marker.deflectionEndCText != null &&
            marker.deflectionEndCText!.isNotEmpty) {
          lines.add('C(단부): ${marker.deflectionEndCText}');
        }
        return lines;
      },
    };
    final builder = buildersByType[marker.equipmentTypeId];
    if (builder != null && marker.equipmentTypeId != 'L') {
      return builder(marker);
    }
    if (marker.category == EquipmentCategory.equipment8) {
      final lines = <String>[_equipmentDisplayLabel(marker)];
      final direction = _settlementDirection(marker);
      if (direction != null && direction.isNotEmpty) {
        lines.add('방향: $direction');
      }
      if (marker.displacementText != null &&
          marker.displacementText!.isNotEmpty) {
        lines.add('변위량: ${marker.displacementText}');
      }
      return lines;
    }
    if (builder != null) {
      return builder(marker);
    }
    return [marker.label, marker.category.label];
  }

  String _formatNumber(double value) {
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  List<Widget> _buildMarkersForPage<T>({
    required Iterable<T> items,
    required int pageIndex,
    required Size pageSize,
    required double Function(T) nx,
    required double Function(T) ny,
    required Widget Function(T) buildMarker,
  }) {
    final filteredItems = items
        .where((item) => (item as dynamic).pageIndex == pageIndex)
        .toList();
    return filteredItems.map((item) {
      final position = Offset(
        nx(item) * pageSize.width,
        ny(item) * pageSize.height,
      );
      return Positioned(
        left: position.dx - 18,
        top: position.dy - 18,
        child: buildMarker(item),
      );
    }).toList();
  }

  Size get _canvasSize => DrawingCanvasSize;

  List<Widget> _buildDefectMarkerWidgets({
    required Size size,
    required int pageIndex,
  }) {
    return _buildMarkersForPage(
      items: _site.defects,
      pageIndex: pageIndex,
      pageSize: size,
      nx: (defect) => defect.normalizedX,
      ny: (defect) => defect.normalizedY,
      buildMarker: (defect) => DefectMarkerWidget(
        label: defect.label,
        category: defect.category,
        color: _defectColor(defect.category),
      ),
    );
  }

  List<Widget> _buildEquipmentMarkerWidgets({
    required Size size,
    required int pageIndex,
  }) {
    return _buildMarkersForPage(
      items: _site.equipmentMarkers,
      pageIndex: pageIndex,
      pageSize: size,
      nx: (marker) => marker.normalizedX,
      ny: (marker) => marker.normalizedY,
      buildMarker: (marker) => EquipmentMarkerWidget(
        label: marker.label,
        category: marker.category,
        color: _equipmentColor(marker.category),
      ),
    );
  }

  List<Widget> _buildDefectMarkers() {
    return _buildDefectMarkerWidgets(
      size: _canvasSize,
      pageIndex: _currentPage,
    );
  }

  List<Widget> _buildDefectMarkersForPage(Size pageSize, int pageIndex) {
    return _buildDefectMarkerWidgets(
      size: pageSize,
      pageIndex: pageIndex,
    );
  }

  List<Widget> _buildEquipmentMarkers() {
    return _buildEquipmentMarkerWidgets(
      size: _canvasSize,
      pageIndex: _currentPage,
    );
  }

  List<Widget> _buildEquipmentMarkersForPage(Size pageSize, int pageIndex) {
    return _buildEquipmentMarkerWidgets(
      size: pageSize,
      pageIndex: pageIndex,
    );
  }

  void _toggleMode(DrawMode nextMode) {
    setState(() {
      _mode = _controller.toggleMode(_mode, nextMode);
    });
  }

  bool _isToolSelectionMode() => _controller.isToolSelectionMode(_mode);

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

  Color _defectColor(DefectCategory category) {
    switch (category) {
      case DefectCategory.generalCrack:
        return Colors.red;
      case DefectCategory.waterLeakage:
        return Colors.blue;
      case DefectCategory.concreteSpalling:
        return Colors.green;
      case DefectCategory.other:
        return Colors.purple;
    }
  }

  String? _settlementDirection(EquipmentMarker marker) {
    final direction = marker.tiltDirection;
    if (direction != null && direction.isNotEmpty) {
      return direction;
    }
    if (marker.equipmentTypeId == 'Lx' || marker.equipmentTypeId == 'Ly') {
      return marker.equipmentTypeId;
    }
    return null;
  }

  int _nextSettlementIndex(String direction) {
    return _site.equipmentMarkers
            .where(
              (marker) =>
                  marker.category == EquipmentCategory.equipment8 &&
                  _settlementDirection(marker) == direction,
            )
            .length +
        1;
  }

  String _equipmentLabelPrefix(EquipmentCategory category) {
    switch (category) {
      case EquipmentCategory.equipment1:
        return 'S';
      case EquipmentCategory.equipment2:
        return 'F';
      case EquipmentCategory.equipment3:
        return 'SH';
      case EquipmentCategory.equipment4:
        return 'Co';
      case EquipmentCategory.equipment5:
        return 'Ch';
      case EquipmentCategory.equipment6:
        return 'Tr';
      case EquipmentCategory.equipment7:
        return 'L';
      case EquipmentCategory.equipment8:
        return 'Lx';
    }
  }

  String _equipmentDisplayLabel(EquipmentMarker marker) {
    if (marker.category == EquipmentCategory.equipment8) {
      return '부동침하 ${marker.label}';
    }
    if (marker.equipmentTypeId == 'F') {
      return '철근배근간격 ${marker.label}';
    }
    if (marker.equipmentTypeId == 'SH') {
      return '슈미트해머 ${marker.label}';
    }
    if (marker.equipmentTypeId == 'Co') {
      return '코어채취 ${marker.label}';
    }
    if (marker.equipmentTypeId == 'Ch') {
      return '콘크리트 탄산화 ${marker.label}';
    }
    if (marker.equipmentTypeId == 'Tr') {
      return '구조물 기울기 ${marker.label}';
    }
    if (marker.equipmentTypeId == 'L') {
      return '부재처짐 ${marker.label}';
    }
    return marker.label;
  }

  Color _equipmentColor(EquipmentCategory category) {
    switch (category) {
      case EquipmentCategory.equipment1:
        return Colors.pinkAccent;
      case EquipmentCategory.equipment2:
        return Colors.lightBlueAccent;
      case EquipmentCategory.equipment3:
      case EquipmentCategory.equipment4:
        return Colors.green;
      case EquipmentCategory.equipment5:
        return Colors.orangeAccent;
      case EquipmentCategory.equipment6:
        return Colors.tealAccent;
      case EquipmentCategory.equipment7:
        return Colors.indigoAccent;
      case EquipmentCategory.equipment8:
        return Colors.deepPurpleAccent;
    }
  }

  List<String> _defectTypeOptions(DefectCategory category) {
    switch (category) {
      case DefectCategory.generalCrack:
        return StringsKo.defectTypesGeneralCrack;
      case DefectCategory.waterLeakage:
        return StringsKo.defectTypesWaterLeakage;
      case DefectCategory.concreteSpalling:
        return StringsKo.defectTypesConcreteSpalling;
      case DefectCategory.other:
        return StringsKo.defectTypesOther;
    }
  }

  List<String> _defectCauseOptions(DefectCategory category) {
    switch (category) {
      case DefectCategory.generalCrack:
        return StringsKo.defectCausesGeneralCrack;
      case DefectCategory.waterLeakage:
        return StringsKo.defectCausesWaterLeakage;
      case DefectCategory.concreteSpalling:
        return StringsKo.defectCausesConcreteSpalling;
      case DefectCategory.other:
        return StringsKo.defectCausesOther;
    }
  }

  String _defectDialogTitle(DefectCategory category) {
    switch (category) {
      case DefectCategory.generalCrack:
        return StringsKo.defectDetailsTitleGeneralCrack;
      case DefectCategory.waterLeakage:
        return StringsKo.defectDetailsTitleWaterLeakage;
      case DefectCategory.concreteSpalling:
        return StringsKo.defectDetailsTitleConcreteSpalling;
      case DefectCategory.other:
        return StringsKo.defectDetailsTitleOther;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_site.name),
        actions: [
          if (_site.drawingType == DrawingType.pdf)
            IconButton(
              tooltip: StringsKo.replacePdfTooltip,
              icon: const Icon(Icons.upload_file_outlined),
              onPressed: _replacePdf,
            ),
        ],
        bottom: DrawingTopBar(
          mode: _mode,
          isToolSelectionMode: _isToolSelectionMode(),
          defectTabs: _defectTabs,
          activeCategory: _activeCategory,
          activeEquipmentCategory: _activeEquipmentCategory,
          onToggleMode: _toggleMode,
          onBack: _returnToToolSelection,
          onAdd: _handleAddToolAction,
          onDefectSelected: (category) {
            setState(() {
              _activeCategory = _controller
                  .selectDefectCategory(
                    tabs: _defectTabs,
                    category: category,
                  )
                  .activeCategory;
            });
          },
          onDefectLongPress: _showDeleteDefectTabDialog,
          onEquipmentSelected: (item) {
            setState(() {
              _activeEquipmentCategory =
                  _controller.selectEquipmentCategory(item).activeCategory;
            });
          },
        ),
      ),
      body: DrawingScaffoldBody(
        drawingType: _site.drawingType,
        pdfViewer: PdfDrawingView(
          pdfController: _pdfController,
          pdfLoadError: _pdfLoadError,
          sitePdfName: _site.pdfName,
          onPageChanged: (page) {
            if (!mounted) {
              return;
            }
            setState(() {
              _currentPage = page;
            });
          },
          onDocumentLoaded: (document) {
            if (!mounted) {
              return;
            }
            setState(() {
              _pageCount = document.pagesCount;
              if (_currentPage > _pageCount) {
                _currentPage = 1;
              }
              _pdfLoadError = null;
            });
            debugPrint('PDF loaded with ${document.pagesCount} pages.');
          },
          onDocumentError: (error) {
            debugPrint('Failed to load PDF: $error');
            if (!mounted) {
              return;
            }
            setState(() {
              _pdfLoadError = StringsKo.pdfDrawingLoadFailed;
            });
          },
          pageSizes: _pdfPageSizes,
          onUpdatePageSize: (pageNumber, pageSize) {
            if (!mounted) {
              return;
            }
            setState(() {
              _pdfPageSizes[pageNumber] = pageSize;
            });
          },
          buildPageOverlay: ({
            required pageSize,
            required pageNumber,
            required imageProvider,
          }) =>
              _buildPdfPageOverlay(
            pageSize: pageSize,
            pageNumber: pageNumber,
            imageProvider: imageProvider,
          ),
        ),
        currentPage: _currentPage,
        pageCount: _pageCount,
        canPrevPage: _currentPage > 1,
        canNextPage: _currentPage < _pageCount,
        onPrevPage: () {
          final nextPage = _currentPage - 1;
          setState(() {
            _currentPage = nextPage;
          });
          _pdfController?.jumpToPage(nextPage);
        },
        onNextPage: () {
          final nextPage = _currentPage + 1;
          setState(() {
            _currentPage = nextPage;
          });
          _pdfController?.jumpToPage(nextPage);
        },
        onCanvasPointerDown: (event) =>
            _handlePointerDown(event.localPosition),
        onCanvasPointerMove: (event) =>
            _handlePointerMove(event.localPosition),
        onCanvasPointerUp: (_) => _handlePointerUp(),
        onCanvasPointerCancel: (_) => _handlePointerCancel(),
        onCanvasTapUp: _handleCanvasTap,
        transformationController: _transformationController,
        canvasKey: _canvasKey,
        canvasSize: DrawingCanvasSize,
        drawingBackground: _buildDrawingBackground(),
        markerWidgets: [
          ..._buildDefectMarkers(),
          ..._buildEquipmentMarkers(),
        ],
        markerPopup: _buildMarkerPopup(MediaQuery.of(context).size),
      ),
    );
  }
}
