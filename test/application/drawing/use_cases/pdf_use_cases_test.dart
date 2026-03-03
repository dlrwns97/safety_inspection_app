import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:safety_inspection_app/application/drawing/use_cases/load_pdf_controller_use_case.dart';
import 'package:safety_inspection_app/application/drawing/use_cases/pdf_use_case_models.dart';
import 'package:safety_inspection_app/application/drawing/use_cases/replace_pdf_use_case.dart';
import 'package:safety_inspection_app/constants/strings_ko.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/site.dart';

Site _site({String? pdfPath, String? pdfName}) {
  return Site(
    id: 's1',
    name: '현장 A',
    createdAt: DateTime(2026, 3, 3),
    drawingType: DrawingType.blank,
    pdfPath: pdfPath,
    pdfName: pdfName,
  );
}

void main() {
  group('LoadPdfControllerUseCase', () {
    test('returns null when site has no PDF path', () async {
      var fileExistsCalled = false;
      final useCase = LoadPdfControllerUseCase(
        fileExists: (_) async {
          fileExistsCalled = true;
          return true;
        },
      );

      final result = await useCase.execute(
        site: _site(),
        previousController: null,
      );

      expect(result, isNull);
      expect(fileExistsCalled, isFalse);
    });

    test('returns load failed result when PDF file is missing', () async {
      final useCase = LoadPdfControllerUseCase(
        fileExists: (_) async => false,
        fileLength: (_) async {
          fail('fileLength should not run for missing file');
        },
        controllerFactory: (_) {
          fail('controllerFactory should not run for missing file');
        },
      );

      final result = await useCase.execute(
        site: _site(pdfPath: r'C:\missing\blueprint.pdf'),
        previousController: null,
      );

      expect(result, isNotNull);
      expect(result!.controller, isNull);
      expect(result.error, StringsKo.pdfDrawingLoadFailed);
      expect(result.clearedPageSizes, isEmpty);
      expect(result.pageCount, 1);
      expect(result.currentPage, 1);
    });

    test(
      'returns load failed result when controller creation throws',
      () async {
        final useCase = LoadPdfControllerUseCase(
          fileExists: (_) async => true,
          fileLength: (_) async => 1234,
          controllerFactory: (_) => throw Exception('open failed'),
        );

        final result = await useCase.execute(
          site: _site(pdfPath: '/tmp/broken.pdf'),
          previousController: null,
        );

        expect(result, isNotNull);
        expect(result!.controller, isNull);
        expect(result.error, StringsKo.pdfDrawingLoadFailed);
        expect(result.pageCount, 1);
        expect(result.currentPage, 1);
      },
    );
  });

  group('ReplacePdfUseCase', () {
    test('returns null when picker is canceled', () async {
      final useCase = ReplacePdfUseCase(pickPdfFile: () async => null);

      final result = await useCase.execute(site: _site());

      expect(result, isNull);
    });

    test('uses picked path when available', () async {
      final useCase = ReplacePdfUseCase(
        pickPdfFile: () async => const PickedPdfFile(
          name: '도면.pdf',
          path: '/tmp/plan.pdf',
          bytes: null,
        ),
      );

      final result = await useCase.execute(site: _site());

      expect(result, isNotNull);
      expect(result!.error, isNull);
      expect(result.updatedSite, isNotNull);
      expect(result.updatedSite!.pdfPath, '/tmp/plan.pdf');
      expect(result.updatedSite!.pdfName, '도면.pdf');
    });

    test('returns null when replacement is not confirmed', () async {
      var persisted = false;
      final useCase = ReplacePdfUseCase(
        pickPdfFile: () async => PickedPdfFile(
          name: '도면.pdf',
          path: null,
          bytes: Uint8List.fromList(<int>[1, 2, 3]),
        ),
        persistPickedPdf: (_) async {
          persisted = true;
          return '/stored/도면.pdf';
        },
      );

      final result = await useCase.execute(
        site: _site(),
        confirmReplace: (_) async => false,
      );

      expect(result, isNull);
      expect(persisted, isFalse);
    });

    test('persists bytes when picker has no path', () async {
      var persistCalled = false;
      final useCase = ReplacePdfUseCase(
        pickPdfFile: () async => PickedPdfFile(
          name: '도면.pdf',
          path: null,
          bytes: Uint8List.fromList(<int>[1, 2, 3]),
        ),
        persistPickedPdf: (picked) async {
          persistCalled = true;
          expect(picked.name, '도면.pdf');
          return '/stored/도면.pdf';
        },
      );

      final result = await useCase.execute(site: _site());

      expect(persistCalled, isTrue);
      expect(result, isNotNull);
      expect(result!.error, isNull);
      expect(result.updatedSite!.pdfPath, '/stored/도면.pdf');
      expect(result.updatedSite!.pdfName, '도면.pdf');
    });

    test('returns error when path is missing and persist fails', () async {
      final useCase = ReplacePdfUseCase(
        pickPdfFile: () async => PickedPdfFile(
          name: '도면.pdf',
          path: null,
          bytes: Uint8List.fromList(<int>[1]),
        ),
        persistPickedPdf: (_) async => null,
      );

      final result = await useCase.execute(site: _site());

      expect(result, isNotNull);
      expect(result!.updatedSite, isNull);
      expect(result.error, StringsKo.pdfDrawingLoadFailed);
    });
  });
}
