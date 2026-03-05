part of 'drawing_screen.dart';

extension _DrawingScreenPointerInputLogic on _DrawingScreenState {
  void _handlePdfNavigationScaleStart(ScaleStartDetails details) {
    if (!_isFreeDrawMode ||
        _isStylusActive ||
        _activeStylusPointerId != null ||
        _inProgressStroke != null ||
        _pendingDraw) {
      _cancelFreeDrawNavGesture();

      return;
    }

    _navStartPage = _currentPage;

    final controller = _photoControllerForPage(_navStartPage!);

    _navStartValue = controller.value;

    _navAccumDelta = Offset.zero;
  }

  void _handlePdfNavigationScaleUpdate(ScaleUpdateDetails details) {
    if (!_isFreeDrawMode ||
        _isStylusActive ||
        _activeStylusPointerId != null ||
        _inProgressStroke != null ||
        _pendingDraw) {
      return;
    }

    if (_navStartPage == null || _navStartValue == null) {
      return;
    }

    final page = _navStartPage!;

    final controller = _photoControllerForPage(page);

    final start = _navStartValue!;

    _navAccumDelta += details.focalPointDelta;

    final double startScale = start.scale ?? 1.0;

    final bool isTwoFinger = details.pointerCount >= 2;

    final double desiredScale = isTwoFinger
        ? startScale * details.scale
        : startScale;

    final double minScale = _freeDrawMinScaleForPage(page);

    final double maxScale = _freeDrawMaxScaleForPage(page);

    final double effectiveScale;

    if (desiredScale < minScale) {
      final over = minScale - desiredScale;

      effectiveScale = minScale - (over * 0.15);
    } else if (desiredScale > maxScale) {
      final over = desiredScale - maxScale;

      effectiveScale = maxScale + (over * 0.15);
    } else {
      effectiveScale = desiredScale;
    }

    final double s = effectiveScale;

    final double panBoost = (s <= 1.0) ? 1.0 : (1.0 + (s - 1.0) * 0.35);

    final Offset desiredPos = start.position + (_navAccumDelta * panBoost);

    controller.value = PhotoViewControllerValue(
      position: desiredPos,

      rotation: start.rotation,

      scale: effectiveScale,

      rotationFocusPoint: start.rotationFocusPoint,
    );
  }

  void _handlePdfNavigationScaleEnd(ScaleEndDetails details) {
    _endFreeDrawNavigationGesture();
  }

  void _endFreeDrawNavigationGesture() {
    if (_isFreeDrawMode) {
      _snapFreeDrawScaleBackIfOutOfBounds(
        _navStartPage ?? _currentPage,

        start: _navStartValue,
      );
    }

    _cancelFreeDrawNavGesture();
  }

  void _cancelFreeDrawNavGesture() {
    _navStartPage = null;

    _navStartValue = null;

    _navAccumDelta = Offset.zero;
  }

  double _resolveFreeDrawScale(Object? value, {required double fallback}) {
    if (value is num) {
      return value.toDouble();
    }

    return fallback;
  }

  double _freeDrawMinScaleForPage(int pageNumber) {
    final minScale = _resolveFreeDrawScale(PdfDrawingMinScale, fallback: 1.0);

    if (!minScale.isFinite || minScale <= 0) {
      return 1.0;
    }

    return minScale;
  }

  double _freeDrawMaxScaleForPage(int pageNumber) {
    final minScale = _freeDrawMinScaleForPage(pageNumber);

    final maxScale = minScale * PdfDrawingMaxScaleMultiplier;

    if (!maxScale.isFinite || maxScale <= minScale) {
      return 5.0;
    }

    return maxScale;
  }

  double _freeDrawInitialScaleForPage(int pageNumber) {
    final minScale = _freeDrawMinScaleForPage(pageNumber);

    final initialScale = _resolveFreeDrawScale(
      PdfDrawingInitialScale,

      fallback: minScale,
    );

    if (!initialScale.isFinite || initialScale <= 0) {
      return minScale;
    }

    return initialScale;
  }

