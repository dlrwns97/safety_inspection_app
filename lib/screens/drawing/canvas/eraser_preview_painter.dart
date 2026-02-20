import 'package:flutter/rendering.dart';

import 'package:safety_inspection_app/models/drawing/eraser_preview.dart';

class EraserPreviewPainter extends CustomPainter {
  const EraserPreviewPainter({required this.preview});

  final EraserPreview? preview;

  @override
  void paint(Canvas canvas, Size size) {
    final activePreview = preview;
    if (activePreview == null) {
      return;
    }

    final cursor = activePreview.cursor;
    final radius = activePreview.radius;
    if (cursor != null && radius != null && radius > 0) {
      final highlightPaint = Paint()
        ..color = const Color(0x1A1E88E5)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(cursor, radius, highlightPaint);

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = const Color(0xFF1E88E5);
      canvas.drawCircle(cursor, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant EraserPreviewPainter oldDelegate) {
    return oldDelegate.preview != preview;
  }
}
