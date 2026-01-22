part of 'drawing_screen.dart';

extension _DrawingScreenStateActions on _DrawingScreenState {
  Future<void> _loadPdfController() async {
    final path = _site.pdfPath;
    if (path == null || path.isEmpty) {
      return;
    }
    final previousController = _pdfController;
    _pdfController = null;
    previousController?.dispose();
    final file = File(path);
    final exists = await file.exists();
    if (!mounted) {
      return;
    }
    if (!exists) {
      setState(() {
        _pdfLoadError = StringsKo.pdfDrawingLoadFailed;
      });
      debugPrint('PDF file not found at $path');
      return;
    }
    final fileSize = await file.length();
    debugPrint(
      'Loading PDF: name=${_site.pdfName ?? file.uri.pathSegments.last}, '
      'path=$path, bytes=$fileSize',
    );
    setState(() {
      _pdfController = PdfController(
        document: PdfDocument.openFile(path),
      );
      _pdfLoadError = null;
      _pdfPageSizes.clear();
      _pageCount = 1;
      _currentPage = 1;
    });
  }

  Future<void> _replacePdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    final file = result.files.first;
    String? pdfPath = file.path;
    if (pdfPath == null && file.bytes != null) {
      pdfPath = await _persistPickedPdf(file);
    }
    if (!mounted) {
      return;
    }
    if (pdfPath == null || pdfPath.isEmpty) {
      setState(() {
        _pdfLoadError = StringsKo.pdfDrawingLoadFailed;
      });
      return;
    }
    setState(() {
      _site = _site.copyWith(pdfPath: pdfPath, pdfName: file.name);
      _selectedDefect = null;
      _selectedEquipment = null;
      _selectedMarkerScenePosition = null;
      _pdfPageSizes.clear();
      _currentPage = 1;
      _pageCount = 1;
    });
    await widget.onSiteUpdated(_site);
    if (!mounted) {
      return;
    }
    await _loadPdfController();
  }

  Future<String?> _persistPickedPdf(PlatformFile file) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final blueprintDirectory = Directory(
        '${directory.path}${Platform.pathSeparator}blueprints',
      );
      if (!await blueprintDirectory.exists()) {
        await blueprintDirectory.create(recursive: true);
      }
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'drawing_${timestamp}_${file.name}';
      final savedFile = File(
        '${blueprintDirectory.path}${Platform.pathSeparator}$filename',
      );
      await savedFile.writeAsBytes(file.bytes!, flush: true);
      return savedFile.path;
    } catch (error) {
      debugPrint('Failed to persist picked PDF: $error');
      return null;
    }
  }

  Future<void> _handleCanvasTap(TapUpDetails details) async {
    if (_isDetailDialogOpen) {
      return;
    }
    if (_tapCanceled) {
      _tapCanceled = false;
      return;
    }
    final scenePoint = _transformationController.toScene(details.localPosition);
    if (!_isTapWithinCanvas(details.globalPosition)) {
      _clearSelectedMarker();
      return;
    }

    final hitResult = _hitTestMarkerOnCanvas(scenePoint);
    if (hitResult != null) {
      _selectMarker(hitResult);
      return;
    }

    _clearSelectedMarker();
    if (_mode == DrawMode.defect && _activeCategory == null) {
      _showSelectDefectCategoryHint();
      return;
    }
    if (_mode == DrawMode.equipment && _activeEquipmentCategory == null) {
      return;
    }
    if (_mode != DrawMode.defect && _mode != DrawMode.equipment) {
      return;
    }
    final normalizedX = (scenePoint.dx / _canvasSize.width).clamp(0.0, 1.0);
    final normalizedY = (scenePoint.dy / _canvasSize.height).clamp(0.0, 1.0);

    if (_mode == DrawMode.defect) {
      final detailsResult = await _showDefectDetailsDialog();
      if (!mounted || detailsResult == null) {
        return;
      }

      final countOnPage = _site.defects
          .where(
            (defect) =>
                defect.pageIndex == _currentPage &&
                defect.category == _activeCategory,
          )
          .length;
      final label = _activeCategory == DefectCategory.generalCrack
          ? 'C${countOnPage + 1}'
          : '${countOnPage + 1}';

      final defect = Defect(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        label: label,
        pageIndex: _currentPage,
        category: _activeCategory!,
        normalizedX: normalizedX,
        normalizedY: normalizedY,
        details: detailsResult,
      );

      setState(() {
        _site = _site.copyWith(defects: [..._site.defects, defect]);
      });
      await widget.onSiteUpdated(_site);
    } else {
      if (_activeEquipmentCategory == EquipmentCategory.equipment8) {
        final nextIndices = {
          'Lx': _nextSettlementIndex('Lx'),
          'Ly': _nextSettlementIndex('Ly'),
        };
        final details = await _showSettlementDialog(
          baseTitle: '부동침하',
          nextIndexByDirection: nextIndices,
        );
        if (!mounted || details == null) {
          return;
        }
        final direction = details.direction;
        final label = '$direction${_nextSettlementIndex(direction)}';
        final marker = EquipmentMarker(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          label: label,
          pageIndex: _currentPage,
          category: EquipmentCategory.equipment8,
          normalizedX: normalizedX,
          normalizedY: normalizedY,
          equipmentTypeId: direction,
          tiltDirection: direction,
          displacementText: details.displacementText,
        );
        setState(() {
          _site = _site.copyWith(
            equipmentMarkers: [..._site.equipmentMarkers, marker],
          );
        });
        await widget.onSiteUpdated(_site);
        return;
      }
      final equipmentCount = _site.equipmentMarkers
          .where((marker) => marker.category == _activeEquipmentCategory)
          .length;
      final prefix = equipmentLabelPrefix(_activeEquipmentCategory!);
      final label = '$prefix${equipmentCount + 1}';
      final pendingMarker = EquipmentMarker(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        label: label,
        pageIndex: _currentPage,
        category: _activeEquipmentCategory!,
        normalizedX: normalizedX,
        normalizedY: normalizedY,
        equipmentTypeId: prefix,
      );

      if (_activeEquipmentCategory == EquipmentCategory.equipment1) {
        final details = await _showEquipmentDetailsDialog(
          title: '부재단면치수 ${pendingMarker.label}',
          initialMemberType: pendingMarker.memberType,
          initialSizeValues: pendingMarker.sizeValues,
        );
        if (!mounted || details == null) {
          return;
        }
        final marker = pendingMarker.copyWith(
          equipmentTypeId: prefix,
          memberType: details.memberType,
          sizeValues: details.sizeValues,
        );
        setState(() {
          _site = _site.copyWith(
            equipmentMarkers: [..._site.equipmentMarkers, marker],
          );
        });
        await widget.onSiteUpdated(_site);
        return;
      }
      if (_activeEquipmentCategory == EquipmentCategory.equipment2) {
        final details = await _showRebarSpacingDialog(
          title: equipmentDisplayLabel(pendingMarker),
          initialMemberType: pendingMarker.memberType,
          initialNumberText: pendingMarker.numberText,
        );
        if (!mounted || details == null) {
          return;
        }
        final marker = pendingMarker.copyWith(
          equipmentTypeId: prefix,
          memberType: details.memberType,
          numberText: details.numberText,
        );
        setState(() {
          _site = _site.copyWith(
            equipmentMarkers: [..._site.equipmentMarkers, marker],
          );
        });
        await widget.onSiteUpdated(_site);
        return;
      }
      if (_activeEquipmentCategory == EquipmentCategory.equipment3) {
        final details = await _showSchmidtHammerDialog(
          title: equipmentDisplayLabel(pendingMarker),
          initialMemberType: pendingMarker.memberType,
          initialMaxValueText: pendingMarker.maxValueText,
          initialMinValueText: pendingMarker.minValueText,
        );
        if (!mounted || details == null) {
          return;
        }
        final marker = pendingMarker.copyWith(
          equipmentTypeId: prefix,
          memberType: details.memberType,
          maxValueText: details.maxValueText,
          minValueText: details.minValueText,
        );
        setState(() {
          _site = _site.copyWith(
            equipmentMarkers: [..._site.equipmentMarkers, marker],
          );
        });
        await widget.onSiteUpdated(_site);
        return;
      }
      if (_activeEquipmentCategory == EquipmentCategory.equipment4) {
        final details = await _showCoreSamplingDialog(
          title: equipmentDisplayLabel(pendingMarker),
          initialMemberType: pendingMarker.memberType,
          initialAvgValueText: pendingMarker.avgValueText,
        );
        if (!mounted || details == null) {
          return;
        }
        final marker = pendingMarker.copyWith(
          equipmentTypeId: prefix,
          memberType: details.memberType,
          avgValueText: details.avgValueText,
        );
        setState(() {
          _site = _site.copyWith(
            equipmentMarkers: [..._site.equipmentMarkers, marker],
          );
        });
        await widget.onSiteUpdated(_site);
        return;
      }
      if (_activeEquipmentCategory == EquipmentCategory.equipment5) {
        final details = await _showCarbonationDialog(
          title: equipmentDisplayLabel(pendingMarker),
          initialMemberType: pendingMarker.memberType,
          initialCoverThicknessText: pendingMarker.coverThicknessText,
          initialDepthText: pendingMarker.depthText,
        );
        if (!mounted || details == null) {
          return;
        }
        final marker = pendingMarker.copyWith(
          equipmentTypeId: prefix,
          memberType: details.memberType,
          coverThicknessText: details.coverThicknessText,
          depthText: details.depthText,
        );
        setState(() {
          _site = _site.copyWith(
            equipmentMarkers: [..._site.equipmentMarkers, marker],
          );
        });
        await widget.onSiteUpdated(_site);
        return;
      }
      if (_activeEquipmentCategory == EquipmentCategory.equipment6) {
        final details = await _showStructuralTiltDialog(
          title: equipmentDisplayLabel(pendingMarker),
          initialDirection: pendingMarker.tiltDirection,
          initialDisplacementText: pendingMarker.displacementText,
        );
        if (!mounted || details == null) {
          return;
        }
        final marker = pendingMarker.copyWith(
          equipmentTypeId: prefix,
          tiltDirection: details.direction,
          displacementText: details.displacementText,
        );
        setState(() {
          _site = _site.copyWith(
            equipmentMarkers: [..._site.equipmentMarkers, marker],
          );
        });
        await widget.onSiteUpdated(_site);
        return;
      }
      if (_activeEquipmentCategory == EquipmentCategory.equipment7) {
        final details = await _showDeflectionDialog(
          title: equipmentDisplayLabel(pendingMarker),
          initialMemberType: pendingMarker.memberType,
          initialEndAText: pendingMarker.deflectionEndAText,
          initialMidBText: pendingMarker.deflectionMidBText,
          initialEndCText: pendingMarker.deflectionEndCText,
        );
        if (!mounted || details == null) {
          return;
        }
        final marker = pendingMarker.copyWith(
          equipmentTypeId: prefix,
          memberType: details.memberType,
          deflectionEndAText: details.endAText,
          deflectionMidBText: details.midBText,
          deflectionEndCText: details.endCText,
        );
        setState(() {
          _site = _site.copyWith(
            equipmentMarkers: [..._site.equipmentMarkers, marker],
          );
        });
        await widget.onSiteUpdated(_site);
        return;
      }
      setState(() {
        _site = _site.copyWith(
          equipmentMarkers: [..._site.equipmentMarkers, pendingMarker],
        );
      });
      await widget.onSiteUpdated(_site);
    }
  }

  void _selectMarker(_MarkerHitResult result) {
    setState(() {
      _selectedDefect = result.defect;
      _selectedEquipment = result.equipment;
      _selectedMarkerScenePosition = result.position;
    });
  }

  void _clearSelectedMarker() {
    if (_selectedDefect == null &&
        _selectedEquipment == null &&
        _selectedMarkerScenePosition == null) {
      return;
    }
    setState(() {
      _selectedDefect = null;
      _selectedEquipment = null;
      _selectedMarkerScenePosition = null;
    });
  }

  _MarkerHitResult? _hitTestMarkerOnCanvas(Offset scenePoint) {
    const hitRadius = 24.0;
    final hitRadiusSquared = hitRadius * hitRadius;
    double closestDistance = hitRadiusSquared;
    Defect? defectHit;
    EquipmentMarker? equipmentHit;
    Offset? positionHit;

    for (final defect in _site.defects.where(
      (defect) => defect.pageIndex == _currentPage,
    )) {
      final position = Offset(
        defect.normalizedX * _canvasSize.width,
        defect.normalizedY * _canvasSize.height,
      );
      final distance = (scenePoint - position).distanceSquared;
      if (distance <= closestDistance) {
        closestDistance = distance;
        defectHit = defect;
        equipmentHit = null;
        positionHit = position;
      }
    }

    for (final marker in _site.equipmentMarkers.where(
      (marker) => marker.pageIndex == _currentPage,
    )) {
      final position = Offset(
        marker.normalizedX * _canvasSize.width,
        marker.normalizedY * _canvasSize.height,
      );
      final distance = (scenePoint - position).distanceSquared;
      if (distance <= closestDistance) {
        closestDistance = distance;
        defectHit = null;
        equipmentHit = marker;
        positionHit = position;
      }
    }

    if (positionHit == null) {
      return null;
    }

    return _MarkerHitResult(
      defect: defectHit,
      equipment: equipmentHit,
      position: positionHit,
    );
  }

  _MarkerHitResult? _hitTestMarkerOnPage(
    Offset pagePoint,
    Size pageSize,
    int pageIndex,
  ) {
    const hitRadius = 24.0;
    final hitRadiusSquared = hitRadius * hitRadius;
    double closestDistance = hitRadiusSquared;
    Defect? defectHit;
    EquipmentMarker? equipmentHit;
    Offset? positionHit;

    for (final defect in _site.defects.where(
      (defect) => defect.pageIndex == pageIndex,
    )) {
      final position = Offset(
        defect.normalizedX * pageSize.width,
        defect.normalizedY * pageSize.height,
      );
      final distance = (pagePoint - position).distanceSquared;
      if (distance <= closestDistance) {
        closestDistance = distance;
        defectHit = defect;
        equipmentHit = null;
        positionHit = position;
      }
    }

    for (final marker in _site.equipmentMarkers.where(
      (marker) => marker.pageIndex == pageIndex,
    )) {
      final position = Offset(
        marker.normalizedX * pageSize.width,
        marker.normalizedY * pageSize.height,
      );
      final distance = (pagePoint - position).distanceSquared;
      if (distance <= closestDistance) {
        closestDistance = distance;
        defectHit = null;
        equipmentHit = marker;
        positionHit = position;
      }
    }

    if (positionHit == null) {
      return null;
    }

    return _MarkerHitResult(
      defect: defectHit,
      equipment: equipmentHit,
      position: positionHit,
    );
  }

  bool _isTapWithinCanvas(Offset globalPosition) {
    final context = _canvasKey.currentContext;
    final renderObject = context?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return false;
    }

    final localPosition = renderObject.globalToLocal(globalPosition);
    return localPosition.dx >= 0 &&
        localPosition.dy >= 0 &&
        localPosition.dx <= renderObject.size.width &&
        localPosition.dy <= renderObject.size.height;
  }

  Future<DefectDetails?> _showDefectDetailsDialog() async {
    final defectCategory = _activeCategory ?? DefectCategory.generalCrack;
    return _showDetailDialog(
      () => showDefectDetailsDialog(
        context: context,
        title: defectDialogTitle(defectCategory),
        typeOptions: defectTypeOptions(defectCategory),
        causeOptions: defectCauseOptions(defectCategory),
      ),
    );
  }

  Future<EquipmentDetails?> _showEquipmentDetailsDialog({
    required String title,
    String? initialMemberType,
    List<String>? initialSizeValues,
  }) async {
    return _showDetailDialog(
      () => showEquipmentDetailsDialog(
        context: context,
        title: title,
        memberOptions: _equipmentMemberOptions,
        sizeLabelsByMember: _equipmentMemberSizeLabels,
        initialMemberType: initialMemberType,
        initialSizeValues: initialSizeValues,
      ),
    );
  }

  Future<RebarSpacingDetails?> _showRebarSpacingDialog({
    required String title,
    String? initialMemberType,
    String? initialNumberText,
  }) async {
    return _showDetailDialog(
      () => showRebarSpacingDialog(
        context: context,
        title: title,
        memberOptions: _rebarSpacingMemberOptions,
        initialMemberType: initialMemberType,
        initialNumberText: initialNumberText,
      ),
    );
  }

  Future<SchmidtHammerDetails?> _showSchmidtHammerDialog({
    required String title,
    String? initialMemberType,
    String? initialMaxValueText,
    String? initialMinValueText,
  }) async {
    return _showDetailDialog(
      () => showSchmidtHammerDialog(
        context: context,
        title: title,
        memberOptions: _schmidtHammerMemberOptions,
        initialMemberType: initialMemberType,
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
        memberOptions: _coreSamplingMemberOptions,
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
        memberOptions: _carbonationMemberOptions,
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
        memberOptions: _deflectionMemberOptions,
        initialMemberType: initialMemberType,
        initialEndAText: initialEndAText,
        initialMidBText: initialMidBText,
        initialEndCText: initialEndCText,
      ),
    );
  }

  void _handlePointerDown(Offset position) {
    _pointerDownPosition = position;
    _tapCanceled = false;
  }

  void _handlePointerMove(Offset position) {
    if (_pointerDownPosition == null) {
      return;
    }
    final distance = (position - _pointerDownPosition!).distance;
    if (distance > _tapSlop) {
      _tapCanceled = true;
    }
  }

  void _handlePointerUp() {
    _pointerDownPosition = null;
  }

  void _handlePointerCancel() {
    _pointerDownPosition = null;
    _tapCanceled = false;
  }

  void _handlePdfPageChanged(int page) {
    if (!mounted) {
      return;
    }
    setState(() {
      _currentPage = page;
    });
  }

  void _handlePdfDocumentLoaded(int pagesCount) {
    if (!mounted) {
      return;
    }
    setState(() {
      _pageCount = pagesCount;
      if (_currentPage > _pageCount) {
        _currentPage = 1;
      }
      _pdfLoadError = null;
    });
  }

  void _handlePdfDocumentError(Object error) {
    if (!mounted) {
      return;
    }
    setState(() {
      _pdfLoadError = StringsKo.pdfDrawingLoadFailed;
    });
  }

  void _handlePdfPageSizeResolved(int pageNumber, Size pageSize) {
    if (!mounted) {
      return;
    }
    setState(() {
      _pdfPageSizes[pageNumber] = pageSize;
    });
  }

  void _jumpToPdfPage(int page) {
    setState(() {
      _currentPage = page;
    });
    _pdfController?.jumpToPage(page);
  }

  Future<void> _handlePdfTap(
    TapUpDetails details,
    Size pageSize,
    int pageIndex,
  ) async {
    if (_isDetailDialogOpen) {
      return;
    }
    if (_tapCanceled) {
      _tapCanceled = false;
      return;
    }
    final localPosition = details.localPosition;
    final hitResult = _hitTestMarkerOnPage(
      localPosition,
      pageSize,
      pageIndex,
    );
    if (hitResult != null) {
      _selectMarker(hitResult);
      return;
    }

    _clearSelectedMarker();
    if (_mode == DrawMode.defect && _activeCategory == null) {
      _showSelectDefectCategoryHint();
      return;
    }
    if (_mode == DrawMode.equipment && _activeEquipmentCategory == null) {
      return;
    }
    if (_mode != DrawMode.defect && _mode != DrawMode.equipment) {
      return;
    }

    final normalizedX = (localPosition.dx / pageSize.width).clamp(0.0, 1.0);
    final normalizedY = (localPosition.dy / pageSize.height).clamp(0.0, 1.0);

    if (_mode == DrawMode.defect) {
      final detailsResult = await _showDefectDetailsDialog();
      if (!mounted || detailsResult == null) {
        return;
      }

      final countOnPage = _site.defects
          .where(
            (defect) =>
                defect.pageIndex == pageIndex &&
                defect.category == _activeCategory,
          )
          .length;
      final label = _activeCategory == DefectCategory.generalCrack
          ? 'C${countOnPage + 1}'
          : '${countOnPage + 1}';

      final defect = Defect(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        label: label,
        pageIndex: pageIndex,
        category: _activeCategory!,
        normalizedX: normalizedX,
        normalizedY: normalizedY,
        details: detailsResult,
      );

      setState(() {
        _site = _site.copyWith(defects: [..._site.defects, defect]);
      });
      await widget.onSiteUpdated(_site);
    } else {
      if (_activeEquipmentCategory == EquipmentCategory.equipment8) {
        final nextIndices = {
          'Lx': _nextSettlementIndex('Lx'),
          'Ly': _nextSettlementIndex('Ly'),
        };
        final details = await _showSettlementDialog(
          baseTitle: '부동침하',
          nextIndexByDirection: nextIndices,
        );
        if (!mounted || details == null) {
          return;
        }
        final direction = details.direction;
        final label = '$direction${_nextSettlementIndex(direction)}';
        final marker = EquipmentMarker(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          label: label,
          pageIndex: pageIndex,
          category: EquipmentCategory.equipment8,
          normalizedX: normalizedX,
          normalizedY: normalizedY,
          equipmentTypeId: direction,
          tiltDirection: direction,
          displacementText: details.displacementText,
        );
        setState(() {
          _site = _site.copyWith(
            equipmentMarkers: [..._site.equipmentMarkers, marker],
          );
        });
        await widget.onSiteUpdated(_site);
        return;
      }
      final equipmentCount = _site.equipmentMarkers
          .where((marker) => marker.category == _activeEquipmentCategory)
          .length;
      final prefix = equipmentLabelPrefix(_activeEquipmentCategory!);
      final label = '$prefix${equipmentCount + 1}';
      final pendingMarker = EquipmentMarker(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        label: label,
        pageIndex: pageIndex,
        category: _activeEquipmentCategory!,
        normalizedX: normalizedX,
        normalizedY: normalizedY,
        equipmentTypeId: prefix,
      );

      if (_activeEquipmentCategory == EquipmentCategory.equipment1) {
        final details = await _showEquipmentDetailsDialog(
          title: '부재단면치수 ${pendingMarker.label}',
          initialMemberType: pendingMarker.memberType,
          initialSizeValues: pendingMarker.sizeValues,
        );
        if (!mounted || details == null) {
          return;
        }
        final marker = pendingMarker.copyWith(
          equipmentTypeId: prefix,
          memberType: details.memberType,
          sizeValues: details.sizeValues,
        );
        setState(() {
          _site = _site.copyWith(
            equipmentMarkers: [..._site.equipmentMarkers, marker],
          );
        });
        await widget.onSiteUpdated(_site);
        return;
      }
      if (_activeEquipmentCategory == EquipmentCategory.equipment2) {
        final details = await _showRebarSpacingDialog(
          title: equipmentDisplayLabel(pendingMarker),
          initialMemberType: pendingMarker.memberType,
          initialNumberText: pendingMarker.numberText,
        );
        if (!mounted || details == null) {
          return;
        }
        final marker = pendingMarker.copyWith(
          equipmentTypeId: prefix,
          memberType: details.memberType,
          numberText: details.numberText,
        );
        setState(() {
          _site = _site.copyWith(
            equipmentMarkers: [..._site.equipmentMarkers, marker],
          );
        });
        await widget.onSiteUpdated(_site);
        return;
      }
      if (_activeEquipmentCategory == EquipmentCategory.equipment3) {
        final details = await _showSchmidtHammerDialog(
          title: equipmentDisplayLabel(pendingMarker),
          initialMemberType: pendingMarker.memberType,
          initialMaxValueText: pendingMarker.maxValueText,
          initialMinValueText: pendingMarker.minValueText,
        );
        if (!mounted || details == null) {
          return;
        }
        final marker = pendingMarker.copyWith(
          equipmentTypeId: prefix,
          memberType: details.memberType,
          maxValueText: details.maxValueText,
          minValueText: details.minValueText,
        );
        setState(() {
          _site = _site.copyWith(
            equipmentMarkers: [..._site.equipmentMarkers, marker],
          );
        });
        await widget.onSiteUpdated(_site);
        return;
      }
      if (_activeEquipmentCategory == EquipmentCategory.equipment4) {
        final details = await _showCoreSamplingDialog(
          title: equipmentDisplayLabel(pendingMarker),
          initialMemberType: pendingMarker.memberType,
          initialAvgValueText: pendingMarker.avgValueText,
        );
        if (!mounted || details == null) {
          return;
        }
        final marker = pendingMarker.copyWith(
          equipmentTypeId: prefix,
          memberType: details.memberType,
          avgValueText: details.avgValueText,
        );
        setState(() {
          _site = _site.copyWith(
            equipmentMarkers: [..._site.equipmentMarkers, marker],
          );
        });
        await widget.onSiteUpdated(_site);
        return;
      }
      if (_activeEquipmentCategory == EquipmentCategory.equipment5) {
        final details = await _showCarbonationDialog(
          title: equipmentDisplayLabel(pendingMarker),
          initialMemberType: pendingMarker.memberType,
          initialCoverThicknessText: pendingMarker.coverThicknessText,
          initialDepthText: pendingMarker.depthText,
        );
        if (!mounted || details == null) {
          return;
        }
        final marker = pendingMarker.copyWith(
          equipmentTypeId: prefix,
          memberType: details.memberType,
          coverThicknessText: details.coverThicknessText,
          depthText: details.depthText,
        );
        setState(() {
          _site = _site.copyWith(
            equipmentMarkers: [..._site.equipmentMarkers, marker],
          );
        });
        await widget.onSiteUpdated(_site);
        return;
      }
      if (_activeEquipmentCategory == EquipmentCategory.equipment6) {
        final details = await _showStructuralTiltDialog(
          title: equipmentDisplayLabel(pendingMarker),
          initialDirection: pendingMarker.tiltDirection,
          initialDisplacementText: pendingMarker.displacementText,
        );
        if (!mounted || details == null) {
          return;
        }
        final marker = pendingMarker.copyWith(
          equipmentTypeId: prefix,
          tiltDirection: details.direction,
          displacementText: details.displacementText,
        );
        setState(() {
          _site = _site.copyWith(
            equipmentMarkers: [..._site.equipmentMarkers, marker],
          );
        });
        await widget.onSiteUpdated(_site);
        return;
      }
      if (_activeEquipmentCategory == EquipmentCategory.equipment7) {
        final details = await _showDeflectionDialog(
          title: equipmentDisplayLabel(pendingMarker),
          initialMemberType: pendingMarker.memberType,
          initialEndAText: pendingMarker.deflectionEndAText,
          initialMidBText: pendingMarker.deflectionMidBText,
          initialEndCText: pendingMarker.deflectionEndCText,
        );
        if (!mounted || details == null) {
          return;
        }
        final marker = pendingMarker.copyWith(
          equipmentTypeId: prefix,
          memberType: details.memberType,
          deflectionEndAText: details.endAText,
          deflectionMidBText: details.midBText,
          deflectionEndCText: details.endCText,
        );
        setState(() {
          _site = _site.copyWith(
            equipmentMarkers: [..._site.equipmentMarkers, marker],
          );
        });
        await widget.onSiteUpdated(_site);
        return;
      }
      setState(() {
        _site = _site.copyWith(
          equipmentMarkers: [..._site.equipmentMarkers, pendingMarker],
        );
      });
      await widget.onSiteUpdated(_site);
    }
  }

  Widget _buildMarkerPopup(Size viewportSize) {
    if (_selectedMarkerScenePosition == null ||
        (_selectedDefect == null && _selectedEquipment == null)) {
      return const SizedBox.shrink();
    }
    final lines = _selectedDefect != null
        ? defectPopupLines(_selectedDefect!)
        : equipmentPopupLines(_selectedEquipment!);
    final markerViewportPosition = MatrixUtils.transformPoint(
      _transformationController.value,
      _selectedMarkerScenePosition!,
    );
    return MarkerPopup(
      lines: lines,
      markerPosition: markerViewportPosition,
      viewportSize: viewportSize,
    );
  }

  Widget _buildMarkerPopupForPage(Size pageSize, int pageIndex) {
    final selectedDefect = _selectedDefect;
    final selectedEquipment = _selectedEquipment;
    if (selectedDefect == null && selectedEquipment == null) {
      return const SizedBox.shrink();
    }
    final selectedPage =
        selectedDefect?.pageIndex ?? selectedEquipment?.pageIndex;
    if (selectedPage != pageIndex) {
      return const SizedBox.shrink();
    }

    final lines = selectedDefect != null
        ? defectPopupLines(selectedDefect)
        : equipmentPopupLines(selectedEquipment!);
    final normalizedX =
        selectedDefect?.normalizedX ?? selectedEquipment!.normalizedX;
    final normalizedY =
        selectedDefect?.normalizedY ?? selectedEquipment!.normalizedY;
    final markerPosition = Offset(
      normalizedX * pageSize.width,
      normalizedY * pageSize.height,
    );
    return MarkerPopup(
      lines: lines,
      markerPosition: markerPosition,
      viewportSize: pageSize,
    );
  }

  List<Widget> _buildDefectMarkers() {
    final defects = _site.defects
        .where((defect) => defect.pageIndex == _currentPage)
        .toList();

    return defects.map((defect) {
      final position = Offset(
        defect.normalizedX * _canvasSize.width,
        defect.normalizedY * _canvasSize.height,
      );
      return Positioned(
        left: position.dx - 18,
        top: position.dy - 18,
        child: DefectMarkerIcon(
          label: defect.label,
          category: defect.category,
          color: _defectColor(defect.category),
        ),
      );
    }).toList();
  }

  List<Widget> _buildDefectMarkersForPage(Size pageSize, int pageIndex) {
    final defects = _site.defects
        .where((defect) => defect.pageIndex == pageIndex)
        .toList();

    return defects.map((defect) {
      final position = Offset(
        defect.normalizedX * pageSize.width,
        defect.normalizedY * pageSize.height,
      );
      return Positioned(
        left: position.dx - 18,
        top: position.dy - 18,
        child: DefectMarkerIcon(
          label: defect.label,
          category: defect.category,
          color: _defectColor(defect.category),
        ),
      );
    }).toList();
  }

  List<Widget> _buildEquipmentMarkers() {
    final markers = _site.equipmentMarkers
        .where((marker) => marker.pageIndex == _currentPage)
        .toList();

    return markers.map((marker) {
      final position = Offset(
        marker.normalizedX * _canvasSize.width,
        marker.normalizedY * _canvasSize.height,
      );
      return Positioned(
        left: position.dx - 18,
        top: position.dy - 18,
        child: EquipmentMarkerIcon(
          label: marker.label,
          category: marker.category,
          color: _equipmentColor(marker.category),
        ),
      );
    }).toList();
  }

  List<Widget> _buildEquipmentMarkersForPage(Size pageSize, int pageIndex) {
    final markers = _site.equipmentMarkers
        .where((marker) => marker.pageIndex == pageIndex)
        .toList();

    return markers.map((marker) {
      final position = Offset(
        marker.normalizedX * pageSize.width,
        marker.normalizedY * pageSize.height,
      );
      return Positioned(
        left: position.dx - 18,
        top: position.dy - 18,
        child: EquipmentMarkerIcon(
          label: marker.label,
          category: marker.category,
          color: _equipmentColor(marker.category),
        ),
      );
    }).toList();
  }

  void _toggleMode(DrawMode nextMode) {
    setState(() {
      _mode = _mode == nextMode ? DrawMode.hand : nextMode;
    });
  }

  bool _isToolSelectionMode() => _mode == DrawMode.hand;

  void _returnToToolSelection() {
    setState(() {
      _mode = DrawMode.hand;
    });
  }

  void _handleAddToolAction() {
    if (_mode == DrawMode.defect) {
      _showDefectCategoryPicker();
    }
  }


  Future<void> _showDeleteDefectTabDialog(DefectCategory category) async {
    final shouldDelete = await showDeleteDefectTabDialog(
      context: context,
      category: category,
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    setState(() {
      _defectTabs.remove(category);
      if (_activeCategory == category) {
        _activeCategory = _defectTabs.isNotEmpty ? _defectTabs.first : null;
      }
    });
  }

  void _showSelectDefectCategoryHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(StringsKo.selectDefectCategoryHint),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showDefectCategoryPicker() async {
    final selectedCategory = await showDefectCategoryPickerSheet(
      context: context,
      selectedCategories: _defectTabs,
    );

    if (selectedCategory == null || !mounted) {
      return;
    }

    setState(() {
      if (!_defectTabs.contains(selectedCategory)) {
        _defectTabs.add(selectedCategory);
      }
      _activeCategory = selectedCategory;
    });
  }

  Future<T?> _showDetailDialog<T>(Future<T?> Function() dialogBuilder) async {
    if (_isDetailDialogOpen) {
      return null;
    }
    _isDetailDialogOpen = true;
    try {
      return await dialogBuilder();
    } finally {
      _isDetailDialogOpen = false;
    }
  }

  Color _defectColor(DefectCategory category) {
    switch (category) {
      case DefectCategory.generalCrack:
        return Colors.red;
      case DefectCategory.waterLeakage:
        return Colors.blue;
      case DefectCategory.concreteSpalling:
        return Colors.green;
      case DefectCategory.other:
        return Colors.purple;
    }
  }

  int _nextSettlementIndex(String direction) {
    return _site.equipmentMarkers
            .where(
              (marker) =>
                  marker.category == EquipmentCategory.equipment8 &&
                  settlementDirection(marker) == direction,
            )
            .length +
        1;
  }

  Color _equipmentColor(EquipmentCategory category) {
    switch (category) {
      case EquipmentCategory.equipment1:
        return Colors.pinkAccent;
      case EquipmentCategory.equipment2:
        return Colors.lightBlueAccent;
      case EquipmentCategory.equipment3:
      case EquipmentCategory.equipment4:
        return Colors.green;
      case EquipmentCategory.equipment5:
        return Colors.orangeAccent;
      case EquipmentCategory.equipment6:
        return Colors.tealAccent;
      case EquipmentCategory.equipment7:
        return Colors.indigoAccent;
      case EquipmentCategory.equipment8:
        return Colors.deepPurpleAccent;
    }
  }
}
