import 'package:flutter_test/flutter_test.dart';
import 'package:safety_inspection_app/presentation/drawing/states/history_state.dart';

void main() {
  group('HistoryState', () {
    test('has expected defaults', () {
      final state = HistoryState();

      expect(state.canUndoDrawing, isFalse);
      expect(state.canRedoDrawing, isFalse);
    });

    test('stores mutable undo/redo visibility', () {
      final state = HistoryState();
      state.canUndoDrawing = true;
      state.canRedoDrawing = true;

      expect(state.canUndoDrawing, isTrue);
      expect(state.canRedoDrawing, isTrue);
    });
  });
}
