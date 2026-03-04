import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safety_inspection_app/presentation/drawing/states/tool_state.dart';
import 'package:safety_inspection_app/screens/drawing/drawing_types.dart';

void main() {
  group('ToolState', () {
    test('has expected defaults', () {
      final state = ToolState();

      expect(state.activeTool, DrawingTool.pen);
      expect(state.activeFamily, ToolFamily.pen);
      expect(state.currentPenWidth, 3.0);
      expect(state.currentPenColor, const Color(0xFF000000));
      expect(state.currentHlOpacity, 0.35);
      expect(state.isStraightenModeEnabled, isFalse);
      expect(state.isStraightenSnapEnabled, isTrue);
    });

    test('stores variant maps and mutable tool options', () {
      final state = ToolState();
      state.penWidthByType[PenUiType.fountainPen] = 4.0;
      state.hlOpacityByType[HighlighterUiType.marker] = 0.8;
      state.currentShapeWidth = 12.0;
      state.isShapeAspectLocked = true;

      expect(state.penWidthByType[PenUiType.fountainPen], 4.0);
      expect(state.hlOpacityByType[HighlighterUiType.marker], 0.8);
      expect(state.currentShapeWidth, 12.0);
      expect(state.isShapeAspectLocked, isTrue);
    });
  });
}
