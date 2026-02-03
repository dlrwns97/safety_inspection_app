import 'package:flutter/material.dart';

import 'dialog_field_builders.dart';
import '../widgets/narrow_dialog_frame.dart';

class StructuralTiltDetails {
  const StructuralTiltDetails({
    required this.direction,
    required this.displacementText,
  });

  final String direction;
  final String? displacementText;
}

Future<StructuralTiltDetails?> showStructuralTiltDialog({
  required BuildContext context,
  required String title,
  String? initialDirection,
  String? initialDisplacementText,
}) {
  return showDialog<StructuralTiltDetails>(
    context: context,
    builder: (context) => _StructuralTiltDialog(
      title: title,
      initialDirection: initialDirection,
      initialDisplacementText: initialDisplacementText,
    ),
  );
}

class _StructuralTiltDialog extends StatefulWidget {
  const _StructuralTiltDialog({
    required this.title,
    this.initialDirection,
    this.initialDisplacementText,
  });

  final String title;
  final String? initialDirection;
  final String? initialDisplacementText;

  @override
  State<_StructuralTiltDialog> createState() => _StructuralTiltDialogState();
}

class _StructuralTiltDialogState extends State<_StructuralTiltDialog> {
  final _formKey = GlobalKey<FormState>();
  final _displacementController = TextEditingController();
  String? _selectedDirection;

  @override
  void initState() {
    super.initState();
    _selectedDirection = widget.initialDirection;
    _displacementController.text = widget.initialDisplacementText ?? '';
  }

  @override
  void dispose() {
    _displacementController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = dialogMaxWidth(
      context,
      widthFactor: 0.45,
      maxWidth: 320.0,
    );
    final isSaveEnabled = _selectedDirection != null;
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    final onSave = isSaveEnabled ? _handleSave : null;

    return NarrowDialogFrame(
      maxWidth: maxWidth,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ..._buildHeader(titleStyle),
            ..._buildFields(),
            const SizedBox(height: 16),
            _buildActions(context, onSave: onSave),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildHeader(TextStyle? titleStyle) {
    return [
      Text(
        widget.title,
        style: titleStyle,
      ),
      const SizedBox(height: 16),
    ];
  }

  List<Widget> _buildFields() {
    final keyboardType = const TextInputType.numberWithOptions(
      decimal: true,
    );

    return [
      buildDialogDropdownField(
        value: _selectedDirection,
        labelText: '방향',
        items: const [
          DropdownMenuItem(
            value: '+',
            child: Text('+'),
          ),
          DropdownMenuItem(
            value: '-',
            child: Text('-'),
          ),
        ],
        onChanged: (value) {
          setState(() {
            _selectedDirection = value;
          });
        },
        requiredMessage: '방향을 선택하세요.',
      ),
      const SizedBox(height: 12),
      buildDialogTextField(
        controller: _displacementController,
        labelText: '변위량',
        keyboardType: keyboardType,
      ),
    ];
  }

  Widget _buildActions(BuildContext context, {required VoidCallback? onSave}) {
    return buildDialogActionButtons(
      context,
      onSave: onSave,
    );
  }

  void _handleSave() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final displacement = _displacementController.text.trim();
    Navigator.of(context).pop(
      StructuralTiltDetails(
        direction: _selectedDirection!,
        displacementText: displacement.isEmpty ? null : displacement,
      ),
    );
  }
}
