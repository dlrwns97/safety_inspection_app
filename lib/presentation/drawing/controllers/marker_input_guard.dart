import 'package:flutter/gestures.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';

class MarkerInputGuard {
  const MarkerInputGuard._();

  static bool requiresStylusForPlacement(DrawMode mode) {
    return mode == DrawMode.defect || mode == DrawMode.equipment;
  }

  static bool isStrictStylus(PointerDeviceKind kind) {
    return kind == PointerDeviceKind.stylus ||
        kind == PointerDeviceKind.invertedStylus;
  }

  static bool isStylusLike(PointerDeviceKind kind) {
    return isStrictStylus(kind) ||
        kind == PointerDeviceKind.touch ||
        kind == PointerDeviceKind.unknown;
  }

  static bool allowMarkerPlacementPointer({
    required DrawMode mode,
    required PointerDeviceKind kind,
  }) {
    if (!requiresStylusForPlacement(mode)) {
      return true;
    }
    return isStrictStylus(kind);
  }
}
