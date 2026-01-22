import 'package:safety_inspection_app/models/site.dart';
import 'package:safety_inspection_app/models/site_storage.dart';

class HomeStorage {
  static Future<List<Site>> loadSites() async {
    return SiteStorage.loadSites();
  }

  static Future<void> saveSites(List<Site> sites) async {
    await SiteStorage.saveSites(sites);
  }

  static Future<List<Site>> updateSite(List<Site> sites, Site site) async {
    final updatedSites = sites
        .map((existing) => existing.id == site.id ? site : existing)
        .toList();
    await saveSites(updatedSites);
    return updatedSites;
  }

  static Future<List<Site>> moveSiteToTrash(
    List<Site> sites,
    Site site,
    DateTime deletedAt,
  ) async {
    final updatedSites = sites
        .map(
          (existing) =>
              existing.id == site.id
                  ? existing.copyWith(isDeleted: true, deletedAt: deletedAt)
                  : existing,
        )
        .toList();
    await saveSites(updatedSites);
    return updatedSites;
  }

  static Future<List<Site>> restoreSite(List<Site> sites, Site site) async {
    final updatedSites = sites
        .map(
          (existing) =>
              existing.id == site.id
                  ? existing.copyWith(isDeleted: false, deletedAt: null)
                  : existing,
        )
        .toList();
    await saveSites(updatedSites);
    return updatedSites;
  }

  static Future<List<Site>> permanentlyDeleteSite(
    List<Site> sites,
    Site site,
  ) async {
    final updatedSites =
        sites.where((existing) => existing.id != site.id).toList();
    await saveSites(updatedSites);
    return updatedSites;
  }

  static Future<List<Site>> emptyTrash(List<Site> sites) async {
    final updatedSites = sites.where((site) => !site.isDeleted).toList();
    await saveSites(updatedSites);
    return updatedSites;
  }
}
