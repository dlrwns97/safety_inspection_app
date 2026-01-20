import 'drawing_enums.dart';

class EquipmentMarker {
  EquipmentMarker({
    required this.id,
    required this.label,
    required this.pageIndex,
    required this.category,
    required this.normalizedX,
    required this.normalizedY,
  });

  final String id;
  final String label;
  final int pageIndex;
  final EquipmentCategory category;
  final double normalizedX;
  final double normalizedY;

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'pageIndex': pageIndex,
    'category': category.name,
    'normalizedX': normalizedX,
    'normalizedY': normalizedY,
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
      );
}
