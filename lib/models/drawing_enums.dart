import '../constants/strings_ko.dart';

enum DrawingType { pdf, blank }

enum DrawMode { defect, equipment, freeDraw, eraser }

enum DefectCategory {
  generalCrack(StringsKo.defectCategoryGeneralCrack),
  waterLeakage(StringsKo.defectCategoryWaterLeakage),
  concreteSpalling(StringsKo.defectCategoryConcreteSpalling),
  other(StringsKo.defectCategoryOther);

  const DefectCategory(this.label);
  final String label;
}
