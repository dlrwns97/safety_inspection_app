import 'package:flutter/material.dart';

import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/screens/drawing/flows/marker_presenters.dart';

Future<EquipmentCategory?> showEquipmentCategoryPickerSheet({
  required BuildContext context,
  required Set<EquipmentCategory> selectedCategories,
}) {
  return showModalBottomSheet<EquipmentCategory>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final availableCategories = kEquipmentCategoryOrder
          .where((category) => !selectedCategories.contains(category))
          .toList();
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.6,
          ),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              for (final category in availableCategories)
                _EquipmentCategoryPickerTile(
                  category: category,
                  onTap: () => Navigator.of(context).pop(category),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _EquipmentCategoryPickerTile extends StatelessWidget {
  const _EquipmentCategoryPickerTile({
    required this.category,
    required this.onTap,
  });

  final EquipmentCategory category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(equipmentCategoryDisplayNameKo(category)),
      enabled: onTap != null,
      trailing:
          onTap == null ? null : Icon(Icons.add, color: theme.iconTheme.color),
      onTap: onTap,
    );
  }
}
