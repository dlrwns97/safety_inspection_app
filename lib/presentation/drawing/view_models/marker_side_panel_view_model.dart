import 'package:safety_inspection_app/models/defect.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/equipment_marker.dart';
import 'package:safety_inspection_app/models/rebar_spacing_group_details.dart';
import 'package:safety_inspection_app/screens/drawing/flows/marker_presenters.dart';

class MarkerSidePanelViewModel {
  MarkerSidePanelViewModel({
    required int currentPage,
    required List<Defect> defects,
    required List<EquipmentMarker> equipmentMarkers,
    required DefectCategory? selectedDefectCategory,
    required EquipmentCategory? selectedEquipmentCategory,
    required Set<DefectCategory> visibleDefectCategories,
    required Set<EquipmentCategory> visibleEquipmentCategories,
    required Defect? selectedDefect,
    required EquipmentMarker? selectedEquipment,
  }) : _allDefects = defects,
       _allEquipmentMarkers = equipmentMarkers,
       filteredDefects = _filterDefects(
         currentPage: currentPage,
         defects: defects,
         selectedDefectCategory: selectedDefectCategory,
         visibleDefectCategories: visibleDefectCategories,
       ),
       filteredEquipment = _filterEquipment(
         currentPage: currentPage,
         equipmentMarkers: equipmentMarkers,
         selectedEquipmentCategory: selectedEquipmentCategory,
         visibleEquipmentCategories: visibleEquipmentCategories,
       ),
       defectInfoMessage = _buildDefectInfoMessage(
         selectedDefectCategory: selectedDefectCategory,
         visibleDefectCategories: visibleDefectCategories,
       ),
       equipmentInfoMessage = _buildEquipmentInfoMessage(
         selectedEquipmentCategory: selectedEquipmentCategory,
         visibleEquipmentCategories: visibleEquipmentCategories,
       ),
       defectDetail = selectedDefect == null
           ? null
           : DefectDetailViewModel.fromDefect(selectedDefect, defects),
       equipmentDetail = selectedEquipment == null
           ? null
           : EquipmentDetailViewModel.fromMarker(
               selectedEquipment,
               equipmentMarkers,
             );

  static const List<DefectCategory> defectCategories = [
    DefectCategory.generalCrack,
    DefectCategory.waterLeakage,
    DefectCategory.concreteSpalling,
    DefectCategory.steelDefect,
    DefectCategory.other,
  ];

  final List<Defect> _allDefects;
  final List<EquipmentMarker> _allEquipmentMarkers;
  final List<Defect> filteredDefects;
  final List<EquipmentMarker> filteredEquipment;
  final String? defectInfoMessage;
  final String? equipmentInfoMessage;
  final DefectDetailViewModel? defectDetail;
  final EquipmentDetailViewModel? equipmentDetail;

  bool get hasSelection => defectDetail != null || equipmentDetail != null;

  String defectFilterChipLabel(DefectCategory category) {
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

  String equipmentFilterChipLabel(EquipmentCategory category) {
    return equipmentChipLabel(category);
  }

  String defectListTitle(Defect defect) {
    return defectDisplayLabel(defect, allDefects: _allDefects);
  }

  String? defectListSubtitle(Defect defect) {
    final member = defect.details.structuralMember;
    return member.isNotEmpty ? member : null;
  }

  String equipmentListTitle(EquipmentMarker marker) {
    return equipmentDisplayLabel(marker, _allEquipmentMarkers);
  }

  String? equipmentListSubtitle(EquipmentMarker marker) {
    final member = marker.memberType;
    return member?.isNotEmpty == true ? member : null;
  }

  String equipmentCategoryLabel(EquipmentCategory category) {
    return equipmentCategoryDisplayNameKo(category);
  }

  static List<Defect> _filterDefects({
    required int currentPage,
    required List<Defect> defects,
    required DefectCategory? selectedDefectCategory,
    required Set<DefectCategory> visibleDefectCategories,
  }) {
    return defects
        .where(
          (defect) =>
              defect.pageIndex == currentPage &&
              selectedDefectCategory != null &&
              defect.category == selectedDefectCategory &&
              visibleDefectCategories.contains(defect.category),
        )
        .toList();
  }

  static List<EquipmentMarker> _filterEquipment({
    required int currentPage,
    required List<EquipmentMarker> equipmentMarkers,
    required EquipmentCategory? selectedEquipmentCategory,
    required Set<EquipmentCategory> visibleEquipmentCategories,
  }) {
    return equipmentMarkers
        .where(
          (marker) =>
              marker.pageIndex == currentPage &&
              selectedEquipmentCategory != null &&
              marker.category == selectedEquipmentCategory &&
              visibleEquipmentCategories.contains(marker.category),
        )
        .toList();
  }

  static String? _buildDefectInfoMessage({
    required DefectCategory? selectedDefectCategory,
    required Set<DefectCategory> visibleDefectCategories,
  }) {
    if (selectedDefectCategory == null ||
        visibleDefectCategories.contains(selectedDefectCategory)) {
      return null;
    }
    final categoryLabel = defectCategoryDisplayNameKo(selectedDefectCategory);
    return "보기 탭에서 '$categoryLabel' 표시가 꺼져 있어요. 켜면 목록이 보입니다.";
  }

  static String? _buildEquipmentInfoMessage({
    required EquipmentCategory? selectedEquipmentCategory,
    required Set<EquipmentCategory> visibleEquipmentCategories,
  }) {
    if (selectedEquipmentCategory == null ||
        visibleEquipmentCategories.contains(selectedEquipmentCategory)) {
      return null;
    }
    final equipmentLabel = equipmentChipLabel(selectedEquipmentCategory);
    return "보기 탭에서 '$equipmentLabel' 표시가 꺼져 있어요. 켜면 목록이 보입니다.";
  }
}

class MarkerDetailRowViewModel {
  const MarkerDetailRowViewModel(this.label, this.value);

