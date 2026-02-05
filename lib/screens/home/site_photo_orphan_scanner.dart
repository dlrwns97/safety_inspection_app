import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:safety_inspection_app/models/site.dart';

class OrphanScanResult {
  OrphanScanResult({required this.orphanFiles, required this.totalCount});

  final List<FileSystemEntity> orphanFiles;
  final int totalCount;

  factory OrphanScanResult.empty() {
    return OrphanScanResult(orphanFiles: [], totalCount: 0);
  }
}

Future<OrphanScanResult> scanOrphanDefectPhotos({
  required String siteId,
  required Site site,
}) async {
  try {
    final usedPaths = <String>{};
    for (final defect in site.defects) {
      for (final path in defect.details.photoPaths) {
        if (path.isEmpty) {
          continue;
        }
        usedPaths.add(photoReferenceKey(path));
      }
    }

    final documentsDir = await getApplicationDocumentsDirectory();
    final defectsDir = Directory('${documentsDir.path}/sites/$siteId/defects');
    if (!await defectsDir.exists()) {
      return OrphanScanResult.empty();
    }

    final entities = await defectsDir
        .list(recursive: true, followLinks: false)
        .toList();
    final orphanFiles = <FileSystemEntity>[];
    for (final entity in entities) {
      if (entity is! File) {
        continue;
      }
      final normalizedPath = photoReferenceKey(entity.path);
      if (!usedPaths.contains(normalizedPath)) {
        orphanFiles.add(entity);
      }
    }

    return OrphanScanResult(
      orphanFiles: orphanFiles,
      totalCount: orphanFiles.length,
    );
  } catch (error) {
    return OrphanScanResult.empty();
  }
}

String photoReferenceKey(String path) {
  return p.normalize(path).replaceAll('\\', '/');
}

String extractOrphanFileName(FileSystemEntity entity) {
  final normalized = photoReferenceKey(entity.path);
  return p.basenameWithoutExtension(normalized);
}

String? extractDefectIdFromPath({
  required FileSystemEntity entity,
  required String siteId,
}) {
  final normalized = photoReferenceKey(entity.path);
  final marker = '/sites/$siteId/defects/';
  final index = normalized.indexOf(marker);
  if (index == -1) {
    return null;
  }
  final remainder = normalized.substring(index + marker.length);
  final segments = remainder.split('/');
  if (segments.length < 2) {
    return null;
  }
  return segments.first;
}
