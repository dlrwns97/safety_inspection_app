import 'package:flutter_test/flutter_test.dart';
import 'package:safety_inspection_app/application/drawing/use_cases/load_site_drawing_use_case.dart';
import 'package:safety_inspection_app/application/drawing/use_cases/persist_pdf_page_position_use_case.dart';
import 'package:safety_inspection_app/application/drawing/use_cases/persist_site_drawing_use_case.dart';
import 'package:safety_inspection_app/domain/drawing/repositories/drawing_repository.dart';
import 'package:safety_inspection_app/domain/site/repositories/site_repository.dart';
import 'package:safety_inspection_app/infrastructure/mappers/drawing_stroke_mapper.dart';
import 'package:safety_inspection_app/models/site_storage.dart';
import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/site.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeDrawingRepository implements DrawingRepository {
  DrawingPayloadJson? loadedPayload;
  String? savedSiteId;
  DrawingPayloadJson? savedPayload;

  @override
  Future<void> deleteSiteDrawing({required String siteId}) async {}

  @override
  Future<DrawingPayloadJson?> loadSiteDrawing({required String siteId}) async {
    return loadedPayload;
  }

  @override
  Future<void> saveSiteDrawing({
    required String siteId,
    required DrawingPayloadJson payloadJson,
  }) async {
    savedSiteId = siteId;
    savedPayload = payloadJson;
  }
}

class _FakeSiteRepository implements SiteRepository {
  List<Site> storedSites = <Site>[];
  List<Site>? savedSites;

  @override
  Future<void> deleteSiteById(String siteId) async {}

  @override
  Future<List<Site>> loadSites() async {
    return List<Site>.from(storedSites);
  }

  @override
  Future<void> saveSites(List<Site> sites) async {
    savedSites = List<Site>.from(sites);
    storedSites = List<Site>.from(sites);
  }
}

Site _site({required String id}) {
  return Site(
    id: id,
    name: '현장$id',
    createdAt: DateTime(2026, 3, 3),
    drawingType: DrawingType.blank,
  );
}

Site _pdfSite({required String id, int? lastViewedPdfPage}) {
  return Site(
    id: id,
    name: 'PDF site $id',
    createdAt: DateTime(2026, 3, 3),
    drawingType: DrawingType.pdf,
    pdfPath: '/tmp/$id.pdf',
    pdfName: '$id.pdf',
    lastViewedPdfPage: lastViewedPdfPage,
  );
}

DrawingStroke _stroke({required String id, required int page}) {
  return DrawingStroke(
    id: id,
    pageNumber: page,
    style: const StrokeStyle(),
    pointsNorm: const <Offset>[Offset(0.1, 0.2), Offset(0.3, 0.4)],
  );
}

