import 'dart:convert';
import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:safety_inspection_app/domain/drawing/repositories/pdf_page_size_cache_repository.dart';

class SharedPrefsPdfPageSizeCacheRepository
    implements PdfPageSizeCacheRepository {
  @override
  Future<Map<int, Size>> loadPageSizes({required String cacheKey}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(cacheKey);
    if (raw == null || raw.isEmpty) {
      return <int, Size>{};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return <int, Size>{};
      }

      final restored = <int, Size>{};
      for (final entry in decoded.entries) {
        final page = int.tryParse(entry.key);
        final value = entry.value;
        if (page == null || value is! Map) {
          continue;
        }
        final width = (value['w'] as num?)?.toDouble();
        final height = (value['h'] as num?)?.toDouble();
        if (width == null || height == null) {
          continue;
        }
        if (width <= 0 || height <= 0) {
          continue;
        }
        restored[page] = Size(width, height);
      }
      return restored;
    } catch (_) {
      return <int, Size>{};
    }
  }

  @override
  Future<void> savePageSizes({
    required String cacheKey,
    required Map<int, Size> pageSizes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, Map<String, double>>{};
    pageSizes.forEach((page, size) {
      if (size.width <= 0 || size.height <= 0) {
        return;
      }
      payload['$page'] = <String, double>{'w': size.width, 'h': size.height};
    });
    await prefs.setString(cacheKey, jsonEncode(payload));
  }
}
