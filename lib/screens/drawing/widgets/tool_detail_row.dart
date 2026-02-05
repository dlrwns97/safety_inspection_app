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
    required this.equipmentTabs,
    required this.onBack,
    required this.onAdd,
    required this.onDefectSelected,
    required this.onDefectLongPress,
    required this.onEquipmentSelected,
    required this.onEquipmentLongPress,
    required this.activeDrawingTool,
    required this.canUndoDrawing,
    required this.canRedoDrawing,
    required this.onDrawingToolSelected,
    required this.onUndoDrawing,
    required this.onRedoDrawing,
  });

  final DrawMode mode;
  final List<DefectCategory> defectTabs;
  final DefectCategory? activeCategory;
  final EquipmentCategory? activeEquipmentCategory;
  final List<EquipmentCategory> equipmentTabs;
  final VoidCallback onBack;
  final VoidCallback onAdd;
  final ValueChanged<DefectCategory> onDefectSelected;
  final ValueChanged<DefectCategory> onDefectLongPress;
  final ValueChanged<EquipmentCategory> onEquipmentSelected;
  final ValueChanged<EquipmentCategory> onEquipmentLongPress;
  final DrawingTool activeDrawingTool;
  final bool canUndoDrawing;
  final bool canRedoDrawing;
  final ValueChanged<DrawingTool> onDrawingToolSelected;
  final VoidCallback onUndoDrawing;
  final VoidCallback onRedoDrawing;

  @override
  Widget build(BuildContext context) {
    return ToolHeaderRow(
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
      activeDrawingTool: activeDrawingTool,
      canUndoDrawing: canUndoDrawing,
      canRedoDrawing: canRedoDrawing,
      onDrawingToolSelected: onDrawingToolSelected,
      onUndoDrawing: onUndoDrawing,
      onRedoDrawing: onRedoDrawing,
    );
  }
}
