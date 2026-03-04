part of 'drawing_screen.dart';

extension _DrawingScreenStateAccessors on _DrawingScreenState {
  Map<int, Size> get _pdfPageSizes => _sessionState.pdfPageSizes;

  PdfController? get _pdfController => _sessionState.pdfController;
  set _pdfController(PdfController? value) {
    _sessionState.pdfController = value;
  }

  String? get _pdfLoadError => _sessionState.pdfLoadError;
  set _pdfLoadError(String? value) {
    _sessionState.pdfLoadError = value;
  }

  int get _currentPage => _sessionState.currentPage;
  set _currentPage(int value) {
    _sessionState.currentPage = value;
  }

  int get _pageCount => _sessionState.pageCount;
  set _pageCount(int value) {
    _sessionState.pageCount = value;
  }

  DefectCategory? get _activeCategory => _markerState.activeCategory;
  set _activeCategory(DefectCategory? value) {
    _markerState.activeCategory = value;
  }

  EquipmentCategory? get _activeEquipmentCategory =>
      _markerState.activeEquipmentCategory;
  set _activeEquipmentCategory(EquipmentCategory? value) {
    _markerState.activeEquipmentCategory = value;
  }

  DefectCategory? get _sidePanelDefectCategory =>
      _markerState.sidePanelDefectCategory;
  set _sidePanelDefectCategory(DefectCategory? value) {
    _markerState.sidePanelDefectCategory = value;
  }

  EquipmentCategory? get _sidePanelEquipmentCategory =>
      _markerState.sidePanelEquipmentCategory;
  set _sidePanelEquipmentCategory(EquipmentCategory? value) {
    _markerState.sidePanelEquipmentCategory = value;
  }

  Set<DefectCategory> get _visibleDefectCategories =>
      _markerState.visibleDefectCategories;

  Set<EquipmentCategory> get _visibleEquipmentCategories =>
      _markerState.visibleEquipmentCategories;

  List<DefectCategory> get _defectTabs => _markerState.defectTabs;

  String? get _selectedDefectId => _markerState.selectedDefectId;
  set _selectedDefectId(String? value) {
    _markerState.selectedDefectId = value;
  }

  String? get _selectedEquipmentId => _markerState.selectedEquipmentId;
  set _selectedEquipmentId(String? value) {
    _markerState.selectedEquipmentId = value;
  }

  Offset? get _selectedMarkerScenePosition =>
      _markerState.selectedMarkerScenePosition;
  set _selectedMarkerScenePosition(Offset? value) {
    _markerState.selectedMarkerScenePosition = value;
  }

  int get _sidePanelTabIndex => _markerState.sidePanelTabIndex;
  set _sidePanelTabIndex(int value) {
    _markerState.sidePanelTabIndex = value.clamp(0, 3).toInt();
  }

  Offset? get _pointerDownPosition => _gestureState.pointerDownPosition;
  set _pointerDownPosition(Offset? value) {
    _gestureState.pointerDownPosition = value;
  }

  bool get _tapCanceled => _gestureState.tapCanceled;
  set _tapCanceled(bool value) {
    _gestureState.tapCanceled = value;
  }

  int? get _markerTapStylusPointerId => _gestureState.markerTapStylusPointerId;
  set _markerTapStylusPointerId(int? value) {
    _gestureState.markerTapStylusPointerId = value;
  }

  Offset? get _markerTapStylusStartLocal =>
      _gestureState.markerTapStylusStartLocal;
  set _markerTapStylusStartLocal(Offset? value) {
    _gestureState.markerTapStylusStartLocal = value;
  }

  bool get _markerTapStylusMoved => _gestureState.markerTapStylusMoved;
  set _markerTapStylusMoved(bool value) {
    _gestureState.markerTapStylusMoved = value;
  }

  Offset? get _eraserCursorPageLocal => _gestureState.eraserCursorPageLocal;
  set _eraserCursorPageLocal(Offset? value) {
    _gestureState.eraserCursorPageLocal = value;
  }

  int? get _eraserCursorPageNumber => _gestureState.eraserCursorPageNumber;
  set _eraserCursorPageNumber(int? value) {
    _gestureState.eraserCursorPageNumber = value;
  }

  int? get _activeAreaEraserPointerId =>
      _gestureState.activeAreaEraserPointerId;
  set _activeAreaEraserPointerId(int? value) {
    _gestureState.activeAreaEraserPointerId = value;
  }

