import 'package:safety_inspection_app/models/defect.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/equipment_marker.dart';
import 'package:safety_inspection_app/models/site.dart';
import 'package:safety_inspection_app/constants/strings_ko.dart';

const Map<DefectCategory, String> defectCategoryLabelPrefixes = {
  DefectCategory.generalCrack: 'C',
  DefectCategory.waterLeakage: '',
  DefectCategory.concreteSpalling: '',
  DefectCategory.steelDefect: '',
  DefectCategory.other: '',
};

String defectPrefixForCategory(DefectCategory category) {
  return defectCategoryLabelPrefixes[category] ?? '';
}

String defectDisplayLabel(Defect defect) {
  final match = RegExp(r'(\d+)$').firstMatch(defect.label);
  if (match == null) {
    return defect.label;
  }
  final digits = match.group(1);
  if (digits == null || digits.isEmpty) {
    return defect.label;
  }
  return '${defectPrefixForCategory(defect.category)}$digits';
}

String defectPanelTitle(Defect defect) {
  return defectDisplayLabel(defect);
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

String _normalizeSymbolCase(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return raw;

  final isSymbol = RegExp(r'^[A-Za-z]+[0-9]*$').hasMatch(s);
  if (!isSymbol) return raw;

  final runes = s.runes.toList();
  final first = String.fromCharCode(runes.first).toUpperCase();
  final rest = String.fromCharCodes(runes.skip(1)).toLowerCase();
  return '$first$rest';
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
    final normalizedDirection = _normalizeSymbolCase(direction);
    return '$normalizedDirection$sequence';
  }
  final prefix = equipmentPrefixFor(marker.category);
  if (prefix.isEmpty) {
    return marker.label;
  }
  final sequence = equipmentSequenceWithinCategory(marker, all);
  if (sequence <= 0) {
    return marker.label;
  }
  final normalizedPrefix = _normalizeSymbolCase(prefix);
  return '$normalizedPrefix$sequence';
}

String equipmentPanelTitle(EquipmentMarker marker, List<EquipmentMarker> all) {
  final label = equipmentDisplayLabel(marker, all).trim();
  final categoryName = equipmentCategoryDisplayNameKo(marker.category).trim();
  if (label.isEmpty) return categoryName;
  return '$label $categoryName';
}

String equipmentChipLabel(EquipmentCategory category) {
  return category.shortLabel;
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
