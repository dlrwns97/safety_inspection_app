import 'dart:ui';

enum StrokeToolKind { pen, highlighter, eraser }

enum PenVariant {
  ballpoint,
  fountain,
  pencil,
  marker,
  calligraphy,
  highlighterSoft,
  highlighterChisel,
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
               ? PenVariant.highlighterSoft
               : PenVariant.ballpoint);

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
              ? PenVariant.highlighterSoft
              : PenVariant.ballpoint),
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
    final kind = StrokeToolKind.values.firstWhere(
      (toolKind) => toolKind.name == json['kind'],
      orElse: () => StrokeToolKind.pen,
    );
    return StrokeStyle(
      kind: kind,
      variant: PenVariant.values.firstWhere(
        (penVariant) => penVariant.name == json['variant'],
        orElse: () => kind == StrokeToolKind.highlighter
            ? PenVariant.highlighterSoft
            : PenVariant.ballpoint,
      ),
      widthPx: (json['widthPx'] as num?)?.toDouble() ?? 3.0,
      argbColor: (json['argbColor'] as num?)?.toInt() ?? 0xFF000000,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class DrawingStroke {
  const DrawingStroke({
    required this.pageNumber,
    required this.style,
    required this.pointsNorm,
  });

  final int pageNumber;
  final StrokeStyle style;
  final List<Offset> pointsNorm;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
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
