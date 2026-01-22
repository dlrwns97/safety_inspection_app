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
          _ToolToggleButton(
            label: StringsKo.defectModeLabel,
            isSelected: mode == DrawMode.defect,
            onTap: () => onToggleMode(DrawMode.defect),
          ),
          const SizedBox(width: 8),
          _ToolToggleButton(
            label: StringsKo.equipmentModeLabel,
            isSelected: mode == DrawMode.equipment,
            onTap: () => onToggleMode(DrawMode.equipment),
          ),
          const SizedBox(width: 8),
          _ToolToggleButton(
            label: StringsKo.freeDrawModeLabel,
            isSelected: mode == DrawMode.freeDraw,
            onTap: () => onToggleMode(DrawMode.freeDraw),
          ),
          const SizedBox(width: 8),
          _ToolToggleButton(
            label: StringsKo.eraserModeLabel,
            isSelected: mode == DrawMode.eraser,
            onTap: () => onToggleMode(DrawMode.eraser),
          ),
        ],
      ),
    );
  }
}

class _ToolToggleButton extends StatelessWidget {
  const _ToolToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        backgroundColor:
            isSelected ? colors.primary : colors.surfaceContainerHighest,
        foregroundColor:
            isSelected ? colors.onPrimary : colors.onSurfaceVariant,
        side: BorderSide(
          color: isSelected ? colors.primary : colors.outlineVariant,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}
