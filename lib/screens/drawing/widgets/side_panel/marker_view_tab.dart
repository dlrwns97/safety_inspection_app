import 'package:flutter/material.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';

class MarkerViewTab extends StatelessWidget {
  const MarkerViewTab({
    super.key,
    required this.visibleDefectCategories,
    required this.visibleEquipmentCategories,
    required this.onDefectVisibilityChanged,
    required this.onEquipmentVisibilityChanged,
    required this.equipmentLabelBuilder,
  });

  final Set<DefectCategory> visibleDefectCategories;
  final Set<EquipmentCategory> visibleEquipmentCategories;
  final void Function(DefectCategory category, bool visible)
      onDefectVisibilityChanged;
  final void Function(EquipmentCategory category, bool visible)
      onEquipmentVisibilityChanged;
  final String Function(EquipmentCategory category) equipmentLabelBuilder;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      children: [
        _MarkerViewSectionTitle(title: '결함'),
        const SizedBox(height: 4),
        for (final category in DefectCategory.values)
          CheckboxListTile(
            value: visibleDefectCategories.contains(category),
            onChanged: (value) =>
                onDefectVisibilityChanged(category, value ?? false),
            title: Text(
              category.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            controlAffinity: ListTileControlAffinity.trailing,
          ),
        const SizedBox(height: 8),
        _MarkerViewSectionTitle(title: '장비'),
        const SizedBox(height: 4),
        for (final category in EquipmentCategory.values)
          CheckboxListTile(
            value: visibleEquipmentCategories.contains(category),
            onChanged: (value) =>
                onEquipmentVisibilityChanged(category, value ?? false),
            title: Text(
              equipmentLabelBuilder(category),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            controlAffinity: ListTileControlAffinity.trailing,
          ),
      ],
    );
  }
}

class _MarkerViewSectionTitle extends StatelessWidget {
  const _MarkerViewSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleSmall,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
