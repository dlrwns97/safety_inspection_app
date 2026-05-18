import 'package:flutter_test/flutter_test.dart';
import 'package:safety_inspection_app/presentation/drawing/controllers/pdf_page_navigation_controller.dart';

void main() {
  group('PdfPageNavigationController', () {
    const controller = PdfPageNavigationController();

    test('resolveLoadedPage restores a valid persisted page', () {
      final state = controller.resolveLoadedPage(
        restoredPage: 8,
        currentPage: 1,
        pageCount: 10,
      );

      expect(state.pageCount, 10);
      expect(state.currentPage, 8);
      expect(state.pendingRestorePage, 8);
      expect(state.didRetryPendingRestoreJump, isFalse);
    });

    test('resolveLoadedPage clamps restored page to document bounds', () {
      final state = controller.resolveLoadedPage(
        restoredPage: 99,
        currentPage: 1,
        pageCount: 10,
      );

      expect(state.currentPage, 10);
      expect(state.pendingRestorePage, 10);
    });

    test('handlePageChanged suppresses non-target pages during restore', () {
      final decision = controller.handlePageChanged(
        reportedPage: 3,
        pendingRestorePage: 8,
        didRetryPendingRestoreJump: true,
      );

      expect(decision.shouldApplyPage, isFalse);
      expect(decision.jumpToPage, 8);
      expect(decision.pendingRestorePage, 8);
      expect(decision.didRetryPendingRestoreJump, isTrue);
    });

    test('handlePageChanged clears pending restore on matching page', () {
      final decision = controller.handlePageChanged(
        reportedPage: 8,
        pendingRestorePage: 8,
        didRetryPendingRestoreJump: true,
      );

      expect(decision.shouldApplyPage, isTrue);
      expect(decision.currentPage, 8);
      expect(decision.pendingRestorePage, isNull);
      expect(decision.didRetryPendingRestoreJump, isFalse);
      expect(decision.jumpToPage, isNull);
    });

    test('previousPage and nextPage stay inside document bounds', () {
      expect(controller.previousPage(currentPage: 1, pageCount: 10), 1);
      expect(controller.nextPage(currentPage: 10, pageCount: 10), 10);
      expect(controller.nextPage(currentPage: 4, pageCount: 10), 5);
    });
  });
}
