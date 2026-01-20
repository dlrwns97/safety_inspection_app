import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'l10n/app_localizations.dart';

void main() {
  runApp(const SafetyInspectionApp());
}

class SafetyInspectionApp extends StatelessWidget {
  const SafetyInspectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) =>
          AppLocalizations.of(context).strings.appTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const InspectionHome(),
    );
  }
}

class InspectionHome extends StatelessWidget {
  const InspectionHome({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context).strings;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(strings.appTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: strings.workspaceTab),
              Tab(text: strings.defectsTab),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            WorkspaceScreen(),
            DefectsScreen(),
          ],
        ),
      ),
    );
  }
}

class WorkspaceScreen extends StatelessWidget {
  const WorkspaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context).strings;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: BlueprintViewer(
              title: strings.blueprintTitle,
              assetPath: 'assets/blueprints/sample_blueprint.pdf',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: _WorkspaceSummary(
              title: strings.workspaceSummaryTitle,
              subtitle: strings.workspaceSummarySubtitle,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceSummary extends StatelessWidget {
  const _WorkspaceSummary({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(subtitle),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: const [
                _SummaryChip(label: 'A-01', value: '3'),
                _SummaryChip(label: 'B-02', value: '2'),
                _SummaryChip(label: 'C-03', value: '4'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class BlueprintViewer extends StatefulWidget {
  const BlueprintViewer({
    super.key,
    required this.title,
    required this.assetPath,
  });

  final String title;
  final String assetPath;

  @override
  State<BlueprintViewer> createState() => _BlueprintViewerState();
}

class _BlueprintViewerState extends State<BlueprintViewer> {
  final PdfViewerController _controller = PdfViewerController();
  int _currentPage = 1;
  int _pageCount = 1;
  Uint8List? _data;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final data = await rootBundle.load(widget.assetPath);
      setState(() {
        _data = data.buffer.asUint8List();
        _loadFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _data = null;
        _loadFailed = true;
      });
    }
  }

  void _updatePageCount(int pageCount) {
    setState(() {
      _pageCount = pageCount;
    });
  }

  void _updateCurrentPage(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _goToPrevious() {
    if (_currentPage > 1) {
      _controller.previousPage();
    }
  }

  void _goToNext() {
    if (_currentPage < _pageCount) {
      _controller.nextPage();
    }
  }

  void _handleScroll(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      if (event.scrollDelta.dy > 0) {
        _goToNext();
      } else if (event.scrollDelta.dy < 0) {
        _goToPrevious();
      }
    }
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
          event.logicalKey == LogicalKeyboardKey.pageDown) {
        _goToNext();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.pageUp) {
        _goToPrevious();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context).strings;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (_data == null) {
                    return _BlueprintStatus(
                      icon: Icons.file_copy_outlined,
                      message: _loadFailed
                          ? strings.blueprintLoadError
                          : strings.blueprintMissing,
                    );
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: Listener(
                          onPointerSignal: _handleScroll,
                          child: Focus(
                            autofocus: true,
                            onKeyEvent: _handleKey,
                            child: SfPdfViewer.memory(
                              _data!,
                              controller: _controller,
                              pageLayoutMode: PdfPageLayoutMode.single,
                              canShowScrollHead: false,
                              onDocumentLoaded: (details) =>
                                  _updatePageCount(details.document.pages.count),
                              onDocumentLoadFailed: (details) {
                                setState(() {
                                  _loadFailed = true;
                                  _data = null;
                                });
                              },
                              onPageChanged: (details) =>
                                  _updateCurrentPage(details.newPageNumber),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(strings.pageIndicator(_currentPage, _pageCount)),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed:
                                    _currentPage > 1 ? _goToPrevious : null,
                                icon: const Icon(Icons.chevron_left),
                                label: Text(strings.previousPage),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed:
                                    _currentPage < _pageCount ? _goToNext : null,
                                icon: const Icon(Icons.chevron_right),
                                label: Text(strings.nextPage),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlueprintStatus extends StatelessWidget {
  const _BlueprintStatus({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56),
            const SizedBox(height: 12),
            Text(message),
          ],
        ),
      ),
    );
  }
}

class DefectsScreen extends StatefulWidget {
  const DefectsScreen({super.key});

  @override
  State<DefectsScreen> createState() => _DefectsScreenState();
}

class _DefectsScreenState extends State<DefectsScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context).strings;
    final defects = _buildDefects(strings);
    final selectedDefect = defects[_selectedIndex];

    return DefaultTabController(
      length: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.defectHeader,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            TabBar(
              tabs: [
                Tab(text: strings.defectTabAll),
                Tab(text: strings.defectTabOpen),
                Tab(text: strings.defectTabClosed),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _DefectList(
                      title: strings.defectListTitle,
                      defects: defects,
                      selectedIndex: _selectedIndex,
                      onSelected: (index) {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: _DefectDetails(
                      title: strings.defectDetailsTitle,
                      formTitle: strings.defectFormTitle,
                      actionLabel: strings.defectActionButton,
                      defect: selectedDefect,
                      locationLabel: strings.defectLocationLabel,
                      severityLabel: strings.defectSeverityLabel,
                      statusLabel: strings.defectStatusLabel,
                      assigneeLabel: strings.defectAssigneeLabel,
                      notesLabel: strings.defectNotesLabel,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_Defect> _buildDefects(AppStrings strings) {
    return [
      _Defect(
        id: 'D-014',
        title: strings.defectSampleTitle1,
        location: strings.defectSampleLocation1,
        severity: _DefectSeverity.high,
        status: _DefectStatus.open,
        assignee: strings.defectSampleAssignee1,
        notes: strings.defectSampleNotes1,
      ),
      _Defect(
        id: 'D-018',
        title: strings.defectSampleTitle2,
        location: strings.defectSampleLocation2,
        severity: _DefectSeverity.medium,
        status: _DefectStatus.open,
        assignee: strings.defectSampleAssignee2,
        notes: strings.defectSampleNotes2,
      ),
      _Defect(
        id: 'D-021',
        title: strings.defectSampleTitle3,
        location: strings.defectSampleLocation3,
        severity: _DefectSeverity.low,
        status: _DefectStatus.closed,
        assignee: strings.defectSampleAssignee3,
        notes: strings.defectSampleNotes3,
      ),
    ];
  }
}

class _DefectList extends StatelessWidget {
  const _DefectList({
    required this.title,
    required this.defects,
    required this.selectedIndex,
    required this.onSelected,
  });

  final String title;
  final List<_Defect> defects;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context).strings;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemBuilder: (context, index) {
                  final defect = defects[index];
                  final isSelected = index == selectedIndex;

                  return ListTile(
                    selected: isSelected,
                    selectedTileColor:
                        Theme.of(context).colorScheme.primary.withOpacity(0.08),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        defect.id.split('-').last,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(defect.title),
                    subtitle: Text(defect.location),
                    trailing: Text(_statusLabel(strings, defect.status)),
                    onTap: () => onSelected(index),
                  );
                },
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemCount: defects.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DefectDetails extends StatelessWidget {
  const _DefectDetails({
    required this.title,
    required this.formTitle,
    required this.actionLabel,
    required this.defect,
    required this.locationLabel,
    required this.severityLabel,
    required this.statusLabel,
    required this.assigneeLabel,
    required this.notesLabel,
  });

  final String title;
  final String formTitle;
  final String actionLabel;
  final _Defect defect;
  final String locationLabel;
  final String severityLabel;
  final String statusLabel;
  final String assigneeLabel;
  final String notesLabel;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context).strings;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _DetailRow(label: locationLabel, value: defect.location),
            _DetailRow(
              label: severityLabel,
              value: _severityLabel(strings, defect.severity),
            ),
            _DetailRow(
              label: statusLabel,
              value: _statusLabel(strings, defect.status),
            ),
            _DetailRow(label: assigneeLabel, value: defect.assignee),
            const SizedBox(height: 16),
            Text(
              formTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                labelText: notesLabel,
                border: const OutlineInputBorder(),
              ),
              minLines: 3,
              maxLines: 4,
              controller: TextEditingController(text: defect.notes),
              readOnly: true,
            ),
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () {},
                child: Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _Defect {
  const _Defect({
    required this.id,
    required this.title,
    required this.location,
    required this.severity,
    required this.status,
    required this.assignee,
    required this.notes,
  });

  final String id;
  final String title;
  final String location;
  final _DefectSeverity severity;
  final _DefectStatus status;
  final String assignee;
  final String notes;
}

enum _DefectSeverity { high, medium, low }

enum _DefectStatus { open, closed }

String _severityLabel(AppStrings strings, _DefectSeverity severity) {
  switch (severity) {
    case _DefectSeverity.high:
      return strings.severityHigh;
    case _DefectSeverity.medium:
      return strings.severityMedium;
    case _DefectSeverity.low:
      return strings.severityLow;
  }
}

String _statusLabel(AppStrings strings, _DefectStatus status) {
  switch (status) {
    case _DefectStatus.open:
      return strings.statusOpen;
    case _DefectStatus.closed:
      return strings.statusClosed;
  }
}
