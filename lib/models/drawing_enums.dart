import '../constants/strings_ko.dart';

enum DrawingType { pdf, blank }

enum DrawMode { hand, defect, equipment, freeDraw, eraser }

enum DefectCategory {
  generalCrack(StringsKo.defectCategoryGeneralCrack),
  waterLeakage(StringsKo.defectCategoryWaterLeakage),
  concreteSpalling(StringsKo.defectCategoryConcreteSpalling),
  other(StringsKo.defectCategoryOther);

  const DefectCategory(this.label);
  final String label;
}

enum EquipmentCategory {
  equipment1(StringsKo.equipmentCategory1),
  equipment2(StringsKo.equipmentCategory2),
  equipment3(StringsKo.equipmentCategory3),
  equipment4(StringsKo.equipmentCategory4),
  equipment5(StringsKo.equipmentCategory5);

  const EquipmentCategory(this.label);
  final String label;
}
