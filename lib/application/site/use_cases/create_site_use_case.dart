import 'package:safety_inspection_app/domain/site/repositories/site_repository.dart';
import 'package:safety_inspection_app/models/site.dart';

class CreateSiteUseCase {
  CreateSiteUseCase({required SiteRepository repository})
    : _repository = repository;

  final SiteRepository _repository;

  Future<List<Site>> execute({
    required List<Site> currentSites,
    required Site newSite,
  }) async {
    final updatedSites = [...currentSites, newSite];
    await _repository.saveSites(updatedSites);
    return updatedSites;
  }
}
