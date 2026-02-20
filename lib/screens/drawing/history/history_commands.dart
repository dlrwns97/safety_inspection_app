import 'package:flutter/foundation.dart';

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
  BatchEraseCommandItem _normalizeItem(
    BatchEraseCommandItem item,
    DrawingCanvasController controller,
  ) {
    final stroke = controller.findStrokeById(page, item.strokeId);
    final pointCount = stroke?.pointsNorm.length ?? item.afterMask.length;
    return BatchEraseCommandItem(
      strokeId: item.strokeId,
      beforeMask: _normalizeMask(item.beforeMask, pointCount),
      afterMask: _normalizeMask(item.afterMask, pointCount),
    );
  }

  List<bool> _normalizeMask(List<bool> mask, int pointCount) {
    if (pointCount <= 0) {
      return const <bool>[];
    }
    final normalized = List<bool>.filled(pointCount, false, growable: false);
    final copyLength = mask.length < pointCount ? mask.length : pointCount;
    for (var i = 0; i < copyLength; i += 1) {
      normalized[i] = mask[i];
    }
    return normalized;
  }

  BatchEraseCommand({
    required this.page,
    required List<BatchEraseCommandItem> items,
    DateTime? timestamp,
  }) : items = (List<BatchEraseCommandItem>.from(items, growable: false)
           ..sort((a, b) => a.strokeId.compareTo(b.strokeId))),
       super(timestamp: timestamp);

  @override
  final int page;
  final List<BatchEraseCommandItem> items;

  @override
  HistoryCommandType get type => HistoryCommandType.eraseArea;

  @override
  void execute(DrawingCanvasController controller) {
    _applyMasks(controller, useAfterMask: true);
  }

  @override
  void undo(DrawingCanvasController controller) {
    _applyMasks(controller, useAfterMask: false);
  }

  void _applyMasks(DrawingCanvasController controller, {required bool useAfterMask}) {
    for (final item in items) {
      final normalizedItem = _normalizeItem(item, controller);
      final applied = controller.setErasedMaskBool(
        page,
        normalizedItem.strokeId,
        useAfterMask ? normalizedItem.afterMask : normalizedItem.beforeMask,
      );
      if (!applied && kDebugMode) {
        debugPrint(
          '[Drawing] BatchEraseCommand skip missing stroke '
          'page=$page id=${normalizedItem.strokeId}',
        );
      }
    }
  }
}

class BatchEraseCommandItem {
  BatchEraseCommandItem({
    required this.strokeId,
    required List<bool> beforeMask,
    required List<bool> afterMask,
  }) : beforeMask = List<bool>.from(beforeMask, growable: false),
       afterMask = List<bool>.from(afterMask, growable: false);

  final String strokeId;
  final List<bool> beforeMask;
  final List<bool> afterMask;
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
