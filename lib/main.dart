import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants/strings_ko.dart';

void main() {
  runApp(const SafetyInspectionApp());
}

class SafetyInspectionApp extends StatelessWidget {
  const SafetyInspectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3A6EA5)),
      useMaterial3: true,
    );
    return MaterialApp(
      title: StringsKo.appTitle,
      theme: theme,
      home: const HomeScreen(),
    );
  }
}

enum DrawingType { pdf, blank }

enum DrawMode { defect, equipment, freeDraw, eraser }

enum DefectCategory {
  generalCrack('일반 균열'),
  waterLeakage('누수'),
  concreteSpalling('콘크리트 박락'),
  other('기타 결함');

  const DefectCategory(this.label);
  final String label;
}

class Site {
  Site({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.drawingType,
    this.pdfPath,
    this.pdfName,
    List<Defect>? defects,
  }) : defects = defects ?? [];

  final String id;
  final String name;
  final DateTime createdAt;
  final DrawingType drawingType;
  final String? pdfPath;
  final String? pdfName;
  final List<Defect> defects;

  Site copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DrawingType? drawingType,
    String? pdfPath,
    String? pdfName,
    List<Defect>? defects,
  }) {
    return Site(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      drawingType: drawingType ?? this.drawingType,
      pdfPath: pdfPath ?? this.pdfPath,
      pdfName: pdfName ?? this.pdfName,
      defects: defects ?? List<Defect>.from(this.defects),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'drawingType': drawingType.name,
    'pdfPath': pdfPath,
    'pdfName': pdfName,
    'defects': defects.map((defect) => defect.toJson()).toList(),
  };

  factory Site.fromJson(Map<String, dynamic> json) => Site(
    id: json['id'] as String,
    name: json['name'] as String,
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    drawingType: DrawingType.values.byName(
      json['drawingType'] as String? ?? 'blank',
    ),
    pdfPath: json['pdfPath'] as String?,
    pdfName: json['pdfName'] as String?,
    defects: (json['defects'] as List<dynamic>? ?? [])
        .map((item) => Defect.fromJson(item as Map<String, dynamic>))
        .toList(),
  );
}

class Defect {
  Defect({
    required this.id,
    required this.label,
    required this.pageIndex,
    required this.category,
    required this.normalizedX,
    required this.normalizedY,
    required this.details,
  });

  final String id;
  final String label;
  final int pageIndex;
  final DefectCategory category;
  final double normalizedX;
  final double normalizedY;
  final DefectDetails details;

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'pageIndex': pageIndex,
    'category': category.name,
    'normalizedX': normalizedX,
    'normalizedY': normalizedY,
    'details': details.toJson(),
  };

  factory Defect.fromJson(Map<String, dynamic> json) => Defect(
    id: json['id'] as String,
    label: json['label'] as String,
    pageIndex: json['pageIndex'] as int? ?? 0,
    category: DefectCategory.values.byName(
      json['category'] as String? ?? 'generalCrack',
    ),
    normalizedX: (json['normalizedX'] as num? ?? 0).toDouble(),
    normalizedY: (json['normalizedY'] as num? ?? 0).toDouble(),
    details: DefectDetails.fromJson(
      json['details'] as Map<String, dynamic>? ?? {},
    ),
  );
}

class DefectDetails {
  DefectDetails({
    required this.structuralMember,
    required this.crackType,
    required this.widthMm,
    required this.lengthMm,
    required this.cause,
  });

  final String structuralMember;
  final String crackType;
  final double widthMm;
  final double lengthMm;
  final String cause;

  Map<String, dynamic> toJson() => {
    'structuralMember': structuralMember,
    'crackType': crackType,
    'widthMm': widthMm,
    'lengthMm': lengthMm,
    'cause': cause,
  };

  factory DefectDetails.fromJson(Map<String, dynamic> json) => DefectDetails(
    structuralMember: json['structuralMember'] as String? ?? '',
    crackType: json['crackType'] as String? ?? '',
    widthMm: (json['widthMm'] as num? ?? 0).toDouble(),
    lengthMm: (json['lengthMm'] as num? ?? 0).toDouble(),
    cause: json['cause'] as String? ?? '',
  );
}

class SiteStorage {
  static const _key = 'inspection_sites';

