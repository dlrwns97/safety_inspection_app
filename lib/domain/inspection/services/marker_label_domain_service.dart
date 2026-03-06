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

  String defectDisplayLabel(Defect defect, {List<Defect>? allDefects}) {
    if (allDefects != null) {
      final sequence = defectSequenceWithinPageCategory(defect, allDefects);
      if (sequence > 0) {
        return '${defectPrefixForCategory(defect.category)}$sequence';
      }
    }
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

  int defectSequenceWithinPageCategory(Defect defect, List<Defect> allDefects) {
    final pageCategoryDefects = allDefects
        .where(
          (item) =>
              item.pageIndex == defect.pageIndex &&
              item.category == defect.category,
        )
        .toList();
    final indexById = defect.id.isNotEmpty
        ? pageCategoryDefects.indexWhere((item) => item.id == defect.id)
        : -1;
    final resolvedIndex = indexById != -1
        ? indexById
        : pageCategoryDefects.indexOf(defect);
    return resolvedIndex == -1 ? 0 : resolvedIndex + 1;
  }

  int defectNumberForPage({
    required Defect defect,
    required int pageIndex,
    required List<Defect> allDefects,
  }) {
    final pageDefects = allDefects
        .where((item) => item.pageIndex == pageIndex)
        .toList();
    final indexById = defect.id.isNotEmpty
        ? pageDefects.indexWhere((item) => item.id == defect.id)
        : -1;
    final resolvedIndex = indexById != -1
        ? indexById
        : pageDefects.indexOf(defect);
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
    final indexById = equipment.id.isNotEmpty
        ? allEquipment.indexWhere((item) => item.id == equipment.id)
        : -1;
    final resolvedIndex = indexById != -1
        ? indexById
        : allEquipment.indexOf(equipment);
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
    final categoryMarkers = all
        .where((item) => item.category == marker.category)
        .toList();
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
    final directionMarkers = all
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
      final displayGroup = equipment2DisplayGroup(marker, all);
      if (displayGroup != null) {
        return displayGroup.rangeLabel();
      }
      final start = _equipment2SequenceStart(marker, all);
      if (start <= 0) {
        return marker.label;
      }
      final count = _equipment2SlotCount(marker);
      final prefix = _equipment2DisplayPrefix(marker);
      if (count <= 1) {
        return '$prefix$start';
      }
      return '$prefix$start~${start + count - 1}';
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

  RebarSpacingGroupDetails? equipment2DisplayGroup(
    EquipmentMarker marker,
    List<EquipmentMarker> all,
  ) {
    if (marker.category != EquipmentCategory.equipment2) {
      return null;
    }
    final group = RebarSpacingGroupDetails.fromJsonString(marker.details);
    if (group == null) {
      return null;
    }
    final start = _equipment2SequenceStart(marker, all);
    if (start <= 0) {
      return group;
    }
    return RebarSpacingGroupDetails(
      baseLabelIndex: start,
      labelPrefix: _equipment2DisplayPrefix(marker, group: group),
      memberType: group.memberType,
      measurements: group.measurements,
    );
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
    final indexById = marker.id.isNotEmpty
        ? markers.indexWhere((item) => item.id == marker.id)
        : -1;
    final resolvedIndex = indexById != -1 ? indexById : markers.indexOf(marker);
    return resolvedIndex == -1 ? 0 : resolvedIndex + 1;
  }

  int _equipment2SequenceStart(
    EquipmentMarker marker,
    List<EquipmentMarker> all,
  ) {
    final equipment2Markers = all
        .where((item) => item.category == EquipmentCategory.equipment2)
        .toList();
    final indexById = marker.id.isNotEmpty
        ? equipment2Markers.indexWhere((item) => item.id == marker.id)
        : -1;
    final resolvedIndex = indexById != -1
        ? indexById
        : equipment2Markers.indexOf(marker);
    if (resolvedIndex == -1) {
      return 0;
    }
    var start = 1;
    for (var i = 0; i < resolvedIndex; i += 1) {
      start += _equipment2SlotCount(equipment2Markers[i]);
    }
    return start;
  }

  int _equipment2SlotCount(EquipmentMarker marker) {
    final group = RebarSpacingGroupDetails.fromJsonString(marker.details);
    if (group != null) {
      return group.measurements.isEmpty ? 1 : group.measurements.length;
    }
    final label = marker.label.trim();
    final match = RegExp(r'^[A-Za-z]+(\d+)(?:~(\d+))?$').firstMatch(label);
    if (match == null) {
      return 1;
    }
    final start = int.tryParse(match.group(1) ?? '');
    final end = int.tryParse(match.group(2) ?? '');
    if (start != null && end != null && end >= start) {
      return end - start + 1;
    }
    return 1;
  }

  String _equipment2DisplayPrefix(
    EquipmentMarker marker, {
    RebarSpacingGroupDetails? group,
  }) {
    final rawPrefix = group?.labelPrefix ?? equipmentPrefixFor(marker.category);
    if (rawPrefix.trim().isEmpty) {
      return _normalizeSymbolCase(equipmentPrefixFor(marker.category));
    }
    return _normalizeSymbolCase(rawPrefix);
  }
}
