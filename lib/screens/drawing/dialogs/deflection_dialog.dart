import 'package:flutter/material.dart';

import 'dialog_field_builders.dart';
import '../widgets/narrow_dialog_frame.dart';

class DeflectionDetails {
  const DeflectionDetails({
    required this.memberType,
    required this.endAText,
    required this.midBText,
    required this.endCText,
  });

  final String memberType;
  final String endAText;
  final String midBText;
  final String endCText;
}

Future<DeflectionDetails?> showDeflectionDialog({
  required BuildContext context,
  required String title,
  required List<String> memberOptions,
  String? initialMemberType,
  String? initialEndAText,
  String? initialMidBText,
  String? initialEndCText,
}) {
  return showDialog<DeflectionDetails>(
    context: context,
    builder: (context) => _DeflectionDialog(
      title: title,
      memberOptions: memberOptions,
      initialMemberType: initialMemberType,
      initialEndAText: initialEndAText,
      initialMidBText: initialMidBText,
      initialEndCText: initialEndCText,
    ),
  );
}

class _DeflectionDialog extends StatefulWidget {
  const _DeflectionDialog({
    required this.title,
    required this.memberOptions,
    this.initialMemberType,
    this.initialEndAText,
    this.initialMidBText,
    this.initialEndCText,
  });

  final String title;
  final List<String> memberOptions;
  final String? initialMemberType;
  final String? initialEndAText;
  final String? initialMidBText;
  final String? initialEndCText;

  @override
  State<_DeflectionDialog> createState() => _DeflectionDialogState();
}

class _DeflectionDialogState extends State<_DeflectionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _endAController = TextEditingController();
  final _midBController = TextEditingController();
  final _endCController = TextEditingController();
  String? _selectedMember;

  @override
  void initState() {
    super.initState();
    _selectedMember = widget.initialMemberType;
    _endAController.text = widget.initialEndAText ?? '';
    _midBController.text = widget.initialMidBText ?? '';
    _endCController.text = widget.initialEndCText ?? '';
  }

  @override
  void dispose() {
    _endAController.dispose();
    _midBController.dispose();
    _endCController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = dialogMaxWidth(
      context,
      widthFactor: 0.5,
      maxWidth: 360.0,
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
              controller: _endAController,
              labelText: 'A(단부)',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 12),
            buildDialogTextField(
              controller: _midBController,
              labelText: 'B(중앙)',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 12),
            buildDialogTextField(
              controller: _endCController,
              labelText: 'C(단부)',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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
                        DeflectionDetails(
                          memberType: _selectedMember!,
                          endAText: _endAController.text.trim(),
                          midBText: _midBController.text.trim(),
                          endCText: _endCController.text.trim(),
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
