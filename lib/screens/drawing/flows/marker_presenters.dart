import 'package:safety_inspection_app/models/defect.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/equipment_marker.dart';
import 'package:safety_inspection_app/models/rebar_spacing_group_details.dart';
import 'package:safety_inspection_app/models/site.dart';
import 'package:safety_inspection_app/domain/inspection/services/marker_label_domain_service.dart';
import 'package:safety_inspection_app/constants/strings_ko.dart';

const _markerLabelDomainService = MarkerLabelDomainService();

String defectPrefixForCategory(DefectCategory category) {
  return _markerLabelDomainService.defectPrefixForCategory(category);
}

String defectDisplayLabel(Defect defect, {List<Defect>? allDefects}) {
  return _markerLabelDomainService.defectDisplayLabel(
    defect,
    allDefects: allDefects,
  );
}

String defectPanelTitle(Defect defect, {List<Defect>? allDefects}) {
  return defectDisplayLabel(defect, allDefects: allDefects);
}

String? settlementDirection(EquipmentMarker marker) {
  return _markerLabelDomainService.settlementDirection(marker);
}

int nextSettlementIndex(Site site, String direction) {
  return _markerLabelDomainService.nextSettlementIndex(site, direction);
}

int defectNumberForPage({
  required Defect defect,
  required int pageIndex,
  required List<Defect> allDefects,
}) {
  return _markerLabelDomainService.defectNumberForPage(
    defect: defect,
    pageIndex: pageIndex,
    allDefects: allDefects,
  );
}

int equipmentGlobalNumber({
  required EquipmentMarker equipment,
  required List<EquipmentMarker> allEquipment,
}) {
  return _markerLabelDomainService.equipmentGlobalNumber(
    equipment: equipment,
    allEquipment: allEquipment,
  );
}

String equipmentPrefixFor(EquipmentCategory category) {
  return _markerLabelDomainService.equipmentPrefixFor(category);
}

int equipmentSequenceWithinCategory(
  EquipmentMarker marker,
  List<EquipmentMarker> all,
) {
  return _markerLabelDomainService.equipmentSequenceWithinCategory(marker, all);
}

int settlementSequenceWithinDirection(
  EquipmentMarker marker,
  List<EquipmentMarker> all,
) {
  return _markerLabelDomainService.settlementSequenceWithinDirection(
    marker,
    all,
  );
}

String equipmentDisplayLabel(
  EquipmentMarker marker,
  List<EquipmentMarker> all,
) {
  return _markerLabelDomainService.equipmentDisplayLabel(marker, all);
}

RebarSpacingGroupDetails? equipment2DisplayGroup(
  EquipmentMarker marker,
  List<EquipmentMarker> all,
) {
  return _markerLabelDomainService.equipment2DisplayGroup(marker, all);
}

String equipmentPanelTitle(EquipmentMarker marker, List<EquipmentMarker> all) {
  final label = equipmentDisplayLabel(marker, all).trim();
  final categoryName = equipmentCategoryDisplayNameKo(marker.category).trim();
  if (label.isEmpty) return categoryName;
  return '$label $categoryName';
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

String defectCategoryDisplayNameKo(DefectCategory category) {
  switch (category) {
    case DefectCategory.generalCrack:
      return StringsKo.defectCategoryGeneralCrack;
    case DefectCategory.waterLeakage:
      return StringsKo.defectCategoryWaterLeakage;
    case DefectCategory.concreteSpalling:
      return StringsKo.defectCategoryConcreteSpalling;
    case DefectCategory.steelDefect:
      return StringsKo.defectCategorySteelDefect;
    case DefectCategory.other:
      return StringsKo.defectCategoryOther;
  }
}

String equipmentCategoryDisplayNameKo(EquipmentCategory category) {
  switch (category) {
    case EquipmentCategory.equipment1:
      return StringsKo.equipmentCategory1;
    case EquipmentCategory.equipment2:
      return StringsKo.equipmentCategory2;
    case EquipmentCategory.equipment3:
      return StringsKo.equipmentCategory3;
    case EquipmentCategory.equipment4:
      return StringsKo.equipmentCategory4;
    case EquipmentCategory.equipment5:
      return StringsKo.equipmentCategory5;
    case EquipmentCategory.equipment6:
      return StringsKo.equipmentCategory6;
    case EquipmentCategory.equipment7:
      return StringsKo.equipmentCategory7;
    case EquipmentCategory.equipment8:
      return StringsKo.equipmentCategory8;
  }
}

List<String> defectPopupLines({
  required Defect defect,
  required int pageIndex,
  required List<Defect> allDefects,
}) {
  final number = _markerLabelDomainService.defectNumberForPage(
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
  final label = _markerLabelDomainService.equipmentDisplayLabel(
    marker,
    allEquipment,
  );
  return [label];
}
