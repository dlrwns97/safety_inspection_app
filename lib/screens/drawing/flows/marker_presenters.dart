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

String? _nonEmpty(String? value) =>
    value != null && value.isNotEmpty ? value : null;

String? _line(String label, String? value) {
  final resolvedValue = _nonEmpty(value);
  if (resolvedValue == null) {
    return null;
  }
  return '$label: $resolvedValue';
}

void _addLine(List<String> lines, String? line) {
  if (line != null) {
    lines.add(line);
  }
}

List<String> equipmentPopupLines(EquipmentMarker marker) {
  List<String> baseLines(EquipmentMarker marker) =>
      <String>[equipmentDisplayLabel(marker)];
  void addMemberTypeIfPresent(EquipmentMarker marker, List<String> lines) =>
      _addLine(lines, _nonEmpty(marker.memberType));
  void addLabeledValue(
    List<String> lines,
    String label,
    String? value,
  ) =>
      _addLine(lines, _line(label, value));

  final buildersByType = <String, List<String> Function(EquipmentMarker)>{
    'F': (marker) {
      final lines = baseLines(marker);
      addMemberTypeIfPresent(marker, lines);
      addLabeledValue(lines, '번호', marker.numberText);
      return lines;
    },
    'SH': (marker) {
      final lines = baseLines(marker);
      addMemberTypeIfPresent(marker, lines);
      addLabeledValue(lines, '최댓값', marker.maxValueText);
      addLabeledValue(lines, '최솟값', marker.minValueText);
      return lines;
    },
    'Co': (marker) {
      final lines = baseLines(marker);
      addMemberTypeIfPresent(marker, lines);
      addLabeledValue(lines, '평균값', marker.avgValueText);
      return lines;
    },
    'Ch': (marker) {
      final lines = baseLines(marker);
      addMemberTypeIfPresent(marker, lines);
      addLabeledValue(lines, '피복두께', marker.coverThicknessText);
      addLabeledValue(lines, '깊이', marker.depthText);
      return lines;
    },
    'Tr': (marker) {
      final lines = baseLines(marker);
      addLabeledValue(lines, '방향', marker.tiltDirection);
      addLabeledValue(lines, '변위량', marker.displacementText);
      return lines;
    },
    'L': (marker) {
      final lines = baseLines(marker);
      addMemberTypeIfPresent(marker, lines);
      addLabeledValue(lines, 'A(단부)', marker.deflectionEndAText);
      addLabeledValue(lines, 'B(중앙)', marker.deflectionMidBText);
      addLabeledValue(lines, 'C(단부)', marker.deflectionEndCText);
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
    _addLine(lines, _line('방향', direction));
    addLabeledValue(lines, '변위량', marker.displacementText);
    return lines;
  }
  if (builder != null) {
    return builder(marker);
  }
  return [marker.label, marker.category.label];
}
