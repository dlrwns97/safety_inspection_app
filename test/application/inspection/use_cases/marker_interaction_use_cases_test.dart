import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safety_inspection_app/application/inspection/use_cases/create_defect_marker_use_case.dart';
import 'package:safety_inspection_app/application/inspection/use_cases/marker_tap_use_case.dart';
import 'package:safety_inspection_app/models/defect.dart';
import 'package:safety_inspection_app/models/defect_details.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/site.dart';
import 'package:safety_inspection_app/screens/drawing/drawing_controller.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/drawing_local_parts.dart';

Site _siteWithDefects(List<Defect> defects) {
  return Site(
    id: 's1',
    name: '현장 A',
    createdAt: DateTime(2026, 3, 3),
    drawingType: DrawingType.blank,
    defects: defects,
  );
}

Defect _defect({
  required String id,
  required String label,
  required int pageIndex,
  required DefectCategory category,
}) {
  return Defect(
    id: id,
    label: label,
    pageIndex: pageIndex,
    category: category,
    normalizedX: 0.1,
    normalizedY: 0.1,
    details: DefectDetails(
      structuralMember: '기둥',
      crackType: '균열',
      widthMm: 0.1,
      lengthMm: 10,
      cause: '원인',
    ),
  );
}

void main() {
  group('Marker interaction use cases', () {
    testWidgets(
      'CreateDefectMarkerUseCase keeps page/category label sequence',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        final context = tester.element(find.byType(SizedBox));
        final useCase = CreateDefectMarkerUseCase();
        final site = _siteWithDefects(<Defect>[
          _defect(
            id: 'd1',
            label: 'C1',
            pageIndex: 1,
            category: DefectCategory.generalCrack,
          ),
          _defect(
            id: 'd2',
            label: 'C1',
            pageIndex: 2,
            category: DefectCategory.generalCrack,
          ),
        ]);

        final updated = await useCase.execute(
          context: context,
          site: site,
          pageIndex: 1,
          normalizedX: 0.3,
          normalizedY: 0.4,
          activeCategory: DefectCategory.generalCrack,
          showDefectDetailsDialog: (dialogContext, defectId) async {
            expect(defectId, isNotEmpty);
            expect(dialogContext, isNotNull);
            return DefectDetails(
              structuralMember: '보',
              crackType: '균열',
              widthMm: 0.2,
              lengthMm: 20,
              cause: '원인',
            );
          },
        );

        expect(updated, isNotNull);
        expect(updated!.defects, hasLength(3));
        expect(updated.defects.last.label, 'C2');
        expect(updated.defects.last.pageIndex, 1);
        expect(updated.defects.last.category, DefectCategory.generalCrack);
      },
    );

    test(
      'MarkerTapUseCase applyTapDecision selects hit and stops creation',
      () {
        final useCase = MarkerTapUseCase();
        var selected = false;
        var cleared = false;
        final hit = MarkerHitResult(
          defect: null,
          equipment: null,
          position: const Offset(10, 20),
        );

        final shouldCreate = useCase.applyTapDecision(
          decision: const TapDecision(shouldSelectHit: true),
          hitResult: hit,
          onResetTapCanceled: () {},
          onSelectHit: (_) => selected = true,
          onClearSelection: () => cleared = true,
          onShowDefectCategoryHint: () {},
        );

        expect(shouldCreate, isFalse);
        expect(selected, isTrue);
        expect(cleared, isFalse);
      },
    );
  });
}
