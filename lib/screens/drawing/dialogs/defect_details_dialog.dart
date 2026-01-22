import 'dart:math';

import 'package:flutter/material.dart';

import 'package:safety_inspection_app/constants/strings_ko.dart';
import 'package:safety_inspection_app/models/defect_details.dart';
import '../widgets/narrow_dialog_frame.dart';

Future<DefectDetails?> showDefectDetailsDialog({
  required BuildContext context,
  required String title,
  required List<String> typeOptions,
  required List<String> causeOptions,
}) {
  return showDialog<DefectDetails>(
    context: context,
    builder: (context) => _DefectDetailsDialog(
      title: title,
      typeOptions: typeOptions,
      causeOptions: causeOptions,
    ),
  );
}

class _DefectDetailsDialog extends StatefulWidget {
  const _DefectDetailsDialog({
    required this.title,
    required this.typeOptions,
    required this.causeOptions,
  });

  final String title;
  final List<String> typeOptions;
  final List<String> causeOptions;

  @override
  State<_DefectDetailsDialog> createState() => _DefectDetailsDialogState();
}

class _DefectDetailsDialogState extends State<_DefectDetailsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _widthController = TextEditingController();
  final _lengthController = TextEditingController();
  final _otherTypeController = TextEditingController();
  final _otherCauseController = TextEditingController();

  String? _structuralMember;
  String? _crackType;
  String? _cause;

  @override
  void dispose() {
    _widthController.dispose();
    _lengthController.dispose();
    _otherTypeController.dispose();
    _otherCauseController.dispose();
    super.dispose();
  }

  bool get _isOtherType => _crackType == StringsKo.otherOptionLabel;
  bool get _isOtherCause => _cause == StringsKo.otherOptionLabel;

  bool _isValid() {
    final width = double.tryParse(_widthController.text);
    final length = double.tryParse(_lengthController.text);
    final hasOtherType =
        !_isOtherType || _otherTypeController.text.trim().isNotEmpty;
    final hasOtherCause =
        !_isOtherCause || _otherCauseController.text.trim().isNotEmpty;
    return _structuralMember != null &&
        _crackType != null &&
        _cause != null &&
        width != null &&
        length != null &&
        width > 0 &&
        length > 0 &&
        hasOtherType &&
        hasOtherCause;
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = min(
      MediaQuery.of(context).size.width * 0.6,
      520.0,
    );

    return NarrowDialogFrame(
      maxWidth: maxWidth,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _structuralMember,
                  decoration: InputDecoration(
                    labelText: StringsKo.structuralMemberLabel,
                  ),
                  items: StringsKo.structuralMembers
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _structuralMember = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? StringsKo.selectMemberError : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _crackType,
                  decoration: InputDecoration(
                    labelText: StringsKo.crackTypeLabel,
                  ),
                  items: widget.typeOptions
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _crackType = value;
                      if (value != StringsKo.otherOptionLabel) {
                        _otherTypeController.clear();
                      }
                    });
                  },
                  validator: (value) =>
                      value == null ? StringsKo.selectCrackTypeError : null,
                ),
                if (_isOtherType) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _otherTypeController,
                    decoration: InputDecoration(
                      labelText: StringsKo.otherTypeLabel,
                    ),
                    validator: (_) =>
                        _otherTypeController.text.trim().isEmpty
                        ? StringsKo.enterOtherTypeError
                        : null,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _widthController,
                        decoration: InputDecoration(
                          labelText: StringsKo.widthLabel,
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                        validator: (value) {
                          final parsed = double.tryParse(value ?? '');
                          if (parsed == null || parsed <= 0) {
                            return StringsKo.enterWidthError;
                          }
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lengthController,
                        decoration: InputDecoration(
                          labelText: StringsKo.lengthLabel,
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                        validator: (value) {
                          final parsed = double.tryParse(value ?? '');
                          if (parsed == null || parsed <= 0) {
                            return StringsKo.enterLengthError;
                          }
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _cause,
                  decoration: InputDecoration(
                    labelText: StringsKo.causeLabel,
                  ),
                  items: widget.causeOptions
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _cause = value;
                      if (value != StringsKo.otherOptionLabel) {
                        _otherCauseController.clear();
                      }
                    });
                  },
                  validator: (value) =>
                      value == null ? StringsKo.selectCauseError : null,
                ),
                if (_isOtherCause) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _otherCauseController,
                    decoration: InputDecoration(
                      labelText: StringsKo.otherCauseLabel,
                    ),
                    validator: (_) =>
                        _otherCauseController.text.trim().isEmpty
                        ? StringsKo.enterOtherCauseError
                        : null,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(StringsKo.cancel),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: _isValid()
                          ? () {
                              if (_formKey.currentState?.validate() ?? false) {
                                final resolvedType = _isOtherType
                                    ? _otherTypeController.text.trim()
                                    : _crackType!;
                                final resolvedCause = _isOtherCause
                                    ? _otherCauseController.text.trim()
                                    : _cause!;
                                Navigator.of(context).pop(
                                  DefectDetails(
                                    structuralMember: _structuralMember!,
                                    crackType: resolvedType,
                                    widthMm: double.parse(
                                      _widthController.text.trim(),
                                    ),
                                    lengthMm: double.parse(
                                      _lengthController.text.trim(),
                                    ),
                                    cause: resolvedCause,
                                  ),
                                );
                              }
                            }
                          : null,
                      child: Text(StringsKo.confirm),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
