import 'package:flutter/rendering.dart';
import 'package:pdfx/pdfx.dart';

class DrawingSessionState {
  DrawingSessionState({
    int currentPage = 1,
    int pageCount = 1,
    this.pdfController,
    this.pdfLoadError,
    Map<int, Size>? pdfPageSizes,
  }) : _currentPage = currentPage,
       _pageCount = pageCount,
       _pdfPageSizes = pdfPageSizes ?? <int, Size>{};

  int _currentPage;
  int _pageCount;
  PdfController? pdfController;
  String? pdfLoadError;
  final Map<int, Size> _pdfPageSizes;

  int get currentPage => _currentPage;
  set currentPage(int value) {
    _currentPage = value <= 0 ? 1 : value;
  }

  int get pageCount => _pageCount;
  set pageCount(int value) {
    _pageCount = value <= 0 ? 1 : value;
  }

  Map<int, Size> get pdfPageSizes => _pdfPageSizes;

  void dispose() {
    pdfController?.dispose();
    pdfController = null;
  }
}
