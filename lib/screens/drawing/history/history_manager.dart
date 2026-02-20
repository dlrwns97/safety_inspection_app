import 'package:safety_inspection_app/screens/drawing/canvas/drawing_canvas_controller.dart';
import 'package:safety_inspection_app/screens/drawing/history/history_commands.dart';

class HistoryManager {
  HistoryManager({this.maxHistory = 300});

  final int maxHistory;
  final List<HistoryCommand> _undoStack = <HistoryCommand>[];
  final List<HistoryCommand> _redoStack = <HistoryCommand>[];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  int get undoCount => _undoStack.length;
  int get redoCount => _redoStack.length;

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }

  void execute(HistoryCommand command, DrawingCanvasController controller) {
    command.execute(controller);
    _undoStack.add(command);
    if (_undoStack.length > maxHistory) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
    controller.invalidateCache(command.page, reason: 'commit');
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
    if (_undoStack.length > maxHistory) {
      _undoStack.removeAt(0);
    }
    controller.invalidateCache(command.page, reason: 'redo');
    return command.page;
  }
}
