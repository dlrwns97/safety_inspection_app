import 'package:flutter/material.dart';

import 'package:safety_inspection_app/models/defect_details.dart';

class DefectPhotoThumbnailsSection extends StatelessWidget {
  const DefectPhotoThumbnailsSection({
    super.key,
    required this.photoPaths,
    required this.photoOriginalNamesByPath,
    required this.onTapManage,
  });

  final List<String> photoPaths;
  final Map<String, String> photoOriginalNamesByPath;
  final VoidCallback onTapManage;

  String _photoDisplayName(String storedPath) {
    return photoDisplayName(
      storedPath: storedPath,
      originalNamesByPath: photoOriginalNamesByPath,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('사진'),
            const SizedBox(width: 8),
            Text('${photoPaths.length}장'),
            const Spacer(),
            TextButton(
              onPressed: photoPaths.isEmpty ? null : onTapManage,
              child: const Text('관리'),
            ),
          ],
        ),
        if (photoPaths.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _photoDisplayName(photoPaths.first),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}
