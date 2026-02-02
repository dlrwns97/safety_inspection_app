import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dialog_field_builders.dart';
import '../widgets/narrow_dialog_frame.dart';

class RebarSpacingDetails {
  const RebarSpacingDetails({
    required this.memberType,
    this.remarkLeft,
    this.remarkRight,
    this.numberPrefix,
    this.numberValue,
  });

  final String memberType;
  final String? remarkLeft;
  final String? remarkRight;
  final String? numberPrefix;
  final String? numberValue;
}

Future<RebarSpacingDetails?> showRebarSpacingDialog({
  required BuildContext context,
  required String title,
  required List<String> memberOptions,
  String? initialMemberType,
  String? initialRemarkLeft,
  String? initialRemarkRight,
  String? initialNumberPrefix,
  String? initialNumberValue,
}) {
  return showDialog<RebarSpacingDetails>(
    context: context,
    builder: (context) => _RebarSpacingDialog(
      title: title,
      memberOptions: memberOptions,
      initialMemberType: initialMemberType,
      initialRemarkLeft: initialRemarkLeft,
      initialRemarkRight: initialRemarkRight,
      initialNumberPrefix: initialNumberPrefix,
      initialNumberValue: initialNumberValue,
    ),
  );
}

class _RebarSpacingDialog extends StatefulWidget {
  const _RebarSpacingDialog({
    required this.title,
    required this.memberOptions,
    this.initialMemberType,
    this.initialRemarkLeft,
    this.initialRemarkRight,
    this.initialNumberPrefix,
    this.initialNumberValue,
  });

  final String title;
  final List<String> memberOptions;
  final String? initialMemberType;
  final String? initialRemarkLeft;
  final String? initialRemarkRight;
  final String? initialNumberPrefix;
  final String? initialNumberValue;

  @override
  State<_RebarSpacingDialog> createState() => _RebarSpacingDialogState();
}

class _RebarSpacingDialogState extends State<_RebarSpacingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  String? _selectedMember;
  String? _selectedRemarkLeft;
  String? _selectedRemarkRight;
  String? _selectedNumberPrefix;

  @override
  void initState() {
    super.initState();
    _selectedMember = widget.initialMemberType;
    _selectedRemarkLeft = widget.initialRemarkLeft;
    _selectedRemarkRight = widget.initialRemarkRight;
    _selectedNumberPrefix = widget.initialNumberPrefix;
    _numberController.text = widget.initialNumberValue ?? '';
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
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedRemarkLeft,
                    decoration: const InputDecoration(
                      labelText: '비고',
                      border: OutlineInputBorder(),
                    ),
                    items: const ['중앙', '단부', 'X열', 'Y열']
                        .map(
                          (option) => DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRemarkLeft = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedRemarkRight,
                    decoration: const InputDecoration(
                      labelText: '비고',
                      border: OutlineInputBorder(),
                    ),
                    items: const ['하부', '측면', '중앙', '단부']
                        .map(
                          (option) => DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRemarkRight = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedNumberPrefix,
                    decoration: const InputDecoration(
                      labelText: '번호',
                      border: OutlineInputBorder(),
                    ),
                    items: const ['FS', 'FQ']
                        .map(
                          (option) => DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedNumberPrefix = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _numberController,
                    decoration: const InputDecoration(
                      labelText: '번호',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    maxLength: 6,
                  ),
                ),
              ],
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
                          remarkLeft: _selectedRemarkLeft,
                          remarkRight: _selectedRemarkRight,
                          numberPrefix: _selectedNumberPrefix,
                          numberValue:
                              _numberController.text.trim().isEmpty
                                  ? null
                                  : _numberController.text.trim(),
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
