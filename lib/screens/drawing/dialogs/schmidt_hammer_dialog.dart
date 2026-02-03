import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dialog_field_builders.dart';
import '../widgets/narrow_dialog_frame.dart';

class SchmidtHammerDetails {
  const SchmidtHammerDetails({
    required this.memberType,
    required this.angleDeg,
    required this.maxValueText,
    required this.minValueText,
  });

  final String memberType;
  final int angleDeg;
  final String maxValueText;
  final String minValueText;
}

Future<SchmidtHammerDetails?> showSchmidtHammerDialog({
  required BuildContext context,
  required String title,
  required List<String> memberOptions,
  String? initialMemberType,
  int? initialAngleDeg,
  String? initialMaxValueText,
  String? initialMinValueText,
}) {
  return showDialog<SchmidtHammerDetails>(
    context: context,
    builder: (context) => _SchmidtHammerDialog(
      title: title,
      memberOptions: memberOptions,
      initialMemberType: initialMemberType,
      initialAngleDeg: initialAngleDeg,
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
    this.initialAngleDeg,
    this.initialMaxValueText,
    this.initialMinValueText,
  });

  final String title;
  final List<String> memberOptions;
  final String? initialMemberType;
  final int? initialAngleDeg;
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
  int _selectedAngleDeg = 0;

  @override
  void initState() {
    super.initState();
    _selectedMember = widget.initialMemberType;
    _selectedAngleDeg = widget.initialAngleDeg ?? 0;
    _maxValueController.text = widget.initialMaxValueText ?? '';
    _minValueController.text = widget.initialMinValueText ?? '';
  }

  @override
  void dispose() {
    _maxValueController.dispose();
    _minValueController.dispose();
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
    final memberItems = widget.memberOptions
        .map(
          (option) => DropdownMenuItem(
            value: option,
            child: Text(option),
          ),
        )
        .toList();
    final angleItems = const [0, 45, 90]
        .map(
          (angle) => DropdownMenuItem(
            value: angle,
            child: Text('$angle'),
          ),
        )
        .toList();
    const decimalInputType = TextInputType.numberWithOptions(
      decimal: true,
      signed: false,
    );
    final decimalFormatter = FilteringTextInputFormatter.allow(
      RegExp(r'^\d*\.?\d*$'),
    );

    return NarrowDialogFrame(
      maxWidth: maxWidth,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildSelectionRow(
              memberItems: memberItems,
              angleItems: angleItems,
            ),
            const SizedBox(height: 16),
            _buildValueRow(
              decimalInputType: decimalInputType,
              decimalFormatter: decimalFormatter,
            ),
            const SizedBox(height: 16),
            _buildActions(
              context,
              isSaveEnabled: isSaveEnabled,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Text(
      widget.title,
      style: Theme.of(context).textTheme.titleMedium,
    );
  }

  Widget _buildSelectionRow({
    required List<DropdownMenuItem<String>> memberItems,
    required List<DropdownMenuItem<int>> angleItems,
  }) {
    return Row(
      children: [
        Expanded(
          child: buildDialogDropdownField(
            value: _selectedMember,
            labelText: '부재',
            items: memberItems,
            onChanged: (value) {
              setState(() {
                _selectedMember = value;
              });
            },
            requiredMessage: '부재를 선택하세요.',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: _selectedAngleDeg,
            decoration: const InputDecoration(
              labelText: '각도',
              border: OutlineInputBorder(),
            ),
            items: angleItems,
            onChanged: (value) {
              setState(() {
                _selectedAngleDeg = value ?? 0;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildValueRow({
    required TextInputType decimalInputType,
    required TextInputFormatter decimalFormatter,
  }) {
    return Row(
      children: [
        Expanded(
          child: buildDialogTextField(
            controller: _minValueController,
            labelText: '최솟값',
            keyboardType: decimalInputType,
            inputFormatters: [
              decimalFormatter,
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: buildDialogTextField(
            controller: _maxValueController,
            labelText: '최댓값',
            keyboardType: decimalInputType,
            inputFormatters: [
              decimalFormatter,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions(
    BuildContext context, {
    required bool isSaveEnabled,
  }) {
    return buildDialogActionButtons(
      context,
      onSave: isSaveEnabled
          ? () {
              if (!(_formKey.currentState?.validate() ?? false)) {
                return;
              }
              Navigator.of(context).pop(
                SchmidtHammerDetails(
                  memberType: _selectedMember!,
                  angleDeg: _selectedAngleDeg,
                  maxValueText: _maxValueController.text.trim(),
                  minValueText: _minValueController.text.trim(),
                ),
              );
            }
          : null,
    );
  }
}
