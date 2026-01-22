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
import 'package:safety_inspection_app/screens/drawing/dialogs/carbonation_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/core_sampling_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/defect_category_picker_sheet.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/defect_details_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/deflection_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/delete_defect_tab_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/equipment_details_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/rebar_spacing_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/schmidt_hammer_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/settlement_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/structural_tilt_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/utils/drawing_helpers.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/canvas_marker_layer.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/drawing_background.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/drawing_tool_bar.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/marker_icon.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/marker_popup.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/pdf_view_layer.dart';

part 'drawing_screen_actions.dart';

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
  static const Size _canvasSize = Size(1200, 1700);
  static const double _tapSlop = 8.0;
  static const List<String> _equipmentMemberOptions = [
    '기둥',
    '보',
    '철골 각형강관',
    '원형기둥',
    '벽체',
    '슬래브',
    '브레이싱',
    '철골 L형강',
    '철골 C찬넬',
    '철골 H형강',
  ];
  static const List<String> _rebarSpacingMemberOptions = [
    '기둥',
    '보',
    '벽체',
    '슬래브',
  ];
  static const List<String> _schmidtHammerMemberOptions = [
    '기둥',
    '보',
    '벽체',
    '슬래브',
  ];
  static const List<String> _coreSamplingMemberOptions = [
    '기둥',
    '보',
    '벽체',
    '슬래브',
  ];
  static const List<String> _carbonationMemberOptions = [
    '기둥',
    '보',
    '벽체',
    '슬래브',
  ];
  static const List<String> _deflectionMemberOptions = [
    '보',
    '슬래브',
  ];
  static const Map<String, List<String>> _equipmentMemberSizeLabels = {
    '기둥': ['W', 'H'],
    '보': ['W', 'H'],
    '철골 각형강관': ['W', 'H'],
    '원형기둥': ['D'],
    '벽체': ['D'],
    '슬래브': ['D'],
    '브레이싱': ['D'],
    '철골 L형강': ['A', 'B', 't'],
    '철골 C찬넬': ['A', 'B', 't'],
    '철골 H형강': ['H', 'B', 'tw', 'tf'],
  };
  final TransformationController _transformationController =
      TransformationController();
  final GlobalKey _canvasKey = GlobalKey();
  final Map<int, Size> _pdfPageSizes = {};

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

  @override
  Widget build(BuildContext context) {
    const toolBarHeight = 56.0;

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
        bottom: DrawingToolBar(
          height: toolBarHeight,
          isToolSelectionMode: _isToolSelectionMode(),
          mode: _mode,
          defectTabs: _defectTabs,
          activeCategory: _activeCategory,
          activeEquipmentCategory: _activeEquipmentCategory,
          onBack: _returnToToolSelection,
          onAdd: _handleAddToolAction,
          onToggleMode: _toggleMode,
          onDefectSelected: (category) {
            setState(() {
              _activeCategory = category;
            });
          },
          onDefectLongPress: _showDeleteDefectTabDialog,
          onEquipmentSelected: (item) {
            setState(() {
              _activeEquipmentCategory = item;
            });
          },
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, _) {
                return Stack(
                  children: [
                    if (_site.drawingType == DrawingType.pdf)
                      PdfViewLayer(
                        pdfLoadError: _pdfLoadError,
                        pdfController: _pdfController,
                        pdfName: _site.pdfName,
                        canvasSize: _canvasSize,
                        pdfPageSizes: _pdfPageSizes,
                        currentPage: _currentPage,
                        pageCount: _pageCount,
                        onPageChanged: _handlePdfPageChanged,
                        onDocumentLoaded: _handlePdfDocumentLoaded,
                        onDocumentError: _handlePdfDocumentError,
                        onPageSizeResolved: _handlePdfPageSizeResolved,
                        onPdfTap: _handlePdfTap,
                        onPointerDown: _handlePointerDown,
                        onPointerMove: _handlePointerMove,
                        onPointerUp: _handlePointerUp,
                        onPointerCancel: _handlePointerCancel,
                        buildDefectMarkersForPage: _buildDefectMarkersForPage,
                        buildEquipmentMarkersForPage:
                            _buildEquipmentMarkersForPage,
                        buildMarkerPopupForPage: _buildMarkerPopupForPage,
                        onPreviousPage: _currentPage > 1
                            ? () => _jumpToPdfPage(_currentPage - 1)
                            : null,
                        onNextPage: _currentPage < _pageCount
                            ? () => _jumpToPdfPage(_currentPage + 1)
                            : null,
                      )
                    else
                      CanvasMarkerLayer(
                        canvasSize: _canvasSize,
                        canvasKey: _canvasKey,
                        transformationController: _transformationController,
                        onPointerDown: _handlePointerDown,
                        onPointerMove: _handlePointerMove,
                        onPointerUp: _handlePointerUp,
                        onPointerCancel: _handlePointerCancel,
                        onTapUp: _handleCanvasTap,
                        background: const DrawingBackground(),
                        defectMarkers: _buildDefectMarkers(),
                        equipmentMarkers: _buildEquipmentMarkers(),
                        markerPopup:
                            _buildMarkerPopup(MediaQuery.of(context).size),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkerHitResult {
  const _MarkerHitResult({
    required this.defect,
    required this.equipment,
    required this.position,
  });

  final Defect? defect;
  final EquipmentMarker? equipment;
  final Offset position;
}
