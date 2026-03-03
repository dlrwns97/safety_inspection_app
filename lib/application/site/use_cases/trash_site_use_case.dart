import 'package:safety_inspection_app/domain/site/repositories/site_repository.dart';
import 'package:safety_inspection_app/models/site.dart';

class TrashSiteUseCase {
  TrashSiteUseCase({required SiteRepository repository})
    : _repository = repository;

  final SiteRepository _repository;

  Future<List<Site>> execute({
    required List<Site> currentSites,
    required Site targetSite,
    required DateTime deletedAt,
  }) async {
    final updatedSites = currentSites
        .map(
          (site) => site.id == targetSite.id
              ? site.copyWith(isDeleted: true, deletedAt: deletedAt)
              : site,
        )
        .toList();
    await _repository.saveSites(updatedSites);
    return updatedSites;
  }
}
