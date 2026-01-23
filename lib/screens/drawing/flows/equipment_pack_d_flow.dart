import 'package:flutter/material.dart';

import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/equipment_marker.dart';
import 'package:safety_inspection_app/models/site.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/settlement_dialog.dart';

Future<Site?> createEquipment8IfConfirmed({
  required BuildContext context,
  required Site site,
  required int pageIndex,
  required double normalizedX,
  required double normalizedY,
  required Map<String, int> nextIndexByDirection,
  required int Function(String direction) nextSettlementIndex,
  required Future<SettlementDetails?> Function({
    required String baseTitle,
    required Map<String, int> nextIndexByDirection,
  })
  showSettlementDialog,
}) async {
  final details = await showSettlementDialog(
    baseTitle: '부동침하',
    nextIndexByDirection: nextIndexByDirection,
  );
  if (details == null) {
    return null;
  }
  final direction = details.direction;
  final label = '$direction${nextSettlementIndex(direction)}';
  final marker = EquipmentMarker(
    id: DateTime.now().microsecondsSinceEpoch.toString(),
    label: label,
    pageIndex: pageIndex,
    category: EquipmentCategory.equipment8,
    normalizedX: normalizedX,
    normalizedY: normalizedY,
    equipmentTypeId: direction,
    tiltDirection: direction,
    displacementText: details.displacementText,
  );
  return site.copyWith(equipmentMarkers: [...site.equipmentMarkers, marker]);
}
