import 'dart:io';

import 'package:flutter/material.dart';
import 'package:safety_inspection_app/models/defect.dart';
import 'package:safety_inspection_app/models/defect_details.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/equipment_marker.dart';
import 'package:safety_inspection_app/models/rebar_spacing_group_details.dart';
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

  int toDisplayPageFromZeroBased(int pageIndex) => pageIndex + 1;

  static const List<DefectCategory> defectCategories = [
    DefectCategory.generalCrack,
    DefectCategory.waterLeakage,
    DefectCategory.concreteSpalling,
    DefectCategory.steelDefect,
    DefectCategory.other,
  ];

  static const Set<String> _equipment1WHMembers = {'기둥', '보', '철골 각형강관'};
  static const Set<String> _equipment1DiameterMembers = {'원형기둥', '브레이싱'};
  static const Set<String> _equipment1ThkMembers = {'벽체', '슬래브'};

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
    final isDefectVisible =
        selectedDefectCategory != null &&
        visibleDefectCategories.contains(selectedDefectCategory);
    final filteredDefects = defects
        .where(
          (defect) =>
              defect.pageIndex == currentPage &&
              selectedDefectCategory != null &&
              defect.category == selectedDefectCategory &&
              visibleDefectCategories.contains(defect.category),
        )
        .toList();
    final isEquipmentVisible =
        selectedEquipmentCategory != null &&
        visibleEquipmentCategories.contains(selectedEquipmentCategory);
    final selectedEquipmentLabel =
        selectedEquipmentCategory == null
            ? null
            : equipmentChipLabel(
              selectedEquipmentCategory ?? EquipmentCategory.equipment1,
            );
    final filteredEquipment = equipmentMarkers
        .where(
          (marker) =>
              marker.pageIndex == currentPage &&
              selectedEquipmentCategory != null &&
              marker.category == selectedEquipmentCategory &&
              visibleEquipmentCategories.contains(marker.category),
        )
        .toList();
    final defectDetail =
        selectedDefect != null
            ? _buildDefectDetail(context, selectedDefect!)
            : null;
    final equipmentDetail =
        selectedEquipment != null
            ? _buildEquipmentDetail(selectedEquipment!)
            : null;
    final detailWidgets = <Widget>[
      if (defectDetail != null) defectDetail,
      if (equipmentDetail != null) equipmentDetail,
    ];
    final hasSelection = detailWidgets.isNotEmpty;
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
                options: defectCategories,
                selected: selectedDefectCategory,
                labelBuilder: defectChipLabel,
                onSelected: onDefectCategorySelected,
              ),
              defectInfoBanner:
                  selectedDefectCategory != null && !isDefectVisible
                      ? MarkerInfoBanner(
                        message:
                            "보기 탭에서 '${selectedDefectCategory?.label ?? '결함'}' 표시가 꺼져 있어요. 켜면 목록이 보입니다.",
                      )
                      : null,
              defectItems: filteredDefects,
              defectEmptyLabel: '현재 페이지에 결함 마커가 없습니다.',
              onSelectDefect: onSelectDefect,
              defectTitleBuilder: defectDisplayLabel,
              defectSubtitleBuilder:
                  (defect) =>
                      defect.details.structuralMember.isNotEmpty
                          ? defect.details.structuralMember
                          : null,
              equipmentFilter: MarkerFilterChips<EquipmentCategory>(
                options: kEquipmentCategoryOrder,
                selected: selectedEquipmentCategory,
                labelBuilder: equipmentChipLabel,
                onSelected: onEquipmentCategorySelected,
              ),
              equipmentInfoBanner:
                  selectedEquipmentCategory != null && !isEquipmentVisible
                      ? MarkerInfoBanner(
                        message:
                            "보기 탭에서 '${selectedEquipmentLabel ?? '장비'}' 표시가 꺼져 있어요. 켜면 목록이 보입니다.",
                      )
                      : null,
              equipmentItems: filteredEquipment,
              equipmentEmptyLabel: '현재 페이지에 장비 마커가 없습니다.',
              onSelectEquipment: onSelectEquipment,
              equipmentTitleBuilder:
                  (marker) => equipmentDisplayLabel(marker, equipmentMarkers),
              equipmentSubtitleBuilder:
                  (marker) =>
                      marker.memberType?.isNotEmpty == true
                          ? marker.memberType
                          : null,
              detailWidgets: detailWidgets,
              hasSelection: hasSelection,
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

  Widget _buildDefectDetail(BuildContext context, Defect defect) {
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
    final photoPreview = _buildDefectPhotoPreview(
      context,
      details.photoPaths,
      details.photoOriginalNamesByPath,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MarkerDetailSection(
          title: defectPanelTitle(defect),
          subtitle: '${defect.category.label} · 페이지 ${defect.pageIndex}',
          rows: rows,
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
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap:
                    () => _handlePhotoTap(
                      context,
                      photoPaths,
                      photoOriginalNamesByPath,
                    ),
                child:
                    hasFile
                        ? Image.file(
                          file,
                          fit: BoxFit.cover,
                          cacheWidth: 800,
                        )
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
                final maxScale = transformationControllers[index]
                    .value
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
                            physics:
                                isZoomed
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
                                child:
                                    hasFile
                                        ? Image.file(
                                          file,
                                          fit: BoxFit.contain,
                                        )
                                        : Center(
                                          child: Text(
                                            '사진을 불러올 수 없습니다',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall?.copyWith(
                                              color:
                                                  Theme.of(
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
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                photoDisplayName(
                                  storedPath: photoPaths[currentIndex],
                                  originalNamesByPath:
                                      photoOriginalNamesByPath,
                                ),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color:
                                          Theme.of(
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

  Widget _buildEquipmentDetail(EquipmentMarker marker) {
    final displayPage = toDisplayPageFromZeroBased(marker.pageIndex - 1);
    final isEquipment1 = marker.category == EquipmentCategory.equipment1;
    final isEquipment2 = marker.category == EquipmentCategory.equipment2;
    final isEquipment3 = marker.category == EquipmentCategory.equipment3;
    final rebarGroup =
        isEquipment2
            ? rebarSpacingGroupFromMarker(
              marker,
              defaultPrefix: equipmentPrefixFor(marker.category),
            )
            : null;
    final sizeText = isEquipment1 ? _equipment1SizeText(marker) : null;
    final remarkValue =
        isEquipment1
            ? (marker.remark?.isNotEmpty == true ? marker.remark! : '-')
            : isEquipment2 && rebarGroup == null
            ? _equipment2RemarkText(marker)
            : null;
    final numberValue =
        isEquipment2 && rebarGroup == null
            ? _equipment2NumberText(marker)
            : marker.numberText?.isNotEmpty == true
            ? marker.numberText
            : null;
    final schmidtAngle = marker.schmidtAngleDeg ?? 0;
    final schmidtMinRaw = marker.schmidtMinValue ?? marker.minValueText;
    final schmidtMaxRaw = marker.schmidtMaxValue ?? marker.maxValueText;
    final schmidtMin =
        schmidtMinRaw?.trim().isNotEmpty == true ? schmidtMinRaw!.trim() : '-';
    final schmidtMax =
        schmidtMaxRaw?.trim().isNotEmpty == true ? schmidtMaxRaw!.trim() : '-';
    final memberType =
        marker.memberType?.isNotEmpty == true
            ? marker.memberType
            : rebarGroup?.memberType;
    final rows = <MarkerDetailRowData>[
      if (memberType?.isNotEmpty == true)
        MarkerDetailRowData('부재', memberType!),
      if (isEquipment3) MarkerDetailRowData('각도', '$schmidtAngle°'),
      if (isEquipment3)
        MarkerDetailRowData('최솟/최댓', '$schmidtMin/$schmidtMax'),
      if (rebarGroup != null)
        ..._buildRebarSpacingRows(rebarGroup)
      else if (isEquipment2 && remarkValue != null)
        MarkerDetailRowData('비고', remarkValue),
      if (isEquipment2 && numberValue != null && rebarGroup == null)
        MarkerDetailRowData('번호', numberValue),
      if (sizeText != null && sizeText.isNotEmpty)
        MarkerDetailRowData('규격', sizeText),
      if (!isEquipment2 && remarkValue != null)
        MarkerDetailRowData('비고', remarkValue),
      if (!isEquipment1 &&
          marker.sizeValues != null &&
          marker.sizeValues!.isNotEmpty)
        MarkerDetailRowData('규격', marker.sizeValues!.join(' / ')),
      if (!isEquipment3 && marker.maxValueText?.isNotEmpty == true)
        MarkerDetailRowData('최대값', marker.maxValueText!),
      if (!isEquipment3 && marker.minValueText?.isNotEmpty == true)
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
      title: equipmentPanelTitle(marker, equipmentMarkers),
      subtitle: '페이지 $displayPage',
      rows: rows,
    );
  }

  String? _equipment1SizeText(EquipmentMarker marker) {
    final values = marker.sizeValues;
    if (values == null || values.isEmpty) {
      return null;
    }
    final memberType = marker.memberType;
    if (_equipment1WHMembers.contains(memberType)) {
      final wValue = values.isNotEmpty ? values[0] : '';
      final hValue = values.length > 1 ? values[1] : '';
      final wLabel = (marker.wComplete ?? true) ? 'A' : 'a';
      final hLabel = (marker.hComplete ?? true) ? 'B' : 'b';
      return '$wLabel : $wValue / $hLabel : $hValue';
    }
    if (_equipment1DiameterMembers.contains(memberType)) {
      final dValue = values.isNotEmpty ? values[0] : '';
      return '⌀ : $dValue';
    }
    if (_equipment1ThkMembers.contains(memberType)) {
      final dValue = values.isNotEmpty ? values[0] : '';
      final label = (marker.dComplete ?? true) ? 'Thk' : 'thk';
      return '$label : $dValue';
    }
    return values.join(' / ');
  }

  String _equipment2NumberText(EquipmentMarker marker) {
    final formatted = _formatEquipment2Number(
      prefix: marker.numberPrefix,
      value: marker.numberValue,
    );
    if (formatted != null && formatted.isNotEmpty) {
      return formatted;
    }
    if (marker.numberText?.isNotEmpty == true) {
      return marker.numberText!;
    }
    return '-';
  }

  String _equipment2RemarkText(EquipmentMarker marker) {
    final left = marker.remarkLeft?.trim() ?? '';
    final right = marker.remarkRight?.trim() ?? '';
    final hasLeft = left.isNotEmpty;
    final hasRight = right.isNotEmpty;
    if (hasLeft && hasRight) {
      return '$left/$right';
    }
    if (hasLeft) {
      return left;
    }
    if (hasRight) {
      return right;
    }
    return '-';
  }

  List<MarkerDetailRowData> _buildRebarSpacingRows(
    RebarSpacingGroupDetails group,
  ) {
    return group.measurements.asMap().entries.map((entry) {
      final index = entry.key;
      final measurement = entry.value;
      final remarkText = _rebarSpacingRemarkText(measurement);
      final numberText = _rebarSpacingNumberText(measurement);
      final value =
          remarkText == '-' && numberText == '-'
              ? '-'
              : remarkText == '-'
              ? numberText
              : numberText == '-'
              ? remarkText
              : '$remarkText $numberText';
      return MarkerDetailRowData(group.labelForIndex(index), value);
    }).toList();
  }

  String _rebarSpacingRemarkText(RebarSpacingMeasurement measurement) {
    final left = measurement.remarkLeft?.trim() ?? '';
    final right = measurement.remarkRight?.trim() ?? '';
    final hasLeft = left.isNotEmpty;
    final hasRight = right.isNotEmpty;
    if (hasLeft && hasRight) {
      return '$left/$right';
    }
    if (hasLeft) {
      return left;
    }
    if (hasRight) {
      return right;
    }
    return '-';
  }

  String _rebarSpacingNumberText(RebarSpacingMeasurement measurement) {
    final formatted = _formatEquipment2Number(
      prefix: measurement.numberPrefix,
      value: measurement.numberValue,
    );
    if (formatted != null && formatted.isNotEmpty) {
      return formatted;
    }
    return '-';
  }

  String? _formatEquipment2Number({String? prefix, String? value}) {
    final trimmedPrefix = prefix?.trim();
    final trimmedValue = value?.trim();
    final hasPrefix = trimmedPrefix?.isNotEmpty == true;
    final hasValue = trimmedValue?.isNotEmpty == true;
    if (!hasPrefix && !hasValue) {
      return null;
    }
    if (hasPrefix && hasValue) {
      return '$trimmedPrefix$trimmedValue';
    }
    return hasPrefix ? trimmedPrefix : trimmedValue;
  }
}
