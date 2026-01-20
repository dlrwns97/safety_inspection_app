import 'package:flutter/material.dart';

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
  static const double _markerDiameter = 28;
  final TransformationController _transformationController =
      TransformationController();

  late Site _site;
  DrawMode _toolMode = DrawMode.defect;
  DefectCategory? _activeCategory;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _site = widget.site;
  }

  Future<void> _handleTap(TapDownDetails details) async {
    final scenePoint = _transformationController.toScene(details.localPosition);
    final normalizedX = (scenePoint.dx / _canvasSize.width).clamp(0.0, 1.0);
    final normalizedY = (scenePoint.dy / _canvasSize.height).clamp(0.0, 1.0);

    if (_toolMode == DrawMode.equipment) {
      await _addEquipmentMarker(normalizedX, normalizedY);
      return;
    }

    if (_toolMode != DrawMode.defect || _activeCategory == null) {
      return;
    }

    final detailsResult = await _showDefectDetailsDialog(_activeCategory!);
    if (!mounted || detailsResult == null) {
      return;
    }

    final countOnPage = _site.defects
        .where((defect) => defect.pageIndex == _currentPage)
        .length;
    final label = 'C${countOnPage + 1}';

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
  }

  Future<void> _addEquipmentMarker(double normalizedX, double normalizedY) async {
    final countOnPage = _site.equipmentMarkers
        .where((marker) => marker.pageIndex == _currentPage)
        .length;
    final label = 'E${countOnPage + 1}';

    final marker = EquipmentMarker(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      label: label,
      pageIndex: _currentPage,
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

  String _defectDetailsTitle(DefectCategory category) {
    switch (category) {
      case DefectCategory.generalCrack:
        return StringsKo.defectDetailsTitleCrack;
      case DefectCategory.waterLeakage:
        return StringsKo.defectDetailsTitleLeakage;
      case DefectCategory.concreteSpalling:
        return StringsKo.defectDetailsTitleConcrete;
      case DefectCategory.other:
        return StringsKo.defectDetailsTitleOther;
    }
  }

  Future<DefectDetails?> _showDefectDetailsDialog(
    DefectCategory category,
  ) async {
    return showDialog<DefectDetails>(
      context: context,
      builder: (context) {
        final formKey = GlobalKey<FormState>();
        String? structuralMember;
        String? crackType;
        String? cause;
        final widthController = TextEditingController();
        final lengthController = TextEditingController();
        final dialogHeight = MediaQuery.of(context).size.height * 0.5;

        return AlertDialog(
          title: Text(_defectDetailsTitle(category)),
          content: SizedBox(
            width: double.maxFinite,
            height: dialogHeight,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: StatefulBuilder(
                builder: (context, setState) {
                  bool isValid() {
                    final width = double.tryParse(widthController.text);
                    final length = double.tryParse(lengthController.text);
                    return structuralMember != null &&
                        crackType != null &&
                        cause != null &&
                        width != null &&
                        length != null &&
                        width > 0 &&
                        length > 0;
                  }

                  return SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                            validator: (value) =>
                                value == null ? StringsKo.selectMemberError : null,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: crackType,
                            decoration: const InputDecoration(
                              labelText: StringsKo.crackTypeLabel,
                            ),
                            items: StringsKo.crackTypes
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
                              });
                            },
                            validator: (value) =>
                                value == null ? StringsKo.selectCrackTypeError : null,
                          ),
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
                            items: StringsKo.defectCauses
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
                              });
                            },
                            validator: (value) =>
                                value == null ? StringsKo.selectCauseError : null,
                          ),
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
                                          Navigator.of(context).pop(
                                            DefectDetails(
                                              structuralMember: structuralMember!,
                                              crackType: crackType!,
                                              widthMm: double.parse(
                                                widthController.text.trim(),
                                              ),
                                              lengthMm: double.parse(
                                                lengthController.text.trim(),
                                              ),
                                              cause: cause!,
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
                  );
                },
              ),
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
        left: position.dx - _markerDiameter / 2,
        top: position.dy - _markerDiameter / 2,
        child: _DefectMarker(
          label: defect.label,
          category: defect.category,
          diameter: _markerDiameter,
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
        left: position.dx - _markerDiameter / 2,
        top: position.dy - _markerDiameter / 2,
        child: _EquipmentMarker(label: marker.label, diameter: _markerDiameter),
      );
    }).toList();
  }

  Widget _buildModeButtons() {
    return Column(
      children: [
        ModeButton(
          icon: Icons.bug_report_outlined,
          label: StringsKo.defectModeLabel,
          isSelected: _toolMode == DrawMode.defect,
          onTap: () => setState(() => _toolMode = DrawMode.defect),
        ),
        const SizedBox(height: 12),
        ModeButton(
          icon: Icons.construction_outlined,
          label: StringsKo.equipmentModeLabel,
          isSelected: _toolMode == DrawMode.equipment,
          onTap: () => setState(() => _toolMode = DrawMode.equipment),
        ),
        const SizedBox(height: 12),
        ModeButton(
          icon: Icons.brush_outlined,
          label: StringsKo.freeDrawModeLabel,
          isSelected: _toolMode == DrawMode.freeDraw,
          onTap: () => setState(() => _toolMode = DrawMode.freeDraw),
        ),
        const SizedBox(height: 12),
        ModeButton(
          icon: Icons.auto_fix_off_outlined,
          label: StringsKo.eraserModeLabel,
          isSelected: _toolMode == DrawMode.eraser,
          onTap: () => setState(() => _toolMode = DrawMode.eraser),
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
              _activeCategory = selected ? null : category;
            });
          },
        );
      }).toList(),
    );
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
          if (_toolMode == DrawMode.defect)
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
                return GestureDetector(
                  behavior: HitTestBehavior.deferToChild,
                  onTapDown: _toolMode == DrawMode.defect ||
                          _toolMode == DrawMode.equipment
                      ? _handleTap
                      : null,
                  child: Stack(
                    children: [
                      InteractiveViewer(
                        transformationController: _transformationController,
                        minScale: 0.5,
                        maxScale: 4,
                        constrained: false,
                        child: SizedBox(
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
                      Positioned(
                        top: 16,
                        right: 16,
                        child: _buildModeButtons(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DefectMarker extends StatelessWidget {
  const _DefectMarker({
    required this.label,
    required this.category,
    required this.diameter,
  });

  final String label;
  final DefectCategory category;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;
    final textStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontSize: 11,
        );
    return Tooltip(
      message: category.label,
      child: Container(
        width: diameter,
        height: diameter,
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
            style: textStyle,
          ),
        ),
      ),
    );
  }
}

class _EquipmentMarker extends StatelessWidget {
  const _EquipmentMarker({required this.label, required this.diameter});

  final String label;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final textStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontSize: 11,
        );
    return Tooltip(
      message: StringsKo.equipmentModeLabel,
      child: Container(
        width: diameter,
        height: diameter,
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
            style: textStyle,
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
