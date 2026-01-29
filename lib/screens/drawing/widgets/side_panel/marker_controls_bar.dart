import 'package:flutter/material.dart';

class MarkerControlsBar extends StatelessWidget {
  const MarkerControlsBar({
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

  static const double _minScale = 0.5;
  static const double _maxScale = 2.0;
  static const double _step = 0.1;

  double _clamp(double value) =>
      value.clamp(_minScale, _maxScale).toDouble();

  double _snap(double value) {
    final clamped = _clamp(value);
    return (clamped * 10).round() / 10;
  }

  void _update(double value) => onMarkerScaleChanged(_clamp(value));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentText = '${(markerScale * 100).round()}%';
    final isEnabled = !isLocked;
    final iconButtonStyle = IconButton.styleFrom(
      minimumSize: const Size(32, 32),
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
    final resetButtonStyle = TextButton.styleFrom(
      minimumSize: const Size(48, 32),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );

    return SizedBox(
      height: 48,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            Text(
              '마커 크기',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(width: 6),
            IconButton(
              icon: Icon(isLocked ? Icons.lock : Icons.lock_open),
              tooltip: isLocked ? '잠금' : '잠금 해제',
              onPressed: onToggleLock,
              style: iconButtonStyle,
            ),
            const SizedBox(width: 2),
            IconButton(
              icon: const Icon(Icons.remove),
              tooltip: '축소',
              onPressed:
                  isEnabled ? () => _update(_snap(markerScale - _step)) : null,
              style: iconButtonStyle,
            ),
            Expanded(
              child: Slider(
                min: _minScale,
                max: _maxScale,
                divisions: 15,
                value: _clamp(markerScale),
                onChanged: isEnabled ? _update : null,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: '확대',
              onPressed:
                  isEnabled ? () => _update(_snap(markerScale + _step)) : null,
              style: iconButtonStyle,
            ),
            const SizedBox(width: 4),
            Text(
              percentText,
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(width: 6),
            TextButton(
              onPressed: isEnabled ? () => _update(1.0) : null,
              style: resetButtonStyle,
              child: const Text('100%'),
            ),
          ],
        ),
      ),
    );
  }
}
