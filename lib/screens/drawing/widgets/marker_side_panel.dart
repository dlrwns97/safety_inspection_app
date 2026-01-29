import 'package:flutter/material.dart';
import 'package:safety_inspection_app/models/defect.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/equipment_marker.dart';
import 'package:safety_inspection_app/screens/drawing/flows/marker_presenters.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/marker_filter_chips.dart';

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
          _buildVisibilityInfoBanner(
            context,
            "보기 탭에서 '${selectedDefectCategory.label}' 표시가 꺼져 있어요. 켜면 목록이 보입니다.",
          ),
        const Divider(height: 1),
        Expanded(
          child: _MarkerList(
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
          options: EquipmentCategory.values,
          selected: selectedEquipmentCategory,
          labelBuilder: equipmentChipLabel,
          onSelected: onEquipmentCategorySelected,
        ),
        if (!isVisible)
          _buildVisibilityInfoBanner(
            context,
            "보기 탭에서 '$selectedLabel' 표시가 꺼져 있어요. 켜면 목록이 보입니다.",
          ),
        const Divider(height: 1),
        Expanded(
          child: _MarkerList(
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
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      children: [
        _buildViewSectionTitle(context, '결함'),
        const SizedBox(height: 4),
        for (final category in DefectCategory.values)
          CheckboxListTile(
            value: visibleDefectCategories.contains(category),
            onChanged: (value) =>
                onDefectVisibilityChanged(category, value ?? false),
            title: Text(
              category.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            controlAffinity: ListTileControlAffinity.trailing,
          ),
        const SizedBox(height: 8),
        _buildViewSectionTitle(context, '장비'),
        const SizedBox(height: 4),
        for (final category in EquipmentCategory.values)
          CheckboxListTile(
            value: visibleEquipmentCategories.contains(category),
            onChanged: (value) =>
                onEquipmentVisibilityChanged(category, value ?? false),
            title: Text(
              equipmentChipLabel(category),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            controlAffinity: ListTileControlAffinity.trailing,
          ),
      ],
    );
  }

  Widget _buildViewSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleSmall,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildVisibilityInfoBanner(BuildContext context, String message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              size: 14,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefectDetail(Defect defect) {
    final label = defectDisplayLabel(defect);
    final details = defect.details;
    final rows = <_DetailRowData>[
      if (details.structuralMember.isNotEmpty)
        _DetailRowData('부재', details.structuralMember),
      if (details.crackType.isNotEmpty)
        _DetailRowData('형태', details.crackType),
      if (details.cause.isNotEmpty) _DetailRowData('원인', details.cause),
      if (details.widthMm > 0) _DetailRowData('폭', '${details.widthMm} mm'),
      if (details.lengthMm > 0) _DetailRowData('길이', '${details.lengthMm} mm'),
    ];
    return _DetailSection(
      title: label,
      subtitle: '${defect.category.label} · 페이지 ${defect.pageIndex}',
      rows: rows,
    );
  }

  Widget _buildEquipmentDetail(EquipmentMarker marker) {
    final label = equipmentDisplayLabel(marker, equipmentMarkers);
    final displayPage = toDisplayPageFromZeroBased(marker.pageIndex - 1);
    final rows = <_DetailRowData>[
      if (marker.memberType?.isNotEmpty == true)
        _DetailRowData('부재', marker.memberType!),
      if (marker.numberText?.isNotEmpty == true)
        _DetailRowData('번호', marker.numberText!),
      if (marker.sizeValues != null && marker.sizeValues!.isNotEmpty)
        _DetailRowData('규격', marker.sizeValues!.join(' / ')),
      if (marker.maxValueText?.isNotEmpty == true)
        _DetailRowData('최대값', marker.maxValueText!),
      if (marker.minValueText?.isNotEmpty == true)
        _DetailRowData('최소값', marker.minValueText!),
      if (marker.avgValueText?.isNotEmpty == true)
        _DetailRowData('평균값', marker.avgValueText!),
      if (marker.coverThicknessText?.isNotEmpty == true)
        _DetailRowData('피복두께', marker.coverThicknessText!),
      if (marker.depthText?.isNotEmpty == true)
        _DetailRowData('깊이', marker.depthText!),
      if (marker.tiltDirection?.isNotEmpty == true)
        _DetailRowData('기울기', marker.tiltDirection!),
      if (marker.displacementText?.isNotEmpty == true)
        _DetailRowData('변위', marker.displacementText!),
      if (marker.deflectionEndAText?.isNotEmpty == true)
        _DetailRowData('처짐 A', marker.deflectionEndAText!),
      if (marker.deflectionMidBText?.isNotEmpty == true)
        _DetailRowData('처짐 B', marker.deflectionMidBText!),
      if (marker.deflectionEndCText?.isNotEmpty == true)
        _DetailRowData('처짐 C', marker.deflectionEndCText!),
    ];
    return _DetailSection(
      title: label,
      subtitle:
          '${equipmentCategoryDisplayNameKo(marker.category)} · 페이지 $displayPage',
      rows: rows,
    );
  }
}

class _MarkerList<T> extends StatelessWidget {
  const _MarkerList({
    required this.items,
    required this.emptyLabel,
    required this.onTap,
    required this.titleBuilder,
    required this.subtitleBuilder,
  });

  final List<T> items;
  final String emptyLabel;
  final ValueChanged<T> onTap;
  final String Function(T item) titleBuilder;
  final String? Function(T item) subtitleBuilder;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(emptyLabel),
      );
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        final subtitle = subtitleBuilder(item);
        return ListTile(
          title: Text(
            titleBuilder(item),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          onTap: () => onTap(item),
        );
      },
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.subtitle,
    required this.rows,
  });

  final String title;
  final String subtitle;
  final List<_DetailRowData> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerTitleStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w600,
    );
    final headerSubtitleStyle = theme.textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: headerTitleStyle),
          const SizedBox(height: 4),
          Text(subtitle, style: headerSubtitleStyle),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            Text(
              '표시할 상세 정보가 없습니다.',
              style: theme.textTheme.bodyMedium,
            )
          else
            ...rows.map((row) => _DetailRow(row: row)),
        ],
      ),
    );
  }
}

class _DetailRowData {
  const _DetailRowData(this.label, this.value);

  final String label;
  final String value;
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.row});

  final _DetailRowData row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            child: Text(
              row.label,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              row.value,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
