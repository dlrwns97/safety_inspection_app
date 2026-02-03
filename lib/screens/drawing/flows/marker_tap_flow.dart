import 'package:flutter/material.dart';

import 'package:safety_inspection_app/models/defect_details.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/equipment_marker.dart';
import 'package:safety_inspection_app/models/rebar_spacing_group_details.dart';
import 'package:safety_inspection_app/models/site.dart';
import 'package:safety_inspection_app/screens/drawing/drawing_controller.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/carbonation_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/core_sampling_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/deflection_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/equipment_details_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/schmidt_hammer_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/settlement_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/structural_tilt_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/flows/defect_marker_flow.dart';
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
  required Future<EquipmentDetails?> Function({
    required String title,
    String? initialMemberType,
    List<String>? initialSizeValues,
    String? initialRemark,
    bool? initialWComplete,
    bool? initialHComplete,
    bool? initialDComplete,
  }) showEquipmentDetailsDialog,
  required Future<RebarSpacingGroupDetails?> Function(
    BuildContext, {
    required String title,
    String? initialMemberType,
    List<RebarSpacingMeasurement>? initialMeasurements,
    bool allowMultiple,
    int? baseLabelIndex,
    String? labelPrefix,
  }) showRebarSpacingDialog,
  required Future<SchmidtHammerDetails?> Function(
    BuildContext, {
    required String title,
    String? initialMemberType,
    int? initialAngleDeg,
    String? initialMaxValueText,
    String? initialMinValueText,
  }) showSchmidtHammerDialog,
  required Future<CoreSamplingDetails?> Function(
    BuildContext, {
    required String title,
    String? initialMemberType,
    String? initialAvgValueText,
  }) showCoreSamplingDialog,
  required Future<CarbonationDetails?> Function({
    required String title,
    String? initialMemberType,
    String? initialCoverThicknessText,
    String? initialDepthText,
  }) showCarbonationDialog,
  required Future<StructuralTiltDetails?> Function({
    required String title,
    String? initialDirection,
    String? initialDisplacementText,
  }) showStructuralTiltDialog,
  required Future<SettlementDetails?> Function({
    required String baseTitle,
    required Map<String, int> nextIndexByDirection,
  }) showSettlementDialog,
  required Future<DeflectionDetails?> Function({
    required String title,
    required List<String> memberOptions,
    String? initialMemberType,
    String? initialEndAText,
    String? initialMidBText,
    String? initialEndCText,
  }) showDeflectionDialog,
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
    showEquipmentDetailsDialog: showEquipmentDetailsDialog,
    showRebarSpacingDialog: showRebarSpacingDialog,
    showSchmidtHammerDialog: showSchmidtHammerDialog,
    showCoreSamplingDialog: showCoreSamplingDialog,
    showCarbonationDialog: showCarbonationDialog,
    showStructuralTiltDialog: showStructuralTiltDialog,
    showSettlementDialog: showSettlementDialog,
    showDeflectionDialog: showDeflectionDialog,
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
  required Future<EquipmentDetails?> Function({
    required String title,
    String? initialMemberType,
    List<String>? initialSizeValues,
    String? initialRemark,
    bool? initialWComplete,
    bool? initialHComplete,
    bool? initialDComplete,
  }) showEquipmentDetailsDialog,
  required Future<RebarSpacingGroupDetails?> Function(
    BuildContext, {
    required String title,
    String? initialMemberType,
    List<RebarSpacingMeasurement>? initialMeasurements,
    bool allowMultiple,
    int? baseLabelIndex,
    String? labelPrefix,
  }) showRebarSpacingDialog,
  required Future<SchmidtHammerDetails?> Function(
    BuildContext, {
    required String title,
    String? initialMemberType,
    int? initialAngleDeg,
    String? initialMaxValueText,
    String? initialMinValueText,
  }) showSchmidtHammerDialog,
  required Future<CoreSamplingDetails?> Function(
    BuildContext, {
    required String title,
    String? initialMemberType,
    String? initialAvgValueText,
  }) showCoreSamplingDialog,
  required Future<CarbonationDetails?> Function({
    required String title,
    String? initialMemberType,
    String? initialCoverThicknessText,
    String? initialDepthText,
  }) showCarbonationDialog,
  required Future<StructuralTiltDetails?> Function({
    required String title,
    String? initialDirection,
    String? initialDisplacementText,
  }) showStructuralTiltDialog,
  required Future<SettlementDetails?> Function({
    required String baseTitle,
    required Map<String, int> nextIndexByDirection,
  }) showSettlementDialog,
  required Future<DeflectionDetails?> Function({
    required String title,
    required List<String> memberOptions,
    String? initialMemberType,
    String? initialEndAText,
    String? initialMidBText,
    String? initialEndCText,
  }) showDeflectionDialog,
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
    showEquipmentDetailsDialog: showEquipmentDetailsDialog,
    showRebarSpacingDialog: showRebarSpacingDialog,
    showSchmidtHammerDialog: showSchmidtHammerDialog,
    showCoreSamplingDialog: showCoreSamplingDialog,
    showCarbonationDialog: showCarbonationDialog,
    showStructuralTiltDialog: showStructuralTiltDialog,
    showSettlementDialog: showSettlementDialog,
    showDeflectionDialog: showDeflectionDialog,
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

class _EquipmentMarkerDraft {
  const _EquipmentMarkerDraft({
    required this.prefix,
    required this.marker,
  });

