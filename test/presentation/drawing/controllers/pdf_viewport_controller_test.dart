import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:safety_inspection_app/presentation/drawing/controllers/pdf_viewport_controller.dart';

void main() {
  group('PdfViewportController', () {
    const controller = PdfViewportController();

    test('destinationRectForOverlay centers contained PDF page', () {
      final rect = controller.destinationRectForOverlay(
        pageSize: const Size(1000, 500),
        overlaySize: const Size(300, 300),
      );

      expect(rect.left, 0);
      expect(rect.top, 75);
      expect(rect.width, 300);
      expect(rect.height, 150);
    });

    test(
      'destinationRectForOverlay falls back to full overlay without page size',
      () {
        final rect = controller.destinationRectForOverlay(
          pageSize: null,
          overlaySize: const Size(300, 200),
        );

        expect(rect, Offset.zero & const Size(300, 200));
      },
    );
  });
}
