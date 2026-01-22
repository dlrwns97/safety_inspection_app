import 'dart:math';

import 'package:flutter/material.dart';

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
    final maxWidth = min(
      MediaQuery.of(context).size.width * 0.4,
      280.0,
    );
    final isSaveEnabled = _selectedDirection != null;

    return NarrowDialogFrame(
      maxWidth: maxWidth,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _dialogTitle(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedDirection,
              decoration: const InputDecoration(
                labelText: '방향',
                border: OutlineInputBorder(),
              ),
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
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '방향을 선택하세요.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _displacementController,
              decoration: const InputDecoration(
                labelText: '변위량',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
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
                          final displacement =
                              _displacementController.text.trim();
                          Navigator.of(context).pop(
                            SettlementDetails(
                              direction: _selectedDirection!,
                              displacementText:
                                  displacement.isEmpty ? null : displacement,
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
