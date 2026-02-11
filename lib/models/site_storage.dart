import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'site.dart';

class SiteStorage {
  static const _key = 'inspection_sites';
  static const List<String> _legacyDrawingKeyPrefixes = <String>[
    'drawing_',
    'undo_',
    'redo_',
  ];
  static const List<String> _legacyDrawingKeys = <String>[
    'drawing_json',
    'undo_redo_json',
    'site_json',
  ];

  static Future<List<Site>> loadSites() async {
    final prefs = await SharedPreferences.getInstance();
    await _cleanupLegacyDrawingPrefs(prefs);

    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => Site.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveSites(List<Site> sites) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      sites.map((site) => _siteMetadataOnlyJson(site)).toList(),
    );
    await prefs.setString(_key, encoded);
  }

  static Map<String, dynamic> _siteMetadataOnlyJson(Site site) {
    final siteJson = site.toJson();
    siteJson
      ..remove('drawingStrokes')
      ..remove('drawingUndoHistory')
      ..remove('drawingRedoHistory');
    return siteJson;
  }

  static Future<void> _cleanupLegacyDrawingPrefs(SharedPreferences prefs) async {
    final keysToRemove = <String>{..._legacyDrawingKeys};
    for (final key in prefs.getKeys()) {
      if (_legacyDrawingKeyPrefixes.any((prefix) => key.startsWith(prefix))) {
        keysToRemove.add(key);
      }
    }

    for (final key in keysToRemove) {
      if (prefs.containsKey(key)) {
        await prefs.remove(key);
      }
    }
  }
}
