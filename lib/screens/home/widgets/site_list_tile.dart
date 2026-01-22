import 'package:flutter/material.dart';
import 'package:safety_inspection_app/constants/strings_ko.dart';
import 'package:safety_inspection_app/models/drawing_enums.dart';
import 'package:safety_inspection_app/models/site.dart';

class SiteListTile extends StatelessWidget {
  const SiteListTile({
    super.key,
    required this.site,
    this.trailing,
    this.onTap,
    this.onLongPress,
  });

  final Site site;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        child: Icon(
          site.drawingType == DrawingType.pdf
              ? Icons.picture_as_pdf
              : Icons.edit_document,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
      title: Text(site.name),
      subtitle: Text(_formatSiteSubtitle(site)),
      trailing: trailing,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}

String _formatSiteSubtitle(Site site) {
  final dateText = _formatInspectionDate(site.inspectionDate);
  final structureType = site.structureType ?? StringsKo.unsetLabel;
  final inspectionType = site.inspectionType ?? StringsKo.unsetLabel;
  return '$dateText · $structureType · $inspectionType';
}

String _formatInspectionDate(DateTime? date) {
  if (date == null) {
    return StringsKo.noInspectionDateLabel;
  }
  final localDate = date.toLocal();
  final year = localDate.year.toString().padLeft(4, '0');
  final month = localDate.month.toString().padLeft(2, '0');
  final day = localDate.day.toString().padLeft(2, '0');
  return '$year.$month.$day';
}
