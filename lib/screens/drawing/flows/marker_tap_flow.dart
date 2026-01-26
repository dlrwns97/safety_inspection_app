import 'package:flutter/material.dart';

import 'package:safety_inspection_app/models/defect_details.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/equipment_marker.dart';
import 'package:safety_inspection_app/models/site.dart';
import 'package:safety_inspection_app/screens/drawing/drawing_controller.dart';
import 'package:safety_inspection_app/screens/drawing/flows/defect_marker_flow.dart';
import 'package:safety_inspection_app/screens/drawing/flows/drawing_dialogs_adapter.dart';
import 'package:safety_inspection_app/screens/drawing/flows/drawing_lookup_helpers.dart';
import 'package:safety_inspection_app/screens/drawing/flows/equipment_pack_d_flow.dart';
import 'package:safety_inspection_app/screens/drawing/flows/equipment_updated_site_flow.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/drawing_local_parts.dart';

bool applyTapDecision({
  required TapDecision decision,
  required MarkerHitResult? hitResult,
  required VoidCallback onResetTapCanceled,
  required void Function(MarkerHitResult result) onSelectHit,
  required VoidCallback onClearSelection,
  required VoidCallback onShowDefectCategoryHint,
}) {
  if (decision.resetTapCanceled) {
    onResetTapCanceled();
    return false;
  }
  if (decision.shouldSelectHit) {
    onSelectHit(hitResult!);
    return false;
  }
  if (decision.shouldClearSelection) {
    onClearSelection();
  }
  if (decision.shouldShowDefectCategoryHint) {
    onShowDefectCategoryHint();
    return false;
  }
  if (!decision.shouldCreateMarker) {
    return false;
  }
  return true;
}

Future<Site?> handleTapCore({
  required BuildContext context,
  required MarkerHitResult? hitResult,
  required TapDecision decision,
  required int pageIndex,
  required double normalizedX,
  required double normalizedY,
  required Site site,
  required DrawMode mode,
  required DefectCategory? activeCategory,
  required EquipmentCategory? activeEquipmentCategory,
  required VoidCallback onResetTapCanceled,
  required void Function(MarkerHitResult result) onSelectHit,
  required VoidCallback onClearSelection,
  required VoidCallback onShowDefectCategoryHint,
  required Future<DefectDetails?> Function(BuildContext context)
      showDefectDetailsDialog,
  required DrawingDialogsAdapter dialogs,
  required List<String> deflectionMemberOptions,
  required int Function(Site site, String direction) nextSettlementIndex,
}) async {
  final shouldCreate = applyTapDecision(
    decision: decision,
    hitResult: hitResult,
    onResetTapCanceled: onResetTapCanceled,
    onSelectHit: onSelectHit,
    onClearSelection: onClearSelection,
    onShowDefectCategoryHint: onShowDefectCategoryHint,
  );
  if (!shouldCreate) {
    return null;
  }
  return createMarkerFromTap(
    context: context,
    site: site,
    mode: mode,
    activeCategory: activeCategory,
    activeEquipmentCategory: activeEquipmentCategory,
    pageIndex: pageIndex,
    normalizedX: normalizedX,
    normalizedY: normalizedY,
    showDefectDetailsDialog: showDefectDetailsDialog,
    dialogs: dialogs,
    deflectionMemberOptions: deflectionMemberOptions,
    nextSettlementIndex: nextSettlementIndex,
  );
}

Future<Site?> createMarkerFromTap({
  required BuildContext context,
  required Site site,
  required DrawMode mode,
  required DefectCategory? activeCategory,
  required EquipmentCategory? activeEquipmentCategory,
  required int pageIndex,
  required double normalizedX,
  required double normalizedY,
  required Future<DefectDetails?> Function(BuildContext context)
      showDefectDetailsDialog,
  required DrawingDialogsAdapter dialogs,
  required List<String> deflectionMemberOptions,
  required int Function(Site site, String direction) nextSettlementIndex,
}) async {
  if (mode == DrawMode.defect) {
    return addDefectMarker(
      context: context,
      site: site,
      pageIndex: pageIndex,
      normalizedX: normalizedX,
      normalizedY: normalizedY,
      activeCategory: activeCategory!,
      showDefectDetailsDialog: showDefectDetailsDialog,
    );
  }
  return addEquipmentMarker(
    context: context,
    site: site,
    activeEquipmentCategory: activeEquipmentCategory,
    pageIndex: pageIndex,
    normalizedX: normalizedX,
    normalizedY: normalizedY,
    dialogs: dialogs,
    deflectionMemberOptions: deflectionMemberOptions,
    nextSettlementIndex: nextSettlementIndex,
  );
}

