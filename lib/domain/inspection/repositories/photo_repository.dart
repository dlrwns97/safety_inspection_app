/// Defect photo persistence boundary.
abstract interface class PhotoRepository {
  Future<List<String>> saveDefectPhotos({
    required String siteId,
    required String defectId,
    required List<String> sourcePaths,
    List<String>? originalNames,
  });

  Future<String?> loadOriginalNameForStoredPath(String storedPhotoPath);

  Future<void> deleteStoredPhoto(String storedPhotoPath);
}
