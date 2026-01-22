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
              title: const Text(StringsKo.newSite),
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
