import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

Map<String, dynamic> _encodeDrawingPayloadForSave(Map<String, dynamic> params) {
  final payload = params['payload'] as Map<String, dynamic>;
  final maxBytes = params['maxBytes'] as int;
  final encoded = jsonEncode(payload);
  final encodedBytes = utf8.encode(encoded).length;

  return <String, dynamic>{
    'encoded': encodedBytes > maxBytes ? null : encoded,
    'byteLength': encodedBytes,
  };
}

class DrawingPersistenceStore {
  static const int _maxSaveBytes = 5 * 1024 * 1024;
  static const int _maxLoadBytes = 20 * 1024 * 1024;

  Future<void> saveSiteDrawing({
    required String siteId,
    required Map<String, dynamic> payloadJson,
  }) async {
    try {
      final encodeResult = await compute(_encodeDrawingPayloadForSave, <String, dynamic>{
        'payload': payloadJson,
        'maxBytes': _maxSaveBytes,
      });
      final encoded = encodeResult['encoded'] as String?;
      final encodedBytes = encodeResult['byteLength'] as int;
      if (encoded == null) {
        debugPrint(
          'Skip drawing save for site=$siteId. payload bytes=$encodedBytes exceeds $_maxSaveBytes.',
        );
        return;
      }

      final file = await _drawingFileForSite(siteId);
      await file.writeAsString(encoded, flush: true);
    } catch (error) {
      debugPrint('Failed to save drawing payload for site=$siteId: $error');
    }
  }

  Future<Map<String, dynamic>?> loadSiteDrawing({required String siteId}) async {
    try {
      final file = await _drawingFileForSite(siteId);
      if (!await file.exists()) {
        return null;
      }

      final stat = await file.stat();
      if (stat.size > _maxLoadBytes) {
        debugPrint(
          'Delete oversized drawing file for site=$siteId. file bytes=${stat.size} exceeds $_maxLoadBytes.',
        );
        await file.delete();
        return null;
      }

      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        debugPrint('Invalid drawing payload for site=$siteId.');
        return null;
      }
      return decoded;
    } catch (error) {
      debugPrint('Failed to load drawing payload for site=$siteId: $error');
      return null;
    }
  }

  Future<void> deleteSiteDrawing({required String siteId}) async {
    final file = await _drawingFileForSite(siteId);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<File> _drawingFileForSite(String siteId) async {
    final baseDir = await getApplicationDocumentsDirectory();
    final sanitizedSiteId = siteId.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return File('${baseDir.path}/drawing_$sanitizedSiteId.json');
  }
}
