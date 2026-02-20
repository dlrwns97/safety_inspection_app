import 'package:flutter/material.dart';

import 'package:safety_inspection_app/screens/drawing/canvas/cached_image_painter.dart';
import 'package:safety_inspection_app/screens/drawing/canvas/drawing_canvas_controller.dart';
import 'package:safety_inspection_app/screens/drawing/canvas/eraser_cursor_painter.dart';
import 'package:safety_inspection_app/screens/drawing/canvas/live_stroke_painter.dart';
import 'package:safety_inspection_app/screens/drawing/canvas/stroke_cache_manager.dart';

class DrawingCanvasWidget extends StatelessWidget {
  const DrawingCanvasWidget({
    super.key,
    required this.controller,
    required this.cacheManager,
    required this.page,
    required this.canvasSize,
    required this.devicePixelRatio,
    required this.eraserRadius,
  });

  final DrawingCanvasController controller;
  final StrokeCacheManager cacheManager;
  final int page;
  final Size canvasSize;
  final double devicePixelRatio;
  final double eraserRadius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: canvasSize.width,
      height: canvasSize.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: cacheManager,
            builder: (context, child) {
              return RepaintBoundary(
                child: CustomPaint(
                  painter: CachedImagePainter(
                    image: cacheManager.getCachedImage(page),
                    devicePixelRatio: devicePixelRatio,
                  ),
                  size: canvasSize,
                ),
              );
            },
          ),
          ValueListenableBuilder(
            valueListenable: controller.liveStroke,
            builder: (context, liveStroke, child) {
              return CustomPaint(
                painter: LiveStrokePainter(
                  liveStroke: liveStroke,
                  devicePixelRatio: devicePixelRatio,
                ),
                size: canvasSize,
              );
            },
          ),
          ValueListenableBuilder(
            valueListenable: controller.eraserCursor,
            builder: (context, cursor, child) {
              return CustomPaint(
                painter: EraserCursorPainter(cursor: cursor, radius: eraserRadius),
                size: canvasSize,
              );
            },
          ),
        ],
      ),
    );
  }
}
