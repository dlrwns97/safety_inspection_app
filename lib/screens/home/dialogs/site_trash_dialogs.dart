import 'package:flutter/material.dart';
import 'package:safety_inspection_app/constants/strings_ko.dart';
import 'package:safety_inspection_app/models/site.dart';

Future<bool> showMoveToTrashConfirm(BuildContext context, {required Site site}) async {
  final shouldDelete = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text(StringsKo.deleteSiteTitle),
        content: Text(
          StringsKo.deleteSiteToTrashMessage.replaceAll('{siteName}', site.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(StringsKo.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(StringsKo.delete),
          ),
        ],
      );
    },
  );

  return shouldDelete ?? false;
}

Future<bool> showPermanentDeleteConfirm(
  BuildContext context, {
  required Site site,
}) async {
  final shouldDelete = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text(StringsKo.permanentDeleteTitle),
        content: Text(
          StringsKo.permanentDeleteMessage.replaceAll('{siteName}', site.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(StringsKo.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(StringsKo.permanentDelete),
          ),
        ],
      );
    },
  );

  return shouldDelete ?? false;
}

Future<bool> showEmptyTrashConfirm(BuildContext context) async {
  final shouldDelete = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text(StringsKo.emptyTrashTitle),
        content: const Text(StringsKo.emptyTrashMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(StringsKo.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(StringsKo.permanentDelete),
          ),
        ],
      );
    },
  );

  return shouldDelete ?? false;
}
