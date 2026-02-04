import 'package:flutter/material.dart';

enum DefectPhotoSource { camera, gallery, file }

Future<DefectPhotoSource?> showDefectPhotoSourceSheet(
  BuildContext context,
) {
  return showModalBottomSheet<DefectPhotoSource>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('촬영하기'),
            onTap: () => Navigator.of(context).pop(DefectPhotoSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.folder_open),
            title: const Text('기기에서 가져오기'),
            onTap: () => Navigator.of(context).pop(DefectPhotoSource.file),
          ),
        ],
      ),
    ),
  );
}
