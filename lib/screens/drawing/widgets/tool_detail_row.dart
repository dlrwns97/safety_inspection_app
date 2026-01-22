import 'package:flutter/material.dart';

import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/tool_header_row.dart';

class ToolDetailRow extends StatelessWidget {
  const ToolDetailRow({
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
    return ToolHeaderRow(
      mode: mode,
      defectTabs: defectTabs,
      activeCategory: activeCategory,
      activeEquipmentCategory: activeEquipmentCategory,
      onBack: onBack,
      onAdd: onAdd,
      onDefectSelected: onDefectSelected,
      onDefectLongPress: onDefectLongPress,
      onEquipmentSelected: onEquipmentSelected,
    );
  }
}
