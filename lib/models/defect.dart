import 'defect_details.dart';
import 'drawing_enums.dart';

class Defect {
  Defect({
    required this.id,
    required this.label,
    required this.pageIndex,
    required this.category,
    required this.normalizedX,
    required this.normalizedY,
    required this.details,
  });

  final String id;
  final String label;
  final int pageIndex;
  final DefectCategory category;
  final double normalizedX;
  final double normalizedY;
  final DefectDetails details;
}
