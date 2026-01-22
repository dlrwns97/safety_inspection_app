import 'package:flutter/material.dart';
import 'package:safety_inspection_app/constants/strings_ko.dart';

class HomeOverflowMenu extends StatelessWidget {
  const HomeOverflowMenu({super.key, required this.onTrashSelected});

  final VoidCallback onTrashSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_HomeMenuAction>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        switch (value) {
          case _HomeMenuAction.trash:
            onTrashSelected();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _HomeMenuAction.trash,
          child: Text(StringsKo.trashMenuLabel),
        ),
      ],
    );
  }
}

enum _HomeMenuAction { trash }
