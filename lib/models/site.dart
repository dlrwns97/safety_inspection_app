import 'defect.dart';
import 'drawing_enums.dart';
import 'equipment_marker.dart';

class Site {
  Site({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.drawingType,
    this.structureType,
    this.inspectionType,
    this.inspectionDate,
    this.pdfPath,
    this.pdfName,
    List<Defect>? defects,
    List<EquipmentMarker>? equipmentMarkers,
  })  : defects = defects ?? [],
        equipmentMarkers = equipmentMarkers ?? [];

  final String id;
  final String name;
  final DateTime createdAt;
  final DrawingType drawingType;
  final String? structureType;
  final String? inspectionType;
  final DateTime? inspectionDate;
  final String? pdfPath;
  final String? pdfName;
  final List<Defect> defects;
  final List<EquipmentMarker> equipmentMarkers;

  Site copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DrawingType? drawingType,
    String? structureType,
    String? inspectionType,
    DateTime? inspectionDate,
    String? pdfPath,
    String? pdfName,
    List<Defect>? defects,
    List<EquipmentMarker>? equipmentMarkers,
  }) {
    return Site(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      drawingType: drawingType ?? this.drawingType,
      structureType: structureType ?? this.structureType,
      inspectionType: inspectionType ?? this.inspectionType,
      inspectionDate: inspectionDate ?? this.inspectionDate,
      pdfPath: pdfPath ?? this.pdfPath,
      pdfName: pdfName ?? this.pdfName,
      defects: defects ?? List<Defect>.from(this.defects),
      equipmentMarkers:
          equipmentMarkers ?? List<EquipmentMarker>.from(this.equipmentMarkers),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'drawingType': drawingType.name,
    'structureType': structureType,
    'inspectionType': inspectionType,
    'inspectionDate': inspectionDate?.toIso8601String(),
    'pdfPath': pdfPath,
    'pdfName': pdfName,
    'defects': defects.map((defect) => defect.toJson()).toList(),
    'equipmentMarkers':
        equipmentMarkers.map((marker) => marker.toJson()).toList(),
  };

  factory Site.fromJson(Map<String, dynamic> json) {
    final inspectionDateValue = json['inspectionDate'];
    DateTime? inspectionDate;
    if (inspectionDateValue is String) {
      inspectionDate = DateTime.tryParse(inspectionDateValue);
    } else if (inspectionDateValue is int) {
      inspectionDate = DateTime.fromMillisecondsSinceEpoch(inspectionDateValue);
    }
    return Site(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      drawingType: DrawingType.values.byName(
        json['drawingType'] as String? ?? 'blank',
      ),
      structureType: json['structureType'] as String?,
      inspectionType: json['inspectionType'] as String?,
      inspectionDate: inspectionDate,
      pdfPath: json['pdfPath'] as String?,
      pdfName: json['pdfName'] as String?,
      defects: (json['defects'] as List<dynamic>? ?? [])
          .map((item) => Defect.fromJson(item as Map<String, dynamic>))
          .toList(),
      equipmentMarkers: (json['equipmentMarkers'] as List<dynamic>? ?? [])
          .map((item) => EquipmentMarker.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
