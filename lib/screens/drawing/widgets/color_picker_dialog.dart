import 'package:flutter/material.dart';

Future<bool> showDrawingColorPickerDialog(
  BuildContext context, {
  required Color initialColor,
  required List<Color> recentColors,
  required ValueChanged<Color> onLiveChanged,
  required ValueChanged<Color> onCommitChanged,
}) async {
  final kept = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => _DrawingColorPickerDialog(
      initialColor: initialColor,
      recentColors: recentColors,
      onLiveChanged: onLiveChanged,
      onCommitChanged: onCommitChanged,
    ),
  );
  return kept ?? false;
}

class _DrawingColorPickerDialog extends StatefulWidget {
  const _DrawingColorPickerDialog({
    required this.initialColor,
    required this.recentColors,
    required this.onLiveChanged,
    required this.onCommitChanged,
  });

  final Color initialColor;
  final List<Color> recentColors;
  final ValueChanged<Color> onLiveChanged;
  final ValueChanged<Color> onCommitChanged;

  @override
  State<_DrawingColorPickerDialog> createState() => _DrawingColorPickerDialogState();
}

class _DrawingColorPickerDialogState extends State<_DrawingColorPickerDialog> {
  late HSVColor _hsv;
  late double _alpha;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initialColor.withValues(alpha: 1));
    _alpha = widget.initialColor.opacity;
  }

  Color get _selectedColor => _hsv.toColor().withValues(alpha: _alpha);

  void _emitLive() => widget.onLiveChanged(_selectedColor);

  void _emitCommit() => widget.onCommitChanged(_selectedColor);

  void _updateSaturationValue(Offset localPosition, Size size, {bool commit = false}) {
    final saturation = (localPosition.dx / size.width).clamp(0.0, 1.0);
    final value = (1 - (localPosition.dy / size.height)).clamp(0.0, 1.0);
    setState(() => _hsv = _hsv.withSaturation(saturation).withValue(value));
    _emitLive();
    if (commit) {
      _emitCommit();
    }
  }

  void _close({required bool kept}) {
    Navigator.of(context).pop(kept);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = _selectedColor;
    final rgbHex =
        '#${selected.red.toRadixString(16).padLeft(2, '0').toUpperCase()}${selected.green.toRadixString(16).padLeft(2, '0').toUpperCase()}${selected.blue.toRadixString(16).padLeft(2, '0').toUpperCase()}';
    final alphaPercent = (_alpha * 100).round();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('색상 선택', style: theme.textTheme.titleMedium),
                  ),
                  Semantics(
                    label: '닫기',
                    button: true,
                    child: IconButton(
                      onPressed: () {
                        _emitCommit();
                        _close(kept: true);
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _SaturationValuePanel(
                hsv: _hsv,
                onChanged: (pos, size) => _updateSaturationValue(pos, size),
                onInteractionEnd: (pos, size) => _updateSaturationValue(pos, size, commit: true),
              ),
              const SizedBox(height: 12),
              _GradientSlider(
                value: _hsv.hue,
                min: 0,
                max: 360,
                gradient: const LinearGradient(colors: [
                  Color(0xFFFF0000),
                  Color(0xFFFFFF00),
                  Color(0xFF00FF00),
                  Color(0xFF00FFFF),
                  Color(0xFF0000FF),
                  Color(0xFFFF00FF),
                  Color(0xFFFF0000),
                ]),
                onChanged: (value) {
                  setState(() => _hsv = _hsv.withHue(value));
                  _emitLive();
                },
                onChangeEnd: (_) => _emitCommit(),
              ),
              const SizedBox(height: 8),
              _GradientSlider(
                value: _alpha,
                min: 0,
                max: 1,
                gradient: LinearGradient(
                  colors: [
                    _hsv.toColor().withValues(alpha: 0),
                    _hsv.toColor().withValues(alpha: 1),
                  ],
                ),
                onChanged: (value) {
                  setState(() => _alpha = value);
                  _emitLive();
                },
                onChangeEnd: (_) => _emitCommit(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: selected,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rgbHex, style: theme.textTheme.titleSmall),
                        const SizedBox(height: 4),
                        Text('투명도 $alphaPercent%', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
              if (widget.recentColors.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text('최근 색상', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final color in widget.recentColors.take(12))
                      _RecentColorSwatch(
                        color: color,
                        isSelected: color.value == selected.withValues(alpha: 1).value,
                        onTap: () {
                          setState(() {
                            _hsv = HSVColor.fromColor(color.withValues(alpha: 1));
                            _alpha = color.opacity;
                          });
                          _emitLive();
                          _emitCommit();
                        },
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _close(kept: false),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        _emitCommit();
                        _close(kept: true);
                      },
                      child: const Text('완료'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaturationValuePanel extends StatelessWidget {
  const _SaturationValuePanel({
    required this.hsv,
    required this.onChanged,
    required this.onInteractionEnd,
  });

  final HSVColor hsv;
  final void Function(Offset localPosition, Size size) onChanged;
  final void Function(Offset localPosition, Size size) onInteractionEnd;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, 210);
        return SizedBox(
          width: size.width,
          height: size.height,
          child: GestureDetector(
            onTapDown: (details) {
              onChanged(details.localPosition, size);
              onInteractionEnd(details.localPosition, size);
            },
            onPanStart: (details) => onChanged(details.localPosition, size),
            onPanUpdate: (details) => onChanged(details.localPosition, size),
            onPanEnd: (_) {
              final last = Offset(
                hsv.saturation * size.width,
                (1 - hsv.value) * size.height,
              );
              onInteractionEnd(last, size);
            },
            child: CustomPaint(
              painter: _SaturationValuePanelPainter(hsv: hsv),
            ),
          ),
        );
      },
    );
  }
}

class _SaturationValuePanelPainter extends CustomPainter {
  const _SaturationValuePanelPainter({required this.hsv});

  final HSVColor hsv;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final hueColor = HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor();

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      Paint()..color = hueColor,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Colors.white, Colors.transparent],
        ).createShader(rect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(rect),
    );

    final thumb = Offset(
      hsv.saturation * size.width,
      (1 - hsv.value) * size.height,
    );
    canvas.drawCircle(
      thumb,
      10,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );
    canvas.drawCircle(
      thumb,
      11,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.black54,
    );
  }

  @override
  bool shouldRepaint(covariant _SaturationValuePanelPainter oldDelegate) {
    return oldDelegate.hsv != hsv;
  }
}

class _GradientSlider extends StatelessWidget {
  const _GradientSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.gradient,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final double value;
  final double min;
  final double max;
  final LinearGradient gradient;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 14,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: gradient,
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 14,
              activeTrackColor: Colors.transparent,
              inactiveTrackColor: Colors.transparent,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              min: min,
              max: max,
              value: value.clamp(min, max),
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentColorSwatch extends StatelessWidget {
  const _RecentColorSwatch({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
            width: isSelected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}
