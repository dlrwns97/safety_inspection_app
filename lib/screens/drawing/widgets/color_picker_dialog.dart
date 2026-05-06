import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

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

int _colorChannel255(double value) =>
    (value * 255.0).round().clamp(0, 255).toInt();

int _red255(Color color) => _colorChannel255(color.r);

int _green255(Color color) => _colorChannel255(color.g);

int _blue255(Color color) => _colorChannel255(color.b);

int _alphaPercent(Color color) => (color.a * 100).round();

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
  State<_DrawingColorPickerDialog> createState() =>
      _DrawingColorPickerDialogState();
}

class _DrawingColorPickerDialogState extends State<_DrawingColorPickerDialog> {
  static const double _kDialogHorizontalPadding = 16;
  static const double _kDialogVerticalPadding = 14;
  static const int _kMosaicColumns = 19;
  static const int _kMosaicRows = 12;

  late HSVColor _hsv;
  late double _alpha;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initialColor.withValues(alpha: 1));
    _alpha = widget.initialColor.a;
  }

  Color get _selectedColor => _hsv.toColor().withValues(alpha: _alpha);

  void _emitLive() => widget.onLiveChanged(_selectedColor);

  void _emitCommit() => widget.onCommitChanged(_selectedColor);

  void _updateSaturationValue(
    Offset localPosition,
    Size size, {
    bool commit = false,
  }) {
    final saturation = (localPosition.dx / size.width).clamp(0.0, 1.0);
    final value = (1 - (localPosition.dy / size.height)).clamp(0.0, 1.0);
    setState(() => _hsv = _hsv.withSaturation(saturation).withValue(value));
    _emitLive();
    if (commit) {
      _emitCommit();
    }
  }

  void _updateMosaicSelection(int column, int row, {bool commit = false}) {
    final color = _mosaicColorAt(column, row);
    setState(() => _hsv = HSVColor.fromColor(color));
    _emitLive();
    if (commit) {
      _emitCommit();
    }
  }

  Color _mosaicColorAt(int column, int row) {
    final clampedColumn = column.clamp(0, _kMosaicColumns - 1);
    final clampedRow = row.clamp(0, _kMosaicRows - 1);
    final hue = (clampedColumn / (_kMosaicColumns - 1)) * 360;
    final base = HSVColor.fromAHSV(1, hue, 1, 1).toColor();
    final t = (clampedRow / math.max(1, _kMosaicRows - 1)).clamp(0.0, 1.0);
    const topEnd = 0.22;
    const middleEnd = 0.62;

    if (t <= topEnd) {
      final u = (t / topEnd).clamp(0.0, 1.0);
      final mixWhite = lerpDouble(0.55, 0.05, u) ?? 0.05;
      return Color.lerp(Colors.white, base, 1 - mixWhite) ?? base;
    }

    if (t < middleEnd) {
      final u = ((t - topEnd) / (middleEnd - topEnd)).clamp(0.0, 1.0);
      final value = lerpDouble(1.0, 0.90, u) ?? 1.0;
      return HSVColor.fromAHSV(1, hue, 1.0, value).toColor();
    }

    final u = ((t - middleEnd) / (1 - middleEnd)).clamp(0.0, 1.0);
    final mixBlack = lerpDouble(0.0, 0.75, u) ?? 0.0;
    return Color.lerp(base, Colors.black, mixBlack) ?? base;
  }

  ({int column, int row}) _selectedMosaicCell() {
    final color = _hsv.toColor();
    var bestDistance = double.infinity;
    var bestColumn = 0;
    var bestRow = 0;

    for (var row = 0; row < _kMosaicRows; row++) {
      for (var column = 0; column < _kMosaicColumns; column++) {
        final candidate = _mosaicColorAt(column, row);
        final dr = (_red255(candidate) - _red255(color)).toDouble();
        final dg = (_green255(candidate) - _green255(color)).toDouble();
        final db = (_blue255(candidate) - _blue255(color)).toDouble();
        final distance = dr * dr + dg * dg + db * db;
        if (distance < bestDistance) {
          bestDistance = distance;
          bestColumn = column;
          bestRow = row;
        }
      }
    }

    return (column: bestColumn, row: bestRow);
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
    final screenSize = MediaQuery.sizeOf(context);
    final maxDialogWidth = math.min(screenSize.width * 0.9, 560.0);
    final maxDialogHeight = math.min(screenSize.height * 0.78, 520.0);
    final shouldAllowBodyScroll = maxDialogHeight < 470;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: LayoutBuilder(
        builder: (context, _) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxDialogWidth,
              maxHeight: maxDialogHeight,
            ),
            child: SizedBox(
              width: maxDialogWidth,
              height: maxDialogHeight,
              child: DefaultTabController(
                length: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _kDialogHorizontalPadding,
                    vertical: _kDialogVerticalPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '색상 선택',
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          Semantics(
                            label: '닫기',
                            button: true,
                            child: IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                _emitCommit();
                                _close(kept: true);
                              },
                              icon: const Icon(Icons.close),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      TabBar(
                        tabs: const [
                          Tab(text: '표준'),
                          Tab(text: '사용자 지정'),
                        ],
                        labelColor: theme.colorScheme.primary,
                        dividerColor: theme.colorScheme.outlineVariant,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: shouldAllowBodyScroll
                            ? SingleChildScrollView(
                                child: SizedBox(
                                  height: 360,
                                  child: TabBarView(
                                    children: [
                                      _buildStandardTab(context, compact: true),
                                      _buildCustomTab(context, compact: true),
                                    ],
                                  ),
                                ),
                              )
                            : TabBarView(
                                children: [
                                  _buildStandardTab(context),
                                  _buildCustomTab(context),
                                ],
                              ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _close(kept: false),
                              child: const Text('취소'),
                            ),
                          ),
                          const SizedBox(width: 8),
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
        },
      ),
    );
  }

  Widget _buildStandardTab(BuildContext context, {bool compact = false}) {
    final selectedCell = _selectedMosaicCell();

    final content = LayoutBuilder(
      builder: (context, constraints) {
        final panelWidth = compact
            ? math.min(320.0, constraints.maxWidth)
            : math.min(420.0, constraints.maxWidth * 0.70);
        final panelHeight = panelWidth * 0.72;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              child: SizedBox(
                width: panelWidth,
                height: panelHeight,
                child: _MosaicPalettePanel(
                  columns: _kMosaicColumns,
                  rows: _kMosaicRows,
                  selectedColumn: selectedCell.column,
                  selectedRow: selectedCell.row,
                  colorAt: _mosaicColorAt,
                  onChanged: (column, row) =>
                      _updateMosaicSelection(column, row),
                  onInteractionEnd: (column, row) =>
                      _updateMosaicSelection(column, row, commit: true),
                ),
              ),
            ),
            SizedBox(height: compact ? 8 : 10),
            _ColorInfoSection(color: _selectedColor, compact: compact),
          ],
        );
      },
    );

    if (!compact) {
      return content;
    }
    return SingleChildScrollView(child: content);
  }

  Widget _buildCustomTab(BuildContext context, {bool compact = false}) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SaturationValuePanel(
          hsv: _hsv,
          height: compact ? 180 : 210,
          onChanged: (pos, size) => _updateSaturationValue(pos, size),
          onInteractionEnd: (pos, size) =>
              _updateSaturationValue(pos, size, commit: true),
        ),
        SizedBox(height: compact ? 8 : 10),
        _GradientSlider(
          value: _hsv.hue,
          min: 0,
          max: 360,
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFF0000),
              Color(0xFFFFFF00),
              Color(0xFF00FF00),
              Color(0xFF00FFFF),
              Color(0xFF0000FF),
              Color(0xFFFF00FF),
              Color(0xFFFF0000),
            ],
          ),
          onChanged: (value) {
            setState(() => _hsv = _hsv.withHue(value));
            _emitLive();
          },
          onChangeEnd: (_) => _emitCommit(),
        ),
        const SizedBox(height: 6),
        _AlphaSliderRow(
          alpha: _alpha,
          baseColor: _hsv.toColor(),
          onChanged: _updateAlpha,
          onChangeEnd: (value) => _updateAlpha(value, commit: true),
        ),
        SizedBox(height: compact ? 8 : 10),
        _ColorInfoSection(color: _selectedColor, compact: compact),
      ],
    );

    if (!compact) {
      return content;
    }
    return SingleChildScrollView(child: content);
  }
}

