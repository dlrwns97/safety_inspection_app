import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DefectPhotoStore {
  Future<Directory> getRootDirectory() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    return Directory('${documentsDir.path}/sites');
  }

  Future<List<String>> savePickedImages({
    required String siteId,
    required String defectId,
    required List<String> sourcePaths,
  }) async {
    if (sourcePaths.isEmpty) {
      return [];
    }

    final documentsDir = await getApplicationDocumentsDirectory();
    final targetDir = Directory(
      '${documentsDir.path}/sites/$siteId/defects/$defectId',
    );
    await targetDir.create(recursive: true);
    final timestamp = _formatTimestamp(DateTime.now());
    final savedPaths = <String>[];

    for (var index = 0; index < sourcePaths.length; index++) {
      final sourcePath = sourcePaths[index];
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        continue;
      }
      final extension = _resolveExtension(sourcePath);
      final destinationPath =
          '${targetDir.path}/${timestamp}_$index$extension';
      try {
        await sourceFile.copy(destinationPath);
        savedPaths.add(destinationPath);
      } catch (_) {
        continue;
      }
      await _writeSidecarMetadata(
        destinationPath: destinationPath,
        originalName: p.basename(sourcePath),
      );
    }

    return savedPaths;
  }

  String sidecarPathFor(String storedPhotoPath) {
    return p.setExtension(storedPhotoPath, '.json');
  }

  Future<String?> readOriginalNameForStoredPath(
    String storedPhotoPath,
  ) async {
    final sidecarPath = sidecarPathFor(storedPhotoPath);
    final sidecarFile = File(sidecarPath);
    if (!await sidecarFile.exists()) {
      return null;
    }
    try {
      final content = await sidecarFile.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final originalName = decoded['originalName'];
      if (originalName is! String) {
        return null;
      }
      final trimmed = originalName.trim();
      return trimmed.isEmpty ? null : trimmed;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeSidecarMetadata({
    required String destinationPath,
    required String originalName,
  }) async {
    final trimmed = originalName.trim();
    if (trimmed.isEmpty) {
      return;
    }
    try {
      final sidecarFile = File(sidecarPathFor(destinationPath));
      await sidecarFile.writeAsString(
        jsonEncode({'originalName': trimmed}),
        flush: true,
      );
    } catch (_) {}
  }

  String _formatTimestamp(DateTime dateTime) {
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    return '$year$month$day-$hour$minute$second';
  }

  String _resolveExtension(String sourcePath) {
    final sanitizedPath = sourcePath.replaceAll('\\', '/');
    final lastSeparator = sanitizedPath.lastIndexOf('/');
    final lastDot = sanitizedPath.lastIndexOf('.');
    if (lastDot == -1 || lastDot < lastSeparator) {
      return '.jpg';
    }
    final extension = sanitizedPath.substring(lastDot);
    return extension.isEmpty ? '.jpg' : extension;
  }
}
