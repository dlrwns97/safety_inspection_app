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
  final indexById = equipment.id.isNotEmpty
      ? allEquipment.indexWhere((item) => item.id == equipment.id)
      : -1;
  final resolvedIndex =
      indexById != -1 ? indexById : allEquipment.indexOf(equipment);
  return resolvedIndex == -1 ? 0 : resolvedIndex + 1;
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
  final number = equipmentGlobalNumber(
    equipment: marker,
    allEquipment: allEquipment,
  );
  return [number.toString()];
}
