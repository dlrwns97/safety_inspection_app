import 'package:flutter/material.dart';

import 'package:safety_inspection_app/models/equipment_marker.dart';
import 'package:safety_inspection_app/models/site.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/carbonation_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/structural_tilt_dialog.dart';

Future<Site?> createEquipment5IfConfirmed({
  required BuildContext context,
  required Site site,
  required int pageIndex,
  required double normalizedX,
  required double normalizedY,
  required EquipmentMarker pendingMarker,
  required String prefix,
  required String title,
  required String? initialMemberType,
  required String? initialCoverThicknessText,
  required String? initialDepthText,
  required Future<CarbonationDetails?> Function({
    required String title,
    String? initialMemberType,
    String? initialCoverThicknessText,
    String? initialDepthText,
  }) showCarbonationDialog,
}) async {
  final details = await showCarbonationDialog(
    title: title,
    initialMemberType: initialMemberType,
    initialCoverThicknessText: initialCoverThicknessText,
    initialDepthText: initialDepthText,
  );
  if (details == null) {
    return null;
  }
  final marker = pendingMarker.copyWith(
    equipmentTypeId: prefix,
    memberType: details.memberType,
    coverThicknessText: details.coverThicknessText,
    depthText: details.depthText,
  );
  return site.copyWith(
    equipmentMarkers: [...site.equipmentMarkers, marker],
  );
}

Future<Site?> createEquipment6IfConfirmed({
  required BuildContext context,
  required Site site,
  required int pageIndex,
  required double normalizedX,
  required double normalizedY,
  required EquipmentMarker pendingMarker,
  required String prefix,
  required String title,
  required String? initialDirection,
  required String? initialDisplacementText,
  required Future<StructuralTiltDetails?> Function({
    required String title,
    String? initialDirection,
    String? initialDisplacementText,
  }) showStructuralTiltDialog,
}) async {
  final details = await showStructuralTiltDialog(
    title: title,
    initialDirection: initialDirection,
    initialDisplacementText: initialDisplacementText,
  );
  if (details == null) {
    return null;
  }
  final marker = pendingMarker.copyWith(
    equipmentTypeId: prefix,
    tiltDirection: details.direction,
    displacementText: details.displacementText,
  );
  return site.copyWith(
    equipmentMarkers: [...site.equipmentMarkers, marker],
  );
}
