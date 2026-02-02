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
    this.sizeValues,
    this.maxValueText,
    this.minValueText,
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
  final List<String>? sizeValues;
  final String? maxValueText;
  final String? minValueText;
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
    List<String>? sizeValues,
    String? maxValueText,
    String? minValueText,
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
      sizeValues: sizeValues ?? this.sizeValues,
      maxValueText: maxValueText ?? this.maxValueText,
      minValueText: minValueText ?? this.minValueText,
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
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'pageIndex': pageIndex,
    'category': category.name,
    'normalizedX': normalizedX,
    'normalizedY': normalizedY,
    'equipmentTypeId': equipmentTypeId,
    'memberType': memberType,
    'numberText': numberText,
    'sizeValues': sizeValues,
    'maxValueText': maxValueText,
    'minValueText': minValueText,
    'avgValueText': avgValueText,
    'coverThicknessText': coverThicknessText,
    'depthText': depthText,
    'tiltDirection': tiltDirection,
    'displacementText': displacementText,
    'deflectionEndAText': deflectionEndAText,
    'deflectionMidBText': deflectionMidBText,
    'deflectionEndCText': deflectionEndCText,
    'remark': remark,
    'wComplete': wComplete,
    'hComplete': hComplete,
    'dComplete': dComplete,
  };

  factory EquipmentMarker.fromJson(Map<String, dynamic> json) =>
      EquipmentMarker(
        id: json['id'] as String,
        label: json['label'] as String,
        pageIndex: json['pageIndex'] as int? ?? 0,
        category: EquipmentCategory.values.byName(
          json['category'] as String? ?? 'equipment1',
        ),
        normalizedX: (json['normalizedX'] as num? ?? 0).toDouble(),
        normalizedY: (json['normalizedY'] as num? ?? 0).toDouble(),
        equipmentTypeId: json['equipmentTypeId'] as String?,
        memberType: json['memberType'] as String?,
        numberText: json['numberText'] as String?,
        sizeValues: (json['sizeValues'] as List<dynamic>?)
            ?.map((value) => value.toString())
            .toList(),
        maxValueText: json['maxValueText'] as String?,
        minValueText: json['minValueText'] as String?,
        avgValueText: json['avgValueText'] as String?,
        coverThicknessText: json['coverThicknessText'] as String?,
        depthText: json['depthText'] as String?,
        tiltDirection: json['tiltDirection'] as String?,
        displacementText: json['displacementText'] as String?,
        deflectionEndAText: json['deflectionEndAText'] as String?,
        deflectionMidBText: json['deflectionMidBText'] as String?,
        deflectionEndCText: json['deflectionEndCText'] as String?,
        remark: json['remark'] as String?,
        wComplete: json['wComplete'] as bool? ?? true,
        hComplete: json['hComplete'] as bool? ?? true,
        dComplete: json['dComplete'] as bool? ?? true,
      );
}
