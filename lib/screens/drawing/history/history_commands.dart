import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';
import 'package:safety_inspection_app/screens/drawing/canvas/drawing_canvas_controller.dart';
import 'package:safety_inspection_app/screens/drawing/history/history_types.dart';

abstract class HistoryCommand {
  HistoryCommand({DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();

  HistoryCommandType get type;
  int get page;
  final DateTime timestamp;

  void execute(DrawingCanvasController controller);

  void undo(DrawingCanvasController controller);
}

class AddStrokeCommand extends HistoryCommand {
  AddStrokeCommand({
    required this.page,
    required DrawingStroke strokeSnapshot,
    DateTime? timestamp,
  }) : strokeSnapshot = strokeSnapshot.deepCopy(),
       super(timestamp: timestamp);

  @override
  final int page;
  final DrawingStroke strokeSnapshot;

  @override
  HistoryCommandType get type => HistoryCommandType.addStroke;

  @override
  void execute(DrawingCanvasController controller) {
    controller.insertStroke(page, strokeSnapshot.deepCopy());
  }

  @override
  void undo(DrawingCanvasController controller) {
    controller.removeStrokeById(page, strokeSnapshot.id);
  }
}

class DeleteStrokeCommand extends HistoryCommand {
  DeleteStrokeCommand({
    required this.page,
    required DrawingStroke deletedSnapshot,
    this.originalIndex,
    DateTime? timestamp,
  }) : deletedSnapshot = deletedSnapshot.deepCopy(),
       super(timestamp: timestamp);

  @override
  final int page;
  final DrawingStroke deletedSnapshot;
  int? originalIndex;

  @override
  HistoryCommandType get type => HistoryCommandType.deleteStroke;

  @override
  void execute(DrawingCanvasController controller) {
    final strokes = controller.getStrokes(page);
    originalIndex ??= strokes.indexWhere((s) => s.id == deletedSnapshot.id);
    controller.removeStrokeById(page, deletedSnapshot.id);
  }

  @override
  void undo(DrawingCanvasController controller) {
    controller.insertStroke(
      page,
      deletedSnapshot.deepCopy(),
      index: originalIndex,
    );
  }
}

class EraseAreaCommand extends HistoryCommand {
  EraseAreaCommand({
    required this.page,
    required this.strokeId,
    required List<bool> previousMask,
    required List<bool> newMask,
    DateTime? timestamp,
  }) : previousMask = List<bool>.from(previousMask, growable: false),
       newMask = List<bool>.from(newMask, growable: false),
       super(timestamp: timestamp);

  @override
  final int page;
  final String strokeId;
  final List<bool> previousMask;
  final List<bool> newMask;

  @override
  HistoryCommandType get type => HistoryCommandType.eraseArea;

  @override
  void execute(DrawingCanvasController controller) {
    controller.setErasedMaskBool(page, strokeId, newMask);
  }

  @override
  void undo(DrawingCanvasController controller) {
    controller.setErasedMaskBool(page, strokeId, previousMask);
  }
}

class ClearAllCommand extends HistoryCommand {
  ClearAllCommand({required this.page, DateTime? timestamp})
    : super(timestamp: timestamp);

  @override
  final int page;
  List<DrawingStroke> previousStrokes = <DrawingStroke>[];

  @override
  HistoryCommandType get type => HistoryCommandType.clearAll;

  @override
  void execute(DrawingCanvasController controller) {
    previousStrokes = controller
        .getStrokes(page)
        .map((stroke) => stroke.deepCopy())
        .toList(growable: false);
    controller.clearPage(page);
  }

  @override
  void undo(DrawingCanvasController controller) {
    controller.restoreStrokes(page, previousStrokes);
  }
}

class BatchEraseCommand extends HistoryCommand {
  BatchEraseCommand({
    required this.page,
    required List<EraseAreaCommand> commands,
    DateTime? timestamp,
  }) : commands = List<EraseAreaCommand>.from(commands, growable: false),
       super(timestamp: timestamp);

  @override
  final int page;
  final List<EraseAreaCommand> commands;

  @override
  HistoryCommandType get type => HistoryCommandType.eraseArea;

  @override
  void execute(DrawingCanvasController controller) {
    for (final command in commands) {
      command.execute(controller);
    }
  }

  @override
  void undo(DrawingCanvasController controller) {
    for (final command in commands.reversed) {
      command.undo(controller);
    }
  }
}

class ReplaceStrokesCommand extends HistoryCommand {
  ReplaceStrokesCommand({
    required this.page,
    required List<DrawingStroke> removedStrokes,
    required List<DrawingStroke> addedStrokes,
    DateTime? timestamp,
  }) : removedStrokes = removedStrokes
           .map((stroke) => stroke.deepCopy())
           .toList(growable: false),
       addedStrokes = addedStrokes
           .map((stroke) => stroke.deepCopy())
           .toList(growable: false),
       super(timestamp: timestamp);

  @override
  final int page;
  final List<DrawingStroke> removedStrokes;
  final List<DrawingStroke> addedStrokes;

  @override
  HistoryCommandType get type => HistoryCommandType.eraseArea;

  @override
  void execute(DrawingCanvasController controller) {
    for (final stroke in removedStrokes) {
      controller.removeStrokeById(page, stroke.id);
    }
    for (final stroke in addedStrokes) {
      controller.insertStroke(page, stroke.deepCopy());
    }
  }

  @override
  void undo(DrawingCanvasController controller) {
    for (final stroke in addedStrokes) {
      controller.removeStrokeById(page, stroke.id);
    }
    for (final stroke in removedStrokes) {
      controller.insertStroke(page, stroke.deepCopy());
    }
  }
}

// TODO(Phase 2 migrate to mask swap): Remove ReplaceStrokesCommand once area
// eraser fully emits mask-based commands only.
