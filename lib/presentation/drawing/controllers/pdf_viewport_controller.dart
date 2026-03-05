import 'package:flutter/material.dart';
import 'package:safety_inspection_app/presentation/drawing/models/pdf_viewport_snapshot.dart';

class PdfViewportController {
  const PdfViewportController();

  Matrix4 buildPhotoViewChildMatrix(PdfViewportSnapshot snapshot) {
    final viewportCenter = snapshot.viewportSize.center(Offset.zero);
    final childCenter = snapshot.childSize.center(Offset.zero);
    final translation = Matrix4.identity()
      ..setTranslationRaw(
        viewportCenter.dx + snapshot.position.dx,
        viewportCenter.dy + snapshot.position.dy,
        0.0,
      );
    final scale = Matrix4.diagonal3Values(snapshot.scale, snapshot.scale, 1.0);
    final centerOffset = Matrix4.identity()
      ..setTranslationRaw(-childCenter.dx, -childCenter.dy, 0.0);
    return translation * scale * centerOffset;
  }

  Offset? mapViewportPointToPageLocal({
    required PdfViewportSnapshot snapshot,
    required Offset viewportLocal,
  }) {
    if (!snapshot.isValid) {
      return null;
    }
    final matrix = buildPhotoViewChildMatrix(snapshot);
    final inverted = Matrix4.inverted(matrix);
    final pageLocal = MatrixUtils.transformPoint(inverted, viewportLocal);
    if (pageLocal.dx < 0 ||
        pageLocal.dx > snapshot.childSize.width ||
        pageLocal.dy < 0 ||
        pageLocal.dy > snapshot.childSize.height) {
      return null;
    }
    return pageLocal;
  }

  Offset? overlayToNormalizedPoint({
    required Offset overlayLocal,
    required Size destSize,
  }) {
    if (destSize.width <= 0 || destSize.height <= 0) {
      return null;
    }
    if (overlayLocal.dx < 0 ||
        overlayLocal.dx > destSize.width ||
        overlayLocal.dy < 0 ||
        overlayLocal.dy > destSize.height) {
      return null;
    }
    return Offset(
      overlayLocal.dx / destSize.width,
      overlayLocal.dy / destSize.height,
    );
  }
}
