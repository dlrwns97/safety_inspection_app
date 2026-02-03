import 'package:flutter/material.dart';

import 'package:safety_inspection_app/models/defect.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/equipment_marker.dart';
import 'package:safety_inspection_app/screens/drawing/flows/marker_presenters.dart';

const double kMarkerBaseSize = 30.0;

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
    this.scale = 1.0,
    this.labelScale = 1.0,
    super.key,
  });

  final String label;
  final DefectCategory category;
  final Color color;
  final bool isSelected;
  final double scale;
  final double labelScale;

  @override
  Widget build(BuildContext context) {
    final scaledSize =
        (kMarkerBaseSize * scale).clamp(kMarkerBaseSize * 0.2, 44.0);
    final borderColor = isSelected
        ? Colors.black
        : Colors.transparent;
    final baseFontSize =
        (Theme.of(context).textTheme.labelMedium?.fontSize ?? 12);
    final labelStyle = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontSize: (baseFontSize - 1) * labelScale,
        );
    return IgnorePointer(
      ignoring: true,
      child: Tooltip(
        message: category.label,
        child: Container(
          width: scaledSize,
          height: scaledSize,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: isSelected ? 4 : 0),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: labelStyle,
            ),
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
    this.scale = 1.0,
    this.labelScale = 1.0,
    super.key,
  });

  final String label;
  final EquipmentCategory category;
  final Color color;
  final bool isSelected;
  final double scale;
  final double labelScale;

  @override
  Widget build(BuildContext context) {
    final scaledSize =
        (kMarkerBaseSize * scale).clamp(kMarkerBaseSize * 0.2, 44.0);
    final borderColor = isSelected
        ? Colors.black
        : Colors.transparent;
    final baseFontSize =
        (Theme.of(context).textTheme.labelMedium?.fontSize ?? 12);
    final labelStyle = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontSize: (baseFontSize - 1) * labelScale,
        );
    return IgnorePointer(
      ignoring: true,
      child: Tooltip(
        message: equipmentCategoryDisplayNameKo(category),
        child: Container(
          width: scaledSize,
          height: scaledSize,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: isSelected ? 4 : 0),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: labelStyle,
            ),
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
