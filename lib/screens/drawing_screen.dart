import 'package:flutter/material.dart';

class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  void _handleTap(TapDownDetails details) {
    if (FocusManager.instance.primaryFocus?.hasFocus ?? false) {
      return;
    }
    // TODO: Implement defect placement logic.
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onTapDown: _handleTap,
      child: InteractiveViewer(
        child: Container(
          color: Colors.transparent,
        ),
      ),
    );
  }
}
