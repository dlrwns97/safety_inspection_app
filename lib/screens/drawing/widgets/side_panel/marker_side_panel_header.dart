import 'package:flutter/material.dart';

class MarkerSidePanelHeader extends StatelessWidget {
  const MarkerSidePanelHeader({
    super.key,
    required this.tabController,
    required this.tabLabelStyle,
    required this.markerScale,
    required this.labelScale,
    required this.onMarkerScaleChanged,
    required this.onLabelScaleChanged,
    required this.isMarkerScaleLocked,
    required this.onToggleMarkerScaleLock,
  });

  final TabController tabController;
  final TextStyle? tabLabelStyle;
  final double markerScale;
  final double labelScale;
  final ValueChanged<double> onMarkerScaleChanged;
  final ValueChanged<double> onLabelScaleChanged;
  final bool isMarkerScaleLocked;
  final VoidCallback onToggleMarkerScaleLock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MarkerHeaderControls(
          markerScale: markerScale,
          labelScale: labelScale,
          onMarkerScaleChanged: onMarkerScaleChanged,
          onLabelScaleChanged: onLabelScaleChanged,
          isLocked: isMarkerScaleLocked,
          onToggleLock: onToggleMarkerScaleLock,
        ),
        const Divider(height: 1),
        TabBar(
          controller: tabController,
          labelColor: theme.colorScheme.primary,
          indicatorColor: theme.colorScheme.primary,
          indicatorWeight: 2.5,
          labelStyle: tabLabelStyle,
          unselectedLabelStyle: tabLabelStyle,
          isScrollable: true,
          labelPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          tabs: const [
            Tab(text: '결함'),
            Tab(text: '장비'),
            Tab(text: '상세'),
            Tab(text: '보기'),
          ],
        ),
        const Divider(height: 1),
      ],
    );
  }
}

class _MarkerHeaderControls extends StatelessWidget {
  const _MarkerHeaderControls({
    required this.markerScale,
    required this.labelScale,
    required this.onMarkerScaleChanged,
    required this.onLabelScaleChanged,
    required this.isLocked,
    required this.onToggleLock,
  });

  final double markerScale;
  final double labelScale;
  final ValueChanged<double> onMarkerScaleChanged;
  final ValueChanged<double> onLabelScaleChanged;
  final bool isLocked;
  final VoidCallback onToggleLock;

  static const List<int> _scalePercents = [
    20,
    30,
    40,
    50,
    60,
    70,
    80,
    90,
    100,
    110,
    120,
    130,
    140,
    150,
    160,
    170,
    180,
    190,
    200,
  ];

  int _selectedPercent(double scale) {
    final rawPercent = (scale * 100).round().clamp(20, 200);
    return ((rawPercent / 10).round() * 10).clamp(20, 200);
  }

  double _percentToScale(int percent) => (percent / 100.0).clamp(0.2, 2.0);

  Future<void> _showScaleMenu({
    required BuildContext context,
    required ValueChanged<int> onSelected,
  }) async {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) {
      return;
    }
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final rect = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(Offset.zero, ancestor: overlay),
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    final selection = await showMenu<int>(
      context: context,
      position: rect,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.45,
      ),
      items: _scalePercents
          .map(
            (percent) => PopupMenuItem<int>(
              value: percent,
              height: 36,
              child: Text('$percent%'),
            ),
          )
          .toList(),
    );
    if (selection != null) {
      onSelected(selection);
    }
  }

  Widget _buildScaleBox({
    required BuildContext context,
    required int percent,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$percent%'),
          const SizedBox(width: 4),
          const Icon(Icons.expand_more, size: 18),
        ],
      ),
    );
    final tooltipWrapper = Tooltip(message: tooltip, child: content);
    if (isLocked) {
      return Opacity(opacity: 0.5, child: tooltipWrapper);
    }
    return GestureDetector(onTap: onTap, child: tooltipWrapper);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            IconButton(
              icon: Icon(isLocked ? Icons.lock : Icons.lock_open),
              tooltip: isLocked ? '잠금' : '잠금 해제',
              onPressed: onToggleLock,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            const Icon(Icons.place, size: 17),
            const SizedBox(width: 8),
            Flexible(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Builder(
                  builder: (context) => _buildScaleBox(
                    context: context,
                    percent: _selectedPercent(markerScale),
                    tooltip: '마커 크기 선택',
                    onTap: () => _showScaleMenu(
                      context: context,
                      onSelected: (value) =>
                          onMarkerScaleChanged(_percentToScale(value)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.text_fields, size: 17),
            const SizedBox(width: 8),
            Flexible(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Builder(
                  builder: (context) => _buildScaleBox(
                    context: context,
                    percent: _selectedPercent(labelScale),
                    tooltip: '라벨 크기 선택',
                    onTap: () => _showScaleMenu(
                      context: context,
                      onSelected: (value) =>
                          onLabelScaleChanged(_percentToScale(value)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