  AreaEraserSession? get _activeAreaEraserSession =>
      _gestureState.activeAreaEraserSession;
  set _activeAreaEraserSession(AreaEraserSession? value) {
    _gestureState.activeAreaEraserSession = value;
  }

  int? get _activeStrokeEraserPointerId =>
      _gestureState.activeStrokeEraserPointerId;
  set _activeStrokeEraserPointerId(int? value) {
    _gestureState.activeStrokeEraserPointerId = value;
  }

  Set<String> get _erasedStrokeIdsThisDrag =>
      _gestureState.erasedStrokeIdsThisDrag;

  int get _erasedStrokeCountThisDrag => _gestureState.erasedStrokeCountThisDrag;
  set _erasedStrokeCountThisDrag(int value) {
    _gestureState.erasedStrokeCountThisDrag = value;
  }

  PendingAreaEraserMove? get _pendingAreaEraserMove =>
      _gestureState.pendingAreaEraserMove;
  set _pendingAreaEraserMove(PendingAreaEraserMove? value) {
    _gestureState.pendingAreaEraserMove = value;
  }

  List<PendingAreaEraserMove> get _areaEraserPath =>
      _gestureState.areaEraserPath;

  bool get _isAreaEraserFrameScheduled =>
      _gestureState.isAreaEraserFrameScheduled;
  set _isAreaEraserFrameScheduled(bool value) {
    _gestureState.isAreaEraserFrameScheduled = value;
  }

  Set<int> get _activePointerIds => _gestureState.activePointerIds;

  Map<int, PointerDeviceKind> get _activePointerKinds =>
      _gestureState.activePointerKinds;

  int? get _activeStylusPointerId => _gestureState.activeStylusPointerId;
  set _activeStylusPointerId(int? value) {
    _gestureState.activeStylusPointerId = value;
  }

  Map<int, double?> get _straightenSnappedAngleByPointer =>
      _gestureState.straightenSnappedAngleByPointer;

  Map<int, Offset> get _straightenStartPageByPointer =>
      _gestureState.straightenStartPageByPointer;

  bool get _isFreeDrawConsumingOneFinger =>
      _gestureState.isFreeDrawConsumingOneFinger;
  set _isFreeDrawConsumingOneFinger(bool value) {
    _gestureState.isFreeDrawConsumingOneFinger = value;
  }

  PhotoViewControllerValue? get _navStartValue => _gestureState.navStartValue;
  set _navStartValue(PhotoViewControllerValue? value) {
    _gestureState.navStartValue = value;
  }

  int? get _navStartPage => _gestureState.navStartPage;
  set _navStartPage(int? value) {
    _gestureState.navStartPage = value;
  }

  Offset get _navAccumDelta => _gestureState.navAccumDelta;
  set _navAccumDelta(Offset value) {
    _gestureState.navAccumDelta = value;
  }

  Offset? get _pendingDrawDownViewportLocal =>
      _gestureState.pendingDrawDownViewportLocal;
  set _pendingDrawDownViewportLocal(Offset? value) {
    _gestureState.pendingDrawDownViewportLocal = value;
  }

  bool get _pendingDraw => _gestureState.pendingDraw;
  set _pendingDraw(bool value) {
    _gestureState.pendingDraw = value;
  }

  bool get _canUndoDrawing => _historyState.canUndoDrawing;
  set _canUndoDrawing(bool value) {
    _historyState.canUndoDrawing = value;
  }

  bool get _canRedoDrawing => _historyState.canRedoDrawing;
  set _canRedoDrawing(bool value) {
    _historyState.canRedoDrawing = value;
  }

  bool get _hasUnsavedChanges => _persistState.hasUnsavedChanges;
  set _hasUnsavedChanges(bool value) {
    _persistState.hasUnsavedChanges = value;
  }

  Timer? get _persistDebounce => _persistState.persistDebounce;
  set _persistDebounce(Timer? value) {
    _persistState.persistDebounce = value;
  }

  bool get _persistInFlight => _persistState.persistInFlight;
  set _persistInFlight(bool value) {
    _persistState.persistInFlight = value;
  }

  bool get _persistPending => _persistState.persistPending;
  set _persistPending(bool value) {
    _persistState.persistPending = value;
  }

  int get _persistEpoch => _persistState.persistEpoch;
  set _persistEpoch(int value) {
    _persistState.persistEpoch = value;
  }

