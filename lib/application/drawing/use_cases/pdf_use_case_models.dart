import 'dart:typed_data';

import 'package:flutter/rendering.dart';
import 'package:pdfx/pdfx.dart';
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
  const ReplacePdfResult({required this.updatedSite, required this.error});

  final Site? updatedSite;
  final String? error;
}

class PickedPdfFile {
  const PickedPdfFile({
    required this.name,
    required this.path,
    required this.bytes,
  });

  final String name;
  final String? path;
  final Uint8List? bytes;
}
