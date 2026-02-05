import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:safety_inspection_app/constants/strings_ko.dart';
import 'package:safety_inspection_app/models/defect.dart';
import 'package:safety_inspection_app/models/defect_details.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/site.dart';
import 'package:safety_inspection_app/screens/drawing/attachments/defect_photo_store.dart';
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
                      site: site,
                      siteId: site.id,
                      onSiteUpdated: _updateSite,
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

extension DefectDetailsCopyWith on DefectDetails {
  DefectDetails copyWith({
    String? structuralMember,
    String? crackType,
    double? widthMm,
    double? lengthMm,
    String? cause,
    List<String>? photoPaths,
    Map<String, String>? photoOriginalNamesByPath,
  }) {
    return DefectDetails(
      structuralMember: structuralMember ?? this.structuralMember,
      crackType: crackType ?? this.crackType,
      widthMm: widthMm ?? this.widthMm,
      lengthMm: lengthMm ?? this.lengthMm,
      cause: cause ?? this.cause,
      photoPaths: photoPaths ?? List<String>.from(this.photoPaths),
      photoOriginalNamesByPath:
          photoOriginalNamesByPath ??
          Map<String, String>.from(this.photoOriginalNamesByPath),
    );
  }
}

extension DefectCopyWith on Defect {
  Defect copyWith({
    String? id,
    String? label,
    int? pageIndex,
    DefectCategory? category,
    double? normalizedX,
    double? normalizedY,
    DefectDetails? details,
  }) {
    return Defect(
      id: id ?? this.id,
      label: label ?? this.label,
      pageIndex: pageIndex ?? this.pageIndex,
      category: category ?? this.category,
      normalizedX: normalizedX ?? this.normalizedX,
      normalizedY: normalizedY ?? this.normalizedY,
      details: details ?? this.details,
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

bool _isAllowedImagePath(String path) {
  const allowedExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.heic',
    '.heif',
  };
  final extension = p.extension(path).toLowerCase();
  return allowedExtensions.contains(extension);
}

class _OrphanScanResultList extends StatefulWidget {
  const _OrphanScanResultList({
    required this.result,
    required this.site,
    required this.siteId,
    required this.onSiteUpdated,
  });

  final OrphanScanResult result;
  final Site site;
  final String siteId;
  final Future<void> Function(Site site) onSiteUpdated;

  @override
  State<_OrphanScanResultList> createState() => _OrphanScanResultListState();
}

class _OrphanScanResultListState extends State<_OrphanScanResultList> {
  late List<FileSystemEntity> _orphanFiles;
  late Site _currentSite;
  final Map<String, String> _originalNameByStoredPath = {};
  bool _isCleaning = false;

  @override
  void initState() {
    super.initState();
    _currentSite = widget.site;
    _orphanFiles = List<FileSystemEntity>.from(widget.result.orphanFiles);
    _loadOriginalNamesForOrphans();
  }

  @override
  void didUpdateWidget(covariant _OrphanScanResultList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.site != widget.site) {
      _currentSite = widget.site;
    }
  }

  Future<void> _loadOriginalNamesForOrphans() async {
    final store = DefectPhotoStore();
    final displayedFiles = _orphanFiles.take(20).toList();
    final updates = <String, String>{};
    for (final entity in displayedFiles) {
      final storedPath = entity.path;
      if (_originalNameByStoredPath.containsKey(storedPath)) {
        continue;
      }
      final originalName = await store.readOriginalNameForStoredPath(
        storedPath,
      );
      if (originalName != null) {
        updates[storedPath] = originalName;
      }
    }
    if (updates.isEmpty || !mounted) {
      return;
    }
    setState(() {
      _originalNameByStoredPath.addAll(updates);
    });
  }

  Future<void> _confirmBulkCleanup() async {
    final count = _orphanFiles.length;
    if (count == 0) {
      return;
    }
    final shouldClean = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('미사용 파일 정리'),
        content: Text(
          '총 $count개 파일을 정리합니다.\n'
          '앱이 저장한 미사용 사진 파일만 삭제됩니다. 갤러리/원본 파일은 삭제되지 않습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    if (shouldClean != true || !mounted) {
      return;
    }
    await _bulkCleanup();
  }

  Future<void> _confirmRestore(FileSystemEntity entity) async {
    if (!_isAllowedImagePath(entity.path)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('복구할 수 없는 파일입니다.')),
        );
      }
      return;
    }
    final defectId = extractDefectIdFromPath(
      entity: entity,
      siteId: widget.siteId,
    );
    if (defectId == null) {
      return;
    }
    final restoredSite = await _restoreOrphanFile(
      entity: entity,
      defectId: defectId,
    );
    if (restoredSite == null) {
      return;
    }
    await widget.onSiteUpdated(restoredSite);
    _currentSite = restoredSite;
    if (!mounted) {
      return;
    }
    setState(() {
      _orphanFiles = _orphanFiles
          .where((existing) => existing.path != entity.path)
          .toList();
    });
    _loadOriginalNamesForOrphans();
  }

  Future<void> _bulkCleanup() async {
    setState(() {
      _isCleaning = true;
    });
    final storeRoot = await DefectPhotoStore().getRootDirectory();
    final normalizedRoot = p.normalize(p.absolute(storeRoot.path));
    final rootWithSeparator = normalizedRoot.endsWith(p.separator)
        ? normalizedRoot
        : '$normalizedRoot${p.separator}';
    final allowedImageExtensions = {
      '.jpg',
      '.jpeg',
      '.png',
      '.webp',
      '.heic',
      '.heif',
    };

    bool isPathInsideRoot(String targetPath) {
      final candidate = p.normalize(p.absolute(targetPath));
      return candidate == normalizedRoot ||
          candidate.startsWith(rootWithSeparator);
    }

    var skippedCount = 0;
    final deletedPaths = <String>{};

    for (final entity in _orphanFiles) {
      final filePath = entity.path;
      if (!isPathInsideRoot(filePath)) {
        skippedCount += 1;
        continue;
      }
      final extension = p.extension(filePath).toLowerCase();
      if (!allowedImageExtensions.contains(extension)) {
        continue;
      }
      final stat = await entity.stat();
      if (stat.type != FileSystemEntityType.file) {
        continue;
      }
      final file = File(filePath);
      final exists = await file.exists();
      if (!exists) {
        continue;
      }
      try {
        await file.delete();
        deletedPaths.add(filePath);
        final sidecarPath = p.join(
          p.dirname(filePath),
          '${p.basenameWithoutExtension(filePath)}.json',
        );
        if (isPathInsideRoot(sidecarPath)) {
          final sidecarFile = File(sidecarPath);
          try {
            if (await sidecarFile.exists()) {
              await sidecarFile.delete();
            }
          } catch (_) {
            // Best effort sidecar cleanup.
          }
        }
      } catch (_) {
        continue;
      }
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _orphanFiles = _orphanFiles
          .where((entity) => !deletedPaths.contains(entity.path))
          .toList();
      _isCleaning = false;
    });
    _loadOriginalNamesForOrphans();
    final deletedCount = deletedPaths.length;
    final snackBarMessage = skippedCount > 0
        ? '$deletedCount개 정리 완료, $skippedCount개는 안전상 건너뜀'
        : '$deletedCount개 정리 완료';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(snackBarMessage)),
    );
  }

  Future<Site?> _restoreOrphanFile({
    required FileSystemEntity entity,
    required String defectId,
  }) async {
    final defectIndex = _currentSite.defects.indexWhere(
      (defect) => defect.id == defectId,
    );
    if (defectIndex == -1) {
      return null;
    }
    final defect = _currentSite.defects[defectIndex];
    final storedPath = entity.path;
    final restoreKey = photoReferenceKey(storedPath);
    final photoPaths = List<String>.from(defect.details.photoPaths);
    _insertPreservingKeyOrder(photoPaths, restoreKey);
    final photoOriginalNamesByPath = Map<String, String>.from(
      defect.details.photoOriginalNamesByPath,
    );
    final originalName = _originalNameByStoredPath[storedPath];
    if (originalName != null && originalName.trim().isNotEmpty) {
      photoOriginalNamesByPath[storedPath] = originalName;
    }
    final updatedDetails = defect.details.copyWith(
      photoPaths: photoPaths,
      photoOriginalNamesByPath: photoOriginalNamesByPath,
    );
    final updatedDefect = defect.copyWith(details: updatedDetails);
    final updatedDefects = List<Defect>.from(_currentSite.defects);
    updatedDefects[defectIndex] = updatedDefect;
    return _currentSite.copyWith(defects: updatedDefects);
  }

  void _insertPreservingKeyOrder(List<String> photoPaths, String restoreKey) {
    for (var i = 0; i < photoPaths.length; i += 1) {
      final existingKey = photoReferenceKey(photoPaths[i]);
      if (existingKey == restoreKey) {
        return;
      }
      if (restoreKey.compareTo(existingKey) < 0) {
        photoPaths.insert(i, restoreKey);
        return;
      }
    }
    photoPaths.add(restoreKey);
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = _orphanFiles.length;
    final displayedFiles = _orphanFiles.take(20).toList();
    return SizedBox(
      width: double.maxFinite,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 360),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('미사용 파일 ${totalCount}개'),
            const SizedBox(height: 4),
            const Text('현재 현장 데이터에서 참조되지 않는 사진입니다.'),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _isCleaning ? null : _confirmBulkCleanup,
                icon: const Icon(Icons.delete_outline),
                label: const Text('미사용 파일 정리'),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: displayedFiles.isEmpty
                  ? const Center(child: Text('표시할 파일이 없습니다.'))
                  : ListView.separated(
                      itemCount: displayedFiles.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final entity = displayedFiles[index];
                        final defectId = extractDefectIdFromPath(
                          entity: entity,
                          siteId: widget.siteId,
                        );
                        final originalName =
                            _originalNameByStoredPath[entity.path];
                        final fileName = originalName != null
                            ? p.basenameWithoutExtension(originalName)
                            : extractOrphanFileName(entity);
                        return ListTile(
                          dense: true,
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  fileName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed:
                                    _isCleaning
                                        ? null
                                        : () => _confirmRestore(entity),
                                child: const Text('복구'),
                              ),
                            ],
                          ),
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
      ),
    );
  }
}
