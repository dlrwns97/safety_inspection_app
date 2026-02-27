import 'dart:developer' as developer;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:safety_inspection_app/screens/drawing/engines/pen_engine.dart';
import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';
import 'package:safety_inspection_app/screens/drawing/drawing_types.dart';

class TempPolylinePainter extends CustomPainter {
  TempPolylinePainter({
    required this.strokes,
    required this.inProgress,
    required this.pageSize,
    this.debugLastPageLocal,
  });

  final List<DrawingStroke> strokes;
  final DrawingStroke? inProgress;
  final Size pageSize;
  final Offset? debugLastPageLocal;

  static ui.Picture? _cachedBasePicture;
  static int _cachedBaseHash = 0;
  static int _cacheHit = 0;
  static int _cacheMiss = 0;
  static final Set<String> _debugLoggedStrokeIds = <String>{};

  @override
  void paint(Canvas canvas, Size size) {
    _DrawingUiPerfProbe.instance.ensureInitialized();
    final Stopwatch? stopwatch = kReleaseMode ? null : Stopwatch();
    stopwatch?.start();
    if (!kReleaseMode) {
      developer.Timeline.startSync('DrawingCanvas.paint');
    }

    try {
      if (pageSize.width <= 0 || pageSize.height <= 0) {
        return;
      }

      final inProgressStroke = inProgress;
      if (inProgressStroke == null) {
        _drawCachedBase(canvas, size);
      } else if (inProgressStroke.style.kind != StrokeToolKind.eraser) {
        _drawCachedBase(canvas, size);
        _drawStroke(canvas, inProgressStroke);
      } else {
        final layerRect = Offset.zero & size;
        canvas.saveLayer(layerRect, Paint());
        _drawCachedBase(canvas, size);
        _drawStroke(canvas, inProgressStroke);
        canvas.restore();
      }
      if (debugLastPageLocal != null) {
        final debugPaint = Paint()
          ..color = Colors.blueAccent
          ..style = PaintingStyle.fill;
        canvas.drawCircle(debugLastPageLocal!, 4, debugPaint);
      }
    } finally {
      if (!kReleaseMode) {
        developer.Timeline.finishSync();
      }
      if (stopwatch != null) {
        _DrawingUiPerfProbe.instance.recordPaint(
          elapsedMicros: stopwatch.elapsedMicroseconds,
          strokeCount: strokes.length + (inProgress == null ? 0 : 1),
        );
      }
      _DrawingUiPerfProbe.instance.recordCache(
        hit: _cacheHit,
        miss: _cacheMiss,
        strokeCount: strokes.length,
      );
    }
  }

  void _drawCachedBase(Canvas canvas, Size size) {
    final baseHash = _computeBaseHash();
    if (_cachedBasePicture != null && _cachedBaseHash == baseHash) {
      _cacheHit += 1;
      canvas.drawPicture(_cachedBasePicture!);
      return;
    }

    _cacheMiss += 1;
    final recorder = ui.PictureRecorder();
    final recordedCanvas = Canvas(recorder, Offset.zero & size);
    for (final stroke in strokes) {
      _drawStroke(recordedCanvas, stroke);
    }

    _cachedBasePicture?.dispose();
    _cachedBasePicture = recorder.endRecording();
    _cachedBaseHash = baseHash;
    canvas.drawPicture(_cachedBasePicture!);
  }

  int _computeBaseHash() {
    var strokeIdsHash = 0;
    for (final stroke in strokes) {
      strokeIdsHash = 0x1fffffff & (strokeIdsHash ^ stroke.id.hashCode);
    }
    return Object.hash(
      identityHashCode(strokes),
      strokes.length,
      strokeIdsHash,
      pageSize.width,
      pageSize.height,
    );
  }

  void _drawStroke(Canvas canvas, DrawingStroke stroke) {
    if (stroke.toolType == DrawingTool.textBox) {
      return;
    }
    final pointsNorm = stroke.pointsNorm;
    if (pointsNorm.isEmpty) {
      return;
    }

    Offset toPageLocal(Offset normPoint) {
      return Offset(
        normPoint.dx * pageSize.width,
        normPoint.dy * pageSize.height,
      );
    }

    final points = pointsNorm.map(toPageLocal).toList(growable: false);
    final erasedMask = stroke.ensureErasedMask();
    final style = stroke.style;
    if (kDebugMode && _debugLoggedStrokeIds.add(stroke.id)) {
      debugPrint(
        '[Drawing] TempPolylinePainter stroke=${stroke.id} variant=${style.variant.name}',
      );
    }

    _drawShapeFillIfNeeded(
      canvas: canvas,
      stroke: stroke,
      points: points,
      erasedMask: erasedMask,
    );

    for (var i = 0; i < points.length; i += 1) {
      if (erasedMask[i] != 0) {
        continue;
      }
      final start = i;
      var end = i;
      while (end + 1 < points.length && erasedMask[end + 1] == 0) {
        end += 1;
      }
      final segmentPoints = points.sublist(start, end + 1);
      if (style.kind == StrokeToolKind.pen) {
        _drawPenStroke(canvas, segmentPoints, style);
      } else {
        _drawCenterlineStroke(canvas, segmentPoints, style, stroke);
      }
      i = end;
    }
  }

