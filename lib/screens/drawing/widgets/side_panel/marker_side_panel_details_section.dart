import 'package:flutter/material.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/side_panel/marker_side_panel_action_bar.dart';

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
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: MarkerSidePanelActionBar(
            hasSelection: hasSelection,
            onEditPressed: onEditPressed,
            onMovePressed: onMovePressed,
            onDeletePressed: onDeletePressed,
          ),
        ),
      ],
    );
  }
}
