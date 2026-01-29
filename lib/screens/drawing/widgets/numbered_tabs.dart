import 'package:flutter/material.dart';

class NumberedTabs<T> extends StatelessWidget {
  const NumberedTabs({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
    this.labels,
    this.labelBuilder,
    this.onLongPress,
  });

  final List<T> items;
  final T? selected;
  final ValueChanged<T> onSelected;
  final List<String>? labels;
  final String Function(T item)? labelBuilder;
  final ValueChanged<T>? onLongPress;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = item == selected;
          final label = labelBuilder != null
              ? labelBuilder!(item)
              : labels != null && index < labels!.length
                  ? labels![index]
                  : '${index + 1}';
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onLongPress:
                  onLongPress == null ? null : () => onLongPress!(item),
              child: ChoiceChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (_) => onSelected(item),
              ),
            ),
          );
        }),
      ),
    );
  }
}
