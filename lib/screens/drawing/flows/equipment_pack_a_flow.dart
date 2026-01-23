import 'package:flutter/material.dart';

import 'package:safety_inspection_app/models/defect_details.dart';
import 'package:safety_inspection_app/models/equipment_marker.dart';
import 'package:safety_inspection_app/models/site.dart';

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
    String? initialNumberText,
  }) showRebarSpacingDialog,
}) async {
  final details = await showRebarSpacingDialog(
    context,
    title: title,
    initialMemberType: pendingMarker.memberType,
    initialNumberText: pendingMarker.numberText,
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
    numberText: details.numberText,
  );
  return site.copyWith(
    equipmentMarkers: [...site.equipmentMarkers, marker],
  );
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
