import 'defect.dart';
import 'drawing_enums.dart';
import 'equipment_marker.dart';
import 'drawing/drawing_history_action_persisted.dart';
import 'drawing/drawing_stroke.dart';

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
    this.lastViewedPdfPage,
    this.isDeleted = false,
    this.deletedAt,
    List<Defect>? defects,
    List<EquipmentMarker>? equipmentMarkers,
    List<DrawingStroke>? drawingStrokes,
    List<DrawingHistoryActionPersisted>? drawingUndoHistory,
    List<DrawingHistoryActionPersisted>? drawingRedoHistory,
    List<String>? visibleDefectCategoryNames,
    List<String>? visibleEquipmentCategoryNames,
  }) : defects = defects ?? [],
       equipmentMarkers = equipmentMarkers ?? [],
       drawingStrokes = drawingStrokes ?? [],
       drawingUndoHistory = drawingUndoHistory ?? [],
       drawingRedoHistory = drawingRedoHistory ?? [],
       visibleDefectCategoryNames =
           visibleDefectCategoryNames ??
           DefectCategory.values.map((category) => category.name).toList(),
       visibleEquipmentCategoryNames =
           visibleEquipmentCategoryNames ??
           kEquipmentCategoryOrder.map((category) => category.name).toList();

  final String id;
  final String name;
  final DateTime createdAt;
  final DrawingType drawingType;
  final String? structureType;
  final String? inspectionType;
  final DateTime? inspectionDate;
  final String? pdfPath;
  final String? pdfName;
  final int? lastViewedPdfPage;
  final bool isDeleted;
  final DateTime? deletedAt;
  final List<Defect> defects;
  final List<EquipmentMarker> equipmentMarkers;
  final List<DrawingStroke> drawingStrokes;
  final List<DrawingHistoryActionPersisted> drawingUndoHistory;
  final List<DrawingHistoryActionPersisted> drawingRedoHistory;
  final List<String> visibleDefectCategoryNames;
  final List<String> visibleEquipmentCategoryNames;

  static const _deletedAtSentinel = Object();

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
    int? lastViewedPdfPage,
    bool? isDeleted,
    Object? deletedAt = _deletedAtSentinel,
    List<Defect>? defects,
    List<EquipmentMarker>? equipmentMarkers,
    List<DrawingStroke>? drawingStrokes,
    List<DrawingHistoryActionPersisted>? drawingUndoHistory,
    List<DrawingHistoryActionPersisted>? drawingRedoHistory,
    List<String>? visibleDefectCategoryNames,
    List<String>? visibleEquipmentCategoryNames,
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
      lastViewedPdfPage: lastViewedPdfPage ?? this.lastViewedPdfPage,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt == _deletedAtSentinel
          ? this.deletedAt
          : deletedAt as DateTime?,
      defects: defects ?? List<Defect>.from(this.defects),
      equipmentMarkers:
          equipmentMarkers ?? List<EquipmentMarker>.from(this.equipmentMarkers),
      drawingStrokes:
          drawingStrokes ?? List<DrawingStroke>.from(this.drawingStrokes),
      drawingUndoHistory:
          drawingUndoHistory ??
          List<DrawingHistoryActionPersisted>.from(this.drawingUndoHistory),
      drawingRedoHistory:
          drawingRedoHistory ??
          List<DrawingHistoryActionPersisted>.from(this.drawingRedoHistory),
      visibleDefectCategoryNames:
          visibleDefectCategoryNames ??
          List<String>.from(this.visibleDefectCategoryNames),
      visibleEquipmentCategoryNames:
          visibleEquipmentCategoryNames ??
          List<String>.from(this.visibleEquipmentCategoryNames),
    );
  }
}
