import 'package:flutter/material.dart';

class DrawingCanvasShell extends StatelessWidget {
  const DrawingCanvasShell({
    super.key,
    required this.child,
    required this.isMoveMode,
    required this.isFreeDrawMode,
    required this.allowTapInFreeDraw,
    required this.hasMoveTarget,
    required this.onPointerDown,
    required this.onPointerMove,
    required this.onPointerUp,
    required this.onPointerCancel,
    required this.onTapUp,
    this.onLongPressStart,
    this.onMovePanUpdate,
    this.onMovePanStart,
    this.onMovePanEnd,
    this.onMovePanCancel,
    this.behavior = HitTestBehavior.opaque,
    this.tapRegionKey,
  });

  final Widget child;
  final bool isMoveMode;
  final bool isFreeDrawMode;
  final bool allowTapInFreeDraw;
  final bool hasMoveTarget;
  final ValueChanged<Offset> onPointerDown;
  final ValueChanged<Offset> onPointerMove;
  final VoidCallback onPointerUp;
  final VoidCallback onPointerCancel;
  final GestureTapUpCallback onTapUp;
  final GestureLongPressStartCallback? onLongPressStart;
  final GestureDragUpdateCallback? onMovePanUpdate;
  final VoidCallback? onMovePanStart;
  final VoidCallback? onMovePanEnd;
  final VoidCallback? onMovePanCancel;
  final HitTestBehavior behavior;
  final Key? tapRegionKey;

  @override
  Widget build(BuildContext context) {
    final GestureTapUpCallback? tapHandler =
        (isMoveMode || (isFreeDrawMode && !allowTapInFreeDraw))
        ? null
        : onTapUp;
    final GestureLongPressStartCallback? longPressHandler =
        (isMoveMode || isFreeDrawMode) ? null : onLongPressStart;
    final bool canMove = isMoveMode && hasMoveTarget;
    final GestureDragUpdateCallback? movePanUpdate =
        (isFreeDrawMode || !canMove) ? null : onMovePanUpdate;

    return Listener(
      behavior: behavior,
      onPointerDown: (e) => onPointerDown(e.localPosition),
      onPointerMove: (e) => onPointerMove(e.localPosition),
      onPointerUp: (_) => onPointerUp(),
      onPointerCancel: (_) => onPointerCancel(),
      child: GestureDetector(
        behavior: behavior,
        onTapUp: tapHandler,
        onLongPressStart: longPressHandler,
        onPanStart: canMove ? (_) => onMovePanStart?.call() : null,
        onPanUpdate: movePanUpdate,
        onPanEnd: canMove ? (_) => onMovePanEnd?.call() : null,
        onPanCancel: canMove ? onMovePanCancel : null,
        child: KeyedSubtree(key: tapRegionKey, child: child),
      ),
    );
  }
}
