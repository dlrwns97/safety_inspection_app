import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safety_inspection_app/application/drawing/use_cases/load_site_drawing_use_case.dart';
import 'package:safety_inspection_app/application/drawing/use_cases/persist_site_drawing_use_case.dart';
import 'package:safety_inspection_app/application/drawing/use_cases/pdf_use_case_models.dart';
import 'package:safety_inspection_app/application/drawing/use_cases/replace_pdf_use_case.dart';
import 'package:safety_inspection_app/domain/drawing/repositories/drawing_repository.dart';
import 'package:safety_inspection_app/domain/site/repositories/site_repository.dart';
import 'package:safety_inspection_app/models/defect.dart';
import 'package:safety_inspection_app/models/defect_details.dart';
import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/equipment_marker.dart';
import 'package:safety_inspection_app/models/site.dart';
import 'package:safety_inspection_app/screens/drawing/flows/marker_presenters.dart';
import 'package:safety_inspection_app/screens/home/home_storage.dart';
import 'package:safety_inspection_app/screens/home/site_photo_orphan_scanner.dart';
import 'package:safety_inspection_app/utils/photo_path_ordering.dart';

Site _site({
  required String id,
  required String name,
  required DrawingType drawingType,
  bool isDeleted = false,
  DateTime? deletedAt,
}) {
  return Site(
    id: id,
    name: name,
    createdAt: DateTime(2026, 3, 3),
    drawingType: drawingType,
    isDeleted: isDeleted,
    deletedAt: deletedAt,
  );
}

EquipmentMarker _equipment({
  required String id,
  required EquipmentCategory category,
  String? tiltDirection,
}) {
  return EquipmentMarker(
    id: id,
    label: 'tmp',
    pageIndex: 1,
    category: category,
    normalizedX: 0.1,
    normalizedY: 0.1,
    tiltDirection: tiltDirection,
  );
}

Defect _defect({
  required String id,
  required String label,
  required int pageIndex,
  required DefectCategory category,
  required List<String> photoPaths,
}) {
  return Defect(
    id: id,
    label: label,
    pageIndex: pageIndex,
    category: category,
    normalizedX: 0.2,
    normalizedY: 0.2,
    details: DefectDetails(
      structuralMember: 'beam',
      crackType: 'general',
      widthMm: 0.1,
      lengthMm: 10,
      cause: 'test',
      photoPaths: photoPaths,
    ),
  );
}

DrawingStroke _stroke({
  required String id,
  required int page,
  StrokeToolKind kind = StrokeToolKind.pen,
}) {
  return DrawingStroke(
    id: id,
    pageNumber: page,
    style: StrokeStyle(kind: kind),
    pointsNorm: const <Offset>[Offset(0.1, 0.1), Offset(0.2, 0.2)],
  );
}

class _MemoryDrawingRepository implements DrawingRepository {
  final Map<String, DrawingPayloadJson> _payloadBySiteId =
      <String, DrawingPayloadJson>{};

  @override
  Future<DrawingPayloadJson?> loadSiteDrawing({required String siteId}) async {
    return _payloadBySiteId[siteId];
  }

  @override
  Future<void> saveSiteDrawing({
    required String siteId,
    required DrawingPayloadJson payloadJson,
  }) async {
    _payloadBySiteId[siteId] = Map<String, dynamic>.from(payloadJson);
  }

  @override
  Future<void> deleteSiteDrawing({required String siteId}) async {
    _payloadBySiteId.remove(siteId);
  }
}

class _MemorySiteRepository implements SiteRepository {
  _MemorySiteRepository(this._sites);

  List<Site> _sites;

  @override
  Future<List<Site>> loadSites() async => List<Site>.from(_sites);

  @override
  Future<void> saveSites(List<Site> sites) async {
    _sites = List<Site>.from(sites);
  }

