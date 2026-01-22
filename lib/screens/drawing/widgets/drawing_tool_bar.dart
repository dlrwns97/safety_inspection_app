import 'package:flutter/material.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/tool_detail_row.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/tool_selection_row.dart';

class DrawingToolBar extends StatelessWidget implements PreferredSizeWidget {
  const DrawingToolBar({
    super.key,
    required this.height,
    required this.isToolSelectionMode,
    required this.mode,
    required this.defectTabs,
    required this.activeCategory,
    required this.activeEquipmentCategory,
    required this.onBack,
    required this.onAdd,
    required this.onToggleMode,
    required this.onDefectSelected,
    required this.onDefectLongPress,
    required this.onEquipmentSelected,
  });

  final double height;
  final bool isToolSelectionMode;
  final DrawMode mode;
  final List<DefectCategory> defectTabs;
  final DefectCategory? activeCategory;
  final EquipmentCategory? activeEquipmentCategory;
  final VoidCallback onBack;
  final VoidCallback onAdd;
  final ValueChanged<DrawMode> onToggleMode;
  final ValueChanged<DefectCategory> onDefectSelected;
  final ValueChanged<DefectCategory> onDefectLongPress;
  final ValueChanged<EquipmentCategory> onEquipmentSelected;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: Size.fromHeight(height),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: isToolSelectionMode
              ? ToolSelectionRow(
                  mode: mode,
                  onToggleMode: onToggleMode,
                )
              : ToolDetailRow(
                  mode: mode,
                  defectTabs: defectTabs,
                  activeCategory: activeCategory,
                  activeEquipmentCategory: activeEquipmentCategory,
                  onBack: onBack,
                  onAdd: onAdd,
                  onDefectSelected: onDefectSelected,
                  onDefectLongPress: onDefectLongPress,
                  onEquipmentSelected: onEquipmentSelected,
                ),
        ),
      ),
    );
  }
}
