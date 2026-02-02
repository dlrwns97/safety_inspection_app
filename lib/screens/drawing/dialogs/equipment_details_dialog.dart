import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dialog_field_builders.dart';
import '../widgets/narrow_dialog_frame.dart';

class EquipmentDetails {
  const EquipmentDetails({
    required this.memberType,
    required this.sizeValues,
    required this.remark,
    required this.wComplete,
    required this.hComplete,
    required this.dComplete,
  });

  final String? memberType;
  final List<String> sizeValues;
  final String? remark;
  final bool? wComplete;
  final bool? hComplete;
  final bool? dComplete;
}

Future<EquipmentDetails?> showEquipmentDetailsDialog({
  required BuildContext context,
  required String title,
  required List<String> memberOptions,
  required Map<String, List<String>> sizeLabelsByMember,
  String? initialMemberType,
  List<String>? initialSizeValues,
  String? initialRemark,
  bool? initialWComplete,
  bool? initialHComplete,
  bool? initialDComplete,
}) {
  return showDialog<EquipmentDetails>(
    context: context,
    builder: (context) => _EquipmentDetailsDialog(
      title: title,
      memberOptions: memberOptions,
      sizeLabelsByMember: sizeLabelsByMember,
      initialMemberType: initialMemberType,
      initialSizeValues: initialSizeValues,
      initialRemark: initialRemark,
      initialWComplete: initialWComplete,
      initialHComplete: initialHComplete,
      initialDComplete: initialDComplete,
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
    this.initialRemark,
    this.initialWComplete,
    this.initialHComplete,
    this.initialDComplete,
  });

  final String title;
  final List<String> memberOptions;
  final Map<String, List<String>> sizeLabelsByMember;
  final String? initialMemberType;
  final List<String>? initialSizeValues;
  final String? initialRemark;
  final bool? initialWComplete;
  final bool? initialHComplete;
  final bool? initialDComplete;

  @override
  State<_EquipmentDetailsDialog> createState() =>
      _EquipmentDetailsDialogState();
}

class _EquipmentDetailsDialogState extends State<_EquipmentDetailsDialog> {
  String? _selectedMember;
  List<String> _sizeLabels = [];
  List<TextEditingController> _sizeControllers = [];
  String? _selectedRemark;
  bool _wComplete = true;
  bool _hComplete = true;
  bool _dComplete = true;

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
    _selectedRemark = widget.initialRemark;
    _wComplete = widget.initialWComplete ?? true;
    _hComplete = widget.initialHComplete ?? true;
    _dComplete = widget.initialDComplete ?? true;
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
    final maxWidth = dialogMaxWidth(
      context,
      widthFactor: 0.6,
      maxWidth: 520.0,
    );

    return NarrowDialogFrame(
      maxWidth: maxWidth,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
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
              ),
              if (_selectedMember != null) ...[
                const SizedBox(height: 16),
                Text(
                  '사이즈',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                ...List.generate(_sizeLabels.length, (index) {
                  final label = _sizeLabels[index];
                  final isLastField = index == _sizeLabels.length - 1;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: buildDialogTextField(
                      controller: _sizeControllers[index],
                      labelText: label,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: false,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*$'),
                        ),
                      ],
                      textInputAction: isLastField
                          ? TextInputAction.done
                          : TextInputAction.next,
                      suffixIcon: _buildCompletionToggle(label),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedRemark,
                  decoration: const InputDecoration(
                    labelText: '비고',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    '마감 포함',
                    '슬래브 제외',
                    '마감 포함+벽체 간섭',
                    '슬래브+단열재 제외',
                    '슬래브 제외+단열재 포함',
                  ].map((option) {
                    return DropdownMenuItem(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRemark = value;
                    });
                  },
                ),
              ],
              const SizedBox(height: 16),
              buildDialogActionButtons(
                context,
                onSave: () {
                  Navigator.of(context).pop(
                    EquipmentDetails(
                      memberType: _selectedMember,
                      sizeValues: _sizeControllers
                          .map((controller) => controller.text)
                          .toList(),
                      remark: _selectedRemark,
                      wComplete: _sizeLabels.contains('W')
                          ? _wComplete
                          : null,
                      hComplete: _sizeLabels.contains('H')
                          ? _hComplete
                          : null,
                      dComplete: _sizeLabels.contains('D')
                          ? _dComplete
                          : null,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildCompletionToggle(String label) {
    switch (label) {
      case 'W':
        return _buildCompletionCheckbox(
          value: _wComplete,
          onChanged: (value) {
            setState(() {
              _wComplete = value ?? true;
            });
          },
        );
      case 'H':
        return _buildCompletionCheckbox(
          value: _hComplete,
          onChanged: (value) {
            setState(() {
              _hComplete = value ?? true;
            });
          },
        );
      case 'D':
        return _buildCompletionCheckbox(
          value: _dComplete,
          onChanged: (value) {
            setState(() {
              _dComplete = value ?? true;
            });
          },
        );
      default:
        return null;
    }
  }

  Widget _buildCompletionCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Center(
        child: Checkbox(
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
