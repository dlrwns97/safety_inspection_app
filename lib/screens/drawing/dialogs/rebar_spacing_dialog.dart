import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:safety_inspection_app/models/rebar_spacing_group_details.dart';

import 'dialog_field_builders.dart';
import '../widgets/narrow_dialog_frame.dart';

Future<RebarSpacingGroupDetails?> showRebarSpacingDialog({
  required BuildContext context,
  required String title,
  required List<String> memberOptions,
  String? initialMemberType,
  List<RebarSpacingMeasurement>? initialMeasurements,
  bool allowMultiple = false,
  int? baseLabelIndex,
  String? labelPrefix,
}) {
  return showDialog<RebarSpacingGroupDetails>(
    context: context,
    builder: (context) => _RebarSpacingDialog(
      title: title,
      memberOptions: memberOptions,
      initialMemberType: initialMemberType,
      initialMeasurements: initialMeasurements,
      allowMultiple: allowMultiple,
      baseLabelIndex: baseLabelIndex,
      labelPrefix: labelPrefix,
    ),
  );
}

class _RebarSpacingDialog extends StatefulWidget {
  const _RebarSpacingDialog({
    required this.title,
    required this.memberOptions,
    this.initialMemberType,
    this.initialMeasurements,
    this.allowMultiple = false,
    this.baseLabelIndex,
    this.labelPrefix,
  });

  final String title;
  final List<String> memberOptions;
  final String? initialMemberType;
  final List<RebarSpacingMeasurement>? initialMeasurements;
  final bool allowMultiple;
  final int? baseLabelIndex;
  final String? labelPrefix;

  @override
  State<_RebarSpacingDialog> createState() => _RebarSpacingDialogState();
}

class _RebarSpacingDialogState extends State<_RebarSpacingDialog> {
  static const int _maxRows = 3;

  final _formKey = GlobalKey<FormState>();
  String? _selectedMember;
  late final List<_RebarSpacingRowVm> _rows;

  @override
  void initState() {
    super.initState();
    _selectedMember = widget.initialMemberType;
    final initialMeasurements = widget.initialMeasurements;
    if (initialMeasurements != null && initialMeasurements.isNotEmpty) {
      _rows =
          initialMeasurements
              .map(
                (measurement) => _RebarSpacingRowVm(
                  remarkLeft: measurement.remarkLeft,
                  remarkRight: measurement.remarkRight,
                  numberPrefix: measurement.numberPrefix,
                  numberValue: measurement.numberValue,
                ),
              )
              .toList();
    } else {
      _rows = [_RebarSpacingRowVm()];
    }
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  bool get _canAddRow => widget.allowMultiple && _rows.length < _maxRows;

  bool get _showRowLabels =>
      widget.baseLabelIndex != null && widget.labelPrefix != null;

  String _rowLabel(int index) {
    final baseIndex = widget.baseLabelIndex ?? 0;
    final prefix = widget.labelPrefix ?? 'F';
    return '$prefix${baseIndex + index}';
  }

  void _addRow() {
    if (!_canAddRow) {
      return;
    }
    setState(() {
      _rows.add(_RebarSpacingRowVm());
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = dialogMaxWidth(
      context,
      widthFactor: 0.6,
      maxWidth: 520.0,
    );
    final isSaveEnabled = _selectedMember != null;
    final canAddRow = _canAddRow;

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
            for (var index = 0; index < _rows.length; index++) ...[
              _RebarSpacingRowFields(
                label: _showRowLabels ? _rowLabel(index) : null,
                row: _rows[index],
                onChanged: () => setState(() {}),
              ),
              if (index != _rows.length - 1) const SizedBox(height: 16),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                if (widget.allowMultiple)
                  IconButton(
                    onPressed: canAddRow ? _addRow : null,
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: '행 추가',
                  ),
                const Spacer(),
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
                            RebarSpacingGroupDetails(
                              baseLabelIndex: widget.baseLabelIndex ?? 1,
                              labelPrefix: widget.labelPrefix ?? 'F',
                              memberType: _selectedMember!,
                              measurements:
                                  _rows
                                      .map(
                                        (row) => RebarSpacingMeasurement(
                                          remarkLeft: row.remarkLeft,
                                          remarkRight: row.remarkRight,
                                          numberPrefix: row.numberPrefix,
                                          numberValue: row.numberValue,
                                        ),
                                      )
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

class _RebarSpacingRowVm {
  _RebarSpacingRowVm({
    this.remarkLeft,
    this.remarkRight,
    this.numberPrefix,
    String? numberValue,
  }) : numberController = TextEditingController(text: numberValue ?? '');

  final TextEditingController numberController;
  String? remarkLeft;
  String? remarkRight;
  String? numberPrefix;

  String? get numberValue {
    final trimmed = numberController.text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void dispose() {
    numberController.dispose();
  }
}

class _RebarSpacingRowFields extends StatelessWidget {
  const _RebarSpacingRowFields({
    required this.row,
    required this.onChanged,
    this.label,
  });

  final _RebarSpacingRowVm row;
  final VoidCallback onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SizedBox(
              width: 40,
              child: Text(
                label!,
                style: Theme.of(context).textTheme.labelLarge,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: row.remarkLeft,
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
                        row.remarkLeft = value;
                        onChanged();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: row.remarkRight,
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
                        row.remarkRight = value;
                        onChanged();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: row.numberPrefix,
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
                        row.numberPrefix = value;
                        onChanged();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: row.numberController,
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
            ],
          ),
        ),
      ],
    );
  }
}
