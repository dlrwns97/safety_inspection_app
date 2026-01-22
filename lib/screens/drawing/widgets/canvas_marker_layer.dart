import 'package:flutter/material.dart';

class CanvasMarkerLayer extends StatelessWidget {
  const CanvasMarkerLayer({
    super.key,
    required this.canvasSize,
    required this.canvasKey,
    required this.transformationController,
    required this.onPointerDown,
    required this.onPointerMove,
    required this.onPointerUp,
    required this.onPointerCancel,
    required this.onTapUp,
    required this.background,
    required this.defectMarkers,
    required this.equipmentMarkers,
    required this.markerPopup,
  });

  final Size canvasSize;
  final GlobalKey canvasKey;
  final TransformationController transformationController;
  final ValueChanged<Offset> onPointerDown;
  final ValueChanged<Offset> onPointerMove;
  final VoidCallback onPointerUp;
  final VoidCallback onPointerCancel;
  final GestureTapUpCallback onTapUp;
  final Widget background;
  final List<Widget> defectMarkers;
  final List<Widget> equipmentMarkers;
  final Widget markerPopup;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Listener(
          onPointerDown: (event) => onPointerDown(event.localPosition),
          onPointerMove: (event) => onPointerMove(event.localPosition),
          onPointerUp: (_) => onPointerUp(),
          onPointerCancel: (_) => onPointerCancel(),
          child: GestureDetector(
            behavior: HitTestBehavior.deferToChild,
            onTapUp: onTapUp,
            child: InteractiveViewer(
              transformationController: transformationController,
              minScale: 0.5,
              maxScale: 4,
              constrained: false,
              child: SizedBox(
                key: canvasKey,
                width: canvasSize.width,
                height: canvasSize.height,
                child: Stack(
                  children: [
                    background,
                    ...defectMarkers,
                    ...equipmentMarkers,
                  ],
                ),
              ),
            ),
          ),
        ),
        markerPopup,
      ],
    );
  }
}
