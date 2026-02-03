import 'package:flutter/material.dart';

import 'dialog_field_builders.dart';
import '../widgets/narrow_dialog_frame.dart';

class SettlementDetails {
  const SettlementDetails({
    required this.direction,
    required this.displacementText,
  });

  final String direction;
  final String? displacementText;
}

Future<SettlementDetails?> showSettlementDialog({
  required BuildContext context,
  required String baseTitle,
  required Map<String, int> nextIndexByDirection,
  String? initialDirection,
  String? initialDisplacementText,
}) {
  return showDialog<SettlementDetails>(
    context: context,
    builder: (context) => _SettlementDialog(
      baseTitle: baseTitle,
      nextIndexByDirection: nextIndexByDirection,
      initialDirection: initialDirection,
      initialDisplacementText: initialDisplacementText,
    ),
  );
}

class _SettlementDialog extends StatefulWidget {
  const _SettlementDialog({
    required this.baseTitle,
    required this.nextIndexByDirection,
    this.initialDirection,
    this.initialDisplacementText,
  });

  final String baseTitle;
  final Map<String, int> nextIndexByDirection;
  final String? initialDirection;
  final String? initialDisplacementText;

  @override
  State<_SettlementDialog> createState() => _SettlementDialogState();
}

class _SettlementDialogState extends State<_SettlementDialog> {
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

  String _dialogTitle() {
    final direction = _selectedDirection;
    if (direction == null || direction.isEmpty) {
      return widget.baseTitle;
    }
    final nextIndex = widget.nextIndexByDirection[direction] ?? 1;
    return '${widget.baseTitle} $direction$nextIndex';
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = dialogMaxWidth(
      context,
      widthFactor: 0.4,
      maxWidth: 280.0,
    );
    final isSaveEnabled = _selectedDirection != null;
    final title = _dialogTitle();
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    final keyboardType = const TextInputType.numberWithOptions(decimal: true);
    final onSave = isSaveEnabled
        ? () {
            if (!(_formKey.currentState?.validate() ?? false)) {
              return;
            }
            final displacement = _displacementController.text.trim();
            Navigator.of(context).pop(
              SettlementDetails(
                direction: _selectedDirection!,
                displacementText: displacement.isEmpty ? null : displacement,
              ),
            );
          }
        : null;

    return NarrowDialogFrame(
      maxWidth: maxWidth,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(title, titleStyle),
            const SizedBox(height: 16),
            _buildDirectionField(),
            const SizedBox(height: 12),
            _buildDisplacementField(keyboardType),
            const SizedBox(height: 16),
            _buildActions(context, onSave),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title, TextStyle? titleStyle) {
    return Text(
      title,
      style: titleStyle,
    );
  }

  Widget _buildDirectionField() {
    return buildDialogDropdownField(
      value: _selectedDirection,
      labelText: '방향',
      items: const [
        DropdownMenuItem(
          value: 'Lx',
          child: Text('Lx'),
        ),
        DropdownMenuItem(
          value: 'Ly',
          child: Text('Ly'),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedDirection = value;
        });
      },
      requiredMessage: '방향을 선택하세요.',
    );
  }

  Widget _buildDisplacementField(TextInputType keyboardType) {
    return buildDialogTextField(
      controller: _displacementController,
      labelText: '변위량',
      keyboardType: keyboardType,
    );
  }

  Widget _buildActions(BuildContext context, VoidCallback? onSave) {
    return buildDialogActionButtons(
      context,
      onSave: onSave,
    );
  }
}
