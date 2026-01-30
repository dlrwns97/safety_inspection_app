import 'package:safety_inspection_app/models/drawing_enums.dart';

class DrawingController {
  DrawMode toggleMode(DrawMode currentMode, DrawMode nextMode) {
    return currentMode == nextMode ? DrawMode.hand : nextMode;
  }

  DrawMode returnToToolSelection() => DrawMode.hand;

  bool isToolSelectionMode(DrawMode mode) => mode == DrawMode.hand;

  bool shouldShowDefectCategoryPicker(DrawMode mode) {
    return mode == DrawMode.defect;
  }

  DefectTabState addDefectCategory({
    required List<DefectCategory> tabs,
    required DefectCategory selectedCategory,
  }) {
    final updatedTabs = List<DefectCategory>.from(tabs);
    if (!updatedTabs.contains(selectedCategory)) {
      updatedTabs.add(selectedCategory);
    }
    return DefectTabState(tabs: updatedTabs, activeCategory: selectedCategory);
  }

  DefectTabState removeDefectCategory({
    required List<DefectCategory> tabs,
    required DefectCategory category,
    required DefectCategory? activeCategory,
  }) {
    final updatedTabs = List<DefectCategory>.from(tabs)..remove(category);
    final nextActiveCategory = activeCategory == category
        ? (updatedTabs.isNotEmpty ? updatedTabs.first : null)
        : activeCategory;
    return DefectTabState(
      tabs: updatedTabs,
      activeCategory: nextActiveCategory,
    );
  }

  DefectTabState selectDefectCategory({
    required List<DefectCategory> tabs,
    required DefectCategory category,
  }) {
    return DefectTabState(tabs: tabs, activeCategory: category);
  }

  EquipmentSelectionState selectEquipmentCategory(
    EquipmentCategory? category,
  ) {
    return EquipmentSelectionState(activeCategory: category);
  }

  TapDecision handleCanvasTapDecision({
    required bool isDetailDialogOpen,
    required bool tapCanceled,
    required bool isWithinCanvas,
    required bool hasHitResult,
    required DrawMode mode,
    required bool hasActiveDefectCategory,
    required bool hasActiveEquipmentCategory,
  }) {
    if (isDetailDialogOpen) {
      return const TapDecision();
    }
    if (tapCanceled) {
      return const TapDecision(resetTapCanceled: true);
    }
    if (!isWithinCanvas) {
      return const TapDecision(shouldClearSelection: true);
    }
    return _handleTapDecision(
      hasHitResult: hasHitResult,
      mode: mode,
      hasActiveDefectCategory: hasActiveDefectCategory,
      hasActiveEquipmentCategory: hasActiveEquipmentCategory,
    );
  }

  TapDecision handlePdfTapDecision({
    required bool isDetailDialogOpen,
    required bool tapCanceled,
    required bool isWithinCanvas,
    required bool hasHitResult,
    required DrawMode mode,
    required bool hasActiveDefectCategory,
    required bool hasActiveEquipmentCategory,
  }) {
    if (isDetailDialogOpen) {
      return const TapDecision();
    }
    if (tapCanceled) {
      return const TapDecision(resetTapCanceled: true);
    }
    if (!isWithinCanvas) {
      return const TapDecision(shouldClearSelection: true);
    }
    return _handleTapDecision(
      hasHitResult: hasHitResult,
      mode: mode,
      hasActiveDefectCategory: hasActiveDefectCategory,
      hasActiveEquipmentCategory: hasActiveEquipmentCategory,
    );
  }

  TapDecision _handleTapDecision({
    required bool hasHitResult,
    required DrawMode mode,
    required bool hasActiveDefectCategory,
    required bool hasActiveEquipmentCategory,
  }) {
    if (hasHitResult) {
      return const TapDecision(shouldSelectHit: true);
    }

    if (mode == DrawMode.defect && !hasActiveDefectCategory) {
      return const TapDecision(
        shouldClearSelection: true,
        shouldShowDefectCategoryHint: true,
      );
    }
    if (mode == DrawMode.equipment && !hasActiveEquipmentCategory) {
      return const TapDecision(shouldClearSelection: true);
    }
    if (mode != DrawMode.defect && mode != DrawMode.equipment) {
      return const TapDecision(shouldClearSelection: true);
    }

    return const TapDecision(
      shouldClearSelection: true,
      shouldCreateMarker: true,
    );
  }
}

class DefectTabState {
  const DefectTabState({
    required this.tabs,
    required this.activeCategory,
  });

  final List<DefectCategory> tabs;
  final DefectCategory? activeCategory;
}

class EquipmentSelectionState {
  const EquipmentSelectionState({required this.activeCategory});

  final EquipmentCategory? activeCategory;
}

class TapDecision {
  const TapDecision({
    this.resetTapCanceled = false,
    this.shouldSelectHit = false,
    this.shouldClearSelection = false,
    this.shouldShowDefectCategoryHint = false,
    this.shouldCreateMarker = false,
  });

  final bool resetTapCanceled;
  final bool shouldSelectHit;
  final bool shouldClearSelection;
  final bool shouldShowDefectCategoryHint;
  final bool shouldCreateMarker;
}