  @override
  Future<void> deleteSiteById(String siteId) async {
    _sites = _sites.where((site) => site.id != siteId).toList();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('H-01/H-02/H-03 smoke', () {
    test('H-01 creates and reloads site metadata', () async {
      final homeStorage = HomeStorage();
      final site = _site(
        id: 's1',
        name: '현장 A',
        drawingType: DrawingType.blank,
      );
      await homeStorage.saveSites(<Site>[site]);

      final loaded = await homeStorage.loadSites();

      expect(loaded, hasLength(1));
      expect(loaded.first.id, 's1');
      expect(loaded.first.name, '현장 A');
      expect(loaded.first.drawingType, DrawingType.blank);
      expect(loaded.first.isDeleted, isFalse);
    });

    test('H-02 trash -> restore -> permanent delete flow', () async {
      final homeStorage = HomeStorage();
      final target = _site(
        id: 's1',
        name: '현장 A',
        drawingType: DrawingType.blank,
      );
      final keep = _site(id: 's2', name: '현장 B', drawingType: DrawingType.pdf);
      final initial = <Site>[target, keep];
      final deletedAt = DateTime(2026, 3, 3, 10, 0);

      final trashed = await homeStorage.moveSiteToTrash(
        initial,
        target,
        deletedAt,
      );
      final trashedTarget = trashed.firstWhere((site) => site.id == target.id);
      expect(trashedTarget.isDeleted, isTrue);
      expect(trashedTarget.deletedAt, deletedAt);

      final restored = await homeStorage.restoreSite(trashed, target);
      final restoredTarget = restored.firstWhere(
        (site) => site.id == target.id,
      );
      expect(restoredTarget.isDeleted, isFalse);
      expect(restoredTarget.deletedAt, isNull);

      final deleted = await homeStorage.permanentlyDeleteSite(restored, target);
      expect(deleted.map((site) => site.id), isNot(contains(target.id)));
      expect(deleted.map((site) => site.id), contains(keep.id));
    });

    test('H-03 restores persisted trash state after reload', () async {
      final homeStorage = HomeStorage();
      final target = _site(
        id: 's1',
        name: '현장 A',
        drawingType: DrawingType.blank,
        isDeleted: true,
        deletedAt: DateTime(2026, 3, 3, 11, 0),
      );
      await homeStorage.saveSites(<Site>[target]);

      final reloaded = await homeStorage.loadSites();
      expect(reloaded, hasLength(1));
      expect(reloaded.first.isDeleted, isTrue);
      expect(reloaded.first.deletedAt, isNotNull);
    });
  });

  group('D-05 smoke', () {
    test('D-05 equipment label rule keeps prefix+sequence order', () {
      final f1 = _equipment(id: 'f1', category: EquipmentCategory.equipment2);
      final f2 = _equipment(id: 'f2', category: EquipmentCategory.equipment2);
      final all = <EquipmentMarker>[f1, f2];

      expect(equipmentDisplayLabel(f1, all), 'F1');
      expect(equipmentDisplayLabel(f2, all), 'F2');
    });
  });

  group('P-02 smoke', () {
    test('P-02 deduplicates mixed legacy path formats', () {
      final result = insertPreservingReferenceOrder(
        photoPaths: <String>['C:\\a\\2.jpg'],
        restoreKey: '/a/2.jpg',
        normalizeKey: photoReferenceKey,
      );

      expect(result, <String>['C:\\a\\2.jpg']);
    });
  });

  group('D-10/P-03 smoke', () {
    test(
      'D-10 PDF replace -> page move -> marker create -> save -> reload restore',
      () async {
        final initialSite = _site(
          id: 's-pdf-1',
          name: 'site-pdf',
          drawingType: DrawingType.pdf,
        );
        final siteRepository = _MemorySiteRepository(<Site>[initialSite]);
        final drawingRepository = _MemoryDrawingRepository();
        final replaceUseCase = ReplacePdfUseCase(
          pickPdfFile: () async => const PickedPdfFile(
            name: 'updated-plan.pdf',
            path: '/tmp/updated-plan.pdf',
            bytes: null,
          ),
        );
        final persistUseCase = PersistSiteDrawingUseCase(
          drawingRepository: drawingRepository,
          siteRepository: siteRepository,
        );
        final loadUseCase = LoadSiteDrawingUseCase(
          drawingRepository: drawingRepository,
        );

        final replaceResult = await replaceUseCase.execute(site: initialSite);
        final replacedSite = replaceResult!.updatedSite!;
        final markerOnPage2 = _defect(
          id: 'd-p2-1',
          label: 'C1',
          pageIndex: 2,
          category: DefectCategory.generalCrack,
          photoPaths: const <String>[],
        );
        final markerCreatedSite = replacedSite.copyWith(
          defects: <Defect>[markerOnPage2],
        );

        await persistUseCase.execute(
          site: markerCreatedSite,
          strokesByPage: <int, List<DrawingStroke>>{
            2: <DrawingStroke>[
              _stroke(id: 'stroke-p2-1', page: 2, kind: StrokeToolKind.pen),
            ],
          },
        );

        final reloadedSites = await siteRepository.loadSites();
        final restoredSite = reloadedSites.firstWhere(
          (site) => site.id == markerCreatedSite.id,
        );
        final restoredDrawing = await loadUseCase.execute(
          siteId: markerCreatedSite.id,
        );

        expect(restoredSite.pdfPath, '/tmp/updated-plan.pdf');
        expect(restoredSite.pdfName, 'updated-plan.pdf');
        expect(restoredSite.defects, hasLength(1));
        expect(restoredSite.defects.first.pageIndex, 2);
        expect(restoredDrawing[2], isNotNull);
        expect(restoredDrawing[2]!.map((stroke) => stroke.id), <String>[
          'stroke-p2-1',
        ]);
      },
    );

    test('P-03 orphan photo scan -> restore -> cleanup flow', () async {
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      final tempRoot = await Directory.systemTemp.createTemp('orphan-smoke-');
      final docsPath = tempRoot.path;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'getApplicationDocumentsDirectory') {
              return docsPath;
            }
            return null;
          });

      try {
        final keepPath = '$docsPath/sites/s-orphan/defects/d-1/keep.jpg';
        final orphanPath = '$docsPath/sites/s-orphan/defects/d-2/orphan.jpg';
        final nonImagePath = '$docsPath/sites/s-orphan/defects/d-2/readme.txt';

        await File(keepPath).create(recursive: true);
        await File(keepPath).writeAsString('keep');
        await File(orphanPath).create(recursive: true);
        await File(orphanPath).writeAsString('orphan');
        await File(nonImagePath).create(recursive: true);
        await File(nonImagePath).writeAsString('ignore');

        final siteWithoutRestore =
            _site(
              id: 's-orphan',
              name: 'site-orphan',
              drawingType: DrawingType.blank,
            ).copyWith(
              defects: <Defect>[
                _defect(
                  id: 'd-1',
                  label: '1',
                  pageIndex: 1,
                  category: DefectCategory.waterLeakage,
                  photoPaths: <String>[keepPath],
                ),
              ],
            );

        final firstScan = await scanOrphanDefectPhotos(
          siteId: 's-orphan',
          site: siteWithoutRestore,
        );
        expect(firstScan.totalCount, 1);
        expect(
          firstScan.orphanFiles.map((entity) => photoReferenceKey(entity.path)),
          <String>[photoReferenceKey(orphanPath)],
        );

        final restoredPhotoPaths = insertPreservingReferenceOrder(
          photoPaths: <String>[keepPath],
          restoreKey: orphanPath,
          normalizeKey: photoReferenceKey,
        );
        final siteAfterRestore = siteWithoutRestore.copyWith(
          defects: <Defect>[
            _defect(
              id: 'd-1',
              label: '1',
              pageIndex: 1,
              category: DefectCategory.waterLeakage,
              photoPaths: restoredPhotoPaths,
            ),
          ],
        );
        final secondScan = await scanOrphanDefectPhotos(
          siteId: 's-orphan',
          site: siteAfterRestore,
        );
        expect(secondScan.totalCount, 0);

        await File(orphanPath).delete();
        final thirdScan = await scanOrphanDefectPhotos(
          siteId: 's-orphan',
          site: siteWithoutRestore,
        );
        expect(thirdScan.totalCount, 0);
      } finally {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
        await tempRoot.delete(recursive: true);
      }
    });
  });
}
