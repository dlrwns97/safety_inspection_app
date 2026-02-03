import 'package:flutter/material.dart';

import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/equipment_marker.dart';
import 'package:safety_inspection_app/models/rebar_spacing_group_details.dart';
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
  required Future<RebarSpacingGroupDetails?> Function(
    BuildContext context, {
    required String title,
    String? initialMemberType,
    List<RebarSpacingMeasurement>? initialMeasurements,
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
  final hasExistingData =
      pendingMarker.details?.isNotEmpty == true ||
      pendingMarker.memberType?.isNotEmpty == true ||
      pendingMarker.remarkLeft?.isNotEmpty == true ||
      pendingMarker.remarkRight?.isNotEmpty == true ||
      pendingMarker.numberPrefix?.isNotEmpty == true ||
      pendingMarker.numberValue?.isNotEmpty == true ||
      pendingMarker.numberText?.isNotEmpty == true;
  final existingGroup =
      hasExistingData
          ? rebarSpacingGroupFromMarker(
            pendingMarker,
            defaultPrefix: prefix,
          )
          : null;
  final initialMeasurements =
      existingGroup?.measurements ??
      [
        RebarSpacingMeasurement(
          remarkLeft: pendingMarker.remarkLeft,
          remarkRight: pendingMarker.remarkRight,
          numberPrefix: pendingMarker.numberPrefix,
          numberValue:
              pendingMarker.numberValue ??
              pendingMarker.numberText?.trim(),
        ),
      ];
  final baseLabelIndex = existingGroup?.baseLabelIndex ?? nextLabelIndex;
  final details = await showRebarSpacingDialog(
    context,
    title: title,
    initialMemberType:
        pendingMarker.memberType?.isNotEmpty == true
            ? pendingMarker.memberType
            : existingGroup?.memberType,
    initialMeasurements: initialMeasurements,
    allowMultiple: allowMultiple,
    baseLabelIndex: baseLabelIndex,
    labelPrefix: prefix,
  );
  if (details == null) {
    return null;
  }
  if (baseLabelIndex == null) {
    return null;
  }
  final isRangeAvailable = _rebarSpacingRangeAvailable(
    site: site,
    baseLabelIndex: baseLabelIndex,
    count: details.measurements.length,
    prefix: prefix,
  );
  if (!isRangeAvailable) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('이미 사용 중인 번호가 포함되어 있습니다.')),
    );
    return null;
  }
  final firstMeasurement = details.measurements.first;
  final numberValue = firstMeasurement.numberValue?.trim();
  final numberPrefix = firstMeasurement.numberPrefix?.trim();
  final numberText = _formatEquipment2Number(
    prefix: numberPrefix,
    value: numberValue,
  );
  final marker = pendingMarker.copyWith(
    label: details.rangeLabel(),
    pageIndex: pageIndex,
    normalizedX: normalizedX,
    normalizedY: normalizedY,
    equipmentTypeId: prefix,
    memberType: details.memberType,
    numberText: numberText,
    remarkLeft: firstMeasurement.remarkLeft,
    remarkRight: firstMeasurement.remarkRight,
    numberPrefix: numberPrefix,
    numberValue: numberValue,
    details: details.toJsonString(),
  );
  return site.copyWith(
    equipmentMarkers: [...site.equipmentMarkers, marker],
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
  var maxIndex = 0;
  var count = 0;
  for (final marker in targetMarkers) {
    count += 1;
    final group = rebarSpacingGroupFromMarker(
      marker,
      defaultPrefix: prefix,
    );
    if (group != null) {
      final endIndex = group.baseLabelIndex + group.measurements.length - 1;
      if (endIndex > maxIndex) {
        maxIndex = endIndex;
      }
      continue;
    }
    final regex = RegExp('^${RegExp.escape(prefix)}(\\d+)\$');
    final match = regex.firstMatch(marker.label.trim());
    final value = match == null ? null : int.tryParse(match.group(1) ?? '');
    if (value != null && value > maxIndex) {
      maxIndex = value;
    }
  }
  if (maxIndex > 0) {
    return maxIndex + 1;
  }
  return count + 1;
}

bool _rebarSpacingRangeAvailable({
  required Site site,
  required int baseLabelIndex,
  required int count,
  required String prefix,
}) {
  final usedIndices = <int>{};
  for (final marker in site.equipmentMarkers) {
    if (marker.category != EquipmentCategory.equipment2) {
      continue;
    }
    final group = rebarSpacingGroupFromMarker(
      marker,
      defaultPrefix: prefix,
    );
    if (group == null) {
      continue;
    }
    for (var i = 0; i < group.measurements.length; i++) {
      usedIndices.add(group.baseLabelIndex + i);
    }
  }
  for (var i = 0; i < count; i++) {
    if (usedIndices.contains(baseLabelIndex + i)) {
      return false;
    }
  }
  return true;
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
