import 'package:flutter/material.dart';

class MarkerSidePanelListItemTile<T> extends StatelessWidget {
  const MarkerSidePanelListItemTile({
    super.key,
    required this.item,
    required this.titleBuilder,
    required this.subtitleBuilder,
    required this.onTap,
  });

  final T item;
  final String Function(T item) titleBuilder;
  final String? Function(T item) subtitleBuilder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = subtitleBuilder(item);
    return ListTile(
      title: Text(
        titleBuilder(item),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      onTap: onTap,
    );
  }
}
