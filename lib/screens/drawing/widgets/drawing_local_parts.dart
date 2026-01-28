import 'package:flutter/material.dart';

import 'package:safety_inspection_app/models/defect.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/equipment_marker.dart';

class MarkerHitResult {
  const MarkerHitResult({
    required this.defect,
    required this.equipment,
    required this.position,
  });

  final Defect? defect;
  final EquipmentMarker? equipment;
  final Offset position;
}

class DefectMarkerWidget extends StatelessWidget {
  const DefectMarkerWidget({
    required this.label,
    required this.category,
    required this.color,
    required this.isSelected,
    super.key,
  });

  final String label;
  final DefectCategory category;
  final Color color;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? Theme.of(context).colorScheme.onPrimary
        : Colors.transparent;
    return Tooltip(
      message: category.label,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: isSelected ? 3 : 0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class EquipmentMarkerWidget extends StatelessWidget {
  const EquipmentMarkerWidget({
    required this.label,
    required this.category,
    required this.color,
    required this.isSelected,
    super.key,
  });

  final String label;
  final EquipmentCategory category;
  final Color color;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? Theme.of(context).colorScheme.onPrimary
        : Colors.transparent;
    return Tooltip(
      message: category.label,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: isSelected ? 3 : 0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  GridPainter({required this.lineColor});

  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    const step = 60.0;
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor;
  }
}
