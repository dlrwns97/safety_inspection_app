import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:safety_inspection_app/models/site_models.dart';

class SiteStorage {
  static const _key = 'inspection_sites';

  static Future<List<Site>> loadSites() async {
    final prefs = await SharedPreferences.getInstance();
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
    final encoded = jsonEncode(sites.map((site) => site.toJson()).toList());
    await prefs.setString(_key, encoded);
  }
}
