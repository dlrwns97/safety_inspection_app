import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:safety_inspection_app/constants/strings_ko.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/site.dart';
import 'package:safety_inspection_app/screens/drawing/drawing_screen.dart';
import 'package:safety_inspection_app/screens/home/dialogs/new_site_dialog.dart';
import 'package:safety_inspection_app/screens/home/dialogs/site_trash_dialogs.dart';
import 'package:safety_inspection_app/screens/home/home_storage.dart';
import 'package:safety_inspection_app/screens/home/site_photo_orphan_scanner.dart';
import 'package:safety_inspection_app/screens/home/trash_screen.dart';
import 'package:safety_inspection_app/screens/home/widgets/home_overflow_menu.dart';
import 'package:safety_inspection_app/screens/home/widgets/site_list_tile.dart';

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
    final sites = await HomeStorage.loadSites();
    setState(() {
      _sites = sites;
      _isLoading = false;
    });
  }

  Future<void> _createSiteFlow() async {
    final details = await showNewSiteDialog(context);
    if (!mounted || details == null) {
      return;
    }
    final selection = await _selectDrawingType();
    if (!mounted || selection == null) {
      return;
    }

    final now = DateTime.now();
    final site = details.copyWith(
      id: now.millisecondsSinceEpoch.toString(),
      createdAt: now,
      drawingType: selection.type,
      inspectionDate: now,
      pdfPath: selection.path,
      pdfName: selection.fileName,
    );

    final updatedSites = [..._sites, site];
    await HomeStorage.saveSites(updatedSites);
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
    final updatedSites = await HomeStorage.updateSite(_sites, site);
    if (!mounted) {
      return;
    }
    setState(() {
      _sites = updatedSites;
    });
  }

  Future<void> _moveSiteToTrash(Site site) async {
    final updatedSites = await HomeStorage.moveSiteToTrash(
      _sites,
      site,
      DateTime.now(),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _sites = updatedSites;
    });
  }

  Future<void> _confirmDeleteSite(Site site) async {
    final shouldDelete = await showMoveToTrashConfirm(context, site: site);
    if (!mounted || !shouldDelete) {
      return;
    }

    await _moveSiteToTrash(site);
  }

  Future<void> _openTrash() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const TrashScreen()));
    if (!mounted) {
      return;
    }
    await _loadSites();
  }

  Future<void> _showOrphanPhotoScanDialog(Site site) async {
    final scanFuture = scanOrphanDefectPhotos(siteId: site.id, site: site);
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) {
        return FutureBuilder<OrphanScanResult>(
          future: scanFuture,
          builder: (context, snapshot) {
            final result = snapshot.data ?? OrphanScanResult.empty();
            final isLoading =
                snapshot.connectionState != ConnectionState.done;
            return AlertDialog(
              title: const Text('사진 정리'),
              content: isLoading
                  ? const SizedBox(
                      height: 72,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _OrphanScanResultList(
                      result: result,
                      siteId: site.id,
                    ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('닫기'),
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
    final activeSites = _sites.where((site) => !site.isDeleted).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text(StringsKo.homeTitle),
        actions: [
          HomeOverflowMenu(onTrashSelected: _openTrash),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : activeSites.isEmpty
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
                  itemCount: activeSites.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final site = activeSites[index];
                    return SiteListTile(
                      site: site,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PopupMenuButton<_SiteMenuAction>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (action) {
                              if (action ==
                                  _SiteMenuAction.scanOrphanPhotos) {
                                _showOrphanPhotoScanDialog(site);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: _SiteMenuAction.scanOrphanPhotos,
                                child: Text('사진 정리'),
                              ),
                            ],
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
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

enum _SiteMenuAction { scanOrphanPhotos }

class _OrphanScanResultList extends StatelessWidget {
  const _OrphanScanResultList({
    required this.result,
    required this.siteId,
  });

  final OrphanScanResult result;
  final String siteId;

  @override
  Widget build(BuildContext context) {
    final totalCount = result.totalCount;
    final displayedFiles = result.orphanFiles.take(20).toList();
    return SizedBox(
      width: double.maxFinite,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('고아 파일 ${totalCount}개'),
          const SizedBox(height: 12),
          if (displayedFiles.isEmpty)
            const Text('표시할 파일이 없습니다.')
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: displayedFiles.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final entity = displayedFiles[index];
                  final fileName = extractOrphanFileName(entity);
                  final defectId = extractDefectIdFromPath(
                    entity: entity,
                    siteId: siteId,
                  );
                  return ListTile(
                    dense: true,
                    title: Text(fileName),
                    subtitle: defectId == null
                        ? null
                        : Text('defectId: $defectId'),
                  );
                },
              ),
            ),
          if (totalCount > displayedFiles.length) ...[
            const SizedBox(height: 12),
            Text('외 ${totalCount - displayedFiles.length}개'),
          ],
        ],
      ),
    );
  }
}
