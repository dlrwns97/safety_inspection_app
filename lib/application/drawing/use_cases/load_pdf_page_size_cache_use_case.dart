import 'dart:ui';

import 'package:safety_inspection_app/application/drawing/use_cases/pdf_page_size_cache_key.dart';
import 'package:safety_inspection_app/domain/drawing/repositories/pdf_page_size_cache_repository.dart';
import 'package:safety_inspection_app/models/site.dart';

class LoadPdfPageSizeCacheUseCase {
  LoadPdfPageSizeCacheUseCase({
    required PdfPageSizeCacheRepository repository,
    this.minValidPageSide = 200.0,
  }) : _repository = repository;

  final PdfPageSizeCacheRepository _repository;
  final double minValidPageSide;

  Future<Map<int, Size>> execute({required Site site}) async {
    final path = site.pdfPath;
    if (path == null || path.isEmpty) {
      return <int, Size>{};
    }
    final loaded = await _repository.loadPageSizes(
      cacheKey: buildPdfPageSizeCacheKey(site),
    );
    if (loaded.isEmpty) {
      return <int, Size>{};
    }

    final filtered = <int, Size>{};
    loaded.forEach((page, size) {
      if (size.width < minValidPageSide || size.height < minValidPageSide) {
        return;
      }
      filtered[page] = size;
    });
    return filtered;
  }
}
