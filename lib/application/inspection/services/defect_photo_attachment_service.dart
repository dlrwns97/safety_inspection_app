import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:safety_inspection_app/domain/inspection/repositories/photo_repository.dart';

enum DefectPhotoInputSource { camera, gallery, file }

class DefectPhotoAttachmentResult {
  const DefectPhotoAttachmentResult({
    this.savedPaths = const <String>[],
    this.originalNamesBySavedPath = const <String, String>{},
    this.ignoredFileCount = 0,
    this.unsupportedOnlySelection = false,
  });

  final List<String> savedPaths;
  final Map<String, String> originalNamesBySavedPath;
  final int ignoredFileCount;
  final bool unsupportedOnlySelection;
}

typedef PickSingleCameraPhoto = Future<XFile?> Function();
typedef PickGalleryPhotos = Future<List<XFile>> Function();
typedef PickFiles =
    Future<FilePickerResult?> Function({required bool allowMultiple});

class DefectPhotoAttachmentService {
  DefectPhotoAttachmentService({
    required PhotoRepository photoRepository,
    PickSingleCameraPhoto? pickSingleCameraPhoto,
    PickGalleryPhotos? pickGalleryPhotos,
    PickFiles? pickFiles,
  }) : _photoRepository = photoRepository,
       _pickSingleCameraPhoto =
           pickSingleCameraPhoto ?? _defaultPickSingleCameraPhoto,
       _pickGalleryPhotos = pickGalleryPhotos ?? _defaultPickGalleryPhotos,
       _pickFiles = pickFiles ?? _defaultPickFiles;

  static const _allowedExtensions = <String>{
    'jpg',
    'jpeg',
    'png',
    'heic',
    'heif',
    'webp',
  };

  final PhotoRepository _photoRepository;
  final PickSingleCameraPhoto _pickSingleCameraPhoto;
  final PickGalleryPhotos _pickGalleryPhotos;
  final PickFiles _pickFiles;

  Future<DefectPhotoAttachmentResult> pickAndSave({
    required DefectPhotoInputSource source,
    required String siteId,
    required String defectId,
    required bool allowMultiple,
  }) async {
    final picked = await _pickPhotos(
      source: source,
      allowMultiple: allowMultiple,
    );
    if (picked.photos.isEmpty) {
      return DefectPhotoAttachmentResult(
        ignoredFileCount: picked.ignoredFileCount,
        unsupportedOnlySelection: picked.unsupportedOnlySelection,
      );
    }

    final sourcePaths = picked.photos.map((photo) => photo.path).toList();
    final originalNames = picked.photos
        .map((photo) => photo.originalName)
        .toList();
    final savedPaths = await _photoRepository.saveDefectPhotos(
      siteId: siteId,
      defectId: defectId,
      sourcePaths: sourcePaths,
      originalNames: originalNames,
    );

    final namesBySavedPath = <String, String>{};
    final count = savedPaths.length < originalNames.length
        ? savedPaths.length
        : originalNames.length;
    for (var i = 0; i < count; i += 1) {
      final savedPath = savedPaths[i];
      final originalName = originalNames[i].isNotEmpty
          ? originalNames[i]
          : p.basename(savedPath);
      namesBySavedPath[savedPath] = originalName;
    }

    return DefectPhotoAttachmentResult(
      savedPaths: savedPaths,
      originalNamesBySavedPath: namesBySavedPath,
      ignoredFileCount: picked.ignoredFileCount,
      unsupportedOnlySelection: picked.unsupportedOnlySelection,
    );
  }

