import '../constants/strings_ko.dart';

enum DrawingType { pdf, blank }

enum DrawMode { hand, defect, equipment, freeDraw, eraser }

enum DefectCategory {
  generalCrack(StringsKo.defectCategoryGeneralCrack),
  waterLeakage(StringsKo.defectCategoryWaterLeakage),
  concreteSpalling(StringsKo.defectCategoryConcreteSpalling),
  steelDefect(StringsKo.defectCategorySteelDefect),
  other(StringsKo.defectCategoryOther);

  const DefectCategory(this.label);
  final String label;
}

enum EquipmentCategory {
  equipment1(StringsKo.equipmentCategory1),
  equipment2(StringsKo.equipmentCategory2),
  equipment3(StringsKo.equipmentCategory3),
  equipment4(StringsKo.equipmentCategory4),
  equipment5(StringsKo.equipmentCategory5),
  equipment6(StringsKo.equipmentCategory6),
  equipment7(StringsKo.equipmentCategory7),
  equipment8(StringsKo.equipmentCategory8);

  const EquipmentCategory(this.label);
  final String label;
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

extension EquipmentCategoryUiLabel on EquipmentCategory {
  String get shortLabel {
    switch (this) {
      case EquipmentCategory.equipment1:
        return '치수';
      case EquipmentCategory.equipment2:
        return '철근';
      case EquipmentCategory.equipment3:
        return '슈미트';
      case EquipmentCategory.equipment4:
        return '코어';
      case EquipmentCategory.equipment5:
        return '탄산화';
      case EquipmentCategory.equipment6:
        return '기울기';
      case EquipmentCategory.equipment7:
        return '처짐';
      case EquipmentCategory.equipment8:
        return '부동침하';
    }
  }
}
