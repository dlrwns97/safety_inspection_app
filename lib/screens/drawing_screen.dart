import 'package:flutter/material.dart';
import 'package:safety_inspection_app/models/defect_models.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/site_models.dart';
import 'package:safety_inspection_app/widgets/defect_marker.dart';
import 'package:safety_inspection_app/widgets/grid_painter.dart';
import 'package:safety_inspection_app/widgets/mode_button.dart';

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
  DefectCategory _activeCategory = DefectCategory.generalCrack;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _site = widget.site;
  }

  Future<void> _handleTap(TapDownDetails details) async {
    if (_mode != DrawMode.defect) {
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
      category: _activeCategory,
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
                      'Defect details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: structuralMember,
                      decoration: const InputDecoration(
                        labelText: 'Structural member',
                      ),
                      items: const [
                        'Column',
                        'Wall',
                        'Slab',
                        'Beam',
                        'Masonry wall',
                      ]
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
                          value == null ? 'Please select a member' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: crackType,
                      decoration: const InputDecoration(
                        labelText: 'Crack type',
                      ),
                      items: const [
                        'Horizontal',
                        'Vertical',
                        'Diagonal',
                        'Vertical+Horizontal',
                        'Network',
                      ]
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
                          value == null ? 'Please select a crack type' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: widthController,
                            decoration: const InputDecoration(
                              labelText: 'Width (mm)',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              final parsed = double.tryParse(value ?? '');
                              if (parsed == null || parsed <= 0) {
                                return 'Enter width';
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
                              labelText: 'Length (mm)',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              final parsed = double.tryParse(value ?? '');
                              if (parsed == null || parsed <= 0) {
                                return 'Enter length';
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
                      decoration: const InputDecoration(labelText: 'Cause'),
                      items: const [
                        'Drying shrinkage',
                        'Rebar corrosion',
                        'Joint crack',
                        'Finish crack',
                      ]
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
                          value == null ? 'Please select a cause' : null,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
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
                          child: const Text('Confirm'),
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
              _site.pdfName ?? 'PDF Drawing Loaded',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'Pinch to zoom and tap to add defects.',
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
        painter: GridPainter(lineColor: theme.colorScheme.outlineVariant),
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
        child: DefectMarker(label: defect.label, category: defect.category),
      );
    }).toList();
  }

  Widget _buildModeButtons() {
    return Column(
      children: [
        ModeButton(
          icon: Icons.bug_report_outlined,
          label: 'Defect',
          isSelected: _mode == DrawMode.defect,
          onTap: () => setState(() => _mode = DrawMode.defect),
        ),
        const SizedBox(height: 12),
        ModeButton(
          icon: Icons.construction_outlined,
          label: 'Equipment',
          isSelected: _mode == DrawMode.equipment,
          onTap: () => setState(() => _mode = DrawMode.equipment),
        ),
        const SizedBox(height: 12),
        ModeButton(
          icon: Icons.brush_outlined,
          label: 'Free Draw',
          isSelected: _mode == DrawMode.freeDraw,
          onTap: () => setState(() => _mode = DrawMode.freeDraw),
        ),
        const SizedBox(height: 12),
        ModeButton(
          icon: Icons.auto_fix_off_outlined,
          label: 'Eraser',
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
    final pageLabel =
        _currentPage == 1 ? 'Page 1' : 'Page ${_currentPage.toString()}';

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
                    child: Text('Page $pageNumber'),
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
              child: _buildDefectCategories(),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                'Mode controls are placeholders in Phase 1.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, _) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: _mode == DrawMode.defect ? _handleTap : null,
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
