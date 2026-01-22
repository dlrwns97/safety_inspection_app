import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../constants/strings_ko.dart';
import '../models/drawing_enums.dart';
import '../models/site.dart';
import '../models/site_storage.dart';
import 'drawing/drawing_screen.dart';

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
    final details = await _promptSiteDetails();
    if (!mounted || details == null) {
      return;
    }
    final selection = await _selectDrawingType();
    if (!mounted || selection == null) {
      return;
    }

    final inspectionDate = DateTime.now();
    final site = Site(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: details.name,
      createdAt: DateTime.now(),
      drawingType: selection.type,
      structureType: details.structureType,
      inspectionType: details.inspectionType,
      inspectionDate: inspectionDate,
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

  Future<void> _deleteSite(Site site) async {
    final updatedSites =
        _sites.where((existing) => existing.id != site.id).toList();
    await SiteStorage.saveSites(updatedSites);
    if (!mounted) {
      return;
    }
    setState(() {
      _sites = updatedSites;
    });
  }

  Future<void> _confirmDeleteSite(Site site) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(StringsKo.deleteSiteTitle),
          content: Text(
            '‘${site.name}’ 현장을 삭제할까요? (삭제하면 복구할 수 없습니다.)',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(StringsKo.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(StringsKo.delete),
            ),
          ],
        );
      },
    );

    if (!mounted || shouldDelete != true) {
      return;
    }

    await _deleteSite(site);
  }

  Future<_SiteDetails?> _promptSiteDetails() async {
    final controller = TextEditingController();
    String? nameErrorText;
    String? structureErrorText;
    String? inspectionErrorText;
    String? selectedStructureType;
    String? selectedInspectionType;
    return showDialog<_SiteDetails>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(StringsKo.newSite),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: StringsKo.siteNameLabel,
                      errorText: nameErrorText,
                    ),
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedStructureType,
                    decoration: InputDecoration(
                      labelText: StringsKo.structureTypeLabel,
                      errorText: structureErrorText,
                    ),
                    items: StringsKo.structureTypes
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedStructureType = value;
                        structureErrorText = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedInspectionType,
                    decoration: InputDecoration(
                      labelText: StringsKo.inspectionTypeLabel,
                      errorText: inspectionErrorText,
                    ),
                    items: StringsKo.inspectionTypes
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedInspectionType = value;
                        inspectionErrorText = null;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(StringsKo.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    final name = controller.text.trim();
                    final hasName = name.isNotEmpty;
                    final hasStructure = selectedStructureType != null;
                    final hasInspection = selectedInspectionType != null;
                    if (!hasName || !hasStructure || !hasInspection) {
                      setState(() {
                        nameErrorText =
                            hasName ? null : StringsKo.siteNameRequired;
                        structureErrorText =
                            hasStructure ? null : StringsKo.structureTypeRequired;
                        inspectionErrorText = hasInspection
                            ? null
                            : StringsKo.inspectionTypeRequired;
                      });
                      return;
                    }
                    Navigator.of(context).pop(
                      _SiteDetails(
                        name: name,
                        structureType: selectedStructureType!,
                        inspectionType: selectedInspectionType!,
                      ),
                    );
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
                    withData: true,
                  );
                  if (result == null || result.files.isEmpty) {
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                    return;
                  }
                  final file = result.files.first;
                  String? pdfPath = file.path;
                  if (pdfPath == null && file.bytes != null) {
                    final savedPath = await _persistPickedPdf(file);
                    pdfPath = savedPath;
                  }
                  if (context.mounted) {
                    Navigator.of(context).pop(
                      _DrawingSelection(
                        type: DrawingType.pdf,
                        path: pdfPath,
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
                  ).pop(const _DrawingSelection(type: DrawingType.blank));
                },
              ),
            ],
          ),
        );
      },
    );
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

  String _formatInspectionDate(DateTime? date) {
    if (date == null) {
      return StringsKo.noInspectionDateLabel;
    }
    final localDate = date.toLocal();
    final year = localDate.year.toString().padLeft(4, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final day = localDate.day.toString().padLeft(2, '0');
    return '$year.$month.$day';
  }

  String _formatSiteSubtitle(Site site) {
    final dateText = _formatInspectionDate(site.inspectionDate);
    final structureType = site.structureType ?? StringsKo.unsetLabel;
    final inspectionType = site.inspectionType ?? StringsKo.unsetLabel;
    return '$dateText · $structureType · $inspectionType';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(StringsKo.homeTitle)),
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
                          StringsKo.noSitesSubtitle,
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
                          color:
                              Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                      ),
                      title: Text(site.name),
                      subtitle: Text(_formatSiteSubtitle(site)),
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
                      onLongPress: () => _confirmDeleteSite(site),
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

class _SiteDetails {
  const _SiteDetails({
    required this.name,
    required this.structureType,
    required this.inspectionType,
  });

  final String name;
  final String structureType;
  final String inspectionType;
}
