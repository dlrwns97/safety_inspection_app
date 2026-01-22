import 'dart:math';

import 'package:flutter/material.dart';

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
    final maxWidth = min(
      MediaQuery.of(context).size.width * 0.5,
      360.0,
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
            DropdownButtonFormField<String>(
              value: _selectedMember,
              decoration: const InputDecoration(
                labelText: '부재',
                border: OutlineInputBorder(),
              ),
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
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '부재를 선택하세요.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _endAController,
              decoration: const InputDecoration(
                labelText: 'A(단부)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _midBController,
              decoration: const InputDecoration(
                labelText: 'B(중앙)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _endCController,
              decoration: const InputDecoration(
                labelText: 'C(단부)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: isSaveEnabled
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
                  child: const Text('저장'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
