import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';
import 'package:safety_inspection_app/models/drawing/eraser_preview.dart';
import 'package:safety_inspection_app/screens/drawing/canvas/cached_image_painter.dart';
import 'package:safety_inspection_app/screens/drawing/canvas/drawing_canvas_controller.dart';
import 'package:safety_inspection_app/screens/drawing/canvas/eraser_cursor_painter.dart';
import 'package:safety_inspection_app/screens/drawing/canvas/live_stroke_painter.dart';
import 'package:safety_inspection_app/screens/drawing/canvas/preview_strokes_painter.dart';
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
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.canvasSize.width,
      height: widget.canvasSize.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ValueListenableBuilder<EraserPreview?>(
            valueListenable: widget.controller.eraserPreview,
            child: _CachedCanvasLayer(
              controller: widget.controller,
              cacheManager: widget.cacheManager,
              page: widget.page,
              canvasSize: widget.canvasSize,
              devicePixelRatio: widget.devicePixelRatio,
            ),
            builder: (context, preview, child) {
              final isPreviewActive = preview?.page == widget.page;
              return Visibility(
                visible: !isPreviewActive,
                maintainState: true,
                maintainAnimation: true,
                maintainSize: true,
                child: child!,
              );
            },
          ),
          ValueListenableBuilder<EraserPreview?>(
            valueListenable: widget.controller.eraserPreview,
            builder: (context, preview, child) {
              final pagePreview = preview?.page == widget.page ? preview : null;
              return RepaintBoundary(
                child: CustomPaint(
                  painter: PreviewStrokesPainter(
                    strokes: pagePreview?.previewStrokes ?? const <DrawingStroke>[],
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

class _CachedCanvasLayer extends StatefulWidget {
  const _CachedCanvasLayer({
    required this.controller,
    required this.cacheManager,
    required this.page,
    required this.canvasSize,
    required this.devicePixelRatio,
  });

  final DrawingCanvasController controller;
  final StrokeCacheManager cacheManager;
  final int page;
  final Size canvasSize;
  final double devicePixelRatio;

  @override
  State<_CachedCanvasLayer> createState() => _CachedCanvasLayerState();
}

class _CachedCanvasLayerState extends State<_CachedCanvasLayer> {
  ui.Image? _lastStableCacheImage;

  void _pullStableImageFromCache() {
    final latestImage = widget.cacheManager.getCachedImage(widget.page);
    if (latestImage != null) {
      _lastStableCacheImage = latestImage;
    }
  }

  @override
  void initState() {
    super.initState();
    _pullStableImageFromCache();
  }

  @override
  void didUpdateWidget(covariant _CachedCanvasLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page != widget.page) {
      _lastStableCacheImage = null;
    }
    _pullStableImageFromCache();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: widget.controller.cacheRebuildTick,
      builder: (context, tick, child) {
        _pullStableImageFromCache();
        if (kDebugMode) {
          debugPrint('[Drawing] cached layer build page=${widget.page} tick=$tick');
        }
        return AnimatedBuilder(
          animation: widget.cacheManager,
          builder: (context, child) {
            _pullStableImageFromCache();
            return RepaintBoundary(
              child: CustomPaint(
                painter: CachedImagePainter(
                  image: _lastStableCacheImage,
                  devicePixelRatio: widget.devicePixelRatio,
                ),
                size: widget.canvasSize,
              ),
            );
          },
        );
      },
    );
  }
}