  Future<_PickedPhotosResult> _pickPhotos({
    required DefectPhotoInputSource source,
    required bool allowMultiple,
  }) async {
    switch (source) {
      case DefectPhotoInputSource.camera:
        final picked = await _pickSingleCameraPhoto();
        if (picked == null) {
          return const _PickedPhotosResult(photos: <_PickedPhotoInfo>[]);
        }
        return _PickedPhotosResult(
          photos: <_PickedPhotoInfo>[
            _PickedPhotoInfo(
              path: picked.path,
              originalName: _resolveCameraName(picked),
            ),
          ],
        );
      case DefectPhotoInputSource.gallery:
        final files = await _pickGalleryPhotos();
        if (files.isEmpty) {
          return const _PickedPhotosResult(photos: <_PickedPhotoInfo>[]);
        }
        final picked = files.map((file) {
          final name = file.name.trim();
          return _PickedPhotoInfo(
            path: file.path,
            originalName: name.isNotEmpty ? name : p.basename(file.path),
          );
        }).toList();
        return _PickedPhotosResult(photos: picked);
      case DefectPhotoInputSource.file:
        final result = await _pickFiles(allowMultiple: allowMultiple);
        if (result == null) {
          return const _PickedPhotosResult(photos: <_PickedPhotoInfo>[]);
        }
        final selectedFiles = result.files
            .where((file) => file.path != null)
            .toList();
        final picked = selectedFiles
            .where((file) {
              final extension =
                  (file.extension ??
                          p.extension(file.name).replaceFirst('.', ''))
                      .toLowerCase();
              return _allowedExtensions.contains(extension);
            })
            .map((file) {
              return _PickedPhotoInfo(
                path: file.path!,
                originalName: file.name,
              );
            })
            .toList();
        final ignoredCount = selectedFiles.length - picked.length;
        return _PickedPhotosResult(
          photos: picked,
          ignoredFileCount: ignoredCount,
          unsupportedOnlySelection: selectedFiles.isNotEmpty && picked.isEmpty,
        );
    }
  }

  static Future<XFile?> _defaultPickSingleCameraPhoto() async {
    final picker = ImagePicker();
    return picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
  }

  static Future<List<XFile>> _defaultPickGalleryPhotos() async {
    final picker = ImagePicker();
    return picker.pickMultiImage();
  }

  static Future<FilePickerResult?> _defaultPickFiles({
    required bool allowMultiple,
  }) {
    return FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: allowMultiple,
    );
  }

  static String _resolveCameraName(XFile picked) {
    final pickedName = picked.name.trim();
    if (_isMeaningfulCameraFileName(pickedName)) {
      return pickedName;
    }
    final pathName = p.basename(picked.path).trim();
    if (_isMeaningfulCameraFileName(pathName)) {
      return pathName;
    }
    return _cameraFallbackName(picked.path);
  }

  static bool _isMeaningfulCameraFileName(String name) {
    if (name.isEmpty) {
      return false;
    }
    final extension = p.extension(name).toLowerCase();
    const allowedExtensions = {
      '.jpg',
      '.jpeg',
      '.png',
      '.webp',
      '.heic',
      '.heif',
    };
    if (!allowedExtensions.contains(extension)) {
      return false;
    }
    final lower = name.toLowerCase();
    const blockedPrefixes = {
      'image_picker',
      'scaled_',
      'cache_',
      'temp_',
      'tmp_',
    };
    if (blockedPrefixes.any(lower.startsWith)) {
      return false;
    }
    return !lower.contains('image_picker');
  }

  static String _cameraFallbackName(String sourcePath) {
    final now = DateTime.now();
    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    final extension = p.extension(sourcePath).isEmpty
        ? '.jpg'
        : p.extension(sourcePath);
    return '$year$month${day}_$hour$minute$second$extension';
  }
}

class _PickedPhotoInfo {
  const _PickedPhotoInfo({required this.path, required this.originalName});

  final String path;
  final String originalName;
}

class _PickedPhotosResult {
  const _PickedPhotosResult({
    required this.photos,
    this.ignoredFileCount = 0,
    this.unsupportedOnlySelection = false,
  });

  final List<_PickedPhotoInfo> photos;
  final int ignoredFileCount;
  final bool unsupportedOnlySelection;
}