class _MosaicPalettePanel extends StatelessWidget {
  const _MosaicPalettePanel({
    required this.columns,
    required this.rows,
    required this.selectedColumn,
    required this.selectedRow,
    required this.colorAt,
    required this.onChanged,
    required this.onInteractionEnd,
  });

  final int columns;
  final int rows;
  final int selectedColumn;
  final int selectedRow;
  final Color Function(int column, int row) colorAt;
  final void Function(int column, int row) onChanged;
  final void Function(int column, int row) onInteractionEnd;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        ({int column, int row}) toCell(Offset local) {
          final cellWidth = size.width / columns;
          final cellHeight = size.height / rows;
          final column = (local.dx / cellWidth).floor().clamp(0, columns - 1);
          final row = (local.dy / cellHeight).floor().clamp(0, rows - 1);
          return (column: column, row: row);
        }

        return Semantics(
          label: '표준 색상 패널',
          child: GestureDetector(
            onTapDown: (details) {
              final cell = toCell(details.localPosition);
              onChanged(cell.column, cell.row);
              onInteractionEnd(cell.column, cell.row);
            },
            onPanDown: (details) {
              final cell = toCell(details.localPosition);
              onChanged(cell.column, cell.row);
            },
            onPanUpdate: (details) {
              final cell = toCell(details.localPosition);
              onChanged(cell.column, cell.row);
            },
            onPanEnd: (_) => onInteractionEnd(selectedColumn, selectedRow),
            child: CustomPaint(
              painter: _MosaicPalettePanelPainter(
                columns: columns,
                rows: rows,
                selectedColumn: selectedColumn,
                selectedRow: selectedRow,
                colorAt: colorAt,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MosaicPalettePanelPainter extends CustomPainter {
  const _MosaicPalettePanelPainter({
    required this.columns,
    required this.rows,
    required this.selectedColumn,
    required this.selectedRow,
    required this.colorAt,
  });

  final int columns;
  final int rows;
  final int selectedColumn;
  final int selectedRow;
  final Color Function(int column, int row) colorAt;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(14));
    final cellWidth = size.width / columns;
    final cellHeight = size.height / rows;

    canvas.save();
    canvas.clipRRect(rrect);
    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        final cellRect = Rect.fromLTWH(
          column * cellWidth,
          row * cellHeight,
          cellWidth,
          cellHeight,
        );
        canvas.drawRect(cellRect, Paint()..color = colorAt(column, row));
        canvas.drawRect(
          cellRect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.7
            ..color = Colors.black.withValues(alpha: 0.10),
        );
      }
    }
    canvas.restore();

    final center = Offset(
      (selectedColumn + 0.5) * cellWidth,
      (selectedRow + 0.5) * cellHeight,
    );
    final ringRadius = math.min(cellWidth, cellHeight) * 0.38;

    canvas.drawCircle(
      center,
      ringRadius + 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.black.withValues(alpha: 0.45),
    );
    canvas.drawCircle(
      center,
      ringRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _MosaicPalettePanelPainter oldDelegate) {
    return oldDelegate.columns != columns ||
        oldDelegate.rows != rows ||
        oldDelegate.selectedColumn != selectedColumn ||
        oldDelegate.selectedRow != selectedRow;
  }
}

class _SaturationValuePanel extends StatelessWidget {
  const _SaturationValuePanel({
    required this.hsv,
    required this.onChanged,
    required this.onInteractionEnd,
    this.height = 210,
  });

  final HSVColor hsv;
  final double height;
  final void Function(Offset localPosition, Size size) onChanged;
  final void Function(Offset localPosition, Size size) onInteractionEnd;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, height);
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
            child: CustomPaint(painter: _SaturationValuePanelPainter(hsv: hsv)),
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
            Text(
              '$alphaPercent%',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
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
  const _ColorInfoSection({required this.color, this.compact = false});

  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hex =
        '#${_red255(color).toRadixString(16).padLeft(2, '0').toUpperCase()}${_green255(color).toRadixString(16).padLeft(2, '0').toUpperCase()}${_blue255(color).toRadixString(16).padLeft(2, '0').toUpperCase()}';
    final alphaPercent = _alphaPercent(color);

    return Row(
      children: [
        Container(
          width: compact ? 48 : 56,
          height: compact ? 48 : 56,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
        ),
        SizedBox(width: compact ? 10 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HEX  $hex',
                style: compact
                    ? theme.textTheme.bodyMedium
                    : theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 2),
              Text(
                'RGB  ${_red255(color)}, ${_green255(color)}, ${_blue255(color)}',
                style: theme.textTheme.bodyMedium,
              ),
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
