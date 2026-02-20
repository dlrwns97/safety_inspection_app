import 'dart:ui';

import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';

class EraserPreview {
  const EraserPreview({
    required this.page,
    required this.previewStrokes,
    required this.virtualStrokesToRender,
    this.hiddenStrokeIds = const <String>{},
    this.strokesToMask = const <DrawingStroke>[],
    this.cursor,
    this.radius,
  });

  final int page;
  final List<DrawingStroke> previewStrokes;
  final List<DrawingStroke> virtualStrokesToRender;
  final Set<String> hiddenStrokeIds;
  final List<DrawingStroke> strokesToMask;
  final Offset? cursor;
  final double? radius;
}
