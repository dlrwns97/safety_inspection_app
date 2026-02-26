import 'package:flutter/material.dart';
import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';
import 'package:safety_inspection_app/screens/drawing/engines/highlighter_engine.dart';

const double _kGap = 8;
const double _kTitleFont = 16;
const double _kBodyFont = 13;
const double _kChipH = 34;

class HighlighterSettingsPopup extends StatefulWidget {
  const HighlighterSettingsPopup({
    super.key,
    required this.currentStyle,
    required this.recentColors,
    required this.standardPaletteColors,
    required this.isStraightenModeEnabled,
    required this.straightenSnapEnabled,
    required this.onVariantChanged,
    required this.onWidthChanged,
    required this.onOpacityChanged,
    required this.onColorChanged,
    required this.onStraightenModeChanged,
    required this.onStraightenSnapChanged,
    required this.onOpenAllColors,
    this.onClose,
  });

  final StrokeStyle currentStyle;
  final List<Color> recentColors;
  final List<Color> standardPaletteColors;
  final bool isStraightenModeEnabled;
  final bool straightenSnapEnabled;
  final ValueChanged<PenVariant> onVariantChanged;
  final ValueChanged<double> onWidthChanged;
  final ValueChanged<double> onOpacityChanged;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<bool> onStraightenModeChanged;
  final ValueChanged<bool> onStraightenSnapChanged;
  final VoidCallback onOpenAllColors;
  final VoidCallback? onClose;

  @override
  State<HighlighterSettingsPopup> createState() => _HighlighterSettingsPopupState();
}

class _HighlighterSettingsPopupState extends State<HighlighterSettingsPopup> {
  late StrokeStyle _style;
  late bool _isStraightenModeEnabled;
  late bool _isStraightenSnapEnabled;

  @override
  void initState() {
    super.initState();
    _style = _normalizedStyle(widget.currentStyle);
    _isStraightenModeEnabled = widget.isStraightenModeEnabled;
    _isStraightenSnapEnabled = widget.straightenSnapEnabled;
    _normalizeVariantIfNeeded(source: widget.currentStyle, normalized: _style);
  }

