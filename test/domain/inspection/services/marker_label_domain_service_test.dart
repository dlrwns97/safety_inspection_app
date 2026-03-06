import 'package:flutter_test/flutter_test.dart';
import 'package:safety_inspection_app/domain/inspection/services/marker_label_domain_service.dart';
import 'package:safety_inspection_app/models/defect.dart';
import 'package:safety_inspection_app/models/defect_details.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/equipment_marker.dart';
import 'package:safety_inspection_app/models/rebar_spacing_group_details.dart';
import 'package:safety_inspection_app/models/site.dart';

Defect _defect({
  required String id,
  required String label,
  required DefectCategory category,
  int pageIndex = 1,
}) {
  return Defect(
    id: id,
    label: label,
    pageIndex: pageIndex,
    category: category,
    normalizedX: 0.1,
    normalizedY: 0.2,
    details: DefectDetails(
      structuralMember: '',
      crackType: '',
      widthMm: 0,
      lengthMm: 0,
      cause: '',
    ),
  );
}

EquipmentMarker _equipment({
  required String id,
  required String label,
  required EquipmentCategory category,
  String? tiltDirection,
  String? equipmentTypeId,
  String? details,
}) {
  return EquipmentMarker(
    id: id,
    label: label,
    pageIndex: 1,
    category: category,
    normalizedX: 0.1,
    normalizedY: 0.2,
    tiltDirection: tiltDirection,
    equipmentTypeId: equipmentTypeId,
    details: details,
  );
}

