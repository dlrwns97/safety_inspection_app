import 'package:flutter/material.dart';
import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';
import 'package:safety_inspection_app/presentation/drawing/states/tool_state.dart';
import 'package:safety_inspection_app/screens/drawing/drawing_types.dart';

class ToolSettingsController {
  const ToolSettingsController();

  int clampPresetIndex(int index, int presetCount) {
    if (presetCount <= 0) {
      return 0;
    }
    return index.clamp(0, presetCount - 1).toInt();
  }

  StrokeToolKind activeToolKindForToolbar({
    required DrawingTool activeTool,
    required ToolFamily activeFamily,
  }) {
    if (activeTool == DrawingTool.areaEraser ||
        activeTool == DrawingTool.strokeEraser) {
      return StrokeToolKind.eraser;
    }
    if (activeTool == DrawingTool.shape) {
      return StrokeToolKind.shape;
    }
    return activeFamily == ToolFamily.highlighter
        ? StrokeToolKind.highlighter
        : StrokeToolKind.pen;
  }

  StrokeToolKind? selectedToolKindForToolbar({
    required bool isFreeDrawMode,
    required DrawingTool activeTool,
    required int? activePresetIndex,
    required ToolFamily activeFamily,
  }) {
    if (!isFreeDrawMode) {
      return null;
    }
    if (activeTool == DrawingTool.pen && activePresetIndex == null) {
      return null;
    }
    return activeToolKindForToolbar(
      activeTool: activeTool,
      activeFamily: activeFamily,
    );
  }

  List<int> buildRecentColors(
    List<int> current,
    int nextArgb, {
    required int maxColors,
  }) {
    final nextRgb = Color(nextArgb).withAlpha(0xFF).toARGB32();
    final updated = <int>[nextRgb, ...current.where((argb) => argb != nextRgb)];
    return updated.take(maxColors).toList(growable: false);
  }

  bool isHighlighterFamilyVariant(PenVariant variant) {
    return variant == PenVariant.highlighter || variant == PenVariant.marker;
  }

  PenUiType penUiTypeFromVariant(PenVariant variant) {
    return switch (variant) {
      PenVariant.fountainPen => PenUiType.fountainPen,
      PenVariant.calligraphyPen => PenUiType.calligraphy,
      PenVariant.pencil => PenUiType.pencil,
      _ => PenUiType.pen,
    };
  }

  PenVariant penVariantFromUiType(PenUiType type) {
    return switch (type) {
      PenUiType.pen => PenVariant.pen,
      PenUiType.fountainPen => PenVariant.fountainPen,
      PenUiType.calligraphy => PenVariant.calligraphyPen,
      PenUiType.pencil => PenVariant.pencil,
    };
  }

  HighlighterUiType highlighterUiTypeFromVariant(PenVariant variant) {
    return variant == PenVariant.marker
        ? HighlighterUiType.marker
        : HighlighterUiType.highlighter;
  }

  PenVariant highlighterVariantFromUiType(HighlighterUiType type) {
    return switch (type) {
      HighlighterUiType.highlighter => PenVariant.highlighter,
      HighlighterUiType.marker => PenVariant.marker,
    };
  }

  StrokeStyle syncCurrentFamilyStyleToPreset({
    required StrokeStyle baseStyle,
    required ToolFamily activeFamily,
    required PenUiType activePenType,
    required HighlighterUiType activeHighlighterType,
    required double currentPenWidth,
    required Color currentPenColor,
    required double currentHighlighterWidth,
    required double currentHighlighterOpacity,
    required Color currentHighlighterColor,
  }) {
    if (activeFamily == ToolFamily.highlighter) {
      return baseStyle.copyWith(
        kind: StrokeToolKind.highlighter,
        variant: highlighterVariantFromUiType(activeHighlighterType),
        widthPx: currentHighlighterWidth,
        opacity: currentHighlighterOpacity,
        argbColor: currentHighlighterColor.toARGB32(),
      );
    }
    return baseStyle.copyWith(
      kind: StrokeToolKind.pen,
      variant: penVariantFromUiType(activePenType),
      widthPx: currentPenWidth,
      argbColor: currentPenColor.toARGB32(),
    );
  }
}