Future<Site?> addDefectMarker({
  required BuildContext context,
  required Site site,
  required int pageIndex,
  required double normalizedX,
  required double normalizedY,
  required DefectCategory activeCategory,
  required Future<DefectDetails?> Function(BuildContext context)
      showDefectDetailsDialog,
}) async {
  return createDefectIfConfirmed(
    context: context,
    site: site,
    pageIndex: pageIndex,
    normalizedX: normalizedX,
    normalizedY: normalizedY,
    activeCategory: activeCategory,
    showDefectDetailsDialog: showDefectDetailsDialog,
  );
}

Future<Site?> addEquipmentMarker({
  required BuildContext context,
  required Site site,
  required EquipmentCategory? activeEquipmentCategory,
  required int pageIndex,
  required double normalizedX,
  required double normalizedY,
  required DrawingDialogsAdapter dialogs,
  required List<String> deflectionMemberOptions,
  required int Function(Site site, String direction) nextSettlementIndex,
}) async {
  if (activeEquipmentCategory == null) {
    return null;
  }
  if (activeEquipmentCategory == EquipmentCategory.equipment8) {
    return addEquipment8Marker(
      context: context,
      site: site,
      pageIndex: pageIndex,
      normalizedX: normalizedX,
      normalizedY: normalizedY,
      dialogs: dialogs,
      nextSettlementIndex: nextSettlementIndex,
    );
  }
  final equipmentCount = site.equipmentMarkers
      .where((marker) => marker.category == activeEquipmentCategory)
      .length;
  final prefix = equipmentLabelPrefix(activeEquipmentCategory);
  final label = '$prefix${equipmentCount + 1}';
  final pendingMarker = EquipmentMarker(
    id: DateTime.now().microsecondsSinceEpoch.toString(),
    label: label,
    pageIndex: pageIndex,
    category: activeEquipmentCategory,
    normalizedX: normalizedX,
    normalizedY: normalizedY,
    equipmentTypeId: prefix,
  );

  return createEquipmentUpdatedSite(
    context: context,
    site: site,
    activeEquipmentCategory: activeEquipmentCategory,
    pendingMarker: pendingMarker,
    prefix: prefix,
    deflectionMemberOptions: deflectionMemberOptions,
    showEquipmentDetailsDialog: dialogs.equipmentDetails,
    showRebarSpacingDialog: (
      context, {
      required title,
      initialMemberType,
      initialNumberText,
    }) =>
        dialogs.rebarSpacing(
      title: title,
      initialMemberType: initialMemberType,
      initialNumberText: initialNumberText,
    ),
    showSchmidtHammerDialog: (
      context, {
      required title,
      initialMemberType,
      initialMaxValueText,
      initialMinValueText,
    }) =>
        dialogs.schmidtHammer(
      title: title,
      initialMemberType: initialMemberType,
      initialMaxValueText: initialMaxValueText,
      initialMinValueText: initialMinValueText,
    ),
    showCoreSamplingDialog: (
      context, {
      required title,
      initialMemberType,
      initialAvgValueText,
    }) =>
        dialogs.coreSampling(
      title: title,
      initialMemberType: initialMemberType,
      initialAvgValueText: initialAvgValueText,
    ),
    showCarbonationDialog: ({
      required title,
      initialMemberType,
      initialCoverThicknessText,
      initialDepthText,
    }) =>
        dialogs.carbonation(
      title: title,
      initialMemberType: initialMemberType,
      initialCoverThicknessText: initialCoverThicknessText,
      initialDepthText: initialDepthText,
    ),
    showStructuralTiltDialog: ({
      required title,
      initialDirection,
      initialDisplacementText,
    }) =>
        dialogs.structuralTilt(
      title: title,
      initialDirection: initialDirection,
      initialDisplacementText: initialDisplacementText,
    ),
    showDeflectionDialog: ({
      required title,
      required memberOptions,
      initialMemberType,
      initialEndAText,
      initialMidBText,
      initialEndCText,
    }) =>
        dialogs.deflection(
      title: title,
      initialMemberType: initialMemberType,
      initialEndAText: initialEndAText,
      initialMidBText: initialMidBText,
      initialEndCText: initialEndCText,
    ),
  );
}

Future<Site?> addEquipment8Marker({
  required BuildContext context,
  required Site site,
  required int pageIndex,
  required double normalizedX,
  required double normalizedY,
  required DrawingDialogsAdapter dialogs,
  required int Function(Site site, String direction) nextSettlementIndex,
}) async {
  final nextIndices = {
    'Lx': nextSettlementIndex(site, 'Lx'),
    'Ly': nextSettlementIndex(site, 'Ly'),
  };
  return createEquipment8IfConfirmed(
    context: context,
    site: site,
    pageIndex: pageIndex,
    normalizedX: normalizedX,
    normalizedY: normalizedY,
    nextIndexByDirection: nextIndices,
    nextSettlementIndex: (direction) => nextSettlementIndex(site, direction),
    showSettlementDialog: ({
      required baseTitle,
      required nextIndexByDirection,
    }) =>
        dialogs.settlement(
      baseTitle: baseTitle,
      nextIndexByDirection: nextIndexByDirection,
    ),
  );
}
