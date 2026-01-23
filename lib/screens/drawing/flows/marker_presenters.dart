import 'package:flutter/material.dart';
import 'package:safety_inspection_app/constants/strings_ko.dart';
import 'package:safety_inspection_app/models/defect.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/equipment_marker.dart';
import 'package:safety_inspection_app/models/site.dart';

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

String? settlementDirection(EquipmentMarker marker) {
  final direction = marker.tiltDirection;
  if (direction != null && direction.isNotEmpty) {
    return direction;
  }
  if (marker.equipmentTypeId == 'Lx' || marker.equipmentTypeId == 'Ly') {
    return marker.equipmentTypeId;
  }
  return null;
}

int nextSettlementIndex(Site site, String direction) {
  return site.equipmentMarkers
          .where(
            (marker) =>
                marker.category == EquipmentCategory.equipment8 &&
                settlementDirection(marker) == direction,
          )
          .length +
      1;
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

List<String> defectPopupLines(Defect defect) {
  final details = defect.details;
  return [
    defect.label,
    '${defect.category.label} / ${details.crackType}',
    '${formatNumber(details.widthMm)} / ${formatNumber(details.lengthMm)}',
    details.cause,
  ];
}

List<String> equipmentPopupLines(EquipmentMarker marker) {
  List<String> baseLines(EquipmentMarker marker) =>
      <String>[equipmentDisplayLabel(marker)];
  void addMemberTypeIfPresent(EquipmentMarker marker, List<String> lines) {
    if (marker.memberType != null && marker.memberType!.isNotEmpty) {
      lines.add(marker.memberType!);
    }
  }

  final buildersByType = <String, List<String> Function(EquipmentMarker)>{
    'F': (marker) {
      final lines = baseLines(marker);
      addMemberTypeIfPresent(marker, lines);
      if (marker.numberText != null && marker.numberText!.isNotEmpty) {
        lines.add('번호: ${marker.numberText}');
      }
      return lines;
    },
    'SH': (marker) {
      final lines = baseLines(marker);
      addMemberTypeIfPresent(marker, lines);
      if (marker.maxValueText != null && marker.maxValueText!.isNotEmpty) {
        lines.add('최댓값: ${marker.maxValueText}');
      }
      if (marker.minValueText != null && marker.minValueText!.isNotEmpty) {
        lines.add('최솟값: ${marker.minValueText}');
      }
      return lines;
    },
    'Co': (marker) {
      final lines = baseLines(marker);
      addMemberTypeIfPresent(marker, lines);
      if (marker.avgValueText != null && marker.avgValueText!.isNotEmpty) {
        lines.add('평균값: ${marker.avgValueText}');
      }
      return lines;
    },
    'Ch': (marker) {
      final lines = baseLines(marker);
      addMemberTypeIfPresent(marker, lines);
      if (marker.coverThicknessText != null &&
          marker.coverThicknessText!.isNotEmpty) {
        lines.add('피복두께: ${marker.coverThicknessText}');
      }
      if (marker.depthText != null && marker.depthText!.isNotEmpty) {
        lines.add('깊이: ${marker.depthText}');
      }
      return lines;
    },
    'Tr': (marker) {
      final lines = baseLines(marker);
      if (marker.tiltDirection != null && marker.tiltDirection!.isNotEmpty) {
        lines.add('방향: ${marker.tiltDirection}');
      }
      if (marker.displacementText != null &&
          marker.displacementText!.isNotEmpty) {
        lines.add('변위량: ${marker.displacementText}');
      }
      return lines;
    },
    'L': (marker) {
      final lines = baseLines(marker);
      addMemberTypeIfPresent(marker, lines);
      if (marker.deflectionEndAText != null &&
          marker.deflectionEndAText!.isNotEmpty) {
        lines.add('A(단부): ${marker.deflectionEndAText}');
      }
      if (marker.deflectionMidBText != null &&
          marker.deflectionMidBText!.isNotEmpty) {
        lines.add('B(중앙): ${marker.deflectionMidBText}');
      }
      if (marker.deflectionEndCText != null &&
          marker.deflectionEndCText!.isNotEmpty) {
        lines.add('C(단부): ${marker.deflectionEndCText}');
      }
      return lines;
    },
  };
  final builder = buildersByType[marker.equipmentTypeId];
  if (builder != null && marker.equipmentTypeId != 'L') {
    return builder(marker);
  }
  if (marker.category == EquipmentCategory.equipment8) {
    final lines = <String>[equipmentDisplayLabel(marker)];
    final direction = settlementDirection(marker);
    if (direction != null && direction.isNotEmpty) {
      lines.add('방향: $direction');
    }
    if (marker.displacementText != null &&
        marker.displacementText!.isNotEmpty) {
      lines.add('변위량: ${marker.displacementText}');
    }
    return lines;
  }
  if (builder != null) {
    return builder(marker);
  }
  return [marker.label, marker.category.label];
}

String formatNumber(double value) {
  if (value % 1 == 0) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(1);
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
