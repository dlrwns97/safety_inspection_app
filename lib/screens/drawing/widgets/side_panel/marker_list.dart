import 'package:flutter/material.dart';

class MarkerList<T> extends StatelessWidget {
  const MarkerList({
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
  final String Function(T item) titleBuilder;
  final String? Function(T item) subtitleBuilder;

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
          onTap: () => onTap(item),
        );
      },
    );
  }
}
