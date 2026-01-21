import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../constants/strings_ko.dart';
import '../models/defect.dart';
import '../models/defect_details.dart';
import '../models/drawing_enums.dart';
import '../models/equipment_marker.dart';
import '../models/site.dart';

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

  Future<void> _handleCanvasTap(TapUpDetails details) async {
    if (_tapCanceled) {
      _tapCanceled = false;
      return;
    }
    final scenePoint = _transformationController.toScene(details.localPosition);
    if (!_isTapWithinCanvas(details.globalPosition)) {
      _clearSelectedMarker();
      return;
    }

    final hitResult = _hitTestMarkerOnCanvas(scenePoint);
    if (hitResult != null) {
      _selectMarker(hitResult);
      return;
    }

    _clearSelectedMarker();
    if (_mode == DrawMode.defect && _activeCategory == null) {
      _showSelectDefectCategoryHint();
      return;
    }
    if (_mode == DrawMode.equipment && _activeEquipmentCategory == null) {
      return;
    }
    if (_mode != DrawMode.defect && _mode != DrawMode.equipment) {
      return;
    }
    final normalizedX = (scenePoint.dx / _canvasSize.width).clamp(0.0, 1.0);
    final normalizedY = (scenePoint.dy / _canvasSize.height).clamp(0.0, 1.0);

    if (_mode == DrawMode.defect) {
      final detailsResult = await _showDefectDetailsDialog();
      if (!mounted || detailsResult == null) {
        return;
      }

      final countOnPage = _site.defects
          .where(
            (defect) =>
                defect.pageIndex == _currentPage &&
                defect.category == _activeCategory,
          )
          .length;
      final label = _activeCategory == DefectCategory.generalCrack
          ? 'C${countOnPage + 1}'
          : '${countOnPage + 1}';

      final defect = Defect(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        label: label,
        pageIndex: _currentPage,
        category: _activeCategory!,
        normalizedX: normalizedX,
        normalizedY: normalizedY,
        details: detailsResult,
      );

      setState(() {
        _site = _site.copyWith(defects: [..._site.defects, defect]);
      });
      await widget.onSiteUpdated(_site);
    } else {
      final equipmentCount = _site.equipmentMarkers
          .where((marker) => marker.category == _activeEquipmentCategory)
          .length;
      final prefix = _equipmentLabelPrefix(_activeEquipmentCategory!);
      final label = '$prefix${equipmentCount + 1}';
      final marker = EquipmentMarker(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        label: label,
        pageIndex: _currentPage,
        category: _activeEquipmentCategory!,
        normalizedX: normalizedX,
        normalizedY: normalizedY,
      );

      setState(() {
        _site = _site.copyWith(
          equipmentMarkers: [..._site.equipmentMarkers, marker],
        );
      });
      await widget.onSiteUpdated(_site);
    }
  }

  void _selectMarker(_MarkerHitResult result) {
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

  _MarkerHitResult? _hitTestMarkerOnCanvas(Offset scenePoint) {
    const hitRadius = 24.0;
    final hitRadiusSquared = hitRadius * hitRadius;
    double closestDistance = hitRadiusSquared;
    Defect? defectHit;
    EquipmentMarker? equipmentHit;
    Offset? positionHit;

    for (final defect in _site.defects.where(
      (defect) => defect.pageIndex == _currentPage,
    )) {
      final position = Offset(
        defect.normalizedX * _canvasSize.width,
        defect.normalizedY * _canvasSize.height,
      );
      final distance = (scenePoint - position).distanceSquared;
      if (distance <= closestDistance) {
        closestDistance = distance;
        defectHit = defect;
        equipmentHit = null;
        positionHit = position;
      }
    }

    for (final marker in _site.equipmentMarkers.where(
      (marker) => marker.pageIndex == _currentPage,
    )) {
      final position = Offset(
        marker.normalizedX * _canvasSize.width,
        marker.normalizedY * _canvasSize.height,
      );
      final distance = (scenePoint - position).distanceSquared;
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

    return _MarkerHitResult(
      defect: defectHit,
      equipment: equipmentHit,
      position: positionHit,
    );
  }

  _MarkerHitResult? _hitTestMarkerOnPage(
    Offset pagePoint,
    Size pageSize,
    int pageIndex,
  ) {
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
        defect.normalizedX * pageSize.width,
        defect.normalizedY * pageSize.height,
      );
      final distance = (pagePoint - position).distanceSquared;
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
        marker.normalizedX * pageSize.width,
        marker.normalizedY * pageSize.height,
      );
      final distance = (pagePoint - position).distanceSquared;
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

    return _MarkerHitResult(
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
    return showDialog<DefectDetails>(
      context: context,
      builder: (context) {
        final formKey = GlobalKey<FormState>();
        String? structuralMember;
        String? crackType;
        String? cause;
        final widthController = TextEditingController();
        final lengthController = TextEditingController();
        final otherTypeController = TextEditingController();
        final otherCauseController = TextEditingController();

        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: StatefulBuilder(
              builder: (context, setState) {
                final typeOptions = _defectTypeOptions(defectCategory);
                final causeOptions = _defectCauseOptions(defectCategory);
                final isOtherType = crackType == StringsKo.otherOptionLabel;
                final isOtherCause = cause == StringsKo.otherOptionLabel;

                bool isValid() {
                  final width = double.tryParse(widthController.text);
                  final length = double.tryParse(lengthController.text);
                  final hasOtherType =
                      !isOtherType ||
                      otherTypeController.text.trim().isNotEmpty;
                  final hasOtherCause =
                      !isOtherCause ||
                      otherCauseController.text.trim().isNotEmpty;
                  return structuralMember != null &&
                      crackType != null &&
                      cause != null &&
                      width != null &&
                      length != null &&
                      width > 0 &&
                      length > 0 &&
                      hasOtherType &&
                      hasOtherCause;
                }

                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _defectDialogTitle(defectCategory),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: structuralMember,
                            decoration: const InputDecoration(
                              labelText: StringsKo.structuralMemberLabel,
                            ),
                            items: StringsKo.structuralMembers
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item,
                                    child: Text(item),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                structuralMember = value;
                              });
                            },
                            validator: (value) => value == null
                                ? StringsKo.selectMemberError
                                : null,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: crackType,
                            decoration: const InputDecoration(
                              labelText: StringsKo.crackTypeLabel,
                            ),
                            items: typeOptions
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item,
                                    child: Text(item),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                crackType = value;
                                if (value != StringsKo.otherOptionLabel) {
                                  otherTypeController.clear();
                                }
                              });
                            },
                            validator: (value) => value == null
                                ? StringsKo.selectCrackTypeError
                                : null,
                          ),
                          if (isOtherType) ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: otherTypeController,
                              decoration: const InputDecoration(
                                labelText: StringsKo.otherTypeLabel,
                              ),
                              validator: (_) =>
                                  otherTypeController.text.trim().isEmpty
                                  ? StringsKo.enterOtherTypeError
                                  : null,
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: widthController,
                                  decoration: const InputDecoration(
                                    labelText: StringsKo.widthLabel,
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  validator: (value) {
                                    final parsed = double.tryParse(value ?? '');
                                    if (parsed == null || parsed <= 0) {
                                      return StringsKo.enterWidthError;
                                    }
                                    return null;
                                  },
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: lengthController,
                                  decoration: const InputDecoration(
                                    labelText: StringsKo.lengthLabel,
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  validator: (value) {
                                    final parsed = double.tryParse(value ?? '');
                                    if (parsed == null || parsed <= 0) {
                                      return StringsKo.enterLengthError;
                                    }
                                    return null;
                                  },
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: cause,
                            decoration: const InputDecoration(
                              labelText: StringsKo.causeLabel,
                            ),
                            items: causeOptions
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item,
                                    child: Text(item),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                cause = value;
                                if (value != StringsKo.otherOptionLabel) {
                                  otherCauseController.clear();
                                }
                              });
                            },
                            validator: (value) => value == null
                                ? StringsKo.selectCauseError
                                : null,
                          ),
                          if (isOtherCause) ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: otherCauseController,
                              decoration: const InputDecoration(
                                labelText: StringsKo.otherCauseLabel,
                              ),
                              validator: (_) =>
                                  otherCauseController.text.trim().isEmpty
                                  ? StringsKo.enterOtherCauseError
                                  : null,
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text(StringsKo.cancel),
                              ),
                              const Spacer(),
                              FilledButton(
                                onPressed: isValid()
                                    ? () {
                                        if (formKey.currentState?.validate() ??
                                            false) {
                                          final resolvedType = isOtherType
                                              ? otherTypeController.text.trim()
                                              : crackType!;
                                          final resolvedCause = isOtherCause
                                              ? otherCauseController.text.trim()
                                              : cause!;
                                          Navigator.of(context).pop(
                                            DefectDetails(
                                              structuralMember:
                                                  structuralMember!,
                                              crackType: resolvedType,
                                              widthMm: double.parse(
                                                widthController.text.trim(),
                                              ),
                                              lengthMm: double.parse(
                                                lengthController.text.trim(),
                                              ),
                                              cause: resolvedCause,
                                            ),
                                          );
                                        }
                                      }
                                    : null,
                                child: const Text(StringsKo.confirm),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildPdfViewer() {
    final theme = Theme.of(context);
    if (_pdfLoadError != null) {
      return Container(
        color: theme.colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Text(
          _pdfLoadError!,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
    if (_pdfController != null) {
      return ClipRect(
        child: PdfView(
          controller: _pdfController!,
          scrollDirection: Axis.vertical,
          pageSnapping: true,
          physics: const PageScrollPhysics(),
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
          builders: PdfViewBuilders<DefaultBuilderOptions>(
            options: const DefaultBuilderOptions(
              loaderSwitchDuration: Duration(milliseconds: 300),
            ),
            documentLoaderBuilder: (_) => const Center(
              child: CircularProgressIndicator(),
            ),
            pageLoaderBuilder: (_) => const Center(
              child: CircularProgressIndicator(),
            ),
            pageBuilder: (context, pageImage, pageIndex, document) {
              final pageNumber = pageIndex + 1;
              final imageProvider = PdfPageImageProvider(
                pageImage,
                pageNumber,
                document.id,
              );
              final fallbackSize =
                  _pdfPageSizes[pageNumber] ?? _canvasSize;
              return PhotoViewGalleryPageOptions.customChild(
                child: FutureBuilder<PdfPageImage>(
                  future: pageImage,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final data = snapshot.data!;
                      final w = (data.width ?? 1).toDouble();
                      final h = (data.height ?? 1).toDouble();
                      final pageSize = Size(
                        w,
                        h,
                      );
                      if (_pdfPageSizes[pageNumber] != pageSize) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) {
                            return;
                          }
                          setState(() {
                            _pdfPageSizes[pageNumber] = pageSize;
                          });
                        });
                      }
                      return _buildPdfPageLayer(
                        pageSize: pageSize,
                        pageNumber: pageNumber,
                        imageProvider: imageProvider,
                      );
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
                childSize: fallbackSize,
                initialScale: PhotoViewComputedScale.contained,
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2.0,
                basePosition: Alignment.center,
              );
            },
          ),
        ),
      );
    }
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.picture_as_pdf_outlined,
            size: 64,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            _site.pdfName ?? StringsKo.pdfDrawingLoaded,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(StringsKo.pdfDrawingHint, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildPdfPageLayer({
    required Size pageSize,
    required int pageNumber,
    required ImageProvider imageProvider,
  }) {
    return Listener(
      onPointerDown: (event) {
        _pointerDownPosition = event.localPosition;
        _tapCanceled = false;
      },
      onPointerMove: (event) {
        if (_pointerDownPosition == null) {
          return;
        }
        final distance =
            (event.localPosition - _pointerDownPosition!).distance;
        if (distance > _tapSlop) {
          _tapCanceled = true;
        }
      },
      onPointerUp: (_) {
        _pointerDownPosition = null;
      },
      onPointerCancel: (_) {
        _pointerDownPosition = null;
        _tapCanceled = false;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapUp: (details) => _handlePdfTap(
          details,
          pageSize,
          pageNumber,
        ),
        child: AspectRatio(
          aspectRatio: pageSize.width / pageSize.height,
          child: SizedBox(
            width: pageSize.width,
            height: pageSize.height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image(
                    image: imageProvider,
                    fit: BoxFit.contain,
                  ),
                ),
                ..._buildDefectMarkersForPage(
                  pageSize,
                  pageNumber,
                ),
                ..._buildEquipmentMarkersForPage(
                  pageSize,
                  pageNumber,
                ),
                _buildMarkerPopupForPage(
                  pageSize,
                  pageNumber,
                ),
              ],
            ),
          ),
        ),
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
        painter: _GridPainter(lineColor: theme.colorScheme.outlineVariant),
      ),
    );
  }

  Future<void> _handlePdfTap(
    TapUpDetails details,
    Size pageSize,
    int pageIndex,
  ) async {
    if (_tapCanceled) {
      _tapCanceled = false;
      return;
    }
    final localPosition = details.localPosition;
    final hitResult = _hitTestMarkerOnPage(
      localPosition,
      pageSize,
      pageIndex,
    );
    if (hitResult != null) {
      _selectMarker(hitResult);
      return;
    }

    _clearSelectedMarker();
    if (_mode == DrawMode.defect && _activeCategory == null) {
      _showSelectDefectCategoryHint();
      return;
    }
    if (_mode == DrawMode.equipment && _activeEquipmentCategory == null) {
      return;
    }
    if (_mode != DrawMode.defect && _mode != DrawMode.equipment) {
      return;
    }

    final normalizedX = (localPosition.dx / pageSize.width).clamp(0.0, 1.0);
    final normalizedY = (localPosition.dy / pageSize.height).clamp(0.0, 1.0);

    if (_mode == DrawMode.defect) {
      final detailsResult = await _showDefectDetailsDialog();
      if (!mounted || detailsResult == null) {
        return;
      }

      final countOnPage = _site.defects
          .where(
            (defect) =>
                defect.pageIndex == pageIndex &&
                defect.category == _activeCategory,
          )
          .length;
      final label = _activeCategory == DefectCategory.generalCrack
          ? 'C${countOnPage + 1}'
          : '${countOnPage + 1}';

      final defect = Defect(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        label: label,
        pageIndex: pageIndex,
        category: _activeCategory!,
        normalizedX: normalizedX,
        normalizedY: normalizedY,
        details: detailsResult,
      );

      setState(() {
        _site = _site.copyWith(defects: [..._site.defects, defect]);
      });
      await widget.onSiteUpdated(_site);
    } else {
      final equipmentCount = _site.equipmentMarkers
          .where((marker) => marker.category == _activeEquipmentCategory)
          .length;
      final prefix = _equipmentLabelPrefix(_activeEquipmentCategory!);
      final label = '$prefix${equipmentCount + 1}';
      final marker = EquipmentMarker(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        label: label,
        pageIndex: pageIndex,
        category: _activeEquipmentCategory!,
        normalizedX: normalizedX,
        normalizedY: normalizedY,
      );

      setState(() {
        _site = _site.copyWith(
          equipmentMarkers: [..._site.equipmentMarkers, marker],
        );
      });
      await widget.onSiteUpdated(_site);
    }
  }

  Widget _buildMarkerPopup(Size viewportSize) {
    if (_selectedMarkerScenePosition == null ||
        (_selectedDefect == null && _selectedEquipment == null)) {
      return const SizedBox.shrink();
    }

    const popupMaxWidth = 220.0;
    const popupMargin = 8.0;
    const lineHeight = 18.0;
    const verticalPadding = 12.0;
    final lines = _selectedDefect != null
        ? _defectPopupLines(_selectedDefect!)
        : _equipmentPopupLines(_selectedEquipment!);
    final estimatedHeight = lines.length * lineHeight + verticalPadding * 2;

    final markerViewportPosition = MatrixUtils.transformPoint(
      _transformationController.value,
      _selectedMarkerScenePosition!,
    );

    final desiredLeft = markerViewportPosition.dx + 16;
    final desiredTop = markerViewportPosition.dy - estimatedHeight - 12;

    final maxLeft = (viewportSize.width - popupMaxWidth - popupMargin).clamp(
      0.0,
      double.infinity,
    );
    final maxTop = (viewportSize.height - estimatedHeight - popupMargin).clamp(
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

    return Positioned(
      left: left,
      top: top,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: popupMaxWidth),
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: verticalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: lines
                  .map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        line,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
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

    const popupMaxWidth = 220.0;
    const popupMargin = 8.0;
    const lineHeight = 18.0;
    const verticalPadding = 12.0;
    final lines = selectedDefect != null
        ? _defectPopupLines(selectedDefect)
        : _equipmentPopupLines(selectedEquipment!);
    final estimatedHeight = lines.length * lineHeight + verticalPadding * 2;

    final normalizedX =
        selectedDefect?.normalizedX ?? selectedEquipment!.normalizedX;
    final normalizedY =
        selectedDefect?.normalizedY ?? selectedEquipment!.normalizedY;
    final markerPosition = Offset(
      normalizedX * pageSize.width,
      normalizedY * pageSize.height,
    );

    final desiredLeft = markerPosition.dx + 16;
    final desiredTop = markerPosition.dy - estimatedHeight - 12;

    final maxLeft = (pageSize.width - popupMaxWidth - popupMargin).clamp(
      0.0,
      double.infinity,
    );
    final maxTop = (pageSize.height - estimatedHeight - popupMargin).clamp(
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

    return Positioned(
      left: left,
      top: top,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: popupMaxWidth),
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: verticalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: lines
                  .map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        line,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
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
    return [marker.label, marker.category.label];
  }

  String _formatNumber(double value) {
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  List<Widget> _buildDefectMarkers() {
    final defects = _site.defects
        .where((defect) => defect.pageIndex == _currentPage)
        .toList();

    return defects.map((defect) {
      final position = Offset(
        defect.normalizedX * _canvasSize.width,
        defect.normalizedY * _canvasSize.height,
      );
      return Positioned(
        left: position.dx - 18,
        top: position.dy - 18,
        child: _DefectMarker(
          label: defect.label,
          category: defect.category,
          color: _defectColor(defect.category),
        ),
      );
    }).toList();
  }

  List<Widget> _buildDefectMarkersForPage(Size pageSize, int pageIndex) {
    final defects = _site.defects
        .where((defect) => defect.pageIndex == pageIndex)
        .toList();

    return defects.map((defect) {
      final position = Offset(
        defect.normalizedX * pageSize.width,
        defect.normalizedY * pageSize.height,
      );
      return Positioned(
        left: position.dx - 18,
        top: position.dy - 18,
        child: _DefectMarker(
          label: defect.label,
          category: defect.category,
          color: _defectColor(defect.category),
        ),
      );
    }).toList();
  }

  List<Widget> _buildEquipmentMarkers() {
    final markers = _site.equipmentMarkers
        .where((marker) => marker.pageIndex == _currentPage)
        .toList();

    return markers.map((marker) {
      final position = Offset(
        marker.normalizedX * _canvasSize.width,
        marker.normalizedY * _canvasSize.height,
      );
      return Positioned(
        left: position.dx - 18,
        top: position.dy - 18,
        child: _EquipmentMarker(
          label: marker.label,
          category: marker.category,
          color: _equipmentColor(marker.category),
        ),
      );
    }).toList();
  }

  List<Widget> _buildEquipmentMarkersForPage(Size pageSize, int pageIndex) {
    final markers = _site.equipmentMarkers
        .where((marker) => marker.pageIndex == pageIndex)
        .toList();

    return markers.map((marker) {
      final position = Offset(
        marker.normalizedX * pageSize.width,
        marker.normalizedY * pageSize.height,
      );
      return Positioned(
        left: position.dx - 18,
        top: position.dy - 18,
        child: _EquipmentMarker(
          label: marker.label,
          category: marker.category,
          color: _equipmentColor(marker.category),
        ),
      );
    }).toList();
  }

  Widget _buildToolSelectionRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToolToggleButton(
            label: StringsKo.defectModeLabel,
            isSelected: _mode == DrawMode.defect,
            onTap: () => _toggleMode(DrawMode.defect),
          ),
          const SizedBox(width: 8),
          _ToolToggleButton(
            label: StringsKo.equipmentModeLabel,
            isSelected: _mode == DrawMode.equipment,
            onTap: () => _toggleMode(DrawMode.equipment),
          ),
          const SizedBox(width: 8),
          _ToolToggleButton(
            label: StringsKo.freeDrawModeLabel,
            isSelected: _mode == DrawMode.freeDraw,
            onTap: () => _toggleMode(DrawMode.freeDraw),
          ),
          const SizedBox(width: 8),
          _ToolToggleButton(
            label: StringsKo.eraserModeLabel,
            isSelected: _mode == DrawMode.eraser,
            onTap: () => _toggleMode(DrawMode.eraser),
          ),
        ],
      ),
    );
  }

  void _toggleMode(DrawMode nextMode) {
    setState(() {
      _mode = _mode == nextMode ? DrawMode.hand : nextMode;
    });
  }

  Widget _buildNumberedTabs<T>({
    required List<T> items,
    required T? selected,
    required ValueChanged<T> onSelected,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = item == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('${index + 1}'),
              selected: isSelected,
              onSelected: (_) => onSelected(item),
            ),
          );
        }),
      ),
    );
  }

  bool _isToolSelectionMode() => _mode == DrawMode.hand;

  String _modeTitle(DrawMode mode) {
    switch (mode) {
      case DrawMode.defect:
        return StringsKo.defectModeLabel;
      case DrawMode.equipment:
        return StringsKo.equipmentModeLabel;
      case DrawMode.freeDraw:
        return StringsKo.freeDrawModeLabel;
      case DrawMode.eraser:
        return StringsKo.eraserModeLabel;
      case DrawMode.hand:
        return '';
    }
  }

  void _returnToToolSelection() {
    setState(() {
      _mode = DrawMode.hand;
    });
  }

  void _handleAddToolAction() {
    if (_mode == DrawMode.defect) {
      _showDefectCategoryPicker();
    }
  }

  Widget _buildToolDetailRow() {
    final showAddButton =
        _mode == DrawMode.defect || _mode == DrawMode.equipment;
    final showTabs = _mode == DrawMode.defect
        ? _defectTabs.isNotEmpty
        : showAddButton;

    return Row(
      children: [
        IconButton(
          tooltip: '뒤로',
          icon: const Icon(Icons.arrow_back),
          onPressed: _returnToToolSelection,
        ),
        const SizedBox(width: 4),
        Flexible(
          fit: FlexFit.loose,
          child: Text(
            _modeTitle(_mode),
            style: Theme.of(context).textTheme.titleSmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (showAddButton) ...[
          const SizedBox(width: 6),
          SizedBox(
            width: 24,
            height: 24,
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 18,
              onPressed: _handleAddToolAction,
              icon: const Icon(Icons.add),
              tooltip: '추가',
            ),
          ),
        ],
        if (showTabs) ...[
          const SizedBox(width: 8),
          Flexible(
            fit: FlexFit.loose,
            child: _mode == DrawMode.defect
                ? _buildDefectCategoryTabs()
                : _buildNumberedTabs(
                    items: EquipmentCategory.values,
                    selected: _activeEquipmentCategory,
                    onSelected: (item) {
                      setState(() {
                        _activeEquipmentCategory = item;
                      });
                    },
                  ),
          ),
        ],
      ],
    );
  }

  Widget _buildDefectCategoryTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _defectTabs.map((category) {
          final isSelected = category == _activeCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(category.label),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _activeCategory = category;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
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
    final selectedCategory = await showModalBottomSheet<DefectCategory>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final category in DefectCategory.values)
                _DefectCategoryPickerTile(
                  category: category,
                  isSelected: _defectTabs.contains(category),
                  onTap: _defectTabs.contains(category)
                      ? null
                      : () => Navigator.of(context).pop(category),
                ),
            ],
          ),
        );
      },
    );

    if (selectedCategory == null || !mounted) {
      return;
    }

    setState(() {
      if (!_defectTabs.contains(selectedCategory)) {
        _defectTabs.add(selectedCategory);
      }
      _activeCategory = selectedCategory;
    });
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
    }
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
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(toolBarHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _isToolSelectionMode()
                  ? _buildToolSelectionRow()
                  : _buildToolDetailRow(),
            ),
          ),
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
                      _buildPdfViewer()
                    else
                      Listener(
                        onPointerDown: (event) {
                          _pointerDownPosition = event.localPosition;
                          _tapCanceled = false;
                        },
                        onPointerMove: (event) {
                          if (_pointerDownPosition == null) {
                            return;
                          }
                          final distance =
                              (event.localPosition - _pointerDownPosition!)
                                  .distance;
                          if (distance > _tapSlop) {
                            _tapCanceled = true;
                          }
                        },
                        onPointerUp: (_) {
                          _pointerDownPosition = null;
                        },
                        onPointerCancel: (_) {
                          _pointerDownPosition = null;
                          _tapCanceled = false;
                        },
                        child: GestureDetector(
                          behavior: HitTestBehavior.deferToChild,
                          onTapUp: _handleCanvasTap,
                          child: InteractiveViewer(
                            transformationController:
                                _transformationController,
                            minScale: 0.5,
                            maxScale: 4,
                            constrained: false,
                            child: SizedBox(
                              key: _canvasKey,
                              width: _canvasSize.width,
                              height: _canvasSize.height,
                              child: Stack(
                                children: [
                                  _buildDrawingBackground(),
                                  ..._buildDefectMarkers(),
                                  ..._buildEquipmentMarkers(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (_site.drawingType != DrawingType.pdf)
                      _buildMarkerPopup(MediaQuery.of(context).size),
                    _buildPageOverlay(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageOverlay() {
    if (_site.drawingType != DrawingType.pdf || _pageCount <= 1) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Positioned(
      right: 16,
      bottom: 16,
      child: Column(
        children: [
          _PageNavButton(
            icon: Icons.keyboard_arrow_up,
            onPressed: _currentPage > 1
                ? () {
                    final nextPage = _currentPage - 1;
                    setState(() {
                      _currentPage = nextPage;
                    });
                    _pdfController?.jumpToPage(nextPage);
                  }
                : null,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              StringsKo.pageIndicator(_currentPage, _pageCount),
              style: theme.textTheme.labelMedium,
            ),
          ),
          const SizedBox(height: 8),
          _PageNavButton(
            icon: Icons.keyboard_arrow_down,
            onPressed: _currentPage < _pageCount
                ? () {
                    final nextPage = _currentPage + 1;
                    setState(() {
                      _currentPage = nextPage;
                    });
                    _pdfController?.jumpToPage(nextPage);
                  }
                : null,
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

class _DefectCategoryPickerTile extends StatelessWidget {
  const _DefectCategoryPickerTile({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final DefectCategory category;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(category.label),
      enabled: onTap != null,
      trailing: isSelected
          ? Icon(
              Icons.check,
              color: theme.colorScheme.primary,
            )
          : null,
      onTap: onTap,
    );
  }
}

class _ToolToggleButton extends StatelessWidget {
  const _ToolToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        backgroundColor:
            isSelected ? colors.primary : colors.surfaceContainerHighest,
        foregroundColor:
            isSelected ? colors.onPrimary : colors.onSurfaceVariant,
        side: BorderSide(
          color: isSelected ? colors.primary : colors.outlineVariant,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}

class _PageNavButton extends StatelessWidget {
  const _PageNavButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
      shape: const CircleBorder(),
      elevation: 4,
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
      ),
    );
  }
}

class _DefectMarker extends StatelessWidget {
  const _DefectMarker({
    required this.label,
    required this.category,
    required this.color,
  });

  final String label;
  final DefectCategory category;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: category.label,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _EquipmentMarker extends StatelessWidget {
  const _EquipmentMarker({
    required this.label,
    required this.category,
    required this.color,
  });

  final String label;
  final EquipmentCategory category;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: category.label,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.lineColor});

  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    const step = 60.0;
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor;
  }
}
