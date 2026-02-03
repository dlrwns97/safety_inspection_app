import 'package:flutter/material.dart';

import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/equipment_marker.dart';
import 'package:safety_inspection_app/models/site.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/core_sampling_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/rebar_spacing_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/schmidt_hammer_dialog.dart';

Future<Site?> createEquipment2IfConfirmed({
  required BuildContext context,
  required Site site,
  required int pageIndex,
  required double normalizedX,
  required double normalizedY,
  required EquipmentMarker pendingMarker,
  required String prefix,
  required String title,
  required bool allowMultiple,
  required Future<RebarSpacingDetails?> Function(
    BuildContext context, {
    required String title,
    String? initialMemberType,
    String? initialRemarkLeft,
    String? initialRemarkRight,
    String? initialNumberPrefix,
    String? initialNumberValue,
    bool allowMultiple,
    int? baseLabelIndex,
    String? labelPrefix,
  }) showRebarSpacingDialog,
}) async {
  final nextLabelIndex =
      allowMultiple
          ? _nextEquipmentLabelIndex(
            site: site,
            category: EquipmentCategory.equipment2,
            prefix: prefix,
          )
          : null;
  final fallbackNumberValue =
      pendingMarker.numberValue ??
      (pendingMarker.numberText?.trim().isNotEmpty == true
          ? pendingMarker.numberText
          : null);
  final details = await showRebarSpacingDialog(
    context,
    title: title,
    initialMemberType: pendingMarker.memberType,
    initialRemarkLeft: pendingMarker.remarkLeft,
    initialRemarkRight: pendingMarker.remarkRight,
    initialNumberPrefix: pendingMarker.numberPrefix,
    initialNumberValue: fallbackNumberValue,
    allowMultiple: allowMultiple,
    baseLabelIndex: nextLabelIndex,
    labelPrefix: prefix,
  );
  if (details == null) {
    return null;
  }
  final rows = details.rows.isEmpty
      ? [const RebarSpacingRowDetails()]
      : details.rows;
  final markers =
      rows.asMap().entries.map((entry) {
        final rowIndex = entry.key;
        final row = entry.value;
        final numberValue =
            row.numberValue?.isNotEmpty == true ? row.numberValue!.trim() : null;
        final numberPrefix =
            row.numberPrefix?.isNotEmpty == true
                ? row.numberPrefix!.trim()
                : null;
        final numberText = _formatEquipment2Number(
          prefix: numberPrefix,
          value: numberValue,
        );
        final labelIndex =
            nextLabelIndex == null ? null : nextLabelIndex + rowIndex;
        final id =
            allowMultiple && rowIndex > 0
                ? (DateTime.now().microsecondsSinceEpoch + rowIndex).toString()
                : pendingMarker.id;
        return pendingMarker.copyWith(
          id: id,
          label:
              allowMultiple && labelIndex != null
                  ? '$prefix$labelIndex'
                  : pendingMarker.label,
          pageIndex: pageIndex,
          normalizedX: normalizedX,
          normalizedY: normalizedY,
          equipmentTypeId: prefix,
          memberType: details.memberType,
          numberText: numberText,
          remarkLeft: row.remarkLeft,
          remarkRight: row.remarkRight,
          numberPrefix: numberPrefix,
          numberValue: numberValue,
        );
      }).toList();
  return site.copyWith(
    equipmentMarkers: [...site.equipmentMarkers, ...markers],
  );
}

String? _formatEquipment2Number({String? prefix, String? value}) {
  final trimmedPrefix = prefix?.trim();
  final trimmedValue = value?.trim();
  final hasPrefix = trimmedPrefix?.isNotEmpty == true;
  final hasValue = trimmedValue?.isNotEmpty == true;
  if (!hasPrefix && !hasValue) {
    return null;
  }
  if (hasPrefix && hasValue) {
    return '$trimmedPrefix$trimmedValue';
  }
  return hasPrefix ? trimmedPrefix : trimmedValue;
}

int _nextEquipmentLabelIndex({
  required Site site,
  required EquipmentCategory category,
  required String prefix,
}) {
  final targetMarkers =
      site.equipmentMarkers.where((marker) => marker.category == category);
  final regex = RegExp('^${RegExp.escape(prefix)}(\\d+)\$');
  var maxIndex = 0;
  var count = 0;
  for (final marker in targetMarkers) {
    count += 1;
    final match = regex.firstMatch(marker.label.trim());
    if (match == null) {
      continue;
    }
    final value = int.tryParse(match.group(1) ?? '');
    if (value != null && value > maxIndex) {
      maxIndex = value;
    }
  }
  if (maxIndex > 0) {
    return maxIndex + 1;
  }
  return count + 1;
}

Future<Site?> createEquipment3IfConfirmed({
  required BuildContext context,
  required Site site,
  required int pageIndex,
  required double normalizedX,
  required double normalizedY,
  required EquipmentMarker pendingMarker,
  required String prefix,
  required String title,
  required Future<SchmidtHammerDetails?> Function(
    BuildContext context, {
    required String title,
    String? initialMemberType,
    int? initialAngleDeg,
    String? initialMaxValueText,
    String? initialMinValueText,
  }) showSchmidtHammerDialog,
}) async {
  final details = await showSchmidtHammerDialog(
    context,
    title: title,
    initialMemberType: pendingMarker.memberType,
    initialAngleDeg: pendingMarker.schmidtAngleDeg,
    initialMaxValueText:
        pendingMarker.schmidtMaxValue ?? pendingMarker.maxValueText,
    initialMinValueText:
        pendingMarker.schmidtMinValue ?? pendingMarker.minValueText,
  );
  if (details == null) {
    return null;
  }
  final marker = pendingMarker.copyWith(
    pageIndex: pageIndex,
    normalizedX: normalizedX,
    normalizedY: normalizedY,
    equipmentTypeId: prefix,
    memberType: details.memberType,
    schmidtAngleDeg: details.angleDeg,
    schmidtMaxValue: details.maxValueText,
    schmidtMinValue: details.minValueText,
    maxValueText: details.maxValueText,
    minValueText: details.minValueText,
  );
  return site.copyWith(
    equipmentMarkers: [...site.equipmentMarkers, marker],
  );
}

Future<Site?> createEquipment4IfConfirmed({
  required BuildContext context,
  required Site site,
  required int pageIndex,
  required double normalizedX,
  required double normalizedY,
  required EquipmentMarker pendingMarker,
  required String prefix,
  required String title,
  required Future<CoreSamplingDetails?> Function(
    BuildContext context, {
    required String title,
    String? initialMemberType,
    String? initialAvgValueText,
  }) showCoreSamplingDialog,
}) async {
  final details = await showCoreSamplingDialog(
    context,
    title: title,
    initialMemberType: pendingMarker.memberType,
    initialAvgValueText: pendingMarker.avgValueText,
  );
  if (details == null) {
    return null;
  }
  final marker = pendingMarker.copyWith(
    pageIndex: pageIndex,
    normalizedX: normalizedX,
    normalizedY: normalizedY,
    equipmentTypeId: prefix,
    memberType: details.memberType,
    avgValueText: details.avgValueText,
  );
  return site.copyWith(
    equipmentMarkers: [...site.equipmentMarkers, marker],
  );
}
