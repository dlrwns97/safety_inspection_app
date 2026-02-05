import 'package:flutter/material.dart';

import 'package:safety_inspection_app/constants/strings_ko.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';

class ToolSelectionRow extends StatelessWidget {
  const ToolSelectionRow({
    super.key,
    required this.mode,
    required this.onToggleMode,
  });

  final DrawMode mode;
  final ValueChanged<DrawMode> onToggleMode;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToolToggleChip(
            label: StringsKo.defectModeLabel,
            isSelected: mode == DrawMode.defect,
            onTap: () => onToggleMode(DrawMode.defect),
          ),
          const SizedBox(width: 8),
          _ToolToggleChip(
            label: StringsKo.equipmentModeLabel,
            isSelected: mode == DrawMode.equipment,
            onTap: () => onToggleMode(DrawMode.equipment),
          ),
          const SizedBox(width: 8),
          _ToolToggleChip(
            label: StringsKo.freeDrawModeLabel,
            isSelected: mode == DrawMode.freeDraw || mode == DrawMode.eraser,
            onTap: () => onToggleMode(DrawMode.freeDraw),
          ),
        ],
      ),
    );
  }
}

class _ToolToggleChip extends StatelessWidget {
  const _ToolToggleChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
    );
  }
}
