import 'package:flutter/material.dart';

class MarkerSidePanelBody extends StatelessWidget {
  const MarkerSidePanelBody({
    super.key,
    required this.tabController,
    required this.defectTab,
    required this.equipmentTab,
    required this.detailTab,
    required this.viewTab,
  });

  final TabController tabController;
  final Widget defectTab;
  final Widget equipmentTab;
  final Widget detailTab;
  final Widget viewTab;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TabBarView(
        controller: tabController,
        children: [defectTab, equipmentTab, detailTab, viewTab],
      ),
    );
  }
}
