import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/equipment_marker.dart';

class EquipmentMarkerMapper {
  const EquipmentMarkerMapper._();

  static Map<String, dynamic> toJson(EquipmentMarker marker) => {
    'id': marker.id,
    'label': marker.label,
    'pageIndex': marker.pageIndex,
    'category': marker.category.name,
    'normalizedX': marker.normalizedX,
    'normalizedY': marker.normalizedY,
    'equipmentTypeId': marker.equipmentTypeId,
    'memberType': marker.memberType,
    'numberText': marker.numberText,
    'remarkLeft': marker.remarkLeft,
    'remarkRight': marker.remarkRight,
    'numberPrefix': marker.numberPrefix,
    'numberValue': marker.numberValue,
    'sizeValues': marker.sizeValues,
    'maxValueText': marker.maxValueText,
    'minValueText': marker.minValueText,
    'schmidtAngleDeg': marker.schmidtAngleDeg,
    'schmidtMinValue': marker.schmidtMinValue,
    'schmidtMaxValue': marker.schmidtMaxValue,
    'avgValueText': marker.avgValueText,
    'coverThicknessText': marker.coverThicknessText,
    'depthText': marker.depthText,
    'tiltDirection': marker.tiltDirection,
    'displacementText': marker.displacementText,
    'deflectionEndAText': marker.deflectionEndAText,
    'deflectionMidBText': marker.deflectionMidBText,
    'deflectionEndCText': marker.deflectionEndCText,
    'remark': marker.remark,
    'wComplete': marker.wComplete,
    'hComplete': marker.hComplete,
    'dComplete': marker.dComplete,
    'details': marker.details,
  };

  static EquipmentMarker fromJson(Map<String, dynamic> json) =>
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
        remarkLeft: json['remarkLeft'] as String?,
        remarkRight: json['remarkRight'] as String?,
        numberPrefix: json['numberPrefix'] as String?,
        numberValue: json['numberValue'] as String?,
        sizeValues:
            (json['sizeValues'] as List<dynamic>?)
                ?.map((value) => value.toString())
                .toList(),
        maxValueText: json['maxValueText'] as String?,
        minValueText: json['minValueText'] as String?,
        schmidtAngleDeg: (json['schmidtAngleDeg'] as num?)?.toInt(),
        schmidtMinValue: json['schmidtMinValue'] as String?,
        schmidtMaxValue: json['schmidtMaxValue'] as String?,
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
        details: json['details'] as String?,
      );
}
