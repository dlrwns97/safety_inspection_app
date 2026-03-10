import 'package:flutter_test/flutter_test.dart';
import 'package:safety_inspection_app/models/drawing/drawing_tool.dart';
import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';
import 'package:safety_inspection_app/screens/drawing/canvas/drawing_canvas_controller.dart';
import 'package:safety_inspection_app/screens/drawing/history/history_commands.dart';
import 'package:safety_inspection_app/screens/drawing/history/history_manager.dart';

DrawingStroke _stroke(int index, {int page = 1}) {
  return DrawingStroke(
    id: 's$index',
    pageNumber: page,
    style: const StrokeStyle(),
    pointsNorm: const <Offset>[Offset(0.1, 0.1), Offset(0.2, 0.2)],
  );
}

DrawingStroke _strokeWithId({required String id, required int page}) {
  return DrawingStroke(
    id: id,
    pageNumber: page,
    style: const StrokeStyle(),
    pointsNorm: const <Offset>[Offset(0.1, 0.1), Offset(0.2, 0.2)],
  );
}

DrawingStroke _toolStroke({
  required String id,
  required int page,
  required StrokeToolKind kind,
  required DrawingTool toolType,
}) {
  return DrawingStroke(
    id: id,
    pageNumber: page,
    style: StrokeStyle(kind: kind),
    toolType: toolType,
    pointsNorm: const <Offset>[
      Offset(0.1, 0.1),
      Offset(0.2, 0.2),
      Offset(0.3, 0.3),
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

    test(
      'mixed pen/highlighter/shape + eraser stays stable across undo/redo',
      () {
        final controller = DrawingCanvasController();
        final history = HistoryManager(maxHistory: 50);

        history.execute(
          AddStrokeCommand(
            page: 1,
            strokeSnapshot: _toolStroke(
              id: 'pen-1',
              page: 1,
              kind: StrokeToolKind.pen,
              toolType: DrawingTool.pen,
            ),
          ),
          controller,
        );
        history.execute(
          AddStrokeCommand(
            page: 1,
            strokeSnapshot: _toolStroke(
              id: 'hl-1',
              page: 1,
              kind: StrokeToolKind.highlighter,
              toolType: DrawingTool.highlighter,
            ),
          ),
          controller,
        );
        history.execute(
          AddStrokeCommand(
            page: 1,
            strokeSnapshot: _toolStroke(
              id: 'shape-1',
              page: 1,
              kind: StrokeToolKind.shape,
              toolType: DrawingTool.shape,
            ),
          ),
          controller,
        );
        history.execute(
          BatchEraseCommand(
            page: 1,
            items: <BatchEraseCommandItem>[
              BatchEraseCommandItem(
                strokeId: 'pen-1',
                beforeMask: const <bool>[false, false, false],
                afterMask: const <bool>[true, false, true],
              ),
            ],
          ),
          controller,
        );

        final afterApply = controller.getStrokes(1);
        expect(afterApply.map((stroke) => stroke.id), <String>[
          'pen-1',
          'hl-1',
          'shape-1',
        ]);
        expect(
          controller.findStrokeById(1, 'pen-1')!.erasedMaskAsBool(),
          <bool>[true, false, true],
        );

        for (var i = 0; i < 4; i += 1) {
          expect(history.undo(controller), 1);
        }
        expect(controller.getStrokes(1), isEmpty);

        for (var i = 0; i < 4; i += 1) {
          expect(history.redo(controller), 1);
        }
        final afterRedo = controller.getStrokes(1);
        expect(afterRedo.map((stroke) => stroke.id), <String>[
          'pen-1',
          'hl-1',
          'shape-1',
        ]);
        expect(
          controller.findStrokeById(1, 'pen-1')!.erasedMaskAsBool(),
          <bool>[true, false, true],
        );
      },
    );

    test('120 undo/redo repeated cycles stay stable', () {
      final controller = DrawingCanvasController();
      final history = HistoryManager(maxHistory: 500);

      for (var i = 0; i < 120; i += 1) {
        history.execute(
          AddStrokeCommand(page: 1, strokeSnapshot: _stroke(i)),
          controller,
        );
      }
      expect(controller.getStrokes(1).length, 120);
      expect(history.undoCount, 120);
      expect(history.redoCount, 0);

      for (var cycle = 0; cycle < 3; cycle += 1) {
        for (var i = 0; i < 120; i += 1) {
          expect(history.undo(controller), 1);
        }
        expect(controller.getStrokes(1), isEmpty);
        expect(history.undoCount, 0);
        expect(history.redoCount, 120);

        for (var i = 0; i < 120; i += 1) {
          expect(history.redo(controller), 1);
        }
        final ids = controller.getStrokes(1).map((s) => s.id).toList();
        expect(ids.length, 120);
        expect(ids.first, 's0');
        expect(ids.last, 's119');
        expect(history.undoCount, 120);
        expect(history.redoCount, 0);
      }
    });

    test('12-page mixed history keeps page isolation after full undo/redo', () {
      final controller = DrawingCanvasController();
      final history = HistoryManager(maxHistory: 1000);
      const pageCount = 12;
      const strokesPerPage = 25;
      const totalCommands = pageCount * strokesPerPage;

      for (var page = 1; page <= pageCount; page += 1) {
        for (var i = 0; i < strokesPerPage; i += 1) {
          history.execute(
            AddStrokeCommand(
              page: page,
              strokeSnapshot: _strokeWithId(id: 'p$page-s$i', page: page),
            ),
            controller,
          );
        }
      }

      for (var page = 1; page <= pageCount; page += 1) {
        final ids = controller.getStrokes(page).map((s) => s.id).toList();
        expect(ids.length, strokesPerPage);
        expect(ids.first, 'p$page-s0');
        expect(ids.last, 'p$page-s24');
      }
      expect(history.undoCount, totalCommands);

      for (var i = 0; i < totalCommands; i += 1) {
        expect(history.undo(controller), isNotNull);
      }
      for (var page = 1; page <= pageCount; page += 1) {
        expect(controller.getStrokes(page), isEmpty);
      }
      expect(history.undoCount, 0);
      expect(history.redoCount, totalCommands);

      for (var i = 0; i < totalCommands; i += 1) {
        expect(history.redo(controller), isNotNull);
      }
      for (var page = 1; page <= pageCount; page += 1) {
        final ids = controller.getStrokes(page).map((s) => s.id).toList();
        expect(ids.length, strokesPerPage);
        expect(ids.first, 'p$page-s0');
        expect(ids.last, 'p$page-s24');
      }
      expect(history.undoCount, totalCommands);
      expect(history.redoCount, 0);
    });
  });
}
