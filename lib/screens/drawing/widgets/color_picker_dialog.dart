import 'dart:math' as math;

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

  void _updateRainbowHueValue(double hue, double value, {bool commit = false}) {
    setState(() => _hsv = _hsv.withHue(hue).withSaturation(1).withValue(value));
    _emitLive();
    if (commit) {
      _emitCommit();
    }
  }

  void _updateAlpha(double value, {bool commit = false}) {
    setState(() => _alpha = value);
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

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: DefaultTabController(
          length: 2,
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
                TabBar(
                  tabs: const [Tab(text: '표준'), Tab(text: '사용자 지정')],
                  labelColor: theme.colorScheme.primary,
                  dividerColor: theme.colorScheme.outlineVariant,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 420,
                  child: TabBarView(
                    children: [
                      _buildStandardTab(context),
                      _buildCustomTab(context),
                    ],
                  ),
                ),
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
      ),
    );
  }

  Widget _buildStandardTab(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final panelHeight = math.min(260.0, width * 0.55);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: panelHeight,
            child: _RainbowValuePanel(
              hsv: _hsv,
              onChanged: (hue, value) => _updateRainbowHueValue(hue, value),
              onInteractionEnd: (hue, value) => _updateRainbowHueValue(hue, value, commit: true),
            ),
          ),
          const SizedBox(height: 12),
          _AlphaSliderRow(
            alpha: _alpha,
            baseColor: _hsv.toColor(),
            onChanged: _updateAlpha,
            onChangeEnd: (value) => _updateAlpha(value, commit: true),
          ),
          const SizedBox(height: 12),
          _ColorInfoSection(color: _selectedColor),
        ],
      ),
    );
  }

  Widget _buildCustomTab(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          _AlphaSliderRow(
            alpha: _alpha,
            baseColor: _hsv.toColor(),
            onChanged: _updateAlpha,
            onChangeEnd: (value) => _updateAlpha(value, commit: true),
          ),
          const SizedBox(height: 12),
          _ColorInfoSection(color: _selectedColor),
        ],
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

class _RainbowValuePanel extends StatelessWidget {
  const _RainbowValuePanel({
    required this.hsv,
    required this.onChanged,
    required this.onInteractionEnd,
  });

  final HSVColor hsv;
  final void Function(double hue, double value) onChanged;
  final void Function(double hue, double value) onInteractionEnd;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxWidth, constraints.maxHeight);
        final size = Size(side, side);

        ({double hue, double value}) toHueValue(Offset local) {
          final clampedX = local.dx.clamp(0.0, size.width);
          final clampedY = local.dy.clamp(0.0, size.height);
          final hue = (clampedX / size.width) * 360;
          final value = 1 - (clampedY / size.height);
          return (hue: hue.clamp(0.0, 360.0), value: value.clamp(0.0, 1.0));
        }

        return Align(
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: Semantics(
              label: '표준 색상 패널',
              child: GestureDetector(
                onTapDown: (details) {
                  final mapped = toHueValue(details.localPosition);
                  onChanged(mapped.hue, mapped.value);
                  onInteractionEnd(mapped.hue, mapped.value);
                },
                onPanDown: (details) {
                  final mapped = toHueValue(details.localPosition);
                  onChanged(mapped.hue, mapped.value);
                },
                onPanUpdate: (details) {
                  final mapped = toHueValue(details.localPosition);
                  onChanged(mapped.hue, mapped.value);
                },
                onPanEnd: (_) {
                  onInteractionEnd(hsv.hue, hsv.value);
                },
                child: CustomPaint(
                  painter: _RainbowValuePanelPainter(hsv: hsv),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RainbowValuePanelPainter extends CustomPainter {
  const _RainbowValuePanelPainter({required this.hsv});

  final HSVColor hsv;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(14));

    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFFFF0000),
            Color(0xFFFFFF00),
            Color(0xFF00FF00),
            Color(0xFF00FFFF),
            Color(0xFF0000FF),
            Color(0xFFFF00FF),
            Color(0xFFFF0000),
          ],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(rect),
    );
    canvas.restore();

    final x = (hsv.hue / 360.0).clamp(0.0, 1.0) * size.width;
    final y = (1 - hsv.value).clamp(0.0, 1.0) * size.height;
    final thumb = Offset(x, y);
    final thumbColor = HSVColor.fromAHSV(1, hsv.hue, 1, hsv.value).toColor();

    canvas.drawCircle(
      thumb,
      12,
      Paint()
        ..color = Colors.black26
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(thumb, 10, Paint()..color = thumbColor);
    canvas.drawCircle(
      thumb,
      10,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _RainbowValuePanelPainter oldDelegate) {
    return oldDelegate.hsv != hsv;
  }
}

class _AlphaSliderRow extends StatelessWidget {
  const _AlphaSliderRow({
    required this.alpha,
    required this.baseColor,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final double alpha;
  final Color baseColor;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final alphaPercent = (alpha * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('투명도', style: Theme.of(context).textTheme.bodyMedium),
            const Spacer(),
            Text('$alphaPercent%', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: 6),
        _GradientSlider(
          value: alpha,
          min: 0,
          max: 1,
          gradient: LinearGradient(
            colors: [
              baseColor.withValues(alpha: 0),
              baseColor.withValues(alpha: 1),
            ],
          ),
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
        ),
      ],
    );
  }
}

class _ColorInfoSection extends StatelessWidget {
  const _ColorInfoSection({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hex =
        '#${color.red.toRadixString(16).padLeft(2, '0').toUpperCase()}${color.green.toRadixString(16).padLeft(2, '0').toUpperCase()}${color.blue.toRadixString(16).padLeft(2, '0').toUpperCase()}';
    final alphaPercent = (color.opacity * 100).round();

    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('HEX  $hex', style: theme.textTheme.titleSmall),
              const SizedBox(height: 2),
              Text('RGB  ${color.red}, ${color.green}, ${color.blue}', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 2),
              Text('A  $alphaPercent%', style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
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
