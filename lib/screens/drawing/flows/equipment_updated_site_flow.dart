import 'package:flutter/material.dart';
import 'package:safety_inspection_app/application/inspection/use_cases/create_equipment_updated_site_use_case.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/equipment_marker.dart';
import 'package:safety_inspection_app/models/rebar_spacing_group_details.dart';
import 'package:safety_inspection_app/models/site.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/carbonation_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/core_sampling_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/deflection_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/equipment_details_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/schmidt_hammer_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/structural_tilt_dialog.dart';

final CreateEquipmentUpdatedSiteUseCase _createEquipmentUpdatedSiteUseCase =
    CreateEquipmentUpdatedSiteUseCase();

Future<Site?> createEquipmentUpdatedSite({
  required BuildContext context,
  required Site site,
  required EquipmentCategory? activeEquipmentCategory,
  required EquipmentMarker pendingMarker,
  required String prefix,
  bool allowRebarSpacingMulti = true,
  required List<String> deflectionMemberOptions,
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
}) async {
  return _createEquipmentUpdatedSiteUseCase.execute(
    context: context,
    site: site,
    activeEquipmentCategory: activeEquipmentCategory,
    pendingMarker: pendingMarker,
    prefix: prefix,
    allowRebarSpacingMulti: allowRebarSpacingMulti,
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
