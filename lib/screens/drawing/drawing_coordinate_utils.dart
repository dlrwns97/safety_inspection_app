import 'package:flutter/material.dart';

Offset toNormalized(Offset local, Size size) {
  if (size.width <= 0 || size.height <= 0) {
    return Offset.zero;
  }
  return Offset(
    (local.dx / size.width).clamp(0.0, 1.0),
    (local.dy / size.height).clamp(0.0, 1.0),
  );
}
