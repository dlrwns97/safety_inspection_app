import 'package:flutter/material.dart';

import 'package:safety_inspection_app/models/defect.dart';
import 'package:safety_inspection_app/models/defect_details.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/site.dart';
import 'package:safety_inspection_app/screens/drawing/flows/drawing_lookup_helpers.dart';

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
  final defectId = DateTime.now().microsecondsSinceEpoch.toString();
  final detailsResult = await showDefectDetailsDialog(context, defectId);
  if (detailsResult == null) {
    return null;
  }

  final countOnPage = site.defects
      .where(
        (defect) =>
            defect.pageIndex == pageIndex && defect.category == activeCategory,
      )
      .length;
  final labelPrefix = defectLabelPrefix(activeCategory);
  final label = '$labelPrefix${countOnPage + 1}';

  final defect = Defect(
    id: defectId,
    label: label,
    pageIndex: pageIndex,
    category: activeCategory,
    normalizedX: normalizedX,
    normalizedY: normalizedY,
    details: detailsResult,
  );

  return site.copyWith(defects: [...site.defects, defect]);
}
