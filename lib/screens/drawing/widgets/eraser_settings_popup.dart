import 'package:flutter/material.dart';

class EraserSettingsPopup extends StatelessWidget {
  const EraserSettingsPopup({
    super.key,
    required this.radiusPx,
    required this.onRadiusChanged,
  });

  final double radiusPx;
  final ValueChanged<double> onRadiusChanged;

  @override
  Widget build(BuildContext context) {
    final clampedRadius = radiusPx.clamp(6.0, 60.0);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('지우개 설정', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(child: Text('크기')),
                Text('${clampedRadius.round()} px'),
              ],
            ),
            Slider(
              value: clampedRadius,
              min: 6,
              max: 60,
              divisions: 54,
              label: clampedRadius.round().toString(),
              onChanged: onRadiusChanged,
            ),
          ],
        ),
      ),
    );
  }
}
