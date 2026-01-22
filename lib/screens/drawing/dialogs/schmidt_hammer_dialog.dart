import 'dart:math';

import 'package:flutter/material.dart';

import '../widgets/narrow_dialog_frame.dart';

class SchmidtHammerDetails {
  const SchmidtHammerDetails({
    required this.memberType,
    required this.maxValueText,
    required this.minValueText,
  });

  final String memberType;
  final String maxValueText;
  final String minValueText;
}

Future<SchmidtHammerDetails?> showSchmidtHammerDialog({
  required BuildContext context,
  required String title,
  required List<String> memberOptions,
  String? initialMemberType,
  String? initialMaxValueText,
  String? initialMinValueText,
}) {
  return showDialog<SchmidtHammerDetails>(
    context: context,
    builder: (context) => _SchmidtHammerDialog(
      title: title,
      memberOptions: memberOptions,
      initialMemberType: initialMemberType,
      initialMaxValueText: initialMaxValueText,
      initialMinValueText: initialMinValueText,
    ),
  );
}

class _SchmidtHammerDialog extends StatefulWidget {
  const _SchmidtHammerDialog({
    required this.title,
    required this.memberOptions,
    this.initialMemberType,
    this.initialMaxValueText,
    this.initialMinValueText,
  });

  final String title;
  final List<String> memberOptions;
  final String? initialMemberType;
  final String? initialMaxValueText;
  final String? initialMinValueText;

  @override
  State<_SchmidtHammerDialog> createState() => _SchmidtHammerDialogState();
}

class _SchmidtHammerDialogState extends State<_SchmidtHammerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _maxValueController = TextEditingController();
  final _minValueController = TextEditingController();
  String? _selectedMember;
  String? _rangeError;

  @override
  void initState() {
    super.initState();
    _selectedMember = widget.initialMemberType;
    _maxValueController.text = widget.initialMaxValueText ?? '';
    _minValueController.text = widget.initialMinValueText ?? '';
  }

  @override
  void dispose() {
    _maxValueController.dispose();
    _minValueController.dispose();
    super.dispose();
  }

  bool _hasInvalidRange(String minText, String maxText) {
    if (minText.isEmpty || maxText.isEmpty) {
      return false;
    }
    final minValue = double.tryParse(minText);
    final maxValue = double.tryParse(maxText);
    if (minValue == null || maxValue == null) {
      return false;
    }
    return minValue > maxValue;
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
              controller: _maxValueController,
              decoration: const InputDecoration(
                labelText: '최댓값',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) {
                if (_rangeError != null) {
                  setState(() {
                    _rangeError = null;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _minValueController,
              decoration: const InputDecoration(
                labelText: '최솟값',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) {
                if (_rangeError != null) {
                  setState(() {
                    _rangeError = null;
                  });
                }
              },
            ),
            if (_rangeError != null) ...[
              const SizedBox(height: 8),
              Text(
                _rangeError!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
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
                          final minText = _minValueController.text.trim();
                          final maxText = _maxValueController.text.trim();
                          if (_hasInvalidRange(minText, maxText)) {
                            setState(() {
                              _rangeError = '최솟값이 최댓값보다 클 수 없습니다.';
                            });
                            return;
                          }
                          if (!(_formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          Navigator.of(context).pop(
                            SchmidtHammerDetails(
                              memberType: _selectedMember!,
                              maxValueText: maxText,
                              minValueText: minText,
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
