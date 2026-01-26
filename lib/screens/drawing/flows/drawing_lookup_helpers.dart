import 'package:flutter/material.dart';
import 'package:safety_inspection_app/constants/strings_ko.dart';
import 'package:safety_inspection_app/models/defect.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/equipment_marker.dart';
import 'package:safety_inspection_app/screens/drawing/drawing_constants.dart';

Color defectColor(DefectCategory category) {
  switch (category) {
    case DefectCategory.generalCrack:
      return Colors.red;
    case DefectCategory.waterLeakage:
      return Colors.blue;
    case DefectCategory.concreteSpalling:
      return Colors.green;
    case DefectCategory.other:
      return Colors.purple;
  }
}

String equipmentLabelPrefix(EquipmentCategory category) {
  if (category == EquipmentCategory.equipment8) {
    return 'Lx';
  }
  return DrawingEquipmentFlowConfigs[category]?.labelPrefix ?? '';
}

String equipmentDisplayLabel(EquipmentMarker marker) {
  if (marker.category == EquipmentCategory.equipment8) {
    return '부동침하 ${marker.label}';
  }
  final config = DrawingEquipmentFlowConfigs[marker.category];
  final labelPrefix = config?.displayLabelPrefix;
  if (labelPrefix == null || labelPrefix.isEmpty) {
    return marker.label;
  }
  return '$labelPrefix ${marker.label}';
}

Color equipmentColor(EquipmentCategory category) {
  if (category == EquipmentCategory.equipment8) {
    return Colors.deepPurpleAccent;
  }
  return DrawingEquipmentFlowConfigs[category]?.color ?? Colors.pinkAccent;
}

List<String> defectTypeOptions(DefectCategory category) {
  switch (category) {
    case DefectCategory.generalCrack:
      return StringsKo.defectTypesGeneralCrack;
    case DefectCategory.waterLeakage:
      return StringsKo.defectTypesWaterLeakage;
    case DefectCategory.concreteSpalling:
      return StringsKo.defectTypesConcreteSpalling;
    case DefectCategory.other:
      return StringsKo.defectTypesOther;
  }
}

List<String> defectCauseOptions(DefectCategory category) {
  switch (category) {
    case DefectCategory.generalCrack:
      return StringsKo.defectCausesGeneralCrack;
    case DefectCategory.waterLeakage:
      return StringsKo.defectCausesWaterLeakage;
    case DefectCategory.concreteSpalling:
      return StringsKo.defectCausesConcreteSpalling;
    case DefectCategory.other:
      return StringsKo.defectCausesOther;
  }
}

String defectDialogTitle(DefectCategory category) {
  switch (category) {
    case DefectCategory.generalCrack:
      return StringsKo.defectDetailsTitleGeneralCrack;
    case DefectCategory.waterLeakage:
      return StringsKo.defectDetailsTitleWaterLeakage;
    case DefectCategory.concreteSpalling:
      return StringsKo.defectDetailsTitleConcreteSpalling;
    case DefectCategory.other:
      return StringsKo.defectDetailsTitleOther;
  }
}

String formatNumber(double value) {
  if (value % 1 == 0) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(1);
}
