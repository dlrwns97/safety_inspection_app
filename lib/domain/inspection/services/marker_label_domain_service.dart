import 'package:safety_inspection_app/models/defect.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/equipment_marker.dart';
import 'package:safety_inspection_app/models/rebar_spacing_group_details.dart';
import 'package:safety_inspection_app/models/site.dart';

class MarkerLabelDomainService {
  const MarkerLabelDomainService();

  static const Map<DefectCategory, String> _defectCategoryLabelPrefixes = {
    DefectCategory.generalCrack: 'C',
    DefectCategory.waterLeakage: '',
    DefectCategory.concreteSpalling: '',
    DefectCategory.steelDefect: '',
    DefectCategory.other: '',
  };

  String defectPrefixForCategory(DefectCategory category) {
    return _defectCategoryLabelPrefixes[category] ?? '';
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
    if (marker.category == EquipmentCategory.equipment2) {
      final group = RebarSpacingGroupDetails.fromJsonString(marker.details);
      if (group != null) {
        return group.rangeLabel();
      }
      final trimmedLabel = marker.label.trim();
      final isRangeLabel = RegExp(r'^[A-Za-z]+\d+(?:~\d+)?$').hasMatch(
        trimmedLabel,
      );
      if (isRangeLabel) {
        return trimmedLabel;
      }
    }
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
    final resolvedIndex =
        indexById != -1 ? indexById : markers.indexOf(marker);
    return resolvedIndex == -1 ? 0 : resolvedIndex + 1;
  }
}