void main() {
  group('MarkerLabelDomainService', () {
    const service = MarkerLabelDomainService();

    test('defect prefix map and fallback label parsing are correct', () {
      final crack = _defect(
        id: 'd1',
        label: 'X12',
        category: DefectCategory.generalCrack,
      );
      final leakage = _defect(
        id: 'd2',
        label: 'W34',
        category: DefectCategory.waterLeakage,
      );
      final raw = _defect(
        id: 'd3',
        label: 'NO_NUMBER',
        category: DefectCategory.generalCrack,
      );

      expect(service.defectPrefixForCategory(DefectCategory.generalCrack), 'C');
      expect(
        service.defectPrefixForCategory(DefectCategory.waterLeakage),
        isEmpty,
      );
      expect(service.defectDisplayLabel(crack), 'C12');
      expect(service.defectDisplayLabel(leakage), '34');
      expect(service.defectDisplayLabel(raw), 'NO_NUMBER');
    });

    test('defect sequence is recalculated by same page and category only', () {
      final d1 = _defect(
        id: 'd1',
        label: 'C1',
        category: DefectCategory.generalCrack,
      );
      final d3 = _defect(
        id: 'd3',
        label: 'C3',
        category: DefectCategory.generalCrack,
      );
      final samePageOtherCategory = _defect(
        id: 'w1',
        label: '1',
        category: DefectCategory.waterLeakage,
      );
      final otherPage = _defect(
        id: 'd4',
        label: 'C4',
        category: DefectCategory.generalCrack,
        pageIndex: 2,
      );
      final all = <Defect>[d1, samePageOtherCategory, d3, otherPage];

      expect(service.defectDisplayLabel(d1, allDefects: all), 'C1');
      expect(service.defectDisplayLabel(d3, allDefects: all), 'C2');
      expect(service.defectSequenceWithinPageCategory(d3, all), 2);
      expect(
        service.defectNumberForPage(defect: d3, pageIndex: 1, allDefects: all),
        3,
      );
    });

    test('settlement direction/index is separated by axis and category', () {
      final eq8x1 = _equipment(
        id: 'x1',
        label: 'tmp',
        category: EquipmentCategory.equipment8,
        tiltDirection: 'lx',
      );
      final eq8x2 = _equipment(
        id: 'x2',
        label: 'tmp',
        category: EquipmentCategory.equipment8,
        tiltDirection: 'lx',
      );
      final eq8y = _equipment(
        id: 'y1',
        label: 'tmp',
        category: EquipmentCategory.equipment8,
        tiltDirection: 'ly',
      );
      final nonSettlement = _equipment(
        id: 'n1',
        label: 'tmp',
        category: EquipmentCategory.equipment7,
        tiltDirection: 'lx',
      );

      final site = Site(
        id: 's1',
        name: 'site',
        createdAt: DateTime(2026, 3, 6),
        drawingType: DrawingType.blank,
        equipmentMarkers: [eq8x1, eq8x2, eq8y, nonSettlement],
      );

      expect(service.nextSettlementIndex(site, 'lx'), 3);
      expect(service.nextSettlementIndex(site, 'ly'), 2);
      expect(service.settlementDirection(eq8x1), 'lx');
      expect(
        service.settlementDirection(
          _equipment(
            id: 'fallback',
            label: 'tmp',
            category: EquipmentCategory.equipment8,
            equipmentTypeId: 'Lx',
          ),
        ),
        'Lx',
      );
      expect(
        service.settlementDirection(
          _equipment(
            id: 'none',
            label: 'tmp',
            category: EquipmentCategory.equipment8,
            equipmentTypeId: 'other',
          ),
        ),
        isNull,
      );
    });

    test('equipment2 grouped labels are compacted and normalized', () {
      final group123 = RebarSpacingGroupDetails(
        baseLabelIndex: 1,
        labelPrefix: 'f',
        memberType: '기둥',
        measurements: const [
          RebarSpacingMeasurement(),
          RebarSpacingMeasurement(),
          RebarSpacingMeasurement(),
        ],
      );
      final group4 = RebarSpacingGroupDetails(
        baseLabelIndex: 4,
        labelPrefix: 'f',
        memberType: '기둥',
        measurements: const [RebarSpacingMeasurement()],
      );
      final grouped = _equipment(
        id: 'g123',
        label: 'F1~3',
        category: EquipmentCategory.equipment2,
        details: group123.toJsonString(),
      );
      final single = _equipment(
        id: 'g4',
        label: 'F4',
        category: EquipmentCategory.equipment2,
        details: group4.toJsonString(),
      );

      final beforeDelete = <EquipmentMarker>[grouped, single];
      final afterDelete = <EquipmentMarker>[single];

      expect(service.equipmentDisplayLabel(grouped, beforeDelete), 'F1~3');
      expect(service.equipmentDisplayLabel(single, beforeDelete), 'F4');
      expect(service.equipmentDisplayLabel(single, afterDelete), 'F1');

      final compacted = service.equipment2DisplayGroup(single, afterDelete);
      expect(compacted, isNotNull);
      expect(compacted!.baseLabelIndex, 1);
      expect(compacted.labelPrefix, 'F');
      expect(compacted.rangeLabel(), 'F1');
    });

    test('equipment8 label/sequence and global number are stable', () {
      final l1 = _equipment(
        id: 'l1',
        label: 'tmp',
        category: EquipmentCategory.equipment8,
        tiltDirection: 'lx',
      );
      final l2 = _equipment(
        id: 'l2',
        label: 'tmp',
        category: EquipmentCategory.equipment8,
        tiltDirection: 'lx',
      );
      final y1 = _equipment(
        id: 'y1',
        label: 'tmp',
        category: EquipmentCategory.equipment8,
        tiltDirection: 'ly',
      );
      final all = <EquipmentMarker>[l1, l2, y1];

      expect(service.equipmentDisplayLabel(l1, all), 'Lx1');
      expect(service.equipmentDisplayLabel(l2, all), 'Lx2');
      expect(service.equipmentDisplayLabel(y1, all), 'Ly1');
      expect(service.settlementSequenceWithinDirection(l2, all), 2);
      expect(
        service.equipmentGlobalNumber(equipment: y1, allEquipment: all),
        3,
      );
    });
  });
}
