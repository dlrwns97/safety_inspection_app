import 'package:flutter_test/flutter_test.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/presentation/drawing/states/marker_state.dart';

void main() {
  group('MarkerState', () {
    test('has expected defaults', () {
      final state = MarkerState();

      expect(state.activeCategory, isNull);
      expect(state.activeEquipmentCategory, isNull);
      expect(state.sidePanelDefectCategory, isNull);
      expect(state.sidePanelEquipmentCategory, isNull);
      expect(state.selectedDefectId, isNull);
      expect(state.selectedEquipmentId, isNull);
      expect(state.selectedMarkerScenePosition, isNull);
      expect(state.sidePanelTabIndex, 0);
      expect(state.visibleDefectCategories, DefectCategory.values.toSet());
      expect(state.visibleEquipmentCategories, isEmpty);
      expect(state.defectTabs, isEmpty);
    });

    test('stores mutable marker selections and filters', () {
      final state = MarkerState();
      final defect = DefectCategory.values.first;
      final equipment = EquipmentCategory.values.first;

      state.activeCategory = defect;
      state.activeEquipmentCategory = equipment;
      state.sidePanelDefectCategory = defect;
      state.sidePanelEquipmentCategory = equipment;
      state.selectedDefectId = 'd-1';
      state.selectedEquipmentId = 'e-1';
      state.selectedMarkerScenePosition = const Offset(10, 20);
      state.sidePanelTabIndex = 2;
      state.visibleDefectCategories.remove(defect);
      state.visibleEquipmentCategories.add(equipment);
      state.defectTabs.add(defect);

      expect(state.activeCategory, defect);
      expect(state.activeEquipmentCategory, equipment);
      expect(state.sidePanelDefectCategory, defect);
      expect(state.sidePanelEquipmentCategory, equipment);
      expect(state.selectedDefectId, 'd-1');
      expect(state.selectedEquipmentId, 'e-1');
      expect(state.selectedMarkerScenePosition, const Offset(10, 20));
      expect(state.sidePanelTabIndex, 2);
      expect(state.visibleDefectCategories.contains(defect), isFalse);
      expect(state.visibleEquipmentCategories.contains(equipment), isTrue);
      expect(state.defectTabs, [defect]);
    });
  });
}
