import 'package:flutter/material.dart';

class DrawingSidePanelShell extends StatelessWidget {
  const DrawingSidePanelShell({
    super.key,
    required this.drawingContent,
    required this.panelWidth,
    required this.isCollapsed,
    required this.panelContent,
    required this.toggleButton,
  });

  final Widget drawingContent;
  final double panelWidth;
  final bool isCollapsed;
  final Widget panelContent;
  final Widget toggleButton;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Row(
          children: [
            Expanded(child: drawingContent),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: isCollapsed ? 0 : panelWidth,
              child: isCollapsed ? null : panelContent,
            ),
          ],
        ),
        Positioned(
          right: isCollapsed ? -16 : panelWidth - 16,
          top: 0,
          bottom: 0,
          child: Center(child: toggleButton),
        ),
      ],
    );
  }
}
