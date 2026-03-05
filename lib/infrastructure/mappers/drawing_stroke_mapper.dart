import 'dart:ui';

import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';
import 'package:safety_inspection_app/screens/drawing/drawing_types.dart';

class DrawingStrokeMapper {
  const DrawingStrokeMapper._();

  static Map<String, dynamic> styleToJson(StrokeStyle style) {
    return <String, dynamic>{
      'kind': style.kind.name,
      'variant': style.variant.name,
      'widthPx': style.widthPx,
      'argbColor': style.argbColor,
      'opacity': style.opacity,
    };
  }

  static StrokeStyle styleFromJson(Map<String, dynamic> json) {
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

  static Map<String, dynamic> toJson(DrawingStroke stroke) {
    final json = <String, dynamic>{
      'id': stroke.id,
      'pageNumber': stroke.pageNumber,
      'style': styleToJson(stroke.style),
      'pointsNorm': stroke.pointsNorm
          .map<List<double>>((point) => <double>[point.dx, point.dy])
          .toList(),
      'toolType': stroke.toolType.name,
      'opacity': stroke.opacity,
      'isStraightened': stroke.isStraightened,
    };
    if (stroke.penVariant != null) {
      json['penVariant'] = stroke.penVariant;
    }
    if (stroke.highlighterVariant != null) {
      json['highlighterVariant'] = stroke.highlighterVariant;
    }
    if (stroke.shapeType != null) {
      json['shapeType'] = stroke.shapeType;
    }
    if (stroke.shapeFillArgb != null) {
      json['shapeFillArgb'] = stroke.shapeFillArgb;
    }
    if (stroke.erasedMaskVersion != null) {
      json['erasedMaskVersion'] = stroke.erasedMaskVersion;
    }
    if (stroke.erasedMask != null) {
      json['erasedMask'] = stroke.erasedMask;
    }
    if (stroke.erasedSegments != null) {
      json['erasedSegments'] = stroke.erasedSegments;
    }
    return json;
  }

  static DrawingStroke fromJson(Map<String, dynamic> json) {
    final rawPoints = (json['pointsNorm'] as List?) ?? const [];
    final style = styleFromJson(
      (json['style'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
    );
    final fallbackTool = switch (style.kind) {
      StrokeToolKind.highlighter => DrawingTool.highlighter,
      StrokeToolKind.eraser => DrawingTool.strokeEraser,
      StrokeToolKind.shape => DrawingTool.shape,
      StrokeToolKind.pen => DrawingTool.pen,
    };
    final erasedMaskRaw = json['erasedMask'];
    final erasedSegmentsRaw = json['erasedSegments'];

    final pointsNorm = rawPoints.whereType<List>().map<Offset>((coords) {
      final x = _asDouble(coords.isNotEmpty ? coords[0] : null, 0);
      final y = _asDouble(coords.length > 1 ? coords[1] : null, 0);
      return Offset(x, y);
    }).toList(growable: false);
    final parsedMask =
        erasedMaskRaw is List
            ? erasedMaskRaw
                .map<int>((item) => _asInt(item, 0) == 0 ? 0 : 1)
                .toList(growable: false)
            : null;
    final normalizedMask =
        parsedMask == null
            ? null
            : List<int>.generate(pointsNorm.length, (index) {
              if (index >= parsedMask.length) {
                return 0;
              }
              return parsedMask[index] == 0 ? 0 : 1;
            }, growable: false);

    return DrawingStroke(
      id: _asString(json['id'], null) ?? DrawingStroke.generateId(),
      pageNumber: _asInt(json['pageNumber'], 1),
      style: style,
      pointsNorm: pointsNorm,
      toolType: _drawingToolFromJson(json['toolType'], fallback: fallbackTool),
      opacity: _asDouble(json['opacity'], style.opacity),
      isStraightened: _asBool(json['isStraightened'], false),
      penVariant: _asString(json['penVariant'], null),
      highlighterVariant: _asString(json['highlighterVariant'], null),
      shapeType: _asString(json['shapeType'], null),
      shapeFillArgb:
          json.containsKey('shapeFillArgb')
              ? _asInt(json['shapeFillArgb'], 0)
              : null,
      erasedMaskVersion:
          json.containsKey('erasedMaskVersion')
              ? _asInt(json['erasedMaskVersion'], 0)
              : null,
      erasedMask: normalizedMask,
      erasedSegments:
          erasedSegmentsRaw is List
              ? List<dynamic>.from(erasedSegmentsRaw)
              : null,
    );
  }
}

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
