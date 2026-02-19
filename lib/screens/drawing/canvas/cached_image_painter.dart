import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

class CachedImagePainter extends CustomPainter {
  CachedImagePainter({required this.image, required this.devicePixelRatio});

  final ui.Image? image;
  final double devicePixelRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final ui.Image? currentImage = image;
    if (currentImage == null) {
      return;
    }

    final Rect src = Rect.fromLTWH(
      0,
      0,
      currentImage.width.toDouble(),
      currentImage.height.toDouble(),
    );
    final Rect dst = Offset.zero & size;

    canvas.drawImageRect(currentImage, src, dst, Paint());
  }

  @override
  bool shouldRepaint(covariant CachedImagePainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.devicePixelRatio != devicePixelRatio;
  }
}
