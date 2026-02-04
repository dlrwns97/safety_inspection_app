import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import 'package:safety_inspection_app/constants/strings_ko.dart';
import 'package:safety_inspection_app/models/defect_details.dart';
import 'package:safety_inspection_app/screens/drawing/attachments/defect_photo_store.dart';
import '../widgets/narrow_dialog_frame.dart';

Future<DefectDetails?> showDefectDetailsDialog({
  required BuildContext context,
  required String title,
  required List<String> typeOptions,
  required List<String> causeOptions,
  required String siteId,
  required String defectId,
  DefectDetails? initialDetails,
}) {
  return showDialog<DefectDetails>(
    context: context,
    builder: (context) => _DefectDetailsDialog(
      title: title,
      typeOptions: typeOptions,
      causeOptions: causeOptions,
      siteId: siteId,
      defectId: defectId,
      initialDetails: initialDetails,
    ),
  );
}

class _DefectDetailsDialog extends StatefulWidget {
  const _DefectDetailsDialog({
    required this.title,
    required this.typeOptions,
    required this.causeOptions,
    required this.siteId,
    required this.defectId,
    this.initialDetails,
  });

  final String title;
  final List<String> typeOptions;
  final List<String> causeOptions;
  final String siteId;
  final String defectId;
  final DefectDetails? initialDetails;

  @override
  State<_DefectDetailsDialog> createState() => _DefectDetailsDialogState();
}

