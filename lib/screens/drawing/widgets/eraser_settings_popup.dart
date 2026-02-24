import 'package:flutter/material.dart';

import 'package:safety_inspection_app/screens/drawing/drawing_types.dart';

const double kPad = 12;
const double kGap = 8;
const double kTitleFont = 16;
const double kBodyFont = 13;
const double kChipH = 34;
const double kButtonH = 40;
const double kPreviewH = 90;

class EraserSettingsPopup extends StatefulWidget {
  const EraserSettingsPopup({
    super.key,
    required this.radiusPx,
    required this.onRadiusChanged,
    required this.onClearPenOnly,
    required this.onClearHighlighterOnly,
    required this.onClearAll,
    this.mode,
    this.onModeChanged,
  });

  final double radiusPx;
  final ValueChanged<double> onRadiusChanged;
  final DrawingTool? mode;
  final ValueChanged<DrawingTool>? onModeChanged;
  final Future<void> Function() onClearPenOnly;
  final Future<void> Function() onClearHighlighterOnly;
  final Future<void> Function() onClearAll;

  @override
  State<EraserSettingsPopup> createState() => _EraserSettingsPopupState();
}

class _EraserSettingsPopupState extends State<EraserSettingsPopup> {
  late double _radiusPx;
  DrawingTool? _mode;

  @override
  void initState() {
    super.initState();
    _radiusPx = widget.radiusPx;
    _mode = widget.mode;
  }

  @override
  Widget build(BuildContext context) {
    final clampedRadius = _radiusPx.clamp(6.0, 60.0);
    final hasModeToggle = _mode != null && widget.onModeChanged != null;
    final isStrokeEraserMode = _mode == DrawingTool.strokeEraser;

    return Padding(
      padding: const EdgeInsets.all(kPad),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '지우개 설정',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontSize: kTitleFont),
                    ),
                  ),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.close, size: 18),
                      tooltip: '닫기',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: kGap),
              if (!isStrokeEraserMode) ...[
                Row(
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: CustomPaint(
                        painter: _EraserBrushPreviewPainter(radiusPx: clampedRadius),
                      ),
                    ),
                    const SizedBox(width: kGap),
                    Text('반경: ${clampedRadius.round()}px', style: const TextStyle(fontSize: kBodyFont)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Expanded(child: Text('크기', style: TextStyle(fontSize: kBodyFont))),
                    Text('${clampedRadius.round()} px', style: const TextStyle(fontSize: kBodyFont)),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  ),
                  child: Slider(
                    value: clampedRadius,
                    min: 6,
                    max: 60,
                    divisions: 54,
                    label: clampedRadius.round().toString(),
                    onChanged: (next) {
                      setState(() {
                        _radiusPx = next;
                      });
                      widget.onRadiusChanged(next);
                    },
                  ),
                ),
              ],
              if (hasModeToggle) ...[
                const SizedBox(height: 6),
                SizedBox(
                  height: kChipH,
                  child: SegmentedButton<DrawingTool>(
                    showSelectedIcon: false,
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      padding: MaterialStateProperty.all(
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      textStyle: MaterialStateProperty.all(
                        const TextStyle(fontSize: kBodyFont),
                      ),
                    ),
                    segments: const [
                      ButtonSegment<DrawingTool>(
                        value: DrawingTool.areaEraser,
                        label: Text('영역 지우개'),
                      ),
                      ButtonSegment<DrawingTool>(
                        value: DrawingTool.strokeEraser,
                        label: Text('획 지우개'),
                      ),
                    ],
                    selected: {_mode!},
                    onSelectionChanged: (next) {
                      if (next.isEmpty) {
                        return;
                      }
                      setState(() {
                        _mode = next.first;
                      });
                      widget.onModeChanged!.call(next.first);
                    },
                  ),
                ),
              ],
              const SizedBox(height: kGap),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(kButtonH),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: const TextStyle(fontSize: kBodyFont),
                  ),
                  onPressed: () async {
                    await widget.onClearPenOnly();
                  },
                  child: const Text('그리기만 지우기'),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(kButtonH),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: const TextStyle(fontSize: kBodyFont),
                  ),
                  onPressed: () async {
                    await widget.onClearHighlighterOnly();
                  },
                  child: const Text('형광펜만 지우기'),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(kButtonH),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: const TextStyle(fontSize: kBodyFont),
                  ),
                  onPressed: () async {
                    await widget.onClearAll();
                  },
                  child: const Text('전체 지우기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EraserBrushPreviewPainter extends CustomPainter {
  const _EraserBrushPreviewPainter({required this.radiusPx});

  final double radiusPx;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = (size.shortestSide / 2) - 2;
    final previewRadius = radiusPx.clamp(1.0, maxRadius);

    final fillPaint = Paint()
      ..color = Colors.grey.withOpacity(0.18)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = Colors.grey.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    canvas.drawCircle(center, previewRadius, fillPaint);
    canvas.drawCircle(center, previewRadius, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _EraserBrushPreviewPainter oldDelegate) {
    return oldDelegate.radiusPx != radiusPx;
  }
}
