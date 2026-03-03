import 'package:flutter_test/flutter_test.dart';
import 'package:safety_inspection_app/application/site/use_cases/create_site_use_case.dart';
import 'package:safety_inspection_app/application/site/use_cases/load_sites_use_case.dart';
import 'package:safety_inspection_app/application/site/use_cases/restore_site_use_case.dart';
import 'package:safety_inspection_app/application/site/use_cases/trash_site_use_case.dart';
import 'package:safety_inspection_app/domain/site/repositories/site_repository.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/site.dart';

class _FakeSiteRepository implements SiteRepository {
  List<Site> storedSites = <Site>[];

  @override
  Future<void> deleteSiteById(String siteId) async {
    storedSites = storedSites.where((site) => site.id != siteId).toList();
  }

  @override
  Future<List<Site>> loadSites() async {
    return List<Site>.from(storedSites);
  }

  @override
  Future<void> saveSites(List<Site> sites) async {
    storedSites = List<Site>.from(sites);
  }
}

Site _site({required String id, bool isDeleted = false, DateTime? deletedAt}) {
  return Site(
    id: id,
    name: '현장$id',
    createdAt: DateTime(2026, 3, 3),
    drawingType: DrawingType.blank,
    isDeleted: isDeleted,
    deletedAt: deletedAt,
  );
}

void main() {
  group('Site use cases', () {
    test('LoadSitesUseCase loads repository data', () async {
      final repository = _FakeSiteRepository();
      repository.storedSites = <Site>[_site(id: 's1')];
      final useCase = LoadSitesUseCase(repository: repository);

      final loaded = await useCase.execute();

      expect(loaded, hasLength(1));
      expect(loaded.first.id, 's1');
    });

    test('CreateSiteUseCase appends and persists site', () async {
      final repository = _FakeSiteRepository();
      final existing = _site(id: 's1');
      repository.storedSites = <Site>[existing];
      final useCase = CreateSiteUseCase(repository: repository);
      final created = _site(id: 's2');

      final updated = await useCase.execute(
        currentSites: <Site>[existing],
        newSite: created,
      );

      expect(updated.map((site) => site.id), <String>['s1', 's2']);
      expect(repository.storedSites.map((site) => site.id), <String>[
        's1',
        's2',
      ]);
    });

    test('TrashSiteUseCase marks deletedAt and isDeleted', () async {
      final repository = _FakeSiteRepository();
      final target = _site(id: 's1');
      final keep = _site(id: 's2');
      final useCase = TrashSiteUseCase(repository: repository);
      final deletedAt = DateTime(2026, 3, 3, 10, 0);

      final updated = await useCase.execute(
        currentSites: <Site>[target, keep],
        targetSite: target,
        deletedAt: deletedAt,
      );

      final trashed = updated.firstWhere((site) => site.id == target.id);
      expect(trashed.isDeleted, isTrue);
      expect(trashed.deletedAt, deletedAt);
      expect(
        repository.storedSites
            .firstWhere((site) => site.id == target.id)
            .isDeleted,
        isTrue,
      );
    });

    test('RestoreSiteUseCase clears deleted markers', () async {
      final repository = _FakeSiteRepository();
      final target = _site(
        id: 's1',
        isDeleted: true,
        deletedAt: DateTime(2026, 3, 3, 11, 0),
      );
      final keep = _site(id: 's2');
      final useCase = RestoreSiteUseCase(repository: repository);

      final updated = await useCase.execute(
        currentSites: <Site>[target, keep],
        targetSite: target,
      );

      final restored = updated.firstWhere((site) => site.id == target.id);
      expect(restored.isDeleted, isFalse);
      expect(restored.deletedAt, isNull);
      expect(
        repository.storedSites
            .firstWhere((site) => site.id == target.id)
            .isDeleted,
        isFalse,
      );
    });
  });
}
