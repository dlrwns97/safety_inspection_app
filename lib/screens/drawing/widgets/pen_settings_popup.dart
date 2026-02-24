import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';
import 'package:safety_inspection_app/widgets/drawing/temp_polyline_painter.dart';

class PenSettingsPopup extends StatefulWidget {
  const PenSettingsPopup({
    super.key,
    required this.currentStyle,
    required this.recentColors,
    required this.standardPaletteColors,
    required this.isStraightenModeEnabled,
    required this.onStyleChanged,
    required this.onPresetCommitted,
    required this.onStraightenModeChanged,
    required this.onOpenAllColors,
  });

  final StrokeStyle currentStyle;
  final List<Color> recentColors;
  final List<Color> standardPaletteColors;
  final bool isStraightenModeEnabled;
  final ValueChanged<StrokeStyle> onStyleChanged;
  final ValueChanged<StrokeStyle> onPresetCommitted;
  final ValueChanged<bool> onStraightenModeChanged;
  final VoidCallback onOpenAllColors;

  @override
  State<PenSettingsPopup> createState() => _PenSettingsPopupState();
}

class _PenSettingsPopupState extends State<PenSettingsPopup> {
  late StrokeStyle _style;
  late bool _isStraightenModeEnabled;

  @override
  void initState() {
    super.initState();
    _style = widget.currentStyle;
    _isStraightenModeEnabled = widget.isStraightenModeEnabled;
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

  @override
  Widget build(BuildContext context) {
    final currentColor = Color(_style.argbColor);
    final penVariants = const <PenVariant>[
      PenVariant.pen,
      PenVariant.fountainPen,
      PenVariant.calligraphyPen,
      PenVariant.pencil,
    ];

    Widget colorChip(Color value) {
      final selected = value.value == currentColor.value;
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

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('펜 설정', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _PenPreview(style: _style),
            if (_style.kind == StrokeToolKind.pen) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final variant in penVariants)
                    ChoiceChip(
                      label: Text(variant.name),
                      selected: _style.variant == variant,
                      onSelected: (_) => _applyStyle(_style.copyWith(variant: variant)),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('두께'),
                Expanded(
                  child: Slider(
                    min: 1,
                    max: 48,
                    divisions: 47,
                    value: _style.widthPx.clamp(1, 48),
                    onChanged: (v) => _applyStyle(_style.copyWith(widthPx: v)),
                  ),
                ),
                Text('${_style.widthPx.round()}'),
              ],
            ),
            if (_style.kind == StrokeToolKind.highlighter)
              Row(
                children: [
                  const Text('투명도'),
                  Expanded(
                    child: Slider(
                      min: 0.05,
                      max: 1,
                      value: _style.opacity.clamp(0.05, 1.0),
                      onChanged: (v) => _applyStyle(_style.copyWith(opacity: v)),
                    ),
                  ),
                  Text('${(_style.opacity * 100).round()}%'),
                ],
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final paletteColor in widget.standardPaletteColors.take(8))
                  colorChip(paletteColor),
                if (widget.recentColors.isNotEmpty) ...widget.recentColors.map(colorChip),
                IconButton(
                  onPressed: widget.onOpenAllColors,
                  icon: const Icon(Icons.colorize),
                  tooltip: '색상 선택',
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('직교 모드'),
              value: _isStraightenModeEnabled,
              onChanged: (enabled) {
                setState(() => _isStraightenModeEnabled = enabled);
                widget.onStraightenModeChanged(enabled);
              },
            ),
          ],
        ),
      ),
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
      height: 72,
      width: double.infinity,
      child: CustomPaint(
        painter: TempPolylinePainter(
          strokes: const <DrawingStroke>[],
          inProgress: stroke,
          pageSize: const Size(300, 72),
        ),
      ),
    );
  }
}
