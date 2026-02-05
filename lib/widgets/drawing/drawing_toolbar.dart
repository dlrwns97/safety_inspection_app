import 'package:flutter/material.dart';

enum DrawingTool { pen, eraser }

class DrawingToolbar extends StatelessWidget {
  const DrawingToolbar({
    super.key,
    required this.activeTool,
    required this.onToolSelected,
    required this.onUndo,
    required this.onRedo,
    required this.canUndo,
    required this.canRedo,
  });

  final DrawingTool activeTool;
  final ValueChanged<DrawingTool> onToolSelected;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final bool canUndo;
  final bool canRedo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 3,
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _ToolbarButton(
                icon: Icons.draw,
                label: '자유선',
                tooltip: '자유선 도구',
                isSelected: activeTool == DrawingTool.pen,
                onPressed: () => onToolSelected(DrawingTool.pen),
              ),
              _ToolbarButton(
                icon: Icons.cleaning_services,
                label: '지우개',
                tooltip: '지우개 도구',
                isSelected: activeTool == DrawingTool.eraser,
                onPressed: () => onToolSelected(DrawingTool.eraser),
              ),
              _ToolbarButton(
                icon: Icons.undo,
                label: '되돌리기',
                tooltip: '되돌리기',
                isSelected: false,
                onPressed: canUndo ? onUndo : null,
              ),
              _ToolbarButton(
                icon: Icons.redo,
                label: '앞으로',
                tooltip: '앞으로',
                isSelected: false,
                onPressed: canRedo ? onRedo : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.isSelected,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final bool isSelected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: tooltip,
        child: TextButton.icon(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor:
                isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
            backgroundColor:
                isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
            disabledForegroundColor: theme.colorScheme.onSurfaceVariant,
            disabledBackgroundColor: theme.colorScheme.surfaceContainer,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: Icon(icon, size: 18),
          label: Text(label),
        ),
      ),
    );
  }
}
