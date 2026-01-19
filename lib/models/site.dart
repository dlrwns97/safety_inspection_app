import 'defect.dart';
import 'drawing_enums.dart';

class Site {
  Site({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.drawingType,
    this.pdfPath,
    this.pdfName,
    List<Defect>? defects,
  }) : defects = defects ?? [];

  final String id;
  final String name;
  final DateTime createdAt;
  final DrawingType drawingType;
  final String? pdfPath;
  final String? pdfName;
  final List<Defect> defects;

  Site copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DrawingType? drawingType,
    String? pdfPath,
    String? pdfName,
    List<Defect>? defects,
  }) {
    return Site(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      drawingType: drawingType ?? this.drawingType,
      pdfPath: pdfPath ?? this.pdfPath,
      pdfName: pdfName ?? this.pdfName,
      defects: defects ?? List<Defect>.from(this.defects),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'drawingType': drawingType.name,
    'pdfPath': pdfPath,
    'pdfName': pdfName,
    'defects': defects.map((defect) => defect.toJson()).toList(),
  };

  factory Site.fromJson(Map<String, dynamic> json) => Site(
    id: json['id'] as String,
    name: json['name'] as String,
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    drawingType: DrawingType.values.byName(
      json['drawingType'] as String? ?? 'blank',
    ),
    pdfPath: json['pdfPath'] as String?,
    pdfName: json['pdfName'] as String?,
    defects: (json['defects'] as List<dynamic>? ?? [])
        .map((item) => Defect.fromJson(item as Map<String, dynamic>))
        .toList(),
  );
}
