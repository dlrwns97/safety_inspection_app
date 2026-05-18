import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';
import 'package:safety_inspection_app/screens/drawing/drawing_types.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/eraser_settings_popup.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/highlighter_settings_popup.dart';
import 'package:safety_inspection_app/screens/drawing/widgets/pen_settings_popup.dart';

Widget _host(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Center(child: SizedBox(width: 420, child: child)),
    ),
  );
}

Finder _colorChip(Color color) {
  return find.byWidgetPredicate((widget) {
    if (widget is! Container || widget.decoration is! BoxDecoration) {
      return false;
    }
    final decoration = widget.decoration! as BoxDecoration;
    return decoration.shape == BoxShape.circle && decoration.color == color;
  });
}

void main() {
  group('tool settings popups', () {
    testWidgets(
      'pen popup emits variant, width, color, and straighten changes',
      (tester) async {
        PenVariant? variant;
        double? width;
        Color? color;
        bool? straighten;
        bool? snap;

        await tester.pumpWidget(
          _host(
            PenSettingsPopup(
              currentVariant: PenVariant.pen,
              currentPenWidth: 3,
              currentPenColor: Colors.black,
              recentColors: const [Colors.blue],
              standardPaletteColors: const [Colors.red],
              isStraightenModeEnabled: false,
              straightenSnapEnabled: true,
              onVariantChanged: (value) => variant = value,
              onWidthChanged: (value) => width = value,
              onColorChanged: (value) => color = value,
              onStraightenModeChanged: (value) => straighten = value,
              onStraightenSnapChanged: (value) => snap = value,
              onOpenAllColors: () {},
            ),
          ),
        );

        await tester.tap(find.text('연필'));
        tester.widget<Slider>(find.byType(Slider)).onChanged!(12);
        await tester.tap(_colorChip(const Color(0xFFE53935)).first);
        await tester.tap(find.byType(Checkbox).at(0));
        await tester.tap(find.byType(Checkbox).at(1));

        expect(variant, PenVariant.pencil);
        expect(width, 12);
        expect(color, const Color(0xFFE53935));
        expect(straighten, isTrue);
        expect(snap, isFalse);
      },
    );

    testWidgets(
      'highlighter popup emits variant, width, opacity, color, and straighten changes',
      (tester) async {
        PenVariant? variant;
        double? width;
        double? opacity;
        Color? color;
        bool? straighten;
        bool? snap;

        await tester.pumpWidget(
          _host(
            HighlighterSettingsPopup(
              currentVariant: PenVariant.highlighter,
              currentHighlighterWidth: 8,
              currentHighlighterOpacity: 0.35,
              currentHighlighterColor: Colors.yellow,
              recentColors: const [Colors.green],
              standardPaletteColors: const [Colors.red],
              isStraightenModeEnabled: false,
              straightenSnapEnabled: true,
              onVariantChanged: (value) => variant = value,
              onWidthChanged: (value) => width = value,
              onOpacityChanged: (value) => opacity = value,
              onColorChanged: (value) => color = value,
              onStraightenModeChanged: (value) => straighten = value,
              onStraightenSnapChanged: (value) => snap = value,
              onOpenAllColors: () {},
            ),
          ),
        );

        await tester.tap(find.text('마커'));
        tester.widget<Slider>(find.byType(Slider).at(0)).onChanged!(18);
        tester.widget<Slider>(find.byType(Slider).at(1)).onChanged!(0.7);
        await tester.tap(_colorChip(const Color(0xFFE53935)).first);
        await tester.tap(find.byType(Checkbox).at(0));
        await tester.tap(find.byType(Checkbox).at(1));

        expect(variant, PenVariant.marker);
        expect(width, 18);
        expect(opacity, 0.7);
        expect(color, const Color(0xFFE53935));
        expect(straighten, isTrue);
        expect(snap, isFalse);
      },
    );

    testWidgets('eraser popup emits radius and mode changes', (tester) async {
      double? radius;
      DrawingTool? mode;

      await tester.pumpWidget(
        _host(
          EraserSettingsPopup(
            radiusPx: 24,
            mode: DrawingTool.areaEraser,
            onRadiusChanged: (value) => radius = value,
            onModeChanged: (value) => mode = value,
            onClearPenOnly: () async {},
            onClearHighlighterOnly: () async {},
            onClearAll: () async {},
          ),
        ),
      );

      tester.widget<Slider>(find.byType(Slider)).onChanged!(36);
      await tester.tap(find.byType(SegmentedButton<DrawingTool>));
      tester
          .widget<SegmentedButton<DrawingTool>>(
            find.byType(SegmentedButton<DrawingTool>),
          )
          .onSelectionChanged
          ?.call({DrawingTool.strokeEraser});

      expect(radius, 36);
      expect(mode, DrawingTool.strokeEraser);
    });
  });
}
