import 'package:flutter/material.dart';

class MarkerSidePanelActionBar extends StatelessWidget {
  const MarkerSidePanelActionBar({
    super.key,
    required this.hasSelection,
    required this.onEditPressed,
    required this.onMovePressed,
    required this.onDeletePressed,
  });

  final bool hasSelection;
  final VoidCallback onEditPressed;
  final VoidCallback onMovePressed;
  final VoidCallback onDeletePressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: hasSelection ? onEditPressed : null,
              child: const Text('수정'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: hasSelection ? onMovePressed : null,
              child: const Text('이동'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: hasSelection ? onDeletePressed : null,
              child: const Text('삭제'),
            ),
          ],
        ),
      ),
    );
  }
}
