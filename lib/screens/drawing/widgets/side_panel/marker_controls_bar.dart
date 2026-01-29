import 'package:flutter/material.dart';

class MarkerControlsBar extends StatelessWidget {
  const MarkerControlsBar({
    super.key,
    required this.markerScale,
    required this.onMarkerScaleChanged,
  });

  final double markerScale;
  final ValueChanged<double> onMarkerScaleChanged;

  static const double _minScale = 0.8;
  static const double _maxScale = 1.4;
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
              icon: const Icon(Icons.remove),
              tooltip: '축소',
              onPressed: () => _update(_snap(markerScale - _step)),
              style: iconButtonStyle,
            ),
            Expanded(
              child: Slider(
                min: _minScale,
                max: _maxScale,
                divisions: 6,
                value: _clamp(markerScale),
                onChanged: _update,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: '확대',
              onPressed: () => _update(_snap(markerScale + _step)),
              style: iconButtonStyle,
            ),
            const SizedBox(width: 4),
            Text(
              percentText,
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(width: 6),
            TextButton(
              onPressed: () => _update(1.0),
              style: resetButtonStyle,
              child: const Text('100%'),
            ),
          ],
        ),
      ),
    );
  }
}
