import 'dart:ui';

import 'package:safety_inspection_app/models/drawing/drawing_tool.dart';

enum StrokeToolKind { pen, highlighter, eraser, shape }

enum PenVariant {
  pen,
  fountainPen,
  calligraphyPen,
  pencil,
  highlighter,
  highlighterChisel,
  marker,
  markerChisel,
}

class StrokeStyle {
  const StrokeStyle({
    this.kind = StrokeToolKind.pen,
    PenVariant? variant,
    this.widthPx = 3.0,
    this.argbColor = 0xFF000000,
    this.opacity = 1.0,
  }) : variant =
           variant ??
           (kind == StrokeToolKind.highlighter
               ? PenVariant.highlighter
               : PenVariant.pen);

  final StrokeToolKind kind;
  final PenVariant variant;
  final double widthPx;
  final int argbColor;
  final double opacity;

  StrokeStyle copyWith({
    StrokeToolKind? kind,
    PenVariant? variant,
    double? widthPx,
    int? argbColor,
    double? opacity,
  }) {
    final nextKind = kind ?? this.kind;
    return StrokeStyle(
      kind: nextKind,
      variant:
          variant ??
          (kind == null
              ? this.variant
              : nextKind == StrokeToolKind.highlighter
              ? PenVariant.highlighter
              : PenVariant.pen),
      widthPx: widthPx ?? this.widthPx,
      argbColor: argbColor ?? this.argbColor,
      opacity: opacity ?? this.opacity,
    );
  }
}

class DrawingStroke {
  DrawingStroke({
    required this.id,
    required this.pageNumber,
    required this.style,
    required List<Offset> pointsNorm,
    this.toolType = DrawingTool.pen,
    this.opacity = 1.0,
    this.isStraightened = false,
    this.penVariant,
    this.highlighterVariant,
    this.shapeType,
    this.shapeFillArgb,
    this.erasedMaskVersion,
    this.erasedMask,
    this.erasedSegments,
  }) : pointsNorm = List<Offset>.from(pointsNorm);

  static int _idCounter = 0;

  static String generateId() {
    _idCounter += 1;
    return '${DateTime.now().microsecondsSinceEpoch}-$_idCounter';
  }

  final String id;
  final int pageNumber;
  final StrokeStyle style;
  final List<Offset> pointsNorm;
  final DrawingTool toolType;
  final double opacity;
  final bool isStraightened;
  final String? penVariant;
  final String? highlighterVariant;
  final String? shapeType;
  final int? shapeFillArgb;
  final int? erasedMaskVersion;
  final List<int>? erasedMask;
  final List<dynamic>? erasedSegments;

  List<int> ensureErasedMask() {
    final pointCount = pointsNorm.length;
    final source = erasedMask;
    if (source == null || source.length != pointCount) {
      final normalized = List<int>.filled(pointCount, 0, growable: false);
      if (source != null) {
        final copyLength = source.length < pointCount ? source.length : pointCount;
        for (var i = 0; i < copyLength; i += 1) {
          normalized[i] = source[i] == 0 ? 0 : 1;
        }
      }
      return normalized;
    }
    return source.map((value) => value == 0 ? 0 : 1).toList(growable: false);
  }

  List<bool> erasedMaskAsBool() {
    return ensureErasedMask()
        .map((value) => value != 0)
        .toList(growable: false);
  }

  DrawingStroke deepCopy() {
    return DrawingStroke(
      id: id,
      pageNumber: pageNumber,
      style: style,
      pointsNorm: List<Offset>.from(pointsNorm),
      toolType: toolType,
      opacity: opacity,
      isStraightened: isStraightened,
      penVariant: penVariant,
      highlighterVariant: highlighterVariant,
      shapeType: shapeType,
      shapeFillArgb: shapeFillArgb,
      erasedMaskVersion: erasedMaskVersion,
      erasedMask: erasedMask == null ? null : List<int>.from(erasedMask!),
      erasedSegments:
          erasedSegments == null ? null : List<dynamic>.from(erasedSegments!),
    );
  }
}
