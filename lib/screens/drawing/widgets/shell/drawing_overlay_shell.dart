import 'package:flutter/material.dart';

class DrawingOverlayShell extends StatelessWidget {
  const DrawingOverlayShell({
    super.key,
    required this.isPdf,
    required this.canMove,
    required this.showFloatingToolSettings,
    required this.pdfLayer,
    required this.canvasLayer,
    required this.floatingToolSettingsButton,
    this.onMovePanStart,
    this.onMovePanUpdate,
    this.onMovePanEnd,
    this.onMovePanCancel,
  });

  final bool isPdf;
  final bool canMove;
  final bool showFloatingToolSettings;
  final Widget pdfLayer;
  final Widget canvasLayer;
  final Widget floatingToolSettingsButton;
  final GestureDragStartCallback? onMovePanStart;
  final GestureDragUpdateCallback? onMovePanUpdate;
  final VoidCallback? onMovePanEnd;
  final VoidCallback? onMovePanCancel;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (isPdf)
          AbsorbPointer(absorbing: canMove, child: pdfLayer)
        else
          canvasLayer,
        if (canMove)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: onMovePanStart,
              onPanUpdate: onMovePanUpdate,
              onPanEnd: (_) => onMovePanEnd?.call(),
              onPanCancel: onMovePanCancel,
            ),
          ),
        if (showFloatingToolSettings)
          Positioned(left: 12, top: 12, child: floatingToolSettingsButton),
      ],
    );
  }
}
