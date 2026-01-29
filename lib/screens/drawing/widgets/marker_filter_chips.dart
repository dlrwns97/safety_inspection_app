import 'package:flutter/material.dart';

class MarkerFilterChips<T> extends StatelessWidget {
  const MarkerFilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.labelBuilder,
    required this.onSelected,
  });

  final List<T> options;
  final T selected;
  final String Function(T item) labelBuilder;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: options
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  selected: item == selected,
                  label: Text(labelBuilder(item)),
                  labelStyle: theme.textTheme.labelLarge,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => onSelected(item),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
