import 'package:flutter/material.dart';

import 'dialog_field_builders.dart';
import '../widgets/narrow_dialog_frame.dart';

class RebarSpacingDetails {
  const RebarSpacingDetails({
    required this.memberType,
    required this.numberText,
  });

  final String memberType;
  final String numberText;
}

Future<RebarSpacingDetails?> showRebarSpacingDialog({
  required BuildContext context,
  required String title,
  required List<String> memberOptions,
  String? initialMemberType,
  String? initialNumberText,
}) {
  return showDialog<RebarSpacingDetails>(
    context: context,
    builder: (context) => _RebarSpacingDialog(
      title: title,
      memberOptions: memberOptions,
      initialMemberType: initialMemberType,
      initialNumberText: initialNumberText,
    ),
  );
}

class _RebarSpacingDialog extends StatefulWidget {
  const _RebarSpacingDialog({
    required this.title,
    required this.memberOptions,
    this.initialMemberType,
    this.initialNumberText,
  });

  final String title;
  final List<String> memberOptions;
  final String? initialMemberType;
  final String? initialNumberText;

  @override
  State<_RebarSpacingDialog> createState() => _RebarSpacingDialogState();
}

class _RebarSpacingDialogState extends State<_RebarSpacingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  String? _selectedMember;

  @override
  void initState() {
    super.initState();
    _selectedMember = widget.initialMemberType;
    _numberController.text = widget.initialNumberText ?? '';
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = dialogMaxWidth(
      context,
      widthFactor: 0.6,
      maxWidth: 520.0,
    );
    final isSaveEnabled = _selectedMember != null;

    return NarrowDialogFrame(
      maxWidth: maxWidth,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            buildDialogDropdownField(
              value: _selectedMember,
              labelText: '부재',
              items: widget.memberOptions
                  .map(
                    (option) => DropdownMenuItem(
                      value: option,
                      child: Text(option),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMember = value;
                });
              },
              requiredMessage: '부재를 선택하세요.',
            ),
            const SizedBox(height: 16),
            buildDialogTextField(
              controller: _numberController,
              labelText: '번호',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            buildDialogActionButtons(
              context,
              onSave: isSaveEnabled
                  ? () {
                      if (!(_formKey.currentState?.validate() ?? false)) {
                        return;
                      }
                      Navigator.of(context).pop(
                        RebarSpacingDetails(
                          memberType: _selectedMember!,
                          numberText: _numberController.text.trim(),
                        ),
                      );
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
