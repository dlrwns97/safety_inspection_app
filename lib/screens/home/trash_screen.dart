import 'package:flutter/material.dart';
import 'package:safety_inspection_app/constants/strings_ko.dart';
import 'package:safety_inspection_app/models/site.dart';
import 'package:safety_inspection_app/screens/home/dialogs/site_trash_dialogs.dart';
import 'package:safety_inspection_app/screens/home/home_storage.dart';
import 'package:safety_inspection_app/screens/home/widgets/site_list_tile.dart';

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
    final sites = await HomeStorage.loadSites();
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
    final updatedSites = await HomeStorage.restoreSite(_sites, site);
    if (!mounted) {
      return;
    }
    setState(() {
      _sites = updatedSites;
    });
  }

  Future<void> _permanentlyDeleteSite(Site site) async {
    final updatedSites = await HomeStorage.permanentlyDeleteSite(_sites, site);
    if (!mounted) {
      return;
    }
    setState(() {
      _sites = updatedSites;
    });
  }

  Future<void> _confirmPermanentDelete(Site site) async {
    final shouldDelete = await showPermanentDeleteConfirm(context, site: site);
    if (!mounted || !shouldDelete) {
      return;
    }

    await _permanentlyDeleteSite(site);
  }

  Future<void> _confirmEmptyTrash() async {
    final shouldDelete = await showEmptyTrashConfirm(context);
    if (!mounted || !shouldDelete) {
      return;
    }

    final updatedSites = await HomeStorage.emptyTrash(_sites);
    if (!mounted) {
      return;
    }
    setState(() {
      _sites = updatedSites;
    });
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
                    return SiteListTile(
                      site: site,
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
