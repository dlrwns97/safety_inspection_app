import 'package:flutter/material.dart';
import 'package:safety_inspection_app/models/defect_details.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/equipment_marker.dart';
import 'package:safety_inspection_app/models/rebar_spacing_group_details.dart';
import 'package:safety_inspection_app/models/site.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/carbonation_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/core_sampling_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/deflection_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/equipment_details_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/schmidt_hammer_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/settlement_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/structural_tilt_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/drawing_controller.dart';
import 'package:safety_inspection_app/screens/drawing/flows/drawing_lookup_helpers.dart';
import 'package:safety_inspection_app/screens/drawing/flows/equipment_updated_site_flow.dart';
import 'package:safety_inspection_app/screens/drawing/flows/marker_presenters.dart';
import 'package:safety_inspection_app/screens/drawing/flows/marker_tap_flow.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/drawing_local_parts.dart';

class MarkerActionCoordinator {
  const MarkerActionCoordinator();

  Future<Site?> handleTap({
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
    required Future<DefectDetails?> Function(BuildContext, String defectId)
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
  }) {
    return handleTapCore(
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

  Future<EquipmentMarker?> editEquipmentMarker({
    required BuildContext context,
    required Site site,
    required EquipmentMarker marker,
    required Future<SettlementDetails?> Function({
      required String baseTitle,
      required Map<String, int> nextIndexByDirection,
      String? initialDirection,
      String? initialDisplacementText,
    })
    showSettlementDialog,
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
  }) async {
    if (marker.category == EquipmentCategory.equipment8) {
      final nextIndexByDirection = <String, int>{
        'Lx': nextSettlementIndex(site, 'Lx'),
        'Ly': nextSettlementIndex(site, 'Ly'),
      };
      final details = await showSettlementDialog(
        baseTitle: '부동침하',
        nextIndexByDirection: nextIndexByDirection,
        initialDirection: settlementDirection(marker),
        initialDisplacementText: marker.displacementText,
      );
      if (details == null) {
        return null;
      }
      return marker.copyWith(
        equipmentTypeId: details.direction,
        tiltDirection: details.direction,
        displacementText: details.displacementText,
      );
    }

    final siteWithoutMarker = site.copyWith(
      equipmentMarkers: site.equipmentMarkers
          .where((item) => item.id != marker.id)
          .toList(),
    );
    final updatedSite = await createEquipmentUpdatedSite(
      context: context,
      site: siteWithoutMarker,
      activeEquipmentCategory: marker.category,
      pendingMarker: marker,
      prefix: equipmentLabelPrefix(marker.category),
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
    if (updatedSite == null) {
      return null;
    }
    for (final item in updatedSite.equipmentMarkers) {
      if (item.id == marker.id) {
        return item;
      }
    }
    return null;
  }
}
