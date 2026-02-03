import 'package:flutter/material.dart';

import 'dialog_field_builders.dart';
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
    final maxWidth = dialogMaxWidth(
      context,
      widthFactor: 0.5,
      maxWidth: 360.0,
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
            _buildMemberSection(context),
            _buildFieldsSection(context),
            _buildActions(context, isSaveEnabled),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMemberSection(BuildContext context) {
    final memberItems = widget.memberOptions
        .map(
          (option) => DropdownMenuItem(
            value: option,
            child: Text(option),
          ),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        buildDialogDropdownField(
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
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFieldsSection(BuildContext context) {
    const keyboardType = TextInputType.numberWithOptions(decimal: true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        buildDialogTextField(
          controller: _coverThicknessController,
          labelText: '피복두께',
          keyboardType: keyboardType,
        ),
        const SizedBox(height: 12),
        buildDialogTextField(
          controller: _depthController,
          labelText: '깊이',
          keyboardType: keyboardType,
        ),
        const SizedBox(height: 16),
      ],
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
                CarbonationDetails(
                  memberType: _selectedMember!,
                  coverThicknessText: _coverThicknessController.text.trim(),
                  depthText: _depthController.text.trim(),
                ),
              );
            }
          : null,
    );
  }
}
