import 'package:flutter/material.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/side_panel/marker_list.dart';

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
    return MarkerList<T>(
      items: items,
      emptyLabel: emptyLabel,
      onTap: onTap,
      titleBuilder: titleBuilder,
      subtitleBuilder: subtitleBuilder,
    );
  }
}
