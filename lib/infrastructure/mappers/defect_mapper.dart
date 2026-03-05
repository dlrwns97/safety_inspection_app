import 'package:safety_inspection_app/models/defect.dart';
import 'package:safety_inspection_app/models/defect_details.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';

class DefectMapper {
  const DefectMapper._();

  static Map<String, dynamic> toJson(Defect defect) => {
    'id': defect.id,
    'label': defect.label,
    'pageIndex': defect.pageIndex,
    'category': defect.category.name,
    'normalizedX': defect.normalizedX,
    'normalizedY': defect.normalizedY,
    'details': defect.details.toJson(),
  };

  static Defect fromJson(Map<String, dynamic> json) => Defect(
    id: json['id'] as String,
    label: json['label'] as String,
    pageIndex: json['pageIndex'] as int? ?? 0,
    category: DefectCategory.values.byName(
      json['category'] as String? ?? 'generalCrack',
    ),
    normalizedX: (json['normalizedX'] as num? ?? 0).toDouble(),
    normalizedY: (json['normalizedY'] as num? ?? 0).toDouble(),
    details: DefectDetails.fromJson(
      json['details'] as Map<String, dynamic>? ?? <String, dynamic>{},
    ),
  );
}
