import 'package:flutter/material.dart';

import 'package:safety_inspection_app/models/drawing_enums.dart';

Future<bool?> showDeleteDefectTabDialog({
  required BuildContext context,
  required DefectCategory category,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('결함 탭 삭제'),
        content: Text("'${category.label}' 탭을 삭제할까요?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      );
    },
  );
}
