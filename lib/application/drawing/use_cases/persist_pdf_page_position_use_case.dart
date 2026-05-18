import 'package:safety_inspection_app/domain/site/repositories/site_repository.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/site.dart';

class PersistPdfPagePositionUseCase {
  PersistPdfPagePositionUseCase({required SiteRepository siteRepository})
    : _siteRepository = siteRepository;

  final SiteRepository _siteRepository;

  Future<Site> execute({required Site site, required int page}) async {
    if (site.drawingType != DrawingType.pdf) {
      return site;
    }

    final safePage = page <= 0 ? 1 : page;
    if (site.lastViewedPdfPage == safePage) {
      return site;
    }

    final updatedSite = site.copyWith(lastViewedPdfPage: safePage);
    final sites = await _siteRepository.loadSites();
    final index = sites.indexWhere((item) => item.id == updatedSite.id);
    final updatedSites = List<Site>.from(sites);

    if (index >= 0) {
      updatedSites[index] = updatedSite;
    } else {
      updatedSites.add(updatedSite);
    }

    await _siteRepository.saveSites(updatedSites);
    return updatedSite;
  }
}
