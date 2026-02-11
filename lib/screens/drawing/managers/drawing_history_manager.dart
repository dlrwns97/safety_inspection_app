import 'package:safety_inspection_app/models/drawing/drawing_history_action_persisted.dart';
import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';

class DrawingHistoryAction {
  const DrawingHistoryAction({
    required this.op,
    this.strokes = const <DrawingStroke>[],
    this.removedStrokes = const <DrawingStroke>[],
    this.addedStrokes = const <DrawingStroke>[],
  });

  factory DrawingHistoryAction.single({
    required DrawingStroke stroke,
    required bool wasAdd,
  }) {
    return DrawingHistoryAction(
      op: wasAdd ? DrawingHistoryOp.add : DrawingHistoryOp.remove,
      strokes: <DrawingStroke>[stroke],
    );
  }

  factory DrawingHistoryAction.replace({
    required List<DrawingStroke> removedStrokes,
    required List<DrawingStroke> addedStrokes,
  }) {
    return DrawingHistoryAction(
      op: DrawingHistoryOp.replace,
      removedStrokes: removedStrokes,
      addedStrokes: addedStrokes,
    );
  }

  final DrawingHistoryOp op;
  final List<DrawingStroke> strokes;
  final List<DrawingStroke> removedStrokes;
  final List<DrawingStroke> addedStrokes;

  DrawingStroke get stroke => strokes.first;

  DrawingHistoryAction deepCopySnapshot() {
    switch (op) {
      case DrawingHistoryOp.replace:
        return DrawingHistoryAction.replace(
          removedStrokes: removedStrokes
              .map((stroke) => stroke.deepCopy())
              .toList(growable: false),
          addedStrokes: addedStrokes
              .map((stroke) => stroke.deepCopy())
              .toList(growable: false),
        );
      case DrawingHistoryOp.add:
      case DrawingHistoryOp.remove:
        return DrawingHistoryAction(
          op: op,
          strokes: strokes
              .map((stroke) => stroke.deepCopy())
              .toList(growable: false),
        );
    }
  }
}

class DrawingHistoryManager {
  DrawingHistoryManager({
    required List<DrawingHistoryAction> undoStack,
    required List<DrawingHistoryAction> redoStack,
    required this.maxHistory,
    required this.onHistoryChanged,
    required this.persistDrawing,
    required this.addStroke,
    required this.removeStroke,
    required this.replaceStrokes,
    this.findStrokeById,
  }) : _undoStack = undoStack,
       _redoStack = redoStack;

  final List<DrawingHistoryAction> _undoStack;
  final List<DrawingHistoryAction> _redoStack;
  final int maxHistory;
  final void Function() onHistoryChanged;
  final void Function() persistDrawing;
  final void Function(DrawingStroke stroke) addStroke;
  final void Function(DrawingStroke stroke) removeStroke;
  final void Function(List<DrawingStroke> removed, List<DrawingStroke> added)
  replaceStrokes;
  final DrawingStroke? Function(String id)? findStrokeById;

  void recordUndoAction(DrawingHistoryAction action) {
    _recordUndoAction(action);
  }

  void recordRedoAction(DrawingHistoryAction action) {
    _recordRedoAction(action);
  }

  void syncHistoryAvailability() {
    _syncDrawingHistoryAvailability();
  }

  void recordAdd(DrawingStroke stroke) {
    _recordUndoAction(DrawingHistoryAction.single(stroke: stroke, wasAdd: true));
    _redoStack.clear();
    _syncDrawingHistoryAvailability();
  }

  void recordRemove(DrawingStroke strokeSnapshot) {
    _recordUndoAction(
      DrawingHistoryAction.single(stroke: strokeSnapshot, wasAdd: false),
    );
    _redoStack.clear();
    _syncDrawingHistoryAvailability();
  }

  void recordReplace(
    List<DrawingStroke> removedSnapshots,
    List<DrawingStroke> addedSnapshots,
  ) {
    _recordUndoAction(
      DrawingHistoryAction.replace(
        removedStrokes: removedSnapshots,
        addedStrokes: addedSnapshots,
      ),
    );
    _redoStack.clear();
    _syncDrawingHistoryAvailability();
  }

  void undo() {
    if (_undoStack.isEmpty) {
      return;
    }
    final action = _undoStack.removeLast();
    switch (action.op) {
      case DrawingHistoryOp.add:
        for (final stroke in action.strokes) {
          removeStroke(stroke);
        }
        break;
      case DrawingHistoryOp.remove:
        for (final stroke in action.strokes) {
          addStroke(stroke);
        }
        break;
      case DrawingHistoryOp.replace:
        replaceStrokes(action.addedStrokes, action.removedStrokes);
        break;
    }
    _recordRedoAction(action);
    _syncDrawingHistoryAvailability();
    persistDrawing();
  }

