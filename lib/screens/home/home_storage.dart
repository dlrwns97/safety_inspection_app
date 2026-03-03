import 'package:safety_inspection_app/application/site/use_cases/create_site_use_case.dart';
import 'package:safety_inspection_app/application/site/use_cases/load_sites_use_case.dart';
import 'package:safety_inspection_app/application/site/use_cases/restore_site_use_case.dart';
import 'package:safety_inspection_app/application/site/use_cases/trash_site_use_case.dart';
import 'package:safety_inspection_app/domain/site/repositories/site_repository.dart';
import 'package:safety_inspection_app/infrastructure/persistence/shared_prefs/site_prefs_repository.dart';
import 'package:safety_inspection_app/models/site.dart';

class HomeStorage {
  HomeStorage({SiteRepository? repository})
    : _repository = repository ?? SitePrefsRepository() {
    _loadSitesUseCase = LoadSitesUseCase(repository: _repository);
    _createSiteUseCase = CreateSiteUseCase(repository: _repository);
    _trashSiteUseCase = TrashSiteUseCase(repository: _repository);
    _restoreSiteUseCase = RestoreSiteUseCase(repository: _repository);
  }

  final SiteRepository _repository;
  late final LoadSitesUseCase _loadSitesUseCase;
  late final CreateSiteUseCase _createSiteUseCase;
  late final TrashSiteUseCase _trashSiteUseCase;
  late final RestoreSiteUseCase _restoreSiteUseCase;

  Future<List<Site>> loadSites() async {
    return _loadSitesUseCase.execute();
  }

  Future<void> saveSites(List<Site> sites) async {
    await _repository.saveSites(sites);
  }

  Future<List<Site>> createSite(List<Site> sites, Site site) async {
    return _createSiteUseCase.execute(currentSites: sites, newSite: site);
  }

  Future<List<Site>> updateSite(List<Site> sites, Site site) async {
    final updatedSites = sites
        .map((existing) => existing.id == site.id ? site : existing)
        .toList();
    await saveSites(updatedSites);
    return updatedSites;
  }

  Future<List<Site>> moveSiteToTrash(
    List<Site> sites,
    Site site,
    DateTime deletedAt,
  ) async {
    return _trashSiteUseCase.execute(
      currentSites: sites,
      targetSite: site,
      deletedAt: deletedAt,
    );
  }

  Future<List<Site>> restoreSite(List<Site> sites, Site site) async {
    return _restoreSiteUseCase.execute(currentSites: sites, targetSite: site);
  }

  Future<List<Site>> permanentlyDeleteSite(List<Site> sites, Site site) async {
    final updatedSites = sites
        .where((existing) => existing.id != site.id)
        .toList();
    await saveSites(updatedSites);
    return updatedSites;
  }

  Future<List<Site>> emptyTrash(List<Site> sites) async {
    final updatedSites = sites.where((site) => !site.isDeleted).toList();
    await saveSites(updatedSites);
    return updatedSites;
  }
}
