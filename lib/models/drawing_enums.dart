enum DrawingType { pdf, blank }

enum DrawMode { hand, defect, equipment, freeDraw, eraser }

enum DefectCategory {
  generalCrack,
  waterLeakage,
  concreteSpalling,
  steelDefect,
  other,
}

enum EquipmentCategory {
  equipment1,
  equipment2,
  equipment3,
  equipment4,
  equipment5,
  equipment6,
  equipment7,
  equipment8,
}

const List<EquipmentCategory> kEquipmentCategoryOrder = [
  EquipmentCategory.equipment1,
  EquipmentCategory.equipment2,
  EquipmentCategory.equipment3,
  EquipmentCategory.equipment4,
  EquipmentCategory.equipment5,
  EquipmentCategory.equipment6,
  EquipmentCategory.equipment7,
  EquipmentCategory.equipment8,
];
