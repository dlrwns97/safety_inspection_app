import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safety_inspection_app/application/inspection/services/equipment_input_validation_service.dart';

DropdownButtonFormField<String> buildDialogDropdownField({
  required String? value,
  required String labelText,
  required List<DropdownMenuItem<String>> items,
  required ValueChanged<String?> onChanged,
  required String requiredMessage,
}) {
  return DropdownButtonFormField<String>(
    initialValue: value,
    decoration: InputDecoration(
      labelText: labelText,
      border: const OutlineInputBorder(),
    ),
    items: items,
    onChanged: onChanged,
    validator: (selected) =>
        EquipmentInputValidationService.validateRequiredSelection(
          selected,
          requiredMessage: requiredMessage,
        ),
  );
}

TextFormField buildDialogTextField({
  required TextEditingController controller,
  required String labelText,
  required TextInputType keyboardType,
  List<TextInputFormatter>? inputFormatters,
  TextInputAction? textInputAction,
  Widget? suffixIcon,
  FormFieldValidator<String>? validator,
}) {
  return TextFormField(
    controller: controller,
    decoration: InputDecoration(
      labelText: labelText,
      border: const OutlineInputBorder(),
      suffixIcon: suffixIcon,
    ),
    keyboardType: keyboardType,
    inputFormatters: inputFormatters,
    textInputAction: textInputAction,
    validator: validator,
  );
}

FormFieldValidator<String> dialogOptionalDecimalValidator({
  String invalidMessage = '숫자 형식으로 입력하세요.',
}) {
  return (value) => EquipmentInputValidationService.validateOptionalDecimal(
    value,
    invalidMessage: invalidMessage,
  );
}

FormFieldValidator<String> dialogOptionalIntegerValidator({
  String invalidMessage = '정수 형식으로 입력하세요.',
  int? maxDigits,
}) {
  return (value) => EquipmentInputValidationService.validateOptionalInteger(
    value,
    invalidMessage: invalidMessage,
    maxDigits: maxDigits,
  );
}

Widget buildDialogActionButtons(
  BuildContext context, {
  required VoidCallback? onSave,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('취소'),
      ),
      const SizedBox(width: 8),
      FilledButton(onPressed: onSave, child: const Text('저장')),
    ],
  );
}

double dialogMaxWidth(
  BuildContext context, {
  required double widthFactor,
  required double maxWidth,
}) {
  return min(MediaQuery.of(context).size.width * widthFactor, maxWidth);
}