  static Future<List<Site>> loadSites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => Site.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveSites(List<Site> sites) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(sites.map((site) => site.toJson()).toList());
    await prefs.setString(_key, encoded);
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Site> _sites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSites();
  }

  Future<void> _loadSites() async {
    final sites = await SiteStorage.loadSites();
    setState(() {
      _sites = sites;
      _isLoading = false;
    });
  }

  Future<void> _createSiteFlow() async {
    final name = await _promptSiteName();
    if (!mounted || name == null) {
      return;
    }
    final selection = await _selectDrawingType();
    if (!mounted || selection == null) {
      return;
    }

    final site = Site(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      createdAt: DateTime.now(),
      drawingType: selection.type,
      pdfPath: selection.path,
      pdfName: selection.fileName,
    );

    final updatedSites = [..._sites, site];
    await SiteStorage.saveSites(updatedSites);
    if (!mounted) {
      return;
    }
    setState(() {
      _sites = updatedSites;
    });

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            DrawingScreen(site: site, onSiteUpdated: _updateSite),
      ),
    );
  }

  Future<void> _updateSite(Site site) async {
    final updatedSites = _sites
        .map((existing) => existing.id == site.id ? site : existing)
        .toList();
    await SiteStorage.saveSites(updatedSites);
    if (!mounted) {
      return;
    }
    setState(() {
      _sites = updatedSites;
    });
  }

  Future<String?> _promptSiteName() async {
    final controller = TextEditingController();
    String? errorText;
    return showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(StringsKo.siteNameTitle),
              content: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: StringsKo.siteNameLabel,
                  errorText: errorText,
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  final value = controller.text.trim();
                  if (value.isEmpty) {
                    setState(() {
                      errorText = StringsKo.siteNameRequired;
                    });
                  } else {
                    Navigator.of(context).pop(value);
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(StringsKo.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    final value = controller.text.trim();
                    if (value.isEmpty) {
                      setState(() {
                        errorText = StringsKo.siteNameRequired;
                      });
                      return;
                    }
                    Navigator.of(context).pop(value);
                  },
                  child: const Text(StringsKo.create),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<_DrawingSelection?> _selectDrawingType() async {
    return showModalBottomSheet<_DrawingSelection>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: const Text(StringsKo.importPdfTitle),
                subtitle: const Text(StringsKo.importPdfSubtitle),
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf'],
                    withData: false,
                  );
                  if (result == null || result.files.isEmpty) {
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                    return;
                  }
                  final file = result.files.first;
                  if (context.mounted) {
                    Navigator.of(context).pop(
                      _DrawingSelection(
                        type: DrawingType.pdf,
                        path: file.path,
                        fileName: file.name,
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.grid_view_outlined),
                title: const Text(StringsKo.createBlankTitle),
                subtitle: const Text(StringsKo.createBlankSubtitle),
                onTap: () {
                  Navigator.of(
                    context,
                  ).pop(_DrawingSelection(type: DrawingType.blank));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(StringsKo.inspectionSitesTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sites.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 72,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      StringsKo.noSitesTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      StringsKo.noSitesDescription,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              itemCount: _sites.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final site = _sites[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.secondaryContainer,
                    child: Icon(
                      site.drawingType == DrawingType.pdf
                          ? Icons.picture_as_pdf
                          : Icons.edit_document,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                  title: Text(site.name),
                  subtitle: Text(
                    site.drawingType == DrawingType.pdf
                        ? (site.pdfName ?? StringsKo.pdfDrawingLabel)
                        : StringsKo.blankCanvasLabel,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => DrawingScreen(
                          site: site,
                          onSiteUpdated: _updateSite,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createSiteFlow,
        icon: const Icon(Icons.add),
        label: const Text(StringsKo.newSite),
      ),
    );
  }
}

class _DrawingSelection {
  const _DrawingSelection({required this.type, this.path, this.fileName});

  final DrawingType type;
  final String? path;
  final String? fileName;
}

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
                          value == null ? StringsKo.memberRequired : null,
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
                          value == null ? StringsKo.crackTypeRequired : null,
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
                                return StringsKo.widthRequired;
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
                                return StringsKo.lengthRequired;
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
                          value == null ? StringsKo.causeRequired : null,
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
              StringsKo.pinchToZoomHint,
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
        _ModeButton(
          icon: Icons.bug_report_outlined,
          label: StringsKo.modeDefect,
          isSelected: _mode == DrawMode.defect,
          onTap: () => setState(() => _mode = DrawMode.defect),
        ),
        const SizedBox(height: 12),
        _ModeButton(
          icon: Icons.construction_outlined,
          label: StringsKo.modeEquipment,
          isSelected: _mode == DrawMode.equipment,
          onTap: () => setState(() => _mode = DrawMode.equipment),
        ),
        const SizedBox(height: 12),
        _ModeButton(
          icon: Icons.brush_outlined,
          label: StringsKo.modeFreeDraw,
          isSelected: _mode == DrawMode.freeDraw,
          onTap: () => setState(() => _mode = DrawMode.freeDraw),
        ),
        const SizedBox(height: 12),
        _ModeButton(
          icon: Icons.auto_fix_off_outlined,
          label: StringsKo.modeEraser,
          isSelected: _mode == DrawMode.eraser,
          onTap: () => setState(() => _mode = DrawMode.eraser),
        ),
      ],
    );
  }

  Future<void> _selectDefectCategory() async {
    final selection = await showModalBottomSheet<DefectCategory>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  StringsKo.selectCategoryTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ...DefectCategory.values.map(
                (category) => ListTile(
                  title: Text(category.label),
                  onTap: () => Navigator.of(context).pop(category),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || selection == null) {
      return;
    }

    setState(() {
      _activeCategory = selection;
    });
  }

  Widget _buildDefectCategorySection() {
    if (_activeCategory == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              StringsKo.selectCategoryHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _selectDefectCategory,
              icon: const Icon(Icons.category_outlined),
              label: const Text(StringsKo.selectCategoryButton),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: _buildDefectCategories(),
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
    final pageLabel = StringsKo.pageLabel(_currentPage);

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
                    child: Text(StringsKo.pageDropdownLabel(pageNumber)),
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
          if (_mode == DrawMode.defect) _buildDefectCategorySection()
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
                  onTapDown:
                      _mode == DrawMode.defect && _activeCategory != null
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

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        InkResponse(
          onTap: onTap,
          radius: 28,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.primary
                  : colors.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? colors.primary : colors.outlineVariant,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
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
