import 'package:flutter/material.dart';

import 'package:safety_inspection_app/models/equipment_marker.dart';
import 'package:safety_inspection_app/models/site.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/deflection_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/equipment_details_dialog.dart';

Future<Site?> createEquipment1IfConfirmed({
  required BuildContext context,
  required Site site,
  required int pageIndex,
  required double normalizedX,
  required double normalizedY,
  required EquipmentMarker pendingMarker,
  required String prefix,
  required String title,
  required String? initialMemberType,
  required List<String>? initialSizeValues,
  required Future<EquipmentDetails?> Function({
    required String title,
    String? initialMemberType,
    List<String>? initialSizeValues,
  }) showEquipmentDetailsDialog,
}) async {
  final details = await showEquipmentDetailsDialog(
    title: title,
    initialMemberType: initialMemberType,
    initialSizeValues: initialSizeValues,
  );
  if (details == null) {
    return null;
  }
  final marker = pendingMarker.copyWith(
    equipmentTypeId: prefix,
    memberType: details.memberType,
    sizeValues: details.sizeValues,
  );
  return site.copyWith(
    equipmentMarkers: [...site.equipmentMarkers, marker],
  );
}

Future<Site?> createEquipment7IfConfirmed({
  required BuildContext context,
  required Site site,
  required int pageIndex,
  required double normalizedX,
  required double normalizedY,
  required EquipmentMarker pendingMarker,
  required String prefix,
  required String title,
  required String? initialMemberType,
  required String? initialEndAText,
  required String? initialMidBText,
  required String? initialEndCText,
  required Future<DeflectionDetails?> Function({
    required String title,
    required List<String> memberOptions,
    String? initialMemberType,
    String? initialEndAText,
    String? initialMidBText,
    String? initialEndCText,
  }) showDeflectionDialog,
  required List<String> memberOptions,
}) async {
  final details = await showDeflectionDialog(
    title: title,
    memberOptions: memberOptions,
    initialMemberType: initialMemberType,
    initialEndAText: initialEndAText,
    initialMidBText: initialMidBText,
    initialEndCText: initialEndCText,
  );
  if (details == null) {
    return null;
  }
  final marker = pendingMarker.copyWith(
    equipmentTypeId: prefix,
    memberType: details.memberType,
    deflectionEndAText: details.endAText,
    deflectionMidBText: details.midBText,
    deflectionEndCText: details.endCText,
  );
  return site.copyWith(
    equipmentMarkers: [...site.equipmentMarkers, marker],
  );
}
