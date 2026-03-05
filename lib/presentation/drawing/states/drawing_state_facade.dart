import 'package:safety_inspection_app/presentation/drawing/states/drawing_session_state.dart';
import 'package:safety_inspection_app/presentation/drawing/states/gesture_state.dart';
import 'package:safety_inspection_app/presentation/drawing/states/history_state.dart';
import 'package:safety_inspection_app/presentation/drawing/states/marker_state.dart';
import 'package:safety_inspection_app/presentation/drawing/states/persist_state.dart';
import 'package:safety_inspection_app/presentation/drawing/states/tool_state.dart';

class DrawingStateFacade {
  DrawingStateFacade({
    DrawingSessionState? sessionState,
    MarkerState? markerState,
    GestureState? gestureState,
    HistoryState? historyState,
    PersistState? persistState,
    ToolState? toolState,
  }) : sessionState = sessionState ?? DrawingSessionState(),
       markerState = markerState ?? MarkerState(),
       gestureState = gestureState ?? GestureState(),
       historyState = historyState ?? HistoryState(),
       persistState = persistState ?? PersistState(),
       toolState = toolState ?? ToolState();

  final DrawingSessionState sessionState;
  final MarkerState markerState;
  final GestureState gestureState;
  final HistoryState historyState;
  final PersistState persistState;
  final ToolState toolState;

  void dispose() {
    persistState.dispose();
    sessionState.dispose();
  }
}
