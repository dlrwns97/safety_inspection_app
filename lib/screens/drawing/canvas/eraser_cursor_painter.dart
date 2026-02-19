import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

class EraserCursorPainter extends CustomPainter {
  EraserCursorPainter({required this.cursor, required this.radius});

  final Offset? cursor;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset? cursorPosition = cursor;
    if (cursorPosition == null) {
      return;
    }

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const ui.Color(0xFFFFFFFF).withValues(alpha: 0.8);

    canvas.drawCircle(cursorPosition, radius, paint);
  }

  @override
  bool shouldRepaint(covariant EraserCursorPainter oldDelegate) {
    return oldDelegate.cursor != cursor || oldDelegate.radius != radius;
  }
}
