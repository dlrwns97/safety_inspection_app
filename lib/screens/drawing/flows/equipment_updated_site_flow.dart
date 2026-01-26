import 'package:flutter/material.dart';

import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/equipment_marker.dart';
import 'package:safety_inspection_app/models/site.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/carbonation_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/core_sampling_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/deflection_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/equipment_details_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/rebar_spacing_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/schmidt_hammer_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/structural_tilt_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/flows/equipment_pack_a_flow.dart';
import 'package:safety_inspection_app/screens/drawing/flows/equipment_pack_b_flow.dart';
import 'package:safety_inspection_app/screens/drawing/flows/equipment_pack_c_flow.dart';
import 'package:safety_inspection_app/screens/drawing/drawing_constants.dart';

String _equipmentDialogTitle(EquipmentCategory category, String label) {
  final config = DrawingEquipmentFlowConfigs[category];
  if (config == null) {
    return label;
  }
  return '${config.dialogTitlePrefix} $label';
}

Future<Site?> createEquipmentUpdatedSite({
  required BuildContext context,
  required Site site,
  required EquipmentCategory? activeEquipmentCategory,
  required EquipmentMarker pendingMarker,
  required String prefix,
  required List<String> deflectionMemberOptions,
  required Future<EquipmentDetails?> Function({
    required String title,
    String? initialMemberType,
    List<String>? initialSizeValues,
  }) showEquipmentDetailsDialog,
  required Future<RebarSpacingDetails?> Function(
    BuildContext, {
    required String title,
    String? initialMemberType,
    String? initialNumberText,
  }) showRebarSpacingDialog,
  required Future<SchmidtHammerDetails?> Function(
    BuildContext, {
    required String title,
    String? initialMemberType,
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
  required Future<DeflectionDetails?> Function({
    required String title,
    required List<String> memberOptions,
    String? initialMemberType,
    String? initialEndAText,
    String? initialMidBText,
    String? initialEndCText,
  }) showDeflectionDialog,
}) async {
  final dialogTitle = _equipmentDialogTitle(
    activeEquipmentCategory ?? pendingMarker.category,
    pendingMarker.label,
  );
  final handlers = <EquipmentCategory, Future<Site?> Function()>{
    EquipmentCategory.equipment1: () => createEquipment1IfConfirmed(
      context: context,
      site: site,
      pageIndex: pendingMarker.pageIndex,
      normalizedX: pendingMarker.normalizedX,
      normalizedY: pendingMarker.normalizedY,
      pendingMarker: pendingMarker,
      prefix: prefix,
      title: dialogTitle,
      initialMemberType: pendingMarker.memberType,
      initialSizeValues: pendingMarker.sizeValues,
      showEquipmentDetailsDialog: showEquipmentDetailsDialog,
    ),
    EquipmentCategory.equipment2: () => createEquipment2IfConfirmed(
      context: context,
      site: site,
      pageIndex: pendingMarker.pageIndex,
      normalizedX: pendingMarker.normalizedX,
      normalizedY: pendingMarker.normalizedY,
      pendingMarker: pendingMarker,
      prefix: prefix,
      title: dialogTitle,
      showRebarSpacingDialog: showRebarSpacingDialog,
    ),
    EquipmentCategory.equipment3: () => createEquipment3IfConfirmed(
      context: context,
      site: site,
      pageIndex: pendingMarker.pageIndex,
      normalizedX: pendingMarker.normalizedX,
      normalizedY: pendingMarker.normalizedY,
      pendingMarker: pendingMarker,
      prefix: prefix,
      title: dialogTitle,
      showSchmidtHammerDialog: showSchmidtHammerDialog,
    ),
    EquipmentCategory.equipment4: () => createEquipment4IfConfirmed(
      context: context,
      site: site,
      pageIndex: pendingMarker.pageIndex,
      normalizedX: pendingMarker.normalizedX,
      normalizedY: pendingMarker.normalizedY,
      pendingMarker: pendingMarker,
      prefix: prefix,
      title: dialogTitle,
      showCoreSamplingDialog: showCoreSamplingDialog,
    ),
    EquipmentCategory.equipment5: () => createEquipment5IfConfirmed(
      context: context,
      site: site,
      pageIndex: pendingMarker.pageIndex,
      normalizedX: pendingMarker.normalizedX,
      normalizedY: pendingMarker.normalizedY,
      pendingMarker: pendingMarker,
      prefix: prefix,
      title: dialogTitle,
      initialMemberType: pendingMarker.memberType,
      initialCoverThicknessText: pendingMarker.coverThicknessText,
      initialDepthText: pendingMarker.depthText,
      showCarbonationDialog: showCarbonationDialog,
    ),
    EquipmentCategory.equipment6: () => createEquipment6IfConfirmed(
      context: context,
      site: site,
      pageIndex: pendingMarker.pageIndex,
      normalizedX: pendingMarker.normalizedX,
      normalizedY: pendingMarker.normalizedY,
      pendingMarker: pendingMarker,
      prefix: prefix,
      title: dialogTitle,
      initialDirection: pendingMarker.tiltDirection,
      initialDisplacementText: pendingMarker.displacementText,
      showStructuralTiltDialog: showStructuralTiltDialog,
    ),
    EquipmentCategory.equipment7: () => createEquipment7IfConfirmed(
      context: context,
      site: site,
      pageIndex: pendingMarker.pageIndex,
      normalizedX: pendingMarker.normalizedX,
      normalizedY: pendingMarker.normalizedY,
      pendingMarker: pendingMarker,
      prefix: prefix,
      title: dialogTitle,
      initialMemberType: pendingMarker.memberType,
      initialEndAText: pendingMarker.deflectionEndAText,
      initialMidBText: pendingMarker.deflectionMidBText,
      initialEndCText: pendingMarker.deflectionEndCText,
      showDeflectionDialog: showDeflectionDialog,
      memberOptions: deflectionMemberOptions,
    ),
  };
  final handler = handlers[activeEquipmentCategory];
  if (handler == null) {
    return null;
  }
  return handler();
}
