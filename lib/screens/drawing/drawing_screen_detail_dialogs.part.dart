part of 'drawing_screen.dart';

extension _DrawingScreenDetailDialogsLogic on _DrawingScreenState {
  Future<DefectDetails?> _showDefectDetailsDialog({
    String? defectId,
    DefectCategory? category,
    DefectDetails? initialDetails,
  }) async {
    final defectCategory =
        category ?? _activeCategory ?? DefectCategory.generalCrack;
    final defectConfig = defectCategoryConfig(defectCategory);
    final resolvedDefectId =
        defectId ??
        _selectedDefect?.id ??
        DateTime.now().microsecondsSinceEpoch.toString();
    return _showDetailDialog(
      () => showDefectDetailsDialog(
        context: context,
        title: defectConfig.dialogTitle,
        typeOptions: defectConfig.typeOptions,
        causeOptions: defectConfig.causeOptions,
        siteId: _site.id,
        defectId: resolvedDefectId,
        initialDetails: initialDetails,
      ),
    );
  }

  Future<EquipmentDetails?> _showEquipmentDetailsDialog({
    required String title,
    String? initialMemberType,
    List<String>? initialSizeValues,
    String? initialRemark,
    bool? initialWComplete,
    bool? initialHComplete,
    bool? initialDComplete,
  }) async {
    return _showDetailDialog(
      () => showEquipmentDetailsDialog(
        context: context,
        title: title,
        memberOptions: DrawingEquipmentMemberOptions,
        sizeLabelsByMember: DrawingEquipmentMemberSizeLabels,
        initialMemberType: initialMemberType,
        initialSizeValues: initialSizeValues,
        initialRemark: initialRemark,
        initialWComplete: initialWComplete,
        initialHComplete: initialHComplete,
        initialDComplete: initialDComplete,
      ),
    );
  }

  Future<RebarSpacingGroupDetails?> _showRebarSpacingDialog({
    required String title,
    String? initialMemberType,
    List<RebarSpacingMeasurement>? initialMeasurements,
    bool allowMultiple = false,
    int? baseLabelIndex,
    String? labelPrefix,
  }) async {
    return _showDetailDialog(
      () => showRebarSpacingDialog(
        context: context,
        title: title,
        memberOptions: DrawingRebarSpacingMemberOptions,
        initialMemberType: initialMemberType,
        initialMeasurements: initialMeasurements,
        allowMultiple: allowMultiple,
        baseLabelIndex: baseLabelIndex,
        labelPrefix: labelPrefix,
      ),
    );
  }

  Future<SchmidtHammerDetails?> _showSchmidtHammerDialog({
    required String title,
    String? initialMemberType,
    int? initialAngleDeg,
    String? initialMaxValueText,
    String? initialMinValueText,
  }) async {
    return _showDetailDialog(
      () => showSchmidtHammerDialog(
        context: context,
        title: title,
        memberOptions: DrawingSchmidtHammerMemberOptions,
        initialMemberType: initialMemberType,
        initialAngleDeg: initialAngleDeg,
        initialMaxValueText: initialMaxValueText,
        initialMinValueText: initialMinValueText,
      ),
    );
  }

  Future<CoreSamplingDetails?> _showCoreSamplingDialog({
    required String title,
    String? initialMemberType,
    String? initialAvgValueText,
  }) async {
    return _showDetailDialog(
      () => showCoreSamplingDialog(
        context: context,
        title: title,
        memberOptions: DrawingCoreSamplingMemberOptions,
        initialMemberType: initialMemberType,
        initialAvgValueText: initialAvgValueText,
      ),
    );
  }

  Future<CarbonationDetails?> _showCarbonationDialog({
    required String title,
    String? initialMemberType,
    String? initialCoverThicknessText,
    String? initialDepthText,
  }) async {
    return _showDetailDialog(
      () => showCarbonationDialog(
        context: context,
        title: title,
        memberOptions: DrawingCarbonationMemberOptions,
        initialMemberType: initialMemberType,
        initialCoverThicknessText: initialCoverThicknessText,
        initialDepthText: initialDepthText,
      ),
    );
  }

  Future<StructuralTiltDetails?> _showStructuralTiltDialog({
    required String title,
    String? initialDirection,
    String? initialDisplacementText,
  }) async {
    return _showDetailDialog(
      () => showStructuralTiltDialog(
        context: context,
        title: title,
        initialDirection: initialDirection,
        initialDisplacementText: initialDisplacementText,
      ),
    );
  }

  Future<SettlementDetails?> _showSettlementDialog({
    required String baseTitle,
    required Map<String, int> nextIndexByDirection,
    String? initialDirection,
    String? initialDisplacementText,
  }) async {
    return _showDetailDialog(
      () => showSettlementDialog(
        context: context,
        baseTitle: baseTitle,
        nextIndexByDirection: nextIndexByDirection,
        initialDirection: initialDirection,
        initialDisplacementText: initialDisplacementText,
      ),
    );
  }

  Future<DeflectionDetails?> _showDeflectionDialog({
    required String title,
    String? initialMemberType,
    String? initialEndAText,
    String? initialMidBText,
    String? initialEndCText,
  }) async {
    return _showDetailDialog(
      () => showDeflectionDialog(
        context: context,
        title: title,
        memberOptions: DrawingDeflectionMemberOptions,
        initialMemberType: initialMemberType,
        initialEndAText: initialEndAText,
        initialMidBText: initialMidBText,
        initialEndCText: initialEndCText,
      ),
    );
  }

  Future<void> _handleOverlapSelection(List<MarkerHitResult> hits) async {
    if (hits.isEmpty || _isDetailDialogOpen) {
      return;
    }
    if (hits.length == 1) {
      _selectMarker(hits.first);
      return;
    }
    final ordered = _orderOverlapHits(hits);
    await _showOverlapSelectorSheet(ordered);
  }

  List<MarkerHitResult> _orderOverlapHits(List<MarkerHitResult> hits) {
    final items = hits
        .asMap()
        .entries
        .map(
          (entry) => (
            index: entry.key,
            createdIndex: entry.value.defect != null
                ? _createdIndexFromId(entry.value.defect!.id)
                : _createdIndexFromId(entry.value.equipment!.id),
            hit: entry.value,
          ),
        )
        .toList();
    final hasCreatedIndex = items.every((item) => item.createdIndex != null);
    if (hasCreatedIndex) {
      items.sort((a, b) => a.createdIndex!.compareTo(b.createdIndex!));
    } else {
      items.sort((a, b) => a.index.compareTo(b.index));
    }
    return items.map((item) => item.hit).toList();
  }

  String _overlapMarkerTitle(MarkerHitResult hit) {
    final defect = hit.defect;
    if (defect != null) {
      return defectPanelTitle(defect, allDefects: _site.defects);
    }
    return equipmentPanelTitle(hit.equipment!, _site.equipmentMarkers);
  }

  Future<void> _showOverlapSelectorSheet(
    List<MarkerHitResult> orderedHits,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: orderedHits.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final hit = orderedHits[index];
              return ListTile(
                title: Text(
                  _overlapMarkerTitle(hit),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _selectMarker(hit);
                },
              );
            },
          ),
        );
      },
    );
  }
}