  final String label;
  final String value;
}

class DefectDetailViewModel {
  const DefectDetailViewModel({
    required this.title,
    required this.subtitle,
    required this.rows,
    required this.photoPaths,
    required this.photoOriginalNamesByPath,
  });

  factory DefectDetailViewModel.fromDefect(
    Defect defect,
    List<Defect> allDefects,
  ) {
    final details = defect.details;
    return DefectDetailViewModel(
      title: defectPanelTitle(defect, allDefects: allDefects),
      subtitle:
          '${defectCategoryDisplayNameKo(defect.category)} · 페이지 ${defect.pageIndex}',
      rows: <MarkerDetailRowViewModel>[
        if (details.structuralMember.isNotEmpty)
          MarkerDetailRowViewModel('부재', details.structuralMember),
        if (details.crackType.isNotEmpty)
          MarkerDetailRowViewModel('형태', details.crackType),
        if (details.cause.isNotEmpty)
          MarkerDetailRowViewModel('원인', details.cause),
        if (details.widthMm > 0)
          MarkerDetailRowViewModel('폭', '${details.widthMm} mm'),
        if (details.lengthMm > 0)
          MarkerDetailRowViewModel('길이', '${details.lengthMm} mm'),
      ],
      photoPaths: details.photoPaths,
      photoOriginalNamesByPath: details.photoOriginalNamesByPath,
    );
  }

  final String title;
  final String subtitle;
  final List<MarkerDetailRowViewModel> rows;
  final List<String> photoPaths;
  final Map<String, String> photoOriginalNamesByPath;
}

class EquipmentDetailViewModel {
  const EquipmentDetailViewModel({
    required this.title,
    required this.subtitle,
    required this.rows,
  });

  static const Set<String> _equipment1WHMembers = {'기둥', '보', '철골 각형강관'};
  static const Set<String> _equipment1DiameterMembers = {'원형기둥', '브레이싱'};
  static const Set<String> _equipment1ThkMembers = {'벽체', '슬래브'};

