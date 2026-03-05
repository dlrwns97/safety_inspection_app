import 'package:safety_inspection_app/models/site.dart';

String buildPdfPageSizeCacheKey(Site site) {
  final path = site.pdfPath ?? '';
  return 'drawing_pdf_page_sizes_cache_v1:${path.hashCode}';
}
