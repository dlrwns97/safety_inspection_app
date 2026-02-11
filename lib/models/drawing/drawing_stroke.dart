import 'dart:ui';

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

  DrawingStroke deepCopy() {
    return DrawingStroke(
      id: id,
      pageNumber: pageNumber,
      style: style,
      pointsNorm: List<Offset>.from(pointsNorm),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'pageNumber': pageNumber,
      'style': style.toJson(),
      'pointsNorm': pointsNorm
          .map<List<double>>((point) => <double>[point.dx, point.dy])
          .toList(),
    };
  }

  factory DrawingStroke.fromJson(Map<String, dynamic> json) {
    final rawPoints = (json['pointsNorm'] as List?) ?? const [];
    return DrawingStroke(
      id: json['id']?.toString() ?? DrawingStroke.generateId(),
      pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 1,
      style: StrokeStyle.fromJson(
        (json['style'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{},
      ),
      pointsNorm: rawPoints.whereType<List>().map<Offset>((coords) {
        final x = (coords.isNotEmpty ? coords[0] : null) as num?;
        final y = (coords.length > 1 ? coords[1] : null) as num?;
        return Offset(x?.toDouble() ?? 0, y?.toDouble() ?? 0);
      }).toList(),
    );
  }
}
