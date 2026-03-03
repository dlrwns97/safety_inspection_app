import 'package:flutter/material.dart';
import 'package:safety_inspection_app/constants/strings_ko.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/site.dart';

Future<Site?> showNewSiteDialog(BuildContext context) {
  return showDialog<Site>(
    context: context,
    builder: (context) => const _NewSiteDialog(),
  );
}

class _NewSiteDialog extends StatefulWidget {
  const _NewSiteDialog();

  @override
  State<_NewSiteDialog> createState() => _NewSiteDialogState();
}

class _NewSiteDialogState extends State<_NewSiteDialog> {
  final TextEditingController _nameController = TextEditingController();

  String? _nameErrorText;
  String? _structureErrorText;
  String? _inspectionErrorText;
  String? _selectedStructureType;
  String? _selectedInspectionType;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      scrollable: true,
      title: const Text(StringsKo.newSite),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: StringsKo.siteNameLabel,
                errorText: _nameErrorText,
              ),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => FocusScope.of(context).nextFocus(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedStructureType,
              decoration: InputDecoration(
                labelText: StringsKo.structureTypeLabel,
                errorText: _structureErrorText,
              ),
              items: StringsKo.structureTypes
                  .map(
                    (type) => DropdownMenuItem(value: type, child: Text(type)),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStructureType = value;
                  _structureErrorText = null;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedInspectionType,
              decoration: InputDecoration(
                labelText: StringsKo.inspectionTypeLabel,
                errorText: _inspectionErrorText,
              ),
              items: StringsKo.inspectionTypes
                  .map(
                    (type) => DropdownMenuItem(value: type, child: Text(type)),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedInspectionType = value;
                  _inspectionErrorText = null;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(StringsKo.cancel),
        ),
        FilledButton(
          onPressed: _handleCreate,
          child: const Text(StringsKo.create),
        ),
      ],
    );
  }

  void _handleCreate() {
    final name = _nameController.text.trim();
    final hasName = name.isNotEmpty;
    final hasStructure = _selectedStructureType != null;
    final hasInspection = _selectedInspectionType != null;

    if (!hasName || !hasStructure || !hasInspection) {
      setState(() {
        _nameErrorText = hasName ? null : StringsKo.siteNameRequired;
        _structureErrorText = hasStructure
            ? null
            : StringsKo.structureTypeRequired;
        _inspectionErrorText = hasInspection
            ? null
            : StringsKo.inspectionTypeRequired;
      });
      return;
    }

    Navigator.of(context).pop(
      Site(
        id: 'draft',
        name: name,
        createdAt: DateTime.now(),
        drawingType: DrawingType.blank,
        structureType: _selectedStructureType!,
        inspectionType: _selectedInspectionType!,
        inspectionDate: DateTime.now(),
        visibleDefectCategoryNames: const [],
        visibleEquipmentCategoryNames: const [],
      ),
    );
  }
}
