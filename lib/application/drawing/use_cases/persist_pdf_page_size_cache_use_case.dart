import 'dart:ui';

import 'package:safety_inspection_app/application/drawing/use_cases/pdf_page_size_cache_key.dart';
import 'package:safety_inspection_app/domain/drawing/repositories/pdf_page_size_cache_repository.dart';
import 'package:safety_inspection_app/models/site.dart';

class PersistPdfPageSizeCacheUseCase {
  PersistPdfPageSizeCacheUseCase({
    required PdfPageSizeCacheRepository repository,
    this.minValidPageSide = 200.0,
  }) : _repository = repository;

  final PdfPageSizeCacheRepository _repository;
  final double minValidPageSide;

  Future<void> execute({
    required Site site,
    required Map<int, Size> pageSizes,
  }) async {
    final path = site.pdfPath;
    if (path == null || path.isEmpty) {
      return;
    }

    final sanitized = <int, Size>{};
    pageSizes.forEach((page, size) {
      if (size.width < minValidPageSide || size.height < minValidPageSide) {
        return;
      }
      sanitized[page] = size;
    });

    await _repository.savePageSizes(
      cacheKey: buildPdfPageSizeCacheKey(site),
      pageSizes: sanitized,
    );
  }
}