class _DefectDetailsDialogState extends State<_DefectDetailsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _widthController = TextEditingController();
  final _lengthController = TextEditingController();
  final _otherTypeController = TextEditingController();
  final _otherCauseController = TextEditingController();
  final _photoStore = DefectPhotoStore();
  final _imagePicker = ImagePicker();

  String? _structuralMember;
  String? _crackType;
  String? _cause;
  List<String> _photoPaths = [];
  Map<String, String> _photoOriginalNamesByPath = {};
  bool _isSavingPhotos = false;

  @override
  void initState() {
    super.initState();
    final details = widget.initialDetails;
    if (details == null) {
      return;
    }
    _photoPaths = List<String>.from(details.photoPaths);
    _photoOriginalNamesByPath = Map<String, String>.from(
      details.photoOriginalNamesByPath,
    );
    _structuralMember = details.structuralMember;
    _widthController.text =
        details.widthMm > 0 ? details.widthMm.toString() : '';
    _lengthController.text =
        details.lengthMm > 0 ? details.lengthMm.toString() : '';
    final crackType = details.crackType;
    if (crackType.isNotEmpty) {
      if (widget.typeOptions.contains(crackType)) {
        _crackType = crackType;
      } else {
        _crackType = StringsKo.otherOptionLabel;
        _otherTypeController.text = crackType;
      }
    }
    final cause = details.cause;
    if (cause.isNotEmpty) {
      if (widget.causeOptions.contains(cause)) {
        _cause = cause;
      } else {
        _cause = StringsKo.otherOptionLabel;
        _otherCauseController.text = cause;
      }
    }
  }

  @override
  void dispose() {
    _widthController.dispose();
    _lengthController.dispose();
    _otherTypeController.dispose();
    _otherCauseController.dispose();
    super.dispose();
  }

  bool get _isOtherType => _crackType == StringsKo.otherOptionLabel;
  bool get _isOtherCause => _cause == StringsKo.otherOptionLabel;

  String _photoDisplayName(String storedPath) {
    return photoDisplayName(
      storedPath: storedPath,
      originalNamesByPath: _photoOriginalNamesByPath,
    );
  }

  Future<void> _handlePhotoAction() async {
    if (_isSavingPhotos) {
      return;
    }
    final selection = await _showPhotoSourceSheet(context);
    if (selection == null) {
      return;
    }
    if (selection == _DefectPhotoSource.camera) {
      await _pickFromCamera();
    } else if (selection == _DefectPhotoSource.gallery) {
      await _pickFromGallery();
    } else {
      await _pickFromFilePicker();
    }
  }

  Future<_DefectPhotoSource?> _showPhotoSourceSheet(
    BuildContext sheetContext,
  ) {
    return showModalBottomSheet<_DefectPhotoSource>(
      context: sheetContext,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('촬영하기'),
              onTap: () =>
                  Navigator.of(context).pop(_DefectPhotoSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('갤러리에서 가져오기'),
              onTap: () =>
                  Navigator.of(context).pop(_DefectPhotoSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('파일에서 가져오기'),
              onTap: () => Navigator.of(context).pop(_DefectPhotoSource.file),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked == null) {
      return;
    }
    await _savePhotoPaths(
      [
        _PickedPhotoInfo(
          path: picked.path,
          originalName: _resolveCameraName(picked),
        ),
      ],
    );
  }

  Future<void> _pickFromGallery() async {
    final pickedPhotos = await _pickFromGalleryAssets(maxAssets: 50);
    if (pickedPhotos.isEmpty) {
      return;
    }
    await _savePhotoPaths(pickedPhotos);
  }

  Future<void> _pickFromFilePicker() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: true,
    );
    final allowedExtensions = {
      'jpg',
      'jpeg',
      'png',
      'heic',
      'heif',
      'webp',
    };
    if (result == null) {
      return;
    }
    final selectedFiles =
        result.files.where((file) => file.path != null).toList();
    final pickedPhotos = selectedFiles.where((file) {
      final extension = (file.extension ??
              p.extension(file.name).replaceFirst('.', ''))
          .toLowerCase();
      return allowedExtensions.contains(extension);
    }).map((file) {
      return _PickedPhotoInfo(
        path: file.path!,
        originalName: file.name,
      );
    }).toList();
    final ignoredCount = selectedFiles.length - pickedPhotos.length;
    if (pickedPhotos.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('지원하지 않는 파일 형식입니다'),
              SizedBox(height: 4),
              Text('사진 파일(jpg, png, heic 등)만 선택할 수 있어요.'),
            ],
          ),
        ),
      );
      return;
    }
    if (ignoredCount > 0) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('일부 파일은 사진 형식이 아니라 제외되었습니다.'),
        ),
      );
    }
    await _savePhotoPaths(pickedPhotos);
  }

  Future<void> _savePhotoPaths(List<_PickedPhotoInfo> pickedPhotos) async {
    if (pickedPhotos.isEmpty) {
      return;
    }
    setState(() {
      _isSavingPhotos = true;
    });
    final sourcePaths = pickedPhotos.map((photo) => photo.path).toList();
    final originalNames =
        pickedPhotos.map((photo) => photo.originalName).toList();
    final savedPaths = await _photoStore.savePickedImages(
      siteId: widget.siteId,
      defectId: widget.defectId,
      sourcePaths: sourcePaths,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _isSavingPhotos = false;
      _photoPaths.addAll(savedPaths);
      _storePhotoOriginalNames(savedPaths, originalNames);
    });
  }

  Future<void> _replacePhotoAt({
    required int index,
    required BuildContext dialogContext,
    required void Function(VoidCallback) setDialogState,
  }) async {
    if (_isSavingPhotos) {
      return;
    }
    final selection = await _showPhotoSourceSheet(dialogContext);
    if (selection == null) {
      return;
    }
    final pickedPath = await _pickSinglePhotoPath(selection);
    if (pickedPath == null) {
      return;
    }
    setState(() {
      _isSavingPhotos = true;
    });
    setDialogState(() {});
    final originalNames = [pickedPath.originalName];
    final savedPaths = await _photoStore.savePickedImages(
      siteId: widget.siteId,
      defectId: widget.defectId,
      sourcePaths: [pickedPath.path],
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _isSavingPhotos = false;
      if (index < _photoPaths.length) {
        final oldPath = _photoPaths[index];
        _photoOriginalNamesByPath.remove(oldPath);
        _photoPaths[index] = savedPaths.single;
        _storePhotoOriginalNames(savedPaths, originalNames);
      }
    });
    setDialogState(() {});
  }

  Future<_PickedPhotoInfo?> _pickSinglePhotoPath(
    _DefectPhotoSource source,
  ) async {
    if (source == _DefectPhotoSource.camera) {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (picked == null) {
        return null;
      }
      return _PickedPhotoInfo(
        path: picked.path,
        originalName: _resolveCameraName(picked),
      );
    }
    if (source == _DefectPhotoSource.gallery) {
      final pickedPhotos = await _pickFromGalleryAssets(maxAssets: 1);
      if (pickedPhotos.isEmpty) {
        return null;
      }
      return pickedPhotos.first;
    }
    return _pickSinglePathFromFilePicker();
  }

  Future<List<_PickedPhotoInfo>> _pickFromGalleryAssets({
    required int maxAssets,
  }) async {
    final permissionGranted = await _ensureGalleryPermission();
    if (!permissionGranted) {
      return [];
    }
    final assets = await AssetPicker.pickAssets(
      context,
      pickerConfig: AssetPickerConfig(
        maxAssets: maxAssets,
        requestType: RequestType.image,
      ),
    );
    if (assets == null || assets.isEmpty) {
      return [];
    }
    final pickedPhotos = <_PickedPhotoInfo>[];
    for (final asset in assets) {
      final file = await asset.file;
      if (file == null) {
        if (!mounted) {
          continue;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('선택한 사진을 불러올 수 없습니다.')),
        );
        continue;
      }
      final title = asset.title?.trim();
      pickedPhotos.add(
        _PickedPhotoInfo(
          path: file.path,
          originalName:
              title == null || title.isEmpty ? p.basename(file.path) : title,
        ),
      );
    }
    return pickedPhotos;
  }

  Future<bool> _ensureGalleryPermission() async {
    final permissionState = await AssetPicker.permissionCheck();
    final isGranted = permissionState == PermissionState.authorized ||
        permissionState == PermissionState.limited;
    if (!isGranted) {
      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사진 접근 권한이 필요합니다')),
      );
    }
    return isGranted;
  }

  Future<_PickedPhotoInfo?> _pickSinglePathFromFilePicker() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (result == null) {
      return null;
    }
    final pickedFile = result.files.single;
    final pickedPath = pickedFile.path;
    if (pickedPath == null) {
      return null;
    }
    final allowedExtensions = {
      'jpg',
      'jpeg',
      'png',
      'heic',
      'heif',
      'webp',
    };
    final extension = (pickedFile.extension ??
            p.extension(pickedFile.name).replaceFirst('.', ''))
        .toLowerCase();
    if (!allowedExtensions.contains(extension)) {
      if (!mounted) {
        return null;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('지원하지 않는 파일 형식입니다'),
              SizedBox(height: 4),
              Text('사진 파일만 선택할 수 있어요.'),
            ],
          ),
        ),
      );
      return null;
    }
    return _PickedPhotoInfo(
      path: pickedPath,
      originalName: pickedFile.name,
    );
  }

  String _resolveCameraName(XFile picked) {
    final name = picked.name.trim();
    if (name.isNotEmpty) {
      return name;
    }
    return _cameraFallbackName(picked.path);
  }

  String _cameraFallbackName(String sourcePath) {
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
    return '${year}${month}${day}_$hour$minute$second$extension';
  }

  void _storePhotoOriginalNames(
    List<String> savedPaths,
    List<String> originalNames,
  ) {
    final count = min(savedPaths.length, originalNames.length);
    for (var i = 0; i < count; i++) {
      final savedPath = savedPaths[i];
      final originalName = originalNames[i].isNotEmpty
          ? originalNames[i]
          : p.basename(savedPath);
      _photoOriginalNamesByPath[savedPath] = originalName;
    }
  }

  bool _isValid() {
    final width = double.tryParse(_widthController.text);
    final length = double.tryParse(_lengthController.text);
    final hasOtherType =
        !_isOtherType || _otherTypeController.text.trim().isNotEmpty;
    final hasOtherCause =
        !_isOtherCause || _otherCauseController.text.trim().isNotEmpty;
    return _structuralMember != null &&
        _crackType != null &&
        _cause != null &&
        width != null &&
        length != null &&
        width > 0 &&
        length > 0 &&
        hasOtherType &&
        hasOtherCause;
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.5;
    final maxWidth = min(
      MediaQuery.of(context).size.width * 0.6,
      520.0,
    );

    return NarrowDialogFrame(
      maxWidth: maxWidth,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._buildHeader(context),
                ..._buildCategorySection(context),
                ..._buildMemberTypeSection(context),
                ..._buildFieldsSection(context),
                ..._buildPhotoSection(context),
                ..._buildActions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildHeader(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge;
    return [
      Text(
        widget.title,
        style: titleStyle,
      ),
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _buildCategorySection(BuildContext context) {
    final structuralMemberItems = StringsKo.structuralMembers
        .map(
          (item) => DropdownMenuItem(
            value: item,
            child: Text(item),
          ),
        )
        .toList();
    return [
      DropdownButtonFormField<String>(
        initialValue: _structuralMember,
        decoration: InputDecoration(
          labelText: StringsKo.structuralMemberLabel,
        ),
        items: structuralMemberItems,
        onChanged: (value) {
          setState(() {
            _structuralMember = value;
          });
        },
        validator: (value) =>
            value == null ? StringsKo.selectMemberError : null,
      ),
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _buildMemberTypeSection(BuildContext context) {
    final typeItems = widget.typeOptions
        .map(
          (item) => DropdownMenuItem(
            value: item,
            child: Text(item),
          ),
        )
        .toList();
    return [
      DropdownButtonFormField<String>(
        initialValue: _crackType,
        decoration: InputDecoration(
          labelText: StringsKo.crackTypeLabel,
        ),
        items: typeItems,
        onChanged: (value) {
          setState(() {
            _crackType = value;
            if (value != StringsKo.otherOptionLabel) {
              _otherTypeController.clear();
            }
          });
        },
        validator: (value) =>
            value == null ? StringsKo.selectCrackTypeError : null,
      ),
      if (_isOtherType) ...[
        const SizedBox(height: 12),
        TextFormField(
          controller: _otherTypeController,
          decoration: InputDecoration(
            labelText: StringsKo.otherTypeLabel,
          ),
          validator: (_) =>
              _otherTypeController.text.trim().isEmpty
              ? StringsKo.enterOtherTypeError
              : null,
          onChanged: (_) => setState(() {}),
        ),
      ],
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _buildFieldsSection(BuildContext context) {
    final numberKeyboardType = const TextInputType.numberWithOptions(
      decimal: true,
    );
    final causeItems = widget.causeOptions
        .map(
          (item) => DropdownMenuItem(
            value: item,
            child: Text(item),
          ),
        )
        .toList();
    return [
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _widthController,
              decoration: InputDecoration(
                labelText: StringsKo.widthLabel,
              ),
              keyboardType: numberKeyboardType,
              validator: (value) {
                final parsed = double.tryParse(value ?? '');
                if (parsed == null || parsed <= 0) {
                  return StringsKo.enterWidthError;
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _lengthController,
              decoration: InputDecoration(
                labelText: StringsKo.lengthLabel,
              ),
              keyboardType: numberKeyboardType,
              validator: (value) {
                final parsed = double.tryParse(value ?? '');
                if (parsed == null || parsed <= 0) {
                  return StringsKo.enterLengthError;
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
        initialValue: _cause,
        decoration: InputDecoration(
          labelText: StringsKo.causeLabel,
        ),
        items: causeItems,
        onChanged: (value) {
          setState(() {
            _cause = value;
            if (value != StringsKo.otherOptionLabel) {
              _otherCauseController.clear();
            }
          });
        },
        validator: (value) =>
            value == null ? StringsKo.selectCauseError : null,
      ),
      if (_isOtherCause) ...[
        const SizedBox(height: 12),
        TextFormField(
          controller: _otherCauseController,
          decoration: InputDecoration(
            labelText: StringsKo.otherCauseLabel,
          ),
          validator: (_) =>
              _otherCauseController.text.trim().isEmpty
              ? StringsKo.enterOtherCauseError
              : null,
          onChanged: (_) => setState(() {}),
        ),
      ],
      const SizedBox(height: 20),
    ];
  }

  List<Widget> _buildPhotoSection(BuildContext context) {
    return [
      Row(
        children: [
          const Text('사진'),
          const SizedBox(width: 8),
          Text('${_photoPaths.length}장'),
          const Spacer(),
          TextButton(
            onPressed: _photoPaths.isEmpty ? null : _openPhotoManagerDialog,
            child: const Text('관리'),
          ),
        ],
      ),
      if (_photoPaths.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            _photoDisplayName(_photoPaths.first),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      const SizedBox(height: 12),
    ];
  }

  Future<void> _openPhotoManagerDialog() async {
    if (_photoPaths.isEmpty) {
      return;
    }
    int currentIndex = 0;
    final controller = PageController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('사진 관리'),
              content: SizedBox(
                width: min(MediaQuery.of(context).size.width * 0.7, 500),
                height: min(MediaQuery.of(context).size.height * 0.6, 420),
                child: Column(
                  children: [
                    Expanded(
                      child: PageView.builder(
                        controller: controller,
                        itemCount: _photoPaths.length,
                        onPageChanged: (index) {
                          setDialogState(() {
                            currentIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return InteractiveViewer(
                            minScale: 1,
                            maxScale: 4,
                            child: Image.file(
                              File(_photoPaths[index]),
                              fit: BoxFit.contain,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: [
                        Text(
                          '${currentIndex + 1} / ${_photoPaths.length}',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _photoDisplayName(_photoPaths[currentIndex]),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isSavingPhotos
                      ? null
                      : () => _replacePhotoAt(
                            index: currentIndex,
                            dialogContext: dialogContext,
                            setDialogState: setDialogState,
                          ),
                  child: const Text('교체'),
                ),
                IconButton(
                  tooltip: '삭제',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _isSavingPhotos
                      ? null
                      : () async {
                    final confirmed = await showDialog<bool>(
                      context: dialogContext,
                      builder: (context) => AlertDialog(
                        content: const Text('이 사진을 삭제할까요?'),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).pop(false),
                            child: Text(StringsKo.cancel),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('삭제'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true) {
                      return;
                    }
                    if (!mounted) {
                      return;
                    }
                    setState(() {
                      final removedPath = _photoPaths.removeAt(currentIndex);
                      _photoOriginalNamesByPath.remove(removedPath);
                    });
                    if (_photoPaths.isEmpty) {
                      Navigator.of(dialogContext).pop();
                      return;
                    }
                    final nextIndex = min(
                      currentIndex,
                      _photoPaths.length - 1,
                    );
                    setDialogState(() {
                      currentIndex = nextIndex;
                    });
                    if (controller.hasClients) {
                      controller.jumpToPage(nextIndex);
                    }
                  },
                ),
                if (_isSavingPhotos)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                TextButton(
                  onPressed: _isSavingPhotos
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('닫기'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    return [
      Row(
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(StringsKo.cancel),
          ),
          const Spacer(),
          IconButton(
            onPressed: _isSavingPhotos ? null : _handlePhotoAction,
            icon: const Icon(Icons.photo_camera),
          ),
          const Spacer(),
          FilledButton(
            onPressed: _isValid() && !_isSavingPhotos
                ? () {
                    if (_formKey.currentState?.validate() ?? false) {
                      final resolvedType = _isOtherType
                          ? _otherTypeController.text.trim()
                          : _crackType!;
                      final resolvedCause = _isOtherCause
                          ? _otherCauseController.text.trim()
                          : _cause!;
                      final widthValue = _widthController.text.trim();
                      final lengthValue = _lengthController.text.trim();
                      Navigator.of(context).pop(
                        DefectDetails(
                          structuralMember: _structuralMember!,
                          crackType: resolvedType,
                          widthMm: double.parse(widthValue),
                          lengthMm: double.parse(lengthValue),
                          cause: resolvedCause,
                          photoPaths: _photoPaths,
                          photoOriginalNamesByPath: Map<String, String>.from(
                            _photoOriginalNamesByPath,
                          ),
                        ),
                      );
                    }
                  }
                : null,
            child: _isSavingPhotos
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(StringsKo.confirm),
                    ],
                  )
                : Text(StringsKo.confirm),
          ),
        ],
      ),
      const SizedBox(height: 8),
    ];
  }
}

class _PickedPhotoInfo {
  const _PickedPhotoInfo({
    required this.path,
    required this.originalName,
  });

  final String path;
  final String originalName;
}

enum _DefectPhotoSource { camera, gallery, file }
