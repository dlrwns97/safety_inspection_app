import 'package:flutter/material.dart';

import 'package:safety_inspection_app/constants/strings_ko.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';
import 'package:safety_inspection_app/screens/drawing/flows/marker_presenters.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/numbered_tabs.dart';

class ToolHeaderRow extends StatelessWidget {
  const ToolHeaderRow({
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
    required this.activeStrokeTool,
    required this.canUndoDrawing,
    required this.canRedoDrawing,
    required this.onDrawingToolSelected,
    required this.onUndoDrawing,
    required this.onRedoDrawing,
    this.penToolLink,
    this.highlighterToolLink,
    this.eraserToolLink,
    this.shapeToolLink,
    this.textToolLink,
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
  final StrokeToolKind activeStrokeTool;
  final bool canUndoDrawing;
  final bool canRedoDrawing;
  final ValueChanged<StrokeToolKind> onDrawingToolSelected;
  final VoidCallback onUndoDrawing;
  final VoidCallback onRedoDrawing;
  final LayerLink? penToolLink;
  final LayerLink? highlighterToolLink;
  final LayerLink? eraserToolLink;
  final LayerLink? shapeToolLink;
  final LayerLink? textToolLink;

  @override
  Widget build(BuildContext context) {
    final showAddButton = mode == DrawMode.defect || mode == DrawMode.equipment;
    final showTabs = mode == DrawMode.defect
        ? defectTabs.isNotEmpty
        : equipmentTabs.isNotEmpty;
    final isFreeDrawMode = mode == DrawMode.freeDraw || mode == DrawMode.eraser;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: '뒤로',
              icon: const Icon(Icons.arrow_back),
              onPressed: onBack,
            ),
            const SizedBox(width: 4),
            Flexible(
              fit: FlexFit.loose,
              child: isFreeDrawMode
                  ? _FreeDrawActionTabs(
                      activeTool: activeStrokeTool,
                      canUndo: canUndoDrawing,
                      canRedo: canRedoDrawing,
                      onToolSelected: onDrawingToolSelected,
                      onUndo: onUndoDrawing,
                      onRedo: onRedoDrawing,
                      penToolLink: penToolLink,
                      highlighterToolLink: highlighterToolLink,
                      eraserToolLink: eraserToolLink,
                      shapeToolLink: shapeToolLink,
                      textToolLink: textToolLink,
                    )
                  : Row(
                  children: [
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
                                items: equipmentTabs,
                                selected: activeEquipmentCategory,
                                onSelected: onEquipmentSelected,
                                labelBuilder: equipmentChipLabel,
                                onLongPress: onEquipmentLongPress,
                              ),
                      ),
                    ],
                  ],
                ),
            ),
          ],
        ),
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

class _FreeDrawActionTabs extends StatelessWidget {
  const _FreeDrawActionTabs({
    required this.activeTool,
    required this.canUndo,
    required this.canRedo,
    required this.onToolSelected,
    required this.onUndo,
    required this.onRedo,
    this.penToolLink,
    this.highlighterToolLink,
    this.eraserToolLink,
    this.shapeToolLink,
    this.textToolLink,
  });

  final StrokeToolKind activeTool;
  final bool canUndo;
  final bool canRedo;
  final ValueChanged<StrokeToolKind> onToolSelected;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final LayerLink? penToolLink;
  final LayerLink? highlighterToolLink;
  final LayerLink? eraserToolLink;
  final LayerLink? shapeToolLink;
  final LayerLink? textToolLink;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CompositedTransformTarget(
          link: penToolLink ?? LayerLink(),
          child: ChoiceChip(
            label: const Text('자유선'),
            selected: activeTool == StrokeToolKind.pen,
            onSelected: (_) => onToolSelected(StrokeToolKind.pen),
          ),
        ),
        const SizedBox(width: 8),
        CompositedTransformTarget(
          link: highlighterToolLink ?? LayerLink(),
          child: ChoiceChip(
            label: const Text('형광펜'),
            selected: activeTool == StrokeToolKind.highlighter,
            onSelected: (_) => onToolSelected(StrokeToolKind.highlighter),
          ),
        ),
        const SizedBox(width: 8),
        CompositedTransformTarget(
          link: shapeToolLink ?? LayerLink(),
          child: ChoiceChip(
            label: const Text('도형'),
            selected: activeTool == StrokeToolKind.shape,
            onSelected: (_) => onToolSelected(StrokeToolKind.shape),
          ),
        ),
        const SizedBox(width: 8),
        CompositedTransformTarget(
          link: textToolLink ?? LayerLink(),
          child: ChoiceChip(
            label: const Text('텍스트'),
            selected: activeTool == StrokeToolKind.textBox,
            onSelected: (_) => onToolSelected(StrokeToolKind.textBox),
          ),
        ),
        const SizedBox(width: 8),
        CompositedTransformTarget(
          link: eraserToolLink ?? LayerLink(),
          child: ChoiceChip(
            label: const Text('지우개'),
            selected: activeTool == StrokeToolKind.eraser,
            onSelected: (_) => onToolSelected(StrokeToolKind.eraser),
          ),
        ),
        const Spacer(),
        ActionChip(
          label: const Text('되돌리기'),
          onPressed: canUndo ? onUndo : null,
        ),
        const SizedBox(width: 8),
        ActionChip(
          label: const Text('앞으로'),
          onPressed: canRedo ? onRedo : null,
        ),
      ],
    );
  }
}

String _shortTopDefectLabel(DefectCategory category) {
  switch (category) {
    case DefectCategory.concreteSpalling:
      return '콘크리트';
    case DefectCategory.steelDefect:
      return '철골';
    case DefectCategory.other:
      return '기타';
    case DefectCategory.generalCrack:
    case DefectCategory.waterLeakage:
      return category.label;
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
                label: Text(_shortTopDefectLabel(category)),
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
