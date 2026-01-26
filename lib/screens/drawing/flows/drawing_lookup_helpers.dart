import 'package:flutter/material.dart';
import 'package:safety_inspection_app/constants/strings_ko.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/equipment_marker.dart';
import 'package:safety_inspection_app/screens/drawing/drawing_constants.dart';

class DefectCategoryConfig {
  const DefectCategoryConfig({
    required this.label,
    required this.dialogTitle,
    required this.color,
    required this.labelPrefix,
    required this.typeOptions,
    required this.causeOptions,
  });

  final String label;
  final String dialogTitle;
  final Color color;
  final String labelPrefix;
  final List<String> typeOptions;
  final List<String> causeOptions;
}

const Map<DefectCategory, DefectCategoryConfig> defectCategoryConfigs = {
  DefectCategory.generalCrack: DefectCategoryConfig(
    label: StringsKo.defectCategoryGeneralCrack,
    dialogTitle: StringsKo.defectDetailsTitleGeneralCrack,
    color: Colors.red,
    labelPrefix: 'C',
    typeOptions: StringsKo.defectTypesGeneralCrack,
    causeOptions: StringsKo.defectCausesGeneralCrack,
  ),
  DefectCategory.waterLeakage: DefectCategoryConfig(
    label: StringsKo.defectCategoryWaterLeakage,
    dialogTitle: StringsKo.defectDetailsTitleWaterLeakage,
    color: Colors.blue,
    labelPrefix: '',
    typeOptions: StringsKo.defectTypesWaterLeakage,
    causeOptions: StringsKo.defectCausesWaterLeakage,
  ),
  DefectCategory.concreteSpalling: DefectCategoryConfig(
    label: StringsKo.defectCategoryConcreteSpalling,
    dialogTitle: StringsKo.defectDetailsTitleConcreteSpalling,
    color: Colors.green,
    labelPrefix: '',
    typeOptions: StringsKo.defectTypesConcreteSpalling,
    causeOptions: StringsKo.defectCausesConcreteSpalling,
  ),
  DefectCategory.other: DefectCategoryConfig(
    label: StringsKo.defectCategoryOther,
    dialogTitle: StringsKo.defectDetailsTitleOther,
    color: Colors.purple,
    labelPrefix: '',
    typeOptions: StringsKo.defectTypesOther,
    causeOptions: StringsKo.defectCausesOther,
  ),
};

DefectCategoryConfig _defectConfig(DefectCategory category) {
  return defectCategoryConfigs[category]!;
}

DefectCategoryConfig defectCategoryConfig(DefectCategory category) {
  return _defectConfig(category);
}

String defectLabelPrefix(DefectCategory category) {
  return _defectConfig(category).labelPrefix;
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

String formatNumber(double value) {
  if (value % 1 == 0) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(1);
}
