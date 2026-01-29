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
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final category in EquipmentCategory.values)
              _EquipmentCategoryPickerTile(
                category: category,
                isSelected: selectedCategories.contains(category),
                onTap: selectedCategories.contains(category)
                    ? null
                    : () => Navigator.of(context).pop(category),
              ),
          ],
        ),
      );
    },
  );
}

class _EquipmentCategoryPickerTile extends StatelessWidget {
  const _EquipmentCategoryPickerTile({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final EquipmentCategory category;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(equipmentCategoryDisplayNameKo(category)),
      enabled: onTap != null,
      trailing: isSelected
          ? Icon(
              Icons.check,
              color: theme.colorScheme.primary,
            )
          : null,
      onTap: onTap,
    );
  }
}
