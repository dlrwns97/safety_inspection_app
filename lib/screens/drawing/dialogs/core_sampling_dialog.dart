import 'dart:math';

import 'package:flutter/material.dart';

import '../widgets/narrow_dialog_frame.dart';

class CoreSamplingDetails {
  const CoreSamplingDetails({
    required this.memberType,
    required this.avgValueText,
  });

  final String memberType;
  final String avgValueText;
}

Future<CoreSamplingDetails?> showCoreSamplingDialog({
  required BuildContext context,
  required String title,
  required List<String> memberOptions,
  String? initialMemberType,
  String? initialAvgValueText,
}) {
  return showDialog<CoreSamplingDetails>(
    context: context,
    builder: (context) => _CoreSamplingDialog(
      title: title,
      memberOptions: memberOptions,
      initialMemberType: initialMemberType,
      initialAvgValueText: initialAvgValueText,
    ),
  );
}

class _CoreSamplingDialog extends StatefulWidget {
  const _CoreSamplingDialog({
    required this.title,
    required this.memberOptions,
    this.initialMemberType,
    this.initialAvgValueText,
  });

  final String title;
  final List<String> memberOptions;
  final String? initialMemberType;
  final String? initialAvgValueText;

  @override
  State<_CoreSamplingDialog> createState() => _CoreSamplingDialogState();
}

class _CoreSamplingDialogState extends State<_CoreSamplingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _avgValueController = TextEditingController();
  String? _selectedMember;

  @override
  void initState() {
    super.initState();
    _selectedMember = widget.initialMemberType;
    _avgValueController.text = widget.initialAvgValueText ?? '';
  }

  @override
  void dispose() {
    _avgValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = min(
      MediaQuery.of(context).size.width * 0.6,
      520.0,
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
              controller: _avgValueController,
              decoration: const InputDecoration(
                labelText: '평균값',
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
                            CoreSamplingDetails(
                              memberType: _selectedMember!,
                              avgValueText: _avgValueController.text.trim(),
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
