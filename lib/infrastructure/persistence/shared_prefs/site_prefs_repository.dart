import 'package:safety_inspection_app/domain/site/repositories/site_repository.dart';
import 'package:safety_inspection_app/models/site.dart';
import 'package:safety_inspection_app/models/site_storage.dart';

class SitePrefsRepository implements SiteRepository {
  @override
  Future<List<Site>> loadSites() {
    return SiteStorage.loadSites();
  }

  @override
  Future<void> saveSites(List<Site> sites) {
    return SiteStorage.saveSites(sites);
  }

  @override
  Future<void> deleteSiteById(String siteId) async {
    final sites = await SiteStorage.loadSites();
    final filtered = sites.where((site) => site.id != siteId).toList();
    await SiteStorage.saveSites(filtered);
  }
}
