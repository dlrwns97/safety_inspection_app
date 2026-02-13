import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';

enum EraserMode { area, stroke }

class EraserSession {
  const EraserSession({
    required this.mode,
    required this.radius,
    required this.removedOriginalIds,
    required this.processedStrokeIds,
    required this.removedById,
    required this.addedById,
  });

  final EraserMode mode;
  final double radius;
  final Set<String> removedOriginalIds;
  final Set<String> processedStrokeIds;
  final Map<String, DrawingStroke> removedById;
  final Map<String, DrawingStroke> addedById;

  EraserSession copyWith({
    EraserMode? mode,
    double? radius,
    Set<String>? removedOriginalIds,
    Set<String>? processedStrokeIds,
    Map<String, DrawingStroke>? removedById,
    Map<String, DrawingStroke>? addedById,
  }) {
    return EraserSession(
      mode: mode ?? this.mode,
      radius: radius ?? this.radius,
      removedOriginalIds: removedOriginalIds ?? this.removedOriginalIds,
      processedStrokeIds: processedStrokeIds ?? this.processedStrokeIds,
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
  static const int _kVirtualStrokeThreshold = 1700;
  static const int _kPointThreshold = 220000;
  static const int _kFallbackCandidateThreshold = 24;
  static const int _kMaxUpdateMicrosThreshold = 24000;
  static const int _kFallbackDeleteCapPerFrame = 12;

  DateTime? _perfWindowStart;
  int _perfCallsInWindow = 0;
  int _perfTotalMicrosInWindow = 0;
  int _perfMaxMicrosInWindow = 0;
  int _perfUiMutationsInWindow = 0;
  bool _isGuardTriggeredForSession = false;
  int _guardSkipsInSession = 0;
  DateTime? _lastFallbackLogAt;

  EraserSession startSession({required EraserMode mode, required double radius}) {
    _isGuardTriggeredForSession = false;
    _guardSkipsInSession = 0;
    _lastFallbackLogAt = null;
    return EraserSession(
      mode: mode,
      radius: radius,
      removedOriginalIds: <String>{},
      processedStrokeIds: <String>{},
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
    final int startedMicros = DateTime.now().microsecondsSinceEpoch;
    final removedById = Map<String, DrawingStroke>.from(session.removedById);
    final addedById = Map<String, DrawingStroke>.from(session.addedById);
    final removedOriginalIds = Set<String>.from(session.removedOriginalIds);
    final processedStrokeIds = Set<String>.from(session.processedStrokeIds);
    final virtualStrokes = <DrawingStroke>[
      ...strokes.where((stroke) => !removedOriginalIds.contains(stroke.id)),
      ...addedById.values,
    ];

    int virtualStrokeCount = virtualStrokes.length;
    int totalPointCount = _countPoints(virtualStrokes);
    final candidates = _collectIntersectingCandidates(
      center: center,
      pageSize: pageSize,
      virtualStrokes: virtualStrokes,
      radiusPagePx: session.radius,
    );

    if (session.mode == EraserMode.stroke) {
      final deleted = _applyFallbackDeleteWholeStroke(
        candidates: candidates,
        removedById: removedById,
        addedById: addedById,
        removedOriginalIds: removedOriginalIds,
        processedStrokeIds: processedStrokeIds,
        maxDeleteCount: _kFallbackDeleteCapPerFrame,
      );
      _logPerfGuard(
        mode: 'F3',
        eraserMode: session.mode,
        reason: 'stroke-path',
        strokeCount: virtualStrokeCount,
        pointCount: totalPointCount,
        candidateCount: candidates.length,
        deletedCount: deleted,
      );
      return session.copyWith(
        removedOriginalIds: removedOriginalIds,
        processedStrokeIds: processedStrokeIds,
        removedById: removedById,
        addedById: addedById,
      );
    }

    if (_isGuardTriggeredForSession ||
        _isOverComplexityThreshold(
          virtualStrokeCount: virtualStrokeCount,
          pointCount: totalPointCount,
          maxUpdateMicros: _perfMaxMicrosInWindow,
          candidateCount: candidates.length,
        )) {
      _isGuardTriggeredForSession = true;
      _guardSkipsInSession += 1;
      final guardMode = _guardSkipsInSession >= 2 ? 'F2' : 'F1';
      _logPerfGuard(
        mode: guardMode,
        eraserMode: session.mode,
        reason: _fallbackReason(
          virtualStrokeCount: virtualStrokeCount,
          pointCount: totalPointCount,
          candidateCount: candidates.length,
          maxUpdateMicros: _perfMaxMicrosInWindow,
        ),
        virtualStrokeCount: virtualStrokeCount,
        strokeCount: virtualStrokeCount,
        pointCount: totalPointCount,
        candidateCount: candidates.length,
        deletedCount: 0,
      );
      final elapsedMicros = DateTime.now().microsecondsSinceEpoch - startedMicros;
      _recordPerf(
        elapsedMicros: elapsedMicros,
        strokeCount: virtualStrokeCount,
        virtualStrokeCount: virtualStrokeCount,
        pointCount: totalPointCount,
        addedByIdCount: addedById.length,
      );
      return session.copyWith(
        removedOriginalIds: removedOriginalIds,
        processedStrokeIds: processedStrokeIds,
        removedById: removedById,
        addedById: addedById,
      );
    }

    for (final stroke in List<DrawingStroke>.from(virtualStrokes)) {
      final isOriginalStroke = !addedById.containsKey(stroke.id);
      if (isOriginalStroke && processedStrokeIds.contains(stroke.id)) {
        // Avoid re-splitting the same original stroke within one eraser session.
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
        processedStrokeIds.add(stroke.id);
      }
      virtualStrokeCount += splitStrokes.length - 1;
      totalPointCount -= stroke.pointsNorm.length;
      for (final split in splitStrokes) {
        addedById[split.id] = split;
        totalPointCount += split.pointsNorm.length;
      }

      if (_isOverComplexityThreshold(
        virtualStrokeCount: virtualStrokeCount,
        pointCount: totalPointCount,
        maxUpdateMicros: _perfMaxMicrosInWindow,
        candidateCount: candidates.length,
      )) {
        _isGuardTriggeredForSession = true;
        final deleted = _applyFallbackDeleteWholeStroke(
          candidates: candidates,
          removedById: removedById,
          addedById: addedById,
          removedOriginalIds: removedOriginalIds,
          processedStrokeIds: processedStrokeIds,
          maxDeleteCount: _kFallbackDeleteCapPerFrame,
        );
        _logPerfGuard(
          mode: 'F3',
          eraserMode: session.mode,
          reason: _fallbackReason(
            virtualStrokeCount: virtualStrokeCount,
            pointCount: totalPointCount,
            candidateCount: candidates.length,
            maxUpdateMicros: _perfMaxMicrosInWindow,
          ),
          strokeCount: virtualStrokeCount,
          pointCount: totalPointCount,
          candidateCount: candidates.length,
          deletedCount: deleted,
        );
        break;
      }
    }

    final elapsedMicros = DateTime.now().microsecondsSinceEpoch - startedMicros;
    if (elapsedMicros > _kMaxUpdateMicrosThreshold) {
      _isGuardTriggeredForSession = true;
      final deleted = _applyFallbackDeleteWholeStroke(
        candidates: candidates,
        removedById: removedById,
        addedById: addedById,
        removedOriginalIds: removedOriginalIds,
        processedStrokeIds: processedStrokeIds,
        maxDeleteCount: _kFallbackDeleteCapPerFrame,
      );
      _logPerfGuard(
        mode: 'F3',
        eraserMode: session.mode,
        reason: 'elapsed>${(_kMaxUpdateMicrosThreshold / 1000).toStringAsFixed(0)}ms',
        strokeCount: virtualStrokeCount,
        pointCount: totalPointCount,
        candidateCount: candidates.length,
        deletedCount: deleted,
      );
    }

    _recordPerf(
      elapsedMicros: elapsedMicros,
      strokeCount: virtualStrokeCount,
      virtualStrokeCount: virtualStrokeCount,
      pointCount: totalPointCount,
      addedByIdCount: addedById.length,
    );

    return session.copyWith(
      removedOriginalIds: removedOriginalIds,
      processedStrokeIds: processedStrokeIds,
      removedById: removedById,
      addedById: addedById,
    );
  }

  int _applyFallbackDeleteWholeStroke({
    required List<DrawingStroke> candidates,
    required Map<String, DrawingStroke> removedById,
    required Map<String, DrawingStroke> addedById,
    required Set<String> removedOriginalIds,
    required Set<String> processedStrokeIds,
    required int maxDeleteCount,
  }) {
    var deletedCount = 0;
    for (final stroke in candidates) {
      if (deletedCount >= maxDeleteCount) {
        break;
      }
      if (addedById.containsKey(stroke.id)) {
        addedById.remove(stroke.id);
        deletedCount += 1;
        continue;
      }
      removedById.putIfAbsent(stroke.id, () => stroke);
      removedOriginalIds.add(stroke.id);
      processedStrokeIds.add(stroke.id);
      deletedCount += 1;
    }
    return deletedCount;
  }

  List<DrawingStroke> _collectIntersectingCandidates({
    required Offset center,
    required Size pageSize,
    required List<DrawingStroke> virtualStrokes,
    required double radiusPagePx,
  }) {
    final candidates = <DrawingStroke>[];
    for (final stroke in virtualStrokes) {
      if (!_isStrokeWithinInflatedBounds(
        stroke: stroke,
        center: center,
        pageSize: pageSize,
        radiusPagePx: radiusPagePx,
      )) {
        continue;
      }
      if (_doesStrokeIntersectEraserCircle(
        stroke: stroke,
        center: center,
        pageSize: pageSize,
        radiusPagePx: radiusPagePx,
      )) {
        candidates.add(stroke);
      }
    }
    return candidates;
  }

  bool _isStrokeWithinInflatedBounds({
    required DrawingStroke stroke,
    required Offset center,
    required Size pageSize,
    required double radiusPagePx,
  }) {
    final inflated = radiusPagePx + stroke.style.widthPx;
    final eraserRect = Rect.fromCircle(center: center, radius: inflated);
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;
    for (final p in stroke.pointsNorm) {
      final x = p.dx * pageSize.width;
      final y = p.dy * pageSize.height;
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
    }
    if (minX == double.infinity) {
      return false;
    }
    final strokeRect = Rect.fromLTRB(minX, minY, maxX, maxY).inflate(stroke.style.widthPx);
    return strokeRect.overlaps(eraserRect);
  }

  bool _doesStrokeIntersectEraserCircle({
    required DrawingStroke stroke,
    required Offset center,
    required Size pageSize,
    required double radiusPagePx,
  }) {
    final effectiveRadius = radiusPagePx + (stroke.style.widthPx / 2);
    final radiusSq = effectiveRadius * effectiveRadius;
    for (final pointNorm in stroke.pointsNorm) {
      final point = Offset(pointNorm.dx * pageSize.width, pointNorm.dy * pageSize.height);
      final delta = point - center;
      final distanceSq = (delta.dx * delta.dx) + (delta.dy * delta.dy);
      if (distanceSq <= radiusSq) {
        return true;
      }
    }
    return false;
  }

  void _logPerfGuard({
    required String mode,
    required EraserMode eraserMode,
    required String reason,
    required int strokeCount,
    required int pointCount,
    required int candidateCount,
    required int deletedCount,
    int? virtualStrokeCount,
  }) {
    if (kReleaseMode) {
      return;
    }
    final now = DateTime.now();
    final last = _lastFallbackLogAt;
    if (last != null && now.difference(last) < const Duration(seconds: 1)) {
      return;
    }
    _lastFallbackLogAt = now;
    debugPrint(
      '[PerfGuard] mode=$mode eraser=${eraserMode.name} reason=$reason '
      'strokes=$strokeCount points=$pointCount candidates=$candidateCount '
      'deleted=$deletedCount${virtualStrokeCount == null ? '' : ' virtual=$virtualStrokeCount'}',
    );
  }

  EraserResult commit(EraserSession session) {
    return EraserResult(
      removed: session.removedById.values.toList(growable: false),
      added: session.addedById.values.toList(growable: false),
    );
  }

  void recordUiMutation() {
    if (kReleaseMode) {
      return;
    }
    _perfUiMutationsInWindow += 1;
  }

  bool _isOverComplexityThreshold({
    required int virtualStrokeCount,
    required int pointCount,
    required int maxUpdateMicros,
    required int candidateCount,
  }) {
    final isHeavyGeometry =
        virtualStrokeCount > _kVirtualStrokeThreshold || pointCount > _kPointThreshold;
    final hasCandidatePressure = candidateCount > _kFallbackCandidateThreshold;
    return maxUpdateMicros > _kMaxUpdateMicrosThreshold ||
        (isHeavyGeometry && hasCandidatePressure);
  }

  String _fallbackReason({
    required int virtualStrokeCount,
    required int pointCount,
    required int candidateCount,
    required int maxUpdateMicros,
  }) {
    if (maxUpdateMicros > _kMaxUpdateMicrosThreshold) {
      return 'maxMs>${(_kMaxUpdateMicrosThreshold / 1000).toStringAsFixed(0)}';
    }
    if (virtualStrokeCount > _kVirtualStrokeThreshold &&
        candidateCount > _kFallbackCandidateThreshold) {
      return 'virtual+candidates';
    }
    if (pointCount > _kPointThreshold && candidateCount > _kFallbackCandidateThreshold) {
      return 'points+candidates';
    }
    return 'guarded';
  }

  int _countPoints(List<DrawingStroke> strokes) {
    int total = 0;
    for (final stroke in strokes) {
      total += stroke.pointsNorm.length;
    }
    return total;
  }

  void _recordPerf({
    required int elapsedMicros,
    required int strokeCount,
    required int virtualStrokeCount,
    required int pointCount,
    required int addedByIdCount,
  }) {
    if (kReleaseMode) {
      return;
    }

    final now = DateTime.now();
    final windowStart = _perfWindowStart;
    if (windowStart == null || now.difference(windowStart) >= const Duration(seconds: 1)) {
      if (windowStart != null && _perfCallsInWindow > 0) {
        final avgMicros = _perfTotalMicrosInWindow / _perfCallsInWindow;
        debugPrint(
          '[Perf] eraser: calls/s=$_perfCallsInWindow '
          'avgMs=${(avgMicros / 1000).toStringAsFixed(1)} '
          'maxMs=${(_perfMaxMicrosInWindow / 1000).toStringAsFixed(1)} '
          'strokes=$strokeCount virtual=$virtualStrokeCount points=$pointCount '
          'addedById=$addedByIdCount uiMutations/s=$_perfUiMutationsInWindow',
        );
      }
      _perfWindowStart = now;
      _perfCallsInWindow = 0;
      _perfTotalMicrosInWindow = 0;
      _perfMaxMicrosInWindow = 0;
      _perfUiMutationsInWindow = 0;
    }

    _perfCallsInWindow += 1;
    _perfTotalMicrosInWindow += elapsedMicros;
    if (elapsedMicros > _perfMaxMicrosInWindow) {
      _perfMaxMicrosInWindow = elapsedMicros;
    }
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
