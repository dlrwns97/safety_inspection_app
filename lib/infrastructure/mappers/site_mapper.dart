import 'package:safety_inspection_app/infrastructure/mappers/defect_mapper.dart';
import 'package:safety_inspection_app/infrastructure/mappers/drawing_stroke_mapper.dart';
import 'package:safety_inspection_app/infrastructure/mappers/equipment_marker_mapper.dart';
import 'package:safety_inspection_app/models/drawing/drawing_history_action_persisted.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/site.dart';

class SiteMapper {
  const SiteMapper._();

  static Map<String, dynamic> toJson(Site site) => {
    'id': site.id,
    'name': site.name,
    'createdAt': site.createdAt.toIso8601String(),
    'drawingType': site.drawingType.name,
    'structureType': site.structureType,
    'inspectionType': site.inspectionType,
    'inspectionDate': site.inspectionDate?.toIso8601String(),
    'pdfPath': site.pdfPath,
    'pdfName': site.pdfName,
    'isDeleted': site.isDeleted,
    'deletedAt': site.deletedAt?.toIso8601String(),
    'defects': site.defects.map(DefectMapper.toJson).toList(),
    'equipmentMarkers':
        site.equipmentMarkers.map(EquipmentMarkerMapper.toJson).toList(),
    'drawingStrokes':
        site.drawingStrokes.map(DrawingStrokeMapper.toJson).toList(),
    'drawingUndoHistory':
        site.drawingUndoHistory.map((action) => action.toJson()).toList(),
    'drawingRedoHistory':
        site.drawingRedoHistory.map((action) => action.toJson()).toList(),
    'visibleDefectCategoryNames': site.visibleDefectCategoryNames,
    'visibleEquipmentCategoryNames': site.visibleEquipmentCategoryNames,
  };

  static Site fromJson(Map<String, dynamic> json) {
    final inspectionDate = _parseDate(json['inspectionDate']);
    final deletedAt = _parseDate(json['deletedAt']);
    final visibleDefectCategoryNames =
        (json['visibleDefectCategoryNames'] as List<dynamic>?)
            ?.whereType<String>()
            .toList();
    final visibleEquipmentCategoryNames =
        json.containsKey('visibleEquipmentCategoryNames')
            ? (json['visibleEquipmentCategoryNames'] as List<dynamic>?)
                ?.whereType<String>()
                .toList()
            : null;

    final drawingStrokesJson = json['drawingStrokes'] as List? ?? const [];
    final drawingStrokes = drawingStrokesJson
        .whereType<Map>()
        .map(
          (item) => DrawingStrokeMapper.fromJson(
            item.cast<String, dynamic>(),
          ),
        )
        .toList();
    final List<dynamic> drawingUndoHistoryJson =
        json['drawingUndoHistory'] as List? ?? const [];
    final drawingUndoHistory = drawingUndoHistoryJson
        .whereType<Map>()
        .map(
          (item) => DrawingHistoryActionPersisted.fromJson(
            item.cast<String, dynamic>(),
          ),
        )
        .where((action) => action.strokeId.isNotEmpty)
        .toList();
    final List<dynamic> drawingRedoHistoryJson =
        json['drawingRedoHistory'] as List? ?? const [];
    final drawingRedoHistory = drawingRedoHistoryJson
        .whereType<Map>()
        .map(
          (item) => DrawingHistoryActionPersisted.fromJson(
            item.cast<String, dynamic>(),
          ),
        )
        .where((action) => action.strokeId.isNotEmpty)
        .toList();

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
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedAt: deletedAt,
      defects:
          (json['defects'] as List<dynamic>? ?? [])
              .whereType<Map>()
              .map((item) => DefectMapper.fromJson(item.cast<String, dynamic>()))
              .toList(),
      equipmentMarkers:
          (json['equipmentMarkers'] as List<dynamic>? ?? [])
              .whereType<Map>()
              .map(
                (item) =>
                    EquipmentMarkerMapper.fromJson(item.cast<String, dynamic>()),
              )
              .toList(),
      drawingStrokes: drawingStrokes,
      drawingUndoHistory: drawingUndoHistory,
      drawingRedoHistory: drawingRedoHistory,
      visibleDefectCategoryNames:
          visibleDefectCategoryNames ??
          DefectCategory.values.map((category) => category.name).toList(),
      visibleEquipmentCategoryNames:
          visibleEquipmentCategoryNames ??
          kEquipmentCategoryOrder.map((category) => category.name).toList(),
    );
  }

  static DateTime? _parseDate(dynamic rawValue) {
    if (rawValue is String) {
      return DateTime.tryParse(rawValue);
    }
    if (rawValue is int) {
      return DateTime.fromMillisecondsSinceEpoch(rawValue);
    }
    return null;
  }
}
