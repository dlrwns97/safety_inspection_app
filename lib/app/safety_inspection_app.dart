import 'package:flutter/material.dart';

import '../constants/strings_ko.dart';
import '../models/drawing_enums.dart';
import '../models/site.dart';
import '../screens/drawing/drawing_screen.dart';

class SafetyInspectionApp extends StatelessWidget {
  const SafetyInspectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3A6EA5)),
      useMaterial3: true,
    );

    final initialSite = Site(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: StringsKo.newSite,
      createdAt: DateTime.now(),
      drawingType: DrawingType.blank,
      visibleDefectCategoryNames: const [],
    );

    return MaterialApp(
      title: StringsKo.appTitle,
      theme: theme,
      home: DrawingScreen(
        site: initialSite,
        onSiteUpdated: (_) async {},
      ),
    );
  }
}
