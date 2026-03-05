import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:safety_inspection_app/application/drawing/use_cases/load_pdf_page_size_cache_use_case.dart';
import 'package:safety_inspection_app/application/drawing/use_cases/persist_pdf_page_size_cache_use_case.dart';
import 'package:safety_inspection_app/domain/drawing/repositories/pdf_page_size_cache_repository.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/site.dart';

class _FakePdfPageSizeCacheRepository implements PdfPageSizeCacheRepository {
  String? loadedKey;
  String? savedKey;
  Map<int, Size> loadedPageSizes = <int, Size>{};
  Map<int, Size>? savedPageSizes;

  @override
  Future<Map<int, Size>> loadPageSizes({required String cacheKey}) async {
    loadedKey = cacheKey;
    return Map<int, Size>.from(loadedPageSizes);
  }

  @override
  Future<void> savePageSizes({
    required String cacheKey,
    required Map<int, Size> pageSizes,
  }) async {
    savedKey = cacheKey;
    savedPageSizes = Map<int, Size>.from(pageSizes);
  }
}

Site _site({String? path}) {
  return Site(
    id: 's1',
    name: 'Site A',
    createdAt: DateTime(2026, 3, 5),
    drawingType: DrawingType.pdf,
    pdfPath: path,
    pdfName: 'drawing.pdf',
  );
}

void main() {
  group('PdfPageSize cache use cases', () {
    test('Load use case returns empty when PDF path is missing', () async {
      final repository = _FakePdfPageSizeCacheRepository();
      final useCase = LoadPdfPageSizeCacheUseCase(repository: repository);

      final loaded = await useCase.execute(site: _site(path: null));

      expect(loaded, isEmpty);
      expect(repository.loadedKey, isNull);
    });

    test('Load use case filters out invalid page sizes', () async {
      final repository = _FakePdfPageSizeCacheRepository()
        ..loadedPageSizes = <int, Size>{
          1: const Size(1200, 900),
          2: const Size(120, 800),
          3: const Size(900, 150),
        };
      final useCase = LoadPdfPageSizeCacheUseCase(
        repository: repository,
        minValidPageSide: 200.0,
      );

      final loaded = await useCase.execute(site: _site(path: '/tmp/a.pdf'));

      expect(loaded.keys, <int>[1]);
      expect(loaded[1], const Size(1200, 900));
      expect(
        repository.loadedKey,
        startsWith('drawing_pdf_page_sizes_cache_v1:'),
      );
    });

    test('Persist use case skips save when PDF path is missing', () async {
      final repository = _FakePdfPageSizeCacheRepository();
      final useCase = PersistPdfPageSizeCacheUseCase(repository: repository);

      await useCase.execute(
        site: _site(path: null),
        pageSizes: <int, Size>{1: const Size(1000, 800)},
      );

      expect(repository.savedKey, isNull);
      expect(repository.savedPageSizes, isNull);
    });

    test('Persist use case saves only valid page sizes', () async {
      final repository = _FakePdfPageSizeCacheRepository();
      final useCase = PersistPdfPageSizeCacheUseCase(
        repository: repository,
        minValidPageSide: 200.0,
      );

      await useCase.execute(
        site: _site(path: '/tmp/a.pdf'),
        pageSizes: <int, Size>{
          1: const Size(1400, 1000),
          2: const Size(100, 1000),
        },
      );

      expect(
        repository.savedKey,
        startsWith('drawing_pdf_page_sizes_cache_v1:'),
      );
      expect(repository.savedPageSizes, isNotNull);
      expect(repository.savedPageSizes!.keys, <int>[1]);
      expect(repository.savedPageSizes![1], const Size(1400, 1000));
    });
  });
}
