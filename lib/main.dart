import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

void main() {
  runApp(const SafetyInspectionApp());
}

class SafetyInspectionApp extends StatelessWidget {
  const SafetyInspectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safety Inspection',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const InspectionHomePage(),
    );
  }
}

enum DefectCategory {
  crack('균열'),
  leak('누수'),
  concrete('콘크리트 결함'),
  etc('기타 결함');

  const DefectCategory(this.label);

  final String label;
}

class DefectSchema {
  const DefectSchema({required this.types, required this.causes});

  final List<String> types;
  final List<String> causes;
}

const Map<DefectCategory, DefectSchema> defectSchemas = {
  DefectCategory.crack: DefectSchema(
    types: [
      '수직 균열',
      '수평 균열',
      '사선 균열',
      '수직·수평 균열',
      '망상 균열',
      '기타',
    ],
    causes: [
      '건조 수축',
      '우각부 균열',
      '접합부 균열',
      '하중 및 응력 집중',
      '기타',
    ],
  ),
  DefectCategory.leak: DefectSchema(
    types: ['누수 흔적', '누수 균열', '누수 진행중', '기타'],
    causes: ['우수 유입 추정', '배관 누수 추정', '균열부 우수 침투', '기타'],
  ),
  DefectCategory.concrete: DefectSchema(
    types: ['콘크리트 박락', '콘크리트 박리', '철근 노출', '기타'],
    causes: ['외력에 의한 손상 추정', '시공 오차', '화학적 반응', '기타'],
  ),
  DefectCategory.etc: DefectSchema(
    types: ['마감재 들뜸', '마감재 탈락', '기타'],
    causes: ['노후화', '외력에 의한 손상 추정', '기타'],
  ),
};

class DefectMarker {
  DefectMarker({required this.position, required this.category});

  final Offset position;
  final DefectCategory category;
}

class InspectionHomePage extends StatefulWidget {
  const InspectionHomePage({super.key});

  @override
  State<InspectionHomePage> createState() => _InspectionHomePageState();
}

