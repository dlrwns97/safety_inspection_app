import 'package:flutter/material.dart';

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
  required Future<RebarSpacingDetails?> Function(
    BuildContext context, {
    required String title,
    String? initialMemberType,
    String? initialRemarkLeft,
    String? initialRemarkRight,
    String? initialNumberPrefix,
    String? initialNumberValue,
  }) showRebarSpacingDialog,
}) async {
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
  );
  if (details == null) {
    return null;
  }
  final numberValue =
      details.numberValue?.isNotEmpty == true
          ? details.numberValue!.trim()
          : null;
  final numberPrefix =
      details.numberPrefix?.isNotEmpty == true
          ? details.numberPrefix!.trim()
          : null;
  final numberText = _formatEquipment2Number(
    prefix: numberPrefix,
    value: numberValue,
  );
  final marker = pendingMarker.copyWith(
    pageIndex: pageIndex,
    normalizedX: normalizedX,
    normalizedY: normalizedY,
    equipmentTypeId: prefix,
    memberType: details.memberType,
    numberText: numberText,
    remarkLeft: details.remarkLeft,
    remarkRight: details.remarkRight,
    numberPrefix: numberPrefix,
    numberValue: numberValue,
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
    String? initialMaxValueText,
    String? initialMinValueText,
  }) showSchmidtHammerDialog,
}) async {
  final details = await showSchmidtHammerDialog(
    context,
    title: title,
    initialMemberType: pendingMarker.memberType,
    initialMaxValueText: pendingMarker.maxValueText,
    initialMinValueText: pendingMarker.minValueText,
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
