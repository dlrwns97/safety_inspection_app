import 'dart:io';

import 'package:flutter/material.dart';
import 'package:safety_inspection_app/models/defect.dart';
import 'package:safety_inspection_app/models/defect_details.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/equipment_marker.dart';
import 'package:safety_inspection_app/presentation/drawing/view_models/marker_side_panel_view_model.dart';
import 'package:safety_inspection_app/screens/drawing/flows/marker_presenters.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/marker_filter_chips.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/side_panel/marker_detail_section.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/side_panel/marker_side_panel_body.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/side_panel/marker_side_panel_header.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/side_panel/marker_info_banner.dart';
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
    required this.onEditPressed,
    required this.onMovePressed,
    required this.onDeletePressed,
  });

  final TabController tabController;
  final int currentPage;
  final List<Defect> defects;
  final List<EquipmentMarker> equipmentMarkers;
  final DefectCategory? selectedDefectCategory;
  final EquipmentCategory? selectedEquipmentCategory;
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
  final VoidCallback onEditPressed;
  final VoidCallback onMovePressed;
  final VoidCallback onDeletePressed;

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
    final tabLabelStyle = compactTextTheme.labelMedium?.copyWith(fontSize: 12);
    final compactTheme = theme.copyWith(
      textTheme: compactTextTheme,
      listTileTheme: theme.listTileTheme.copyWith(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        visualDensity: VisualDensity.compact,
      ),
    );
    final viewModel = MarkerSidePanelViewModel(
      currentPage: currentPage,
      defects: defects,
      equipmentMarkers: equipmentMarkers,
      selectedDefectCategory: selectedDefectCategory,
      selectedEquipmentCategory: selectedEquipmentCategory,
      visibleDefectCategories: visibleDefectCategories,
      visibleEquipmentCategories: visibleEquipmentCategories,
      selectedDefect: selectedDefect,
      selectedEquipment: selectedEquipment,
    );
    final defectDetail = viewModel.defectDetail != null
        ? _buildDefectDetail(context, viewModel.defectDetail!)
        : null;
    final equipmentDetail = viewModel.equipmentDetail != null
        ? _buildEquipmentDetail(viewModel.equipmentDetail!)
        : null;
    final detailWidgets = <Widget>[
      if (defectDetail != null) defectDetail,
      if (equipmentDetail != null) equipmentDetail,
    ];
    return Theme(
      data: compactTheme,
      child: Material(
        color: theme.colorScheme.surface,
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MarkerSidePanelHeader(
              tabController: tabController,
              tabLabelStyle: tabLabelStyle,
              markerScale: markerScale,
              labelScale: labelScale,
              onMarkerScaleChanged: onMarkerScaleChanged,
              onLabelScaleChanged: onLabelScaleChanged,
              isMarkerScaleLocked: isMarkerScaleLocked,
              onToggleMarkerScaleLock: onToggleMarkerScaleLock,
            ),
            MarkerSidePanelBody(
              tabController: tabController,
              defectFilter: MarkerFilterChips<DefectCategory>(
                options: MarkerSidePanelViewModel.defectCategories,
                selected: selectedDefectCategory,
                labelBuilder: viewModel.defectFilterChipLabel,
                onSelected: onDefectCategorySelected,
              ),
              defectInfoBanner: viewModel.defectInfoMessage != null
                  ? MarkerInfoBanner(message: viewModel.defectInfoMessage!)
                  : null,
              defectItems: viewModel.filteredDefects,
              defectEmptyLabel: '현재 페이지에 결함 마커가 없습니다.',
              onSelectDefect: onSelectDefect,
              defectTitleBuilder: viewModel.defectListTitle,
              defectSubtitleBuilder: viewModel.defectListSubtitle,
              equipmentFilter: MarkerFilterChips<EquipmentCategory>(
                options: kEquipmentCategoryOrder,
                selected: selectedEquipmentCategory,
                labelBuilder: viewModel.equipmentFilterChipLabel,
                onSelected: onEquipmentCategorySelected,
              ),
              equipmentInfoBanner: viewModel.equipmentInfoMessage != null
                  ? MarkerInfoBanner(message: viewModel.equipmentInfoMessage!)
                  : null,
              equipmentItems: viewModel.filteredEquipment,
              equipmentEmptyLabel: '현재 페이지에 장비 마커가 없습니다.',
              onSelectEquipment: onSelectEquipment,
              equipmentTitleBuilder: viewModel.equipmentListTitle,
              equipmentSubtitleBuilder: viewModel.equipmentListSubtitle,
              detailWidgets: detailWidgets,
              hasSelection: viewModel.hasSelection,
              onEditPressed: onEditPressed,
              onMovePressed: onMovePressed,
              onDeletePressed: onDeletePressed,
              viewTab: _buildViewTab(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewTab(BuildContext context) {
    return MarkerViewTab(
      visibleDefectCategories: visibleDefectCategories,
      visibleEquipmentCategories: visibleEquipmentCategories,
      onDefectVisibilityChanged: onDefectVisibilityChanged,
      onEquipmentVisibilityChanged: onEquipmentVisibilityChanged,
      equipmentLabelBuilder: equipmentCategoryDisplayNameKo,
    );
  }

  Widget _buildDefectDetail(
    BuildContext context,
    DefectDetailViewModel detail,
  ) {
    final photoPreview = _buildDefectPhotoPreview(
      context,
      detail.photoPaths,
      detail.photoOriginalNamesByPath,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MarkerDetailSection(
          title: detail.title,
          subtitle: detail.subtitle,
          rows: _toDetailRows(detail.rows),
        ),
        if (photoPreview != null) photoPreview,
      ],
    );
  }

  Widget? _buildDefectPhotoPreview(
    BuildContext context,
    List<String> photoPaths,
    Map<String, String> photoOriginalNamesByPath,
  ) {
    if (photoPaths.isEmpty) {
      return null;
    }
    final theme = Theme.of(context);
    final file = File(photoPaths.first);
    final hasFile = file.existsSync();
    final extraCount = photoPaths.length - 1;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _handlePhotoTap(
                  context,
                  photoPaths,
                  photoOriginalNamesByPath,
                ),
                child: hasFile
                    ? Image.file(file, fit: BoxFit.cover, cacheWidth: 800)
                    : Center(
                        child: Text(
                          '사진을 불러올 수 없습니다',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          if (extraCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '외 $extraCount장',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handlePhotoTap(
    BuildContext context,
    List<String> photoPaths,
    Map<String, String> photoOriginalNamesByPath,
  ) async {
    final size = MediaQuery.sizeOf(context);
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (context) {
        final dialogRadius = BorderRadius.circular(16);
        final controller = PageController(initialPage: 0);
        final transformationControllers = List.generate(
          photoPaths.length,
          (_) => TransformationController(),
        );
        var currentIndex = 0;
        var isZoomed = false;
        return Dialog(
          insetPadding: const EdgeInsets.all(12),
          backgroundColor: Colors.black,
          child: StatefulBuilder(
            builder: (context, setState) {
              void updateZoomState(int index) {
                final maxScale = transformationControllers[index].value
                    .getMaxScaleOnAxis();
                final nextZoomed = maxScale > 1.01;
                if (nextZoomed != isZoomed) {
                  setState(() => isZoomed = nextZoomed);
                }
              }

              return ClipRRect(
                borderRadius: dialogRadius,
                child: SizedBox(
                  width: size.width * 0.9,
                  height: size.height * 0.85,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ColoredBox(
                          color: Colors.black,
                          child: PageView.builder(
                            controller: controller,
                            itemCount: photoPaths.length,
                            physics: isZoomed
                                ? const NeverScrollableScrollPhysics()
                                : const PageScrollPhysics(),
                            onPageChanged: (index) {
                              setState(() => currentIndex = index);
                              updateZoomState(index);
                            },
                            itemBuilder: (context, index) {
                              final file = File(photoPaths[index]);
                              final hasFile = file.existsSync();
                              return InteractiveViewer(
                                clipBehavior: Clip.hardEdge,
                                boundaryMargin: EdgeInsets.zero,
                                minScale: 1.0,
                                maxScale: 8.0,
                                panEnabled: true,
                                scaleEnabled: true,
                                transformationController:
                                    transformationControllers[index],
                                onInteractionUpdate: (_) {
                                  if (index == currentIndex) {
                                    updateZoomState(index);
                                  }
                                },
                                onInteractionEnd: (_) {
                                  if (index == currentIndex) {
                                    updateZoomState(index);
                                  }
                                },
                                child: hasFile
                                    ? Image.file(file, fit: BoxFit.contain)
                                    : Center(
                                        child: Text(
                                          '사진을 불러올 수 없습니다',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                              ),
                                        ),
                                      ),
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          color: Theme.of(context).colorScheme.onSurface,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${currentIndex + 1} / ${photoPaths.length}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                photoDisplayName(
                                  storedPath: photoPaths[currentIndex],
                                  originalNamesByPath: photoOriginalNamesByPath,
                                ),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEquipmentDetail(EquipmentDetailViewModel detail) {
    return MarkerDetailSection(
      title: detail.title,
      subtitle: detail.subtitle,
      rows: _toDetailRows(detail.rows),
    );
  }

  List<MarkerDetailRowData> _toDetailRows(List<MarkerDetailRowViewModel> rows) {
    return rows
        .map((row) => MarkerDetailRowData(row.label, row.value))
        .toList();
  }
}
