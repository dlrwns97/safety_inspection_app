import 'package:safety_inspection_app/models/defect.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/equipment_marker.dart';
import 'package:safety_inspection_app/models/site.dart';
import 'package:safety_inspection_app/screens/drawing/flows/drawing_lookup_helpers.dart';

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