  void redo() {
    if (_redoStack.isEmpty) {
      return;
    }
    final action = _redoStack.removeLast();
    switch (action.op) {
      case DrawingHistoryOp.add:
        for (final stroke in action.strokes) {
          addStroke(stroke);
        }
        break;
      case DrawingHistoryOp.remove:
        for (final stroke in action.strokes) {
          removeStroke(stroke);
        }
        break;
      case DrawingHistoryOp.replace:
        replaceStrokes(action.removedStrokes, action.addedStrokes);
        break;
    }
    _recordUndoAction(action);
    _syncDrawingHistoryAvailability();
    persistDrawing();
  }

  void loadPersisted(
    List<DrawingHistoryActionPersisted> undoPersisted,
    List<DrawingHistoryActionPersisted> redoPersisted,
  ) {
    final loadedUndo = undoPersisted
        .map(_runtimeHistoryActionFromPersisted)
        .whereType<DrawingHistoryAction>()
        .toList();
    if (loadedUndo.length > maxHistory) {
      loadedUndo.removeRange(0, loadedUndo.length - maxHistory);
    }
    final loadedRedo = redoPersisted
        .map(_runtimeHistoryActionFromPersisted)
        .whereType<DrawingHistoryAction>()
        .toList();
    if (loadedRedo.length > maxHistory) {
      loadedRedo.removeRange(0, loadedRedo.length - maxHistory);
    }

    _undoStack
      ..clear()
      ..addAll(loadedUndo);
    _redoStack
      ..clear()
      ..addAll(loadedRedo);
    _syncDrawingHistoryAvailability();
  }

  ({
    List<DrawingHistoryActionPersisted> undoPersisted,
    List<DrawingHistoryActionPersisted> redoPersisted,
  }) toPersistedStacks() {
    final persistedUndo = _undoStack
        .map(_persistedHistoryActionFromRuntime)
        .toList(growable: false);
    final persistedRedo = _redoStack
        .map(_persistedHistoryActionFromRuntime)
        .toList(growable: false);
    return (undoPersisted: persistedUndo, redoPersisted: persistedRedo);
  }

  void _recordUndoAction(DrawingHistoryAction action) {
    _undoStack.add(action.deepCopySnapshot());
    if (_undoStack.length > maxHistory) {
      _undoStack.removeAt(0);
    }
  }

  void _recordRedoAction(DrawingHistoryAction action) {
    _redoStack.add(action.deepCopySnapshot());
    if (_redoStack.length > maxHistory) {
      _redoStack.removeAt(0);
    }
  }

  void _syncDrawingHistoryAvailability() {
    onHistoryChanged();
  }

  DrawingHistoryAction? _runtimeHistoryActionFromPersisted(
    DrawingHistoryActionPersisted action,
  ) {
    if (action.op == DrawingHistoryOp.replace) {
      final removed = (action.removedStrokesJson ?? const <Map<String, dynamic>>[])
          .map(DrawingStroke.fromJson)
          .whereType<DrawingStroke>()
          .toList(growable: false);
      final added = (action.addedStrokesJson ?? const <Map<String, dynamic>>[])
          .map(DrawingStroke.fromJson)
          .whereType<DrawingStroke>()
          .toList(growable: false);
      if (removed.isEmpty && added.isEmpty) {
        return null;
      }
      return DrawingHistoryAction.replace(
        removedStrokes: removed,
        addedStrokes: added,
      );
    }
    final snapshots = action.strokesJson;
    if (snapshots != null && snapshots.isNotEmpty) {
      final strokes = snapshots
          .map(DrawingStroke.fromJson)
          .whereType<DrawingStroke>()
          .toList(growable: false);
      if (strokes.isEmpty) {
        return null;
      }
      return DrawingHistoryAction(op: action.op, strokes: strokes);
    }
    final snapshot = action.strokeJson;
    final stroke =
        snapshot == null
            ? findStrokeById?.call(action.strokeId)
            : DrawingStroke.fromJson(snapshot);
    if (stroke == null) {
      return null;
    }
    return DrawingHistoryAction.single(
      stroke: stroke,
      wasAdd: action.op == DrawingHistoryOp.add,
    );
  }

  DrawingHistoryActionPersisted _persistedHistoryActionFromRuntime(
    DrawingHistoryAction action,
  ) {
    if (action.op == DrawingHistoryOp.replace) {
      final removed = action.removedStrokes
          .map((stroke) => stroke.toJson())
          .toList(growable: false);
      final added = action.addedStrokes
          .map((stroke) => stroke.toJson())
          .toList(growable: false);
      return DrawingHistoryActionPersisted(
        op: DrawingHistoryOp.replace,
        strokeId: action.removedStrokes.isNotEmpty
            ? action.removedStrokes.first.id
            : action.addedStrokes.isNotEmpty
                ? action.addedStrokes.first.id
                : '',
        removedStrokesJson: removed,
        addedStrokesJson: added,
      );
    }
    if (action.strokes.length > 1) {
      return DrawingHistoryActionPersisted(
        op: action.op,
        strokeId: action.strokes.first.id,
        strokesJson: action.strokes
            .map((stroke) => stroke.toJson())
            .toList(growable: false),
      );
    }
    final stroke = action.stroke;
    return DrawingHistoryActionPersisted(
      op: action.op,
      strokeId: stroke.id,
      strokeJson: stroke.toJson(),
    );
  }
}
