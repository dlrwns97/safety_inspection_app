import 'dart:math';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

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
  bool _isSavingPhotos = false;

  @override
  void initState() {
    super.initState();
    final details = widget.initialDetails;
    if (details == null) {
      return;
    }
    _photoPaths = List<String>.from(details.photoPaths);
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

  Future<void> _handlePhotoAction() async {
    if (_isSavingPhotos) {
      return;
    }
    final selection = await showModalBottomSheet<_DefectPhotoSource>(
      context: context,
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
    await _savePhotoPaths([picked.path]);
  }

  Future<void> _pickFromGallery() async {
    final pickedImages = await _imagePicker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (pickedImages.isNotEmpty) {
      await _savePhotoPaths(pickedImages.map((image) => image.path).toList());
      return;
    }
    final pickedSingle = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (pickedSingle == null) {
      return;
    }
    await _savePhotoPaths([pickedSingle.path]);
  }

  Future<void> _pickFromFilePicker() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    final sourcePaths = result?.paths.whereType<String>().toList() ?? [];
    if (sourcePaths.isEmpty) {
      return;
    }
    await _savePhotoPaths(sourcePaths);
  }

  Future<void> _savePhotoPaths(List<String> sourcePaths) async {
    if (sourcePaths.isEmpty) {
      return;
    }
    setState(() {
      _isSavingPhotos = true;
    });
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
    });
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

enum _DefectPhotoSource { camera, gallery, file }
