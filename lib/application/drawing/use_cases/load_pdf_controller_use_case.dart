import 'dart:io';

import 'package:flutter/rendering.dart';
import 'package:pdfx/pdfx.dart';
import 'package:safety_inspection_app/application/drawing/use_cases/pdf_use_case_models.dart';
import 'package:safety_inspection_app/constants/strings_ko.dart';
import 'package:safety_inspection_app/models/site.dart';

typedef PdfFileExists = Future<bool> Function(String path);
typedef PdfFileLength = Future<int> Function(String path);
typedef PdfControllerFactory =
    PdfController Function(String path, int initialPage);

class LoadPdfControllerUseCase {
  LoadPdfControllerUseCase({
    PdfFileExists? fileExists,
    PdfFileLength? fileLength,
    PdfControllerFactory? controllerFactory,
  }) : _fileExists = fileExists ?? ((path) => File(path).exists()),
       _fileLength = fileLength ?? ((path) => File(path).length()),
       _controllerFactory =
           controllerFactory ??
           ((path, initialPage) => PdfController(
             document: PdfDocument.openFile(path),
             initialPage: initialPage,
           ));

  final PdfFileExists _fileExists;
  final PdfFileLength _fileLength;
  final PdfControllerFactory _controllerFactory;

  Future<PdfControllerLoadResult?> execute({
    required Site site,
    required PdfController? previousController,
    int initialPage = 1,
  }) async {
    final path = site.pdfPath;
    if (path == null || path.isEmpty) {
      return null;
    }
    previousController?.dispose();

    final exists = await _fileExists(path);
    if (!exists) {
      debugPrint('PDF file not found at $path');
      return const PdfControllerLoadResult(
        controller: null,
        error: StringsKo.pdfDrawingLoadFailed,
        clearedPageSizes: <int, Size>{},
        pageCount: 1,
        currentPage: 1,
      );
    }
    try {
      final fileSize = await _fileLength(path);
      debugPrint(
        'Loading PDF: name=${site.pdfName ?? File(path).uri.pathSegments.last}, '
        'path=$path, bytes=$fileSize, initialPage=${initialPage <= 0 ? 1 : initialPage}',
      );
      return PdfControllerLoadResult(
        controller: _controllerFactory(
          path,
          initialPage <= 0 ? 1 : initialPage,
        ),
        error: null,
        clearedPageSizes: const <int, Size>{},
        pageCount: 1,
        currentPage: initialPage <= 0 ? 1 : initialPage,
      );
    } catch (error) {
      debugPrint('Failed to load PDF at $path: $error');
      return const PdfControllerLoadResult(
        controller: null,
        error: StringsKo.pdfDrawingLoadFailed,
        clearedPageSizes: <int, Size>{},
        pageCount: 1,
        currentPage: 1,
      );
    }
  }
}
