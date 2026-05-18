class PdfPageNavigationController {
  const PdfPageNavigationController();

  int normalizePage(int page) => page <= 0 ? 1 : page;

  int clampPage({required int page, required int pageCount}) {
    final safePageCount = normalizePage(pageCount);
    return normalizePage(page).clamp(1, safePageCount).toInt();
  }

  PdfPageNavigationState resolveLoadedPage({
    required int restoredPage,
    required int currentPage,
    required int pageCount,
  }) {
    final safePageCount = normalizePage(pageCount);
    final basePage = restoredPage > 0
        ? restoredPage
        : normalizePage(currentPage);
    final resolvedPage = basePage.clamp(1, safePageCount).toInt();
    return PdfPageNavigationState(
      pageCount: safePageCount,
      currentPage: resolvedPage,
      pendingRestorePage: pendingRestorePageFor(resolvedPage),
      didRetryPendingRestoreJump: false,
    );
  }

  int? pendingRestorePageFor(int page) {
    final normalizedPage = normalizePage(page);
    return normalizedPage > 1 ? normalizedPage : null;
  }

  PdfPageChangedDecision handlePageChanged({
    required int reportedPage,
    required int? pendingRestorePage,
    required bool didRetryPendingRestoreJump,
  }) {
    final normalizedPage = normalizePage(reportedPage);
    final pendingPage = pendingRestorePage;

    if (pendingPage != null) {
      if (normalizedPage == pendingPage) {
        return PdfPageChangedDecision(
          currentPage: normalizedPage,
          pendingRestorePage: null,
          didRetryPendingRestoreJump: false,
        );
      }

      if (pendingPage > 1) {
        return PdfPageChangedDecision(
          currentPage: normalizedPage,
          pendingRestorePage: pendingPage,
          didRetryPendingRestoreJump: true,
          jumpToPage: pendingPage,
          shouldApplyPage: false,
        );
      }
    }

    return PdfPageChangedDecision(
      currentPage: normalizedPage,
      pendingRestorePage: pendingPage,
      didRetryPendingRestoreJump: didRetryPendingRestoreJump,
    );
  }

  PdfPageNavigationState resetAfterPdfReplacement() {
    return const PdfPageNavigationState(
      pageCount: 1,
      currentPage: 1,
      pendingRestorePage: null,
      didRetryPendingRestoreJump: false,
    );
  }

  int previousPage({required int currentPage, required int pageCount}) {
    return clampPage(
      page: normalizePage(currentPage) - 1,
      pageCount: pageCount,
    );
  }

  int nextPage({required int currentPage, required int pageCount}) {
    return clampPage(
      page: normalizePage(currentPage) + 1,
      pageCount: pageCount,
    );
  }
}

class PdfPageNavigationState {
  const PdfPageNavigationState({
    required this.pageCount,
    required this.currentPage,
    required this.pendingRestorePage,
    required this.didRetryPendingRestoreJump,
  });

  final int pageCount;
  final int currentPage;
  final int? pendingRestorePage;
  final bool didRetryPendingRestoreJump;
}

class PdfPageChangedDecision {
  const PdfPageChangedDecision({
    required this.currentPage,
    required this.pendingRestorePage,
    required this.didRetryPendingRestoreJump,
    this.jumpToPage,
    this.shouldApplyPage = true,
  });

  final int currentPage;
  final int? pendingRestorePage;
  final bool didRetryPendingRestoreJump;
  final int? jumpToPage;
  final bool shouldApplyPage;
}
