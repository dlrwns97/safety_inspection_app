import 'package:safety_inspection_app/domain/drawing/repositories/drawing_repository.dart';
import 'package:safety_inspection_app/domain/site/repositories/site_repository.dart';
import 'package:safety_inspection_app/infrastructure/mappers/drawing_stroke_mapper.dart';
import 'package:safety_inspection_app/models/drawing/drawing_history_action_persisted.dart';
import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';
import 'package:safety_inspection_app/models/site.dart';

class PersistSiteDrawingUseCase {
  PersistSiteDrawingUseCase({
    required DrawingRepository drawingRepository,
    required SiteRepository siteRepository,
  }) : _drawingRepository = drawingRepository,
       _siteRepository = siteRepository;

  final DrawingRepository _drawingRepository;
  final SiteRepository _siteRepository;

  Future<Site> execute({
    required Site site,
    required Map<int, List<DrawingStroke>> strokesByPage,
  }) async {
    final flatList = strokesByPage.entries
        .expand((entry) => entry.value)
        .map((stroke) => stroke.deepCopy())
        .toList();

    await _drawingRepository.saveSiteDrawing(
      siteId: site.id,
      payloadJson: <String, dynamic>{
        'drawingStrokes': flatList.map(DrawingStrokeMapper.toJson).toList(),
      },
    );

    final updatedSite = site.copyWith(
      drawingStrokes: const <DrawingStroke>[],
      drawingUndoHistory: const <DrawingHistoryActionPersisted>[],
      drawingRedoHistory: const <DrawingHistoryActionPersisted>[],
    );

    final sites = await _siteRepository.loadSites();
    final existingIndex = sites.indexWhere((item) => item.id == updatedSite.id);
    final updatedSites = List<Site>.from(sites);
    if (existingIndex >= 0) {
      updatedSites[existingIndex] = updatedSite;
    } else {
      updatedSites.add(updatedSite);
    }
    await _siteRepository.saveSites(updatedSites);

    return updatedSite;
  }
}
