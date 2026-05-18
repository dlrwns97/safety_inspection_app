import 'package:file_picker/file_picker.dart';
import 'package:pdfx/pdfx.dart';
import 'package:safety_inspection_app/application/drawing/use_cases/load_pdf_controller_use_case.dart';
import 'package:safety_inspection_app/application/drawing/use_cases/pdf_use_case_models.dart';
import 'package:safety_inspection_app/application/drawing/use_cases/replace_pdf_use_case.dart';
import 'package:safety_inspection_app/models/site.dart';

final LoadPdfControllerUseCase _loadPdfControllerUseCase =
    LoadPdfControllerUseCase();
final ReplacePdfUseCase _replacePdfUseCase = ReplacePdfUseCase();

Future<PdfControllerLoadResult?> loadPdfControllerForSite({
  required Site site,
  required PdfController? previousController,
  int initialPage = 1,
}) async {
  return _loadPdfControllerUseCase.execute(
    site: site,
    previousController: previousController,
    initialPage: initialPage,
  );
}

Future<ReplacePdfResult?> replacePdfAndUpdateSite({
  required Site site,
  ConfirmPdfReplace? confirmReplace,
}) async {
  return _replacePdfUseCase.execute(site: site, confirmReplace: confirmReplace);
}

Future<String?> persistPickedPdf(PlatformFile file) async {
  return _replacePdfUseCase.persistPickedPdf(
    PickedPdfFile(name: file.name, path: file.path, bytes: file.bytes),
  );
}
