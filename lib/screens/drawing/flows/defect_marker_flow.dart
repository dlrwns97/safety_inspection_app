import 'package:flutter/material.dart';
import 'package:safety_inspection_app/application/inspection/use_cases/create_defect_marker_use_case.dart';

import 'package:safety_inspection_app/models/defect_details.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/site.dart';

final CreateDefectMarkerUseCase _createDefectMarkerUseCase =
    CreateDefectMarkerUseCase();

Future<Site?> createDefectIfConfirmed({
  required BuildContext context,
  required Site site,
  required int pageIndex,
  required double normalizedX,
  required double normalizedY,
  required DefectCategory activeCategory,
  required Future<DefectDetails?> Function(
    BuildContext context,
    String defectId,
  )
  showDefectDetailsDialog,
}) async {
  return _createDefectMarkerUseCase.execute(
    context: context,
    site: site,
    pageIndex: pageIndex,
    normalizedX: normalizedX,
    normalizedY: normalizedY,
    activeCategory: activeCategory,
    showDefectDetailsDialog: showDefectDetailsDialog,
  );
}
