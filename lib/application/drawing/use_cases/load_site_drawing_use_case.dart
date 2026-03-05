import 'package:safety_inspection_app/domain/drawing/repositories/drawing_repository.dart';
import 'package:safety_inspection_app/infrastructure/mappers/drawing_stroke_mapper.dart';
import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';

class LoadSiteDrawingUseCase {
  LoadSiteDrawingUseCase({required DrawingRepository drawingRepository})
    : _drawingRepository = drawingRepository;

  final DrawingRepository _drawingRepository;

  Future<Map<int, List<DrawingStroke>>> execute({
    required String siteId,
  }) async {
    final payload = await _drawingRepository.loadSiteDrawing(siteId: siteId);
    final loaded = <int, List<DrawingStroke>>{};
    final drawingStrokesJson = payload?['drawingStrokes'];
    if (drawingStrokesJson is! List) {
      return loaded;
    }
    for (final rawStroke in drawingStrokesJson.whereType<Map>()) {
      final stroke = DrawingStrokeMapper.fromJson(
        rawStroke.cast<String, dynamic>(),
      );
      loaded
          .putIfAbsent(stroke.pageNumber, () => <DrawingStroke>[])
          .add(stroke);
    }
    return loaded;
  }
}
