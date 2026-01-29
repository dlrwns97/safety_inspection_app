import 'package:flutter/material.dart';

class MarkerHeaderControls extends StatelessWidget {
  const MarkerHeaderControls({
    super.key,
    required this.markerScale,
    required this.onMarkerScaleChanged,
    required this.isLocked,
    required this.onToggleLock,
  });

  final double markerScale;
  final ValueChanged<double> onMarkerScaleChanged;
  final bool isLocked;
  final VoidCallback onToggleLock;

  static const List<int> _scalePercents = [
    20,
    30,
    40,
    50,
    60,
    70,
    80,
    90,
    100,
    110,
    120,
    130,
    140,
    150,
    160,
    170,
    180,
    190,
    200,
  ];

  int _selectedPercent() {
    final rawPercent = (markerScale * 100).round().clamp(20, 200);
    return ((rawPercent / 10).round() * 10).clamp(20, 200);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dropdown = DropdownButtonHideUnderline(
      child: DropdownButton<int>(
        value: _selectedPercent(),
        isDense: true,
        icon: const Icon(Icons.expand_more),
        itemHeight: 36,
        style: theme.textTheme.bodySmall?.copyWith(fontSize: 13),
        items: _scalePercents
            .map(
              (percent) => DropdownMenuItem<int>(
                value: percent,
                height: 36,
                child: Text('$percent%'),
              ),
            )
            .toList(),
        onChanged: isLocked
            ? null
            : (value) {
                if (value == null) {
                  return;
                }
                onMarkerScaleChanged((value / 100.0).clamp(0.2, 2.0));
              },
      ),
    );
    final dropdownBox = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: dropdown,
    );

    return SizedBox(
      height: 48,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: Icon(isLocked ? Icons.lock : Icons.lock_open),
              tooltip: isLocked ? '잠금' : '잠금 해제',
              onPressed: onToggleLock,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            if (isLocked)
              Tooltip(
                message: '잠금',
                child: Opacity(opacity: 0.5, child: dropdownBox),
              )
            else
              dropdownBox,
          ],
        ),
      ),
    );
  }
}
