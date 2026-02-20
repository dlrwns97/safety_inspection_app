import 'package:safety_inspection_app/screens/drawing/canvas/drawing_canvas_controller.dart';
import 'package:safety_inspection_app/screens/drawing/history/history_commands.dart';

class HistoryManager {
  HistoryManager({this.maxHistory = 200});

  final int maxHistory;
  final List<HistoryCommand> _undoStack = <HistoryCommand>[];
  final List<HistoryCommand> _redoStack = <HistoryCommand>[];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }

  void execute(
    HistoryCommand command,
    DrawingCanvasController controller, {
    String reason = 'commit',
  }) {
    command.execute(controller);
    _undoStack.add(command);
    if (_undoStack.length > maxHistory) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
    controller.invalidateCache(command.page, reason: reason);
  }

  int? undo(DrawingCanvasController controller) {
    if (!canUndo) {
      return null;
    }
    final command = _undoStack.removeLast();
    command.undo(controller);
    _redoStack.add(command);
    controller.invalidateCache(command.page, reason: 'undo');
    return command.page;
  }

  int? redo(DrawingCanvasController controller) {
    if (!canRedo) {
      return null;
    }
    final command = _redoStack.removeLast();
    command.execute(controller);
    _undoStack.add(command);
    controller.invalidateCache(command.page, reason: 'redo');
    return command.page;
  }
}
