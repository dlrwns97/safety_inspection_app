import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../constants/strings_ko.dart';
import '../models/defect.dart';
import '../models/defect_details.dart';
import '../models/drawing_enums.dart';
import '../models/equipment_marker.dart';
import '../models/site.dart';
import '../widgets/mode_button.dart';

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
  static const int _pageCount = 3;
  final TransformationController _transformationController =
      TransformationController();
  final GlobalKey _canvasKey = GlobalKey();

  late Site _site;
  DrawMode _mode = DrawMode.defect;
  DefectCategory? _activeCategory;
  EquipmentCategory? _activeEquipmentCategory;
  int _currentPage = 1;
  Defect? _selectedDefect;
  EquipmentMarker? _selectedEquipment;
  Offset? _selectedMarkerScenePosition;

  @override
  void initState() {
    super.initState();
    _site = widget.site;
  }

  Future<void> _handleTap(TapDownDetails details) async {
    final scenePoint = _transformationController.toScene(details.localPosition);
    if (!_isTapWithinCanvas(details)) {
      _clearSelectedMarker();
      return;
    }

    final hitResult = _hitTestMarker(scenePoint);
    if (hitResult != null) {
      _selectMarker(hitResult);
      return;
    }

    _clearSelectedMarker();
    if (_mode == DrawMode.defect && _activeCategory == null) {
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
      final label = '${_site.equipmentMarkers.length + 1}';
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

  _MarkerHitResult? _hitTestMarker(Offset scenePoint) {
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

  bool _isTapWithinCanvas(TapDownDetails details) {
    final context = _canvasKey.currentContext;
    final renderObject = context?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return false;
    }

    final localPosition = renderObject.globalToLocal(details.globalPosition);
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

                return SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
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

  Widget _buildDrawingBackground() {
    final theme = Theme.of(context);
    if (_site.drawingType == DrawingType.pdf) {
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
        child: _EquipmentMarker(label: marker.label, category: marker.category),
      );
    }).toList();
  }

  Widget _buildModeButtons() {
    return Column(
      children: [
        ModeButton(
          icon: Icons.bug_report_outlined,
          label: StringsKo.defectModeLabel,
          isSelected: _mode == DrawMode.defect,
          onTap: () => setState(() => _mode = DrawMode.defect),
        ),
        const SizedBox(height: 12),
        ModeButton(
          icon: Icons.construction_outlined,
          label: StringsKo.equipmentModeLabel,
          isSelected: _mode == DrawMode.equipment,
          onTap: () => setState(() => _mode = DrawMode.equipment),
        ),
        const SizedBox(height: 12),
        ModeButton(
          icon: Icons.brush_outlined,
          label: StringsKo.freeDrawModeLabel,
          isSelected: _mode == DrawMode.freeDraw,
          onTap: () => setState(() => _mode = DrawMode.freeDraw),
        ),
        const SizedBox(height: 12),
        ModeButton(
          icon: Icons.auto_fix_off_outlined,
          label: StringsKo.eraserModeLabel,
          isSelected: _mode == DrawMode.eraser,
          onTap: () => setState(() => _mode = DrawMode.eraser),
        ),
      ],
    );
  }

  Widget _buildDefectCategories() {
    return Wrap(
      spacing: 8,
      children: DefectCategory.values.map((category) {
        final selected = _activeCategory == category;
        return ChoiceChip(
          label: Text(category.label),
          selected: selected,
          onSelected: (_) {
            setState(() {
              _activeCategory = category;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildEquipmentCategories() {
    return Wrap(
      spacing: 8,
      children: EquipmentCategory.values.map((category) {
        final selected = _activeEquipmentCategory == category;
        return ChoiceChip(
          label: Text(category.label),
          selected: selected,
          onSelected: (_) {
            setState(() {
              _activeEquipmentCategory = category;
            });
          },
        );
      }).toList(),
    );
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
    final pageLabel = StringsKo.pageTitle(_currentPage);

    return Scaffold(
      appBar: AppBar(
        title: Text(_site.name),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _currentPage,
                items: List.generate(_pageCount, (index) {
                  final pageNumber = index + 1;
                  return DropdownMenuItem<int>(
                    value: pageNumber,
                    child: Text(StringsKo.pageTitle(pageNumber)),
                  );
                }),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _currentPage = value;
                  });
                },
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              pageLabel,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_mode == DrawMode.defect)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_activeCategory == null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        StringsKo.selectDefectCategoryHint,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  _buildDefectCategories(),
                ],
              ),
            )
          else if (_mode == DrawMode.equipment)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_activeEquipmentCategory == null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        StringsKo.selectEquipmentCategoryHint,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  _buildEquipmentCategories(),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                StringsKo.modePlaceholder,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, _) {
                return Stack(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.deferToChild,
                      onTapDown: _handleTap,
                      child: InteractiveViewer(
                        transformationController: _transformationController,
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
                    _buildMarkerPopup(MediaQuery.of(context).size),
                    Positioned(top: 16, right: 16, child: _buildModeButtons()),
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
  const _EquipmentMarker({required this.label, required this.category});

  final String label;
  final EquipmentCategory category;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
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
