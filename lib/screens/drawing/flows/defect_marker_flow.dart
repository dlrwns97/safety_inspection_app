import 'package:flutter/material.dart';

import 'package:safety_inspection_app/models/defect.dart';
import 'package:safety_inspection_app/models/defect_details.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/site.dart';

Future<Site?> createDefectIfConfirmed({
  required BuildContext context,
  required Site site,
  required int pageIndex,
  required double normalizedX,
  required double normalizedY,
  required DefectCategory activeCategory,
  required Future<DefectDetails?> Function(BuildContext context)
      showDefectDetailsDialog,
}) async {
  final detailsResult = await showDefectDetailsDialog(context);
  if (detailsResult == null) {
    return null;
  }

  final countOnPage = site.defects
      .where(
        (defect) =>
            defect.pageIndex == pageIndex && defect.category == activeCategory,
      )
      .length;
  final label = activeCategory == DefectCategory.generalCrack
      ? 'C${countOnPage + 1}'
      : '${countOnPage + 1}';

  final defect = Defect(
    id: DateTime.now().microsecondsSinceEpoch.toString(),
    label: label,
    pageIndex: pageIndex,
    category: activeCategory,
    normalizedX: normalizedX,
    normalizedY: normalizedY,
    details: detailsResult,
  );

  return site.copyWith(defects: [...site.defects, defect]);
}
