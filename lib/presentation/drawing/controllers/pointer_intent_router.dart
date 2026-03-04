import 'package:flutter/gestures.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/presentation/drawing/controllers/marker_input_guard.dart';

class PointerIntentRouter {
  const PointerIntentRouter._();

  static bool shouldTrackMarkerStylusTap({
    required bool isFreeDrawMode,
    required DrawMode mode,
    required PointerDeviceKind pointerKind,
  }) {
    return !isFreeDrawMode &&
        MarkerInputGuard.requiresStylusForPlacement(mode) &&
        MarkerInputGuard.isStrictStylus(pointerKind);
  }

  static bool shouldHandleShapeDown({
    required bool isFreeDrawMode,
    required bool isShapeToolActive,
    required PointerDeviceKind pointerKind,
  }) {
    return isFreeDrawMode &&
        isShapeToolActive &&
        MarkerInputGuard.isStrictStylus(pointerKind);
  }

  static bool shouldHandleShapeMove({
    required bool isFreeDrawMode,
    required bool isShapeToolActive,
    required int? activeStylusPointerId,
    required int pointerId,
    required PointerDeviceKind pointerKind,
  }) {
    return isFreeDrawMode &&
        isShapeToolActive &&
        activeStylusPointerId != null &&
        pointerId == activeStylusPointerId &&
        MarkerInputGuard.isStrictStylus(pointerKind);
  }

  static bool shouldHandleShapeEnd({
    required bool isFreeDrawMode,
    required bool isShapeToolActive,
    required int? activeStylusPointerId,
    required int pointerId,
  }) {
    return isFreeDrawMode &&
        isShapeToolActive &&
        activeStylusPointerId == pointerId;
  }

  static bool shouldProcessFreeDrawMove({
    required bool isFreeDrawMode,
    required PointerDeviceKind pointerKind,
  }) {
    if (!isFreeDrawMode) {
      return false;
    }
    if (!MarkerInputGuard.isStylusLike(pointerKind)) {
      return false;
    }
    return pointerKind != PointerDeviceKind.touch;
  }

  static bool shouldStartFreeDrawStroke({
    required bool isFreeDrawMode,
    required bool hasActiveStrokeStyle,
  }) {
    return isFreeDrawMode && hasActiveStrokeStyle;
  }
}