void main() {
  group('Drawing persistence use cases', () {
    test('LoadSiteDrawingUseCase restores strokes by page', () async {
      final drawingRepository = _FakeDrawingRepository();
      final s1 = _stroke(id: 'a', page: 1);
      final s2 = _stroke(id: 'b', page: 2);
      drawingRepository.loadedPayload = <String, dynamic>{
        'drawingStrokes': <Map<String, dynamic>>[
          DrawingStrokeMapper.toJson(s1),
          DrawingStrokeMapper.toJson(s2),
        ],
      };
      final useCase = LoadSiteDrawingUseCase(
        drawingRepository: drawingRepository,
      );

      final loaded = await useCase.execute(siteId: 's1');

      expect(loaded.keys.toSet(), <int>{1, 2});
      expect(loaded[1], hasLength(1));
      expect(loaded[2], hasLength(1));
      expect(loaded[1]!.first.id, 'a');
      expect(loaded[2]!.first.id, 'b');
    });

    test(
      'LoadSiteDrawingUseCase returns empty when payload has no stroke list',
      () async {
        final drawingRepository = _FakeDrawingRepository()
          ..loadedPayload = <String, dynamic>{'drawingStrokes': 'invalid'};
        final useCase = LoadSiteDrawingUseCase(
          drawingRepository: drawingRepository,
        );

        final loaded = await useCase.execute(siteId: 's1');

        expect(loaded, isEmpty);
      },
    );

    test(
      'LoadSiteDrawingUseCase skips non-map entries in stroke list',
      () async {
        final drawingRepository = _FakeDrawingRepository();
        final s1 = _stroke(id: 'a', page: 1);
        drawingRepository.loadedPayload = <String, dynamic>{
          'drawingStrokes': <dynamic>[
            DrawingStrokeMapper.toJson(s1),
            'not-a-map',
            1,
          ],
        };
        final useCase = LoadSiteDrawingUseCase(
          drawingRepository: drawingRepository,
        );

        final loaded = await useCase.execute(siteId: 's1');

        expect(loaded.keys.toSet(), <int>{1});
        expect(loaded[1], hasLength(1));
        expect(loaded[1]!.first.id, 'a');
      },
    );

    test(
      'PersistSiteDrawingUseCase saves file payload and site metadata',
      () async {
        final drawingRepository = _FakeDrawingRepository();
        final siteRepository = _FakeSiteRepository()
          ..storedSites = <Site>[_site(id: 's1')];
        final useCase = PersistSiteDrawingUseCase(
          drawingRepository: drawingRepository,
          siteRepository: siteRepository,
        );
        final stroke = _stroke(id: 'a', page: 1);

        final updatedSite = await useCase.execute(
          site: _site(id: 's1'),
          strokesByPage: <int, List<DrawingStroke>>{
            1: <DrawingStroke>[stroke],
          },
        );

        expect(drawingRepository.savedSiteId, 's1');
        expect(drawingRepository.savedPayload, isNotNull);
        final savedList =
            drawingRepository.savedPayload!['drawingStrokes'] as List<dynamic>;
        expect(savedList, hasLength(1));

        expect(updatedSite.drawingStrokes, isEmpty);
        expect(updatedSite.drawingUndoHistory, isEmpty);
        expect(updatedSite.drawingRedoHistory, isEmpty);

        expect(siteRepository.savedSites, isNotNull);
        expect(siteRepository.savedSites, hasLength(1));
        expect(siteRepository.savedSites!.first.id, 's1');
      },
    );

    test(
      'PersistSiteDrawingUseCase appends site when repository has no match',
      () async {
        final drawingRepository = _FakeDrawingRepository();
        final siteRepository = _FakeSiteRepository()
          ..storedSites = <Site>[_site(id: 'existing')];
        final useCase = PersistSiteDrawingUseCase(
          drawingRepository: drawingRepository,
          siteRepository: siteRepository,
        );

        final updatedSite = await useCase.execute(
          site: _site(id: 'missing'),
          strokesByPage: <int, List<DrawingStroke>>{
            1: <DrawingStroke>[_stroke(id: 'a', page: 1)],
          },
        );

        expect(updatedSite.id, 'missing');
        expect(siteRepository.savedSites, isNotNull);
        expect(siteRepository.savedSites!.map((site) => site.id), <String>[
          'existing',
          'missing',
        ]);
      },
    );

    test(
      'PersistPdfPagePositionUseCase updates PDF last viewed page',
      () async {
        final siteRepository = _FakeSiteRepository()
          ..storedSites = <Site>[_pdfSite(id: 's1', lastViewedPdfPage: 1)];
        final useCase = PersistPdfPagePositionUseCase(
          siteRepository: siteRepository,
        );

        final updatedSite = await useCase.execute(
          site: _pdfSite(id: 's1', lastViewedPdfPage: 1),
          page: 8,
        );

        expect(updatedSite.lastViewedPdfPage, 8);
        expect(siteRepository.savedSites, isNotNull);
        expect(siteRepository.savedSites!.single.lastViewedPdfPage, 8);
      },
    );

    test('PersistPdfPagePositionUseCase ignores non-PDF sites', () async {
      final siteRepository = _FakeSiteRepository()
        ..storedSites = <Site>[_site(id: 's1')];
      final useCase = PersistPdfPagePositionUseCase(
        siteRepository: siteRepository,
      );

      final updatedSite = await useCase.execute(site: _site(id: 's1'), page: 8);

      expect(updatedSite.lastViewedPdfPage, isNull);
      expect(siteRepository.savedSites, isNull);
    });

    test('SiteStorage legacy cleanup keeps PDF page position key', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'inspection_pdf_last_page:s1': 8,
        'drawing_pdf_last_page:pdf:/tmp/s1.pdf': 7,
        'drawing_old': 'legacy',
      });

      await SiteStorage.loadSites();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('inspection_pdf_last_page:s1'), 8);
      expect(prefs.getInt('drawing_pdf_last_page:pdf:/tmp/s1.pdf'), isNull);
      expect(prefs.getString('drawing_old'), isNull);
    });
  });
}
