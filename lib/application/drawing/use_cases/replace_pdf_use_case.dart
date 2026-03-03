import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:safety_inspection_app/application/drawing/use_cases/pdf_use_case_models.dart';
import 'package:safety_inspection_app/constants/strings_ko.dart';
import 'package:safety_inspection_app/models/site.dart';

typedef PickPdfFile = Future<PickedPdfFile?> Function();
typedef PersistPickedPdf = Future<String?> Function(PickedPdfFile file);
typedef ConfirmPdfReplace = Future<bool> Function(String fileName);

class ReplacePdfUseCase {
  ReplacePdfUseCase({
    PickPdfFile? pickPdfFile,
    PersistPickedPdf? persistPickedPdf,
  }) : _pickPdfFile = pickPdfFile ?? _defaultPickPdfFile,
       _persistPickedPdf = persistPickedPdf ?? _defaultPersistPickedPdf;

  final PickPdfFile _pickPdfFile;
  final PersistPickedPdf _persistPickedPdf;

  Future<ReplacePdfResult?> execute({
    required Site site,
    ConfirmPdfReplace? confirmReplace,
  }) async {
    final pickedFile = await _pickPdfFile();
    if (pickedFile == null) {
      return null;
    }
    if (confirmReplace != null) {
      final shouldReplace = await confirmReplace(pickedFile.name);
      if (!shouldReplace) {
        return null;
      }
    }

    String? pdfPath = pickedFile.path;
    if ((pdfPath == null || pdfPath.isEmpty) && pickedFile.bytes != null) {
      pdfPath = await _persistPickedPdf(pickedFile);
    }

    if (pdfPath == null || pdfPath.isEmpty) {
      return const ReplacePdfResult(
        updatedSite: null,
        error: StringsKo.pdfDrawingLoadFailed,
      );
    }

    return ReplacePdfResult(
      updatedSite: site.copyWith(pdfPath: pdfPath, pdfName: pickedFile.name),
      error: null,
    );
  }

  Future<String?> persistPickedPdf(PickedPdfFile file) {
    return _persistPickedPdf(file);
  }

  static Future<PickedPdfFile?> _defaultPickPdfFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }
    final file = result.files.first;
    return PickedPdfFile(name: file.name, path: file.path, bytes: file.bytes);
  }

  static Future<String?> _defaultPersistPickedPdf(PickedPdfFile file) async {
    try {
      if (file.bytes == null) {
        return null;
      }
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
      return null;
    }
  }
}
