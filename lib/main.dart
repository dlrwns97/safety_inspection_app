import 'dart:async';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

void main() {
  runApp(const SafetyInspectionApp());
}

enum ToolMode { defect, equipment, freeDraw, eraser }

enum DefectCategory { crack, leak, concrete, other }

enum CrackType {
  vertical,
  horizontal,
  diagonal,
  verticalHorizontal,
  map,
  other,
}

enum GenericDefectType { surface, penetration, other }

class SafetyInspectionApp extends StatelessWidget {
  const SafetyInspectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safety Inspection',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const InspectionHomePage(),
    );
  }
}

class InspectionHomePage extends StatefulWidget {
  const InspectionHomePage({super.key});

  @override
  State<InspectionHomePage> createState() => _InspectionHomePageState();
}

class _InspectionHomePageState extends State<InspectionHomePage> {
  ToolMode _toolMode = ToolMode.defect;
  DefectCategory _selectedCategory = DefectCategory.crack;
  CrackType _crackType = CrackType.vertical;
  GenericDefectType _genericDefectType = GenericDefectType.surface;

  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _lengthController = TextEditingController();
  final TextEditingController _customCrackController = TextEditingController();
  final TextEditingController _customTypeController = TextEditingController();
  final FocusNode _widthFocusNode = FocusNode();
  final FocusNode _lengthFocusNode = FocusNode();
  final FocusNode _customCrackFocusNode = FocusNode();
  final FocusNode _customTypeFocusNode = FocusNode();

  PdfControllerPinch? _pdfController;
  PdfDocument? _document;
  String? _pdfPath;
  String? _pdfError;
  int _currentPage = 1;
  int _totalPages = 1;
  Size? _pageSize;

  final List<Offset> _defectMarkers = [];
  bool _showDefectPanel = false;

