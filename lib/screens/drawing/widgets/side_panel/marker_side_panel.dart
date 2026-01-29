import 'package:flutter/material.dart';
import 'package:safety_inspection_app/models/defect.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/equipment_marker.dart';
import 'package:safety_inspection_app/screens/drawing/flows/marker_presenters.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/marker_filter_chips.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/side_panel/marker_detail_section.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/side_panel/marker_header_controls.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/side_panel/marker_info_banner.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/side_panel/marker_list.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/side_panel/marker_view_tab.dart';

class MarkerSidePanel extends StatelessWidget {
  const MarkerSidePanel({
    super.key,
    required this.tabController,
    required this.currentPage,
    required this.defects,
    required this.equipmentMarkers,
    required this.selectedDefectCategory,
    required this.selectedEquipmentCategory,
    required this.selectedDefect,
    required this.selectedEquipment,
    required this.onSelectDefect,
    required this.onSelectEquipment,
    required this.onDefectCategorySelected,
    required this.onEquipmentCategorySelected,
    required this.visibleDefectCategories,
    required this.visibleEquipmentCategories,
    required this.onDefectVisibilityChanged,
    required this.onEquipmentVisibilityChanged,
    required this.markerScale,
    required this.labelScale,
    required this.onMarkerScaleChanged,
    required this.onLabelScaleChanged,
    required this.isMarkerScaleLocked,
    required this.onToggleMarkerScaleLock,
  });

  final TabController tabController;
  final int currentPage;
  final List<Defect> defects;
  final List<EquipmentMarker> equipmentMarkers;
  final DefectCategory selectedDefectCategory;
  final EquipmentCategory selectedEquipmentCategory;
  final Defect? selectedDefect;
  final EquipmentMarker? selectedEquipment;
  final ValueChanged<Defect> onSelectDefect;
  final ValueChanged<EquipmentMarker> onSelectEquipment;
  final ValueChanged<DefectCategory> onDefectCategorySelected;
  final ValueChanged<EquipmentCategory> onEquipmentCategorySelected;
  final Set<DefectCategory> visibleDefectCategories;
  final Set<EquipmentCategory> visibleEquipmentCategories;
  final void Function(DefectCategory category, bool visible)
      onDefectVisibilityChanged;
  final void Function(EquipmentCategory category, bool visible)
      onEquipmentVisibilityChanged;
  final double markerScale;
  final double labelScale;
  final ValueChanged<double> onMarkerScaleChanged;
  final ValueChanged<double> onLabelScaleChanged;
  final bool isMarkerScaleLocked;
  final VoidCallback onToggleMarkerScaleLock;

  int toDisplayPageFromZeroBased(int pageIndex) => pageIndex + 1;

  static const List<DefectCategory> defectCategories = [
    DefectCategory.generalCrack,
    DefectCategory.waterLeakage,
    DefectCategory.concreteSpalling,
    DefectCategory.steelDefect,
    DefectCategory.other,
  ];

