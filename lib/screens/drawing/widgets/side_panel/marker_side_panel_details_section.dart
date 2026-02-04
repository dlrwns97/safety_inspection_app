import 'package:flutter/material.dart';

class MarkerSidePanelDetailsSection extends StatelessWidget {
  const MarkerSidePanelDetailsSection({
    super.key,
    required this.detailWidgets,
    required this.hasSelection,
    required this.onEditPressed,
    required this.onMovePressed,
    required this.onDeletePressed,
  });

  final List<Widget> detailWidgets;
  final bool hasSelection;
  final VoidCallback onEditPressed;
  final VoidCallback onMovePressed;
  final VoidCallback onDeletePressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          child:
              hasSelection
                  ? ListView(
                    padding: const EdgeInsets.all(12),
                    children: detailWidgets,
                  )
                  : Center(
                    child: Text(
                      '선택된 마커 없음',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
        ),
        const Divider(height: 1),
        SafeArea(
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
        ),
      ],
    );
  }
}
