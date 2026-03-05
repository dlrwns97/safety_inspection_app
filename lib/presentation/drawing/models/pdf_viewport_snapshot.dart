import 'package:flutter/material.dart';

class PdfViewportSnapshot {
  const PdfViewportSnapshot({
    required this.scale,
    required this.position,
    required this.viewportSize,
    required this.childSize,
  });

  final double scale;
  final Offset position;
  final Size viewportSize;
  final Size childSize;

  bool get isValid =>
      scale > 0 &&
      viewportSize.width > 0 &&
      viewportSize.height > 0 &&
      childSize.width > 0 &&
      childSize.height > 0;
}