  bool get _didWarnUnsavedOnExit => _persistState.didWarnUnsavedOnExit;
  set _didWarnUnsavedOnExit(bool value) {
    _persistState.didWarnUnsavedOnExit = value;
  }

  DrawingTool get _activeTool => _toolState.activeTool;
  set _activeTool(DrawingTool value) {
    _toolState.activeTool = value;
  }

  ToolFamily get _activeFamily => _toolState.activeFamily;
  set _activeFamily(ToolFamily value) {
    _toolState.activeFamily = value;
  }

  PenUiType get _activePenType => _toolState.activePenType;
  set _activePenType(PenUiType value) {
    _toolState.activePenType = value;
  }

  HighlighterUiType get _activeHighlighterType =>
      _toolState.activeHighlighterType;
  set _activeHighlighterType(HighlighterUiType value) {
    _toolState.activeHighlighterType = value;
  }

  Map<PenUiType, double> get _penWidthByType => _toolState.penWidthByType;
  Map<PenUiType, Color> get _penColorByType => _toolState.penColorByType;
  Map<HighlighterUiType, double> get _hlWidthByType => _toolState.hlWidthByType;
  Map<HighlighterUiType, double> get _hlOpacityByType =>
      _toolState.hlOpacityByType;
  Map<HighlighterUiType, Color> get _hlColorByType => _toolState.hlColorByType;
  Map<ShapeType, double> get _shapeWidthByType => _toolState.shapeWidthByType;
  Map<ShapeType, double> get _shapeOpacityByType =>
      _toolState.shapeOpacityByType;
  Map<ShapeType, Color> get _shapeStrokeColorByType =>
      _toolState.shapeStrokeColorByType;
  Map<ShapeType, Color?> get _shapeFillColorByType =>
      _toolState.shapeFillColorByType;

  double get _currentPenWidth => _toolState.currentPenWidth;
  set _currentPenWidth(double value) {
    _toolState.currentPenWidth = value;
  }

  Color get _currentPenColor => _toolState.currentPenColor;
  set _currentPenColor(Color value) {
    _toolState.currentPenColor = value;
  }

  double get _currentHlWidth => _toolState.currentHlWidth;
  set _currentHlWidth(double value) {
    _toolState.currentHlWidth = value;
  }

  double get _currentHlOpacity => _toolState.currentHlOpacity;
  set _currentHlOpacity(double value) {
    _toolState.currentHlOpacity = value;
  }

  Color get _currentHlColor => _toolState.currentHlColor;
  set _currentHlColor(Color value) {
    _toolState.currentHlColor = value;
  }

  double get _currentShapeWidth => _toolState.currentShapeWidth;
  set _currentShapeWidth(double value) {
    _toolState.currentShapeWidth = value;
  }

  double get _currentShapeOpacity => _toolState.currentShapeOpacity;
  set _currentShapeOpacity(double value) {
    _toolState.currentShapeOpacity = value;
  }

  Color get _currentShapeStrokeColor => _toolState.currentShapeStrokeColor;
  set _currentShapeStrokeColor(Color value) {
    _toolState.currentShapeStrokeColor = value;
  }

  Color? get _currentShapeFillColor => _toolState.currentShapeFillColor;
  set _currentShapeFillColor(Color? value) {
    _toolState.currentShapeFillColor = value;
  }

  bool get _isStraightenModeEnabled => _toolState.isStraightenModeEnabled;
  set _isStraightenModeEnabled(bool value) {
    _toolState.isStraightenModeEnabled = value;
  }

  bool get _isStraightenSnapEnabled => _toolState.isStraightenSnapEnabled;
  set _isStraightenSnapEnabled(bool value) {
    _toolState.isStraightenSnapEnabled = value;
  }

  bool get _isShapeAspectLocked => _toolState.isShapeAspectLocked;
  set _isShapeAspectLocked(bool value) {
    _toolState.isShapeAspectLocked = value;
  }

  bool get _isShapeRotateSnapEnabled => _toolState.isShapeRotateSnapEnabled;
  set _isShapeRotateSnapEnabled(bool value) {
    _toolState.isShapeRotateSnapEnabled = value;
  }

  double? get _shapeRotateSnappedAngleRad =>
      _toolState.shapeRotateSnappedAngleRad;
  set _shapeRotateSnappedAngleRad(double? value) {
    _toolState.shapeRotateSnappedAngleRad = value;
  }
}
