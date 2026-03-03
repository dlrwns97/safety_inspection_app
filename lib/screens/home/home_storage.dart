import 'package:safety_inspection_app/domain/site/repositories/site_repository.dart';
import 'package:safety_inspection_app/infrastructure/persistence/shared_prefs/site_prefs_repository.dart';
import 'package:safety_inspection_app/models/site.dart';

class HomeStorage {
  HomeStorage({SiteRepository? repository})
    : _repository = repository ?? SitePrefsRepository();

  final SiteRepository _repository;

  Future<List<Site>> loadSites() async {
    return _repository.loadSites();
  }

  Future<void> saveSites(List<Site> sites) async {
    await _repository.saveSites(sites);
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
    final updatedSites = sites
        .map(
          (existing) => existing.id == site.id
              ? existing.copyWith(isDeleted: true, deletedAt: deletedAt)
              : existing,
        )
        .toList();
    await saveSites(updatedSites);
    return updatedSites;
  }

  Future<List<Site>> restoreSite(List<Site> sites, Site site) async {
    final updatedSites = sites
        .map(
          (existing) => existing.id == site.id
              ? existing.copyWith(isDeleted: false, deletedAt: null)
              : existing,
        )
        .toList();
    await saveSites(updatedSites);
    return updatedSites;
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