  String defectChipLabel(DefectCategory category) {
    switch (category) {
      case DefectCategory.generalCrack:
        return '균열';
      case DefectCategory.waterLeakage:
        return '누수';
      case DefectCategory.concreteSpalling:
        return '콘크리트';
      case DefectCategory.steelDefect:
        return '철골';
      case DefectCategory.other:
        return '기타';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compactTextTheme = theme.textTheme
        .apply(fontSizeFactor: 0.9)
        .copyWith(
          titleMedium: theme.textTheme.titleMedium?.copyWith(fontSize: 15),
          labelLarge: theme.textTheme.labelLarge?.copyWith(fontSize: 11),
          labelMedium: theme.textTheme.labelMedium?.copyWith(fontSize: 11),
        );
    final tabLabelStyle =
        compactTextTheme.labelMedium?.copyWith(fontSize: 12);
    final compactTheme = theme.copyWith(
      textTheme: compactTextTheme,
      listTileTheme: theme.listTileTheme.copyWith(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        visualDensity: VisualDensity.compact,
      ),
    );
    return Theme(
      data: compactTheme,
      child: Material(
        color: theme.colorScheme.surface,
        elevation: 2,
        child: Column(
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
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: [
                  _buildDefectTab(context),
                  _buildEquipmentTab(context),
                  _buildDetailTab(context),
                  _buildViewTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefectTab(BuildContext context) {
    final isVisible =
        visibleDefectCategories.contains(selectedDefectCategory);
    final filteredDefects = defects
        .where(
          (defect) =>
              defect.pageIndex == currentPage &&
              defect.category == selectedDefectCategory &&
              visibleDefectCategories.contains(defect.category),
        )
        .toList();
    return Column(
      children: [
        MarkerFilterChips<DefectCategory>(
          options: defectCategories,
          selected: selectedDefectCategory,
          labelBuilder: defectChipLabel,
          onSelected: onDefectCategorySelected,
        ),
        if (!isVisible)
          MarkerInfoBanner(
            message:
                "보기 탭에서 '${selectedDefectCategory.label}' 표시가 꺼져 있어요. 켜면 목록이 보입니다.",
          ),
        const Divider(height: 1),
        Expanded(
          child: MarkerList(
            items: filteredDefects,
            emptyLabel: '현재 페이지에 결함 마커가 없습니다.',
            onTap: onSelectDefect,
            titleBuilder: defectDisplayLabel,
            subtitleBuilder: (defect) =>
                defect.details.structuralMember.isNotEmpty
                    ? defect.details.structuralMember
                    : null,
          ),
        ),
      ],
    );
  }

  Widget _buildEquipmentTab(BuildContext context) {
    final isVisible =
        visibleEquipmentCategories.contains(selectedEquipmentCategory);
    final selectedLabel = equipmentChipLabel(selectedEquipmentCategory);
    final filteredEquipment = equipmentMarkers
        .where(
          (marker) =>
              marker.pageIndex == currentPage &&
              marker.category == selectedEquipmentCategory &&
              visibleEquipmentCategories.contains(marker.category),
        )
        .toList();
    return Column(
      children: [
        MarkerFilterChips<EquipmentCategory>(
          options: kEquipmentCategoryOrder,
          selected: selectedEquipmentCategory,
          labelBuilder: equipmentChipLabel,
          onSelected: onEquipmentCategorySelected,
        ),
        if (!isVisible)
          MarkerInfoBanner(
            message:
                "보기 탭에서 '$selectedLabel' 표시가 꺼져 있어요. 켜면 목록이 보입니다.",
          ),
        const Divider(height: 1),
        Expanded(
          child: MarkerList(
            items: filteredEquipment,
            emptyLabel: '현재 페이지에 장비 마커가 없습니다.',
            onTap: onSelectEquipment,
            titleBuilder: (marker) {
              return equipmentDisplayLabel(marker, equipmentMarkers);
            },
            subtitleBuilder: (marker) =>
                marker.memberType?.isNotEmpty == true
                    ? marker.memberType
                    : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailTab(BuildContext context) {
    final theme = Theme.of(context);
    final defect = selectedDefect;
    final equipment = selectedEquipment;
    if (defect == null && equipment == null) {
      return Center(
        child: Text(
          '선택된 마커 없음',
          style: theme.textTheme.bodyLarge,
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (defect != null) _buildDefectDetail(defect),
        if (equipment != null) _buildEquipmentDetail(equipment),
      ],
    );
  }

  Widget _buildViewTab(BuildContext context) {
    return MarkerViewTab(
      visibleDefectCategories: visibleDefectCategories,
      visibleEquipmentCategories: visibleEquipmentCategories,
      onDefectVisibilityChanged: onDefectVisibilityChanged,
      onEquipmentVisibilityChanged: onEquipmentVisibilityChanged,
      equipmentLabelBuilder: equipmentChipLabel,
    );
  }

  Widget _buildDefectDetail(Defect defect) {
    final label = defectDisplayLabel(defect);
    final details = defect.details;
    final rows = <MarkerDetailRowData>[
      if (details.structuralMember.isNotEmpty)
        MarkerDetailRowData('부재', details.structuralMember),
      if (details.crackType.isNotEmpty)
        MarkerDetailRowData('형태', details.crackType),
      if (details.cause.isNotEmpty) MarkerDetailRowData('원인', details.cause),
      if (details.widthMm > 0)
        MarkerDetailRowData('폭', '${details.widthMm} mm'),
      if (details.lengthMm > 0)
        MarkerDetailRowData('길이', '${details.lengthMm} mm'),
    ];
    return MarkerDetailSection(
      title: label,
      subtitle: '${defect.category.label} · 페이지 ${defect.pageIndex}',
      rows: rows,
    );
  }

  Widget _buildEquipmentDetail(EquipmentMarker marker) {
    final label = equipmentDisplayLabel(marker, equipmentMarkers);
    final displayPage = toDisplayPageFromZeroBased(marker.pageIndex - 1);
    final rows = <MarkerDetailRowData>[
      if (marker.memberType?.isNotEmpty == true)
        MarkerDetailRowData('부재', marker.memberType!),
      if (marker.numberText?.isNotEmpty == true)
        MarkerDetailRowData('번호', marker.numberText!),
      if (marker.sizeValues != null && marker.sizeValues!.isNotEmpty)
        MarkerDetailRowData('규격', marker.sizeValues!.join(' / ')),
      if (marker.maxValueText?.isNotEmpty == true)
        MarkerDetailRowData('최대값', marker.maxValueText!),
      if (marker.minValueText?.isNotEmpty == true)
        MarkerDetailRowData('최소값', marker.minValueText!),
      if (marker.avgValueText?.isNotEmpty == true)
        MarkerDetailRowData('평균값', marker.avgValueText!),
      if (marker.coverThicknessText?.isNotEmpty == true)
        MarkerDetailRowData('피복두께', marker.coverThicknessText!),
      if (marker.depthText?.isNotEmpty == true)
        MarkerDetailRowData('깊이', marker.depthText!),
      if (marker.tiltDirection?.isNotEmpty == true)
        MarkerDetailRowData('기울기', marker.tiltDirection!),
      if (marker.displacementText?.isNotEmpty == true)
        MarkerDetailRowData('변위', marker.displacementText!),
      if (marker.deflectionEndAText?.isNotEmpty == true)
        MarkerDetailRowData('처짐 A', marker.deflectionEndAText!),
      if (marker.deflectionMidBText?.isNotEmpty == true)
        MarkerDetailRowData('처짐 B', marker.deflectionMidBText!),
      if (marker.deflectionEndCText?.isNotEmpty == true)
        MarkerDetailRowData('처짐 C', marker.deflectionEndCText!),
    ];
    return MarkerDetailSection(
      title: label,
      subtitle:
          '${equipmentCategoryDisplayNameKo(marker.category)} · 페이지 $displayPage',
      rows: rows,
    );
  }
}
