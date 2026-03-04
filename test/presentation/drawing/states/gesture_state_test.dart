import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safety_inspection_app/presentation/drawing/states/gesture_state.dart';

void main() {
  group('GestureState', () {
    test('has expected defaults', () {
      final state = GestureState();

      expect(state.pointerDownPosition, isNull);
      expect(state.tapCanceled, isFalse);
      expect(state.activePointerIds, isEmpty);
      expect(state.activePointerKinds, isEmpty);
      expect(state.activeStylusPointerId, isNull);
      expect(state.pendingDraw, isFalse);
      expect(state.navStartPage, isNull);
      expect(state.navAccumDelta, Offset.zero);
      expect(state.eraserCursorPageLocal, isNull);
      expect(state.activeAreaEraserSession, isNull);
      expect(state.erasedStrokeIdsThisDrag, isEmpty);
      expect(state.pendingStraightenCommitByPointer, isEmpty);
    });

    test('stores mutable pointer/nav/eraser state', () {
      final state = GestureState();
      const pendingMove = PendingAreaEraserMove(
        pageNumber: 2,
        pageSize: Size(100, 200),
        pageLocal: Offset(10, 20),
        radiusPagePx: 8,
      );
      const pendingDrawMove = PendingFreeDrawMove(
        pointerId: 1,
        pageNumber: 2,
        pageSize: Size(100, 200),
        normalized: Offset(0.1, 0.2),
        photoScale: 1.5,
      );

      state.pointerDownPosition = const Offset(3, 4);
      state.tapCanceled = true;
      state.activePointerIds.add(7);
      state.activePointerKinds[7] = PointerDeviceKind.touch;
      state.activeStylusPointerId = 7;
      state.pendingDraw = true;
      state.navStartPage = 2;
      state.navAccumDelta = const Offset(5, 6);
      state.pendingAreaEraserMove = pendingMove;
      state.areaEraserPath.add(pendingMove);
      state.pendingFreeDrawMove = pendingDrawMove;
      state.pendingStraightenCommitByPointer[7] = const PendingStraightenCommit(
        snappedPageExact: Offset(11, 12),
        destSize: Size(100, 200),
        photoScale: 1.0,
      );

      expect(state.pointerDownPosition, const Offset(3, 4));
      expect(state.tapCanceled, isTrue);
      expect(state.activePointerIds.contains(7), isTrue);
      expect(state.activePointerKinds[7], PointerDeviceKind.touch);
      expect(state.activeStylusPointerId, 7);
      expect(state.pendingDraw, isTrue);
      expect(state.navStartPage, 2);
      expect(state.navAccumDelta, const Offset(5, 6));
      expect(state.pendingAreaEraserMove, pendingMove);
      expect(state.areaEraserPath.length, 1);
      expect(state.pendingFreeDrawMove, pendingDrawMove);
      expect(state.pendingStraightenCommitByPointer[7], isNotNull);
    });
  });
}
