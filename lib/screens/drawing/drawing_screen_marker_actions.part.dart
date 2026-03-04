part of 'drawing_screen.dart';

extension _DrawingScreenMarkerActions on _DrawingScreenState {
  void _handleEditPressed() async {
    final selectedDefect = _selectedDefect;
    final selectedEquipment = _selectedEquipment;
    if (selectedDefect == null && selectedEquipment == null) {
      return;
    }
    if (selectedDefect != null) {
      final detailsResult = await _showDefectDetailsDialog(
        category: selectedDefect.category,
        initialDetails: selectedDefect.details,
      );
      if (detailsResult == null) {
        return;
      }
      final updatedDefect = Defect(
        id: selectedDefect.id,
        label: selectedDefect.label,
        pageIndex: selectedDefect.pageIndex,
        category: selectedDefect.category,
        normalizedX: selectedDefect.normalizedX,
        normalizedY: selectedDefect.normalizedY,
        details: detailsResult,
      );
      final updatedDefects = _site.defects
          .map(
            (defect) => defect.id == updatedDefect.id ? updatedDefect : defect,
          )
          .toList();
      final updatedSite = _site.copyWith(defects: updatedDefects);
      await _applyUpdatedSite(
        updatedSite,
        onStateUpdated: () {
          _selectedDefectId = updatedDefect.id;
          _selectedEquipmentId = null;
        },
      );
      return;
    }
    if (selectedEquipment != null) {
      final updatedMarker = await _editEquipmentMarker(selectedEquipment);
      if (updatedMarker == null) {
        return;
      }
      final updatedMarkers = _site.equipmentMarkers
          .map(
            (marker) => marker.id == updatedMarker.id ? updatedMarker : marker,
          )
          .toList();
      final updatedSite = _site.copyWith(equipmentMarkers: updatedMarkers);
      await _applyUpdatedSite(
        updatedSite,
        onStateUpdated: () {
          _selectedDefectId = null;
          _selectedEquipmentId = updatedMarker.id;
        },
      );
    }
  }

  Future<EquipmentMarker?> _editEquipmentMarker(EquipmentMarker marker) async {
    if (marker.category == EquipmentCategory.equipment8) {
      final nextIndexByDirection = {
        'Lx': nextSettlementIndex(_site, 'Lx'),
        'Ly': nextSettlementIndex(_site, 'Ly'),
      };
      final details = await _showSettlementDialog(
        baseTitle: '부동침하',
        nextIndexByDirection: nextIndexByDirection,
        initialDirection: settlementDirection(marker),
        initialDisplacementText: marker.displacementText,
      );
      if (details == null) {
        return null;
      }
      return marker.copyWith(
        equipmentTypeId: details.direction,
        tiltDirection: details.direction,
        displacementText: details.displacementText,
      );
    }
    final siteWithoutMarker = _site.copyWith(
      equipmentMarkers: _site.equipmentMarkers
          .where((item) => item.id != marker.id)
          .toList(),
    );
    final updatedSite = await createEquipmentUpdatedSite(
      context: context,
      site: siteWithoutMarker,
      activeEquipmentCategory: marker.category,
      pendingMarker: marker,
      prefix: equipmentLabelPrefix(marker.category),
      allowRebarSpacingMulti: true,
      deflectionMemberOptions: DrawingDeflectionMemberOptions,
      showEquipmentDetailsDialog: _showEquipmentDetailsDialog,
      showRebarSpacingDialog:
          (
            context, {
            required title,
            initialMemberType,
            initialMeasurements,
            allowMultiple = false,
            baseLabelIndex,
            labelPrefix,
          }) => _showRebarSpacingDialog(
            title: title,
            initialMemberType: initialMemberType,
            initialMeasurements: initialMeasurements,
            allowMultiple: allowMultiple,
            baseLabelIndex: baseLabelIndex,
            labelPrefix: labelPrefix,
          ),
      showSchmidtHammerDialog:
          (
            context, {
            required title,
            initialMemberType,
            initialAngleDeg,
            initialMaxValueText,
            initialMinValueText,
          }) => _showSchmidtHammerDialog(
            title: title,
            initialMemberType: initialMemberType,
            initialAngleDeg: initialAngleDeg,
            initialMaxValueText: initialMaxValueText,
            initialMinValueText: initialMinValueText,
          ),
      showCoreSamplingDialog:
          (context, {required title, initialMemberType, initialAvgValueText}) =>
              _showCoreSamplingDialog(
                title: title,
                initialMemberType: initialMemberType,
                initialAvgValueText: initialAvgValueText,
              ),
      showCarbonationDialog: _showCarbonationDialog,
      showStructuralTiltDialog: _showStructuralTiltDialog,
      showDeflectionDialog:
          ({
            required title,
            required memberOptions,
            initialMemberType,
            initialEndAText,
            initialMidBText,
            initialEndCText,
          }) => _showDeflectionDialog(
            title: title,
            initialMemberType: initialMemberType,
            initialEndAText: initialEndAText,
            initialMidBText: initialMidBText,
            initialEndCText: initialEndCText,
          ),
    );
    if (updatedSite == null) {
      return null;
    }
    for (final item in updatedSite.equipmentMarkers) {
      if (item.id == marker.id) {
        return item;
      }
    }
    return null;
  }

  void _handleMovePressed() {
    if (_isMoveMode) {
      _cancelMoveMode();
      return;
    }
    if (_selectedDefect == null && _selectedEquipment == null) {
      return;
    }
    _enterMoveMode();
  }

  void _handleDeletePressed() {
    _confirmDeleteSelectedMarker();
  }

  Future<void> _confirmDeleteSelectedMarker() async {
    final selectedDefect = _selectedDefect;
    final selectedEquipment = _selectedEquipment;
    if (selectedDefect == null && selectedEquipment == null) {
      return;
    }
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: const Text('정말로 삭제 하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('아니오'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('예'),
            ),
          ],
        );
      },
    );
    if (shouldDelete != true || !mounted) {
      return;
    }
    if (selectedDefect != null) {
      final updatedDefects = _site.defects
          .where((defect) => defect.id != selectedDefect.id)
          .toList();
      await _applyUpdatedSite(
        _site.copyWith(defects: updatedDefects),
        onStateUpdated: () {
          _clearSelectionAndPopup(inSetState: false);
        },
      );
      return;
    }
    if (selectedEquipment != null) {
      final updatedMarkers = _site.equipmentMarkers
          .where((marker) => marker.id != selectedEquipment.id)
          .toList();
      await _applyUpdatedSite(
        _site.copyWith(equipmentMarkers: updatedMarkers),
        onStateUpdated: () {
          _clearSelectionAndPopup(inSetState: false);
        },
      );
    }
  }

  GlobalKey _pdfTapRegionKeyForPage(int pageNumber) {
    return _pdfTapRegionKeys.putIfAbsent(pageNumber, () => GlobalKey());
  }

  void _handleSidePanelTabChanged() {
    final index = _sidePanelController.index;
    if (_sidePanelTabIndex == index) {
      return;
    }
    _sidePanelTabIndex = index;
  }
}