  final String prefix;
  final EquipmentMarker marker;
}

bool _isEquipment8(EquipmentCategory category) {
  return category == EquipmentCategory.equipment8;
}

int _equipmentCountForCategory(Site site, EquipmentCategory category) {
  return site.equipmentMarkers
      .where((marker) => marker.category == category)
      .length;
}

_EquipmentMarkerDraft _buildEquipmentMarkerDraft({
  required Site site,
  required EquipmentCategory category,
  required int pageIndex,
  required double normalizedX,
  required double normalizedY,
}) {
  final equipmentCount = _equipmentCountForCategory(site, category);
  final prefix = equipmentLabelPrefix(category);
  final label = '$prefix${equipmentCount + 1}';
  return _EquipmentMarkerDraft(
    prefix: prefix,
    marker: EquipmentMarker(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      label: label,
      pageIndex: pageIndex,
      category: category,
      normalizedX: normalizedX,
      normalizedY: normalizedY,
      equipmentTypeId: prefix,
    ),
  );
}

Map<String, int> _buildSettlementNextIndices(
  Site site,
  int Function(Site site, String direction) nextSettlementIndex,
) {
  return {
    'Lx': nextSettlementIndex(site, 'Lx'),
    'Ly': nextSettlementIndex(site, 'Ly'),
  };
}

Future<Site?> addEquipmentMarker({
  required BuildContext context,
  required Site site,
  required EquipmentCategory? activeEquipmentCategory,
  required int pageIndex,
  required double normalizedX,
  required double normalizedY,
  required Future<EquipmentDetails?> Function({
    required String title,
    String? initialMemberType,
    List<String>? initialSizeValues,
    String? initialRemark,
    bool? initialWComplete,
    bool? initialHComplete,
    bool? initialDComplete,
  }) showEquipmentDetailsDialog,
  required Future<RebarSpacingGroupDetails?> Function(
    BuildContext, {
    required String title,
    String? initialMemberType,
    List<RebarSpacingMeasurement>? initialMeasurements,
    bool allowMultiple,
    int? baseLabelIndex,
    String? labelPrefix,
  }) showRebarSpacingDialog,
  required Future<SchmidtHammerDetails?> Function(
    BuildContext, {
    required String title,
    String? initialMemberType,
    int? initialAngleDeg,
    String? initialMaxValueText,
    String? initialMinValueText,
  }) showSchmidtHammerDialog,
  required Future<CoreSamplingDetails?> Function(
    BuildContext, {
    required String title,
    String? initialMemberType,
    String? initialAvgValueText,
  }) showCoreSamplingDialog,
  required Future<CarbonationDetails?> Function({
    required String title,
    String? initialMemberType,
    String? initialCoverThicknessText,
    String? initialDepthText,
  }) showCarbonationDialog,
  required Future<StructuralTiltDetails?> Function({
    required String title,
    String? initialDirection,
    String? initialDisplacementText,
  }) showStructuralTiltDialog,
  required Future<SettlementDetails?> Function({
    required String baseTitle,
    required Map<String, int> nextIndexByDirection,
  }) showSettlementDialog,
  required Future<DeflectionDetails?> Function({
    required String title,
    required List<String> memberOptions,
    String? initialMemberType,
    String? initialEndAText,
    String? initialMidBText,
    String? initialEndCText,
  }) showDeflectionDialog,
  required List<String> deflectionMemberOptions,
  required int Function(Site site, String direction) nextSettlementIndex,
}) async {
  if (activeEquipmentCategory == null) {
    return null;
  }
  if (_isEquipment8(activeEquipmentCategory)) {
    return addEquipment8Marker(
      context: context,
      site: site,
      pageIndex: pageIndex,
      normalizedX: normalizedX,
      normalizedY: normalizedY,
      showSettlementDialog: showSettlementDialog,
      nextSettlementIndex: nextSettlementIndex,
    );
  }
  final draft = _buildEquipmentMarkerDraft(
    site: site,
    category: activeEquipmentCategory,
    pageIndex: pageIndex,
    normalizedX: normalizedX,
    normalizedY: normalizedY,
  );

  return createEquipmentUpdatedSite(
    context: context,
    site: site,
    activeEquipmentCategory: activeEquipmentCategory,
    pendingMarker: draft.marker,
    prefix: draft.prefix,
    allowRebarSpacingMulti: true,
    deflectionMemberOptions: deflectionMemberOptions,
    showEquipmentDetailsDialog: showEquipmentDetailsDialog,
    showRebarSpacingDialog: showRebarSpacingDialog,
    showSchmidtHammerDialog: showSchmidtHammerDialog,
    showCoreSamplingDialog: showCoreSamplingDialog,
    showCarbonationDialog: showCarbonationDialog,
    showStructuralTiltDialog: showStructuralTiltDialog,
    showDeflectionDialog: showDeflectionDialog,
  );
}

Future<Site?> addEquipment8Marker({
  required BuildContext context,
  required Site site,
  required int pageIndex,
  required double normalizedX,
  required double normalizedY,
  required Future<SettlementDetails?> Function({
    required String baseTitle,
    required Map<String, int> nextIndexByDirection,
  }) showSettlementDialog,
  required int Function(Site site, String direction) nextSettlementIndex,
}) async {
  final nextIndices = _buildSettlementNextIndices(site, nextSettlementIndex);
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
        showSettlementDialog(
      baseTitle: baseTitle,
      nextIndexByDirection: nextIndexByDirection,
    ),
  );
}
