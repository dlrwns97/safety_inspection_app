import 'dart:io';

import 'package:safety_inspection_app/domain/inspection/repositories/photo_repository.dart';
import 'package:safety_inspection_app/screens/drawing/attachments/defect_photo_store.dart';

class DefectPhotoRepository implements PhotoRepository {
  DefectPhotoRepository({DefectPhotoStore? store})
    : _store = store ?? DefectPhotoStore();

  final DefectPhotoStore _store;

  @override
  Future<List<String>> saveDefectPhotos({
    required String siteId,
    required String defectId,
    required List<String> sourcePaths,
    List<String>? originalNames,
  }) {
    return _store.savePickedImages(
      siteId: siteId,
      defectId: defectId,
      sourcePaths: sourcePaths,
      originalNames: originalNames,
    );
  }

  @override
  Future<String?> loadOriginalNameForStoredPath(String storedPhotoPath) {
    return _store.readOriginalNameForStoredPath(storedPhotoPath);
  }

  @override
  Future<void> deleteStoredPhoto(String storedPhotoPath) async {
    final photoFile = File(storedPhotoPath);
    if (await photoFile.exists()) {
      await photoFile.delete();
    }

    final sidecarFile = File(_store.sidecarPathFor(storedPhotoPath));
    if (await sidecarFile.exists()) {
      await sidecarFile.delete();
    }
  }
}
