import 'package:flutter/material.dart';

const Size DrawingCanvasSize = Size(1200, 1700);
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
const List<String> DrawingRebarSpacingMemberOptions = [
  '기둥',
  '보',
  '벽체',
  '슬래브',
];
const List<String> DrawingSchmidtHammerMemberOptions = [
  '기둥',
  '보',
  '벽체',
  '슬래브',
];
const List<String> DrawingCoreSamplingMemberOptions = [
  '기둥',
  '보',
  '벽체',
  '슬래브',
];
const List<String> DrawingCarbonationMemberOptions = [
  '기둥',
  '보',
  '벽체',
  '슬래브',
];
const List<String> DrawingDeflectionMemberOptions = [
  '보',
  '슬래브',
];
const Map<String, List<String>> DrawingEquipmentMemberSizeLabels = {
  '기둥': ['W', 'H'],
  '보': ['W', 'H'],
  '철골 각형강관': ['W', 'H'],
  '원형기둥': ['D'],
  '벽체': ['D'],
  '슬래브': ['D'],
  '브레이싱': ['D'],
  '철골 L형강': ['A', 'B', 't'],
  '철골 C찬넬': ['A', 'B', 't'],
  '철골 H형강': ['H', 'B', 'tw', 'tf'],
};
