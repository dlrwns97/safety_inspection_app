import 'package:flutter/material.dart';

import '../../models/drawing_enums.dart';

Future<DefectCategory?> showDefectCategoryPickerSheet({
  required BuildContext context,
  required List<DefectCategory> selectedCategories,
}) {
  return showModalBottomSheet<DefectCategory>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final category in DefectCategory.values)
              _DefectCategoryPickerTile(
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

class _DefectCategoryPickerTile extends StatelessWidget {
  const _DefectCategoryPickerTile({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final DefectCategory category;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(category.label),
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