  void _snapFreeDrawScaleBackIfOutOfBounds(
    int pageNumber, {

    PhotoViewControllerValue? start,
  }) {
    final controller = _photoControllerForPage(pageNumber);

    final value = controller.value;

    final scale = value.scale ?? 1.0;

    final minScale = _freeDrawMinScaleForPage(pageNumber);

    final maxScale = _freeDrawMaxScaleForPage(pageNumber);

    if (scale >= minScale && scale <= maxScale) {
      return;
    }

    final snapshot = start ?? value;

    if (scale > maxScale) {
      controller.value = PhotoViewControllerValue(
        position: value.position,

        rotation: snapshot.rotation,

        scale: maxScale,

        rotationFocusPoint: snapshot.rotationFocusPoint,
      );

      return;
    }

    final snapScale = _freeDrawInitialScaleForPage(
      pageNumber,
    ).clamp(minScale, maxScale);

    controller.value = PhotoViewControllerValue(
      position: Offset.zero,

      rotation: snapshot.rotation,

      scale: snapScale,

      rotationFocusPoint: snapshot.rotationFocusPoint,
    );
  }

  void _debugLogPhotoViewBaseStateOnce(String tag) {
    if (!kDebugMode || !mounted || _isFreeDrawMode) {
      return;
    }

    final key = '$tag:$_currentPage';

    if (!_basePhotoViewDebugLogOnceKeys.add(key)) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isFreeDrawMode) {
        return;
      }

      final controller = _photoControllerForPage(_currentPage);

      final v = controller.value;

      debugPrint(
        '[$tag] page=$_currentPage scale=${v.scale} '
        'pos=${v.position} rot=${v.rotation}',
      );

