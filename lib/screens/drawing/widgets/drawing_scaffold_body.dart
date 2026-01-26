import 'package:flutter/material.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/screens/drawing/drawing_constants.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/canvas_marker_layer.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/pdf_view_layer.dart';

class DrawingScaffoldBody extends StatelessWidget {
  const DrawingScaffoldBody({
    super.key,
    required this.drawingType,
    required this.pdfViewer,
    required this.currentPage,
    required this.pageCount,
    required this.canPrevPage,
    required this.canNextPage,
    required this.onPrevPage,
    required this.onNextPage,
    required this.onCanvasPointerDown,
    required this.onCanvasPointerMove,
    required this.onCanvasPointerUp,
    required this.onCanvasPointerCancel,
    required this.onCanvasTapUp,
    required this.transformationController,
    required this.canvasKey,
    required this.canvasSize,
    required this.drawingBackground,
    required this.markerWidgets,
    required this.markerPopup,
  });

  final DrawingType drawingType;
  final Widget pdfViewer;
  final int currentPage;
  final int pageCount;
  final bool canPrevPage;
  final bool canNextPage;
  final VoidCallback onPrevPage;
  final VoidCallback onNextPage;
  final PointerDownEventListener onCanvasPointerDown;
  final PointerMoveEventListener onCanvasPointerMove;
  final PointerUpEventListener onCanvasPointerUp;
  final PointerCancelEventListener onCanvasPointerCancel;
  final GestureTapUpCallback onCanvasTapUp;
  final TransformationController transformationController;
  final GlobalKey canvasKey;
  final Size canvasSize;
  final Widget drawingBackground;
  final List<Widget> markerWidgets;
  final Widget markerPopup;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, _) {
              return Stack(
                children: [
                  if (drawingType == DrawingType.pdf)
                    PdfViewLayer(
                      pdfViewer: pdfViewer,
                      currentPage: currentPage,
                      pageCount: pageCount,
                      canPrev: canPrevPage,
                      canNext: canNextPage,
                      onPrevPage: onPrevPage,
                      onNextPage: onNextPage,
                    )
                  else
                    Listener(
                      onPointerDown: onCanvasPointerDown,
                      onPointerMove: onCanvasPointerMove,
                      onPointerUp: onCanvasPointerUp,
                      onPointerCancel: onCanvasPointerCancel,
                      child: GestureDetector(
                        behavior: HitTestBehavior.deferToChild,
                        onTapUp: onCanvasTapUp,
                        child: InteractiveViewer(
                          transformationController: transformationController,
                          minScale: DrawingCanvasMinScale,
                          maxScale: DrawingCanvasMaxScale,
                          constrained: false,
                          child: SizedBox(
                            key: canvasKey,
                            width: canvasSize.width,
                            height: canvasSize.height,
                            child: CanvasMarkerLayer(
                              childPdfOrCanvas: drawingBackground,
                              markerWidgets: markerWidgets,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (drawingType != DrawingType.pdf) markerPopup,
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
