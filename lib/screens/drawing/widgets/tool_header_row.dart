import 'package:flutter/material.dart';

import 'package:safety_inspection_app/constants/strings_ko.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/numbered_tabs.dart';

class ToolHeaderRow extends StatelessWidget {
  const ToolHeaderRow({
    super.key,
    required this.mode,
    required this.defectTabs,
    required this.activeCategory,
    required this.activeEquipmentCategory,
    required this.onBack,
    required this.onAdd,
    required this.onDefectSelected,
    required this.onDefectLongPress,
    required this.onEquipmentSelected,
  });

  final DrawMode mode;
  final List<DefectCategory> defectTabs;
  final DefectCategory? activeCategory;
  final EquipmentCategory? activeEquipmentCategory;
  final VoidCallback onBack;
  final VoidCallback onAdd;
  final ValueChanged<DefectCategory> onDefectSelected;
  final ValueChanged<DefectCategory> onDefectLongPress;
  final ValueChanged<EquipmentCategory> onEquipmentSelected;

  @override
  Widget build(BuildContext context) {
    final showAddButton = mode == DrawMode.defect || mode == DrawMode.equipment;
    final showTabs =
        mode == DrawMode.defect ? defectTabs.isNotEmpty : showAddButton;

    return Row(
      children: [
        IconButton(
          tooltip: '뒤로',
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        const SizedBox(width: 4),
        Flexible(
          fit: FlexFit.loose,
          child: Text(
            _modeTitle(mode),
            style: Theme.of(context).textTheme.titleSmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (showAddButton) ...[
          const SizedBox(width: 6),
          SizedBox(
            width: 24,
            height: 24,
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 18,
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              tooltip: '추가',
            ),
          ),
        ],
        if (showTabs) ...[
          const SizedBox(width: 8),
          Flexible(
            fit: FlexFit.loose,
            child: mode == DrawMode.defect
                ? _DefectCategoryTabs(
                    defectTabs: defectTabs,
                    activeCategory: activeCategory,
                    onSelected: onDefectSelected,
                    onLongPress: onDefectLongPress,
                  )
                : NumberedTabs<EquipmentCategory>(
                    items: EquipmentCategory.values,
                    selected: activeEquipmentCategory,
                    onSelected: onEquipmentSelected,
                  ),
          ),
        ],
      ],
    );
  }

  String _modeTitle(DrawMode mode) {
    switch (mode) {
      case DrawMode.defect:
        return StringsKo.defectModeLabel;
      case DrawMode.equipment:
        return StringsKo.equipmentModeLabel;
      case DrawMode.freeDraw:
        return StringsKo.freeDrawModeLabel;
      case DrawMode.eraser:
        return StringsKo.eraserModeLabel;
      case DrawMode.hand:
        return '';
    }
  }
}

class _DefectCategoryTabs extends StatelessWidget {
  const _DefectCategoryTabs({
    required this.defectTabs,
    required this.activeCategory,
    required this.onSelected,
    required this.onLongPress,
  });

  final List<DefectCategory> defectTabs;
  final DefectCategory? activeCategory;
  final ValueChanged<DefectCategory> onSelected;
  final ValueChanged<DefectCategory> onLongPress;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: defectTabs.map((category) {
          final isSelected = category == activeCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onLongPress: () => onLongPress(category),
              child: ChoiceChip(
                label: Text(category.label),
                selected: isSelected,
                onSelected: (_) => onSelected(category),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
