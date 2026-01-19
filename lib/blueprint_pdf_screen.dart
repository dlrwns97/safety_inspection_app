import 'package:flutter/material.dart';

import 'marker_model.dart';
import 'pdf_renderer_service.dart';

class BlueprintPdfScreen extends StatefulWidget {
  const BlueprintPdfScreen({
    super.key,
    required this.assetPath,
    this.filePath,
    required this.initialDefects,
    required this.onDefectsChanged,
    this.onMarkerTap,
  });

  final String assetPath;
  final String? filePath;
  final List<Defect> initialDefects;
  final Future<void> Function(List<Defect> defects) onDefectsChanged;
  final ValueChanged<String>? onMarkerTap;

  @override
  State<BlueprintPdfScreen> createState() => _BlueprintPdfScreenState();
}

class _BlueprintPdfScreenState extends State<BlueprintPdfScreen> {
  final TransformationController _transformationController =
      TransformationController();
  final PdfRendererService _rendererService = PdfRendererService();

  RenderedPdfPage? _renderedPage;
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  int _pageCount = 1;
  DefectCategory _activeCategory = DefectCategory.crack;
  late List<Defect> _defects;

  @override
  void initState() {
    super.initState();
    _defects = List<Defect>.from(widget.initialDefects);
    _loadDocument();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _rendererService.close();
    super.dispose();
  }

