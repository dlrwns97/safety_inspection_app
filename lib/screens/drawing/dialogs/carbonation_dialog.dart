import 'dart:math';

import 'package:flutter/material.dart';

import '../widgets/narrow_dialog_frame.dart';

class CarbonationDetails {
  const CarbonationDetails({
    required this.memberType,
    required this.coverThicknessText,
    required this.depthText,
  });

  final String memberType;
  final String coverThicknessText;
  final String depthText;
}

Future<CarbonationDetails?> showCarbonationDialog({
  required BuildContext context,
  required String title,
  required List<String> memberOptions,
  String? initialMemberType,
  String? initialCoverThicknessText,
  String? initialDepthText,
}) {
  return showDialog<CarbonationDetails>(
    context: context,
    builder: (context) => _CarbonationDialog(
      title: title,
      memberOptions: memberOptions,
      initialMemberType: initialMemberType,
      initialCoverThicknessText: initialCoverThicknessText,
      initialDepthText: initialDepthText,
    ),
  );
}

class _CarbonationDialog extends StatefulWidget {
  const _CarbonationDialog({
    required this.title,
    required this.memberOptions,
    this.initialMemberType,
    this.initialCoverThicknessText,
    this.initialDepthText,
  });

  final String title;
  final List<String> memberOptions;
  final String? initialMemberType;
  final String? initialCoverThicknessText;
  final String? initialDepthText;

  @override
  State<_CarbonationDialog> createState() => _CarbonationDialogState();
}

class _CarbonationDialogState extends State<_CarbonationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _coverThicknessController = TextEditingController();
  final _depthController = TextEditingController();
  String? _selectedMember;

  @override
  void initState() {
    super.initState();
    _selectedMember = widget.initialMemberType;
    _coverThicknessController.text = widget.initialCoverThicknessText ?? '';
    _depthController.text = widget.initialDepthText ?? '';
  }

  @override
  void dispose() {
    _coverThicknessController.dispose();
    _depthController.dispose();
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
              controller: _coverThicknessController,
              decoration: const InputDecoration(
                labelText: '피복두께',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _depthController,
              decoration: const InputDecoration(
                labelText: '깊이',
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
                            CarbonationDetails(
                              memberType: _selectedMember!,
                              coverThicknessText:
                                  _coverThicknessController.text.trim(),
                              depthText: _depthController.text.trim(),
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
