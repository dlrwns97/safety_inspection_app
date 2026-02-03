import 'package:flutter/material.dart';

import 'dialog_field_builders.dart';
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
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildMemberSection(),
            const SizedBox(height: 16),
            _buildFieldsSection(),
            const SizedBox(height: 16),
            _buildActions(context, isSaveEnabled),
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

  Widget _buildMemberSection() {
    final memberItems = widget.memberOptions
        .map(
          (option) => DropdownMenuItem(
            value: option,
            child: Text(option),
          ),
        )
        .toList();

    return buildDialogDropdownField(
      value: _selectedMember,
      labelText: '부재',
      items: memberItems,
      onChanged: (value) {
        setState(() {
          _selectedMember = value;
        });
      },
      requiredMessage: '부재를 선택하세요.',
    );
  }

  Widget _buildFieldsSection() {
    final keyboardType = const TextInputType.numberWithOptions(
      decimal: true,
    );

    return buildDialogTextField(
      controller: _avgValueController,
      labelText: '평균값',
      keyboardType: keyboardType,
    );
  }

  Widget _buildActions(BuildContext context, bool isSaveEnabled) {
    return buildDialogActionButtons(
      context,
      onSave: isSaveEnabled
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
    );
  }
}
