import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class CanvasMarkerLayer extends StatelessWidget {
  const CanvasMarkerLayer({
    super.key,
    required this.childPdfOrCanvas,
    required this.markerWidgets,
    this.miniPopup,
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerUp,
    this.onPointerCancel,
    this.onTapUp,
    this.hitTestBehavior,
    this.fillChild = true,
  });

  final Widget childPdfOrCanvas;
  final List<Widget> markerWidgets;
  final Widget? miniPopup;
  final PointerDownEventListener? onPointerDown;
  final PointerMoveEventListener? onPointerMove;
  final PointerUpEventListener? onPointerUp;
  final PointerCancelEventListener? onPointerCancel;
  final GestureTapUpCallback? onTapUp;
  final HitTestBehavior? hitTestBehavior;
  final bool fillChild;

  @override
  Widget build(BuildContext context) {
    final stackChildren = <Widget>[
      if (fillChild) Positioned.fill(child: childPdfOrCanvas) else childPdfOrCanvas,
      ...markerWidgets,
      if (miniPopup != null) miniPopup!,
    ];

    Widget content = Stack(children: stackChildren);

    if (onPointerDown != null ||
        onPointerMove != null ||
        onPointerUp != null ||
        onPointerCancel != null ||
        onTapUp != null) {
      content = Listener(
        onPointerDown: onPointerDown,
        onPointerMove: onPointerMove,
        onPointerUp: onPointerUp,
        onPointerCancel: onPointerCancel,
        child: GestureDetector(
          behavior: hitTestBehavior,
          onTapUp: onTapUp,
          child: content,
        ),
      );
    }

    return content;
  }
}
