import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';
import 'package:safety_inspection_app/screens/drawing/canvas/drawing_canvas_controller.dart';

abstract class HistoryCommand {
  const HistoryCommand();

  int get page;

  void execute(DrawingCanvasController controller);

  void undo(DrawingCanvasController controller);
}

class AddStrokeCommand extends HistoryCommand {
  const AddStrokeCommand({required this.page, required this.stroke});

  @override
  final int page;
  final DrawingStroke stroke;

  @override
  void execute(DrawingCanvasController controller) {
    controller.addStroke(page, stroke.deepCopy());
  }

  @override
  void undo(DrawingCanvasController controller) {
    controller.removeStrokeById(page, stroke.id);
  }
}

class DeleteStrokeCommand extends HistoryCommand {
  const DeleteStrokeCommand({required this.page, required this.deletedStroke});

  @override
  final int page;
  final DrawingStroke deletedStroke;

  @override
  void execute(DrawingCanvasController controller) {
    controller.removeStrokeById(page, deletedStroke.id);
  }

  @override
  void undo(DrawingCanvasController controller) {
    controller.addStroke(page, deletedStroke.deepCopy());
  }
}

class ReplaceStrokesCommand extends HistoryCommand {
  const ReplaceStrokesCommand({
    required this.page,
    required this.removedStrokes,
    required this.addedStrokes,
  });

  @override
  final int page;
  final List<DrawingStroke> removedStrokes;
  final List<DrawingStroke> addedStrokes;

  @override
  void execute(DrawingCanvasController controller) {
    for (final stroke in removedStrokes) {
      controller.removeStrokeById(page, stroke.id);
    }
    for (final stroke in addedStrokes) {
      controller.addStroke(page, stroke.deepCopy());
    }
  }

  @override
  void undo(DrawingCanvasController controller) {
    for (final stroke in addedStrokes) {
      controller.removeStrokeById(page, stroke.id);
    }
    for (final stroke in removedStrokes) {
      controller.addStroke(page, stroke.deepCopy());
    }
  }
}
