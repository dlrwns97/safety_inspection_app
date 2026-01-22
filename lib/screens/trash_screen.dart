import 'package:flutter/material.dart';

import '../constants/strings_ko.dart';
import '../models/drawing_enums.dart';
import '../models/site.dart';
import '../models/site_storage.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  List<Site> _sites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSites();
  }

  Future<void> _loadSites() async {
    final sites = await SiteStorage.loadSites();
    if (!mounted) {
      return;
    }
    setState(() {
      _sites = sites;
      _isLoading = false;
    });
  }

  List<Site> get _trashSites =>
      _sites.where((site) => site.isDeleted).toList();

  Future<void> _restoreSite(Site site) async {
    final updatedSites = _sites
        .map(
          (existing) =>
              existing.id == site.id
                  ? existing.copyWith(isDeleted: false, deletedAt: null)
                  : existing,
        )
        .toList();
    await SiteStorage.saveSites(updatedSites);
    if (!mounted) {
      return;
    }
    setState(() {
      _sites = updatedSites;
    });
  }

  Future<void> _permanentlyDeleteSite(Site site) async {
    final updatedSites =
        _sites.where((existing) => existing.id != site.id).toList();
    await SiteStorage.saveSites(updatedSites);
    if (!mounted) {
      return;
    }
    setState(() {
      _sites = updatedSites;
    });
  }

  Future<void> _confirmPermanentDelete(Site site) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(StringsKo.permanentDeleteTitle),
          content: Text(
            StringsKo.permanentDeleteMessage.replaceAll(
              '{siteName}',
              site.name,
            ),
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

    if (!mounted || shouldDelete != true) {
      return;
    }

    await _permanentlyDeleteSite(site);
  }

  Future<void> _confirmEmptyTrash() async {
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

    if (!mounted || shouldDelete != true) {
      return;
    }

    final updatedSites =
        _sites.where((site) => !site.isDeleted).toList();
    await SiteStorage.saveSites(updatedSites);
    if (!mounted) {
      return;
    }
    setState(() {
      _sites = updatedSites;
    });
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

  String _formatSiteSubtitle(Site site) {
    final dateText = _formatInspectionDate(site.inspectionDate);
    final structureType = site.structureType ?? StringsKo.unsetLabel;
    final inspectionType = site.inspectionType ?? StringsKo.unsetLabel;
    return '$dateText · $structureType · $inspectionType';
  }

  @override
  Widget build(BuildContext context) {
    final trashSites = _trashSites;
    return Scaffold(
      appBar: AppBar(
        title: const Text(StringsKo.trashTitle),
        actions: [
          if (!_isLoading && trashSites.isNotEmpty)
            TextButton(
              onPressed: _confirmEmptyTrash,
              child: const Text(StringsKo.emptyTrash),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : trashSites.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 72,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          StringsKo.trashEmptyTitle,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          StringsKo.trashEmptySubtitle,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: trashSites.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final site = trashSites[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondaryContainer,
                        child: Icon(
                          site.drawingType == DrawingType.pdf
                              ? Icons.picture_as_pdf
                              : Icons.edit_document,
                          color:
                              Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                      ),
                      title: Text(site.name),
                      subtitle: Text(_formatSiteSubtitle(site)),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: () => _restoreSite(site),
                            child: const Text(StringsKo.restore),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.error,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onError,
                            ),
                            onPressed: () => _confirmPermanentDelete(site),
                            child: const Text(StringsKo.permanentDelete),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
