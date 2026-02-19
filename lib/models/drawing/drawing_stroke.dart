import 'dart:ui';

import 'package:safety_inspection_app/screens/drawing/drawing_types.dart';

double _asDouble(dynamic value, double fallback) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? fallback;
  }
  return fallback;
}

int _asInt(dynamic value, int fallback) {
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
}

bool _asBool(dynamic value, bool fallback) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') {
      return true;
    }
    if (normalized == 'false' || normalized == '0') {
      return false;
    }
  }
  return fallback;
}

String? _asString(dynamic value, String? fallback) {
  if (value is String) {
    return value;
  }
  if (value == null) {
    return fallback;
  }
  return value.toString();
}

DrawingTool _drawingToolFromJson(dynamic value, {DrawingTool? fallback}) {
  final defaultTool = fallback ?? DrawingTool.pen;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    for (final tool in DrawingTool.values) {
      if (tool.name.toLowerCase() == normalized) {
        return tool;
      }
    }
  }
  if (value is num) {
    final index = value.toInt();
    if (index >= 0 && index < DrawingTool.values.length) {
      return DrawingTool.values[index];
    }
  }
  return defaultTool;
}

enum StrokeToolKind { pen, highlighter, eraser }

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

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'kind': kind.name,
      'variant': variant.name,
      'widthPx': widthPx,
      'argbColor': argbColor,
      'opacity': opacity,
    };
  }

  factory StrokeStyle.fromJson(Map<String, dynamic> json) {
    final kindName = json['kind']?.toString();
    final kind = StrokeToolKind.values.firstWhere(
      (toolKind) => toolKind.name == kindName,
      orElse: () => StrokeToolKind.pen,
    );

    final rawVariant = json['variant']?.toString();
    final normalizedVariant = rawVariant == 'brush' ? 'pen' : rawVariant;

    return StrokeStyle(
      kind: kind,
      variant: PenVariant.values.firstWhere(
        (penVariant) => penVariant.name == normalizedVariant,
        orElse: () =>
            kind == StrokeToolKind.highlighter
                ? PenVariant.highlighter
                : PenVariant.pen,
      ),
      widthPx: (json['widthPx'] as num?)?.toDouble() ?? 3.0,
      argbColor: (json['argbColor'] as num?)?.toInt() ?? 0xFF000000,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
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
  final int? erasedMaskVersion;
  final List<int>? erasedMask;
  final List<dynamic>? erasedSegments;

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
      erasedMaskVersion: erasedMaskVersion,
      erasedMask: erasedMask == null ? null : List<int>.from(erasedMask!),
      erasedSegments:
          erasedSegments == null ? null : List<dynamic>.from(erasedSegments!),
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'pageNumber': pageNumber,
      'style': style.toJson(),
      'pointsNorm': pointsNorm
          .map<List<double>>((point) => <double>[point.dx, point.dy])
          .toList(),
      'toolType': toolType.name,
      'opacity': opacity,
      'isStraightened': isStraightened,
    };
    if (penVariant != null) {
      json['penVariant'] = penVariant;
    }
    if (highlighterVariant != null) {
      json['highlighterVariant'] = highlighterVariant;
    }
    if (erasedMaskVersion != null) {
      json['erasedMaskVersion'] = erasedMaskVersion;
    }
    if (erasedMask != null) {
      json['erasedMask'] = erasedMask;
    }
    if (erasedSegments != null) {
      json['erasedSegments'] = erasedSegments;
    }
    return json;
  }

  factory DrawingStroke.fromJson(Map<String, dynamic> json) {
    final rawPoints = (json['pointsNorm'] as List?) ?? const [];
    final style = StrokeStyle.fromJson(
      (json['style'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
    );
    final fallbackTool = switch (style.kind) {
      StrokeToolKind.highlighter => DrawingTool.highlighter,
      StrokeToolKind.eraser => DrawingTool.strokeEraser,
      StrokeToolKind.pen => DrawingTool.pen,
    };
    final erasedMaskRaw = json['erasedMask'];
    final erasedSegmentsRaw = json['erasedSegments'];

    return DrawingStroke(
      id: _asString(json['id'], null) ?? DrawingStroke.generateId(),
      pageNumber: _asInt(json['pageNumber'], 1),
      style: style,
      pointsNorm: rawPoints.whereType<List>().map<Offset>((coords) {
        final x = _asDouble(coords.isNotEmpty ? coords[0] : null, 0);
        final y = _asDouble(coords.length > 1 ? coords[1] : null, 0);
        return Offset(x, y);
      }).toList(),
      toolType: _drawingToolFromJson(json['toolType'], fallback: fallbackTool),
      opacity: _asDouble(json['opacity'], style.opacity),
      isStraightened: _asBool(json['isStraightened'], false),
      penVariant: _asString(json['penVariant'], null),
      highlighterVariant: _asString(json['highlighterVariant'], null),
      erasedMaskVersion:
          json.containsKey('erasedMaskVersion')
              ? _asInt(json['erasedMaskVersion'], 0)
              : null,
      erasedMask:
          erasedMaskRaw is List
              ? erasedMaskRaw
                  .map<int>((item) => _asInt(item, 0))
                  .toList(growable: false)
              : null,
      erasedSegments:
          erasedSegmentsRaw is List
              ? List<dynamic>.from(erasedSegmentsRaw)
              : null,
    );
  }
}
