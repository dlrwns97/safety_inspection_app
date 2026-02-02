import 'package:flutter_test/flutter_test.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/equipment_marker.dart';
import 'package:safety_inspection_app/screens/drawing/flows/marker_presenters.dart';

EquipmentMarker _marker({
  required String id,
  required EquipmentCategory category,
  required String label,
  String? tiltDirection,
}) {
  return EquipmentMarker(
    id: id,
    label: label,
    pageIndex: 0,
    category: category,
    normalizedX: 0,
    normalizedY: 0,
    tiltDirection: tiltDirection,
  );
}

group('equipment label sequencing', () {
  test('settlement axis-separated sequencing', () {
    final mX1 = _marker(
      id: 'mx1',
      label: 'mX1',
      category: EquipmentCategory.equipment8,
      tiltDirection: 'Lx',
    );
    final mX2 = _marker(
      id: 'mx2',
      label: 'mX2',
      category: EquipmentCategory.equipment8,
      tiltDirection: 'Lx',
    );
    final mX3 = _marker(
      id: 'mx3',
      label: 'mX3',
      category: EquipmentCategory.equipment8,
      tiltDirection: 'Lx',
    );
    final mY1 = _marker(
      id: 'my1',
      label: 'mY1',
      category: EquipmentCategory.equipment8,
      tiltDirection: 'Ly',
    );
    final all = [mX1, mX2, mX3, mY1];

    expect(equipmentDisplayLabel(mX1, all), 'Lx1');
    expect(equipmentDisplayLabel(mX2, all), 'Lx2');
    expect(equipmentDisplayLabel(mX3, all), 'Lx3');
    expect(equipmentDisplayLabel(mY1, all), 'Ly1');
    expect(equipmentPanelTitle(mX3, all), 'Lx3 부동침하');
    expect(equipmentPanelTitle(mY1, all), 'Ly1 부동침하');
  });

  test('prefix + sequence category', () {
    final f1 = _marker(
      id: 'f1',
      label: 'f1',
      category: EquipmentCategory.equipment2,
    );
    final f2 = _marker(
      id: 'f2',
      label: 'f2',
      category: EquipmentCategory.equipment2,
    );
    final all = [f1, f2];

    expect(equipmentDisplayLabel(f1, all), 'F1');
    expect(equipmentDisplayLabel(f2, all), 'F2');
    expect(equipmentPanelTitle(f1, all), 'F1 철근배근간격');
    expect(equipmentPanelTitle(f2, all), 'F2 철근배근간격');
  });
});
