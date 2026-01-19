import 'dart:typed_data';

import 'package:pdfx/pdfx.dart';

class RenderedPdfPage {
  const RenderedPdfPage({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;
}

class PdfRendererService {
  PdfDocument? _document;

  int get pageCount => _document?.pagesCount ?? 0;

  Future<void> openDocument({
    required String assetPath,
    String? filePath,
  }) async {
    await close();
    if (assetPath.isNotEmpty) {
      try {
        _document = await PdfDocument.openAsset(assetPath);
        return;
      } catch (_) {
        // Fall back to file path below if asset loading fails.
      }
    }
    if (filePath != null && filePath.isNotEmpty) {
      _document = await PdfDocument.openFile(filePath);
    }
  }

  Future<RenderedPdfPage> renderPage(int pageNumber) async {
    final document = _document;
    if (document == null) {
      throw StateError('PDF document is not loaded.');
    }
    final page = await document.getPage(pageNumber);
    final pageImage = await page.render(
      width: page.width,
      height: page.height,
      format: PdfPageImageFormat.png,
    );
    await page.close();
    if (pageImage == null) {
      throw StateError('Failed to render page $pageNumber.');
    }
    return RenderedPdfPage(
      bytes: pageImage.bytes,
      width: pageImage.width,
      height: pageImage.height,
    );
  }

  Future<void> close() async {
    await _document?.close();
    _document = null;
  }
}
