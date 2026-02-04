import 'package:flutter/material.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/side_panel/marker_header_controls.dart';

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
        MarkerHeaderControls(
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
