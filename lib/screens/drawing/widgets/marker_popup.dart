import 'package:flutter/material.dart';
import 'package:safety_inspection_app/screens/drawing/utils/drawing_helpers.dart';

class MarkerPopup extends StatelessWidget {
  const MarkerPopup({
    super.key,
    required this.lines,
    required this.markerPosition,
    required this.viewportSize,
  });

  static const double popupMaxWidth = 220.0;
  static const double popupMargin = 8.0;
  static const double lineHeight = 18.0;
  static const double verticalPadding = 12.0;

  final List<String> lines;
  final Offset markerPosition;
  final Size viewportSize;

  @override
  Widget build(BuildContext context) {
    final estimatedHeight = lines.length * lineHeight + verticalPadding * 2;
    final position = popupPosition(
      markerPosition: markerPosition,
      viewportSize: viewportSize,
      popupMaxWidth: popupMaxWidth,
      popupMargin: popupMargin,
      estimatedHeight: estimatedHeight,
    );

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: popupMaxWidth),
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
