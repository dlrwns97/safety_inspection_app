import 'package:flutter/material.dart';
import 'package:safety_inspection_app/constants/strings_ko.dart';

class PdfViewLayer extends StatelessWidget {
  const PdfViewLayer({
    super.key,
    required this.pdfViewer,
    required this.currentPage,
    required this.pageCount,
    required this.onPrevPage,
    required this.onNextPage,
    this.canPrev,
    this.canNext,
  });

  final Widget pdfViewer;
  final int currentPage;
  final int pageCount;
  final VoidCallback onPrevPage;
  final VoidCallback onNextPage;
  final bool? canPrev;
  final bool? canNext;

  @override
  Widget build(BuildContext context) {
    final canPrevPage = canPrev ?? currentPage > 1;
    final canNextPage = canNext ?? currentPage < pageCount;

    return Stack(
      children: [
        Positioned.fill(child: pdfViewer),
        if (pageCount > 1)
          Positioned(
            right: 16,
            bottom: 16,
            child: Column(
              children: [
                _PageNavButton(
                  icon: Icons.keyboard_arrow_up,
                  onPressed: canPrevPage ? onPrevPage : null,
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.9),
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
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                const SizedBox(height: 8),
                _PageNavButton(
                  icon: Icons.keyboard_arrow_down,
                  onPressed: canNextPage ? onNextPage : null,
                ),
              ],
            ),
          ),
      ],
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
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      elevation: 4,
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
      ),
    );
  }
}
