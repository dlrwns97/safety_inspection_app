import 'package:flutter/material.dart';

import 'package:safety_inspection_app/application/inspection/use_cases/marker_tap_use_case.dart';
import 'package:safety_inspection_app/models/defect_details.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
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
import 'package:safety_inspection_app/screens/drawing/widgets/drawing_local_parts.dart';

final MarkerTapUseCase _markerTapUseCase = MarkerTapUseCase();

bool applyTapDecision({
  required TapDecision decision,
  required MarkerHitResult? hitResult,
  required VoidCallback onResetTapCanceled,
  required void Function(MarkerHitResult result) onSelectHit,
  required VoidCallback onClearSelection,
  required VoidCallback onShowDefectCategoryHint,
}) {
  return _markerTapUseCase.applyTapDecision(
    decision: decision,
    hitResult: hitResult,
    onResetTapCanceled: onResetTapCanceled,
    onSelectHit: onSelectHit,
    onClearSelection: onClearSelection,
    onShowDefectCategoryHint: onShowDefectCategoryHint,
  );
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
  required Future<DefectDetails?> Function(
    BuildContext context,
    String defectId,
  )
  showDefectDetailsDialog,
  required Future<EquipmentDetails?> Function({
    required String title,
    String? initialMemberType,
    List<String>? initialSizeValues,
    String? initialRemark,
    bool? initialWComplete,
    bool? initialHComplete,
    bool? initialDComplete,
  })
  showEquipmentDetailsDialog,
  required Future<RebarSpacingGroupDetails?> Function(
    BuildContext, {
    required String title,
    String? initialMemberType,
    List<RebarSpacingMeasurement>? initialMeasurements,
    bool allowMultiple,
    int? baseLabelIndex,
    String? labelPrefix,
  })
  showRebarSpacingDialog,
  required Future<SchmidtHammerDetails?> Function(
    BuildContext, {
    required String title,
    String? initialMemberType,
    int? initialAngleDeg,
    String? initialMaxValueText,
    String? initialMinValueText,
  })
  showSchmidtHammerDialog,
  required Future<CoreSamplingDetails?> Function(
    BuildContext, {
    required String title,
    String? initialMemberType,
    String? initialAvgValueText,
  })
  showCoreSamplingDialog,
  required Future<CarbonationDetails?> Function({
    required String title,
    String? initialMemberType,
    String? initialCoverThicknessText,
    String? initialDepthText,
  })
  showCarbonationDialog,
  required Future<StructuralTiltDetails?> Function({
    required String title,
    String? initialDirection,
    String? initialDisplacementText,
  })
  showStructuralTiltDialog,
  required Future<SettlementDetails?> Function({
    required String baseTitle,
    required Map<String, int> nextIndexByDirection,
  })
  showSettlementDialog,
  required Future<DeflectionDetails?> Function({
    required String title,
    required List<String> memberOptions,
    String? initialMemberType,
    String? initialEndAText,
    String? initialMidBText,
    String? initialEndCText,
  })
  showDeflectionDialog,
  required List<String> deflectionMemberOptions,
  required int Function(Site site, String direction) nextSettlementIndex,
}) async {
  return _markerTapUseCase.handleTapCore(
    context: context,
    hitResult: hitResult,
    decision: decision,
    pageIndex: pageIndex,
    normalizedX: normalizedX,
    normalizedY: normalizedY,
    site: site,
    mode: mode,
    activeCategory: activeCategory,
    activeEquipmentCategory: activeEquipmentCategory,
    onResetTapCanceled: onResetTapCanceled,
    onSelectHit: onSelectHit,
    onClearSelection: onClearSelection,
    onShowDefectCategoryHint: onShowDefectCategoryHint,
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
  required Future<DefectDetails?> Function(
    BuildContext context,
    String defectId,
  )
  showDefectDetailsDialog,
  required Future<EquipmentDetails?> Function({
    required String title,
    String? initialMemberType,
    List<String>? initialSizeValues,
    String? initialRemark,
    bool? initialWComplete,
    bool? initialHComplete,
    bool? initialDComplete,
  })
  showEquipmentDetailsDialog,
  required Future<RebarSpacingGroupDetails?> Function(
    BuildContext, {
    required String title,
    String? initialMemberType,
    List<RebarSpacingMeasurement>? initialMeasurements,
    bool allowMultiple,
    int? baseLabelIndex,
    String? labelPrefix,
  })
  showRebarSpacingDialog,
  required Future<SchmidtHammerDetails?> Function(
    BuildContext, {
    required String title,
    String? initialMemberType,
    int? initialAngleDeg,
    String? initialMaxValueText,
    String? initialMinValueText,
  })
  showSchmidtHammerDialog,
  required Future<CoreSamplingDetails?> Function(
    BuildContext, {
    required String title,
    String? initialMemberType,
    String? initialAvgValueText,
  })
  showCoreSamplingDialog,
  required Future<CarbonationDetails?> Function({
    required String title,
    String? initialMemberType,
    String? initialCoverThicknessText,
    String? initialDepthText,
  })
  showCarbonationDialog,
  required Future<StructuralTiltDetails?> Function({
    required String title,
    String? initialDirection,
    String? initialDisplacementText,
  })
  showStructuralTiltDialog,
  required Future<SettlementDetails?> Function({
    required String baseTitle,
    required Map<String, int> nextIndexByDirection,
  })
  showSettlementDialog,
  required Future<DeflectionDetails?> Function({
    required String title,
    required List<String> memberOptions,
    String? initialMemberType,
    String? initialEndAText,
    String? initialMidBText,
    String? initialEndCText,
  })
  showDeflectionDialog,
  required List<String> deflectionMemberOptions,
  required int Function(Site site, String direction) nextSettlementIndex,
}) async {
  return _markerTapUseCase.createMarkerFromTap(
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

Future<Site?> addDefectMarker({
  required BuildContext context,
  required Site site,
  required int pageIndex,
  required double normalizedX,
  required double normalizedY,
  required DefectCategory activeCategory,
  required Future<DefectDetails?> Function(
    BuildContext context,
    String defectId,
  )
  showDefectDetailsDialog,
}) async {
  return _markerTapUseCase.addDefectMarker(
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
  required Future<EquipmentDetails?> Function({
    required String title,
    String? initialMemberType,
    List<String>? initialSizeValues,
    String? initialRemark,
    bool? initialWComplete,
    bool? initialHComplete,
    bool? initialDComplete,
  })
  showEquipmentDetailsDialog,
  required Future<RebarSpacingGroupDetails?> Function(
    BuildContext, {
    required String title,
    String? initialMemberType,
    List<RebarSpacingMeasurement>? initialMeasurements,
    bool allowMultiple,
    int? baseLabelIndex,
    String? labelPrefix,
  })
  showRebarSpacingDialog,
  required Future<SchmidtHammerDetails?> Function(
    BuildContext, {
    required String title,
    String? initialMemberType,
    int? initialAngleDeg,
    String? initialMaxValueText,
    String? initialMinValueText,
  })
  showSchmidtHammerDialog,
  required Future<CoreSamplingDetails?> Function(
    BuildContext, {
    required String title,
    String? initialMemberType,
    String? initialAvgValueText,
  })
  showCoreSamplingDialog,
  required Future<CarbonationDetails?> Function({
    required String title,
    String? initialMemberType,
    String? initialCoverThicknessText,
    String? initialDepthText,
  })
  showCarbonationDialog,
  required Future<StructuralTiltDetails?> Function({
    required String title,
    String? initialDirection,
    String? initialDisplacementText,
  })
  showStructuralTiltDialog,
  required Future<SettlementDetails?> Function({
    required String baseTitle,
    required Map<String, int> nextIndexByDirection,
  })
  showSettlementDialog,
  required Future<DeflectionDetails?> Function({
    required String title,
    required List<String> memberOptions,
    String? initialMemberType,
    String? initialEndAText,
    String? initialMidBText,
    String? initialEndCText,
  })
  showDeflectionDialog,
  required List<String> deflectionMemberOptions,
  required int Function(Site site, String direction) nextSettlementIndex,
}) async {
  return _markerTapUseCase.addEquipmentMarker(
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

Future<Site?> addEquipment8Marker({
  required BuildContext context,
  required Site site,
  required int pageIndex,
  required double normalizedX,
  required double normalizedY,
  required Future<SettlementDetails?> Function({
    required String baseTitle,
    required Map<String, int> nextIndexByDirection,
  })
  showSettlementDialog,
  required int Function(Site site, String direction) nextSettlementIndex,
}) async {
  return _markerTapUseCase.addEquipment8Marker(
    context: context,
    site: site,
    pageIndex: pageIndex,
    normalizedX: normalizedX,
    normalizedY: normalizedY,
    showSettlementDialog: showSettlementDialog,
    nextSettlementIndex: nextSettlementIndex,
  );
}
