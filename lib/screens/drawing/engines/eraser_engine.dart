import 'dart:ui';

import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';

enum EraserMode { area, stroke }

class EraserSession {
  const EraserSession({
    required this.mode,
    required this.radius,
    required this.removedById,
    required this.addedById,
  });

  final EraserMode mode;
  final double radius;
  final Map<String, DrawingStroke> removedById;
  final Map<String, DrawingStroke> addedById;

  EraserSession copyWith({
    EraserMode? mode,
    double? radius,
    Map<String, DrawingStroke>? removedById,
    Map<String, DrawingStroke>? addedById,
  }) {
    return EraserSession(
      mode: mode ?? this.mode,
      radius: radius ?? this.radius,
      removedById: removedById ?? this.removedById,
      addedById: addedById ?? this.addedById,
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
      removedById: <String, DrawingStroke>{},
      addedById: <String, DrawingStroke>{},
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

    for (final stroke in strokes) {
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

      final wasAddedThisSession = addedById.remove(stroke.id) != null;
      if (!wasAddedThisSession) {
        removedById.putIfAbsent(stroke.id, () => stroke);
      }
      for (final split in splitStrokes) {
        addedById[split.id] = split;
      }
    }

    return session.copyWith(removedById: removedById, addedById: addedById);
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
      return const <DrawingStroke>[];
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
