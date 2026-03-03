import 'package:safety_inspection_app/models/site.dart';

/// Site metadata persistence boundary.
abstract interface class SiteRepository {
  Future<List<Site>> loadSites();

  Future<void> saveSites(List<Site> sites);

  Future<void> deleteSiteById(String siteId);
}
