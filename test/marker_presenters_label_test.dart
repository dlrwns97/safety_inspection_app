import 'package:flutter_test/flutter_test.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/equipment_marker.dart';
import 'package:safety_inspection_app/screens/drawing/flows/marker_presenters.dart';

EquipmentMarker _mk({
  required String id,
  required String label,
  required EquipmentCategory category,
  String? tiltDirection,
  String? equipmentTypeId,
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
  });
}
