
import 'package:flutter_test/flutter_test.dart';
import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';
import 'package:safety_inspection_app/screens/drawing/canvas/drawing_canvas_controller.dart';
import 'package:safety_inspection_app/screens/drawing/history/history_commands.dart';
import 'package:safety_inspection_app/screens/drawing/history/history_manager.dart';

DrawingStroke _stroke(int index, {int page = 1}) {
  return DrawingStroke(
    id: 's$index',
    pageNumber: page,
    style: const StrokeStyle(),
    pointsNorm: const <Offset>[
      Offset(0.1, 0.1),
      Offset(0.2, 0.2),
    ],
  );
}

void main() {
  group('HistoryManager stress', () {
    test('100 add -> undo 100 -> redo 100 keeps state stable', () {
      final controller = DrawingCanvasController();
      final history = HistoryManager(maxHistory: 300);

      for (var i = 0; i < 100; i += 1) {
        history.execute(
          AddStrokeCommand(page: 1, strokeSnapshot: _stroke(i)),
          controller,
        );
      }

      expect(controller.getStrokes(1).length, 100);
      expect(history.undoCount, 100);
      expect(history.redoCount, 0);

      for (var i = 0; i < 100; i += 1) {
        expect(history.undo(controller), 1);
      }

      expect(controller.getStrokes(1), isEmpty);
      expect(history.undoCount, 0);
      expect(history.redoCount, 100);

      for (var i = 0; i < 100; i += 1) {
        expect(history.redo(controller), 1);
      }

      final ids = controller.getStrokes(1).map((s) => s.id).toList();
      expect(ids.length, 100);
      expect(ids.first, 's0');
      expect(ids.last, 's99');
      expect(history.undoCount, 100);
      expect(history.redoCount, 0);
    });

    test('maxHistory=300 keeps only recent commands in undo stack', () {
      final controller = DrawingCanvasController();
      final history = HistoryManager(maxHistory: 300);

      for (var i = 0; i < 350; i += 1) {
        history.execute(
          AddStrokeCommand(page: 1, strokeSnapshot: _stroke(i)),
          controller,
        );
      }

      expect(controller.getStrokes(1).length, 350);
      expect(history.undoCount, 300);

      for (var i = 0; i < 300; i += 1) {
        history.undo(controller);
      }

      final remainingIds = controller.getStrokes(1).map((s) => s.id).toList();
      expect(remainingIds.length, 50);
      expect(remainingIds.first, 's0');
      expect(remainingIds.last, 's49');
    });
  });
}