class _InspectionHomePageState extends State<InspectionHomePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  DefectCategory _selectedCategory = DefectCategory.crack;
  final List<DefectMarker> _markers = [];
  bool _isDialogOpen = false;

  PdfControllerPinch? _pdfController;
  String? _pdfPath;
  int _pageNumber = 1;
  int _pageCount = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: DefectCategory.values.length, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _pdfController?.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      return;
    }
    setState(() {
      _selectedCategory = DefectCategory.values[_tabController.index];
    });
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    final filePath = result?.files.single.path;
    if (filePath == null) {
      return;
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final fileName = result?.files.single.name ?? 'inspection.pdf';
    final savedPath = '${docsDir.path}/$fileName';
    final savedFile = await File(filePath).copy(savedPath);

    _pdfController?.dispose();
    setState(() {
      _pdfPath = savedFile.path;
      _pdfController = PdfControllerPinch(
        document: PdfDocument.openFile(savedFile.path),
        initialPage: 1,
      );
      _pageNumber = 1;
      _pageCount = 1;
    });
  }

  Future<void> _openDefectDialog(Offset position) async {
    setState(() {
      _isDialogOpen = true;
      _markers.add(DefectMarker(position: position, category: _selectedCategory));
    });

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return DefectDetailDialog(category: _selectedCategory);
      },
    );

    if (!mounted) {
      return;
    }
    setState(() {
      _isDialogOpen = false;
    });
  }

  void _goToPreviousPage() {
    _pdfController?.previousPage(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  void _goToNextPage() {
    _pdfController?.nextPage(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('안전 점검 도면'),
        bottom: TabBar(
          controller: _tabController,
          tabs: DefectCategory.values
              .map((category) => Tab(text: category.label))
              .toList(),
        ),
        actions: [
          IconButton(
            onPressed: _pickPdf,
            tooltip: 'PDF 불러오기',
            icon: const Icon(Icons.picture_as_pdf),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: IgnorePointer(
              ignoring: _isDialogOpen,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (details) {
                          final localPosition = details.localPosition;
                          final normalized = Offset(
                            localPosition.dx / constraints.maxWidth,
                            localPosition.dy / constraints.maxHeight,
                          );
                          _openDefectDialog(normalized);
                        },
                        child: Container(
                          color: Colors.grey.shade200,
                          child: _pdfController == null
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('PDF 도면을 선택해주세요.'),
                                      const SizedBox(height: 12),
                                      ElevatedButton.icon(
                                        onPressed: _pickPdf,
                                        icon: const Icon(Icons.upload_file),
                                        label: const Text('PDF 불러오기'),
                                      ),
                                    ],
                                  ),
                                )
                              : PdfViewPinch(
                                  controller: _pdfController!,
                                  onDocumentLoaded: (document) {
                                    setState(() {
                                      _pageCount = document.pagesCount;
                                    });
                                  },
                                  onPageChanged: (page) {
                                    setState(() {
                                      _pageNumber = page;
                                    });
                                  },
                                ),
                        ),
                      ),
                      for (final marker in _markers)
                        Positioned(
                          left: marker.position.dx * constraints.maxWidth - 8,
                          top: marker.position.dy * constraints.maxHeight - 8,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _pdfController == null ? null : _goToPreviousPage,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('$_pageNumber / $_pageCount'),
                IconButton(
                  onPressed: _pdfController == null ? null : _goToNextPage,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DefectDetailDialog extends StatefulWidget {
  const DefectDetailDialog({super.key, required this.category});

  final DefectCategory category;

  @override
  State<DefectDetailDialog> createState() => _DefectDetailDialogState();
}

class _DefectDetailDialogState extends State<DefectDetailDialog> {
  final List<String> _components = ['벽체', '슬래브', '보', '기둥', '기타'];

  late final TextEditingController _widthController;
  late final TextEditingController _lengthController;
  late final TextEditingController _otherTypeController;
  late final TextEditingController _otherCauseController;
  late final FocusNode _widthFocus;
  late final FocusNode _lengthFocus;
  late final FocusNode _otherTypeFocus;
  late final FocusNode _otherCauseFocus;

  String? _selectedComponent;
  String? _selectedType;
  String? _selectedCause;

  @override
  void initState() {
    super.initState();
    _widthController = TextEditingController();
    _lengthController = TextEditingController();
    _otherTypeController = TextEditingController();
    _otherCauseController = TextEditingController();
    _widthFocus = FocusNode();
    _lengthFocus = FocusNode();
    _otherTypeFocus = FocusNode();
    _otherCauseFocus = FocusNode();
  }

  @override
  void dispose() {
    _widthController.dispose();
    _lengthController.dispose();
    _otherTypeController.dispose();
    _otherCauseController.dispose();
    _widthFocus.dispose();
    _lengthFocus.dispose();
    _otherTypeFocus.dispose();
    _otherCauseFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final schema = defectSchemas[widget.category]!;
    final showOtherType = _selectedType == '기타';
    final showOtherCause = _selectedCause == '기타';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '결함 상세 입력 - ${widget.category.label}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedComponent,
              items: _components
                  .map((component) => DropdownMenuItem(
                        value: component,
                        child: Text(component),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedComponent = value;
                });
              },
              decoration: const InputDecoration(
                labelText: '부재 선택',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedType,
              items: schema.types
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value;
                  if (_selectedType != '기타') {
                    _otherTypeController.clear();
                  }
                });
              },
              decoration: const InputDecoration(
                labelText: '유형',
                border: OutlineInputBorder(),
              ),
            ),
            if (showOtherType) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _otherTypeController,
                focusNode: _otherTypeFocus,
                decoration: const InputDecoration(
                  labelText: '유형 기타 입력',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _widthController,
              focusNode: _widthFocus,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '폭(mm)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lengthController,
              focusNode: _lengthFocus,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '길이(mm)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCause,
              items: schema.causes
                  .map((cause) => DropdownMenuItem(
                        value: cause,
                        child: Text(cause),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCause = value;
                  if (_selectedCause != '기타') {
                    _otherCauseController.clear();
                  }
                });
              },
              decoration: const InputDecoration(
                labelText: '원인',
                border: OutlineInputBorder(),
              ),
            ),
            if (showOtherCause) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _otherCauseController,
                focusNode: _otherCauseFocus,
                decoration: const InputDecoration(
                  labelText: '원인 기타 입력',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('닫기'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('저장'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
