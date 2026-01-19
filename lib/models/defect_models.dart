import 'package:safety_inspection_app/models/drawing_enums.dart';

class Defect {
  Defect({
    required this.id,
    required this.label,
    required this.pageIndex,
    required this.category,
    required this.normalizedX,
    required this.normalizedY,
    required this.details,
  });

  final String id;
  final String label;
  final int pageIndex;
  final DefectCategory category;
  final double normalizedX;
  final double normalizedY;
  final DefectDetails details;

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'pageIndex': pageIndex,
    'category': category.name,
    'normalizedX': normalizedX,
    'normalizedY': normalizedY,
    'details': details.toJson(),
  };

  factory Defect.fromJson(Map<String, dynamic> json) => Defect(
    id: json['id'] as String,
    label: json['label'] as String,
    pageIndex: json['pageIndex'] as int? ?? 0,
    category: DefectCategory.values.byName(
      json['category'] as String? ?? 'generalCrack',
    ),
    normalizedX: (json['normalizedX'] as num? ?? 0).toDouble(),
    normalizedY: (json['normalizedY'] as num? ?? 0).toDouble(),
    details: DefectDetails.fromJson(
      json['details'] as Map<String, dynamic>? ?? {},
    ),
  );
}

class DefectDetails {
  DefectDetails({
    required this.structuralMember,
    required this.crackType,
    required this.widthMm,
    required this.lengthMm,
    required this.cause,
  });

  final String structuralMember;
  final String crackType;
  final double widthMm;
  final double lengthMm;
  final String cause;

  Map<String, dynamic> toJson() => {
    'structuralMember': structuralMember,
    'crackType': crackType,
    'widthMm': widthMm,
    'lengthMm': lengthMm,
    'cause': cause,
  };

  factory DefectDetails.fromJson(Map<String, dynamic> json) => DefectDetails(
    structuralMember: json['structuralMember'] as String? ?? '',
    crackType: json['crackType'] as String? ?? '',
    widthMm: (json['widthMm'] as num? ?? 0).toDouble(),
    lengthMm: (json['lengthMm'] as num? ?? 0).toDouble(),
    cause: json['cause'] as String? ?? '',
  );
}
