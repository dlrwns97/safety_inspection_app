import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:safety_inspection_app/constants/strings_ko.dart';

class PdfViewLayer extends StatelessWidget {
  const PdfViewLayer({
    super.key,
    required this.pdfLoadError,
    required this.pdfController,
    required this.pdfName,
    required this.canvasSize,
    required this.pdfPageSizes,
    required this.currentPage,
    required this.pageCount,
    required this.onPageChanged,
    required this.onDocumentLoaded,
    required this.onDocumentError,
    required this.onPageSizeResolved,
    required this.onPdfTap,
    required this.onPointerDown,
    required this.onPointerMove,
    required this.onPointerUp,
    required this.onPointerCancel,
    required this.buildDefectMarkersForPage,
    required this.buildEquipmentMarkersForPage,
    required this.buildMarkerPopupForPage,
    required this.onPreviousPage,
    required this.onNextPage,
  });

  final String? pdfLoadError;
  final PdfController? pdfController;
  final String? pdfName;
  final Size canvasSize;
  final Map<int, Size> pdfPageSizes;
  final int currentPage;
  final int pageCount;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onDocumentLoaded;
  final ValueChanged<Object> onDocumentError;
  final void Function(int pageNumber, Size pageSize) onPageSizeResolved;
  final void Function(TapUpDetails details, Size pageSize, int pageNumber)
      onPdfTap;
  final ValueChanged<Offset> onPointerDown;
  final ValueChanged<Offset> onPointerMove;
  final VoidCallback onPointerUp;
  final VoidCallback onPointerCancel;
  final List<Widget> Function(Size pageSize, int pageNumber)
      buildDefectMarkersForPage;
  final List<Widget> Function(Size pageSize, int pageNumber)
      buildEquipmentMarkersForPage;
  final Widget Function(Size pageSize, int pageNumber) buildMarkerPopupForPage;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;

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
    if (pdfController == null) {
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
              pdfName ?? StringsKo.pdfDrawingLoaded,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(StringsKo.pdfDrawingHint, textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return Stack(
      children: [
        ClipRect(
          child: PdfView(
            controller: pdfController!,
            scrollDirection: Axis.vertical,
            pageSnapping: true,
            physics: const PageScrollPhysics(),
            onPageChanged: onPageChanged,
            onDocumentLoaded: (document) {
              onDocumentLoaded(document.pagesCount);
              debugPrint('PDF loaded with ${document.pagesCount} pages.');
            },
            onDocumentError: (error) {
              debugPrint('Failed to load PDF: $error');
              onDocumentError(error);
            },
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
                final fallbackSize = pdfPageSizes[pageNumber] ?? canvasSize;
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
                        if (pdfPageSizes[pageNumber] != pageSize) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            onPageSizeResolved(pageNumber, pageSize);
                          });
                        }
                        return _PdfPageLayer(
                          pageSize: pageSize,
                          pageNumber: pageNumber,
                          imageProvider: imageProvider,
                          onPdfTap: onPdfTap,
                          onPointerDown: onPointerDown,
                          onPointerMove: onPointerMove,
                          onPointerUp: onPointerUp,
                          onPointerCancel: onPointerCancel,
                          buildDefectMarkersForPage: buildDefectMarkersForPage,
                          buildEquipmentMarkersForPage:
                              buildEquipmentMarkersForPage,
                          buildMarkerPopupForPage: buildMarkerPopupForPage,
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
        ),
        if (pageCount > 1)
          Positioned(
            right: 16,
            bottom: 16,
            child: Column(
              children: [
                _PageNavButton(
                  icon: Icons.keyboard_arrow_up,
                  onPressed: onPreviousPage,
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    StringsKo.pageIndicator(currentPage, pageCount),
                    style: theme.textTheme.labelMedium,
                  ),
                ),
                const SizedBox(height: 8),
                _PageNavButton(
                  icon: Icons.keyboard_arrow_down,
                  onPressed: onNextPage,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PdfPageLayer extends StatelessWidget {
  const _PdfPageLayer({
    required this.pageSize,
    required this.pageNumber,
    required this.imageProvider,
    required this.onPdfTap,
    required this.onPointerDown,
    required this.onPointerMove,
    required this.onPointerUp,
    required this.onPointerCancel,
    required this.buildDefectMarkersForPage,
    required this.buildEquipmentMarkersForPage,
    required this.buildMarkerPopupForPage,
  });

  final Size pageSize;
  final int pageNumber;
  final ImageProvider imageProvider;
  final void Function(TapUpDetails details, Size pageSize, int pageNumber)
      onPdfTap;
  final ValueChanged<Offset> onPointerDown;
  final ValueChanged<Offset> onPointerMove;
  final VoidCallback onPointerUp;
  final VoidCallback onPointerCancel;
  final List<Widget> Function(Size pageSize, int pageNumber)
      buildDefectMarkersForPage;
  final List<Widget> Function(Size pageSize, int pageNumber)
      buildEquipmentMarkersForPage;
  final Widget Function(Size pageSize, int pageNumber) buildMarkerPopupForPage;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) => onPointerDown(event.localPosition),
      onPointerMove: (event) => onPointerMove(event.localPosition),
      onPointerUp: (_) => onPointerUp(),
      onPointerCancel: (_) => onPointerCancel(),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapUp: (details) => onPdfTap(details, pageSize, pageNumber),
        child: AspectRatio(
          aspectRatio: pageSize.width / pageSize.height,
          child: SizedBox(
            width: pageSize.width,
            height: pageSize.height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image(
                    image: imageProvider,
                    fit: BoxFit.contain,
                  ),
                ),
                ...buildDefectMarkersForPage(pageSize, pageNumber),
                ...buildEquipmentMarkersForPage(pageSize, pageNumber),
                buildMarkerPopupForPage(pageSize, pageNumber),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PageNavButton extends StatelessWidget {
  const _PageNavButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
      shape: const CircleBorder(),
      elevation: 4,
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
      ),
    );
  }
}
