import 'package:flutter_test/flutter_test.dart';
import 'package:safety_inspection_app/models/defect.dart';
import 'package:safety_inspection_app/models/defect_details.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/equipment_marker.dart';
import 'package:safety_inspection_app/models/rebar_spacing_group_details.dart';
import 'package:safety_inspection_app/screens/drawing/flows/marker_presenters.dart';

EquipmentMarker _mk({
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
    normalizedY: 0.1,
    tiltDirection: tiltDirection,
    equipmentTypeId: equipmentTypeId,
    details: details,
  );
}

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
    normalizedY: 0.1,
    details: DefectDetails(
      structuralMember: '',
      crackType: '',
      widthMm: 0,
      lengthMm: 0,
      cause: '',
    ),
  );
}

void main() {
  group('equipmentDisplayLabel / equipmentPanelTitle', () {
    test('settlement equipment8 uses axis-separated sequences (Lx/Ly)', () {
      final mX1 = _mk(
        id: 'mx1',
        label: 'tmp',
        category: EquipmentCategory.equipment8,
        tiltDirection: 'lx',
      );
      final mX2 = _mk(
        id: 'mx2',
        label: 'tmp',
        category: EquipmentCategory.equipment8,
        tiltDirection: 'lx',
      );
      final mX3 = _mk(
        id: 'mx3',
        label: 'tmp',
        category: EquipmentCategory.equipment8,
        tiltDirection: 'lx',
      );
      final mY1 = _mk(
        id: 'my1',
        label: 'tmp',
        category: EquipmentCategory.equipment8,
        tiltDirection: 'ly',
      );

      final all = <EquipmentMarker>[mX1, mX2, mX3, mY1];
      final categoryName = equipmentCategoryDisplayNameKo(
        EquipmentCategory.equipment8,
      );

      expect(equipmentDisplayLabel(mX1, all), 'Lx1');
      expect(equipmentDisplayLabel(mX2, all), 'Lx2');
      expect(equipmentDisplayLabel(mX3, all), 'Lx3');
      expect(equipmentDisplayLabel(mY1, all), 'Ly1');

      expect(equipmentPanelTitle(mX3, all), 'Lx3 $categoryName');
      expect(equipmentPanelTitle(mY1, all), 'Ly1 $categoryName');
    });

    test('equipment2 uses prefix+sequence (F1, F2)', () {
      final f1 = _mk(
        id: 'f1',
        label: 'tmp',
        category: EquipmentCategory.equipment2,
      );
      final f2 = _mk(
        id: 'f2',
        label: 'tmp',
        category: EquipmentCategory.equipment2,
      );

      final all = <EquipmentMarker>[f1, f2];
      final categoryName = equipmentCategoryDisplayNameKo(
        EquipmentCategory.equipment2,
      );

      expect(equipmentDisplayLabel(f1, all), 'F1');
      expect(equipmentDisplayLabel(f2, all), 'F2');

      expect(equipmentPanelTitle(f1, all), 'F1 $categoryName');
      expect(equipmentPanelTitle(f2, all), 'F2 $categoryName');
    });

    test('equipment2 is renumbered after middle deletion', () {
      final f1 = _mk(
        id: 'f1',
        label: 'F1',
        category: EquipmentCategory.equipment2,
      );
      final f3 = _mk(
        id: 'f3',
        label: 'F3',
        category: EquipmentCategory.equipment2,
      );
      final afterDelete = <EquipmentMarker>[f1, f3];

      expect(equipmentDisplayLabel(f1, afterDelete), 'F1');
      expect(equipmentDisplayLabel(f3, afterDelete), 'F2');
    });

    test(
      'equipment2 grouped range is compacted after deleting prior range',
      () {
        final group123 = RebarSpacingGroupDetails(
          baseLabelIndex: 1,
          labelPrefix: 'F',
          memberType: '기둥',
          measurements: const [
            RebarSpacingMeasurement(),
            RebarSpacingMeasurement(),
            RebarSpacingMeasurement(),
          ],
        );
        final group4 = RebarSpacingGroupDetails(
          baseLabelIndex: 4,
          labelPrefix: 'F',
          memberType: '기둥',
          measurements: const [RebarSpacingMeasurement()],
        );
        final group5 = RebarSpacingGroupDetails(
          baseLabelIndex: 5,
          labelPrefix: 'F',
          memberType: '기둥',
          measurements: const [RebarSpacingMeasurement()],
        );
        final m123 = _mk(
          id: 'm123',
          label: 'F1~3',
          category: EquipmentCategory.equipment2,
          details: group123.toJsonString(),
        );
        final m4 = _mk(
          id: 'm4',
          label: 'F4',
          category: EquipmentCategory.equipment2,
          details: group4.toJsonString(),
        );
        final m5 = _mk(
          id: 'm5',
          label: 'F5',
          category: EquipmentCategory.equipment2,
          details: group5.toJsonString(),
        );

        expect(
          equipmentDisplayLabel(m123, <EquipmentMarker>[m123, m4, m5]),
          'F1~3',
        );
        expect(
          equipmentDisplayLabel(m4, <EquipmentMarker>[m123, m4, m5]),
          'F4',
        );
        expect(
          equipmentDisplayLabel(m5, <EquipmentMarker>[m123, m4, m5]),
          'F5',
        );

        final afterDelete = <EquipmentMarker>[m4, m5];
        expect(equipmentDisplayLabel(m4, afterDelete), 'F1');
        expect(equipmentDisplayLabel(m5, afterDelete), 'F2');
      },
    );
  });

  group('defectDisplayLabel / defectPanelTitle', () {
    test('defect labels are renumbered within same page/category', () {
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
      final afterDelete = <Defect>[d1, d3];

      expect(defectDisplayLabel(d1, allDefects: afterDelete), 'C1');
      expect(defectDisplayLabel(d3, allDefects: afterDelete), 'C2');
      expect(defectPanelTitle(d3, allDefects: afterDelete), 'C2');
    });
  });
}
