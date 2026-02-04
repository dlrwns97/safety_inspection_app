import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:safety_inspection_app/constants/strings_ko.dart';
import 'package:safety_inspection_app/models/defect_details.dart';

Future<void> showPhotoManagerDialog({
  required BuildContext context,
  required List<String> photoPaths,
  required Map<String, String> photoOriginalNamesByPath,
  required int initialIndex,
  required Future<void> Function(int index) onDelete,
  required Future<void> Function(int index) onReplace,
  required bool isSavingPhotos,
}) async {
  if (photoPaths.isEmpty) {
    return;
  }
  int currentIndex = initialIndex;
  final controller = PageController(initialPage: initialIndex);
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
                      itemCount: photoPaths.length,
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
                            File(photoPaths[index]),
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
                        '${currentIndex + 1} / ${photoPaths.length}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        photoDisplayName(
                          storedPath: photoPaths[currentIndex],
                          originalNamesByPath: photoOriginalNamesByPath,
                        ),
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
                onPressed: isSavingPhotos
                    ? null
                    : () async {
                        final replaceFuture = onReplace(currentIndex);
                        setDialogState(() {});
                        await replaceFuture;
                        setDialogState(() {});
                      },
                child: const Text('교체'),
              ),
              IconButton(
                tooltip: '삭제',
                icon: const Icon(Icons.delete_outline),
                onPressed: isSavingPhotos
                    ? null
                    : () async {
                        final dialogNavigator = Navigator.of(dialogContext);
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
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('삭제'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed != true) {
                          return;
                        }
                        await onDelete(currentIndex);
                        if (!dialogContext.mounted) {
                          return;
                        }
                        if (photoPaths.isEmpty) {
                          dialogNavigator.pop();
                          return;
                        }
                        final nextIndex = min(
                          currentIndex,
                          photoPaths.length - 1,
                        );
                        setDialogState(() {
                          currentIndex = nextIndex;
                        });
                        if (controller.hasClients) {
                          controller.jumpToPage(nextIndex);
                        }
                      },
              ),
              if (isSavingPhotos)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              TextButton(
                onPressed: isSavingPhotos
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
