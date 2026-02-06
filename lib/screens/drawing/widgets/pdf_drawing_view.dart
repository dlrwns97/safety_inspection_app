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
    required this.pdfViewVersion,
    required this.onUpdatePageSize,
    required this.photoControllerForPage,
    required this.scaleStateControllerForPage,
    required this.buildPageOverlay,
    required this.pageContentKeyForPage,
    required this.enablePdfPanGestures,
    required this.enablePdfScaleGestures,
    required this.disablePageSwipe,
  });

  final PdfController? pdfController;
  final String? pdfLoadError;
  final String? sitePdfName;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<PdfDocument> onDocumentLoaded;
  final ValueChanged<Object> onDocumentError;
  final Map<int, Size> pageSizes;
  final int pdfViewVersion;
  final void Function(int pageNumber, Size pageSize) onUpdatePageSize;
  final PhotoViewController Function(int pageNumber) photoControllerForPage;
  final PhotoViewScaleStateController Function(int pageNumber)
      scaleStateControllerForPage;
  final Widget Function({
    required Size pageSize,
    required Size renderSize,
    required int pageNumber,
    required ImageProvider imageProvider,
    required Key pageContentKey,
  }) buildPageOverlay;
  final GlobalKey Function(int pageNumber) pageContentKeyForPage;
  final bool enablePdfPanGestures;
  final bool enablePdfScaleGestures;
  final bool disablePageSwipe;

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
          key: ValueKey(pdfViewVersion),
          controller: pdfController!,
          scrollDirection: Axis.vertical,
          pageSnapping: true,
          physics: disablePageSwipe
              ? const NeverScrollableScrollPhysics()
              : const PageScrollPhysics(),
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
                controller: photoControllerForPage(pageNumber),
                scaleStateController:
                    scaleStateControllerForPage(pageNumber),
                disableGestures:
                    !(enablePdfPanGestures || enablePdfScaleGestures),
                child: FutureBuilder<PdfPageImage>(
                  future: pageImage,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final data = snapshot.data!;
                      final w = (data.width ?? 1).toDouble();
                      final h = (data.height ?? 1).toDouble();
                      final imageSize = Size(
                        w,
                        h,
                      );
                      final resolvedSize =
                          pageSizes[pageNumber] ?? imageSize;
                      if (pageSizes[pageNumber] == null &&
                          pageSizes[pageNumber] != imageSize) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!context.mounted) {
                            return;
                          }
                          onUpdatePageSize(pageNumber, imageSize);
                        });
                      }
                      return _buildPdfPageLayer(
                        pageSize: resolvedSize,
                        pageNumber: pageNumber,
                        imageProvider: imageProvider,
                      );
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
                childSize: fallbackSize,
                initialScale: PdfDrawingInitialScale,
                minScale: PdfDrawingMinScale,
                maxScale:
                    PhotoViewComputedScale.covered * PdfDrawingMaxScaleMultiplier,
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final renderSize = constraints.biggest;
          return SizedBox.expand(
            child: buildPageOverlay(
              pageSize: pageSize,
              renderSize: renderSize,
              pageNumber: pageNumber,
              imageProvider: imageProvider,
              pageContentKey: pageContentKeyForPage(pageNumber),
            ),
          );
        },
      ),
    );
  }
}
