import 'package:flutter/material.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/side_panel/marker_side_panel_list_item_tile.dart';

class MarkerSidePanelListSection<T> extends StatelessWidget {
  const MarkerSidePanelListSection({
    super.key,
    required this.items,
    required this.emptyLabel,
    required this.onTap,
    required this.titleBuilder,
    required this.subtitleBuilder,
  });

  final List<T> items;
  final String emptyLabel;
  final ValueChanged<T> onTap;
  final String Function(T) titleBuilder;
  final String? Function(T) subtitleBuilder;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(emptyLabel),
      );
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return MarkerSidePanelListItemTile<T>(
          item: item,
          titleBuilder: titleBuilder,
          subtitleBuilder: subtitleBuilder,
          onTap: () => onTap(item),
        );
      },
    );
  }
}
