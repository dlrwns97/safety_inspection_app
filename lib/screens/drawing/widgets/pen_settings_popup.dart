import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';
import 'package:safety_inspection_app/widgets/drawing/temp_polyline_painter.dart';

const double kGap = 8;
const double kTitleFont = 16;
const double kBodyFont = 13;
const double kChipH = 34;
const double kButtonH = 40;
const double kPreviewH = 90;

class PenSettingsPopup extends StatefulWidget {
  const PenSettingsPopup({
    super.key,
    required this.currentStyle,
    required this.recentColors,
    required this.standardPaletteColors,
    required this.isStraightenModeEnabled,
    required this.straightenSnapEnabled,
    required this.onStyleChanged,
    required this.onPresetCommitted,
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
  final ValueChanged<StrokeStyle> onStyleChanged;
  final ValueChanged<StrokeStyle> onPresetCommitted;
  final ValueChanged<bool> onStraightenModeChanged;
  final ValueChanged<bool> onStraightenSnapChanged;
  final VoidCallback onOpenAllColors;
  final VoidCallback? onClose;

  @override
  State<PenSettingsPopup> createState() => _PenSettingsPopupState();
}

class _PenSettingsPopupState extends State<PenSettingsPopup> {
  late StrokeStyle _style;
  late bool _isStraightenModeEnabled;
  late bool _isStraightenSnapEnabled;

  @override
  void initState() {
    super.initState();
    _style = widget.currentStyle;
    _isStraightenModeEnabled = widget.isStraightenModeEnabled;
    _isStraightenSnapEnabled = widget.straightenSnapEnabled;
  }

  @override
  void didUpdateWidget(covariant PenSettingsPopup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSameStyle(oldWidget.currentStyle, widget.currentStyle)) {
      _style = widget.currentStyle;
    }
    if (oldWidget.isStraightenModeEnabled != widget.isStraightenModeEnabled) {
      _isStraightenModeEnabled = widget.isStraightenModeEnabled;
    }
    if (oldWidget.straightenSnapEnabled != widget.straightenSnapEnabled) {
      _isStraightenSnapEnabled = widget.straightenSnapEnabled;
    }
  }

  bool _isSameStyle(StrokeStyle a, StrokeStyle b) {
    return a.kind == b.kind &&
        a.variant == b.variant &&
        a.widthPx == b.widthPx &&
        a.argbColor == b.argbColor &&
        a.opacity == b.opacity;
  }

  void _applyStyle(StrokeStyle next) {
    setState(() => _style = next);
    if (kDebugMode) {
      debugPrint(
        '[Drawing] PenSettingsPopup onStyleChanged '
        'kind=${next.kind.name} variant=${next.variant.name} '
        'width=${next.widthPx.toStringAsFixed(1)} color=${next.argbColor}',
      );
    }
    widget.onStyleChanged(next);
  }

  void _pickColor(Color color) {
    final next = _style.copyWith(argbColor: color.value);
    setState(() => _style = next);
    widget.onPresetCommitted(next);
  }

  String _variantLabel(PenVariant variant) {
    return switch (variant) {
      PenVariant.pen => '펜 라운드',
      PenVariant.calligraphyPen => '펜 치즐',
      PenVariant.marker => '마커',
      PenVariant.markerChisel => '마커 치즐',
      _ => variant.name,
    };
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = Color(_style.argbColor);
    final penVariants = const <PenVariant>[
      PenVariant.pen,
      PenVariant.calligraphyPen,
      PenVariant.marker,
      PenVariant.markerChisel,
    ];

    Widget colorChip(Color value) {
      final selected = value.withAlpha(0xFF).value == currentColor.withAlpha(0xFF).value;
      return GestureDetector(
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
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '펜 설정',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: kTitleFont),
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
        const SizedBox(height: kGap),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 110),
          child: _PenPreview(style: _style),
        ),
        if (_style.kind == StrokeToolKind.pen) ...[
          const SizedBox(height: kGap),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final variant in penVariants)
                SizedBox(
                  height: kChipH,
                  child: ChoiceChip(
                    label: Text(_variantLabel(variant), style: const TextStyle(fontSize: kBodyFont)),
                    selected: _style.variant == variant,
                    visualDensity: VisualDensity.compact,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    onSelected: (_) => _applyStyle(_style.copyWith(variant: variant)),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: kGap),
        _CompactSliderRow(
          label: '두께',
          valueLabel: '${_style.widthPx.round()}',
          slider: Slider(
            min: 1,
            max: 48,
            divisions: 47,
            value: _style.widthPx.clamp(1, 48),
            onChanged: (v) => _applyStyle(_style.copyWith(widthPx: v)),
          ),
        ),
        if (_style.kind == StrokeToolKind.highlighter)
          _CompactSliderRow(
            label: '투명도',
            valueLabel: '${(_style.opacity * 100).round()}%',
            slider: Slider(
              min: 0.05,
              max: 1,
              value: _style.opacity.clamp(0.05, 1.0),
              onChanged: (v) => _applyStyle(_style.copyWith(opacity: v)),
            ),
          ),
        const SizedBox(height: kGap),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final paletteColor in widget.standardPaletteColors.take(8))
              colorChip(paletteColor),
            if (widget.recentColors.isNotEmpty) ...widget.recentColors.take(7).map(colorChip),
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
            const Text('스냅', style: TextStyle(fontSize: kBodyFont)),
            const SizedBox(width: 8),
            Expanded(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('직교 모드', style: TextStyle(fontSize: kBodyFont)),
                value: _isStraightenModeEnabled,
                onChanged: (enabled) {
                  setState(() => _isStraightenModeEnabled = enabled);
                  widget.onStraightenModeChanged(enabled);
                },
              ),
            ),
          ],
        ),
      ],
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
          width: 34,
          child: Text(label, style: const TextStyle(fontSize: kBodyFont)),
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
          width: 34,
          child: Text(
            valueLabel,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: kBodyFont),
          ),
        ),
      ],
    );
  }
}

class _PenPreview extends StatelessWidget {
  const _PenPreview({required this.style});

  final StrokeStyle style;

  @override
  Widget build(BuildContext context) {
    final stroke = DrawingStroke(
      id: 'preview',
      pageNumber: 1,
      style: style,
      pointsNorm: const [
        Offset(0.05, 0.70),
        Offset(0.20, 0.35),
        Offset(0.35, 0.65),
        Offset(0.50, 0.30),
        Offset(0.68, 0.62),
        Offset(0.86, 0.42),
        Offset(0.95, 0.52),
      ],
    );

    return SizedBox(
      height: kPreviewH,
      width: double.infinity,
      child: CustomPaint(
        painter: TempPolylinePainter(
          strokes: const <DrawingStroke>[],
          inProgress: stroke,
          pageSize: const Size(300, kPreviewH),
        ),
      ),
    );
  }
}
