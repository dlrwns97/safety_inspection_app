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

    test('optional decimal validator allows empty and valid decimal', () {
      expect(
        EquipmentInputValidationService.validateOptionalDecimal(''),
        isNull,
      );
      expect(
        EquipmentInputValidationService.validateOptionalDecimal('12.5'),
        isNull,
      );
    });

    test('optional decimal validator rejects invalid text', () {
      final result = EquipmentInputValidationService.validateOptionalDecimal(
        '12a',
      );
      expect(result, isNotNull);
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
  });
}
