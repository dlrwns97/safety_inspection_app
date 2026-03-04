import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:pdfx/pdfx.dart';
import 'package:safety_inspection_app/models/drawing/drawing_stroke.dart';

class PendingAreaEraserMove {
  const PendingAreaEraserMove({
    required this.pageNumber,
    required this.pageSize,
    required this.pageLocal,
    required this.radiusPagePx,
  });

  final int pageNumber;
  final Size pageSize;
  final Offset pageLocal;
  final double radiusPagePx;
}

class PendingFreeDrawMove {
  const PendingFreeDrawMove({
    required this.pointerId,
    required this.pageNumber,
    required this.pageSize,
    required this.normalized,
    required this.photoScale,
  });

  final int pointerId;
  final int pageNumber;
  final Size pageSize;
  final Offset normalized;
  final double photoScale;
}

class PendingStraightenCommit {
  const PendingStraightenCommit({
    required this.snappedPageExact,
    required this.destSize,
    required this.photoScale,
  });

  final Offset snappedPageExact;
  final Size destSize;
  final double photoScale;
}

class AreaEraserSession {
  const AreaEraserSession({
    required this.radius,
    this.removedStrokeIds = const <String>{},
    this.processedStrokeIds = const <String>{},
    this.removedById = const <String, DrawingStroke>{},
    this.addedById = const <String, DrawingStroke>{},
  });

  final double radius;
  final Set<String> removedStrokeIds;
  final Set<String> processedStrokeIds;
  final Map<String, DrawingStroke> removedById;
  final Map<String, DrawingStroke> addedById;

  AreaEraserSession copyWith({
    double? radius,
    Set<String>? removedStrokeIds,
    Set<String>? processedStrokeIds,
    Map<String, DrawingStroke>? removedById,
    Map<String, DrawingStroke>? addedById,
  }) {
    return AreaEraserSession(
      radius: radius ?? this.radius,
      removedStrokeIds: removedStrokeIds ?? this.removedStrokeIds,
      processedStrokeIds: processedStrokeIds ?? this.processedStrokeIds,
      removedById: removedById ?? this.removedById,
      addedById: addedById ?? this.addedById,
    );
  }
}

class GestureState {
  GestureState();

  Offset? pointerDownPosition;
  bool tapCanceled = false;
  int? markerTapStylusPointerId;
  Offset? markerTapStylusStartLocal;
  bool markerTapStylusMoved = false;

  Offset? eraserCursorPageLocal;
  int? eraserCursorPageNumber;
  int? activeAreaEraserPointerId;
  AreaEraserSession? activeAreaEraserSession;
  int? activeStrokeEraserPointerId;
  final Set<String> erasedStrokeIdsThisDrag = <String>{};
  int erasedStrokeCountThisDrag = 0;
  PendingAreaEraserMove? pendingAreaEraserMove;
  final List<PendingAreaEraserMove> areaEraserPath = <PendingAreaEraserMove>[];
  bool isAreaEraserFrameScheduled = false;

  final Set<int> activePointerIds = <int>{};
  final Map<int, PointerDeviceKind> activePointerKinds =
      <int, PointerDeviceKind>{};
  int? activeStylusPointerId;
  final Map<int, double?> straightenSnappedAngleByPointer = <int, double?>{};
  final Map<int, Offset> straightenStartPageByPointer = <int, Offset>{};
  final Map<int, PendingStraightenCommit> pendingStraightenCommitByPointer =
      <int, PendingStraightenCommit>{};

  bool isFreeDrawConsumingOneFinger = false;
  PhotoViewControllerValue? navStartValue;
  int? navStartPage;
  Offset navAccumDelta = Offset.zero;
  Offset? pendingDrawDownViewportLocal;
  bool pendingDraw = false;
  PendingFreeDrawMove? pendingFreeDrawMove;
  bool isFreeDrawMoveScheduled = false;
}
