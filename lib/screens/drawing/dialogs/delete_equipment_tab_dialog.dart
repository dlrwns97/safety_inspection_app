import 'package:flutter/material.dart';

import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/screens/drawing/flows/marker_presenters.dart';

Future<bool?> showDeleteEquipmentTabDialog({
  required BuildContext context,
  required EquipmentCategory category,
}) {
  final label = equipmentChipLabel(category);
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('장비 탭 삭제'),
        content: Text('$label 탭을 삭제할까요?'),
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
