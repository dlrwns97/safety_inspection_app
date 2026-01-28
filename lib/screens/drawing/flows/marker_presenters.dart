import 'package:safety_inspection_app/models/defect.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/equipment_marker.dart';
import 'package:safety_inspection_app/models/site.dart';

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

int defectNumberForPage({
  required Defect defect,
  required int pageIndex,
  required List<Defect> allDefects,
}) {
  final pageDefects =
      allDefects.where((item) => item.pageIndex == pageIndex).toList();
  final indexById =
      defect.id.isNotEmpty
          ? pageDefects.indexWhere((item) => item.id == defect.id)
          : -1;
  final resolvedIndex =
      indexById != -1 ? indexById : pageDefects.indexOf(defect);
  return resolvedIndex == -1 ? 0 : resolvedIndex + 1;
}

int equipmentGlobalNumber({
  required EquipmentMarker equipment,
  required List<EquipmentMarker> allEquipment,
}) {
  final indexById =
      equipment.id.isNotEmpty
          ? allEquipment.indexWhere((item) => item.id == equipment.id)
          : -1;
  final resolvedIndex =
      indexById != -1 ? indexById : allEquipment.indexOf(equipment);
  return resolvedIndex == -1 ? 0 : resolvedIndex + 1;
}

String equipmentPrefixFor(EquipmentCategory category) {
  switch (category) {
    case EquipmentCategory.equipment1:
      return 'S';
    case EquipmentCategory.equipment2:
      return 'F';
    case EquipmentCategory.equipment3:
      return 'Sh';
    case EquipmentCategory.equipment4:
      return 'Co';
    case EquipmentCategory.equipment5:
      return 'Ch';
    case EquipmentCategory.equipment6:
      return 'Tr';
    case EquipmentCategory.equipment7:
      return 'Df';
    case EquipmentCategory.equipment8:
      return '';
  }
}

int _equipmentIndexInList(
  EquipmentMarker marker,
  List<EquipmentMarker> markers,
) {
  final indexById =
      marker.id.isNotEmpty
          ? markers.indexWhere((item) => item.id == marker.id)
          : -1;
  final resolvedIndex = indexById != -1 ? indexById : markers.indexOf(marker);
  return resolvedIndex == -1 ? 0 : resolvedIndex + 1;
}

int equipmentSequenceWithinCategory(
  EquipmentMarker marker,
  List<EquipmentMarker> all,
) {
  final categoryMarkers =
      all.where((item) => item.category == marker.category).toList();
  return _equipmentIndexInList(marker, categoryMarkers);
}

int settlementSequenceWithinDirection(
  EquipmentMarker marker,
  List<EquipmentMarker> all,
) {
  final direction = settlementDirection(marker);
  if (direction == null || direction.isEmpty) {
    return 0;
  }
  final directionMarkers =
      all
          .where(
            (item) =>
                item.category == EquipmentCategory.equipment8 &&
                settlementDirection(item) == direction,
          )
          .toList();
  return _equipmentIndexInList(marker, directionMarkers);
}

String equipmentDisplayLabel(
  EquipmentMarker marker,
  List<EquipmentMarker> all,
) {
  if (marker.category == EquipmentCategory.equipment8) {
    final direction = settlementDirection(marker);
    if (direction == null || direction.isEmpty) {
      return marker.label;
    }
    final sequence = settlementSequenceWithinDirection(marker, all);
    if (sequence <= 0) {
      return marker.label;
    }
    return '$direction$sequence';
  }
  final prefix = equipmentPrefixFor(marker.category);
  if (prefix.isEmpty) {
    return marker.label;
  }
  final sequence = equipmentSequenceWithinCategory(marker, all);
  if (sequence <= 0) {
    return marker.label;
  }
  return '$prefix$sequence';
}

String equipmentChipLabel(EquipmentCategory category) {
  switch (category) {
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

String equipmentCategoryDisplayNameKo(EquipmentCategory category) {
  switch (category) {
    case EquipmentCategory.equipment1:
      return '부재단면치수';
    case EquipmentCategory.equipment2:
      return '철근배근탐사';
    case EquipmentCategory.equipment3:
      return '슈미트해머';
    case EquipmentCategory.equipment4:
      return '코어채취';
    case EquipmentCategory.equipment5:
      return '콘크리트 탄산화';
    case EquipmentCategory.equipment6:
      return '구조물 기울기';
    case EquipmentCategory.equipment7:
      return '부재처짐';
    case EquipmentCategory.equipment8:
      return '구조물 부동침하';
  }
}

List<String> defectPopupLines({
  required Defect defect,
  required int pageIndex,
  required List<Defect> allDefects,
}) {
  final number = defectNumberForPage(
    defect: defect,
    pageIndex: pageIndex,
    allDefects: allDefects,
  );
  return [number.toString()];
}

List<String> equipmentPopupLines({
  required EquipmentMarker marker,
  required List<EquipmentMarker> allEquipment,
}) {
  final label = equipmentDisplayLabel(marker, allEquipment);
  return [label];
}
