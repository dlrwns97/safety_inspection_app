import 'dart:ui';

/// PDF page-size cache persistence boundary.
abstract interface class PdfPageSizeCacheRepository {
  Future<Map<int, Size>> loadPageSizes({required String cacheKey});

  Future<void> savePageSizes({
    required String cacheKey,
    required Map<int, Size> pageSizes,
  });
}
