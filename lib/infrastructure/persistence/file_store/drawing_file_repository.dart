import 'package:safety_inspection_app/domain/drawing/repositories/drawing_repository.dart';
import 'package:safety_inspection_app/screens/drawing/persistence/drawing_persistence_store.dart';

class DrawingFileRepository implements DrawingRepository {
  DrawingFileRepository({DrawingPersistenceStore? store})
    : _store = store ?? DrawingPersistenceStore();

  final DrawingPersistenceStore _store;

  @override
  Future<DrawingPayloadJson?> loadSiteDrawing({required String siteId}) {
    return _store.loadSiteDrawing(siteId: siteId);
  }

  @override
  Future<void> saveSiteDrawing({
    required String siteId,
    required DrawingPayloadJson payloadJson,
  }) {
    return _store.saveSiteDrawing(siteId: siteId, payloadJson: payloadJson);
  }

  @override
  Future<void> deleteSiteDrawing({required String siteId}) {
    return _store.deleteSiteDrawing(siteId: siteId);
  }
}