  @override
  void didUpdateWidget(covariant HighlighterSettingsPopup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSameStyle(oldWidget.currentStyle, widget.currentStyle)) {
      final normalized = _normalizedStyle(widget.currentStyle);
      _style = normalized;
      _normalizeVariantIfNeeded(source: widget.currentStyle, normalized: normalized);
    }
    if (oldWidget.isStraightenModeEnabled != widget.isStraightenModeEnabled) {
      _isStraightenModeEnabled = widget.isStraightenModeEnabled;
    }
    if (oldWidget.straightenSnapEnabled != widget.straightenSnapEnabled) {
      _isStraightenSnapEnabled = widget.straightenSnapEnabled;
    }
  }

  StrokeStyle _normalizedStyle(StrokeStyle style) {
    final normalizedVariant = switch (style.variant) {
      PenVariant.highlighter => PenVariant.highlighter,
      PenVariant.highlighterChisel => PenVariant.highlighterChisel,
      _ => PenVariant.highlighter,
    };
    if (normalizedVariant == style.variant) {
      return style;
    }
    return style.copyWith(variant: normalizedVariant);
  }

  void _normalizeVariantIfNeeded({
    required StrokeStyle source,
    required StrokeStyle normalized,
  }) {
    if (source.variant == normalized.variant) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      widget.onVariantChanged(normalized.variant);
    });
  }

  bool _isSameStyle(StrokeStyle a, StrokeStyle b) {
    return a.kind == b.kind &&
        a.variant == b.variant &&
        a.widthPx == b.widthPx &&
        a.argbColor == b.argbColor &&
        a.opacity == b.opacity;
  }

  void _pickVariant(PenVariant variant) {
    setState(() => _style = _style.copyWith(variant: variant));
    widget.onVariantChanged(variant);
  }

  void _pickWidth(double width) {
    setState(() => _style = _style.copyWith(widthPx: width));
    widget.onWidthChanged(width);
  }

  void _pickOpacity(double opacity) {
    setState(() => _style = _style.copyWith(opacity: opacity));
    widget.onOpacityChanged(opacity);
  }

  void _pickColor(Color color) {
    setState(() => _style = _style.copyWith(argbColor: color.value));
    widget.onColorChanged(color);
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = Color(_style.argbColor);
    const highlighterVariants = <({PenVariant variant, String label})>[
      (variant: PenVariant.highlighter, label: '형광펜 라운드'),
      (variant: PenVariant.highlighterChisel, label: '형광펜 치즐'),
    ];

    Widget colorChip(Color value) {
      final selected = value.withAlpha(0xFF).value == selectedColor.withAlpha(0xFF).value;
      return Semantics(
        label: '색상 선택',
        button: true,
        child: GestureDetector(
          onTap: () => _pickColor(value),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: value,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
                width: selected ? 3 : 1,
              ),
            ),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 420),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '형광펜 설정',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: _kTitleFont),
                ),
              ),
              SizedBox(
                width: 32,
                height: 32,
                child: Semantics(
                  label: '닫기',
                  button: true,
                  child: IconButton(
                    onPressed: widget.onClose,
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: _kGap),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('타입', style: TextStyle(fontSize: _kBodyFont)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final option in highlighterVariants)
                        SizedBox(
                          height: _kChipH,
                          child: Semantics(
                            label: option.label,
                            button: true,
                            selected: _style.variant == option.variant,
                            child: ChoiceChip(
                              label: Text(option.label, style: const TextStyle(fontSize: _kBodyFont)),
                              selected: _style.variant == option.variant,
                              visualDensity: VisualDensity.compact,
                              labelPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              onSelected: (_) => _pickVariant(option.variant),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: _kGap),
                  SizedBox(
                    height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                      ),
                      child: CustomPaint(
                        painter: _HighlighterPreviewPainter(style: _style),
                      ),
                    ),
                  ),
                  const SizedBox(height: _kGap),
                  _CompactSliderRow(
                    label: '두께',
                    valueLabel: '${_style.widthPx.round()}px',
                    slider: Slider(
                      min: 1,
                      max: 48,
                      divisions: 47,
                      value: _style.widthPx.clamp(1, 48),
                      onChanged: _pickWidth,
                    ),
                  ),
                  _CompactSliderRow(
                    label: '투명도',
                    valueLabel: '${(_style.opacity * 100).round()}%',
                    slider: Slider(
                      min: 0.05,
                      max: 1,
                      value: _style.opacity.clamp(0.05, 1),
                      onChanged: _pickOpacity,
                    ),
                  ),
                  const SizedBox(height: _kGap),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ...widget.recentColors.take(7).map(colorChip),
                      ...widget.standardPaletteColors.take(8).map(colorChip),
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: Semantics(
                          label: '색상 선택',
                          button: true,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: widget.onOpenAllColors,
                            icon: const Icon(Icons.colorize, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Checkbox(
                        value: _isStraightenSnapEnabled,
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() => _isStraightenSnapEnabled = value);
                          widget.onStraightenSnapChanged(value);
                        },
                      ),
                      const Text('스냅', style: TextStyle(fontSize: _kBodyFont)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Semantics(
                          label: '직교 모드',
                          toggled: _isStraightenModeEnabled,
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: const Text('직교 모드', style: TextStyle(fontSize: _kBodyFont)),
                            value: _isStraightenModeEnabled,
                            onChanged: (enabled) {
                              setState(() => _isStraightenModeEnabled = enabled);
                              widget.onStraightenModeChanged(enabled);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactSliderRow extends StatelessWidget {
  const _CompactSliderRow({
    required this.label,
    required this.valueLabel,
    required this.slider,
  });

  final String label;
  final String valueLabel;
  final Widget slider;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 42,
          child: Text(label, style: const TextStyle(fontSize: _kBodyFont)),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: slider,
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            valueLabel,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: _kBodyFont),
          ),
        ),
      ],
    );
  }
}

class _HighlighterPreviewPainter extends CustomPainter {
  const _HighlighterPreviewPainter({required this.style});

  final StrokeStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final path = Path()
      ..moveTo(12, centerY)
      ..lineTo(size.width - 12, centerY);
    final paint = HighlighterEngine.paintForStyle(
      style: style,
      strokeOpacity: 1.0,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HighlighterPreviewPainter oldDelegate) {
    return oldDelegate.style != style;
  }
}