  Future<void> _loadDocument() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _rendererService.openDocument(
        assetPath: widget.assetPath,
        filePath: widget.filePath,
      );
      if (!mounted) {
        return;
      }
      _pageCount = _rendererService.pageCount;
      await _renderPage(_currentPage);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = 'PDF를 불러오지 못했습니다.';
      });
    }
  }

  Future<void> _renderPage(int pageNumber) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final rendered = await _rendererService.renderPage(pageNumber);
      if (!mounted) {
        return;
      }
      _transformationController.value = Matrix4.identity();
      setState(() {
        _renderedPage = rendered;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = '페이지를 렌더링하지 못했습니다.';
      });
    }
  }

  Future<void> _handleTap(TapDownDetails details) async {
    final renderedPage = _renderedPage;
    if (renderedPage == null) {
      return;
    }
    final scenePoint = _transformationController.toScene(
      details.localPosition,
    );
    final normalizedX =
        (scenePoint.dx / renderedPage.width).clamp(0.0, 1.0);
    final normalizedY =
        (scenePoint.dy / renderedPage.height).clamp(0.0, 1.0);

    final detailsResult = await _showDefectDetailsSheet(_activeCategory);
    if (!mounted || detailsResult == null) {
      return;
    }

    final countOnPage = _defects
        .where((defect) => defect.pageIndex == _currentPage)
        .length;
    final label = 'C${countOnPage + 1}';

    final defect = Defect(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      label: label,
      pageIndex: _currentPage,
      category: _activeCategory,
      normalizedX: normalizedX,
      normalizedY: normalizedY,
      details: detailsResult,
    );

    setState(() {
      _defects = [..._defects, defect];
    });
    await widget.onDefectsChanged(_defects);
  }

  Future<DefectDetails?> _showDefectDetailsSheet(
    DefectCategory category,
  ) async {
    final widthController = TextEditingController();
    final lengthController = TextEditingController();
    final typeCustomController = TextEditingController();
    final causeCustomController = TextEditingController();
    final widthFocusNode = FocusNode();
    final lengthFocusNode = FocusNode();

    DefectDetails? result;
    try {
      result = await showModalBottomSheet<DefectDetails>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          final formKey = GlobalKey<FormState>();
          String? structuralMember;
          DefectOption? defectType;
          DefectOption? cause;

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: StatefulBuilder(
              builder: (context, setState) {
                bool isValid() {
                  final width = double.tryParse(widthController.text);
                  final length = double.tryParse(lengthController.text);
                  final typeCustomValid =
                      !(defectType?.isCustom ?? false) ||
                          typeCustomController.text.trim().isNotEmpty;
                  final causeCustomValid =
                      !(cause?.isCustom ?? false) ||
                          causeCustomController.text.trim().isNotEmpty;
                  return structuralMember != null &&
                      defectType != null &&
                      cause != null &&
                      width != null &&
                      length != null &&
                      width > 0 &&
                      length > 0 &&
                      typeCustomValid &&
                      causeCustomValid;
                }

                return Form(
                  key: formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '결함 상세',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: structuralMember,
                        decoration: const InputDecoration(
                          labelText: '부재',
                        ),
                        items: structuralMembers
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            structuralMember = value;
                          });
                        },
                        validator: (value) =>
                            value == null ? '부재를 선택하세요' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<DefectOption>(
                        value: defectType,
                        decoration: const InputDecoration(
                          labelText: '유형',
                        ),
                        items: defectTypeOptions[category]
                            ?.map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item.label),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            defectType = value;
                          });
                        },
                        validator: (value) =>
                            value == null ? '유형을 선택하세요' : null,
                      ),
                      if (defectType?.isCustom ?? false) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: typeCustomController,
                          decoration: const InputDecoration(
                            labelText: '유형 기타 입력',
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if ((defectType?.isCustom ?? false) &&
                                (value == null || value.trim().isEmpty)) {
                              return '기타 유형을 입력하세요';
                            }
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: widthController,
                              focusNode: widthFocusNode,
                              decoration: const InputDecoration(
                                labelText: '폭 (mm)',
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (value) {
                                final parsed = double.tryParse(value ?? '');
                                if (parsed == null || parsed <= 0) {
                                  return '폭 입력';
                                }
                                return null;
                              },
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: lengthController,
                              focusNode: lengthFocusNode,
                              decoration: const InputDecoration(
                                labelText: '길이 (mm)',
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (value) {
                                final parsed = double.tryParse(value ?? '');
                                if (parsed == null || parsed <= 0) {
                                  return '길이 입력';
                                }
                                return null;
                              },
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<DefectOption>(
                        value: cause,
                        decoration: const InputDecoration(labelText: '원인'),
                        items: defectCauseOptions[category]
                            ?.map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item.label),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            cause = value;
                          });
                        },
                        validator: (value) =>
                            value == null ? '원인을 선택하세요' : null,
                      ),
                      if (cause?.isCustom ?? false) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: causeCustomController,
                          decoration: const InputDecoration(
                            labelText: '원인 기타 입력',
                          ),
                          textInputAction: TextInputAction.done,
                          validator: (value) {
                            if ((cause?.isCustom ?? false) &&
                                (value == null || value.trim().isEmpty)) {
                              return '기타 원인을 입력하세요';
                            }
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('취소'),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: isValid()
                                ? () {
                                    if (formKey.currentState?.validate() ??
                                        false) {
                                      Navigator.of(context).pop(
                                        DefectDetails(
                                          structuralMember: structuralMember!,
                                          defectType: defectType!.code,
                                          defectTypeCustomText:
                                              defectType!.isCustom
                                                  ? typeCustomController.text
                                                      .trim()
                                                  : null,
                                          widthMm: double.parse(
                                            widthController.text.trim(),
                                          ),
                                          lengthMm: double.parse(
                                            lengthController.text.trim(),
                                          ),
                                          cause: cause!.code,
                                          causeCustomText: cause!.isCustom
                                              ? causeCustomController.text
                                                  .trim()
                                              : null,
                                        ),
                                      );
                                    }
                                  }
                                : null,
                            child: const Text('확인'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                );
              },
            ),
          );
        },
      );
    } finally {
      widthController.dispose();
      lengthController.dispose();
      typeCustomController.dispose();
      causeCustomController.dispose();
      widthFocusNode.dispose();
      lengthFocusNode.dispose();
    }
    return result;
  }

  List<Widget> _buildMarkers() {
    final renderedPage = _renderedPage;
    if (renderedPage == null) {
      return [];
    }
    final pageDefects = _defects
        .where((defect) => defect.pageIndex == _currentPage)
        .toList();

    return pageDefects.map((defect) {
      final position = Offset(
        defect.normalizedX * renderedPage.width,
        defect.normalizedY * renderedPage.height,
      );
      return Positioned(
        left: position.dx - 18,
        top: position.dy - 18,
        child: GestureDetector(
          onTap: () => widget.onMarkerTap?.call(defect.id),
          child: DefectMarker(label: defect.label, category: defect.category),
        ),
      );
    }).toList();
  }

  Widget _buildPageContent() {
    final renderedPage = _renderedPage;
    if (renderedPage == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _handleTap,
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 1.0,
        maxScale: 8.0,
        panEnabled: true,
        scaleEnabled: true,
        constrained: false,
        child: SizedBox(
          width: renderedPage.width.toDouble(),
          height: renderedPage.height.toDouble(),
          child: Stack(
            children: [
              Image.memory(
                renderedPage.bytes,
                width: renderedPage.width.toDouble(),
                height: renderedPage.height.toDouble(),
                fit: BoxFit.fill,
              ),
              ..._buildMarkers(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: _currentPage > 1
              ? () {
                  setState(() {
                    _currentPage -= 1;
                  });
                  _renderPage(_currentPage);
                }
              : null,
        ),
        Text('$_currentPage / $_pageCount'),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _currentPage < _pageCount
              ? () {
                  setState(() {
                    _currentPage += 1;
                  });
                  _renderPage(_currentPage);
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildCategoryChips() {
    return Wrap(
      spacing: 8,
      children: DefectCategory.values.map((category) {
        final selected = _activeCategory == category;
        return ChoiceChip(
          label: Text(category.label),
          selected: selected,
          onSelected: (_) {
            setState(() {
              _activeCategory = category;
            });
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF 도면 보기'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: _buildCategoryChips(),
          ),
          Expanded(
            child: Center(
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : _errorMessage != null
                  ? Text(_errorMessage!)
                  : _buildPageContent(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _buildPageControls(),
          ),
        ],
      ),
    );
  }
}
