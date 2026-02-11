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
  static const int _kVirtualStrokeThreshold = 1500;
  static const int _kStrokeThreshold = 800;
  static const int _kPointThreshold = 200000;
  static const int _kMaxUpdateMicrosThreshold = 20000;

  DateTime? _perfWindowStart;
  int _perfCallsInWindow = 0;
  int _perfTotalMicrosInWindow = 0;
  int _perfMaxMicrosInWindow = 0;
  int _perfUiMutationsInWindow = 0;
  bool _isGuardTriggeredForSession = false;
  bool _isGuardLogPrintedForSession = false;

  EraserSession startSession({required EraserMode mode, required double radius}) {
    _isGuardTriggeredForSession = false;
    _isGuardLogPrintedForSession = false;
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
    if (session.mode != EraserMode.area) {
      return session;
    }

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

    if (_isGuardTriggeredForSession ||
        _isOverComplexityThreshold(
          virtualStrokeCount: virtualStrokeCount,
          strokeCount: virtualStrokeCount,
          pointCount: totalPointCount,
          maxUpdateMicros: _perfMaxMicrosInWindow,
        )) {
      _isGuardTriggeredForSession = true;
      _logGuardOnce(
        virtualStrokeCount: virtualStrokeCount,
        strokeCount: virtualStrokeCount,
        pointCount: totalPointCount,
        maxUpdateMicros: _perfMaxMicrosInWindow,
      );
      _recordPerf(
        elapsedMicros: DateTime.now().microsecondsSinceEpoch - startedMicros,
        strokeCount: virtualStrokeCount,
        virtualStrokeCount: virtualStrokeCount,
        pointCount: totalPointCount,
        addedByIdCount: addedById.length,
      );
      return session;
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
        strokeCount: virtualStrokeCount,
        pointCount: totalPointCount,
        maxUpdateMicros: _perfMaxMicrosInWindow,
      )) {
        _isGuardTriggeredForSession = true;
        _logGuardOnce(
          virtualStrokeCount: virtualStrokeCount,
          strokeCount: virtualStrokeCount,
          pointCount: totalPointCount,
          maxUpdateMicros: _perfMaxMicrosInWindow,
        );
        break;
      }
    }

    final elapsedMicros = DateTime.now().microsecondsSinceEpoch - startedMicros;
    if (elapsedMicros > _kMaxUpdateMicrosThreshold) {
      _isGuardTriggeredForSession = true;
      _logGuardOnce(
        virtualStrokeCount: virtualStrokeCount,
        strokeCount: virtualStrokeCount,
        pointCount: totalPointCount,
        maxUpdateMicros: elapsedMicros,
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
    required int strokeCount,
    required int pointCount,
    required int maxUpdateMicros,
  }) {
    return virtualStrokeCount > _kVirtualStrokeThreshold ||
        strokeCount > _kStrokeThreshold ||
        pointCount > _kPointThreshold ||
        maxUpdateMicros > _kMaxUpdateMicrosThreshold;
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

  void _logGuardOnce({
    required int virtualStrokeCount,
    required int strokeCount,
    required int pointCount,
    required int maxUpdateMicros,
  }) {
    if (kReleaseMode || _isGuardLogPrintedForSession) {
      return;
    }
    _isGuardLogPrintedForSession = true;
    debugPrint(
      '[PerfGuard] triggered: '
      'points=$pointCount virtual=$virtualStrokeCount strokes=$strokeCount '
      'maxMs=${(maxUpdateMicros / 1000).toStringAsFixed(1)} '
      '-> skipping split this frame',
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