  void _drawShapeFillIfNeeded({
    required Canvas canvas,
    required DrawingStroke stroke,
    required List<Offset> points,
    required List<int> erasedMask,
  }) {
    if (stroke.toolType != DrawingTool.shape || stroke.shapeFillArgb == null) {
      return;
    }
    if (erasedMask.any((value) => value != 0)) {
      return;
    }
    if (points.length < 3) {
      return;
    }

    final shapeType = stroke.shapeType ?? '';
    if (shapeType != 'rectangle' &&
        shapeType != 'circle' &&
        shapeType != 'triangle') {
      return;
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i += 1) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Color(
        stroke.shapeFillArgb!,
      ).withOpacity(stroke.style.opacity.clamp(0.0, 1.0))
      ..blendMode = BlendMode.srcOver;
    canvas.drawPath(path, fillPaint);
  }

  void _drawPenStroke(Canvas canvas, List<Offset> points, StrokeStyle style) {
    final resolvedOpacity = _resolvedPenOpacity(style);

    if (points.length == 1) {
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = Color(
          style.argbColor,
        ).withOpacity(resolvedOpacity.clamp(0.0, 1.0))
        ..blendMode = BlendMode.srcOver;
      canvas.drawCircle(points.first, style.widthPx / 2, paint);
      return;
    }

    final strokeInput = points
        .map((o) => PointVector(o.dx, o.dy))
        .toList(growable: false);

    final outline = getStroke(strokeInput, options: _optionsForPen(style));

    if (outline.isEmpty) {
      return;
    }

    final fillPath = _outlineToPath(outline);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Color(
        style.argbColor,
      ).withOpacity(resolvedOpacity.clamp(0.0, 1.0))
      ..blendMode = BlendMode.srcOver;

    canvas.drawPath(fillPath, paint);
  }

  StrokeOptions _optionsForPen(StrokeStyle style) {
    return PenEngine.optionsFor(style);
  }

  double _resolvedPenOpacity(StrokeStyle style) {
    var resolvedOpacity = style.opacity;
    if (style.variant == PenVariant.pencil) {
      resolvedOpacity *= 0.85;
    }
    return resolvedOpacity;
  }

  Path _outlineToPath(List<Offset> outline) {
    final path = Path();
    if (outline.isEmpty) {
      return path;
    }

    path.moveTo(outline.first.dx, outline.first.dy);
    for (var i = 0; i < outline.length - 1; ++i) {
      final p0 = outline[i];
      final p1 = outline[i + 1];
      path.quadraticBezierTo(
        p0.dx,
        p0.dy,
        (p0.dx + p1.dx) / 2,
        (p0.dy + p1.dy) / 2,
      );
    }
    path.close();
    return path;
  }

