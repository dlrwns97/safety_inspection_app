import 'package:safety_inspection_app/screens/drawing/models/drawing_stroke.dart';

class StrokePresets {
  const StrokePresets._();

  static List<StrokeStyle> defaults() {
    return <StrokeStyle>[
      const StrokeStyle(
        kind: StrokeToolKind.pen,
        variant: PenVariant.pen,
        widthPx: 3.0,
        argbColor: 0xFF000000,
        opacity: 1.0,
      ),
      const StrokeStyle(
        kind: StrokeToolKind.pen,
        variant: PenVariant.calligraphyPen,
        widthPx: 6.0,
        argbColor: 0xFF000000,
        opacity: 1.0,
      ),
      const StrokeStyle(
        kind: StrokeToolKind.highlighter,
        variant: PenVariant.highlighter,
        widthPx: 14.0,
        argbColor: 0xFFFFEB3B,
        opacity: 0.35,
      ),
      const StrokeStyle(
        kind: StrokeToolKind.highlighter,
        variant: PenVariant.highlighterChisel,
        widthPx: 16.0,
        argbColor: 0xFFFFEB3B,
        opacity: 0.30,
      ),
    ];
  }
}