  @override
  void dispose() {
    _widthController.dispose();
    _lengthController.dispose();
    _customCrackController.dispose();
    _customTypeController.dispose();
    _widthFocusNode.dispose();
    _lengthFocusNode.dispose();
    _customCrackFocusNode.dispose();
    _customTypeFocusNode.dispose();
    _pdfController?.dispose();
    _document?.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    setState(() {
      _pdfError = null;
    });
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.single.path == null) {
      return;
    }
    final path = result.files.single.path!;
    try {
      final document = await PdfDocument.openFile(path);
      final firstPage = await document.getPage(1);
      final pageSize = Size(firstPage.width.toDouble(), firstPage.height.toDouble());
      await firstPage.close();
      _pdfController?.dispose();
      _document?.dispose();
      setState(() {
        _pdfPath = path;
        _document = document;
        _pdfController = PdfControllerPinch(document: Future.value(document));
        _currentPage = 1;
        _totalPages = document.pagesCount;
        _pageSize = pageSize;
        _showDefectPanel = false;
      });
    } catch (error) {
      setState(() {
        _pdfError = 'PDF 로드 실패: $error';
        _pdfPath = null;
        _pdfController?.dispose();
        _document?.dispose();
        _pdfController = null;
        _document = null;
        _pageSize = null;
        _showDefectPanel = false;
      });
    }
  }

  void _handleDefectTap(Offset localPosition, Rect contentRect) {
    if (!_isDefectModeActive || !_hasBlueprint) {
      return;
    }
    if (!contentRect.contains(localPosition)) {
      return;
    }
    final normalized = Offset(
      (localPosition.dx - contentRect.left) / contentRect.width,
      (localPosition.dy - contentRect.top) / contentRect.height,
    );
    setState(() {
      _defectMarkers.add(normalized);
      _showDefectPanel = true;
    });
  }

  bool get _isDefectModeActive {
    return _toolMode == ToolMode.defect;
  }

  bool get _hasBlueprint {
    return _pdfPath != null && _pdfController != null && _pageSize != null;
  }

  Rect _calculateContentRect(Size availableSize) {
    final pageSize = _pageSize;
    if (pageSize == null) {
      return Rect.fromLTWH(0, 0, availableSize.width, availableSize.height);
    }
    final pageAspectRatio = pageSize.width / pageSize.height;
    final viewAspectRatio = availableSize.width / max(availableSize.height, 1);
    double width;
    double height;
    if (viewAspectRatio > pageAspectRatio) {
      height = availableSize.height;
      width = height * pageAspectRatio;
    } else {
      width = availableSize.width;
      height = width / pageAspectRatio;
    }
    final left = (availableSize.width - width) / 2;
    final top = (availableSize.height - height) / 2;
    return Rect.fromLTWH(left, top, width, height);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          children: [
            _HeaderBar(
              currentPage: _currentPage,
              totalPages: _totalPages,
              onPickPdf: _pickPdf,
            ),
            _CategoryTabs(
              selectedCategory: _selectedCategory,
              onChanged: (category) {
                setState(() {
                  _selectedCategory = category;
                  _showDefectPanel = false;
                });
              },
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final size = constraints.biggest;
                        final contentRect = _calculateContentRect(size);
                        return Stack(
                          children: [
                            Positioned.fill(
                              child: _BlueprintViewer(
                                controller: _pdfController,
                                pdfPath: _pdfPath,
                                errorMessage: _pdfError,
                                onPageChanged: (page) {
                                  setState(() {
                                    _currentPage = page;
                                  });
                                },
                              ),
                            ),
                            Positioned.fill(
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTapUp: (details) {
                                  _handleDefectTap(
                                    details.localPosition,
                                    contentRect,
                                  );
                                },
                              ),
                            ),
                            _MarkerOverlay(
                              markers: _defectMarkers,
                              contentRect: contentRect,
                            ),
                            if (_isDefectModeActive && _showDefectPanel)
                              Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: TapRegion(
                                    onTapOutside: (event) {
                                      FocusManager.instance.primaryFocus?.unfocus();
                                    },
                                    child: DefectDetailPanel(
                                      category: _selectedCategory,
                                      crackType: _crackType,
                                      genericDefectType: _genericDefectType,
                                      widthController: _widthController,
                                      lengthController: _lengthController,
                                      customCrackController: _customCrackController,
                                      customTypeController: _customTypeController,
                                      widthFocusNode: _widthFocusNode,
                                      lengthFocusNode: _lengthFocusNode,
                                      customCrackFocusNode: _customCrackFocusNode,
                                      customTypeFocusNode: _customTypeFocusNode,
                                      onCrackTypeChanged: (type) {
                                        setState(() {
                                          _crackType = type;
                                        });
                                      },
                                      onGenericTypeChanged: (type) {
                                        setState(() {
                                          _genericDefectType = type;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  _ToolPanel(
                    toolMode: _toolMode,
                    onModeChanged: (mode) {
                      setState(() {
                        _toolMode = mode;
                        if (_toolMode != ToolMode.defect) {
                          _showDefectPanel = false;
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.currentPage,
    required this.totalPages,
    required this.onPickPdf,
  });

  final int currentPage;
  final int totalPages;
  final VoidCallback onPickPdf;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            '시설 안전 점검',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(width: 12),
          Text(
            'Page $currentPage / $totalPages',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: onPickPdf,
            icon: const Icon(Icons.upload_file, size: 18),
            label: const Text('PDF 불러오기'),
          ),
        ],
      ),
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({
    required this.selectedCategory,
    required this.onChanged,
  });

  final DefectCategory selectedCategory;
  final ValueChanged<DefectCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          _CategoryChip(
            label: '균열',
            isSelected: selectedCategory == DefectCategory.crack,
            onTap: () => onChanged(DefectCategory.crack),
          ),
          _CategoryChip(
            label: '누수',
            isSelected: selectedCategory == DefectCategory.leak,
            onTap: () => onChanged(DefectCategory.leak),
          ),
          _CategoryChip(
            label: '콘크리트 결함',
            isSelected: selectedCategory == DefectCategory.concrete,
            onTap: () => onChanged(DefectCategory.concrete),
          ),
          _CategoryChip(
            label: '기타 결함',
            isSelected: selectedCategory == DefectCategory.other,
            onTap: () => onChanged(DefectCategory.other),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _BlueprintViewer extends StatelessWidget {
  const _BlueprintViewer({
    required this.controller,
    required this.pdfPath,
    required this.errorMessage,
    required this.onPageChanged,
  });

  final PdfControllerPinch? controller;
  final String? pdfPath;
  final String? errorMessage;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return Center(
        child: Text(
          errorMessage!,
          style: const TextStyle(color: Colors.redAccent),
        ),
      );
    }
    if (pdfPath == null || controller == null) {
      return Center(
        child: Text(
          'PDF를 불러오면 도면이 표시됩니다.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return PdfViewPinch(
      controller: controller!,
      onPageChanged: (page) => onPageChanged(page),
      builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
        options: const DefaultBuilderOptions(),
        documentLoaderBuilder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
        pageLoaderBuilder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorBuilder: (context, error) => Center(
          child: Text(
            'PDF 렌더링 실패: $error',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }
}

class _MarkerOverlay extends StatelessWidget {
  const _MarkerOverlay({
    required this.markers,
    required this.contentRect,
  });

  final List<Offset> markers;
  final Rect contentRect;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _MarkerPainter(markers: markers, contentRect: contentRect),
        size: Size.infinite,
      ),
    );
  }
}

class _MarkerPainter extends CustomPainter {
  _MarkerPainter({required this.markers, required this.contentRect});

  final List<Offset> markers;
  final Rect contentRect;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;
    for (final marker in markers) {
      final position = Offset(
        contentRect.left + marker.dx * contentRect.width,
        contentRect.top + marker.dy * contentRect.height,
      );
      canvas.drawCircle(position, 6, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MarkerPainter oldDelegate) {
    return !listEquals(oldDelegate.markers, markers) ||
        oldDelegate.contentRect != contentRect;
  }
}

class _ToolPanel extends StatelessWidget {
  const _ToolPanel({
    required this.toolMode,
    required this.onModeChanged,
  });

  final ToolMode toolMode;
  final ValueChanged<ToolMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 8),
          _ToolButton(
            label: '결함',
            icon: Icons.report,
            isSelected: toolMode == ToolMode.defect,
            onTap: () => onModeChanged(ToolMode.defect),
          ),
          _ToolButton(
            label: '장비',
            icon: Icons.precision_manufacturing,
            isSelected: toolMode == ToolMode.equipment,
            onTap: () => onModeChanged(ToolMode.equipment),
          ),
          _ToolButton(
            label: '자유
드로잉',
            icon: Icons.gesture,
            isSelected: toolMode == ToolMode.freeDraw,
            onTap: () => onModeChanged(ToolMode.freeDraw),
          ),
          _ToolButton(
            label: '지우개',
            icon: Icons.cleaning_services,
            isSelected: toolMode == ToolMode.eraser,
            onTap: () => onModeChanged(ToolMode.eraser),
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueGrey.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blueGrey : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: isSelected ? Colors.blueGrey : Colors.grey),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.blueGrey : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DefectDetailPanel extends StatelessWidget {
  const DefectDetailPanel({
    super.key,
    required this.category,
    required this.crackType,
    required this.genericDefectType,
    required this.widthController,
    required this.lengthController,
    required this.customCrackController,
    required this.customTypeController,
    required this.widthFocusNode,
    required this.lengthFocusNode,
    required this.customCrackFocusNode,
    required this.customTypeFocusNode,
    required this.onCrackTypeChanged,
    required this.onGenericTypeChanged,
  });

  final DefectCategory category;
  final CrackType crackType;
  final GenericDefectType genericDefectType;
  final TextEditingController widthController;
  final TextEditingController lengthController;
  final TextEditingController customCrackController;
  final TextEditingController customTypeController;
  final FocusNode widthFocusNode;
  final FocusNode lengthFocusNode;
  final FocusNode customCrackFocusNode;
  final FocusNode customTypeFocusNode;
  final ValueChanged<CrackType> onCrackTypeChanged;
  final ValueChanged<GenericDefectType> onGenericTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '결함 상세 입력',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (category == DefectCategory.crack)
                _CrackTypeSelector(
                  value: crackType,
                  onChanged: onCrackTypeChanged,
                )
              else
                _GenericTypeSelector(
                  value: genericDefectType,
                  onChanged: onGenericTypeChanged,
                ),
              if (category == DefectCategory.crack && crackType == CrackType.other)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextField(
                    controller: customCrackController,
                    focusNode: customCrackFocusNode,
                    decoration: const InputDecoration(
                      labelText: '기타 균열 입력',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              if (category != DefectCategory.crack &&
                  genericDefectType == GenericDefectType.other)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextField(
                    controller: customTypeController,
                    focusNode: customTypeFocusNode,
                    decoration: const InputDecoration(
                      labelText: '기타 유형 입력',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widthController,
                      focusNode: widthFocusNode,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '폭 (mm)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: lengthController,
                      focusNode: lengthFocusNode,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '길이 (mm)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '메모',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CrackTypeSelector extends StatelessWidget {
  const _CrackTypeSelector({required this.value, required this.onChanged});

  final CrackType value;
  final ValueChanged<CrackType> onChanged;

  String _labelFor(CrackType type) {
    switch (type) {
      case CrackType.vertical:
        return '수직 균열';
      case CrackType.horizontal:
        return '수평 균열';
      case CrackType.diagonal:
        return '사선 균열';
      case CrackType.verticalHorizontal:
        return '수직·수평 균열';
      case CrackType.map:
        return '망상 균열';
      case CrackType.other:
        return '기타';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<CrackType>(
      value: value,
      decoration: const InputDecoration(
        labelText: '균열 유형',
        border: OutlineInputBorder(),
      ),
      items: CrackType.values
          .map(
            (type) => DropdownMenuItem(
              value: type,
              child: Text(_labelFor(type)),
            ),
          )
          .toList(),
      onChanged: (type) {
        if (type != null) {
          onChanged(type);
        }
      },
    );
  }
}

class _GenericTypeSelector extends StatelessWidget {
  const _GenericTypeSelector({required this.value, required this.onChanged});

  final GenericDefectType value;
  final ValueChanged<GenericDefectType> onChanged;

  String _labelFor(GenericDefectType type) {
    switch (type) {
      case GenericDefectType.surface:
        return '표면 결함';
      case GenericDefectType.penetration:
        return '관통 결함';
      case GenericDefectType.other:
        return '기타';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<GenericDefectType>(
      value: value,
      decoration: const InputDecoration(
        labelText: '결함 유형',
        border: OutlineInputBorder(),
      ),
      items: GenericDefectType.values
          .map(
            (type) => DropdownMenuItem(
              value: type,
              child: Text(_labelFor(type)),
            ),
          )
          .toList(),
      onChanged: (type) {
        if (type != null) {
          onChanged(type);
        }
      },
    );
  }
}
