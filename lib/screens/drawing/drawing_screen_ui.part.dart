part of 'drawing_screen.dart';

extension _DrawingScreenUi on _DrawingScreenState {
  List<Widget> _buildMarkerWidgetsForPage({
    required Size size,
    required int pageIndex,
  }) => [
    ..._buildMarkersForPage(
      items: _site.defects.where(
        (defect) => _visibleDefectCategories.contains(defect.category),
      ),
      pageIndex: pageIndex,
      pageSize: size,
      isSelected:
          (defect) =>
              _selectedDefect != null &&
              _isSameDefect(defect, _selectedDefect!),
      nx: (defect) => defect.normalizedX,
      ny: (defect) => defect.normalizedY,
      buildMarker:
          (defect, selected) => DefectMarkerWidget(
        label: defectDisplayLabel(defect),
        category: defect.category,
        color: defectCategoryConfig(defect.category).color,
        isSelected: selected,
        scale: _markerScale,
        labelScale: _labelScale,
      ),
    ),
    ..._buildMarkersForPage(
      items: _site.equipmentMarkers.where(
        (marker) => _visibleEquipmentCategories.contains(marker.category),
      ),
      pageIndex: pageIndex,
      pageSize: size,
      isSelected:
          (marker) =>
              _selectedEquipment != null &&
              _isSameEquipment(marker, _selectedEquipment!),
      nx: (marker) => marker.normalizedX,
      ny: (marker) => marker.normalizedY,
      buildMarker:
          (marker, selected) => EquipmentMarkerWidget(
        label: equipmentDisplayLabel(marker, _site.equipmentMarkers),
        category: marker.category,
        color: equipmentColor(marker.category),
        isSelected: selected,
        scale: _markerScale,
        labelScale: _labelScale,
      ),
    ),
  ];

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(_site.name),
      actions: [
        if (_site.drawingType == DrawingType.pdf)
          IconButton(
            tooltip: StringsKo.replacePdfTooltip,
            icon: const Icon(Icons.upload_file_outlined),
            onPressed: _replacePdf,
          ),
      ],
      bottom: _buildDrawingTopBar(),
    );
  }

  List<Widget> _buildDrawingStackChildren() {
    final isPdf = _site.drawingType == DrawingType.pdf;
    return [
      if (isPdf)
        PdfViewLayer(
          pdfViewer: _buildPdfViewer(),
          currentPage: _currentPage,
          pageCount: _pageCount,
          canPrev: _currentPage > 1,
          canNext: _currentPage < _pageCount,
          onPrevPage: _handlePrevPage,
          onNextPage: _handleNextPage,
        )
      else
        _buildCanvasDrawingLayer(),
    ];
  }

  Widget _buildCanvasDrawingLayer() {
    final theme = Theme.of(context);
    return _wrapWithPointerHandlers(
      tapRegionKey: _canvasTapRegionKey,
      onTapUp: _handleCanvasTap,
      child: _buildCanvasViewer(theme),
    );
  }

  PdfDrawingView _buildPdfViewer() => PdfDrawingView(
    pdfController: _pdfController,
    pdfLoadError: _pdfLoadError,
    sitePdfName: _site.pdfName,
    onPageChanged: _handlePdfPageChanged,
    onDocumentLoaded: _handlePdfDocumentLoaded,
    onDocumentError: _handlePdfDocumentError,
    pageSizes: _pdfPageSizes,
    pdfViewVersion: _pdfViewVersion,
    onUpdatePageSize: _handleUpdatePageSize,
    buildPageOverlay:
        ({required pageSize, required pageNumber, required imageProvider}) =>
            _buildPdfPageOverlay(
              pageSize: pageSize,
              pageNumber: pageNumber,
              imageProvider: imageProvider,
            ),
  );

  Widget _buildPdfPageOverlay({
    required Size pageSize,
    required int pageNumber,
    required ImageProvider imageProvider,
  }) {
    return Builder(
      builder: (tapContext) => _wrapWithPointerHandlers(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) =>
            _handlePdfTap(details, pageSize, pageNumber, tapContext),
        child: _buildMarkerLayer(
          size: pageSize,
          pageIndex: pageNumber,
          child: Image(
            image: imageProvider,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildCanvasViewer(ThemeData theme) {
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: DrawingCanvasMinScale,
      maxScale: DrawingCanvasMaxScale,
      constrained: false,
      child: SizedBox(
        key: _canvasKey,
        width: DrawingCanvasSize.width,
        height: DrawingCanvasSize.height,
        child: _buildMarkerLayer(
          size: DrawingCanvasSize,
          pageIndex: _currentPage,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: CustomPaint(
              painter: GridPainter(lineColor: theme.colorScheme.outlineVariant),
            ),
          ),
        ),
      ),
    );
  }

  Widget _wrapWithPointerHandlers({
    required Widget child,
    required GestureTapUpCallback onTapUp,
    HitTestBehavior behavior = HitTestBehavior.opaque,
    Key? tapRegionKey,
  }) {
    return Listener(
      behavior: behavior,
      onPointerDown: (e) => _handlePointerDown(e.localPosition),
      onPointerMove: (e) => _handlePointerMove(e.localPosition),
      onPointerUp: (_) => _handlePointerUp(),
      onPointerCancel: (_) => _handlePointerCancel(),
      child: GestureDetector(
        behavior: behavior,
        onTapUp: onTapUp,
        child: SizedBox.expand(key: tapRegionKey, child: child),
      ),
    );
  }
}
