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
    this.sizeValues,
  });

  final String id;
  final String label;
  final int pageIndex;
  final EquipmentCategory category;
  final double normalizedX;
  final double normalizedY;
  final String? equipmentTypeId;
  final String? memberType;
  final List<String>? sizeValues;

  EquipmentMarker copyWith({
    String? id,
    String? label,
    int? pageIndex,
    EquipmentCategory? category,
    double? normalizedX,
    double? normalizedY,
    String? equipmentTypeId,
    String? memberType,
    List<String>? sizeValues,
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
      sizeValues: sizeValues ?? this.sizeValues,
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
    'sizeValues': sizeValues,
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
        sizeValues: (json['sizeValues'] as List<dynamic>?)
            ?.map((value) => value.toString())
            .toList(),
      );
}
