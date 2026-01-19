enum DrawingType { pdf, blank }

enum DrawMode { defect, equipment, freeDraw, eraser }

enum DefectCategory {
  generalCrack('General crack'),
  waterLeakage('Water leakage'),
  concreteSpalling('Concrete spalling'),
  other('Other defect');

  const DefectCategory(this.label);
  final String label;
}