  factory EquipmentDetailViewModel.fromMarker(
    EquipmentMarker marker,
    List<EquipmentMarker> allEquipmentMarkers,
  ) {
    final isEquipment1 = marker.category == EquipmentCategory.equipment1;
    final isEquipment2 = marker.category == EquipmentCategory.equipment2;
    final isEquipment3 = marker.category == EquipmentCategory.equipment3;

    final rebarGroup = isEquipment2
        ? equipment2DisplayGroup(marker, allEquipmentMarkers)
        : null;

    final sizeText = isEquipment1 ? _equipment1SizeText(marker) : null;
    final remarkValue = isEquipment1
        ? (marker.remark?.isNotEmpty == true ? marker.remark! : '-')
        : isEquipment2 && rebarGroup == null
        ? _equipment2RemarkText(marker)
        : null;
    final numberValue = isEquipment2 && rebarGroup == null
        ? _equipment2NumberText(marker)
        : marker.numberText?.isNotEmpty == true
        ? marker.numberText
        : null;
    final schmidtAngle = marker.schmidtAngleDeg ?? 0;
    final schmidtMinRaw = marker.schmidtMinValue ?? marker.minValueText;
    final schmidtMaxRaw = marker.schmidtMaxValue ?? marker.maxValueText;
    final schmidtMin = schmidtMinRaw?.trim().isNotEmpty == true
        ? schmidtMinRaw!.trim()
        : '-';
    final schmidtMax = schmidtMaxRaw?.trim().isNotEmpty == true
        ? schmidtMaxRaw!.trim()
        : '-';
    final memberType = marker.memberType?.isNotEmpty == true
        ? marker.memberType
        : rebarGroup?.memberType;

    final rows = <MarkerDetailRowViewModel>[
      if (memberType?.isNotEmpty == true)
        MarkerDetailRowViewModel('부재', memberType!),
      if (isEquipment3) MarkerDetailRowViewModel('각도', '$schmidtAngle°'),
      if (isEquipment3)
        MarkerDetailRowViewModel('최솟/최댓', '$schmidtMin/$schmidtMax'),
      if (rebarGroup != null)
        ..._buildRebarSpacingRows(rebarGroup)
      else if (isEquipment2 && remarkValue != null)
        MarkerDetailRowViewModel('비고', remarkValue),
      if (isEquipment2 && numberValue != null && rebarGroup == null)
        MarkerDetailRowViewModel('번호', numberValue),
      if (sizeText != null && sizeText.isNotEmpty)
        MarkerDetailRowViewModel('규격', sizeText),
      if (!isEquipment2 && remarkValue != null)
        MarkerDetailRowViewModel('비고', remarkValue),
      if (!isEquipment1 &&
          marker.sizeValues != null &&
          marker.sizeValues!.isNotEmpty)
        MarkerDetailRowViewModel('규격', marker.sizeValues!.join(' / ')),
      if (!isEquipment3 && marker.maxValueText?.isNotEmpty == true)
        MarkerDetailRowViewModel('최대값', marker.maxValueText!),
      if (!isEquipment3 && marker.minValueText?.isNotEmpty == true)
        MarkerDetailRowViewModel('최소값', marker.minValueText!),
      if (marker.avgValueText?.isNotEmpty == true)
        MarkerDetailRowViewModel('평균값', marker.avgValueText!),
      if (marker.coverThicknessText?.isNotEmpty == true)
        MarkerDetailRowViewModel('피복두께', marker.coverThicknessText!),
      if (marker.depthText?.isNotEmpty == true)
        MarkerDetailRowViewModel('깊이', marker.depthText!),
      if (marker.tiltDirection?.isNotEmpty == true)
        MarkerDetailRowViewModel('기울기', marker.tiltDirection!),
      if (marker.displacementText?.isNotEmpty == true)
        MarkerDetailRowViewModel('변위', marker.displacementText!),
      if (marker.deflectionEndAText?.isNotEmpty == true)
        MarkerDetailRowViewModel('처짐 A', marker.deflectionEndAText!),
      if (marker.deflectionMidBText?.isNotEmpty == true)
        MarkerDetailRowViewModel('처짐 B', marker.deflectionMidBText!),
      if (marker.deflectionEndCText?.isNotEmpty == true)
        MarkerDetailRowViewModel('처짐 C', marker.deflectionEndCText!),
    ];

    return EquipmentDetailViewModel(
      title: equipmentPanelTitle(marker, allEquipmentMarkers),
      subtitle: '페이지 ${marker.pageIndex}',
      rows: rows,
    );
  }

  final String title;
  final String subtitle;
  final List<MarkerDetailRowViewModel> rows;

  static String? _equipment1SizeText(EquipmentMarker marker) {
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

  static String _equipment2NumberText(EquipmentMarker marker) {
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

  static String _equipment2RemarkText(EquipmentMarker marker) {
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

  static List<MarkerDetailRowViewModel> _buildRebarSpacingRows(
    RebarSpacingGroupDetails group,
  ) {
    return group.measurements.asMap().entries.map((entry) {
      final index = entry.key;
      final measurement = entry.value;
      final remarkText = _rebarSpacingRemarkText(measurement);
      final numberText = _rebarSpacingNumberText(measurement);
      final value = remarkText == '-' && numberText == '-'
          ? '-'
          : remarkText == '-'
          ? numberText
          : numberText == '-'
          ? remarkText
          : '$remarkText $numberText';
      return MarkerDetailRowViewModel(group.labelForIndex(index), value);
    }).toList();
  }

  static String _rebarSpacingRemarkText(RebarSpacingMeasurement measurement) {
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

  static String _rebarSpacingNumberText(RebarSpacingMeasurement measurement) {
    final formatted = _formatEquipment2Number(
      prefix: measurement.numberPrefix,
      value: measurement.numberValue,
    );
    if (formatted != null && formatted.isNotEmpty) {
      return formatted;
    }
    return '-';
  }

  static String? _formatEquipment2Number({String? prefix, String? value}) {
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
