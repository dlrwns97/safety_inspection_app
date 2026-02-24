import 'package:flutter/material.dart';

import 'package:safety_inspection_app/screens/drawing/drawing_types.dart';

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
  final VoidCallback onClearPenOnly;
  final VoidCallback onClearHighlighterOnly;
  final VoidCallback onClearAll;

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
    final viewInsetsBottom = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: viewInsetsBottom),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '지우개 설정',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        tooltip: '닫기',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                    onChanged: (next) {
                      setState(() {
                        _radiusPx = next;
                      });
                      widget.onRadiusChanged(next);
                    },
                  ),
                  if (hasModeToggle) ...[
                    const SizedBox(height: 8),
                    SegmentedButton<DrawingTool>(
                      showSelectedIcon: false,
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
                  ],
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed: () {
                        widget.onClearPenOnly();
                        Navigator.of(context).pop();
                      },
                      child: const Text('그리기만 지우기'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed: () {
                        widget.onClearHighlighterOnly();
                        Navigator.of(context).pop();
                      },
                      child: const Text('형광펜만 지우기'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        widget.onClearAll();
                        Navigator.of(context).pop();
                      },
                      child: const Text('전체 지우기'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
