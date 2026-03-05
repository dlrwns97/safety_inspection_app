import 'drawing_enums.dart';

class EquipmentMarker {
  EquipmentMarker({
    required this.id,
    required this.label,
    required this.pageIndex,
    required this.category,
    required this.normalizedX,
    required this.normalizedY,
    this.equipmentTypeId,
    this.memberType,
    this.numberText,
    this.remarkLeft,
    this.remarkRight,
    this.numberPrefix,
    this.numberValue,
    this.sizeValues,
    this.maxValueText,
    this.minValueText,
    this.schmidtAngleDeg,
    this.schmidtMinValue,
    this.schmidtMaxValue,
    this.avgValueText,
    this.coverThicknessText,
    this.depthText,
    this.tiltDirection,
    this.displacementText,
    this.deflectionEndAText,
    this.deflectionMidBText,
    this.deflectionEndCText,
    this.remark,
    this.wComplete,
    this.hComplete,
    this.dComplete,
    this.details,
  });

  final String id;
  final String label;
  final int pageIndex;
  final EquipmentCategory category;
  final double normalizedX;
  final double normalizedY;
  final String? equipmentTypeId;
  final String? memberType;
  final String? numberText;
  final String? remarkLeft;
  final String? remarkRight;
  final String? numberPrefix;
  final String? numberValue;
  final List<String>? sizeValues;
  final String? maxValueText;
  final String? minValueText;
  final int? schmidtAngleDeg;
  final String? schmidtMinValue;
  final String? schmidtMaxValue;
  final String? avgValueText;
  final String? coverThicknessText;
  final String? depthText;
  final String? tiltDirection;
  final String? displacementText;
  final String? deflectionEndAText;
  final String? deflectionMidBText;
  final String? deflectionEndCText;
  final String? remark;
  final bool? wComplete;
  final bool? hComplete;
  final bool? dComplete;
  final String? details;

  EquipmentMarker copyWith({
    String? id,
    String? label,
    int? pageIndex,
    EquipmentCategory? category,
    double? normalizedX,
    double? normalizedY,
    String? equipmentTypeId,
    String? memberType,
    String? numberText,
    String? remarkLeft,
    String? remarkRight,
    String? numberPrefix,
    String? numberValue,
    List<String>? sizeValues,
    String? maxValueText,
    String? minValueText,
    int? schmidtAngleDeg,
    String? schmidtMinValue,
    String? schmidtMaxValue,
    String? avgValueText,
    String? coverThicknessText,
    String? depthText,
    String? tiltDirection,
    String? displacementText,
    String? deflectionEndAText,
    String? deflectionMidBText,
    String? deflectionEndCText,
    String? remark,
    bool? wComplete,
    bool? hComplete,
    bool? dComplete,
    String? details,
  }) {
    return EquipmentMarker(
      id: id ?? this.id,
      label: label ?? this.label,
      pageIndex: pageIndex ?? this.pageIndex,
      category: category ?? this.category,
      normalizedX: normalizedX ?? this.normalizedX,
      normalizedY: normalizedY ?? this.normalizedY,
      equipmentTypeId: equipmentTypeId ?? this.equipmentTypeId,
      memberType: memberType ?? this.memberType,
      numberText: numberText ?? this.numberText,
      remarkLeft: remarkLeft ?? this.remarkLeft,
      remarkRight: remarkRight ?? this.remarkRight,
      numberPrefix: numberPrefix ?? this.numberPrefix,
      numberValue: numberValue ?? this.numberValue,
      sizeValues: sizeValues ?? this.sizeValues,
      maxValueText: maxValueText ?? this.maxValueText,
      minValueText: minValueText ?? this.minValueText,
      schmidtAngleDeg: schmidtAngleDeg ?? this.schmidtAngleDeg,
      schmidtMinValue: schmidtMinValue ?? this.schmidtMinValue,
      schmidtMaxValue: schmidtMaxValue ?? this.schmidtMaxValue,
      avgValueText: avgValueText ?? this.avgValueText,
      coverThicknessText: coverThicknessText ?? this.coverThicknessText,
      depthText: depthText ?? this.depthText,
      tiltDirection: tiltDirection ?? this.tiltDirection,
      displacementText: displacementText ?? this.displacementText,
      deflectionEndAText: deflectionEndAText ?? this.deflectionEndAText,
      deflectionMidBText: deflectionMidBText ?? this.deflectionMidBText,
      deflectionEndCText: deflectionEndCText ?? this.deflectionEndCText,
      remark: remark ?? this.remark,
      wComplete: wComplete ?? this.wComplete,
      hComplete: hComplete ?? this.hComplete,
      dComplete: dComplete ?? this.dComplete,
      details: details ?? this.details,
    );
  }
}
