import 'package:flutter/material.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/tool_detail_row.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/tool_selection_row.dart';

class DrawingTopBar extends StatelessWidget implements PreferredSizeWidget {
  const DrawingTopBar({
    super.key,
    required this.mode,
    required this.isToolSelectionMode,
    required this.defectTabs,
    required this.activeCategory,
    required this.activeEquipmentCategory,
    required this.equipmentTabs,
    required this.onToggleMode,
    required this.onBack,
    required this.onAdd,
    required this.onDefectSelected,
    required this.onDefectLongPress,
    required this.onEquipmentSelected,
    required this.onEquipmentLongPress,
  });

  static const double _toolBarHeight = 56.0;

  final DrawMode mode;
  final bool isToolSelectionMode;
  final List<DefectCategory> defectTabs;
  final DefectCategory? activeCategory;
  final EquipmentCategory? activeEquipmentCategory;
  final List<EquipmentCategory> equipmentTabs;
  final ValueChanged<DrawMode> onToggleMode;
  final VoidCallback onBack;
  final VoidCallback onAdd;
  final ValueChanged<DefectCategory> onDefectSelected;
  final ValueChanged<DefectCategory> onDefectLongPress;
  final ValueChanged<EquipmentCategory> onEquipmentSelected;
  final ValueChanged<EquipmentCategory> onEquipmentLongPress;

  @override
  Size get preferredSize => const Size.fromHeight(_toolBarHeight);

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                equipmentTabs: equipmentTabs,
                onBack: onBack,
                onAdd: onAdd,
                onDefectSelected: onDefectSelected,
                onDefectLongPress: onDefectLongPress,
                onEquipmentSelected: onEquipmentSelected,
                onEquipmentLongPress: onEquipmentLongPress,
              ),
      ),
    );
  }
}
