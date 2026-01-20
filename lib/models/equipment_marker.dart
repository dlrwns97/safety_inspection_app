class EquipmentMarker {
  EquipmentMarker({
    required this.id,
    required this.label,
    required this.pageIndex,
    required this.normalizedX,
    required this.normalizedY,
  });

  final String id;
  final String label;
  final int pageIndex;
  final double normalizedX;
  final double normalizedY;

  EquipmentMarker copyWith({
    String? id,
    String? label,
    int? pageIndex,
    double? normalizedX,
    double? normalizedY,
  }) {
    return EquipmentMarker(
      id: id ?? this.id,
      label: label ?? this.label,
      pageIndex: pageIndex ?? this.pageIndex,
      normalizedX: normalizedX ?? this.normalizedX,
      normalizedY: normalizedY ?? this.normalizedY,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'pageIndex': pageIndex,
    'normalizedX': normalizedX,
    'normalizedY': normalizedY,
  };

  factory EquipmentMarker.fromJson(Map<String, dynamic> json) =>
      EquipmentMarker(
        id: json['id'] as String,
        label: json['label'] as String,
        pageIndex: json['pageIndex'] as int? ?? 1,
        normalizedX: (json['normalizedX'] as num?)?.toDouble() ?? 0,
        normalizedY: (json['normalizedY'] as num?)?.toDouble() ?? 0,
      );
}
