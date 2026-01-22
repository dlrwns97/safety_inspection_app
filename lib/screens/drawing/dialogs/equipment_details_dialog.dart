import 'dart:math';

import 'package:flutter/material.dart';

import '../widgets/narrow_dialog_frame.dart';

class EquipmentDetails {
  const EquipmentDetails({
    required this.memberType,
    required this.sizeValues,
  });

  final String memberType;
  final List<String> sizeValues;
}

Future<EquipmentDetails?> showEquipmentDetailsDialog({
  required BuildContext context,
  required String title,
  required List<String> memberOptions,
  required Map<String, List<String>> sizeLabelsByMember,
  String? initialMemberType,
  List<String>? initialSizeValues,
}) {
  return showDialog<EquipmentDetails>(
    context: context,
    builder: (context) => _EquipmentDetailsDialog(
      title: title,
      memberOptions: memberOptions,
      sizeLabelsByMember: sizeLabelsByMember,
      initialMemberType: initialMemberType,
      initialSizeValues: initialSizeValues,
    ),
  );
}

class _EquipmentDetailsDialog extends StatefulWidget {
  const _EquipmentDetailsDialog({
    required this.title,
    required this.memberOptions,
    required this.sizeLabelsByMember,
    this.initialMemberType,
    this.initialSizeValues,
  });

  final String title;
  final List<String> memberOptions;
  final Map<String, List<String>> sizeLabelsByMember;
  final String? initialMemberType;
  final List<String>? initialSizeValues;

  @override
  State<_EquipmentDetailsDialog> createState() =>
      _EquipmentDetailsDialogState();
}

class _EquipmentDetailsDialogState extends State<_EquipmentDetailsDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedMember;
  List<String> _sizeLabels = [];
  List<TextEditingController> _sizeControllers = [];

  @override
  void initState() {
    super.initState();
    _selectedMember = widget.initialMemberType;
    _sizeLabels = _selectedMember == null
        ? []
        : widget.sizeLabelsByMember[_selectedMember] ?? [];
    _sizeControllers = _buildSizeControllers(
      _sizeLabels,
      widget.initialSizeValues,
    );
  }

  @override
  void dispose() {
    _disposeSizeControllers();
    super.dispose();
  }

  List<TextEditingController> _buildSizeControllers(
    List<String> labels,
    List<String>? initialValues,
  ) {
    return List.generate(labels.length, (index) {
      final controller = TextEditingController();
      if (initialValues != null && index < initialValues.length) {
        controller.text = initialValues[index];
      }
      return controller;
    });
  }

  void _disposeSizeControllers() {
    for (final controller in _sizeControllers) {
      controller.dispose();
    }
  }

  void _resetSizeControllers(List<String> labels) {
    _disposeSizeControllers();
    _sizeControllers = _buildSizeControllers(labels, null);
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
                  _sizeLabels = value == null
                      ? []
                      : widget.sizeLabelsByMember[value] ?? [];
                  _resetSizeControllers(_sizeLabels);
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '부재를 선택하세요.';
                }
                return null;
              },
            ),
            if (_selectedMember != null) ...[
              const SizedBox(height: 16),
              Text(
                '사이즈',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              ...List.generate(_sizeLabels.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextFormField(
                    controller: _sizeControllers[index],
                    decoration: InputDecoration(
                      labelText: _sizeLabels[index],
                      border: const OutlineInputBorder(),
                    ),
                  ),
                );
              }),
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
                          if (!(_formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          Navigator.of(context).pop(
                            EquipmentDetails(
                              memberType: _selectedMember!,
                              sizeValues: _sizeControllers
                                  .map((controller) => controller.text)
                                  .toList(),
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
