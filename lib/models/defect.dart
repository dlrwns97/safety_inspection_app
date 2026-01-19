import 'defect_details.dart';
import 'drawing_enums.dart';

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