      debugPrint(
        '[$tag] bounds min=$PdfDrawingMinScale '
        'initial=$PdfDrawingInitialScale '
        'maxMul=$PdfDrawingMaxScaleMultiplier',
      );
    });
  }

  void _handleOverlayPointerDown(PointerDownEvent event) {
    if (!_isFreeDrawMode && event.kind == PointerDeviceKind.touch) {
      return;
    }

    final previousCount = _activePointerIds.length;

    final previousTouchCount = _activeTouchPointerCount;

    _activePointerIds.add(event.pointer);

    _activePointerKinds[event.pointer] = event.kind;

    if (!_isFreeDrawMode) {
      if (previousCount != _activePointerIds.length) {
        _safeSetState(() {});
      }

      return;
    }

    final touchCount = _activeTouchPointerCount;

    final bool becameTwoFingerTouch = previousTouchCount < 2 && touchCount >= 2;

    if (becameTwoFingerTouch) {
      if (_isFreeDrawConsumingOneFinger && _inProgressStroke != null) {
        _handleFreeDrawPointerEnd(
          _inProgressStroke?.pageNumber ?? _currentPage,

          pointerId: event.pointer,
        );
      }

      _safeSetState(() {
        _isFreeDrawConsumingOneFinger = false;

        _pendingDraw = false;

        _pendingDrawDownViewportLocal = null;
      });

      return;
    }
  }

  void _handleOverlayPointerDownWithStylusDrawing(
    PointerDownEvent event, {

    required int pageNumber,

    required Size pageSize,

    required OverlayToPageLocal drawingLocalToPageLocal,

    required double photoScale,
  }) {
    _handleOverlayPointerDown(event);

    if (PointerIntentRouter.shouldTrackMarkerStylusTap(
      isFreeDrawMode: _isFreeDrawMode,

      mode: _mode,

      pointerKind: event.kind,
    )) {
      _markerTapStylusPointerId = event.pointer;

      _markerTapStylusStartLocal = event.localPosition;

      _markerTapStylusMoved = false;

      return;
    }

    if (!_isStylusKind(event.kind)) {
      return;
    }

    if (PointerIntentRouter.shouldHandleShapeDown(
      isFreeDrawMode: _isFreeDrawMode,

      isShapeToolActive: _activeTool == DrawingTool.shape,

      pointerKind: event.kind,
    )) {
      _activeStylusPointerId = event.pointer;

      final pageLocal = drawingLocalToPageLocal(event.localPosition);

      if (pageLocal == null) {
        return;
      }

      final downNorm = _overlayToNormalizedPoint(
        overlayLocal: pageLocal,

        destSize: pageSize,
      );

      if (downNorm == null) {
        return;
      }

      this._handleShapeStrokeInteractionStart(
        pointerId: event.pointer,

        pageNumber: pageNumber,

        pageSize: pageSize,

        startNorm: downNorm,

        style: _activeShapeStrokeStyle,
      );

      return;
    }

    final activeToolKind = _activeToolKindForToolbar;

    if (activeToolKind == StrokeToolKind.eraser) {
      _handleEraserPointerDown(
        event,

        pageNumber: pageNumber,

        drawingLocalToPageLocal: drawingLocalToPageLocal,
      );

      return;
    }

    if (!PointerIntentRouter.shouldStartFreeDrawStroke(
      isFreeDrawMode: _isFreeDrawMode,

      hasActiveStrokeStyle: _activeStrokeStyle != null,
    )) {
      return;
    }

    _cancelFreeDrawNavGesture();

    _activeStylusPointerId = event.pointer;

    _safeSetState(() {
      _pendingDraw = true;

      _pendingDrawDownViewportLocal = event.localPosition;
    });
  }

  void _handleOverlayPointerMoveWithStylusDrawing(
    PointerMoveEvent event, {

    required int pageNumber,

    required Size pageSize,

    required OverlayToPageLocal drawingLocalToPageLocal,

    required double photoScale,
  }) {
    if (_isStylusRequiredMarkerPlacementMode && !_isFreeDrawMode) {
      if (_markerTapStylusPointerId == event.pointer) {
        final startLocal = _markerTapStylusStartLocal;

        if (startLocal != null &&
            (event.localPosition - startLocal).distance > DrawingTapSlop) {
          _markerTapStylusMoved = true;
        }
      }

      return;
    }

    if (PointerIntentRouter.shouldHandleShapeMove(
      isFreeDrawMode: _isFreeDrawMode,

      isShapeToolActive: _activeTool == DrawingTool.shape,

      activeStylusPointerId: _activeStylusPointerId,

      pointerId: event.pointer,

      pointerKind: event.kind,
    )) {
      final pageLocal = drawingLocalToPageLocal(event.localPosition);

      if (pageLocal == null) {
        return;
      }

      final norm = _overlayToNormalizedPoint(
        overlayLocal: pageLocal,

        destSize: pageSize,
      );

      if (norm == null) {
        return;
      }

      this._handleShapeStrokeInteractionUpdate(
        pointerId: event.pointer,

        pageNumber: pageNumber,

        pageSize: pageSize,

        norm: norm,

        style: _activeShapeStrokeStyle,
      );

      return;
    }

    if (!PointerIntentRouter.shouldProcessFreeDrawMove(
      isFreeDrawMode: _isFreeDrawMode,

      pointerKind: event.kind,
    )) {
      return;
    }

    if (_activeToolKindForToolbar == StrokeToolKind.eraser) {
      _handleEraserPointerMove(
        event,

        pageNumber: pageNumber,

        pageSize: pageSize,

        drawingLocalToPageLocal: drawingLocalToPageLocal,
      );

      return;
    }

    if (_activeStrokeStyle == null) {
      if (_isFreeDrawConsumingOneFinger && _inProgressStroke != null) {
        _handleFreeDrawPointerEnd(
          _inProgressStroke?.pageNumber ?? _currentPage,

          pointerId: event.pointer,
        );
      }

      _safeSetState(() {
        _isFreeDrawConsumingOneFinger = false;

        _pendingDraw = false;

        _pendingDrawDownViewportLocal = null;

        _activeStylusPointerId = null;
      });

      return;
    }

    if (_activeStylusPointerId == null ||
        event.pointer != _activeStylusPointerId ||
        !_isStylusKind(event.kind)) {
      return;
    }

    final pendingDown = _pendingDrawDownViewportLocal;

    if (pendingDown == null) {
      _safeSetState(() {
        _pendingDraw = true;

        _pendingDrawDownViewportLocal = event.localPosition;
      });

      return;
    }

    if (!_isFreeDrawConsumingOneFinger && _pendingDraw) {
      final distance = (event.localPosition - pendingDown).distance;

      if (distance < _DrawingScreenState._kDrawStartSlopPx) return;

      final downPageLocal = drawingLocalToPageLocal(pendingDown);

      if (downPageLocal == null) {
        _safeSetState(() {
          _pendingDraw = false;

          _pendingDrawDownViewportLocal = null;

          _activeStylusPointerId = null;
        });

        return;
      }

      final downNorm = _overlayToNormalizedPoint(
        overlayLocal: downPageLocal,

        destSize: pageSize,
      );

      if (downNorm == null) {
        _safeSetState(() {
          _pendingDraw = false;

          _pendingDrawDownViewportLocal = null;

          _activeStylusPointerId = null;
        });

        return;
      }

      _safeSetState(() {
        _isFreeDrawConsumingOneFinger = true;

        _pendingDraw = false;
      });

      _handleFreeDrawPointerStart(downNorm, pageNumber);
    }

    if (!_isFreeDrawConsumingOneFinger) return;

    final inProgressStroke = _inProgressStroke;

    if (inProgressStroke == null || inProgressStroke.pointsNorm.isEmpty) return;

    final pageLocal = drawingLocalToPageLocal(event.localPosition);

    if (pageLocal == null) {
      return;
    }

    final norm = _overlayToNormalizedPoint(
      overlayLocal: pageLocal,

      destSize: pageSize,
    );

    if (norm == null) {
      return;
    }

    _queueFreeDrawMove(
      pointerId: event.pointer,

      pageNumber: pageNumber,

      pageSize: pageSize,

      normalized: norm,

      photoScale: photoScale,
    );
  }

  void _handleOverlayPointerUpOrCancelWithStylusDrawing(
    PointerEvent event, {

    required int pageNumber,

    required Size pageSize,

    required OverlayToPageLocal drawingLocalToPageLocal,
  }) {
    if (_isStylusRequiredMarkerPlacementMode && !_isFreeDrawMode) {
      final isTrackedStylus = _markerTapStylusPointerId == event.pointer;

      final moved = _markerTapStylusMoved;

      final startLocal = _markerTapStylusStartLocal;

      _markerTapStylusPointerId = null;

      _markerTapStylusStartLocal = null;

      _markerTapStylusMoved = false;

      _handleOverlayPointerUpOrCancel(event);

      if (!isTrackedStylus ||
          event is PointerCancelEvent ||
          moved ||
          !_isStrictStylusKind(event.kind)) {
        return;
      }

      Offset? pageLocal = drawingLocalToPageLocal(event.localPosition);

      pageLocal ??= startLocal == null
          ? null
          : drawingLocalToPageLocal(startLocal);

      if (pageLocal == null) {
        return;
      }

      unawaited(_handlePdfTapAt(pageLocal, pageSize, pageNumber, event.kind));

      return;
    }

    if ((event is PointerUpEvent || event is PointerCancelEvent) &&
        PointerIntentRouter.shouldHandleShapeEnd(
          isFreeDrawMode: _isFreeDrawMode,

          isShapeToolActive: _activeTool == DrawingTool.shape,

          activeStylusPointerId: _activeStylusPointerId,

          pointerId: event.pointer,
        )) {
      final pageLocal = drawingLocalToPageLocal(event.localPosition);

      if (pageLocal != null) {
        final norm = _overlayToNormalizedPoint(
          overlayLocal: pageLocal,

          destSize: pageSize,
        );

        if (norm != null) {
          this._handleShapeStrokeInteractionEnd(
            pointerId: event.pointer,

            pageNumber: pageNumber,

            pageSize: pageSize,

            pageLocalNorm: norm,
          );
        }
      } else {
        this._clearShapeInteractionState();
      }

      _shapeCreateHasMoved = false;

      return;
    }

    final wasStylus = _activeStylusPointerId == event.pointer;

    final wasAreaSession = _activeAreaEraserPointerId == event.pointer;

    if (wasStylus) {
      _flushPendingFreeDrawMove();
    }

    _handleOverlayPointerUpOrCancel(event);

    if (!_isFreeDrawMode) {
      return;
    }

    if (_activeToolKindForToolbar == StrokeToolKind.eraser) {
      _handleEraserPointerUpOrCancel(
        event,

        pageNumber: pageNumber,

        pageSize: pageSize,

        drawingLocalToPageLocal: drawingLocalToPageLocal,

        wasStylus: wasStylus,

        wasAreaSession: wasAreaSession,
      );

      return;
    }

    if (wasStylus) {
      _flushPendingFreeDrawMove();

      if (_isFreeDrawConsumingOneFinger) {
        _handleFreeDrawPointerEnd(pageNumber, pointerId: event.pointer);
      }

      _safeSetState(() {
        _isFreeDrawConsumingOneFinger = false;

        _pendingDraw = false;

        _pendingDrawDownViewportLocal = null;

        _activeStylusPointerId = null;
      });

      _resetFreeDrawMoveCoalescing();
    }
  }

  void _handleEraserPointerDown(
    PointerDownEvent event, {

    required int pageNumber,

    required OverlayToPageLocal drawingLocalToPageLocal,
  }) {
    if (!_isFreeDrawMode) {
      return;
    }

    if (_activeTool == DrawingTool.strokeEraser) {
      if (kDebugMode) {
        debugPrint('[Eraser] down mode=stroke');
      }

      _cancelFreeDrawNavGesture();

      _activeStylusPointerId = event.pointer;

      _safeSetState(() {
        _activeStrokeEraserPointerId = event.pointer;

        _erasedStrokeIdsThisDrag.clear();

        _erasedStrokeCountThisDrag = 0;
      });

      return;
    }

    if (kDebugMode) {
      debugPrint('[Eraser] down mode=area');
    }

    _cancelFreeDrawNavGesture();

    final pageLocal = drawingLocalToPageLocal(event.localPosition);

    if (pageLocal == null) {
      return;
    }

    _safeSetState(() {
      _eraserCursorPageNumber = pageNumber;

      _eraserCursorPageLocal = pageLocal;

      _canvasController.setEraserCursor(
        _currentPage == pageNumber ? pageLocal : null,
      );

      _startAreaEraserSession(event.pointer);
    });
  }

  void _handleEraserPointerMove(
    PointerMoveEvent event, {

    required int pageNumber,

    required Size pageSize,

    required OverlayToPageLocal drawingLocalToPageLocal,
  }) {
    const double kStrokeEraserHitRadiusPx = 10.0;

    if (_activeTool == DrawingTool.strokeEraser) {
      if (_activeStrokeEraserPointerId != event.pointer) {
        return;
      }

      final pageLocal = drawingLocalToPageLocal(event.localPosition);

      if (pageLocal == null) {
        return;
      }

      final radiusPagePx = _viewportDistanceToPageDistance(
        viewportLocal: event.localPosition,

        viewportDistancePx: kStrokeEraserHitRadiusPx,

        drawingLocalToPageLocal: drawingLocalToPageLocal,
      );

      final closestResult = _findClosestStrokeAtPageLocal(
        pageNumber: pageNumber,

        pageLocal: pageLocal,

        pageSize: pageSize,

        queryRadiusPx: math.max(
          radiusPagePx,

          _strokeEraserBaseThresholdForPage(
            strokes: _strokesByPage[pageNumber],

            pageSize: pageSize,
          ),
        ),
      );

      if (closestResult == null ||
          closestResult.distanceSquared > radiusPagePx * radiusPagePx ||
          _erasedStrokeIdsThisDrag.contains(closestResult.stroke.id)) {
        return;
      }

      _safeSetState(() {
        _erasedStrokeIdsThisDrag.add(closestResult.stroke.id);

        _erasedStrokeCountThisDrag += 1;

        _removeStrokeWithUndoSnapshot(closestResult.stroke);
      });

      return;
    }

    if (_activeAreaEraserPointerId != event.pointer) {
      return;
    }

    final pageLocal = drawingLocalToPageLocal(event.localPosition);

    if (pageLocal == null) {
      return;
    }

    final rightOffset = drawingLocalToPageLocal(
      event.localPosition + Offset(_areaEraserRadiusPx, 0),
    );

    final leftOffset = drawingLocalToPageLocal(
      event.localPosition - Offset(_areaEraserRadiusPx, 0),
    );

    final radiusPagePx = (rightOffset != null)
        ? (rightOffset - pageLocal).distance
        : (leftOffset != null)
        ? (leftOffset - pageLocal).distance
        : _areaEraserRadiusPx;

    _queueAreaEraserMove(
      pageNumber: pageNumber,

      pageSize: pageSize,

      pageLocal: pageLocal,

      radiusPagePx: radiusPagePx,
    );
  }

  void _handleEraserPointerUpOrCancel(
    PointerEvent event, {

    required int pageNumber,

    required Size pageSize,

    required OverlayToPageLocal drawingLocalToPageLocal,

    required bool wasStylus,

    required bool wasAreaSession,
  }) {
    if (_activeTool == DrawingTool.areaEraser && wasAreaSession) {
      if (kDebugMode) {
        debugPrint('[Eraser] up mode=area');
      }

      _flushPendingAreaEraserMove();

      _safeSetState(() {
        _eraserCursorPageLocal = null;

        _eraserCursorPageNumber = null;

        _canvasController.setEraserCursor(null);

        _canvasController.setEraserPreview(null);
      });

      _commitAreaEraserSession();

      return;
    }

    if (_activeTool == DrawingTool.strokeEraser && wasStylus) {
      if (kDebugMode) {
        debugPrint(
          '[Eraser] up mode=stroke removed=$_erasedStrokeCountThisDrag',
        );
      }

      _safeSetState(() {
        _activeStrokeEraserPointerId = null;

        _erasedStrokeIdsThisDrag.clear();

        _erasedStrokeCountThisDrag = 0;

        _activeStylusPointerId = null;
      });
    }
  }

  List<Offset> _interpolateNormalizedPoints({
    required Offset from,

    required Offset to,

    required Size pageSize,

    required double photoScale,
  }) {
    const double targetSpacingPx = 1.2;

    final s = (photoScale <= 0) ? 1.0 : photoScale;

    final double spacingNorm = (targetSpacingPx / s) / pageSize.shortestSide;

    final double dist = (to - from).distance;

    if (dist <= spacingNorm) return <Offset>[to];

    final int steps = (dist / spacingNorm).ceil().clamp(1, 24);

    final List<Offset> out = <Offset>[];

    for (int i = 1; i <= steps; i++) {
      final double t = i / steps;

      out.add(
        Offset(
          from.dx + (to.dx - from.dx) * t,

          from.dy + (to.dy - from.dy) * t,
        ),
      );
    }

    return out;
  }

  void _handleOverlayPointerUpOrCancel(PointerEvent event) {
    if (!_isFreeDrawMode && event.kind == PointerDeviceKind.touch) {
      return;
    }

    final didRemove = _activePointerIds.remove(event.pointer);

    if (!didRemove) {
      return;
    }

    _activePointerKinds.remove(event.pointer);

    if (_activeStylusPointerId == event.pointer) {
      _activeStylusPointerId = null;
    }

    _straightenSnappedAngleByPointer.remove(event.pointer);

    _straightenStartPageByPointer.remove(event.pointer);

    _pendingStraightenCommitByPointer.remove(event.pointer);

    if (_isFreeDrawMode) {
      if (_activePointerIds.isEmpty && _inProgressStroke != null) {
        _handleFreeDrawPointerEnd(
          _inProgressStroke?.pageNumber ?? _currentPage,

          pointerId: event.pointer,
        );
      }

      _safeSetState(() {});

      return;
    }

    _safeSetState(() {});
  }
}
