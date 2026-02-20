import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';
import 'package:safety_inspection_app/screens/drawing/canvas/cached_image_painter.dart';
import 'package:safety_inspection_app/screens/drawing/canvas/drawing_canvas_controller.dart';
import 'package:safety_inspection_app/screens/drawing/canvas/eraser_cursor_painter.dart';
import 'package:safety_inspection_app/screens/drawing/canvas/eraser_preview_painter.dart';
import 'package:safety_inspection_app/screens/drawing/canvas/live_stroke_painter.dart';
import 'package:safety_inspection_app/screens/drawing/canvas/stroke_cache_manager.dart';

class DrawingCanvasWidget extends StatefulWidget {
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
  State<DrawingCanvasWidget> createState() => _DrawingCanvasWidgetState();
}

class _DrawingCanvasWidgetState extends State<DrawingCanvasWidget> {
  ui.Image? _lastStableCacheImage;

  @override
  void didUpdateWidget(covariant DrawingCanvasWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page != widget.page) {
      _lastStableCacheImage = widget.cacheManager.getCachedImage(widget.page);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.canvasSize.width,
      height: widget.canvasSize.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ValueListenableBuilder<int>(
            valueListenable: widget.controller.cacheRebuildTick,
            builder: (context, tick, child) {
              if (kDebugMode) {
                debugPrint('[Drawing] cached layer build page=${widget.page} tick=$tick');
              }
              return AnimatedBuilder(
                animation: widget.cacheManager,
                builder: (context, child) {
                  final latestImage = widget.cacheManager.getCachedImage(widget.page);
                  if (latestImage != null) {
                    _lastStableCacheImage = latestImage;
                  }
                  return RepaintBoundary(
                    child: CustomPaint(
                      painter: CachedImagePainter(
                        image: latestImage ?? _lastStableCacheImage,
                        devicePixelRatio: widget.devicePixelRatio,
                      ),
                      size: widget.canvasSize,
                    ),
                  );
                },
              );
            },
          ),
          ValueListenableBuilder(
            valueListenable: widget.controller.eraserPreview,
            builder: (context, preview, child) {
              return RepaintBoundary(
                child: CustomPaint(
                  painter: EraserPreviewPainter(
                    preview: preview?.page == widget.page ? preview : null,
                  ),
                  size: widget.canvasSize,
                ),
              );
            },
          ),
          ValueListenableBuilder<DrawingStroke?>(
            valueListenable: widget.controller.liveStroke,
            builder: (context, liveStroke, child) {
              return RepaintBoundary(
                child: CustomPaint(
                  painter: LiveStrokePainter(
                    liveStroke: liveStroke,
                    devicePixelRatio: widget.devicePixelRatio,
                    repaint: widget.controller.liveStroke,
                  ),
                  size: widget.canvasSize,
                ),
              );
            },
          ),
          ValueListenableBuilder(
            valueListenable: widget.controller.eraserCursor,
            builder: (context, cursor, child) {
              return RepaintBoundary(
                child: CustomPaint(
                  painter: EraserCursorPainter(
                    cursor: cursor,
                    radius: widget.eraserRadius,
                  ),
                  size: widget.canvasSize,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
