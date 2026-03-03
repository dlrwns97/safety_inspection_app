import 'package:safety_inspection_app/domain/site/repositories/site_repository.dart';
import 'package:safety_inspection_app/models/site.dart';

class LoadSitesUseCase {
  LoadSitesUseCase({required SiteRepository repository})
    : _repository = repository;

  final SiteRepository _repository;

  Future<List<Site>> execute() {
    return _repository.loadSites();
  }
}
