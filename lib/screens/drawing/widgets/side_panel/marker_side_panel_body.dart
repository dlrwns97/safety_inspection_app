import 'package:flutter/material.dart';
import 'package:safety_inspection_app/models/defect.dart';
import 'package:safety_inspection_app/models/equipment_marker.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/side_panel/marker_side_panel_details_section.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/side_panel/marker_side_panel_list_section.dart';

class MarkerSidePanelBody extends StatelessWidget {
  const MarkerSidePanelBody({
    super.key,
    required this.tabController,
    required this.defectFilter,
    this.defectInfoBanner,
    required this.defectItems,
    required this.defectEmptyLabel,
    required this.onSelectDefect,
    required this.defectTitleBuilder,
    required this.defectSubtitleBuilder,
    required this.equipmentFilter,
    this.equipmentInfoBanner,
    required this.equipmentItems,
    required this.equipmentEmptyLabel,
    required this.onSelectEquipment,
    required this.equipmentTitleBuilder,
    required this.equipmentSubtitleBuilder,
    required this.detailWidgets,
    required this.hasSelection,
    required this.onEditPressed,
    required this.onMovePressed,
    required this.onDeletePressed,
    required this.viewTab,
  });

  final TabController tabController;
  final Widget defectFilter;
  final Widget? defectInfoBanner;
  final List<Defect> defectItems;
  final String defectEmptyLabel;
  final ValueChanged<Defect> onSelectDefect;
  final String Function(Defect) defectTitleBuilder;
  final String? Function(Defect) defectSubtitleBuilder;
  final Widget equipmentFilter;
  final Widget? equipmentInfoBanner;
  final List<EquipmentMarker> equipmentItems;
  final String equipmentEmptyLabel;
  final ValueChanged<EquipmentMarker> onSelectEquipment;
  final String Function(EquipmentMarker) equipmentTitleBuilder;
  final String? Function(EquipmentMarker) equipmentSubtitleBuilder;
  final List<Widget> detailWidgets;
  final bool hasSelection;
  final VoidCallback onEditPressed;
  final VoidCallback onMovePressed;
  final VoidCallback onDeletePressed;
  final Widget viewTab;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TabBarView(
        controller: tabController,
        children: [
          Column(
            children: [
              defectFilter,
              if (defectInfoBanner != null) defectInfoBanner!,
              const Divider(height: 1),
              Expanded(
                child: MarkerSidePanelListSection<Defect>(
                  items: defectItems,
                  emptyLabel: defectEmptyLabel,
                  onTap: onSelectDefect,
                  titleBuilder: defectTitleBuilder,
                  subtitleBuilder: defectSubtitleBuilder,
                ),
              ),
            ],
          ),
          Column(
            children: [
              equipmentFilter,
              if (equipmentInfoBanner != null) equipmentInfoBanner!,
              const Divider(height: 1),
              Expanded(
                child: MarkerSidePanelListSection<EquipmentMarker>(
                  items: equipmentItems,
                  emptyLabel: equipmentEmptyLabel,
                  onTap: onSelectEquipment,
                  titleBuilder: equipmentTitleBuilder,
                  subtitleBuilder: equipmentSubtitleBuilder,
                ),
              ),
            ],
          ),
          MarkerSidePanelDetailsSection(
            detailWidgets: detailWidgets,
            hasSelection: hasSelection,
            onEditPressed: onEditPressed,
            onMovePressed: onMovePressed,
            onDeletePressed: onDeletePressed,
          ),
          viewTab,
        ],
      ),
    );
  }
}
