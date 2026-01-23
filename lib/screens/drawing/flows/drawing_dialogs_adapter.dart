import 'package:safety_inspection_app/screens/drawing/dialogs/carbonation_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/core_sampling_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/deflection_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/equipment_details_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/rebar_spacing_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/schmidt_hammer_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/settlement_dialog.dart';
import 'package:safety_inspection_app/screens/drawing/dialogs/structural_tilt_dialog.dart';

class DrawingDialogsAdapter {
  DrawingDialogsAdapter({
    required Future<EquipmentDetails?> Function({
      required String title,
      String? initialMemberType,
      List<String>? initialSizeValues,
    })
        equipmentDetails,
    required Future<RebarSpacingDetails?> Function({
      required String title,
      String? initialMemberType,
      String? initialNumberText,
    })
        rebarSpacing,
    required Future<SchmidtHammerDetails?> Function({
      required String title,
      String? initialMemberType,
      String? initialMaxValueText,
      String? initialMinValueText,
    })
        schmidtHammer,
    required Future<CoreSamplingDetails?> Function({
      required String title,
      String? initialMemberType,
      String? initialAvgValueText,
    })
        coreSampling,
    required Future<CarbonationDetails?> Function({
      required String title,
      String? initialMemberType,
      String? initialCoverThicknessText,
      String? initialDepthText,
    })
        carbonation,
    required Future<StructuralTiltDetails?> Function({
      required String title,
      String? initialDirection,
      String? initialDisplacementText,
    })
        structuralTilt,
    required Future<SettlementDetails?> Function({
      required String baseTitle,
      required Map<String, int> nextIndexByDirection,
      String? initialDirection,
      String? initialDisplacementText,
    })
        settlement,
    required Future<DeflectionDetails?> Function({
      required String title,
      String? initialMemberType,
      String? initialEndAText,
      String? initialMidBText,
      String? initialEndCText,
    })
        deflection,
  })  : _equipmentDetails = equipmentDetails,
        _rebarSpacing = rebarSpacing,
        _schmidtHammer = schmidtHammer,
        _coreSampling = coreSampling,
        _carbonation = carbonation,
        _structuralTilt = structuralTilt,
        _settlement = settlement,
        _deflection = deflection;

  final Future<EquipmentDetails?> Function({
    required String title,
    String? initialMemberType,
    List<String>? initialSizeValues,
  }) _equipmentDetails;
  final Future<RebarSpacingDetails?> Function({
    required String title,
    String? initialMemberType,
    String? initialNumberText,
  }) _rebarSpacing;
  final Future<SchmidtHammerDetails?> Function({
    required String title,
    String? initialMemberType,
    String? initialMaxValueText,
    String? initialMinValueText,
  }) _schmidtHammer;
  final Future<CoreSamplingDetails?> Function({
    required String title,
    String? initialMemberType,
    String? initialAvgValueText,
  }) _coreSampling;
  final Future<CarbonationDetails?> Function({
    required String title,
    String? initialMemberType,
    String? initialCoverThicknessText,
    String? initialDepthText,
  }) _carbonation;
  final Future<StructuralTiltDetails?> Function({
    required String title,
    String? initialDirection,
    String? initialDisplacementText,
  }) _structuralTilt;
  final Future<SettlementDetails?> Function({
    required String baseTitle,
    required Map<String, int> nextIndexByDirection,
    String? initialDirection,
    String? initialDisplacementText,
  }) _settlement;
  final Future<DeflectionDetails?> Function({
    required String title,
    String? initialMemberType,
    String? initialEndAText,
    String? initialMidBText,
    String? initialEndCText,
  }) _deflection;

  Future<EquipmentDetails?> equipmentDetails({
    required String title,
    String? initialMemberType,
    List<String>? initialSizeValues,
  }) =>
      _equipmentDetails(
        title: title,
        initialMemberType: initialMemberType,
        initialSizeValues: initialSizeValues,
      );

  Future<RebarSpacingDetails?> rebarSpacing({
    required String title,
    String? initialMemberType,
    String? initialNumberText,
  }) =>
      _rebarSpacing(
        title: title,
        initialMemberType: initialMemberType,
        initialNumberText: initialNumberText,
      );

  Future<SchmidtHammerDetails?> schmidtHammer({
    required String title,
    String? initialMemberType,
    String? initialMaxValueText,
    String? initialMinValueText,
  }) =>
      _schmidtHammer(
        title: title,
        initialMemberType: initialMemberType,
        initialMaxValueText: initialMaxValueText,
        initialMinValueText: initialMinValueText,
      );

  Future<CoreSamplingDetails?> coreSampling({
    required String title,
    String? initialMemberType,
    String? initialAvgValueText,
  }) =>
      _coreSampling(
        title: title,
        initialMemberType: initialMemberType,
        initialAvgValueText: initialAvgValueText,
      );

  Future<CarbonationDetails?> carbonation({
    required String title,
    String? initialMemberType,
    String? initialCoverThicknessText,
    String? initialDepthText,
  }) =>
      _carbonation(
        title: title,
        initialMemberType: initialMemberType,
        initialCoverThicknessText: initialCoverThicknessText,
        initialDepthText: initialDepthText,
      );

  Future<StructuralTiltDetails?> structuralTilt({
    required String title,
    String? initialDirection,
    String? initialDisplacementText,
  }) =>
      _structuralTilt(
        title: title,
        initialDirection: initialDirection,
        initialDisplacementText: initialDisplacementText,
      );

  Future<SettlementDetails?> settlement({
    required String baseTitle,
    required Map<String, int> nextIndexByDirection,
    String? initialDirection,
    String? initialDisplacementText,
  }) =>
      _settlement(
        baseTitle: baseTitle,
        nextIndexByDirection: nextIndexByDirection,
        initialDirection: initialDirection,
        initialDisplacementText: initialDisplacementText,
      );

  Future<DeflectionDetails?> deflection({
    required String title,
    String? initialMemberType,
    String? initialEndAText,
    String? initialMidBText,
    String? initialEndCText,
  }) =>
      _deflection(
        title: title,
        initialMemberType: initialMemberType,
        initialEndAText: initialEndAText,
        initialMidBText: initialMidBText,
        initialEndCText: initialEndCText,
      );
}
