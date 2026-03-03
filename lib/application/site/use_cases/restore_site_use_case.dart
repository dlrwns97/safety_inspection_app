import 'package:safety_inspection_app/domain/site/repositories/site_repository.dart';
import 'package:safety_inspection_app/models/site.dart';

class RestoreSiteUseCase {
  RestoreSiteUseCase({required SiteRepository repository})
    : _repository = repository;

  final SiteRepository _repository;

  Future<List<Site>> execute({
    required List<Site> currentSites,
    required Site targetSite,
  }) async {
    final updatedSites = currentSites
        .map(
          (site) => site.id == targetSite.id
              ? site.copyWith(isDeleted: false, deletedAt: null)
              : site,
        )
        .toList();
    await _repository.saveSites(updatedSites);
    return updatedSites;
  }
}
