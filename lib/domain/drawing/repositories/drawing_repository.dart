typedef DrawingPayloadJson = Map<String, dynamic>;

/// Drawing snapshot persistence boundary.
abstract interface class DrawingRepository {
  Future<DrawingPayloadJson?> loadSiteDrawing({required String siteId});

  Future<void> saveSiteDrawing({
    required String siteId,
    required DrawingPayloadJson payloadJson,
  });

  Future<void> deleteSiteDrawing({required String siteId});
}
