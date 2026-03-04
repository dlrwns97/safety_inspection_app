import 'package:flutter/widgets.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';

class MarkerState {
  MarkerState({
    this.activeCategory,
    this.activeEquipmentCategory,
    this.sidePanelDefectCategory,
    this.sidePanelEquipmentCategory,
    this.selectedDefectId,
    this.selectedEquipmentId,
    this.selectedMarkerScenePosition,
    this.sidePanelTabIndex = 0,
    Set<DefectCategory>? visibleDefectCategories,
    Set<EquipmentCategory>? visibleEquipmentCategories,
    List<DefectCategory>? defectTabs,
  }) : _visibleDefectCategories =
           visibleDefectCategories ?? DefectCategory.values.toSet(),
       _visibleEquipmentCategories =
           visibleEquipmentCategories ?? <EquipmentCategory>{},
       _defectTabs = defectTabs ?? <DefectCategory>[];

  DefectCategory? activeCategory;
  EquipmentCategory? activeEquipmentCategory;
  DefectCategory? sidePanelDefectCategory;
  EquipmentCategory? sidePanelEquipmentCategory;

  String? selectedDefectId;
  String? selectedEquipmentId;
  Offset? selectedMarkerScenePosition;

  int sidePanelTabIndex;

  final Set<DefectCategory> _visibleDefectCategories;
  final Set<EquipmentCategory> _visibleEquipmentCategories;
  final List<DefectCategory> _defectTabs;

  Set<DefectCategory> get visibleDefectCategories => _visibleDefectCategories;

  Set<EquipmentCategory> get visibleEquipmentCategories =>
      _visibleEquipmentCategories;

  List<DefectCategory> get defectTabs => _defectTabs;
}
