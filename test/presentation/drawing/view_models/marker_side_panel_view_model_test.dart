import 'package:flutter_test/flutter_test.dart';
import 'package:safety_inspection_app/models/defect.dart';
import 'package:safety_inspection_app/models/defect_details.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/equipment_marker.dart';
import 'package:safety_inspection_app/presentation/drawing/view_models/marker_side_panel_view_model.dart';

Defect _defect({
  required String id,
  required int pageIndex,
  required DefectCategory category,
}) {
  return Defect(
    id: id,
    label: 'tmp',
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

EquipmentMarker _equipment({
  required String id,
  required int pageIndex,
  required EquipmentCategory category,
}) {
  return EquipmentMarker(
    id: id,
    label: 'tmp',
    pageIndex: pageIndex,
    category: category,
    normalizedX: 0.2,
    normalizedY: 0.2,
  );
}

void main() {
  group('MarkerSidePanelViewModel visibility filters', () {
    test('filters defects by page + selected category + visibility', () {
      final defects = <Defect>[
        _defect(id: 'd1', pageIndex: 1, category: DefectCategory.generalCrack),
        _defect(id: 'd2', pageIndex: 1, category: DefectCategory.waterLeakage),
        _defect(id: 'd3', pageIndex: 2, category: DefectCategory.generalCrack),
      ];

      final viewModel = MarkerSidePanelViewModel(
        currentPage: 1,
        defects: defects,
        equipmentMarkers: const [],
        selectedDefectCategory: DefectCategory.generalCrack,
        selectedEquipmentCategory: null,
        visibleDefectCategories: {DefectCategory.generalCrack},
        visibleEquipmentCategories: const {},
        selectedDefect: null,
        selectedEquipment: null,
      );

      expect(viewModel.filteredDefects.map((item) => item.id), ['d1']);
      expect(viewModel.defectInfoMessage, isNull);
    });

    test(
      'shows defect hidden info message when selected category is hidden',
      () {
        final viewModel = MarkerSidePanelViewModel(
          currentPage: 1,
          defects: [
            _defect(
              id: 'd1',
              pageIndex: 1,
              category: DefectCategory.generalCrack,
            ),
          ],
          equipmentMarkers: const [],
          selectedDefectCategory: DefectCategory.generalCrack,
          selectedEquipmentCategory: null,
          visibleDefectCategories: {DefectCategory.waterLeakage},
          visibleEquipmentCategories: const {},
          selectedDefect: null,
          selectedEquipment: null,
        );

        expect(viewModel.filteredDefects, isEmpty);
        expect(viewModel.defectInfoMessage, isNotNull);
        expect(viewModel.defectInfoMessage, contains('표시가 꺼져 있어요'));
      },
    );

    test('filters equipment by page + selected category + visibility', () {
      final equipment = <EquipmentMarker>[
        _equipment(
          id: 'e1',
          pageIndex: 1,
          category: EquipmentCategory.equipment2,
        ),
        _equipment(
          id: 'e2',
          pageIndex: 1,
          category: EquipmentCategory.equipment3,
        ),
        _equipment(
          id: 'e3',
          pageIndex: 2,
          category: EquipmentCategory.equipment2,
        ),
      ];

      final viewModel = MarkerSidePanelViewModel(
        currentPage: 1,
        defects: const [],
        equipmentMarkers: equipment,
        selectedDefectCategory: null,
        selectedEquipmentCategory: EquipmentCategory.equipment2,
        visibleDefectCategories: DefectCategory.values.toSet(),
        visibleEquipmentCategories: {EquipmentCategory.equipment2},
        selectedDefect: null,
        selectedEquipment: null,
      );

      expect(viewModel.filteredEquipment.map((item) => item.id), ['e1']);
      expect(viewModel.equipmentInfoMessage, isNull);
    });

    test(
      'shows equipment hidden info message when selected category is hidden',
      () {
        final viewModel = MarkerSidePanelViewModel(
          currentPage: 1,
          defects: const [],
          equipmentMarkers: [
            _equipment(
              id: 'e1',
              pageIndex: 1,
              category: EquipmentCategory.equipment2,
            ),
          ],
          selectedDefectCategory: null,
          selectedEquipmentCategory: EquipmentCategory.equipment2,
          visibleDefectCategories: DefectCategory.values.toSet(),
          visibleEquipmentCategories: {EquipmentCategory.equipment3},
          selectedDefect: null,
          selectedEquipment: null,
        );

        expect(viewModel.filteredEquipment, isEmpty);
        expect(viewModel.equipmentInfoMessage, isNotNull);
        expect(viewModel.equipmentInfoMessage, contains('표시가 꺼져 있어요'));
      },
    );
  });
}
