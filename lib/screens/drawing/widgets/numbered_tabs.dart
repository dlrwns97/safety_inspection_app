import 'package:flutter/material.dart';

class NumberedTabs<T> extends StatelessWidget {
  const NumberedTabs({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
  });

  final List<T> items;
  final T? selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = item == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('${index + 1}'),
              selected: isSelected,
              onSelected: (_) => onSelected(item),
            ),
          );
        }),
      ),
    );
  }
}
