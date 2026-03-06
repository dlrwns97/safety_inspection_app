import 'package:flutter_test/flutter_test.dart';
import 'package:safety_inspection_app/application/inspection/services/equipment_input_validation_service.dart';

void main() {
  group('EquipmentInputValidationService', () {
    test('required selection validator returns error for empty value', () {
      final result = EquipmentInputValidationService.validateRequiredSelection(
        '',
        requiredMessage: 'required',
      );
      expect(result, 'required');
    });

    test('required selection validator trims whitespace before validation', () {
      final result = EquipmentInputValidationService.validateRequiredSelection(
        '   ',
        requiredMessage: 'required',
      );
      expect(result, 'required');
      expect(
        EquipmentInputValidationService.validateRequiredSelection(
          '  ok  ',
          requiredMessage: 'required',
        ),
        isNull,
      );
    });

    test(
      'optional decimal validator allows empty, spaced, and signed values',
      () {
        expect(
          EquipmentInputValidationService.validateOptionalDecimal(''),
          isNull,
        );
        expect(
          EquipmentInputValidationService.validateOptionalDecimal(null),
          isNull,
        );
        expect(
          EquipmentInputValidationService.validateOptionalDecimal('12.5'),
          isNull,
        );
        expect(
          EquipmentInputValidationService.validateOptionalDecimal('  -3.25  '),
          isNull,
        );
      },
    );

    test('optional decimal validator rejects invalid text', () {
      final result = EquipmentInputValidationService.validateOptionalDecimal(
        '12a',
      );
      expect(result, isNotNull);
    });

    test('optional decimal validator supports custom error message', () {
      expect(
        EquipmentInputValidationService.validateOptionalDecimal(
          '1.2.3',
          invalidMessage: 'invalid-decimal',
        ),
        'invalid-decimal',
      );
    });

    test('optional integer validator respects max digits', () {
      expect(
        EquipmentInputValidationService.validateOptionalInteger(
          '123456',
          maxDigits: 6,
        ),
        isNull,
      );
      expect(
        EquipmentInputValidationService.validateOptionalInteger(
          '1234567',
          maxDigits: 6,
        ),
        isNotNull,
      );
    });

    test('optional integer validator trims and rejects non-integer forms', () {
      expect(
        EquipmentInputValidationService.validateOptionalInteger(' 123 '),
        isNull,
      );
      expect(
        EquipmentInputValidationService.validateOptionalInteger('12.3'),
        isNotNull,
      );
      expect(
        EquipmentInputValidationService.validateOptionalInteger('1e3'),
        isNotNull,
      );
    });

    test('optional integer validator supports custom error message', () {
      expect(
        EquipmentInputValidationService.validateOptionalInteger(
          '12345',
          maxDigits: 4,
          invalidMessage: 'invalid-int',
        ),
        'invalid-int',
      );
    });
  });
}
