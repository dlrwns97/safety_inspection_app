import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:safety_inspection_app/constants/strings_ko.dart';
import 'package:safety_inspection_app/models/site.dart';

class PdfControllerLoadResult {
  const PdfControllerLoadResult({
    required this.controller,
    required this.error,
    required this.clearedPageSizes,
    required this.pageCount,
    required this.currentPage,
  });

  final PdfController? controller;
  final String? error;
  final Map<int, Size> clearedPageSizes;
  final int pageCount;
  final int currentPage;
}

class ReplacePdfResult {
  const ReplacePdfResult({
    required this.updatedSite,
    required this.error,
  });

  final Site? updatedSite;
  final String? error;
}

Future<PdfControllerLoadResult?> loadPdfControllerForSite({
  required Site site,
  required PdfController? previousController,
}) async {
  final path = site.pdfPath;
  if (path == null || path.isEmpty) {
    return null;
  }
  previousController?.dispose();
  final file = File(path);
  final exists = await file.exists();
  if (!exists) {
    debugPrint('PDF file not found at $path');
    return PdfControllerLoadResult(
      controller: null,
      error: StringsKo.pdfDrawingLoadFailed,
      clearedPageSizes: const {},
      pageCount: 1,
      currentPage: 1,
    );
  }
  final fileSize = await file.length();
  debugPrint(
    'Loading PDF: name=${site.pdfName ?? file.uri.pathSegments.last}, '
    'path=$path, bytes=$fileSize',
  );
  return PdfControllerLoadResult(
    controller: PdfController(
      document: PdfDocument.openFile(path),
    ),
    error: null,
    clearedPageSizes: const {},
    pageCount: 1,
    currentPage: 1,
  );
}

Future<ReplacePdfResult?> replacePdfAndUpdateSite({
  required Site site,
}) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf'],
    withData: true,
  );
  if (result == null || result.files.isEmpty) {
    return null;
  }
  final file = result.files.first;
  String? pdfPath = file.path;
  if (pdfPath == null && file.bytes != null) {
    pdfPath = await persistPickedPdf(file);
  }
  if (pdfPath == null || pdfPath.isEmpty) {
    return const ReplacePdfResult(
      updatedSite: null,
      error: StringsKo.pdfDrawingLoadFailed,
    );
  }
  return ReplacePdfResult(
    updatedSite: site.copyWith(pdfPath: pdfPath, pdfName: file.name),
    error: null,
  );
}

Future<String?> persistPickedPdf(PlatformFile file) async {
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
