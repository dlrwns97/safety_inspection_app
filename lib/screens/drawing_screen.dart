import 'package:flutter/material.dart';

import '../constants/strings_ko.dart';
import '../models/defect.dart';
import '../models/defect_details.dart';
import '../models/drawing_enums.dart';
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

  late Site _site;
  DrawMode _mode = DrawMode.defect;
  DefectCategory? _activeCategory;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _site = widget.site;
  }

  Future<void> _handleTap(TapDownDetails details) async {
    if (_mode != DrawMode.defect || _activeCategory == null) {
      return;
    }

    final scenePoint = _transformationController.toScene(details.localPosition);
    final normalizedX = (scenePoint.dx / _canvasSize.width).clamp(0.0, 1.0);
    final normalizedY = (scenePoint.dy / _canvasSize.height).clamp(0.0, 1.0);

    final detailsResult = await _showDefectDetailsSheet();
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

  Future<DefectDetails?> _showDefectDetailsSheet() async {
    return showModalBottomSheet<DefectDetails>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final formKey = GlobalKey<FormState>();
        String? structuralMember;
        String? crackType;
        String? cause;
        final widthController = TextEditingController();
        final lengthController = TextEditingController();

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
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

              return Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      StringsKo.defectDetailsTitle,
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
                            keyboardType: const TextInputType.numberWithOptions(
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
                            keyboardType: const TextInputType.numberWithOptions(
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
              );
            },
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
            const Text(
              StringsKo.pdfDrawingHint,
              textAlign: TextAlign.center,
            ),
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
        left: position.dx - 18,
        top: position.dy - 18,
        child: _DefectMarker(label: defect.label, category: defect.category),
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
                  behavior: HitTestBehavior.opaque,
                  onTapDown: _mode == DrawMode.defect && _activeCategory != null
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
  const _DefectMarker({required this.label, required this.category});

  final String label;
  final DefectCategory category;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;
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
