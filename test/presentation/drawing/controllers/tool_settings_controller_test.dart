import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';
import 'package:safety_inspection_app/presentation/drawing/controllers/tool_settings_controller.dart';
import 'package:safety_inspection_app/presentation/drawing/states/tool_state.dart';
import 'package:safety_inspection_app/screens/drawing/drawing_types.dart';

void main() {
  group('ToolSettingsController', () {
    const controller = ToolSettingsController();

    test('maps toolbar selection from active tool and family', () {
      expect(
        controller.activeToolKindForToolbar(
          activeTool: DrawingTool.pen,
          activeFamily: ToolFamily.pen,
        ),
        StrokeToolKind.pen,
      );
      expect(
        controller.activeToolKindForToolbar(
          activeTool: DrawingTool.pen,
          activeFamily: ToolFamily.highlighter,
        ),
        StrokeToolKind.highlighter,
      );
      expect(
        controller.activeToolKindForToolbar(
          activeTool: DrawingTool.areaEraser,
          activeFamily: ToolFamily.pen,
        ),
        StrokeToolKind.eraser,
      );
      expect(
        controller.activeToolKindForToolbar(
          activeTool: DrawingTool.shape,
          activeFamily: ToolFamily.pen,
        ),
        StrokeToolKind.shape,
      );
    });

    test('selected toolbar kind is hidden outside drawable state', () {
      expect(
        controller.selectedToolKindForToolbar(
          isFreeDrawMode: false,
          activeTool: DrawingTool.pen,
          activePresetIndex: 0,
          activeFamily: ToolFamily.pen,
        ),
        isNull,
      );
      expect(
        controller.selectedToolKindForToolbar(
          isFreeDrawMode: true,
          activeTool: DrawingTool.pen,
          activePresetIndex: null,
          activeFamily: ToolFamily.pen,
        ),
        isNull,
      );
      expect(
        controller.selectedToolKindForToolbar(
          isFreeDrawMode: true,
          activeTool: DrawingTool.pen,
          activePresetIndex: 0,
          activeFamily: ToolFamily.highlighter,
        ),
        StrokeToolKind.highlighter,
      );
    });

    test('keeps recent colors unique, opaque, and bounded', () {
      final colors = controller.buildRecentColors(
        <int>[0xFF112233, 0xFF445566, 0xFF778899],
        0x44112233,
        maxColors: 3,
      );

      expect(colors, <int>[0xFF112233, 0xFF445566, 0xFF778899]);

      final capped = controller.buildRecentColors(
        colors,
        0xFFAABBCC,
        maxColors: 3,
      );

      expect(capped, <int>[0xFFAABBCC, 0xFF112233, 0xFF445566]);
    });

    test('maps pen and highlighter variants independently', () {
      expect(
        controller.penUiTypeFromVariant(PenVariant.fountainPen),
        PenUiType.fountainPen,
      );
      expect(
        controller.penVariantFromUiType(PenUiType.calligraphy),
        PenVariant.calligraphyPen,
      );
      expect(
        controller.highlighterUiTypeFromVariant(PenVariant.marker),
        HighlighterUiType.marker,
      );
      expect(
        controller.highlighterVariantFromUiType(HighlighterUiType.highlighter),
        PenVariant.highlighter,
      );
      expect(controller.isHighlighterFamilyVariant(PenVariant.pencil), isFalse);
      expect(controller.isHighlighterFamilyVariant(PenVariant.marker), isTrue);
    });

    test('syncs pen family style without leaking highlighter settings', () {
      final next = controller.syncCurrentFamilyStyleToPreset(
        baseStyle: const StrokeStyle(kind: StrokeToolKind.highlighter),
        activeFamily: ToolFamily.pen,
        activePenType: PenUiType.pencil,
        activeHighlighterType: HighlighterUiType.marker,
        currentPenWidth: 7,
        currentPenColor: const Color(0xFF123456),
        currentHighlighterWidth: 30,
        currentHighlighterOpacity: 0.25,
        currentHighlighterColor: const Color(0xFFABCDEF),
      );

      expect(next.kind, StrokeToolKind.pen);
      expect(next.variant, PenVariant.pencil);
      expect(next.widthPx, 7);
      expect(next.argbColor, 0xFF123456);
      expect(next.opacity, 1.0);
    });

    test('syncs highlighter family style without leaking pen settings', () {
      final next = controller.syncCurrentFamilyStyleToPreset(
        baseStyle: const StrokeStyle(kind: StrokeToolKind.pen, widthPx: 2),
        activeFamily: ToolFamily.highlighter,
        activePenType: PenUiType.fountainPen,
        activeHighlighterType: HighlighterUiType.marker,
        currentPenWidth: 7,
        currentPenColor: const Color(0xFF123456),
        currentHighlighterWidth: 30,
        currentHighlighterOpacity: 0.25,
        currentHighlighterColor: const Color(0xFFABCDEF),
      );

      expect(next.kind, StrokeToolKind.highlighter);
      expect(next.variant, PenVariant.marker);
      expect(next.widthPx, 30);
      expect(next.opacity, 0.25);
      expect(next.argbColor, 0xFFABCDEF);
    });
  });
}
