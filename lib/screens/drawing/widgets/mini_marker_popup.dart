import 'package:flutter/material.dart';

class MiniMarkerPopup extends StatelessWidget {
  const MiniMarkerPopup({
    super.key,
    required this.left,
    required this.top,
    required this.lines,
  });

  static const double maxWidth = 220.0;
  static const double margin = 8.0;
  static const double lineHeight = 18.0;
  static const double verticalPadding = 12.0;

  final double left;
  final double top;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: verticalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: lines
                  .map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        line,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}
