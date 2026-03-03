import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/equipment_marker.dart';
import 'package:safety_inspection_app/models/site.dart';
import 'package:safety_inspection_app/screens/drawing/flows/marker_presenters.dart';
import 'package:safety_inspection_app/screens/home/home_storage.dart';
import 'package:safety_inspection_app/screens/home/site_photo_orphan_scanner.dart';
import 'package:safety_inspection_app/utils/photo_path_ordering.dart';

Site _site({
  required String id,
  required String name,
  required DrawingType drawingType,
  bool isDeleted = false,
  DateTime? deletedAt,
}) {
  return Site(
    id: id,
    name: name,
    createdAt: DateTime(2026, 3, 3),
    drawingType: drawingType,
    isDeleted: isDeleted,
    deletedAt: deletedAt,
  );
}

EquipmentMarker _equipment({
  required String id,
  required EquipmentCategory category,
  String? tiltDirection,
}) {
  return EquipmentMarker(
    id: id,
    label: 'tmp',
    pageIndex: 1,
    category: category,
    normalizedX: 0.1,
    normalizedY: 0.1,
    tiltDirection: tiltDirection,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('H-01/H-02/H-03 smoke', () {
    test('H-01 creates and reloads site metadata', () async {
      final homeStorage = HomeStorage();
      final site = _site(
        id: 's1',
        name: '현장 A',
        drawingType: DrawingType.blank,
      );
      await homeStorage.saveSites(<Site>[site]);

      final loaded = await homeStorage.loadSites();

      expect(loaded, hasLength(1));
      expect(loaded.first.id, 's1');
      expect(loaded.first.name, '현장 A');
      expect(loaded.first.drawingType, DrawingType.blank);
      expect(loaded.first.isDeleted, isFalse);
    });

    test('H-02 trash -> restore -> permanent delete flow', () async {
      final homeStorage = HomeStorage();
      final target = _site(
        id: 's1',
        name: '현장 A',
        drawingType: DrawingType.blank,
      );
      final keep = _site(id: 's2', name: '현장 B', drawingType: DrawingType.pdf);
      final initial = <Site>[target, keep];
      final deletedAt = DateTime(2026, 3, 3, 10, 0);

      final trashed = await homeStorage.moveSiteToTrash(
        initial,
        target,
        deletedAt,
      );
      final trashedTarget = trashed.firstWhere((site) => site.id == target.id);
      expect(trashedTarget.isDeleted, isTrue);
      expect(trashedTarget.deletedAt, deletedAt);

      final restored = await homeStorage.restoreSite(trashed, target);
      final restoredTarget = restored.firstWhere(
        (site) => site.id == target.id,
      );
      expect(restoredTarget.isDeleted, isFalse);
      expect(restoredTarget.deletedAt, isNull);

      final deleted = await homeStorage.permanentlyDeleteSite(restored, target);
      expect(deleted.map((site) => site.id), isNot(contains(target.id)));
      expect(deleted.map((site) => site.id), contains(keep.id));
    });

    test('H-03 restores persisted trash state after reload', () async {
      final homeStorage = HomeStorage();
      final target = _site(
        id: 's1',
        name: '현장 A',
        drawingType: DrawingType.blank,
        isDeleted: true,
        deletedAt: DateTime(2026, 3, 3, 11, 0),
      );
      await homeStorage.saveSites(<Site>[target]);

      final reloaded = await homeStorage.loadSites();
      expect(reloaded, hasLength(1));
      expect(reloaded.first.isDeleted, isTrue);
      expect(reloaded.first.deletedAt, isNotNull);
    });
  });

  group('D-05 smoke', () {
    test('D-05 equipment label rule keeps prefix+sequence order', () {
      final f1 = _equipment(id: 'f1', category: EquipmentCategory.equipment2);
      final f2 = _equipment(id: 'f2', category: EquipmentCategory.equipment2);
      final all = <EquipmentMarker>[f1, f2];

      expect(equipmentDisplayLabel(f1, all), 'F1');
      expect(equipmentDisplayLabel(f2, all), 'F2');
    });
  });

  group('P-02 smoke', () {
    test('P-02 deduplicates mixed legacy path formats', () {
      final result = insertPreservingReferenceOrder(
        photoPaths: <String>['C:\\a\\2.jpg'],
        restoreKey: '/a/2.jpg',
        normalizeKey: photoReferenceKey,
      );

      expect(result, <String>['C:\\a\\2.jpg']);
    });
  });
}
