import 'package:flutter/material.dart';
import 'package:safety_inspection_app/screens/drawing/engines/shape_engine.dart';
import 'package:safety_inspection_app/screens/drawing/drawing_types.dart';

enum ToolFamily { pen, highlighter }

enum PenUiType { pen, fountainPen, calligraphy, pencil }

enum HighlighterUiType { highlighter, marker }

class ToolState {
  ToolState({
    this.activeTool = DrawingTool.pen,
    this.activeFamily = ToolFamily.pen,
    this.activePenType = PenUiType.pen,
    this.activeHighlighterType = HighlighterUiType.highlighter,
    this.currentPenWidth = 3.0,
    this.currentPenColor = const Color(0xFF000000),
    this.currentHlWidth = 3.0,
    this.currentHlOpacity = 0.35,
    this.currentHlColor = const Color(0xFF000000),
    this.currentShapeWidth = 3.0,
    this.currentShapeOpacity = 1.0,
    this.currentShapeStrokeColor = const Color(0xFF000000),
    this.currentShapeFillColor,
    this.isPenStraightenModeEnabled = false,
    this.isPenStraightenSnapEnabled = true,
    this.isHighlighterStraightenModeEnabled = false,
    this.isHighlighterStraightenSnapEnabled = true,
    this.isShapeAspectLocked = false,
    this.isShapeRotateSnapEnabled = false,
    this.shapeRotateSnappedAngleRad,
  });

  DrawingTool activeTool;
  ToolFamily activeFamily;
  PenUiType activePenType;
  HighlighterUiType activeHighlighterType;

  final Map<PenUiType, double> penWidthByType = <PenUiType, double>{};
  final Map<PenUiType, Color> penColorByType = <PenUiType, Color>{};
  final Map<HighlighterUiType, double> hlWidthByType =
      <HighlighterUiType, double>{};
  final Map<HighlighterUiType, double> hlOpacityByType =
      <HighlighterUiType, double>{};
  final Map<HighlighterUiType, Color> hlColorByType =
      <HighlighterUiType, Color>{};
  final Map<ShapeType, double> shapeWidthByType = <ShapeType, double>{};
  final Map<ShapeType, double> shapeOpacityByType = <ShapeType, double>{};
  final Map<ShapeType, Color> shapeStrokeColorByType = <ShapeType, Color>{};
  final Map<ShapeType, Color?> shapeFillColorByType = <ShapeType, Color?>{};

  double currentPenWidth;
  Color currentPenColor;
  double currentHlWidth;
  double currentHlOpacity;
  Color currentHlColor;
  double currentShapeWidth;
  double currentShapeOpacity;
  Color currentShapeStrokeColor;
  Color? currentShapeFillColor;

  bool isPenStraightenModeEnabled;
  bool isPenStraightenSnapEnabled;
  bool isHighlighterStraightenModeEnabled;
  bool isHighlighterStraightenSnapEnabled;
  bool isShapeAspectLocked;
  bool isShapeRotateSnapEnabled;
  double? shapeRotateSnappedAngleRad;
}
