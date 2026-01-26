import 'package:flutter/material.dart';
import 'package:safety_inspection_app/constants/strings_ko.dart';
import 'package:safety_inspection_app/models/defect.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/equipment_marker.dart';

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
  switch (category) {
    case EquipmentCategory.equipment1:
      return 'S';
    case EquipmentCategory.equipment2:
      return 'F';
    case EquipmentCategory.equipment3:
      return 'SH';
    case EquipmentCategory.equipment4:
      return 'Co';
    case EquipmentCategory.equipment5:
      return 'Ch';
    case EquipmentCategory.equipment6:
      return 'Tr';
    case EquipmentCategory.equipment7:
      return 'L';
    case EquipmentCategory.equipment8:
      return 'Lx';
  }
}

String equipmentDisplayLabel(EquipmentMarker marker) {
  if (marker.category == EquipmentCategory.equipment8) {
    return '부동침하 ${marker.label}';
  }
  if (marker.equipmentTypeId == 'F') {
    return '철근배근간격 ${marker.label}';
  }
  if (marker.equipmentTypeId == 'SH') {
    return '슈미트해머 ${marker.label}';
  }
  if (marker.equipmentTypeId == 'Co') {
    return '코어채취 ${marker.label}';
  }
  if (marker.equipmentTypeId == 'Ch') {
    return '콘크리트 탄산화 ${marker.label}';
  }
  if (marker.equipmentTypeId == 'Tr') {
    return '구조물 기울기 ${marker.label}';
  }
  if (marker.equipmentTypeId == 'L') {
    return '부재처짐 ${marker.label}';
  }
  return marker.label;
}

Color equipmentColor(EquipmentCategory category) {
  switch (category) {
    case EquipmentCategory.equipment1:
      return Colors.pinkAccent;
    case EquipmentCategory.equipment2:
      return Colors.lightBlueAccent;
    case EquipmentCategory.equipment3:
    case EquipmentCategory.equipment4:
      return Colors.green;
    case EquipmentCategory.equipment5:
      return Colors.orangeAccent;
    case EquipmentCategory.equipment6:
      return Colors.tealAccent;
    case EquipmentCategory.equipment7:
      return Colors.indigoAccent;
    case EquipmentCategory.equipment8:
      return Colors.deepPurpleAccent;
  }
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
