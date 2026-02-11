import 'dart:ui';

import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';

enum EraserMode { area, stroke }

class EraserSession {
  const EraserSession({
    required this.mode,
    required this.radius,
    required this.removedOriginalIds,
    required this.removedById,
    required this.addedById,
    required this.boundsByIdPagePx,
  });

  final EraserMode mode;
  final double radius;
  final Set<String> removedOriginalIds;
  final Map<String, DrawingStroke> removedById;
  final Map<String, DrawingStroke> addedById;
  final Map<String, Rect> boundsByIdPagePx;

  EraserSession copyWith({
    EraserMode? mode,
    double? radius,
    Set<String>? removedOriginalIds,
    Map<String, DrawingStroke>? removedById,
    Map<String, DrawingStroke>? addedById,
    Map<String, Rect>? boundsByIdPagePx,
  }) {
    return EraserSession(
      mode: mode ?? this.mode,
      radius: radius ?? this.radius,
      removedOriginalIds: removedOriginalIds ?? this.removedOriginalIds,
      removedById: removedById ?? this.removedById,
      addedById: addedById ?? this.addedById,
      boundsByIdPagePx: boundsByIdPagePx ?? this.boundsByIdPagePx,
    );
  }
}

class EraserResult {
  const EraserResult({required this.removed, required this.added});

  final List<DrawingStroke> removed;
  final List<DrawingStroke> added;

  bool get hasChanges => removed.isNotEmpty || added.isNotEmpty;
}

class EraserEngine {
  EraserSession startSession({required EraserMode mode, required double radius}) {
    return EraserSession(
      mode: mode,
      radius: radius,
      removedOriginalIds: <String>{},
      removedById: <String, DrawingStroke>{},
      addedById: <String, DrawingStroke>{},
      boundsByIdPagePx: <String, Rect>{},
    );
  }

  EraserSession updateSession(
    EraserSession session, {
    required Offset center,
    required Size pageSize,
    required List<DrawingStroke> strokes,
  }) {
    if (session.mode != EraserMode.area) {
      return session;
    }

    final removedById = Map<String, DrawingStroke>.from(session.removedById);
    final addedById = Map<String, DrawingStroke>.from(session.addedById);
    final removedOriginalIds = Set<String>.from(session.removedOriginalIds);
    final boundsByIdPagePx = Map<String, Rect>.from(session.boundsByIdPagePx);
    final eraserBounds = Rect.fromCircle(center: center, radius: session.radius);
    final virtualStrokes = <DrawingStroke>[
      ...strokes.where((stroke) => !removedOriginalIds.contains(stroke.id)),
      ...addedById.values,
    ];

    for (final stroke in List<DrawingStroke>.from(virtualStrokes)) {
      final strokeBounds = boundsByIdPagePx[stroke.id] ??
          (boundsByIdPagePx[stroke.id] = computeStrokeBoundsPagePx(stroke, pageSize));
      if (!strokeBounds.overlaps(eraserBounds)) {
        continue;
      }

      final splitStrokes = _splitStrokeByEraserCircle(
        stroke: stroke,
        center: center,
        pageSize: pageSize,
        radiusPagePx: session.radius,
      );
      if (splitStrokes.length == 1 &&
          splitStrokes.first.pointsNorm.length == stroke.pointsNorm.length) {
        continue;
      }

      if (addedById.containsKey(stroke.id)) {
        addedById.remove(stroke.id);
      } else {
        removedById.putIfAbsent(stroke.id, () => stroke);
        removedOriginalIds.add(stroke.id);
      }
      boundsByIdPagePx.remove(stroke.id);
      for (final split in splitStrokes) {
        addedById[split.id] = split;
        boundsByIdPagePx[split.id] = computeStrokeBoundsPagePx(split, pageSize);
      }
    }

    return session.copyWith(
      removedOriginalIds: removedOriginalIds,
      removedById: removedById,
      addedById: addedById,
      boundsByIdPagePx: boundsByIdPagePx,
    );
  }

  Rect computeStrokeBoundsPagePx(DrawingStroke stroke, Size pageSize) {
    final points = stroke.pointsNorm;
    if (points.isEmpty) {
      return Rect.zero;
    }

    var minX = points.first.dx * pageSize.width;
    var minY = points.first.dy * pageSize.height;
    var maxX = minX;
    var maxY = minY;
    for (var i = 1; i < points.length; i++) {
      final point = points[i];
      final x = point.dx * pageSize.width;
      final y = point.dy * pageSize.height;
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  EraserResult commit(EraserSession session) {
    return EraserResult(
      removed: session.removedById.values.toList(growable: false),
      added: session.addedById.values.toList(growable: false),
    );
  }

  List<DrawingStroke> _splitStrokeByEraserCircle({
    required DrawingStroke stroke,
    required Offset center,
    required Size pageSize,
    required double radiusPagePx,
  }) {
    final radiusSq = radiusPagePx * radiusPagePx;
    final points = stroke.pointsNorm;
    if (points.length < 2) {
      return <DrawingStroke>[stroke];
    }

    final outsideSegments = <List<Offset>>[];
    List<Offset>? currentSegment;

    for (final pointNorm in points) {
      final point = Offset(pointNorm.dx * pageSize.width, pointNorm.dy * pageSize.height);
      final delta = point - center;
      final isInside = (delta.dx * delta.dx) + (delta.dy * delta.dy) <= radiusSq;
      if (!isInside) {
        currentSegment ??= <Offset>[];
        currentSegment.add(pointNorm);
      } else if (currentSegment != null && currentSegment.isNotEmpty) {
        outsideSegments.add(currentSegment);
        currentSegment = null;
      }
    }
    if (currentSegment != null && currentSegment.isNotEmpty) {
      outsideSegments.add(currentSegment);
    }

    final splitStrokes = <DrawingStroke>[];
    for (final segment in outsideSegments) {
      if (segment.length < 2) {
        continue;
      }
      splitStrokes.add(
        DrawingStroke(
          id: DrawingStroke.generateId(),
          pageNumber: stroke.pageNumber,
          style: stroke.style,
          pointsNorm: List<Offset>.from(segment),
        ),
      );
    }
    return splitStrokes;
  }
}
