import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import 'package:safety_inspection_app/constants/strings_ko.dart';
import 'package:safety_inspection_app/screens/drawing/drawing_constants.dart';

class PdfDrawingView extends StatelessWidget {
  const PdfDrawingView({
    super.key,
    required this.pdfController,
    required this.pdfLoadError,
    required this.sitePdfName,
    required this.onPageChanged,
    required this.onDocumentLoaded,
    required this.onDocumentError,
    required this.pageSizes,
    required this.onUpdatePageSize,
    required this.buildPageOverlay,
  });

  final PdfController? pdfController;
  final String? pdfLoadError;
  final String? sitePdfName;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<PdfDocument> onDocumentLoaded;
  final ValueChanged<Object> onDocumentError;
  final Map<int, Size> pageSizes;
  final void Function(int pageNumber, Size pageSize) onUpdatePageSize;
  final Widget Function({
    required Size pageSize,
    required int pageNumber,
    required ImageProvider imageProvider,
  }) buildPageOverlay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (pdfLoadError != null) {
      return Container(
        color: theme.colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Text(
          pdfLoadError!,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
    if (pdfController != null) {
      return ClipRect(
        child: PdfView(
          controller: pdfController!,
          scrollDirection: Axis.vertical,
          pageSnapping: true,
          physics: const PageScrollPhysics(),
          onPageChanged: onPageChanged,
          onDocumentLoaded: onDocumentLoaded,
          onDocumentError: onDocumentError,
          builders: PdfViewBuilders<DefaultBuilderOptions>(
            options: const DefaultBuilderOptions(
              loaderSwitchDuration: Duration(milliseconds: 300),
            ),
            documentLoaderBuilder: (_) => const Center(
              child: CircularProgressIndicator(),
            ),
            pageLoaderBuilder: (_) => const Center(
              child: CircularProgressIndicator(),
            ),
            pageBuilder: (context, pageImage, pageIndex, document) {
              final pageNumber = pageIndex + 1;
              final imageProvider = PdfPageImageProvider(
                pageImage,
                pageNumber,
                document.id,
              );
              final fallbackSize =
                  pageSizes[pageNumber] ?? DrawingCanvasSize;
              return PhotoViewGalleryPageOptions.customChild(
                child: FutureBuilder<PdfPageImage>(
                  future: pageImage,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final data = snapshot.data!;
                      final w = (data.width ?? 1).toDouble();
                      final h = (data.height ?? 1).toDouble();
                      final pageSize = Size(
                        w,
                        h,
                      );
                      if (pageSizes[pageNumber] != pageSize) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!context.mounted) {
                            return;
                          }
                          onUpdatePageSize(pageNumber, pageSize);
                        });
                      }
                      return _buildPdfPageLayer(
                        pageSize: pageSize,
                        pageNumber: pageNumber,
                        imageProvider: imageProvider,
                      );
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
                childSize: fallbackSize,
                initialScale: PhotoViewComputedScale.contained,
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2.0,
                basePosition: Alignment.center,
              );
            },
          ),
        ),
      );
    }
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.picture_as_pdf_outlined,
            size: 64,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            sitePdfName ?? StringsKo.pdfDrawingLoaded,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(StringsKo.pdfDrawingHint, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildPdfPageLayer({
    required Size pageSize,
    required int pageNumber,
    required ImageProvider imageProvider,
  }) {
    return AspectRatio(
      aspectRatio: pageSize.width / pageSize.height,
      child: SizedBox(
        width: pageSize.width,
        height: pageSize.height,
        child: buildPageOverlay(
          pageSize: pageSize,
          pageNumber: pageNumber,
          imageProvider: imageProvider,
        ),
      ),
    );
  }
}
