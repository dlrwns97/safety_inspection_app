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
    required this.currentVariant,
    required this.currentHighlighterWidth,
    required this.currentHighlighterOpacity,
    required this.currentHighlighterColor,
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

  final PenVariant currentVariant;
  final double currentHighlighterWidth;
  final double currentHighlighterOpacity;
  final Color currentHighlighterColor;
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
  late bool _isStraightenModeEnabled;
  late bool _isStraightenSnapEnabled;

  @override
  void initState() {
    super.initState();
    _isStraightenModeEnabled = widget.isStraightenModeEnabled;
    _isStraightenSnapEnabled = widget.straightenSnapEnabled;
  }

  @override
  void didUpdateWidget(covariant HighlighterSettingsPopup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isStraightenModeEnabled != widget.isStraightenModeEnabled) {
      _isStraightenModeEnabled = widget.isStraightenModeEnabled;
    }
    if (oldWidget.straightenSnapEnabled != widget.straightenSnapEnabled) {
      _isStraightenSnapEnabled = widget.straightenSnapEnabled;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = widget.currentHighlighterColor;
    final previewStyle = StrokeStyle(
      kind: StrokeToolKind.highlighter,
      variant: widget.currentVariant,
      widthPx: widget.currentHighlighterWidth,
      opacity: widget.currentHighlighterOpacity,
      argbColor: widget.currentHighlighterColor.toARGB32(),
    );
    const highlighterVariants = <({PenVariant variant, String label})>[
      (variant: PenVariant.highlighter, label: '형광펜'),
      (variant: PenVariant.marker, label: '마커'),
    ];

    Widget colorChip(Color value) {
      final selected =
          value.withAlpha(0xFF).toARGB32() == selectedColor.withAlpha(0xFF).toARGB32();
      return Semantics(
        label: '색상 선택',
        button: true,
        child: GestureDetector(
          onTap: () => widget.onColorChanged(value),
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

    const fixedPalette = <Color>[
      Color(0xFFE53935),
      Color(0xFFFF9800),
      Color(0xFFFFEB3B),
      Color(0xFF43A047),
      Color(0xFF1E88E5),
    ];
    final fixedRgb = fixedPalette
        .map((color) => color.withAlpha(0xFF).toARGB32())
        .toSet();
    final recentPalette = <Color>[];
    for (final color in widget.recentColors) {
      final rgb = color.withAlpha(0xFF).toARGB32();
      if (fixedRgb.contains(rgb)) {
        continue;
      }
      recentPalette.add(color);
      if (recentPalette.length == 2) {
        break;
      }
    }
    const fallbackRecent = <Color>[Color(0xFF000000), Color(0xFFFFFFFF)];
    for (final color in fallbackRecent) {
      if (recentPalette.length == 2) {
        break;
      }
      final rgb = color.withAlpha(0xFF).toARGB32();
      final exists = recentPalette.any(
        (entry) => entry.withAlpha(0xFF).toARGB32() == rgb,
      );
      if (!fixedRgb.contains(rgb) && !exists) {
        recentPalette.add(color);
      }
    }
    final displayPalette = <Color>[...fixedPalette, ...recentPalette];

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
                            selected: widget.currentVariant == option.variant,
                            child: ChoiceChip(
                              label: Text(option.label, style: const TextStyle(fontSize: _kBodyFont)),
                              selected: widget.currentVariant == option.variant,
                              visualDensity: VisualDensity.compact,
                              labelPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              onSelected: (_) => widget.onVariantChanged(option.variant),
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
                        painter: _HighlighterPreviewPainter(style: previewStyle),
                      ),
                    ),
                  ),
                  const SizedBox(height: _kGap),
                  _CompactSliderRow(
                    label: '두께',
                    valueLabel: '${widget.currentHighlighterWidth.round()}px',
                    slider: Slider(
                      min: 1,
                      max: 48,
                      divisions: 47,
                      value: widget.currentHighlighterWidth.clamp(1, 48),
                      onChanged: widget.onWidthChanged,
                    ),
                  ),
                  _CompactSliderRow(
                    label: '투명도',
                    valueLabel: '${(widget.currentHighlighterOpacity * 100).round()}%',
                    slider: Slider(
                      min: 0.05,
                      max: 1,
                      value: widget.currentHighlighterOpacity.clamp(0.05, 1),
                      onChanged: widget.onOpacityChanged,
                    ),
                  ),
                  const SizedBox(height: _kGap),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ...displayPalette.map(colorChip),
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
                        value: _isStraightenModeEnabled,
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() => _isStraightenModeEnabled = value);
                          widget.onStraightenModeChanged(value);
                        },
                      ),
                      const Text('직교', style: TextStyle(fontSize: _kBodyFont)),
                      const SizedBox(width: 12),
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
