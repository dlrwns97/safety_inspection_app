class EquipmentInputValidationService {
  const EquipmentInputValidationService._();

  static String? validateRequiredSelection(
    String? value, {
    required String requiredMessage,
  }) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return requiredMessage;
    }
    return null;
  }

  static String? validateOptionalDecimal(
    String? value, {
    String invalidMessage = '숫자 형식으로 입력하세요.',
  }) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }
    return double.tryParse(trimmed) == null ? invalidMessage : null;
  }

  static String? validateOptionalInteger(
    String? value, {
    String invalidMessage = '정수 형식으로 입력하세요.',
    int? maxDigits,
  }) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }
    if (maxDigits != null && trimmed.length > maxDigits) {
      return invalidMessage;
    }
    return int.tryParse(trimmed) == null ? invalidMessage : null;
  }
}
