import 'package:flutter/material.dart';
import 'package:safety_inspection_app/constants/strings_ko.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/site.dart';

Future<Site?> showNewSiteDialog(BuildContext context) {
  final controller = TextEditingController();
  String? nameErrorText;
  String? structureErrorText;
  String? inspectionErrorText;
  String? selectedStructureType;
  String? selectedInspectionType;

  return showDialog<Site>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text(StringsKo.newSite),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: StringsKo.siteNameLabel,
                    errorText: nameErrorText,
                  ),
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedStructureType,
                  decoration: InputDecoration(
                    labelText: StringsKo.structureTypeLabel,
                    errorText: structureErrorText,
                  ),
                  items: StringsKo.structureTypes
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedStructureType = value;
                      structureErrorText = null;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedInspectionType,
                  decoration: InputDecoration(
                    labelText: StringsKo.inspectionTypeLabel,
                    errorText: inspectionErrorText,
                  ),
                  items: StringsKo.inspectionTypes
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedInspectionType = value;
                      inspectionErrorText = null;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(StringsKo.cancel),
              ),
              FilledButton(
                onPressed: () {
                  final name = controller.text.trim();
                  final hasName = name.isNotEmpty;
                  final hasStructure = selectedStructureType != null;
                  final hasInspection = selectedInspectionType != null;
                  if (!hasName || !hasStructure || !hasInspection) {
                    setState(() {
                      nameErrorText =
                          hasName ? null : StringsKo.siteNameRequired;
                      structureErrorText =
                          hasStructure ? null : StringsKo.structureTypeRequired;
                      inspectionErrorText = hasInspection
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
                      structureType: selectedStructureType!,
                      inspectionType: selectedInspectionType!,
                      inspectionDate: DateTime.now(),
                      visibleDefectCategoryNames: const [],
                    ),
                  );
                },
                child: const Text(StringsKo.create),
              ),
            ],
          );
        },
      );
    },
  );
}
