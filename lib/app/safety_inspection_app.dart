import 'package:flutter/material.dart';
import 'package:safety_inspection_app/screens/home_screen.dart';

class SafetyInspectionApp extends StatelessWidget {
  const SafetyInspectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3A6EA5)),
      useMaterial3: true,
    );
    return MaterialApp(
      title: 'Site Safety Inspection',
      theme: theme,
      home: const HomeScreen(),
    );
  }
}
