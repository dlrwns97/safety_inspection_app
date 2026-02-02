import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import 'package:safety_inspection_app/models/drawing_enums.dart';

const Size DrawingCanvasSize = Size(1200, 1700);
const double DrawingCanvasMinScale = 0.5;
const double DrawingCanvasMaxScale = 4.0;
const PhotoViewComputedScale PdfDrawingInitialScale =
    PhotoViewComputedScale.contained;
const PhotoViewComputedScale PdfDrawingMinScale =
    PhotoViewComputedScale.contained;
const double PdfDrawingMaxScaleMultiplier = 2.0;
const double DrawingTapSlop = 8.0;
const List<String> DrawingEquipmentMemberOptions = [
  '기둥',
  '보',
  '철골 각형강관',
  '원형기둥',
  '벽체',
  '슬래브',
  '브레이싱',
  '철골 L형강',
  '철골 C찬넬',
  '철골 H형강',
];
const List<String> DrawingConcreteMemberOptions = [
  '기둥',
  '보',
  '벽체',
  '슬래브',
];
const List<String> DrawingRebarSpacingMemberOptions =
    DrawingConcreteMemberOptions;
const List<String> DrawingSchmidtHammerMemberOptions =
    DrawingConcreteMemberOptions;
const List<String> DrawingCoreSamplingMemberOptions =
    DrawingConcreteMemberOptions;
const List<String> DrawingCarbonationMemberOptions =
    DrawingConcreteMemberOptions;
const List<String> DrawingDeflectionMemberOptions = [
  '보',
  '슬래브',
];
const Map<String, List<String>> DrawingEquipmentMemberSizeLabels = {
  '기둥': ['A', 'B'],
  '보': ['A', 'B'],
  '철골 각형강관': ['A', 'B'],
  '원형기둥': ['⌀'],
  '벽체': ['Thk'],
  '슬래브': ['Thk'],
  '브레이싱': ['⌀'],
  '철골 L형강': ['A', 'B', 't'],
  '철골 C찬넬': ['A', 'B', 't'],
  '철골 H형강': ['H', 'B', 'tw', 'tf'],
};

class EquipmentFlowConfig {
  const EquipmentFlowConfig({
    required this.category,
    required this.labelPrefix,
    required this.dialogTitlePrefix,
    required this.color,
    this.displayLabelPrefix,
  });

  final EquipmentCategory category;
  final String labelPrefix;
  final String dialogTitlePrefix;
  final String? displayLabelPrefix;
  final Color color;
}

const Map<EquipmentCategory, EquipmentFlowConfig> DrawingEquipmentFlowConfigs = {
  EquipmentCategory.equipment1: EquipmentFlowConfig(
    category: EquipmentCategory.equipment1,
    labelPrefix: 'S',
    dialogTitlePrefix: '부재단면치수',
    color: Colors.pinkAccent,
  ),
  EquipmentCategory.equipment2: EquipmentFlowConfig(
    category: EquipmentCategory.equipment2,
    labelPrefix: 'F',
    dialogTitlePrefix: '철근배근간격',
    displayLabelPrefix: '철근배근간격',
    color: Colors.lightBlueAccent,
  ),
  EquipmentCategory.equipment3: EquipmentFlowConfig(
    category: EquipmentCategory.equipment3,
    labelPrefix: 'SH',
    dialogTitlePrefix: '슈미트해머',
    displayLabelPrefix: '슈미트해머',
    color: Colors.green,
  ),
  EquipmentCategory.equipment4: EquipmentFlowConfig(
    category: EquipmentCategory.equipment4,
    labelPrefix: 'Co',
    dialogTitlePrefix: '코어채취',
    displayLabelPrefix: '코어채취',
    color: Colors.green,
  ),
  EquipmentCategory.equipment5: EquipmentFlowConfig(
    category: EquipmentCategory.equipment5,
    labelPrefix: 'Ch',
    dialogTitlePrefix: '콘크리트 탄산화',
    displayLabelPrefix: '콘크리트 탄산화',
    color: Colors.orangeAccent,
  ),
  EquipmentCategory.equipment6: EquipmentFlowConfig(
    category: EquipmentCategory.equipment6,
    labelPrefix: 'Tr',
    dialogTitlePrefix: '구조물 기울기',
    displayLabelPrefix: '구조물 기울기',
    color: Colors.tealAccent,
  ),
  EquipmentCategory.equipment7: EquipmentFlowConfig(
    category: EquipmentCategory.equipment7,
    labelPrefix: 'L',
    dialogTitlePrefix: '부재처짐',
    displayLabelPrefix: '부재처짐',
    color: Colors.indigoAccent,
  ),
};
