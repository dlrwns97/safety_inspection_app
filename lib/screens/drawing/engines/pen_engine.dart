import 'package:flutter/foundation.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart' show PenVariant, StrokeStyle;

class PenEngine {
  const PenEngine._();

  static final Set<String> _debugLoggedOptionKeys = <String>{};

  static void _debugLogOptionsFor(StrokeStyle style) {
    if (!kDebugMode) {
      return;
    }
    final key = '${style.variant.name}:${style.widthPx.toStringAsFixed(2)}';
    if (_debugLoggedOptionKeys.contains(key)) {
      return;
    }
    _debugLoggedOptionKeys.add(key);
    debugPrint(
      '[Drawing] PenEngine optionsFor: variant=${style.variant.name} '
      'kind=${style.kind.name} width=${style.widthPx.toStringAsFixed(1)}',
    );
  }

  static StrokeOptions optionsFor(StrokeStyle style) {
    _debugLogOptionsFor(style);
    final size = style.widthPx;

    switch (style.variant) {
      case PenVariant.fountainPen:
        return StrokeOptions(
          size: size,
          thinning: 0.55,
          smoothing: 0.75,
          streamline: 0.70,
          simulatePressure: true,
          start: StrokeEndOptions.start(cap: true),
          end: StrokeEndOptions.end(cap: true),
        );
      case PenVariant.calligraphyPen:
        return StrokeOptions(
          size: size,
          thinning: 0.75,
          smoothing: 0.55,
          streamline: 0.60,
          simulatePressure: true,
          start: StrokeEndOptions.start(cap: true),
          end: StrokeEndOptions.end(cap: true),
        );
      case PenVariant.pencil:
        return StrokeOptions(
          size: size * 0.95,
          thinning: 0.35,
          smoothing: 0.40,
          streamline: 0.35,
          simulatePressure: true,
          start: StrokeEndOptions.start(cap: true),
          end: StrokeEndOptions.end(cap: true),
        );
      case PenVariant.pen:
      default:
        return StrokeOptions(
          size: size,
          thinning: 0.60,
          smoothing: 0.65,
          streamline: 0.60,
          simulatePressure: true,
          start: StrokeEndOptions.start(cap: true),
          end: StrokeEndOptions.end(cap: true),
        );
    }
  }
}
