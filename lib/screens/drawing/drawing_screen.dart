import 'package:flutter/widgets.dart';

class DrawingScreen extends StatelessWidget {
  const DrawingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }

  Widget _buildMarkerPopupForSelection({
    required bool hasPopupLines,
    required List<String> lines,
  }) {
    final List<String> popupLines =
        hasPopupLines ? lines : const <String>[];

    return MiniMarkerPopup(lines: popupLines);
  }
}

class MiniMarkerPopup extends StatelessWidget {
  const MiniMarkerPopup({super.key, required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