  void _drawCenterlineStroke(
    Canvas canvas,
    List<Offset> points,
    StrokeStyle style,
    DrawingStroke stroke,
  ) {
    var resolvedOpacity = style.opacity;
    var resolvedStrokeWidth = style.widthPx;
    var resolvedStrokeCap = StrokeCap.round;
    var resolvedStrokeJoin = StrokeJoin.round;
    var resolvedBlendMode = switch (style.kind) {
      StrokeToolKind.highlighter => BlendMode.multiply,
      StrokeToolKind.eraser => BlendMode.clear,
      StrokeToolKind.pen => BlendMode.srcOver,
      StrokeToolKind.shape => BlendMode.srcOver,
      StrokeToolKind.textBox => BlendMode.srcOver,
    };

    switch (style.variant) {
      case PenVariant.pen:
        break;
      case PenVariant.fountainPen:
        resolvedStrokeWidth *= 1.15;
        break;
      case PenVariant.calligraphyPen:
        resolvedStrokeCap = StrokeCap.square;
        resolvedStrokeJoin = StrokeJoin.bevel;
        resolvedStrokeWidth *= 1.1;
        break;
      case PenVariant.pencil:
        resolvedOpacity *= 0.75;
        resolvedStrokeWidth *= 0.9;
        break;
      case PenVariant.highlighter:
        resolvedBlendMode = BlendMode.multiply;
        break;
      case PenVariant.highlighterChisel:
        resolvedStrokeCap = StrokeCap.square;
        resolvedStrokeJoin = StrokeJoin.bevel;
        resolvedBlendMode = BlendMode.multiply;
        break;
      case PenVariant.marker:
        resolvedBlendMode = BlendMode.srcOver;
        break;
      case PenVariant.markerChisel:
        resolvedStrokeCap = StrokeCap.square;
        resolvedStrokeJoin = StrokeJoin.bevel;
        resolvedBlendMode = BlendMode.srcOver;
        break;
    }

    final isShapeArrow =
        stroke.toolType == DrawingTool.shape && stroke.shapeType == 'arrow';
    if (isShapeArrow) {
      resolvedStrokeCap = StrokeCap.butt;
      resolvedStrokeJoin = StrokeJoin.miter;
    }

    final paint = Paint()
      ..color = Color(
        style.argbColor,
      ).withOpacity(resolvedOpacity.clamp(0.0, 1.0))
      ..strokeWidth = resolvedStrokeWidth
      ..strokeCap = resolvedStrokeCap
      ..strokeJoin = resolvedStrokeJoin
      ..strokeMiterLimit = isShapeArrow ? 6.0 : 4.0
      ..style = PaintingStyle.stroke
      ..blendMode = resolvedBlendMode;

    if (points.length == 1) {
      canvas.drawCircle(points.first, paint.strokeWidth / 2, paint);
      return;
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final point = points[i];
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant TempPolylinePainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.inProgress != inProgress ||
        oldDelegate.pageSize != pageSize ||
        oldDelegate.debugLastPageLocal != debugLastPageLocal;
  }
}

class _DrawingUiPerfProbe {
  _DrawingUiPerfProbe._();

  static final _DrawingUiPerfProbe instance = _DrawingUiPerfProbe._();

  bool _initialized = false;
  DateTime? _windowStart;
  int _paintCalls = 0;
  int _paintTotalMicros = 0;
  int _paintMaxMicros = 0;
  int _buildCalls = 0;
  int _buildTotalMicros = 0;
  int _buildMaxMicros = 0;
  int _latestStrokeCount = 0;
  int _cacheHit = 0;
  int _cacheMiss = 0;

  void ensureInitialized() {
    if (kReleaseMode || _initialized) {
      return;
    }
    _initialized = true;
    SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
  }

  void recordPaint({required int elapsedMicros, required int strokeCount}) {
    if (kReleaseMode) {
      return;
    }
    _rolloverWindowIfNeeded();
    _latestStrokeCount = strokeCount;
    _paintCalls += 1;
    _paintTotalMicros += elapsedMicros;
    if (elapsedMicros > _paintMaxMicros) {
      _paintMaxMicros = elapsedMicros;
    }
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    if (kReleaseMode) {
      return;
    }
    for (final timing in timings) {
      _rolloverWindowIfNeeded();
      final buildMicros = timing.buildDuration.inMicroseconds;
      _buildCalls += 1;
      _buildTotalMicros += buildMicros;
      if (buildMicros > _buildMaxMicros) {
        _buildMaxMicros = buildMicros;
      }
    }
  }

  void recordCache({
    required int hit,
    required int miss,
    required int strokeCount,
  }) {
    if (kReleaseMode) {
      return;
    }
    _rolloverWindowIfNeeded();
    _cacheHit = hit;
    _cacheMiss = miss;
    _latestStrokeCount = strokeCount;
  }

  void _rolloverWindowIfNeeded() {
    final now = DateTime.now();
    final windowStart = _windowStart;
    if (windowStart == null) {
      _windowStart = now;
      return;
    }
    if (now.difference(windowStart) < const Duration(seconds: 1)) {
      return;
    }

    if (_paintCalls > 0 || _buildCalls > 0) {
      final paintAvgMs = _paintCalls == 0
          ? 0.0
          : (_paintTotalMicros / _paintCalls) / 1000;
      final buildAvgMs = _buildCalls == 0
          ? 0.0
          : (_buildTotalMicros / _buildCalls) / 1000;
      debugPrint(
        '[PerfUI] paint: avgMs=${paintAvgMs.toStringAsFixed(1)} '
        'maxMs=${(_paintMaxMicros / 1000).toStringAsFixed(1)} '
        'build: avgMs=${buildAvgMs.toStringAsFixed(1)} '
        'maxMs=${(_buildMaxMicros / 1000).toStringAsFixed(1)} '
        'strokes=$_latestStrokeCount',
      );
      debugPrint(
        '[PerfCache] basePicture hit=$_cacheHit miss=$_cacheMiss '
        'strokes=$_latestStrokeCount',
      );
    }

    _windowStart = now;
    _paintCalls = 0;
    _paintTotalMicros = 0;
    _paintMaxMicros = 0;
    _buildCalls = 0;
    _buildTotalMicros = 0;
    _buildMaxMicros = 0;
  }
}
