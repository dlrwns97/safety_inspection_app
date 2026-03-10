import 'package:flutter/foundation.dart';

/// Toggle for verbose drawing logs in debug/profile troubleshooting sessions.
const bool kDrawingVerboseLogging = false;

void drawingVerboseLog(String message) {
  assert(() {
    if (kDrawingVerboseLogging) {
      debugPrint(message);
    }
    return true;
  }());
}
